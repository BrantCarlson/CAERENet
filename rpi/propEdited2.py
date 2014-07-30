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

def talkingtoProp(valuesfromprop):

        threshold = 8 #(no idea what this should be): value at which amplitude should be marked as interesting

        count = -1 #prep count to represent index of array
        
        interestingcount = 0
        high = 50       #set range for interesting count
        low = 0

        collectcount = 0
        smallestwritecount = 5

        runcount = 0

        running = True #wait for shutdown call from GUI?

        writing = False #wait for interesting data
        
        while running == True:

##                wait = 0
##
##                while wait != 7:
##                        wait = IO16(7)
##                        print wait
##
##                IO16(36)
##                IO16(36)
                
                IO16(1)         #give command to Prop to send maxs and mins

                i = 0
                n = 4

                while i < n:            #add max1, min1, max2, min2, from prop into array in that order

                        current = IO16(0)
                        
                        valuesfromprop.append(current)

                        i = i + 1

                        count = count + 1

                        print valuesfromprop[count]
                        print 'end of loop'

                channel1amplitude = valuesfromprop[count - 3] - valuesfromprop[count - 2]       #calculate channel amplitudes according to last four added values
                channel2amplitude = valuesfromprop[count - 1] - valuesfromprop[count]

                print 'channel1amplitude = ', channel1amplitude
                print 'channel2amplitude = ', channel2amplitude

                if channel1amplitude > threshold:               #adjust interesting count according to channel amplitudes and relation to threshold value 
                        interestingcount = interestingcount + 1 
                else:
                        interestingcount = interestingcount - 1
                        
                if channel2amplitude > threshold:
                        interestingcount = interestingcount + 1
                else:
                        interestingcount = interestingcount - 1

                interestingcount = clamp(interestingcount, low, high) #limit interesting count to range 0-50

                if interestingcount > 25:       #change status of collect according to interestingcount value
                        collect = True
                else:
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
                        
                print 'interesting count = ', interestingcount
                print 'whatup'

                runcount = runcount + 1

##                wait = 0
##
##                while wait != 7:
##                        wait = IO16(7)
##                        print wait
##
##                IO16(36)
##                IO16(36)

                if runcount > 15:
                        running = False
                
        if running == False: #GUI will send command to change running status?
                IO16(4) #if running = false, tell Prop to shutdown

        return valuesfromprop #return array full of maxs and mins
                

setup()

maxsandmins = []

talkingtoProp(maxsandmins)

GPIO.cleanup()







print "hello AARON"
