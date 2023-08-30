## Overview

This directory contains files used to carry out analyses of data from the [Amsterdam Open MRI Collection (AOMIC)](https://nilab-uva.github.io/AOMIC.github.io/). Download links for these data may be found at the previous link. Extensive background on these data may be found in the article ["The Amsterdam Open MRI Collection, a set of multimodal MRI datasets for individual difference analyses"](https://www.nature.com/articles/s41597-021-00870-6) by Lukas Snoek, Maite M. van der Miesen, Tinka Beemsterboer, Andries van der Leij, Annemarie Eigenhuis and H. Steven Scholte. 


## Running the Analysis

Run the following sequence of commands from within this project's root directory to carry out the analysis described in Stanley et. al (2023). Approximate runtimes are given for each script execution on a given number of CPU cores.

### Setup

1. Create an "analysis" file called `analysis-id.yml`. This analysis file contains information needed to carry out an analysis. To replicate the simulation from the paper, copy and paste the below information into your design file, replacing the `path/to/...` fields with your desired paths.

```
scratch_root: path/to/scratch
dirs:
  dataset: path/to/dataset
  data: data-analysis/data/analysis-id
  results: data-analysis/results/analysis-id
settings:
  sub_label: 0181
  z_: 30
  N_: ~
  M1: ~
  M2: ~
  ffa:
    prop_train: 0.7
    num_tests: 1
    K: 8
    delta: 0.1
    alpha: ~
    kappas: ~
  ica:
    fsl_path: path/to/your/fsl
    sigma_smoothing: 1
    num_comps: 8
```

Descriptions of imporant fields: 

- `sub_label`: Label of subject to be analyzed.
- `z_`: Horizontal slice of the brain to study.
- `N_`: (Populated by `preprocess.R`) Number of time points in scan.
- `M1`: (Populated by `preprocess.R`) Grid resolution in `x` direction.
- `M2`: (Populated by `preprocess.R`) Grid resolution in `y` direction.
- `prop_train`: Proportion of time slices to use for training.
- `K`: Initially, a large value used in smoothness tuning. Later, manually changed to the number of loading tensors to estimate.
- `delta`: Bandwidth to use in estimation.
- `alpha`: Initially empty. Later, manually changed to the tuned value of the smoothing parameter.
- `kappas`: (Populated by `tune_kappa_analysis.R`) Vector of shrinkage parameters. 
- `fsl_path`: If performing MELODIC ICA, populate with your FSL path.
- `sigma_smoothing`: Value of smoothing parameter in MELODIC ICA.
- `num_comps`: Number of independent components to estimate.
- `dataset`: Path to AOMIC data.
- `scratch_root`: Directory in which intermediate files are stored. 

2. To create required directories:

```
# Set analysis ID
ANALYSIS_ID='analysis-id'

# Create directories
mkdir -p data-analysis/data/$ANALYSIS_ID
mkdir -p data-analysis/results/$ANALYSIS_ID
mkdir -p /path/to/scratch/ffa-p1/data-analysis/data/$DESIGN_ID
```

3. To preprocess data (~1 hr. with 20 cores):

```
Rscript data-analysis/preprocess.R $ANALYSIS_ID > data-analysis/results/$ANALYSIS_ID/log-preprocessing
```

4. To split data into training and test sets:

```
Rscript data-analysis/split_samples.R $ANALYSIS_ID > data-analysis/results/$ANALYSIS_ID/log-splitting
```

### FFA

5. To manually choose a smoothing parameter, plot `K` loadings for a variety of smoothing parameters:

```
ALPHAS='[0 10 20 30 40 50 60 70]'  # Values of smoothing parameter to test
matlab -nodisplay -nosplash -r "add_paths; estimate_L_analysis('$ANALYSIS_ID', 'Lhat', $ALPHAS); exit" > data-analysis/results/$ANALYSIS_ID/log-alpha-testing
Rscript data-analysis/plot_smoothed_loadings.R $ANALYSIS_ID "$ALPHAS"
```

After inspecting plots, choose a value for smoothing parameter and, within `analysis-id.yml`, set `alpha` to that value. In our analysis, we set `alpha` to 30.

6. To generate the scree plot used to choose the number of factors `K`:

```
KMAX='15'  # The scree plot will go up to this number of factors
matlab -nodisplay -nosplash -r "add_paths; create_scree_plot('$ANALYSIS_ID', $KMAX); exit" > data-analysis/results/$ANALYSIS_ID/log-scree-plot
```

After inspecting the scree plot, set `K` equal to the chosen number of factors. In our analysis, we set `K` equal to 6. 

7. To obtain initial loading estimates for the full and training data:

```
matlab -nodisplay -nosplash -r "add_paths; estimate_L_analysis('$ANALYSIS_ID', 'Lhat'); exit" > data-analysis/results/$ANALYSIS_ID/log-alpha-estimation
matlab -nodisplay -nosplash -r "add_paths; estimate_L_analysis('$ANALYSIS_ID', '$LNAME', nan, 1, 'train'); exit" > data-analysis/results/$ANALYSIS_ID/log-alpha-estimation-train
```

8. To post-process the initial loading estimates:

```
Rscript data-analysis/tune_kappa_analysis.R $ANALYSIS_ID > data-analysis/results/$ANALYSIS_ID/log-tune-kappa
Rscript data-analysis/postprocess_L_analysis.R $ANALYSIS_ID > data-analysis/results/$ANALYSIS_ID/log-postprocess-L
```

### ICA

9. To perform MELODIC ICA on the same data:

```
Rscript data-analysis/melodic_ica.R $ANALYSIS_ID > data-analysis/results/$ANALYSIS_ID/log-melodic-ica
```

### Plotting

10. To generate scree plot, plot of estimated loading functions, and plot of estimated independent components:

```
Rscript data-analysis/plot_results.R $ANALYSIS_ID
```




