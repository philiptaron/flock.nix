// sudo-notify names a sudo command in a desktop notification while sudo waits for a YubiKey touch.
//
// pam_exec runs it from sudo's auth stack, so its parent is sudo and the parent's argv is the sudo
// command line, whoever typed it. It reads what it needs from /proc, then starts a copy of itself
// as the user, in its own session, and exits so PAM can go on to the touch. The copy sends the
// notification, watches sudo, and closes the notification once sudo starts the command or gives up.
package main

import (
	"bytes"
	"errors"
	"fmt"
	"os"
	"os/exec"
	"os/user"
	"path/filepath"
	"regexp"
	"strconv"
	"strings"
	"syscall"
	"time"

	"github.com/godbus/dbus/v5"
)

const notifications = "org.freedesktop.Notifications"

func main() {
	if len(os.Args) > 1 && os.Args[1] == "watch" {
		if err := watch(os.Args[2:]); err != nil {
			os.Exit(1)
		}
		return
	}
	// PAM runs this as `optional`, so failing quietly costs nothing but the notification.
	_ = notify()
}

func notify() error {
	sudo := os.Getppid()
	start, err := startTime(sudo)
	if err != nil {
		return err
	}
	argv, err := cmdline(sudo)
	if err != nil {
		return err
	}

	u, err := user.Lookup(os.Getenv("PAM_USER"))
	if err != nil {
		return err
	}
	bus := "/run/user/" + u.Uid + "/bus"
	if _, err := os.Stat(bus); err != nil {
		return err
	}

	// Name who asked: the nearest ancestor of sudo that isn't a shell, like claude or ghostty.
	shell, err := parent(sudo)
	if err != nil {
		return err
	}
	title := requester(shell)

	// And where: sudo's working directory, which only root can read, else its shell's.
	cwd, err := os.Readlink(fmt.Sprintf("/proc/%d/cwd", sudo))
	if err != nil {
		cwd, _ = os.Readlink(fmt.Sprintf("/proc/%d/cwd", shell))
	}
	if cwd != "" {
		title += " in " + shortenDir(cwd, u.HomeDir)
	}

	self, err := os.Executable()
	if err != nil {
		return err
	}
	cmd := exec.Command(self, "watch",
		strconv.Itoa(sudo), strconv.FormatUint(start, 10), strconv.Itoa(os.Getpid()),
		title, markup(command(argv[1:])))
	cmd.Dir = "/"
	cmd.Env = []string{"DBUS_SESSION_BUS_ADDRESS=unix:path=" + bus}
	cmd.SysProcAttr = &syscall.SysProcAttr{Setsid: true}

	// pam_exec runs this with sudo's user IDs: the real one is root or the user depending on how far
	// sudo has gotten, and the effective one is root. Drop to the user entirely; the session bus
	// refuses a connection whose effective user isn't the one it claims to be.
	if os.Geteuid() == 0 {
		credential, err := credentialOf(u)
		if err != nil {
			return err
		}
		cmd.SysProcAttr.Credential = credential
	}
	return cmd.Start()
}

func credentialOf(u *user.User) (*syscall.Credential, error) {
	uid, err := strconv.ParseUint(u.Uid, 10, 32)
	if err != nil {
		return nil, err
	}
	gid, err := strconv.ParseUint(u.Gid, 10, 32)
	if err != nil {
		return nil, err
	}
	groupIDs, err := u.GroupIds()
	if err != nil {
		return nil, err
	}
	groups := make([]uint32, 0, len(groupIDs))
	for _, g := range groupIDs {
		id, err := strconv.ParseUint(g, 10, 32)
		if err != nil {
			return nil, err
		}
		groups = append(groups, uint32(id))
	}
	return &syscall.Credential{Uid: uint32(uid), Gid: uint32(gid), Groups: groups}, nil
}

