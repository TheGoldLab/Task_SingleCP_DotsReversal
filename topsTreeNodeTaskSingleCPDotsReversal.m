classdef topsTreeNodeTaskSingleCPDotsReversal < topsTreeNodeTask
    % @class topsTreeNodeTaskRTDots
    %
    % Response-time dots (RTD) task
    %
    % For standard configurations, call:
    %  topsTreeNodeTaskRTDots.getStandardConfiguration
    %
    % Otherwise:
    %  1. Create an instance directly:
    %        task = topsTreeNodeTaskRTDots();
    %
    %  2. Set properties. These are required:
    %        task.screenEnsemble
    %        task.helpers.readers.theObject
    %     Others can use defaults
    %
    %  3. Add this as a child to another topsTreeNode
    %
    % 11/28/18 created by aer / reviewed by jig
    
    properties % (SetObservable) % uncomment if adding listeners
        
        % Trial properties.
        %
        % Set useQuest to a handle to a topsTreeNodeTaskSingleCPDotsReversal to use it
        %     to get coherences
        % Possible values of dotsDuration:
        %     [] (default)        ... RT task
        %     [val]               ... use given fixed value
        %     [min mean max]      ... specify as pick from exponential distribution
        %     'indep'             ... specified in self.independentVariables
        settings = struct( ...
            'minTrialsPerCondition',      10,   ...
            'useQuest',                   [],   ...
            'coherencesFromQuest',        [],   ...
            'possibleDirections',         [0 180],   ...
            'directionPriors',            [],   ... % change For asymmetric priors
            'referenceRT',                [],   ...
            'fixationRTDim',              0.4,  ...
            'targetDistance',             10,   ... % meaning 10 degs to the left and right of fp, as in Palmer/Huk/Shadlen/2005
            'textStrings',                '',   ...
            'correctImageIndex',          1,    ...
            'errorImageIndex',            3,    ...
            'correctPlayableIndex',       1,    ...
            'errorPlayableIndex',         2,    ...
            'recordDotsPositions',        false);   % flag controlling whether to store dots positions or not
        
        % Timing properties
        timing = struct( ...
            'showInstructions',          10.0, ...
            'waitAfterInstructions',     0.5, ...
            'fixationTimeout',           5.0, ...
            'holdFixation',              0.2, ...
            'showSmileyFace',            0.5, ...
            'showFeedback',              1.0, ...
            'interTrialInterval',        1.0, ...          % as in Palmer/Huk/Shadlen 2005
            'preDots',                   [0.2 0.7 4.8],... % truncated exponential time between fixation and dots onset as in Palmer/Huk/Shadlen 2005. Actual code is this one: https://github.com/TheGoldLab/Lab-Matlab-Control/blob/c4bebf2fc40111ca4c58f801bc6f9210d2a824e6/tower-of-psych/foundation/runnable/topsStateMachine.m#L534
            'dotsDuration1',             [],  ...
            'dotsDuration2',             [],  ...
            'dotsTimeout',               5.0, ...
            'choiceTimeout',             3.0);
        
        % Quest properties
        questSettings = struct( ...
            'stimRange',                 0:100,           ... % coherence levels 
            'thresholdRange',            0.5:.5:100,       ... % cannot start at 0 with Weibull
            'slopeRange',                2,             ... % we don't estimate the slope
            'guessRate',                 0.5,             ... % because it is a 2AFC task
            'lapseRange',                0.001,           ... % this lapse will affect percent correct at threshold, so we estimate it
            'recentGuess',               [],              ...
            'viewingDuration',           .4);             % stimulus duration for Quest (sec)
        
        % Fields below are optional but if found with the given names
        %  will be used to automatically configure the task
        
        % Array of structures of independent variables, used by makeTrials
