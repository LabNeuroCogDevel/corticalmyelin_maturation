library(ciftiTools)
ciftiTools.setOption('wb_path', '/Volumes/Hera/Projects/corticalmyelin_development/software/workbench')

#Extract left and right hemisphere giftis from initial hemisphere-specific dscalar files
command="-cifti-separate /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/nieuwenhuys_GLI_from_colin27_to_conte69_32k_lh.dscalar.nii COLUMN -metric CORTEX_LEFT /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLI_space-fsLR_den-32k_hemi-L.shape.gii"
ciftiTools::run_wb_cmd(command, intern = FALSE, ignore.stdout = NULL, ignore.stderr = NULL)

command="-cifti-separate /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/nieuwenhuys_GLI_from_colin27_to_conte69_32k_rh.dscalar.nii COLUMN -metric CORTEX_RIGHT /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLI_space-fsLR_den-32k_hemi-R.shape.gii"
ciftiTools::run_wb_cmd(command, intern = FALSE, ignore.stdout = NULL, ignore.stderr = NULL)

#Combine left and right hemisphere giftis into a single dscalar cifti
command="-cifti-create-dense-scalar /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLI_space-fsLR_den-32k.dscalar.nii -left-metric /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLI_space-fsLR_den-32k_hemi-L.shape.gii -right-metric /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLI_space-fsLR_den-32k_hemi-R.shape.gii"
ciftiTools::run_wb_cmd(command, intern = FALSE, ignore.stdout = NULL, ignore.stderr = NULL)

#Create a dscalar .txt file for masking
command="-cifti-convert -to-text /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLI_space-fsLR_den-32k.dscalar.nii /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLI_space-fsLR_den-32k.dscalar.txt"
ciftiTools::run_wb_cmd(command, intern = FALSE, ignore.stdout = NULL, ignore.stderr = NULL)

#Read in dscalar .txt file for masking
##"lower values indicate densely myelinated areas, while high MGL are found in lightly myelinated areas"
##"Since MGL are only available for the frontal, parietal and temporal lobes, remaining areas were assigned 255 as a default value"
vogt.myelin.data <- read.table("/Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLI_space-fsLR_den-32k.dscalar.txt")
vogt.myelin.data$V1[vogt.myelin.data$V1 > 250] <- NA
write.table(vogt.myelin.data, "/Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLImasked_space-fsLR_den-32k.dscalar.txt", quote = F, row.names = F, col.names = F)

command="-cifti-convert -from-text /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLImasked_space-fsLR_den-32k.dscalar.txt /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLI_space-fsLR_den-32k.dscalar.nii /Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLImasked_space-fsLR_den-32k.dscalar.nii"
ciftiTools::run_wb_cmd(command, intern = FALSE, ignore.stdout = NULL, ignore.stderr = NULL)



#Read in cifti and set values of 255 to NA 
##"lower values indicate densely myelinated areas, while high MGL are found in lightly myelinated areas"
##"Since MGL are only available for the frontal, parietal and temporal lobes, remaining areas were assigned 255 as a default value"
vogt.cifti <- read_cifti("/Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLI_space-fsLR_den-32k.dscalar.nii")

vogt.masked.cortexleft <- vogt.cifti$data$cortex_left
vogt.masked.cortexleft[vogt.masked.cortexleft == 255] <- NA
vogt.masked.cortexright <- vogt.cifti$data$cortex_right
vogt.masked.cortexright[vogt.masked.cortexright == 255] <- NA
write.table(vogt.masked.cortexleft, "/Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLImasked_space-fsLR_den-32k_hemi-L.shape.txt", quote = F, col.names = F, row.names = F)
write.table(vogt.masked.cortexright, "/Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLImasked_space-fsLR_den-32k_hemi-R.shape.txt", quote = F, col.names = F, row.names = F)


vogt.masked <- vogt.cifti
vogt.masked$data$cortex_left[vogt.masked$data$cortex_left == 255] <- NaN
vogt.masked$data$cortex_right[vogt.masked$data$cortex_right == 255] <- NaN
write_cifti(xifti = vogt.masked, cifti_fname = "/Volumes/Hera/Projects/corticalmyelin_development/Maps/VogtVogt_myeloarchitecture/source-nieuwenhuys_desc-myelinGLImasked_space-fsLR_den-32k.dscalar.nii")
