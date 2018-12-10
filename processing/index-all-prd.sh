#!/usr/bin/env bash

# Command arguments
# $1 = Optional mode:
#           Append 'force' to disable checking for data issues and push to Solr without prompting
#           Append 'noindex' to generate the files and do the checking but not push to Solr

SERVER="solr01-prd.bodleian.ox.ac.uk"

if [ ! "$1" == "force" ]; then
    # Give up if any one index fails or is abandoned
    set -e
fi

cd "${0%/*}"

# Re-index manuscripts (includes rebuilding customized manuscript HTML pages, which must be run first)
./generate-html.sh && ./generate-solr-document.sh manuscripts.xquery manuscripts_index.xml manuscript $SERVER $1

# Reindex people
./generate-solr-document.sh persons.xquery persons_index.xml person $SERVER $1

# Reindex works
./generate-solr-document.sh works.xquery works_index.xml work $SERVER $1

# Reindex subjects
./generate-solr-document.sh subjects.xquery subjects_index.xml subject $SERVER $1l
