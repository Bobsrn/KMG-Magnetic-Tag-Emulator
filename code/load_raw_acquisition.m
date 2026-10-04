function [X, Y, raw] = load_raw_acquisition(csvFile)
%LOAD_RAW_ACQUISITION Load the released 40-feature raw KMG acquisition CSV.
%
%   [X,Y,raw] = load_raw_acquisition()
%   [X,Y,raw] = load_raw_acquisition(csvFile)
%
% The CSV is headerless. Columns 1:40 are scalar magnetic-field features
% and column 41 is the class label (1-5).

    if nargin < 1 || isempty(csvFile)
        scriptDir = fileparts(mfilename('fullpath'));
        repoRoot = fileparts(scriptDir);
        csvFile = fullfile(repoRoot, 'data', 'raw', 'mmdreza.csv');
    end

    if ~isfile(csvFile)
        error('Raw acquisition file not found: %s', csvFile);
    end

    raw = readmatrix(csvFile);
    if size(raw,2) ~= 41
        error('Expected 41 columns (40 features + label); found %d.', size(raw,2));
    end

    X = double(raw(:,1:40));
    Y = categorical(raw(:,41));

    if numel(categories(Y)) ~= 5
        error('Expected five class labels; found %d.', numel(categories(Y)));
    end
end
