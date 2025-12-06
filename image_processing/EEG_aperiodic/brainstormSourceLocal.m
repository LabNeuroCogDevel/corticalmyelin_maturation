%% Script by Shane McKeon to source localize EEG activity to HCP-MMP frontal regions and calculate the aperiodic exponent
addpath resources/brainstorm3/
brainstorm nogui


%% Path to FreeSurfer subjects
FSfolder = '/Volumes/Hera/preproc/7TBrainMech_rest/FS7.4.1_long'; 
FSdirs = dir(fullfile(FSfolder, '*'));

EEGfolder = '/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/preprocessed_data/Resting_State/AfterWhole/ICAwholeClean_homogenize/';
DBfolder = '/Volumes/Hera/Projects/7TBrainMech/scripts/eeg/Shane/resources/brainstorm_db_new';
glasserFrontalRegions = readtable('/Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser360_regionlist_frontallobe.csv','Delimiter', '\n', 'ReadVariableNames', true);
parcelNames = extractBefore(string(glasserFrontalRegions.orig_parcelname_label), ',');
merge7t = readmatrix('/Volumes/Hera/Projects/7TBrainMech/scripts/txt/merged_7t.csv'); 
% 
failedSubjects = {};

for i = 1:length(FSdirs)
    if FSdirs(i).isdir && ~ismember(FSdirs(i).name, {'.', '..'})
       
        FSsubfolder = FSdirs(i).name;  % folder name
        

        % Only include folders with an underscore (ID_date format)
        if contains(FSsubfolder, 'long')
        
            SubjectNameMRI = sprintf('%s_%s', FSsubfolder(5:9), FSsubfolder(15:22));

            subjectDBfolder = [DBfolder '/sourceLocal_' SubjectNameMRI];
            
            searchPattern = fullfile(subjectDBfolder, 'data', SubjectNameMRI, '**', '*specparam.mat');
            files = dir(searchPattern);

            if isempty(files)
                
                try
                    sFiles = [];
                
                    % Set a unique protocol for each subject
                    ProtocolName = sprintf('sourceLocal_%s', SubjectNameMRI);
                    
                    % Get existing protocols
                    iProtocol = bst_get('Protocol', ProtocolName);
                    if isempty(iProtocol)
                        
                        % Create a new protocol for each subject
                        gui_brainstorm('CreateProtocol', ProtocolName, 0, 0); %
                        
                        % Add the subject to the protocol (if not already present)
                        db_add_subject(SubjectNameMRI, []);
                    else
                        gui_brainstorm('SetCurrentProtocol', iProtocol);

                    end
                    
                    % Import FreeSurfer anatomy
                    FSpath = fullfile(FSfolder, FSsubfolder, '/');
                    
                    sFiles = bst_process('CallProcess', 'process_import_anatomy', sFiles, [], ...
                        'subjectname', SubjectNameMRI, ...
                        'mrifile',     {FSpath, 'FreeSurfer'}, ...
                        'nvertices', 15000);  % adjust resolution if needed
                    
                    % Import raw data
                    
                    % Process: Create link to raw file
                    
                    luna = str2double(SubjectNameMRI(1:5));
                    MRIdate = str2double(SubjectNameMRI(7:14));
                    
                    rowIdx = merge7t(:,1) == luna & merge7t(:,4) == MRIdate;

                    if any(rowIdx)
                        eeg_date = merge7t(rowIdx, 5);
                    end
                    
                    pattern = sprintf('%s_%s*_rerefwhole_ICA_icapru.set', string(luna), string(eeg_date));
                    
                    files = dir(fullfile(EEGfolder, pattern));
                    
                    match = [];
                    for f = 1:numel(files)
                        % Case-insensitive check for "_rest_Rem_" pattern
                        if contains(lower(files(f).name), '_rest_rem_rerefwhole_ica_icapru.set')
                            match = files(f).name;
                            break;
                        end
                    end
                    
                    if isempty(match)
                        error('File not found for %s in %s', SubjectNameMRI(1:10), EEGfolder);
                    else
                        EEGpath = fullfile(EEGfolder, match);
                    end
                    
                  
                    sFiles = bst_process('CallProcess', 'process_import_data_raw', [], [], ...
                        'subjectname',    SubjectNameMRI, ...
                        'datafile',       {EEGpath, 'EEG-EEGLAB'}, ...
                        'channelreplace', 1, ...
                        'channelalign',   1, ...
                        'evtmode',        'value');
                    
                    
                    sFiles = bst_process('CallProcess', 'process_import_data_event', sFiles, [], ...
                        'subjectname',   SubjectNameMRI, ...
                        'condition',     '', ...
                        'eventname',     '16130, 15362', ...
                        'timewindow',    [], ...
                        'epochtime',     [0, 4], ...
                        'split',         0, ...
                        'createcond',    1, ...
                        'ignoreshort',   0, ...
                        'usectfcomp',    1, ...
                        'usessp',        1, ...
                        'freq',          [], ...
                        'baseline',      [], ...
                        'blsensortypes', 'MEG, EEG');
                    
                    
                     sFiles = bst_process('CallProcess', 'process_concat', sFiles, []);
                    
                    
                    % Process: Refine registration
                    sFiles = bst_process('CallProcess', 'process_headpoints_refine', sFiles, [], ...
                        'tolerance', 2);
                    
                    sFiles = bst_process('CallProcess', 'process_channel_project', sFiles, [], ...
                        'sensortypes', 'EEG');
                    
                    sFiles = bst_process('CallProcess', 'process_generate_bem', sFiles, [], ...
                        'subjectname', SubjectNameMRI, ...
                        'nscalp',      1082, ...
                        'nouter',      1082, ...
                        'ninner',      1082, ...
                        'thickness',   4, ...
                        'method',      'brainstorm', ...  % Brainstorm
                        'source_abs',  -1);
                    
                    
                    % Process: Compute head model
                    sHeadModel = bst_process('CallProcess', 'process_headmodel', sFiles, [], ...
                        'Comment',     '', ...
                        'sourcespace', 1, ...  % Cortex surface
                        'meg',         3, ...  % Overlapping spheres
                        'eeg',         3, ...  % OpenMEEG BEM
                        'ecog',        2, ...  % OpenMEEG BEM
                        'seeg',        2, ...  % OpenMEEG BEM
                        'nirs',        1, ...  %
                        'openmeeg',    struct(...
                        'BemSelect',    [1, 1, 1], ...
                        'BemCond',      [1, 0.0125, 1], ...
                        'BemNames',     {{'Scalp','Skull', 'Brain'}}, ...
                        'BemFiles',     {{}}, ...
                        'isAdjoint',    0, ...
                        'isAdaptative', 1, ...
                        'isSplit',      0, ...
                        'SplitLength',  4000), ...
                        'nirstorm',    struct(...
                        'FluenceFolder',    'https://neuroimage.usc.edu/resources/nst_data/fluence/', ...
                        'smoothing_method', 'geodesic_dist', ...
                        'smoothing_fwhm',   10), ...
                        'channelfile', sFiles(1).ChannelFile);
                    
                    
                    % Process: Compute covariance (noise or data)
                    sNoise = bst_process('CallProcess', 'process_noisecov', sHeadModel, [], ...
                        'baseline',       [], ...
                        'datatimewindow', [0, 500], ...
                        'sensortypes',    'EEG', ...
                        'target',         1, ...  % Noise covariance     (covariance over baseline time window)
                        'dcoffset',       1, ...  % Block by block, to avoid effects of slow shifts in data
                        'identity',       1, ...
                        'copycond',       0, ...
                        'copysubj',       0, ...
                        'copymatch',      0, ...
                        'replacefile',    1);  % Replace
                    
                    
                    % Process: Compute sources [2018]
                    sSources = bst_process('CallProcess', 'process_inverse_2018', sNoise, [], ...
                        'output',  1, ...  % Kernel only: shared
                        'inverse', struct(...
                        'Comment',        'sLORETA: EEG', ...
                        'InverseMethod',  'minnorm', ...
                        'InverseMeasure', 'sloreta', ...
                        'SourceOrient',   {{'fixed'}}, ...
                        'Loose',          0.2, ...
                        'UseDepth',       0, ...
                        'WeightExp',      0.5, ...
                        'WeightLimit',    10, ...
                        'NoiseMethod',    'reg', ...
                        'NoiseReg',       0.1, ...
                        'SnrMethod',      'fixed', ...
                        'SnrRms',         1e-06, ...
                        'SnrFixed',       3, ...
                        'ComputeKernel',  1, ...
                        'DataTypes',      {{'EEG'}}));

                    
                    %load subjects cortex file
                    sSubject = bst_get('Subject', SubjectNameMRI);
                    CortexFile = sSubject.Surface(sSubject.iCortex).FileName;
                    CortexMat = in_tess_bst(CortexFile);
                   
                    idx = strcmp({CortexMat.Atlas.Name}, 'glasser');
                    glasser_atlas = CortexMat.Atlas(idx);
                    % Extract all labels from the Glasser atlas
                    labels = {glasser_atlas.Scouts.Label};
                    
                    % Remove the trailing ' L' or ' R' for matching
                    cleanLabels = regexprep(labels, ' [LR]$', '');
                    
                    % Find matches
                    ROIsIdx = find(ismember(cleanLabels, parcelNames));
                    
                    ROIs = glasser_atlas.Scouts(ROIsIdx);
                    
                    %extrsact scout time series
                    sScoutTS = bst_process('CallProcess', 'process_extract_scout', sSources, [], ...
                        'timewindow',   [], ...                  % full time window
                        'scouts',       {'glasser', {ROIs.Label}}, ...  % use the atlas name + scout labels
                        'scoutfunc',    1, ...                   % 1 = mean, 2 = max, 3 = PCA, etc.
                        'isflip',       0, ...                   % don't flip sign
                        'isnorm',       0, ...                   % no normalization
                        'concatenate',  1, ...                   % concatenate all scouts
                        'save',         1);                      % save results in the database
                    
                    
                    % Process: Power spectrum density (Welch)
                    sPSD = bst_process('CallProcess', 'process_psd', sScoutTS, [], ...
                        'timewindow',  [], ...
                        'win_length',  2, ...
                        'win_overlap', 50, ...
                        'units',       'physical', ...  % Physical: U2/Hz
                        'sensortypes', 'EEG', ...
                        'win_std',     0, ...
                        'edit',        struct(...
                        'Comment',         'Power', ...
                        'TimeBands',       [], ...
                        'Freqs',           [], ...
                        'ClusterFuncTime', 'none', ...
                        'Measure',         'power', ...
                        'Output',          'all', ...
                        'SaveKernel',      0));
                    
                    % Process: specparam: Fitting oscillations and 1/f
                    sFOOOF = bst_process('CallProcess', 'process_fooof', sPSD, [], ...
                        'implementation', 'matlab', ...  % Matlab
                        'freqrange',      [1, 50], ...
                        'powerline',      '60', ...  % 60 Hz
                        'method',         'leastsquare', ...  % Default
                        'peakwidth',      [0.5, 12], ...
                        'maxpeaks',       4, ...
                        'minpeakheight',  0, ...
                        'proxthresh',     2, ...
                        'apermode',       'fixed', ...  % Fixed
                        'guessweight',    'none', ...  % None
                        'sorttype',       'param', ...  % Peak parameters
                        'sortparam',      'frequency', ...  % Frequency
                        'sortbands',      {'delta', '2, 4'; 'theta', '5, 7'; 'alpha', '8, 12'; 'beta', '15, 29'; 'gamma1', '30, 59'; 'gamma2', '60, 90'});
                    
                    
               
                    
                catch
                    fprintf('Sub wont run: %s\n', SubjectNameMRI);
                    failedSubjects{end+1} = SubjectNameMRI;

                end
                
            else
                fprintf('Sub already run, skipping %s\n', SubjectNameMRI);
                
            end
            
        else
            fprintf('Skipping folder (no date): %s\n', FSsubfolder);
            
        end
    end
    
    
