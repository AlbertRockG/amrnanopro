#!/usr/bin/env python3
"""Checks, validate, and transform Oxford Nanopore Technologies reads sample sheet."""
import argparse
import csv
import logging
import pandas as pd
import sys
from collections import Counter
from pathlib import Path

logger = logging.getLogger()


class RowChecker:
    """
    Define a service that can validate and transform each given row.

    Attributes:
        modified (list): A list of dicts, where each dict corresponds to a previously
        validated and transformed row. The order of rows is maintained.

    """

    VALID_FORMATS = (
        ".fast5",
        ".fq.gz",
        ".fastq.gz",
    )

    def __init__(
        self,
        sample_col="sample",
        filepath_col ="file_path",
        **kwargs,
    ):
        """
        Initialize the row checker with the expected column names.

        Args:
            sample_col (str): The name of the column that contains the sample name
                (default "sample").
            filepath_col (str): The path to the file fast5 or fastq to process
                (default "filepath")
        """
        super().__init__(**kwargs)
        self._sample_col = sample_col
        self._filepath_col = filepath_col
        self._seen = set()
        self.modified = []

    def validate_q_and_transform(self, row):
        """
        Perform all validations on the given row and insert the read pairing status.

        Args:
            row (dict): A mapping from column headers (keys) to elements of that row
                (values).

        """
        self._validate_sample(row)
        self._validate_fastq_filepath(row)
        self._seen.add((row[self._sample_col], row[self._filepath_col]))
        self.modified.append(row)

    def validate_5_and_transform(self, row):
        """
        Perform all validations on the given fast5 row and insert the read pairing status.

        Args:
            row (dict): A mapping from column headers (keys) to elements of that row
                (values).

        """
        self._validate_sample(row)
        self._validate_fast5_filepath(row)
        self._seen.add((row[self._sample_col], row[self._filepath_col]))
        self.modified.append(row)

    def _validate_sample(self, row):
        """Assert that the sample name exists and convert spaces to underscores."""
        if len(row[self._sample_col]) <= 0:
            raise AssertionError("Sample input is required.")
        # Sanitize samples slightly.
        row[self._sample_col] = row[self._sample_col].replace(" ", "_")

    def _validate_fast5_filepath(self, row):
        """Assert that the FAST5 file path entry is non-empty and has the right format."""
        if len(row[self._filepath_col]) <= 0:
            raise AssertionError("At least one FAST5 file is required.")
        self._validate_fast5_format(row[self._filepath_col])

    def _validate_fastq_filepath(self, row):
            """Assert that the FAST5 file path entry is non-empty and has the right format."""
            if len(row[self._filepath_col]) <= 0:
                raise AssertionError("At least one FAST5 file is required.")
            self._validate_fastq_format(row[self._filepath_col])

    def _validate_fast5_format(self, filename):
        """Assert that a given fast5 file path has the expected fast5 extension."""
        if not filename.endswith(self.VALID_FORMATS[0]):
            raise AssertionError(
                f"The FAST5 file has an unrecognized extension: {filename}\n"
                f"It should be this: {self.VALID_FORMATS[0]}"
            )

    def _validate_fastq_format(self, filename):
        """Assert that a given filename has one of the expected FASTQ extensions."""
        if not any(filename.endswith(extension) for extension in self.VALID_FORMATS[1:]):
            raise AssertionError(
                f"The FASTQ file has an unrecognized extension: {filename}\n"
                f"It should be one of: {', '.join(self.VALID_FORMATS)}"
            )

    def validate_unique_samples(self):
        """
        Assert that the combination of sample name and FASTQ filename is unique.

        In addition to the validation, also rename all samples to have a suffix of _T{n}, where n is the
        number of times the same sample exist, but with different FASTQ files, e.g., multiple runs per experiment.

        """
        if len(self._seen) != len(self.modified):
            raise AssertionError("The pair of sample name and FASTQ must be unique.")
        seen = Counter()
        for row in self.modified:
            sample = row[self._sample_col]
            seen[sample] += 1
            row[self._sample_col] = f"{sample}_T{seen[sample]}"


# def read_head(handle, num_lines=10):
#     """Read the specified number of lines from the current position in the file."""
#     lines = []
#     for idx, line in enumerate(handle):
#         if idx == num_lines:
#             break
#         lines.append(line)
#     return "".join(lines)


