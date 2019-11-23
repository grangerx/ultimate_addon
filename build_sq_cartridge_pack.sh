#!/bin/bash -eEuxo pipefail
 
#cart_file=./byog_cartridge_shfs.img
cart_file="$2"
cart_tmp_file=./byog_cartridge_shfs_temp.img
cart_save_file=./byog_cart_saving_ext4.img
squash_mount_point=./squashfs
ext4_saving_mount_point=./saving
cart_saving_size=4M
 
if [ -f "$cart_tmp_file" ]; then
    rm "$cart_tmp_file"
fi
 
if [ -f "$cart_save_file" ]; then
    rm "$cart_save_file"
fi
 
#with gzip, block size set as 256K 
chmod 755 "$1/exec.sh"
mksquashfs "$1" "$cart_tmp_file" -comp gzip -b 262144 -root-owned -nopad

file-size() {
  if [ "$(uname -s)" = Darwin ]; then
    stat -f%z "$1"
  else
    stat -c%s "$1"
  fi
}
 
SQIMGFILESIZE="$(file-size "$cart_tmp_file")"
echo "*** Size of $cart_tmp_file: $SQIMGFILESIZE Bytes (before applying 4k alignment)"
 
REAL_BYTES_USED_DIVIDED_BY_4K="$((SQIMGFILESIZE/4096))"
if  [ "$((SQIMGFILESIZE % 4096))" != 0 ]
then
  REAL_BYTES_USED_DIVIDED_BY_4K=$((REAL_BYTES_USED_DIVIDED_BY_4K+1))
fi
REAL_BYTES_USED=$((REAL_BYTES_USED_DIVIDED_BY_4K*4096))
 
dd if=/dev/zero bs=1 count="$((REAL_BYTES_USED-SQIMGFILESIZE))" >> "$cart_tmp_file"
 
SQIMGFILESIZE="$(file-size "$cart_tmp_file")"
echo "*** Size of $cart_tmp_file: $SQIMGFILESIZE Bytes (after applying 4k alignment)"
 
my_md5string_hex_file=./my_md5string_hex.bin

# TODO
#  * oflag append is not portable
#  * stat is not portable
#  * md5sum is not portable
 
# header padding 64 bytes
EXT4FILE_OFFSET=$((SQIMGFILESIZE+64));
echo "*** Offset of Ext4 partition for file saving would be: $EXT4FILE_OFFSET"

# macOS and BSDs use md5(1)
if ! which md5sum && which md5; then
  md5sum() {
    md5 "$@"
  }
fi
 
md5=$(md5sum "$cart_tmp_file" | cut -d ' '  -f 1)
echo "*** SQFS Partition MD5 Hash: "$md5""
echo "$md5" | xxd -r -p > "$my_md5string_hex_file"
dd if="$my_md5string_hex_file" ibs=16 count=1 obs=16 conv=notrunc >> "$cart_tmp_file"
dd if=/dev/zero ibs=16 count=2 obs=16 conv=notrunc >> "$cart_tmp_file"
 
if [ -e "$my_md5string_hex_file" ]; then
    rm "$my_md5string_hex_file"
fi
 
truncate -s "$cart_saving_size" "$cart_save_file"
mkfs.ext4 "$cart_save_file"
debugfs -R 'mkdir upper' -w "$cart_save_file"
debugfs -R 'mkdir work' -w "$cart_save_file"
 
md5="$(md5sum "$cart_save_file" | cut -d ' '  -f 1)"
echo "*** Ext4 Partition MD5 Hash: "$md5""
echo "$md5" | xxd -r -p > "$my_md5string_hex_file"
dd if="$my_md5string_hex_file" ibs=16 count=1 obs=16 conv=notrunc >> "$cart_tmp_file"
 
#bind files together
cat "$cart_tmp_file" "$cart_save_file" > "$cart_file"
 
if [ -f "$my_md5string_hex_file" ]; then
    rm "$my_md5string_hex_file"
fi
 
if [ -f "$cart_tmp_file" ]; then
    rm "$cart_tmp_file"
fi
 
if [ -f "$cart_save_file" ]; then
    rm "$cart_save_file"
fi
