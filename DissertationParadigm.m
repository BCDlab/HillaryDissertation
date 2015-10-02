function y = DissertationParadigm()
%% Initial set-up
clc;
clear;

if usejava('System.time')
    disp('error loading java package "System.time"');
    return;
end
if usejava('java.util.LinkedList')
    disp('error loading java package "java.util.LinkedList"');
    return;
end
try
    AssertOpenGL;
    
    % Prompt box for subnum and counterbalance; creates variables for these
    prompt = {'Subject Number','Counterbalance'};
    defaults = {'1','1'};
    answer = inputdlg(prompt,'Subnum',1,defaults);
    if(size(answer) ~= 2)
        clear;
        clc;
        disp('Exiting.');
        return;
    end
    
    Priority(2);
    [subject,counterbalance] = deal(answer{:});

    rng('Shuffle'); 
    fid = fopen('Subinfo.txt','a+');

    % odd or even counterbalance
    if mod(str2double(counterbalance(end)),2) == 0
        isEven = true;
    else
        isEven = false;
    end

    counterbalance = str2double(counterbalance);
      
    % Set stimuli directories for each species (to present images)
    Macaques = dir(fullfile('/Images/Macaques/','*.png'));
    Capuchins = dir(fullfile('/Images/Capuchins/','*.png'));

    % Set stimuli directory for audio files
    Labels = dir(fullfile('/Audio','*.wav'));
    Noise = dir(fullfile('/Audio','Noise.wav'));

    % Read in text files for stim lists
    [MacaqueNames] = textread('Lists/Stimuli.txt','%s'); %#ok<*REMFF1>
    [CapuchinNames] = textread('Lists/Stimuli.txt','%s'); %#ok<*REMFF1>

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
    Screen('Preference', 'SkipSyncTests', 0);
    screennum = 0;
    white = WhiteIndex(screennum);
    gray = GrayIndex(screennum);
    black = BlackIndex(screennum);
    [w, wRect] = Screen('OpenWindow',screennum,gray);
    Screen(w,'BlendFunction',GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
    fps = 75;
    hz=Screen(screennum,'FrameRate',[], fps);

    % Set up for ssVEP size variation
    xsize = 400;
    ysize = 550;
    x = 0; % Drawing position relative to center
    y = 0;
    x0 = wRect(3)/2; % Screen center
    y0 = wRect(4)/2;
    sizevary = [.90,.94,.98,1.02,1.06,1.10];


    %% Run through the tasks in the correct order
    nTask = 3;
    nSpecies = 2;
    nStimuli = 4;
    TimessVEP = 10; % seconds
    FreqssVEP = 5.88; % Hz
    nTrialssVEP = 10; % number of ssVEP trials - 1
    nTrialsERP = 60; % number of ERP training trials  - 3
    nImagesssVEP = floor(TimessVEP*FreqssVEP); % floor stops presenting at an image instead of half an image or something

    nAlpha = 5;  % the amount of different alpha values to be presented per stimuli; currently set (sort of arbitrarily to 30)
    framesPerStimuli = floor(1 / (FreqssVEP * nAlpha));  % calculate the exact number of frames per stimulus
    waitTime = 0;
    
    milli = 1000000;   % one millisecond
    nMillis = 2;
%     secs = 1 / (FreqssVEP * nStimuli * nAlpha);
%     secs = .0099;
    
    
    % initialize stimuli for ssVEP tasks
    import java.util.LinkedList;
    presStims1 = LinkedList();
    presStims2 = LinkedList();
    
    destrect1 = LinkedList();
    destrect2 = LinkedList();
    
%% Preload the stimuli for ssVEP tasks

    Screen('DrawText', w, 'Preparing stimuli', x0 - 110, y0, black, gray);
    [standon] = Screen('Flip', w);
    
    for Task=1:nTask
        for Species=1:nSpecies
            if isEven == true % If subnum is even, Capuchins first
                if Species==1
                    thisSpecies = Capuchins;
                    speciesName = 'Capuchins';
                    thisTask = CapuchinList(:,Task);
                elseif Species>=2
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
                     destrect1.add(destrect);  
                      if mod(image,5) ~= 0 % checks if remainder is divisible by 5; if not, present standard
                           
                           st = char(standardshow);
                           showstring = '';
                           luminancevalue = randi(9); %Make the image a random luminance
                           switch luminancevalue
                                case 1
                                    lumstring = '+40';
                                case 2
                                    lumstring = '+30';
                                case 3
                                    lumstring = '+20';
                                case 4
                                    lumstring = '+10';
                                case 5
                                    lumstring = '+0';
                                case 6
                                    lumstring = '-10';
                                case 7
                                    lumstring = '-20';
                                case 8
                                    lumstring = '-30';
                                case 9
                                    lumstring = '-40';
                           end    
                           if st(2) == '.'
                               showstring = st(1);
                           else
                               showstring = st(1:2);
                           end

                           filename = strjoin({'Images', speciesName, strcat(showstring, lumstring, '.png')}, '/');
                           
                           presStims1.add(filename);

                       elseif mod(image,5) == 0 % if remainder is divisible by 5, present oddball
                           newoddball = randi(4);
                           while newoddball == oddball || newoddball == standard
                               newoddball = randi(4);
                           end
                           oddball = newoddball;
                           oddballshow = thisTask(newoddball);
                           
                           st = char(oddballshow);
                           showstring = '';
                           if st(2) == '.'
                               showstring = st(1);
                           else
                               showstring = st(1:2);
                           end
                           luminancevalue = randi(9); %Make the image a random luminance
                           switch luminancevalue 
                                case 1
                                    lumstring = '+40';
                                case 2
                                    lumstring = '+30';
                                case 3
                                    lumstring = '+20';
                                case 4
                                    lumstring = '+10';
                                case 5
                                    lumstring = '+0';
                                case 6
                                    lumstring = '-10';
                                case 7
                                    lumstring = '-20';
                                case 8
                                    lumstring = '-30';
                                case 9
                                    lumstring = '-40';
                           end    
                           filename = strjoin({'Images', speciesName, strcat(showstring, lumstring, '.png')}, '/');
                           
                           presStims1.add(filename);
                           
                       end    
                   end
                   
                   
                   Screen('Close'); % Supposed to clean up old textures
                   fprintf(fid,'%s\t%d\t%d\t%d\t%s\n',subject,counterbalance,Task,Trial,char(standardshow));
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
                     destrect2.add(destrect);
                      if mod(image,5) ~= 0 % checks if remainder is divisible by 5; if not, present standard
                           
                           s = char(standardshow);
                           showstring = '';
                           if s(2) == '.'
                               showstring = s(1);
                           else
                               showstring = s(1:2);
                           end

                           filename = strjoin({'Images', speciesName, strcat(showstring, '.png')}, '/');
    
                           presStims2.add(filename);

                       elseif mod(image,5) == 0 % if remainder is divisible by 5, present oddball
                           newoddball = randi(4);
                           while newoddball == oddball || newoddball == standard
                               newoddball = randi(4);
                           end
                           oddball = newoddball;
                           oddballshow = thisTask(newoddball);
                           
                           s = char(oddballshow);
                           showstring = '';
                           if s(2) == '.'
                               showstring = s(1);
                           else
                               showstring = s(1:2);
                           end
                           
                           filename = strjoin({'Images', speciesName, strcat(showstring, '.png')}, '/');
                           
                           presStims2.add(filename);
                           
                       end    
                   end
               end
            end
        end
    end
    
    ssVEPStims1 = presStims1.clone();
    ssVEPStims2 = presStims2.clone();
    
    Screen('DrawText', w, 'Finished preparing stimuli, press any key to begin', x0 - 400, y0, black, gray);
    [standon] = Screen('Flip', w);

    KbWait([], 2);    % postpone the presentation of the stimuli until any key is pressed
    KbEventFlush;
    Screen(w, 'FillRect', gray);
    [standon] = Screen('Flip', w);

%% Begin Executing Tasks
   disimagedata1 = imread(char('Images/Distractors/d2.bmp'));
   disimagedata2 = imread(char('Images/Distractors/d4.bmp'));
   
   KbQueueCreate()
    newSec = GetSecs;
    initialTime = GetSecs;    
    
    imageCount = 0;
    
    times = LinkedList();
    %saveDiName = sprintf('sub%dCommandLog.txt',subject);
    %diary(saveDiName)
    %diary on
    Task = 1;
    
    for stim=1 : nSpecies
        if (stim == 1 && isEven == false) || (stim == 2 && isEven == true)
            speciesName = 'Macaques';
        elseif (stim == 1 && isEven == true) || (stim == 2 && isEven == false)
            speciesName = 'Capuchins';
        end
        for Trial=1:nTrialssVEP
         Screen(w, 'FillRect', gray);  % makes the back buffer blank
         [standon] = Screen('Flip', w); % flips the back and front buffer
         %[buttons] = GetClicks(w); % Listens for mouseclicks
         switch speciesName %Change the event label based on species
          case 'Macaques'
           label = 'm11';
          case 'Capuchins' 
           label = 'c12';
         end
%          soundfilerand = randi(2);
%           switch soundfilerand
%               case 1
%                dissoundfile = 's4.wav';
%               case 2
%                dissoundfile = 's6.wav';    
%           end
          dissoundfile = 'Audio/Distractors/s6.wav';
          InitializePsychSound;
          Channels = 1;
          %MySoundFreq = 11025;
           MySoundFreq = 32000;
          %           disp(dissoundfile)
          diswavdata = transpose(wavread(dissoundfile));
          MySoundHandle = PsychPortAudio('Open',[],[],0,MySoundFreq,Channels);
          FinishTime1 = length(diswavdata)/MySoundFreq;
          PsychPortAudio('FillBuffer',MySoundHandle,diswavdata,0);
           %gives chance to use distractors by looking until mouse click
         [keyIsDown] = KbCheck(); %Listens for Keypresses
         [xpos,ypos,buttons] = GetMouse();
          while ~any(buttons) % Loops while no mouse buttons are pressed
              [keyIsDown] = KbCheck();
              [xpos,ypos,buttons] = GetMouse();
               if any(keyIsDown)
                    disrand = char(randi(2));
%                     switch disrand
%                         case 1
%                             disimage = Screen('MakeTexture',w,disimagedata1);
%                         case 2
%                             disimage = Screen('MakeTexture',w,disimagedata2);    
%                     end 
                    disimage = Screen('MakeTexture',w,disimagedata2);
%                     disp(keyIsDown)
                    
                    %Screen('DrawTexture',w,mytex);
                    Screen('DrawTexture',w,disimage);
                    Screen('Flip',w);
                    PsychPortAudio('Start',MySoundHandle,1,0,1);
                     %PsychPortAudio('Start',MySoundHandle,1,0,1);
                     
                    WaitSecs(FinishTime1);
        %                                     while 1 < 2 %Endless Loop
        %                                      KbEventFlush;   
        %                                     [xpos,ypos,buttons] = GetMouse(w);
        %                                         if any(keyIsDown) %Break the loop
        %                                             break
        %                                         end
        %                                         
        %                                     end
        %                                    
                   Screen(w, 'FillRect', gray);
                   Screen('Flip',w);
                   WaitSecs(.01);
                   KbEventFlush;
               end
   
          end
          KbEventFlush
          
          %if any(buttons) % Present images on mouseclick
           
           
           NetStation('Event',label, GetSecs, 0.001, 'trl#',Trial,'species',speciesName); % signals the beginning of a trial
           for image=1:nImagesssVEP
               destrect = destrect1.remove();
               if mod(image,5) ~= 0 % checks if remainder is divisible by 5; if not, present standard
                   
                   imageCount = imageCount + 1;
                   imdata = imread(char(presStims1.remove()));
                   mytex = Screen('MakeTexture', w, imdata);

                   for curAlpha = 0 : nAlpha
                      Screen('DrawTexture', w, mytex, [], destrect, [], [], curAlpha / nAlpha);
                      [standon] = Screen('Flip', w);
%                       if curAlpha / nAlpha == 1
%                         NetStation('Event','a100',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);
%                       elseif curAlpha / nAlpha == 0
%                         NetStation('Event','a000',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);  
%                       end
                      javaMethod('parkNanos', 'java.util.concurrent.locks.LockSupport', floor(milli * nMillis));
                   end
                   for curAlpha = 1 : nAlpha - 1
%                       if curAlpha / nAlpha == 1
%                         NetStation('Event','a100',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);
%                       elseif curAlpha / nAlpha == 0
%                         NetStation('Event','a000',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);
%                       end  
                      Screen('DrawTexture', w, mytex, [], destrect, [], [], 1 - (curAlpha / nAlpha));
                      [standon] = Screen('Flip', w);
                      javaMethod('parkNanos', 'java.util.concurrent.locks.LockSupport', floor(milli * nMillis));
                   end

                   oldTime = newSec;
                   newSec = GetSecs;
                   times.add(newSec - oldTime);


               elseif mod(image,5) == 0      % if remainder is divisible by 5, present oddball

                   imageCount = imageCount + 1;
                   
                   imdata = imread(char(presStims1.remove()));
                   %disp(char(presStims1.remove())) %Checking to make sure
                   %the luminance is changing
                   mytex = Screen('MakeTexture', w, imdata);

                   for curAlpha = 0 : nAlpha

                      Screen('DrawTexture', w, mytex, [], destrect, [], [], curAlpha / nAlpha);
                      [standon] = Screen('Flip', w);
%                       if curAlpha / nAlpha == 1
%                         NetStation('Event','a100',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);
%                       elseif curAlpha / nAlpha == 0
%                         NetStation('Event','a000',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);
%                       end  
  
                      javaMethod('parkNanos', 'java.util.concurrent.locks.LockSupport', floor(milli * nMillis));
                   end
                   for curAlpha = 1 : nAlpha - 1

                      Screen('DrawTexture', w, mytex, [], destrect, [], [], 1 - (curAlpha / nAlpha));
                      [standon] = Screen('Flip', w);
%                       if curAlpha / nAlpha == 1
%                         NetStation('Event','a100',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);
%                       elseif curAlpha / nAlpha == 0
%                         NetStation('Event','a000',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);
%                       end  
  
                      javaMethod('parkNanos', 'java.util.concurrent.locks.LockSupport', floor(milli * nMillis));
                   end

                   oldTime = newSec;
                   newSec = GetSecs;
                   times.add(newSec - oldTime);

               end    
            end
          %end
          Screen('Close'); % Supposed to clean up old textures
        end

       
       fprintf(fid,'%s\t%d\t%d\t%s\t%d\t%s\n',subject,counterbalance,Task,speciesName,Trial,char(standardshow));
    end
    
    while(~times.isEmpty())
%         disp(times.pop());
        times.pop();
    end
    
   % display some data for now ... DELETE LATER
   finalTime = GetSecs;
   disp('Final Time: ');
   disp(finalTime - initialTime);
   disp('Average Time: ');
   disp((finalTime - initialTime) / imageCount);
   KbQueueCreate(0)
   
   %% TASK 2
   Task = 2;
   Trial = 1;
   disimagedata1 = imread(char('Images/Distractors/d2.bmp'));
   disimagedata2 = imread(char('Images/Distractors/d3.bmp'));
   
    for Species=1:nSpecies           
           InitializePsychSound;
           MySoundFreq = 96000;
           Channels = 1;
           face = -1; % initially sets to something impossible
           countfortag = 1; 
           stimSetCount = 1;
           faceOrder = {-1, -1, -1, -1};
           for Trial=1:nTrialsERP
            
            if (isEven == true && Species == 1) || (isEven == false && Species == 2)
                monkeyspecies = 'Capuchin';
                speciesName = 'Capuchins';
            elseif (isEven == true && Species == 2) || (isEven == false && Species == 1)
                monkeyspecies = 'Macaque';
                speciesName = 'Macaques';
            end
            if (counterbalance == 1 && Species == 1 || counterbalance == 2 && Species == 1) || (counterbalance == 3 && Species == 2 || counterbalance == 4 && Species == 2)
                labeltype = 'Label';
            elseif (counterbalance == 1 && Species == 2 || counterbalance == 2 && Species == 2) || (counterbalance == 3 && Species == 1 || counterbalance == 4 && Species == 1)
                labeltype = 'Noise';
            end
               if strcmp('Macaque',monkeyspecies)
                   whowent = '1';
               else
                   whowent = '2';
                 
               end    
               switch labeltype %Changing the tag for the label type
                   case 'Label'
                       orglabel = 'l90';
                       soundlabel = strcat(orglabel,whowent);
                   case 'Noise'
                       orglabel = 'n91';
                       soundlabel = strcat(orglabel,whowent);
               end
               
               % pick a new random grouping of four stimuli every four
               % presentations
               if stimSetCount == 1
                   lastFacePresented = faceOrder{4};
                   faceOrder = {-1, -1, -1, -1};
                   usedList = LinkedList();
                   for faceIndex = 1 : 4
                       newface = randi(4);
                       while usedList.contains(newface)
                           newface = randi(4);
                       end
                       if faceIndex == 1
                           while newface == lastFacePresented
                               newface = randi(4);
                           end
                       end
                       faceOrder{faceIndex} = newface;
                       usedList.add(newface);
                   end
               end
               
               face = faceOrder{stimSetCount};
               faceshow = thisTask(faceOrder{stimSetCount});
               stimSetCount = stimSetCount + 1;
               if stimSetCount > 4
                   stimSetCount = 1;
               end
               
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

               % disp(faceshow); % Use to check output of filenames

               curFile = '';
               curStr = char(faceshow(1));
               if length(char(faceshow(1))) == 5
                   curFile = curStr(1);
               end
               if length(char(faceshow(1))) == 6
                   curFile = curStr(1:2);
               end
               soundfilerand = randi(2);
               switch soundfilerand
                   case 1
                    dissoundfile = 'Audio/Distractors/s4.wav';
                   case 2
                    dissoundfile = 'Audio/Distractors/s5.wav';    
               end        
               MySoundFreq = 11025;
%                disp(dissoundfile)
               diswavdata = transpose(wavread(dissoundfile));
               MySoundHandle = PsychPortAudio('Open',[],[],0,MySoundFreq,Channels);
               PsychPortAudio('FillBuffer',MySoundHandle,diswavdata,0);
               filename = strjoin({'Images',speciesName,strcat(curFile, '.png')}, '/');

               % disp(filename);
               imdata = imread(char(filename));
               mytex = Screen('MakeTexture',w,imdata);

               [X,Y] = RectCenter(wRect); % Centers fixation cross
               FixCross = [X-1,Y-20,X+1,Y+20;X-20,Y-1,X+20,Y+1]; % Fixation cross size
               Screen('FillRect', w, [0,0,0], FixCross');
               %Screen('FillRect', w, [0,0,0], [100,100,200,300]);
               Screen('Flip',w);
               s3 = GetSecs;
               NetStation('Event','fix+',s3,0.001,'trl#',Trial);
               [xpos,ypos,buttons] = GetMouse(w);
               while any(buttons) == 0 %gives chance to use distractors by looking until mouse click

                   [keyIsDown] = KbCheck(); %Listens for Keypresses
                   [xpos,ypos,buttons] = GetMouse(w);
                   if any(keyIsDown)
                            disrand = char(randi(2));
                            switch disrand
                                case 1
                                disimage = Screen('MakeTexture',w,disimagedata1);
                                case 2
                                disimage = Screen('MakeTexture',w,disimagedata2);    
                            end        
%                             disp(keyIsDown)
                            KbEventFlush;
                            %Screen('DrawTexture',w,mytex);
                            Screen('DrawTexture',w,disimage);
                            Screen('Flip',w);
                            PsychPortAudio('Start',MySoundHandle,1,0,1);
                            [xpos,ypos,buttons] = GetMouse(w);
                            WaitSecs(1.5);
%                                     while 1 < 2 %Endless Loop
%                                      KbEventFlush;   
%                                     [xpos,ypos,buttons] = GetMouse(w);
%                                         if any(keyIsDown) %Break the loop
%                                             break
%                                         end
%                                         
%                                     end
%                                    
                   Screen('FillRect', w, [0,0,0], FixCross');
                   Screen('Flip',w);
                   WaitSecs(.01);
                   end
               end    
                KbEventFlush;

               [xpos,ypos,buttons] = GetMouse(w); % Waits for mouseclicks. same as KbWait

               MySoundFreq = 96000;
               MySound = strjoin({'Audio',char(LabelPlay(1))},'/');
               MySoundData = transpose(wavread(MySound));
               FinishTime = length(MySoundData)/MySoundFreq;
               MySoundHandle = PsychPortAudio('Open',[],[],0,MySoundFreq,Channels);
               PsychPortAudio('FillBuffer',MySoundHandle,MySoundData,0);

                  if any(buttons) % Present image on mouseclick
                   Screen('DrawTexture',w,mytex);
                   %Screen('FillRect',w,[255,255,255],[100,100,200,300]);
                   [stimOn] = Screen('Flip',w);
                   NetStation('Event',soundlabel,stimOn,0.001,'trl#',Trial,'monk',monkeyspecies,'name',face,'labl',labeltype);
                   startTime = PsychPortAudio('Start',MySoundHandle,1,0,1); % Jitter onset time between 10-300ms post-face onset
                   WaitSecs(FinishTime);
                   Screen('Flip',w);  
                   s2 = GetSecs;
                   NetStation('Event','stm-',s2,0.001);
                   countfortag = countfortag +1;
%                    disp(countfortag)
                  end  
               WaitSecs((rand() / 5.0) + 0.5);
               Screen('Close');
               PsychPortAudio('Close');
               disp('close')
               fprintf(fid,'%s\t%d\t%d\t%d\t%s\t%s\t%s\n',subject,counterbalance,Task,Trial,char(faceshow),monkeyspecies,labeltype);
           end                 
    end
    
    %% TASK 3
    
    Task = 3;
    
    for stim=1 : nSpecies
      if (stim == 1 && isEven == false) || (stim == 2 && isEven == true)
          speciesName = 'Macaques';
      elseif (stim == 1 && isEven == true) || (stim == 2 && isEven == false)
          speciesName = 'Capuchins';
      end
      switch speciesName %Change the event label based on species
          case 'Macaques'
           label = 'm21';
          case 'Capuchins' 
           label = 'c22';
      end 
%       soundfilerand = randi(2);
%           switch soundfilerand
%               case 1
%                dissoundfile = 's4.wav';
%               case 2
%                dissoundfile = 's6.wav';    
%           end
%           InitializePsychSound;
        disimagedata2 = imread(char('Images/Distractors/d4.bmp'));
        dissoundfile = 'Audio/Distractors/s6.wav';
          Channels = 1;
          MySoundFreq = 32000;
%           disp(dissoundfile)
          diswavdata = transpose(wavread(dissoundfile));
          MySoundHandle = PsychPortAudio('Open',[],[],0,MySoundFreq,Channels);
          FinishTime2 = length(diswavdata)/MySoundFreq;
          PsychPortAudio('FillBuffer',MySoundHandle,diswavdata,0);
        for Trial=1:nTrialssVEP
          Screen(w, 'FillRect', gray);  % makes the screen blank
          [standon] = Screen('Flip', w);
          [xpos,ypos,buttons] = GetMouse(); % Listens for mouseclicks
          while ~any(buttons) %gives chance to use distractors by looking until mouse click
               [keyIsDown] = KbCheck(); %Listens for Keypresses
               [xpos,ypos,buttons] = GetMouse(w);
               if any(keyIsDown)
%                         disrand = char(randi(2));
%                         switch disrand
%                             case 1
%                             disimage = Screen('MakeTexture',w,disimagedata1);
%                             case 2
%                             disimage = Screen('MakeTexture',w,disimagedata2);    
%                         end   
                   disimage = Screen('MakeTexture',w,disimagedata2);
%                         disp(keyIsDown)
                        KbEventFlush;
                        %Screen('DrawTexture',w,mytex);
                        Screen('DrawTexture',w,disimage);
                        Screen('Flip',w)
                        PsychPortAudio('Start',MySoundHandle,1,0,1);
                        
                        WaitSecs(FinishTime2)
    %                                     while 1 < 2 %Endless Loop
    %                                      KbEventFlush;   
    %                                     [xpos,ypos,buttons] = GetMouse(w);
    %                                         if any(keyIsDown) %Break the loop
    %                                             break
    %                                         end
    %                                         
    %                                     end
    %                                    
               %Screen('FillRect', w, [0,0,0], FixCross');
               Screen('Flip',w);
               WaitSecs(.01)
               end
          end           
          
              
            NetStation('Event',label, GetSecs, 0.001, 'trl#',Trial,'species',speciesName); % signals the beginning of a trial
            for image=1:nImagesssVEP
               destrect = destrect2.remove();
               if mod(image,5) ~= 0 % checks if remainder is divisible by 5; if not, present standard
                   
                   imageCount = imageCount + 1;

                   imdata = imread(char(presStims2.remove()));
                   mytex = Screen('MakeTexture', w, imdata);

                   for curAlpha = 0 : nAlpha

                      Screen('DrawTexture', w, mytex, [], destrect, [], [], curAlpha / nAlpha);
                      [standon] = Screen('Flip', w);
%                       if curAlpha / nAlpha == 1
%                         NetStation('Event','a100',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);
%                       elseif curAlpha / nAlpha == 0
%                         NetStation('Event','a000',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);  
%                       end
                      javaMethod('parkNanos', 'java.util.concurrent.locks.LockSupport', floor(milli * nMillis));
                   end
                   for curAlpha = 1 : nAlpha - 1
                      Screen('DrawTexture', w, mytex, [], destrect, [], [], 1 - (curAlpha / nAlpha));
%                       if curAlpha / nAlpha == 1
%                         NetStation('Event','a100',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);
%                       elseif curAlpha / nAlpha == 0
%                         NetStation('Event','a000',standon,0.001,'trl#',Trial,'monk',speciesName,'alpha#',curAlpha / nAlpha);  
%                       end                      
                      [standon] = Screen('Flip', w);
                      javaMethod('parkNanos', 'java.util.concurrent.locks.LockSupport', floor(milli * nMillis));
                   end

                   oldTime = newSec;
                   newSec = GetSecs;

                   times.add(newSec - oldTime);


               elseif mod(image,5) == 0      % if remainder is divisible by 5, present oddball

                   imageCount = imageCount + 1;
                   
                   imdata = imread(char(presStims2.remove()));
                   mytex = Screen('MakeTexture', w, imdata);

                   for curAlpha = 0 : nAlpha

                      Screen('DrawTexture', w, mytex, [], destrect, [], [], curAlpha / nAlpha);
                      [standon] = Screen('Flip', w);
                      javaMethod('parkNanos', 'java.util.concurrent.locks.LockSupport', floor(milli * nMillis));
                   end
                   for curAlpha = 1 : nAlpha - 1

                      Screen('DrawTexture', w, mytex, [], destrect, [], [], 1 - (curAlpha / nAlpha));
                      [standon] = Screen('Flip', w);
                      javaMethod('parkNanos', 'java.util.concurrent.locks.LockSupport', floor(milli * nMillis));
                   end

                   oldTime = newSec;
                   newSec = GetSecs;
                   times.add(newSec - oldTime);

               end    
           end
           Screen('Close'); % Supposed to clean up old textures
          
        end

       fprintf(fid,'%s\t%d\t%d\t%d\t%s\n',subject,counterbalance,Task,Trial,char(standardshow));
    end
    
    while(~times.isEmpty())
%         disp(times.pop());
            times.pop();
    end
               
    NetStation('Synchronize');
    NetStation('StopRecording');
    NetStation('Disconnect', DAC_IP);

     % End screen
    ThankYou = imread(char('d2.bmp'));
    disThankYou = Screen('MakeTexture',w,ThankYou);
    Screen('DrawTexture',w,disThankYou);
    Screen('Flip',w);
    
     %Listens for Keypresses
    [xpos,ypos,buttons] = GetMouse();
     while ~any(buttons) % Loops while no mouse buttons are pressed
          [keyIsDown] = KbCheck();
          [xpos,ypos,buttons] = GetMouse();
           if any(keyIsDown)
               Screen('CloseAll');
           end
     end
    
    %PsychPortAudio('Stop',MySoundHandle);
    %PsychPortAudio('Close',MySoundHandle);
    
    Priority(1);  %reset the priority
    
    % clc;    % clear the screen
    clear;  % clear the workspace

    disp('Process complete.');


catch
    Screen('CloseAll');
    ShowCursor;
    Priority(0);
    
    psychrethrow(psychlasterror);
end