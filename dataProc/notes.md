Notes on data processing
========================

Julia code is now working.  And it's a lot faster than the Python, at least considering that it does a lot more.

Some thoughts so far:
- high-frequency noise bursts from SD card writing are becoming problematic.
- but seem to affect standard deviation in ch1 and ch2 in opposite directions.
- so plots of std1 + std2 are actually surprisingly stable.
- otherwise noise bursts seem to migrate slowly in and out of phase with the rotation...?
- maybe edit the code so the process of going from one file to the next is properly timed?  That would require looking at the clock variable...  somehow?

