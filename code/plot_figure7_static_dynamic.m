% plot_figure7_static_dynamic.m
% Reproduces the integrated Static/Dynamic boxplots used in Fig. 7.
% Requires MATLAB R2020a or newer for boxchart/exportgraphics.
% Data paths are resolved relative to this repository.

clearvars;
close all;
clc;

%% General configuration
fontSize = 24;
fontName = 'Times New Roman';

modelNames    = {'QDA', 'SVM', 'kNN', 'NN', 'DNN'};
protocolNames = {'Static', 'Dynamic'};

numModels   = numel(modelNames);
numGestures = 4;
numProtocols = numel(protocolNames);

%% Repository-relative paths
% This script is portable when kept inside the repository's code folder.
scriptDir = fileparts(mfilename('fullpath'));
repoRoot = fileparts(scriptDir);
rootStatic = fullfile(repoRoot, 'data', 'online', 'static');
rootDynamic = fullfile(repoRoot, 'data', 'online', 'dynamic');
rootFolders = {rootStatic, rootDynamic};

outputDir = fullfile(repoRoot, 'outputs', 'figures');
if ~isfolder(outputDir)
    mkdir(outputDir);
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

%% Load all models and protocols
% data{protocol, model}{gesture}
data = cell(numProtocols, numModels);

for p = 1:numProtocols
    for m = 1:numModels
        filePath = fullfile(rootFolders{p}, fileNames{p}{m});
        data{p, m} = loadGestureTrials(filePath);
    end
end

%% Pool trials across all four functional gestures
ST       = [];
CT       = [];
RTA      = [];
Model    = {};
Protocol = {};

for p = 1:numProtocols
    for m = 1:numModels
        for g = 1:numGestures

            gestureData = data{p, m}{g};

            currentST  = gestureData.timeST(:);
            currentCT  = gestureData.timeCT(:);
            currentRTA = 100 .* gestureData.ACC(:);

            nST  = numel(currentST);
            nCT  = numel(currentCT);
            nRTA = numel(currentRTA);

            if ~(nST == nCT && nCT == nRTA)
                error(['Metric lengths are inconsistent for protocol %s, ' ...
                    'model %s, gesture %d.'], ...
                    protocolNames{p}, modelNames{m}, g);
            end

            % Replace nonfinite values with NaN.
            % boxchart ignores NaN values.
            currentST(~isfinite(currentST))   = NaN;
            currentCT(~isfinite(currentCT))   = NaN;
            currentRTA(~isfinite(currentRTA)) = NaN;

            ST  = [ST; currentST];       %#ok<AGROW>
            CT  = [CT; currentCT];       %#ok<AGROW>
            RTA = [RTA; currentRTA];     %#ok<AGROW>

            Model = [
                Model
                repmat(modelNames(m), nST, 1)
                ]; %#ok<AGROW>

            Protocol = [
                Protocol
                repmat(protocolNames(p), nST, 1)
                ]; %#ok<AGROW>
        end
    end
end

%% Create analysis table
resultsTable = table(Model, Protocol, ST, CT, RTA);

% Fix category orders.
resultsTable.Model = categorical( ...
    resultsTable.Model, modelNames, 'Ordinal', true);

resultsTable.Protocol = categorical( ...
    resultsTable.Protocol, protocolNames, 'Ordinal', true);

%% Figure configuration
fig = figure( ...
    'Units', 'normalized', ...
    'OuterPosition', [0.04 0.04 0.92 0.92], ...
    'Color', 'w');

layout = tiledlayout(fig, 3, 1, ...
    'TileSpacing', 'compact', ...
    'Padding', 'compact');

protocolColors = [
    0.0000  0.4470  0.7410   % Static
    0.8500  0.3250  0.0980   % Dynamic
    ];

metricNames = {'ST', 'CT', 'RTA'};

yLabels = {
    {'Selection'; 'Time (s)'}
    {'Completion'; 'Time (s)'}
    {'Real-Time'; 'Accuracy (%)'}
    };

yLimits = {
    [0.00 0.30]
    [1.00 1.40]
    [80.0 100.0]
    };

%% Horizontal positions
% Increase modelSpacing for greater separation between classifiers.
modelSpacing = 2.0;

% Separation between Static and Dynamic boxes within each classifier.
protocolOffset = 0.27;

% Width of each individual box.
boxWidth = 0.42;

modelCenters = 1 + (0:numModels-1) .* modelSpacing;

staticPositions  = modelCenters - protocolOffset;
dynamicPositions = modelCenters + protocolOffset;

axesHandles = gobjects(3,1);
staticHandles = gobjects(3,1);
dynamicHandles = gobjects(3,1);

