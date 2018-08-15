function [means, variances] = var_channel(path)
    
I = imread(path);
R = I(:,:,1);
G = I(:,:,2);
B = I(:,:,3);

mask = R>0;
Area = sum(mask(:));

R = R.*uint8(mask);
G = G.*uint8(mask);
B = B.*uint8(mask);

R_bar = mean(R(R>0));
G_bar = mean(G(G>0));
B_bar = mean(B(B>0));
means = [R_bar G_bar B_bar];

calc_var = @(X,Y) sum((X-Y).^2)/Area;

R_G = calc_var(R,G);
R_B = calc_var(R,B);
G_B = calc_var(G, B);
variances = [R_G R_B G_B];

end

