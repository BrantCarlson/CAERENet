CON

{{
Carthage Field Mill Code Summer 2014
Michael Brusich and Aaron Scheets, supervised by Brant Carlson
This program:
- controls the ESC for an brushless motor to spin the motor.
no data is collected by this program, as appropriate for basic preamp sanity check experiments.
}}

  ' clock settings
  _clkmode = xtal1 + pll16x
  _xinfreq = 5_000_000

  'PIN ASSIGNMENTS
  'Note: Pin values in this document refer to propeller pin numbers, starting from 0.
  '      Pin values as listed on the QuickStart board start from 1, see QuickStart board docs.
  
  'indicator LED (set to one of the pins on the QuickStart that has an LED attached)
  IndicatorLED = 23

  'ESC control PWM pin (see assembly code at bottom)
  Servo_Pin = 1

OBJ
  pst : "Parallax Serial Terminal"  ' debugging via USB cable to serial terminal
  
VAR
  'motor control variable
  long speed   ' 80000 -> ESC off, 86857 -> 1500rpm -> 25 Hz -> 50 Hz for cover/uncover cycle of mill electrodes

  long cogstack[150] 'designating space for cog startup
  long servo_cog

PUB main
  dira[IndicatorLED] := %1  'set indicator LED pin as output
  outa[IndicatorLED] := %1  ' and turn the LED on

  pst.Start(115_200)     'start Parallax Serial Terminal

  waitcnt(3*clkfreq + cnt)  ' wait 3 seconds for PST startup on computer

  pst.str(string("starting ESC"))
  pst.str(string(13,10))
  
  speed := 80_000                   'sets esc to idle
  servo_cog := cognew(@SingleServo,@speed)       'opens new cog for ESC

  waitcnt(2*clkfreq + cnt)  ' wait 5 seconds for PST startup on computer

  'speed := 84_800  'starts ESC, 86857=1500rpm
  speed := 86857  'starts ESC, 86857=1500rpm

  pst.str(string("startup completed"))
  pst.str(string(13,10))

  waitcnt(10*clkfreq + cnt)  ' wait 5 seconds for PST startup on computer

  shutdown
  

PUB shutdown | i
  pst.str(string("shutting down"))
  pst.str(string(13,10)) 
  
  speed := 80_000                       'sets esc to idle

  cogstop(servo_cog)

  pst.str(string("shut down"))
  pst.str(string(13,10)) 
  
  outa[IndicatorLED] := %0 ' turn indicator LED off

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
