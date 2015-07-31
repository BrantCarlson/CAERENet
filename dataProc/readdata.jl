module R

using DataFrames

const bufsize=1024
const clkfreq = 80.0e6
const nsampPerChanPerBuf = div((bufsize-4),3)

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

  
  t0 = zeros(nbufs*nsampPerChanPerBuf)
  t1 = zeros(nbufs*nsampPerChanPerBuf)
  t2 = zeros(nbufs*nsampPerChanPerBuf)
  for i=1:nbufs*nsampPerChanPerBuf
    t0[i] = 
    t1[i] =
    t2[i] = 
  end

  c0 = reshape(a[3:3:end-2,:],nbufs*nsampPerChanPerBuf)
  c1 = reshape(a[4:3:end-2,:],nbufs*nsampPerChanPerBuf)
  c2 = reshape(a[5:3:end-2,:],nbufs*nsampPerChanPerBuf)

  DataFrame(c0=c0,c1=c1,c2=c2)
end

end #endmodule
