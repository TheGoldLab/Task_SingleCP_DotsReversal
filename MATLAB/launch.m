function launch()
% Test script for Adrian

%% ---- Create topsTreeNodeTopNode to control the experiment
%
% Make the topsTreeNodeTopNode
topNode = topsTreeNodeTopNode('oneCP');

% Add the screen ensemble as a "helper" object. See
% topsTaskHelperScreenEnsemble for details
topNode.addHelpers('screenEnsemble',  ...
   'displayIndex',      0, ...
   'remoteDrawing',     false, ...
   'topNode',           topNode);

% Add keyboard
topNode.addReadable('dotsReadableHIDKeyboard');

% Turn on block messages
pauseBeforeTask = -1; % -1 means wait for keypress -- see topsTreeNode.pauseBeforeTask

%% ---- Add the tasks
%
% 1. Quest
% questTask = topsTreeNodeTaskRTDots('Quest');
% questTask.taskID = 1;
% questTask.trialIterations = 1;
% questTask.timing.dotsDuration = 0.4;
% questTask.pauseBeforeTask = pauseBeforeTask;
% topNode.addChild(questTask);

% 2. CP dots, 600 ms dur
cpDots1Task = topsTreeNodeTaskReversingDots('cpDots1');
cpDots1Task.taskID = 2;
%cpDots1Task.loadTrials('trials.csv');

cpDots1Task.independentVariables='CSVs/trials.csv';  % THIS CREATES A BUG (email sent at 2:07 on 6 Sep 2019)
cpDots1Task.trialIterationMethod='sequential';

% cpDots1Task.trialIterations = 2;
% cpDots1Task.settings.useQuest = questTask;
%cpDots1Task.settings.valsFromQuest = [60 100]; % set to % cor values on pmf to get from Quest

% cpDots1Task.independentVariables.reversal.values = 0.2;
% cpDots1Task.independentVariables.duration.values = 0.4;

cpDots1Task.pauseBeforeTask = pauseBeforeTask;

topNode.addChild(cpDots1Task);

% Run it
topNode.run();
topNode.children{1}.saveTrials('CSVs/completedTrialsOrdered.csv', 'all');

