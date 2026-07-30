# Kanata keyboard remapping

This stow package replaces the active part of `xmodmap/.xmodmap` and adds a
small SpaceFN navigation layer. It intentionally keeps character layout in
IBus/XKB; Kanata handles physical behavior and non-character navigation.

## Install on Arch Linux

Kanata is currently available from the AUR, its official release page, or via
`cargo install kanata`. This setup installs the release executable as
`/usr/local/bin/kanata`.

Allow the logged-in user to read input devices and create a virtual input
device using Kanata's documented Linux setup, then log out and back in. Do not
run an unreviewed configuration as root.

Install `.config/kanata/99-input.rules.example` as
`/etc/udev/rules.d/99-input.rules`, add the user to the `input` and `uinput`
groups, reload udev, and log out and back in.

```sh
cd ~/dotfiles
stow kanata
kanata --check --cfg ~/.config/kanata/kanata.kbd
systemctl --user enable --now kanata.service
journalctl --user -u kanata.service -f
```

Stop it immediately (useful before games or while debugging):

```sh
systemctl --user stop kanata.service
```

Only `Space+h/j/k/l` activate navigation. Every other Space chord emits an
ordinary Space followed by its key, preserving Vim leader mappings such as
`Space+w`.

## Layer reference

Hold Space, then press:

| Keys | Action |
|---|---|
| `h j k l` | Left, Down, Up, Right |

Caps remains Escape, matching the only active mapping in the old xmodmap
file. The commented symbol and Y/Z mappings are not migrated because IBus/XKB
already owns the US/German character layouts.
