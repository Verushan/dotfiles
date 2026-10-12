# dotfiles

The configuration for my qtile desktop. Each folder here is linked into
`~/.config` under the same name.

| Folder | For |
| --- | --- |
| `qtile/` | The window manager and its bar - a submodule, [Verushan/qtile](https://github.com/Verushan/qtile) |
| `ghostty/` | Terminal |
| `fish/` | Shell |
| `rofi/` | Launcher and the bar's menus |
| `picom/` | Compositor |
| `sddm/` | Login screen |
| `nvim/` | Editor |
| `gtk-3.0/`, `gtk-4.0/` | GTK appearance |
| `htop/`, `flameshot/` | One settings file each |

## Install

```sh
git clone --recurse-submodules <this repo> ~/dotfiles
~/dotfiles/install.sh
sudo ~/dotfiles/sddm/install.sh   # the login screen, which lives outside $HOME
```

`install.sh` links every folder here into `~/.config`. Anything already there
is moved aside to `<name>.pre-dotfiles`, and it is safe to run again.

## Themes

`theme` in `qtile/config.json` sets the colours for everything: qtile carries
them over to ghostty, fish and rofi whenever it starts or reloads
(`qtile/scripts/apply-theme.py`). Rerun `sudo ~/dotfiles/sddm/install.sh` to
bring the login screen along. `qtile/themes/README.md` covers adding a theme.

## Not in here

- `fish/fish_variables` and the theme files qtile generates
  (`ghostty/qtile.conf`, `rofi/qtile.rasi`) - they are per machine.
- Neovim plugins: lazy.nvim installs them from `nvim/lazy-lock.json` on first
  start.
- `~/.config/environment.d`, which holds API keys. `fish/config.fish` still
  loads it if it is there.

## Changing qtile

qtile is its own repository. Commit and push there first, then record the new
version here:

```sh
git -C ~/dotfiles/qtile push
git -C ~/dotfiles commit qtile -m "Update qtile"
```
