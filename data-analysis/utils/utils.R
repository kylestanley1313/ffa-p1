library(stringr)


gen_mat_fname <- function(
    mat, v = NULL, split = NULL
) {
  fname <- str_glue('mat-{mat}')
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
    matrix, dir, mat, v = NULL, split = NULL
) {
  filename <- gen_mat_fname(mat, v, split)
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