%         independentVariables = struct( ...
%             'name',        {...
%                 'initDirection',   ...
%                 'coherence',       ...
%                 'viewingDuration', ...
%                 'probCP',          ...
%                 'timeCP'},         ...
%             'values',      {...
%                 [0 180],           ... % allowed initial directions
%                 [10 30 70],        ... % coherence values
%                 .1:.1:.4,          ... % viewingDuration (sec)
%                 .5,                ... % probability of CP
%                 .2},               ... % time of CP
%             'priors',      {[], [], [20 20 30 30], [], []});
        
        % dataFieldNames are used to set up the trialData structure
        trialDataFields = {...
            'RT', ...
            'choice', ...
            'correct', ...
            'initDirection', ...
            'endDirection', ...
            'presenceCP', ...
            'coherence', ...
            'viewingDuration', ...
            'probCP', ...
            'timeCP', ...
            'randSeedBase', ...
            'fixationOn', ...
            'fixationStart', ...
            'targetOn', ...
            'dotsOn', ...
            'dotsOff', ...
            'choiceTime', ...
            'targetOff', ...
            'fixationOff', ...
            'feedbackOn'};
        
        
        % empty struct that will later be filled, only if 
        % self.settings.recordDotsPositions is true. 
        %%%%%%%%%%%%%%%%%%%%%%%%
        % Description of fields:
        %  dotsPositions is a 1-by-JJ cell, where JJ is the number of 
        %                trials run in the experiment. Each entry of the 
        %                cell will contain matrix equal to 
        %                dotsDrawableDotKinetogram.dotsPositions
        %  dumpTime      is a cell array of times, each computed as
        %                feval(self.clockFunction).
        %                The times are computed by the dumpDots() method, 
        %                once at the end of every trial. They should be
        %                compared to the 'trialStart' time stamp in order
        %                to assign a sequence of dots frames to a
        %                particular trial.
        dotsInfo = struct('dotsPositions', [], 'dumpTime', []);  
                
        % Drawables settings
        drawable = struct( ...
            ...
            ...   % Stimulus ensemble and settings
            'stimulusEnsemble',              struct( ...
            ...
            ...   % Fixation drawable settings
            'fixation',                   struct( ...
            'fevalable',                  @dotsDrawableTargets, ...
            'settings',                   struct( ...
            'xCenter',                    0,                ...
            'yCenter',                    0,                ...
            'nSides',                     100,                ...
            'width',                      .4,   ...% 0.4 deg vis. angle as in Palmer/Huk/Shadlen 2005
            'height',                     .4,   ...
            'colors',                     [1 0 0])),        ...% red as in Palmer/Huk/Shadlen 2005, and blue at dotsOn
            ...
            ...   % Targets drawable settings
            'targets',                    struct( ...
            'fevalable',                  @dotsDrawableTargets, ...
            'settings',                   struct( ...
            'nSides',                     100,              ...
            'width',                      .8*ones(1,2),       ... % 0.8 deg vis. angle as in Palmer/Huk/Shadlen 2005
            'height',                     .8*ones(1,2), ...
            'colors',                     [1 0 0])),        ...% red as in Palmer/Huk/Shadlen 2005)   ...
            ...
            ...   % Smiley face for feedback
            'smiley',                     struct(  ...
            'fevalable',                  @dotsDrawableImages, ...
            'settings',                   struct( ...
            'fileNames',                  {{'smiley.jpg'}}, ...
            'height',                     2)), ...
            ...
            ...   % Dots drawable settings
            'dots',                       struct( ...
            'fevalable',                  @dotsDrawableDotKinetogram, ...
            'settings',                   struct( ...
            'xCenter',                    0,                ...
            'yCenter',                    0,                ...
            'coherenceSTD',               10,               ...
            'stencilNumber',              1,                ...
            'pixelSize',                  6,                ... % Palmer/Huk/Shadlen 2005 use 3, but they have 25.5 px per degree!
            'diameter',                   5,                ... % as in Palmer/Huk/Shadlen 2005
            'density',                    90,               ... % 16.7 in Palmer/Huk/Shadlen 2005
            'speed',                      5,                ... % as in Palmer/Huk/Shadlen 2005 (and 3 interleaved frames)
            'recordDotsPositions',        false)))); % will be set to self.settings.recordDotsPositions in self.prepareDrawables               
        
        % Readable settings
        readable = struct( ...
            ...
            ...   % The readable object
            'reader',                     struct( ...
            ...
            'copySpecs',                  struct( ...
            ...
            ...   % The gaze windows
            'dotsReadableEye',            struct( ...
            'bindingNames',               'stimulusEnsemble', ...
            'prepare',                    {{@updateGazeWindows}}, ...
            'start',                      {{@defineEventsFromStruct, struct( ...
            'name',                       {'holdFixation', 'breakFixation', 'choseLeft', 'choseRight'}, ...
            'ensemble',                   {'stimulusEnsemble', 'stimulusEnsemble', 'stimulusEnsemble', 'stimulusEnsemble'}, ... % ensemble object to bind to
            'ensembleIndices',            {[1 1], [1 1], [2 1], [2 2]})}}), ...
            ...
            ...   % The keyboard events .. 'uiType' is used to conditinally use these depending on the theObject type
            'dotsReadableHIDKeyboard',    struct( ...
            'start',                      {{@defineEventsFromStruct, struct( ...
            'name',                       {'holdFixation', 'choseLeft', 'choseRight'}, ...
            'component',                  {'KeyboardSpacebar', 'KeyboardLeftArrow', 'KeyboardRightArrow'}, ...
            'isRelease',                  {true, false, false})}}), ...
            ...
            ...   % Gamepad
            'dotsReadableHIDGamepad',     struct( ...
            'start',                      {{@defineEventsFromStruct, struct( ...
            'name',                       {'holdFixation', 'choseLeft', 'choseRight'}, ...
            'component',                  {'Button1', 'Trigger1', 'Trigger2'}, ...
            'isRelease',                  {true, false, false})}}), ...
            ...
            ...   % Ashwin's magic buttons
            'dotsReadableHIDButtons',     struct( ...
            'start',                      {{@defineEventsFromStruct, struct( ...
            'name',                       {'holdFixation', 'choseLeft', 'choseRight'}, ...
            'component',                  {'KeyboardSpacebar', 'KeyboardLeftShift', 'KeyboardRightShift'}, ...
            'isRelease',                  {true, false, false})}}), ...
            ...
            ...   % Dummy to run in demo mode
            'dotsReadableDummy',          struct( ...
            'start',                      {{@defineEventsFromStruct, struct( ...
            'name',                       {'holdFixation'}, ...
            'component',                  {'auto_1'})}}))));
    end
    
    properties (SetAccess = protected)
        
        % The quest object
        quest;
        
        % Boolean flag, whether the specific trial has a change point or not
        isCP;
        
        % Check for changes in properties that require drawables to be
        %  recomputed
        targetDistance;
    end
    
    methods
        
        %% Constructor
        %  Use topsTreeNodeTask method, which can parse the argument list
        %  that can set properties (even those nested in structs)
        function self = topsTreeNodeTaskSingleCPDotsReversal(varargin)
            
            % ---- Make it from the superclass
            %
            self = self@topsTreeNodeTask(varargin{:});
        end
        
        %% Make trials (overloaded)
        % this method exists in the super class, but for now, I reimplement
        % it as I find it to be buggy in the superclass.
        %
        %  Utility to make trialData array using array of structs (independentVariables),
        %     which must be a property of the given task with fields:
        %
        %     1. name: string name
        %     2. values: vector of unique values
        %     3. priors: vector of priors (or empty for equal priors)
        %
        %  trialIterations is number of repeats of each combination of
        %     independent variables
        %
        function makeTrials(self, independentVariables, trialIterations)
            %%%%%%%%%%%%%%%%%% 
            %PUT MY CUSTOM CODE HERE!
            %
            %%%%%%%%%%%%%%%%%%
        end
        
        %% Self paced break screen
        function self_paced_break(self)
            
            % ---- Check for event
            %
            eventName = self.helpers.reader.readEvent({'holdFixation'}, self, 'end_of_break');
            
            % Nothing... keep checking
            while isempty(eventName)
                self.helpers.feedback.show('text', ...
                    'Well done! Take a break if you wish. You may start the next chunk by pressing space bar.', ...
                    'showDuration', 0.1, ...
                     'blank', false);
                eventName = self.helpers.reader.readEvent({'holdFixation'}, self, 'end_of_break');
            end
        end
        
        %% Start task (overloaded)
        %
        % Put stuff here that you want to do before each time you run this
        % task
        function startTask(self)
            self.trialIterationMethod = 'sequential';  % enforce sequential
            self.randomizeWhenRepeating = false;
            
            % ---- Set up independent variables if Quest task
            %
            if strcmp(self.name, 'Quest') % when we are running the task as Quest node
                % Initialize and save Quest object
                self.quest = qpInitialize(qpParams( ...
                    'stimParamsDomainList', { ...
                    self.questSettings.stimRange}, ...
                    'psiParamsDomainList',  { ...
                    self.questSettings.thresholdRange, ...
                    self.questSettings.slopeRange, ...
                    self.questSettings.guessRate, ...
                    self.questSettings.lapseRange}, ...
                    'qpOutcomeF',@(x) qpSimulatedObserver(x,@qpPFStandardWeibull,simulatedPsiParams), ...
                    'qpPF', @qpPFStandardWeibull));
                
                % Update independent variable struct using initial value
                self.setIndependentVariableByName('coherence', 'values', ...
                    self.getQuestGuess());
                self.setIndependentVariableByName('probCP', 'values', 0);
                self.setIndependentVariableByName('viewingDuration', ...
                    'values', self.questSettings.viewingDuration);      
            elseif ~isempty(self.settings.useQuest) % when we are running the task AFTER a Quest node
                % get Quest threshold
                questThreshold = self.settings.useQuest.getQuestThreshold( ...
                    self.settings.coherencesFromQuest);
                
                % get coherence value corresponding to 98 pCorrect
                questHighCoh = self.settings.useQuest.getQuestCoh(.98);
                if questHighCoh > 100
                    questHighCoh = 100;
                end
                
                % Update independent variable struct using Quest's fit
                self.setIndependentVariableByName('coherence', 'values', ...
                    [0, questThreshold, questHighCoh]);
                self.setIndependentVariableByName('coherence', 'priors', ...
                    [30 40 30]);
            end
            
            % ---- Self-paced break screen
            % we offer the subject the possibility to take a break
            % the subject triggers the start of the task with a key press
            
            %waitfor(self.self_paced_break())
            
            % ---- Initialize the state machine
            %
            self.initializeStateMachine();
            

            
            % ---- Show task-specific instructions
            %
            self.helpers.feedback.show('text', self.settings.textStrings, ...
                'showDuration', self.timing.showInstructions);
            pause(self.timing.waitAfterInstructions);
            
            % pre-allocate cell size to record dots positions and states
            if self.settings.recordDotsPositions
                self.dotsInfo.dotsPositions = cell(1,length(self.trialIndices));
                self.dotsInfo.dumpTime = self.dotsInfo.dotsPositions;
            end
        end
        
        %% Finish task (overloaded)
        %
        % Put stuff here that you want to do after each time you run this
        % task
        function finishTask(self)
        end
        
        %% Start trial
        %
        % Put stuff here that you want to do before each time you run a trial
        function startTrial(self)
            % ---- check whether a CP will occur in this trial or not
            %
            
            % Get current task/trial
            trial = self.getTrial();
            %ensemble = self.helpers.stimulusEnsemble.theObject;
            %initialDirection = ensemble.getObjectProperty('direction',4);
            
            % if CP time is longer than viewing duration, no CP
            if trial.timeCP >= trial.viewingDuration
                self.isCP = false;
                trial.presenceCP = 0;
                trial.endDirection = trial.initDirection;
                self.timing.dotsDuration1 = trial.viewingDuration;
                self.timing.dotsDuration2 = 0;
            else
                if rand < trial.probCP
                    self.isCP = true;
                    trial.presenceCP = 1.0; % numeric because of FIRA
                    trial.endDirection = self.flipDirection(trial.initDirection);
                    self.timing.dotsDuration1 = trial.timeCP;
                    self.timing.dotsDuration2 = trial.viewingDuration - trial.timeCP;
                else
                    self.isCP = false;
                    trial.presenceCP = 0;
                    trial.endDirection = trial.initDirection;
                    self.timing.dotsDuration1 = trial.viewingDuration;
                    self.timing.dotsDuration2 = 0;
                end
            end
            
            self.setTrial(trial);
            
            % ---- Prepare components
            %
            self.prepareDrawables();
            self.prepareStateMachine();
            
            % jig sets the timing in the statelist
            self.stateMachine.editStateByName('showDotsEpoch1', 'timeout', self.timing.dotsDuration1);
            self.stateMachine.editStateByName('switchDots', 'timeout', self.timing.dotsDuration2);
            
            % ---- Inactivate all of the readable events
            %
            self.helpers.reader.theObject.deactivateEvents();
            
            % ---- Show information about the task/trial
            %
            % Task information
            taskString = sprintf('%s (task %d/%d): %d correct, %d error, mean RT=%.2f, epoch1=%.2f, epoch2=%.2f', ...
                self.name, self.taskID, length(self.caller.children), ...
                sum([self.trialData.correct]==1), sum([self.trialData.correct]==0), ...
                nanmean([self.trialData.RT]), ...
                self.timing.dotsDuration1, self.timing.dotsDuration2);
            
            % Trial information
            trial = self.getTrial();
            trialString = sprintf('Trial %d/%d, dir=%d, coh=%.0f', self.trialCount, ...
                numel(self.trialData), trial.initDirection, trial.coherence);
            
            % Show the information
            self.statusStrings = {taskString, trialString};
            self.updateStatus(); % just update the second one
            
        end
        
        %% Flip direction of dots
        %
        % very simple function that
        function direction2 = flipDirection(self, direction1)
            pd = self.settings.possibleDirections;
            direction2 = pd(~(pd == direction1));
        end
        
        %% Finish Trial
        %
        % Could add stuff here
        function finishTrial(self)
            % add numFrames field to trial struct
            trial = self.getTrial();
            self.setTrial(trial);
            
            % Conditionally update Quest
            if strcmp(self.name, 'Quest')
                
                % ---- Check for bad trial
                %
                trial = self.getTrial();
                if isempty(trial) || ~(trial.correct >= 0)
                    return
                end
                
                % ---- Update Quest
                %
                % (expects 1=error, 2=correct)
                self.quest = qpUpdate(self.quest, self.questSettings.recentGuess, ...
                    trial.correct+1);
                
                % Update next guess, if there is a next trial
                if self.trialCount < length(self.trialIndices)
                    self.trialData(self.trialIndices(self.trialCount+1)).coherence = ...
                        self.getQuestGuess();
                end
                
                % ---- Set reference coherence to current threshold
                %        and set reference RT
                %
                self.settings.coherences = self.getQuestThreshold( ...
                    self.settings.coherencesFromQuest);
                self.settings.referenceRT = nanmedian([self.trialData.RT]);
            end
        end
        
        %% Check for choice
        %
        % Save choice/RT information and set up feedback for the dots task
        function nextState = checkForChoice(self, events, eventTag)
            
            % ---- Check for event
            %
            eventName = self.helpers.reader.readEvent(events, self, eventTag);
            
            % Nothing... keep checking
            if isempty(eventName)
                nextState = [];
                return
            end
            
            % ---- Good choice!
            %
            % Override completedTrial flag
            self.completedTrial = true;
            
            % Jump to next state when done
            nextState = 'blank';
            
            % Get current task/trial
            trial = self.getTrial();
            
            % Save the choice
            trial.choice = double(strcmp(eventName, 'choseRight'));
            
            % Mark as correct/error
            % jig changed direction to endDirection
            trial.correct = double( ...
                (trial.choice==0 && trial.endDirection==180) || ...
                (trial.choice==1 && trial.endDirection==0));
            
            % Compute/save RT, wrt dotsOff for non-RT
            trial.RT = trial.choiceTime - trial.dotsOff;
            
            
            % ---- Re-save the trial
            %
            self.setTrial(trial);
            
            % ---- Possibly show smiley face
            if trial.correct == 1 && self.timing.showSmileyFace > 0
                self.helpers.stimulusEnsemble.draw({3, [1 2 4]});
                pause(self.timing.showSmileyFace);
            end
        end
        
        %% Switch dots direction at change point
        %
        % this function gets called, via its handle, in an fevalable of the
        % state machine. It is the 'entry' function of a state. It does the
        % following: switch direction of dots
        function switchDots(self)
            trial=self.getTrial();
            self.helpers.stimulusEnsemble.theObject.setObjectProperty(...
                'direction', trial.endDirection, 4)
        end
        
        %% dump dots positions and states 
        % by state I mean whether each dot is active or not on a particular
        % frame, and whether it is coherent or not, on a particular frame
        function dumpDots(self)
            if self.settings.recordDotsPositions
                self.dotsInfo.dotsPositions{self.trialCount} = ...
                    self.helpers.stimulusEnsemble.theObject.getObjectProperty(...
                    'dotsPositions', 4);
                self.dotsInfo.dumpTime{self.trialCount} = feval(self.clockFunction);
            end
        end
        
        %% dump dotsOn with toc function
        % function will be used as exit function of state "preDots" in
        % statelist
        function tocDotsOn(self)
            trial = self.getTrial();
            trial.tocDotsOn = toc;
            self.setTrial(trial);
        end
        
        %% dump dotsOff with toc function
        % function will be used as exit function of state "showDotsEpoch1"
        % in statelist
        function tocDotsOffEpoch1(self) 
            if ~self.isCP % only execute if no CP in this trial
                trial = self.getTrial();
                trial.tocDotsOff = toc;
                self.setTrial(trial);
            end
        end
        
        %% dump dotsOff with toc function
        % function will be used as exit function of state "switchDots"
        % in statelist
        function tocDotsOffEpoch2(self)
            trial = self.getTrial();
            trial.tocDotsOff = toc;
            self.setTrial(trial);
        end
        
        %% Show feedback
        %
        function showFeedback(self)
            
            % Get current task/trial
            trial = self.getTrial();
            
            % Set up feedback based on outcome
            if trial.correct == 1
                feedbackStr = 'Correct';
                feedbackArgs = { ...
                    'image', self.settings.correctImageIndex, ...
                    'sound', self.settings.correctPlayableIndex};
            elseif trial.correct == 0
                feedbackStr = 'Error';
                feedbackArgs = { ...
                    'image', self.settings.errorImageIndex, ...
                    'sound', self.settings.errorPlayableIndex};
            else
                feedbackArgs = {'text', 'No choice'};
                feedbackStr = 'No choice';
            end
            
            % --- Show trial feedback in GUI/text window
            %
            % jig changed direction to endDirection
            self.statusStrings{2} = ...
                sprintf('Trial %d/%d, dir=%d, coh=%.0f: %s, RT=%.2f', ...
                self.trialCount, numel(self.trialData), ...
                trial.endDirection, trial.coherence, feedbackStr, trial.RT);
            self.updateStatus(2); % just update the second one
            
            % --- Show trial feedback on the screen
            %
            % self.helpers.feedback.show(feedbackArgs{:});
        end
        
        %% Get Quest threshold value(s)
        %
        % pcors is list of proportion correct values
        %  if given, find associated coherences from QUEST Weibull
        %  Parameters are: threshold, slope, guess, lapse
        % NOTE: it is possible to enhance this function by fitting a
        % psychometric function (with Quest) to the data collected during
        % the Quest node.
        function threshold = getQuestThreshold(self, pcors)
            
            % Find values from PMF
            psiParamsIndex = qpListMaxArg(self.quest.posterior);
            psiParamsQuest = self.quest.psiParamsDomain(psiParamsIndex,:);
            
            if ~isempty(psiParamsQuest)
                
                if nargin < 2 || isempty(pcors)
                    % Just return threshold in units of % coh
                    threshold = psiParamsQuest(1);
