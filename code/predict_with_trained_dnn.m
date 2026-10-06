function [labels,scores,trainedModel] = predict_with_trained_dnn(X,protocol)
%PREDICT_WITH_TRAINED_DNN Apply the released Static or Dynamic DNN model.
    arguments
        X double
        protocol {mustBeTextScalar}
    end
    if size(X,2)~=40, error('X must contain exactly 40 predictor columns.'); end
    scriptDir=fileparts(mfilename('fullpath')); repoRoot=fileparts(scriptDir);
    switch lower(string(protocol))
        case "static"
            modelFile=fullfile(repoRoot,'data','online','static','DNN.mat');
        case "dynamic"
            modelFile=fullfile(repoRoot,'data','online','dynamic','DNN.mat');
        otherwise
            error('protocol must be "Static" or "Dynamic".');
    end
    S=load(modelFile,'NN3'); trainedModel=S.NN3;
    [labels,scores]=trainedModel.predictFcn(X);
end
