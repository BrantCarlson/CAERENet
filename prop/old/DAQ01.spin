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

  buf = 256
  buflng = buf * 4
OBJ

  pst    : "Parallax Serial Terminal"
  adc   : "MCP3208"                 ' Serial communication object
  sd    : "fsrw"
  num   : "Numbers"
VAR
  long  buffer[buf]
  long  cogstack[100]
  'long tst[128]

PUB go | insert_card, text, value, i

  pst.Start(115200)                                                             ' Start the Parallax Serial Terminal cog

  adc.start(DPIN,CPIN,SPIN,2)

''---------------- Replace the code below with your test code ----------------

  insert_card := \sd.mount_explicit(D0, CLK, DI, CS)        ' Here we call the 'mount' method using the 4 pins described in the 'CON' section.
  if insert_card < 0                                           ' If mount returns a zero...
    pst.str(string(13))                                        ' Print a carriage return to get a new line.
    pst.str(string("The Micro SD Card was not found!"))        ' Print the failure message.
    pst.str(string(13))                                        ' Carriage return...
    pst.str(string("Insert card, or check your connections.")) ' Remind user to insert card or check the wiring.
    pst.str(string(13))                                        ' And yet another carriage return.
    abort                                                      ' Then we abort the program.

  pst.str(string(13))
  pst.str(string("Micro SD card was found!"))                  ' Let the user know the card is properly inserted.
  pst.str(string(13))

  sd.popen(string("output.txt"), "w")  ' Open output.txt, a text file, to receive your line of text.
                                          ' Change "a" to "w" if you want to overwrite the text each time.
                                          ' The "a" option will append text to the end of the file every time you write to it.
  'repeat i from 0 to 128
    'tst[i] := 0
  'tst[0] := 1
  'sd.pwrite(@tst,512)
  'repeat 100000                                                                ' Main loop


    'value :=adc.in(1)
    'sd.pputs(num.ToStr(value,%1010))
    'sd.pputs(string(13))
    'sd.pputs((value))
    'sd.pputs(string("abcdefghijklmnopqrstuvwxyz"))
  repeat 100
    repeat i from 0 to buf                                                                ' Main loop

      buffer[i] :=adc.in(1)
    sd.pwrite(@buffer,buflng)
    'sd.pputs(num.ToStr(value,%1010))
    'sd.pputs(string(13))
    'sd.pputs((value))
    'sd.pputs(string("abcdefghijklmnopqrstuvwxyz"))
    'pst.Dec(i)
  sd.pclose

  pst.str(string(13))                     ' In this section, we let the user know that the file write has been completed:
  pst.str(string("Text was written to your output file on the Micro SD Card"))
  pst.str(string(13))

  sd.unmount                           ' This line dismounts the card so you can safely remove it.

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
