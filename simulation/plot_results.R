library(argparser)
library(dplyr)
library(ggplot2)
library(ggpubr)
library(gridExtra)
library(reshape2)
library(stringr)
library(xtable)
library(yaml)

source(file.path('utils', 'utils.R'))


p <- arg_parser("Script for plotting simulation results.")
p <- add_argument(p, "design.id", help = "ID of design")
p <- add_argument(p, "--rank", flag = TRUE, help = "Flag to plot for rank study.")
p <- add_argument(p, "--acc_comp", flag = TRUE, help = "Flag to plot for accuracy comparison study.")
p <- add_argument(p, "--acc_comp_old_data", flag = TRUE, help = "Flag to use old data in accuracy comparison study.")
p <- add_argument(p, "--int_comp", flag = TRUE, help = "Flag to plot for interpretability study.")
args <- parse_args(p)

## Read design
design.id <- args$design.id
design <- yaml.load_file(
  file.path('simulation', 'designs', paste0(design.id, '.yml'))
)

if (args$rank | args$acc_comp) {
  
  ## Read config.map
  config.map <- read.csv(file.path('simulation', 'results', design.id, 'config_map.csv'))
  
  ## Process config.map
  config.map$scenario <- NA
  config.map$regime <- NA
  for (i in 1:nrow(config.map)) {
    
    l.scheme <- config.map$l.scheme[i]
    e.scheme <- config.map$e.scheme[i]
    l.scale.max <- config.map$l.scale.max[i]
    
    ## assign scenario
    if (l.scheme == 'bump01') {
      if (e.scheme == 'bump01') {
        config.map$scenario[i] <- 'S1'
      }
      else {
        config.map$scenario[i] <- 'S2'
      }
    }
    else {
      if (e.scheme == 'bump01') {
        config.map$scenario[i] <- 'S3'
      }
      else {
        config.map$scenario[i] <- 'S4'
      }
    }
    
    ## assign regime 
    if (l.scale.max == 3) {
      config.map$regime[i] <- 'R1'
    }
    else if (l.scale.max == 1.8) {
      config.map$regime[i] <- 'R2'
    }
    else {
      config.map$regime[i] <- 'other'
    }
    
  }
  
}


## Rank ========================================================================

if (args$rank) {
  
  
  ## Compile rank data -----------------------------------------------------------
  
  col.names <- c('scenario', 'regime', 'n', 'delta', 'K', 'rep', 'j', 'fit')
  data <- data.frame(matrix(nrow = 0, ncol = length(col.names)))
  colnames(data) <- col.names
  for (i in 1:nrow(config.map)) {
    temp <- read.csv(file.path(
      'simulation', 'results', design.id,
      paste0('config-', config.map$config.id[i]),
      'data_rank_select.csv'
    ))
    colnames(temp) <- c('rep', 'j', 'fit')
    temp$scenario <- config.map$scenario[i]
    temp$regime <- config.map$regime[i]
    temp$n <- config.map$n[i]
    temp$delta <- config.map$delta[i]
    temp$K <- config.map$K[i]
    temp <- temp[,col.names]
    data <- rbind(data, temp)
  }
  
  
  ## Generate scree plots --------------------------------------------------------
  
  scale_fun <- function(x) sprintf("%.1f", x)
  
  ### Code used for paper ###
  generate_scree_plot <- function(data_, scenario_, regime_, n_, rep_, K_) {
    data_ %>%
      filter(rep == rep_) %>%
      filter(n == n_) %>%
      filter(scenario == scenario_) %>%
      filter(regime == regime_) %>%
      mutate(
        K = factor(K),
        delta = factor(delta)
      ) %>%
      ggplot(aes(x = j, y = fit)) +
      geom_line(aes(color = K, linetype = delta)) + 
      geom_vline(aes(xintercept = K_), linetype = 'dotted') + 
      scale_y_continuous(labels = scale_fun) +
      theme(
        legend.position = 'none', 
        text = element_text(size = 14)) + # ,
      #axis.title.x = element_blank(),
      #axis.text.x = element_blank()) + 
      labs(
        title = paste(scenario_, regime_, paste0('n = ', n_), sep = ', '),
        y = 'normalized fit')
  }
  
  
  for (K_ in c(2, 4)) {
    for (delta_ in c(0.05, 0.1)) {
      
      data.filt <- data %>% 
        filter(regime %in% c('R1', 'R2')) %>%
        filter(K == K_) %>%
        filter(delta == delta_)
      
      
      for (scenario in c('S1', 'S2', 'S3', 'S4')) {
        
        
        plots <- list()      
        for (regime in c('R1', 'R2')) {
          for (n in c(250, 500, 1000)) {
            plots[[length(plots)+1]] <- generate_scree_plot(data.filt, scenario, regime, n, 1, K_)
          }
        }
        
        g <- grid.arrange(grobs = plots, nrow = 3, ncol = 2, as.table=FALSE)
        path <- file.path(
          'simulation', 'results', design.id, 
          str_glue('sim-scree-K{K_}-d{100*delta_}-{scenario}.png')
        )
        ggsave(path, g, width=7.0, height=10.0)      
        
      }
      
      
    }
  }
  
  
}



