# RC2 Documentation

This folder contains the technical reference manual for RC2 modules and software usage guides, in reStructuredText.

## Install Prerequisites

1. Install [Sphinx](https://www.sphinx-doc.org/en/master/usage/installation.html)
2. Install the [sphinxcontrib-matlabdomain](https://github.com/sphinx-contrib/matlabdomain) extension
```
pip install sphinxcontrib-matlabdomain
```
3. Install the [Renku documentation Sphinx theme](https://pypi.org/project/renku-sphinx-theme/)
```
pip install renku-sphinx-theme
```

### Install Prerequisites for C++ Documentation
4. Install [Breathe](https://breathe.readthedocs.io/en/latest/index.html#)
```
pip install breathe
```

### doxygen Notes
C++ documentation for the RC2 libraries is generated via doxygen, which outputs an xml description of the C++ codebase. To rebuild the C++ documentation:

1. Install [doxygen](https://www.doxygen.nl/manual/install.html)
2. doxygen uses a configuration file (named Doxyfile by default) to build C++ docs. If one is not already present navigate to docs/doxygen and:
```
doxygen -g
```
3. Set the Doxyfile parameters:
- PROJECT_NAME    = ```<target-project-name>```
- INPUT           = ```<c++-directory>```
- RECURSIVE       = YES
- GENERATE_XML    = YES
- EXTRACT_PRIVATE = YES
4. Generate the documentation:
```
doxygen
```

## Build the docs

```
make html
```

## Troubleshooting

If the documentation project builds without errors but references to doxygen generated docs do not appear in the output, delete the docs/build folder and rebuild everything.