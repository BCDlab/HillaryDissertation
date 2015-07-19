%% Initial set-up
rng 'Shuffle'; 
% Set stimuli directories for each species (to present images)
Macaques = dir(fullfile('C:\Users\Hillz\Desktop\DissertationParadigm\Images\Macaques\Grey','*.bmp'));
Capuchins = dir(fullfile('C:\Users\Hillz\Desktop\DissertationParadigm\Images\Capuchins\Grey','*.bmp'));

% Set stimuli directory for audio files
Labels = dir(fullfile('C:\Users\Hillz\Desktop\DissertationParadigm\Audio','*.wav'));

% Read in text files for stim lists
[MacaqueNames] = textread('C:\Users\Hillz\Desktop\DissertationParadigm\Macaques.txt','%s'); %#ok<*REMFF1>
[CapuchinNames] = textread('C:\Users\Hillz\Desktop\DissertationParadigm\Capuchins.txt','%s'); %#ok<*REMFF1>
[LabelNames] = textread('C:\Users\Hillz\Desktop\DissertationParadigm\Labels.txt','%s'); %#ok<*REMFF1>

% Shuffle order of each species and create a randomized list of each
% species
nMacaque = length(MacaqueNames);
nCapuchin = length(CapuchinNames);
RandMacaque = randperm(nMacaque);
RandCapuchin = randperm(nCapuchin);

MacaqueShuffle = MacaqueNames(RandMacaque);
CapuchinShuffle = CapuchinNames(RandCapuchin);

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
%preM = MacaqueList(1:4);
%preC = CapuchinList(1:4);
%trainM = MacaqueList(5:8);
%trainC = CapuchinList(5:8);
%postM = MacaqueList(9:12);
%postC = CapuchinList(9:12);

% Set up the screen
%Screen('Preference', 'SkipSyncTests', 1);
screennum = 0;
white = WhiteIndex(screennum);
grey = white/2;
%[w, wRect] = Screen('OpenWindow',screennum,grey);

