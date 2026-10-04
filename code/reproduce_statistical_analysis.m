% reproduce_statistical_analysis.m
% Reproduces the independent-run statistical analysis reported for the
% Static and Dynamic online experiments.
% Requires MATLAB Statistics and Machine Learning Toolbox.
% Data and output paths are resolved relative to this repository.

clearvars;
close all;
clc;

%% ============================================================
% KMG INDEPENDENT-RUN STATISTICAL ANALYSIS
%
% Experimental design
% -------------------
% Each classifier is evaluated in its own online run. Therefore,
% observations from different classifiers are INDEPENDENT and are
% not paired by gesture repetition.
%
% Within each acquisition protocol
% --------------------------------
% ST, CT, and RTA:
%   1. Kruskal-Wallis omnibus test
%   2. Epsilon-squared omnibus effect size
%   3. Pairwise Mann-Whitney U tests (MATLAB ranksum)
%   4. Holm correction across the 10 classifier pairs
%   5. Cliff's delta pairwise effect size
%
% Completion success / CR (CT <= 1.125 s):
%   1. Pearson chi-square test of independence on a 5-by-2 table
%   2. Cramer's V omnibus effect size
%   3. Pairwise two-sided Fisher exact tests
%   4. Holm correction across the 10 classifier pairs
%   5. Wilson 95% confidence intervals, risk difference, and odds ratio
%
% Between acquisition protocols, within each classifier
% -----------------------------------------------------
% ST, CT, and RTA:
%   Independent Mann-Whitney U tests with Holm correction across
%   the five classifiers for each metric, plus Cliff's delta.
%
% CR:
%   Pairwise Fisher exact tests with Holm correction across the
%   five classifiers.
%
% Outputs
% -------
%   KMG_Independent_Statistical_Analysis.xlsx
%   KMG_Independent_Statistical_Analysis.mat
%   KMG_Manuscript_Statistical_Summary.txt
%
% Requires MATLAB Statistics and Machine Learning Toolbox.
%% ============================================================

%% General configuration
modelNames = {'QDA', 'SVM', 'kNN', 'NN', 'DNN'};
protocolNames = {'Static', 'Dynamic'};
metricNames = {'ST', 'CT', 'RTA'};

numModels = numel(modelNames);
numGestures = 4;
numProtocols = numel(protocolNames);
alpha = 0.05;

% Completion criterion
ctThreshold = 1.125;

% Repository-relative paths and output files
scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(scriptDir);
rootStatic = fullfile(repoRoot, 'data', 'online', 'static');
rootDynamic = fullfile(repoRoot, 'data', 'online', 'dynamic');
rootFolders = {rootStatic, rootDynamic};

outputDir = fullfile(repoRoot, 'outputs', 'analysis');
if ~isfolder(outputDir)
    mkdir(outputDir);
end

outputExcel = fullfile(outputDir, 'KMG_Independent_Statistical_Analysis.xlsx');
outputMAT = fullfile(outputDir, 'KMG_Independent_Statistical_Analysis.mat');
outputText = fullfile(outputDir, 'KMG_Manuscript_Statistical_Summary.txt');

if isfile(outputExcel)
    delete(outputExcel);
end
if isfile(outputText)
    delete(outputText);
end

%% File names
staticFiles = {
    'QDA.mat'
    'SVM.mat'
    'kNN.mat'
    'NN.mat'
    'DNN.mat'
    };

dynamicFiles = {
    'QDA.mat'
    'SVM.mat'
    'kNN.mat'
    'NN.mat'
    'DNN.mat'
    };

fileNames = {staticFiles, dynamicFiles};

%% Load all data
% data{protocol, model}{gesture}
data = cell(numProtocols, numModels);

for p = 1:numProtocols
    for m = 1:numModels
        filePath = fullfile(rootFolders{p}, fileNames{p}{m});
        data{p, m} = loadGestureTrials(filePath);
    end
end

%% Convert all observations into one long-format table
longData = buildLongDataTable( ...
    data, protocolNames, modelNames, numGestures, ...
    ctThreshold);

fprintf('\n============================================================\n');
fprintf('KMG INDEPENDENT-RUN STATISTICAL ANALYSIS\n');
fprintf('============================================================\n');
fprintf('Each classifier is evaluated in a separate online run.\n');
fprintf('Classifier groups are therefore treated as independent.\n');
fprintf('Total rows in long-format dataset: %d\n', height(longData));

%% Initialize output tables
continuousDescAll = table();
continuousOmnibusAll = table();
continuousPairsAll = table();

crDescAll = table();
crOmnibusAll = table();
crPairsAll = table();

protocolContinuousAll = table();
protocolCRAll = table();

analysisResults = struct();

