library(ggplot2)
library(stringr)


## File Management =============================================================

gen_mat_fname <- function(
    mat, K = NULL, alpha = NULL, v = NULL, split = NULL
) {
  fname <- str_glue('mat-{mat}')
  if (!is.null(K)) {
    fname <- str_glue('{fname}_K-{K}')
  }
  if (!is.null(alpha)) {
    fname <- str_glue('{fname}_alpha-{alpha}')
  }
  if (!is.null(v)) {
    fname <- str_glue('{fname}_v-{v}')
  }
  if (!is.null(split)) {
    fname <- str_glue('{fname}_split-{split}')
  }
  fname <- str_glue('{fname}.csv.gz')
  return(fname)
}


write_matrix <- function(
    matrix, dir, mat, K = NULL, alpha = NULL, v = NULL, split = NULL
) {
  filename <- gen_mat_fname(mat, K, alpha, v, split)
  path <- file.path(dir, filename)
  write.table(
    matrix,
    gzfile(path),
    sep = ',',
    row.names = FALSE,
    col.names = FALSE,
    append = FALSE
  )
}


gen_fmriprep_path <- function(dir.dataset, sub) {
  fname <- paste0(
    str_glue('sub-{sub}_task-restingstate_acq-mb3_'),
    'space-MNI152NLin2009cAsym_desc-preproc_bold.nii.gz'
  )
  path <- file.path(
    dir.dataset, 'derivatives', 'fmriprep', 
    str_glue('sub-{sub}'), 'func', fname
  )
  return(path)
}


## Plotting ====================================================================

to_log_scale <- function(x) {
  sign(x) * log(abs(x) + 1)
}

to_exp_scale <- function(y) {
  sign(y) * (exp(abs(y)) - 1)
}

val_to_pltmag <- function(val, z.alpha) {
  pmax(abs(val) - z.alpha, 0)
}


pltmag_to_mag <- function(pltmag, z.alpha) {
  pltmag + z.alpha
}


plot_loading <- function(
    data, k, alpha, breaks, 
    max.pltmag = NULL,
    title = NULL,
    col.low = '#000099', 
    col.mid = 'grey', 
    col.high = '#990000',
    midpoint = 0,
    log.scale = FALSE
) {
  
  z.alpha <- quantile(abs(data$val), probs = c(alpha))
  if (is.null(max.pltmag)) {
    max.pltmag <- max(abs(data$val)) 
  }
  
  if (is.null(title)) {
    title <- str_glue("k = {k}")
  }
  
  breaks <- sign(breaks) * round(val_to_pltmag(breaks, z.alpha), 2)
  if (log.scale) {
    breaks_labs <- round(to_exp_scale(breaks), 2)
    log.val <- 't(value)'
  } else {
    breaks_labs <- breaks
    log.val <- 'value'
  }
  
  data <- data %>%
    mutate(sign = sign(val)) %>%
    mutate(pltmag = val_to_pltmag(val, z.alpha)) %>%
    mutate(pltval = sign*pltmag)
  
  data[which(data$k == k),] %>%
    ggplot(aes(x = x, y = y, fill = pltval)) + 
    geom_tile() + 
    scale_fill_gradient2(
      low = col.low,
      mid = col.mid,
      high = col.high, 
      midpoint = midpoint,
      limits = c(-max.pltmag, max.pltmag),
      breaks = breaks,
      labels = as.character(breaks_labs)
    ) +
    labs(
      fill = log.val,
      x = "s1",
      y = "s2",
      title = title
    ) +
    theme_bw() + 
    theme(
      legend.key.height = unit(0.6, 'cm'),
      legend.key.width = unit(1.8, 'cm'),
      panel.grid.major = element_blank(),
      panel.grid.minor = element_blank(),
      plot.title = element_text(hjust = 0.5, size = 16),
      legend.text = element_text(size = 10),
      legend.title = element_text(size = 10),
      legend.position = 'bottom',
      axis.title = element_text(size = 10)
    )
  
}





