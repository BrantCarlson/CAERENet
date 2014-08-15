# code for min/max communication with prop.spin
import RPi.GPIO as GPIO
import numpy as np

# communications pins
# note that since the GPIO init is called with GPIO.BOARD mode,
# these pin numbers correspond to the header on the physical RPi board.
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

def IOarray(dataout, passes):
    j = 0
    k = passes

    values = np.zeros(k)

    while j < k:
        values[j] = IO16(0)

        j = j + 1

    return values

def clamp(n, minn, maxn):
    if n < minn:
        return minn
    elif n > maxn:
        return maxn
    else:
        return n

threshold = 8 #(no idea what this should be): value at which amplitude should be marked as interesting
high = 50       #set range for interesting count
low = 0


def talkingtoProp(numcycles):
    count = -1 #prep count to represent index of array
    
    thrct = 0
    collectcount = 0
    smallestwritecount = 5

    runcount = 0

    running = True #wait for shutdown call from GUI?

    writing = False #wait for interesting data
    
    while running == True:
        IO16(1)         #give command to Prop to send maxs and mins

        i = 0
        n = 4

        mx1 = IO16(0)
        mn1 = IO16(0)
        mx2 = IO16(0)
        mn2 = IO16(0)
        print "max1 %d, min1 %d, max2 %d, min2 %d"%(mx1,mn2,mx2,mn2)

        ch1amp = mx1-mn1
        ch2amp = mx2-mn2

        print 'ch1amp = ', ch1amp
        print 'ch2amp = ', ch2amp

        # processes amplitudes, judge if interesting or not
        if ch1amp > threshold:
            thrct = thrct + 1 
        else:
            thrct = thrct - 1
                
        if ch2amp > threshold:
            thrct = thrct + 1
        else:
            thrct = thrct - 1

        thrct = clamp(thrct, low, high) #limit interesting count to range 0-50

        if thrct > 50:       #change status of collect according to thrct value
            collect = True
        if thrct < 10:
            collect = False

        if collect == True:     #if collecting, count number of times gone through loop while collect = true
            collectcount = collectcount + 1
        
        if collect == True and writing != True: #if collect is true and we aren't already writing send command to prop to start writing, set writing true
            IO16(2)
            writing = True
            print 'writing file'
        if collect == False and writing == True and collectcount > smallestwritecount: #if collect is false and we are writing send command to prop...
            IO16(3)                                                         #...to stop writing, and we have run through the loop at least... 
            writing = False                                                 #...smallestwrite count times, set writing false
            print 'closing file'
                
        print 'interesting count = ', thrct

        runcount = runcount + 1

        if runcount >= numcycles:
            running = False
            
    if running == False: #GUI will send command to change running status?
        IO16(4) #if running = false, tell Prop to shutdown

def runMe():
    setup()
    talkingtoProp(50)
    shutdown()
