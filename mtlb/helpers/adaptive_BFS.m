function [region_mask] = adaptive_BFS(img, region0)
    region_mask = (region0 > 0);
    region_mask(region_mask == 0) = nan;
    
    import java.util.LinkedList
    q = LinkedList();
    
    while (~q.isempty())
        
    end
    
    region_mask(isnan(region_mask)) = 0;
    
end


function [neighbors, inds] = find_neighbors(x, y, img)
% Find neighboring pixel values
% neighbors: gray scale values of corresponding pixel values
% inds: y,x (row, column) indices in columnwise vector (ie. n x 2)
    neighbors = [];
    
    x_max = size(img, 2);
    y_max = size(img, 1);
    % Stored in dx, dy
    directions = [-1 -1; 0 -1; 1 -1; -1 0; 1 0; -1 1; 0 1; 1 1];
    
    for i = 1:size(directions, 1)
        dir = directions(i,:);
        dx = dir(1); dy = dir(2);
        
        x_new = x +dx; y_new = y+dy;
        % If potential neighbor is off the current image, discount
        if (x_new < 1 || y_new < 1 || x_new > x_max || y_new > y_max)
            continue;
        end
        
        inds = [inds; ydy x+dx];
        neighbors = [neighbors, img(y_new, x_new)];
    end
end

