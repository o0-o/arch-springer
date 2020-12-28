#!/usr/bin/env zsh

# Firewalld
# Manually configuring nftables is too much work :(
pacstrap '/mnt' 'firewalld'
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
