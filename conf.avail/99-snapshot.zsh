#!/usr/bin/env zsh

# Take a pre-boot snapshot of the OS
declare snap_time="$(date +"%Y-%m-%d-%H-%M-%S")"
lvs --noheadings                                                            \
    --option      'lv_path'                                                 \
    '@os'                                                                   |
while read -r lv; do
  declare size="$(  df  --block-size='1K'                             \
                        --exclude-type='tmpfs'                        \
                        --exclude-type='devtmpfs'                     \
                        --output='source,used'                        |
                    tail  --lines '+2'                                |
                    fgrep $(  lvs --noheadings                    \
                                  --option      'vg_name,lvname'  \
                                  --separator   '-'               \
                                  "${lv}"                           ) |
                    awk '{ print $2 }'                                  )K"
  lvcreate  --snapshot                            \
            --name      "${lv##*/}_${snap_time}"  \
            --size      "${size}"                 \
            --addtag    "${snap_time}"            \
            --addtag    "$(uname -r)"             \
            "${lv}"
done
