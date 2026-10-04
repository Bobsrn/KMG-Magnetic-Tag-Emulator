% train_all_dnn.m
% Train the manuscript DNN configuration for both acquisition protocols.

clearvars;
clc;

staticResult = train_dnn('Static'); %#ok<NASGU>
dynamicResult = train_dnn('Dynamic'); %#ok<NASGU>