%% Generate integrated panels
for k = 1:3

    ax = nexttile(layout, k);
    axesHandles(k) = ax;
    hold(ax, 'on');

    metricData = resultsTable.(metricNames{k});

    %% Construct Static and Dynamic plotting vectors
    staticX = [];
    staticY = [];

    dynamicX = [];
    dynamicY = [];

    for m = 1:numModels

        isStatic = ...
            resultsTable.Model == modelNames{m} & ...
            resultsTable.Protocol == protocolNames{1};

        isDynamic = ...
            resultsTable.Model == modelNames{m} & ...
            resultsTable.Protocol == protocolNames{2};

        yStatic = metricData(isStatic);
        yDynamic = metricData(isDynamic);

        staticX = [
            staticX
            repmat(staticPositions(m), numel(yStatic), 1)
            ]; %#ok<AGROW>

        staticY = [
            staticY
            yStatic
            ]; %#ok<AGROW>

        dynamicX = [
            dynamicX
            repmat(dynamicPositions(m), numel(yDynamic), 1)
            ]; %#ok<AGROW>

        dynamicY = [
            dynamicY
            yDynamic
            ]; %#ok<AGROW>
    end

    %% Static boxplots
    staticHandles(k) = boxchart( ...
        ax, ...
        staticX, ...
        staticY, ...
        'BoxWidth', boxWidth, ...
        'BoxFaceColor', protocolColors(1,:), ...
        'BoxFaceAlpha', 0.55, ...
        'LineWidth', 1.1, ...
        'MarkerStyle', '+', ...
        'MarkerColor', protocolColors(1,:), ...
        'JitterOutliers', 'off');

    %% Dynamic boxplots
    dynamicHandles(k) = boxchart( ...
        ax, ...
        dynamicX, ...
        dynamicY, ...
        'BoxWidth', boxWidth, ...
        'BoxFaceColor', protocolColors(2,:), ...
        'BoxFaceAlpha', 0.55, ...
        'LineWidth', 1.1, ...
        'MarkerStyle', '+', ...
        'MarkerColor', protocolColors(2,:), ...
        'JitterOutliers', 'off');

    %% Axes formatting
    ylabel(ax, yLabels{k}, ...
        'FontName', fontName, ...
        'FontSize', fontSize);

    ylim(ax, yLimits{k});

    xlim(ax, [
        modelCenters(1) - 0.9
        modelCenters(end) + 0.9
        ]);

    xticks(ax, modelCenters);

    if k < 3
        xticklabels(ax, {});
    else
        xticklabels(ax, modelNames);
        xlabel(ax, 'Classifier', ...
            'FontName', fontName, ...
            'FontSize', fontSize);
    end

    ax.FontName = fontName;
    ax.FontSize = fontSize;
    ax.LineWidth = 1;
    ax.TickDir = 'out';
    ax.Box = 'off';
    ax.YGrid = 'on';
    ax.XGrid = 'off';
    ax.GridAlpha = 0.18;
    ax.Layer = 'top';

    %% Optional vertical separators between classifiers
    for m = 1:numModels-1
        separatorX = mean([modelCenters(m), modelCenters(m+1)]);

        xline(ax, separatorX, ':', ...
            'LineWidth', 0.8, ...
            'HandleVisibility', 'off');
    end

    %% Panel labels
    text(ax, 0.012, 0.90, ...
        sprintf('(%c)', char('a' + k - 1)), ...
        'Units', 'normalized', ...
        'FontName', fontName, ...
        'FontSize', fontSize, ...
        'FontWeight', 'bold', ...
        'VerticalAlignment', 'top');

    hold(ax, 'off');
end

%% Shared legend
legendHandle = legend( ...
    axesHandles(1), ...
    [staticHandles(1), dynamicHandles(1)], ...
    protocolNames, ...
    'Orientation', 'horizontal', ...
    'Location', 'northoutside');

legendHandle.FontName = fontName;
legendHandle.FontSize = fontSize;
legendHandle.Box = 'off';

%% Export
exportgraphics( ...
    fig, ...
    fullfile(outputDir, 'Fig7_Static_Dynamic_Integrated.pdf'), ...
    'ContentType', 'vector', ...
    'BackgroundColor', 'white');

exportgraphics( ...
    fig, ...
    fullfile(outputDir, 'Fig7_Static_Dynamic_Integrated.png'), ...
    'Resolution', 600, ...
    'BackgroundColor', 'white');

set(fig, 'Renderer', 'painters');

print(fig, ...
    fullfile(outputDir, 'Fig7_Static_Dynamic_Integrated.eps'), ...
    '-depsc', ...
    '-painters');

%% Local function
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

    requiredVariables = {
        'RTtest1'
        'RTtest2'
        'RTtest3'
        'RTtest4'
        };

    for i = 1:numel(requiredVariables)
        variableName = requiredVariables{i};

        if ~isfield(loadedData, variableName)
            error( ...
                'Variable %s is missing from:\n%s', ...
                variableName, filePath);
        end
    end

    gestureTrials = {
        loadedData.RTtest1
        loadedData.RTtest2
        loadedData.RTtest3
        loadedData.RTtest4
        };
end