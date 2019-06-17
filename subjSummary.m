function subjSummary(subjcode, filename)
% displays metadata about a subject in this experiment

% block list
blockList = {'Tut1', 'Quest', 'Tut2', 'Block2', ...
    'Block3', 'Block4', 'Block5', 'Block6', 'Block7', ...
    'Block8', 'Block9', 'Block10', 'Block11'};

% read metadata file
if nargin == 1
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
        sessStruct = currDs.(session);
        datesArray{s} = sessStruct.sessionTag;
        for b = 1:length(blockList)
            completedBlocks{s,b} = double( ...
                strcmp(sessStruct.(blockList{b}).completed, 'true') ...
            );
        end
    end
    fprintf(char(10))  % new line
    fprintf('Session metadata for subject %s', subjcode);
    fprintf(char(10))  % new line
    cell2table(completedBlocks, ...
        'VariableNames', blockList, ...
        'RowNames', datesArray)
else
    % if subject is new
    %   say subject is new
    fprintf(char(10))
    fprintf('Subject %s is new for this experiment', subjcode);
    fprintf(char(10))
end

end