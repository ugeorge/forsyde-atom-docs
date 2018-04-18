# forsyde-atom-docs

Project for generating API documentation for [ForSyDe-Atom](https://github.com/forsyde/forsyde-atom) in various formats.

## Usage

The Makefile provided does pretty much everything needed. The most important targets are:

    make workspace     # needed at the beginning
    make clean         # cleans the generated files
    make remove        # removes the workspace
    make html          # creates HTML API
    make www           # API ready for WWW publishing