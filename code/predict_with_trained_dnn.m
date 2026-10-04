function [labels, scores, trainedModel] = predict_with_trained_dnn(X, protocol)
%PREDICT_WITH_TRAINED_DNN Run one of the released trained DNN models.
%
%   [labels, scores] = predict_with_trained_dnn(X, protocol)
%
% Inputs
%   X         - N-by-40 predictor matrix. Columns must follow exactly the
%               same sensor-feature order used during model training.
%   protocol  - "Static" or "Dynamic" (case-insensitive).
%
% Outputs
%   labels       - Predicted class labels returned by the exported model.
%   scores       - Class scores returned by the exported model.
%   trainedModel - MATLAB exported model structure (variable NN3).
%
% This helper loads and applies the trained DNN model released with the dataset.

    arguments
        X double
        protocol {mustBeTextScalar}
    end

    if size(X,2) ~= 40
        error('X must contain exactly 40 predictor columns.');
    end

    scriptDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(scriptDir);

    switch lower(string(protocol))
        case "static"
            modelFile = fullfile(repoRoot, 'data', 'online', 'static', 'DNN.mat');
        case "dynamic"
            modelFile = fullfile(repoRoot, 'data', 'online', 'dynamic', 'DNN.mat');
        otherwise
            error('protocol must be "Static" or "Dynamic".');
    end

    S = load(modelFile, 'NN3');
    if ~isfield(S, 'NN3')
        error('The expected trained model variable NN3 was not found in %s.', modelFile);
    end

    trainedModel = S.NN3;
    [labels, scores] = trainedModel.predictFcn(X);
end
