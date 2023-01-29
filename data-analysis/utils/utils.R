library(stringr)

get_sub_labs <- function(dir) {
  all.dirs <- list.dirs(dir, full.names = FALSE, recursive = FALSE)
  sub.labs <- c()
  for (dir in all.dirs) {
    if (str_starts(dir, 'sub-')) {
      sub.lab <- str_split(dir, '-')[[1]][2]
      sub.labs <- c(sub.labs, sub.lab)
    }
  }
  return(sub.labs)
}


gen_mat_fname <- function(
    mat, time = NULL, v = NULL, split = NULL
) {
  fname <- str_glue('mat-{mat}')
  if (!is.null(time)) {
    fname <- str_glue('{fname}_time-{time}')
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
    matrix, dir, mat, time = NULL, v = NULL, split = NULL
) {
  filename <- gen_mat_fname(mat, time, v, split)
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