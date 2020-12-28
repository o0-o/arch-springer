#!/usr/bin/env zsh

# What to install
declare -a pacs=()
declare -a keys=()
declare -a aurs=()

# Install SELinux
[ "${mandatory_access_control-}" = 'selinux' ]    &&
{ aurs+=( 'aide-selinux' )
  printf  '%s\n'                            \
          "${maker} ALL=(ALL) NOPASSWD:ALL" >\
          '/mnt/etc/sudoers.d/maker'
  printf  '%s\n'                                                          \
          '#!/usr/bin/env bash'                                           \
          'set -euxo pipefail'                                            \
          'sed --expression '"'"'/^BUILDENV/ s/check/!check/'"'"'  \'     \
          '     "/etc/makepkg.conf"                        >\'            \
          '     "${HOME}/.makepkg.conf"'                                  \
          'sudo pacman --sync --noconfirm git devtools'                   \
          'git clone  "https://github.com/archlinuxhardened/selinux"  \'  \
          '            "${HOME}/selinux"'                                 \
          'cd "${HOME}/selinux"'                                          \
          './recv_gpg_keys.sh'                                            \
          './build_and_install_all.sh'                                    \
          'cd "../"'                                                      \
          'rm --force                       \'                            \
          '   --recursive "${HOME}/selinux"'                              \
          'rm "${HOME}/.makepkg.conf"'                                    >\
          "/mnt${maker_home}/install_selinux.sh"
  chmod '+x' "/mnt${maker_home}/install_selinux.sh"
  declare gcl="${gcl-}security=selinux selinux=1 "
  arch-chroot '/mnt' su "${maker}" --command "${maker_home}/install_selinux.sh"
  arch-chroot '/mnt'  semanage login  --add                   \
                                      --seuser  'staff_u'     \
                                      "${adm_user}"
  sed --in-place                                              \
      --expression  's/ALL$/TYPE=sysadm_t ROLE=sysadm_r ALL/' \
      '/mnt/etc/sudoers.d/wheel'
  rm  "/mnt${maker_home}/install_selinux.sh"
  first_boot_early+=( '/usr/bin/restorecon -v -r /' )
}                                                 ||
[ ! "${mandatory_access_control-}" = 'selinux' ]

# Or Install App Armor
[ "${mandatory_access_control-}" = 'apparmor' ] &&
{ pacs+=( 'apparmor' )
  declare gcl="${gcl-}apparmor=1 lsm=lockdown,yama,apparmor "
}                                                 ||
[ ! "${mandatory_access_control-}" = 'apparmor' ]

# AIDE
printf  '%s' "${aurs[@]}" |
fgrep 'aide-selinux'      ||
{ aurs+=( 'aide' )
  keys+=( '18EE86386022EF57' )
}
declare aide_db='/var/lib/aide/aide.db.gz'
declare aide_db_new='/var/lib/aide/aide.db.new.gz'
first_boot_early+=( '/usr/bin/aide --verbose --init'
                    "/usr/bin/mv ${aide_db_new} ${aide_db}" )

# Install pacman packages
pacstrap  '/mnt'  ${pacs[@]-}

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

# Firewall
# Manually configuring nftables is too much work :(
declare zone='default_gateway'
first_boot_late+=(
  'while [ -z "$( ip route show default )" ]; do sleep 1; done'
  'declare gw_if="$(  ip route show default     |'
  "                   sed -e 's/^.*dev \([[:alnum:]]*\).*$/\1/'    )\""
  'firewall-cmd  --permanent                     \'
  "              --new-zone    '${zone}'         \\"
  '              --set-short   "Default Gateway" \'
  '              --set-target  "DROP"'
  'ip  -brief link             |'
  'cut --delimiter " "         \'
  '    --fields    "1"         |'
  'grep  --invert-match "^lo"  |'
  'while read -r iface; do'
  '  firewall-cmd  --permanent               \'
  '                --zone          "drop"    \'
  '                --add-interface "${iface}"'
  'done'
  'firewall-cmd  --permanent                     \'
  '              --zone              "drop"      \'
  '              --remove-interface  "${gw_if}"'
  'firewall-cmd  --permanent                           \'
  "              --zone          '${zone}'             \\"
  '              --add-rich-rule "rule               \'
  '                              family=ipv4         \'
  '                              source              \'
  "                              address=${adm_net}  \\"
  '                              service             \'
  '                              name=ssh            \'
  '                              accept"               \'
  '              --add-rich-rule "rule               \'
  '                              family=ipv4         \'
  '                              source              \'
  "                              address=${adm_net}  \\"
  '                              icmp-type           \'
  '                              name=echo-request   \'
  '                              accept"'
  'firewall-cmd  --permanent                 \'
  "              --zone          '${zone}'   \\"
  '              --add-interface "${gw_if}"'
  'firewall-cmd  --set-default-zone  "drop"'
  'firewall-cmd  --reload'                                  )