## Accuracy Comparison =========================================================


if (args$acc_comp) {
  
  path.data <- file.path('simulation', 'results', design.id, 'acc-comp-data.csv')
  if (args$acc_comp_old_data) {
    data <- read.csv(path.data)
  }
  else {
    
    ## Compile comparison data -----------------------------------------------------
    
    col.names <- c('scenario', 'regime', 'n', 'delta', 'K', 'rep', 'method', 'err', 'rel.err.dps', 'rel.err.ffa')
    data <- data.frame(matrix(nrow = 0, ncol = length(col.names)))
    colnames(data) <- col.names
    for (i in 1:nrow(config.map)) {
      print(str_glue("{i} of {nrow(config.map)}"))
      dir.data <- file.path('simulation', 'data', design.id, paste0('config-', config.map$config.id[i]))
      
      for (r in 1:design$num_reps) {
        
        tryCatch({
          
          L <- csv_to_matrix(file.path(dir.data, paste0('mat-L_.csv.gz')))
          L.ffa <- csv_to_matrix(file.path(dir.data, paste0('mat-Lhat_method-ffa_r-', r, '_.csv.gz')))
          L.dps <- csv_to_matrix(file.path(dir.data, paste0('mat-Lhat_method-dps_r-', r, '_.csv.gz')))
          L.dp <- csv_to_matrix(file.path(dir.data, paste0('mat-Lhat_method-dp_r-', r, '_.csv.gz')))
          L.kl <- csv_to_matrix(file.path(dir.data, paste0('mat-Lhat_method-kl_r-', r, '_.csv.gz')))
          L.ica <- csv_to_matrix(file.path(dir.data, paste0('mat-Lhat_method-ica_r-', r, '_.csv.gz')))
          
          err.ffa <- norm(L.ffa%*%t(L.ffa) - L%*%t(L), type = 'F') / norm(L%*%t(L), type = 'F')
          err.dps <- norm(L.dps%*%t(L.dps) - L%*%t(L), type = 'F') / norm(L%*%t(L), type = 'F')
          err.dp <- norm(L.dp%*%t(L.dp) - L%*%t(L), type = 'F') / norm(L%*%t(L), type = 'F')
          err.kl <- norm(L.kl%*%t(L.kl) - L%*%t(L), type = 'F') / norm(L%*%t(L), type = 'F')
          err.ica <- norm(L.ica%*%t(L.ica) - L%*%t(L), type = 'F') / norm(L%*%t(L), type = 'F')
          
          rel.err.dps.ffa <- err.ffa / err.dps
          rel.err.dps.dps <- err.dps / err.dps
          rel.err.dps.dp <- err.dp / err.dps
          rel.err.dps.kl <- err.kl / err.dps
          rel.err.dps.ica <- err.ica / err.dps
          
          rel.err.ffa.ffa <- err.ffa / err.ffa
          rel.err.ffa.dps <- err.dps / err.ffa
          rel.err.ffa.dp <- err.dp / err.ffa
          rel.err.ffa.kl <- err.kl / err.ffa
          rel.err.ffa.ica <- err.ica / err.ffa
          
          temp <- data.frame(
            method = c('ffa', 'dps', 'dp', 'kl', 'ica'),
            err = c(err.ffa, err.dps, err.dp, err.kl, err.ica),
            rel.err.dps = c(rel.err.dps.ffa, rel.err.dps.dps, rel.err.dps.dp, rel.err.dps.kl, rel.err.dps.ica),
            rel.err.ffa = c(rel.err.ffa.ffa, rel.err.ffa.dps, rel.err.ffa.dp, rel.err.ffa.kl, rel.err.ffa.ica)
          )
          temp$scenario <- config.map$scenario[i]
          temp$regime <- config.map$regime[i]
          temp$n <- config.map$n[i]
          temp$delta <- config.map$delta[i]
          temp$K <- config.map$K[i]
          temp$rep <- r
          temp <- temp[,col.names]
          data <- rbind(data, temp)
          
        }, error = function(e) {
          print(str_glue("ERROR: {e$message}"))
        })
        
      }
    }
    
    write.csv(data, file = path.data, row.names = FALSE)
    
  }
  
  
  ## Stacked Boxplots ------------------------------------------------------------
  
  ## Set triplet factor levels
  Ks <- c(2, 4)
  deltas <- c(0.05, 0.1)
  ns <- c(250, 500, 1000)
  triplet.levels <- c()
  for (K in Ks) {
    for (delta in deltas) {
      for (n in ns) {
        triplet.levels[length(triplet.levels)+1] <- str_glue('({K},{delta},{n})')
      }
    }
  }
  
  ## Wrangle data for plotting
  data <- data %>%
    mutate(triplet = factor(str_glue('({K},{delta},{n})'), levels = triplet.levels))
  
  ## Find x axis limits
  out <- data %>%
    group_by(scenario, regime, triplet, method) %>%
    summarise(
      mean.rel.err.dps = mean(rel.err.dps),
      std.dev.rel.err.dps = sd(rel.err.dps),
      mean.rel.err.ffa = mean(rel.err.ffa),
      std.dev.rel.err.ffa = sd(rel.err.ffa))
  min(c(out$mean.rel.err.dps - 2*out$std.dev.rel.err.dps,
        out$mean.rel.err.ffa - 2*out$std.dev.rel.err.ffa))
  max(c(out$mean.rel.err.dps + 2*out$std.dev.rel.err.dps,
        out$mean.rel.err.ffa + 2*out$std.dev.rel.err.ffa))
  
  ## Wrangle data for plotting
  data$method <- recode(data$method, ica = 'ICA', kl = 'PCA',dp = 'DP', dps = 'DPS', ffa = 'FFA')
  ## Range: [0.47, 5.12]
  
  ## FFA Relative Error Plots
  for (regime_ in c('R1', 'R2')) {
    
    p <- data %>%
      filter(regime == regime_) %>%
      filter(method %in% c('ICA', 'PCA', 'DP', 'DPS')) %>%
      group_by(scenario, triplet, method) %>%
      summarise(
        mean.rel.err = mean(rel.err.ffa),
        std.dev.rel.err = sd(rel.err.ffa)) %>%
      ggplot(aes(y = triplet, x = mean.rel.err, colour = method)) +
      geom_pointrange(aes(
        xmin = mean.rel.err - 2*std.dev.rel.err,
        xmax = mean.rel.err + 2*std.dev.rel.err),
        cex = 0.1,
        position = position_dodge(width = 0.5)) +
      scale_y_discrete(limits=rev) +
      geom_vline(xintercept = 1, lty = 'dotted') +
      scale_x_continuous(breaks = 1:6, limits = c(0.4, 5.9)) +
      labs(
        x = "Error Relative to FFA",
        y = "(K,delta,n)") +
      facet_wrap(~scenario, nrow = 2)
    
    path <- file.path(
      'simulation', 'results', design.id,
      str_glue('sim-comparison-{regime_}-3.png') # TODO: Rename as needed
    )
    ggsave(path, p, width=7.0, height=10.0)
    
  }
  
}



