function bl =readDefaultBlockSequence()
% reads default block sequence from file DefaultBlockSequence.txt
% returns a Nx1 cell array with one block name per entry (N names if
% N lines in the file).
fID = fopen('DefaultBlockSequence.txt');
C = textscan(fID, '%s');
fclose(fID);
bl = C{1};
end