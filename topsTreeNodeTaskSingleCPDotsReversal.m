classdef topsTreeNodeTaskSingleCPDotsReversal < topsTreeNodeTask
    % @class topsTreeNodeTaskRTDots
    %
    % recall the sequence of blocks
    %   Tut1    Tutorial 1
    %   Quest   Block 1 (Quest)
    %   Tut2    Tutorial 2
    %   Block2  Block 2 (standard dots task)
    %   Tut3    Tutorial 3
    %   Block3  Blocks 3+ (dual-report task)
    %
    % 11/28/18 created by aer / reviewed by jig
    % 
    
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
            'showInstructions',          0, ...
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
            'dirChoiceTimeout',          3.0, ...
            'cpChoiceTimeout',           8.0);
        
        % settings about the trial sequence to use
        trialSettings = struct( ...
            'numTrials',        204, ... % theoretical number of valid trials per block
            'loadFromFile',     false,      ... % load trial sequence from files?
            'csvFile',          '',         ... % file of the form filename.csv
            'jsonFile',         '');        ... % file of the form filename_metadata.json
        
        % Quest properties
        questSettings = struct( ...
            'stimRange',                 0:100,           ... % coherence levels 
            'thresholdRange',            0.5:.5:100,      ... % cannot start at 0 with Weibull
            'slopeRange',                2,               ... % we don't estimate the slope
            'guessRate',                 0.5,             ... % because it is a 2AFC task
            'lapseRange',                0.001,           ... % this lapse will affect percent correct at threshold, so we estimate it
            'recentGuess',               [],              ...
            'viewingDuration',           .4);             % stimulus duration for Quest (sec)
           
        % Array of structures of independent variables, used by makeTrials
        % NOTE: DO NOT CHANGE THE ORDERING OF THE ENTRIES BELOW!
        % 1. initDirection
        % 2. coherence
        % 3. viewingDuration
        % 4. condProbCP
        % 5. timeCP
        independentVariables = struct( ...
            'name',        {...
                'initDirection',   ...
                'coherence',       ...
                'viewingDuration', ...
                'condProbCP',          ...
                'timeCP'},         ...
            'values',      {...
                [0 180],           ... % allowed initial directions
                [10 30 70],        ... % coherence values, if not a Quest
                .1:.1:.4,          ... % viewingDuration (sec)
                .5,                ... % probability of CP, given that the trial is longer than timeCP
                .2},               ... % time of CP
            'priors',      {[], [], [], [], []});
        
        % dataFieldNames are used to set up the trialData structure
        trialDataFields = {...
            'dirRT', ...
            'dirChoice', ...
            'dirCorrect', ...
            'cpRT', ...
            'cpChoice', ...
            'cpCorrect', ...
            'initDirection', ...
            'endDirection', ...
            'presenceCP', ...
            'coherence', ...
            'viewingDuration', ...
            'condProbCP', ...
            'timeCP', ...
            'randSeedBase', ...
            'fixationOn', ...
            'fixationStart', ...
            'targetOn', ...
            'dotsOn', ...
            'dotsOff', ...
            'dirChoiceTime', ...
            'dirReleaseChoiceTime', ...
            'cpChoiceTime', ...
            'targetOff', ...
            'fixationOff', ...
            'feedbackOn', ...
            'CPresponseSide', ...
            'startResponseTwo'};
        
        
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
            'recordDotsPositions',        false)), ...
            ...   % CP Targets drawable settings
            'cpLeftTarget',               struct( ...
            'fevalable',                  @dotsDrawableText, ...
            'settings',                   struct( ...
            'x',                          -12, ...
            'y',                          0)), ...
            ...
            'cpRightTarget',              struct( ...
            'fevalable',                  @dotsDrawableText, ...
            'settings',                   struct( ...
            'x',                          12, ...
            'y',                          0))));              
        
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
            'name',                       {'holdFixation', 'choseLeft', 'choseRight', 'choseCP', 'choseNOCP'}, ...
            'component',                  {'KeyboardSpacebar', 'KeyboardLeftArrow', 'KeyboardRightArrow', 'KeyboardC', 'KeyboardN'}, ...
            'isRelease',                  {true, false, false, false, false})}}), ...
            ...
            ...   % Gamepad
            'dotsReadableHIDGamepad',     struct( ...
            'start',                      {{@defineEventsFromStruct, struct( ...
            'name',                       {'holdFixation', ...  % A button
                                            'choseLeft', ...    % left trigger
                                            'choseRight', ...   % right trigger
                                            'startTask', ...    % B button
                                            'choseCP', ...      % X button
                                            'choseNOCP'}, ...   % Y button
            'component',                  {'Button1', ...  % button ID 3
                                            'Trigger1', ...% button ID 7
                                            'Trigger2', ...% button ID 8
                                            'Button2', ... % button ID 4
                                            'Button3', ... % button ID 5
                                            'Button4'}, ...% button ID 6
            'isRelease',                  {true, ...
                                           false, ...
                                           false, ...
                                           false, ...
                                           false, ...
                                           false})}}), ...
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
        
        % requests for 2 responses if true; for decide on direction, then
        % decide on presence/absence of change point
        isDualReport = false;
        
        getMoney = false;
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
            % 
            if self.trialSettings.loadFromFile
                trialsTable = ...
                    readtable(self.trialSettings.csvFile);
                metaData = ...
                    loadjson(self.trialSettings.jsonFile);
                
                % set values that are common to all trials
                self.trialSettings.numTrials = self.trialIterations;
                ntr = self.trialSettings.numTrials;
                
                % produce copies of trialData struct to render it ntr x 1
                self.trialData = repmat(self.trialData(1), ntr, 1);
                
                % taskID
                [self.trialData.taskID] = deal(self.taskID);
                
                % condProbCP
                [self.trialData.condProbCP] = ...
                    deal(metaData.cond_prob_cp);
                
                % timeCP
                [self.trialData.timeCP] = ...
                    deal(self.independentVariables(5).values(1));
                
                trlist = num2cell(1:ntr);
                
                % trialIndex
                [self.trialData.trialIndex] = deal(trlist{:});
                
                % set values that are specific to each trial
                for tr = 1:ntr
                    
                    % initDirection
                    if strcmp(trialsTable.dir(tr), 'left')
                        self.trialData(tr).initDirection = 180;
                    else
                        self.trialData(tr).initDirection = 0;
                    end
                    
                    % endDirection and presenceCP
                    if strcmp(trialsTable.cp(tr), 'True')
                        self.trialData(tr).endDirection = ...
                            self.flipDirection( ...
                                self.trialData(tr).initDirection);
                        self.trialData(tr).presenceCP = 1.0;  % numeric for FIRA
                    else
                        self.trialData(tr).endDirection = ...
                                self.trialData(tr).initDirection;
                        self.trialData(tr).presenceCP = 0;
                    end
                    
                    % coherence (3 possible values)
                    
                    cohMetaData = trialsTable.coh(tr);
                    if isnumeric(cohMetaData)
                        cohMetaData = num2str(cohMetaData);
                    end
                    if strcmp(cohMetaData, '0')
                        self.trialData(tr).coherence = ...
                            self.independentVariables(2).values(1);
                    elseif strcmp(cohMetaData, 'th')
                        self.trialData(tr).coherence = ...
                            self.independentVariables(2).values(2);
                    elseif strcmp(cohMetaData, '100')
                        self.trialData(tr).coherence = ...
                            self.independentVariables(2).values(3);
                    end
                        
                    % viewingDuration
                    self.trialData(tr).viewingDuration = ...
                        trialsTable.vd(tr) / 1000;

                end
                
            % we only use the old makeTrials() for the Quest node
            elseif strcmp(self.name, 'Quest') || strcmp(self.name, 'Tut1')
                % if trialIterations arg is not provided or is empty, set it to
                % 1
                if nargin < 3 || isempty(trialIterations)
                    trialIterations = 1;
                end

                % Loop through to set full set of values for each variable
                for ii = 1:length(independentVariables)

                    % now do something only if priors field is nonempty
                    %
                    % update values based on priors, if they are given in the
                    % format: [proportion_value_1 proportion_value_2 ... etc]
                    %
                    % check that priors vector has same length as values
                    % vector, and that the sum of the entries in priors is
                    % positive
                    if length(independentVariables(ii).priors) == ...
                            length(independentVariables(ii).values) && ...
                            sum(independentVariables(ii).priors) > 0

                        % TOTEST
                        % rescale priors by greatest common divisor
                        priors = independentVariables(ii).priors;
                        priors = priors./gcd(sym(priors));

                        % TOTEST -- what does this currently do?
                        % now re-make values array based on priors
                        values = [];
                        for jj = 1:length(priors)
                            values = cat(1, values, repmat( ...
                                independentVariables(ii).values(jj), priors(jj), 1));
                        end

                        % re-save the values
                        independentVariables(ii).values = values;
                    end
                end

                % get values as cell array and make ndgrid
                values = {independentVariables.values};
                grids  = cell(size(values));
                  [grids{:}] = ndgrid(values{:});

                % update trialData struct array with "trialIterations" copies of
                % each trial, defined by unique combinations of the independent
                % variables
                ntr = numel(grids{1}) * trialIterations;
                self.trialData = repmat(self.trialData(1), ntr, 1);
                [self.trialData.taskID] = deal(self.taskID);
                trlist = num2cell(1:ntr);
                [self.trialData.trialIndex] = deal(trlist{:});
                [self.trialData.presenceCP] = deal(0);

                % loop through the independent variables and set in each trialData
                % struct. Make sure to repeat each set trialIterations times.
                for ii = 1:length(independentVariables)
                    values = num2cell(repmat(grids{ii}(:), trialIterations, 1));
                    [self.trialData.(independentVariables(ii).name)] = deal(values{:});
                end
            end
        end
        
