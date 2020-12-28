#!/usr/bin/env zsh

# What to install
declare -a pacs=( 'xorg-server' 'xorg-xinit' 'xorg-xrandr'
                  'gtk3' 'libvncserver' 'freerdp'
                  'nnn' 'sxiv' 'xclip' 'xss-lock'
                  'alacritty' 'pcmanfm-gtk3' 'vlc' 'remmina'  )
declare -a keys=( )
declare -a aurs=( 'nerd-fonts-meslo'
                  'ipmiview' 'brave-bin' 'firefox-esr-bin'  )

# Install pacman packages
pacstrap  '/mnt'  "${pacs[@]-}"

# Install AUR packages
printf  '%s %s\n'                                     \
        "${maker} ALL=(ALL)"                          \
        'NOPASSWD:/usr/bin/makepkg, /usr/bin/pacman'  >\
        '/mnt/etc/sudoers.d/maker'
for key in ${keys[@]-}; do
  arch-chroot '/mnt'  su "${maker}" --command "gpg --recv-keys ${key}"
done
for aur_pkg in "${aurs[@]}"; do
  arch-chroot '/mnt'  su "${maker}" --command "${aur_installer} ${aur_pkg}"
done

# Enable unprivileged user namespace for browser sandboxing
printf  'kernel.unprivileged_userns_clone=1'  >\
        '/mnt/etc/sysctl.d/00-local-userns.conf'

# Configure Awesome
sed --expression  '/^twm/ { s/^.*$/exec awesome/; q; }' \
    '/mnt/etc/X11/xinit/xinitrc'                        >\
    "/mnt/home/${adm_user}/.xinitrc"
arch-chroot '/mnt'  chown "${adm_user}" "/home/${adm_user}/.xinitrc"
declare awe_cfg="/home/${adm_user}/.config/awesome"
arch-chroot '/mnt'  su "${adm_user}" --command "mkdir --parents '${awe_cfg}'"

# Natural Scrolling
printf  '%s\n'                                        \
        'Section "InputClass"'                        \
        '  Identifier "Scrolling"'                    \
        '  MatchDriver "libinput"'                    \
        '  Option "NaturalScrolling" "true"'          \
        'EndSection'                                  >\
        '/mnt/etc/X11/xorg.conf.d/30-scrolling.conf'
