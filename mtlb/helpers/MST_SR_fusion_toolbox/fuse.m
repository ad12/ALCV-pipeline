function [ imgo, imgf ] = fuse(regImgStack)
%FUSE Summary of this function goes here
%
%
%   Return:
%   imgo: fused version of original image
%   imgf: filtered image
%

addpath(genpath('helpers/MST_SR_fusion_toolbox/dtcwt_toolbox'));
addpath(genpath('helpers/MST_SR_fusion_toolbox/fdct_wrapping_matlab'));
addpath(genpath('helpers/MST_SR_fusion_toolbox/nsct_toolbox'));
addpath(genpath('helpers/MST_SR_fusion_toolbox/sparsefusion'));
load('D_100000_256_8.mat');


len = length(regImgStack);
overlap = 6;
epsilon=0.1;
level=4;
h1 = fspecial('gaussian',[15 15],3);
h2 = strel('disk',5);
for cf = 1:len
    if cf == 1
        image_input1= (regImgStack(cf).Img);
        img1f = double(regImgStack(cf).FiltImg);
        imSize = size(image_input1);
    else
        image_input2= (regImgStack(cf).Img);
        img2f = double(regImgStack(cf).FiltImg);
        
        if size(image_input1)~=size(image_input2)
            error('two images are not the same size.');
        end
        
        img1=double(image_input1);
        img2=double(image_input2);
        
        % Specularity removal - start
%         img1lab = rgb2lab(mat2gray(image_input1));
%         img2lab = rgb2lab(mat2gray(image_input2));
%         tmpImg = imfilter(img1lab(:,:,2),h1);
%         maskXA = tmpImg>0.3*max(tmpImg(:));
%         tmpImg = imfilter(img2lab(:,:,2),h1);
%         maskXB = tmpImg>0.3*max(tmpImg(:));
%         maska = imdilate(img1lab(:,:,1)>80,h2);
%         maskb = imdilate(img2lab(:,:,1)>80,h2);
%         [idxA,idxDA] = bwdist(~maska);
%         [idxB,idxDB] = bwdist(~maskb);
%         
% %         maskac = maska & (~maskb);
% %         maskbc = maskb & (~maska);
%         for cf2 = 1:3
%             tmpa = img1(:,:,cf2);
%             tmpb = img2(:,:,cf2);
%             mA = mean(tmpa(maskXA));
%             mB = mean(tmpb(maskXB));
%             mAo = zeros(imSize(1),imSize(2));
%             mAo(maska) = tmpa(idxDA(maska));
%             tmpa(maska) = mAo(maska) + idxA(maska).*(mA-mAo(maska))./max(idxA(maska));
%             mBo = zeros(imSize(1),imSize(2));
%             mBo(maskb) = tmpb(idxDB(maskb));
%             tmpb(maskb) = mBo(maskb) + idxB(maskb).*(mB-mBo(maskb))./max(idxB(maskb));
% %             tmpa(maska) = mean(tmpa(maskXA));
% %             tmpb(maskb) = mean(tmpb(maskXB));
% %             tmpa(maskac) = tmpb(maskac);
% %             tmpb(maskbc) = tmpa(maskbc);
%             img1(:,:,cf2) = tmpa;
%             img2(:,:,cf2) = tmpb;
%         end
        % Specularity removal - end
        
        tic;
% %         [imgf, imgo] = lp_sr_fuse3(img1f, img2f, level, 3, 3, D, overlap, epsilon, img1, img2);
        
        % Try rgb2ycbcr
        yuvimg1 = rgb2ycbcr(img1); yuvimg2 = rgb2ycbcr(img2);
        imgf = lp_sr_fuse(img1f,img2f,level,3,3,D,overlap,epsilon);
        yuvimgo = lp_sr_fuse(yuvimg1(:,:,1),yuvimg2(:,:,1),level,3,3,D,overlap,epsilon);  
%         imgf = rp_sr_fuse(img1f,img2f,level,3,3,D,overlap,epsilon);
%         yuvimgo = rp_sr_fuse(yuvimg1(:,:,1),yuvimg2(:,:,1),level,3,3,D,overlap,epsilon);         
%         imgf = dwt_sr_fuse(img1f,img2f,level,D,overlap,epsilon);
%         yuvimgo = dwt_sr_fuse(yuvimg1(:,:,1),yuvimg2(:,:,1),level,D,overlap,epsilon);          
%         imgf = dtcwt_sr_fuse(img1f,img2f,level,D,overlap,epsilon);
%         yuvimgo = dtcwt_sr_fuse(yuvimg1(:,:,1),yuvimg2(:,:,1),level,D,overlap,epsilon);  
%         imgf = curvelet_sr_fuse(img1f,img2f,level+1,D,overlap,epsilon);
%         yuvimgo = curvelet_sr_fuse(yuvimg1(:,:,1),yuvimg2(:,:,1),level+1,D,overlap,epsilon);          
%         imgf = nsct_sr_fuse(img1f,img2f,[2],D,overlap,epsilon);
%         yuvimgo = nsct_sr_fuse(yuvimg1(:,:,1),yuvimg2(:,:,1),[2],D,overlap,epsilon);          
        
        imgo = zeros(size(yuvimgo,1),size(yuvimgo,2),3);
        imgo(:,:,1) = yuvimgo; imgo(:,:,2) = yuvimg1(:,:,2); imgo(:,:,3) = yuvimg1(:,:,3);
        imgo = ycbcr2rgb(imgo);

% %         % Try gray image
% %         imgf = lp_sr_fuse(img1f,img2f,level,3,3,D,overlap,epsilon);
% %         imgo = lp_sr_fuse(rgb2gray(img1),rgb2gray(img2),level,3,3,D,overlap,epsilon);  
% %         imgo = repmat(imgo,1,1,3);
        
%         [imgf, imgo] = lp_sr_fuse3a(img1f, img2f, level, 3, 3, D, overlap, epsilon, img1, img2);
        toc;
        
        img1f = imgf;
        image_input1 = imgo;
    end
end
end