%% ============================================================
%  PART 1: CLASSIFIER COMPARISONS WITHIN EACH PROTOCOL
%% ============================================================
for p = 1:numProtocols

    protocolName = protocolNames{p};
    protocolMask = longData.Protocol == string(protocolName);
    protocolTable = longData(protocolMask, :);

    fprintf('\n\n============================================================\n');
    fprintf('%s PROTOCOL: CLASSIFIER COMPARISONS\n', upper(protocolName));
    fprintf('============================================================\n');

    %% Continuous metrics
    for k = 1:numel(metricNames)

        metricName = metricNames{k};
        metricValues = protocolTable.(metricName);
        modelLabels = protocolTable.Model;

        fprintf('\n------------------------------------------------------------\n');
        fprintf('%s: %s protocol\n', metricName, protocolName);
        fprintf('------------------------------------------------------------\n');

        % Descriptive statistics
        descTable = continuousDescriptiveLong( ...
            protocolTable, metricName, modelNames, protocolName);
        disp(descTable);
        continuousDescAll = [continuousDescAll; descTable]; %#ok<AGROW>

        % Kruskal-Wallis omnibus test
        kw = kruskalWallisIndependent(metricValues, modelLabels, modelNames);

        fprintf('\nKruskal-Wallis test\n');
        fprintf('H(%d) = %.6f, p = %.6g\n', kw.DF, kw.H, kw.PValue);
        fprintf('Epsilon-squared = %.6f (%s)\n', ...
            kw.EpsilonSquared, kw.EffectMagnitude);

        omnibusRow = table( ...
            string(protocolName), string(metricName), kw.N, kw.K, ...
            kw.H, kw.DF, kw.PValue, kw.EpsilonSquared, ...
            string(kw.EffectMagnitude), ...
            'VariableNames', { ...
            'Protocol', 'Metric', 'N_Total', 'NumberOfGroups', ...
            'H', 'DF', 'PValue', 'EpsilonSquared', 'EffectMagnitude'});

        continuousOmnibusAll = [continuousOmnibusAll; omnibusRow]; %#ok<AGROW>

        % Pairwise Mann-Whitney U tests
        pairTable = pairwiseMannWhitneyHolm( ...
            protocolTable, metricName, modelNames, protocolName, alpha);

        fprintf('\nPairwise Mann-Whitney U comparisons\n');
        disp(pairTable);

        significantPairs = pairTable(pairTable.Significant, :);
        if isempty(significantPairs)
            fprintf('No pairwise comparison remains significant after Holm correction.\n');
        else
            fprintf('Significant pairwise comparisons after Holm correction:\n');
            disp(significantPairs);
        end

        continuousPairsAll = [continuousPairsAll; pairTable]; %#ok<AGROW>

        % Save in structure
        pField = matlab.lang.makeValidName(protocolName);
        mField = matlab.lang.makeValidName(metricName);
        analysisResults.(pField).(mField).Descriptive = descTable;
        analysisResults.(pField).(mField).Omnibus = kw;
        analysisResults.(pField).(mField).Pairwise = pairTable;
    end

    %% Completion Rate / binary success
    fprintf('\n------------------------------------------------------------\n');
    fprintf('Completion Rate: %s protocol\n', protocolName);
    fprintf('------------------------------------------------------------\n');

    crDesc = completionRateLong(protocolTable, modelNames, protocolName);
    disp(crDesc);
    crDescAll = [crDescAll; crDesc]; %#ok<AGROW>

    fprintf('\nIMPORTANT CHECK\n');
    fprintf(['Confirm that these CR values match the manuscript. ' ...
        'If not, verify ctThreshold.\n']);

    crOmnibus = pearsonChiSquareCR(protocolTable, modelNames);

    fprintf('\nPearson chi-square test of independence\n');
    fprintf('Chi-square(%d) = %.6f, p = %.6g\n', ...
        crOmnibus.DF, crOmnibus.ChiSquare, crOmnibus.PValue);
    fprintf('Cramer''s V = %.6f (%s)\n', ...
        crOmnibus.CramersV, crOmnibus.EffectMagnitude);

    crOmnibusRow = table( ...
        string(protocolName), crOmnibus.N, crOmnibus.ChiSquare, ...
        crOmnibus.DF, crOmnibus.PValue, crOmnibus.CramersV, ...
        string(crOmnibus.EffectMagnitude), ...
        'VariableNames', { ...
        'Protocol', 'N_Total', 'ChiSquare', 'DF', 'PValue', ...
        'CramersV', 'EffectMagnitude'});

    crOmnibusAll = [crOmnibusAll; crOmnibusRow]; %#ok<AGROW>

    crPairTable = pairwiseFisherHolm( ...
        protocolTable, modelNames, protocolName, alpha);

    fprintf('\nPairwise two-sided Fisher exact comparisons\n');
    disp(crPairTable);

    significantCRPairs = crPairTable(crPairTable.Significant, :);
    if isempty(significantCRPairs)
        fprintf('No CR comparison remains significant after Holm correction.\n');
    else
        fprintf('Significant CR comparisons after Holm correction:\n');
        disp(significantCRPairs);
    end

    crPairsAll = [crPairsAll; crPairTable]; %#ok<AGROW>

    pField = matlab.lang.makeValidName(protocolName);
    analysisResults.(pField).CR.Descriptive = crDesc;
    analysisResults.(pField).CR.Omnibus = crOmnibus;
    analysisResults.(pField).CR.Pairwise = crPairTable;
end

%% ============================================================
%  PART 2: STATIC-VERSUS-DYNAMIC COMPARISONS WITHIN EACH MODEL
%  These analyses directly quantify the acquisition-protocol effect.
%% ============================================================
fprintf('\n\n============================================================\n');
fprintf('STATIC-VERSUS-DYNAMIC COMPARISONS WITHIN EACH CLASSIFIER\n');
fprintf('============================================================\n');

