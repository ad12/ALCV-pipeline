%
%	function downsample_factor = find_downsample_factor(input, output)
%
%	@brief: Returns downsample factor between input and output in x
%           direction
%
%   @param input: 2D/3D matrix
%   @param output: 2D/3D matrix
%
%   @return: downsample factor in x direction 
%
%   @author: Arjun Desai, Duke University
%            (c) Duke University
function downsample_factor = find_downsample_factor(input, output)
    y_factor = size(input, 1) / size(output, 1);
    x_factor = size(input, 2) / size(output, 2);
    
    if (x_factor ~= y_factor)
        error('x,y resize factors not the same');
    end
    
    downsample_factor = 1 / x_factor;
end