function concatenate_and_plot_TD_data()
if ismac 
    rootdir  = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS02/v13_home_data_stim/rcs_data/RCS02L';
else isunix
    rootdir  = '/home/starr/ROEE/data/RCS02L/';
end

% save td 
ff = findFilesBVQX(rootdir,'proc*TD*.mat');
tdProcDat = struct();
for f = 1:length(ff)
    
    load(ff{f},'processedData','params');
    if isempty(fieldnames(tdProcDat))
        if isstruct(processedData)
            tdProcDat = processedData;
        end
    else
        if ~isempty(processedData)
            tdProcDat = [tdProcDat processedData];
        end
    end
    clear processedData
end
save( fullfile(rootdir,'processedData.mat'),'tdProcDat','params','-v7.3')

% save acc 
ffAcc = findFilesBVQX(rootdir,'processedAccData.mat');
accProcDat = struct();
for f = 1:length(ffAcc)
%     process and analyze acc data
    load(ffAcc{f},'accData');
    
    if isempty(fieldnames(accProcDat))
        if isstruct(accData)
            accProcDat = accData;
        end
    else
        if ~isempty(accData)
            accProcDat = [accProcDat accData];
        end
    end
    fprintf('acc file %d/%d done\n',f,length(ffAcc));
    clear accData;
end
save( fullfile(rootdir,'processedData.mat'),'accProcDat','-v7.3')

%% create a large file that has overlapping data for PKG, ACC, TD data 
load('/Volumes/Samsung_T5/RCS02/RCS02_all_home_data_processed/data/RCS02L/processedDataSepFiles.mat');


%% load processed data and print times for each file 
load('/Volumes/Samsung_T5/RCS02/RCS02_all_home_data_processed/data/RCS02L/processedDataSepFiles.mat');
times = [tdProcDatSep.duration];
for t = 1:length(times)
    fprintf('%d %s\n',t,times(t));
end
tdProcDatSep(36); 


%% plot coverage by day 
for i = 1:length(tdProcDatSep)
    times = [tdProcDatSep(i).res.timeEnd];
    timeStarts(i) = times(1); 
    timeEnds(i) = times(end); 
end
allTimes = sortrows([fftResultsTd.timeStart',fftResultsTd.timeEnd'],1);
% split up recordings that are not in the samy day 
idxNotSameDay = day(allTimes(:,1)) ~= day(allTimes(:,2));
allTimesSameDay = allTimes(~idxNotSameDay,:); 
allTimesDiffDay = allTimes(idxNotSameDay,:); 
% for idx that is not the same day, split it 
newTimesDay1 = [allTimesDiffDay(:,1) (allTimesDiffDay(:,1) - timeofday(allTimesDiffDay(:,1)) + day(1)) - minutes(1)];
newTimesDay2 = [((allTimesDiffDay(:,2) - timeofday(allTimesDiffDay(:,2))) + minutes(2)  ) allTimesDiffDay(:,2) ];
% concatenate all times 
allTimesNew  = sortrows([allTimesSameDay ; newTimesDay1 ; newTimesDay2],1); 
daysUse      = day(allTimesNew); 
ycnt = 1; 
for d = 1:length(daysUse)
    if daysUse(d) == daysUse(d+1)
        yValue(d) = ycnt; 
    else
        yValue(d) = ycnt; 
        ycnt = ycnt+1;
    end
