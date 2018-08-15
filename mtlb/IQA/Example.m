clc;clear all;close all;

img1 = imread('../../test1.jpg');
img2 = imread('../../test2.jpg');
img1 = im2double(img1);
img2 = im2double(img2);
[Qg1,Qch1]=blindimagequality(img1);
[Qg2,Qch2]=blindimagequality(img2);

% IQA(img1)<IQA(img2)
% Qg1=0.0056, Qg2=0.0044;