CON

{{
Carthage Field Mill Code Summer 2014
Michael Brusich and Aaron Scheets
This program controls the esc for an brushless PWM motor. It also uses a MCP3208 ADC to collect data from the mill that
has been amplified and filtered, storing this data to a collection of four arrays (buffers).  
}}

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  'Note: Pin values on this document are one less than the pin number shown on the propeller board
  '(pins are indexed from 0-39)
  
  'adc pins
  DPIN =  20
  SPIN =  22
  CPIN =  18

  'sd card pins
  D0 = 1
  CLK = 3       'SCK on SD card holder
  DI =  5
  CS = 7

  'spi pins
  mclk = 0
  sclk = 4
  mosi = 2
  miso = 6

  'startup led
  MagicLED = 23

  'assembly related 
  Servo_Pin = 23

  'buffer size
  buf = 1024
  bufwrd = buf * 2   'designates number of bytes in buffer, (buffer of words)

  'buffer state flags
  full = 0
  fw = 1  '(full written)

  'sd operation flags
  open = 2
  opening = 3
  closing = 4
  closed = 5

  'flags for running and shutdown
  _running = 6
  _shutdown = 7

OBJ
  adc : "MCP3208"
  sd  : "fsrw"   '(fsrw 2.6)
  pst   : "Parallax Serial Terminal" 
  
VAR

  'motor control variable
  long position   '

  'flags for four buffers respectively, either hold value full, or fw
  byte flag_1 
  byte flag_2
  byte flag_3
  byte flag_4

  'sd flag: open, opening, closing, closed
  byte _file

  'program operation: _running, _shutdown
  byte shutdownflag

  long cogstack[150] 'designating space for cog startup
  long reader_cog, writer_cog, comm_cog

  'global max and min values, updated directly by maxmin function
  word max_1
  word min_1      
  word max_2
  word min_2

  'buffers being dumped into by ADC
  word buffer_1[buf]
  word buffer_2[buf]
  word buffer_3[buf]
  word buffer_4[buf]

PUB main

  Startup   'setup type operations
  run      'calling minmax function when buffers full

PUB Startup | insert_card
  
  pst.Start(115_200)     'start Parallax Serial Terminal

  dira[MagicLED] := %1   'Led signifies program startup
  outa[MagicLED] := %1

  waitcnt(5*clkfreq + cnt)

  pst.str(string("running startup"))
  pst.str(string(13))
  
  shutdownflag := _running         'program is running

  _file := closed                  'initialize _file to closed

  position := 80_000                   'sets esc to idle
  cognew(@SingleServo,@position)       'opens new cog for motor

  adc.start(DPIN,CPIN,SPIN,7)          'starts adc chip, 7 correlates to mode parameter, (see MCP3208)
  'eliminated a wait cnt
  
  pst.str(string("running startup"))
  pst.str(string(13))

  insert_card := \sd.mount_explicit(D0, CLK, DI, CS)      'mount sd card or abort, see "abort trap" in propeller manual
  if insert_card < 0
    abort

  pst.str(string("running startup"))      'third serial write to indicate whether sd successfully mounted
  pst.str(string(13))

  position := 84_800                'starts motor 86857=1500rpm
'  waitcnt(clkfreq*5 + cnt)

  flag_1 := fw
  flag_2 := fw                  'initializes flags to fw, signifying they are ready to be filled from ADC channels
  flag_3 := fw
  flag_4 := fw

  reader_cog := cognew (reader, @cogstack[0])  'start reader, writer, and SPI cogs
  writer_cog := cognew (writer, @cogstack[50])                        
  comm_cog := cognew (SPI_binary, @cogstack[100])

PUB run | X

  repeat  'if buffers are full, indicated by flag_1 == full, find min max of function, @ symbol syntax for passing in array as parameter
    if flag_1 == full
      minmax(@buffer_1)
    if flag_2 == full
      minmax(@buffer_2)
    if flag_3 == full
      minmax(@buffer_3)
    if flag_4 == full
      minmax(@buffer_4)

    if shutdownflag == _shutdown
      shutdown  'shutdown function
      quit
  

PUB shutdown | i

  repeat i from 0 to buf             'sanity check serial write in place for ADC amplitudes
    if buffer_1[i] < 500 AND i//3<>0 'looking for ADC values less than 500 on channels other than photogate channel
      pst.str(string("buf_1 "))                                      
      pst.dec(buffer_1[i])
      pst.str(string(" at "))                                      
      pst.dec(i)
      pst.str(string(13))

  repeat while _file <> closed    'while file isn't closed, wait...
    next

  cogstop(reader_cog)            'shutdown cogs
  cogstop(writer_cog)
  cogstop(comm_cog)
  ' cogstop for servo?

  sd.unmount                'unmount sd card

  position := 80_000                       'sets esc to idle

  pst.str(string("shutting down"))
  pst.str(string(13)) 
  
  outa[MagicLED] := %0

