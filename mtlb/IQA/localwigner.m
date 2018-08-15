function W=localwigner(X,N,theta,units,period,window_shape)
%%

%%
X=double(X);
X=X+eps; % avoid zeros
[ro,co]=size(X);
if nargin<6
    v=direction(N,theta,units,'square');
else % when 'circular' shape is determined in the input, values are
     %calculated by bilinear interpolation and some smoothing effect
     % will be expected
    v=direction(N,theta,units,window_shape);
end

AI=zeros(ro,co,N);
AD=zeros(ro,co,N);
A=zeros(ro,co,N);

for k=1:N
    if k<=N/2+1
        iz=v(:,:,k);
        [IIx,IIy]=find(iz~=0);
        izx=zeros(N+1,1);
        izx(IIx,1)=1;
        izy=zeros(1,N+1);
        izy(1,IIy)=1;
        IIIx=(N+2)-IIx;
        IIIy=(N+2)-IIy;
        dex=zeros(N+1,1);
        dex(IIIx,1)=1;
        dey=zeros(1,N+1);
        dey(1,IIIy)=1;
        AI(:,:,k)=conv2(conv2(X,izx,'same'),izy,'same');
        AD(:,:,k)=conv2(conv2(conj(X),dex,'same'),dey,'same');
        A(:,:,k)=AD(:,:,k).*AI(:,:,k);
        if nargin>4
            switch period
                case 'periodic'
                    % this bound is required when the function is not real
                    if k==1
                        A(:,:,k)=AI(:,:,k).*conj(AI(:,:,k));
                    end
                case 'aperiodic'
            end
        end
    else
        A(:,:,k)=A(:,:,N+2-k);
    end
end
 
Y=fft(A,[],3);
W=fftshift(Y,3);
W=real(W);


function H=direction(N,theta,units,window_shape)
%%
% Position correction
switch units
    case 'radian'
        arad=theta-pi/2;
        m=tan(arad);
    case 'degree'
        theta=theta-90;
        arad=deg2rad(theta);
        m=tan(arad);
    case 'slope'
        m=theta;
        m=-1/(m+eps);
        arad=atan(m);
end

% Generatriz
if abs(m)<1
    x=(-N/2:N/2);
    y=round(m*x);
    h=zeros(N+1,N+1);
    x=x+N/2+1;
    y=y+N/2+1;
    for k=1:N+1
        h(x(k),y(k))=1;
    end
elseif abs(m)>1
    y=(-N/2:N/2);
    x=round(m^-1*y);
    h=zeros(N+1,N+1);
    x=x+N/2+1;
    y=y+N/2+1;
    for k=1:N+1
        h(x(k),y(k))=1;
    end
elseif abs(m)==1
        h=diag(ones(1,N+1));
end

% Individualisation
H=zeros(N+1,N+1,N+1);
if abs(m)<=1
    for k=1:N+1
        H(:,:,k)=zeros(N+1);
        H(k,:,k)=h(k,:);
    end
elseif abs(m)>1
        for k=1:N+1
            H(:,:,k)=zeros(N+1);
            H(:,k,k)=h(:,k);
        end
end

switch window_shape
    case 'circular'
        
        % Interpolation
        narad=arad+pi/2;
        U=zeros(N+1,N+1,N+1);
        
        % angle
        phi=mod(narad,pi);
  
        %for k=1:N+1
        for k=1:N+1
            % interpolation position
            x=(N+2)/2-(k-(N+2)/2)*sin(phi);
            y=(N+2)/2+(k-(N+2)/2)*cos(phi);
            
            % boundary positions
            x0=fix(x);
            x1=fix(x)+1;
            y0=fix(y);
            y1=fix(y)+1;
        
            % weight factors
            fx=x-fix(x);
            fy=y-fix(y);
            w00=(1-fx)*(1-fy);
            w01=(1-fx)*fy;
            w10=fx*(1-fy);
            w11=fx*fy;
            
            % calculation masks
            if and(x0<=N+1,y0<=N+1)
                U(x0,y0,N+2-k)=w00;
            end
            if and(x0<=N+1,y1<=N+1)
                U(x0,y1,N+2-k)=w01;
            end
            if and(x1<=N+1,y0<=N+1)
                U(x1,y0,N+2-k)=w10;
            end
            if and(x1<=N+1,y1<=N+1)
                U(x1,y1,N+2-k)=w11;
            end
           
        end
        
     H=U;
        
    case 'square'
       
end

return


