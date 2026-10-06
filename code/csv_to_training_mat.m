function csv_to_training_mat(inputCsv,outputMat)
%CSV_TO_TRAINING_MAT Convert a 40-feature + label CSV subset to X/Y MAT format.
    A=readmatrix(inputCsv);
    if size(A,2)~=41, error('Expected 41 columns; found %d.',size(A,2)); end
    X=double(A(:,1:40)); Y=categorical(A(:,41));
    if numel(categories(Y))~=5, error('Expected five classes.'); end
    save(outputMat,'X','Y');
end