%                 else
%                     
%                     % Compute PMF with fixed guess and no lapse
%                     cax = 0:0.1:100;
%                     predictedProportions =100*qpPFWeibull(cax', ...
%                         [psiParamsQuest(1,1:3) 0]);
%                     threshold = nans(size(pcors));
%                     for ii = 1:length(pcors)
%                         Lp = predictedProportions(:,2)>=pcors(ii);
%                         if any(Lp)
%                             threshold(ii) = cax(find(Lp,1));
%                         end
%                     end
                end
            end
            
            % Convert to % coherence
            %threshold = 10^(threshold./20).*100;
        end
        
        %% Get next coherences guess from Quest
        %
        function coh = getQuestGuess(self)
            self.questSettings.recentGuess = qpQuery(self.quest);
            coh = min(100, max(0, self.questSettings.recentGuess));
        end
        
        %% Get coherence value corresponding to any desired percent corr.
        function desired_coh = getQuestCoh(self, pcorr)
            % pcorr         is percent correct between 0.5 and 1
            % desired_coh   is the desired coherence level, in %
             
            % Find values from PMF
            psiParamsIndex = qpListMaxArg(self.quest.posterior);
            
            % I intentionally omit the ; at the end of the line below
            % to see parameters fitted by Quest at console
            psiParamsQuest = self.quest.psiParamsDomain(psiParamsIndex,:) 
            
            % Compute PMF with fixed guess and no lapse
            desired_coh =qpPFStandardWeibullInv(pcorr, psiParamsQuest);
            
            % convert back to correct scale (mQUESTPlus uses dB)
            % desired_coh = 10^(desired_coh/20);
        end
        
        %% Change color of fixation symbol to blue
        function changeFixationColor(self, rgbCol)
            ensemble = self.helpers.stimulusEnsemble.theObject;
            ensemble.setObjectProperty('colors', rgbCol, 1);
        end
    end
    
    methods (Access = protected)
        
        %% Prepare drawables for this trial
        %
        function prepareDrawables(self)
            
            % ---- Get the current trial and the stimulus ensemble
            %
            trial    = self.getTrial();
            ensemble = self.helpers.stimulusEnsemble.theObject;
            
            % ----- Get target locations
            %
            %  Determined relative to fp location
            fpX = ensemble.getObjectProperty('xCenter', 1);
            fpY = ensemble.getObjectProperty('yCenter', 1);
            td  = self.settings.targetDistance;
            
            % ---- Possibly update all stimulusEnsemble objects if settings
            %        changed
            %
            if isempty(self.targetDistance) || ...
                    self.targetDistance ~= self.settings.targetDistance
                
                % Save current value(s)
                self.targetDistance = self.settings.targetDistance;
                
                %  Now set the target x,y
                ensemble.setObjectProperty('xCenter', [fpX - td, fpX + td], 2);
                ensemble.setObjectProperty('yCenter', [fpY fpY], 2);
            end
            
            % ---- Set a new seed base for the dots random-number process
            %
            trial.randSeedBase = randi(9999);
            self.setTrial(trial);
            
            % ---- Save dots properties
            %
            ensemble.setObjectProperty('randBase',  trial.randSeedBase, 4);
            ensemble.setObjectProperty('coherence', trial.coherence, 4);
            ensemble.setObjectProperty('direction', trial.initDirection, 4);
            ensemble.setObjectProperty('recordDotsPositions', self.settings.recordDotsPositions, 4);
            ensemble.setObjectProperty('colors', [1 0 0], 1); % reset fixation color to red
            % ---- Possibly update smiley face to location of correct target
            %
            if self.timing.showSmileyFace > 0
                
                % Set x,y
                ensemble.setObjectProperty('x', fpX + sign(cosd(trial.endDirection))*td, 3);
                ensemble.setObjectProperty('y', fpY, 3);
            end
            
            % ---- Prepare to draw dots stimulus
            %
            ensemble.callObjectMethod(@prepareToDrawInWindow);
        end
        
        
        %% Prepare stateMachine for this trial
        %
        function prepareStateMachine(self)
            % empty function
        end
        
        %% Initialize StateMachine
        %
        function initializeStateMachine(self)
            
            % ---- Fevalables for state list
            %
            dnow    = {@drawnow};
            blanks  = {@dotsTheScreen.blankScreen};
            chkuif  = {@getNextEvent, self.helpers.reader.theObject, false, {'holdFixation'}};
            chkuib  = {}; % {@getNextEvent, self.readables.theObject, false, {}}; % {'brokeFixation'}
            chkuic  = {@checkForChoice, self, {'choseLeft' 'choseRight'}, 'choiceTime'};
            showfx  = {@draw, self.helpers.stimulusEnsemble, {{'colors', ...
                [1 1 1], 1}, {'isVisible', true, 1}, {'isVisible', false, [2 3 4]}},  self, 'fixationOn'};
            showt   = {@draw, self.helpers.stimulusEnsemble, {2, []}, self, 'targetOn'};
            showfb  = {@showFeedback, self};
            showdFX = {@draw, self.helpers.stimulusEnsemble, {4, []}, self, 'dotsOn'};
            % jig added self
            switchd = {@switchDots self};
            hided   = {@draw, self.helpers.stimulusEnsemble, {[], [1 4]}, self, 'dotsOff'};
            dumpdots = {@dumpDots, self};
            tocdon = {@tocDotsOn, self};
            tocdoff1 = {@tocDotsOffEpoch1, self};
            tocdoff2 = {@tocDotsOffEpoch2, self};
            chgfxcb = {@changeFixationColor, self, [0 0 1]}; % set fixation to blue
            chgfxcr = {@changeFixationColor, self, [1 0 0]}; % set fixation to red
            
            % recall this function's signature from topsTreeNodeTopNode
            % setNextState(self, condition, thisState, nextStateIfTrue, nextStateIfFalse)
            % thus, the function below sets the 'next' state of the 'showDotsEpoch1'
            % state
            pdbr    = {@setNextState, self, 'isCP', 'showDotsEpoch1', 'switchDots', 'waitForChoiceFX'};
            
            % drift correction
            hfdc  = {@reset, self.helpers.reader.theObject, true};
            
            % Activate/deactivate readable events
            sea   = @setEventsActiveFlag;
            gwfxw = {sea, self.helpers.reader.theObject, 'holdFixation'};
            gwfxh = {};
            gwts  = {sea, self.helpers.reader.theObject, {'choseLeft', 'choseRight'}, 'holdFixation'};
            
            % ---- Timing variables, read directly from the timing property struct
            %
            t = self.timing;
            
            % ---- Make the state machine. These will be added into the
            %        stateMachine (in topsTreeNode)
            %
            % jig:
            %  - changed next state for preDots
            %  - removed showDotsEpoch2 state, which could be consolidated
            %        with switchDots
            states = {...
                'name'              'entry'  'input'  'timeout'                'exit'    'next'            ; ...
                'showFixation'      showfx   {}       0                         pdbr     'waitForFixation' ; ...
                'waitForFixation'   gwfxw    chkuif   t.fixationTimeout         {}       'blankNoFeedback' ; ...
                'holdFixation'      gwfxh    chkuib   t.holdFixation            hfdc     'showTargets'     ; ...
                'showTargets'       showt    chkuib   t.preDots                 gwts     'preDots'         ; ...
                'preDots'           chgfxcb   {}       0                        {}       'showDotsEpoch1'  ; ...
                'showDotsEpoch1'    showdFX  {}       t.dotsDuration1           {}       ''                ; ...
                'switchDots'        switchd  {}       t.dotsDuration2           {}       'waitForChoiceFX' ; ...
                'waitForChoiceFX'   hided    chkuic   t.choiceTimeout           {}       'blank'           ; ...
                'blank'             chgfxcr  {}       0.1                       blanks   'showFeedback'    ; ...
                'showFeedback'      showfb   {}       t.showFeedback            blanks   'done'            ; ...
                'blankNoFeedback'   {}       {}       0                         blanks   'done'            ; ...
                'done'              dnow     {}       t.interTrialInterval      dumpdots ''                ; ...
                };
            
            % ---- Set up ensemble activation list. This determines which
            %        states will correspond to automatic, repeated calls to
            %        the given ensemble methods
            %
            % See topsActivateEnsemblesByState for details.
            % jig updated state list to include states that require dots
            % drawing
            activeList = {{ ...
                self.helpers.stimulusEnsemble.theObject, 'draw'; ...
                self.helpers.screenEnsemble.theObject, 'flip'}, ...
                {'preDots' 'showDotsEpoch1' 'switchDots'}};
            
            % --- List of children to add to the stateMachineComposite
            %        (the state list above is added automatically)
            %
            compositeChildren = { ...
                self.helpers.stimulusEnsemble.theObject, ...
                self.helpers.screenEnsemble.theObject};
            
            % Call utility to set up the state machine
            self.addStateMachine(states, activeList, compositeChildren);
        end
    end
    
    methods (Static)
        
        %% ---- Utility for defining standard configurations
        %
        % name is string:
        %  'Quest' for adaptive threshold procedure
        %  or '<SAT><BIAS>' tag, where:
        %     <SAT> is 'N' for neutral, 'S' for speed, 'A' for accuracy
        %     <BIAS> is 'N' for neutral, 'L' for left more likely, 'R' for
        %     right more likely
        function task = getStandardConfiguration(name, varargin)
            
            % ---- Get the task object, with optional property/value pairs
            %
            task = topsTreeNodeTaskSingleCPDotsReversal(name, varargin{:});
             
            % ---- Instruction settings, by column:
            %  1. tag (first character of name)
            %  2. Text string #1
            %  3. RTFeedback flag
            %
            SATsettings = { ...
                'S' 'Be as FAST as possible.'                 task.settings.referenceRT; ...
                'A' 'Be as ACCURATE as possible.'             nan;...
                'N' 'Be as FAST and ACCURATE as possible.'    nan};
            
            dp = task.settings.directionPriors;
            BIASsettings = { ...
                'L' 'Left is more likely.'                    [max(dp) min(dp)]; ...
                'R' 'Right is more likely.'                   [min(dp) max(dp)]; ...
                'N' 'Both directions are equally likely.'     [50 50]};
            
            % For instructions
            %          if strcmp(name, 'Quest')
            %             name = 'NN';
            %          end
            
            % ---- Set strings, priors based on type
            % NOTE: 3 lines below are hard-coded for now, just to get the task
            % to run. Should be improved in the future
            task.settings.textStrings = {SATsettings{2, 2}, BIASsettings{3, 2}};
            task.settings.referenceRT = nan;
        end
    end
end

