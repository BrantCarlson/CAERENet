CON

{{
Carthage Field Mill Code Summer 2014
Michael Brusich and Aaron Scheets, supervised by Brant Carlson
This program:
- controls the ESC for an brushless motor.
- uses an MCP3208 ADC to collect data from the mill preamp, storing this data in buffers.
- writes a certain amount of data to an SD card

No SPI communication in this one.
}}

  ' clock settings
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  'PIN ASSIGNMENTS
  'Note: Pin values in this document refer to propeller pin numbers, starting from 0.
  '      Pin values as listed on the QuickStart board start from 1, see QuickStart board docs.

  'adc pins for ADC/SD shield (see pcb/adcsd_shield_pinout.svg)
  ADC_DPIN =  14
  ADC_SPIN =  16
  ADC_CPIN =  12

  'sd card pins for ADC/SD shield (see pcb/adcsd_shield_pinout.svg)
  SD_D0 = 22
  SD_CLK = 24
  SD_DI =  25
  SD_CS = 26

  'pseudo-spi pins (see pcb/adcsd_shield_pinout.svg)
  ' UNUSED in this version
  SPI_MOSI = 0  ' master out slave in
  SPI_MISO = 2  ' master in slave out
  SPI_MCLK = 4  ' master clock
  SPI_SCLK = 6  ' slave clock

  'indicator LED (set to one of the pins on the QuickStart that has an LED attached)
  IndicatorLED = 23

  'ESC control PWM pin (see assembly code at bottom)
  ' this block of pins is contiguous on the header on the ADC/SD board, so just plug the 3-pin connector
  ' from the ESC to these 3 pins on the ADC/SD board header, with the white wire on pin 1.
  Servo_Pin = 1
  BEC_Plus  = 3 'Battery eliminator circuit power supply.  not used, but should be set to input (high impedance)
  BEC_Minus = 5 'Battery eliminator circuit power supply.  not used, but should be set to input (high impedance)

  'CONSTANTS FOR FLAGS AND BUFFERS
  'buffer size
  buflen = 1024
  buflen_bytes = buflen * 2   'designates number of bytes in buffer, (buffer of words)

  maxbufctr = 1000

  'buffer state flags
  _full = 0     ' buffer has been filled from ADC
  _written = 1  ' buffer has been written to SD card (or is otherwise ready to be filled again)


OBJ
  adc : "MCP3208"  ' ADC
  sd  : "fsrw"   ' SD card file system (fsrw 2.6)
  pst : "Parallax Serial Terminal"  ' debugging via USB cable to serial terminal

VAR
  'motor control variable
  long speed   ' 80000 -> ESC off, 86857 -> 1500rpm -> 25 Hz -> 50 Hz for cover/uncover cycle of mill electrodes

  'flags for four buffers respectively, either hold value _full, or _written
  byte bufflag_1
  byte bufflag_2
  byte bufflag_3
  byte bufflag_4

  'sd flag: open, opening, closing, closed
  long bufctr 'number of buffers written

  long cogstack[150] 'designating space for cog startup
  long reader_cog, comm_cog, servo_cog

  'buffers being dumped into by ADC
  word buffer_1[buflen]
  word buffer_2[buflen]
  word buffer_3[buflen]
  word buffer_4[buflen]

PUB main
  Startup  'initialize things

  repeat while filename < "f"
    pst.str(string("writing... "))
    writeFile
    pst.str(string("done!"))
    pst.str(string(13,10))

  shutdown  'and shutdown.

PUB Startup | insert_card

  dira[IndicatorLED] := %1  'set indicator LED pin as output
  outa[IndicatorLED] := %1  ' and turn the LED on

  pst.Start(115_200)     'start Parallax Serial Terminal

  waitcnt(5*clkfreq + cnt)  ' wait 5 seconds for PST startup on computer

  bufctr := 0
  bufflag_1 := _written     'initializes flags to _written, signifying they are ready to be filled from ADC channels
  bufflag_2 := _written
  bufflag_3 := _written
  bufflag_4 := _written

  pst.str(string("starting ESC"))
  pst.str(string(13,10))
  
  speed := 80_000                   'sets esc to idle
  servo_cog := cognew(@SingleServo,@speed)       'opens new cog for ESC

  waitcnt(2*clkfreq + cnt)  ' wait 5 seconds for PST startup on computer

  pst.str(string("starting ADC"))
  pst.str(string(13,10))
  
  adc.start(ADC_DPIN,ADC_CPIN,ADC_SPIN,7)          'starts adc chip, 7 corresponds to mode parameter, (see MCP3208)

  pst.str(string("starting SD card"))
  pst.str(string(13,10))

  insert_card := \sd.mount_explicit(SD_D0, SD_CLK, SD_DI, SD_CS)      'mount sd card or abort, see "abort trap" in propeller manual
  if insert_card < 0
    pst.str(string("problem with SD card mount!"))
    pst.str(string(13,10))
    abort

  pst.str(string("SD card mounted."))
  pst.str(string(13,10))

  speed := 84_800  'starts ESC, 86857=1500rpm

  pst.str(string("starting reader"))
  pst.str(string(13,10))

  reader_cog := cognew (reader, @cogstack[0])

  pst.str(string("startup completed"))
  pst.str(string(13,10))

PUB shutdown | i
  pst.str(string("shutting down"))
  pst.str(string(13,10)) 
  
  speed := 80_000                       'sets esc to idle

  cogstop(reader_cog)            'shutdown cogs
  'cogstop(servo_cog)

  sd.unmount                'unmount sd card

  pst.str(string("shut down complete. SD card safe to remove."))
  pst.str(string(13,10)) 
  
  outa[IndicatorLED] := %0 ' turn indicator LED off