%         %% debug cross
%         function debug_cross(self)
%             
%             % ---- Activate event and check for it
%             %
%             self.helpers.reader.theObject.setEventsActiveFlag({'x','y'})
%             xeventName = self.helpers.reader.readEvent({'x'});
%             yeventName = self.helpers.reader.readEvent({'y'});
%             
%             
%             
%             % Nothing... keep checking
%             while isempty(xeventName) && isempty(yeventName)
%                 self.helpers.feedback.show('text', ...
%                     {'waiting for cross press'}, ...
%                     'showDuration', 0.1, ...
%                     'blank', false);
%                 
%                 xeventName = self.helpers.reader.readEvent({'x'});
%                 yeventName = self.helpers.reader.readEvent({'y'});
%             end
%             
%             if ~isempty(xeventName)
%                 ev='x';
%             elseif ~isempty(yeventName)
%                 ev='y';
%             end
%             
%             self.helpers.feedback.show('text', ...
%                 ['event ',ev,' detected!'], ...
%                 'showDuration', 3.5, ...
%                 'blank', true);
%         end
        
        %% Self paced break screen
        function self_paced_break(self)
            
            % ---- Activate event and check for it
            %
            self.helpers.reader.theObject.setEventsActiveFlag('startTask')
            eventName = self.helpers.reader.readEvent({'startTask'});
            

            
            % Nothing... keep checking
            while isempty(eventName)
                if ismember(self.name,{'Tut1', 'Tut2', 'Tut3', 'Quest', 'Block2', 'Block3'})
                    self.helpers.feedback.show('text', ...
                        {['You may start the next block by pressing', ...
                        ' the B button.']}, ...
                        'showDuration', 0.1, ...
                        'blank', false);
                else
                    breakstr = 'Take a break if you wish.';
                    self.helpers.feedback.show('text', ...
                        {breakstr,  ...
                        ['You may start the next block by pressing', ...
                        ' the B button.']}, ...
                        'showDuration', 0.1, ...
                        'blank', false);
                end
                
                eventName = self.helpers.reader.readEvent({'startTask'});
            end
            if ~isempty(self.trialSettings.jsonFile) && ~ismember(self.name, {'Tut1', 'Tut2', 'Tut3', 'Block2'})
                metaData = ...
                    loadjson(self.trialSettings.jsonFile);
                if metaData.prob_cp < 0.5
                    cpfreq = 'a LOW';
                elseif metaData.prob_cp == 0.5
                    cpfreq = 'a MEDIUM';
                elseif metaData.prob_cp == .8
                    cpfreq = 'a HIGH';
                end
                self.helpers.feedback.show('text', ...
                    ['This block has ',cpfreq,' number of switch trials'], ...
                    'showDuration', 6.5, ...
                    'blank', true);
            end
        end
        
        %% Start task (overloaded)
        %
        % Put stuff here that you want to do before each time you run this
        % task
        function startTask(self)
            % manually add dummy events related to x and y directions of
            % directional cross on gamepad
            readableObj = self.helpers.reader.theObject;
            if isa(readableObj,'dotsReadableHIDGamepad')
                readableObj.defineEvent('x', 'component', 9);
                readableObj.defineEvent('y', 'component', 10);
            end
            
            self.trialIterationMethod = 'sequential';  % enforce sequential
            self.randomizeWhenRepeating = false;
            
            % ---- Set up independent variables if Quest task
            %
            if strcmp(self.name, 'Quest') || strcmp(self.name, 'Tut1') % when we are running the task as Quest node
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
                self.setIndependentVariableByName('condProbCP', 'values', 0);
                self.setIndependentVariableByName('viewingDuration', ...
                    'values', self.questSettings.viewingDuration);      
            elseif ~isempty(self.settings.useQuest) % when we are running the task AFTER a Quest node
                % get Quest threshold
                questThreshold = self.settings.useQuest.getQuestThreshold( ...
                    self.settings.coherencesFromQuest);
                
                % get coherence value corresponding to 98 pCorrect
