library(argparser)
library(parallelly)
library(pbmcapply)
library(RNifti)
library(stringr)
library(yaml)

source(file.path('utils', 'utils.R'))
source(file.path('simulation', 'utils', 'utils.R'))



## Helpers =====================================================================

smooth_scan <- function(path.in, path.out, sigma, fsl.path) {
  out <- system2(
    command = file.path(fsl.path, 'fslmaths'),
    args = str_glue('{path.in} -s {sigma} {path.out}'),
    env = 'FSLOUTPUTTYPE=NIFTI_GZ'
  )
}


tune_sigma <- function(config.id, design.id) {
  
  ## Load YAMLs and set variables
  design <- yaml.load_file(
    file.path('simulation', 'designs', str_glue('{design.id}.yml'))
  )
  config <- yaml.load_file(
    file.path('simulation', 'data', design.id, config.id, 'config.yml')
  )
  fsl.path <- config$dirs$fsl_path
  M <- config$settings$M
  num.train <- num.train <- ceiling(config$settings$num_samps * config$tuning$train_prop)
  nl <- 'pow3'
  K <- config$settings$K
  sigmas <- seq(0.2, 20, by = 0.2)
  num.sigmas <- length(sigmas)
  
  ## Create dataframe table.tune and vector sigma.stars for tuning results
  col.names <- c('sigma', 'rep', 'v', 'nobpe')
  data.tune <- data.frame(matrix(nrow = 0, ncol = length(col.names)))
  colnames(data.tune) <- col.names
  sigma.stars <- rep(NA, config$settings$num_reps)
  
  A.mat <- create_band_deletion_array(
    config$settings$M, 
    config$settings$M, 
    config$settings$delta
  )$A.mat
  
  for (rep in 1:10) { ## config$settings$num_reps) { ## DEBUG
    
    print(str_glue("----- rep = {rep} -----"))
    
    hit.error <- FALSE
    
    for (l in 1:num.sigmas) {
      
      print(str_glue("--- sigma = {sigmas[l]}"))
      
      for (v in 1:config$tuning$num_reps) {
        
        ## Set globals
        fname.data <- format_matrix_filename(
          'X', r = rep, v = v, split = 'train', extension = FALSE
        )
        path.data <- file.path(design$scratch_root, config$dirs$data, str_glue('{fname.data}.csv.gz'))
        dir.ica <- file.path(design$scratch_root, config$dirs$data, str_glue('ica_r-{rep}_sigma-{l}_v-{v}'))
        
        ## Create ICA directory
        if (!dir.exists(dir.ica)) dir.create(dir.ica)
        
        ## Create Nifti copy of training data
        data <- csv_to_matrix(path.data)
        data <- array_reshape(data, c(M, M, 1, num.train))
        data <- asNifti(data)
        path.data.nii <- file.path(dir.ica, str_glue('{fname.data}.nii.gz'))
        writeNifti(data, path.data.nii)
        
        ## Smooth training data
        path.data.sm <- file.path(dir.ica, str_glue('{fname.data}sm.nii.gz'))
        smooth_scan(path.data.nii, path.data.sm, sigmas[l], fsl.path)
        
        ## Run MELODIC ICA
        flags <- paste(
          str_glue("-i {path.data.sm} -o {dir.ica}"),
          str_glue('--nomask --nl={nl}'),
          str_glue('--nobet --tr=1.0 --Oorig'),
          str_glue('--disableMigp'),
          str_glue('--varnorm'),
          str_glue('--maxit=1000'),
          str_glue('-d {K}'),
          str_glue('--seed=12345'),
          sep = ' '
        )
        command <- file.path(fsl.path, 'melodic')
        path.stderr <- file.path(config$dirs$results, str_glue('tune-sigma_{config.id}_rep-{rep}_sigma-{l}_v-{v}.log'))
        out <- system2(
          command = command, args = flags,
          env = 'FSLOUTPUTTYPE=NIFTI_GZ',
          stderr = path.stderr
        )
        
        if (file.info(path.stderr)$size == 0) { ## if no error, update dataframe and proceed to next fold
          ## Delete stderr log
          unlink(path.stderr)
          
          ## Compute training covariance
          path <- file.path(dir.ica, 'melodic_oIC.nii.gz')
          loads <- readNifti(path)
          loads <- array_reshape(loads, dim = c(M*M, K))
          cov.train <- loads %*% t(loads)
          
          ## Delete ICA directory
          unlink(dir.ica, recursive = TRUE)
          
          ## Read testing covariance
          path <- file.path(
            design$scratch_root, config$dirs$data,
            format_matrix_filename('Chat', r = rep, v = v, split = 'test')
          )
          cov.test <- csv_to_matrix(path)
          
          ## Compute normalized off-band prediction error and add row to data.tune
          nobpe <- norm(A.mat * (cov.train - cov.test), type = 'f') / norm(A.mat * cov.test, type = 'f')
          data.tune[nrow(data.tune)+1,] <- c(sigmas[l], rep, v, nobpe)
        }
        else { ## if error, break from folds loop
          print(str_glue("Errors logged to: {path.stderr}"))
          hit.error <- TRUE
          break
        }
      
      }
      
      ## If error for this sigma, then use previous sigma as sigma star.
      if (hit.error) {
        print(str_glue("Setting sigma to {sigmas[l-1]}"))
        sigma.stars[rep] <- sigmas[l-1]
        break
      }
      ## Determine whether MNOBPE is decreasing
      ##   - If it is, then
      ##       (i) store current sigma in sigma.stars
      ##       (ii) break from sigma loop
      ##   - If it is not, then proceed to next sigma
      else {
        if (l > 1) {
          
          if (l == num.sigmas) {
            print(str_glue("Tried all sigmas. Using last one: {sigmas[l]}."))
            sigmas.start[rep] <- sigmas[l]
          }
          else {
            mnobpe.last <- mean(filter(data.tune, rep == rep & sigma == sigmas[l-1])$nobpe)
            mnobpe.curr <- mean(filter(data.tune, rep == rep & sigma == sigmas[l])$nobpe)
            if (mnobpe.last - mnobpe.curr < 0) {
              print(str_glue("Setting sigma to {sigmas[l-1]}"))
              sigma.stars[rep] <- sigmas[l-1]
              break  ## Move to next rep
            }
          }

        }
      }
    }
    
    ## Write tuning results to appropriate files   
    config$tuning$selections$comp_sim$sigmas <- sigma.stars
    write_yaml(
      config, 
      file.path(config$dirs$data, 'config.yml')
    )
    write.table(
      data.tune, 
      file.path(config$dirs$results, 'data_tune_sigma.csv'), 
      sep = ',',
      col.names = TRUE,
      row.names = FALSE,
      append = FALSE,
      quote = FALSE
    )
    
  }
  
}


## Execution ===================================================================

p <- arg_parser("Script to tune sigma for MELODIC estimation.")
p <- add_argument(p, "design.id", help = "ID of design.")
args <- parse_args(p)

# config.ids <- list.dirs(
#   file.path('simulation', 'data', args$design.id),
#   full.names = FALSE, recursive = FALSE
# )
config.ids <- c('config-23') ## DEBUG

print("----- START TUNING -----")
num.cores <- availableCores()
print(str_glue("Using {num.cores} cores..."))
out <- pbmclapply(
  config.ids, tune_sigma, design.id = args$design.id,
  mc.cores = num.cores, ignore.interactive = TRUE
)
print("----- END TUNING -----")

print("----- END ESTIMATION -----")