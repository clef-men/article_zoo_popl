#!/bin/bash

## Gabriel Scherer's arxival script
#
# This is a script to produce an 'arxiv.zip' archive that is ready for
# arxiv submission, so that re-submitting updated version is very
# easy.
#
# The script needs to be fine-tuned for each paper due to their
# varying dependencies etc.

MAIN=main
BIB=main

# By convention, we use arxiv/ as working directory,
# and zip it at the end.
#
# Leaving arxiv/ around is convenient as sometimes you want to try to
# build from there. To avoid reproducibility issues, the script fails
# if this directory already exists.

mkdir arxiv || { echo "error, you need to (rmdir arxiv)"; exit 1; }
rm -f arxiv.zip

cp abstract.md arxiv/
cp *.tex arxiv/
cp -r images arxiv/
cp -r figures arxiv/

# the ACM wants to have the .bbl source in addition to the bibliography
cp $BIB.bib arxiv/ # (unused) source .bib, for reference
stat $MAIN.bbl > /dev/null || { echo "you need to run bibtex first"; exit 1; }
cp $MAIN.bbl arxiv/

# Copy all local packages, class files, etc. that are necessary to build.
cp *.sty arxiv/
cp acmart.cls arxiv/
cp ACM-Reference-Format.bst arxiv/

# By convention, I write a script arxiv/build.sh,
# so that (cd arxiv; sh build.sh) should always
# work and produce a PDF. This is useful to check
# that I didn't forget some build dependencies.

(
    echo "pdflatex -shell-escape $MAIN.tex"
    echo "pdflatex -shell-escape $MAIN.tex"
    echo "pdflatex -shell-escape $MAIN.tex"
) > arxiv/build.sh

zip -r arxiv arxiv
echo "feel free to test the packed source in arxiv/, archive is arxiv.zip"
