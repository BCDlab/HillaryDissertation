Labels = dir(fullfile('C:\Users\Hillz\Desktop\DissertationParadigm\Audio','*.wav'));
[LabelNames] = textread('C:\Users\Hillz\Desktop\DissertationParadigm\Labels.txt','%s');
nLabels = length(LabelNames);
RandLabels = randperm(nLabels);
LabelShuffle = LabelNames(RandLabels);


nPlays = 4;

InitializePsychSound;
MySoundFreq = 32000;
Channels = 1;

for i = 1:nPlays
    Label = randi(4);
    LabelPlay = LabelShuffle(Label);
    MySound = strjoin({'Audio',char(LabelPlay(1))},'/');
    MySoundData = transpose(wavread(MySound));
    FinishTime = length(MySoundData)/MySoundFreq;
    MySoundHandle = PsychPortAudio('Open',[],[],0,MySoundFreq,Channels);
    PsychPortAudio('FillBuffer',MySoundHandle,MySoundData,0);
    startTime = PsychPortAudio('Start',MySoundHandle,1,0,1);
    WaitSecs(FinishTime);
end
%PsychPortAudio('Stop',MySoundHandle);
%PsychPortAudio('Close',MySoundHandle);