#!/usr/bin/env zsh

# Sudo
printf  '%s\n' '%adm ALL=(ALL) ALL' > '/mnt/etc/sudoers.d/adm'

# Prevent password being printed in trace
set +x

# Create admin user
arch-chroot '/mnt'  useradd --create-home                                     \
                            --user-group                                      \
                            --groups      'adm,systemd-journal'               \
                            --shell       '/bin/sh'                           \
                            --password $(openssl passwd -crypt "${password}") \
                            "${adm_user}"

# Add password to luks
yes "${password}"                                                       |
arch-chroot '/mnt'  cryptsetup  luksAddKey  --key-file  '/etc/luks.key' \
                                            '/dev/md/boot_mirror'       ||
[ "${pipestatus[2]}" = 0 ]
yes "${password}"                                                       |
arch-chroot '/mnt'  cryptsetup  luksAddKey  --key-file  '/etc/luks.key' \
                                            '/dev/md/root_mirror'       ||
[ "${pipestatus[2]}" = 0 ]
yes "${password}"                                                       |
arch-chroot '/mnt'  cryptsetup  luksAddKey  --key-file  '/etc/luks.key' \
                                            "${home}1"                  ||
[ "${pipestatus[2]}" = 0 ]

# Re-enable trace
set -x
