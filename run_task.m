function topNode = run_task(location)
%% function [mainTreeNode, datatub] = run_task(location)
%
% run_task = Single Change Point Dots
%
% This function configures, initializes, runs, and cleans up a SingleCP_DotsReversal
%  experiment 
%
% 11/28/18   aer wrote it

%% ---- Clear globals
%
% umm, duh
clear globals

%% ---- Configure experiment based on location
%
%   locations are 'pilot', 'office', 'tutorial'
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
    case {'office' 'Office'}
        arglist = { ...
            'taskSpecs',            {'Quest' 1 'Block2' 1 ...
                                    'Block3' 1 'Block4' 1}, ...%{'Quest' 50 'SN' 50 'AN' 50}, ...
            'trialFolder',          'Blocks002/', ...  % folder where trial generation data resides
            'readables',            {'dotsReadableHIDKeyboard'}, ...
            'recordDotsPositions',  false, ...
            'displayIndex',         0, ... % 0=small, 1=main, 2=other screen
            'remoteDrawing',        false, ...
            'sendTTLs',             false, ...
            'showFeedback',         0, ... % timeout for feedback
            'showSmileyFace',       0, ... % timeout for smiley face on correct target
            };
        
    case {'pilot' 'Pilot'}
        arglist = { ...
            'taskSpecs',            {'Quest' 25 'CP' 1 'CP' 1}, ...%{'Quest' 30 'CP' 22}, ...
            'probCPs',              [0 .5, .1], ... %this vector should be as long as there are task nodes.
            'readables',            {'dotsReadableHIDGamepad'}, ...
            'recordDotsPositions',  false, ...
            'displayIndex',         2, ... % 0=small, 1=main, 2=other screen
            'remoteDrawing',        false, ...
            'sendTTLs',             false, ...
            'showFeedback',         0, ... % timeout for feedback
            'showSmileyFace',       0, ... % timeout for smiley face on correct target
            };
        
    case {'tutorial' 'Tutorial'}
        arglist = { ...
            'taskSpecs',            {'CP' 10}, ...%{'Quest' 50 'SN' 50 'AN' 50}, ...
            'probCPs',              .5, ... %this vector should be as long as there are task nodes.
            'readables',            {'dotsReadableHIDKeyboard'}, ...
            'displayIndex',         2, ... % 0=small, 1=main, 2=other screen
            'remoteDrawing',        false, ...
            'sendTTLs',             false, ...
            'showFeedback',         0.5, ... % timeout for feedback
            'showSmileyFace',       0.5, ... % timeout for smiley face on correct target
            };
end

%% ---- Call the configuration routine
%
topNode = configure_task(arglist{:});

%% ---- Run it!
%
topNode.run();
