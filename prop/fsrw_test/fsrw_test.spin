CON

{{
FSRW test code for ADC/SD shield.  see pinout in pcb directory.
}}

  ' clock settings
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  'PIN ASSIGNMENTS
  'Note: Pin values in this document refer to propeller pin numbers, starting from 0.
  '      Pin values as listed on the QuickStart board start from 1, see QuickStart board docs.
  
  'sd card pins (see pcb/adcsd_shield_pinout.svg)
  SD_D0 = 22
  SD_CLK = 24
  SD_DI =  25
  SD_CS = 26

OBJ
  sd  : "fsrw"   ' SD card file system (fsrw 2.6)
  pst : "Parallax Serial Terminal"  ' debugging via USB cable to serial terminal
  
VAR
  long cogstack[150] 'designating space for cog startup
  word buffer_1[1024]
  word buffer_2[1024]

PUB main | insert_card, i
  pst.Start(115_200)     'start Parallax Serial Terminal
  waitcnt(5*clkfreq + cnt)  ' wait 5 seconds for PST startup on computer

  pst.str(string("Setting up buffer"))
  pst.str(string(10,13))
  repeat i from 0 to 1023
    buffer_1[i] := i
    buffer_2[i] := 0

  pst.str(string("mounting SD"))
  pst.str(string(10,13))

  insert_card := \sd.mount_explicit(SD_D0, SD_CLK, SD_DI, SD_CS)
  if insert_card < 0
    pst.str(string("SD mount failed?"))
    pst.dec(insert_card)
    pst.str(string(10,13))
    abort

  pst.str(string("SD mount succeeded"))
  pst.str(string(10,13))

  pst.str(string("opening file"))
  pst.str(string(10,13))
  sd.popen(@filename, "w") 'open file on sd for writing to, filename correpsonds to file name A-Z

  pst.str(string("file open, writing buffer"))
  pst.str(string(10,13))
  sd.pwrite(@buffer_1,2048)

  pst.str(string("buffer written, closing file"))
  pst.str(string(10,13))
  sd.pclose

  pst.str(string("file closed, reopening to read"))
  pst.str(string(10,13))
  sd.popen(@filename,"r")

  pst.str(string("file open, reading..."))
  pst.str(string(10,13))
  sd.pread(@buffer_2,2048)

  pst.str(string("read complete, buffer elements 5 and 1023 are "))
  pst.dec(buffer_2[5])
  pst.str(string(10,13))
  pst.dec(buffer_2[1023])
  pst.str(string(10,13))

  pst.str(string("closing file"))
  pst.str(string(10,13))
  sd.pclose

  pst.str(string("file closed, unmounting card"))
  pst.str(string(10,13))
  sd.unmount                'unmount sd card

  pst.str(string("card unmounted, program complete."))
  pst.str(string(10,13))

DAT
              org                         'Assembles the next command to the first cell (cell 0) in the new cog's RAM

filename      byte      "a",0
