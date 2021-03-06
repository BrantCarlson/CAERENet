import numpy as np
import pandas as pd
import os
import scipy.optimize as op
import matplotlib.pyplot as plt
from scipy.interpolate import interp1d

def readArray32(filename,num_ints=np.inf,start_int=0):
    """Read an array of nothing but 32-bit integers using numpy's fromfile function."""
    num_ints = min(os.stat(filename).st_size/4-start_int,num_ints)
    with open(filename,'r') as f:
        f.seek(start_int*4)
        x = np.fromfile(f,np.uint32,num_ints)
    return x

def readArray(filename,num_ints=np.inf,start_int=0):
    """Read an array of nothing but 16-bit unsigned integers using numpy's fromfile function."""
    num_ints = min(os.stat(filename).st_size/2-start_int,num_ints)
    with open(filename,'r') as f:
        f.seek(start_int*2)
        x = np.fromfile(f,np.uint16,num_ints)
    return x

def splitData(x,b=1024):
    """Split data into start clock, end clock, and three channels according to a given buffer size (default 1024).  Returns a dictionary with keys 'start', 'end', 'd0', 'd1', and 'd2'"""
    n = x.shape[0]
    x = x.reshape(-1,b)
    start = x[:,1]*2**16 + x[:,0]
    end = x[:,-1]*2**16 + x[:,-2]
    return {'start':start,
            'end':end,
            'd0':x[:,2:-2:3].reshape(-1),
            'd1':x[:,3:-2:3].reshape(-1),
            'd2':x[:,4:-2:3].reshape(-1)}

def makeTimedDataFrame(d,t0=0.0):
    """Calculates timing information, makes 3 Pandas data frames, one for each channel.  returns a dictionary with keys 0, 1, and 2.
    Entries of dictionaries are data frames with columns 't' and 'adc'."""
    nb = d['start'].shape[0] # number of buffers
    n0 = d['d0'].shape[0]/nb # number of channel 0 samples per buffer
    n1 = d['d1'].shape[0]/nb # likewise for channel 1
    n2 = d['d2'].shape[0]/nb # likewise for channel 2
    bl = n0+n1+n2+2 # buffer length (i.e. 1024)

    # setup sW (start time, un-wrapped), a floating point representation of the clock, with offsets added for clock overflow / restart
    sW = np.zeros(d['start'].shape)
    sW[1:] = np.cumsum(d['start'][1:] < d['start'][0:(nb-1)])*2**32
    sW = d['start'] + sW

    # likewise for end time, un-wrapped.
    eW = np.zeros(d['end'].shape)
    eW[1:] = np.cumsum(d['end'][1:] < d['end'][0:(nb-1)])*2**32
    eW = d['end'] + eW

    # some constants for conversion from clock time (32-bit integer) to real time (in seconds)
    startDelay = 0  # number of clocks after start is written before first sample in buffer is acquired
    endDelay = 0    # likewise for clocks after last sample before end clock is written.
    clockFreq = 80.0e6 # 80 MHz clock
    startTime = sW[0]
    sampleTime = (eW[0]-sW[0])/bl # offset from sampling of channel 0 to channel 1.  should be about eW[0]-sW[0])/(buffer length

    # set up time arrays for real time
    tc0 = np.zeros(d['d0'].shape)
    tc1 = np.zeros(d['d1'].shape)
    tc2 = np.zeros(d['d2'].shape)

    # fill time arrays with times interpolated between start and end unwrapped times, offset and converted to seconds.
    for i in xrange(nb):
        tc0[(i*n0):((i+1)*n0)] = (np.linspace(sW[i]+startDelay,eW[i]-endDelay,n0)-startTime)/clockFreq + t0
        tc1[(i*n1):((i+1)*n1)] = (np.linspace(sW[i]+startDelay,eW[i]-endDelay,n1)-startTime+sampleTime)/clockFreq + t0
        tc2[(i*n2):((i+1)*n2)] = (np.linspace(sW[i]+startDelay,eW[i]-endDelay,n2)-startTime+2*sampleTime)/clockFreq + t0

    return {0:pd.DataFrame({'t':tc0,'adc':d['d0']}),
            1:pd.DataFrame({'t':tc1,'adc':d['d1']}),
            2:pd.DataFrame({'t':tc2,'adc':d['d2']})}


