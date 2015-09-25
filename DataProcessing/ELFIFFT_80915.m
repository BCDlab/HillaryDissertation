function [] = ELFIFFT_80915()

    %numberofsub = input('How many subjects are we averaging today (Must start at 1 through that number)');

    prompt = {'Condition','Channels'};
    defaults = {'LabelPre','75'};
    answer = inputdlg(prompt,'Condition',1,defaults);

    [condition, channels] = deal(answer{:});

    folder = uigetdir;

    sublist = {'2','4','6','8','9','10', '14'}; % Currently need to adjust by hand based on what subnums are in a specific folder
    numberofsub = length(sublist);


    for i = 1:numberofsub
        filename = strcat('ELFI_',(sublist(i)),'_9_',condition,'.set');
        EEG = pop_loadset('filename',filename,'filepath',folder);
        [ym, f] = fourieeg(EEG,channels,[],0,7);
        CombinedFiles(i,:) = ym;
    end    

    AveResponse = mean(CombinedFiles,1);
    % disp(AveResponse(4));
    % disp(AveResponse(5));
    % disp(AveResponse(6));
    % disp(AveResponse(83));
    % disp(AveResponse(84));
    % disp(AveResponse(85));

    BaseSignal = AveResponse(100); % Bin 100 is 6.04
    bnoise = [AveResponse(90:99),AveResponse(101:110)];
    BaseNoise = mean(bnoise);
    BaseRatio = BaseSignal/BaseNoise;
    BaseSNR = mean(BaseRatio);

    OddSignal = AveResponse(21); % Bin 21 is 1.22
    onoise = [AveResponse(11:20),AveResponse(22:31)];
    OddNoise = mean(onoise);
    OddRatio = OddSignal/OddNoise;
    OddSNR = mean(OddRatio);

    disp(BaseSNR);
    disp(OddSNR);

    plot(f,AveResponse);
    % axis([1 7 0 35]); % Change the last number to adjust y-scale
    xlim([1 7]);
    ylim auto
    xlabel('Frequency (Hz)')
    ylabel('Y(f)')
end