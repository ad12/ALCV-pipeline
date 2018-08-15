clear;clc;

tic
base_folder = '../output_files/2018-08-04-00-48-54';
subdirs = get_subdirectories(base_folder);
solidities = [];
f = waitbar(0, 'Evaluating raw segmentation');
subject_data_total = [];
frame_data_total = [];
for i = 1:length(subdirs)
    case_id_subdir = subdirs(i).name;
    case_id_path = fullfile(subdirs(i).folder, case_id_subdir);
    
    [sd, fd] = evaluate_raw(case_id_path, case_id_subdir);
    
    % append data
    subject_data_total = [subject_data_total; sd];
    frame_data_total = [frame_data_total; fd];
    
    waitbar(i/length(subdirs), f, sprintf('Evaluating raw segmentation: %d/%d', i, length(subdirs)));
end

close(f);
toc

function [subject_data, frame_data] = evaluate_raw(base_folder, case_id)
% Load downsampling, upsampling factor
downsampling_factor = 0.2;
upsampling_factor = 1/downsampling_factor;

% Extensions
prediction_extension = 'pred.png';
label_extension = 'label.png';
label_overlay_extension = 'label_overlay.png';
png_extension = '.png';
h5_output_ext = '.out';
mask_overlay_extension = 'overlay.png';

DEFAULT_PATH = '../mlb_data';

% Load h5 files that contain ground truth and prediction
h5_files = dir(fullfile(base_folder, ['*' h5_output_ext]));
frame_data = [];
for i = 1:length(h5_files)
    curr_file = h5_files(i);
    curr_filepath = fullfile(curr_file.folder, curr_file.name);
    frame_name = erase(curr_file.name, h5_output_ext);
    
    % Find original mask
    original_groundTruth_filepath_prefix = fullfile(...
                                                DEFAULT_PATH,...
                                                'manual_label_data',...
                                                case_id);
    groundTruth_filepath = fullfile(original_groundTruth_filepath_prefix, [frame_name '_' label_extension]);
    ytrue = imread(groundTruth_filepath);
    
    % Load mask and upsample to orignal size
    ypred = uint8(permute(h5read(curr_filepath, '/y_pred'), [3 2 1]));
    ypred = imresize(ypred, size(ytrue));
    
    [~, P, R, ~, ~, ~, DSC] = imoverlay_binary(ytrue, ypred);
    assert(~isnan(P))
    assert(~isnan(R))
    assert(~isnan(DSC))
    
    frame_data = [frame_data; P, R, DSC];
end

subject_data = mean(frame_data);

end

