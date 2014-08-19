CON
{{
Use DAQ02:4flags:esc
}}
  _clkmode = xtal1 + pll16x                             ' Crystal and PLL settings.
  _xinfreq = 5_000_000                               ' 5 MHz crystal (5 MHz x 16 = 80 MHz).

  CS  = 3       ' Propeller Pin 3 - Set up these pins to match the Parallax Micro SD Card adapter connections.
  DI  = 2       ' Propeller Pin 2 - For additional information, download and refer to the Parallax PDF file for the Micro SD Adapter.
  CLK = 1       ' Propeller Pin 1 - The pins shown here are the correct pin numbers for my Micro SD Card adapter from Parallax
  D0  = 0       ' Propeller Pin 0 - In addition to these pins, make the power connections as shown in the following comment block.
  SPIN = 17
  DPIN = 19
  CPIN = 20
  Servo_Pin = 22

  buf = 2048
  buflng = buf * 4
  count = 1000
  f = 0
  fw = 1
  done = 2
OBJ

  'pst    : "Parallax Serial Terminal"
  adc   : "MCP3208"                 ' Serial communication object
  sd    : "fsrw"
  num   : "Numbers"
VAR
  long  buffer_1[buf]
  long  buffer_2[buf]
  long  cogstack[100]
  long  reader_cog, writer_cog
  byte  flag_1
  byte  flag_2
  long  buffcounter
  long  position
  'long tst[128]

PUB main | insert_card, text, value, i, flag

  waitcnt(clkfreq*5 + cnt)
  'pst.Start(115200)                                                             ' Start the Parallax Serial Terminal cog

  adc.start(DPIN,CPIN,SPIN,2)

  dira[23] := %1
  outa[23] := %1

  insert_card := \sd.mount_explicit(D0, CLK, DI, CS)
  if insert_card < 0
    'pst.str(string(13))
    'pst.str(string("Mike you're a fuckhead!"))
    abort
  'pst.str(string(13))
  'pst.str(string("Found Carmen Sandiego!"))
  'pst.str(string(13))

  sd.popen(string("output.txt"), "w")  ' Open output.txt, a text file, to receive your line of text.
                                          ' Change "a" to "w" if you want to overwrite the text each time.
  waitcnt(clkfreq*5 + cnt)

  flag_1 := fw
  flag_2 := fw
  buffcounter := 0
  position := 80_000

  cognew(@SingleServo,@position)
  reader_cog := cognew (reader, @cogstack[0])
  writer_cog := cognew (writer, @cogstack[50])

  repeat until buffcounter == count
    waitcnt(50_000 + cnt)
    'pst.Dec (counter)
    'pst.str(string(13))
  'cogstop (reader)
  'cogstop (writer)
  sd.pclose

  'pst.str(string(13))
  'pst.str(string("Take the hampster out of the toaster!"))
  'pst.str(string(13))

  sd.unmount

  outa[23] := %0


PUB reader | i

  repeat until buffcounter == count
    if flag_1 == fw
      buffer_1[0] := cnt
      repeat i from 1 to (buf-1)
        buffer_1[i] :=adc.in(1)
      buffer_1[buf-1] := cnt
      flag_1 := f
    if flag_2 == fw
      buffer_2[0] := cnt
      repeat i from 1 to (buf-1)
        buffer_2[i] :=adc.in(1)
      buffer_2[buf-1] := cnt
      flag_2 := f


PUB writer

  repeat until buffcounter == count
    if flag_1 == f
      sd.pwrite(@buffer_1,buflng)
      flag_1 := fw
      buffcounter := buffcounter +1
    if flag_2 == f
      sd.pwrite(@buffer_2,buflng)
      flag_2 := fw
      buffcounter := buffcounter + 1


DAT
'The assembly program below runs on a parallel cog and checks the value of the "position" variable in the main Hub RAM (which
' other cogs can change at any time). It then outputs a servo high pulse for the "position" number of system clock ticks and
' sends a 10ms low part of the pulse. It repeats this signal continuously and changes the width of the high pulse as the
' "position" variable is changed by other cogs.

              org                         'Assembles the next command to the first cell (cell 0) in the new cog's RAM
SingleServo   mov       dira,ServoPin     'Set the direction of the "ServoPin" to be an output (and all others to be inputs)

Loop          rdlong    HighTime,par      'Read the "position" variable (at "par") from Main RAM and store it as "HighTime"
              mov       counter,cnt       'Store the current system clock count in the "counter" cell's address
              mov       outa,AllOn        'Set all pins on this cog high (really only sets ServoPin high b/c rest are inputs)
              add       counter,HighTime  'Add "HighTime" value to "counter" value
              waitcnt   counter,LowTime   'Wait until "cnt" matches "counter" then add a 10ms delay to "counter" value
              mov       outa,#0           'Set all pins on this cog low (really only sets ServoPin low b/c rest are inputs)
              waitcnt   counter,0         'Wait until cnt matches counter (adds 0 to "counter" afterwards)
              jmp       #Loop             'Jump back up to the cell labled "Loop"

'Constants and Variables:
ServoPin      long      |< Servo_Pin      '<------- This sets the pin that outputs the servo signal (which is sent to the white wire
                                          ' on most servomotors). Here, this "7" indicates Pin 7. Simply change the "7"
                                          ' to another number to specify another pin (0-31).
AllOn         long      $FFFFFFFF         'This will be used to set all of the pins high (this number is 32 ones in binary)
LowTime       long      1_600_000         'This works out to be a 20ms pause time with an 80MHz system clock.
'LowTime       long      800_000          'This works out to be a 10ms pause time with an 80MHz system clock.
counter       res                         'Reserve one long of cog RAM for this "counter" variable
HighTime      res                         'Reserve one long of cog RAM for this "HighTime" variable
              fit                         'Makes sure the preceding code fits within cells 0-495 of the cog's RAM

{{

┌──────────────────────────────────────────────────────────────────────────────────────┐
│                           TERMS OF USE: MIT License                                  │
├──────────────────────────────────────────────────────────────────────────────────────┤
│Permission is hereby granted, free of charge, to any person obtaining a copy of this  │
│software and associated documentation files (the "Software"), to deal in the Software │
│without restriction, including without limitation the rights to use, copy, modify,    │
│merge, publish, distribute, sublicense, and/or sell copies of the Software, and to    │
│permit persons to whom the Software is furnished to do so, subject to the following   │
│conditions:                                                                           │                                            │
│                                                                                      │                                               │
│The above copyright notice and this permission notice shall be included in all copies │
│or substantial portions of the Software.                                              │
│                                                                                      │                                                │
│THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED,   │
│INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A         │
│PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT    │
│HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION     │
│OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE        │
│SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.                                │
└──────────────────────────────────────────────────────────────────────────────────────┘
}}
