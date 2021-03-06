function compare_intrapop_to_rcs_data()
%% This funciton compares intraop to RC+S data
% it reiles on code here:
% '/Users/roee/Starr_Lab_Folder/Data_Analysis/1_intraop_data_analysis'
% note that you want to re-reference the data according to what you did
% with RC+S data
%% clear stuff 
clear all;
close all;
clc;
%% intraop data:
% ecog
fnm = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS01/v02-surgery/intraop/NO data/analyzed/RCS01_Lecog_Llfp_rest_postlead_newlocatio2_ecog_filt.mat';
% left side 
fnm = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS02/v01_or_day/NeuroOmega/cora_analysis/done/RCS02_bilatM1_Llfp_rest_postlead_ecog_filt.mat';
% right side 
% fnm = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS02/v01_or_day/NeuroOmega/cora_analysis/done/RCS02_bilatM1_Llfp_rest_postlead_ecog_filt.mat';
% both sides 
fnm = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS02/v01_or_day/NeuroOmega/cora_analysis/RCS02_bilatM1_bilatlfp_rest_postlead_ecog_filt.mat';
fnm = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS05/v02_or_day/intraop_data/NO/RCS05_bi_04_LRecog_Rlfp_rest_ecog_filt.mat';
fnm = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS07/v01_ORday/NeuroOmegaData/RCS07_05_biEcog_bilfp_rest_ecog_filt.mat';

fnm = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS07/v01_ORday/NeuroOmegaData/RCS07_05_biEcog_bilfp_rest_ecog_filt.mat';
fnm = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS08/v02_OR_day/NO_data/RCS08_biecog_bilfp_rest_ecog_filt.mat';

% fnm = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS06/v00_OR_day/NeuroOmegaData/RCS06_07_bi_ecog_lfp_rest_postlead_ecog_filt.mat';
%1-4 left 5-8 right for both ecog and lfp 
load(fnm);
clear fnm
% remember for right side to trim neuroomega
% 
lfp.contact = lfp.contact(5:8); 
lfp.Fs      = lfp.Fs(5:8); 
ecog.contact = ecog.contact(5:8);     
ecog.Fs = ecog.Fs(5:8); 

%% load rest rc+s data
% right side
fnm = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS01/v03-postop/rcs-data/Session1539481694013/DeviceNPC700395H/rest.mat';
fnm = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS01/v03-postop/rcs-data/Session1539481694013/DeviceNPC700395H/rest.mat';
fnm = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS07/v13_10day/scbs/SummitContinuousBilateralStreaming/RCS07R/Session1568824817583/DeviceNPC700403H/rest.mat';
fnm = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS06/v00_OR_day/RCSdata/StarrLab/RCS06R/Session1569979644476/DeviceNPC700425H/rest.mat';
fnm = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS05/v05_3week/rcs_data/SummitContinuousBilateralStreaming/RCS05R/Session1565801991414/DeviceNPC700415H/rest.mat';
% left side 
% fnm = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS02/v04_10_day/rcs_data/off_meds/RCS02L/Session1557938513404/DeviceNPC700398H/rest.mat';
% fnm = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS05/v05_3week/rcs_data/SummitContinuousBilateralStreaming/RCS05L/Session1565801977503/DeviceNPC700414H/rest_off_meds_rcs05L.mat';
% fnm  = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS07/v13_10day/scbs/SummitContinuousBilateralStreaming/RCS07L/Session1568824808509/DeviceNPC700419H/rest.mat';
% fnm = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS06/v00_OR_day/RCSdata/StarrLab/RCS06L/Session1569979258863/DeviceNPC700424H/rest.mat';
fnm = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS08/v03_10_day/rcsdata/RCS08L/Session1580841864086/DeviceNPC700444H/rest.mat';
load(fnm);
clear fnm;

%% re ref neuromega data according to RC+S recording config 
% idx use left
idxuse = 60754:90572; 
% idx use right
idxuse = 15901:30503; 
% idx use right RCS05 
idxuse = 2504 :6538;
% idx use left RCS08 
idxuse = 9507:46502;
% idx use right side RCS08 - some weird signals 
idxuse = 55867: 61599;
% default 
% idxuse = 1:size(lfp.contact(1).signal,2);

outdatcomplete = outdatachunk ;
outRec = outRec(1); % assuming first montage is relevant one if using a motnage file 
cns = {outRec.tdData.chanOut};
% get NeuroOmega Channels 
for c = 1:length(cns)
    idxmins = str2num(outRec.tdData(c).minusInput);
    idxplus = str2num(outRec.tdData(c).plusInput);
    if c <= 2 
        idxmins = idxmins + 1; 
        idxplus = idxplus + 1; 
        neuroOmegaDat(c).dat = lfp.contact(idxplus).signal(idxuse) - lfp.contact(idxmins).signal(idxuse);
    else
        idxmins = idxmins - 7;
        idxplus = idxplus - 7;
        neuroOmegaDat(c).dat = ecog.contact(idxplus).signal(idxuse) - ecog.contact(idxmins).signal(idxuse);
    end
    
    neuroOmegaDat(c).chanName = sprintf('Neuro-Omega %s',cns{c});

end
neuroOmegaTab = struct2table(neuroOmegaDat);
% plot raw data neuromega to check for transienst 
figure;
for i = 1:4
    hsub(i) = subplot(4,1,i); 
    plot(hsub(i),neuroOmegaTab.dat(i,:));
    title(neuroOmegaTab.chanName{i});
