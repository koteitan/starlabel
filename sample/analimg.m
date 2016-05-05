filename='o0597039813019218534.png';
trendR   = 50;
smoothF  = [1 -0.5]';
noiseThRate = 0.0001;

A = mean(imread(filename),3);
wx=size(A,1);
wy=size(A,2);
nA    = normfil(A);

% remove trend
tA = zeros(size(A));
for y=1:trendR:wy
  for x=1:trendR:wx
    x1=min(x+trendR,wx);
    y1=min(y+trendR,wy);
    subA = A(x:x1,y:y1);
    medsubA = median(reshape(subA,prod(size(subA)),1));
    tA(x:x1,y:y1) = medsubA;
  end % for x
end % for y
rtA = A-tA;

% smoothing
srtA = iir2d(1,smoothF,rtA);

% noise reduction
rankA = sort(reshape(rtA,wx*wy,1),'descend');
th = rankA(ceil(noiseThRate*wx*wy),1);
nrsrtA = normfil(max(srtA,th));
B = nrsrtA;

% make centroids
checked = (B==0)+0; % 1=checked
checked([1 end],1:end)=1; % discard photo edge
checked(1:end,[1 end])=1; % discard photo edge
checked2=checked;

cx = zeros(wx*wy/2,1);
cy = zeros(wx*wy/2,1);
cz = zeros(wx*wy/2,1);
cs = 0;
for y=2:wy-1
  for x=2:wx-1
    if ~checked(x,y)
      clust = checked; % 0=unknown 1=not 2=new 3=old
      clust(x,y) = 2;
      x0=x-1;x1=x+1;
      y0=y-0;y1=y+1;
      while 1
        renewed=0;
        for y2=y0:y1
          for x2=x0:x1
%          fprintf('clust(x=%d,y=%d)=%d, clust(x2=%d,y2=%d)=%d\n',x,y,clust(x,y),x2,y2,clust(x2,y2));
%          input('');
            if clust(x2,y2)==2
              clust(x2,y2)=3;
              if clust(x2-1,y2  )==0
                clust(x2-1,y2  )=2;
                x0=min(x0,x2-1);
                renewed=1;
              end
              if clust(x2+1,y2  )==0
                clust(x2+1,y2  )=2;
                x1=max(x0,x2+1);
                renewed=1;
              end
              if clust(x2  ,y2-1)==0
                clust(x2  ,y2-1)=2;
                clust(x2,y2)=3;
                y0=min(y0,y2-1);
                renewed=1;
              end
              if clust(x2  ,y2+1)==0
                clust(x2  ,y2+1)=2;
                y1=max(y0,y2+1);
                renewed=1;
              end
            end
          end
        end
        if ~renewed
          break;
        end
      end % while
      % clustering is finished
      ccn=0;
      ccx=0;
      ccy=0;
      ccz=0;
      for y2=y0:y1
        for x2=x0:x1
          if clust(x2,y2)==3;
            ccn=ccn+ 1;
            ccx=ccx+x2*B(x2,y2);
            ccy=ccy+y2*B(x2,y2);
            ccz=ccz+B(x2,y2);
            checked(x2,y2)=1;
          end
        end % for x2
      end %for y2
      cs=cs+1;
      cx(cs,1)=ccx/ccz;
      cy(cs,1)=ccy/ccz;
      cz(cs,1)=ccz;
    end% if ~checked
    
  end% x
end% y

cx=cx(1:cs,1);
cy=cy(1:cs,1);
cz=cz(1:cs,1);
cz=cz/sum(cz,1);
[cz,ci]=sort(cz,'descend');
cx=cx(ci,1);
cy=cy(ci,1);

% plot
contourf(1:wy,wx-(1:wx),5*log10((B)));
hold on;
for ci=1:20
  text(cy(ci),wx-cx(ci)+10,sprintf('%1.1f',5*log10(cz(ci))));
end
hold off;

