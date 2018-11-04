%
%	function [path] = check_and_create_dir(path)
%
%	@brief: Creates directory specified by 'path', if doesn't exist
%
%   @param path: Path to directory to create
%
%   @author: Arjun Desai, Duke University
%            (c) Duke University
function [path] = check_and_create_dir(path)

if (exist(path, 'dir') ~= 7)
    mkdir(path);
end

end
