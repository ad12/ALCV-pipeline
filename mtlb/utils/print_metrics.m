%% Print mean f1 accuracies of subjects
% Params to initialize:
%   base_folder: the folder where test results are stored per subject
%                Example File structure:
%                   | base_folder
%                       | Subject1
%                           | results.mat
%                       | Subject2
%                           | results.mat
%                       | ....
%   @author: Arjun Desai, Duke University
%            (c) Duke University

clear;clc;
base_folder = 'mask_refined/mask_upsampled/test_results/';
subdirs = get_subdirectories(base_folder);
count = 0;

thresh = 0.42;
for i = 1:length(subdirs)
    case_id_subdir = subdirs(i).name;
    results_path = fullfile(subdirs(i).folder, case_id_subdir, 'results.mat');
    
    results = load(results_path);
    f1_accuracies = results.f1_accuracies_orig;
    inds = results.valid_image_indices;
    f1_accuracies = f1_accuracies(inds);
    mean_f1_accuracy = mean(f1_accuracies);
    if (mean_f1_accuracy <= thresh)
        count = count+1;
    end
    fprintf('%s: \t\t %0.2f\n', case_id_subdir, mean_f1_accuracy) 
end

fprintf('%d\n', count)