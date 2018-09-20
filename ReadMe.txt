Project provides data exchange between (Gorebin-SPI and RS-232 devices) and (PC master)
Project may run on 2 different PCBs:
1) HUB (native)
2) Kom and Sopr with DE0

Only MASTER branch is verified. PCB_old_kom_sopr branch - is obsolete
Switching the boards is performed by replacing files and changing text variables and furthermore compiling.

==============HUB PCB=========================

To run project on HUB PCB:
1) Make copy of "redirector(hub).qsf" and rename it to "redirector.qsf", confirm overwrite
2) Edit defines.v:
`define NUM_SPI 4
`define NUM_UART 2
3) Edit redirector.sdc:
set NUM_SPI 4
4) Compile

Very important! When making .JIC file via Quartus II programmer on HUB PCB:
1) Click Advanced
2) Check box Disable AS mode CONF_DONE error check
(Checkbox Disable EPCS ID check - no effect noticed)

=============Kom and Sopr PCB================

To run project on Kom and Sopr PCB:
1) Make copy of "redirector(komsopr).qsf" and rename it to "redirector.qsf", confirm overwrite
2) Edit defines.v:
`define NUM_SPI 1
`define NUM_UART 1
3) Edit redirector.sdc:
set NUM_SPI 1
4) Compile

To connect UART, plug it in GPIO BH-14 socket, near the DE0
UART uses Kulakoff's 5-pin socket / plug:

Top view socket:
   +---+---+---+---+---+---+---+
 2 |   |GND|   |   |   |   |   | 14
   +---+---+---+---+---+---+---+
 1 |   |RX |TX |   |   |   |   | 13
   +---+---+---+   +---+---+---+

Top view plug:
   +---+---+---+
 2 |   |GND|   | 6
   +---+---+---+
 1 |   |TX |RX | 5
   +---+---+---+	


To connect SPI-device (e.g. Blok Analiza) use twisted IDC flat cable (where RXs swapped with TXs).