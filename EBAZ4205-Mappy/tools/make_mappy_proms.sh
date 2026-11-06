#!/bin/bash
# Generate the PROM VHDL from the Mappy romset into ../proms/ (port of
# make_mappy_proms.bat):
#   1. compile make_vhdl_prom into tools_prom_src/bin/
#   2. unzip ROMZIP (comma-separated) or ${ROMDIR:-~/roms}/mappy.zip into unzip/
#   3. write the PROM VHDL into ../proms/
#   4. create ../proms/.done, a marker file the Makefile checks before a bitstream build
set -euo pipefail

HERE="$(cd "$(dirname "$0")" && pwd)"
PROM_DIR="$HERE/../proms"
UNZIP="$HERE/unzip"
TOOL="$HERE/tools_prom_src/bin/make_vhdl_prom"

if [ -n "${ROMZIP:-}" ]; then
    IFS=, read -r -a romzips <<< "$ROMZIP"
else
    romzips=("${ROMDIR:-$HOME/roms}/mappy.zip")
fi
for z in "${romzips[@]}"; do
    if [ ! -f "$z" ]; then
        echo "error: romset not found: $z (set ROMDIR or ROMZIP)" >&2
        exit 1
    fi
done

mkdir -p "$(dirname "$TOOL")" "$UNZIP" "$PROM_DIR"
gcc -w "$HERE/tools_prom_src/src/make_vhdl_prom.c" -lm -o "$TOOL"

for z in "${romzips[@]}"; do
    unzip -q -o "$z" -d "$UNZIP"
done
cd "$UNZIP"

prom() {
    "$TOOL" "$1" "$2"
    mv -f "$2" "$PROM_DIR/$2"
}

cat mpx_3.1d mpx_3.1d mp1_2.1c mpx_1.1b > cpu1_rom.bin
cat mp1-7.5k mp1-7.5k mp1-7.5k mp1-7.5k > spclut_rom.bin
cat mp1_6.3m mp1_6.3m > sprite0_rom.bin
cat mp1_7.3n mp1_7.3n > sprite1_rom.bin

prom mp1-5.5b clut_rom.vhd
prom mp1-6.4c char_rom.vhd
prom spclut_rom.bin spclut_rom.vhd
prom mp1-3.3m snd_rom.vhd

prom mp1_5.3b gfx1_rom.vhd
prom sprite0_rom.bin sprite0_rom.vhd
prom sprite1_rom.bin sprite1_rom.vhd

prom cpu1_rom.bin cpu1_rom.vhd
prom mp1_4.1k cpu2_rom.vhd

touch "$PROM_DIR/.done"
echo "PROM VHDL in $PROM_DIR:"
ls -1 "$PROM_DIR"
