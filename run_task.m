function topNode = run_task(location)
%% function [mainTreeNode, datatub] = run_task(location)
%
% run_task = Single Change Point Dots
%
% This function configures, initializes, runs, and cleans up a SingleCP_DotsReversal
%  experiment (OR or office)
%
% 11/28/18   aer wrote it

%% ---- Clear globals
%
% umm, duh
clear globals

%% ---- Configure experiment based on location
%
%   locations are 'psychophys_booth' (default), 'buttons', 'pilot' or 'debug'
%
% UIs:
%  'dotsReadableEyeEyelink'
%  'dotsReadableEyePupilLabs'
%  'dotsReadableEyeEOG'
%  'dotsReadableHIDKeyboard'
%  'dotsReadableEyeMouseSimulator'
%  'dotsReadableHIDButtons'
%  'dotsReadableHIDGamepad'

if nargin < 1 || isempty(location)
    location = 'psychophys_booth';
end

% add something different

switch location
    
    case {'psychophys_booth'}
        arglist = { ...
            'taskSpecs',            {'Quest' 40 'CP' 10}, ...
            'readables',            {'dotsReadableEyePupilLabs'}, ...
            'sendTTLs',             true, ...
            };
        
        
    case {'buttons' 'Buttons'}  % Or using buttons
        arglist = { ...
            'taskSpecs',            {'Quest' 40 'CP' 10}, ...
            'sendTTLs',             true, ...
            'readables',            {'dotsReadableHIDButtons'}, ...
            };
        
        
    case {'debug' 'Debug'}
        arglist = { ...
            'taskSpecs',            {'CP' 1}, ...%{'Quest' 50 'SN' 50 'AN' 50}, ...
            'readables',            {'dotsReadableHIDKeyboard'}, ...
            'displayIndex',         0, ... % 0=small, 1=main
            'remoteDrawing',        false, ...
            'sendTTLs',             false, ...
            };
        
    case {'pilot' 'Pilot'}
        arglist = { ...
            'taskSpecs',            {'CP' 1}, ...%{'Quest' 50 'SN' 50 'AN' 50}, ...
            'readables',            {'dotsReadableHIDKeyboard'}, ...
            'displayIndex',         1, ... % 0=small, 1=main
            'remoteDrawing',        false, ...
            'sendTTLs',             false, ...
            'showFeedback',         0, ... % timeout for feedback
            'showSmileyFace',       0, ... % timeout for smiley face on correct target
            };
        
    otherwise % office
        arglist = { ...
            'taskSpecs',            {'Quest' 1 'CP' 1}, ...
            };
end

%% ---- Call the configuration routine
%
topNode = configure_task(arglist{:});

%% ---- Run it!
%
topNode.run();