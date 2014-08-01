import dataProc_cal as dp
import pandas as pd
import os
import scipy.optimize as op
from scipy.interpolate import interp1d
import scipy.signal as signal

def extractAmplitude(d,a1,a2,phi):
    """
    find the amplitude of a signal by finding peaks in waveforms and by taking the variance.
    """
    n = len(d.index)
    t = d['t'].values
    dt = t[1]-t[0]
    
    adc1 = d['adc0'].values
    adc2 = d['adc2'].values
    pg = d['adc1'].values
    
    b,a = signal.butter(4,1000.0/5500.0)
    adc1 = filtfilt(b,a,adc1)
    adc2 = filtfilt(b,a,adc2)
    pg = filtfilt(b,a,pg)
   
    # determine ts where sensor plates are maximally covered here.  (calibration info)
    pg = pg-mean(pg)
    pgB = pg>0
    pgi = find(logical_and(logical_and(pgB[1:-1],pgB[2:]),logical_not(pgB[:-2])))
    nrev = pgi.shape[0]-1
    pgTrans = t[pgi]
    
    tm1 = np.zeros(2*nrev); tm2 = np.zeros(2*nrev)
    tm1[0::2] = pgTrans[:-1] + (pgTrans[1:]-pgTrans[:-1])*phi/(2*pi)
    tm1[1::2] = pgTrans[:-1] + (pgTrans[1:]-pgTrans[:-1])*(phi+pi)/(2*pi)
    tm2[0::2] = pgTrans[:-1] + (pgTrans[1:]-pgTrans[:-1])*(phi+pi/2)/(2*pi)
    tm2[1::2] = pgTrans[:-1] + (pgTrans[1:]-pgTrans[:-1])*(phi+pi/2+pi)/(2*pi)
    im1 = searchsorted(t,tm1)
    im2 = searchsorted(t,tm2)

    #return t,adc1,adc2,tm1,tm2,pg
        
    v01a = np.zeros(2*(nrev-1))
    v02a = np.zeros(2*(nrev-1))
    v01b = np.zeros(2*(nrev-1))
    v02b = np.zeros(2*(nrev-1))
    var1 = np.zeros(2*(nrev-1))
    var2 = np.zeros(2*(nrev-1))
    
    nsamp = 15
    x = arange(-nsamp,nsamp+1)

    for i in xrange(2*(nrev-1)):
        a,b,c = polyfit(x, adc1[im1[i]-nsamp:im1[i]+nsamp+1], 2)
        v01a[i] = c
        a,b,c = polyfit(x, adc2[im2[i]-nsamp:im2[i]+nsamp+1], 2)
        v02a[i] = c
        a,b,c = polyfit(x, adc1[im2[i]-nsamp:im2[i]+nsamp+1], 2)
        v01b[i] = c
        a,b,c = polyfit(x, adc2[im1[i]-nsamp:im1[i]+nsamp+1], 2)
        v02b[i] = c
        var1[i] = var(adc1[im1[i]:im1[i+1]])
        var2[i] = var(adc2[im2[i]:im2[i+1]])

    return pd.DataFrame({'t':tm1[:-2],'v01a':v01a,'v01b':v01b,'v02a':v02a,'v02b':v02b,'var1':var1,'var2':var2})

def extractAmplitude_manyFiles(fns,blksize,nblk,a1,a2,phi):
    """
    read a bunch of files, extract amplitudes by fitting polynomials to peaks in the waveform and finding the variance.
    """
    x = pd.DataFrame()
    tmax = 0.0
    for fn in fns:
        nblk = min(os.stat(fn).st_size/4 / blksize, nblk)
        for i in xrange(1,nblk):
            a = dp.readData(fn,blksize,i*blksize)
            b = dp.interpAlign(a)
            c = extractAmplitude(b,a1,a2,phi)
            tm = c['t'].max()
            c['t'] = c['t']+tmax
            tmax = tm+tmax
            print "file",fn,"block",i,"of",nblk,"tmax:",tmax
            
            x = x.append(c)
    
    return x
