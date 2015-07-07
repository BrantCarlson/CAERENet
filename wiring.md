Wiring 
======

This document describes the wiring necessary to assemble the CAERENet field mill.

Preamp
------

The preamp needs:
- Power: +12, -12, ground
- input: ch1, ch2 from electrodes
- output: ch1, ch2 to ADC

Viewed from the top of the board with the input wires closest to you, the pins for the power connectors are, from left to right: +12, 0, -12.

The input wires come in through a connector in the side, pins 1 and 2 for channels 1 and 2.  Channel 1 should go to the left input pin (same orientation as before), while Channel 2 should go to the right.  Likewise for the outputs.

Prop/ADC/SD
-----------

The Propellor needs +5 and ground
the ADC needs +5 and another ground (i.e. analog ground, different from the propellor).

Todo:
- work out pin numbers for ESC control
- work out what to do with battery eliminator circuit from ESC
- work out what do do with power supply for the ADC, analog ground.
- double-check the rest of the pin numbers.
- write detailed documentation (with images?) for board pinouts and wiring i.e. finish this document).


