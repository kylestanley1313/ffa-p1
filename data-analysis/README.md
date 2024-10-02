## Overview

This directory contains files used to conduct analyses of the PIOP1 dataset from the [Amsterdam Open MRI Collection (AOMIC)](https://nilab-uva.github.io/AOMIC.github.io/). This dataset is hosted on [OpenNeuro](https://openneuro.org/datasets/ds002785/versions/2.0.0) which provides various download methods. Extensive background on these data may be found in the article titled "The Amsterdam Open MRI Collection, a set of multimodal MRI datasets for individual difference analyses" by Lukas Snoek, Maite M. van der Miesen, Tinka Beemsterboer, Andries van der Leij, Annemarie Eigenhuis and H. Steven Scholte [[Article]](https://www.nature.com/articles/s41597-021-00870-6). 


## Setup

Analysis files containing analysis-specific configurations are stored in `data-analysis/analyses`. [Slurm](https://slurm.schedmd.com/documentation.html) bash scripts used to perform the analysis described in Stanley et al. (2024+) may be found in `slurm-scripts/`. Before running the analysis, some setup is required:

1. The template analysis file `data-analysis/analyses/ANALYSIS_ID.yml` is prepopulated with the configurations used in the analysis of Stanley et al. (2024+). Before performing this analysis, make the followin edits to `ANALYSIS_ID.yml`:

    -  Replace `<ANALYSIS_ID>` with a name that uniquely identifies the analysis to be conducted (you must also rename the template analysis file accordingly).
    -  Replace `<SCRATCH_ROOT>` with a directory (e.g., `path/to/scratch/ffa-p1`) in which to store intermediate files.
    -  Replace `<FSL_PATH>` with your FSL path.
    -  Replace `<DATASET_DIR>` with the root directory of the AOMIC-PIOP1 dataset.

2. The batch script `slurm_scripts/analysis.sh` may be used to execute the analysis in Stanley et al. (2024+). It runs a sequence of Slurm batch scripts which can also be found in the `slurm-scripts/` directory. Before performing the analysis, make the following edits to `analysis.sh`:

    -  Replace `<ACCOUNT>` with the Slurm account that will be charged for resources.
    -  Replace `<EMAIL>` with the email address that will receive notifications.
    -  Replace `<WORK_ROOT>` with the working root directory of the `ffa-p1` project.
    -  Replace `<SRATCH_ROOT>` with the scratch root directory of the `ffa-p1` project where you will store intermediate files (same as `<SCRATCH_ROOT>` in `ANALYSIS_ID.yml`).


## Execution

After setup, you may perform the analysis in Stanley et al. (2024+) by executing the following from this project's root directory:
```
$ sbatch slurm-scripts/analysis.sh
```


## Alterations

It is also possible to use the described framework to perform analyses that are different from that described in Stanley et al. (2023) by making edits to the analysis file. For instance: 

  - To perform the analysis on only subjects 1, 2, and 3, set `all_subs: no` and `sub_nums: [1, 2, 3]` in the analysis file.
  - To perform the analysis on the 20th axial slice, set `z_: 20` in the analysis file.

Other changes, such as editing the smoothing and/or bandwidth parameters are also possible, but require changes to the Slurm scripts. 


## Multi-Scale ICA

Supplement A to Stanley et al. (2024+) adapts the multi-scale ICA method of [Iraji et al. (2023)](https://onlinelibrary.wiley.com/doi/full/10.1002/hbm.26472) to the AOMIC data. To replicate this application, you may run the following from this project's root directory:
```
$ sbatch slurm-scripts/analysis-iraji.sh <WORK_ROOT> <ANALYSIS_ID>
```
where you should:
- replace `<WORK_ROOT>` with the project's root directory;
- replace `<ANALYSIS_ID>` with a name that uniquely identifies the analysis to be conducted (to replicate the analysis of the supplement, use the configurations provided in the template file `ANALYSIS_ID.yml`).





