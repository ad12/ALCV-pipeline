% Run segmentation analysis on all of processed outputs
clear; clc;
base_path = '../output_files/2018-08-04-00-48-54';
subdirs = get_subdirectories(base_path);

f = waitbar(0, 'Analyzing Segmentation');
for i = 1:length(subdirs)
    curr_subdir = subdirs(i);
    subdir_path = fullfile(curr_subdir.folder, curr_subdir.name);
    
    segmentation_analysis_func(subdir_path, curr_subdir.name);
    waitbar(i/length(subdirs), f);
end
close(f);