PUB reader | i
'reading from the ADC into buffers

  pst.dec(7)      'serial write "7" indicating reader cog is on board
  pst.str(string(13))

  repeat
    if flag_1 == fw  'if buffer has been analyzed/written from if deemed appropriate, enter loop
      buffer_1[0] := 2048           'cnt            
      repeat i from 1 to (buf-1) step 3   'incrementing i in steps of 3 since three channels on ADC, 1,2, and photogate
        buffer_1[i] := adc.in(0)          'read from particular ADC channel into respective buffer index
        buffer_1[i+1] := adc.in(1)                        '(adc.in(channel))
        buffer_1[i+2] := adc.in(2)
      buffer_1[buf-1] := 2048       'cnt
      flag_1 := full            'full indicates buffer full of new data to be analyzed
    if flag_2 == fw
      buffer_2[0] := 2048           'cnt               'repeat process for three other buffers...
      repeat i from 1 to (buf-1) step 3
        buffer_2[i] := adc.in(0)
        buffer_2[i+1] := adc.in(1)
        buffer_2[i+2] := adc.in(2)
      buffer_2[buf-1] := 2048       'cnt              'need to decide what to do for initializing and capping buffers, buffers...
      flag_2 := full                                  '...are buffers of words, "cnt" is a long, what is the consequence of...
    if flag_3 == fw                                   '...using a long where the objects of the buffers are words?
      buffer_3[0] := 2048           'cnt
      repeat i from 1 to (buf-1) step 3
        buffer_3[i] := adc.in(0)
        buffer_3[i+1] := adc.in(1)
        buffer_3[i+2] := adc.in(2)
      buffer_3[buf-1] := 2048       'cnt
      flag_3 := full
    if flag_4 == fw
      buffer_4[0] := 2048           'cnt
      repeat i from 1 to (buf-1) step 3
        buffer_4[i] := adc.in(0)
        buffer_4[i+1] := adc.in(1)
        buffer_4[i+2] := adc.in(2)
      buffer_4[buf-1] := 2048       'cnt
      flag_4 := full

PUB writer
'when a flag is set to full this cog writes the data to the sd card then sets the flag to full written.

  pst.dec(8)     'serial write of "8" indicates writer function/cog startup
  pst.str(string(13))

  repeat    'continuously checking file status and responding appropriately
    if _file == opening  '_file is set to opening in SPI_binary via command from Pi
      _file := open
      sd.popen(@fname, "w") 'open file on sd for writing to, fname correpsonds to file name A-Z
 
    if _file == open
      repeat while _file == open
        if flag_1 == full   'if buffer is full and file == open, write buffer to sd card
          sd.pwrite(@buffer_1,bufwrd)
          flag_1 := fw
        if flag_2 == full
          sd.pwrite(@buffer_2,bufwrd)
          flag_2 := fw
        if flag_3 == full
          sd.pwrite(@buffer_3,bufwrd)
          flag_3 := fw
        if flag_4 == full
          sd.pwrite(@buffer_4,bufwrd)
          flag_4 := fw
          
    if _file == closing  '_file set to closing in SPI_binary via command from Pi
      sd.pclose
      fname := fname+1   'increment file name
      _file := closed
      
    if _file == closed   'set files to fw, enabling reader to write to buffers
      flag_1 := fw
      flag_2 := fw                  
      flag_3 := fw
      flag_4 := fw    

PUB minmax(lookit) | i, a, b, c, d       'function finding max and min of channel 1 and 2 from passed in buffer---lookit

  a := word[lookit][1]         'set a and c to first value of channel 1 for comparison
  b := word[lookit][2]         'set b and d to first value of channel 2 for comparison
  c := word[lookit][1]         
  d := word[lookit][2]

  repeat i from 1 to (buf - 2) step 3       'go through buffer in steps of three
    if word[lookit][i] > a   'max_1
      a := word[lookit][i]
    if word[lookit][i+1] > b 'max_2                                                 'something seems funky about this function
      b := word[lookit][i+1]
    if word[lookit][i] < c   'min_1
      c := word[lookit][i]
    if word[lookit][i+1] < d 'min_2
      d := word[lookit][i+1]
 
  max_1 := a
  max_2 := b       'set global max and min variables to values just set in local variables
  min_1 := c
  min_2 := d

PUB SPI_setup  'prepping SPI pins for communication  

  dira[mclk] := %0    'master clock set to input      
  dira[mosi] := %0    'master out slave in set to input
  dira[sclk] := %1    'slave clock set to output
  dira[miso] := %1    'master in slave out to set output
  outa[sclk] := %0    'slave clock initialized to low

