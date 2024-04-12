#!/usr/bin/env python3

import sys, os, re
import logging
import argparse
from collections import defaultdict

logging.basicConfig(level=logging.INFO,
                    format='%(asctime)s : %(levelname)s : %(message)s',
                    datefmt='%H:%M:%S')
logger = logging.getLogger(__name__)


def main():

    parser = argparse.ArgumentParser(description="extract GTF records according to benchmarking categories",
                                     formatter_class=argparse.ArgumentDefaultsHelpFormatter)

    parser.add_argument("--gtf", type=str, required=True, help="reco gtf file")

    parser.add_argument("--tracking", type=str, required=True, help="tracking file from gffcompare")

    args = parser.parse_args()
    

    gtf_file = args.gtf
    tracking_file = args.tracking
    

    transcript_to_gtf_txt = parse_transcripts_from_gtf(gtf_file)

    # code chunk adapted from isoquant bmarking below:
    for line in open(input_tracking_file, "r"):
        # column[0]: unique internal id for the transfrag
        # column[1]: unique internal id for the super-locus containing these transcripts across all samples and the reference annotation
        # column[2]: gene name and transcript id of the reference record associated to this transcript
        # column[3]: type of overlap or relationship between the reference transcripts and the transcript structure represented by this row
        # columns[4:]: each following column showns the transcript for each sample/tool
        transcript_columns = line.strip().split()

        if transcript_columns[4] != '-' and transcript_columns[5] == '-' and transcript_columns[6] == '-':
            novel_fn += 1
        elif transcript_columns[4] != '-' and transcript_columns[5] != '-' and transcript_columns[6] == '-':
            known_fn += 1
        elif transcript_columns[4] != '-' and transcript_columns[5] != '-' and transcript_columns[6] != '-':
            known_tp += 1
        elif transcript_columns[4] != '-' and transcript_columns[5] == '-' and transcript_columns[6] != '-':
            novel_tp += 1
        elif transcript_columns[4] == '-' and transcript_columns[5] == '-' and transcript_columns[6] != '-':
            novel_fp += 1
        else:
            print("WARNING: This should not have happened! Current line: " + str(transcript_columns))







def parse_transcripts_from_gtf(gtf_file):

    transcript_to_gtf_txt = defaultdict(str)
    
    with open(gtf_file) as fh:
        for line in fh:
            m = re.search("transcript_id \"([^\"]+)\"", line)
            if m:
                transcript_id = m.group(1)
                transcript_to_gtf_txt[transcript_id] += line
                
    return transcript_to_gtf_txt

    

if __name__=='__main__':
    main()
