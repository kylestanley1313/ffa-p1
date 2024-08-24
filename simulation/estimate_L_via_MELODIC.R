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


estimate_L_via_MELODIC <- function(config.id, design.id) {
  
  ## Load YAMLs and set variables
  design <- yaml.load_file(
    file.path('simulation', 'designs', str_glue('{design.id}.yml'))
  )
  config <- yaml.load_file(
    file.path('simulation', 'data', design.id, config.id, 'config.yml')
  )
  fsl.path <- config$dirs$fsl_path
  M <- config$settings$M
  num.samps <- config$settings$num_samps
  nl <- 'pow3'
  K <- config$settings$K
  sigmas <- config$tuning$selections$comp_sim$sigmas
  max.attempts <- 10
  
  for (rep in 1:config$settings$num_reps) {
    
    n.attempts <- 0
    
    tryCatch({
      
      ## Set globals
      fname.data <- format_matrix_filename('X', r = rep, extension = FALSE)
      path.data <- file.path(design$scratch_root, config$dirs$data, str_glue('{fname.data}.csv.gz'))
      dir.ica <- file.path(design$scratch_root, config$dirs$data, str_glue('ica-{rep}'))
      
      ## Create ICA directory
      if (!dir.exists(dir.ica)) dir.create(dir.ica)
      
      ## Create Nifti copy of data
      data <- csv_to_matrix(path.data)
      data <- array_reshape(data, c(M, M, 1, num.samps))
      data <- asNifti(data)
      path.data.nii <- file.path(dir.ica, str_glue('{fname.data}.nii.gz'))
      writeNifti(data, path.data.nii)
      
      ## Smooth scan
      if (sigmas[rep] == 0) {
        path.data.sm <- path.data.nii
      }
      else {
        path.data.sm <- file.path(dir.ica, str_glue('{fname.data}sm.nii.gz'))
        smooth_scan(path.data.nii, path.data.sm, sigmas[rep], fsl.path)
      }
      
      while (n.attempts < max.attempts) {
        
        ## Run MELODIC ICA
        flags <- paste(
          str_glue("-i {path.data.sm} -o {dir.ica}"), ## TODO: path.data.nii -> path.data.sm
          str_glue('--nomask --nl={nl}'),
          str_glue('--nobet --tr=1.0 --Oorig'),
          str_glue('--disableMigp'),
          str_glue('--varnorm'),
          str_glue('--maxit=1000'),
          str_glue('-d {K}'),
          str_glue('--seed={12345 + n.attempts}'),
          sep = ' '
        )
        command <- file.path(fsl.path, 'melodic')
        path.stderr <- file.path(config$dirs$results, str_glue('estimate-melodic_{config.id}_rep-{rep}.log'))
        out <- system2(
          command = command, args = flags,
          env = 'FSLOUTPUTTYPE=NIFTI_GZ',
          stderr = path.stderr
        )
        
        if (file.info(path.stderr)$size == 0) {  ## if there were no errors...
          ## Delete stderr log
          unlink(path.stderr)
          
          ## Convert Nifti to CSV
          path <- file.path(dir.ica, 'melodic_oIC.nii.gz')
          loads <- readNifti(path)
          loads <- array_reshape(loads, dim = c(M*M, K))
          write_matrix(loads, config$dirs$data, 'Lhat', method = 'ica3', r = rep)
          
          ## Delete ICA directory
          unlink(dir.ica, recursive = TRUE)
          
          ## Move on to next rep
          break
        }
        else { ## if there was an error...
          print(str_glue("WARNING: MELODIC failed for ({config.id}, rep-{rep}) on attempt {n.attempts}. Retrying."))
  
          n.attempts <- n.attempts + 1
          if (n.attempts == max.attempts) {
            print(str_glue("ERROR: No more attempts for ({config.id}, rep-{rep})."))
          }
          
        } 
        
      }
      
    }, error = function(e) {
      # Code to run if an error occurs
      print(str_glue("An error occurred: {e$message}"))
    })

  }
  
}



## Execution ===================================================================

p <- arg_parser("Script to estimate L via MELODIC.")
p <- add_argument(p, "design.id", help = "ID of design.")
args <- parse_args(p)
# args <- list(design.id = 'test-1')

config.ids <- list.dirs(
  file.path('simulation', 'data', args$design.id),
  full.names = FALSE, recursive = FALSE
)

print("----- START ESTIMATION -----")
num.cores <- availableCores()
print(str_glue("Using {num.cores} cores..."))
out <- pbmclapply(
  config.ids, estimate_L_via_MELODIC, design.id = args$design.id,
  mc.cores = num.cores, ignore.interactive = TRUE
)
print("----- END ESTIMATION -----")
