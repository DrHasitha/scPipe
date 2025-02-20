###########################################################
# Create a SingleCell Experiment Object for scATAC-Seq data
###########################################################

#' sc_atac_create_sce()
#'
#' @param input_folder The output folder produced by the pipeline
#' @param organism The type of the organism
#' @param feature_type The type of the feature
#' @param pheno_data The pheno data
#' @param report Whether or not a HTML report should be produced
#'
#' @examples
#' \dontrun{
#' sc_atac_create_sce(
#'    input_folder = input_folder,
#'    organism = "hg38",
#'    feature_type = "peak",
#'    report = TRUE)
#' }    
#' 
#' @export
#'

sc_atac_create_sce <- function(input_folder = NULL, 
                               organism     = NULL, 
                               feature_type = NULL, 
                               pheno_data   = NULL, 
                               report       = FALSE) {
  
  # if(is.null(input_folder)){
  #   input_folder <- file.path(getwd(), "scPipe-atac-output")
  #   input_stats_folder <- file.path(getwd(), "scPipe-atac-output/scPipe_atac_stats")
  # } else {
  #   cat("input location ", input_folder, " is not valid. Please enter the full path to proceed. \n")
  #   break;
  # }
  
  if(is.null(input_folder)){
    input_folder <- file.path(getwd(), "scPipe-atac-output")
    input_stats_folder <- file.path(getwd(), "scPipe-atac-output/scPipe_atac_stats")
  }
  
  if (!dir.exists(input_folder)){
    cat("Default input folder could not be found at " , input_folder,  "\nPlease enter the full input path to proceed \n");
  } else {
    input_stats_folder <- file.path(input_folder, "scPipe_atac_stats")
  }
  
  #feature_cnt   <- readMM(file.path(input_folder, "sparse_matrix.mtx"))
  feature_cnt   <- readRDS(file.path(input_folder, "sparse_matrix.rds"))
  cell_stats    <- read.csv(file.path(input_stats_folder, "filtered_stats_per_cell.csv"), row.names=1)
  feature_stats <- read.csv(file.path(input_stats_folder, "filtered_stats_per_feature.csv"))
  
  # need to change from here.... (check whether I need to filter before saving to the SCE object)
  
  # can I order a matrix like a csv file like below? test...
  feature_cnt      <- feature_cnt[, order(colnames(feature_cnt))]
  
  qc <- utils::read.table(file.path(input_folder, "qc_per_bc_file.txt"), header = TRUE, row.names = "bc")
  cell_stats <- merge(x = cell_stats, y = qc, by = 0, all.x = TRUE) %>% tibble::column_to_rownames(var = "Row.names")
  cell_stats       <- cell_stats[order(rownames(cell_stats)), ]
  

  # generating the SCE object
  sce                         <- SingleCellExperiment(assays = list(counts = feature_cnt))

  sce@metadata$scPipe$version <- packageVersion("scPipe")  # set version information
  
  if(!is.null(organism)){
    organism(sce) <- organism
  }
  
  if(!is.null(feature_type)){
    feature_type(sce) <- feature_type
  }
  
  # Saving demultiplexing stats to sce object
  stats_file <- file.path(input_stats_folder, "mapping_stats_per_barcode.csv")
  raw <- read.csv(stats_file, row.names = "barcode")
  
  
  QC_metrics(sce) <- cell_stats
  demultiplex_info(sce) <- raw
  
  
  
  if(!is.null(pheno_data)){
    colData(sce) <- cbind(colData(sce), pheno_data[order(rownames(pheno_data)),])
  }

  feature_info(sce) <- feature_stats
  saveRDS(sce, file = file.path(input_folder, "scPipe_atac_SCEobject.rds"))
  
  if(report){
    sc_atac_create_report(input_folder = file.path(input_folder),
                          output_folder= file.path(input_folder, "scPipe_atac_stats"),
                          sample_name  = NULL,
                          organism     = organism,
                          feature_type = feature_type)
  }
  
  
  return(sce)
  
}

#' @name sc_atac_plot_fragments_per_cell
#' @title A histogram of the log-number of fragments per cell
#'
#' @param sce The SingleExperimentObject produced by the sc_atac_create_sce function at the end of the pipeline
#'
#' @return returns NULL
#' @export
#'
sc_atac_plot_fragments_per_cell <- function(sce) {
  cell_stats <- as.data.frame(QC_metrics(sce))
  cell_stats$log_counts_per_cell <- log(cell_stats$counts_per_cell+1)

  ggplot(cell_stats, aes(x=log_counts_per_cell, y = ..count..)) +
    geom_histogram(color = "#E6AB02", fill = "#E6AB02", bins = 10) +
    stat_density(geom = "line", color = "#E6AB02") +
    ggtitle("Counts per cell") +
    xlab("log_counts_per_cell") + 
    ylab("count") 
}

