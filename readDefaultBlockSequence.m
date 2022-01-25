function bl =readDefaultBlockSequence(optn)
% reads default block sequence from file DefaultBlockSequence.txt
% if optn == 1
% returns a Nx1 cell array with one block name per entry (N names if
% N lines in the file).
% if optn == 2
% returns a 1x2N cell array of key-value pairs, where the keys are the
% block names and the pairs are the number of trials to pass in to the
% run_task script.
c=readtable('DefaultBlockSequence.csv', 'Format','%s%u');
numBlocks = size(c,1);
if optn == 1
    bl = table2cell(c(:,1));
elseif optn == 2
    bl={};
    for i=1:numBlocks
        cc=table2array(c(i,1));
        bl{2*i-1} = cc{1};
        bl{2*i} = table2array(c(i,2));
    end
end