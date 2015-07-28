Noise tests
===========

Procedure
- take data with no_spi code
- copy to testdata directory
- examine last few seconds (see noiseAnalysis.ipynb)
- compare various cases by power spectrum, RMS, presence/absence of spikes, etc.

Things to try:
- run several times to get a baseline
- remove serial terminal communications code
- with/without power supply load resistor
- cover rotor
- remove rotor
- disconnect electrodes
- leave motor stopped
- disable servo code
- unpower ESC
- disconnect photogate
- add sheet metal inside box to isolate preamp
- move laptop away

Data files:
- repeatability: orig_1, orig_2, orig_3
- no SPI code: nospi_4
- with supply load resistor: withR_5
- rotor covered: coverRot_6
- rotor removed (but electrodes uncovered): noRot_7
- rotor removed, electrodes covered: noRotElCov_8
- electrode disconnected: noEl_9, noEl_10
- servo code disabled: noServo_11
- ESC unpowered: noESC_12

Observations
============

Starting with the low-noise side and working my way up...

In noESC_12, there are some bursts of noise repeating every 0.031 s, i.e. 32 Hz.

Moving on to noESC_12 vs noServo_11, there seems to be no significant difference.  Perhaps a bit more HF noise in one of the channels, but nothing major.  So, merely connecting the ESC to power doesn't hurt things too much.

In noESC_12 vs noEl_10, the motor is now running.  Now there's a lot more noise, bursting in both channels.  The noise seems to be alternating, first one channel, then the other.  Burst frequency in one channel is around 72 Hz, and within the burst there seems to be significant frequency content 3200 Hz, which shows up loud and clear in the power spectrum.

In noEl_9 vs NoRotElCov_8, connecting the electrodes opens the system up to a LOT more interference.  A grounded piece of sheet metal was held (by hand) over the instrument here, and yet there are bursts at around 32 Hz again.  These bursts are slightly faster than the photogate, so it seems to be a legit source of external interference.

Using the scope's FFT mode and just measuring the spectrum of the probe hooked up to a plate, there isn't any obvious source of interference around 32 Hz.

Uncovering the electrode (still no rotors, i.e. noRot_7), all of a sudden it picks up a lot of 60Hz interference.  Unsurprisingly, I suppose.

attaching the rotor but covering the electrode/rotor assembly (i.e. coverRot_6), the 60Hz noise goes mostly away, but the 32Hz spikes are back.  Something about me holding a sheet of metal above the thing is contributing 32Hz spikes?

adding or removing the power supply load resistor doesn't seem to have much effect (comparing nospi_4 and withR_5).

disabling the Parallax Serial Terminal (i.e. nospi_4 vs orig_1, I should have named those files noPST not nospi) unsurprisingly doesn't seem to have an effect.


32 Hz noise at low amplitude (noESC_12)
---------------------------------------

In noESC_12, there was no ESC and no servo running.  The most visible noise source is a series of spikes visible in the data at the ~10 ADC bin level, present in the signals as well as the photogate (though perhaps more in the photogate), at around 32 Hz, i.e. a repetition period of 0.031s.  The sample frequency for a single channel is around 11 kHz, so the ADC is operating overall at around 33 kHz, so the time required to fill a given buffer is 1024/33000 = 0.031s, i.e. the same as the repetition frequency of that anomalous pulse.

Hypothesis: writing to the SD card is causing problems.  Experiment: comment out the SD card writes and check again.
- ESC unpowered, no servo, SD write of third buffer commented out: noSDb3_13
Ok, that's too hard to interpret.  gaps in the data, and all.  Maybe if I change the relative timing, by adding a waitcnt to the SD write?
- ESC unpowered, no servo, SD write of third buffer delayed by a quarter of the time needed to write the buffer: sdB3Delay_14

Yeah, that theory holds water.  The spikes in sdB3Delay_14 that looks, well, delayed.  There don't seem to be gaps in the data, either, which is good, I guess, though the data does seem to drop by a few ADC bins on a timescale comparable to the waitcnt I added.  That's ... weird.

SD Card Noise Reduction
-----------------------

The following is all done with ESC unpowered and servo code disabled.

baseline case: sdBase_15

nevermind, not going to do much more with this.