%% Run through the tasks in the correct order
nTask = 3;
nSpecies = 2;
TimessVEP = 10; % seconds
FreqssVEP = 5.88; % Hz
nTrialssVEP = 1; % number of ssVEP trials
nTrialsERP = 120; % number of ERP training trials 
nImagesssVEP = floor(TimessVEP*FreqssVEP); % floor stops presenting at an image instead of half an image or something
for Task=1:nTask
    for Species=1:nSpecies
        if Species==1
            thisSpecies = Capuchins;
            speciesName = 'Capuchins';
            thisTask = CapuchinList(:,Task);
        elseif Species==2
            thisSpecies = Macaques;
            speciesName = 'Macaques';
            thisTask = MacaqueList(:,Task);
        end
        if Task==3 % pre-training ssVEP task
           standard = -1; % initially sets standard to something impossible
           for Trial=2:nTrialssVEP
               oddball = -1;
               newstandard = randi(4);
               while newstandard == standard
                   newstandard = randi(4); % checks to make sure standard is not repeated twice in a row
               end 
               standard = newstandard;
               standardshow = thisTask(standard);
               for image=1:nImagesssVEP
                   if mod(image,5) ~= 0 % checks if remainder is divisible by 5; if not, present standard
                       %disp('standard'); % Use this line for checking output order only 
                       %disp(thisTask(standard));
                       filename = strjoin({'Images',speciesName,'Grey',char(standardshow(1))}, '/');
                       imdata = imread(char(filename));
                       mytex = Screen('MakeTexture',w,imdata);
                       Screen('DrawTexture',w,mytex);
                       Screen('Flip',w);
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
                       filename = strjoin({'Images',speciesName,char(oddballshow(1))}, '/');
                       imdata = imread(char(filename));
                       mytex = Screen('MakeTexture',w,imdata);
                       Screen('DrawTexture',w,mytex);
                       Screen('Flip',w);
                       WaitSecs(1/FreqssVEP);
                       Screen('Flip',w);
                   end
               end
           end
        elseif Task==2 
             %  InitializePsychSound;
               MySoundFreq = 32000;
               Channels = 1;
               %Label = randi(4);
               %LabelPlay = LabelShuffle(Label);
               face = -1; % initially sets to something impossible
               count1 = 0;
               count2 = 0;
               count3 = 0;
               count4 = 0;
           for Trial=1:nTrialsERP
               newface = randi(4); % Put counter in at this level to show each face 15 times
               while newface == face
                   newface = randi(4); % checks to make sure standard is not repeated twice in a row
               end 
                       face = newface;  
                       mastercount = {count1,count2,count3,count4};
                    if mastercount{face} >= 4
                        newface = randi(4);
                        face = newface;
                    elseif mastercount{face} < 4
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
                       LabelPlay = LabelShuffle(face);
                    %   MySound = strjoin({'Audio',char(LabelPlay(1))},'/');
                    %   MySoundData = transpose(wavread(MySound));
                    %   FinishTime = length(MySoundData)/MySoundFreq;
                    %   MySoundHandle = PsychPortAudio('Open',[],[],0,MySoundFreq,Channels);
                    %   PsychPortAudio('FillBuffer',MySoundHandle,MySoundData,0);
                       % disp(faceshow); % Use to check output of filenames
                   %    filename = strjoin({'Images',speciesName,char(faceshow(1))}, '/');
                   %    imdata = imread(char(filename));
                       disp(faceshow);
                       % mytex = Screen('MakeTexture',w,imdata);
                   %    [X,Y] = RectCenter(wRect); % Centers fixation cross
                   %    FixCross = [X-1,Y-20,X+1,Y+20;X-20,Y-1,X+20,Y+1]; % Fixation cross size
                       %Screen('FillRect', w, [0,0,0], FixCross');
                      % Screen('Flip',w);
                    %   [buttons] = GetClicks(w); % Listens for mouseclicks
                      %    if any(buttons) % Present image on mouseclick
                      %     Screen('DrawTexture',w,mytex);
                       %    Screen('Flip',w);
                       %    startTime = PsychPortAudio('Start',MySoundHandle,1,0,1);
                       %    WaitSecs(FinishTime);
                       %    Screen('Flip',w);   
                       %   end
                      % WaitSecs(.5); % Random inter-trial interval
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
               for image=1:nImagesssVEP
                   if mod(image,5) ~= 0 % checks if remainder is divisible by 5; if not, present standard
                       %disp('standard');
                       disp(thisTask(standard));
                   elseif mod(image,5) == 0 % if remainder is divisible by 5, present oddball
                       newoddball = randi(4);
                       while newoddball == oddball || newoddball == standard
                           newoddball = randi(4);
                       end
                       oddball = newoddball;
                       oddballshow = thisTask(newoddball);
                       %disp('oddball');
                       disp(oddballshow); 
                   end
               end
           end
        end
    end
end
%Task = {'preM', 'preC', 'trainM', 'trainC', 'postM', 'postC'};
%fid1 = fopen('StimList.txt','a+');
%nTask = 6;
%    for i=1:nTask
%        m = Task{:};
%        z = randperm(4);
%        fprintf(fid1,'%s %s\n', m(z(1)), m(z(2)));
%    end 
%z = randperm(4);
%fprintf(fid1,'%s %s\n', char(preM(z(1))), char(preM(z(2))));
%fprintf(fid1,'%s %s\n', char(preM(z(1))), char(preM(z(3))));
%fprintf(fid1,'%s %s\n', char(preM(z(1))), char(preM(z(4))));
%fprintf(fid1,'%s %s\n', char(preM(z(2))), char(preM(z(1))));
%fprintf(fid1,'%s %s\n', char(preM(z(2))), char(preM(z(3))));
%fprintf(fid1,'%s %s\n', char(preM(z(2))), char(preM(z(4))));
%fprintf(fid1,'%s %s\n', char(preM(z(3))), char(preM(z(1))));
%fprintf(fid1,'%s %s\n', char(preM(z(3))), char(preM(z(2))));
%fprintf(fid1,'%s %s\n', char(preM(z(3))), char(preM(z(4))));
%fprintf(fid1,'%s %s\n', char(preM(z(4))), char(preM(z(1))));
%fprintf(fid1,'%s %s\n', char(preM(z(4))), char(preM(z(3))));
%fprintf(fid1,'%s %s\n', char(preM(z(4))), char(preM(z(2))));


%PsychPortAudio('Stop',MySoundHandle);
%PsychPortAudio('Close',MySoundHandle);