end
linkaxes(hsub,'x'); 
%% plot data 
hfig = figure; 
for c = 1:length(cns)
    if c > 2
        nmpltuse = 2;
        ttlstr = 'ECOG';
    else
        nmpltuse = 1;
        ttlstr = 'LFP';
    end
    hsub(c) = subplot(2,2,c);
    
    % RC+S 
    hold on;
    fnm = sprintf('key%d',c-1);
    y = outdatcomplete.(fnm);
    y = y - mean(y);
    srate = unique(outdatcomplete.samplerate);
    [fftOut,f]   = pwelch(y,srate,srate/2,0:1:srate/2,srate,'psd');
    idxnorm = f > 5 & f < 150; 
    fftOut = fftOut./mean(fftOut(idxnorm));
    hplt(c,1) = plot(f,log10(fftOut));
    hplt(c,1).LineWidth = 2;
    hplt(c,1).Color = [0 0 0.8 0.8];
    xlim([0 250]);
    xlabel('Frequency (Hz)');
    ylabel('Power  (log_1_0\muV^2/Hz)');
    lgndttls{1} = sprintf('RC+S %s',outRec.tdData(c).chanFullStr);
    title(ttlstr);
    fprintf('%s %s rms = %.2f\n',lgndttls{1},ttlstr,rms(y.*1e3));
    clear y yout;
    
    % Neuro Omega (intra op);
    hold on;
    y = neuroOmegaTab.dat(c,:);
    y = y - mean(y);
    srate = ecog.Fs(c);
    [fftOut,f]   = pwelch(y,srate,srate/2,0:1:srate/2,srate,'psd');
    idxnorm = f > 5 & f < 150;
    fftOut = fftOut./mean(fftOut(idxnorm));
    hplt(c,2) = plot(f,log10(fftOut));
    hplt(c,2).LineWidth = 2;
    hplt(c,2).Color = [0.8 0 0 0.8];
    xlim([0 250]);
    xlabel('Frequency (Hz)');
    ylabel('Power  (log_1_0\muV^2/Hz)');
    lgndttls{2} = neuroOmegaDat(c).chanName;
    title(ttlstr);
    fprintf('%s %s rms = %.2f\n',neuroOmegaDat(c).chanName,ttlstr,rms(y));
    clear y yout;
    legend(hplt(c,:),lgndttls);
    % add legends

end
return 

suptitle('Comparison of RC+S and NeuroOmega - normalized 5-150Hz');
% set params
params.figdir  = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS05/v02_or_day/figures';
params.figtype = '-djpeg';
params.resolution = 300;
params.closeafterprint = 1;
params.figname = 'rc-s_vs_neuroomega-normalized-5-150';
% plot_hfig(hfig,params)
figdir = params.figdir;
figname = 'neuroomega vs rc+s.fig';
savefig(hfig,fullfile(figdir,figname)); 


%% plot pac 
pacparams.PhaseFreqVector      = 5:2:50;
pacparams.AmpFreqVector        = 10:5:200;

pacparams.PhaseFreq_BandWidth  = 4;
pacparams.AmpFreq_BandWidth    = 10;
pacparams.computeSurrogates    = 0;
pacparams.numsurrogate         = 0;
pacparams.alphause             = 0.05;
pacparams.plotdata             = 0;
pacparams.useparfor            = 0; % if true, user parfor, requires parallel computing toolbox

%% pac path
addpath(genpath('/Users/roee/Starr_Lab_Folder/Data_Analysis/PAC'));
for c = 1:4
    if c > 2
        nmpltuse = 2;
        ttlstr = 'ECOG';
    else
        nmpltuse = 1;
        ttlstr = 'LFP';
    end
    hfig = figure; 
    % rc+s data 
    hsb = subplot(1,2,1); 
    srate = unique( outdatcomplete.samplerate );
    fnm = sprintf('key%d',c-1);
    y = outdatcomplete.(fnm);
    y = y - mean(y);
    results = computePAC(y',srate,pacparams);
    % plot pac 
    contourf(results.PhaseFreqVector+results.PhaseFreq_BandWidth/2,...
        results.AmpFreqVector+results.AmpFreq_BandWidth/2,...
        results.Comodulogram',30,'lines','none')
    shading interp
    set(gca,'fontsize',14)
    ttly = sprintf('Amplitude Frequency %s (Hz)',outRec.tdData(c).chanOut);
    ylabel(ttly)
    ttlx = sprintf('Phase Frequency %s (Hz)',outRec.tdData(c).chanOut);
    xlabel(ttlx)
    ttluse = [ttlstr ' - RC+S'];
    title(ttluse);
    % plot neuroomega 
    hsb = subplot(1,2,2);
    srate = ecog.Fs(c);
    fnm = sprintf('key%d',c-1);
    y = neuroOmegaTab.dat(c,:);
    y = y - mean(y);
    results = computePAC(y,srate,pacparams);
    % plot pac 
    contourf(results.PhaseFreqVector+results.PhaseFreq_BandWidth/2,...
        results.AmpFreqVector+results.AmpFreq_BandWidth/2,...
        results.Comodulogram',30,'lines','none')
    shading interp
    set(gca,'fontsize',14)
    ttly = sprintf('Amplitude Frequency %s (Hz)',outRec.tdData(c).chanOut);
    ylabel(ttly)
    ttlx = sprintf('Phase Frequency %s (Hz)',outRec.tdData(c).chanOut);
    xlabel(ttlx)
    ttluse = [ttlstr ' - NeuroOmega'];
    title(ttluse);
    % print figure;
    suptitle(sprintf('Comparison of RC+S and NeuroOmega %s',ttlstr));
    % set params
    params.figdir  = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS01/v03-postop/figures';
    params.figtype = '-djpeg';
    params.resolution = 300;
    params.closeafterprint = 1;
    params.figname = sprintf('PAC-%s-%s',ttlstr,outRec.tdData(c).chanOut);
    plot_hfig(hfig,params)
end

end