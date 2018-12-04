function dumpFIRAecodes2csv(inFilename, outFilename, taskName)
% writes the FIRA.ecodes matrix to csv file, with column names
% ARGS:
%   inFilename      input filename
%   outFilename     output filename
%   taskName        e.g. 'SingleCP_DotsReversal'
% RETURNS:
%   Nothing, but creates a file

[~, FIRA] = topsTreeNodeTopNode.getDataFromFile(inFilename, taskName);

T=array2table(FIRA.ecodes.data, 'VariableNames', FIRA.ecodes.name);
writetable(T,outFilename,'WriteRowNames',true) 
end