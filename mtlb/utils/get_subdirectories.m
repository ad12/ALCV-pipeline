function [sub_directories] = get_subdirectories(directory)

sub_elements = dir(directory);
i_sub_directory = [sub_elements(:).isdir];
nameFolds = sub_elements(i_sub_directory);

% Remove '.' and '..' directories
nameFolds(ismember({nameFolds.name}, {'.','..'})) = [];

sub_directories = nameFolds';
end
