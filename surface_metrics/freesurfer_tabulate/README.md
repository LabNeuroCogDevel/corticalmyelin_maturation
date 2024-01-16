# FreeSurfer Tabulate

This software uses fmriprep and neuromaps containers to extract lots of anatomical
features from FreeSurfer results directories in easy-to-analyze formats.

## Tabular data for lots of atlases

Part of this repo is a set of atlases in FreeSurfer annot format that were collected
or converted via `datalad run`. This means their origins and history are all kept
in the git history here. The `gather_annots.sh` script contains all the details.

## Using the outputs

After running this on a bunch of freesurfer output directories, you will have access to

  1. Lots of tabular data
  2. Surface data in fsaverage space in `.mgh` files
  3. Surface data in fsLR space in CIFTI2 `.nii` files
  4. The entire FreeSurfer directory in an xzipped tar file

### Gathering the data you want

There are many great ways to combine the tabular data that is created here. The
following is how I would gather the data.

### 1. Install the apache arrow library

Apache arrow provides "parquet," a fantastic file format that you can use in R and Python. It's
smaller, faster and more accurate than tsv files. You need pandas and pyarrow

```
$ pip install pandas pyarrow
```

Now you can concatenate the subject-specific data from your output directory using

```python

>>> from pathlib import Path
>>> import pandas as pd
>>> dataframes = []
>>> for tsv in Path('./freesurfer').rglob("*brainmeasures.tsv"):
...     dataframes.append(pd.read_csv(tsv, sep="\t"))
>>> group_brainmeasures = pd.concat(dataframes, ignore_index=True, axis=0)
>>> group_brainmeasures.to_parquet("group_brainmeasures.parquet")
>>>
```

This will take awhile if you have a lot of subjects. Continuing here, if you
want to extract the parcel measures for a specific atlas, you could do
something like this (from the same python session):

```python
>>> parcel_dfs = []
>>> atlas_i_want = 'glasser'
>>> for tsv in Path('./freesurfer').rglob("*regionsurfacestats.tsv"):
...     _parcel_df = pd.read_csv(tsv, sep="\t")
...     parcel_dfs.append(_parcel_df[_parcel_df["atlas"] == atlas_i_want])
>>> atlas_df = pd.concat(parcel_dfs, ignore_index=True, axis=0)
>>> atlas_df.to_parquet(atlas_i_want + "_surfacestats.parquet")
```

Now you're ready to look at these in R! Be sure to have the `arrow` package installed
in R:

```R
install.packages("arrow")
group_df <- arrow::read_parquet("group_brainmeasures.parquet") # 1 row per subject
parcel_df <- arrow::read_parquet("glasser_surfacestats.parquet") # replace glasser with your atlas of choice
```

And you're ready to do some analysis in R