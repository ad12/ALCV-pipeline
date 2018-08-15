function [F,FO] =sparse_fusion2(A,B,D,overlap,epsilon,AO,BO)
%    SR
%    Input:
%    A - input image A
%    B - input image B
%    D  - Dictionary for sparse representation
%    overlap - the overlapped pixels between two neighbor patches
%    epsilon - sparse reconstuction error
%    Output:
%    F  - fused image   
%
%    The code is edited by Yu Liu, 01-09-2014.
%    Update: fusion of original images using the data from A and B
%    Update: AO - original image A; BO - original image B, FO - fused
%    original image

% normalize the dictionary
norm_D = sqrt(sum(D.^2, 1)); 
D = D./repmat(norm_D, size(D, 1), 1);

patch_size = sqrt(size(D, 1));
[h,w]=size(A);
F=zeros(h,w);
% Update-start:
FO=zeros(h,w,3);
% Update-end:
cntMat=zeros(h,w);

gridx = 1:patch_size - overlap : w-patch_size+1;
gridy = 1:patch_size - overlap : h-patch_size+1;

%cnt=0;  
G=D'*D;
for ii = 1:length(gridx)
    for jj = 1:length(gridy)
        %cnt = cnt+1;
        xx = gridx(ii);
        yy = gridy(jj);
        
        patch_1 = A(yy:yy+patch_size-1, xx:xx+patch_size-1);
        mean1 = mean(patch_1(:));
        patch1 = patch_1(:) - mean1;
        patch_2 = B(yy:yy+patch_size-1, xx:xx+patch_size-1);
        mean2 = mean(patch_2(:));
        patch2 = patch_2(:) - mean2;
        w1=omp2(D,patch1,G,epsilon);
        w2=omp2(D,patch2,G,epsilon);
        
        % Update-start:
        patch_1O = AO(yy:yy+patch_size-1, xx:xx+patch_size-1,:);
        mean1O = mean(patch_1O(:));
        patch1O = patch_1O(:) - mean1O;
        patch_2O = BO(yy:yy+patch_size-1, xx:xx+patch_size-1,:);
        mean2O = mean(patch_2O(:));
        patch2O = patch_2O(:) - mean2O;
        lenp = length(patch1O)/3;
        lenw = length(w1);
        w1O = zeros(lenw*3,1);
        w2O = w1O;
        tmpIndp = 1;
        tmpIndw = 1;
        for cf = 1:3
            tmpPatch = patch1O(tmpIndp:tmpIndp+lenp-1);
            w1O(tmpIndw:tmpIndw+lenw-1) =omp2(D,tmpPatch,G,epsilon);
            tmpPatch = patch2O(tmpIndp:tmpIndp+lenp-1);
            w2O(tmpIndw:tmpIndw+lenw-1)=omp2(D,tmpPatch,G,epsilon);
            tmpIndp = tmpIndp + lenp;
            tmpIndw = tmpIndw + lenw;
        end
        % Update-end:
        
        w=w1;
        mean_f=mean1;
        % Update-start:
        wO=w1O;
        mean_fO=mean1O;
        % Update-end:
        if sum(abs(w1))<sum(abs(w2))
            w=w2;
            mean_f=mean2;
            % Update-start:
            wO=w2O;
            mean_fO=mean2O;
            % Update-end:
        end
        
        patch_f=D*w;
        Patch_f = reshape(patch_f, [patch_size, patch_size]);
        Patch_f = Patch_f + mean_f;
        
        F(yy:yy+patch_size-1, xx:xx+patch_size-1) = F(yy:yy+patch_size-1, xx:xx+patch_size-1) + Patch_f;
        cntMat(yy:yy+patch_size-1, xx:xx+patch_size-1) = cntMat(yy:yy+patch_size-1, xx:xx+patch_size-1) + 1;
        
        % Update-start:
        lenf = length(patch_f(:));
        patch_fO = zeros(lenf,1);
        tmpIndf = 1;
        tmpIndw = 1;
        for cf = 1:3
            tmpW = wO(tmpIndw:tmpIndw+lenw-1);
            patch_fO(tmpIndf:tmpIndf+lenf-1)=D*tmpW;
            tmpIndf = tmpIndf + lenf;
            tmpIndw = tmpIndw + lenw;
        end
        Patch_fO = reshape(patch_fO, [patch_size, patch_size, 3]);
        Patch_fO = Patch_fO + mean_fO;
        
        FO(yy:yy+patch_size-1, xx:xx+patch_size-1, :) = FO(yy:yy+patch_size-1, xx:xx+patch_size-1, :) + Patch_fO;
        % Update-end:
    end
    %cnt
end

idx = (cntMat < 1);
F(idx) = (A(idx)+B(idx))./2;
% Update-start:
for cf = 1:3
    tmpA = AO(:,:,cf);
    tmpB = BO(:,:,cf);
    tmpF = FO(:,:,cf);
    tmpF(idx) = (tmpA(idx)+tmpB(idx))./2;
    FO(:,:,cf) = tmpF;
end
% Update-end:
cntMat(idx) = 1;

F = F./cntMat;
% Update-start:
FO = FO./repmat(cntMat,[1,1,3]);
% Update-end:


