## Overview

This directory contains files used to conduct the three simulation studies described in Stanley et al. (2024+):
1. **Accuracy Comparison:** Compares the accuracy of the proposed post-processed estimator for the global covariance to those computed by alternative methods.
2. **Interpretability Comparison:** Compares the interpretability of the proposed post-processed estimator for the global covariance to those computed by alternative methods.
3. **Rank Selection:** Explores how the scree plot approach for selecting the number of factors behaves in different settings. 


## Setup

Design files containing simulation-specific configurations are stored in `simulation/designs`. [Slurm](https://slurm.schedmd.com/documentation.html) bash scripts used to perform the simulations described in Stanley et al. (2024+) may be found in `slurm-scripts/`. Before replicating each of the above studies, some setup is required: 

### Accuracy Comparison

1. The template design file `simulation/designs/DESIGN_ID_ACC_COMP.yml` is prepopulated with the configurations used in the accuracy comparison study of Stanley et al. (2024+). You should make the following edits to this file:

- Rename the file using a design ID of your choice (e.g., `comp-acc.yml`).
- Replace `<SCRATCH_ROOT>` with a directory (e.g., `path/to/scratch/ffa-p1`) in which to store intermediate files.
- Replace `<FSL_PATH>` with your FSL path.

2. The bash script `slurm-scripts/simulation-comp-acc.sh` may be used to execute the accuracy comparison study in Stanley et al. (2024+). It runs a sequence of Slurm batch scripts which can also be found in the `slurm-scripts/` directory. Before performing the simulations, make the following edits to `simulation-comp-acc.sh`:

- Replace `<ACCOUNT>` with the Slurm account that will be charged for resources.
- Replace `<EMAIL>` with the email address that will receive notifications.
- Replace `<WORK_ROOT>` with the working root directory of the `ffa-p1` project.
- Replace `<SRATCH_ROOT>` with the scratch root directory of the `ffa-p1` project where you will store intermediate files (same as `<SCRATCH_ROOT>` in `DESIGN_ID.yml`).
- Replace `<DESIGN_ID>` with the design file name, minus the extension (e.g., `comp-acc`).

### Interpretability Comparison

1. The template design files `simulation/designs/DESIGN_ID_INT_COMP_K8.yml` and `simulation/designs/DESIGN_ID_INT_COMP_K25.yml` are prepopulated with the configurations used in the interpretability comparison study of Stanley et al. (2024+). You should make the following edits to both file:

- Rename the file using a design ID of your choice (e.g., `comp-int-k8.yml` or `comp-int-k25.yml`).
- Replace `<SCRATCH_ROOT>` with a directory (e.g., `path/to/scratch/ffa-p1`) in which to store intermediate files.
- Replace `<FSL_PATH>` with your FSL path.

2. The bash script `slurm-scripts/simulation-comp-int.sh` may be used to execute the interpretability comparison study in Stanley et al. (2024+). It runs a sequence of Slurm batch scripts which can also be found in the `slurm-scripts/` directory. Before performing the simulations, make the following edits to `simulation-comp-int.sh`:

- Replace `<ACCOUNT>` with the Slurm account that will be charged for resources.
- Replace `<EMAIL>` with the email address that will receive notifications.
- Replace `<WORK_ROOT>` with the working root directory of the `ffa-p1` project.
- Replace `<SRATCH_ROOT>` with the scratch root directory of the `ffa-p1` project where you will store intermediate files (same as `<SCRATCH_ROOT>` in `DESIGN_ID.yml`).
- Replace `<DESIGN_ID_K8>` with the design file name used in place of `DESIGN_ID_INT_COMP_K8.yml`, minus the extension (e.g., `comp-int-k8`).
- Replace `<DESIGN_ID_K25>` with the design file name used in place of `DESIGN_ID_INT_COMP_K25.yml`, minus the extension (e.g., `comp-int-k25`).

  
## Rank Selection

1. The template design file `simulation/designs/DESIGN_ID_RANK.yml` is prepopulated with the configurations used in the rank selection study of Stanley et al. (2024+). You should make the following edits to this file:

- Rename the file using a design ID of your choice (e.g., `rank.yml`).
- Replace `<SCRATCH_ROOT>` with a directory (e.g., `path/to/scratch/ffa-p1`) in which to store intermediate files.

2. The bash script `slurm-scripts/simulation-rank.sh` may be used to execute the rank selection study in Stanley et al. (2024+). It runs a sequence of Slurm batch scripts which can also be found in the `slurm-scripts/` directory. Before performing the simulations, make the following edits to `simulation-comp-acc.sh`:

-  Replace `<ACCOUNT>` with the Slurm account that will be charged for resources.
-  Replace `<EMAIL>` with the email address that will receive notifications.
-  Replace `<WORK_ROOT>` with the working root directory of the `ffa-p1` project.
-  Replace `<SRATCH_ROOT>` with the scratch root directory of the `ffa-p1` project where you will store intermediate files (same as `<SCRATCH_ROOT>` in `DESIGN_ID.yml`).


## Execution

After setup, you may perform the simulation studies in Stanley et al. (2024+) by executing one of the following from this project's root directory:
```
$ sbatch slurm-scripts/simulation-comp-acc.sh ## for accuracy comparison
$ sbatch slurm-scripts/simulation-comp-int.sh ## for interpretability comparison
$ sbatch slurm-scripts/simulation-rank.sh ## for rank selection
```


## Alterations

It is also possible to use the described framework to perform simulations that are different from that described in Stanley et al. (2024+) by making edits to the design files. For instance: 

  - To perform simulations on a 25-by-25 grid, set `M: 25` in the design files.
  - To perform simulations under different "regimes" (i.e., signal-to-noise paradigms), edit the `loading_scale_ranges` field in the design file (see Stanley et al., 2024+ for details on how this parameter influences the difficulty of estimation).

Other alterations, such as using a custom loading/error scheme, are possible but require additions to the R code. 



