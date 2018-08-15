function downsample_factor = find_downsample_factor(input, output)
    y_factor = size(input, 1) / size(output, 1);
    x_factor = size(input, 2) / size(output, 2);
    
    if (x_factor ~= y_factor)
        error('x,y resize factors not the same');
    end
    
    downsample_factor = 1 / x_factor;
end