end

if ~isempty(failedSubjects)
    failedFile = fullfile(pwd, 'failedSubjects.txt');  % save in current folder
    fid = fopen(failedFile, 'w');
    for k = 1:length(failedSubjects)
        fprintf(fid, '%s\n', failedSubjects{k});
    end
    fclose(fid);
    fprintf('Saved list of failed subjects to %s\n', failedFile);
end


failedSubjects = {};

for i = 1:length(FSdirs)
    if FSdirs(i).isdir && ~ismember(FSdirs(i).name, {'.', '..'})
        
        FSsubfolder = FSdirs(i).name;  % folder name
        
        
        % Only include folders with an underscore (ID_date format)
        if contains(FSsubfolder, 'long')
            
            SubjectNameMRI = sprintf('%s_%s', FSsubfolder(5:9), FSsubfolder(15:22));
            
            subjectDBfolder = [DBfolder '/sourceLocal_' SubjectNameMRI];
            
            searchPattern = fullfile(subjectDBfolder, 'data', SubjectNameMRI, '**', '*specparam.mat');
            files = dir(searchPattern);
            if isempty(files)
                
                failedSubjects{end+1} = SubjectNameMRI;
                
                
            end
        end
    end
end

if ~isempty(failedSubjects)
    failedFile = fullfile(pwd, 'failedSubjects.txt');  % save in current folder
    fid = fopen(failedFile, 'w');
    for k = 1:length(failedSubjects)
        fprintf(fid, '%s\n', failedSubjects{k});
    end
    fclose(fid);
    fprintf('Saved list of failed subjects to %s\n', failedFile);
end