PUB reader | i
  repeat
    if bufflag_1 == _written  'if buffer has been analyzed/_written from if deemed appropriate, enter loop
      'buffer_1[0] := cnt
      long[@buffer_1][0] := cnt
      repeat i from 1 to (buflen-2) step 3   'incrementing i in steps of 3 since three channels on ADC, 1,2, and photogate
        buffer_1[i] := adc.in(0)          'read from particular ADC channel into respective buffer index
        buffer_1[i+1] := adc.in(1)                        '(adc.in(channel))
        buffer_1[i+2] := adc.in(2)
      long[@buffer_1][buflen/2-1] := cnt
      bufflag_1 := _full            '_full indicates buffer _full of new data to be analyzed
    if bufflag_2 == _written
      long[@buffer_2][0] := cnt
      repeat i from 1 to (buflen-2) step 3
        buffer_2[i] := adc.in(0)
        buffer_2[i+1] := adc.in(1)
        buffer_2[i+2] := adc.in(2)
      long[@buffer_2][buflen/2-1] := cnt
      bufflag_2 := _full
    if bufflag_3 == _written
      long[@buffer_3][0] := cnt
      repeat i from 1 to (buflen-2) step 3
        buffer_3[i] := adc.in(0)
        buffer_3[i+1] := adc.in(1)
        buffer_3[i+2] := adc.in(2)
      long[@buffer_3][buflen/2-1] := cnt
      bufflag_3 := _full
    if bufflag_4 == _written
      long[@buffer_4][0] := cnt
      repeat i from 1 to (buflen-2) step 3
        buffer_4[i] := adc.in(0)
        buffer_4[i+1] := adc.in(1)
        buffer_4[i+2] := adc.in(2)
      long[@buffer_4][buflen/2-1] := cnt
      bufflag_4 := _full

PUB writeFile
  bufctr := 0
  sd.popen(@filename, "w") 'open file on sd for writing to, filename correpsonds to file name A-Z

  pst.str(string(13,10))
  pst.str(string("file opened..."))
  pst.str(string(13,10))

  repeat while bufctr < maxbufctr
    if bufflag_1 == _full   'if buffer is _full and file == open, write buffer to sd card
      sd.pwrite(@buffer_1,buflen_bytes)
      bufflag_1 := _written
      bufctr := bufctr + 1
    if bufflag_2 == _full
      sd.pwrite(@buffer_2,buflen_bytes)
      bufflag_2 := _written
      bufctr := bufctr + 1
    if bufflag_3 == _full
      sd.pwrite(@buffer_3,buflen_bytes)
      bufflag_3 := _written
      bufctr := bufctr + 1
    if bufflag_4 == _full
      sd.pwrite(@buffer_4,buflen_bytes)
      bufflag_4 := _written
      bufctr := bufctr + 1

  pst.str(string("buffers written..."))
  pst.str(string(13,10))
        
  sd.pclose
  filename := filename+1   'increment file name

DAT
' NOTE WELL: edited by a programmer who doesn't know what he's doing (BEC).  verify that this works.
' details: the original servo PWM assembly code seemed to set all output pins high/low at the PWM rate, which was messing up our ADC (and possibly SD card) outputs.
' the lines annotated "Set ServoPin high(?)" and "Set servopin low(?)" used to be movs with %FFFFFFFF and %00000000, if I (BEC) recall correctly
' I am also suspicious that there may be some memory issues here -- how to make the original servo code work with the other cogs and their cogstacks?

' The assembly program below runs on a parallel cog and checks the value of the "speed" variable in the main Hub RAM (which
' other cogs can change at any time). It then outputs a servo high pulse for the "speed" number of system clock ticks and
' sends a 10ms low part of the pulse. It repeats this signal continuously and changes the width of the high pulse as the
' "speed" variable is changed by other cogs.

              org                         'Assembles the next command to the first cell (cell 0) in the new cog's RAM
SingleServo   or        dira,ServoPin      'Set the direction of the "ServoPin" to be an output (and leaves others as is)

Loop          rdlong    HighTime,par      'Read the "speed" variable (at "par") from Main RAM and store it as "HighTime"
              mov       counter,cnt       'Store the current system clock count in the "counter" cell's address

              or        outa,ServoPin     ' Set ServoPin high(?)

              add       counter,HighTime  'Add "HighTime" value to "counter" value
              waitcnt   counter,LowTime   'Wait until "cnt" matches "counter" then add a 10ms delay to "counter" value

              andn      outa,ServoPin     ' Set servopin low(?)

              waitcnt   counter,0         'Wait until cnt matches counter (adds 0 to "counter" afterwards)
              jmp       #Loop             'Jump back up to the cell labled "Loop"

'Constants and Variables:
ServoPin      long      |< Servo_Pin      '<------- This sets the pin that outputs the servo signal (which is sent to the white wire
                                          ' on most servomotors). Here, this "7" indicates Pin 7. Simply change the "7"
                                          ' to another number to specify another pin (0-31).

LowTime       long      1_600_000         'This works out to be a 20ms pause time with an 80MHz system clock.
'LowTime       long      800_000          'This works out to be a 10ms pause time with an 80MHz system clock.
counter       res                         'Reserve one long of cog RAM for this "counter" variable
HighTime      res                         'Reserve one long of cog RAM for this "HighTime" variable
              fit                         'Makes sure the preceding code fits within cells 0-495 of the cog's RAM

filename      byte      "a",0

{{

┌──────────────────────────────────────────────────────────────────────────────────────┐
│                           TERMS OF USE: MIT License                                  │
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │
│                                                                                      │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     │
│OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        │
│SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}