def readData(filename,num_ints=np.inf,start_int=0,bufferLength=1024,t0=0.0):
    """Reads in data, splits it into channels, and associates a time in seconds."""
    return makeTimedDataFrame(splitData(readArray(filename,num_ints=num_ints,start_int=start_int),bufferLength),t0=t0)

def interpAlign(tdf):
  """linearly interpolates channel 1 and channel 2 to match channel 0's timing"""
  return pd.DataFrame({
    't':tdf[0]['t'],
    'adc0':tdf[0]['adc'],
    #'adc1':interp1d(tdf[1]['t'],tdf[1]['adc'],kind='cubic')(tdf[0]['t']),
    #'adc2':interp1d(tdf[2]['t'],tdf[2]['adc'],kind='cubic')(tdf[0]['t'])})
    'adc1':np.interp(tdf[0]['t'],tdf[1]['t'],tdf[1]['adc']),
    'adc2':np.interp(tdf[0]['t'],tdf[2]['t'],tdf[2]['adc'])})

def cycleShape(d,segSize=500):
    """takes a pandas data frame with adc and t columns, returns a pandas data frame with t, amp, and midpt columns,
    where amp refers to the amplitude of the oscillation, and midpt refers to the midpoint (halfway between max and min)."""
    n = d.adc.shape[0]
    assert n % segSize == 0, "total size (%d) not divisble by segSize (%d)."%(n,segSize)
    adcSegs = d.adc.reshape((-1,segSize))
    tSegs = d.t.reshape((-1,segSize))
    return pd.DataFrame({'t':tSegs.mean(1),'amp':adcSegs.max(1)-adcSegs.min(1),'midpt':(adcSegs.max(1)+adcSegs.min(1))/2})



def fitSeg(t1,a1,t2,a2,makePlot=False):
    maxAmp1 = 1.2*(np.max(a1)-np.min(a1))/2.0
    maxAmp2 = 1.2*(np.max(a2)-np.min(a2))/2.0
    buf = np.zeros(t1.shape[0]+t2.shape[0])
    def fit(midpt,ampX,omega,t0,t,mxA):
        return midpt + mxA*np.tanh(ampX)*np.cos(omega*(t+t0))
    def err2(p,t1,y1,t2,y2):
        buf[0:t1.shape[0]] = fit(p[0],p[1],p[2],p[3],t1,maxAmp1) - y1
        buf[t1.shape[0]:] = fit(p[4],p[5],p[2],p[3],t2,maxAmp2) - y2
        return buf

    p0 = np.array([(np.max(a1)+np.min(a1))/2.0,
      1.2,
      2*np.pi*50.0,
      t1[a1.idxmax()],
      (np.max(a2)+np.min(a2))/2.0,
      -1.2])
    p00 = p0.copy()

    p1, success = op.leastsq(err2,p0,args=(t1,a1,t2,a2))

    if makePlot:
      plt.plot(t1,a1)
      plt.plot(t2,a2)
      plt.plot(t1,fit(p[0],p1[1],p1[2],p1[3],t1,maxAmp1))
      plt.plot(t2,fit(p[4],p1[5],p1[2],p1[3],t2,maxAmp2))

    p1[1] = maxAmp1*np.tanh(p1[1])
    p1[5] = maxAmp2*np.tanh(p1[5])

    return p1

