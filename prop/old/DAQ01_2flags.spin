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
  long  counter
  'long tst[128]

PUB main | insert_card, text, value, i, flag

  waitcnt(clkfreq*5 + cnt)
  'pst.Start(115200)                                                             ' Start the Parallax Serial Terminal cog

  adc.start(DPIN,CPIN,SPIN,2)


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
  counter := 0


  reader_cog := cognew (reader, @cogstack[0])
  writer_cog := cognew (writer, @cogstack[50])

  repeat until counter == count
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




PUB reader | i

  repeat until counter == count
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

  repeat until counter == count
    if flag_1 == f
      sd.pwrite(@buffer_1,buflng)
      flag_1 := fw
      counter := counter +1
    if flag_2 == f
      sd.pwrite(@buffer_2,buflng)
      flag_2 := fw
      counter := counter + 1


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