%                 questHighCoh = self.settings.useQuest.getQuestCoh(.98);
%                 if questHighCoh > 100
%                     questHighCoh = 100;
%                 end
                questHighCoh = 100;

                % Update independent variable struct using Quest's fit
                self.setIndependentVariableByName('coherence', 'values', ...
                    [0, questThreshold, questHighCoh]);
                self.setIndependentVariableByName('coherence', 'priors', ...
                    [30 40 30]);
            end
            
            
%             % debug
%             self.debug_cross()
%             
            
            % ---- Self-paced break screen
            % we offer the subject the possibility to take a break
            % the subject triggers the start of the task with a key press
            
            self.self_paced_break()
            
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
            % fetch current total accrued reward for this session
            curr_tot_reward = ...
                self.caller.nodeData.getItemFromGroupWithMnemonic('Settings', 'accruedReward');
            pause(0.1)
            % compute money reward
            if length(self.name) > 4
                if strcmp(self.name(1:5), 'Block')
                    full_correct_counter = 0;
                    trial_counter = 0;
                    tot_trials = numel(self.trialData);
                    for t = 1:tot_trials
                        trial = self.trialData(t);
                        if trial.coherence == 100
                            trial_counter = trial_counter + 1;
                            if trial.dirCorrect && trial.cpCorrect
                                full_correct_counter = full_correct_counter + 1;
                            end
                        end
                    end
                    self.getMoney = (full_correct_counter / trial_counter) > 0.75;
                    
                    if self.getMoney
                        block_reward = 2;
                        self.helpers.feedback.show('text', ...
                            {['Well done! You earned $', ...
                            num2str(block_reward)], ...
                            ['Total = $', num2str(curr_tot_reward + block_reward)]}, ...
                            'showDuration', 4.5, ...
                            'blank', false);
                        
                    else
                        self.helpers.feedback.show('text', ...
                            {'You did not earn additional money on this block.', ...
                            'Let us know if something is wrong.'}, ...
                            'showDuration', 4.5, ...
                            'blank', false);
                        block_reward = 0;
                    end
                elseif strcmp(self.name(1:5), 'Quest')
                    block_reward = 2;
                    self.helpers.feedback.show('text', ...
                        ['You earned your first $', ...
                        num2str(block_reward),' with this block!'], ...
                        'showDuration', 4.5, ...
                        'blank', false);
                end
            else
                block_reward = 0;
            end
            curr_tot_reward = curr_tot_reward + block_reward;
            
            % store reward entries in topsGroupedList from parent topNode
            self.caller.nodeData.addItemToGroupWithMnemonic(curr_tot_reward, 'Settings', 'accruedReward');
            self.caller.nodeData.addItemToGroupWithMnemonic(block_reward, 'Settings', [self.name,'_reward']);
            
            fprintf('----------')
            fprintf(' End of %s, block reward %d, total reward %d', ...
                self.name, block_reward, curr_tot_reward)
            fprintf(char(10))
            fprintf('============================================================')
            fprintf(char(10))
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

            if trial.presenceCP
                self.isCP = true;
                self.timing.dotsDuration1 = trial.timeCP;
                self.timing.dotsDuration2 = trial.viewingDuration - trial.timeCP;
            else
                self.isCP = false;
                self.timing.dotsDuration1 = trial.viewingDuration;
                self.timing.dotsDuration2 = 0;
                if isnan(trial.endDirection)
                    trial.endDirection = trial.initDirection;
                end
            end

            self.setTrial(trial);
            
            % ---- Prepare components
            %
            self.prepareDrawables();
            self.prepareReadables();
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
            % string of the form
            % <block name> (block X/Y): <num dir correct> dirCorrect, <>
            taskString = sprintf('%s (block %d/%d): %d dirCorrect, %d dirError, mean dirRT=%.2f, %d cpCorrect, %d cpError, mean dirRT=%.2f, epoch1=%.2f, epoch2=%.2f dualReport=%d', ...
                self.name, ...
                self.taskID, ...
                length(self.caller.children), ...
                sum([self.trialData.dirCorrect]==1), ...
                sum([self.trialData.dirCorrect]==0), ...
                nanmean([self.trialData.dirRT]), ...
                sum([self.trialData.cpCorrect]==1), ...
                sum([self.trialData.cpCorrect]==0), ...
                nanmean([self.trialData.cpRT]), ...
                self.timing.dotsDuration1, ...
                self.timing.dotsDuration2, ...
                self.isDualReport);
            
            % Trial information
            trial = self.getTrial();
            trialString = sprintf('Trial %d/%d, init dir=%d, coh=%.0f', ...
                self.trialCount, ...
                numel(self.trialData), ...
                trial.initDirection, ...
                trial.coherence);
            
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
            if strcmp(self.name, 'Quest') || strcmp(self.name, 'Tut1')
                
                % ---- Check for bad trial
                %
                trial = self.getTrial();
                if isempty(trial) || ~(trial.dirCorrect >= 0)
                    return
                end
                
                % ---- Update Quest
                %
                % (expects 1=error, 2=correct)
                self.quest = qpUpdate(self.quest, self.questSettings.recentGuess, ...
                    trial.dirCorrect+1);
                
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
                self.settings.referenceRT = nanmedian([self.trialData.dirRT]);
            end
        end
        
        %% Check for direction choice
        %
        % Save choice/RT information and set up feedback for the dots task
        function nextState = checkForDirChoice(self, events, eventTag)
            
            % ---- Check for event
            %