I think the cause here is supply fluctuations on the Vref of the ADC chip.  There are some bursty-looking voltage decreases if I watch the +5V input to the prop with an oscilloscope.

As a fix, the current draw on Iref is around 0.1 mA, which is not so bad, so I might try adding some sort of filter to the board.


Summary so far
--------------

Noise seems to come in two main ways: when the ESC and motor are running, there are bursts that come at a rate of 72 Hz with amplitude around 10-20 ADC channels and frequency content around 3.2 kHz.  These are going to be problematic if we need to precisely measure things happening at high frequencies but will be easy to filter out if all we need is static fields.  Beneath that, there are some noise bursts that I think are due to the SD card writes affecting the reference voltage to the ADC.

There's also a lot of external interference coming in when the electrodes are covered, pulses appearing at around 32 Hz.  I'm not sure why that's the case, but it doesn't really matter.  It might be worth playing around with a bit, building a better faraday cage, but it doesn't happen when the rotors are uncovered.  Odd.

Beyond that, the circuit seems to be behaving itself pretty well.

Attempts to eliminate motor noise
=================================

no rotor, electrodes disconnected, running upside down, load resistor on +12V (as before), lid closed: mnbase_16
lid OPEN: mnopen_17
lid open, load resistor on +5: mnR5_18
scope on: mnScOn_19

Poking around with the scope, there are serious noise spikes on the PHOTOGATE OUTPUT(!?) repeating at about 15.566 kHz.  Seems to be coming from the connection to the ADC, though, which is bizzare.  No noise is visible on the inputs when NOT connected to the ADC, nor is any noise visible on the ADC input pin, but somehow connecting them together... = bad.  = ground loop?  magnetic coupling?

pulses from ESC to motor are large and happen around 7.8 kHz.  That's a good candidate for pickup here, since it would be aliased down to 3.something kHz.  Visual inspection via oscilloscope makes it look like that's actually not a bad hypothesis.  Yeah, it's there...  ok.  How to get around that?

