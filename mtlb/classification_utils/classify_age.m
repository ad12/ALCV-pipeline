function [labels] = classify_age(im_features, thresholds)
    models_map = load('svm_models.mat');
    models_map = models_map.models_map;
    
    labels = zeros(length(thresholds), 1);
    
    for i=1:length(thresholds)
        threshold = thresholds(i);
        % Load svm model
        model = models_map(threshold);
        
        label = get_label(im_features, model);
        
        labels(i) = label;
    end
    
end


function [label, prob] = get_label(im_features, model)

    pseudo_labels = zeros(size(im_features, 1), 1);
    [label, ~, prob] = svmpredict(pseudo_labels, im_features, model, '-b 1 -q');

end
