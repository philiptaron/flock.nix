package main

import "testing"

func TestCommand(t *testing.T) {
	for _, test := range []struct {
		args []string
		want string
	}{
		{[]string{"id"}, "id"},
		{
			[]string{"systemctl", "show", "--property=ActiveState,SubState", "--no-pager"},
			"systemctl show --property=ActiveState,SubState --no-pager",
		},
		{
			[]string{"printf", `[%s]\n`, "a b", "$HOME", "x&y", "<b>bold</b>", "two\nlines", "plain", ""},
			`printf '[%s]\n' 'a b' '$HOME' 'x&y' '<b>bold</b>' $'two\nlines' plain ''`,
		},
		{[]string{"echo", "it's"}, `echo 'it'\''s'`},
		{[]string{"echo", "\x1b[1m'\\"}, `echo $'\E[1m\'\\'`},
		{[]string{"echo", "\x01"}, `echo $'\001'`},
		{
			[]string{
				"/nix/store/yn2n603bacr51pigr0d9ldx7bcd51vlh-ripgrep-15.2.0/bin/rg",
				"/nix/store/brv5fwiknx7a6y1z8kc5wdf8mns16sr9-gnome-shell-50.4/bin",
			},
			"ripgrep-15.2.0/bin/rg gnome-shell-50.4/bin",
		},
		{
			[]string{"sh", "-c", "/nix/store/5fy94f5bbvzc3fglwa8w6nci55i1qacz-nixos-system-zebul/bin/switch-to-configuration switch"},
			"sh -c 'nixos-system-zebul/bin/switch-to-configuration switch'",
		},
	} {
		if got := command(test.args); got != test.want {
			t.Errorf("command(%q) = %s, want %s", test.args, got, test.want)
		}
	}
}

func TestMarkup(t *testing.T) {
	if got, want := markup(`'x&y' '<b>bold</b>'`), `'x&amp;y' '&lt;b&gt;bold&lt;/b&gt;'`; got != want {
		t.Errorf("markup = %s, want %s", got, want)
	}
}

func TestShortenDir(t *testing.T) {
	const home = "/home/philip"
	for _, test := range []struct{ dir, want string }{
		{"/home/philip", "~"},
		{"/home/philip/Code", "~/Code"},
		{"/home/philip/Code/github.com/philiptaron", "~/Code/github.com/philiptaron"},
		{"/home/philip/Code/github.com/philiptaron/flock.nix", "~/…/philiptaron/flock.nix"},
		{"/home/philipx/Code", "/home/philipx/Code"},
		{"/nix/store/brv5fwiknx7a6y1z8kc5wdf8mns16sr9-gnome-shell-50.4/bin", "/…/gnome-shell-50.4/bin"},
		{"/nix/store/brv5fwiknx7a6y1z8kc5wdf8mns16sr9-gnome-shell-50.4", "/nix/store/gnome-shell-50.4"},
		{"/nix/store", "/nix/store"},
		{"/etc", "/etc"},
		{"/var/lib/systemd/coredump", "/…/systemd/coredump"},
		{"/", "/"},
	} {
		if got := shortenDir(test.dir, home); got != test.want {
			t.Errorf("shortenDir(%q) = %q, want %q", test.dir, got, test.want)
		}
	}
}
