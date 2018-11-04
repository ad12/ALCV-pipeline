%
%	function upsample_factor = find_upsample_factor(input, output)
%
%	@brief: Returns upsample factor between input and output in x
%           direction
%
%   @param input: 2D/3D matrix
%   @param output: 2D/3D matrix
%
%   @return: upsample factor in x direction 
%
%   @author: Arjun Desai, Duke University
%            (c) Duke University
function upsample_factor = find_upsample_factor(input, output)
    downsample_factor = find_downsample_factor(input, output);
    upsample_factor = 1 / downsample_factor;
end