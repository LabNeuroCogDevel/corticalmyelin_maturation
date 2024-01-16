#!/usr/bin/env python
import os
import re
import sys
from pathlib import Path
import pandas as pd
import json
import numpy as np

fs_root = Path(os.getenv("SUBJECTS_DIR"))

def get_euler_from_log(subject_id):

    reconlog = fs_root / subject_id / "scripts" / "recon-all.log"
    with reconlog.open("r") as reconlogf:
        log_lines = [line.strip() for line in reconlogf]

    def read_qc(target_str):
        data, = [line for line in log_lines if target_str in line]
        data = data.replace(",", "")
        tokens = data.split()
        rh_val = float(tokens[-1])
        lh_val = float(tokens[-4])
        return rh_val, lh_val

    rh_euler, lh_euler = read_qc("lheno")
    rh_holes, lh_holes = read_qc("lhholes")
    return {"lh_euler": {"value": lh_euler,
                         "meta": "Left hemisphere Euler number from recon-all.log"},
            "rh_euler": {"value": rh_euler,
                         "meta": "Right hemisphere Euler number from recon-all.log"},
            "lh_holes": {"value": lh_holes,
                         "meta": "Left hemisphere number of holes from recon-all.log"},
            "rh_holes": {"value": rh_holes,
                         "meta": "Right hemisphere number of holes from recon-all.log"}
           }


def read_stats(stats_name, source_id, info, get_measures=False, measures_only=False):
    """Reads stats from a freesurfer stats table.

    Parameters:
    ===========

    stats_name: str
        Name of the .stats file to parts
    source_id: str
        ID for these stats in the output ()
    info: dict
        Dictionary containing other collected info about the run
    get_measures: bool
        Should the # Measure lines be parsed and added to info?
    Returns: Nothing. the info dict gets keys/values added to it

    """
    stats_file = fs_root / subject_id / "stats" / stats_name
    if not stats_file.exists():
        raise Exception(str(stats_file) + "does not exist")

    with stats_file.open("r") as statsf:
        lines = statsf.readlines()

    # Get the column names by finding the line with the header tag in it
    header_tag = "# ColHeaders"
    header, = [line for line in lines if header_tag in line]
    header = header[len(header_tag):].strip().split()

    stats_df = pd.read_csv(
        str(stats_file),
        sep='\s+',
        comment="#",
        names=header).melt(id_vars=["StructName"],
                           ignore_index=True)
    stats_df = stats_df[stats_df['variable'] != "Index"]

    if stats_name.startswith("lh"):
        suffix = "_Left"
    elif stats_name.startswith("rh"):
        suffix = "_Right"
    else:
        suffix = "_Sub"

    if not measures_only:
        # Get it into a nice form
        stats_df['FlatName'] = stats_df['StructName'] + '_' + stats_df['variable']

        for _, row in stats_df.iterrows():
            col_name = row['FlatName'].replace(
                "-", "_").replace(
                "3rd", "Third").replace(
                "4th", "Fourth").replace(
                "5th", "Fifth")
            if col_name in info:
                raise Exception(f"{col_name} is already present in the collected data")
            info[col_name] = {
                "value": row['value'],
                "meta": (
                  f'The "{row["variable"]}" value for the "{row["StructName"]}" '
                  f'structure. Originally in the stats/{stats_name} file.')}

    if get_measures:
        get_stat_measures(stats_file, suffix, info, stats_name)


def get_stat_measures(stats_file, suffix, info, stats_name):
    """Read a "Measure" from a stats file.

    Parameters:
    ===========

    stats_file: Path
        Path to a .stats file containing the measure you want
    info: dict
        Dictionary with all this subject's info
    """
    with stats_file.open("r") as statsf:
        lines = statsf.readlines()
    suffix = ""
    if "/rh." in str(stats_file):
        suffix = "_rh"
    elif "/lh." in str(stats_file):
        suffix = "_lh"

    measure_pat = re.compile(
        "# Measure ([A-Za-z]+), ([A-Za-z]+),* [-A-Za-z ]+, ([0-9.]+), .*")
    for line in lines:
        match = re.match(measure_pat, line)
        if match:
            pt1, pt2, value = match.groups()
            pt1 = pt1 if pt1 == pt2 else "{}_{}".format(pt1, pt2)
            key = "{}{}".format(pt1, suffix)
            if key in info:
                if not float(value) == info[key]['value']:
                    raise Exception(f"{key} is already in the metadata with a different value")
            info[key] = {
                "value": float(value),
                "meta": ("This is a whole-brain metadata measure with two "
                         f'possible labels, "{pt1}" and "{pt2}". It comes '
                         f"from the stats/{stats_name} file.")}


if __name__ == "__main__":
    fs_dirname = sys.argv[1]

    session_id = None
    subject_id = fs_dirname
    if "_" in fs_dirname:
        subject_id, session_id = fs_dirname.split("_")

    fs_audit = {
        "subject_id": {"value": subject_id,
                       "meta": "BIDS subject id"},
        "session_id": {"value": session_id,
                       "meta": "BIDS session id"}
    }
    fs_audit.update(get_euler_from_log(subject_id))

    # Add global stats from two of the surface stats files
    read_stats("lh.aparc.pial.stats", "Pial", fs_audit,
               get_measures=True, measures_only=True)
    read_stats("rh.aparc.pial.stats", "Pial", fs_audit,
               get_measures=True, measures_only=True)

    # And grab the volume stats from aseg
    read_stats("aseg.stats", "aseg", fs_audit, get_measures=True)

    # Remove SegId, it's the same for everyone
    for key in list(fs_audit.keys()):
        if "SegId" in key:
            del fs_audit[key]

    out_tsv = fs_root / (fs_dirname + "_brainmeasures.tsv")
    out_json = fs_root / (fs_dirname + "_brainmeasures.json")

    metadata = {key: value["meta"] for key, value in fs_audit.items()}
    with out_json.open("w") as jsonf:
        json.dump(metadata, jsonf, indent=2)

    real_data = {key: value['value'] for key,value in fs_audit.items()}
    data_df = pd.DataFrame([real_data])
    data_df.to_csv(out_tsv, sep="\t", index=False)