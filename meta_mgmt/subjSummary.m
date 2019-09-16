function tab = subjSummary(subjcode, filename)
% displays metadata about a subject in this experiment
% function accepts 0, 1 or 2 arguments.
% if the subject code is not known, just call the function with no argument
% or with '' as first argument.
% With a single or no argument, the function uses the default filename for 
% the json metadata 
%
% Example: the easiest and best way to use the function is with no argument
%    subjSummary()

blockList = readDefaultBlockSequence(1);

% get subject info to get code
if nargin == 0 || isempty(subjcode)
    subjcode = getSubjectCode();
end

% read metadata file
if nargin < 2
    filename = 'subj_metadata.json';
end

% disp(filename)
ds = loadjson(filename);

% if subject exists
if isfield(ds, subjcode)
    currDs = ds.(subjcode);  % struct for this subject
    sessionNames = fieldnames(currDs);  % cell array of field names
    numSessions = length(fieldnames(currDs));
    completedBlocks = cell(numSessions, length(blockList));
    datesArray = cell(size(sessionNames));
    
    % display the blocks completed by the subject and their date
    for s = 1:numSessions
        session = sessionNames{s};
%         disp(session)
        sessStruct = currDs.(session);
        datesArray{s} = sessStruct.sessionTag;
        for b = 1:length(blockList)
%             disp(blockList{b})
            if isfield(sessStruct, blockList{b})
                completedBlocks{s,b} = sessStruct.(blockList{b}).completed;
            else
                completedBlocks{s,b} = 0;
%                 disp('is NOT field')
            end
        end
    end
    fprintf(char(10))  % new line
    fprintf('Session metadata for subject %s', subjcode);
    fprintf(char(10))  % new line
    tab = cell2table(completedBlocks, ...
        'VariableNames', blockList, ...
        'RowNames', datesArray);
    disp(tab)
    
    % TODO: compute total earned reward
else
    % if subject is new
    %   say subject is new
    fprintf(char(10))
    fprintf('Subject %s is new for this experiment', subjcode);
    fprintf(char(10))
    tab=table();
end

end