#' @name sc_atac_plot_fragments_per_feature
#' @title A histogram of the log-number of fragments per feature
#'
#' @param sce The SingleExperimentObject produced by the sc_atac_create_sce function at the end of the pipeline
#'
#' @return returns NULL
#' @export
#'
sc_atac_plot_fragments_per_feature <- function(sce) {
  feature_stats <- as.data.frame(feature_info(sce))
  feature_stats$log_counts_per_feature <- log(feature_stats$counts_per_feature+1)

  ggplot(feature_stats, aes(x=log_counts_per_feature, y = ..count..)) +
    geom_histogram(color = "#E6AB02", fill = "#E6AB02", bins = 10) +
    stat_density(geom = "line", color = "#E6AB02") +
    ggtitle("Counts per feature") +
    xlab("log_counts_per_feature") + 
    ylab("count") 
}


#' @name sc_atac_plot_features_per_cell
#' @title A histogram of the log-number of features per cell
#'
#' @param sce The SingleExperimentObject produced by the sc_atac_create_sce function at the end of the pipeline
#'
#' @return returns NULL
#' @export
#'
sc_atac_plot_features_per_cell <- function(sce) {
  cell_stats <- as.data.frame(QC_metrics(sce))
  cell_stats$log_features_per_cell <- log(cell_stats$features_per_cell+1)

  ggplot(cell_stats, aes(x=log_features_per_cell, y = ..count..)) +
    geom_histogram(color = "#7570B3", fill = "#7570B3", bins = 10) +
    stat_density(geom = "line", color = "#7570B3") +
    ggtitle("Features per cell") +
    xlab("log_features_per_cell") + 
    ylab("count") 
}

#' @name sc_atac_plot_features_per_cell_ordered
#' @title Plot showing the number of features per cell in ascending order
#'
#' @param sce The SingleExperimentObject produced by the sc_atac_create_sce function at the end of the pipeline
#'
#' @return returns NULL
#' @export
#'
sc_atac_plot_features_per_cell_ordered <- function(sce) {
  cell_stats <- QC_metrics(sce)
  plot(sort(cell_stats$features_per_cell), 
       xlab= 'cell', 
       log= 'y', 
       ylab = "features", 
       main= 'features per cell (ordered)',
       col = "#1B9E77")
}

#' @name sc_atac_plot_cells_per_feature
#' @title A histogram of the log-number of cells per feature
#'
#' @param sce The SingleExperimentObject produced by the sc_atac_create_sce function at the end of the pipeline
#'
#' @return returns NULL
#' @export
#'
sc_atac_plot_cells_per_feature <- function(sce) {
  feature_stats <- as.data.frame(feature_info(sce))
  feature_stats$log_cells_per_feature <- log(feature_stats$cells_per_feature+1)
  
  ggplot(feature_stats, aes(x=log_cells_per_feature, y = ..count..)) +
    geom_histogram(color = "#7570B3", fill = "#7570B3", bins = 10) +
    stat_density(geom = "line", color = "#7570B3") +
    ggtitle("Cells per feature") +
    xlab("log_cells_per_feature") + 
    ylab("count") 
      
}

#' @name sc_atac_plot_fragments_features_per_cell
#' @title A scatter plot of the log-number of fragments and log-number of features per cell
#'
#' @param sce The SingleExperimentObject produced by the sc_atac_create_sce function at the end of the pipeline
#'
#' @return returns NULL
#' @export
#'
sc_atac_plot_fragments_features_per_cell <- function(sce) {
  cell_stats <- as.data.frame(QC_metrics(sce))
  cell_stats$log_counts_per_cell <- log(cell_stats$counts_per_cell+1)
  cell_stats$log_features_per_cell <- log(cell_stats$features_per_cell+1)

  ggplot(cell_stats, aes(x=log_counts_per_cell, y=log_features_per_cell)) +
    geom_point(color = "#E6AB02") +
    ggtitle("Relationship between counts and features per cell") +
    xlab("log_counts_per_cell") + 
    ylab("log_features_per_cell") +
    geom_smooth(formula = y ~ x, method='lm', color = "#E6AB02", fill = "#E6AB02")
}

#' @name sc_atac_plot_fragments_cells_per_feature
#' @title A scatter plot of the log-number of fragments and log-number of cells per feature
#'
#' @param sce The SingleExperimentObject produced by the sc_atac_create_sce function at the end of the pipeline
#'
#' @return returns NULL
#' @export
#'
sc_atac_plot_fragments_cells_per_feature <- function(sce) {
  feature_stats <- as.data.frame(feature_info(sce))
  feature_stats$log_counts_per_feature <- log(feature_stats$counts_per_feature+1)
  feature_stats$log_cells_per_feature <- log(feature_stats$cells_per_feature+1)

  ggplot(feature_stats, aes(x=log_counts_per_feature, y=log_cells_per_feature)) +
    geom_point(color = "#7570B3") +
    xlab("log_counts_per_feature") + 
    ylab("log_cells_per_feature") +
    geom_smooth(formula = y ~ x, method='lm', color = "#7570B3", fill = "#7570B3")
}

