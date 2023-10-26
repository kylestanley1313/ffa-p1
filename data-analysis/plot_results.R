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
p <- add_argument(p, "--analysis_type", help = "Analysis type (choices: ffa, ica).")
p <- add_argument(p, "--smooth", type = 'numeric', help = "FFA/ICA smoothing parameter for which to plot results.")
p <- add_argument(p, "--ncomps", type = 'numeric', help = "FFA/ICA rank parameter for which to plot results.")
p <- add_argument(p, "--scree_plot", flag = TRUE, help = "Flag to create scree plot (for ffa).")
p <- add_argument(p, "--no_migp", flag = TRUE, help = "Flag to plot for ICA not using MIGP (for ica).")
p <- add_argument(p, "--no_varnorm", flag = TRUE, help = "Flag to plot for ICA not using variance normalization (for ica).")
p <- add_argument(p, "--nonlinearity", default = 'pow3', help = "Nonlinearity used during ICA unmixing.")
args <- parse_args(p)
analysis.type <- args$analysis_type
smooth <- args$smooth
ncomps <- args$ncomps
scree.plot <- args$scree_plot
migp <- ifelse(args$no_migp, 'no', 'yes')
varnorm <- ifelse(args$no_varnorm, 'no', 'yes')
nonlinearity <- args$nonlinearity

## Read analysis
analysis.id <- args$analysis.id
analysis <- yaml.load_file(
  file.path('data-analysis', 'analyses', paste0(analysis.id, '.yml'))
)
dir.data <- analysis$dirs$data
dir.results <- analysis$dirs$results
M1 <- analysis$settings$M1
M2 <- analysis$settings$M2
z <- analysis$settings$z_


## FFA =========================================================================

# [PAPER] Scree and ratio plots
if (analysis.type == 'ffa' & scree.plot) {
  path <- file.path(dir.results, 'data_rank_select.csv')
  data.rank <- read.csv(path)
  ratio <- (data.rank$fit[1:(length(data.rank$fit)-1)] / 
              data.rank$fit[2:length(data.rank$fit)])
  data.rank$ratio <- c(ratio, NA)
  g1 <- data.rank %>%
    ggplot(aes(K, fit)) +
    geom_point() + 
    geom_vline(xintercept = 12, color = 'red', linetype = 'dashed') + 
    labs(x = 'j', y = 'g(j)') + 
    theme(text = element_text(size=30))
  g2 <- data.rank[1:(length(data.rank$fit)-1),] %>%
    ggplot(aes(K, ratio)) +
    geom_point() +
    geom_hline(yintercept = 1, linetype = 'dotted') +
    geom_vline(xintercept = 12, color = 'red', linetype = 'dashed') + 
    labs(x = 'i', y = 'g(i) / g(i+1)')  + 
    theme(text = element_text(size=30))
  g <- ggarrange(g1, g2, nrow = 1)
  path <- file.path(dir.results, 'rs-scree-plot.png')
  ggexport(g, filename=path, height=600, width=1600)
}


if (analysis.type == 'ffa') {
  
  # [PAPER] Loadings
  fname <- str_glue('mat-Lhatpp_K-{ncomps}_alpha-{smooth}.csv.gz')
  path <- file.path('data-analysis', 'data', analysis.id, fname)
  L.mat <- csv_to_matrix(path)
  path.mask <- file.path('data-analysis','data', str_glue('common_mask_z-{z}.nii.gz'))
  mask <- readNifti(path.mask)
  dim(mask) <- c(M1*M2, 1)
  masks <- matrix(rep(mask, ncomps), ncol = ncomps)
  L.mat <- masks*L.mat
  L <- array_reshape(L.mat, c(M1, M2, ncomps))
  page.nrow <- min(5, ceiling(sqrt(ncomps)))
  page.ncol <- min(5, floor(sqrt(ncomps)))
  num.comps.per.page <- page.nrow * page.ncol
  num.pages <- ceiling(ncomps / num.comps.per.page)
  data <- melt(L)
  colnames(data) <- c('x', 'y', 'k', 'val')
  breaks <- c(-0.4, -0.2, 0, 0.2, 0.4)
  max.pltmag <- max(abs(data$val))
  for (i in 1:num.pages) {
    plots <- vector('list', num.comps.per.page)
    for (j in 1:num.comps.per.page) {
      plots[[j]] <- plot_loading(data, (i-1) * num.comps.per.page + j, 0, breaks)
    }
    g <- ggarrange(
      plotlist = plots,
      nrow = page.nrow, ncol = page.ncol, 
      common.legend = TRUE, 
      legend = 'bottom'
    )
    if (num.pages > 1) {
      path <- file.path(dir.results, str_glue('rs-ffa-loadings-K{ncomps}-{i}.png'))
    } else {
      path <- file.path(dir.results, str_glue('rs-ffa-loadings-K{ncomps}.png'))
    }
    
    ggexport(g, filename=path, width=200*page.ncol, height=200*page.nrow)
  }
  
}



## ICA =========================================================================


if (analysis.type == 'ica') {
  
  ## [PAPER] ICs (K = 25, 50)
  path <- file.path(
    dir.data, 
    'ica',
    paste0(
      'slice_',
      str_glue('sigma-{smooth}_'),
      str_glue('migp-{migp}_'),
      str_glue('varnorm-{varnorm}_'),
      str_glue('nl-{nonlinearity}_'),
      str_glue('ncomps-{ncomps}')
    ),
    'melodic_oIC.nii.gz'
  )
  img <- readNifti(path)
  L <- img[,,1,]
  page.nrow <- min(5, ceiling(sqrt(ncomps)))
  page.ncol <- min(5, floor(sqrt(ncomps)))
  num.comps.per.page <- page.nrow * page.ncol
  num.pages <- ceiling(ncomps / num.comps.per.page)
  data <- melt(L)
  colnames(data) <- c('x', 'y', 'k', 'val')
  data$val <- to_log_scale(data$val)
  breaks <- to_log_scale(c(-3, -2, -1, 0, 1, 2, 3))
  max.pltmag <- max(abs(data$val))
  for (i in 1:num.pages) {
    plots <- vector('list', num.comps.per.page)
    for (j in 1:num.comps.per.page) {
      plots[[j]] <- plot_loading(data, (i-1) * num.comps.per.page + j, 0, breaks, max.pltmag, log.scale = TRUE)
    }
    g <- ggarrange(
      plotlist = plots,
      nrow = page.nrow, ncol = page.ncol, 
      common.legend = TRUE, 
      legend = 'bottom'
    )
    if (num.pages > 1) {
      path <- file.path(dir.results, str_glue('rs-ica-comps-K{ncomps}-{i}.png'))
    } else {
      path <- file.path(dir.results, str_glue('rs-ica-comps-K{ncomps}.png'))
    }
    ggexport(g, filename=path, width=200*page.ncol, height=200*page.nrow)
  }
  
}






