% entry script to run the Task_SingleCP_DotsReversal experiment from Adrian
% Radillo. Last udpated on 06/19/2019

clear all

tbUseProject('Task_SingleCP_DotsReversal');

hashed_sc = getSubjectCode();

% diary feature doesn't work yet
% diaryname='lastDiary.txt';
% diary lastDiary.txt

% compute suggested block sequence for current session
[bSeq, kvPairs] = suggestBlockSequence(hashed_sc);

if size(bSeq,1) == 1
    bSeq=bSeq';  % transpose for aesthetic purposes
end
disp(bSeq)

isOK = input('Is the above sequence OK? (y/n) ', 's');

if ~strcmp(isOK, 'y')
    bSeq = input('provide your own sequence as a cell array please');
    if size(bSeq,1) == 1
        bSeq=bSeq';  % transpose for aesthetic purposes
    end
    if strcmp(bSeq{1}, 'Tut1')
        hasQuest = strcmp(bSeq{2}, 'Quest');
        startWithTut1 = true;
    else
        startWithTut1 = false;
        hasQuest = strcmp(bSeq{1}, 'Quest');
    end
    if ~hasQuest
        questParam = getLatestQuestParams(hashed_sc);
        if isempty(questParam)
            disp('Adding Quest block as no valid Quest metadata found')
            if startWithTut1
                bSeq = [{'Tut1';'Quest'};bSeq(2:end)];
            else
                bSeq = ['Quest';bSeq];
            end
        end
    else
        questParam = [];
    end
    disp(bSeq)
    isOK = input('Do you confirm the above sequence? (y/n) ', 's');
    if strcmp(isOK, 'y')
        topnode=run_task('pilot', buildkvpairs(kvPairs, bSeq), hashed_sc, questParam);
    else
        disp('aborting')
    end
else
    questParam = [];
    topnode=run_task('pilot', kvPairs, hashed_sc, questParam);
end

% from here onwards are failed attempt to use diary
% % wait until task has finished running
% waitfor(~topnode.isRunning)

% diary off

% move diary file to appropriate data folder
% consoleFilename=[topnode.filename(1:end-32),'consoleDump.log'];
% movefile(diaryname, consoleFilename)