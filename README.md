# Mïmis

## The Goal

A relable search system for [IPFS](//ipfs.io) bootstrapped soely from IPFS itself.

The gist is a program creates a forest of trees to the various content. For example, the book A Wizard of Earthsea by Ursula K. LeGuinn; paths to it might include:

* /A Wizard of Earthsea by Ursula K. LeGuinn
* /book/by/Ursula K. LeGuinn/A Wizard of Earthsea
* /award/Hugo/1978/Best Novella

There are myriad others.  Those are saved as directories and symlinks in IPFS.

[PouchDB](//pouchdb.com) reads in these tens of thousands of entries and runs an autocomplete off them.

The goal is to be able to aggregate from several sources so that the metadata tree covers as much of what we might want to find as possible.

Users should be able to dedicate a portion of their storage to preservation and whereas pinning saves the entire file, preserving randomly pins subsections of all the preserved data.

## Current Status

I've got the list of [Hugo Award](//thehugoaward.com) winners and nominees and I'm working at generating a context forest.

The interface is meant to terminate at the actual data, so I'm working on a way to increase the corpus.