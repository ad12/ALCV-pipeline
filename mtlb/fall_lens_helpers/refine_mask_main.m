%% Refine all masks
clear;clc;

base_folder = '../output_files/2018-08-04-00-48-54';
subdirs = get_subdirectories(base_folder);
solidities = [];
f = waitbar(0, 'Refining masks');
refining_times = []; % per subject
for i = 1:length(subdirs)
    case_id_subdir = subdirs(i).name;
    case_id_path = fullfile(subdirs(i).folder, case_id_subdir);
    
    rts = refine_mask(case_id_path, case_id_subdir);
    
    % refining_times
    refining_times = [refining_times; mean(rts)];
    
    waitbar(i/length(subdirs), f, sprintf('Refining Masks: %d/%d', i, length(subdirs)));
end

fprintf('Mean +/- Std: %0.4f +/- %0.4f', mean(refining_times), std(refining_times));
fprintf('Median: %0.4f', median(refining_times));

close(f);