def is_fast5_files(file_in):
    """
    Check the tag provided by the user to identify the format of the files.

    Args:
        in_handle (file object).
    """
    with file_in.open(newline="") as in_handle:
        table_tag = in_handle.readline()
        if "#FAST5" in table_tag:
            return True
        elif "#NANO_FASTQ" in table_tag:
            return False
        else:
            return None

def validate_qrows(reader):
    checker = RowChecker()
    for i, row in enumerate(reader):
        try:
            checker.validate_q_and_transform(row)
        except AssertionError as error:
            logger.critical(f"{str(error)} On line {i + 2}.")
            sys.exit(1)
    checker.validate_unique_samples()
    return checker

def validate_5rows(reader):
    checker = RowChecker()
    for i, row in enumerate(reader):
        try:
            checker.validate_5_and_transform(row)
        except AssertionError as error:
            logger.critical(f"{str(error)} On line {i + 2}.")
            sys.exit(1)
    checker.validate_unique_samples()
    return checker

def check_samplesheet(file_in, file_out):
    """
    Check that the tabular samplesheet has the structure expected by nf-core pipelines.

    Validate the general shape of each table, expected columns, and each row. Also add
    an additional column which records whether one or two FASTQ reads were found.

    Args:
        file_in (pathlib.Path): The given tabular samplesheet. The format can be either
            CSV, TSV, or any other format automatically recognized by ``csv.Sniffer``.
        file_out (pathlib.Path): Where the validated and transformed samplesheet should
            be created; always in CSV format.

            Example:
        This function checks that the samplesheet follows the following structure:

            #FAST5
            sample,file_path
            SAMEA112464067,ERR10857133.fast5
            SAMEA112464070,ERR10857136.fast5
            SAMEA112464073,ERR10857139.fast5
            SAMEA112464091,ERR10857157.fast5

        or this structure:

            #NANO_FASTQ
            sample,file_path
            SAMEA112464067,ERR10857133.fastq.gz
            SAMEA112464070,ERR10857136.fastq.gz
            SAMEA112464073,ERR10857139.fastq.gz
            SAMEA112464091,ERR10857157.fastq.gz
    """
    required_columns = {"sample", "file_path"}
    with file_in.open(newline="") as in_handle:
        csv_df = pd.read_csv(in_handle, header=1)
        reader = csv_df.to_dict('records')
        # Validate the existence of the expected header columns.
        provided_columns = {column for column in reader[0].keys()}
        if not required_columns.issubset(provided_columns):
            req_cols = ", ".join(required_columns)
            logger.critical(
                f"The sample sheet **must** contain these column headers: {req_cols}."
                )
            sys.exit(1)
        # Validate each row based on the provided tag
        if is_fast5_files(file_in):
            checker = validate_5rows(reader)
        if not is_fast5_files(file_in):
            checker = validate_qrows(reader)
        if is_fast5_files(file_in) == None:
            logger.critical(f"The required tag **must** be provided!")
    # Write validated rows in new csv file: {filename}.validated.csv
    header = list(provided_columns)
    with file_out.open(mode="w", newline="") as out_handle:
        writer = csv.DictWriter(out_handle, header, delimiter=",")
        writer.writeheader()
        for row in checker.modified:
            writer.writerow(row)


def parse_args(argv=None):
    """Define and immediately parse command line arguments."""
    parser = argparse.ArgumentParser(
        description="Validate and transform a tabular samplesheet.",
        epilog="Example: python check_samplesheet.py samplesheet.csv samplesheet.valid.csv",
    )
    parser.add_argument(
        "file_in",
        metavar="FILE_IN",
        type=Path,
        help="Tabular input samplesheet in CSV or TSV format.",
    )
    parser.add_argument(
        "file_out",
        metavar="FILE_OUT",
        type=Path,
        help="Transformed output samplesheet in CSV format.",
    )
    parser.add_argument(
        "-l",
        "--log-level",
        help="The desired log level (default WARNING).",
        choices=("CRITICAL", "ERROR", "WARNING", "INFO", "DEBUG"),
        default="WARNING",
    )
    return parser.parse_args(argv)


def main(argv=None):
    """Coordinate argument parsing and program execution."""
    args = parse_args(argv)
    logging.basicConfig(level=args.log_level, format="[%(levelname)s] %(message)s")
    if not args.file_in.is_file():
        logger.error(f"The given input file {args.file_in} was not found!")
        sys.exit(2)
    args.file_out.parent.mkdir(parents=True, exist_ok=True)
    check_samplesheet(args.file_in, args.file_out)


if __name__ == "__main__":
    sys.exit(main())
