function [X,Y,raw] = load_raw_acquisition(csvFile)
%LOAD_RAW_ACQUISITION Load the released 40-feature acquisition CSV.
    if nargin<1 || isempty(csvFile)
        scriptDir=fileparts(mfilename('fullpath'));
        repoRoot=fileparts(scriptDir);
        csvFile=fullfile(repoRoot,'data','raw','kmg_raw_acquisition.csv');
    end
    raw=readmatrix(csvFile);
    if size(raw,2)~=41
        error('Expected 41 columns (40 features + label); found %d.',size(raw,2));
    end
    X=double(raw(:,1:40));
    Y=categorical(raw(:,41));
end
