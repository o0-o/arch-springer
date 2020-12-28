#!/usr/bin/env zsh

# First boot scripts
# Early (before network)
printf  '%s\n'                                                      \
        '#!/usr/bin/env bash'                                       \
        'set -euxo pipefail'                                        \
        "export PATH='/usr/bin:/usr/sbin:/bin:/sbin'"               \
        "${first_boot_early[@]-}"                                   \
        '/usr/bin/systemctl disable first-boot-early.service'       \
        '/usr/bin/rm /etc/systemd/system/first-boot-early.service'  \
        '/usr/bin/rm ${0}'                                          >>\
        '/mnt/usr/local/bin/first-boot-early'
chmod '+x' '/mnt/usr/local/bin/first-boot-early'
printf  '%s\n'                                              \
        '[Unit]'                                            \
        'Description=First Boot Early Configuration'        \
        'After=sysinit.target'                              \
        ''                                                  \
        '[Service]'                                         \
        'Type=oneshot'                                      \
        'ExecStart=/usr/local/bin/first-boot-early'         \
        'TimeoutSec=600'                                    \
        'StandardOutput=journal+console'                    \
        'StandardError=journal+console'                     \
        ''                                                  \
        '[Install]'                                         \
        'WantedBy=network.target'                           >\
        '/mnt/etc/systemd/system/first-boot-early.service'
# Late (after firewalld)
printf  '%s\n'                                                    \
        '#!/usr/bin/env bash'                                     \
        'set -euxo pipefail'                                      \
        "export PATH='/usr/bin:/usr/sbin:/bin:/sbin'"             \
        "${first_boot_late[@]-}"                                  \
        '/usr/bin/systemctl disable first-boot-late.service'      \
        '/usr/bin/rm /etc/systemd/system/first-boot-late.service' \
        '/usr/bin/rm ${0}'                                        >>\
        '/mnt/usr/local/bin/first-boot-late'
chmod '+x' '/mnt/usr/local/bin/first-boot-late'
printf  '%s\n'                                            \
        '[Unit]'                                          \
        'Description=First Boot Late Configuration'       \
        'After=firewalld.service'                         \
        ''                                                \
        '[Service]'                                       \
        'Type=oneshot'                                    \
        'ExecStart=/usr/local/bin/first-boot-late'        \
        'StandardOutput=journal+console'                  \
        'StandardError=journal+console'                   \
        ''                                                \
        '[Install]'                                       \
        'WantedBy=multi-user.target'                      >\
        '/mnt/etc/systemd/system/first-boot-late.service'

# Allow some enable to fail in case you've commented out a section above
arch-chroot '/mnt'  systemctl enable first-boot-early.service
arch-chroot '/mnt'  systemctl enable first-boot-late.service
arch-chroot '/mnt'  systemctl enable systemd-networkd.service
arch-chroot '/mnt'  systemctl enable systemd-resolved.service
arch-chroot '/mnt'  systemctl enable apparmor.service         || :
arch-chroot '/mnt'  systemctl enable firewalld.service        || :
arch-chroot '/mnt'  systemctl enable sshd.service             || :
arch-chroot '/mnt'  systemctl enable postfix.service          || :
arch-chroot '/mnt'  systemctl enable smartd.service           || :
arch-chroot '/mnt'  systemctl enable clamav-freshclam.service || :
arch-chroot '/mnt'  systemctl enable clamav-daemon.service    || :
arch-chroot '/mnt'  systemctl enable fangfrisch.timer         || :
arch-chroot '/mnt'  systemctl enable clamav-clamdscan.timer   || :
