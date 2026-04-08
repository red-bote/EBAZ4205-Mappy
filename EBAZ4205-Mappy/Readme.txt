Mappy Arcade for the EBAZ-4205 ZYNQ-7010 FPGA Board. Pinballwiz.org 2026
Code from Mister-X Druaga Core.

Notes:
Setup for keyboard controls in Upright mode (5 = Coin) (Start P1 = 1) (Start P2 = 2)(LCtrl = Action)(Arrow Keys = Move U or D or L or R)
Consult the Docs Folder for Information regarding peripheral connections and schematics.

Build:
* Obtain correct roms file for Mappy (see scripts in tools folder for rom details).
* Unzip rom files to the tools folder.
* Run the make mappy proms script in the tools folder.
* Place the generated prom files inside the proms folder.
* Open the EBAZ4205-Druaga project file using Vivado (v2022.2 or silimar is recommended)
* Compile the project updating filepaths to source files as necessary.
* If not using Zynq Arcade Platform connect JTAG Programmer and program EBAZ4205 Board.
* If using Zynq Arcade (see the github repo) copy bitstream file to MicroSD Card and sys reset EBAZ4205 Adapter board to load.

