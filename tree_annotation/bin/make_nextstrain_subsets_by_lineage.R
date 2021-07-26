library(data.table)
library(dplyr)
library(optparse)


option_list = list(
  make_option(c("-i", "--input_lineage"), type="character", default=NULL, 
              help="Input lineage report CSV for PHO sequences", metavar="character"),
  make_option(c("-l", "--lineage_id"), type="character", default=NULL, 
              help="ID of the lineage to create subset", metavar="character")
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

# read the pangolin lineage report and get the WGS Ids with the lineage
pangolin_pho <- read.table(opt$input_lineage, header = TRUE, sep=',', fill = TRUE, quote = "")

subset_pho <- subset(pangolin_pho, lineage == opt$lineage_id)

# write the unique IDs only
unique_ids <- unique(subset_pho$taxon)

output_file <- paste(opt$lineage_id, ".txt", sep="")
write.table(unique_ids,
          output_file,
          row.names = F,
          col.names = F,
          quote = F)