for k = 1:numel(metricNames)

    metricName = metricNames{k};
    tempRows = table();
    rawP = nan(numModels, 1);

    for m = 1:numModels

        modelName = modelNames{m};

        x = longData.(metricName)( ...
            longData.Model == string(modelName) & ...
            longData.Protocol == "Static");

        y = longData.(metricName)( ...
            longData.Model == string(modelName) & ...
            longData.Protocol == "Dynamic");

        x = x(isfinite(x));
        y = y(isfinite(y));

        [pValue, uStatistic] = mannWhitneyPAndU(x, y);
        delta = cliffsDelta(x, y); % positive: Static > Dynamic

        medianStatic = median(x);
        medianDynamic = median(y);

        betterProtocol = chooseBetterProtocol( ...
            metricName, medianStatic, medianDynamic);

        rawP(m) = pValue;

        row = table( ...
            string(metricName), string(modelName), ...
            numel(x), numel(y), medianStatic, medianDynamic, ...
            medianDynamic - medianStatic, uStatistic, delta, ...
            string(cliffsMagnitude(delta)), pValue, NaN, false, ...
            string(betterProtocol), ...
            'VariableNames', { ...
            'Metric', 'Model', 'N_Static', 'N_Dynamic', ...
            'Median_Static', 'Median_Dynamic', ...
            'DynamicMinusStatic_Median', 'U_Static', ...
            'CliffsDelta_StaticVsDynamic', 'EffectMagnitude', ...
            'P_Raw', 'P_Holm', 'Significant', 'BetterProtocol'});

        tempRows = [tempRows; row]; %#ok<AGROW>
    end

    adjustedP = holmAdjustment(rawP);
    tempRows.P_Holm = adjustedP;
    tempRows.Significant = adjustedP < alpha;

    fprintf('\n%s: Static versus Dynamic within each classifier\n', metricName);
    disp(tempRows);

    protocolContinuousAll = [protocolContinuousAll; tempRows]; %#ok<AGROW>
end

%% CR: Static versus Dynamic within each classifier
rawP = nan(numModels, 1);
tempRows = table();

for m = 1:numModels

    modelName = modelNames{m};

    staticSuccess = longData.Success( ...
        longData.Model == string(modelName) & ...
        longData.Protocol == "Static");

    dynamicSuccess = longData.Success( ...
        longData.Model == string(modelName) & ...
        longData.Protocol == "Dynamic");

    s1 = sum(staticSuccess);
    n1 = numel(staticSuccess);
    s2 = sum(dynamicSuccess);
    n2 = numel(dynamicSuccess);

    contingency = [s1, n1 - s1; s2, n2 - s2];
    pValue = fisherExactTwoSided(contingency);

    riskStatic = s1 / n1;
    riskDynamic = s2 / n2;
    riskDifference = 100 * (riskDynamic - riskStatic);
    oddsRatio = correctedOddsRatio(contingency);

    if riskDynamic > riskStatic
        betterProtocol = "Dynamic";
    elseif riskDynamic < riskStatic
        betterProtocol = "Static";
    else
        betterProtocol = "Tie";
    end

    rawP(m) = pValue;

    row = table( ...
        string(modelName), s1, n1, 100 * riskStatic, ...
        s2, n2, 100 * riskDynamic, riskDifference, oddsRatio, ...
        pValue, NaN, false, betterProtocol, ...
        'VariableNames', { ...
        'Model', 'StaticSuccesses', 'StaticTrials', 'StaticCR_Percent', ...
        'DynamicSuccesses', 'DynamicTrials', 'DynamicCR_Percent', ...
        'DynamicMinusStatic_CR_Percent', 'OddsRatio_StaticVsDynamic', ...
        'P_Raw', 'P_Holm', 'Significant', 'BetterProtocol'});

    tempRows = [tempRows; row]; %#ok<AGROW>
end

adjustedP = holmAdjustment(rawP);
tempRows.P_Holm = adjustedP;
tempRows.Significant = adjustedP < alpha;
protocolCRAll = tempRows;

fprintf('\nCR: Static versus Dynamic within each classifier\n');
disp(protocolCRAll);

%% ============================================================
%  CREATE MANUSCRIPT-READY SUMMARY
%% ============================================================
summaryLines = buildManuscriptSummary( ...
    continuousOmnibusAll, continuousPairsAll, ...
    crOmnibusAll, crPairsAll, ...
    protocolContinuousAll, protocolCRAll, alpha);

fprintf('\n\n============================================================\n');
fprintf('MANUSCRIPT-READY STATISTICAL SUMMARY\n');
fprintf('============================================================\n');
for i = 1:numel(summaryLines)
    fprintf('%s\n', summaryLines{i});
end

fid = fopen(outputText, 'w');
if fid < 0
    error('Could not create output text file: %s', outputText);
end
cleanupObject = onCleanup(@() fclose(fid)); %#ok<NASGU>
for i = 1:numel(summaryLines)
    fprintf(fid, '%s\n', summaryLines{i});
end

%% ============================================================
%  EXPORT RESULTS
%% ============================================================
writetable(longData, outputExcel, 'Sheet', 'Raw_Long_Data');
writetable(continuousDescAll, outputExcel, 'Sheet', 'Desc_Continuous');
writetable(continuousOmnibusAll, outputExcel, 'Sheet', 'Omnibus_Classifier');
writetable(continuousPairsAll, outputExcel, 'Sheet', 'Pairs_Classifier');
writetable(crDescAll, outputExcel, 'Sheet', 'CR_Descriptive');
writetable(crOmnibusAll, outputExcel, 'Sheet', 'CR_Omnibus');
writetable(crPairsAll, outputExcel, 'Sheet', 'CR_Pairs');
writetable(protocolContinuousAll, outputExcel, 'Sheet', 'Protocol_Continuous');
writetable(protocolCRAll, outputExcel, 'Sheet', 'Protocol_CR');

