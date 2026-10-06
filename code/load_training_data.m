function [X,Y,sourceInfo] = load_training_data(protocol)
%LOAD_TRAINING_DATA Load a protocol-specific 40-feature model-development set.
    protocol=validatestring(char(protocol),{'Static','Dynamic'},mfilename,'protocol');
    scriptDir=fileparts(mfilename('fullpath')); repoRoot=fileparts(scriptDir);
    trainingFile=fullfile(repoRoot,'data','training',sprintf('%s_training.mat',lower(protocol)));
    if ~isfile(trainingFile)
        error(['Training data file not found: %s\nSee data/training/README.md for the required format.'],trainingFile);
    end
    S=load(trainingFile);
    if isfield(S,'X') && isfield(S,'Y')
        X=S.X; Y=S.Y;
    elseif isfield(S,'DATA_5cls')
        T=S.DATA_5cls;
        if ~istable(T) || ~ismember('Label',T.Properties.VariableNames)
            error('DATA_5cls must be a table with a Label column.');
        end
        predictorNames=setdiff(T.Properties.VariableNames,{'Label'},'stable');
        if numel(predictorNames)~=40, error('Expected exactly 40 predictor columns.'); end
        X=table2array(T(:,predictorNames)); Y=T.Label;
    else
        error('Training MAT file must contain X/Y or DATA_5cls with Label.');
    end
    X=double(X); Y=categorical(Y);
    if size(X,2)~=40, error('Expected 40 predictor columns.'); end
    if numel(categories(Y))~=5, error('Expected five classes.'); end
    sourceInfo=struct('file',trainingFile,'numObservations',size(X,1), ...
        'numPredictors',size(X,2),'classNames',{categories(Y)});
end
