#Introduction

`pdb_to_chains.pl` is a simple script for generating a PDB file for each chain
in a multi-chain PDB file. In particular, it is designed to aid in keeping a
database of single-chain PDB files mirroring a local copy of the PDB.

#Usage

Usage is extremely simple. The following command will process the files
`1abc.ent` and `4xyz.ent`:

    pdb_to_chains.pl $PDBDIR 1abc.ent 4xyz.ent

It is assumed that `$PDBDIR` is a directory containing a copy of the RCSB's
[FTP archive][1]. That is, under `$PDBDIR` is the following hierarchy:

    $PDBDIR
    └── pdb
        ├── 00
        │   ├── pdb100d.ent.gz
        │   ├── pdb200d.ent.gz
        │   ├── pdb200l.ent.gz
        │   ├── pdb300d.ent.gz
        │   └── pdb400d.ent.gz
        ├── 01
        │   ├── pdb101d.ent.gz
        │   ├── pdb101m.ent.gz
        │   ├── pdb201d.ent.gz
        │   ├── pdb201l.ent.gz
        │   ├── pdb301d.ent.gz
        │   └── pdb401d.ent.gz
        ├── 02
        │   ├── pdb102d.ent.gz
        │   ├── pdb102l.ent.gz
        │   ├── pdb102m.ent.gz
        │   ├── pdb202d.ent.gz
        SNIP

If `1abc.ent` contains chains A, B and C then the files `c1abcA_.pdb`,
`c1abcB_.pdb` and `c1abcC_.pdb` will be produced. Optionally, the **-m**
(**--middle**) option may be supplied to `pdb_to_chains.pl`, in which case the
output will be placed in subdirectories named with the middle two characters of
the PDB ID (`ab/c1abcA_.pdb`, etc). Output is always generated in the current
directory.

If the **-l** (**--list**) option is supplied, PDB files are also read from a
list file.

#Rsync integration

This script is designed to work with existing cron jobs that rsync the PDB
archive. As such, lines from the file specified by **--list** are ignored if
they do not contain a file name, or if they contain the text "deleted". This
allows rsync logs to be piped directly into `pdb_to_chains.pl`.

For example:

    zcat rsyncLog.gz | pdb_to_chains.pl -l - -m


[1]: ftp://ftp.wwpdb.org/pub/pdb/data/structures/divided/
