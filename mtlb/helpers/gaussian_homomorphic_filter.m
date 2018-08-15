function I_filtered = gaussian_homomorphic_filter(I_in, sigma)
%% Gaussian homomorphic filtering
% param I_in: Input image
% param sigma: standard deviation of gaussian kernel

    I = im2double(I_in);
    I = log(I+1);
    
    
    
    M = 2*size(I,1) + 1;
    N = 2*size(I,2) + 1;
    [X, Y] = meshgrid(1:N, 1:M);
    cx = ceil(N/2);
    cy = ceil(M/2);

    % High pass filter = 1 - Low Pass Filter
    gaussian_numerator = (X - cx).^2 + (Y-cy).^2;
    h = 1 - exp(-gaussian_numerator./(2*sigma.^2));

    H = fftshift(h);
    
    I_filtered = zeros(size(I_in));
    for i = 1:size(I_in, 3)
        I_channel_filtered = real(ifft2(H.*fft2(I(:,:,i), M, N)));
        I_channel_filtered = I_channel_filtered(1:size(I, 1), 1:size(I,2));
        I_channel_filtered = exp(I_channel_filtered) - 1;
        
        I_filtered(:,:,i) = I_channel_filtered;
    end
    
end

