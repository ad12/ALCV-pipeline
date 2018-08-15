function [I_overlay, P, R, F, BF, IoU, DSC] = imoverlay_binary(groundTruth, pred)

% Convert ground truth and prediction masks to binary masks
groundTruth = imbinarize_offset(groundTruth, [1 0]);
pred = imbinarize_offset(pred, [1 2]);

temp_red = (groundTruth == 1) & (pred == 0); % false negative
temp_green = (groundTruth == 1) & (pred == 1); % true positive
temp_blue = (groundTruth == 0) & (pred == 1); % false positive

I_overlay = zeros(size(groundTruth, 1), size(groundTruth, 2), 3);
I_overlay(:,:,1) = temp_red;
I_overlay(:,:,2) = temp_green;
I_overlay(:,:,3) = temp_blue;

TP = sum(temp_green(:));
FP = sum(temp_blue(:));
FN = sum(temp_red(:));

P = TP / (TP + FP); % precision
R = TP / (TP + FN); % recall

% If R is NaN, (TP + FN) = 0
% this means the frame has no lens region
if (isnan(R))
    R = 0;
end

F = 2*P*R / (P + R); % f1 score
if (isnan(F))
    F = 0;
end

BF = bfscore(pred, groundTruth); % bfscore
IoU = TP / (TP + FP + FN); % intersection over union
DSC = 2*TP / (2*TP + FP + FN); % dice score coefficient

end


