CON

{{
MCP3208 ADC test for ADC/SD shield
}}

  ' clock settings
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  'PIN ASSIGNMENTS
  'Note: Pin values in this document refer to propeller pin numbers, starting from 0.
  '      Pin values as listed on the QuickStart board start from 1, see QuickStart board docs.
  
  'adc pins (see pcb/adcsd_shield_pinout.svg)
  ADC_DPIN =  14 ' DIN and DOUT
  ADC_SPIN =  16 ' CS
  ADC_CPIN =  12 ' CLK

OBJ
  adc : "MCP3208"  ' ADC
  pst : "Parallax Serial Terminal"  ' debugging via USB cable to serial terminal
  
VAR
  long cogstack[150] 'designating space for cog startup

PUB main | tmp
  pst.Start(115_200)     'start Parallax Serial Terminal
  waitcnt(2*clkfreq + cnt)  ' wait 2 seconds for PST startup on computer

  pst.str(string("starting ADC"))
  pst.str(string(13,10))

  adc.start(ADC_DPIN,ADC_CPIN,ADC_SPIN,%00000001)
  'starts adc chip, %00000111 corresponds to enabled pins, (see "mode" in MCP3208.spin)

  repeat
    pst.str(string("0: "))
    pst.dec(adc.in(0))
    pst.str(string(13)) ' cr only, not crlf...  works well in xterm.

