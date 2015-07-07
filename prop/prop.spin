CON

{{
Carthage Field Mill Code Summer 2014
Michael Brusich and Aaron Scheets, supervised by Brant Carlson
This program:
- controls the ESC for an brushless motor.
- uses an MCP3208 ADC to collect data from the mill preamp, storing this data in buffers.
- communicates via a pseudo-SPI bus with a Raspberry Pi, receiving commands, responidng, and sending data.
- writes data to an SD card when requested by the Raspberry Pi
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
  SPI_MOSI = 0  ' master out slave in
  SPI_MISO = 2  ' master in slave out
  SPI_MCLK = 4  ' master clock
  SPI_SCLK = 6  ' slave clock

  'indicator LED (set to one of the pins on the QuickStart that has an LED attached)
  IndicatorLED = 23

  'ESC control PWM pin (see assembly code at bottom)
  Servo_Pin = 1


  'CONSTANTS FOR FLAGS AND BUFFERS
  'buffer size
  buflen = 1024
  buflen_bytes = buflen * 2   'designates number of bytes in buffer, (buffer of words)

  'buffer state flags
  _full = 0     ' buffer has been filled from ADC
  _written = 1  ' buffer has been written to SD card (or is otherwise ready to be filled again)

  'sd operation flags
  _open = 2     ' a file is open
  _opening = 3  ' no file is open, but it should be.
  _closing = 4  ' the file is open but shouldn't be.
  _closed = 5   ' file is closed

  'flags for running and shutdown
  _running = 6   '
  _shutdown = 7

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
  byte fileflag

  'program operation: _running, _shutdown
  byte shutdownflag

  long cogstack[150] 'designating space for cog startup
  long reader_cog, writer_cog, comm_cog, servo_cog

  'global max and min values, updated directly by maxmin function
  word max_1 ' channel 1 max
  word min_1 ' channel 1 min
  word max_2 ' channel 2 max
  word min_2 ' channel 2 min

  'buffers being dumped into by ADC
  word buffer_1[buflen]
  word buffer_2[buflen]
  word buffer_3[buflen]
  word buffer_4[buflen]

PUB main
  Startup  'initialize things
  run      'and start running
  ' shutdown code called elsewhere

PUB Startup | insert_card

  dira[IndicatorLED] := %1  'set indicator LED pin as output
  outa[IndicatorLED] := %1  ' and turn the LED on

  pst.Start(115_200)     'start Parallax Serial Terminal

  waitcnt(5*clkfreq + cnt)  ' wait 5 seconds for PST startup on computer

  shutdownflag := _running  ' program is running
  fileflag := _closed       ' initialize fileflag to _closed
  bufflag_1 := _written     'initializes flags to _written, signifying they are ready to be filled from ADC channels
  bufflag_2 := _written
  bufflag_3 := _written
  bufflag_4 := _written

  pst.str(string("starting ESC"))
  pst.str(string(13,10))

  speed := 80_000                   'sets esc to idle
  servo_cog := cognew(@SingleServo,@speed)       'opens new cog for ESC

  pst.str(string("starting ADC"))
  pst.str(string(13,10))

  adc.start(ADC_DPIN,ADC_CPIN,ADC_SPIN,7)          'starts adc chip, 7 corresponds to mode parameter, (see MCP3208)

  pst.str(string("starting SD card"))
  pst.str(string(13,10))

  insert_card := \sd.mount_explicit(SD_D0, SD_CLK, SD_DI, SD_CS)      'mount sd card or abort, see "abort trap" in propeller manual
  if insert_card < 0
    abort

  speed := 84_800  'starts ESC, 86857=1500rpm

  pst.str(string("starting reader, writer, and communications"))
  pst.str(string(13,10))

  reader_cog := cognew (reader, @cogstack[0])  'start reader, writer, and SPI cogs
  writer_cog := cognew (writer, @cogstack[50])
  comm_cog := cognew (comms, @cogstack[100])

  pst.str(string("startup completed"))
  pst.str(string(13,10))

PUB run
  ' all the main cog does here is run minmax repeatedly
  ' more data processing should probably happen here?

  repeat  'if buffers are _full, indicated by bufflag_1 == _full, find min max of function, @ symbol syntax for passing in array as parameter
    if bufflag_1 == _full
      minmax(@buffer_1)
    if bufflag_2 == _full
      minmax(@buffer_2)
    if bufflag_3 == _full
      minmax(@buffer_3)
    if bufflag_4 == _full
      minmax(@buffer_4)

    if shutdownflag == _shutdown
      shutdown  'shutdown function
      quit


PUB shutdown | i
  ''sanity check serial write in place for ADC amplitudes
  'repeat i from 0 to buflen
  '  if buffer_1[i] < 500 AND i//3<>0 'looking for ADC values less than 500 on channels other than photogate channel
  '    pst.str(string("buf_1 "))
  '    pst.dec(buffer_1[i])
  '    pst.str(string(" at "))
  '    pst.dec(i)
  '    pst.str(string(13,10))

  pst.str(string("shutting down"))
  pst.str(string(13,10))

  speed := 80_000                       'sets esc to idle

  repeat while fileflag <> _closed    'while file isn't closed, wait...
    next

  cogstop(reader_cog)            'shutdown cogs
  cogstop(writer_cog)
  cogstop(comm_cog)
  cogstop(servo_cog)

  sd.unmount                'unmount sd card

  pst.str(string("shut down"))
  pst.str(string(13,10))

  outa[IndicatorLED] := %0 ' turn indicator LED off

PUB reader | i
'reading from the ADC into buffers

  'pst.dec(7)      'serial write "7" indicating reader cog is on board
  'pst.str(string(13,10))

  ' the lines that set the beginning and end of each buffer should use the cnt variable (i.e. the clock)
  repeat
    if bufflag_1 == _written  'if buffer has been analyzed/_written from if deemed appropriate, enter loop
      buffer_1[0] := 2048           'cnt
      repeat i from 1 to (buflen-1) step 3   'incrementing i in steps of 3 since three channels on ADC, 1,2, and photogate
        buffer_1[i] := adc.in(0)          'read from particular ADC channel into respective buffer index
        buffer_1[i+1] := adc.in(1)                        '(adc.in(channel))
        buffer_1[i+2] := adc.in(2)
      buffer_1[buflen-1] := 2048       'cnt
      bufflag_1 := _full            '_full indicates buffer _full of new data to be analyzed
    if bufflag_2 == _written
      buffer_2[0] := 2048           'cnt               'repeat process for three other buffers...
      repeat i from 1 to (buflen-1) step 3
        buffer_2[i] := adc.in(0)
        buffer_2[i+1] := adc.in(1)
        buffer_2[i+2] := adc.in(2)
      buffer_2[buflen-1] := 2048       'cnt              'need to decide what to do for initializing and capping buffers, buffers...
      bufflag_2 := _full                                  '...are buffers of words, "cnt" is a long, what is the consequence of...
    if bufflag_3 == _written                                   '...using a long where the objects of the buffers are words?
      buffer_3[0] := 2048           'cnt
      repeat i from 1 to (buflen-1) step 3
        buffer_3[i] := adc.in(0)
        buffer_3[i+1] := adc.in(1)
        buffer_3[i+2] := adc.in(2)
      buffer_3[buflen-1] := 2048       'cnt
      bufflag_3 := _full
    if bufflag_4 == _written
      buffer_4[0] := 2048           'cnt
      repeat i from 1 to (buflen-1) step 3
        buffer_4[i] := adc.in(0)
        buffer_4[i+1] := adc.in(1)
        buffer_4[i+2] := adc.in(2)
      buffer_4[buflen-1] := 2048       'cnt
      bufflag_4 := _full

PUB writer
'when fileflag is set to open and the buffers are _full,
'this cog writes the data to the sd card then sets the buffer flag to _written.

  pst.dec(8)     'serial write of "8" indicates writer function/cog startup
  pst.str(string(13,10))

  repeat    'continuously checking file status and responding appropriately
    if fileflag == _opening  'fileflag is set to _opening in comms via command from Pi
      fileflag := _open
      sd.popen(@filename, "w") 'open file on sd for writing to, filename correpsonds to file name A-Z

    if fileflag == _open
      repeat while fileflag == _open
        if bufflag_1 == _full   'if buffer is _full and file == open, write buffer to sd card
          sd.pwrite(@buffer_1,buflen_bytes)
          bufflag_1 := _written
        if bufflag_2 == _full
          sd.pwrite(@buffer_2,buflen_bytes)
          bufflag_2 := _written
        if bufflag_3 == _full
          sd.pwrite(@buffer_3,buflen_bytes)
          bufflag_3 := _written
        if bufflag_4 == _full
          sd.pwrite(@buffer_4,buflen_bytes)
          bufflag_4 := _written

    if fileflag == _closing  'fileflag set to _closing in comms via command from Pi
      sd.pclose
      filename := filename+1   'increment file name
      fileflag := _closed

    if fileflag == _closed   'set files to _written, enabling reader to write to buffers
      bufflag_1 := _written
      bufflag_2 := _written
      bufflag_3 := _written
      bufflag_4 := _written

PUB minmax(lookit) | i, mx1, mx2, mn1, mn2       'function finding max and min of channel 1 and 2 from passed in buffer---lookit

  mx1 := word[lookit][1]         'set mx1 and mn1 to first value of channel 1 for comparison
  mx2 := word[lookit][2]         'set mx2 and mn2 to first value of channel 2 for comparison
  mn1 := word[lookit][1]
  mn2 := word[lookit][2]

  repeat i from 1 to (buflen - 2) step 3       'go through buffer in steps of three
    if word[lookit][i] > mx1   'max_1
      mx1 := word[lookit][i]
    if word[lookit][i+1] > mx2 'max_2                                                 'something seems funky about this function
      mx2 := word[lookit][i+1]
    if word[lookit][i] < mn1   'min_1
      mn1 := word[lookit][i]
    if word[lookit][i+1] < mn2 'min_2
      mn2 := word[lookit][i+1]

  max_1 := mx1
  max_2 := mx2       'set global max and min variables to values just set in local variables
  min_1 := mn1
  min_2 := mn2

PUB SPI_setup  'prepping SPI pins for communication
  dira[SPI_MCLK] := %0    'master clock set to input
  dira[SPI_MOSI] := %0    'master out slave in set to input
  dira[SPI_SCLK] := %1    'slave clock set to output
  dira[SPI_MISO] := %1    'master in slave out to set output

  outa[SPI_SCLK] := %0    'slave clock initialized to low

PUB IO1 (outputbit) : frompi | i    ' pseudo-SPI code, (custom communication code, similar to SPI)
' sends one bit, acting as the slave to the Raspberry Pi.
  repeat while INA[SPI_MCLK] == 0    'wait for master clock to go high (while == 0, next/wait)
    next

  outa[SPI_SCLK] := %1           'once master clock is read as high, set slave clock to high

  outa[SPI_MISO] := outputbit     'set output, (master-in-slave-out) to either 1 or 0

  repeat while INA[SPI_MCLK] == 1     'wait for master clock to go low
    next

  frompi := INA[SPI_MOSI]        'read either a 1 or 0 in from Pi, (master-out-slave-in) -value returned by function

  outa[SPI_SCLK] := %0          'once MISO is read, set slave clock to low, signifying ready

PUB IO16(x) : a | i     'function operating spi code for one bit, 16 times, results in construction of 16 bit value sent from Pi

  'x is 16 bit value to be sent to Pi

  a := 0    'function returns a, which will be constructed into number from Pi

  repeat i from 0 to 15
    a := a | (IO1(x & 1) << i)    'bitwise or's a with bit from Pi, shifted i places to the left, sends one bit of x to Pi
    x := x >> 1

PUB comms | localmax_1, localmax_2, localmin_1, localmin_2, command, continue, wait

  'pst.dec(9)    'serial write of 9 indicates startup of comms function/comm_cog
  'pst.str(string(13,10))

  SPI_setup     'initializes pins for communication, setting inputs, outputs, SPI_SCLK low

  repeat     'this loop repeats til shutdown

    command := (IO16(0)) 'send a zero to Pi, value returned is set as "command"
    pst.str(string("command "))
    pst.dec(command)               'serial write command
    pst.str(string(13,10))
    if command == 1               'if Pi sets command to 1, send current values of global max and min variables
      localmax_1 := max_1  'storing current values of maxs and mins into local variables for use in current data transfer
      localmin_1 := min_1
      localmax_2 := max_2
      localmin_2 := min_2

      IO16(localmax_1)                  'Utilize IO16 to send max and min of both channels to Pi
      pst.str(string("max1 "))
      pst.dec(localmax_1)
      pst.str(string(13,10))
      IO16(localmin_1)
      pst.str(string("min1 "))
      pst.dec(localmin_1)
      pst.str(string(13,10))
      IO16(localmax_2)
      pst.str(string("max2 "))
      pst.dec(localmax_2)
      pst.str(string(13,10))
      IO16(localmin_2)
      pst.str(string("min2 "))
      pst.dec(localmin_2)
      pst.str(string(13,10))

    if command == 2                 'If command from Pi == 2, set fileflag to _opening to start writing
      fileflag := _opening
    if command == 3                 'If command from Pi == 3, set fileflag to _closing to stop writing
      fileflag := _closing
    if command == 4                 'If command from Pi == 4, start shutdown process
      if fileflag == _open or fileflag == _opening   'make sure fileflag status is set to _closing
        fileflag := _closing
      shutdownflag := _shutdown   'change status of operation flag to _shutdown
      quit

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
