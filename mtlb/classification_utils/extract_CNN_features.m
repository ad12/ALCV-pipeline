%
%	function [im_features] = extract_CNN_features(lens_dir)
%
%	@brief: Extract feature vector from fully connected layer of Resnet-152
%               instance trained on ImageNet
%
%   @param lens_dir: Directory where lens images (png, uint8) are stored.
%
%   @detailed: Feature vector (len=1000) is extracted per lens image using
%               Renet-152 instance trained on ImageNet dataset, which can
%               be found at matconvnet. Results are returned as 2D matrix
%               of size (1000 x #images). Each column corresponds to
%               features for a given lens image.
%   
%   matconvnet:
%   (http://www.vlfeat.org/matconvnet/models/imagenet-resnet-152-dag.mat)
%   
%
%   @author: Arjun Desai, Duke University
%            (c) Duke University
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