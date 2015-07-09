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
The SD card needs 3.3V and ground, but the , but the ADC/SD card board has a 3.3V regulator that takes care of that, so it can run off the same +5 digital power supply.

the ADC needs +5 (also from the prop/SD card)
the ADC also needs another ground (i.e. analog ground, different from the propellor).




FINISH ASSEMBLY Todo:
- work out pinouts for connectors overall
- work out grounding for circuit overall
- work out wiring harness.
- work out wiring for photogate
- work out power for photogate
- work out mounting for ESC
- make cables for connection to power supply
- revise code to work without RPi connected
- program propeller

GET ENSEMBLE WORKING Todo:

TAKE TEST DATA
