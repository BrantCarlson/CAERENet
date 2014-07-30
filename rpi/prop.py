import RPi.GPIO as GPIO
import numpy as np

mclk = 7
mosi = 11
sclk = 13
miso = 15


GPIO.setmode(GPIO.BOARD)
GPIO.setwarnings(False)
GPIO.setup(mclk,GPIO.OUT, initial=GPIO.LOW)
GPIO.setup(mosi,GPIO.OUT)
GPIO.setup(sclk,GPIO.IN)
GPIO.setup(miso,GPIO.IN)

n = 100000
datain = np.zeros(n)
dataout=np.zeros(n)
dataout[::2] = 1
i = 0


while i < n:
	GPIO.output(mclk, GPIO.HIGH)
	while GPIO.input(sclk) == 0:
                continue

        if dataout[i]==1:
                GPIO.output(mosi,GPIO.HIGH)
        else:
                GPIO.output(mosi,GPIO.LOW)
        GPIO.output(mclk, GPIO.LOW)

	while GPIO.input(sclk) == 1:
                continue

	datain[i] = GPIO.input(miso)

        i = i + 1

GPIO.cleanup()

a = 0
b = 10

while a < b:
        print(datain[a])
        a = a + 1
