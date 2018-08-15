function [] = segmentation_analysis_func(base_folder, sub_folder_name, overwrite)
%% segnet_analysis
% Analysis of segmentation of lens region using segnet architecture
% Trained network can be found under variable keyword "net"

if (nargin == 2)
    overwrite = false;
end

downsampling_factor = 0.2;
upsampling_factor = 1/downsampling_factor;

% Original input/label information
orig_input_file_path = fullfile('../mlb_data/manual_input_data', sub_folder_name);
orig_label_file_path = fullfile('../mlb_data/manual_label_data', sub_folder_name);

ground_truth_prediction_file_path = 'raw_mask_ground_truth_prediction_raw_overlap';
resized_ground_truth_prediction_file_path = fullfile('../mlb_data/manual_resized', ground_truth_prediction_file_path, sub_folder_name);
check_and_create_dir(resized_ground_truth_prediction_file_path);
orig_ground_truth_prediction_file_path = fullfile('../mlb_data', ground_truth_prediction_file_path, sub_folder_name);
check_and_create_dir(orig_ground_truth_prediction_file_path);

mask_overlap_file_path = 'raw_mask_overlap';
resized_mask_overlap_file_path = fullfile('../mlb_data/manual_resized', mask_overlap_file_path, sub_folder_name);
check_and_create_dir(resized_mask_overlap_file_path);
orig_mask_overlap_file_path = fullfile('../mlb_data', mask_overlap_file_path, sub_folder_name);
check_and_create_dir(orig_mask_overlap_file_path);

resized_input_file_path = fullfile('../mlb_data/manual_resized/manual_input_data', sub_folder_name);

orig_test_results_file_path = fullfile('../mlb_data/raw_test_results', sub_folder_name);
check_and_create_dir(orig_test_results_file_path);
resized_test_results_file_path = fullfile('../mlb_data/manual_resized/raw_test_results', sub_folder_name);
check_and_create_dir(resized_test_results_file_path);

% Check if test result exists and user doesn't want to overwrite
% in this case, we can skip
if (~overwrite && exist(fullfile(resized_test_results_file_path, 'results.mat'), 'file')==2)
    return
end


prediction_extension = 'pred.png';
label_extension = 'label.png';
label_overlay_extension = 'label_overlay.png';
png_extension = '.png';
h5_output_ext = '.out';
mask_overlay_extension = 'overlay.png';

% Load h5 files
h5_files = dir(fullfile(base_folder, ['*' h5_output_ext]));

precision = zeros(length(h5_files), 1);
recall = zeros(length(h5_files), 1);
f1_score = zeros(length(h5_files), 1);
bf_score = zeros(length(h5_files), 1);
        
        
% Create overlay images for resized masks
for i = 1:length(h5_files)
    curr_file = h5_files(i);
    curr_filepath = fullfile(curr_file.folder, curr_file.name);
    frame_name = erase(curr_file.name, h5_output_ext);
    
    % Load h5 files
    groundTruth = permute(h5read(curr_filepath, '/y_true'), [3 2 1]);
    prediction = permute(h5read(curr_filepath, '/y_pred'), [3 2 1]);
    
    % save prediction
    pred_filepath = fullfile(resized_test_results_file_path, [frame_name '_' prediction_extension]);
    imwrite(prediction, pred_filepath);
    
    if (length(unique(groundTruth(:))) == 1)
        fprintf('%s: %d\n', frame_name, unique(groundTruth(:)));
    end
    
    % I = masked image
    % TP = true positive pixel count
    % FP = false positive pixel count
    % FN = false negative pixel count
    % P = precision
    % R = recall
    % F = F1 score
    [I, P, R, F, BF] = imoverlay_binary(groundTruth, prediction);
    
    precision(i) = P;
    recall(i) = R;
    f1_score(i) = F;
    bf_score(i) = BF;
    
    % Save color image of image masks - ground truth vs pred
    % Green = True Positive (Lens region, not background)
    % Blue = False Positive
    % Red = False Negative
    mask_file_path = fullfile(resized_ground_truth_prediction_file_path, [frame_name '_' label_overlay_extension]);
    imwrite(I, mask_file_path);
    
    % Save prediction mask on input image
    I = imread(fullfile(resized_input_file_path, [frame_name png_extension]));
    if (length(unique(prediction(:))) == 2)
        I = labeloverlay(I, imbinarize_offset(prediction, [1 2]), 'Transparency', 0.85);
    end
    
    mask_file_path = fullfile(resized_mask_overlap_file_path, [frame_name '_' mask_overlay_extension]);
    imwrite(I, mask_file_path);
end

% Save to results mat file
save(fullfile(resized_test_results_file_path, 'results.mat'), 'precision', 'recall', 'f1_score', 'bf_score');


upsampled_data.precision = zeros(length(h5_files), 1);
upsampled_data.recall = zeros(length(h5_files), 1);
upsampled_data.f1_score = zeros(length(h5_files), 1);
upsampled_data.bf_score = zeros(length(h5_files), 1);

% Upsample to original mask to do analysis
for i = 1:length(h5_files)
    curr_file = h5_files(i);
    curr_filepath = fullfile(curr_file.folder, curr_file.name);
    frame_name = erase(curr_file.name, h5_output_ext);
    
    % Load h5 files
    prediction = permute(h5read(curr_filepath, '/y_pred'), [3 2 1]);
    
    % Find original label image
    label_file = fullfile(orig_label_file_path, [frame_name '_' label_extension]);
    groundTruth = imread(label_file);
    
    % Upsample predicition
    % Upsampling will cause interpolation, so binarize after
    % Assume ground truth and input image have same x,y dimensions
    upsampling_factor = find_upsample_factor(groundTruth, prediction);
    prediction = imresize(prediction, upsampling_factor);
    
    % save prediction
    pred_filepath = fullfile(orig_test_results_file_path, [frame_name '_' prediction_extension]);
    imwrite(prediction, pred_filepath);
    
    % Save color image of image masks - ground truth vs pred
    % Green = True Positive (Lens region, not background)
    % Blue = False Positive
    % Red = False Negative
    [I, P, R, F, BF] = imoverlay_binary(groundTruth, prediction);
    
    upsampled_data.precision(i) = P;
    upsampled_data.recall(i) = R;
    upsampled_data.f1_score(i) = F;
    upsampled_data.bf_score(i) = BF;
    
    % Save label overlay
    label_overlay_file_path = fullfile(orig_ground_truth_prediction_file_path, [frame_name '_' label_overlay_extension]);
    imwrite(I, label_overlay_file_path);
    
    % Save mask on input image
    orig_input_path = fullfile(orig_input_file_path, [frame_name png_extension]);
    I = imread(orig_input_path);
    if (length(unique(prediction(:))) == 2)
        I = labeloverlay(I, imbinarize_offset(prediction, [1 2]), 'Transparency', 0.85);
    end
    
    mask_file_path = fullfile(orig_mask_overlap_file_path, [frame_name '_' mask_overlay_extension]);
    imwrite(I, mask_file_path);
end

% Save raw upsampled mask data
save(fullfile(orig_test_results_file_path, 'results.mat'), '-struct', 'upsampled_data');

end


