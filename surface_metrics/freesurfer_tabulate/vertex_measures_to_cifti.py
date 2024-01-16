import os
import sys
import pandas as pd
from pathlib import Path
import subprocess
from collections import defaultdict
from neuromaps.transforms import fsaverage_to_fslr

input_dir = Path(sys.argv[1])
surfs_dir = input_dir / "surf"
malformed_giftis = list(map(str, surfs_dir.rglob("*.malformed.*gii")))
print(f"Found {len(malformed_giftis)} giftis to merge")
#print("\n" + "\n".join(malformed_giftis))

to_merge = defaultdict(list)

for mgii in malformed_giftis:
    cifti_name = mgii.replace(
        "rh.", "").replace(
        "lh.", "").replace(
        ".malformed", "").replace(
        ".fsaverage.", ".fsLR_den-164k.").replace(
        ".shape.gii", ".dscalar.nii")
    out_file = str(surfs_dir / (input_dir.name + "_" + Path(cifti_name).name))
    to_merge[out_file].append(mgii)


def cifti_from_giftis(rh_gii, lh_gii, cifti_name):
    l_fslr = fsaverage_to_fslr(
        lh_gii,
        target_density="164k", hemi="L", method="linear")
    r_fslr = fsaverage_to_fslr(
        rh_gii,
        target_density="164k", hemi="R", method="linear")

    wd = Path(cifti_name)
    tmp_rh = str(wd.parent / ("rh._TMP_" + "164k_fslr.shape.gii"))
    tmp_lh = str(wd.parent / ("lh._TMP_" + "164k_fslr.shape.gii"))

    l_fslr[0].to_filename(tmp_lh)
    r_fslr[0].to_filename(tmp_rh)
    cmd = ["wb_command",
           "-cifti-create-dense-scalar",
           "-left-metric", tmp_lh,
           "-right-metric", tmp_rh,
           cifti_name]
    ret = subprocess.run(cmd)

for cifti_name, giftis in to_merge.items():
    rh_gii, = [gii for gii in giftis if "rh." in gii]
    lh_gii, = [gii for gii in giftis if "lh." in gii]
    _rh = Path(rh_gii).name
    _lh = Path(lh_gii).name
    _cifti = Path(cifti_name).name
    print(f"Combining rh: {_rh} with lh: {_lh}\n"
          f"    to create {_cifti}")
    cifti_from_giftis(rh_gii, lh_gii, cifti_name)

