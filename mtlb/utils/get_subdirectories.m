%
%	function [sub_directories] = get_subdirectories(directory)
%
%	@brief: Returns all named subdirectories under `directory`
%           Removes return values corresponding to local path
%           subdirectories (i.e. '.', '..')
%
%   @param directory: The path to the directory for which the
%                       subdirectories are returned
%
%   @return: Array of structs as in format of `dir(directory)` 
%
%   @author: Arjun Desai, Duke University
%            (c) Duke University
function [sub_directories] = get_subdirectories(directory)
sub_elements = dir(directory);
i_sub_directory = [sub_elements(:).isdir];
nameFolds = sub_elements(i_sub_directory);

% Remove '.' and '..' directories
nameFolds(ismember({nameFolds.name}, {'.','..'})) = [];

sub_directories = nameFolds';
end
