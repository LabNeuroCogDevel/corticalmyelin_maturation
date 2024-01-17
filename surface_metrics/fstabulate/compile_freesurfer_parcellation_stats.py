"""Compile FreeSurfer stats files."""
import os
import sys
import pandas as pd
import numpy as np

hemispheres = ["lh", "rh"]
NOSUFFIX_COLS = ["Index", "SegId", "StructName"]
LGI_COLUMN_NAMES = ["Mean_piallgi", "StdDev_piallgi", "Min_piallgi", "Max_piallgi", "Range_piallgi"]

def statsfile_to_df(stats_fname, hemi, atlas, column_suffix=""):
    with open(stats_fname, "r") as fo:
        data = fo.readlines()

    idx = [i for i, l in enumerate(data) if l.startswith("# ColHeaders ")]
    assert len(idx) == 1
    idx = idx[0]

    columns_row = data[idx]
    actual_data = data[idx + 1:]
    actual_data = [line.split() for line in actual_data]
    columns = columns_row.replace("# ColHeaders ", "").split()

    df = pd.DataFrame(columns=[col + column_suffix
                               if not col in NOSUFFIX_COLS
                               else col for col in columns],
                      data=actual_data)
    df.insert(0, "hemisphere", hemi)
    df.insert(0, "atlas", atlas)
    return df


subjects_dir = os.getenv("SUBJECTS_DIR")
metrics = os.getenv("user_measures")
lgi = os.getenv("LGI")
anatomical_stats = os.getenv("anatomical_stats")

if metrics:
    metrics = metrics.split(" ")
if __name__ == "__main__":
    subject_id = sys.argv[1]
    atlases = sys.argv[2:]
    print(f"Summarizing regional stats for {len(atlases)} atlases")
    in_dir = os.path.join(subjects_dir, subject_id)
    stats_dir = os.path.join(in_dir, "stats")
    surfstat_dfs = []
    for atlas in atlases:
        print(atlas)
        for hemi in hemispheres:
            print(f"   {hemi}")

            # get the surface statistics
            if anatomical_stats == "true": 
                print("     anatomical stats")
                surfstats_file = os.path.join(stats_dir, f"{hemi}.{atlas}.stats")
                surfstat_df_ = statsfile_to_df(surfstats_file, hemi, atlas)

            if anatomical_stats == "false":
                surfstats_file = os.path.join(stats_dir, f"{hemi}.{atlas}.stats")
                surfstat_df_ = statsfile_to_df(surfstats_file, hemi, atlas)
                surfstat_df_ = surfstat_df_[["atlas", "hemisphere","StructName","NumVert","SurfArea"]]

            # get statistics for user-specified metrics
            if metrics:
                for metric in metrics:
                    print(f"     {metric}")
                    userstat_file = os.path.join(stats_dir, f"{hemi}.{atlas}.{metric}.stats")
                    userstat_df_ = statsfile_to_df(userstat_file, hemi, atlas, column_suffix=f"_{metric}")
                    surfstat_df_ = pd.merge(surfstat_df_, userstat_df_)

            # get LGI statistics 
            lgi_file = os.path.join(stats_dir, f"{hemi}.{atlas}.pial_lgi.stats")
            if os.path.exists(lgi_file):
                print("     lgi stats")
                lgi_df_ = statsfile_to_df(lgi_file, hemi, atlas, column_suffix="_piallgi")
                surfstat_dfs.append(pd.merge(surfstat_df_, lgi_df_))
            else:
                surfstat_dfs.append(surfstat_df_)

    # The freesurfer directory may contain subject and session. check here
    session_id = None
    subject_id_fs = subject_id #retain original freesurfer id for writing output csv
    if "_" in subject_id:
        subject_id, session_id = subject_id.split("_")
    if "long" in session_id:
        session_id, long, base = session_id.split(".")
    out_df = pd.concat(surfstat_dfs, axis=0, ignore_index=True)
    out_df.insert(0, "session_id", session_id)
    out_df.insert(0, "subject_id", subject_id)

    def sanity_check_columns(reference_column, redundant_column, atol=0):
        if not np.allclose(
            out_df[reference_column].astype(np.float32),
            out_df[redundant_column].astype(np.float32), atol=atol):
            raise Exception(f"The {reference_column} values were not identical to {redundant_column}")
        out_df.drop(redundant_column, axis=1, inplace=True)

    # Do some sanity checks and remove redundant columns
    if metrics:
        for metric in metrics:
            sanity_check_columns("NumVert", f"NVertices_{metric}", 0)
            sanity_check_columns("SurfArea", f"Area_mm2_{metric}", 1)

    # If LGI is available, check it too
    if "NVertices_piallgi" in out_df.columns:
        sanity_check_columns("NumVert", "NVertices_piallgi", 0)
        sanity_check_columns("SurfArea", "Area_mm2_piallgi", 1)
    else:
        # If LGI failed and lgi environment variable is set to TRUE, fill the columns with NaNs
        if lgi:
            for lgi_col in LGI_COLUMN_NAMES:
                out_df[lgi_col] = np.nan

    out_df.to_csv(f"{subjects_dir}/{subject_id_fs}/stats/{subject_id}_{session_id}_regionsurfacestats.tsv", sep="\t", index=False)
