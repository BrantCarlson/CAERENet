CON

{{
pseudo-SPI test code
}}

  ' clock settings
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  'pseudo-spi pins (see pcb/adcsd_shield_pinout.svg)
  SPI_MOSI = 0  ' master out slave in
  SPI_MISO = 2  ' master in slave out
  SPI_MCLK = 4  ' master clock
  SPI_SCLK = 6  ' slave clock

  buflen = 1024
  buflen_bytes = buflen * 2   'designates number of bytes in buffer, (buffer of words)

OBJ
  pst : "Parallax Serial Terminal"  ' debugging via USB cable to serial terminal
  
VAR
  word buffer_1[buflen]

PUB main | in, out
  pst.Start(115_200)     'start Parallax Serial Terminal
  waitcnt(5*clkfreq + cnt)  ' wait 5 seconds for PST startup on computer

  pst.str(string("SPI setup..."))
  pst.str(string(13,10))
  
  dira[SPI_MCLK] := %0    'master clock set to input      
  dira[SPI_MOSI] := %0    'master out slave in set to input
  dira[SPI_SCLK] := %1    'slave clock set to output
  dira[SPI_MISO] := %1    'master in slave out to set output
  outa[SPI_SCLK] := %0    'slave clock initialized to low

  pst.str(string("starting loop..."))
  pst.str(string(13,10))
  
  repeat 10
    out := 10
    in := IO16(out)
    pst.str(string("sent "))             
    pst.dec(out)
    pst.str(string(", got "))
    pst.dec(in)
    pst.str(string(13,10))

  pst.str(string("finished!"))
  pst.str(string(13,10))

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

