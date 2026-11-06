# Mappy - Digilent Basys 3

Mappy (1983 Namco), FPGA core by MiSTer-X, MC6809 by Greg Miller, based on EBAZ4205 port
by pinballwiz.org (<https://github.com/pinballwizz/EBAZ4205-Mappy>).

## Hardware

- Digilent Basys 3 (Artix-7 `xc7a35tcpg236-1`).
- VGA monitor (31 kHz), or a 15 kHz TV/CRT (sw13, not tested).
- USB keyboard on the Basys 3 USB-HID host port.
- Optional: Atari-style joystick on Pmod JA, Digilent PmodAMP2 on Pmod JXADC.

## Build

Requirements:

- Vivado 2020.2, gcc, make, unzip, openFPGALoader.
- Romset `mappy.zip`.

```
make roms        # compile make_vhdl_prom, unzip ~/roms/mappy.zip, write PROM VHDL
make bitstream   # Vivado batch build of basys3/mappy_basys3.xpr
make load        # program the xc7 in JTAG mode (jumper JP1 in the JTAG position)
make clean       # remove roms, PROM VHDL and Vivado outputs
```

- `ROMDIR=<dir>` or `ROMZIP=<zip>` selects the romset.
- `VIVADO=<path>` selects the Vivado binary.

## IO

| Input           | Function                                      |
|-----------------|-----------------------------------------------|
| Arrow keys      | move                                          |
| Left Ctrl       | door                                          |
| 1 / 2           | start 1 player / 2 players                    |
| 5               | coin                                          |
| btnU, btnD      | coin                                          |
| btnL / btnR     | start 1 player / 2 players                    |
| btnC            | reset                                         |
| JA 1/2/3/4/7    | joystick right/left/down/up/door (active low) |
| sw0-sw9         | DIP switches (down = default, see below)      |
| sw12 up         | test mode                                     |
| sw13 down       | 31 kHz VGA                                    |
| sw13 up         | 15 kHz TV, composite sync on HS (not tested)  |
| sw14 up         | scanlines, alternate lines at 50 %, 31 kHz    |
| sw15 up         | audio off (PmodAMP2 shutdown)                 |

DIP switches. The core orders the DIP inputs for Druaga, so each switch sets the Mappy
setting below:

| Switch | Setting                                 |
|--------|-----------------------------------------|
| sw0    | bonus life, bit 0                       |
| sw1    | coin B, bit 1                           |
| sw2    | demo sounds                             |
| sw3    | rack test                               |
| sw4    | freeze                                  |
| sw5    | bonus life, bit 1                       |
| sw6    | bonus life, bit 2                       |
| sw7    | lives (3/5)                             |
| sw8    | difficulty, bit 1                       |
| sw9    | difficulty, bit 2 (also cocktail table) |

## Clock

The core runs from one 49.155 MHz MMCM clock (original board 49.152 MHz) from which 24, 12
and 6 MHz are derived to run the 6809 E and Q clocks and the sound generator clocks. These
are called out explicitly in the Vivado XDC constraints because occasionally the game was
locking up after the power-on test. Converting to clock enables on the master clock
is in the backlog for investigation.

## Core changes for the Basys 3 port

None. The core files in `rtl/` are unchanged from the EBAZ4205 project.

## Third-party additions

- `tools/tools_prom_src/src/make_vhdl_prom.c` (darfpga): PROM-to-VHDL converter,
  unmodified, from <https://github.com/pinballwizz/DE2-Xevious>.

## License

- The additions and changes made for the Basys 3 port are MIT licensed.
- Core files (`rtl/*.v`): (c) 2007 MiSTer-X, MC6809 (`rtl/mc6809/`) (c) 2016 Greg
  Miller, terms as stated in their headers. Other code keeps the terms stated in its
  files. `make_vhdl_prom.c` states no license.
- Roms and anything generated from them (PROM VHDL, bitstreams) are not distributed.