analysisResults.LongData = longData;
analysisResults.ContinuousDescriptive = continuousDescAll;
analysisResults.ContinuousOmnibus = continuousOmnibusAll;
analysisResults.ContinuousPairwise = continuousPairsAll;
analysisResults.CRDescriptive = crDescAll;
analysisResults.CROmnibus = crOmnibusAll;
analysisResults.CRPairwise = crPairsAll;
analysisResults.ProtocolContinuous = protocolContinuousAll;
analysisResults.ProtocolCR = protocolCRAll;
analysisResults.ManuscriptSummary = summaryLines;

save( ...
    outputMAT, ...
    'analysisResults', ...
    'modelNames', ...
    'protocolNames', ...
    'metricNames', ...
    'ctThreshold', ...
    'alpha');

fprintf('\n============================================================\n');
fprintf('Analysis complete.\n');
fprintf('Excel output: %s\n', outputExcel);
fprintf('MAT output:   %s\n', outputMAT);
fprintf('Text output:  %s\n', outputText);
fprintf('============================================================\n');

%% ============================================================
%  LOCAL FUNCTIONS
%% ============================================================

function gestureTrials = loadGestureTrials(filePath)
%LOADGESTURETRIALS Loads RTtest1 through RTtest4 from one MAT file.

    if ~isfile(filePath)
        error('The following MAT file does not exist:\n%s', filePath);
    end

    loadedData = load( ...
        filePath, ...
        'RTtest1', ...
        'RTtest2', ...
        'RTtest3', ...
        'RTtest4');

    requiredVariables = {'RTtest1', 'RTtest2', 'RTtest3', 'RTtest4'};

    for i = 1:numel(requiredVariables)
        variableName = requiredVariables{i};
        if ~isfield(loadedData, variableName)
            error('Variable %s is missing from:\n%s', variableName, filePath);
        end
    end

    gestureTrials = { ...
        loadedData.RTtest1, ...
        loadedData.RTtest2, ...
        loadedData.RTtest3, ...
        loadedData.RTtest4};
end

function longTable = buildLongDataTable( ...
    data, protocolNames, modelNames, numGestures, ...
    ctThreshold)
