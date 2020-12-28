# Springer
Modular Arch Linux Installation Scripts

Less famous than the keystone, [springer](https://en.wikipedia.org/wiki/Springer_\(architecture\)) refers to the stones that begin an arch.

## Fair Warning
The `00-erase.zsh` script will aggressively destroy data with no warning or prompt. It is intended for use on a system where all filesystems, partitions, etc need to be erased to prepare for the Arch installation.

In any other cases (dual boot, pre-existing `/home`, etc.), please prepare the drives for partitioning manually.

Definitely be conscious of any external hard drives, flash drives, etc that may be plugged into the system (other than the Arch installation media).

## How to Use Springer
1. Set parameters in `springer.conf`
2. Symlink the example config from `conf.avail` to `conf.d` or add your own custom config to `conf.d`
3. Run `springer`
4. `springer` will immediately prompt for an admin password and will not prompt for anything else (using example config files)*
4. Reboot
5. If Arch fails to boot, `springer-recover` can be used from the Arch installer to restore chroot mounts in `/mnt`

\* the admin password is also used for disk encryption and boot loader

## About the Example Configuration
Currently, the values in `springer.conf` may be changed to suit your system, but everything else is hard coded (for instance, installing the OS on a mirror and `/home` on a 3rd drive is hard coded). So if you were to change the admin user and disk paths in `springer.conf` and add all of the `conf.avail` config to `conf.d`, that should result in a system that boots and has `dwm` available via `startx`.

In the future, the script may be made more configurable, but for now, the example config is intended to be used as-is or changed manually.
