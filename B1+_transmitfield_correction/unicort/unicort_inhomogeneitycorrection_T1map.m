%A script to run SPM's UNICORT (Unified segmentation based correction of R1 brain maps for RF transmit field inhomogeneities) algorithm on quantitative T1 images and output corrected T1 maps and estimated bias fields

cd /opt/ni_tools/matlab_toolboxes/spm_bids
addpath('/opt/ni_tools/matlab_toolboxes/spm12-head')

global BIDS BIDS_App

%call to bids/spm, including bids_dir output_dir level and --participant_label
inputs_base= {'/Volumes/Hera/Projects/corticalmyelin_development/BIDS/', '/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/unicort_T1map', 'participant', '--skip-bids-validator', '--participant_label'};
%configuration file; this is a matlab script detailing the unicort/segmentation/bias correction parameters
config_T1map = '/Volumes/Hera/Projects/corticalmyelin_development/code/corticalmyelin_maturation/B1+_transmitfield_correction/unicort/unicort_configparams_T1map.m';

%get list of study participants to run unicort on
subjectlist = fileread('/Volumes/Hera/Projects/corticalmyelin_development/sample_info/7T_CuBIDS_subjects_list.txt'); %CuBIDS dominant group participant list
subjects = strsplit(subjectlist);
subjects(end) = []; %remove empty element at end of subjects list

%launch UNICORT
for id = 1:length(subjects)

	subid = subjects{id};
	subid(1:4) = []; %remove "sub-" from the BIDS id

	inputs = {inputs_base{:} char(subid)};
	if ~exist(sprintf('/Volumes/Hera/Projects/corticalmyelin_development/BIDS/derivatives/unicort_T1map/%s', subjects{id}), 'dir');
	sprintf("running UNICORT on subjects{id}")
		try
			run spm_BIDS_App.m; 
		end
	run(config_T1map)
	end
end