// watch shows the notification until sudo stops waiting for the touch.
func watch(args []string) error {
	if len(args) != 5 {
		return errors.New("usage: sudo-notify watch SUDO-PID SUDO-START NOTIFIER-PID TITLE BODY")
	}
	sudo, err := strconv.Atoi(args[0])
	if err != nil {
		return err
	}
	start, err := strconv.ParseUint(args[1], 10, 64)
	if err != nil {
		return err
	}
	notifier, err := strconv.Atoi(args[2])
	if err != nil {
		return err
	}
	title, body := args[3], args[4]

	conn, err := dbus.ConnectSessionBus()
	if err != nil {
		return err
	}
	defer conn.Close()

	if err := conn.AddMatchSignal(
		dbus.WithMatchInterface(notifications),
		dbus.WithMatchMember("NotificationClosed"),
	); err != nil {
		return err
	}
	signals := make(chan *dbus.Signal, 16)
	conn.Signal(signals)

	// Critical, so GNOME keeps the banner up instead of timing it out after four seconds and
	// showing yubikey-touch-detector's in its place.
	server := conn.Object(notifications, "/org/freedesktop/Notifications")
	var id uint32
	if err := server.Call(notifications+".Notify", 0,
		"sudo", uint32(0), "auth-fingerprint-symbolic", title, body, []string{},
		map[string]dbus.Variant{"urgency": dbus.MakeVariant(byte(2))}, int32(-1),
	).Store(&id); err != nil {
		return err
	}

	tick := time.NewTicker(100 * time.Millisecond)
	defer tick.Stop()
	for {
		select {
		case signal, ok := <-signals:
			if !ok {
				return errors.New("lost the session bus")
			}
			if signal.Name != notifications+".NotificationClosed" || len(signal.Body) == 0 {
				continue
			}
			// Dismissed by hand: nothing left to close.
			if closed, ok := signal.Body[0].(uint32); ok && closed == id {
				return nil
			}
		case <-tick.C:
			if !waiting(sudo, start, notifier) {
				// yubikey-touch-detector calls a touch done 200 ms after the key's last packet, so its
				// notification outlives the wait by that much. Closing first lets GNOME show its banner,
				// queued behind this one, until it goes.
				time.Sleep(400 * time.Millisecond)
				return server.Call(notifications+".CloseNotification", 0, id).Err
			}
		}
	}
}

// waiting reports whether sudo is still authenticating: still running, and with no child but the
// first half of this program. sudo forks only once the touch is done, to run the command.
func waiting(sudo int, start uint64, notifier int) bool {
	if t, err := startTime(sudo); err != nil || t != start {
		return false
	}
	// /proc/<sudo>/task/<sudo>/children would be quicker, but sudo is setuid and the user can't
	// read it; everyone's stat is readable.
	entries, err := os.ReadDir("/proc")
	if err != nil {
		return false
	}
	for _, entry := range entries {
		pid, err := strconv.Atoi(entry.Name())
		if err != nil || pid == notifier {
			continue
		}
		if ppid, err := parent(pid); err == nil && ppid == sudo {
			return false
		}
	}
	return true
}

var shells = map[string]bool{"bash": true, "dash": true, "fish": true, "nu": true, "sh": true, "zsh": true}

// requester names the first process from pid up that isn't a shell, or sudo if there's none.
func requester(pid int) string {
	for pid > 1 {
		argv, err := cmdline(pid)
		if err != nil || len(argv) == 0 {
			break
		}
		// A login shell's argv[0] starts with a dash.
		name := strings.TrimPrefix(filepath.Base(argv[0]), "-")
		if !shells[name] {
			return name
		}
		if pid, err = parent(pid); err != nil {
			break
		}
	}
	return "sudo"
}

var (
	storeHash = regexp.MustCompile(`/nix/store/[0-9a-z]+-`)
	storeDir  = regexp.MustCompile(`^/nix/store/[0-9a-z]+-`)
)

// command writes out sudo's arguments the way they'd be typed. The setuid wrapper in /run/wrappers
// swaps argv[0] for sudo's store path, and the notification already says it's from sudo, so this
// names only what it's running.
func command(args []string) string {
	words := make([]string, len(args))
	for i, arg := range args {
		// A store path's hash says nothing at a glance; keep its name.
		words[i] = quote(storeHash.ReplaceAllLiteralString(arg, ""))
	}
	return strings.Join(words, " ")
}

