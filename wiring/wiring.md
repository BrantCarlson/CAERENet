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

Photogate
---------

The photogate needs +5 and ground from digital power supply, connected to propeller board?

Output from the photogate needs to go to ADC channel 0.

Grounding
---------

All ground points will be wired to a star ground which will be wired to the case by soldering to the lock-washer at the signal entry point.

4 things will need to be connected to the star ground: preamp ground (female on board), propeller ground (male on board), ADC analog ground (male on board), ESC input ground (banana).  Will need at least 4 pins at the star ground, and will need 4 wires to connect to those pins, 3 with female on one end and male and female on the other, one with female on one end and some sort of banana plug connector on the other (solder this one directly to the black wire at ESC input.


Overall connector pinouts
=================
3-pin connector for signal input
- pin 1: red wire inside box, one channel
- pin 2: blue wire inside box, another channel
- pin 3: unused.

12-pin connector for everything else
- pin 1: +12V for preamp
- pin 2: gnd for preamp
- pin 3: -12V for preamp

- pin 4: +5V for prop
- pin 5: gnd for prop

- pin 6: MCLK
- pin 7: MOSI
- pin 8: [unused]
- pin 9: MISO
- pin 10: SCLK

- pin 11: +12V for ESC
- pin 12: gnd for ESC

Wiring to 12-pin connector with Belkden M 9536 cable (7 wires, no SPI)
- pin 1: blue
- pin 2: unshielded
- pin 3: black
- pin 4: white
- pin 5: red
- pin 6: -
- pin 7: -
- pin 8: -
- pin 9: -
- pin 10: -
- pin 11: brown
- pin 12: green

Current source issues
=====================
It doesn't work...  the voltage on the +12V power rail at the ESC drops a LOT when the ESC powers up and wants to start the motor, so the ESC either gives up (thinking there's a dead battery) or otherwise cannot make the motor respond.

Two possible issues here...
- too much resistance in the wires, so the amount of current the ESC wants will make the voltage drop too much.  Diagnostic: measure resistance of the power rail (0.9 ohms... not too bad).  Measure voltage drop over wire, infer current, determine if voltage drop is due to resistive losses over the wire or due to power supply not being able to source enough current.  Solution: separate power cable and connector for the ESC power +12 and ground, thicker wires to decrease resistance.  Add a big-ass capacitor inside the instrument.
- not enough juice from the power supply.  Diagnostic: measure voltage drop at the power supply, see if it's a significant portion of the voltage drop.  Check current ratings on the various lines, see if it's sufficient.  Solution: tie multiple yellow wires (+12V) together to avoid built-in current limits, include more power supply sources (i.e. capacitors) to provide more juice.  Add a load resistance to draw power from the +5V or +12V rail, since switching power supplies need at least _some_ load to provide stable power.  

Nope.  Turns out it's neither of these possibilities...

ESC Issues
==========

Nevermind, it's not either of the above issues.  The ESCs need to be calibrated for the endpoints of the throttle the first time through, or at least that's what I think is going on.  The procedure I had to follow to get the ESCs working was to hook them up to the propeller programmed with the esc_cal code and hooked up to the USB.  Start the program, then wait until the PWM is active, then power on the ESC.  The ESC should enter calibration mode.  As soon as the ESC starts beeping, turn the servo PWM to idle.  The ESC should acknowledge this and stop the calibration.  Once you've done this, power cycle the ESC with the PWM to idle, and increasing the servo width from there should make the motor turn.

Or something like that.  If you need to make the ESC go back into calibration mode, it might work to increase the pulse width above the 160000 cycles that would normally be "max".  Otherwise, the ESC should enter calibration mode by powering it on with the servo PWM at maximum width.
