#!/usr/bin/env zsh

# What to install
declare -a pacs=( 'linux-lts' 'man-db' 'pkgfile'
                  'perl' 'tcl' 'expect' 'python3' 'ruby'
                  'go' 'jre-openjdk-headless'
                  'postfix' 's-nail' 'smartmontools'
                  'dmidecode' 'sysstat' 'strace'
                  'zsh' 'tmux' 'neovim' 'rsync' 'ipmitool'    )
arch-chroot '/mnt'  command -v ssh >/dev/null || pacs+=( 'openssh' )
#selinux installs conflicting openssh package
declare -a keys=( '3FEF9748469ADBE15DA7CA80AC2D62742012EA22' ) #1password
declare -a aurs=( 'yay' '1password-cli' )

# Install pacman packages
pacstrap  '/mnt'  ${pacs[@]-}
# Boot into linux-hardened by default
sed --in-place                                \
    --expression  '/GRUB_DEFAULT=/ s/=.*/=2/' \
    '/mnt/etc/default/grub'

# Install AUR packages
printf  '%s %s\n'                                     \
        "${maker} ALL=(ALL)"                          \
        'NOPASSWD:/usr/bin/makepkg, /usr/bin/pacman'  >\
        '/mnt/etc/sudoers.d/maker'
for key in ${keys[@]}; do
  arch-chroot '/mnt'  su "${maker}" --command "gpg --recv-keys ${key}"
done
for aur_pkg in "${aurs[@]}"; do
  arch-chroot '/mnt'  su "${maker}" --command "${aur_installer} ${aur_pkg}"
done

# Update package search data
arch-chroot '/mnt'  yay --files --refresh
arch-chroot '/mnt'  pkgfile --update

# Update sysadmin
arch-chroot '/mnt'  usermod --shell '/bin/zsh'  \
                            "${adm_user}"
sed --in-place                                \
    --expression  '/#root:[[:space:]]*you/ a\
root:\t\t'"${adm_user}"                       \
    '/mnt/etc/postfix/aliases'
arch-chroot '/mnt'  newaliases

# Configure smartd short test between 1-2AM daily and long test between
# 3-4AM Saturdays on all SMART-enabled drives
printf  '%s (%s) - %s\n'                            \
        'DEVICESCAN -a -o on -S on -n standby,q -s' \
        'S/../.././01|L/../../6/03'                 \
        '-W 4,35,40 -m root'                        >>\
        '/mnt/etc/smartd.conf'
