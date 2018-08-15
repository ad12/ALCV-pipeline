function [I_var] = variance_conv(I,N)
%variance_conv Calculate variance in image I with neighborhood NxN
%   Detailed explanation goes here

I = im2double(I);

h = ones(N);

% element count in each window
n = conv2(ones(size(I,1), size(I,2)), h, 'same');

% calculate s vector
s = conv2(I, h, 'same');

% calculate q vector
q = I .^ 2;
q = conv2(q, h, 'same');

% calculate output values
I_var = (q - s .^ 2 ./ n) ./ (n - 1);

% Normalize and scale - reduce error estimation rate
I_var = I_var / max(I_var(:)) * 100;

end

