%% Compare results from neural network to 
clear; clc;

precisions_nn = [];
recalls_nn = [];
f1_accuracies_nn = [];
bf_scores_nn=[];

precisions_refined = [];
recalls_refined = [];
f1_accuracies_refined = [];
bf_scores_refined =[];

case_ids = [];

refined_results_path_prefix = 'mask_refined/test_results';
nn_results_path_prefix = 'manual_resized/test_results';
subdirs = get_subdirectories(nn_results_path_prefix);

min_IoU.case_id = '';
min_IoU.ind = 0;
min_IoU.val = Inf;
max_IoU.case_id = '';
max_IoU.ind = 0;
max_IoU.val = -Inf;

for i = 1:length(subdirs)
    case_id_subdir = subdirs(i).name;
    
    % Refined data extraction
    curr_refined_subdir_path = fullfile(refined_results_path_prefix, subdirs(i).name, 'results.mat');
    results = load(curr_refined_subdir_path);
    valid_image_indices = results.valid_image_indices;
        
    precisions_refined = [precisions_refined; results.precisions(valid_image_indices)];
    recalls_refined = [recalls_refined; results.recalls(valid_image_indices)];
    f1_accuracies_refined = [f1_accuracies_refined; results.f1_accuracies(valid_image_indices)];
    bf_scores_refined = [bf_scores_refined; results.bf_scores(valid_image_indices)];
    
    IoUs = 1./ ((1./results.recalls(valid_image_indices)) + (1./results.precisions(valid_image_indices)) -1);
    IoUs_max = max(IoUs(:));
    IoUs_min = min(IoUs(:));
    
    if (IoUs_max > max_IoU.val)
        max_IoU.val = IoUs_max;
        max_IoU.ind = find(max(IoUs(:)));
        max_IoU.case_id = case_id_subdir;
    end
    
    if(IoUs_min < min_IoU.val)
        min_IoU.val = IoUs_min;
        min_IoU.ind = find(min(IoUs(:)));
        min_IoU.case_id = case_id_subdir;
    end
    
    % Neural network data extraction
    curr_nn_refined_subdir_path = fullfile(nn_results_path_prefix, subdirs(i).name, 'results.mat');
    results = load(curr_nn_refined_subdir_path);
    precisions_nn = [precisions_nn; results.precisions(valid_image_indices)];
    recalls_nn = [recalls_nn; results.recalls(valid_image_indices)];
    f1_accuracies_nn = [f1_accuracies_nn; results.f1_accuracies(valid_image_indices)];
    bfscores_nn = [bf_scores_nn; results.bf_scores(valid_image_indices)];
    
    if (sum(isnan(results.recalls(valid_image_indices))) > 0)
        fprintf('Failed: %s\n', subdirs(i).name)
    end
    
end

% Handle NaN cases
precisions_nn(find(isnan(precisions_nn))) = 0;
recalls_nn(find(isnan(recalls_nn))) = 0;
f1_accuracies_nn(find(isnan(f1_accuracies_nn))) = 0;

precisions_refined(find(isnan(precisions_refined))) = 0;
recalls_refined(find(isnan(recalls_refined))) = 0;
f1_accuracies_refined(isnan(f1_accuracies_refined)) = 0;

IoU_nn = 1./ ((1./recalls_nn) + (1./precisions_nn) -1);
IoU_refined = 1./ ((1./recalls_refined) + (1./precisions_refined) -1);

% Significance testing
% Check if refined outperforms nn significantly
% x = refined; y = nn; x-y > 0 (right tailed), alpha = 0.01
alpha = 0.01;

% Paired ttest
[P.h, P.p] = ttest(precisions_refined, precisions_nn, 'Tail', 'right', 'Alpha', alpha);
[R.h, R.p] = ttest(recalls_refined, recalls_nn, 'Tail', 'left', 'Alpha', alpha);
[F.h, F.p] = ttest(f1_accuracies_refined, f1_accuracies_nn, 'Tail', 'right', 'Alpha', alpha);
[IoU.h, IoU.p] = ttest(IoU_refined, IoU_nn, 'Tail', 'right', 'Alpha', alpha);

