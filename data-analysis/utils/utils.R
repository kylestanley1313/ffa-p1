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


## Plotting ====================================================================

val_to_pltmag <- function(val, z.alpha) {
  pmax(abs(val) - z.alpha, 0)
}


pltmag_to_mag <- function(pltmag, z.alpha) {
  pltmag + z.alpha
}


plot_loading <- function(data, k, alpha, breaks_) {
  
  z.alpha <- quantile(abs(data$val), probs = c(alpha))
  max.pltmag <- max(abs(data$val))
  
  data <- data %>%
    mutate(sign = sign(val)) %>%
    mutate(pltmag = val_to_pltmag(val, z.alpha)) %>%
    mutate(pltval = sign*pltmag)
  
  data[which(data$k == k),] %>%
    ggplot(aes(x = x, y = y, fill = pltval)) + 
    geom_tile() + 
    scale_fill_gradient2(
      low = '#000099',
      mid = 'grey',
      high = '#990000', 
      midpoint = 0,
      limits = c(-max.pltmag, max.pltmag),
      # limits = c(0, max.pltmag),
      breaks = c(
        -1*val_to_pltmag(breaks_[1], z.alpha),
        -1*val_to_pltmag(breaks_[2], z.alpha),
        breaks_[3],
        val_to_pltmag(breaks_[4], z.alpha),
        val_to_pltmag(breaks_[5], z.alpha)
      ),
      labels = as.character(breaks_)
    ) +
    labs(
      fill = "value",
      x = "s1",
      y = "s2",
      title = str_glue("k = {k}")
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
      axis.title = element_text(size = 10)
    )
  
}





