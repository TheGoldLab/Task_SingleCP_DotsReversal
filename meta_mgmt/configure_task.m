function topNode =  configure_task(varargin)
%% function topNode =  configure_task(varargin)
%
% This function sets up a Single Change Point Dots Reversal experiment. We
% keep this logic separate from
% running and cleaning up an experiment because we may want to decide
% when/how do do those other things on the fly (e.g., add/subtract tasks
% depending on the subject's motivation, etc).
%
% Arguments:
%  varargin  ... optional <property>, <value> pairs for settings variables
%                 note that <property> can be a cell array for nested
%                 property structures in the task object
%
% Returns:
%  mainTreeNode ... the topsTreeNode at the top of the hierarchy
%
% 11/28/18   aer wrote it, based on DBSconfigure.m in
% Lab-Matlab-Control/tasks/DBSStudy/DBSconfigure.m

%% ---- Parse arguments for configuration settings
%
% Name of the experiment, which determines where data are are stored
name = 'SingleCP_DotsReversal';

defaultBlockSequence = readDefaultBlockSequence(2);

% Other defaults
settings = { ...
    'taskSpecs',                  defaultBlockSequence, ...
    'subjectCode',                '', ...
    'runGUIname',                 'eyeGUI', ...
    'databaseGUIname',            [], ...
    'remoteDrawing',              false, ...
    'instructionDuration',        0, ...
    'displayIndex',               0, ... % 0=small, 1=main
    'readables',                  {'dotsReadableHIDKeyboard'}, ...
    'recordDotsPositions',        false, ...
    'doCalibration',              true, ...
    'doRecording',                true, ...
    'queryDuringCalibration',     false, ...
    'sendTTLs',                   false, ...
    'deactivateConsoleStatus',    false, ...
    'gazeWindowSize',             6, ...
    'gazeWindowDuration',         0.15, ...
    'saccadeDirections',          [0 180], ...
    'dotDirections',              [0 180], ...
    'referenceRT',                500, ... % for speed feedback
    'showFeedback',               .5, ... % timeout for feedback
    'showSmileyFace',             .2, ...
    'trialFolder',                '', ...
    'accruedReward',               0, ...
    'questThreshold',             0
    };

% Update from argument list (property/value pairs)
for ii = 1:2:nargin
    settings{find(strcmp(varargin{ii}, settings),1) + 1} = varargin{ii+1};
end

%% ---- Create topsTreeNodeTopNode to control the experiment
%
% Make the topsTreeNodeTopNode
topNode = topsTreeNodeTopNode(name);

% Add a topsGroupedList as the nodeData, which here just stores the
% property/value "settings" we use to control task behaviors
topNode.nodeData = topsGroupedList.createGroupFromList('Settings', settings);

% Add GUIS. The first is the "run gui" that has some buttons to start/stop
% running and some real-time output of eye position. The "database gui" is
% a series of dialogs that execute at the beginning to collect subject/task
% information and store it in a standard format.
topNode.addGUIs('run', topNode.nodeData{'Settings'}{'runGUIname'}, ...
    'database', topNode.nodeData{'Settings'}{'databaseGUIname'});

% Add the screen ensemble as a "helper" object. See
% topsTaskHelperScreenEnsemble for details
topNode.addHelpers('screenEnsemble',  ...
    topNode.nodeData{'Settings'}{'displayIndex'}, ...
    topNode.nodeData{'Settings'}{'remoteDrawing'}, ...
    topNode);

% Add a basic feedback helper object, which includes text, images,
% and sounds. See topsTaskHelperFeedback for details.
topNode.addHelpers('feedback');

% Add readable(s). See topsTaskHelperReadable for details.
readables = topNode.nodeData{'Settings'}{'readables'};
for ii = 1:length(readables)
   topNode.addReadable('readable', ...
      topNode.nodeData{'Settings'}{'doRecording'}, ...
      topNode.nodeData{'Settings'}{'doCalibration'}, ...
      false, ... % this boolean value cooresponds to the doShow argument in topsTreeNodeTopNode.addReadable()
      readables{ii});   
end

% Add writable (TTL out). See topsTaskHelperTTL for details.
if topNode.nodeData{'Settings'}{'sendTTLs'}
    topNode.addHelpers('TTL');
end

%% ---- Make call lists to show text/images between tasks
%
%  Use the sharedHelper screenEnsemble
%
% Welcome call list
paceStr = 'Work at your own pace.';
strs = { ...
    'dotsReadableEye',         paceStr, ''; ...
    'dotsReadableHIDGamepad',  paceStr, ''; ...
    'dotsReadableHIDButtons',  paceStr, ''; ...
    'dotsReadableHIDKeyboard', paceStr, ''; ...
    'default',                 '', ''};
for index = 1:size(strs,1)
    if ~isempty(topNode.getHelperByClassName(strs{index,1}))
        break;
    end
end
welcome = {@show, topNode.helpers.feedback, 'text', strs(index, 2:3), ...
    'showDuration', topNode.nodeData{'Settings'}{'instructionDuration'}};

% Countdown call list
callStrings = cell(10, 1);
for ii = 1:10
    callStrings{ii} = {'string', sprintf('Next task starts in: %d', 10-ii+1), 'y', -9};
end
countdown = {@showMultiple, topNode.helpers.feedback, ...
    'text', callStrings, 'image', {2, 'y', 4, 'height', 13}, ...
    'showDuration', 1.0, 'pauseDuration', 0.0, 'blank', false};

%% ---- Loop through the task specs array, making tasks with appropriate arg lists
%
taskSpecs = topNode.nodeData{'Settings'}{'taskSpecs'};
QuestTask = [];
noDots    = true;



% tasks with single report
singleReports = {'Quest','Tut1','Tut2','Block2'}; 

% loop through task nodes
taskCounter = 1;
for ii = 1:2:length(taskSpecs)
    % Make list of properties to send
    args = {taskSpecs{ii}, ...   
        'trialIterations',                  taskSpecs{ii+1}, ...
        {'timing',   'showInstructions'},   topNode.nodeData{'Settings'}{'instructionDuration'}, ...
        {'timing',   'showFeedback'},       topNode.nodeData{'Settings'}{'showFeedback'}, ...
        {'timing',   'showSmileyFace'},     topNode.nodeData{'Settings'}{'showSmileyFace'}, ...
        {'settings', 'recordDotsPositions'},topNode.nodeData{'Settings'}{'recordDotsPositions'}, ...
        {'settings', 'deactivateConsoleStatus'},topNode.nodeData{'Settings'}{'deactivateConsoleStatus'}, ...
        'taskID',                           taskCounter, ...
        'taskTypeID',  find(strcmp(taskSpecs{ii}, defaultBlockSequence),1)};
    

    % If there was a Quest task, use to update coherences in other tasks
    if ~isempty(QuestTask)
        args = cat(2, args, ...
            {{'settings' 'useQuest'},   QuestTask, ...
            {'settings' 'referenceRT'}, QuestTask});
    end
    
    % Make SingleCP_DotsReversal task with args
    task = topsTreeNodeTaskSingleCPDotsReversal.getStandardConfiguration(args{:});
    task.setIndependentVariableByName('initDirection', 'values', ...
        topNode.nodeData{'Settings'}{'dotDirections'});
    task.settings.subjectCode = topNode.nodeData{'Settings'}{'subjectCode'};
      
%     % Add special instructions for first dots task
%     if noDots
%         task.settings.textStrings = cat(1, ...
%             {'', ...
%             ''}, ...
%             task.settings.textStrings);
%         noDots = false;
%     end
    
    trial_folder = topNode.nodeData{'Settings'}{'trialFolder'};
    % Special case of quest ... use output as coh/RT refs
    if strcmp(taskSpecs{ii}, 'Quest')
        QuestTask = task;
        task.trialSettings.loadFromFile = false;
    elseif strcmp(taskSpecs{ii}, 'Tut1')
        task.trialSettings.loadFromFile = false;
        task.timing.showSmileyFace = .5;
    else
        task.questThreshold = topNode.nodeData{'Settings'}{'questThreshold'};
        task.trialSettings.loadFromFile = true;
        task.trialSettings.numTrials = taskSpecs{ii+1};
        task.trialSettings.csvFile = [trial_folder, taskSpecs{ii}, '.csv'];
        task.trialSettings.jsonFile = [trial_folder, taskSpecs{ii}, '_metadata.json'];
        if ~ismember(task.name, singleReports)
            task.isDualReport = true;
        end
        if strcmp(taskSpecs{ii},'Tut2') || strcmp(taskSpecs{ii}, 'Tut3')
            task.timing.showSmileyFace = .5;
        end
    end
        
%     % Add some fevalables to show instructions/feedback before/after tasks
%     if ii == 1
% %         task.addCall('start', welcome);
% %     else
% %         task.addCall('start', countdown);
%     end
    
    % Add as child to the maintask.
    topNode.addChild(task);
    
    % update task node counter
    taskCounter = taskCounter + 1;
end
