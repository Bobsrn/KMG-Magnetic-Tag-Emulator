function csv_to_training_mat(inputCsv, outputMat)
%CSV_TO_TRAINING_MAT Convert a 40-feature/label CSV subset to X/Y MAT format.
%
% The input CSV must contain exactly 41 columns with no header:
% columns 1:40 are predictors and column 41 is the class label.
%
% This utility is intended for protocol-specific model-development subsets.

    if nargin < 2
        error('Usage: csv_to_training_mat(inputCsv, outputMat)');
    end

    A = readmatrix(inputCsv);
    if size(A,2) ~= 41
        error('Expected 41 columns; found %d.', size(A,2));
    end

    X = double(A(:,1:40));
    Y = categorical(A(:,41));

    if numel(categories(Y)) ~= 5
        error('Expected five classes; found %d.', numel(categories(Y)));
    end

    save(outputMat, 'X', 'Y');
    fprintf('Saved %d observations to %s\n', size(X,1), outputMat);
end
