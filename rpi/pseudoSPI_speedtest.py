# code for min/max communication with prop.spin
import RPi.GPIO as GPIO
import numpy as np

mosi = 11
miso = 12
mclk = 13
sclk = 15

def setup():
    GPIO.setmode(GPIO.BOARD)
    GPIO.setwarnings(False)
    GPIO.setup(mclk,GPIO.OUT, initial=GPIO.LOW)
    GPIO.setup(mosi,GPIO.OUT)
    GPIO.setup(sclk,GPIO.IN)
    GPIO.setup(miso,GPIO.IN)

def shutdown():
    GPIO.cleanup()

def IO1(dataout):
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
        datain = datain | IO1(dataout & 1)<<i

        dataout = dataout >> 1
        
        i = i + 1

    return datain

def runMe():
    setup()
    out = 15
    for i in xrange(10000):
        inp = IO16(out)
        #print("sent",out,"got",inp)
    shutdown()

runMe()
