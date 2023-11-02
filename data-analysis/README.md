## Overview

This directory contains files used to conduct analyses of the PIOP1 dataset from the [Amsterdam Open MRI Collection (AOMIC)](https://nilab-uva.github.io/AOMIC.github.io/). This dataset is hosted on [OpenNeuro](https://openneuro.org/datasets/ds002785/versions/2.0.0) which provides various download methods. Extensive background on these data may be found in the article ["The Amsterdam Open MRI Collection, a set of multimodal MRI datasets for individual difference analyses"](https://www.nature.com/articles/s41597-021-00870-6) by Lukas Snoek, Maite M. van der Miesen, Tinka Beemsterboer, Andries van der Leij, Annemarie Eigenhuis and H. Steven Scholte. 


## Setup

Analysis files containing analysis-specific configurations are stored in `data-analysis/analyses`. [Slurm](https://slurm.schedmd.com/documentation.html) bash scripts used to perform the analysis described in Stanley et. al (2023) may be found in `slurm-scripts/`. Before running the analysis, some setup is required:

1. The template analysis file `data-analysis/analyses/ANALYSIS_ID.yml` is prepopulated with the configurations used in the analysis of Stanley et al. (2023). Before performing this analysis, make the followin edits to `ANALYSIS_ID.yml`:

    -  Replace `<ANALYSIS_ID>` with a name that uniquely identifies the analysis to be conducted (you must also rename the template analysis file accordingly).
    -  Replace `<SCRATCH_ROOT>` with a directory in which to store intermediate files.
    -  Replace `<FSL_PATH>` with your FSL path.
    -  Replace `<DATASET_DIR>` with the root directory of the AOMIC-PIOP1 dataset.

4. The batch script `slurm_scripts/analysis.sh` may be used to execute the analysis in Stanley et al. (2023). It runs a sequence of Slurm batch scripts which can also be found in the `slurm-scripts/` directory. Before performing the analysis, make the following edits to `analysis.sh`:

    -  Replace `<ACCOUNT>` with the Slurm account that will be charged for resources.
    -  Replace `<EMAIL>` with the email address that will receive notifications.
    -  Replace `<ROOT_ROOT>` with the working root directory of the `ffa-p1` project.
    -  Replace `<SRATCH_ROOT>` with the scratch root directory of the `ffa-p1` project where you will store intermediate files (same as `<SCRATCH_ROOT>` in `ANALYSIS_ID.yml`).


## Execution

After setup, you may perform the analysis in Stanley et al. (2023) by executing the following from this project's root directory:
```
$ sbatch slurm-scripts/analysis.sh
```


## Alterations

It is also possible to use the described framework to perform analyses that are different from that described in Stanley et al. (2023) by making edits to the analysis file. For instance: 

  - To perform the analysis on only subjects 1, 2, and 3, edit analysis file fileds as follows: `all_subs: no` and `sub_nums: [1, 2, 3]`.
  - To perform the analysis on the 20th axial slice, edit analysis file fields as follows: `z_: 20`.

Other changes, such as editing the smoothing and/or bandwidth parameters are also possible, but require changes to the Slurm scripts. 




