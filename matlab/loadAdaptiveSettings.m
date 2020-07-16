function adaptiveSettings =  loadAdaptiveSettings(fn)
DeviceSettings = jsondecode(fixMalformedJson(fileread(fn),'DeviceSettings'));
% fix issues with device settings sometiems being a cell array and
% sometimes not 
if isstruct(DeviceSettings)
    DeviceSettings = {DeviceSettings};
end
clc;
%% Adaptive / detection config
% detection settings first are reported in full (e.g. all fields) 
% after this point, only changes are reported. 
% to make analysis easier, each row in output table will contain the full
% settings such that I copy over initial settings. 
% this also assumes that you get a full report of the detection settings on
% first connection. 

% the settings being changed in each adaptive state update will be noted
% in a cell array as well 



%%%
%%%
%%%
% NEW CODE - first load initial settings that then get updates 
%%%
%%%
%%%

f = 1;
previosSettIdx = 0;
currentSettIdx  = 1; 
adaptiveSettings = table();

fnms = fieldnames(DeviceSettings{f});
curStr = DeviceSettings{f};
det_fiels = {'blankingDurationUponStateChange',...
    'detectionEnable','detectionInputs','fractionalFixedPointValue',...
    'holdoffTime','onsetDuration','terminationDuration','updateRate'};
if isfield(curStr,'DetectionConfig')
    lds_fn = {'Ld0','Ld1'};
    for ll = 1:length(lds_fn)
        ldTable = table();
        if isfield(curStr.DetectionConfig,lds_fn{ll})
            LD = curStr.DetectionConfig.(lds_fn{ll});
            adaptiveSettings.([lds_fn{ll} '_' 'biasTerm']) = LD.biasTerm';
            adaptiveSettings.([lds_fn{ll} '_' 'normalizationMultiplyVector']) = [LD.features.normalizationMultiplyVector];
            adaptiveSettings.([lds_fn{ll} '_' 'normalizationSubtractVector']) = [LD.features.normalizationSubtractVector];
            adaptiveSettings.([lds_fn{ll} '_' 'weightVector']) = [LD.features.weightVector];
            for d = 1:length(det_fiels)
                adaptiveSettings.([lds_fn{ll} '_' det_fiels{d}])  =  LD.(det_fiels{d});
            end
        else % fill in previous settings.
            warning('missing field on first itiration');
        end
    end
    adaptiveSettings.HostUnixTime = curStr.RecordInfo.HostUnixTime;
end
if isfield(curStr,'AdaptiveConfig')
    adaptive_fields = {'adaptiveMode','adaptiveStatus','currentState',...
        'deltaLimitsValid','deltasValid'};
    adaptiveConfig = curStr.AdaptiveConfig;
    for a = 1:length(adaptive_fields)
        if isfield(adaptiveConfig,adaptive_fields{a})
            adaptiveSettings.(adaptive_fields{a}) = adaptiveConfig.(adaptive_fields{a});
        else
            warning('missing field on first itiration');
        end
    end
    if isfield(adaptiveConfig,'deltas')
        adaptiveSettings.fall_rate = [adaptiveConfig.deltas.fall];
        adaptiveSettings.rise_rate = [adaptiveConfig.deltas.rise];
    else
        warning('missing field on first itiration');
    end
    adaptiveSettings.HostUnixTime = curStr.RecordInfo.HostUnixTime;
end
if isfield(curStr,'AdaptiveConfig')
    % loop on states
    if isfield(adaptiveConfig,'state0')
        for s = 0:8
            statefn = sprintf('state%d',s);
            stateStruct = adaptiveConfig.(statefn);
            adaptiveSettings.(['state' num2str(s)] ) = s;
            adaptiveSettings.(['rate_hz_state' num2str(s)] ) = stateStruct.rateTargetInHz;
            adaptiveSettings.(['isValid_state' num2str(s)] ) = stateStruct.isValid;
            for p = 0:3
                progfn = sprintf('prog%dAmpInMilliamps',p);
                curr(p+1) = stateStruct.(progfn);
            end
            adaptiveSettings.(['currentMa_state' num2str(s)] )(1,:) = curr;
        end
    else
        % fill in previous settings.
    end
end


% loop on rest of code and just report changes and when they happened 
% don't copy things over for now 

end