function I_binarized = imbinarize_offset(I, vals)
% MATLAB inbuilt prediction output binarizes images by numbering classes
% For example, if my labelled classes were ["lens", "bg"],
%   "lens" = 1
%   "bg" = 2
% The output image would be an image with 1s and 2s
% We want to convert these to 0s and 1s
% 
% params:
%   I : image to binarize
%   vals : values corresponding to classes
%          vals(1) is foreground
%          vals(2) is background

% If image is not unary or binary, throw error
if (length(unique(I(:))) > 2)
    error('Image is not unary or binary');
end

% If image is already 0s and 1s, assume it has already been binarized
if (islogical(I))
    I_binarized = I;
    return;
end

I_binarized = zeros(size(I)) > 0;
I_binarized(I == vals(1)) = true;
I_binarized(I == vals(2)) = false;
end