end
% plot figure 
hfig = figure; 
hold on; 
hax = subplot(1,1,1); 
plot(timeofday( allTimesNew' ),[yValue' yValue']',...
    'LineWidth',10,...
    'Color',[0.8 0 0 0.7]);
unqDays = unique(daysUse); 
yticks(1:length(unqDays))
ylabelsUse = {}; 
for d = 1:length(unqDays)
    ylabelsUse{d,1} = sprintf('May %d',unqDays(d));
end
hax.YTickLabel = ylabelsUse;

set(gca,'FontSize',16); 
ttluse = sprintf('Continous Chronic Recording at Home (%s hours)',sum(fftResultsTd.timeEnd-fftResultsTd.timeStart)/2); 
title(ttluse);
figdir = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS02/v06_home_data/figures';
figname = 'continous recording.fig';
savefig(hfig,fullfile(figdir,figname)); 

%% load actigraphy data, td data, pkg data and create one big database (one for each side) 
% td psd results data - get rid out outliers 

for c = 1:4 
    fn = sprintf('key%dfftOut',c-1); 
    idxkeep = fftResultsTd.(fn)(120,:) < -7;
end
hfig = figure; 
ttls = {'STN 0-2','STN 1-3','M1 8-10','M1 9-11'}; 
for c = 1:4 
    fn = sprintf('key%dfftOut',c-1); 
    hsub = subplot(2,2,c); 
    plot(fftResultsTd.ff,fftResultsTd.(fn)(:,idxkeep),'LineWidth',0.2,'Color',[0 0 0.8 0.2]); 
end

timesPKG = pkgTable.DateTime; 
timesPKG.TimeZone = 'America/Los_Angeles';
idxLoop = find(idxkeep==1); 
cnt = 1; 
dkVals = []; bkVals = []; idxThatHasPKGVals = []; 
for i = 1:length(idxLoop)
    timeGoal = fftResultsTd.timeEnd(idxLoop(i));
    [val(i),idx(i)] = min(abs(timeGoal - timesPKG));
    if val(i) < minutes(3)
        dkVals(cnt) = pkgTable.DK(idx(i));
        bkVals(cnt) = pkgTable.BK(idx(i)); 
        idxThatHasPKGVals(cnt) = idxLoop(i); 
        cnt = cnt + 1; 
    end
end






%% do fft but on sep recordings  
for c = 1:4
    start = tic;
    fn = sprintf('key%d',c-1);
    dat = [tdProcDat.(fn)];
    sr = 250; 
    [fftOut,ff]   = pwelch(dat,sr,sr/2,0:1:sr/2,sr,'psd');
    fftResultsTd.([fn 'fftOut']) = log10(fftOut); 
    fprintf('chanel %d done in %.2f\n',c,toc(start))
end
fftResultsTd.ff = ff; 
fftResultsTd.timeStart = [tdProcDat.timeStart];
fftResultsTd.timeEnd = [tdProcDat.timeEnd];

save( fullfile(rootdir,'psdResults.mat'),'params','fftResultsTd')

%% plot the data 

%% get td data + pkg data + acc data - correct place 
% get idx to plot 
% load('/Volumes/Samsung_T5/RCS02/RCS02_all_home_data_processed/data/RCS02R/psdResults.mat');
load('/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS02/v08_all_home_data_before_stim/RCS02_all_home_data_processed/RCS02L/psdResults.mat') % left hand 

% read pkg 
% first set of pkg data 
fn = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/pkg_data/UCSF_Scores_17_July_2019/scores_20190515_124018.csv'; % left hand f
fn = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/pkg_data/UCSF_Scores_17_July_2019/scores_20190515_124531.csv'; % right hand 
% fn = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS02/v07_3_week/pkg/scores_20190515_124531.csv'; % right hand 
pkgTable1 = readtable(fn); 
fn = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/pkg_data/UCSF_Scores_17_July_2019/scores_20190523_125035.csv'; % left hand 
fn = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/pkg_data/UCSF_Scores_17_July_2019/scores_20190523_124728.csv'; % right hand 

% fn = '/Users/roee/Starr_Lab_Folder/Data_Analysis/RCS_data/RCS02/v08_1_month_initial_programming/pkg_data/scores_20190523_124728.csv'; % right hand 
pkgTable2 = readtable(fn); 
pkgTable = [pkgTable1; pkgTable2]; 

figure; 
hsb(1) = subplot(2,1,1); 
plot(pkgTable.Date_Time,pkgTable.BK,'LineWidth',1,'Color',[0 0.8 0 0.5]); 
title('bk'); 
hsb(2) = subplot(2,1,2); 
plot(pkgTable.Date_Time,log10(pkgTable.DK),'LineWidth',1,'Color',[0 0 0.8 0.5]); 
title('dk'); 
linkaxes(hsb,'x'); 
%plot bk vs DK 
figure;
scatter(log10(pkgTable.DK),pkgTable.BK,10,'filled','MarkerFaceColor',[0.8 0 0],'MarkerEdgeAlpha',0.5);
title('Log DK vs BK vals')
xlabel('log DK vals');
ylabel('BK vals');
grid on 
axis normal 
set(gcf,'Color','w'); 
set(gca,'FontSize',20); 

figure;
idxWhisker = []; 
for c = 1:4 
    fn = sprintf('key%dfftOut',c-1); 
    hsub = subplot(2,2,c); 
    meanVals = mean(fftResultsTd.(fn)(40:60,:));
    boxplot(meanVals);
    q75_test=quantile(meanVals,0.75);
    q25_test=quantile(meanVals,0.25);
    w=2.0;
    wUpper(c) = w*(q75_test-q25_test)+q75_test;
    idxWhisker(:,c) = meanVals' < wUpper(c);

end
idxkeep = idxWhisker(:,1) &  idxWhisker(:,2) & idxWhisker(:,3) & idxWhisker(:,4) ; 


% confirm that this is a good way to get rid of outliers 
hfig = figure; 
ttls = {'STN 0-2','STN 1-3','M1 8-10','M1 9-11'}; 
for c = 1:4 
    fn = sprintf('key%dfftOut',c-1); 
    hsub = subplot(2,2,c); 
    plot(fftResultsTd.ff,fftResultsTd.(fn)(:,idxkeep),'LineWidth',0.2,'Color',[0 0 0.8 0.2]); 
end

% get the pkg data 
timesPKG = pkgTable.Date_Time; 
timesPKG.TimeZone = 'America/Los_Angeles';
idxLoop = find(idxkeep==1); 
cnt = 1; 
dkVals = []; bkVals = []; idxThatHasPKGVals = []; 
for i = 1:length(idxLoop)
    timeGoal = fftResultsTd.timeEnd(idxLoop(i));
    [val(i),idx(i)] = min(abs(timeGoal - timesPKG));
    if val(i) < minutes(3)
        dkVals(cnt) = pkgTable.DK(idx(i));
        bkVals(cnt) = pkgTable.BK(idx(i)); 
        idxThatHasPKGVals(cnt) = idxLoop(i); 
        cnt = cnt + 1; 
    end
end

% make a table with pkg values and td results 
allDataPkgRcsAcc = struct();
allDataPkgRcsAcc.key0fftOut = fftResultsTd.key0fftOut(:,idxThatHasPKGVals)';
allDataPkgRcsAcc.key1fftOut = fftResultsTd.key1fftOut(:,idxThatHasPKGVals)';
allDataPkgRcsAcc.key2fftOut = fftResultsTd.key2fftOut(:,idxThatHasPKGVals)';
allDataPkgRcsAcc.key3fftOut = fftResultsTd.key3fftOut(:,idxThatHasPKGVals)';
allDataPkgRcsAcc.timeStart  = fftResultsTd.timeStart(idxThatHasPKGVals)';
allDataPkgRcsAcc.timeEnd  = fftResultsTd.timeEnd(idxThatHasPKGVals)';
allDataPkgRcsAcc.dkVals = dkVals';
allDataPkgRcsAcc.bkVals = bkVals';
allDatTable = struct2table(allDataPkgRcsAcc); 

% plot histogrma correlate with pkg 
betaIdxUse  = 23:25; 
gamaIdxUse  = 74:76; 
powerBeta13  = mean(allDataPkgRcsAcc.key1fftOut(:,betaIdxUse),2); 
powerGama810 = mean(allDataPkgRcsAcc.key3fftOut(:,gamaIdxUse),2); 
powerGamma = mean(allDataPkgRcsAcc.key3fftOut(:,betaIdxUse),2); 
pkgOffMeds  = allDataPkgRcsAcc.bkVals > -120 & allDataPkgRcsAcc.bkVals < -60; 
pkgOnMeds   = allDataPkgRcsAcc.bkVals > -60 & allDataPkgRcsAcc.bkVals < -10; 

pkgOffMeds  = allDataPkgRcsAcc.dkVals > 0 & allDataPkgRcsAcc.dkVals < 30; 
pkgOnMeds   = allDataPkgRcsAcc.dkVals >= 30 & allDataPkgRcsAcc.dkVals < 300; 

bksabs = abs(allDataPkgRcsAcc.bkVals); 
% pkgOffMeds  = bksabs > 32 & bksabs < 80; 
% pkgOnMeds   = bksabs <= 20 & bksabs > 0; 
%{
We use BKS>26<40 (BKS=26 =UPDRS III~30)as a marker of 
?OFF? and >32<40 as (BKS=32 =UPDRS III~45)marker of very OFF
We use DKS>7 as a marker of dyskinesia and > 16 as significant dyskinesia
Generally when BKS>26, DKS will be low.

We don?t usually use the terminology of OFF/On/dyskinesia use in diaries
because they are categorical states compared to a continuous variable. 
If I can ask you the same question for UPDRS and AIMS score 
what cut-off would you like to use to indicate those 
same states and then I can give you approximate numbers for the BKS DKS.
We have good evidence thatTreatable bradykinesia 
(i.e. presumable OFF according to a clinician) is when the
 BKS>26 (or <-26 as per the csv files)
Good control (i.e. neither OFF nor ON) is when BKS <26 AND DKS<7
Dyskinesia is when DKS>7 and BKS <26.

However you should not use single epochs alone.  
We tend to use the 4/7 or 3/5 rule ? 
that is use take the first 7 epochs of BKS (or DKS), 
then the middle epoch will be ?OFF? if 4/7 of the epochs >26. 
Slide along one and apply the rule again etc.  
Mal Horne
Wed 7/24/2019 7:12 PM email 
%}

figure;
subplot(1,2,1); 
shadedErrorBar(fftResultsTd.ff,allDataPkgRcsAcc.key1fftOut(pkgOffMeds,:),{@median,@(x) std(x)*1.96},'lineprops',{'r','markerfacecolor','r','LineWidth',2});
shadedErrorBar(fftResultsTd.ff,allDataPkgRcsAcc.key1fftOut(pkgOnMeds,:),{@median,@(x) std(x)*1.96},'lineprops',{'b','markerfacecolor','b','LineWidth',2});
legend({'off meds - PKG estimate','on meds - PKG estimate'}); 
xlim([3 100]); 
xlabel('Frequency (Hz)');
ylabel('Power (log_1_0\muV^2/Hz)');
title('STN'); 
set(gca,'FontSize',20);


subplot(1,2,2); 
shadedErrorBar(fftResultsTd.ff,allDataPkgRcsAcc.key3fftOut(pkgOffMeds,:),{@median,@(x) std(x)*1.96},'lineprops',{'r','markerfacecolor','k','LineWidth',2});
shadedErrorBar(fftResultsTd.ff,allDataPkgRcsAcc.key3fftOut(pkgOnMeds,:),{@median,@(x) std(x)*1.96},'lineprops',{'b','markerfacecolor','b','LineWidth',2});
legend({'off meds - PKG estimate','on meds - PKG estimate'}); 
xlim([3 100]); 
xlabel('Frequency (Hz)');
ylabel('Power (log_1_0\muV^2/Hz)');
title('M1'); 
set(gca,'FontSize',20);
set(gcf,'Color','w'); 



figure;
subplot(2,2,1); 
hold on; 
histogram(powerBeta13(pkgOffMeds),'Normalization','probability','BinWidth',0.1); 
histogram(powerBeta13(pkgOnMeds),'Normalization','probability','BinWidth',0.1); 
legend({'off (PKG estimate)','on (PKG estimate)'}); 
ylabel('Probability (%)');
xlabel('Beta power');
ttluse = sprintf('Beta (%d-%dHz) on/off(PKG) - STN',betaIdxUse(1),betaIdxUse(end));
title(ttluse); 
set(gcf,'Color','w')
set(gca,'FontSize',20)

subplot(2,2,2); 
hold on; 
histogram(powerGama810(pkgOffMeds),'Normalization','probability','BinWidth',0.1); 
histogram(powerGama810(pkgOnMeds),'Normalization','probability','BinWidth',0.1); 
legend({'off (PKG estimate)','on (PKG estimate)'}); 
xlabel('Gamma power');
ylabel('Probability (%)');
ttluse = sprintf('Gama (%d-%dHz) on/off(PKG) - M1',gamaIdxUse(1),gamaIdxUse(end));
title(ttluse); 
set(gcf,'Color','w')
set(gca,'FontSize',20)

subplot(2,2,3); 
hold on; 
scatter(powerGama810(pkgOffMeds), powerBeta13(pkgOffMeds),4,'filled','MarkerFaceColor',[0.8 0 0],'MarkerFaceAlpha',0.5)
scatter(powerGama810(pkgOnMeds), powerBeta13(pkgOnMeds),4,'filled','MarkerFaceColor',[0 0 0.8],'MarkerFaceAlpha',0.5)
legend({'off (PKG estimate)','on (PKG estimate)'}); 
title ('Beta (STN) vs Gamma (M1) power'); 
xlabel('Power Gamma M1');
ylabel('Power Beta STN'); 
set(gcf,'Color','w')
set(gca,'FontSize',20)



% compute roc
subplot(2,2,4); 
hold on; 

tbl = table();
tbl.powerBeta = powerBeta13;
tbl.powerGamma = powerGama810; 

labels     = zeros(size(powerBeta13,1),1);
labels(pkgOnMeds) = 1; 
labels(pkgOffMeds) = 2;

idxkeepROC = labels~=0; 
labels = labels(idxkeepROC); 
labels(labels==1) = 0;
labels(labels==2) = 1;
dat    = [tbl.powerBeta(idxkeepROC),tbl.powerGamma(idxkeepROC)];

% beta 
[X,Y,T,AUC,OPTROCPT] = perfcurve(logical(labels),dat(:,1),1);
hplt = plot(X,Y);
hplt.LineWidth = 3;
hplt.Color = [0 0 0.8 0.7];
lgndTtls{1}  = sprintf('%s (AUC %.2f)','stn beta',AUC);
% gama 
[X,Y,T,AUC,OPTROCPT] = perfcurve(logical(labels),dat(:,2),0);
hplt = plot(X,Y);
hplt.LineWidth = 3;
hplt.Color = [0.8 0 0 0.7];
lgndTtls{2}  = sprintf('%s (AUC %.2f)','m1 gamma',AUC);
% both 
mdl = fitglm(dat,labels,'Distribution','binomial','Link','logit');
score_log = mdl.Fitted.Probability; % Probability estimates
[Xlog,Ylog,Tlog,AUClog] = perfcurve(logical(labels),score_log,'true');
hplt = plot(Xlog,Ylog);
hplt.LineWidth = 3;
hplt.Color = [0 0.7 0 0.7];
lgndTtls{3}  = sprintf('%s (AUC %.2f)','Beta + Gama',AUClog);


xlabel('False positive rate')
ylabel('True positive rate')
legend(lgndTtls);
title('ROC curves - beta, gamma, both');
set(gca,'FontSize',20);




% plot correlation 
figure;
% stn dk
subplot(2,2,1);
x = powerBeta13;
y = allDataPkgRcsAcc.dkVals; 
[r,pp] = corrcoef(x,y,'Rows','complete');
s1 = scatter(x,log10(y),20,[0 0 0.9],'filled','MarkerFaceAlpha',0.5);
xlabel('STN Beta');
ylabel('PKG DK');
ttluse = sprintf('STN corr between %s and %s is %.2f',...
    'STN Beta','PKG DK (log)',r(1,2));
title(ttluse);
hline = refline(gca);
hline.LineWidth = 3;
hline.Color = [hline.Color 0.5];
set(gca,'FontSize',16);
% stn bk
subplot(2,2,2);
x = powerBeta13;
y = allDataPkgRcsAcc.bkVals; 
[r,pp] = corrcoef(x,y,'Rows','complete');
s1 = scatter(x,y,20,[0 0 0.9],'filled','MarkerFaceAlpha',0.5);
xlabel('STN Beta');
ylabel('PKG BK');
ttluse = sprintf('STN - corr between %s and %s is %.2f',...
    'STN Beta','PKG BK',r(1,2));
title(ttluse);
hline = refline(gca);
hline.LineWidth = 3;
hline.Color = [hline.Color 0.5];
set(gca,'FontSize',16);

% m1 dk
subplot(2,2,3);
x = powerGama810;
y = allDataPkgRcsAcc.dkVals; 
[r,pp] = corrcoef(x,y,'Rows','complete');
s1 = scatter(x,log10(y),20,[0 0 0.9],'filled','MarkerFaceAlpha',0.5);
xlabel('M1 Gamma');
ylabel('PKG DK');
ttluse = sprintf('M1 corr between %s and %s is %.2f',...
    'M1 Beta','PKG DK (log)',r(1,2));
title(ttluse);
hline = refline(gca);
hline.LineWidth = 3;
hline.Color = [hline.Color 0.5];
set(gca,'FontSize',16);
% m1 bk
subplot(2,2,4);
x = powerGama810;
y = allDataPkgRcsAcc.bkVals; 
[r,pp] = corrcoef(x,y,'Rows','complete');
s1 = scatter(x,y,20,[0 0 0.9],'filled','MarkerFaceAlpha',0.5);
xlabel('M1 Beta');
ylabel('PKG BK');
ttluse = sprintf('M1 - corr between %s and %s is %.2f',...
    'M1 Beta','PKG BK',r(1,2));
title(ttluse);
hline = refline(gca);
hline.LineWidth = 3;
hline.Color = [hline.Color 0.5];
set(gca,'FontSize',16);

set(gcf,'Color','w');


% compute correlations 
% pkg values 
dkVals = log10(allDataPkgRcsAcc.dkVals);
idxDk  = allDataPkgRcsAcc.dkVals>10;
bkVals = allDataPkgRcsAcc.bkVals;
idxBk  = allDataPkgRcsAcc.bkVals >= -80 &  allDataPkgRcsAcc.bkVals <= -1;
% power vals 
powerBeta02 = mean(allDataPkgRcsAcc.key0fftOut(:,16:29),2); 
powerBeta13 = mean(allDataPkgRcsAcc.key1fftOut(:,14:30),2); 
powerGama810 = mean(allDataPkgRcsAcc.key2fftOut(:,71:84),2); 
powerGama911 = mean(allDataPkgRcsAcc.key3fftOut(:,70:84),2); 
powerBeta810 = mean(allDataPkgRcsAcc.key2fftOut(:,18:30),2); 
powerBeta911 = mean(allDataPkgRcsAcc.key3fftOut(:,20:29),2); 

% compute correlations 
pkgNames = {'dkVals','bkVals'}; 
idxNames = {'idxDk','idxBk'}; 
pwrNames = {'powerBeta02','powerBeta13','powerGama810','powerGama911','powerBeta810','powerBeta911'};

for k = 1:length(pkgNames)
    hfig = figure; 
    for p = 1:length(pwrNames)
        
        x = eval(pkgNames{k}); 
        idx = eval(idxNames{k}); 
        x = x(idx); 
        y = eval(pwrNames{p}); 
        y = y(idx); 
        [r,pp] = corrcoef(x,y,'Rows','complete');
        fprintf('corr between %s and %s is %.2f\n',...
            pkgNames{k},pwrNames{p},r(1,2)); 
        
        subplot(2,3,p); 
        s1 = scatter(x,y,20,[0 0 0.9],'filled','MarkerFaceAlpha',0.5); 
        xlabel(pkgNames{k});
        ylabel(pwrNames{p});
        ttluse = sprintf('corr between %s and %s is %.2f\n',...
            pkgNames{k},pwrNames{p},r(1,2)); 
        title(ttluse); 
        hline = refline(gca);
        hline.LineWidth = 3;
        hline.Color = [hline.Color 0.5];
        set(gca,'FontSize',16); 
    end
end
%



% get acc rms of data 
% load acc data 
load('/Volumes/Samsung_T5/RCS02/RCS02_all_home_data_processed/data/RCS02L/processedDataAcc.mat'); 
timesAcc = [accProcDat.timeStart]; 
for i = 1:length(accProcDat)
    rmsVals(i) = rms(accProcDat(i).XSamples) + ...
              rms(accProcDat(i).YSamples) + ...
              rms(accProcDat(i).ZSamples); 
end

idxLoop = find(idxkeep==1); 
cnt = 1; 
clear val idx 
for i = 1:length(idxLoop)
    timeGoal = fftResultsTd.timeEnd(idxLoop(i));
    [val(i),idx(i)] = min(abs(timeGoal - timesAcc));
    if val(i) < minutes(3)
        accVals(cnt) = rmsVals(idx(i));
        idxThatHasAccVals(cnt) = idxLoop(i); 
        cnt = cnt + 1; 
    end
end






% plot all data spectral 
figure;
ttls = {'STN 0-2','STN 1-3','M1 8-10','M1 9-11'}; 
for c = 1:4 
    hsub(c) = subplot(4,1,c); 
    fn = sprintf('key%dfftOut',c-1); 
    C = fftResultsTd.(fn)(:,idxkeep);
    
    Cmed = median(C,2);
    CDev = repmat(Cmed,1,sum(idxkeep));
    Cplot = C./CDev;
    
    zscored = zscore(C,0,2); 
    
    y = fftResultsTd.ff;
    imagesc(C);
    title(ttls{c});
    set(gca,'YDir','normal') 
    ylabel('Frequency (Hz)');
    set(gca,'FontSize',20); 
end
dataKeep = sum(fftResultsTd.timeEnd(idxkeep) - fftResultsTd.timeStart(idxkeep));
ttluse = sprintf('%s hours of data, %d 30 sec chunks',dataKeep,sum(idxkeep));
sgtitle(ttluse,'FontSize',30)
linkaxes(hsub,'x');

% cortex - gamma - 75-79; 
% beta - stn - 19-24 

figure;
powerBeta = mean(fftResultsTd.key0fftOut(17:19,idxkeep)); 
powerGama = mean(fftResultsTd.key3fftOut(65:68,idxkeep)); 
x = fftResultsTd.timeEnd(idxkeep); 

hold on; 
scatter(x,rescale(  powerBeta, 0, 0.45),20, [0 0 0.9],'filled','MarkerFaceAlpha',0.5);
scatter(x,rescale(  powerGama, 0.5, 1) ,20,[0.8 0 0],'filled','MarkerFaceAlpha',0.5);
legend('Beta','Gamma');
title('beta (stn) & gamma (m1) extracted from TD data'); 
ylabel('Beta + Gamma - rescaled - a.u.'); 
set(gca,'FontSize',16); 


figure; 
hold on; 
scatter(1:length(x),rescale(  powerBeta, 0, 0.45) ,20,[0 0 0.9],'filled','MarkerFaceAlpha',0.5);
scatter(1:length(x),rescale(  powerGama, 0.5, 1) ,20,[0.8 0 0],'filled','MarkerFaceAlpha',0.5);
legend('Beta','Gamma');
title('beta vs gamma rescaled - linear'); 

figure; 
hsb(1) = subplot(2,1,1); 
scatter(timeofday(x),powerBeta,20,[0 0 0.9],'filled','MarkerFaceAlpha',0.5);
title('beta'); 

hsb(2) = subplot(2,1,2); 
scatter(timeofday(x),powerGama,20,[0.8 0 0],'filled','MarkerFaceAlpha',0.5);
title('gamma'); 
linkaxes(hsb,'x'); 



figure; 
powerBeta = mean(fftResultsTd.key1fftOut(19:24,idxkeep)); 
powerGama = mean(fftResultsTd.key3fftOut(75:79,idxkeep)); 

s = scatter(powerBeta,powerGama,10,[0 0 0.9],'filled','MarkerFaceAlpha',0.2); 
xlabel('Beta'); 
ylabel('Gamma');
s.DataTipTemplate.DataTipRows(1).Label = 'Beta';
s.DataTipTemplate.DataTipRows(2).Label = 'Gamma';
row = dataTipTextRow('time',[cellstr(datestr(fftResultsTd.timeStart))]);
s.DataTipTemplate.DataTipRows(end+1) = row;
title('beta (stn) gamma (m1)'); 
datacursormode toggle

% plot against pkg dat

figure; 
subplot(3,1,1);
scatter(pkgTable.DK,pkgTable.BK,10,[0.8 0 0],'filled','MarkerEdgeAlpha',0.2);
xlabel('dk'); 
ylabel('bk'); 
subplot(3,1,2);
histogram(pkgTable.DK);
title('DK'); 
subplot(3,1,3);
histogram(pkgTable.BK);
title('BK'); 

timesPKG = pkgTable.DateTime; 
timesPKG.TimeZone = 'America/Los_Angeles';
idxLoop = find(idxkeep==1); 
cnt = 1; 
dkVals = []; bkVals = []; idxThatHasPKGVals = []; 
for i = 1:length(idxLoop)
    timeGoal = fftResultsTd.timeEnd(idxLoop(i));
    [val(i),idx(i)] = min(abs(timeGoal - timesPKG));
    if val(i) < minutes(3)
        dkVals(cnt) = pkgTable.DK(idx(i));
        bkVals(cnt) = pkgTable.BK(idx(i)); 
        idxThatHasPKGVals(cnt) = idxLoop(i); 
        cnt = cnt + 1; 
    end
end
% power vals 
powerBeta02 = mean(fftResultsTd.key0fftOut(16:29,idxThatHasPKGVals)); 
powerBeta13 = mean(fftResultsTd.key1fftOut(14:30,idxThatHasPKGVals)); 
powerGama810 = mean(fftResultsTd.key2fftOut(71:84,idxThatHasPKGVals)); 
powerGama911 = mean(fftResultsTd.key2fftOut(70:84,idxThatHasPKGVals)); 
powerBeta810 = mean(fftResultsTd.key2fftOut(18:30,idxThatHasPKGVals)); 
powerBeta911 = mean(fftResultsTd.key2fftOut(20:29,idxThatHasPKGVals)); 
% pkg values 
dkVals; 
bkVals; 
% compute correlations 
pkgNames = {'dkVals','bkVals'}; 
pwrNames = {'powerBeta02','powerBeta13','powerGama810','powerGama911','powerBeta810','powerBeta911'};

for k = 1:length(pkgNames)
    hfig = figure; 
    for p = 1:length(pwrNames)
        
        x = eval(pkgNames{k}); 
        y = eval(pwrNames{p}); 
        [r,pp] = corrcoef(x,y,'Rows','complete');
        fprintf('corr between %s and %s is %.2f\n',...
            pkgNames{k},pwrNames{p},r(1,2)); 
        
        subplot(2,3,p); 
        s1 = scatter(x,y,20,[0 0 0.9],'filled','MarkerFaceAlpha',0.5); 
        xlabel(pkgNames{k});
        ylabel(pwrNames{p});
        ttluse = sprintf('corr between %s and %s is %.2f\n',...
            pkgNames{k},pwrNames{p},r(1,2)); 
        title(ttluse); 
        hline = refline(gca);
        hline.LineWidth = 3;
        hline.Color = [hline.Color 0.5];
        set(gca,'FontSize',16); 
    end
end

figure 
subplot(2,2,1); 
plot(fftResultsTd.key0fftOut(:,idxThatHasPKGVals),'LineWidth',0.002,'Color',[0 0 0.8 0.2])
title('stn 0-2');
subplot(2,2,2); 
plot(fftResultsTd.key1fftOut(:,idxThatHasPKGVals),'LineWidth',0.002,'Color',[0 0 0.8 0.2])
title('stn 1-3');
subplot(2,2,3); 
plot(fftResultsTd.key2fftOut(:,idxThatHasPKGVals),'LineWidth',0.002,'Color',[0 0 0.8 0.2])
title('m1 8-10');
subplot(2,2,4); 
plot(fftResultsTd.key3fftOut(:,idxThatHasPKGVals),'LineWidth',0.002,'Color',[0 0 0.8 0.2])
title('m1 9-11');

figure;
subplot(2,1,1); 
s = scatter(dkVals,powerGama,20,[0 0 0.9],'filled','MarkerFaceAlpha',0.5); 
s.DataTipTemplate.DataTipRows(1).Label = 'DK PKG';
s.DataTipTemplate.DataTipRows(2).Label = 'RCS power gamma';
times = fftResultsTd.timeStart(idxThatHasPKGVals);
row = dataTipTextRow('time',[cellstr(datestr(times))]);
s.DataTipTemplate.DataTipRows(end+1) = row;
datacursormode toggle
xlabel('PKG'); 
ylabel('RCs'); 
title('gamma vs dk vals'); 
hline = refline(gca); 
hline.LineWidth = 3; 
hline.Color = [hline.Color 0.5]; 
set(gca,'FontSize',16)

subplot(2,1,2); 

s1 = scatter(bkVals,powerBeta,20,[0 0 0.9],'filled','MarkerFaceAlpha',0.5); 
s1.DataTipTemplate.DataTipRows(1).Label = 'BK PKG';
s1.DataTipTemplate.DataTipRows(2).Label = 'RCS power beta';
times = fftResultsTd.timeStart(idxThatHasPKGVals);
row = dataTipTextRow('time',[cellstr(datestr(times))]);
s1.DataTipTemplate.DataTipRows(end+1) = row;
datacursormode toggle
xlabel('PKG'); 
ylabel('RCs'); 
title('beta vs bk vals');
hline = refline(gca); 
hline.LineWidth = 3; 
hline.Color = [hline.Color 0.5]; 
set(gca,'FontSize',16)

% get acc rms of data 
timesAcc = [accProcDat.timeStart]; 
for i = 1:length(accProcDat)
    rmsVals(i) = rms(accProcDat(i).XSamples) + ...
              rms(accProcDat(i).YSamples) + ...
              rms(accProcDat(i).ZSamples); 
        
end


idxLoop = find(idxkeep==1); 
cnt = 1; 
clear val idx 
for i = 1:length(idxLoop)
    timeGoal = fftResultsTd.timeEnd(idxLoop(i));
    [val(i),idx(i)] = min(abs(timeGoal - timesAcc));
    if val(i) < minutes(3)
        accVals(cnt) = rmsVals(idx(i));
        idxThatHasAccVals(cnt) = idxLoop(i); 
        cnt = cnt + 1; 
    end
end



% power vals 
powerBeta02Acc = mean(fftResultsTd.key0fftOut(16:29,idxThatHasAccVals)); 
powerBeta13Acc = mean(fftResultsTd.key1fftOut(14:30,idxThatHasAccVals)); 
powerGama810Acc = mean(fftResultsTd.key2fftOut(71:84,idxThatHasAccVals)); 
powerGama911Acc = mean(fftResultsTd.key2fftOut(70:84,idxThatHasAccVals)); 
powerBeta810Acc = mean(fftResultsTd.key2fftOut(18:30,idxThatHasAccVals)); 
powerBeta911Acc = mean(fftResultsTd.key2fftOut(20:29,idxThatHasAccVals)); 
% pkg values 
dkVals; 
bkVals; 
% compute correlations 
pkgNames = {'accVals'};
pwrNames = {'powerBeta02Acc','powerBeta13Acc','powerGama810Acc','powerGama911Acc','powerBeta810Acc','powerBeta911Acc'};
hfig = figure; 
for k = 1:length(pkgNames)
    for p = 1:length(pwrNames)
        x = eval(pkgNames{k}); 
        y = eval(pwrNames{p}); 
        [r,pp] = corrcoef(x,y,'Rows','complete');
        fprintf('corr between RCs actgiraphy and %s is %.2f\n',...
             pwrNames{p},r(1,2)); 
         
         subplot(2,3,p);
         s1 = scatter(x,y,20,[0 0 0.9],'filled','MarkerFaceAlpha',0.5);
         xlabel(pkgNames{k});
         ylabel(pwrNames{p});
         ttluse = sprintf('corr between %s and %s is %.2f\n',...
             pkgNames{k},pwrNames{p},r(1,2));
         title(ttluse);
         hline = refline(gca);
         hline.LineWidth = 3;
         hline.Color = [hline.Color 0.5];
         set(gca,'FontSize',16);
    end
end




powerBetaAcc = mean(fftResultsTd.key0fftOut(19:24,idxThatHasAccVals)); 
powerGamaAcc = mean(fftResultsTd.key2fftOut(75:79,idxThatHasAccVals)); 

figure;
subplot(2,1,1); 
scatter(accVals,powerBetaAcc,20,[0 0 0.9],'filled','MarkerFaceAlpha',0.5); 
xlabel('acc rms'); 
ylabel('power beta stn'); 
title('beta (stn) vs internal rc+s actigraphy RMS'); 
hline = refline(gca); 
hline.LineWidth = 3; 
hline.Color = [hline.Color 0.5]; 
set(gca,'FontSize',16)

subplot(2,1,2); 
scatter(accVals,powerGamaAcc,20,[0.8 0 0],'filled','MarkerFaceAlpha',0.5); 
xlabel('acc rms'); 
ylabel('power gamma m1'); 
title('gamma (m1) vs internal rc+s actigraphy RMS'); 
hline = refline(gca); 
hline.LineWidth = 3; 
hline.Color = [hline.Color 0.5];
set(gca,'FontSize',16)


% get correlations between rc+S and beta and gamma power 
[r,p] = corrcoef(powerBeta,bkVals,'Rows','complete');
[r,p] = corrcoef(powerGama,dkVals,'Rows','complete');




figure;
cntplt = 1;
hsb(cntplt) = subplot(2,1,cntplt); cntplt = cntplt +1; 
hp = plot(pkgTable.DateTime,pkgTable.DK);





for c = 1:4 
    hsub(c) = subplot(4,1,c); 
    fn = sprintf('key%dfftOut',c-1); 
    C = fftResultsTd.(fn)(:,idxkeep);
    
    imagesc(C);
    title(ttls{c});
    set(gca,'YDir','normal') 
    ylabel('Frequency (Hz)');
    set(gca,'FontSize',20); 
end
sgtitle('160 hours of data -30 sec chunks - RCS02L','FontSize',30)
linkaxes(hsub,'x');
