{
  lib,
  stdenvNoCC,
  pkgs,
  writeTextFile,
  jq,
  ripgrep,
  nix,
  runtimeShell,
  perl,
  gnused,
  git,
}:

let
  inherit (lib) attrNames concatStringsSep;

  nixAttrsets = {
    inherit lib pkgs;
  };

  namesDirectory = stdenvNoCC.mkDerivation {
    # `__structuredAttrs` turns on passing the values as a JSON file in $NIX_ATTRS_JSON_FILE.
    __structuredAttrs = true;

    # The core values to be passed through.
    nixAttrsetNames = lib.mapAttrs (name: value: attrNames value) nixAttrsets;

    name = "namesDirectory";
    dontUnpack = true;
    nativeBuildInputs = [ jq ];
    installPhase = ''
      mkdir $out
      for symbol in ${concatStringsSep " " (attrNames nixAttrsets)}; do
        jq -r ".nixAttrsetNames.$symbol[]" $NIX_ATTRS_JSON_FILE > $out/$symbol
      done
    '';
  };
in

writeTextFile {
  name = "issue-208242.sh";
  destination = "/bin/issue-208242.sh";
  executable = true;
  derivationArgs = {
    passthru = {
      inherit namesDirectory;
    };
  };
  text = ''
    #!${runtimeShell}
    export PATH=${lib.makeBinPath [ nix git ripgrep nix gnused perl ]}:$PATH
    set -euo pipefail

    NIX_ID_RE="[a-zA-Z_][0-9A-Za-z_'-]*"
    LIB_RE="$(sed -z 's/\n/|/g; s/|$/)/; s/^/(/' ${namesDirectory}/lib)"

    doWork() {
        f=$1

        # Find the top-level `with` statements
        for top in $(rg '^(in )?with ' $f | sed 's/in with //; s/with //; s/;//;'); do

            # We ought to have previously found all the names exported from that attrset.
            names="${namesDirectory}/$top"
            if [ ! -e "$names" ]; then
                echo Cannot find $names in ${namesDirectory}
                exit 1
            fi

            # Have Nix parse the file (no comments) then search through the identifiers for the names
            # that were being accessed through the top-level `with`. The pipeline does this:
            #
            # 1. Remove comments by parsing the nix file
            # 2. Select out just the identifiers (plus keywords)
            # 3. Deduplicate them with `sort` and `uniq`
            # 4. Have `nixfmt` format the expression
            # 5. Replace the top-level `with` with `let ... inherit expr ... in`
            replace="$(nix-instantiate --parse $f | \
                rg -o "$NIX_ID_RE" | \
                rg -xf $names | \
                sort | \
                uniq | \
                perl -0777 -p -e "s/^/let inherit ($top) /; s/\$/; in EOF/" | \
                nixfmt | \
                sed 's/^EOF//')"
            perl -i -p -e "s/^with $top*;/$replace/g" $f

            # Since we replaced the uses at the top level, remove excess with.
            perl -i -p -e "s/with $top;\s*//g" $f
        done

        # Access names from `lib` in just one way.
        perl -0777 -i -p -e "s/lib\.$LIB_RE/\$1/g" $f

        # Combine adjacent `in ... let` scopes.
        perl -0777 -i -p -e 's/in\s*let\s*/\n  /g' $f

        # Make sure that the file still parses.
        while ! nix-instantiate --parse $f > /dev/null; do
            read -p "Press <Return> to re-parse $f "
        done

        # Show the changes
        git diff $f
        echo "Look through $f above"

        # Commit it with a standard commit message.
        read -p "Press <Return> to commit it! "

        # Make sure that the file still parses.
        while ! nix-instantiate --parse $f > /dev/null; do
            read -p "Press <Return> to re-parse $f "
        done

        git commit -m "$(printf 'Avoid top-level `with ...;` in %s' $f)" $f
    }

    ROOT="."

    # If called with an argument, it's a either a file or a directory
    if [ "$#" -ne 0 ]; then
        if [ -f "$1" ]; then
            doWork "$1"
            exit 0
        elif [ -d "$1" ]; then
            ROOT="$1"
        else
            echo "$1 is neither file nor directory"
            exit 1
        fi
    fi

    # Loop through each file, working on it.
    for f in $(rg '^(in )?with ' -l --sort=path -tnix "$ROOT"); do
        doWork $f
    done
  '';
}