## Interpretability Comparison =================================================


if (args$int_comp) {
  
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
      breaks_labs <- to_exp_scale(breaks)
      leg.val <- 'log(value)'
    } else {
      breaks_labs <- breaks
      leg.val <- 'value'
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
        fill = leg.val,
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
  
  config <- yaml.load_file(
    file.path('simulation', 'data', design.id, 'config-1', 'config.yml')
  )
  num.facs <- config$settings$K
  
  method.to.name <- list(
    'ffa' = 'ffa',
    'dps' = 'dps',
    'dp' = 'dp',
    'kl' = 'pca',
    'ica' = 'ica'
  )
  nfacs.to.img.size <- list(
    '8' = c(2, 4),
    '25' = c(5, 5)
  )
  breaks <- c(-0.2, -0.1, 0, 0.1, 0.2)
  
  for (method in names(method.to.name)) {
      
    ## Read in loads
    path <- file.path(config$dirs$data, str_glue('mat-Lhat_method-{method}_r-1_.csv.gz'))
    loads <- csv_to_matrix(path)
    loads <- array_reshape(loads, c(design$M, design$M, num.facs))
    
    ## Create plot
    plots <- vector('list', num.facs)
    data <- melt(loads)
    colnames(data) <- c('x', 'y', 'k', 'val')
    max.pltmag <- max(abs(data$val))
    for (k in 1:num.facs) {
      plots[[k]] <- plot_loading(data, k, 0, breaks, title = str_glue('k = {k}'))
    }
    num.row <- nfacs.to.img.size[[as.character(num.facs)]][1]
    num.col <- nfacs.to.img.size[[as.character(num.facs)]][2]
    g <- ggarrange(
      plotlist = plots,
      nrow = num.row, ncol = num.col, 
      common.legend = TRUE, 
      legend = 'bottom'
    )
    path <- file.path(config$dirs$results, str_glue('loads_method-{method}.png'))
    ggexport(g, filename=path, width=200*num.col, height=200*num.row)
      
  }
  
}


