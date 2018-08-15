function trvImg = hyst2d_3x(img,t1,t2,mask,skelImg)
% HARDTHRESH = 25;
% opt = option_defaults_fa;
imSize = size(img);
if (nargin<4) || isempty(mask)
    h1 = fspecial('gaussian',[15 15],3);
    imglab = rgb2lab(uint8(img));
    imglab = imfilter(imglab(:,:,2),h1);
    maskX = imglab>0.3*max(imglab(:));
    mask = imfill(maskX,'holes');
end
mask2 = mask;
mask2(1:2,:) = false; mask2(end-1:end,:) = false;
mask2(:,1:2) = false; mask2(:,end-1:end) = false;
mask2 = imerode(mask2,strel('disk',12));

fImg = mat2gray(filter_image_mex(img));
fImg(~mask) = 1;
h4 = fspecial('gaussian',31,31/4);
img = img(:,:,1);
im2 = double(img)-double(imfilter(img,h4));
im2 = im2.*mask.*(im2<0);
imSize = size(im2);
img = imbothat(im2,strel('disk',31)).*mask;
img = img.*(1-fImg);
minv=min(img(mask2));                % min image intensity value
maxv=max(img(mask2));  

t1v=t1*(maxv-minv)+minv;
if (nargin<5) || isempty(skelImg)
    skelImg = img>=t1v;
end

myStack = zeros(imSize(1)*imSize(2),1);
stackPos = 0;

[r1,c1] = find(skelImg);
len = numel(r1);
trvImg = skelImg;
% cnt = 0;

for cf = 1:len
    stack_add(r1(cf),c1(cf));
end
while ~stack_empty()
    val = stack_last();
    r = floor(val/imSize(2))+1;
    c = mod(val,imSize(2))+1;
    val2 = t2*img(r,c);
    for rr = -1:1
        nr = r + rr;
        if (nr>0) && (nr<=imSize(1))
            for cc = -1:1
                nc = c + cc;
                if (nc>0) && (nc<=imSize(2))
                    if (~trvImg(nr,nc)) && (img(nr,nc)>val2)
                        trvImg(nr,nc) = true;
                        stack_add(nr,nc);
                    end
                end
            end
        end
    end
end
trvImg = imopen(trvImg,strel('disk',1));
trvImg = bwareafilt(trvImg,[50,imSize(1)*imSize(2)]);
% [~,branchImg,~,numImg] = analyzeVessels(trvImg);
% trvImg = numImg>0;
% stats = regionprops(numImg,'MajorAxisLength','MinorAxisLength','PixelIdxList');
% for cf = 1:numel(stats)
%     if (stats(cf).MinorAxisLength/stats(cf).MajorAxisLength)>0.4
%         trvImg(stats(cf).PixelIdxList) = false;
%     end
% end
trvImg(~mask2) = false;
clear myStack

    % Stack handling functions
    function stack_add(r,c)
        stackPos = stackPos + 1;
        myStack(stackPos) = (r-1)*imSize(2)+(c-1);
    end

    function p = stack_last()
        if stackPos == 0
            p = [];
            return;
        end
        p = myStack(stackPos);
        myStack(stackPos) = 0;
        stackPos = stackPos - 1;
    end

    function isEmpty = stack_empty()
        if stackPos == 0
            isEmpty = true;
        else
            isEmpty = false;
        end
    end
end