function questParams = getLatestQuestParams(sc)
% finds the latest quest data saved for subject sc
% sc is the hashed subject code
% TODO: use actual dates as opposed to session number to fetch the latest
% parameters, and check whether latest parameters were collected today or
% not.
filename = 'subj_metadata.json';
ds = loadjson(filename);
if isfield(ds, sc)
    currDs = ds.(sc);  % struct for this subject
    if isempty(currDs)
        questParams=[];
        return
    end
    sessionNames = fieldnames(currDs);  % cell array of field names
    numSessions = length(fieldnames(currDs));
    questParams = [];
    datesArray = cell(size(sessionNames));
    
    % display the blocks completed by the subject and their date
    for s = 1:numSessions
        session = sessionNames{s};
        %         disp(session)
        sessStruct = currDs.(session);
        datesArray{s} = sessStruct.sessionTag;
        
        if isfield(sessStruct, 'Quest')
            if sessStruct.Quest.completed
                % just override previous write to questParams to get the
                % latest
                questParams = sessStruct.Quest.QuestFit;
                if length(questParams) > 0
                    questParams = questParams(1);
                end
            end
        end
    end
else
    error('subject code not found in metadatafile')
end
end