%             self.helpers.reader.theObject.flushData()
%             self.helpers.reader.theObject.setEventsActiveFlag(events)
            eventName = self.helpers.reader.readEvent(events, self, eventTag);
            
            % Nothing... keep checking
            if isempty(eventName)
                nextState = [];
                return
            end
            
            % Jump to next state when done
            if self.isDualReport
                nextState = 'waitForReleasFX';
            else
                % Override completedTrial flag
                self.completedTrial = true;
                nextState = 'blank';
            end
            
            % Get current task/trial
            trial = self.getTrial();
            
            % Save the choice
            trial.dirChoice = double(strcmp(eventName, 'choseRight'));
            
            % Mark as correct/error
            % jig changed direction to endDirection
            trial.dirCorrect = double( ...
                (trial.dirChoice==0 && trial.endDirection==180) || ...
                (trial.dirChoice==1 && trial.endDirection==0));
            
            % Compute/save RT, wrt dotsOff for non-RT
            trial.dirRT = trial.dirChoiceTime - trial.dotsOff;
            
            
            % ---- Re-save the trial
            %
            self.setTrial(trial);
            
            % ---- Possibly show smiley face
            if trial.dirCorrect == 1 && self.timing.showSmileyFace > 0
                self.helpers.stimulusEnsemble.draw({3, [1 2 4]});
                pause(self.timing.showSmileyFace);
            end
