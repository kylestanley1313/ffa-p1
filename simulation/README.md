## Overview

This directory contains files used to conduct the simulation study described in Stanley et al. (2023). This study is divided in two parts: the first explores how the scree plot approach for selecting the number of factors behaves in different settings while the second compares the proposed post-processed estimator for the global covariance to those computed by alternative means.

## Setup

Design files containing simulation-specific configurations are stored in `simulation/designs`. [Slurm](https://slurm.schedmd.com/documentation.html) bash scripts used to perform the simulations described in Stanley et. al (2023) may be found in `slurm-scripts/`. Before replicating this study, some setup is required:

1. The template design file `simulation/designs/DESIGN_ID.yml` is prepoulated with the configurations used in the simulatoin study of Stanley et al. (2023). Before performing this study, make the following edits to `DESIGN_ID.yml`:

      -  Rename the file with a `DESIGN_ID` of your choice.
      -  Replace `<SCRATCH_ROOT>` with a directory (e.g., `path/to/scratch/ffa-p1`) in which to store intermediate files.

2. The bash script `slurm-scripts/simulation.sh` may be used to execute the simulations in Stanley et al. (2023). It runs a sequence of Slurm batch scripts which can also be found in the `slurm-scripts/` directory. Before performing the simulations, make the following edits to `simulation.sh`:

    -  Replace `<ACCOUNT>` with the Slurm account that will be charged for resources.
    -  Replace `<EMAIL>` with the email address that will receive notifications.
    -  Replace `<WORK_ROOT>` with the working root directory of the `ffa-p1` project.
    -  Replace `<SRATCH_ROOT>` with the scratch root directory of the `ffa-p1` project where you will store intermediate files (same as `<SCRATCH_ROOT>` in `DESIGN_ID.yml`).


## Execution

After setup, you may perform the simulation study in Stanley et al. (2023) by executing the following from this project's root directory:
```
$ sbatch slurm-scripts/simulation.sh
```


## Alterations

It is also possible to use the described framework to perform simulations that are different from that described in Stanley et al. (2023) by making edits to the design file. For instance: 

  - To perform simulations on a 25-by-25 grid, set `M: 25` in the design file.
  - To perform simulations under different "regimes" (i.e., signal-to-noise paradigms), edit the `loading_scale_ranges` field in the design file (see Stanley et al., 2023 for details on how this parameter influences the difficulty of estimation).

Other alterations, such as using a custom loading/error scheme, are possible but require additions to the R code. 



