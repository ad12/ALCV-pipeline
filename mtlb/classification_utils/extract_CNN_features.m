function [im_features] = extract_CNN_features(lens_dir)

net = dagnn.DagNN.loadobj(load('imagenet-resnet-152-dag.mat')) ;
net.mode = 'test';
usedlayer = 514;

imlist = dir(fullfile(lens_dir, '*.png'));


total_set = [];

for i = 1:length(imlist)
    tic
    im = imread(fullfile(lens_dir, imlist.name));

    im_ = single(im) ; % note: 255 range
    im_ = imresize(im_, net.meta.normalization.imageSize(1:2));
    
    im_ = bsxfun(@minus, im_, net.meta.normalization.averageImage);

    % run the CNN
    net.conserveMemory = 0;
    net.eval({'data', im_}) ;
    
    I_Patches = double(net.vars(usedlayer).value(:));

    total_set = [total_set, I_Patches(:)];
    
end

im_features = total_set;

end