%             self.helpers.reader.theObject.deactivateEvents();
        end
        %% Check for direction choice trigger Release
        %
        % Save choice/RT information and set up feedback for the dots task
        function nextState = checkForReleaseDirChoice(self, events, eventTag)
            
            % ---- Check for event
            %
%             self.helpers.reader.theObject.flushData()
%             self.helpers.reader.theObject.setEventsActiveFlag(events)
            eventName = self.helpers.reader.readEvent(events, self, eventTag);
            
            % Nothing... keep checking
            if isempty(eventName)
                nextState = [];
                return
            end
            
            % Jump to next state when done
            nextState = 'blank1';

            
        end
        
        %% Check for CP choice 
        %
        % Save choice/RT information and set up feedback for the dots task
        function nextState = checkForCPChoice(self, events, eventTag)
            
            % ---- Check for event
            %
%             self.helpers.reader.theObject.flushData()
%             self.helpers.reader.theObject.setEventsActiveFlag(events)
            eventName = self.helpers.reader.readEvent(events, self, eventTag);
            
            % Nothing... keep checking
            if isempty(eventName)
                nextState = [];
                return
            end
            
            % ---- Good choice!
            %
            nextState='blank';
            % Override completedTrial flag
            self.completedTrial = true;
                      
            % Get current task/trial
            trial = self.getTrial();
            
            % Save the choice
            if strcmp(eventName, 'choseLeft') 
                if trial.CPresponseSide == 0
                    trial.cpChoice = 1;
                else
                    trial.cpChoice = 0;
                end
            else
                if trial.CPresponseSide == 1
                    trial.cpChoice = 1;
                else
                    trial.cpChoice = 0;
                end
            end
            
            % Mark as correct/error
            % jig changed direction to endDirection
            trial.cpCorrect = double( ...
                (trial.cpChoice==0 && ~self.isCP) || ...
                (trial.cpChoice==1 && self.isCP));
            
            % Compute/save RT, wrt dotsOff for non-RT
            trial.cpRT = trial.cpChoiceTime - trial.startResponseTwo;
            
            % ---- Re-save the trial
            %
            self.setTrial(trial);
            
            % ---- Possibly show smiley face
            if trial.cpCorrect == 1 && self.timing.showSmileyFace > 0
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
            if ~isnan(trial.dirCorrect)
                feedbackStr = ['dir ans ', num2str(trial.dirChoice), ...
                    ' cp ans ', num2str(trial.cpChoice)]; 
                
            else
