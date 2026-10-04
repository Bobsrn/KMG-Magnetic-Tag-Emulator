function result = train_dnn(protocol, rngSeed)
%TRAIN_DNN Train the compact DNN configuration described in the manuscript.
%
%   result = train_dnn("Static")
%   result = train_dnn("Dynamic", 1)
%
% Configuration:
%   - 40 scalar magnetic-field predictors
%   - five output classes
%   - hidden layers: 128, 64, and 32 ReLU units
%   - softmax output with cross-entropy classification loss
%   - Adam optimizer
%   - 30 epochs
%   - mini-batch size 64
%   - 80% model fitting / 20% internal model-development holdout
%   - training observations shuffled every epoch
%
% The script expects protocol-specific model-development data in
% data/training/static_training.mat or data/training/dynamic_training.mat.
% See data/training/README.md for the accepted file format.

    if nargin < 2
        rngSeed = [];
    end

    protocol = validatestring(char(protocol), {'Static','Dynamic'}, mfilename, 'protocol');

    if ~isempty(rngSeed)
        rng(rngSeed, 'twister');
    end

    [X, Y, sourceInfo] = load_kmg_training_data(protocol);

    numSamples = size(X,1);
    order = randperm(numSamples);
    nTrain = round(0.80 * numSamples);

    trainIdx = order(1:nTrain);
    holdoutIdx = order(nTrain+1:end);

    XTrain = X(trainIdx,:);
    YTrain = Y(trainIdx);
    XHoldout = X(holdoutIdx,:);
    YHoldout = Y(holdoutIdx);

    layers = [
        featureInputLayer(40, 'Name', 'input', 'Normalization', 'none')
        fullyConnectedLayer(128, 'Name', 'fc1')
        reluLayer('Name', 'relu1')
        fullyConnectedLayer(64, 'Name', 'fc2')
        reluLayer('Name', 'relu2')
        fullyConnectedLayer(32, 'Name', 'fc3')
        reluLayer('Name', 'relu3')
        fullyConnectedLayer(5, 'Name', 'output')
        softmaxLayer('Name', 'softmax')
        classificationLayer('Name', 'classoutput')
        ];

    options = trainingOptions('adam', ...
        'MaxEpochs', 30, ...
        'MiniBatchSize', 64, ...
        'Shuffle', 'every-epoch', ...
        'ValidationData', {XHoldout, YHoldout}, ...
        'Verbose', true, ...
        'Plots', 'training-progress');

    net = trainNetwork(XTrain, YTrain, layers, options);
    holdoutPred = classify(net, XHoldout);
    holdoutAccuracy = mean(holdoutPred == YHoldout);

    result = struct();
    result.protocol = string(protocol);
    result.network = net;
    result.holdoutAccuracy = holdoutAccuracy;
    result.trainIdx = trainIdx;
    result.holdoutIdx = holdoutIdx;
    result.rngSeed = rngSeed;
    result.sourceInfo = sourceInfo;

    scriptDir = fileparts(mfilename('fullpath'));
    repoRoot = fileparts(scriptDir);
    outputDir = fullfile(repoRoot, 'outputs', 'models');
    if ~isfolder(outputDir)
        mkdir(outputDir);
    end

    outputFile = fullfile(outputDir, sprintf('DNN_%s_retrained.mat', lower(protocol)));
    save(outputFile, 'result', '-v7.3');

    fprintf('\n%s DNN training complete.\n', protocol);
    fprintf('Observations: %d (%d fitting, %d holdout)\n', ...
        numSamples, numel(trainIdx), numel(holdoutIdx));
    fprintf('Holdout accuracy: %.2f%%\n', 100 * holdoutAccuracy);
    fprintf('Saved: %s\n', outputFile);
end
