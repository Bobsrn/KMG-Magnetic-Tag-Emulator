% reproduce_lpe_table.m
% Reproduces the pooled DNN limb-position-effect summary from the released data.
%
% Six recorded baseline-shift conditions are pooled. Each condition contains
% 10 online trials for each of the four functional gestures. Completion Rate
% is the percentage of trials with CT <= 1.125 s.

clearvars;
clc;

scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(scriptDir);
sourceFile = fullfile(repoRoot, 'data', 'lpe', 'DNN_LPE.mat');
outputDir = fullfile(repoRoot, 'outputs', 'analysis');
if ~isfolder(outputDir)
    mkdir(outputDir);
end

S = load(sourceFile);
conditionNames = { ...
    'TestResults_conv_0', ...
    'TestResults_conv_15', ...
    'TestResults_conv_25', ...
    'TestResults_conv_5', ...
    'TestResults_conv_6', ...
    'TestResults_conv_75'};
shift_mm = [0, 1.5, 2.5, 5.0, 6.0, 7.5];

gestureNames = { ...
    'Grasp and Release', ...
    'Wrist Flexion/Extension', ...
    'Fourth and Fifth Fingers', ...
    'Tripod Pinch'};

numGestures = numel(gestureNames);
ctThreshold = 1.125;

ST = cell(numGestures,1);
CT = cell(numGestures,1);
RTA = cell(numGestures,1);
conditionRows = table();

for c = 1:numel(conditionNames)
    name = conditionNames{c};
    if ~isfield(S, name)
        error('Missing LPE result block: %s', name);
    end

    R = S.(name);
    if ~isfield(R, 'RTtest') || ~isfield(R.RTtest, 'pc')
        error('Expected RTtest.pc was not found in %s.', name);
    end

    for g = 1:numGestures
        D = R.RTtest.pc{1,g};
        st = D.timeST(:);
        ct = D.timeCT(:);
        rta = 100 .* D.ACC(:);

        if numel(st) ~= 10 || numel(ct) ~= 10 || numel(rta) ~= 10
            error('Expected 10 trials in %s, gesture %d.', name, g);
        end

        ST{g} = [ST{g}; st]; %#ok<AGROW>
        CT{g} = [CT{g}; ct]; %#ok<AGROW>
        RTA{g} = [RTA{g}; rta]; %#ok<AGROW>

        row = table(c, shift_mm(c), g, string(gestureNames{g}), numel(st), ...
            mean(st), std(st), mean(ct), std(ct), mean(rta), std(rta), ...
            100*mean(ct <= ctThreshold), ...
            'VariableNames', {'ConditionID','BaselineShift_mm','GestureID','Gesture', ...
            'N_trials','ST_mean_s','ST_sd_s','CT_mean_s','CT_sd_s', ...
            'RTA_mean_pct','RTA_sd_pct','CR_pct'});
        conditionRows = [conditionRows; row]; %#ok<AGROW>
    end
end

summary = table('Size', [numGestures 10], ...
    'VariableTypes', {'double','string','double','double','double','double','double','double','double','double'}, ...
    'VariableNames', {'GestureID','Gesture','N_trials','ST_mean_s','ST_sd_s', ...
    'CT_mean_s','CT_sd_s','RTA_mean_pct','RTA_sd_pct','CR_pct'});

for g = 1:numGestures
    summary.GestureID(g) = g;
    summary.Gesture(g) = string(gestureNames{g});
    summary.N_trials(g) = numel(ST{g});
    summary.ST_mean_s(g) = mean(ST{g}, 'omitnan');
    summary.ST_sd_s(g) = std(ST{g}, 0, 'omitnan');
    summary.CT_mean_s(g) = mean(CT{g}, 'omitnan');
    summary.CT_sd_s(g) = std(CT{g}, 0, 'omitnan');
    summary.RTA_mean_pct(g) = mean(RTA{g}, 'omitnan');
    summary.RTA_sd_pct(g) = std(RTA{g}, 0, 'omitnan');
    summary.CR_pct(g) = 100 * mean(CT{g} <= ctThreshold, 'omitnan');
end

disp(summary);

writetable(summary, fullfile(outputDir, 'lpe_table_summary.csv'));
writetable(conditionRows, fullfile(outputDir, 'lpe_condition_summary.csv'));
fprintf('Saved pooled and condition-level LPE summaries to %s\n', outputDir);
