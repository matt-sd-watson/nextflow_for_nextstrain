library(argparse)
library(dplyr)
library(data.table)

parser <- ArgumentParser(description='Create subsets by lineage for a Nextstrain build')
parser$add_argument('--input_lineage', type = "character", 
                    help='Input lineage report CSV for PHO sequences')
parser$add_argument('--lineage_id', type = "character", 
                    help='ID of the lineage to create subset')
parser$add_argument('--input_metadata', type = "character", 
                    help='ID of the lineage to create subset')

# parser$add_argument('--output_dir', type = "character", 
                    # help='target output dir')

args <- parser$parse_args()

# read the pangolin lineage report and get the WGS Ids with the lineage
pangolin_pho <- read.table(args$input_lineage, header = TRUE, sep=',', fill = TRUE, quote = "")

subset_pho <- subset(pangolin_pho, lineage == args$lineage_id)

# write the unique IDs only
unique_ids <- unique(subset_pho$taxon)

# read in metadata from the qc90 list
pho_data <- read.table(
  args$input_metadata,
  header = T,
  sep = ',',
  fill = TRUE,
  quote = ""
)

pho_data_subset_lineage <- pho_data[pho_data$WGS_Id %in% unique_ids,]

setnames(pho_data_subset_lineage, "PHO.WGS.Id", "strain")
setnames(pho_data_subset_lineage, "Date", "date")

output_file <- paste(args$lineage_id, ".csv", sep="") # replace with desired output directory
write.csv(pho_data_subset_lineage,
          output_file,
          row.names = F,
          quote = F)
