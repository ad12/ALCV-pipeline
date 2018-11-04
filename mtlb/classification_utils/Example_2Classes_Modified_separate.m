%% Sample of 2-bin classification system
%   @author: Arjun Desai, Duke University
%            (c) Duke University
%% train on manually selected images
clc; clear all; close all;

%% initialize vlfeat library
% run matcovnet/matlab/vl_compilenn
% run matcovnet/matlab/vl_setupnn
% run matcovnet/matlab/vl_testnn

data_version_folder = 'accuracy_data/auto_extracted_v1_rbf_kernel/';

% Check if directory to save results exists
if (exist(data_version_folder, 'dir') ~= 7)
    mkdir(data_version_folder)
end

testing_image_ext = {'*.png'};
testing_eye_image_directory = 'extract_lens_top1_v1\';

training_eye_image_directory = 'extract_lens_top1_v1\';
training_image_ext = {'*.png'};

%eye_image_directory = 'EyeImage_modified\';

Ccv = 1;

%% Start ResNet 152
skiploading = 0;

%run('vlfeat-0.9.19-bin\vlfeat-0.9.19\toolbox\vl_setup.m')
%run vl_setupnn;
threshoulds = 33:38;

% General Accuracy parameters
tot_data.total_classification_time = [];
tot_data.training_feature_extraction_time = [];
tot_data.testing_feature_extraction_time = [];
tot_data.total_feature_extraction_time = [];
tot_data.total_svm_training_time = [];
tot_data.thresholds = threshoulds;
tot_data.sensitivity = [];
tot_data.specificity = [];
tot_data.accuracy = [];
tot_data.TP = [];
tot_data.TN = [];
tot_data.FP = [];
tot_data.FN = [];

total_per_image_classification = [];

%% Extract Features for all images - save information

% Try loading training and testing data
image_feature_data_filepath = [data_version_folder 'image_data_mat.mat'];
%net = inceptionresnetv2();
if (exist(image_feature_data_filepath, 'file') == 2)
    f = waitbar(0, 'Loading Existing Image Data');
    data = load(image_feature_data_filepath);
    training_data = data.training_data;
    testing_data = data.testing_data;
    close(f)
else
    training_data = extract_CNN_features(training_eye_image_directory, training_image_ext, 'Training Images', false);
    testing_data = extract_CNN_features(testing_eye_image_directory, testing_image_ext, 'Testing Images', false);
    save(image_feature_data_filepath, 'training_data', 'testing_data');
end

tot_data.training_feature_extraction_time = training_data.cnn_times;
tot_data.testing_feature_extraction_time = testing_data.cnn_times;
tot_data.total_feature_extraction_time = [training_data.cnn_times, testing_data.cnn_times];

%% Execute on different thresholds
for threshould = threshoulds
    Result_accuracy = [];
    Result_acc1 = [];
    Result_acc2 = [];
    Result_num1 = [];
    Result_num2 = [];
    
    TP = [];
    TN = [];
    FP = [];
    FN = [];
    
    % Set training and testing data
   
    [training_data.total_label, training_data.case_lsTS, training_data.case_TSmr, training_data.num_lsTS, training_data.num_TSmr] = load_labels_func(training_data.case_id_and_dates, training_data.caseid_ages, threshould);
    [testing_data.total_label, testing_data.case_lsTS, testing_data.case_TSmr, testing_data.num_lsTS, testing_data.num_TSmr] = load_labels_func(testing_data.case_id_and_dates, testing_data.caseid_ages, threshould);    
    
    %% train and test svm
    PredLabel = zeros(length(testing_data.total_label),1);
    classification_times = [];

    for i = 1:length(testing_data.total_label)
        curr_case_id_and_date = testing_data.case_id_and_dates{i};

        [train_set, train_label] = isolate_training_set(training_data, curr_case_id_and_date);
        % Normalize training set
        %[train_set, standardization_model] = soft_stand_features_SVM(train_set);

        test_label = testing_data.total_label(i);
        test_set = testing_data.total_set(:,i);

        % Normalize testing set
        %test_set = soft_stand_features_SVM(test_set, standardization_model);

        parameter = ['-t 2 -h 0 -c ' num2str(Ccv) ' -b 1'];

        % Log SVM training time
        tic
        model=svmtrain(train_label,train_set',parameter);
        tot_data.total_svm_training_time = [tot_data.total_svm_training_time, toc];

        tic
        [SVMresult, accuracy, prob] = svmpredict(test_label,test_set',model,'-b 1'); 
        classification_times = [classification_times,toc];
        PredLabel(i) = SVMresult;

    end

    % Log classification_times
    tot_data.total_classification_time = [tot_data.total_classification_time, classification_times];
    Result_accuracy = [Result_accuracy, sum(PredLabel==testing_data.total_label)/length(PredLabel)];

    tmp = PredLabel(testing_data.total_label==0);
    Result_acc1 = [Result_acc1, sum(tmp==0)/length(tmp)];
    Result_num1 = [Result_num1, length(tmp)];

    tmp = PredLabel(testing_data.total_label==1);
    Result_acc2 = [Result_acc2, sum(tmp==1)/length(tmp)];
    Result_num2 = [Result_num2, length(tmp)];

    tot_data.TP = [tot_data.TP; sum(PredLabel(:) & testing_data.total_label(:))];
    tot_data.TN = [tot_data.TN; sum(~PredLabel(:) & ~testing_data.total_label(:))];
    tot_data.FP = [tot_data.FP; sum(PredLabel(:) & ~testing_data.total_label(:))];
    tot_data.FN = [tot_data.FN; sum(~PredLabel(:) & testing_data.total_label(:))];
    
    per_image_classification = PredLabel==testing_data.total_label;
    
    % Append sensitivity, specificity, and f1 accuracy to overall data
    tot_data.sensitivity = [tot_data.sensitivity; Result_acc2];
    tot_data.specificity = [tot_data.specificity; Result_acc1];
    tot_data.accuracy = [tot_data.accuracy; Result_accuracy];
    total_per_image_classification = [total_per_image_classification, per_image_classification(:)];
    
    save([data_version_folder 'Result_DL_modified_linearSVM_2c_' num2str(threshould) '.mat']);
end

tot_data.precision = tot_data.TP ./ (tot_data.TP + tot_data.FP);
tot_data.recall = tot_data.TP ./ (tot_data.TP + tot_data.FN);
tot_data.f1_score = (2 .* tot_data.precision .* tot_data.recall) ./ (tot_data.precision + tot_data.recall);
tot_data.dsc = (2 .* tot_data.TP) ./ (2.*tot_data.TP + tot_data.FP + tot_data.FN);
tot_data.metrics = [tot_data.sensitivity, tot_data.specificity, tot_data.accuracy, tot_data.precision, tot_data.recall, tot_data.f1_score, tot_data.dsc]';
% reshape for CCvs
%tot_data.accuracy = reshape(tot_data.accuracy,[3, length(Ccvs), length(threshoulds)]);

% Make table
testing_data.total_filename;
t = struct2table(testing_data.total_filename);
table_headers = {};
for i = 1:length(threshoulds)
    table_headers{i} = sprintf('T_%d',threshoulds(i));
end

t = [t, array2table(total_per_image_classification,'VariableNames', table_headers)];
tot_data.per_image_classification = t;

save([data_version_folder 'condensed_results.mat'], '-struct', 'tot_data');
