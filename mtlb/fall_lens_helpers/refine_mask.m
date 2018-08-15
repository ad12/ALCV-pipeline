function [mask_eroded, mask_eroded_upsampled, cost, props] = refine_mask(mask, upsample_factor)
    mask_eroded_upsampled = [];
    props = [];
    % First fill holes
    mask_eroded = imfill(mask, 'holes');
    % Erode mask to find disk-like structures
    r = 1; % radius
    disk_strel = strel('disk', r);
    mask_eroded = imerode(mask_eroded, disk_strel);
    
    if (max(mask_eroded(:)) == 0)
        cost = Inf;
        return;
    end
    
    % Reset to original mask
    mask_eroded = mask;
    
    CC = bwconncomp(mask_eroded);
    
    % Penalize mutliple connected components 
    % If there is at least one connected components with sizes within 20%
    % of the max, we cannot make a sound decision, so we should reject this
    % image
    numPixels = cellfun(@numel,CC.PixelIdxList);
    [CC_max_size, idx] = max(numPixels);
    num_pixels_frac = numPixels./CC_max_size;
    
    % Have at least 1 other connected component with 80% of area of
    threshold = 0.8;
    if (sum(num_pixels_frac >= threshold) >= 2)
        cost = Inf;
        return;
    end

    % Erase all other components
    for i = 1:length(CC.PixelIdxList)
        if (i == idx)
            continue;
        end
        mask_eroded(CC.PixelIdxList{i}) = 0;
    end

    % Determine convex mask around current selection
    % Convex mask must have solidity of >=0.85
    props = regionprops(mask_eroded, 'BoundingBox', 'Solidity', 'ConvexImage',...
                                        'Perimeter','MajorAxisLength', 'MinorAxisLength',...
                                        'Eccentricity', 'Area', 'Centroid');
    if (props.Solidity < 0.85)
        cost = Inf;
        return;
    end
    
    % Determine circularity of mask
    % Circularity ratio is defined as CR = Ai / Ac = ri^2 / rc^2
    % Ai = area of inscribed circle
    % Ac = area of circumscribed circle
    mask_eroded = bwconvhull(mask_eroded);
    
    % Find largest inscribed circle in convex mask
    [cx, cy, ri] = largest_inscribed_circle(mask_eroded);
    
    % Find smallest circumscribed circle in convex mask
    rc = min_bounding_circle(mask_eroded);
    
    assert(ri <= rc);
    
    CR = ri^2 / rc^2;
    props.CR = CR;
    if (CR < 0.65)
        cost = Inf;
        return;
    end
    
    radius = ri;
    % Check if we have more than 1 contender
    % if difference between all contenders is less than 1, take the mean 
    % if any difference is > 1, then we have a problem and reject this
    % image
    if (length(cx) > 1)
        diffx = diff(cx) > 1;
        diffy = diff(cy) > 1;
        
        if (sum(diffx) > 1 || sum(diffy) > 1)
            cost = Inf;
            return;
        end
        
        cx = mean(cx);
        cy = mean(cy);
    end
    
    props.circle_center = [cx, cy];
    % % Adjust radius by erosion radius
    %radius = radius + r/2;
    
    % Create circular mask
    Cmask = zeros(size(mask_eroded));
    for y = 1:size(mask_eroded, 1)
        for x = 1:size(mask_eroded, 2)
            Cmask(y,x) = (hypot(x-cx, y-cy) <= radius);
        end
    end
    
    convex_hull = mask_eroded;
    mask_eroded = Cmask;
    
    % The cost is the proportion of area that the 
    cost = sum(convex_hull(:)) / sum(mask_eroded(:));
    
    % Upsample eroded mask
    % instead of using imresize, we cna recreate the circle because we know
    % the center and radius
    cx = cx*upsample_factor;
    cy = cy*upsample_factor;
    radius = radius * upsample_factor;
    
    % Create circular mask
    Cmask = zeros(size(mask_eroded) * upsample_factor);
    for y = 1:size(Cmask, 1)
        for x = 1:size(Cmask, 2)
            Cmask(y,x) = (hypot(x-cx, y-cy) <= radius);
        end
    end
    
    mask_eroded_upsampled = Cmask;
    
    % Reject all tiny predictions smaller than 35x35 in size on original
    % image, which corresponds to 7x7 on downsampled image
    pixel_thresh = 35*35;
    bin_mask = mask_eroded_upsampled > 0;
    if (sum(bin_mask(:)) < pixel_thresh)
        cost = Inf;
    end
    
    mask_e = mask_eroded;
    mask_e_upsampled = mask_eroded_upsampled;
    
end

function [cx, cy, radius] = largest_inscribed_circle(mask)
    edtI = bwdist(~mask);
    radius = max(edtI(:));
    [cy, cx] = find(edtI == radius);
end

function radius = min_bounding_circle(mask)
% mask must be binary and convex

% To find the parameters (cx, cy, r) of the minimum circumscribing circle
% we must find the maximum euclidean distance to the from some arbitrary
% center C = (cx, cy) to a point on the edge of the circumscribed circle.
%
% The "maximum euclidean distance" from some center C to the edge of the
% convex mask will be the distance from C to some point A on the edge of
% the convex mask such that sqrt((Cx-Ax)^2 + (Cy-Ay)^2) is maximized for
% all A in edge points
%
% Of all possible centers Cs, the center with the minimum maximum euclidean 
% distance will be the center of the circumscribing circle, and its
% magnitude will be the radius of that circle
%
% Center:
%   1. Will be within the convex mask - any point outside of the mask will
%   have a maximum euclidean distance greater than any point inside the mask


% matrix of centers
% values will be the radius from the center (cx, cy) to circumscribe the
% mask
% initialize values at infinity, only have to search points within the mask
Cs = ones(size(mask)) * Inf;

[ys, xs] = find(mask);
assert(length(ys) == length(xs));
num_points = length(ys);

% get edges of mask
% find y,x coordinates for pixels on the edge
B = bwboundaries(mask, 'noholes');
assert(length(B) == 1);

Bs = B{1};
By = Bs(:,1);
Bx = Bs(:,2);

assert(length(By) == length(Bx));

for i=1:num_points
    y = ys(i);
    x = xs(i);
    
    % find maximum distance to 
    e_dists = sqrt((x-Bx).^2 + (y-By).^2);
    Cs(y,x) = max(e_dists(:));
end

radius = min(Cs(:));

end
