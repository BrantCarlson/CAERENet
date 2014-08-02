# medium-level GPIO pseudo-SPI code

import RPi.GPIO as GPIO
import numpy as np

mclk = 7
mosi = 11
sclk = 13
miso = 15

def setup():
        GPIO.setmode(GPIO.BOARD)
        GPIO.setwarnings(False)
        GPIO.setup(mclk,GPIO.OUT, initial=GPIO.LOW)
        GPIO.setup(mosi,GPIO.OUT)
        GPIO.setup(sclk,GPIO.IN)
        GPIO.setup(miso,GPIO.IN)
def IO1(command):

        dataout = command
        
        GPIO.output(mclk, GPIO.HIGH)
        while GPIO.input(sclk) == 0:
                continue

        if dataout == 1:
                GPIO.output(mosi,GPIO.HIGH)
        else:
                GPIO.output(mosi,GPIO.LOW)
        GPIO.output(mclk, GPIO.LOW)

        while GPIO.input(sclk) == 1:
                continue

        datain = GPIO.input(miso)

        return datain
        
def IO16(dataout):
        n = 16
        i = 0
        datain = 0
        
        while i < n:

                datain = datain | IO1(0)<<i
                
                i = i + 1

        return datain

def IO(dataout, passes):
        j = 0
        k = passes

        values = np.zeros(k)

        while j < k:
                
                values[j] = IO16(0)

                j = j + 1

        return values

def findmaxmin():
        maxx = IO16(1)
        minn = IO16(0)

        return maxx, minn         


setup()

print np.all(IO(0, 20)==43690)

GPIO.cleanup()








print "hello AARON"
