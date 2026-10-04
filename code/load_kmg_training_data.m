function [X, Y, sourceInfo] = load_kmg_training_data(protocol)
%LOAD_KMG_TRAINING_DATA Load protocol-specific 40-feature DNN training data.
%
% Accepted files:
%   data/training/static_training.mat
%   data/training/dynamic_training.mat
%
% Each file must contain either:
%   1) X (N-by-40 numeric matrix) and Y (N labels), or
%   2) DATA_5cls, a table with 40 predictor columns and a Label column.

    protocol = validatestring(char(protocol), {'Static','Dynamic'}, mfilename, 'protocol');

    scriptDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(scriptDir);
    trainingFile = fullfile(repoRoot, 'data', 'training', ...
        sprintf('%s_training.mat', lower(protocol)));

    if ~isfile(trainingFile)
        error(['Training data file not found: %s\n' ...
            'See data/training/README.md for the required format.'], trainingFile);
    end

    S = load(trainingFile);
    [X, Y] = parseTrainingVariables(S);

    if istable(X)
        X = table2array(X);
    end
    X = double(X);
    Y = categorical(Y);

    if size(X,1) ~= numel(Y)
        error('The number of observations in X and Y must match.');
    end
    if size(X,2) ~= 40
        error('Expected 40 predictor columns; found %d.', size(X,2));
    end
    if numel(categories(Y)) ~= 5
        error('Expected five classes; found %d.', numel(categories(Y)));
    end

    sourceInfo = struct();
    sourceInfo.file = trainingFile;
    sourceInfo.numObservations = size(X,1);
    sourceInfo.numPredictors = size(X,2);
    sourceInfo.classNames = categories(Y);

    if size(X,1) ~= 4000
        warning(['The manuscript reports 4000 samples per acquisition protocol, ' ...
            'whereas the loaded file contains %d observations.'], size(X,1));
    end
end

function [X, Y] = parseTrainingVariables(S)
    if isfield(S, 'X') && isfield(S, 'Y')
        X = S.X;
        Y = S.Y;
        return;
    end

    if isfield(S, 'DATA_5cls')
        T = S.DATA_5cls;
        if ~istable(T)
            error('DATA_5cls must be a MATLAB table.');
        end
        if ~ismember('Label', T.Properties.VariableNames)
            error('DATA_5cls must contain a response column named Label.');
        end

        predictorNames = setdiff(T.Properties.VariableNames, {'Label'}, 'stable');
        if numel(predictorNames) ~= 40
            error('DATA_5cls must contain exactly 40 predictor columns plus Label.');
        end

        X = table2array(T(:, predictorNames));
        Y = T.Label;
        return;
    end

    error('Training MAT file must contain X/Y or DATA_5cls with a Label column.');
end
