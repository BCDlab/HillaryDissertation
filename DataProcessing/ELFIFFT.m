function [] = ELFIFFT()
%         averager( ALLEEG , 'Criterion', 1, 'DSindex',  5, 'Stdev', 'on');

    % Prompt the user for the condition and channels with default values
    prompt = {'Condition','Channels'};
    defaults = {'LabelPre','75'};
    promptResponse = inputdlg(prompt,'Condition',1,defaults);
    [condition, channels] = deal(promptResponse{:});

    % Prompt the user for the path to the .set files and find all of that
    % directory's .set files. Also store the number of subjects
    directory = uigetdir(pwd);
    pattern = fullfile(directory,'*.set');
    allFilesInDirectory = dir(pattern);
    setFiles = removeDotUnderscores(allFilesInDirectory);
    numSubjects = size(setFiles); 
    
    % Find the average
    for subjectIndex = 1 : 1
        EEG = pop_loadset('filename', setFiles{subjectIndex}, 'filepath', directory);
        concatenatedEEGs(subjectIndex, :) = EEG;
%         [ym, f] = fourieeg(EEG,channels,[],0,7);
%         CombinedFiles(subjectIndex,:) = ym;
    end
    
    disp(EEG.data);
    
    save subject.mat
    
%     for i = 1 : 6500
%         disp(EEG.data(1, i, 1));
%     end



%     [ym, f] = fourieeg(concatenatedEEGs,channels,[],0,7);
%     CombinedFiles(subjectIndex,:) = ym;
% 
%     AveResponse = mean(CombinedFiles,1);
% 
%     BaseSignal = AveResponse(100); % Bin 100 is 6.04
%     bnoise = [AveResponse(90:99),AveResponse(101:110)];
%     BaseNoise = mean(bnoise);
%     BaseRatio = BaseSignal/BaseNoise;
%     BaseSNR = mean(BaseRatio);
% 
%     OddSignal = AveResponse(21); % Bin 21 is 1.22
%     onoise = [AveResponse(11:20),AveResponse(22:31)];
%     OddNoise = mean(onoise);
%     OddRatio = OddSignal/OddNoise;
%     OddSNR = mean(OddRatio);
% 
%     disp(BaseSNR);
%     disp(OddSNR);
% 
%     plot(f,AveResponse);
%     % axis([1 7 0 35]); % Change the last number to adjust y-scale
%     xlim([1 7]);
%     ylim auto
%     xlabel('Frequency (Hz)')
%     ylabel('Y(f)')
%     title('Concatenated')
    
%     save test.mat;
end

function fileNames = removeDotUnderscores(setFiles)
    setFilesWithoutDotUnderscores = cell(size(setFiles));
    newArrayIndex = 1;
    for index = 1 : size(setFiles)
        if ~strcmp(setFiles(index).name(1:2), '._')
            setFilesWithoutDotUnderscores{newArrayIndex} = setFiles(index).name;
            newArrayIndex = newArrayIndex + 1;
        end
    end
    
    emptyCellCount = countEmptyCells(setFilesWithoutDotUnderscores);
    fileNames = cell(size(setFilesWithoutDotUnderscores) - emptyCellCount);
    fileNameIndex = 1;
    for index = 1 : size(setFilesWithoutDotUnderscores)
        if ~isempty(setFilesWithoutDotUnderscores{index})
            fileNames{fileNameIndex} = setFilesWithoutDotUnderscores(index);
            fileNameIndex = fileNameIndex + 1;
        end
    end
    
    fileNames = fileNames';
end

function numberOfEmptyCells = countEmptyCells(cellArray)
    numberOfEmptyCells = 0;
    for index = 1 : size(cellArray)
        if isempty(cellArray{index})
            numberOfEmptyCells = numberOfEmptyCells + 1;
        end
    end
end
