% analyze_dnn_lpe_pc_mainboard.m
% Reproduce compact-DNN LPE results and compare PC vs main-board execution.
%
% The MAT file contains five compact-DNN result structures labeled by
% the investigator-confirmed baseline shift in millimeters.

clearvars;
clc;

scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(scriptDir);
sourceFile = fullfile(repoRoot, 'data', 'lpe', 'dnn_lpe_pc_mainboard.mat');
outputDir = fullfile(repoRoot, 'outputs', 'analysis');
if ~isfolder(outputDir), mkdir(outputDir); end

S = load(sourceFile);
conditionVars = {'DNN_LPE_0mm','DNN_LPE_1p5mm', ...
                 'DNN_LPE_3mm','DNN_LPE_4p5mm','DNN_LPE_6mm'};
physicalShift_mm = [0 1.5 3.0 4.5 6.0];
assert(isequal(S.condition_shift_mm(:)', physicalShift_mm), ...
    'Condition shifts in MAT file differ from the selected protocol.');
gestureNames = {'Grasp and Release','Wrist Flexion/Extension', ...
                'Fourth and Fifth Fingers','Tripod Pinch'};
hardwareFields = {'pc','mb'};
hardwareNames = {'PC','MainBoard'};
ctThreshold = 1.125;
maxRuns = 10;

% Long-form table: one row per recorded task trial.
T = table();
for c = 1:numel(conditionVars)
    R = S.(conditionVars{c});
    for g = 1:numel(gestureNames)
        for h = 1:numel(hardwareFields)
            D = R.RTtest.(hardwareFields{h}){1,g};
            n = min([numel(D.timeST), numel(D.timeCT), numel(D.ACC), maxRuns]);
            st = D.timeST(1:n); ct = D.timeCT(1:n); rta = 100*D.ACC(1:n);
            completion = ct(:) <= ctThreshold;
            block = table(repmat(c,n,1), repmat(string(conditionVars{c}),n,1), ...
                repmat(physicalShift_mm(c),n,1), ...
                repmat(g,n,1), repmat(string(gestureNames{g}),n,1), (1:n)', ...
                repmat(string(hardwareNames{h}),n,1), st(:), ct(:), rta(:), completion, ...
                'VariableNames', {'ConditionID','SourceCondition', ...
                'PhysicalDisplacement_mm','GestureID','Gesture', ...
                'Trial','Hardware','ST_s','CT_s','RTA_pct','Completion'});
            T = [T; block]; %#ok<AGROW>
        end
    end
end

% Table V: PC implementation under LPE conditions.
pcT = T(T.Hardware=="PC",:);
tableV = groupsummary(pcT, {'GestureID','Gesture'}, {'mean','std','numel'}, ...
    {'ST_s','CT_s','RTA_pct'});
cr = groupsummary(pcT, {'GestureID','Gesture'}, 'mean', 'Completion');
tableV.CR_pct = 100*cr.mean_Completion;
disp('Table V: compact DNN on PC');
disp(tableV);

% Table VI: implementation comparison, pooled across recorded LPE trials.
tableVI = groupsummary(T, 'Hardware', {'mean','std','numel'}, {'ST_s','CT_s','RTA_pct'});
cr2 = groupsummary(T, 'Hardware', 'mean', 'Completion');
tableVI.CR_pct = 100*cr2.mean_Completion;
disp('Table VI: PC vs Main Board');
disp(tableVI);

% Matched PC/MainBoard comparisons.
keys = {'ConditionID','GestureID','Trial'};
pcPair = sortrows(T(T.Hardware=="PC",:), keys);
mbPair = sortrows(T(T.Hardware=="MainBoard",:), keys);
if ~isequal(pcPair{:,keys}, mbPair{:,keys})
    error('PC and Main Board trial keys do not align.');
end

metrics = {'ST_s','CT_s','RTA_pct'};
pRaw = nan(4,1);
statRows = table();
for k = 1:numel(metrics)
    x = pcPair.(metrics{k}); y = mbPair.(metrics{k});
    [p,~,stats] = signrank(y,x,'method','approximate');
    d = y-x;
    nz = d~=0;
    r = tiedrank(abs(d(nz)));
    Wp = sum(r(d(nz)>0)); Wm = sum(r(d(nz)<0));
    rbc = (Wp-Wm)/(Wp+Wm);
    pRaw(k)=p;
    row = table(string(metrics{k}), string('Wilcoxon signed-rank'), numel(x), ...
        mean(x), mean(y), mean(d), median(d), stats.signedrank, p, rbc, ...
        'VariableNames', {'Metric','Test','N_pairs','PC_mean','MainBoard_mean', ...
        'Mean_difference','Median_difference','Statistic','P_raw','Effect_size'});
    statRows = [statRows; row]; %#ok<AGROW>
end

pcSuccess = pcPair.Completion; mbSuccess = mbPair.Completion;
pcOnly = sum(pcSuccess & ~mbSuccess); mbOnly = sum(~pcSuccess & mbSuccess);
nd = pcOnly + mbOnly;
if nd==0
    pMc = 1;
else
    pMc = min(1, 2*binocdf(min(pcOnly,mbOnly), nd, 0.5));
end
pRaw(4)=pMc;
row = table("CR", "Exact McNemar", height(pcPair), ...
    100*mean(pcSuccess), 100*mean(mbSuccess), ...
    100*(mean(mbSuccess)-mean(pcSuccess)), NaN, nd, pMc, NaN, ...
    'VariableNames', {'Metric','Test','N_pairs','PC_mean','MainBoard_mean', ...
    'Mean_difference','Median_difference','Statistic','P_raw','Effect_size'});
statRows = [statRows; row];

% Holm adjustment across four implementation comparisons.
[ps,ord] = sort(pRaw);
adjSorted = zeros(size(ps)); running = 0;
for i=1:numel(ps)
    running = max(running, (numel(ps)-i+1)*ps(i));
    adjSorted(i) = min(1,running);
end
pHolm = zeros(size(pRaw)); pHolm(ord)=adjSorted;
statRows.P_Holm = pHolm;
disp('Paired PC vs Main Board tests');
disp(statRows);

% Prediction-stream agreement.
actual=[]; pcPred=[]; mbPred=[];
for c=1:numel(conditionVars)
    R=S.(conditionVars{c});
    n=min([numel(R.net_actual),numel(R.net_pred),numel(R.net_main_pred)]);
    actual=[actual; reshape(R.net_actual(1:n),[],1)]; %#ok<AGROW>
    pcPred=[pcPred; reshape(R.net_pred(1:n),[],1)]; %#ok<AGROW>
    mbPred=[mbPred; reshape(R.net_main_pred(1:n),[],1)]; %#ok<AGROW>
end
agreement = table(numel(actual), 100*mean(pcPred==actual), ...
    100*mean(mbPred==actual), 100*mean(pcPred==mbPred), ...
    'VariableNames', {'N_synchronized_predictions','PC_vs_actual_pct', ...
    'MainBoard_vs_actual_pct','PC_vs_MainBoard_agreement_pct'});
disp('Prediction-stream agreement');
disp(agreement);

writetable(T, fullfile(outputDir,'dnn_lpe_trials.csv'));
writetable(tableV, fullfile(outputDir,'table_v_dnn_lpe_pc.csv'));
writetable(tableVI, fullfile(outputDir,'table_vi_dnn_pc_mainboard.csv'));
writetable(statRows, fullfile(outputDir,'dnn_pc_mainboard_paired_statistics.csv'));
writetable(agreement, fullfile(outputDir,'dnn_prediction_agreement.csv'));
