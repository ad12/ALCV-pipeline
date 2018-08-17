function [I_best, filename_best] = get_best_lens(lens_dir)

niqe_params = load('modelparameters.mat');
niqe_params.blocksizerow = 30; niqe_params.blocksizecol = 30;
niqe_params.blockrowoverlap = 0; niqe_params.blockcoloverlap = 0;

runtimes = [];
I_best = [];
filename_best = '';

max_score = -inf;

files = dir(fullfile(lens_dir, '*.png'));

for i = 1:length(files)
    im_file = files(i);
    I = imread(fullfile(im_file.folder, im_file.name));
    
    lens_score = calculate_lens_score(I, niqe_params);
        
    if (lens_score > max_score)
    	max_score = lens_score;
    	I_best = I;
        filename_best = im_file.name;
    end
end

end