%BUILDLONGDATATABLE Creates one row per independent online trial.

    Protocol = strings(0, 1);
    Model = strings(0, 1);
    Gesture = zeros(0, 1);
    Repetition = zeros(0, 1);
    ST = zeros(0, 1);
    CT = zeros(0, 1);
    RTA = zeros(0, 1);
    Success = false(0, 1);

    for p = 1:numel(protocolNames)
        for m = 1:numel(modelNames)
            for g = 1:numGestures

                currentData = data{p, m}{g};

                currentST = currentData.timeST(:);
                currentCT = currentData.timeCT(:);
                currentACC = currentData.ACC(:);

                nTrials = numel(currentACC);

                if numel(currentST) ~= nTrials || numel(currentCT) ~= nTrials
                    error(['Metric lengths are inconsistent for protocol %s, ' ...
                        'model %s, gesture %d.'], ...
                        protocolNames{p}, modelNames{m}, g);
                end

                if max(currentACC, [], 'omitnan') > 1.5
                    error(['ACC appears to be stored as a percentage rather ' ...
                        'than a proportion for protocol %s, model %s, gesture %d.'], ...
                        protocolNames{p}, modelNames{m}, g);
                end

                currentST(~isfinite(currentST)) = NaN;
                currentCT(~isfinite(currentCT)) = NaN;
                currentACC(~isfinite(currentACC)) = NaN;

                currentRTA = 100 .* currentACC;

                currentSuccess = false(nTrials, 1);
                validTrial = isfinite(currentCT);
                currentSuccess(validTrial) = ...
                    currentCT(validTrial) <= ctThreshold;

                Protocol = [Protocol; repmat(string(protocolNames{p}), nTrials, 1)]; %#ok<AGROW>
                Model = [Model; repmat(string(modelNames{m}), nTrials, 1)]; %#ok<AGROW>
                Gesture = [Gesture; repmat(g, nTrials, 1)]; %#ok<AGROW>
                Repetition = [Repetition; (1:nTrials)']; %#ok<AGROW>
                ST = [ST; currentST]; %#ok<AGROW>
                CT = [CT; currentCT]; %#ok<AGROW>
                RTA = [RTA; currentRTA]; %#ok<AGROW>
                Success = [Success; currentSuccess]; %#ok<AGROW>
            end
        end
    end

    longTable = table( ...
        Protocol, Model, Gesture, Repetition, ST, CT, RTA, Success);
end

function outputTable = continuousDescriptiveLong( ...
    protocolTable, metricName, modelNames, protocolName)
%CONTINUOUSDESCRIPTIVELONG Descriptive statistics by classifier.

    numModels = numel(modelNames);

    Protocol = repmat(string(protocolName), numModels, 1);
    Metric = repmat(string(metricName), numModels, 1);
    Model = string(modelNames(:));

    N = zeros(numModels, 1);
    Mean = nan(numModels, 1);
    SD = nan(numModels, 1);
    Median = nan(numModels, 1);
    Q1 = nan(numModels, 1);
    Q3 = nan(numModels, 1);

    for m = 1:numModels
        values = protocolTable.(metricName)( ...
            protocolTable.Model == string(modelNames{m}));
        values = values(isfinite(values));

        N(m) = numel(values);
        if isempty(values)
            continue;
        end

        Mean(m) = mean(values);
        SD(m) = std(values);
        Median(m) = median(values);
        Q1(m) = prctile(values, 25);
        Q3(m) = prctile(values, 75);
    end

    outputTable = table( ...
        Protocol, Metric, Model, N, Mean, SD, Median, Q1, Q3);
end

function results = kruskalWallisIndependent(values, labels, modelNames)
%KRUSKALWALLISINDEPENDENT Kruskal-Wallis test with tie correction.

    valid = isfinite(values) & ~ismissing(labels);
    values = values(valid);
    labels = labels(valid);

    k = numel(modelNames);
    N = numel(values);

    ranks = tiedrank(values);
    rankSums = zeros(k, 1);
    groupCounts = zeros(k, 1);

    for m = 1:k
        mask = labels == string(modelNames{m});
        rankSums(m) = sum(ranks(mask));
        groupCounts(m) = sum(mask);

        if groupCounts(m) == 0
            error('No valid observations found for model %s.', modelNames{m});
        end
    end

    HUncorrected = ...
        (12 / (N * (N + 1))) * sum((rankSums.^2) ./ groupCounts) ...
        - 3 * (N + 1);

    [~, ~, tieGroup] = unique(values);
    tieCounts = accumarray(tieGroup, 1);
    tieCorrection = 1 - sum(tieCounts.^3 - tieCounts) / (N^3 - N);

    if tieCorrection <= 0
        H = 0;
        pValue = 1;
    else
        H = HUncorrected / tieCorrection;
        pValue = 1 - chi2cdf(H, k - 1);
    end

    epsilonSquared = (H - k + 1) / (N - k);
    epsilonSquared = max(0, min(1, epsilonSquared));

    results = struct( ...
        'N', N, ...
        'K', k, ...
        'H', H, ...
        'DF', k - 1, ...
        'PValue', pValue, ...
        'EpsilonSquared', epsilonSquared, ...
        'EffectMagnitude', epsilonMagnitude(epsilonSquared), ...
        'MeanRanks', rankSums ./ groupCounts, ...
        'TieCorrection', tieCorrection);
end

function outputTable = pairwiseMannWhitneyHolm( ...
    protocolTable, metricName, modelNames, protocolName, alpha)
%PAIRWISEMANNWHITNEYHOLM Independent pairwise tests with Holm correction.

    pairs = nchoosek(1:numel(modelNames), 2);
    numPairs = size(pairs, 1);

    Protocol = repmat(string(protocolName), numPairs, 1);
    Metric = repmat(string(metricName), numPairs, 1);
    Model1 = strings(numPairs, 1);
    Model2 = strings(numPairs, 1);
    N1 = zeros(numPairs, 1);
    N2 = zeros(numPairs, 1);
    Median1 = nan(numPairs, 1);
    Median2 = nan(numPairs, 1);
    U_Model1 = nan(numPairs, 1);
    CliffsDelta = nan(numPairs, 1);
    EffectMagnitude = strings(numPairs, 1);
    P_Raw = nan(numPairs, 1);
    BetterModel = strings(numPairs, 1);

    for i = 1:numPairs
        m1 = pairs(i, 1);
        m2 = pairs(i, 2);

        model1 = modelNames{m1};
        model2 = modelNames{m2};

        x = protocolTable.(metricName)(protocolTable.Model == string(model1));
        y = protocolTable.(metricName)(protocolTable.Model == string(model2));

        x = x(isfinite(x));
        y = y(isfinite(y));

        [pValue, uStatistic] = mannWhitneyPAndU(x, y);
        delta = cliffsDelta(x, y);

        med1 = median(x);
        med2 = median(y);

        Model1(i) = string(model1);
        Model2(i) = string(model2);
        N1(i) = numel(x);
        N2(i) = numel(y);
        Median1(i) = med1;
        Median2(i) = med2;
        U_Model1(i) = uStatistic;
        CliffsDelta(i) = delta;
        EffectMagnitude(i) = string(cliffsMagnitude(delta));
        P_Raw(i) = pValue;
        BetterModel(i) = string(chooseBetterModel(metricName, model1, model2, med1, med2));
    end

    P_Holm = holmAdjustment(P_Raw);
    Significant = P_Holm < alpha;

    outputTable = table( ...
        Protocol, Metric, Model1, Model2, N1, N2, ...
        Median1, Median2, U_Model1, CliffsDelta, EffectMagnitude, ...
        P_Raw, P_Holm, Significant, BetterModel);
end

function [pValue, uStatistic] = mannWhitneyPAndU(x, y)
%MANNWHITNEYPANDU Returns two-sided approximate p and U for group x.

    x = x(:);
    y = y(:);

    if isempty(x) || isempty(y)
        pValue = NaN;
        uStatistic = NaN;
        return;
    end

    combined = [x; y];
    if all(combined == combined(1))
        pValue = 1;
        uStatistic = numel(x) * numel(y) / 2;
        return;
    end

    pValue = ranksum(x, y, 'method', 'approximate');

    ranks = tiedrank(combined);
    rankSumX = sum(ranks(1:numel(x)));
    uStatistic = rankSumX - numel(x) * (numel(x) + 1) / 2;
end

function delta = cliffsDelta(x, y)
%CLIFFSDELTA Positive values mean x tends to be larger than y.

    x = x(:);
    y = y(:);

    if isempty(x) || isempty(y)
        delta = NaN;
        return;
    end

    comparisons = x - y.';
    delta = (sum(comparisons > 0, 'all') - ...
        sum(comparisons < 0, 'all')) / numel(comparisons);
end

function magnitude = cliffsMagnitude(delta)
%CLIFFSMAGNITUDE Conventional thresholds for absolute Cliff's delta.

    a = abs(delta);
    if a < 0.147
        magnitude = 'negligible';
    elseif a < 0.33
        magnitude = 'small';
    elseif a < 0.474
        magnitude = 'medium';
    else
        magnitude = 'large';
    end
end

function magnitude = epsilonMagnitude(epsilonSquared)
%EPSILONMAGNITUDE Eta-squared-like interpretation thresholds.

    if epsilonSquared < 0.01
        magnitude = 'negligible';
    elseif epsilonSquared < 0.06
        magnitude = 'small';
    elseif epsilonSquared < 0.14
        magnitude = 'moderate';
    else
        magnitude = 'large';
    end
end

function magnitude = cramersMagnitude(v)
%CRAMERSMAGNITUDE General descriptive thresholds.

    if v < 0.10
        magnitude = 'negligible';
    elseif v < 0.30
        magnitude = 'small';
    elseif v < 0.50
        magnitude = 'moderate';
    else
        magnitude = 'large';
    end
end

function betterModel = chooseBetterModel(metricName, model1, model2, med1, med2)
%CHOOSEBETTERMODEL Smaller is better for ST/CT; larger is better for RTA.

    if med1 == med2
        betterModel = 'Tie';
        return;
    end

    if strcmp(metricName, 'RTA')
        if med1 > med2
            betterModel = model1;
        else
            betterModel = model2;
        end
    else
        if med1 < med2
            betterModel = model1;
        else
            betterModel = model2;
        end
    end
end

function betterProtocol = chooseBetterProtocol(metricName, medStatic, medDynamic)
%CHOOSEBETTERPROTOCOL Smaller is better for ST/CT; larger is better for RTA.

    if medStatic == medDynamic
        betterProtocol = 'Tie';
        return;
    end

    if strcmp(metricName, 'RTA')
        if medDynamic > medStatic
            betterProtocol = 'Dynamic';
        else
            betterProtocol = 'Static';
        end
    else
        if medDynamic < medStatic
            betterProtocol = 'Dynamic';
        else
            betterProtocol = 'Static';
        end
    end
end

function outputTable = completionRateLong(protocolTable, modelNames, protocolName)
%COMPLETIONRATELONG CR and Wilson 95% confidence intervals.

    numModels = numel(modelNames);

    Protocol = repmat(string(protocolName), numModels, 1);
    Model = string(modelNames(:));
    Successes = zeros(numModels, 1);
    Trials = zeros(numModels, 1);
    CR_Percent = zeros(numModels, 1);
    CI95_Lower_Percent = zeros(numModels, 1);
    CI95_Upper_Percent = zeros(numModels, 1);

    for m = 1:numModels
        values = protocolTable.Success(protocolTable.Model == string(modelNames{m}));

        Successes(m) = sum(values);
        Trials(m) = numel(values);
        CR_Percent(m) = 100 * Successes(m) / Trials(m);

        [lowerCI, upperCI] = wilsonConfidenceInterval(Successes(m), Trials(m));
        CI95_Lower_Percent(m) = 100 * lowerCI;
        CI95_Upper_Percent(m) = 100 * upperCI;
    end

    outputTable = table( ...
        Protocol, Model, Successes, Trials, CR_Percent, ...
        CI95_Lower_Percent, CI95_Upper_Percent);
end

function results = pearsonChiSquareCR(protocolTable, modelNames)
%PEARSONCHISQUARECR Pearson chi-square for classifier-by-success table.

    k = numel(modelNames);
    observed = zeros(k, 2);

    for m = 1:k
        values = protocolTable.Success(protocolTable.Model == string(modelNames{m}));
        successes = sum(values);
        failures = numel(values) - successes;
        observed(m, :) = [successes, failures];
    end

    rowTotals = sum(observed, 2);
    colTotals = sum(observed, 1);
    N = sum(observed, 'all');
    expected = rowTotals * colTotals / N;

    if any(expected(:) == 0)
        chiSquare = 0;
        pValue = 1;
    else
        chiSquare = sum(((observed - expected).^2) ./ expected, 'all');
        pValue = 1 - chi2cdf(chiSquare, k - 1);
    end

    cramersV = sqrt(chiSquare / (N * min(k - 1, 1)));

    results = struct( ...
        'N', N, ...
        'Observed', observed, ...
        'Expected', expected, ...
        'ChiSquare', chiSquare, ...
        'DF', k - 1, ...
        'PValue', pValue, ...
        'CramersV', cramersV, ...
        'EffectMagnitude', cramersMagnitude(cramersV));
end

function outputTable = pairwiseFisherHolm( ...
    protocolTable, modelNames, protocolName, alpha)
%PAIRWISEFISHERHOLM Independent pairwise CR comparisons.

    pairs = nchoosek(1:numel(modelNames), 2);
    numPairs = size(pairs, 1);

    Protocol = repmat(string(protocolName), numPairs, 1);
    Model1 = strings(numPairs, 1);
    Model2 = strings(numPairs, 1);
    Successes1 = zeros(numPairs, 1);
    Trials1 = zeros(numPairs, 1);
    CR1_Percent = zeros(numPairs, 1);
    Successes2 = zeros(numPairs, 1);
    Trials2 = zeros(numPairs, 1);
    CR2_Percent = zeros(numPairs, 1);
    RiskDifference_Percent = zeros(numPairs, 1);
    OddsRatio = zeros(numPairs, 1);
    P_Raw = nan(numPairs, 1);
    BetterModel = strings(numPairs, 1);

    for i = 1:numPairs
        m1 = pairs(i, 1);
        m2 = pairs(i, 2);

        model1 = modelNames{m1};
        model2 = modelNames{m2};

        values1 = protocolTable.Success(protocolTable.Model == string(model1));
        values2 = protocolTable.Success(protocolTable.Model == string(model2));

        s1 = sum(values1);
        n1 = numel(values1);
        s2 = sum(values2);
        n2 = numel(values2);

        contingency = [s1, n1 - s1; s2, n2 - s2];
        pValue = fisherExactTwoSided(contingency);

        risk1 = s1 / n1;
        risk2 = s2 / n2;

        Model1(i) = string(model1);
        Model2(i) = string(model2);
        Successes1(i) = s1;
        Trials1(i) = n1;
        CR1_Percent(i) = 100 * risk1;
        Successes2(i) = s2;
        Trials2(i) = n2;
        CR2_Percent(i) = 100 * risk2;
        RiskDifference_Percent(i) = 100 * (risk1 - risk2);
        OddsRatio(i) = correctedOddsRatio(contingency);
        P_Raw(i) = pValue;

        if risk1 > risk2
            BetterModel(i) = string(model1);
        elseif risk2 > risk1
            BetterModel(i) = string(model2);
        else
            BetterModel(i) = "Tie";
        end
    end

    P_Holm = holmAdjustment(P_Raw);
    Significant = P_Holm < alpha;

    outputTable = table( ...
        Protocol, Model1, Model2, ...
        Successes1, Trials1, CR1_Percent, ...
        Successes2, Trials2, CR2_Percent, ...
        RiskDifference_Percent, OddsRatio, ...
        P_Raw, P_Holm, Significant, BetterModel);
end

function pValue = fisherExactTwoSided(table2x2)
%FISHEREXACTTWOSIDED Two-sided Fisher exact test with fixed margins.
% The two-sided p-value sums probabilities less than or equal to the
% probability of the observed table, using the standard probability-based
% definition.

    if ~isequal(size(table2x2), [2, 2]) || any(table2x2(:) < 0)
        error('Input must be a 2-by-2 table of nonnegative counts.');
    end

    a = table2x2(1, 1);
    b = table2x2(1, 2);
    c = table2x2(2, 1);
    d = table2x2(2, 2);

    row1 = a + b;
    row2 = c + d;
    col1 = a + c;
    N = row1 + row2;

    minA = max(0, col1 - row2);
    maxA = min(row1, col1);
    possibleA = (minA:maxA)';

    logProbabilities = ...
        logCombination(row1, possibleA) + ...
        logCombination(row2, col1 - possibleA) - ...
        logCombination(N, col1);

    probabilities = exp(logProbabilities);

    observedLogP = ...
        logCombination(row1, a) + ...
        logCombination(row2, col1 - a) - ...
        logCombination(N, col1);
    observedP = exp(observedLogP);

    tolerance = max(1e-12, observedP * 1e-10);
    pValue = sum(probabilities(probabilities <= observedP + tolerance));
    pValue = min(1, pValue);
end

function value = logCombination(n, k)
%LOGCOMBINATION Logarithm of n choose k; supports vector k.

    value = -inf(size(k));
    valid = k >= 0 & k <= n & floor(k) == k;
    value(valid) = gammaln(n + 1) - gammaln(k(valid) + 1) ...
        - gammaln(n - k(valid) + 1);
end

function oddsRatio = correctedOddsRatio(table2x2)
%CORRECTEDODDSRATIO Haldane-Anscombe correction when any cell is zero.

    T = double(table2x2);
    if any(T(:) == 0)
        T = T + 0.5;
    end
    oddsRatio = (T(1, 1) * T(2, 2)) / (T(1, 2) * T(2, 1));
end

function [lowerCI, upperCI] = wilsonConfidenceInterval(successes, trials)
%WILSONCONFIDENCEINTERVAL Two-sided 95% Wilson interval.

    if trials <= 0
        lowerCI = NaN;
        upperCI = NaN;
        return;
    end

    z = 1.95996398454005;
    proportion = successes / trials;
    denominator = 1 + z^2 / trials;
    center = (proportion + z^2 / (2 * trials)) / denominator;
    halfWidth = z * sqrt( ...
        proportion * (1 - proportion) / trials + ...
        z^2 / (4 * trials^2)) / denominator;

    lowerCI = max(0, center - halfWidth);
    upperCI = min(1, center + halfWidth);
end

function adjustedP = holmAdjustment(rawP)
%HOLMADJUSTMENT Holm step-down multiplicity correction.

    adjustedP = nan(size(rawP));
    valid = isfinite(rawP);
    pValues = rawP(valid);

    if isempty(pValues)
        return;
    end

    [sortedP, sortIndex] = sort(pValues);
    m = numel(sortedP);

    adjustedSorted = nan(m, 1);
    for i = 1:m
        adjustedSorted(i) = (m - i + 1) * sortedP(i);
    end

    adjustedSorted = cummax(adjustedSorted);
    adjustedSorted(adjustedSorted > 1) = 1;

    restored = nan(m, 1);
    restored(sortIndex) = adjustedSorted;
    adjustedP(valid) = restored;
end

function lines = buildManuscriptSummary( ...
    continuousOmnibus, continuousPairs, ...
    crOmnibus, crPairs, protocolContinuous, protocolCR, alpha)
%BUILDMANUSCRIPTSUMMARY Produces ready-to-copy statistical statements.

    lines = {};
    lines{end + 1} = 'STATISTICAL METHODS';
    lines{end + 1} = ['Each classifier was evaluated in a separate online run; ' ...
        'therefore, observations from different classifiers were treated as independent.'];
    lines{end + 1} = ['ST, CT, and RTA were compared using Kruskal-Wallis tests, ' ...
        'followed by Holm-corrected Mann-Whitney U tests. Epsilon-squared ' ...
        'and Cliff''s delta were used as omnibus and pairwise effect sizes, respectively.'];
    lines{end + 1} = ['Completion success was compared using Pearson chi-square tests, ' ...
        'followed by Holm-corrected two-sided Fisher exact tests. CR values ' ...
        'were reported with 95% Wilson confidence intervals.'];
    lines{end + 1} = '';

    lines{end + 1} = 'WITHIN-PROTOCOL CLASSIFIER EFFECTS';

    for i = 1:height(continuousOmnibus)
        row = continuousOmnibus(i, :);
        lines{end + 1} = sprintf( ...
            '%s %s: H(%d) = %.2f, p = %s, epsilon^2 = %.3f (%s).', ...
            row.Protocol, row.Metric, row.DF, row.H, ...
            formatP(row.PValue), row.EpsilonSquared, row.EffectMagnitude);

        pairMask = continuousPairs.Protocol == row.Protocol & ...
            continuousPairs.Metric == row.Metric & ...
            continuousPairs.Significant;
        significantPairs = continuousPairs(pairMask, :);

        if isempty(significantPairs)
            lines{end + 1} = '  No pairwise comparison remained significant after Holm correction.';
        else
            pairText = strings(height(significantPairs), 1);
            for j = 1:height(significantPairs)
                pairText(j) = sprintf( ...
                    '%s vs %s (p_adj = %s, delta = %.3f, %s; better: %s)', ...
                    significantPairs.Model1(j), significantPairs.Model2(j), ...
                    formatP(significantPairs.P_Holm(j)), ...
                    significantPairs.CliffsDelta(j), ...
                    significantPairs.EffectMagnitude(j), ...
                    significantPairs.BetterModel(j));
            end
            lines{end + 1} = ['  Significant pairs: ' strjoin(cellstr(pairText), '; ') '.'];
        end
    end

    lines{end + 1} = '';
    lines{end + 1} = 'COMPLETION RATE';

    for i = 1:height(crOmnibus)
        row = crOmnibus(i, :);
        lines{end + 1} = sprintf( ...
            '%s CR: chi-square(%d) = %.2f, p = %s, Cramer''s V = %.3f (%s).', ...
            row.Protocol, row.DF, row.ChiSquare, ...
            formatP(row.PValue), row.CramersV, row.EffectMagnitude);

        pairMask = crPairs.Protocol == row.Protocol & crPairs.Significant;
        significantPairs = crPairs(pairMask, :);

        if isempty(significantPairs)
            lines{end + 1} = '  No pairwise CR comparison remained significant after Holm correction.';
        else
            pairText = strings(height(significantPairs), 1);
            for j = 1:height(significantPairs)
                pairText(j) = sprintf( ...
                    '%s vs %s (p_adj = %s, risk difference = %.1f percentage points; better: %s)', ...
                    significantPairs.Model1(j), significantPairs.Model2(j), ...
                    formatP(significantPairs.P_Holm(j)), ...
                    significantPairs.RiskDifference_Percent(j), ...
                    significantPairs.BetterModel(j));
            end
            lines{end + 1} = ['  Significant pairs: ' strjoin(cellstr(pairText), '; ') '.'];
        end
    end

    lines{end + 1} = '';
    lines{end + 1} = 'STATIC-VERSUS-DYNAMIC PROTOCOL EFFECTS';

    for i = 1:height(protocolContinuous)
        if protocolContinuous.Significant(i)
            lines{end + 1} = sprintf( ...
                '%s %s: Static vs Dynamic p_adj = %s, delta = %.3f (%s); better protocol: %s.', ...
                protocolContinuous.Model(i), protocolContinuous.Metric(i), ...
                formatP(protocolContinuous.P_Holm(i)), ...
                protocolContinuous.CliffsDelta_StaticVsDynamic(i), ...
                protocolContinuous.EffectMagnitude(i), ...
                protocolContinuous.BetterProtocol(i));
        end
    end

    for i = 1:height(protocolCR)
        if protocolCR.Significant(i)
            lines{end + 1} = sprintf( ...
                '%s CR: Static vs Dynamic p_adj = %s; Dynamic minus Static = %.1f percentage points; better protocol: %s.', ...
                protocolCR.Model(i), formatP(protocolCR.P_Holm(i)), ...
                protocolCR.DynamicMinusStatic_CR_Percent(i), ...
                protocolCR.BetterProtocol(i));
        end
    end

    if ~any(protocolContinuous.Significant) && ~any(protocolCR.Significant)
        lines{end + 1} = 'No Static-versus-Dynamic comparison remained significant after Holm correction.';
    end

    lines{end + 1} = '';
    lines{end + 1} = sprintf('Significance level: alpha = %.3f.', alpha);
end

function text = formatP(p)
%FORMATP Compact p-value formatting for manuscript text.

    if isnan(p)
        text = 'NaN';
    elseif p < 0.001
        text = '<0.001';
    elseif p < 0.01
        text = sprintf('%.4f', p);
    else
        text = sprintf('%.3f', p);
    end
end
