function getSenseSettingsInDeviceSettingsStructure(DeviceSettings,senseSettings)

%% print raw device settings strucutre 
clc
printRawDeviceSettings = 1;
if printRawDeviceSettings
    for f = 1:length(DeviceSettings)
        curStr = DeviceSettings{f};
        fieldnames1 = fieldnames(curStr);
        fprintf('[%0.3d]\n',f);
        for f1 = 1:length(fieldnames1)
            fprintf('\t%s\n',fieldnames1{f1});
            curStr2 = curStr.(fieldnames1{f1});
            if isstruct(curStr2)
                fieldnames2 = fieldnames(curStr2);
                for f2 = 1:length(fieldnames2)
                    fprintf('\t\t%s\n',fieldnames2{f2});
                end
            end
        end
        fprintf('\n');
    end
end
%%
recNum = 1; 
senseSettings.action{1} = 'sense config';
senseSettings.recNum(1) = NaN;
tdData = translateTimeDomainChannelsStruct(senseSettings.TimeDomainDataStruc{1});

f = 2; % start with the second structure 
strCnt = 1; 
strmStopCnt = 1; 
senseStopCnt = 1; 
instream = 0;
while f <= length(DeviceSettings)
    fnms = fieldnames(DeviceSettings{f});
    curStr = DeviceSettings{f};
    if isfield(curStr,'SensingConfig')
        if isfield(curStr.SensingConfig,'timeDomainChannels')
            tdData = translateTimeDomainChannelsStruct(curStr.SensingConfig.timeDomainChannels);
            timenum = curStr.RecordInfo.HostUnixTime;
            t = datetime(timenum/1000,'ConvertFrom','posixTime','TimeZone','America/Los_Angeles','Format','dd-MMM-yyyy HH:mm:ss.SSS');
            outRec(recNum).timeStart = t;
            outRec(recNum).unixtimeStart  = timenum;
            outRec(recNum).tdData = tdData;
            senseSettings.action{recNum} = 'sense config';
            senseSettings.recNum(recNum) = NaN;
            senseSettings.timeStart{recNum} = t;
            for c = 1:4
                fnuse = sprintf('chan%d',c);
                senseSettings.(fnuse){recNum} = tdData(c).chanFullStr;
            end
            senseSettings.tdDataStruc{recNum} = tdData;
            recNum = recNum + 1;
        end
    end
    % check if streaming started 
    if isfield(curStr,'StreamState')
        if curStr.StreamState.TimeDomainStreamEnabled
            if ~instream % if not instream then streaming is starting 
                timenum = curStr.RecordInfo.HostUnixTime;
                t = datetime(timenum/1000,'ConvertFrom','posixTime','TimeZone','America/Los_Angeles','Format','dd-MMM-yyyy HH:mm:ss.SSS');
                actionuse = sprintf('stream start %d',strCnt);
                senseSettings.action{recNum} = actionuse;
                senseSettings.recNum(recNum) = strCnt;
                senseSettings.timeStart{recNum} = t;
                for c = 1:4
                    fnuse = sprintf('chan%d',c);
                    senseSettings.(fnuse){recNum} = tdData(c).chanFullStr;
                end
                senseSettings.tdDataStruc{recNum} = tdData;
                strCnt = strCnt + 1;
                recNum = recNum + 1;
                instream = 1;
            end
        end 
    end
    % check if streaming stopped - 
    % it can either be stopped by turning streaming off 
    % or it can be stopped by turning sensing off 
    % option 1 - stream has been turned off 
    if isfield(curStr,'StreamState')
        if instream % streaming is happening detect it's stop
            if ~curStr.StreamState.TimeDomainStreamEnabled
                timenum = curStr.RecordInfo.HostUnixTime;
                t = datetime(timenum/1000,'ConvertFrom','posixTime','TimeZone','America/Los_Angeles','Format','dd-MMM-yyyy HH:mm:ss.SSS');
                actionuse = sprintf('stop stream %d',strmStopCnt);
                senseSettings.action{recNum} = actionuse;
                senseSettings.recNum(recNum) = strmStopCnt;
                senseSettings.timeStart{recNum} = t;
                for c = 1:4
                    fnuse = sprintf('chan%d',c);
                    senseSettings.(fnuse){recNum} = tdData(c).chanFullStr;
                end
                senseSettings.tdDataStruc{recNum} = tdData;
                instream = 0;
                strmStopCnt = strmStopCnt + 1;
                recNum = recNum + 1;
            end
        end
    end
    % option 2 sense has been turned off 
    if isfield(curStr,'SenseState')
        if instream % streaming is happening detect it's stop
            if isfield(curStr.SenseState,'state')
                sensestat = dec2bin(curStr.SenseState.state,4);
                % blow is assuming we only care about time domain streaming
                % starting / stopping, see:
                % enum
                % Medtronic.NeuroStim.Olympus.DataTypes.Sensing.SenseStates : byte
                % for details re what the binary number means
                if strcmp(sensestat(4),'0') % time domain off
                    timenum = curStr.RecordInfo.HostUnixTime;
                    t = datetime(timenum/1000,'ConvertFrom','posixTime','TimeZone','America/Los_Angeles','Format','dd-MMM-yyyy HH:mm:ss.SSS');
                    actionuse = sprintf('stop sense %d',senseStopCnt);
                    senseSettings.action{recNum} = actionuse;
                    senseSettings.recNum(recNum) = senseStopCnt;
                    senseSettings.timeStart{recNum} = t;
                    for c = 1:4
                        fnuse = sprintf('chan%d',c);
                        senseSettings.(fnuse){recNum} = tdData(c).chanFullStr;
                    end
                    senseSettings.tdDataStruc{recNum} = tdData;
                    instream = 0;
                    senseStopCnt = senseStopCnt + 1;
                    recNum = recNum + 1;
                end
            end
        end
    end
    f = f+1;
