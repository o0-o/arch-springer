#!/usr/bin/env zsh

pacstrap  '/mnt'  clamav
arch-chroot '/mnt' su "${maker}" --command "${aur_installer} python-fangfrisch"

arch-chroot '/mnt' freshclam
arch-chroot '/mnt' sudo --user 'clamav'                                       \
                   fangfrisch initdb --conf '/etc/fangfrisch/fangfrisch.conf'
declare ALERT_CMD='{ echo "Subject: $(hostname -f) '
declare ALERT_CMD="${ALERT_CMD}"'CLAMAV ALERT:%v"; '
declare ALERT_CMD="${ALERT_CMD}"'log show --predicate '
declare ALERT_CMD="${ALERT_CMD}'"'(process == "clamd")'"' "
declare ALERT_CMD="${ALERT_CMD}"'--info --last 1m '
declare ALERT_CMD="${ALERT_CMD}"'--style syslog; } | '
declare ALERT_CMD="${ALERT_CMD}"'/usr/sbin/sendmail -F clamd root'
sed --in-place                                                  \
    --expression  '/^Example/                 s/^/#/'           \
    --expression  '/^#LogSyslog/              s/^#//'           \
    --expression  '/^#LocalSocket[[:space:]]/ s/^#//'           \
    --expression  '/^#LocalSocketMode/        s/^#//'           \
    --expression  '/^#ExcludePath/            s/^#//'           \
    --expression  '/^# Default: scan all/ a\
ExcludePath ^/dev/'                                             \
    --expression  's/^#\(MaxDirectoryRecursion\).*/\1 0/'       \
    --expression  's@^#\(VirusEvent\).*$@\1 '"${ALERT_CMD}"'@'  \
    --expression  '/^#ExitonOOM/              s/^#//'           \
    '/mnt/etc/clamav/clamd.conf'
printf  '%s\n'                                            \
        '[Unit]'                                          \
        'Description=Weekly Virus Scan'                   \
        ''                                                \
        '[Timer]'                                         \
        'OnCalendar=weekly'                               \
        'Unit=clamav-clamdscan.service'                   \
        'RandomizedDelaySec=1h'                           \
        ''                                                \
        '[Install]'                                       \
        'WantedBy=timers.target'                          >\
        '/mnt/etc/systemd/system/clamav-clamdscan.timer'
printf  '%s\n'                                              \
        '[Unit]'                                            \
        'Description=Virus Scan'                            \
        'Requires=clamav-daemon.service'                    \
        ''                                                  \
        '[Service]'                                         \
        'Type=simple'                                       \
        'ExecStart=/usr/bin/clamdscan --multiscan /'        \
        'Nice=20'                                           \
        ''                                                  \
        '[Install]'                                         \
        'WantedBy=multi-user.target'                        >\
        '/mnt/etc/systemd/system/clamav-clamdscan.service'
