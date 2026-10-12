# dotfiles

The configuration for my qtile desktop: window manager, terminal, shell,
launcher, compositor, login screen and editor, all in one theme.

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

## How it is set up

Programs look for their settings in `~/.config/<program>`. The real files live
here in `~/dotfiles`, and each `~/.config/<program>` is a **symlink** - a
signpost that sends anything opening it on to the folder here:

```
~/.config/                           ~/dotfiles/           (the git repository)
├── fish     ──────────────────────▶ ├── fish/
├── ghostty  ──────────────────────▶ ├── ghostty/
├── nvim     ──────────────────────▶ ├── nvim/
├── qtile    ──────────────────────▶ ├── qtile/            (a submodule)
├── rofi     ──────────────────────▶ ├── rofi/
├── ...                              ├── ...
├── environment.d/   (a real folder, not in the repo)
└── kdeglobals       (and everything else: untouched)
```

So there is only ever one copy of each file. Opening
`~/.config/fish/config.fish` and `~/dotfiles/fish/config.fish` opens the same
file, and an edit through either path shows up in `git status` here. Programs
cannot tell the difference, and nothing else in `~/.config` is affected.

You can see the links with:

```sh
ls -l ~/.config | grep dotfiles
# fish -> /home/<you>/dotfiles/fish
# ...
```

### The exceptions

- **The login screen is copied, not linked.** SDDM runs as its own user before
  you log in and cannot read your home folder, so `sddm/install.sh` copies the
  theme into `/usr/share/sddm/themes/qtile` as root. After changing anything in
  `sddm/` - or switching qtile's theme - run it again:
  `sudo ~/dotfiles/sddm/install.sh`.
- **qtile is a separate repository** inside this one (a git *submodule*). This
  repository records which qtile commit to use, not qtile's files themselves.
  See [Changing qtile](#changing-qtile).
- **Some files are made on each machine** and are left out by `.gitignore`:
  `fish/fish_variables` (fish's saved state), and `ghostty/qtile.conf` and
  `rofi/qtile.rasi`, which qtile writes for whichever theme is current.

## Setting up another machine

1. **Install the programs.** On Arch:

   ```sh
   sudo pacman -S git fish ghostty rofi picom neovim sddm breeze-gtk \
       qtile python-psutil ttf-jetbrains-mono-nerd
   ```

   `qtile/README.md` lists what the bar's widgets and menus use on top of that
   (`feh`, `imagemagick`, `networkmanager`, `bluez-utils`, `pavucontrol`, ...).

2. **Clone this repository with its submodule:**

   ```sh
   git clone --recurse-submodules <this repo's URL> ~/dotfiles
   ```

   qtile's submodule is fetched over SSH (`git@github.com:...`). On a machine
   without a GitHub SSH key, have git use HTTPS instead, then clone:

   ```sh
   git config --global url."https://github.com/".insteadOf git@github.com:
   ```

3. **Link everything into `~/.config`:**

   ```sh
   ~/dotfiles/install.sh
   ```

   For every folder in `~/dotfiles`, this makes `~/.config/<folder>` a link to
   it. If something is already at that path - say the default fish config - it
   is moved aside to `~/.config/<folder>.pre-dotfiles`, never deleted. Links
   that are already right are left alone, so it is safe to run again.

4. **Install the login screen:** `sudo ~/dotfiles/sddm/install.sh`, then
   `sudo systemctl enable sddm` if SDDM is not already your display manager.

5. **Make fish your shell:** `chsh -s /usr/bin/fish`.

6. **Put back what is not in here** (see [Not in here](#not-in-here)), such as
   `~/.config/environment.d` and a folder of wallpapers.

7. **Log out and pick the qtile session** on the login screen. Neovim
   installs its plugins the first time it opens.

### Using only some of it

To take, say, just the rofi and ghostty config, skip `install.sh` and link the
folders you want by hand:

```sh
ln -s ~/dotfiles/rofi ~/.config/rofi
ln -s ~/dotfiles/ghostty ~/.config/ghostty
```

Move any existing `~/.config/rofi` out of the way first - `ln` will not
replace a folder.

Their colours come from qtile's theme, written out each time qtile starts.
Without qtile running, write them once yourself - it only needs the `qtile/`
folder to be there, not qtile itself:

```sh
~/dotfiles/qtile/scripts/apply-theme.py
```

## Day to day

Edit the configs as usual, through `~/.config` or here, then commit here:

```sh
cd ~/dotfiles
git status
git commit -am "Describe the change"
git push
```

### Switching theme

Set `theme` in `qtile/config.json` (`kanagawa-dragon`, `catppuccin-mocha` or
`nord`) and reload qtile with `Mod+Ctrl+R`: ghostty, fish and rofi follow.
Then `sudo ~/dotfiles/sddm/install.sh` for the login screen.

### Changing qtile

qtile has its own history and its own GitHub repository, so it is committed in
two steps - first in qtile, then here, to record which qtile version these
dotfiles use:

```sh
cd ~/dotfiles/qtile
git commit -am "Describe the change"
git push                       # push qtile first, or another machine
                               # cannot fetch the commit recorded here
cd ~/dotfiles
git commit qtile -m "Update qtile"
```

On another machine, `git pull --recurse-submodules` brings both up to date.

### Adding another program's config

```sh
mv ~/.config/kitty ~/dotfiles/kitty        # move the real folder in
ln -s ~/dotfiles/kitty ~/.config/kitty     # leave a link in its place
cd ~/dotfiles && git add kitty && git commit -m "Add kitty"
```

Check it for passwords and API keys before committing.

### Taking a program back out

```sh
rm ~/.config/kitty                         # removes only the link
mv ~/dotfiles/kitty ~/.config/kitty        # the real folder goes back
cd ~/dotfiles && git commit -am "Remove kitty"
```

## Not in here

- **`~/.config/environment.d`** holds API keys, so it stays out of git. Copy it
  across yourself; `fish/config.fish` loads it if it is there.
- **Neovim plugins.** lazy.nvim installs them from `nvim/lazy-lock.json`.
- **Wallpapers.** `qtile/autostart.sh` names the folder it picks from.
- **`fish_variables`** and the generated theme files - see
  [The exceptions](#the-exceptions).
- **Backups** (`*.bak`, `*.before-*`) stay next to the files they back up, but
  are not committed.

## If something looks wrong

- **A program has lost its settings:** check its link with
  `ls -l ~/.config/<program>`. If it points at a folder that no longer exists -
  say `~/dotfiles` was moved - run `install.sh` again from the new location.
- **Your old config went missing after `install.sh`:** it is in
  `~/.config/<program>.pre-dotfiles`.
- **`~/dotfiles/qtile` is empty:** `git submodule update --init`.
- **GTK apps look wrong:** `gtk-4.0/gtk.css` links to the system Breeze-Dark
  theme, which comes from the `breeze-gtk` package.