%                 feedbackArgs = {'text', 'No choice'};
                feedbackStr = 'No choice';
            end
            
            % --- Show trial feedback in GUI/text window
            %
            % jig changed direction to endDirection
            self.statusStrings{2} = ...
                sprintf('Trial %d/%d, end dir=%d, coh=%.0f: %s, dirRT=%.2f, cpRT=%.2f ', ...
                self.trialCount, ...
                numel(self.trialData), ...
                trial.endDirection, ...
                trial.coherence, ...
                feedbackStr, ...
                trial.dirRT, ...
                trial.cpRT);
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
            psiParamsQuest = self.quest.psiParamsDomain(psiParamsIndex,:)
            
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
            
            
            % CP targets assigned randomly
            if rand < 0.5
                ensemble.setObjectProperty('string', 'switch', 5);     % switch response on left
                ensemble.setObjectProperty('string', 'no switch', 6);  % no switch response on right
                trial.CPresponseSide = 0;
            else
                ensemble.setObjectProperty('string', 'switch', 6);     % switch response on right
                ensemble.setObjectProperty('string', 'no switch', 5);  % no switch response on left
                trial.CPresponseSide = 1;
            end
            
  
            % save trial struct
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
        
        %% Prepare readables for this trial
        %
        function prepareReadables(self)
         
            % ---- Inactivate all of the readable events
            %
            self.helpers.reader.theObject.deactivateEvents();
        end   
        
        %% Prepare stateMachine for this trial
        %
        function prepareStateMachine(self)
            % empty function
        end
        
        function flushEventsQueue(self)
            numEventsInQueue = self.helpers.reader.theObject.getNumberOfEvents();
            while numEventsInQueue > 0
                self.helpers.reader.theObject.dequeueEvent(false);
                numEventsInQueue = self.helpers.reader.theObject.getNumberOfEvents();
            end
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
            chkuic  = {@checkForDirChoice, self, {'choseLeft' 'choseRight'}, 'dirChoiceTime'};
            chkuic2  = {@checkForReleaseDirChoice, self, {'choseLeft' 'choseRight'}, 'dirReleaseChoiceTime'};
            chkuid  = {@checkForCPChoice, self, {'choseLeft' 'choseRight'}, 'cpChoiceTime'};
            showfx  = {@draw, self.helpers.stimulusEnsemble, {{'colors', ...
                [1 0 0], 1}, {'isVisible', true, 1}, {'isVisible', false, [2 3 4 5 6]}},  self, 'fixationOn'};
            cpopts  = {@draw, self.helpers.stimulusEnsemble, {{'colors', ...
                [1 1 1], 1}, {'isVisible', true, [5 6]}, {'isVisible', false, [1 2 3 4]}},  self, 'startResponseTwo'};
            showt   = {@draw, self.helpers.stimulusEnsemble, {2, []}, self, 'targetOn'};
            showfb  = {@showFeedback, self};
            showdFX = {@draw, self.helpers.stimulusEnsemble, {4, []}, self, 'dotsOn'};
            switchd = {@switchDots self};
            hided   = {@draw, self.helpers.stimulusEnsemble, {[], [1 4]}, self, 'dotsOff'};
            dumpdots = {@dumpDots, self};

            chgfxcb = {@changeFixationColor, self, [0 0 1]}; % set fixation to blue
