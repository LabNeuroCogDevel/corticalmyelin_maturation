#/bin/bash

#A script to calculate Vogt-Vogt histology-based myelin mean gray levels in HCP-MMP glasser parcels, based on the myelin map provided in https://www.sciencedirect.com/science/article/pii/S1053811922007327

project_dir=/Volumes/Hera/Projects/corticalmyelin_development
wb_command=/Volumes/Hera/Projects/corticalmyelin_development/software/workbench/bin_linux64/wb_command

#Extract left and right hemisphere giftis from initial hemisphere-specific dscalar files
wb_command -cifti-separate /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/nieuwenhuys_GLI_from_colin27_to_conte69_32k_lh.dscalar.nii COLUMN -metric CORTEX_LEFT /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLI_space-fsLR_den-32k_hemi-L.shape.gii
wb_command -cifti-separate /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/nieuwenhuys_GLI_from_colin27_to_conte69_32k_rh.dscalar.nii COLUMN -metric CORTEX_RIGHT /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLI_space-fsLR_den-32k_hemi-R.shape.gii

#Combine left and right hemisphere giftis into a single dscalar cifti
wb_command -cifti-create-dense-scalar /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLI_space-fsLR_den-32k.dscalar.nii -left-metric /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLI_space-fsLR_den-32k_hemi-L.shape.gii -right-metric /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLI_space-fsLR_den-32k_hemi-R.shape.gii

#Parcellate with the HCP-MMP (glasser) parcellation
wb_command -cifti-parcellate /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLI_space-fsLR_den-32k.dscalar.nii /Volumes/Hera/Projects/corticalmyelin_development/Maps/HCPMMP_glasseratlas/glasser_space-fsLR_den-32k_desc-atlas.dlabel.nii COLUMN /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLI_atlas-glasser_space-fsLR_den-32k.pscalar.nii  

