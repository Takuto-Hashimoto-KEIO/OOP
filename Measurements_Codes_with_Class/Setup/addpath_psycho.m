%% addpath_psycho
p= fileparts(mfilename('fullpath'));

try
    sca;
catch
    if ismac
        name = fullfile(p,'psychopath.txt');
        flag_path = 1;
        pathlist = table2array(importfile_mac(name));
    else
        dir_header = 'C:\toolbox';
        name = fullfile(p,'psychopath2.txt');
        flag_path  = 2;
        pathlist   = table2array(importfile_win(name));
    end

    switch flag_path
        case 1
            for i_path = numel(pathlist) :-1: 1
                addpath(pathlist{i_path,1});
            end
        case 2
            for i_path = numel(pathlist) :-1: 1
                addpath(fullfile(dir_header,pathlist{i_path,1}));
            end
    end

    try
        PsychtoolboxPostInstallRoutine(1);
        sca;
    catch
        fprintf('PTB might not be installed\n');
    end
end
%%
function pathlist = importfile_mac(filename, startRow, endRow)
delimiter = '\t';
if nargin<=2
    startRow = 1;
    endRow = inf;
end
formatSpec = '%*s%s%[^\n\r]';
fileID = fopen(filename,'r');
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', startRow(1)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
for block=2:length(startRow)
    frewind(fileID);
    dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'TextType', 'string', 'HeaderLines', startRow(block)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
    dataArray{1} = [dataArray{1};dataArrayBlock{1}];
end
fclose(fileID);
raw = repmat({''},length(dataArray{1}),length(dataArray)-1);
for col=1:length(dataArray)-1
    raw(1:length(dataArray{col}),col) = mat2cell(dataArray{col}, ones(length(dataArray{col}), 1));
end
numericData = NaN(size(dataArray{1},1),size(dataArray,2));
rawNumericColumns = {};
rawStringColumns = string(raw(:, 1));
pathlist = table;
pathlist.ApplicationsPsychtoolbox = cellstr(rawStringColumns(:, 1));
end
%%
function psychopath1 = importfile_win(filename, dataLines)
if nargin < 2
    dataLines = [1, Inf];
end
opts = delimitedTextImportOptions("NumVariables", 1);
opts.DataLines = dataLines;
opts.Delimiter = "";

opts.VariableNames = "PsychtoolboxPsychHardwareEyelinkToolboxEyelinkOneLiners";
opts.VariableTypes = "string";
opts = setvaropts(opts, 1, "WhitespaceRule", "preserve");
opts = setvaropts(opts, 1, "EmptyFieldRule", "auto");
opts.ExtraColumnsRule = "ignore";
opts.EmptyLineRule = "read";

psychopath1 = readtable(filename, opts);
end