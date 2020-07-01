function MAIN_create_subsets_of_home_data_for_analysis()
%% This function creats subsets of home data for later analysis 
% it uses previous functions to concatenate the data (listed below) and
% process it into small chunks. 

% pre reqs: 
%% data converstion and databasing functions 
% MAIN_report_data_in_folder 
% creates a database file you need 
% this function runs very quickly and will enter each TD.json file 
% and compute the the duration of each file 
% it will fail to find data if time domain data was not streamed (so for
% exmpale just power domain data. 

% MAIN_load_rcsdata_from_folders 
% this function converts all the .json containedin each session directory
% to .json files 
% note that this function relies on the database folder above. If you have
% added new data, you will need to delete the database.mat folder created
% in the top level session directryo and rerun the load function. 
% note that this function will only convert files that have not already
% been converted 

% print_stim_and_sense_settings_in_folders
% this function will create a .mat file and text file 
% 1) 'stim_and_sense_settings_table.mat'
% 2) 'stimAndDeviceSettingsLog.txt' 
% these will can be used to parse data for further analysis 
% stim and sense settings has information about sense and stim settings 
% so that "apples to apples" comaprison is possible from the data 
%
% This function will also plot a sense_stim_text_metrics.txt text file that
% will have infromation about all unique sense and stim combinations and
% their datasize 
% sense_stim_database_operations


% MAIN_run_process_RCS_data_in_parallel()
% this function splits dat into 30 second chunks 
% and reshape the data into this setting (with some overlap depending on
% settings) 
% this rehsaping is mostly so that PSD and such can be caluclated using
% vectorized code which greatly aaccelrates proccessing time for many time
% domai based analysis 
% processes data into 30 second chunks 

% analyzeContinouseDataFromSCS()
% this function is called by MAIN_run_process_RCS_data_in_parallel()
% in this function you will find the params used in order to chop the data
% up into little parts as well as the parameters used to do this choppping
% (like max gap allowed in time between each data segement, segement size
% in seconds etc. 
%%

%% parametrs 
% the first step after running all above functions is to look at the output
% of print_stim_and_sense_settings_in_folders()
% this will create a text file: stimAndDeviceSettingsLog.txt 
% as noted above that will tell you important information about what kind
% of parameters you would want to filter on for your database.
% then you can do your sorting here, and create subsets of your data that
% will then be passed to a concatenateing function 
% note that in order to concatenate data and run PSD's efficiently on
% hundereds of data chunk you need the data to be the same size (for vector
% operations). 
% TODO: make this robust to differnt sampleing rate by introducing
% interpolation to PSD results 

%% data selection: 
dropboxdir = findFilesBVQX('/Users','Starr Lab Dropbox',struct('dirs',1,'depth',2));
DROPBOX_PATH = dropboxdir; 

%%
% find unsynced data folder on dropbox and then patient needed 
rootfolder = findFilesBVQX(DROPBOX_PATH,'RC+S Patient Un-Synced Data',struct('dirs',1,'depth',1));

% exmaple selections: 
%%
patient = 'RCS08'; 
patdir = findFilesBVQX(rootfolder{1},[patient '*'],struct('dirs',1,'depth',1));
% find the home data folder (SCBS fodler 
scbs_folder = findFilesBVQX(patdir{1},'SummitContinuousBilateralStreaming',struct('dirs',1,'depth',2));
% assumign you want the same settings for L and R side  
pat_side_folders = findFilesBVQX(scbs_folder{1},[patient '*'],struct('dirs',1,'depth',1));
for ss = 1:length(pat_side_folders)
    % check if database file exists, if not create it 
    dbFile = fullfile(pat_side_folders{ss},'stim_and_sense_settings_table.mat');
    if exist(dbFile,'file')
        load(dbFile)
    else
        try
            print_stim_and_sense_settings_in_folders(pat_side_folders{ss});
            load(dbFile)
        catch
            fprintf('error with creating the database');
            fprintf('please run %s function', 'print_stim_and_sense_settings_in_folders.m');
            fprintf('with this folder:\n');
            fprintf('%s\n',pat_side_folders{ss});
            error('error with creating db file');
        end
    end
    % print the database file to screen (the text portion it creats to make
    % this next bit easier 
    databaseReport = fullfile(pat_side_folders{ss},'sense_stim_database_report.txt');
    dbtype(databaseReport);
    
    %% this bit can be specific on a "per patient" basis 
    idxuse = strcmp(sense_stim_table.chan1,'+2-0 lpf1-450Hz lpf2-1700Hz sr-250Hz') & ... 
             sense_stim_table.stimulation_on == 0; 
    stim_off_database = sense_stim_table(idxuse,:); 
    concatenate_and_plot_TD_data_from_database_table(stim_off_database,pat_side_folders{ss},'before_stim');
    
end



end
