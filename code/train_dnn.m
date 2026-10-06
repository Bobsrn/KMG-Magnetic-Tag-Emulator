function result = train_dnn(protocol,rngSeed)
%TRAIN_DNN Train the compact feedforward DNN configuration used in the study.
    if nargin<2, rngSeed=[]; end
    protocol=validatestring(char(protocol),{'Static','Dynamic'},mfilename,'protocol');
    if ~isempty(rngSeed), rng(rngSeed,'twister'); end
    [X,Y,sourceInfo]=load_training_data(protocol);
    order=randperm(size(X,1)); nTrain=round(0.80*size(X,1));
    trainIdx=order(1:nTrain); holdoutIdx=order(nTrain+1:end);
    XTrain=X(trainIdx,:); YTrain=Y(trainIdx); XHoldout=X(holdoutIdx,:); YHoldout=Y(holdoutIdx);
    layers=[
        featureInputLayer(40,'Name','input','Normalization','none')
        fullyConnectedLayer(128,'Name','fc1')
        reluLayer('Name','relu1')
        fullyConnectedLayer(64,'Name','fc2')
        reluLayer('Name','relu2')
        fullyConnectedLayer(32,'Name','fc3')
        reluLayer('Name','relu3')
        fullyConnectedLayer(5,'Name','output')
        softmaxLayer('Name','softmax')
        classificationLayer('Name','classoutput')];
    options=trainingOptions('adam','MaxEpochs',30,'MiniBatchSize',64, ...
        'Shuffle','every-epoch','ValidationData',{XHoldout,YHoldout}, ...
        'Verbose',true,'Plots','training-progress');
    net=trainNetwork(XTrain,YTrain,layers,options);
    pred=classify(net,XHoldout);
    result=struct('protocol',string(protocol),'network',net, ...
        'holdoutAccuracy',mean(pred==YHoldout),'trainIdx',trainIdx, ...
        'holdoutIdx',holdoutIdx,'rngSeed',rngSeed,'sourceInfo',sourceInfo);
    scriptDir=fileparts(mfilename('fullpath')); repoRoot=fileparts(scriptDir);
    out=fullfile(repoRoot,'outputs','models'); if ~isfolder(out), mkdir(out); end
    save(fullfile(out,sprintf('DNN_%s_retrained.mat',lower(protocol))),'result','-v7.3');
end
