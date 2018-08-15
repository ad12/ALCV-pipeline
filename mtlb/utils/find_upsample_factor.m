function upsample_factor = find_upsample_factor(input, output)
    downsample_factor = find_downsample_factor(input, output);
    upsample_factor = 1 / downsample_factor;
end