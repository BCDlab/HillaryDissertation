%% Initial set-up
% Prompt box for subnum and counterbalance; creates variables for these
prompt = {'Subject Number','Counterbalance'};
defaults = {'1','1'};
answer = inputdlg(prompt,'Subnum',1,defaults);
[subject,counterbalance] = deal(answer{:});

rng 'Shuffle'; 
fid = fopen('Subinfo.txt','a+');

% odd or even counterbalance
  if mod(str2double(counterbalance(end)),2) == 0
    isEven = true;
  else
    isEven = false;
  end

 counterbalance = str2double(counterbalance);
  
% Set stimuli directories for each species (to present images)
Macaques = dir(fullfile('\Images\Macaques\gray','*.png'));
Capuchins = dir(fullfile('\Images\Capuchins\gray','*.png'));

% Set stimuli directory for audio files
Labels = dir(fullfile('\Audio','*.wav'));
Noise = dir(fullfile('Audio','Noise.wav'));

% Read in text files for stim lists
[MacaqueNames] = textread('Lists/Macaques.txt','%s'); %#ok<*REMFF1>
[CapuchinNames] = textread('Lists/Capuchins.txt','%s'); %#ok<*REMFF1>
[LabelNames] = textread('Lists/Labels.txt','%s'); %#ok<*REMFF1>
[NoiseFile] = textread('Lists/Noise.txt','%s'); %#ok<*REMFF1>

% Shuffle order of each species and create a randomized list of each
% species
nMacaque = length(MacaqueNames);
nCapuchin = length(CapuchinNames);
RandMacaque = randperm(nMacaque);
RandCapuchin = randperm(nCapuchin);

MacaqueShuffle = MacaqueNames(RandMacaque);
CapuchinShuffle = CapuchinNames(RandCapuchin);

% Counters for equal numbers of face presentations in ERP task
count1 = 0;
count2 = 0;
count3 = 0;
count4 = 0;

% Shuffle order of audio labels
nLabels = length(LabelNames);
RandLabels = randperm(nLabels);
LabelShuffle = LabelNames(RandLabels);
%Label = randi(4);
%LabelPlay = LabelShuffle(Label); % This is the file that will be used to present a label each trial

% 4 counterbalances: Individual-Capuchin, Noise-Macaque; Individual-Macaque, Noise-Capuchin; Noise-Macaque, Individual-Capuchin; Noise-Capuchin, Individual-Macaque

% Randomize divvying up 4 faces/species per task - random, no replacement
MacaqueList = [MacaqueShuffle(1:4), MacaqueShuffle(5:8), MacaqueShuffle(9:12)];
CapuchinList = [CapuchinShuffle(1:4), CapuchinShuffle(5:8), CapuchinShuffle(9:12)];

fprintf(fid,'SubNum\tCounterbalance\tTask\tTrial\tStimulus\tMonkeySpecies\tLabelType\n');

% Connect to NetStation
DAC_IP = '10.0.0.42';
NetStation('Connect', DAC_IP);
NetStation('Synchronize');
NetStation('StartRecording');

