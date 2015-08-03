module R

using DataFrames
using DSP

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

function maxMinusMin(a,i1,i2)
  mx=mn=a[i1]
  for i=i1:i2
    if mx<a[i]
      mx=a[i]
    end
    if mn>a[i]
      mn=a[i]
    end
  end

  mx-mn
end

function filtStats(a,i1,i2)
  ftype = Lowpass(0.05)
  fmethod = Butterworth(4)
  f = filtfilt(digitalfilter(ftype,fmethod),a[i1:i2])

  n = size(f,1)
  n8 = div(n,8)

  sgn = sign(f[n8]+f[5*n8] - f[3*n8]-f[7*n8])

  fmm = maxMinusMin(f,1,n)
  dmm = maxMinusMin(diff(f),1,n-1)

  sgn,fmm,dmm
end

function procData(a,pgthr=convert(Uint16,1000))
  t = Float64[]
  mmm1 = Float64[]
  mmm2 = Float64[]
  std1 = Float64[]
  std2 = Float64[]
  s1 = Float64[]
  s2 = Float64[]
  fm1 = Float64[]
  fm2 = Float64[]
  dm1 = Float64[]
  dm2 = Float64[]
  ii1 = Int64[]

  #=ctr = 0=#
  tctr = 0
  for i=2:size(a,1)
    if a[i-1,:c0]<pgthr && a[i,:c0]>=pgthr
      if tctr==0
        i1 = i
      elseif tctr==2
        i2 = i

        # process revolution, store results
        push!(t,a[i1,:t0])

        ts1,tfm1,tdm1 = filtStats(a[:c1],i1,i2)
        ts2,tfm2,tdm2 = filtStats(a[:c2],i1,i2)
        ts1 = -ts1
        push!(s1,ts1)
        push!(s2,ts2)
        push!(fm1,tfm1*ts1)
        push!(fm2,tfm2*ts2)
        push!(dm1,tdm1*ts1)
        push!(dm2,tdm2*ts2)
        push!(mmm1,maxMinusMin(a[:c1],i1,i2)*ts1)
        push!(mmm2,maxMinusMin(a[:c2],i1,i2)*ts2)
        push!(std1,std(a[i1:i2,:c1])*ts1)
        push!(std2,std(a[i1:i2,:c2])*ts2)
        push!(ii1,i1)

        #=if ctr>2379=#
          #=return a,i1,i2=#
        #=end=#
        #=ctr += 1=#

        # and reset
        i1=i
        tctr = 0
      end
      tctr += 1
    end
  end

  DataFrame(t=t,s1=s1,s2=s2,fm1=fm1,fm2=fm2,dm1=dm1,dm2=dm2,
            mmm1=mmm1,mmm2=mmm2,std1=std1,std2=std2,i1=ii1)
end

function procFiles(fns)
  dfs = [procData(readData(fn)) for fn=fns]
  t0 = dfs[1][end,:t]
  for i=2:size(dfs,1)
    dfs[i][:t] = dfs[i][:t]+t0
    t0 = dfs[i][end,:t] + (dfs[i][2,:t]-dfs[i][1,:t])
  end

  vcat(dfs)
end

end #endmodule