%             chgfxcr = {@changeFixationColor, self, [1 0 0]}; % set fixation to red
            
            % recall this function's signature from topsTreeNodeTopNode
            % setNextState(self, condition, thisState, nextStateIfTrue, nextStateIfFalse)
            % thus, the function below sets the 'next' state of the 'showDotsEpoch1'
            % state
            pdbr    = {@setNextState, self, 'isCP', 'showDotsEpoch1', 'switchDots', 'waitForChoiceFX'};
%             blabla  = {@setNextState, self, 'isDualReport', 'waitForChoiceFX', 'blank1', 'blank'};
            
            % drift correction
            hfdc  = {@reset, self.helpers.reader.theObject, true};
            
            % Activate/deactivate readable events
            sea   = @setEventsActiveFlag;
            gwfxw = {sea, self.helpers.reader.theObject, 'holdFixation'};
            gwfxh = {};
            gwts  = {sea, self.helpers.reader.theObject, {'choseLeft', 'choseRight'}, 'holdFixation'};
            flsh = {@flushData, self.helpers.reader.theObject};
            dque = {@flushEventsQueue, self};
%             gwcp  = {sea, self.helpers.reader.theObject, {'choseNOCP', 'choseCP'}};
            
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
                'preDots'           chgfxcb  {}       0                         {}       'showDotsEpoch1'  ; ...
                'showDotsEpoch1'    showdFX  {}       t.dotsDuration1           {}       ''                ; ...
                'switchDots'        switchd  {}       t.dotsDuration2           {}       'waitForChoiceFX' ; ...
                'waitForChoiceFX'   hided    chkuic   t.dirChoiceTimeout        {}       ''                ; ...
                'waitForReleasFX'   {}       chkuic2  t.dirChoiceTimeout        {}       ''                ; ...
                'blank1'            blanks   {}       0.2                       dque    'waitForChoiceCP' ; ...
                'waitForChoiceCP'   cpopts   chkuid   t.cpChoiceTimeout         {}       'blank'           ; ...
                'blank'             blanks   {}       0.1                       flsh     'showFeedback'    ; ...
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
%             SATsettings = { ...
%                 'S' 'Be as FAST as possible.'                 task.settings.referenceRT; ...
%                 'A' 'Be as ACCURATE as possible.'             nan;...
%                 'N' 'Be as FAST and ACCURATE as possible.'    nan};
%             
%             dp = task.settings.directionPriors;
%             BIASsettings = { ...
%                 'L' 'Left is more likely.'                    [max(dp) min(dp)]; ...
%                 'R' 'Right is more likely.'                   [min(dp) max(dp)]; ...
%                 'N' 'Both directions are equally likely.'     [50 50]};
            
            % For instructions
            %          if strcmp(name, 'Quest')
            %             name = 'NN';
            %          end
            
            % ---- Set strings, priors based on type
            % NOTE: 3 lines below are hard-coded for now, just to get the task
            % to run. Should be improved in the future
%             task.settings.textStrings = {SATsettings{2, 2}, BIASsettings{3, 2}};
            task.settings.referenceRT = nan;
        end
    end
end

