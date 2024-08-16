library(stringr)



## File Management =============================================================

format_matrix_filename <- function(
    mat, method = NULL, r = NULL, v = NULL, split = NULL
) {
  fname <- str_glue('mat-{mat}_')
  if (!is.null(method)) {
    fname <- str_glue('{fname}method-{method}_')
  }
  if (!is.null(r)) {
    fname <- str_glue('{fname}r-{r}_')
  }
  if (!is.null(v)) {
    fname <- str_glue('{fname}v-{v}_')
  }
  if (!is.null(split)) {
    fname <- str_glue('{fname}split-{split}_')
  }
  fname <- str_glue('{fname}.csv.gz')
  return(fname)
}


write_matrix <- function(
    matrix, dir, mat, method = NULL, r = NULL, v = NULL, split = NULL
) {
  filename <- format_matrix_filename(mat, method, r, v, split)
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


## Functions on the plane ======================================================

#' Bump Function
#' 
#' A helper function that returns the value of a 2D bump function at (s1, s2).
#'
#' @param s1 first coordinate
#' @param s2 second coordinate
#' @param center center of bump function
#' @param max maximum of bump function
#' @param scale.s1 scaling factor in first direction
#' @param scale.s2 scaling factor in second direction
#' @param theta angle of rotation
bump_fcn <- function(
    s1, s2, 
    center = c(0.5, 0.5),
    max = 1, 
    scale.s1 = 0.25, 
    scale.s2 = 0.25, 
    theta = 0) 
{
  
  ## Matrix for scaling about center
  S <- rbind(c(1, 0, center[1]), c(0, 1, center[2]), c(0, 0, 1)) %*%  ## translate back
    rbind(c(scale.s1, 0, 0), c(0, scale.s2, 0), c(0, 0, 1)) %*%  ## scale
    rbind(c(1, 0, -center[1]), c(0, 1, -center[2]), c(0, 0, 1)) ## translate
  
  ## Matrix for rotation about center
  theta <- theta * pi / 180  ## degrees to radians
  R <- rbind(c(1, 0, center[1]), c(0, 1, center[2]), c(0, 0, 1)) %*%  ## translate back
    rbind(c(cos(theta), -sin(theta), 0), c(sin(theta), cos(theta), 0), c(0, 0, 1)) %*%  ## rotation
    rbind(c(1, 0, -center[1]), c(0, 1, -center[2]), c(0, 0, 1)) ## translate
  
  ## IDEA: The (s1, s2) passed to this function are the points for which we 
  ##       must set a bump function value. To do so, we assume (s1, s2) have
  ##       already been transformed (scaled then rotated), and reverse
  ##       transform them back to their original axes before computing their
  ##       bump function value.
  p <- c(s1, s2, 1)  
  p.trans <- solve(R%*%S)%*%p  ## reverse transform
  s1 <- p.trans[1]; s2 <- p.trans[2]
  
  r <- sqrt((s1-center[1])^2 + (s2-center[2])^2)
  if (r >= 1) return(0)
  else {
    return((max*exp(1))*exp(-1/(1-r^2)))
  }
}


#' Triangle Function
#' 
#' A helper function that returns the value of a 2D triangle function 
#' at (s1, s2).
#'
#' @param s1 first coordinate
#' @param s2 second coordinate
#' @param center center of triangle function
#' @param max maximum of triangle function
#' @param scale.s1 scaling factor in first direction
#' @param scale.s2 scaling factor in second direction
#' @param theta angle of rotation
triangle_fcn <- function(
    s1, s2, 
    center = c(0.5, 0.5),
    max = 1, 
    scale.s1 = 0.25, 
    scale.s2 = 0.25, 
    theta = 0) 
{
  
  ## Matrix for scaling about center
  S <- rbind(c(1, 0, center[1]), c(0, 1, center[2]), c(0, 0, 1)) %*%  ## translate back
    rbind(c(scale.s1, 0, 0), c(0, scale.s2, 0), c(0, 0, 1)) %*%  ## scale
    rbind(c(1, 0, -center[1]), c(0, 1, -center[2]), c(0, 0, 1)) ## translate
  
  ## Matrix for rotation about center
  theta <- theta * pi / 180  ## degrees to radians
  R <- rbind(c(1, 0, center[1]), c(0, 1, center[2]), c(0, 0, 1)) %*%  ## translate back
    rbind(c(cos(theta), -sin(theta), 0), c(sin(theta), cos(theta), 0), c(0, 0, 1)) %*%  ## rotation
    rbind(c(1, 0, -center[1]), c(0, 1, -center[2]), c(0, 0, 1)) ## translate
  
  ## IDEA: The (s1, s2) passed to this function are the points for which we 
  ##       must set a bump function value. To do so, we assume (s1, s2) have
  ##       already been transformed (scaled then rotated), and reverse
  ##       transform them back to their original axes before computing their
  ##       bump function value.
  p <- c(s1, s2, 1)  
  p.trans <- solve(R%*%S)%*%p  ## reverse transform
  s1 <- p.trans[1]; s2 <- p.trans[2]
  
  r <- max(abs(s1 - center[1]), abs(s2 - center[2]))
  if (r >= 1) return(0)
  else {
    return(max*(1 - r))
  }
}


## Loadings ====================================================================


## NOTE: The below loading "schemes" only specify the arrangement of loading
## functions. In the compute_loading_array function, each loading function is
## scaled to have unit norm, then scaled again by some strength factor. 


#' First Bump Scheme Loading Function
#' 
#' Returns the value of the kth un-normalized loading function at (s1, s2) for 
#' the first bump scheme.
#'
#' @param k number of the loading function
#' @param s1 first coordinate
#' @param s2 second coordinate
load_scheme_bump01 <- function(k, s1, s2) {
  if (k > 4) stop("k must be <= 4!")
  if (k == 1) {
    val1 <- bump_fcn(s1, s2, center = c(0.25, 0.25), max = 0.5)
    val2 <- bump_fcn(s1, s2, center = c(0.75, 0.75), max = 0.5)
    val <- max(val1, val2)
  }
  else if (k == 2) {
    val1 <- bump_fcn(s1, s2, center = c(0.25, 0.75), max = 0.5)
    val2 <- bump_fcn(s1, s2, center = c(0.75, 0.25), max = 0.5)
    val <- max(val1, val2)
  }
  else if (k == 3) {
    val1 <- bump_fcn(s1, s2, center = c(0.5, 0.75), max = 0.5)
    val2 <- bump_fcn(s1, s2, center = c(0.5, 0.25), max = 0.5)
    val <- max(val1, val2)
  }
  else {
    val1 <- bump_fcn(s1, s2, center = c(0.75, 0.5), max = 0.5)
    val2 <- bump_fcn(s1, s2, center = c(0.25, 0.5), max = 0.5)
    val <- max(val1, val2)
  }
  return(val)
}


load_scheme_bump02 <- function(k, s1, s2) {
  if (k > 8) stop("k must be <= 8!")
  if (k == 1) {
    val1 <- bump_fcn(s1, s2, center = c(0.1, 0.1), scale.s1 = 0.1, scale.s2 = 0.1)
    val2 <- bump_fcn(s1, s2, center = c(0.9, 0.9), scale.s1 = 0.1, scale.s2 = 0.1)
    val3 <- bump_fcn(s1, s2, center = c(0.3, 0.7), scale.s1 = 0.1, scale.s2 = 0.1)
    val <- max(val1, val2, val3)
  }
  else if (k == 2) {
    val1 <- bump_fcn(s1, s2, center = c(0.3, 0.1), scale.s1 = 0.1, scale.s2 = 0.1)
    val2 <- bump_fcn(s1, s2, center = c(0.7, 0.9), scale.s1 = 0.1, scale.s2 = 0.1)
    val3 <- bump_fcn(s1, s2, center = c(0.7, 0.5), scale.s1 = 0.1, scale.s2 = 0.1)
    val <- max(val1, val2, val3)
  }
  else if (k == 3) {
    val1 <- bump_fcn(s1, s2, center = c(0.5, 0.1), scale.s1 = 0.1, scale.s2 = 0.1)
    val2 <- bump_fcn(s1, s2, center = c(0.5, 0.9), scale.s1 = 0.1, scale.s2 = 0.1)
    val3 <- bump_fcn(s1, s2, center = c(0.3, 0.5), scale.s1 = 0.1, scale.s2 = 0.1)
    val <- max(val1, val2, val3)
  }
  else if (k == 4) {
    val1 <- bump_fcn(s1, s2, center = c(0.7, 0.1), scale.s1 = 0.1, scale.s2 = 0.1)
    val2 <- bump_fcn(s1, s2, center = c(0.3, 0.9), scale.s1 = 0.1, scale.s2 = 0.1)
    val3 <- bump_fcn(s1, s2, center = c(0.3, 0.3), scale.s1 = 0.1, scale.s2 = 0.1)
    val <- max(val1, val2, val3)
  }
  else if (k == 5) {
    val1 <- bump_fcn(s1, s2, center = c(0.9, 0.1), scale.s1 = 0.1, scale.s2 = 0.1)
    val2 <- bump_fcn(s1, s2, center = c(0.1, 0.9), scale.s1 = 0.1, scale.s2 = 0.1)
    val3 <- bump_fcn(s1, s2, center = c(0.7, 0.7), scale.s1 = 0.1, scale.s2 = 0.1)
    val <- max(val1, val2, val3)
  }
  else if (k == 6) {
    val1 <- bump_fcn(s1, s2, center = c(0.9, 0.3), scale.s1 = 0.1, scale.s2 = 0.1)
    val2 <- bump_fcn(s1, s2, center = c(0.1, 0.7), scale.s1 = 0.1, scale.s2 = 0.1)
    val3 <- bump_fcn(s1, s2, center = c(0.5, 0.7), scale.s1 = 0.1, scale.s2 = 0.1)
    val <- max(val1, val2, val3)
  }
  else if (k == 7) {
    val1 <- bump_fcn(s1, s2, center = c(0.9, 0.5), scale.s1 = 0.1, scale.s2 = 0.1)
    val2 <- bump_fcn(s1, s2, center = c(0.1, 0.5), scale.s1 = 0.1, scale.s2 = 0.1)
    val3 <- bump_fcn(s1, s2, center = c(0.5, 0.3), scale.s1 = 0.1, scale.s2 = 0.1)
    val <- max(val1, val2, val3)
  }
  else {
    val1 <- bump_fcn(s1, s2, center = c(0.9, 0.7), scale.s1 = 0.1, scale.s2 = 0.1)
    val2 <- bump_fcn(s1, s2, center = c(0.1, 0.3), scale.s1 = 0.1, scale.s2 = 0.1)
    val3 <- bump_fcn(s1, s2, center = c(0.7, 0.3), scale.s1 = 0.1, scale.s2 = 0.1)
    val <- max(val1, val2, val3)
  }
  return(val)
}


#' First Network Scheme Loading Function
#' 
#' Returns the value of the kth un-normalized loading function at (s1, s2) for 
#' the first network scheme. Scheme inspired by resting state networks 
#' identified by ICA:
#' https://www.researchgate.net/figure/The-resting-state-networks-Melodic-ICA-generated-resting-state-networks-from-our-data_fig6_259002919
#'
#' @param k number of the loading function
#' @param s1 first coordinate
#' @param s2 second coordinate
load_scheme_net01 <- function(k, s1, s2) {
  if (k > 4) stop("k must be <= 4!")
  if (k == 1) {  ## default mode (z = 32)
    val1 <- bump_fcn(s1, s2, center = c(0.5, 0.25), max = 1, scale.s1 = 0.1, scale.s2 = 0.15, theta = 0)
    val2 <- bump_fcn(s1, s2, center = c(0.3, 0.1), max = 1, scale.s1 = 0.05, scale.s2 = 0.1, theta = 30)
    val3 <- bump_fcn(s1, s2, center = c(0.7, 0.1), max = 1, scale.s1 = 0.05, scale.s2 = 0.1, theta = -30)
    val4 <- bump_fcn(s1, s2, center = c(0.5, 0.9), max = 0.5, scale.s1 = 0.1, scale.s2 = 0.05, theta = 0)
    val5 <- bump_fcn(s1, s2, center = c(0.4, 0.8), max = 0.5, scale.s1 = 0.05, scale.s2 = 0.05, theta = 0)
    val6 <- bump_fcn(s1, s2, center = c(0.6, 0.8), max = 0.5, scale.s1 = 0.05, scale.s2 = 0.05, theta = 0)
    val <- max(val1, val2, val3, val4, val5, val6)
  }
  else if (k == 2) {  ## executive (z = 26)
    val1 <- bump_fcn(s1, s2, center = c(0.5, 0.8), max = 1, scale.s1 = 0.1, scale.s2 = 0.15, theta = 0)
    val2 <- bump_fcn(s1, s2, center = c(0.4, 0.8), max = 1, scale.s1 = 0.15, scale.s2 = 0.1, theta = 45)
    val3 <- bump_fcn(s1, s2, center = c(0.6, 0.8), max = 1, scale.s1 = 0.15, scale.s2 = 0.1, theta = -45)
    val4 <- bump_fcn(s1, s2, center = c(0.5, 0.5), max = 0.5, scale.s1 = 0.05, scale.s2 = 0.05, theta = 0)
    val5 <- bump_fcn(s1, s2, center = c(0.8, 0.35), max = 0.5, scale.s1 = 0.05, scale.s2 = 0.05, theta = 0)
    val6 <- bump_fcn(s1, s2, center = c(0.2, 0.35), max = 0.5, scale.s1 = 0.05, scale.s2 = 0.05, theta = 0)
    val7 <- bump_fcn(s1, s2, center = c(0.55, 0.1), max = 0.5, scale.s1 = 0.05, scale.s2 = 0.05, theta = 0)
    val8 <- bump_fcn(s1, s2, center = c(0.45, 0.1), max = 0.5, scale.s1 = 0.05, scale.s2 = 0.05, theta = 0)
    val <- max(val1, val2, val3, val4, val5, val6, val7, val8)
  }
  else if (k == 3) {  ### right dorsal visual stream (z = 46)
    val1 <- bump_fcn(s1, s2, center = c(0.3, 0.25), max = 1, scale.s1 = 0.15, scale.s2 = 0.25, theta = 30)
    val2 <- bump_fcn(s1, s2, center = c(0.35, 0.8), max = 1, scale.s1 = 0.15, scale.s2 = 0.25, theta = -30)
    val3 <- bump_fcn(s1, s2, center = c(0.7, 0.25), max = 0.7, scale.s1 = 0.15, scale.s2 = 0.1, theta = 30)
    val <- max(val1, val2, val3)
  }
  else {  ## left dorsal visual stream (z = 46)
    val1 <- bump_fcn(s1, s2, center = c(0.7, 0.25), max = 1, scale.s1 = 0.15, scale.s2 = 0.25, theta = -30)
    val2 <- bump_fcn(s1, s2, center = c(0.65, 0.8), max = 1, scale.s1 = 0.15, scale.s2 = 0.25, theta = 30)
    val3 <- bump_fcn(s1, s2, center = c(0.3, 0.25), max = 0.7, scale.s1 = 0.15, scale.s2 = 0.1, theta = -30)
    val <- max(val1, val2, val3)
  }
  return(val)
}


loading.scheme.map <- list(
  bump01 = load_scheme_bump01,
  bump02 = load_scheme_bump02,
  net01 = load_scheme_net01
)



#' Compute Loading Array
#'
#' @param loading_scheme loading scheme used to generate loading functions
#' @param loading.scales vector of scale factors for each loading function
#' @param M grid size
#'
#' @return a loading array of dimension M by M by K
compute_loading_array <- function(loading.scheme, loading.scales, M) {
  loading_scheme <- loading.scheme.map[[loading.scheme]]
  K <- length(loading.scales)
  L <- array(dim = c(M, M, K))
  grid <- seq(0, 1, length.out = M)
  for (k in 1:K) {
    L[,,k] <- outer(
      grid, grid, 
      Vectorize(loading_scheme, c('s1', 's2')),
      k = k
    )
    L[,,k] <- loading.scales[k] * L[,,k] / norm(L[,,k], type = 'F')
  }
  return(L)
}




## Errors ======================================================================


assign_error_fcn_centers <- function(J) {
  if (sqrt(J) %% 1 != 0) stop("J must be a square number!")
  grid <- seq(0, 1, length.out = sqrt(J))
  centers <- expand.grid(grid, grid)
  return(as.matrix(centers))
}


error_scheme_bump01 <- function(j, centers, delta, s1, s2) {
  bump_fcn(
    s1, s2, center = as.numeric(centers[j,]), 
    scale.s1 = delta/2, scale.s2 = delta/2
    )
}


error_scheme_tri01 <- function(j, centers, delta, s1, s2) {
  triangle_fcn(
    s1, s2, center = as.numeric(centers[j,]), 
    scale.s1 = delta/2, scale.s2 = delta/2
  )
}


error.scheme.map <- list(
  bump01 = error_scheme_bump01,
  tri01 = error_scheme_tri01
)


#' Compute Error Array
#'
#' @param error_scheme error scheme used to generate error basis functions 
#' @param error.scales vector of scaling factors for each error basis function
#' @param delta bandwidth
#' @param M grid size
#'
#' @return an array of error bases with dimension M by M by J
compute_error_array <- function(error.scheme, error.scales, delta, M) {
  
  ## Generate path to error basis
  J <- length(error.scales)
  fname <- str_glue('scheme-{error.scheme}_M-{M}_J-{J}_delta-{delta}.csv.gz')
  path <- file.path('simulation', 'error-bases', fname)
  
  ## If file exists, retrieve basis
  if (file.exists(path)) {
    E.mat <- csv_to_matrix(path)
    E <- array_reshape(E.mat, dim = c(M, M, J))
  }
  ## Otherwise, create then write basis
  else {
    E <- array(dim = c(M, M, J))
    error_scheme <- error.scheme.map[[error.scheme]]
    centers <- assign_error_fcn_centers(J)
    grid <- seq(0, 1, length.out = M)
    for (j in 1:J) {
      E[,,j] <- outer(
        grid, grid,
        Vectorize(error_scheme, c('s1', 's2')), 
        j = j, centers = centers, delta = delta
      )
      E[,,j] <- E[,,j] / norm(E[,,j], type = 'F')
    }
    E.mat <- array_reshape(E, dim = c(M*M, J))
    write.table(
      E.mat,
      gzfile(path),
      sep = ',',
      row.names = FALSE,
      col.names = FALSE,
      append = FALSE
    )
  }
  
  ## Scale error basis
  for (j in 1:J) E[,,j] <- error.scales[j] * E[,,j]
  return(E)
}


