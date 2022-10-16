#!/usr/bin/env python3


"""This script moves duplicate images listed in a text file to a new location,
 retaining the one with the best resolution

 Generate the text file with paths to duplicate images using findimagedupes

 ie.,
 findimagedupes -R -- . > duplicates.txt

 Then
 ./remove.py duplicates.text (backupdir)

 NOTE: `findimagedupes` outputs a list where filenames are seperated by
 spaces. Thus the filepath cannot contain spaces

 nix shell nixpkgs#findimagedupes
 nix-shell -p findimagedupes
"""


import argparse
import shutil
import sys
from pathlib import Path

from PIL import Image


parser = argparse.ArgumentParser(
    description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter
)
parser.add_argument(
    "-f",
    "--file",
    type=str,
    required=True,
    help="path of file specifying duplicates. Output of findimagedupes",
)
parser.add_argument(
    "-b",
    "--backupdir",
    type=str,
    help="""directory to move the duplicate images into. Will be created if it
doesn't exist. Existing images will not be overwritten. If omitted it will be
set to `path/to/file/bak/`""",
)
parser.add_argument("-d", "--dryrun", action="store_true", help="no action")
parser.add_argument(
    "-v",
    "--verbosity",
    default=0,
    type=int,
    help="verbosity level. 2 for printing all images that are moved",
)


args = vars(parser.parse_args())
fn = args["file"]
backupdir = args["backupdir"]
verbosity = args["verbosity"]
dryrun = args["dryrun"]


if backupdir is None:
    # set it to the basedir where the textfile of duplicates resides
    # backupdir = Path.cwd() / "bak"
    backupdir = Path(fn).parent / "bak"

if dryrun:
    print("DRYRUN")

# create backupdir if it is not existing
Path(backupdir).mkdir(exist_ok=True)
print(f"###\nmoving duplicates to {backupdir}\n###")


with open(fn, "r") as f:
    for line in f:
        fpaths = line.rstrip("\n").split(" ")

        # get pixels of listed duplicates
        table = dict()
        for fp in fpaths:
            try:
                img = Image.open(fp)
                size = img.size
                pixels = size[0] * size[1]
                img.close()
                table[fp] = pixels
            except FileNotFoundError as e:
                print(f"{e}. Skipping")

        # remove image with highes resolution from table
        fp_best = max(table, key=table.get)
        best = {fp_best: table.pop(fp_best)}

        # move duplicates with lower resolution to backup dir in current dir
        if not dryrun:
            for fp, v in table.items():
                fn = Path(fp).name  # use .stem to get filename without extension
                shutil.move(src=fp, dst=backupdir)

        else:
            if verbosity > 1:
                print(f"best {best}")
                print(f"removing {table}\n")
