#!/usr/bin/env zsh

# Install the base OS
declare pacs=(  'base' 'base-devel'
                'linux-hardened' 'linux-firmware'
                'grub' 'mkinitcpio'
                'mdadm' 'lvm2'                    )
grep  --quiet "GenuineIntel"  \
      '/proc/cpuinfo'         &&
pacs+=( 'intel-ucode' )       || :
pacstrap  '/mnt'  "${pacs[@]-}"

# Configure mdadm
mdadm --detail  \
      --scan    >> '/mnt/etc/mdadm.conf'
printf  'MAILADDR root\n' >> '/mnt/etc/mdadm.conf'

# Configure luks
# Transfer keys to chroot
cp  --archive  'luks.key' '/mnt/etc/'
# Add swap and home to crypttab
printf  '%s\t%s\t%s\t%s\n'                                                \
        'swap'                                                            \
        "$( find  -L        '/dev/disk'           \
                  -samefile '/dev/md/swap_mirror' |
            head  --lines   '1'                     )"                    \
        '/dev/urandom'                                                    \
        'swap,cipher=aes-xts-plain64,size=256'                            \
        'home_luks'                                                       \
        "UUID=$( blkid --match-tag 'UUID' --output 'value' "${home}1" )"  \
        '/etc/luks.key'                                                   \
        'luks,discard'                                  >> '/mnt/etc/crypttab'
# Add boot and root to initramfs
printf  '%s\t%s\t%s\t%s\n'                          \
        'boot_luks'                                 \
        "UUID=$(  blkid --match-tag 'UUID'    \
                        --output    'value'   \
                        '/dev/md/boot_mirror'   )"  \
        '/etc/luks.key'                             \
        'luks,discard'                              \
        'root_luks'                                 \
        "UUID=$(  blkid --match-tag 'UUID'    \
                        --output    'value'   \
                        '/dev/md/root_mirror'   )"  \
        '/etc/luks.key'                             \
        'luks,discard'                        >> '/mnt/etc/crypttab.initramfs'

# Configure fstab
genfstab  '/mnt'  >>  '/mnt/etc/fstab'
# Swap is re-encrypted each boot via crypttab
printf  '%s\t%s\t%s\t%s\t%s\t%s\n'  \
        '/dev/mapper/swap'          \
        'none'                      \
        'swap'                      \
        'defaults'                  \
        '0'                         \
        '0'                         >>  '/mnt/etc/fstab'

# Time
arch-chroot '/mnt'  hwclock --systohc
arch-chroot '/mnt'  ln  --symbolic                              \
                        --force                                 \
                        '/usr/share/zoneinfo/America/New_York'  \
                        '/etc/localtime'

# Locale
sed --in-place                            \
    --expression '/#en_US.UTF-8/ s/^#//'  \
    '/mnt/etc/locale.gen'
printf  'LANG=%s.%s'  \
        'en_US'       \
        'UTF-8'       > '/mnt/etc/locale.conf'
printf  'KEYMAP=%s' \
        'us'        > '/mnt/etc/vconsole.conf'

arch-chroot '/mnt'  locale-gen

# Network
cp  --archive                   \
    '/etc/systemd/network/'*    \
    '/mnt/etc/systemd/network/'

# Hostname
printf  '%s' "${hostname}"  > '/mnt/etc/hostname'
printf  '%s\t%s'      \
        '127.0.1.1'   \
        "${hostname}" >>  '/mnt/etc/hosts'

# GPG
install --mode      '700'                   \
        --directory '/mnt/etc/skel/.gnupg'
printf  'keyserver hkps://keyserver.ubuntu.com\n' >\
        '/mnt/etc/skel/.gnupg/dirmngr.conf'
cp  '/mnt/etc/skel/.gnupg/dirmngr.conf' \
    '/mnt/root/.gnupg/'

# Create temporary user for AUR/makepkg
sed --in-place                                                            \
    --expression  '/^#\{,1\}MAKEFLAGS/ s/.*/MAKEFLAGS="-j'"$(nproc)"'"/p' \
    '/mnt/etc/makepkg.conf'
declare maker="z$( uuidgen | cut --delimiter '-' --fields '1' )"
declare maker_home="/home/${maker}"
arch-chroot '/mnt'  useradd --create-home           \
                            --user-group            \
                            --shell       '/bin/sh' \
                            "${maker}"

# Create a simple script to install AURs
pacstrap  '/mnt'  git
declare aur_installer="${maker_home}/install_aur.sh"
printf  '%s\n'                                                      \
        '#!/usr/bin/env bash'                                       \
        'set -euxo pipefail'                                        \
        'git clone "https://aur.archlinux.org/${1}.git"  \'         \
        '          "${HOME}/${1}"'                                  \
        'cd "${HOME}/${1}"'                                         \
        'makepkg --noconfirm --syncdeps --needed --clean --install --skippgpcheck' \
        'cd "../"'                                                  \
        'rm --force --recursive "${HOME}/${1}"'                     >\
        "/mnt${aur_installer}"
chmod '+x' "/mnt${aur_installer}"

declare -a first_boot_early=()
declare -a first_boot_late=()
