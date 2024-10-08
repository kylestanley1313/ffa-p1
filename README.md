# ffa-p1

A repository containing code used in the paper titled "Functional Factor Modeling of Brain Connectivity" by Kyle Stanley, Nicole A. Lazar, and Matthew Reimherr (2024+) [[Preprint]](https://arxiv.org/abs/2409.13963).

## Getting Started

To use the code in this repository, you must have the following: 

1. An installation of R 4.2.2 or newer. 
2. An installation of MATLAB 2023a or newer with access to the Optimization toolbox.
3. An installation of Conda 4.10.1 or newer.
4. If you would like to reproduce ICA plots from Stanley et al. (2024+), an installation of FSL 5.0.10 or newer.
5. If you would like to reproduce simulation and analysis results from the paper, access to a high performance computing environment using the Slurm workload manager. 


To get started with this project using conda, navigate to the repository's root directory, then execute the commands below. 

```
conda env create --prefix ./.conda -f environment.yml
conda activate ffa-p1
```

## Organization

This repository is organized into subdirectories as follows: 

- `estimation`: MATLAB functions used in estimation procedures. 
- `utils`: Various utility functions. 
- `simulation`: Files and scripts used to organize and conduct simulations. 
- `data-analysis`: Files and scripts used to organize and perform analysis of resting-state fMRI data.
- `slurm-scripts`: Slurm batch scripts used to run analyses and simulations.
