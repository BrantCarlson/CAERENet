CON

{{
pseudo-SPI speed test code

test results with wiringPi (C code) version on RPi:
send/recieve 10 16-bit numbers:
real: 0.166, 0.166, 0.168
user: 0.05, 0.06, 0.05
sys: 0.03, 0.01, 0.02

send/receive 1000 16-bit numbers:
real: 1.738, 1.717, 1.714
user: 1.590, 1.590, 1.590
sys: 0.02, 0.02, 0.02

send/receive 10000 16-bit numbers:
real: 15.759, 15.728, 15.722
user: 15.480, 15.530, 15.510
sys: 0.07, 0.02, 0.04

rate calculation: (1000-10)/(1.72-0.16) = 634 16-bit numbers per second
rate calculation: (10000-1000)/(15.73-1.72) = 642 16-bit numbers per second

overall bit rate: ~635*16 = 10000 bits/second


test results with Python version on RPi:
send/recieve 10 16-bit numbers:
real: 1.866, 1.834, 1.817
user: 1.64, 1.62, 1.59
sys: 0.14, 0.14, 0.14

send/receive 1000 16-bit numbers:
real: 3.64, 3.69, 3.669
user: 3.39, 3.42, 3.47
sys: 0.15, 0.17, 0.11

send/receive 10000 16-bit numbers:
real: 20.923, 20.395, 20.950
user: 20.67, 20.070, 20.72
sys: 0.07, 0.16, 0.06

rate calculation: (1000-10)/(3.67 - 1.84) = 540 16-bit numbers per second
rate calculation: (10000-1000)/(20.6 - 3.67) = 530 16-bit numbers per second

That's actually comparable to the C version.  Strange.

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
  waitcnt(2*clkfreq + cnt)  ' wait 2 seconds for PST startup on computer

  pst.str(string("SPI setup..."))
  pst.str(string(13,10))
  
  dira[SPI_MCLK] := %0    'master clock set to input      
  dira[SPI_MOSI] := %0    'master out slave in set to input
  dira[SPI_SCLK] := %1    'slave clock set to output
  dira[SPI_MISO] := %1    'master in slave out to set output
  outa[SPI_SCLK] := %0    'slave clock initialized to low

  pst.str(string("starting loop..."))
  pst.str(string(13,10))
  
  out := 13
  repeat 10000
    in := IO16(out)

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

