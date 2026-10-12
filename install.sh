#!/usr/bin/env bash
# Link these dotfiles into ~/.config.
#   ~/dotfiles/install.sh
# A folder already in ~/.config is moved aside to <name>.pre-dotfiles rather
# than overwritten, and links that already point here are left alone, so it is
# safe to run again.
set -euo pipefail

here=$(dirname "$(readlink -f "$0")")
config=${XDG_CONFIG_HOME:-$HOME/.config}

git -C "$here" submodule update --init

for source in "$here"/*/; do
	name=$(basename "$source")
	target=$config/$name

	if [ "$(readlink -f "$target" 2>/dev/null)" = "${source%/}" ]; then
		continue
	fi

	if [ -e "$target" ] || [ -L "$target" ]; then
		mv "$target" "$target.pre-dotfiles"
		echo "moved the old $target to $target.pre-dotfiles"
	fi

	mkdir -p "$config"
	ln -s "${source%/}" "$target"
	echo "linked $target"
done

echo "The login screen is installed as root: sudo $here/sddm/install.sh"
