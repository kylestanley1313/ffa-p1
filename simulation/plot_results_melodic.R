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
p <- add_argument(p, "design.id", help = "ID of design.")
p <- add_argument(p, "load.type", help = "Type of loading to plot (choices: true, ffa, ica).")
p <- add_argument(p, "--ncomps", type = 'numeric', help = "FFA/ICA rank parameter for which to plot results.")
p <- add_argument(p, "--archive", flag = TRUE, help = "Flag to copy relevant files to new location.")
args <- parse_args(p)

# args = list(
#   design.id = 'melodic-1',
#   load.type = 'ica',
#   ncomps = 8,
#   archive = TRUE
# )


config <- yaml.load_file(
  file.path('simulation', 'data', args$design.id, 'config-1', 'config.yml')
)
M <- config$settings$M
if (args$load.type == 'true') {
  ncomps <- config$settings$K
} else {
  ncomps <- args$ncomps
}


## True loads
if (args$load.type == 'true') {
  path.fname <- 'mat-L_.csv.gz'
  path.loads <- file.path(config$dirs$data, path.fname)
  loads <- csv_to_matrix(path.loads)
  loads <- array_reshape(loads, c(M, M, ncomps))
  breaks <- c(-0.4, -0.2, 0, 0.2, 0.4)
}

## FFA loads
if (args$load.type == 'ffa') {
  path.fname <- 'mat-Lhat_method-ffa_r-1_.csv.gz'
  path.loads <- file.path(config$dirs$data, path.fname)
  loads <- csv_to_matrix(path.loads)
  loads <- array_reshape(loads, c(M, M, ncomps))
  breaks <- c(-0.4, -0.2, 0, 0.2, 0.4)
}

## ICA loads
if (args$load.type == 'ica') {
  path.fname <- 'melodic_IC.nii.gz'
  path.loads <- file.path(config$dirs$data, 'ica', path.fname)
  loads <- readNifti(path.loads)
  loads <- array_reshape(loads, c(M, M, ncomps))
  breaks <- c(-20, -10, 0, 10, 20)
}

if (ncomps == 8) {
  page.nrow <- 4
  page.ncol <- 2
} else {
  page.nrow <- 5
  page.ncol <- 5
}

fname <- str_glue('loads-{args$load.type}-K{ncomps}')
num.comps.per.page <- page.nrow * page.ncol
num.pages <- ceiling(ncomps / num.comps.per.page)
data <- melt(loads)
colnames(data) <- c('x', 'y', 'k', 'val')
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
    path <- file.path(config$dirs$results, str_glue('{fname}-{i}.png'))
  } else {
    path <- file.path(config$dirs$results, str_glue('{fname}.png'))
  }
  
  ggexport(g, filename=path, width=200*page.ncol, height=200*page.nrow)
}

## Archive file
if (args$archive) {
  dir.archive <- file.path(config$dir$data, str_glue('K{ncomps}'))
  if (!file.exists(dir.archive)) dir.create(dir.archive)
  file.copy(path.loads, file.path(dir.archive, path.fname))
}













