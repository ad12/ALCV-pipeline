function R=renyientropy(W,alpha)

 
 
% normalize pseudo-Wigner distribution
[ro co N]=size(W);    
W2=reshape(W,ro*co,N);
P=W2.*conj(W2);
S=sum(P,2);
SS=repmat(S,1,N);
P=P./(SS+eps);

if nargin==1
    alpha=3;
end

if alpha==1
    % Rényi entropy = Shannon entropy
    Pp=P.*log2(P+eps);
    Q=-sum(Pp,2);
else
    % Rényi entropy
    P=P.^alpha;
    Q=(1/(1-alpha))*log2(sum(P,2)+eps);
end

% round-off error correction
I=find(Q<0); 
Q(I)=0;
II=find(Q>log2(N));
Q(II)=0;
U=reshape(Q,ro,co);
R=U./log2(N);
 
