#! /bin/bash 

to_hex() {
    IN="$1"
    xxd -i "$IN" > "$IN.hex"
}

write_bytes() {
    FILE="$1"
    OFFSET="$2"
    BYTES="$3"
    printf "%b" "$BYTES" | dd of="$FILE" conv=notrunc bs=1 seek=$(("$OFFSET"))
}

extract_bytes() {
    IN_PATH="$1"
    OUT_PATH="$2"
    OFFSET="$3"
    BYTES_LEN="$4"
    dd of="$OUT_PATH" if="$IN_PATH" ibs=1 skip=$(("$OFFSET")) count="$BYTES_LEN"
}

HACK_workaround() {
    IN="$1"
    cut -c 2- "$IN" > "$IN.tmp"
    mv "$IN.tmp" "$IN"
    truncate -s -1 "$IN"
}

OUT="$PWD/hello_lib_so.aout"
PT_INTERP_SEGMENT="$PWD/pt_interp.segment"
PT_INTERP_DATA="$PWD/pt_interp.data"

make
cp ./hello_lib_so.so  "$OUT" 

# increase number of program headers by 1 (set it to 0xc)
write_bytes "$OUT" "0x38" "\x0c"

# set entrypoint address
write_bytes "$OUT" "0x18" "\xe9\x10"

to_hex "$OUT"
extract_bytes "../rust-v/hello_c" "$PT_INTERP_SEGMENT" "0x78" 56
to_hex "$PT_INTERP_SEGMENT"
extract_bytes "../rust-v/hello_c" "$PT_INTERP_DATA" "0x318" $((0x1c))
to_hex "$PT_INTERP_DATA"

# write pt_interp segment
write_bytes "$OUT" "0x2A8" "\x03\x00\x00\x00\x04\x00\x00\x00\x18\x03\x00\x00\x00\x00\x00\x00\x18\x03\x00\x00\x00\x00\x00\x00\x18\x03\x00\x00\x00\x00\x00\x00\x1c\x00\x00\x00\x00\x00\x00\x00\x1c\x00\x00\x00\x00\x00\x00\x00\x01\x00\x00\x00\x00\x00\x00\x00"

# write pt interpreter data (path to loader)
write_bytes "$OUT" "0x318" "\x2f\x6c\x69\x62\x36\x34\x2f\x6c\x64\x2d\x6c\x69\x6e\x75\x78\x2d\x78\x38\x36\x2d\x36\x34\x2e\x73\x6f\x2e\x32\x00"