var plain = regexp.MustCompile(`^[[:alnum:]_./:=@%+,#-]+$`)

// quote quotes a word as bash's ${word@Q} does, unless it's plain enough to type bare.
func quote(word string) string {
	if plain.MatchString(word) {
		return word
	}
	if !strings.ContainsFunc(word, func(r rune) bool { return r < 0x20 || r == 0x7f }) {
		return "'" + strings.ReplaceAll(word, "'", `'\''`) + "'"
	}
	var b strings.Builder
	b.WriteString("$'")
	for i := 0; i < len(word); i++ {
		switch c := word[i]; c {
		case '\a':
			b.WriteString(`\a`)
		case '\b':
			b.WriteString(`\b`)
		case '\t':
			b.WriteString(`\t`)
		case '\n':
			b.WriteString(`\n`)
		case '\v':
			b.WriteString(`\v`)
		case '\f':
			b.WriteString(`\f`)
		case '\r':
			b.WriteString(`\r`)
		case 0x1b:
			b.WriteString(`\E`)
		case '\'', '\\':
			b.WriteByte('\\')
			b.WriteByte(c)
		default:
			if c < 0x20 || c == 0x7f {
				fmt.Fprintf(&b, `\%03o`, c)
			} else {
				b.WriteByte(c)
			}
		}
	}
	b.WriteByte('\'')
	return b.String()
}

// markup escapes text for the notification body, which is markup; the title is plain text.
var markup = strings.NewReplacer("&", "&amp;", "<", "&lt;", ">", "&gt;").Replace

// shortenDir writes dir for the title, which doesn't wrap and which GNOME ellipsizes at the end.
// Past two directories below ~ or /, it keeps the last two, which tell one project from another.
func shortenDir(dir, home string) string {
	if home != "" && home != "/" {
		if dir == home {
			dir = "~"
		} else if rest, ok := strings.CutPrefix(dir, home+"/"); ok {
			dir = "~/" + rest
		}
	}
	// Keep /nix/store/ so that a shortened store path still reads as absolute.
	dir = storeDir.ReplaceAllLiteralString(dir, "/nix/store/")
	if parts := strings.Split(dir, "/"); len(parts) > 4 {
		dir = parts[0] + "/…/" + parts[len(parts)-2] + "/" + parts[len(parts)-1]
	}
	return dir
}

func cmdline(pid int) ([]string, error) {
	b, err := os.ReadFile(fmt.Sprintf("/proc/%d/cmdline", pid))
	if err != nil || len(b) == 0 {
		return nil, err
	}
	return strings.Split(strings.TrimSuffix(string(b), "\x00"), "\x00"), nil
}

// stat returns the fields of /proc/<pid>/stat after the command name, which can hold spaces and
// parentheses, so that field n of proc_pid_stat(5) is at n-3.
func stat(pid int) ([]string, error) {
	b, err := os.ReadFile(fmt.Sprintf("/proc/%d/stat", pid))
	if err != nil {
		return nil, err
	}
	i := bytes.LastIndexByte(b, ')')
	if i < 0 {
		return nil, fmt.Errorf("/proc/%d/stat: no command name", pid)
	}
	fields := strings.Fields(string(b[i+1:]))
	if len(fields) < 20 {
		return nil, fmt.Errorf("/proc/%d/stat: too few fields", pid)
	}
	return fields, nil
}

func parent(pid int) (int, error) {
	fields, err := stat(pid)
	if err != nil {
		return 0, err
	}
	return strconv.Atoi(fields[4-3])
}

// startTime tells a process from a later one that reuses its PID.
func startTime(pid int) (uint64, error) {
	fields, err := stat(pid)
	if err != nil {
		return 0, err
	}
	return strconv.ParseUint(fields[22-3], 10, 64)
}
