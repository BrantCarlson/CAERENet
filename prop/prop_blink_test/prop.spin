CON

  ' clock settings
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  'indicator LED (set to one of the pins on the QuickStart that has an LED attached)
  IndicatorLED = 23

OBJ
  pst : "Parallax Serial Terminal"  ' debugging via USB cable to serial terminal
  
'VAR
' nothing in the var block here

PUB main
  dira[IndicatorLED] := %1  'set indicator LED pin as output

  pst.Start(115_200)     'start Parallax Serial Terminal

  repeat while true
    outa[IndicatorLED] := %1  ' and turn the LED on
    waitcnt(1*clkfreq + cnt)
    outa[IndicatorLED] := %0  ' and turn the LED off
    waitcnt(1*clkfreq + cnt)
    pst.str(string("hello!"))
    pst.str(string(13,10))

'  
'
'  pst.str(string("startup completed"))
'  pst.str(string(13,10))

'DAT
' no dat block here either
