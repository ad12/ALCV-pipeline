function [diagImg,branchImg,branchStruct,numImg] = analyzeVessels(img,thresh,minorAxis)

if ~islogical(img)
    img = img>0;
end
imSize = size(img);

distImg = 2*bwdist(~img);
skelImg = bwmorph(img,'skel',Inf);
skelImg = bwmorph(imclose(skelImg,strel('disk',5)),'skel',Inf);
diagImg = distImg.*skelImg;
endptImg = bwmorph(skelImg,'endpoints');
brptImg = bwmorph(skelImg,'branchpoints');
trvImg = false(imSize);
cmpstImg = endptImg | brptImg;
[r,c] = find(cmpstImg);
L = zeros(imSize);
lenBr = length(r);
L(cmpstImg) = 1:lenBr;

numBranches = 0;
branchImg = zeros(imSize);
branchSImg = branchImg;
branchSImg2 = branchImg;
sqrtof2 = sqrt(2);
indMat = [sqrtof2,1,sqrtof2;1,0,1;sqrtof2,1,sqrtof2];
% Find individual branches
dataSize = lenBr*4;
leafBranches = false(dataSize,1);
maxBranchLen = 0;
for cf = 1:lenBr
    startIsLeaf = false;
    currNumBranches = numBranches;
    if (endptImg(r(cf),c(cf))) && (~trvImg(r(cf),c(cf)))
        numBranches = numBranches + 1;
        branchImg(r(cf),c(cf)) = numBranches;
        startIsLeaf = true;
    end
    trvImg(r(cf),c(cf)) = true;
    % Mark branches
    for rr = -1:1
        for cc = -1:1
            if ~((rr==0) && (cc==0))
                newR = r(cf)+rr; newC = c(cf)+cc;
                if (newR>0) && (newC>0) && (newR<=imSize(1)) && (newC<=imSize(2))
                    if (skelImg(newR,newC))
                        if (~trvImg(newR,newC))
                            trvImg(newR,newC) = true;
                            if brptImg(r(cf),c(cf))
                                numBranches = numBranches + 1;
                            end
                            branchImg(newR,newC) = numBranches;
                        end
                    end
                end
            end
        end
    end
    % Traverse branches
    for rr = -1:1
        for cc = -1:1
            if ~((rr==0) && (cc==0))
                newR = r(cf)+rr; newC = c(cf)+cc;
                if (newR>0) && (newC>0) && (newR<=imSize(1)) && (newC<=imSize(2))
                    if (branchImg(newR,newC)>currNumBranches)
                        endIsLeaf = false;
                        branchSImg(newR,newC) = 1;
                        branchSImg2(newR,newC) = 0;
                        tracePath(newR,newC,branchImg(newR,newC),L(r(cf),c(cf)));
                        if startIsLeaf || endIsLeaf
                            leafBranches(branchImg(newR,newC),1) = true;
                        end
                    end
                end
            end
        end
    end
end

if nargin<2
    thresh = 0.05*maxBranchLen;
else
    thresh = max(0.05*maxBranchLen,thresh);
end

if nargin<3
    minorAxis = imSize(1);
end

% Remove branches with length < thresh
for cf = 1:numBranches
    brImg = branchImg == cf;
    brImg2 = branchSImg2.*brImg;
    maxVal2 = max(brImg2(:));
    if (maxVal2<thresh) && (leafBranches(cf))
        skelImg(brImg) = false;
    end
end

% Merge branches if size < thresh - run the code again with new skelImg
skelImg = bwmorph(imclose(skelImg,strel('disk',5)),'skel',Inf);
endptImg = bwmorph(skelImg,'endpoints');
brptImg = bwmorph(skelImg,'branchpoints');
trvImg = false(imSize);
cmpstImg = endptImg | brptImg;
[r,c] = find(cmpstImg);
L = zeros(imSize);
lenBr = length(r);
L(cmpstImg) = 1:lenBr;

