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
- move laptop away
- with/without power supply load resistor
- cover rotor
- remove rotor
- disconnect electrodes
- leave motor stopped
- unpower ESC
- disable servo code
- disconnect photogate
- add sheet metal inside box to isolate preamp

Data files:
- repeatability: orig_1, orig_2, orig_3
