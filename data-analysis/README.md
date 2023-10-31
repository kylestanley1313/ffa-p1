## Overview

This directory contains files used to conduct analyses of the PIOP1 dataset from the [Amsterdam Open MRI Collection (AOMIC)](https://nilab-uva.github.io/AOMIC.github.io/). This dataset is hosted on [OpenNeuro](https://openneuro.org/datasets/ds002785/versions/2.0.0) which provides various download methods. Extensive background on these data may be found in the article ["The Amsterdam Open MRI Collection, a set of multimodal MRI datasets for individual difference analyses"](https://www.nature.com/articles/s41597-021-00870-6) by Lukas Snoek, Maite M. van der Miesen, Tinka Beemsterboer, Andries van der Leij, Annemarie Eigenhuis and H. Steven Scholte. 


## Setup

[Slurm](https://slurm.schedmd.com/documentation.html) bash scripts used to perform the analysis described in Stanley et. al (2023) may be found in `slurm-scripts/`. Before doing so, some setup is required:

1. In the analysis file `data-analysis/analyses/aomic.yml`, replace:

    -  `<SCRATCH_ROOT>` with a directory in which to store intermediate files
    -  `<FSL_PATH>` with your FSL path
    -  `<DATASET_DIR>` with the root directory of the AOMIC-PIOP1 dataset

2. Slurm batch scripts for conducting this anlaysis follow the naming convention `analysis-<NUMBER>-<PURPOSE>` where `NUMBER` describes the order in which scripts should be executed and `PURPOSE` denotes the function of the script. Each script has several fields that must be populated (not all scripts require population of all fields):
   - `<ACCOUNT>`: Slurm account that will be charged for resources.
   - `<EMAIL>`: Email address that will receive notifications.
   - `<ROOT_DIR>`: Root directory of the `ffa-p1` project.
   - `<SRACTCH_ROOT_DIR>`: Same as `<SCRATCH_ROOT>` in `aomic.yml`.


## Execution

After setup, the batch scripts may be executed in order: 
```
$ sbatch analysis-1-preprocessing.sh
Submitted batch job <JOB1-ID>
$ sbatch --dependency=afterok:<JOB1-ID> analysis-2-splitting.sh
Submitted batch job <JOB2-ID>
$ sbatch --dependency=afterok:<JOB2-ID> analysis-3-alpha-testing.sh
Submitted batch job <JOB3-ID>
$ sbatch --dependency=afterok:<JOB3-ID> analysis-4-scree-plot.sh
Submitted batch job <JOB4-ID>
$ sbatch --dependency=afterok:<JOB4-ID> analysis-5-estimation.sh
Submitted batch job <JOB5-ID>
$ sbatch --dependency=afterok:<JOB5-ID> analysis-6-postprocessing.sh
Submitted batch job <JOB6-ID>
$ sbatch --dependency=afterok:<JOB6-ID> analysis-7-ica.sh
Submitted batch job <JOB7-ID>
$ sbatch --dependency=afterok:<JOB7-ID> analysis-8-plot.sh
Submitted batch job <JOB8-ID>
```


## Alterations

Alterations to the analysis performed in Stanley (2023) may be performed through a combination of changes to `aomic.yml` and to command line script arguments. 




