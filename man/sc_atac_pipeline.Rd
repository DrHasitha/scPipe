% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/sc_atac_pipeline.R
\name{sc_atac_pipeline}
\alias{sc_atac_pipeline}
\title{A convenient function for running the entire pipeline}
\usage{
sc_atac_pipeline(
  r1,
  r2,
  barcode_fastq = NULL,
  barcode_csv = NULL,
  valid_barcode_file = "",
  id1_st = 0,
  id1_len = 16,
  id2_st = 0,
  id2_len = 16,
  rmN = TRUE,
  rmlow = TRUE,
  organism = NULL,
  reference = NULL,
  feature_type = NULL,
  remove_duplicates = FALSE,
  samtools_path = NULL,
  genome_size = NULL,
  bin_size = NULL,
  yieldsize = 1e+07,
  mapq = 30,
  exclude_regions = TRUE,
  excluded_regions_filename = NULL,
  fix_chr = "none",
  lower = NULL,
  cell_calling = "filter",
  promoters_file = NULL,
  tss_file = NULL,
  enhs_file = NULL,
  gene_anno_file = NULL,
  min_uniq_frags = 3000,
  max_uniq_frags = 50000,
  min_frac_peak = 0.3,
  min_frac_tss = 0,
  min_frac_enhancer = 0,
  min_frac_promoter = 0.1,
  max_frac_mito = 0.15,
  report = TRUE,
  nthreads = 12,
  output_folder = NULL
)
}
\arguments{
\item{r1}{The first read fastq file}

\item{r2}{The second read fastq file}

\item{barcode_fastq}{The barcode fastq file (need either this or `barcode_csv`)}

\item{barcode_csv}{The barcode csv file (need either this or `barcode_fastq`)}

\item{valid_barcode_file}{file path of the valid (expected) barcode sequences to be found in the bc_file (.txt, can be txt.gz). Only used if
\code{bc_file} is a fastq file. Must contain one barcode per line, with no other separators. 
If given, each barcode from bc_file is matched against the barcode of
best fit (allowing a hamming distance of 1, prioritising barcodes with a higher mapping quality, as given by
the fastq reads quality score)}

\item{id1_st}{barcode start position (0-indexed) for read 1, which is an extra parameter that is needed if the
\code{bc_file} is in a \code{.csv} format.}

\item{id1_len}{barcode length for read 1, which is an extra parameter that is needed if the
\code{bc_file} is in a \code{.csv} format.}

\item{id2_st}{barcode start position (0-indexed) for read 2, which is an extra parameter that is needed if the
\code{bc_file} is in a \code{.csv} format.}

\item{id2_len}{barcode length for read 2, which is an extra parameter that is needed if the
\code{bc_file} is in a \code{.csv} format.}

\item{organism}{The name of the organism e.g. hg38}

\item{reference}{The reference genome file}

\item{feature_type}{The feature type (either `genome_bin` or `peak`)}

\item{remove_duplicates}{Whether or not to remove duplicates (samtools is required)}

\item{samtools_path}{A custom path of samtools to use for duplicate removal}

\item{genome_size}{The size of the genome (used for the \code{cellranger} cell calling method)}

\item{bin_size}{The size of the bins for feature counting with the `genome_bin` feature type}

\item{yieldsize}{The number of reads to read in for feature counting}

\item{mapq}{The minimum MAPQ score}

\item{exclude_regions}{Whether or not the regions should be excluded}

\item{excluded_regions_filename}{The filename of the file containing the regions to be excluded}

\item{fix_chr}{Specify `none`, `exclude_regions`, `feature` or `both` to prepend the string "chr" to the start of the associated file}

\item{lower}{the lower threshold for the data if using the \code{emptydrops} function for cell calling.}

\item{cell_calling}{The desired cell calling method either \code{cellranger}, \code{emptydrops} or  \code{filter}}

\item{promoters_file}{The path of the promoter annotation file (if the specified organism isn't recognised)}

\item{tss_file}{The path of the tss annotation file (if the specified organism isn't recognised)}

\item{enhs_file}{The path of the enhs annotation file (if the specified organism isn't recognised)}

\item{gene_anno_file}{The path of the gene annotation file (gtf or gff3 format)}

\item{min_uniq_frags}{The minimum number of required unique fragments required for a cell (used for \code{filter} cell calling)}

\item{max_uniq_frags}{The maximum number of required unique fragments required for a cell (used for \code{filter} cell calling)}

\item{min_frac_peak}{The minimum proportion of fragments in a cell to overlap with a peak (used for \code{filter} cell calling)}

\item{min_frac_tss}{The minimum proportion of fragments in a cell to overlap with a tss (used for \code{filter} cell calling)}

\item{min_frac_enhancer}{The minimum proportion of fragments in a cell to overlap with a enhancer sequence (used for \code{filter} cell calling)}

\item{min_frac_promoter}{The minimum proportion of fragments in a cell to overlap with a promoter sequence (used for \code{filter} cell calling)}

\item{max_frac_mito}{The maximum proportion of fragments in a cell that are mitochondrial (used for \code{filter} cell calling)}

\item{report}{Whether or not a HTML report should be produced}

\item{nthreads}{The number of threads to use for alignment (sc_align) and demultiplexing (sc_atac_bam_tagging)}

\item{output_folder}{The path of the output folder}
}
\description{
A convenient function for running the entire pipeline
}
\examples{
\dontrun{
sc_atac_pipeline(
  r1,
  r2,
  barcode_csv,
  "hg38",
  "peak",
  remove_duplicates = FALSE
)

}

}
