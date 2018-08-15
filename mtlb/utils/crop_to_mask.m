function [I_cropped, bb_rect] = crop_to_mask(I, mask)

    I = im2uint8(I);
    
    mask_rep = repmat(mask, [1 1 size(I,3)]);
    I = I .* uint8(mask_rep);
    
    x_crop_any = any(mask, 1);
    y_crop_any = any(mask, 2);

    x_crop_inds = [find(x_crop_any, 1, 'first') find(x_crop_any, 1, 'last')];
    y_crop_inds = [find(y_crop_any, 1, 'first') find(y_crop_any, 1, 'last')];

    I_cropped = I(y_crop_inds(1):y_crop_inds(2), x_crop_inds(1):x_crop_inds(2),:);
    
    rect_height = size(I_cropped, 1);
    rect_width = size(I_cropped, 2);
    bb_rect = [x_crop_inds(1) y_crop_inds(1) rect_width rect_height];
end
