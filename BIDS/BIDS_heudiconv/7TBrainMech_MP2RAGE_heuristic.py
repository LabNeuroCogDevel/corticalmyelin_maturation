#!/usr/bin/env python
"""Heuristic for mapping 7T Brain Mechanisms MP2RAGE and B1 map data to BIDS"""
import os


def create_key(template, outtype=('nii.gz',), annotation_classes=None):
    if template is None or not template:
        raise ValueError('Template must be a valid format string')
    return template, outtype, annotation_classes

grouping = 'AcquisitionDate'
# **********************************************************************************


## MP2RAGE
inv1_phase = create_key(
    'sub-{subject}/{session}/anat/sub-{subject}_{session}_inv-1_part-mag_MP2RAGE')
inv1_mag = create_key(
    'sub-{subject}/{session}/anat/sub-{subject}_{session}_inv-1_part-phase_MP2RAGE')
inv2_phase = create_key(
    'sub-{subject}/{session}/anat/sub-{subject}_{session}_inv-2_part-mag_MP2RAGE')
inv2_mag = create_key(
    'sub-{subject}/{session}/anat/sub-{subject}_{session}_inv-2_part-phase_MP2RAGE')
UNI = create_key(
    'sub-{subject}/{session}/anat/sub-{subject}_{session}_UNIT1')
UNIDEN = create_key(
    'sub-{subject}/{session}/anat/sub-{subject}_{session}_acq-UNIDENT1_T1w')
T1 = create_key(
    'sub-{subject}/{session}/anat/sub-{subject}_{session}_T1map')

## B1 fmaps
tfl_b1map = create_key(
    'sub-{subject}/{session}/fmap/sub-{subject}_{session}_acq-famp_TB1TFL')


# **********************************************************************************

def infotodict(seqinfo):
    """Heuristic evaluator for determining which runs belong where
    allowed template fields - follow python string module:
    item: index within category
    subject: participant id
    seqitem: run number during scanning
    subindex: sub index within group
    """

    last_run = len(seqinfo)

    info = {

    inv1_phase: [],
    inv1_mag: [],
    inv2_phase: [],
    inv2_mag: [],
    UNI: [],
    UNIDEN: [],
    T1: [],
    tfl_b1map: []

    }

    for s in seqinfo:

        if "MP2RAGEPTX_TR6000_1mmiso_INV1_PHS_FILT" in s.series_description:
            info[inv1_phase].append(s.series_id)
        if ("MP2RAGEPTX_TR6000_1mmiso_INV1" in s.series_description) and ("M" in s.image_type):
            info[inv1_mag].append(s.series_id)
        if "MP2RAGEPTX_TR6000_1mmiso_INV2_PHS_FILT" in s.series_description:
            info[inv2_phase].append(s.series_id)
        if ("MP2RAGEPTX_TR6000_1mmiso_INV2" in s.series_description) and ("M" in s.image_type):
            info[inv2_mag].append(s.series_id)
        if "MP2RAGEPTX_TR6000_1mmiso_UNI_Images" in s.series_description:
            info[UNI].append(s.series_id)
        if ("MP2RAGEPTX_TR6000_1mmiso_UNI-DEN" in s.series_description) and ("mlBrainStrip" not in s.series_description):
            info[UNIDEN].append(s.series_id)
        if "MP2RAGEPTX_TR6000_1mmiso_T1_Images" in s.series_description:
            info[T1].append(s.series_id)
        #if "B1-abs-1slc-singleChannelMode-B1" in s.dcm_dir_name:
            #info[tfl_b1map].append(s.series_id)

    return info
