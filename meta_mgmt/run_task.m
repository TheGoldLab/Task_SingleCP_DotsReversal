function topNode = run_task(location, blockSequence, subjcode, questThreshold)

clear globals

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
            'questThreshold',       questThreshold
        };
end

topNode = configure_task(arglist{:});

topNode.run();