Randomly adding some shielding around ESC (pieces of sheet metal, alligator-wired to case...: shield0_20
a second attempt (shield closer to prop and preamp on other side of motor than last test): shield1_21
no real difference there with a shield.  must not be capacitive coupling.

moving motor further away didn't help either (motorFar_22).
must not be inductive coupling.

Therefore, must be power supply coupling.
Pity, since that's probably the hardest to deal with.

big-ass cap (470 microfarad electrolytic) across ESC power wires at ESC: escCap_23
no improvement.

big-ass caps at input to preamp power supply: preCap_24
slight improvement.

Trying separate power wire for ESC (load resistor removed): escSep_25
helped a lot.  double-checking, back to old power wire: escNotSep_26
back to separate power wire: escSep_27

Structure in power spectrum due to 7.8 kHz ESC pulses aliased down into spectrum now greatly reduced, 13 db lower than before.

Pulses are still there, but they're down at the level of the SD-card-write noise.

Fix
---

wired up second power wire, drilled third hole, used second 3-pin connector to get power in: twowires_28

seems to work fine.

Data Tests
==========

instrument assembled again, electrodes connected again, no rotor: norot_29
rotor re-attached: decided to let it stall and complete: stall_30
with a push to get started: run_31
with an E-field: runWithE_32

swapped lt1097s out for LM741s, still with E-field: lm741E_33
nothing.  hm.  no signal at all.

back to the LT1097...  backToNormal_34
one channel was flatlining, turned out the electrode had come unplugged.  I should work out some better way to keep them connected.  proper data --> overwrote backToNormal_34.

Pulses in data when actually collecting
=======================================

Those spikes in coverRot_6, noRotElCov_8 turned up in the actual data as well...  What do I know?
- channels respond unequally
- spike occurs once per buffer
- spike does NOT occur when electrodes are not connected
- spike is NOT synchronized with photogate

Moving on to data in pulsetestdata
- 01_orig: nothing edited, rotor removed, grounded metal sheet in front of electrode, connected to box, box open.  pulses visible.  bigger in channel 2 than channel 1.
- 02_inputSwap: swapped INPUTs to preamp.  pulses now bigger in channel 1 than channel 2.  WTF!
- 03_electrodesUnplugged: pulses gone.

Checking connections...  turns out one electrode just isn't connected.  Wires soldered to jack are soldered to the wrong pins.  Disassembling plug suggests a transient short might have been present thanks to a flake of shield bridging from ground/shield to signal.  Needs to be fixed, regardless...  Pinout from plug:
- pin 1: ground/shield
- pin 2: black wire (electrode)
- pin 3: red wire (electrode)

Pinout from jack, resoldering:
- pin 1: ~~red wire inside case~~ --> NC
- pin 2: blue wire inside case
- pin 3: ~~NC~~ --> red wire inside case

After re-wiring, sanity check:
- 04_rewired: whew.  pulses now show up equally on both channels.

Reprogrammed to run for an hour, to poke around with the scope...
spikes are visible on scope if you monitor input to ADC
rewriting code to remove SD card writing...
- SPIKES GO AWAY!?!
rewriting code to only write one of four buffers...
- spikes are back but there are fewer of them.

back to writing all 4 buffers to make timing easier to spot and poking around more...
- dips with correct timing are visible on +5 power rail.  slight, but visible.
- noise with correct timing is visible on preamp INPUT!

leaving motor idle...
ok, lost the signal...
trying to get it back... huh?
SD card noise seems gone (huh?!) but now there are pulses with around 532 ms period.
disconnecting SD card momentarily stops the pulses (also probably crashes the SD card)...
attempting to rearrange preamp to get better access makes pulses smaller...  turns out to be the longer wires connecting electrodes to inputs...  no, not really?

poking around...

physical proximity of propeller to normal mounting position seems to affect amplitude of pulses.  farther away = smaller amplitude.

connecting ch2 input to electrode affects amplitude of ch1 pulses?  makes sense...  connecting ch2 electrode to virtual ground should limit static pickup.

ensuring good connection between SD card shield and CASE NEAR SD CARD with a SHORT wire makes noise go away almost completely.
but why?
what coupling does that remove?  magnetic coupling doesn't make any sense.  moving WIRES around doesn't matter.  Power supply coupling is out right away, since pulses are not visible when electrodes are disconnected.  processes are way too slow for electrodynamics...  30 ms pulse period ~ 8 Mm wavelength.  nonsense.  electrostatic coupling is the only remaining option, but ...  signals getting in the ELECTRODES from the propeller side?  hmph.

Adding a big electrolytic capacitor from +5V to case at the propeller +5V input also reduces noise.
Adding the same big cap between +5 and digital ground does not.

Ok, I give up.  Let's just locally reinforce digital ground.

SD card interference interpretation and testing
-----------------------------------------------

The basic idea: if you deposit a net charge on an object surrounded by a conducting shell, the inner surface of the conducting shell will accumulate the same charge as you've deposited on the interior object.  If the conducting shell is to remain neutral, which it will, at least on the sort of timescale necessary to draw charge into or off of the shell through whatever cables are connected, the outside of the shell will accumulate some charge as well.  That accumulation might be picked up by the preamp somehow.  Maybe.

Testing this idea: put a conducting plate inside the box, wired up to a signal generator, and oscillate its potential.  That should push some charge in and out of the box, which might produce the same sort of signal...
... and...?
no signal appears unless the plate is positioned such that it's easy to imagine its elcetric field reaching the electrodes.  Ok, then.

Remaining ideas?  None whatsoever.

Simulations
===========

One thing that's bugged me: wave shape is not a pure triangle wave, looks a bit saw-tooth-y.  Why?
Probably it's just some property of the circuit, but...  just to double-check that nothing's broken, I re-did Mike's LTspice simulations (see preampSim.asc in the PCB directory).

Simulation results verify that the saw-tooth wave output is expected, so the circuit is behaving as designed.  Not exactly as intended, perhaps.  The amplitude response is not exactly flat over the pass band, has a bit of a resonance peak near the upper end of the pass band, and the phase response is not particularly linear.  Perhaps this is due for a redesign?


Plan / TODO
===========

- fix schematics for resistor placement (? or did I already do that?  check the regulators)
- add a regulator and/or a filter to the ADC Vref.
- redesign preamp to flatten amplitude response, linearize phase response.

