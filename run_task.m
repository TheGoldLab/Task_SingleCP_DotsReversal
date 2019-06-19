function topNode = run_task(location, blockSequence, subjcode)
%% function [mainTreeNode, datatub] = run_task(location)
%
% run_task = Single Change Point Dots
%
% This function configures, initializes, runs, and cleans up a SingleCP_DotsReversal
%  experiment 
%
% 11/28/18   aer wrote it

%% ---- Clear 
clear globals

%% ---- Configure experiment based on location
%
%   locations are 'pilot', 'office', 'short', 'tutorial'
%
% UIs:
%  'dotsReadableEyeEyelink'
%  'dotsReadableEyePupilLabs'
%  'dotsReadableEyeEOG'
%  'dotsReadableHIDKeyboard'
%  'dotsReadableEyeMouseSimulator'
%  'dotsReadableHIDButtons'
%  'dotsReadableHIDGamepad'

switch location      
    case {'pilot'}
        arglist = { ...
            'taskSpecs',            blockSequence, ...%{'Quest' 50 'SN' 50 'AN' 50}, ...
            'subjectCode',          subjcode, ...
            'trialFolder',          'Blocks003/', ...  % folder where trial generation data resides
            'readables',            {'dotsReadableHIDGamepad'}, ...
            'deactivateConsoleStatus', true, ...  % if true, trial by trial status not shown in console
            'recordDotsPositions',  true, ...
            'displayIndex',         2, ... % 0=small, 1=main, 2=other screen
            'remoteDrawing',        false, ...
            'sendTTLs',             false, ...
            'showFeedback',         0, ... % timeout for feedback
            'showSmileyFace',       0, ... % timeout for smiley face on correct target
        };
end

%% ---- Call the configuration routine
%
topNode = configure_task(arglist{:});

%% ---- Run it!
%
topNode.run();
