#!/usr/bin/env zsh

# ESP
for drive in "${boot_swap_root_mirror[@]}"; do
  mkfs.vfat -F '32'     \
            -n 'ESP'    \
            "${drive}2"
done

# Boot
mkfs.ext4 -FF -L  'boot'                \
          '/dev/mapper/boot_vg-boot_lv'

# Root
mkfs.ext4 -FF -L  'root'                \
          '/dev/mapper/root_vg-root_lv'

# Var
mkfs.ext4 -FF -L  'var'                 \
          '/dev/mapper/root_vg-var_lv'

# Log
mkfs.ext4 -FF -L  'var_log'                 \
          '/dev/mapper/root_vg-var_log_lv'

# Home
mkfs.ext4 -FF -L  'home'                \
          '/dev/mapper/home_vg-home_lv'

# Chroot mount
mount   '/dev/mapper/root_vg-root_lv'               '/mnt'
mkdir                                               '/mnt/boot'
mount   --options 'rw,relatime,nodev,nosuid'                        \
        '/dev/mapper/boot_vg-boot_lv'               '/mnt/boot'
mkdir                                               '/mnt/var'
mount   --options 'rw,relatime,nodev'                               \
        '/dev/mapper/root_vg-var_lv'                '/mnt/var'
mkdir                                               '/mnt/var/log'
mount   --options 'rw,relatime,nodev,nosuid,noexec'                 \
        '/dev/mapper/root_vg-var_log_lv'            '/mnt/var/log'
mkdir                                               '/mnt/home'
mount   --options 'rw,relatime,nodev,nosuid'                        \
        '/dev/mapper/home_vg-home_lv'               '/mnt/home'
