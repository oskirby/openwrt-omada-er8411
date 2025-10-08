
. /lib/functions.sh
. /lib/upgrade/common.sh
. /lib/upgrade/nand.sh
. /usr/share/libubox/jshn.sh

dkmgt_extraparam_get_score() {
    local partname="$1"
	local ubidev="$(nand_find_ubi ${CI_UBIPART})"
	local ubivol="$(nand_find_volume $ubidev $partname)"
    if [ ! "$ubivol" ]; then
		echo "ERROR: UBI volume \"$partname\" not found" >&2
        return 1
    fi

    local magic=$(dd if=/dev/$ubivol bs=8 count=1 2>/dev/null | hexdump -v -n 8 -e '1/1 "%02x"')
    if [ "$magic" != "aa55d98f04e955aa" ]; then
		echo "ERROR: UBI volume \"$partname\" has invalid magic" >&2
        return 1
    fi
    local size=$(dd if=/dev/$ubivol bs=4 count=1 skip=2 2>/dev/null | hexdump -v -n 4 -e '1/1 " %d"' |
                 awk '{ print $1 * 16777216 + $2 * 65536 + $3 * 256 + $4}')
    json_load "$(dd if=/dev/$ubivol bs=1 count=$size skip=16 2>/dev/null)"
	json_get_var fwflag fwFlag
    json_get_var score score
    if [ "$fwflag" != "GOOD" ]; then
        score="0"
    fi
    echo "$score"
    return 0
}

dkmgt_extraparam_encode_score() {
    local score="$1"
    local filename="$2"

    json_init
    json_add_string "dbootFlag" "1"
    json_add_string "integerFlag" "1"
    json_add_string "fwFlag" "GOOD"
    json_add_int "score" "$score"
    json_close_object
    json_dump | dd of="$filename" bs=1 seek=16 2>/dev/null

    local size=$(dd if="$filename" bs=1 skip=16 2>/dev/null | wc -c)
    data_2bin $(printf "aa55d98f04e955aa%08x00000000" $size) | dd of="$filename" bs=16 count=1 seek=0 conv=notrunc 2>/dev/null
}

platform_pre_upgrade_tplink_dkmgt() {
    # Find the boot partition with the highest score.
    local primary_score=$(dkmgt_extraparam_get_score "extra-para")
    local backup_score=$(dkmgt_extraparam_get_score "extra-para.b")
    v "Primary boot score: $primary_score"
    v "Backup boot score: $backup_score"

    # Prepare an updated boot configuration to select the primary partition.
    local new_score=1
    if [ "$primary_score" -ge "$new_score" ]; then
        new_score=$(expr $primary_score + 1)
    fi
    if [ "$backup_score" -ge "$new_score" ]; then
        new_score=$(expr $backup_score + 1)
    fi
    dkmgt_extraparam_encode_score "$new_score" /tmp/dkmgt-extra-para.bin
}

platform_do_upgrade_tplink_dkmgt() {
    # Instruct the bootloader to use the primary boot partition after successful sysupgrade
    if nand_upgrade_tar "$1"; then
        v "Selecting primary boot partition"
        local partname="extra-para"
        local ubidev=$(nand_find_ubi ${CI_UBIPART})
        local ubivol=$(nand_find_volume $ubidev $partname)
        if [ ! "$ubivol" ]; then
            echo "UBI volume \"$partname\" not found" >&2
        else
            v "Writing: /dev/$ubivol /tmp/dkmgt-extra-para.bin"
            ubiupdatevol /dev/$ubivol /tmp/dkmgt-extra-para.bin
        fi

        nand_do_upgrade_success
    fi

    nand_do_upgrade_failed
}
