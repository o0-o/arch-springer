#!/usr/bin/env zsh

# Delete temporary AUR/makepkg user
arch-chroot '/mnt'  userdel --force     \
                            --remove    \
                            "${maker}"
rm  '/mnt/etc/sudoers.d/maker' || :
