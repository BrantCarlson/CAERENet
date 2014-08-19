CON

{{
This is a basic program that can be used to talk to the raspberry pi. just an example on how it can be done It sends and receives
a bit every clock cycle. It depends on the signal sent from the raspberry pi wo work.
}}

  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  mclk = 0
  MOSI = 2
  sclk = 4
  MISO = 6

OBJ

  pst   : "Parallax Serial Terminal"

PUB main | temp, i

  pst.Start(115_200)
  waitcnt(clkfreq + cnt)
  dira[mclk] := %0
  dira[MOSI] := %0
  dira[sclk] := %1
  dira[MISO] := %1
  outa[sclk] := %0

  repeat i from 1 to 100000
    repeat while INA[mclk] == 0
      next
    'pst.str(string("a"))
    'pst.str(string(13))

    outa[sclk] := %1
    'pst.str(string("b"))
    'pst.str(string(13))

    outa[MISO] := i & 1
    'pst.str(string("c"))
    'pst.str(string(13))

    repeat while INA[mclk] == 1
      next
    'pst.str(string("d"))
    'pst.str(string(13))

    temp := INA[MOSI]
    'pst.dec(temp)
    'pst.str(string(13))

    outa[sclk] := %0
    'pst.str(string("f"))
    'pst.str(string(13))

  pst.str(string("done"))


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

