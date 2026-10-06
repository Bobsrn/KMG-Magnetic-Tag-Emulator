% Train the compact DNN for both protocol-specific model-development datasets.
clearvars; clc;
staticResult=train_dnn('Static'); %#ok<NASGU>
dynamicResult=train_dnn('Dynamic'); %#ok<NASGU>
