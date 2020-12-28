#!/usr/bin/env zsh

# mkinitcpio
declare files='/etc/luks.key'
declare hooks='base systemd autodetect keyboard sd-vconsole modconf block'
declare hooks="${hooks} mdadm_udev sd-encrypt sd-lvm2 filesystems fsck"
sed --in-place                                          \
    --expression  '/^FILES/   s|(.*)$|('"${files}"')|'  \
    --expression  '/^HOOKS/   s/(.*)$/('"${hooks}"')/'  \
    --expression  '/^#COMPRESSION="zstd"/ a\
COMPRESSION="cat"'                                          \
        '/mnt/etc/mkinitcpio.conf'
arch-chroot '/mnt'  mkinitcpio  --allpresets

# dracut
# dracut wasn't functional for me, will try again in the future
#pacstrap  '/mnt'  dracut
#arch-chroot '/mnt'  su "${maker}" --command "${aur_installer} dracut-hooks"
#printf  '%s\n'  'hostonly="yes"'          \
#                'compress="cat"'          \
#                'hostonly_cmdline="yes"'  >\
#        '/mnt/etc/dracut.conf.d/00-default.conf'
#printf  '%s\n'  'install_items+="/etc/luks.key"' >\
#        '/mnt/etc/dracut.conf.d/10-luks.conf'
#reinstall kernels will regenerate initramfs
#pacstrap  '/mnt'  linux-hardened linux-lts

# Grub
declare gcl="${gcl-}audit=1 "
declare gcl="${gcl-}loglevel=3 "
declare gcl="${gcl-}quiet"
sed --in-place                                                            \
    --expression  '/GRUB_ENABLE_CRYPTODISK=/      s/^#//'                 \
    --expression  '/GRUB_CMDLINE_LINUX_DEFAULT=/  s|".*"$|"'"${gcl}"'"|'  \
    '/mnt/etc/default/grub'
printf  '%s\n'  'GRUB_DISABLE_SUBMENU=y'  >>\
        '/mnt/etc/default/grub'
# Install
for dev in "${boot_swap_root_mirror[@]}"; do
  arch-chroot '/mnt'  grub-install  --target  'i386-pc' \
                                    "${dev}"
done
# Set Password
printf  '%s\n%s\n%s\n%s'                                                      \
        "echo 'menuentry_id_option=\"--unrestricted \$menuentry_id_option\"'" \
        "echo 'export menuentry_id_option'"                                   \
        "echo 'set superusers=\"${adm_user}\"'"                               \
        "echo 'password_pbkdf2 ${adm_user} "                                 >\
        '/mnt/etc/grub.d/01_users'
set +x
arch-chroot '/mnt' su --command 'yes "'"${password}"'"  |
                                grub-mkpasswd-pbkdf2'     |
tail  --lines '1'                                         |
awk '{print $NF "'\''"}'                                  >>\
'/mnt/etc/grub.d/01_users'
set -x
chmod '0700' '/mnt/etc/grub.d/01_users'
# Generate config
arch-chroot '/mnt'  grub-mkconfig --output  '/boot/grub/grub.cfg'
