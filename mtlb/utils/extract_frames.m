%% Extract frames from all videos

function [] = extract_frames()
%% Choose directory with movies
% Select all .mat files
ext = '*.mat';
dirname = uigetdir(pwd, 'Select mat file folder');

if (isempty(dirname))
    return
end

data_path_prefix = fullfile(dirname, 'top_frames/');
check_and_create_dir(data_path_prefix)

mat_file_paths = dir(fullfile(dirname, ext));

num_files = length(mat_file_paths);

f = waitbar(0, 'Extracting Top Frames');
%% Extract Frames
for i = 1:length(mat_file_paths)
    mat_file_path = mat_file_paths(i).name;
    results = load(fullfile(dirname, mat_file_path));
    
    % Remove .mat extension - store in directories corresponding to video
    frame_name_prefix = mat_file_path(1:end-4);
    
    frame_directory = [data_path_prefix frame_name_prefix];
    mkdir(frame_directory);
    
    % Extract imageStack - struct field where all selected images are
    % stored
    curr_imageStack = results.imageStack;
    
    for j = 1:length(curr_imageStack)
        frame_data = curr_imageStack(j);
        
        frame = frame_data.OrigImg;
        
        frame_number = frame_data.OrigFrameNum;
        frame_name = sprintf('%s_Frame_%s.png', frame_name_prefix,num2str(frame_number, '%04.f'));
        frame_filename = [frame_directory '/' frame_name];
        
        imwrite(frame, frame_filename);
    end
    
    waitbar(i/num_files, f);
end

close(f)

end