numBranches = 0;
branchImg = zeros(imSize);
branchSImg = branchImg;
branchSImg2 = branchImg;
sqrtof2 = sqrt(2);
indMat = [sqrtof2,1,sqrtof2;1,0,1;sqrtof2,1,sqrtof2];
% Find individual branches
maxBranchLen = 0;
for cf = 1:lenBr
    startIsLeaf = false;
    currNumBranches = numBranches;
    if (endptImg(r(cf),c(cf))) && (~trvImg(r(cf),c(cf)))
        numBranches = numBranches + 1;
        branchImg(r(cf),c(cf)) = numBranches;
        startIsLeaf = true;
    end
    trvImg(r(cf),c(cf)) = true;    
    % Mark branches
    for rr = -1:1
        for cc = -1:1
            if ~((rr==0) && (cc==0))
                newR = r(cf)+rr; newC = c(cf)+cc;
                if (newR>0) && (newC>0) && (newR<=imSize(1)) && (newC<=imSize(2))
                    if (skelImg(newR,newC)) && (~brptImg(newR,newC)) % Not a branch point
                        if (~trvImg(newR,newC))
                            trvImg(newR,newC) = true;
                            if brptImg(r(cf),c(cf))
                                numBranches = numBranches + 1;
                            end
                            branchImg(newR,newC) = numBranches;
                        end
                    end
                end
            end
        end
    end
    % Traverse branches
    for rr = -1:1
        for cc = -1:1
            if ~((rr==0) && (cc==0))
                newR = r(cf)+rr; newC = c(cf)+cc;
                if (newR>0) && (newC>0) && (newR<=imSize(1)) && (newC<=imSize(2))
                    if (branchImg(newR,newC)>currNumBranches)
                        endIsLeaf = false;
                        branchSImg(newR,newC) = 1;
                        branchSImg2(newR,newC) = 0;
                        tracePath(newR,newC,branchImg(newR,newC),L(r(cf),c(cf)));
                        if startIsLeaf && endIsLeaf % Both leaves - so its not part of a group
                            leafBranches(branchImg(newR,newC),1) = true;
                        else
                            leafBranches(branchImg(newR,newC),1) = false;
                        end
                    end
                end
            end
        end
    end
end

% Find tortuosity for each branch, remove branches with length < thresh
branchStruct = struct('Tortuosity',cell(numBranches,1),'AvgWidth',cell(numBranches,1),...
    'Length',cell(numBranches,1));
newBranchImg = zeros(imSize);
cnt = 0;
for cf = 1:numBranches
    brImg = branchImg == cf;
    brImg1 = branchSImg.*brImg;
    brImg2 = branchSImg2.*brImg;
    maxVal1 = max(brImg1(:));
    maxVal2 = max(brImg2(:));
    avgWidth = mean(diagImg(brImg));
    if ((maxVal2<thresh) && (leafBranches(cf))) || (avgWidth>(0.05*minorAxis))
%         branchImg(brImg) = 0;
        diagImg(brImg) = 0;
    else
        cnt = cnt + 1;
        if maxVal1>5 % Ignore small branches
            [x1,y1] = find(brImg1==1);
            [x2,y2] = find(brImg1==maxVal1);
            C = sqrt((x1-x2)^2+(y1-y2)^2);
            branchStruct(cnt).Tortuosity = maxVal2/C;
        else
            branchStruct(cnt).Tortuosity = 1; % Do not consider
        end
        branchStruct(cnt).Length = maxVal2;
        branchStruct(cnt).AvgWidth = avgWidth;
        newBranchImg(brImg) = cnt;
    end
end

branchImg = newBranchImg;
skelImg = branchImg>0;
if sum(skelImg(:))>0
    [~,idx] = bwdist(skelImg);
    img = imreconstruct(skelImg,img);
    numImg = branchImg(idx);
    numImg = numImg.*img;
    diagImg = diagImg(idx);
    diagImg = diagImg.*img;
else
    numImg = zeros(imSize);
    diagImg = numImg;
end

    function tracePath(ro,co,branchNum,sourceBr)
        % Recursive function to trace each branch separately
        trvImg(ro,co) = true;
        branchImg(ro,co) = branchNum;
        % Find if any branch points in neighbourhood - if yes, stop tracing
        for ri = -1:1
            for ci = -1:1
                if ~((ri==0) && (ci==0))
                    newR2 = ro+ri; newC2 = co+ci;
                    if (newR2>0) && (newC2>0) && (newR2<=imSize(1)) && (newC2<=imSize(2))
                        if (brptImg(newR2,newC2)) && (L(newR2,newC2)~=sourceBr)
                            return;
                        end
                    end
                end
            end
        end
        
        for ri = -1:1
            for ci = -1:1
                if ~((ri==0) && (ci==0))
                    newR2 = ro+ri; newC2 = co+ci;
                    if (newR2>0) && (newC2>0) && (newR2<=imSize(1)) && (newC2<=imSize(2))
                        if (skelImg(newR2,newC2)) && (~trvImg(newR2,newC2))
                            if (endptImg(newR2,newC2))
                                trvImg(newR2,newC2) = true;
                                branchImg(newR2,newC2) = branchNum;
                                endIsLeaf = true;
                            else
                                branchSImg(newR2,newC2) = branchSImg(ro,co) + 1;
                                branchSImg2(newR2,newC2) = branchSImg2(ro,co) + indMat(ri+2,ci+2);
                                if branchSImg2(newR2,newC2)>maxBranchLen
                                    maxBranchLen = branchSImg2(newR2,newC2);
                                end
                                tracePath(newR2,newC2,branchNum,sourceBr);
                            end
                        end
                    end
                end
            end
        end
    end
end