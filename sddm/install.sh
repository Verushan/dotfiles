#!/usr/bin/env bash
# Install the qtile SDDM theme, in the colours of a qtile theme, and make it
# the login screen.
#   sudo ~/.config/sddm/install.sh [theme]
# The theme defaults to the one in ~/.config/qtile/config.json, so after
# switching qtile's theme, run this again to bring the login screen along.
# It copies, it does not link, since the sddm user cannot read into this home
# directory.
set -euo pipefail

[ "$(id -u)" -eq 0 ] || { echo "run with sudo" >&2; exit 1; }

here=$(dirname "$(readlink -f "$0")")
source=$here/themes/qtile
qtile=$(readlink -f "$here/../qtile")
target=/usr/share/sddm/themes/qtile
conf=/etc/sddm.conf.d/20-qtile.conf

theme=${1:-$(python3 -c 'import json, sys; print(json.load(open(sys.argv[1]))["theme"])' "$qtile/config.json")}
palette=$qtile/themes/$theme.json
[ -f "$palette" ] || { echo "no such qtile theme: $palette" >&2; exit 1; }

rm -rf "$target"
install -d "$target"
install -m 644 "$source"/Main.qml "$source"/metadata.desktop "$target"/

background=
if [ -f "$source/background-$theme.jpg" ]; then
	background=background.jpg
	install -m 644 "$source/background-$theme.jpg" "$target/$background"
fi

# theme.conf, with the picture and the qtile theme's colours filled in. rule
# and hint are the bar's own dimmed text: shade("light", 0.35) in widgets.py,
# and a touch brighter for placeholders.
python3 - "$source/theme.conf" "$palette" "$background" >"$target/theme.conf" <<'PY'
import json, sys

conf, palette, background = sys.argv[1:]
colours = {k: v[0] if isinstance(v, list) else v for k, v in json.load(open(palette)).items()}

def shade(colour, factor):
    top, bottom = (bytes.fromhex(c.lstrip("#")) for c in (colour, colours["dark"]))
    return "#" + bytes(round(t * factor + b * (1 - factor)) for t, b in zip(top, bottom)).hex()

colours["rule"] = shade(colours["light"], 0.35)
colours["hint"] = shade(colours["light"], 0.42)

for line in open(conf).read().splitlines():
    print(f"background={background}" if line.startswith("background=") else line)

print(f"\n# Colours from {palette}")
for key in ("dark", "grey", "light", "focus", "urgent", "active", "inactive",
            "color1", "color2", "color4", "color5", "color6", "rule", "hint"):
    print(f'{key}="{colours[key]}"')
PY
chmod 644 "$target/theme.conf"

# The theme used to be installed under its first palette's name.
rm -rf /usr/share/sddm/themes/kanagawa-dragon /etc/sddm.conf.d/20-kanagawa-dragon.conf

# conf.d files are read in order, so this overrides 10-endeavouros.conf.
# That file also turns on qtvirtualkeyboard, which puts an on-screen keyboard
# over half the screen whenever the password box takes focus; clear it.
cat > "$conf" <<'CONF'
[Theme]
Current=qtile
CursorTheme=breeze_cursors
CursorSize=24

[General]
InputMethod=
CONF

echo "installed $target in $theme"
echo "wrote $conf"
echo "takes effect at the next login screen (log out, or: sudo systemctl restart sddm)"