end
% loop on deviceSettigs and extract the start and stop time for each
% recording in the file.
deviceSettingsOut = table(); 
idxnotnan = ~isnan(senseSettings.recNum);
unqRecs = unique(senseSettings.recNum(idxnotnan)); 
for u = 1:length(unqRecs)
    idxuse = senseSettings.recNum == unqRecs(u);
    dt = senseSettings(idxuse,:);
    if size(dt,1) == 1 % this means that stream didn't stop properly / or that we jsut have one recrodings 
        deviceSettingsOut.recNum(u) = unqRecs(u);
        deviceSettingsOut.timeStart(u) = dt.timeStart{1};
        % assume time stop is end of file 
        timenum = DeviceSettings{end}.RecordInfo.HostUnixTime;
        timeEnd = datetime(timenum/1000,'ConvertFrom','posixTime','TimeZone','America/Los_Angeles','Format','dd-MMM-yyyy HH:mm:ss.SSS');

        deviceSettingsOut.timeStop(u) = timeEnd;
        deviceSettingsOut.duration(u) = deviceSettingsOut.timeStop(u) - deviceSettingsOut.timeStart(u);
        for c = 1:4 % find sample rate
            if ~strcmp(dt.tdDataStruc{1}(c).sampleRate,'disabled')
                deviceSettingsOut.samplingRate(u) = str2num(dt.tdDataStruc{1}(c).sampleRate(1:end-2));
            end
        end
        for c = 1:4
            fnuse = sprintf('chan%d',c);
            deviceSettingsOut.(fnuse){u} = dt.(fnuse){1};
        end
        deviceSettingsOut.TimeDomainDataStruc{u} = dt.tdDataStruc{1};

    else
        deviceSettingsOut.recNum(u) = unqRecs(u);
        deviceSettingsOut.timeStart(u) = dt.timeStart{1};
        deviceSettingsOut.timeStop(u) = dt.timeStart{2};
        deviceSettingsOut.duration(u) = deviceSettingsOut.timeStop(u) - deviceSettingsOut.timeStart(u);
        for c = 1:4 % find sample rate
            if ~strcmp(dt.tdDataStruc{1}(c).sampleRate,'disabled')
                deviceSettingsOut.samplingRate(u) = str2num(dt.tdDataStruc{1}(c).sampleRate(1:end-2));
            end
        end
        for c = 1:4
            fnuse = sprintf('chan%d',c);
            deviceSettingsOut.(fnuse){u} = dt.(fnuse){1};
        end
        deviceSettingsOut.TimeDomainDataStruc{u} = dt.tdDataStruc{1};
    end
