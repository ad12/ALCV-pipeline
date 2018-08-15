clear;clc;
addpath(genpath('helpers'))
addpath(genpath('IQA'))

extracted_lens_path = '../mlb_data/extract_lens';
top_extracted_lens_path = '../mlb_data/extract_lens_top1_rt';
check_and_create_dir(top_extracted_lens_path);
lens_ext = '.png';


subject_subdirs = get_subdirectories(extracted_lens_path);

niqe_params = load('modelparameters.mat');
niqe_params.blocksizerow = 30; niqe_params.blocksizecol = 30;
niqe_params.blockrowoverlap = 0; niqe_params.blockcoloverlap = 0;

runtimes = [];
f = waitbar(0, 'Extracting top frame');
for i = 1:length(subject_subdirs)
    lens_subdir_data = subject_subdirs(i);
    tic
    % Get lens information from current subject
    lens_subdir_path = fullfile(lens_subdir_data.folder, lens_subdir_data.name);
    lens_files = dir(fullfile(lens_subdir_path, ['*' lens_ext]))';
    
    I_best = [];
    max_score = -Inf;
    
    assert(~isempty(lens_files), sprintf('%s failed', lens_subdir_path));
    
    for lens_file = lens_files
    % Load each file and determine corresponding score
        im_lens = imread(fullfile(lens_file.folder, lens_file.name));
        lens_score = calculate_lens_score(im_lens, niqe_params);
        
        if (lens_score > max_score)
            max_score = lens_score;
            I_best = im_lens;
        end
        
    end
    imwrite(I_best, fullfile(top_extracted_lens_path, [lens_subdir_data.name, lens_ext]));
    fprintf(sprintf('%s: \t\t %0.2f\n', lens_subdir_data.name, max_score));
    runtimes = [runtimes; toc];
    
    waitbar(i/length(subject_subdirs), f, sprintf('Extracting top frame: %d/%d', i, length(subject_subdirs)))
end
close(f)