PUB IO (highlow) : frompi | i    ' "SPI" code, (custom communication code, similar to SPI), sends one bit

  repeat while INA[mclk] == 0    'wait for master clock to go high (while == 0, next/wait)
    next
  
  outa[sclk] := %1           'once master clock is read as high, set slave clock to high

  outa[miso] := highlow     'set output, (master-in-slave-out) to either 1 or 0

  repeat while INA[mclk] == 1     'wait for master clock to go low
    next

  frompi := INA[mosi]        'read either a 1 or 0 in from Pi, (master-out-slave-in) -value returned by function
  
  outa[sclk] := %0          'once master clokc is read as low, set slave clock to low

PUB SPI_binary | localmax_1, localmax_2, localmin_1, localmin_2, command, continue, wait  

  pst.dec(9)    'serial write of 9 indicates startup of SPI_binary function/comm_cog
  pst.str(string(13))

  SPI_setup     'initializes pins for communication, setting inputs, outputs, sclk low

  repeat     'this loop repeats til shutdown
    
    command := (IO16(0)) 'send a zero to Pi, value returned is set as "command" 
    pst.str(string("command "))             
    pst.dec(command)               'serial write command
    pst.str(string(13))
    if command == 1               'if Pi sets command to 1, send current values of global max and min variables
      localmax_1 := max_1  'storing current values of maxs and mins into local variables for use in current data transfer
      localmin_1 := min_1
      localmax_2 := max_2
      localmin_2 := min_2                                                             

      IO16(localmax_1)                  'Utilize IO16 to send max and min of both channels to Pi
      pst.str(string("max1 "))             
      pst.dec(localmax_1)
      pst.str(string(13))
      IO16(localmin_1)
      pst.str(string("min1 "))                                                                                                                                        
      pst.dec(localmin_1)
      pst.str(string(13))
      IO16(localmax_2)
      pst.str(string("max2 "))
      pst.dec(localmax_2)
      pst.str(string(13))
      IO16(localmin_2)
      pst.str(string("min2 "))
      pst.dec(localmin_2)
      pst.str(string(13))          
      
    if command == 2                 'If command from Pi == 2, set _file to opening to start writing
      _file := opening
    if command == 3                 'If command from Pi == 3, set _file to closing to stop writing
      _file := closing
    if command == 4                 'If command from Pi == 4, start shutdown process
      if _file == open or _file == opening   'make sure _file status is set to closing
        _file := closing
      shutdownflag := _shutdown   'change status of operation flag to _shutdown
      quit

PUB IO16(x) : a | i     'function operating spi code for one bit, 16 times, results in construction of 16 bit value sent from Pi

  'x is 16 bit value to be sent to Pi
   
  a := 0    'function returns a, which will be constructed into number from Pi                         
  
  repeat i from 0 to 15
    a := a | IO(x & 1) << i    'bitwise or's a with bit from Pi, shifted i places to the left, sends one bit of x to Pi 
    x := x >> 1
    
DAT
' NOTE WELL: edited by a programmer who doesn't know what he's doing.  check carefully if this works.
' details: the original servo PWM assembly code seemed to set all output pins high/low at the PWM rate, which was messing up our ADC (and possibly SD card) outputs.
' the lines annotated "Set ServoPin high(?)" and "Set servopin low(?)" used to be movs with %FFFFFFFF and %00000000, if I (BEC) recall correctly

'The assembly program below runs on a parallel cog and checks the value of the "position" variable in the main Hub RAM (which
' other cogs can change at any time). It then outputs a servo high pulse for the "position" number of system clock ticks and
' sends a 10ms low part of the pulse. It repeats this signal continuously and changes the width of the high pulse as the
' "position" variable is changed by other cogs.

              org                         'Assembles the next command to the first cell (cell 0) in the new cog's RAM
SingleServo   or        dira,ServoPin      'Set the direction of the "ServoPin" to be an output (and leaves others as is)

Loop          rdlong    HighTime,par      'Read the "position" variable (at "par") from Main RAM and store it as "HighTime"
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

'AllOn         long      $FFFFFFFF         'WTF!?   This will be used to set all of the pins high (this number is 32 ones in binary)
'ServoMask     long      $FFFFFFFF         'needs to match ServoPin

LowTime       long      1_600_000         'This works out to be a 20ms pause time with an 80MHz system clock.
'LowTime       long      800_000          'This works out to be a 10ms pause time with an 80MHz system clock.
counter       res                         'Reserve one long of cog RAM for this "counter" variable
HighTime      res                         'Reserve one long of cog RAM for this "HighTime" variable
              fit                         'Makes sure the preceding code fits within cells 0-495 of the cog's RAM

fname         byte      "a",0

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
