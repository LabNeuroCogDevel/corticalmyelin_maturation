%==========================================================================
%     C O N F I G U R A T I O N    F I L E  :  P A R T I C I P A N T
%==========================================================================

% Available variables: BIDS and BIDS_App
%==========================================================================
vox_anat = [1 1 1];

anat = spm_BIDS(BIDS,'data', 'modality','anat', 'type','T1map');
if isempty(anat), error('Cannot find quantitative T1 image.'); end

clear matlabbatch

% UNICORT Correction via SPM Segmentation
%------------------------------------------------------------------
matlabbatch{1}.spm.spatial.preproc.channel.vols  = cellstr(anat);
matlabbatch{1}.spm.spatial.preproc.channel.biasreg  = 0.001;
matlabbatch{1}.spm.spatial.preproc.channel.biasfwhm  = 60;
matlabbatch{1}.spm.spatial.preproc.channel.write  = [1 1];
matlabbatch{1}.spm.spatial.preproc.warp.mrf = 1;
matlabbatch{1}.spm.spatial.preproc.warp.cleanup = 1;
matlabbatch{1}.spm.spatial.preproc.warp.reg = [0 0.001 0.5 0.05 0.2];
matlabbatch{1}.spm.spatial.preproc.warp.affreg = 'mni';
matlabbatch{1}.spm.spatial.preproc.warp.fwhm = 0;
matlabbatch{1}.spm.spatial.preproc.warp.samp = 3;
matlabbatch{1}.spm.spatial.preproc.warp.write = [0 0];


[~,prov] = spm_jobman('run',matlabbatch);

