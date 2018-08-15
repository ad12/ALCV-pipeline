function [F,FO] =sparse_fusion3a(A,B,D,overlap,epsilon,AO,BO)
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
cntMatO=zeros(h,w,3);
% Update-start:
FO=zeros(h,w,3);
cntMat=zeros(h,w);
% Update-end:

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
        lenw = length(w1);
        w1O = zeros(lenw,3);
        mean1O = zeros(1,3);
        mean2O = mean1O;
        w2O = w1O;
        for cf = 1:3
            patch_1O = AO(yy:yy+patch_size-1, xx:xx+patch_size-1,cf);
            mean1O(cf) = mean(patch_1O(:));
            patch1O = patch_1O(:) - mean1O(cf);
            patch_2O = BO(yy:yy+patch_size-1, xx:xx+patch_size-1,cf);
            mean2O(cf) = mean(patch_2O(:));
            patch2O = patch_2O(:) - mean2O(cf);
            w1O(:,cf) =omp2(D,patch1O,G,epsilon);
            w2O(:,cf) =omp2(D,patch2O,G,epsilon);
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
        for cf = 1:3
            patch_f=D*wO(:,cf);
            Patch_f = reshape(patch_f, [patch_size, patch_size]);
            Patch_f = Patch_f + mean_fO(cf);
            
            FO(yy:yy+patch_size-1, xx:xx+patch_size-1,cf) = FO(yy:yy+patch_size-1, xx:xx+patch_size-1,cf) + Patch_f;
            cntMatO(yy:yy+patch_size-1, xx:xx+patch_size-1,cf) = cntMatO(yy:yy+patch_size-1, xx:xx+patch_size-1,cf) + 1;
        end
        % Update-end:
    end
    %cnt
end

idx = (cntMat < 1);
F(idx) = (A(idx)+B(idx))./2;
cntMat(idx) = 1;

F = F./cntMat;

% Update-start:
for cf = 1:3
    tmpMat = cntMatO(:,:,cf);
    tmpA = AO(:,:,cf);
    tmpB = BO(:,:,cf);
    tmpF = FO(:,:,cf);
    tmpF(idx) = (tmpA(idx)+tmpB(idx))./2;
    FO(:,:,cf) = tmpF;
    tmpMat(idx) = 1;
    cntMatO(:,:,cf) = tmpMat;
    FO(:,:,cf) = FO(:,:,cf)./cntMatO(:,:,cf);
end
% Update-end:


