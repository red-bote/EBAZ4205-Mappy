copy /b mpx_3.1d + mpx_3.1d + mp1_2.1c + mpx_1.1b cpu1_rom.bin
copy /b mp1-7.5k + mp1-7.5k + mp1-7.5k + mp1-7.5k spclut_rom.bin
copy /b mp1_6.3m + mp1_6.3m sprite0_rom.bin
copy /b mp1_7.3n + mp1_7.3n sprite1_rom.bin


make_vhdl_prom mp1-5.5b clut_rom.vhd
make_vhdl_prom mp1-6.4c char_rom.vhd
make_vhdl_prom spclut_rom.bin spclut_rom.vhd
make_vhdl_prom mp1-3.3m snd_rom.vhd

make_vhdl_prom mp1_5.3b gfx1_rom.vhd
make_vhdl_prom sprite0_rom.bin sprite0_rom.vhd
make_vhdl_prom sprite1_rom.bin sprite1_rom.vhd

make_vhdl_prom cpu1_rom.bin cpu1_rom.vhd
make_vhdl_prom mp1_4.1k cpu2_rom.vhd

pause

