#!/usr/bin/env python3
"""Split the given sample sheet to get the nano.csv and illumina.csv if exists"""
import argparse
import logging
from pathlib import Path
import sys

logger = logging.getLogger()

def process_samplesheet(input_filepath, nano_filepath, illumina_filepath):
    """Process the sample sheet and split it in two csv files if illumina
    reads are provided.

    Args:
        input_filepath
    """
    with open(input_filepath, newline='') as csvfile, \
            open(nano_filepath, mode="w") as nano, \
            open(illumina_filepath, mode="w") as illumina:

        samplesheet = csvfile.readlines()

        # Iterate through the rest of the rows
        for row in samplesheet:
            if "#ILLUMINA_FASTQ" in row:
                break
            nano.write(row)

        # Iterate through again to illumina reads' rows to the illumina file
        for row in samplesheet:
            if len(row.split(",")) > 2:
                illumina.write(row)

def main(argv=None):
    parser = argparse.ArgumentParser(
        description="Process sample sheet and split into nano and Illumina csv files.",
        epilog="Example: python split_samplesheet.py samplesheet.csv nano.csv illumina.csv",
    )
    parser.add_argument(
        "--input",
        metavar="INPUT",
        type=Path,
        help="Path to the samplesheet CSV file."
        )
    parser.add_argument(
        "--output_nano",
        metavar="OUTPUT_NANO",
        type=Path,
        help="Path to the output nano CSV file."
        )
    parser.add_argument(
        "--output_illumina",
        metavar="OUTPUT_ILLUMINA",
        type=Path,
        help="Path to the output Illumina CSV file."
        )
    parser.add_argument(
        "--log-level",
        help="The desired log level (default WARNING).",
        choices=("CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG"),
        default="WARNING",
        )
    args = parser.parse_args(argv)
    logging.basicConfig(level=args.log_level, format="[%(levelname)s] %(message)s")
    if not args.input.is_file():
        logger.error(f"The given input file {args.input} was not found!")
        sys.exit(2)
    args.output_nano.parent.mkdir(parents=True, exist_ok=True)
    args.output_illumina.parent.mkdir(parents=True, exist_ok=True)
    process_samplesheet(args.input, args.output_nano, args.output_illumina)

if __name__ == "__main__":
    sys.exit(main())
