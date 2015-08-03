module R

using DataFrames

const bufsize=1024
const clkfreq = 80.0e6
const nchan = 3
const nsampPerChanPerBuf = div((bufsize-4),nchan)

function readData(fn)
  nbytes = stat(fn).size
  nbufs = div(nbytes,2*bufsize)
  a = read(open(fn),Uint16,(bufsize,nbufs))
  ts = [(a[2,i]*2^16+a[1,i])/clkfreq for i=1:nbufs]
  te = [(a[bufsize,i]*2^16+a[bufsize-1,i])/clkfreq for i=1:nbufs]
  t0 = ts[1]
  wt = 0.0
  for i=1:nbufs
    if i>1 && ts[i]+wt-t0<te[i-1]
      wt += 2^32/clkfreq
    end
    ts[i] += wt-t0
    te[i] += wt-t0
    if te[i]<ts[i]
      wt += 2^32/clkfreq
      te[i] += 2^32/clkfreq
    end
  end

  t0 = zeros(nsampPerChanPerBuf,nbufs)
  t1 = zeros(nsampPerChanPerBuf,nbufs)
  t2 = zeros(nsampPerChanPerBuf,nbufs)
  for i=1:nbufs
    for j=1:nsampPerChanPerBuf
      dt2 = (te[i]-ts[i])/(nsampPerChanPerBuf*nchan+1)
      dt1 = 3*dt2

      t0[j,i] = ts[i] + j*dt1
      t1[j,i] = ts[i] + j*dt1 + dt2
      t2[j,i] = ts[i] + j*dt1 + 2*dt2
    end
  end

  c0 = reshape(a[3:3:end-2,:],nbufs*nsampPerChanPerBuf)
  t0 = reshape(t0,nbufs*nsampPerChanPerBuf)
  c1 = reshape(a[4:3:end-2,:],nbufs*nsampPerChanPerBuf)
  t1 = reshape(t0,nbufs*nsampPerChanPerBuf)
  c2 = reshape(a[5:3:end-2,:],nbufs*nsampPerChanPerBuf)
  t2 = reshape(t0,nbufs*nsampPerChanPerBuf)

  DataFrame(t0=t0,c0=c0,t1=t1,c1=c1,t2=t2,c2=c2)
end

function procData(a,pgthr=1000)
  # generate new data frame
  # extract basic statistics using photogate-chunked filtered data:
  # - max minus min
  # - variance
  # - peak slope

  

  pgt = 

end

end #endmodule
