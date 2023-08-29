## Overview

This subdirectory contains files and scripts used to organize and conduct simulations from Stanley et al. (2023) (see this paper for simulation study details). The paper's study is divided in two parts. The first explores how the scree plot approach for selecting the number of factors behaves in different settings. The second compares the proposed post-processed estimator for the global covariance to those computed by alternative means.


## Running the Simulation

Perform the following steps to carry out simulations described in the paper. All commands should be run from within the project's root directory on the command line. 

### Setup

1. Create a "design" file called `design-id.yml`. This design file contains information needed to carry out a simulation. To replicate the simulation from the paper, copy and paste the below information into your design file, replaceing `path/to/scratch` with the path of your choice.  

```
scratch_root: path/to/scratch
M: 30
num_reps: 100
num_reps_rank: 1
delta_est: 0.1
train_prop: 0.8
num_tuning_reps: 1
K_max: 8
loading_schemes: [bump01, net01]
Ks: [2, 4]
loading_scale_ranges: [[2, 3], [0.8, 1.8]]
error_schemes: [bump01, tri01]
Js: [900]
deltas: [0.05, 0.1]
error_scale_ranges: [[0.1, 1]]
num_samps: [250, 500, 1000]
```

Descriptions of important fields: 

- `M`: Grid resolution. 
- `Ks`: All ranks used across configurations.
- `deltas`: All bandwidths used across configurations.
- `loading_schemes`: All loading schemes used across scenarios.
- `loading_scale_ranges`: Ranges of loading scaling parameters used (in conjunction with `error_scale_ranges`) to determine regime. 
- `error_schemes`: All error schemes used across scenarios. 
- `error_scale_ranges`: Ranges of error scaling parameters used (in conjunction with `loading_scale_ranges`) to determine regime. 
- `num_samps`: All sample sizes used across configurations.
- `path/to/scratch`: Directory in which intermediate data files are stored. 


2. Create required directories by executing the following commands. 

```
# Set design ID
DESIGN_ID='design-id'

# Create directories
mkdir -p simulation/data/$DESIGN_ID
mkdir -p simulation/results/$DESIGN_ID
mkdir -p /path/to/scratch/ffa-p1/simulation/data/$DESIGN_ID
```


3. To (i) creates directories for design `design-id`, and (ii) generate a YAML file for each configuration of the design:

```
Rscript simulation/setup_simulation.R $DESIGN_ID > simulation/results/$DESIGN_ID/log-setup-simulation
```

4. To generate data for each configuration (~7 min. with 20 cores):

```
Rscript simulation/simulate_data.R $DESIGN_ID > simulation/results/$DESIGN_ID/log-simulate-data
```


5. To split data for each repetition of each configuration into a traning and test set (~2 min. with 20 cores):

```
Rscript simulation/split_data.R $DESIGN_ID > simulation/results/$DESIGN_ID/log-split-data
```


### Rank Selection

6. To tune the smoothing parameter for rank selection (~3.5 hr. with 16 cores):

```
matlab -nodisplay -nosplash -r "add_paths; tune_alpha('$DESIGN_ID', true); exit" > simulation/results/$DESIGN_ID/log-tune-alpha-rank
```

7. To generate a scree plot used for rank selection (~1.5 hr. with 16 cores):

```
matlab -nodisplay -nosplash -r "add_paths; select_rank('$DESIGN_ID'); exit" > simulation/results/$DESIGN_ID/log-rank-select
```

### Comparison

8. To perform estimation via PCA (~20 min. with 20 cores): 

```
Rscript simulation/estimate_L_via_KL.R $DESIGN_ID > simulation/results/$DESIGN_ID/log-estimate-L-kl
```

9. To perform esimation via the method presented in "Functional Data Analysis by Matrix Completion" by Descary and Panaretos (2019) (~3 hr. with 16 cores):

```
matlab -nodisplay -nosplash -r "add_paths; estimate_L('$DESIGN_ID', true, false); exit" > simulation/results/$DESIGN_ID/log-estimate-L-dp
```

10. To tune the smoothing parameter for comparison (~ _ hr. with 16 cores): 

```
matlab -nodisplay -nosplash -r "add_paths; tune_alpha('$DESIGN_ID', false); exit" > simulation/results/$DESIGN_ID/log-tune-alpha-comparison
```

11. To perform estimation via the method proposed in Stanley et al. (2023) without post-processing (~_ hr. with ): 

```
matlab -nodisplay -nosplash -r "add_paths; estimate_L('$DESIGN_ID', true, true); exit" > simulation/results/$DESIGN_ID/log-estimate-L-dps
```

12. To tune the shrinkage parameter:

```
Rscript simulation/tune_kappa.R $DESIGN_ID > simulation/results/$DESIGN_ID/log-tune-kappa
```

13. To post-process the estimates from Step 11: 

```
Rscript simulation/postprocess_L.R $DESIGN_ID > simulation/results/$DESIGN_ID/log-postprocess-L
```




