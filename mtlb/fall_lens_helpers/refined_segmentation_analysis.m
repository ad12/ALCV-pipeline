%% Compare results from neural network to 
clear; clc;

subject_data_total = [];
frame_data_total = [];

case_ids = [];

refined_results_path_prefix = '../mlb_data/mask_refined/mask_upsampled/test_results';
subdirs = get_subdirectories(refined_results_path_prefix);

for i = 1:length(subdirs)
    case_id_subdir = subdirs(i).name;
    
    % Refined data extraction
    curr_refined_subdir_path = fullfile(refined_results_path_prefix, subdirs(i).name, 'results.mat');
    results = load(curr_refined_subdir_path);
    valid_image_indices = results.valid_image_indices;
        
    % frame data
    % we parse by valid_image_indices because the arrays were initialized
    % to 0
    % we only modified indices of frames that were not omitted
    % so we had to parse by these indices to make sure we are not counting
    % frames we may have omitted
    P = results.precisions_orig(valid_image_indices);
    R = results.recalls_orig(valid_image_indices);
    DSC = results.DSCs_orig(valid_image_indices);
    assert(sum(isnan(P)) == 0);
    assert(sum(isnan(R)) == 0);
    assert(sum(isnan(DSC)) == 0);
    
    fd = [P, R, DSC];
    frame_data_total = [frame_data_total; fd];
    subject_data_total = [subject_data_total; mean(fd)];
end

