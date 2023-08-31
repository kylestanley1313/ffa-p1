library(argparser)
library(dplyr)
library(ggplot2)
library(ggpubr)
library(gridExtra)
library(reshape2)
library(RNifti)
library(stringr)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('data-analysis', 'utils', 'utils.R'))


p <- arg_parser("Script for plotting analysis results.")
p <- add_argument(p, "analysis.id", help = "ID of analysis")
args <- parse_args(p)
# args <- list(analysis.id = 'rs-sub-0181')  ## TODO: Remove

## Read analysis
analysis.id <- args$analysis.id
analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', paste0(analysis.id, '.yml'))
)
dir.dataset <- analysis$dirs$dataset
dir.results <- analysis$dirs$results
sub <- analysis$settings$sub_label
M1 <- analysis$settings$M1
M2 <- analysis$settings$M2
K <- analysis$settings$ffa$K
z <- analysis$settings$z_
alpha <- analysis$settings$ffa$alpha



## FFA
fname <- str_glue('mat-Lhatpp_K-{K}_alpha-{alpha}.csv.gz')
path <- file.path('data-analysis', 'data', analysis.id, fname)
L.mat <- csv_to_matrix(path)
path.mask <- file.path(
  dir.dataset,
  'derivatives', 'fmriprep', 
  str_glue('sub-{sub}'), 'func',
  str_glue('sub-{sub}_task-restingstate_acq-mb3_space-MNI152NLin2009cAsym_desc-brain_mask.nii.gz')
)
mask <- readNifti(path.mask)
dim(mask) <- c(M1*M2, dim(mask)[3])
masks <- matrix(rep(mask[,30], K), ncol = K)
L.mat <- masks*L.mat
L <- array_reshape(L.mat, c(M1, M2, K))

data <- melt(L)
colnames(data) <- c('x', 'y', 'k', 'val')
breaks <- c(-0.4, -0.2, 0, 0.2, 0.4)
p1 <- plot_loading(data, 1, 0, breaks)
p2 <- plot_loading(data, 2, 0, breaks)
p3 <- plot_loading(data, 3, 0, breaks)
p4 <- plot_loading(data, 4, 0, breaks)
p5 <- plot_loading(data, 5, 0, breaks)
p6 <- plot_loading(data, 6, 0, breaks)
g <- ggarrange(
  p1, p2, p3, p4, p5, p6,
  nrow = 3, ncol = 2, common.legend = TRUE, legend = 'bottom')
path <- file.path(dir.results, 'ffa-loadings.png')
ggexport(g, filename=path, width=500, height=800)

## ICA
path <- file.path('data-analysis', 'results', analysis.id, 'ica', 'melodic_IC.nii.gz')
img <- readNifti(path)
L <- img[,,z,]
data <- melt(L)
colnames(data) <- c('x', 'y', 'k', 'val')
breaks <- c(-4, -2, 0, 2, 4)
p1 <- plot_loading(data, 1, 0, breaks)
p2 <- plot_loading(data, 2, 0, breaks)
p3 <- plot_loading(data, 3, 0, breaks)
p4 <- plot_loading(data, 4, 0, breaks)
p5 <- plot_loading(data, 5, 0, breaks)
p6 <- plot_loading(data, 6, 0, breaks)
g <- ggarrange(
  p1, p2, p3, p4, p5, p6,
  nrow = 3, ncol = 2, common.legend = TRUE, legend = 'bottom')
path <- file.path(dir.results, 'ica-components.png')
ggexport(g, filename=path, width=500, height=800)