% Set up the screen
Screen('Preference', 'SkipSyncTests', 1);
screennum = 0;
white = WhiteIndex(screennum);
gray = GrayIndex(screennum);
[w, wRect] = Screen('OpenWindow',screennum,gray);
Screen(w,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
fps = 30;
hz=Screen(screennum,'FrameRate',[], [fps]);

% Set up for ssVEP size variation
xsize = 400;
ysize = 512;
x = 0; % Drawing position relative to center
y = 0;
x0 = wRect(3)/2; % Screen center
y0 = wRect(4)/2;
sizevary = [.95,.97,.99,1.01,1.03,1.05];

% Data concerning the sinusoidal modulation of the alpha channel
nFrames = 30;



%% Run through the tasks in the correct order
nTask = 3;
nSpecies = 2;
nStimuli = 5;
TimessVEP = 10; % seconds
FreqssVEP = 5.88; % Hz
nTrialssVEP = 1; % number of ssVEP trials
nTrialsERP = 3; % number of ERP training trials 
nImagesssVEP = floor(TimessVEP*FreqssVEP); % floor stops presenting at an image instead of half an image or something

framesPerStimuli = 7;  % hard-code the number of frames per stimulus ease computational work
% framesPerStimuli = floor(fps * (FreqssVEP / nStimuli));  % calculate the
% use the exact number of frames per stimulus

for Task=1:nTask
    for Species=1:nSpecies
        if isEven == true % If subnum is even, Capuchins first
            if Species==1
                thisSpecies = Capuchins;
                speciesName = 'Capuchins';
                thisTask = CapuchinList(:,Task);
            elseif Species==2
                thisSpecies = Macaques;
                speciesName = 'Macaques';
                thisTask = MacaqueList(:,Task);
            end
        elseif isEven == false % If subnum is odd, Macaques first 
            if Species==1
                thisSpecies = Macaques;
                speciesName = 'Macaques';
                thisTask = MacaqueList(:,Task);
            elseif Species==2
                thisSpecies = Capuchins;
                speciesName = 'Capuchins';
                thisTask = CapuchinList(:,Task);
            end
        end
        if Task==1 % pre-training ssVEP task
           standard = -1; % initially sets standard to something impossible
           for Trial=1:nTrialssVEP
               oddball = -1;
               newstandard = randi(4);
               while newstandard == standard
                   newstandard = randi(4); % checks to make sure standard is not repeated twice in a row
               end 
               standard = newstandard;
               standardshow = thisTask(standard);
               for image=1:nImagesssVEP
                 sizepick = sizevary(randi(numel(sizevary)));
                 s = sizepick;
                 destrect = [x0-s*xsize/2+x,y0-s*ysize/2+y,x0+s*xsize/2+x,y0+s*ysize/2+y]; % For size variation
                   if mod(image,5) ~= 0 % checks if remainder is divisible by 5; if not, present standard
                       %disp('standard'); % Use this line for checking output order only 
                       %disp(thisTask(standard));
                       filename = strjoin({'Images',speciesName,'gray',char(standardshow(1))}, '/');
                       imdata = imread(char(filename));
                       mytex = Screen('MakeTexture',w,imdata);
                       
                       % Adjust alpha
                       alphaCount = 0;
                       alpha(0);
                       for currentFrame = 0:framesPerStimuli
                           
                           if currentFrame < (framesPerStimuli / 2)
                               alphaCount = alphaCount + (1/framesPerStimuli);
                               alpha(alphaCount);
                           elseif currentFrame >= (framesPerStimuli / 2)
                               alphaCount = alphaCount - (1/framesPerStimuli);
                               alpha(alphaCount);
                           end
                           
                           Screen('DrawTexture',w,mytex,[],destrect,[],[],0.3);
                           [standOn] = Screen('Flip',w);
                           WaitSecs(1/(framesPerStimuli * FreqssVEP));
                           Screen('Flip',w);
                       end
                       
                   elseif mod(image,5) == 0 % if remainder is divisible by 5, present oddball
                       newoddball = randi(4);
                       while newoddball == oddball || newoddball == standard
                           newoddball = randi(4);
                       end
                       oddball = newoddball;
                       oddballshow = thisTask(newoddball);
                       %disp('oddball'); % Use to check output
                       %disp(oddballshow); 
                       filename = strjoin({'Images',speciesName,'gray',char(oddballshow(1))}, '/');
                       imdata = imread(char(filename));
                       mytex = Screen('MakeTexture',w,imdata);
                       
                       % insert alpha adjustment here
                       
                       Screen('DrawTexture',w,mytex,[],destrect);
                       [oddOn] = Screen('Flip',w);
                       WaitSecs(1/FreqssVEP);
                       Screen('Flip',w);
                   end    
               end
               Screen('Close'); % Supposed to clean up old textures
               fprintf(fid,'%s\t%d\t%d\t%d\t%s\n',subject,counterbalance,Task,Trial,char(standardshow));
           end
        elseif Task==2 
               InitializePsychSound;
               MySoundFreq = 96000;
               Channels = 1;
               face = -1; % initially sets to something impossible
           for Trial=1:nTrialsERP
            if (isEven == true && Species == 1) || (isEven == false && Species == 2)
                monkeyspecies = 'Capuchin';
            elseif (isEven == true && Species == 2) || (isEven == false && Species == 1)
                monkeyspecies = 'Macaque';
            end
            if (counterbalance == 1 && Species == 1 || counterbalance == 2 && Species == 1) || (counterbalance == 3 && Species == 2 || counterbalance == 4 && Species == 2)
                labeltype = 'Label';
            elseif (counterbalance == 1 && Species == 2 || counterbalance == 2 && Species == 2) || (counterbalance == 3 && Species == 1 || counterbalance == 4 && Species == 1)
                labeltype = 'Noise';
            end
               newface = randi(4); 
               while newface == face
                   newface = randi(4); % checks to make sure standard is not repeated twice in a row
               end 
                       face = newface;
                       mastercount = {count1,count2,count3,count4}; 
                           if mastercount{face} >= 15
                              newface = randi(4);
                              face = newface;
                           elseif mastercount{face} < 15
                                if face == 1
                                       count1 = count1 + 1;
                                   elseif face == 2
                                       count2 = count2 + 1;
                                   elseif face == 3
                                       count3 = count3 + 1;
                                   elseif face == 4
                                       count4 = count4 + 1;
                                end 
                           end
                       faceshow = thisTask(face);
                        if Species == 1
                            if counterbalance == 1 || counterbalance == 2
                                LabelPlay = LabelShuffle(face);
                            elseif counterbalance == 3 || counterbalance == 4
                                LabelPlay = NoiseFile;
                            end
                        end 
                        if Species == 2
                            if counterbalance == 1 || counterbalance == 2
                                LabelPlay = NoiseFile;
                            elseif counterbalance == 3 || counterbalance == 4
                                LabelPlay = LabelShuffle(face);
                            end
                        end                        
                       MySound = strjoin({'Audio',char(LabelPlay(1))},'/');
                       MySoundData = transpose(wavread(MySound));
                       FinishTime = length(MySoundData)/MySoundFreq;
                       MySoundHandle = PsychPortAudio('Open',[],[],0,MySoundFreq,Channels);
                       PsychPortAudio('FillBuffer',MySoundHandle,MySoundData,0);
                       % disp(faceshow); % Use to check output of filenames
                       filename = strjoin({'Images',speciesName,'gray',char(faceshow(1))}, '/');
                       imdata = imread(char(filename));
                       mytex = Screen('MakeTexture',w,imdata);
                       [X,Y] = RectCenter(wRect); % Centers fixation cross
                       FixCross = [X-1,Y-20,X+1,Y+20;X-20,Y-1,X+20,Y+1]; % Fixation cross size
                       Screen('FillRect', w, [0,0,0], FixCross');
                       Screen('Flip',w);
                       s3 = GetSecs();
                       %NetStation('Event','fix+',s,0.001,'trl#',Trial);
                       [buttons] = GetClicks(w); % Listens for mouseclicks
                          if any(buttons) % Present image on mouseclick
                           Screen('DrawTexture',w,mytex);
                           [stimOn] = Screen('Flip',w);
                           %NetStation('Event','stm+',stimOn,0.001,'trl#',Trial,'monk',monkeyspecies,'labl',labeltype);
                           startTime = PsychPortAudio('Start',MySoundHandle,1,0,1); % Jitter onset time between 10-300ms post-face onset
                           WaitSecs(FinishTime);
                           Screen('Flip',w);  
                           s2 = GetSecs();
                           %NetStation('Event','stm-',s2,0.001);
                          end
                       randi([800,1000]); % Random inter-trial interval   
                       %WaitSecs(.5); 
                       fprintf(fid,'%s\t%d\t%d\t%d\t%s\t%s\t%s\n',subject,counterbalance,Task,Trial,char(faceshow),monkeyspecies,labeltype);
           end  
        elseif Task==3
standard = -1; % initially sets standard to something impossible
           for Trial=1:nTrialssVEP
               oddball = -1;
               newstandard = randi(4);
               while newstandard == standard
                   newstandard = randi(4); % checks to make sure standard is not repeated twice in a row
               end 
               standard = newstandard;
               standardshow = thisTask(standard);
               for image=1:nImagesssVEP
                 sizepick = sizevary(randi(numel(sizevary)));
                 s = sizepick;
                 destrect = [x0-s*xsize/2+x,y0-s*ysize/2+y,x0+s*xsize/2+x,y0+s*ysize/2+y]; % For size variation
                   if mod(image,5) ~= 0 % checks if remainder is divisible by 5; if not, present standard
                       %disp('standard'); % Use this line for checking output order only 
                       %disp(thisTask(standard));
                       filename = strjoin({'Images',speciesName,'gray',char(standardshow(1))}, '/');
                       imdata = imread(char(filename));
                       mytex = Screen('MakeTexture',w,imdata);
                       Screen('DrawTexture',w,mytex,[],destrect);
                       [standOn] = Screen('Flip',w);
                       WaitSecs(1/FreqssVEP);
                       Screen('Flip',w);
                   elseif mod(image,5) == 0 % if remainder is divisible by 5, present oddball
                       newoddball = randi(4);
                       while newoddball == oddball || newoddball == standard
                           newoddball = randi(4);
                       end
                       oddball = newoddball;
                       oddballshow = thisTask(newoddball);
                       %disp('oddball'); % Use to check output
                       %disp(oddballshow); 
                       filename = strjoin({'Images',speciesName,'gray',char(oddballshow(1))}, '/');
                       imdata = imread(char(filename));
                       mytex = Screen('MakeTexture',w,imdata);
                       Screen('DrawTexture',w,mytex,[],destrect);
                       [oddOn] = Screen('Flip',w);
                       WaitSecs(1/FreqssVEP);
                       Screen('Flip',w);
                   end
               end
           fprintf(fid,'%s\t%d\t%d\t%d\t%s\n',subject,counterbalance,Task,Trial,char(standardshow));    
           end
        end
    end
end
NetStation('Synchronize');
NetStation('StopRecording');
NetStation('Disconnect', DAC_IP);
Screen('CloseAll');


%PsychPortAudio('Stop',MySoundHandle);
%PsychPortAudio('Close',MySoundHandle);
