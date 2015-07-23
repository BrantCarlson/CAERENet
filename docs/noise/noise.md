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

pulses from power supply are around 122 kHz



Plan 
====

Some things to try:
- isolate the preamp and its signal wires from the motor/ESC.
- add a regulator and/or a filter to the ADC Vref.
- work out why gain is unequal in two channels.  urgh.  friggen preamp...