end

end


function outstruc = translateTimeDomainChannelsStruct(tdDat)
%% assume no bridging
outstruc = tdDat;
for f = 1:length(outstruc)
    % lpf 1 (front end)
    switch tdDat(f).lpf1
        case 9
            outstruc(f).lpf1 = '450Hz';
        case 18
            outstruc(f).lpf1 = '100Hz';
        case 36
            outstruc(f).lpf1 = '50Hz';
        otherwise
            outstruc(f).lpf1 = 'unexpected';
    end
    % lpf 1 (bacnk end amplifier)
    switch tdDat(f).lpf2
        case 9
            outstruc(f).lpf2 = '100Hz';
        case 11
            outstruc(f).lpf2 = '160Hz';
        case 12
            outstruc(f).lpf2 = '350Hz';
        case 14
            outstruc(f).lpf2 = '1700Hz';
        otherwise
            outstruc(f).lpf2 = 'unexpected';
    end
    % channels - minus input
    switch tdDat(f).minusInput
        case 0
            outstruc(f).minusInput = 'floating';
        case 1
            outstruc(f).minusInput = '0';
        case 2
            outstruc(f).minusInput = '1';
        case 4
            outstruc(f).minusInput = '2';
        case 8
            outstruc(f).minusInput = '3';
        case 16
            outstruc(f).minusInput = '4';
        case 32
            outstruc(f).minusInput = '5';
        case 64
            outstruc(f).minusInput = '6';
        case 128
            outstruc(f).minusInput = '7';
        otherwise
            outstruc(f).minusInput = 'unexpected';
    end
    if ~strcmp(outstruc(f).minusInput,'floating') & ~strcmp(outstruc(f).minusInput,'unexpected')
        if f > 2 % asssumes there is no bridging
            outstruc(f).minusInput = num2str( str2num(outstruc(f).minusInput)+8);
        end
    end
    % channels - plus input
    switch tdDat(f).plusInput
        case 0
            outstruc(f).plusInput = 'floating';
        case 1
            outstruc(f).plusInput = '0';
        case 2
            outstruc(f).plusInput = '1';
        case 4
            outstruc(f).plusInput = '2';
        case 8
            outstruc(f).plusInput = '3';
        case 16
            outstruc(f).plusInput = '4';
        case 32
            outstruc(f).plusInput = '5';
        case 64
            outstruc(f).plusInput = '6';
        case 128
            outstruc(f).plusInput = '7';
        otherwise
            outstruc(f).plusInput = 'unexpected';
    end
    if ~strcmp(outstruc(f).plusInput,'floating') & ~strcmp(outstruc(f).plusInput,'unexpected')
        if f > 2 % asssumes there is no bridging
            outstruc(f).plusInput = num2str( str2num(outstruc(f).plusInput)+8);
        end
    end
    % sample rate
    switch tdDat(f).sampleRate
        case 0
            outstruc(f).sampleRate = '250Hz';
        case 1
            outstruc(f).sampleRate = '500Hz';
        case 2
            outstruc(f).sampleRate = '1000Hz';
        case 240
            outstruc(f).sampleRate = 'disabled';
        otherwise
            outstruc(f).plusInput = 'unexpected';
    end
    outstruc(f).chanOut = sprintf('+%s-%s',...
        outstruc(f).plusInput,outstruc(f).minusInput);
    outstruc(f).chanFullStr = sprintf('%s lpf1-%s lpf2-%s sr-%s',...
        outstruc(f).chanOut,...
        outstruc(f).lpf1,outstruc(f).lpf2,outstruc(f).sampleRate);
end
end