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
cpDots1Task.independentVariables='trials.csv';  % THIS CREATES A BUG (email sent at 2:07 on 6 Sep 2019)
cpDots1Task.pauseBeforeTask = pauseBeforeTask;
topNode.addChild(cpDots1Task);
cpDots2Task = topsTreeNodeTaskReversingDots('cpDots2');
cpDots2Task.taskID = 3;
cpDots2Task.independentVariables='trials2.csv';  % THIS CREATES A BUG (email sent at 2:07 on 6 Sep 2019)
cpDots2Task.pauseBeforeTask = pauseBeforeTask;
topNode.addChild(cpDots2Task);
cpDots3Task = topsTreeNodeTaskReversingDots('cpDots2');
cpDots3Task.taskID = 4;
cpDots3Task.independentVariables='trials3.csv';  % THIS CREATES A BUG (email sent at 2:07 on 6 Sep 2019)
cpDots3Task.pauseBeforeTask = pauseBeforeTask;
topNode.addChild(cpDots3Task);
% Run it
topNode.run();
topNode.children{1}.saveTrials('CSVs/completedTrials1.csv', 'all');
topNode.children{2}.saveTrials('CSVs/completedTrials2.csv', 'all');
topNode.children{3}.saveTrials('CSVs/completedTrials2.csv', 'all');
