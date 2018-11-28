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
%   locations are 'psychophys_booth' (default), 'buttons', or 'debug'
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
         'taskSpecs',            {'VGS' 5 'MGS' 5 'Quest' 40 'SN' 40 'AN' 40}, ...
         'readables',            {'dotsReadableEyeEOG'}, ... 
         'sendTTLs',             true, ...
         };
      
           
   case {'buttons' 'Buttons'}  % Or using buttons
      arglist = { ...
         'taskSpecs',            {'Quest' 40 'SN' 40 'AN' 40}, ...
         'sendTTLs',             true, ...
         'readables',            {'dotsReadableHIDButtons'}, ... 
         };
   
   
   case {'debug' 'Debug'}
      arglist = { ...
         'taskSpecs',            {'VGS' 1 'MGS' 1 'Quest' 4 'SN' 1 'AN' 1}, ...%{'Quest' 50 'SN' 50 'AN' 50}, ...
         'readables',            {'dotsReadableHIDKeyboard'}, ... 
         'displayIndex',         1, ... % 0=small, 1=main
         'remoteDrawing',        false, ...
         'sendTTLs',             true, ...
         };
      
   otherwise % office
      arglist = { ...
         'taskSpecs',            {'VGS' 1 'MGS' 1 'Quest' 8 'SN' 1 'AN' 1}, ...
...%         'taskSpecs',            {'VGS' 5 'MGS' 5 'Quest' 40 'SN' 25 'AN' 25}, ...
         };
end

%% ---- Call the configuration routine
%
topNode = configure_task(arglist{:});

%% ---- Run it!
%
topNode.run();