def fitSegs(t1,a1,t2,a2,seglen=340): #340 comes from (1024 - 2) / 3
    n = t1.shape[0]
    #assert n % seglen == 0, "seglen (%d) doesn't divide array length (%d)."%(seglen,n)
    nseg = n/seglen
    #t = t.reshape((-1,seglen))
    #a = a.reshape((-1,seglen))
    p = np.zeros((nseg,6+4+1)) # 6 parameters from 2-channel fit, 4 from 2-channel minmax amp and midpt, and 1 for time

    for i in xrange(nseg):
        tmin = t1[i*seglen]
        tmax = t1[min((i+1)*seglen-1,n)]
        p[i,0] = tmin
        if(tmax-tmin > (seglen/10000.0)*2): #if this chunk of data contains a big glitch,
            p[i,1:] = np.nan
            continue

        m1 = np.logical_and(t1>tmin,t1<tmax)
        ts1 = t1[m1]
        as1 = a1[m1]

        m2 = np.logical_and(t2>tmin,t2<tmax)
        ts2 = t2[m2]
        as2 = a2[m2]

        p[i,1:7] = fitSeg(ts1,as1,ts2,as2)

        p[i,7] = (max(as1)-min(as1))/2.0
        p[i,8] = (max(as1)+min(as1))/2.0

        p[i,9] = (max(as2)-min(as2))/2.0
        p[i,10] = (max(as2)+min(as2))/2.0

    return pd.DataFrame(p,columns=['t','m1','a1','omega','t0','m2','a2','mma1','mmm1','mma2','mmm2'])

def fitSegs_qnd(t0,a0,t1,a1,t2,a2,segLen=340*4): #340 = (1024 - 2(start clk storage) - 2 (end clk storage))/3 (channels per buffer)
    """qnd = quick and dirty.  no actual fitting."""
    n = t1.shape[0]
    nseg = n/segLen
    p = np.zeros((nseg,10))

    # TODO: use t0, a0 (photogate signals) to assign a polarity.

    for i in xrange(nseg):
        i1 = i*segLen
        i2 = min((i+1)*segLen-1,n)
        tmin = t1.iloc[i1]
        tmax = t1.iloc[i2]
        p[i,0] = tmin
        p[i,1] = tmax
        if(tmax-tmin > (segLen/10000.0)*2): #if this chunk of data contains a big glitch,
            p[i,1:] = np.nan
            continue

        ts1 = t1.iloc[i1:i2]
        as1 = a1.iloc[i1:i2]
        ts2 = t2.iloc[i1:i2]
        as2 = a2.iloc[i1:i2]

        p[i,2] = as1.min()
        p[i,3] = as1.max()
        p[i,4] = p[i,3]-p[i,2]
        p[i,5] = as1.var()
        p[i,6] = as2.min()
        p[i,7] = as2.max()
        p[i,8] = p[i,7]-p[i,6]
        p[i,9] = as2.var()

    return pd.DataFrame(p,columns=['t1','t2','min1','max1','mmm1','var1','min2','max2','mmm2','var2'])

def procBigFile(filename,cpg=0,cch1=1,cch2=2,bufsize=1024,func=fitSegs_qnd,t0=0.0):
    """use fitSegs_qnd for method if desired."""
    num_ints = os.stat(filename).st_size/2  #NOTE: assuming 16-bit integers here!
    nb = num_ints/bufsize # number of buffers in file
    nbp = 1024*4 # number of BUFFERS per chunk
    ps = []
    for i in xrange(0,num_ints,nbp*bufsize):
        print "processing %d of %d, %f"%(i/bufsize,num_ints/bufsize,t0)
        x = readData(filename,nbp*bufsize,i,bufsize,t0)
        p2 = func(x[cpg].t,x[cpg].adc,
                x[cch1].t,x[cch1].adc,
                x[cch2].t,x[cch2].adc)
        ps.append(p2)
        t0 = p2.t2.iloc[-1]+(p2.t1.iloc[2]-p2.t1.iloc[1])
    return pd.concat(ps)

def procBigFiles(fns):
    dfs = []
    t0 = 0.0
    for f in fns:
        dfs.append(procBigFile(f,t0=t0))
        t0 = dfs[-1].t2.max()
    return pd.concat(dfs)
