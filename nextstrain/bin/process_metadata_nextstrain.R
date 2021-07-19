library(data.table)
library(dplyr)
library(optparse)

option_list = list(
  make_option(c("-i", "--input_metadata"), type="character", default=NULL, 
              help="path to metadata sheet", metavar="character"),
  make_option(c("-o", "--output_file"), type="character", default=NULL, 
              help="output file for the sub-sampled metadata sheet", metavar="character"),
  make_option(c("-s", "--subset_number"), type="integer", default=NULL, 
             help="Number of PHO sequences for the Nextstrain build", metavar="integer"),
  make_option(c("-c", "--category"), type="character", default=NULL, 
              help="the character specifying the unique subset for the metadata sheet", metavar="character")
); 

opt_parser = OptionParser(option_list=option_list);
opt = parse_args(opt_parser);

# read in metadata from the qc90 list
pho_data <- read.table(
  opt$input_metadata,
  header = T,
  sep = ',',
  fill = TRUE,
  quote = ""
)

pho_data <- pho_data[!duplicated(pho_data$WGS_Id), ]
pho_data <- pho_data[pho_data$Date != "--",]
pho_data <- pho_data[pho_data$Pango.Lineage != "None",]

pho_data <- pho_data[order(as.Date(pho_data$Date, format = "%Y-%m-%d")),]

pho_data <- pho_data[pho_data$GISAID.Clade != "",]

# group by the outbreak id and keep only the first 2 observations from each outbreak
# split into samples that have outbreak ID and not, retain all samples without outbreak designation
# re-merge the outbreak and non-outbreak samples before random subsetting

# gisaid_no_outbreak <- pho_data[pho_data$OB_Id == "",]
# gisaid_outbreak <- pho_data[pho_data$OB_Id != "",]
# 
# gisaid_filter_outbreak <- gisaid_outbreak[with(gisaid_outbreak, do.call(order, list(OB_Id))), ]
# # specify the fields to group by in list
# # specify how many samples per grouping to retain with head
# gisaid_filter_outbreak <- do.call(rbind, by(gisaid_filter_outbreak, list(gisaid_filter_outbreak$OB_Id), 
#                                             FUN=function(x) head(x, 2)))
# 
# final_gisaid <- rbind(gisaid_no_outbreak, gisaid_filter_outbreak)

final_subset <- sample_n(pho_data, opt$subset_number)
setnames(final_subset, "PHO.WGS.Id", "strain")
setnames(final_subset, "Date", "date")

output_file <- paste(opt$category, ".csv", sep="") # replace with desired output directory
write.csv(final_subset,
          output_file,
          row.names = F,
          quote = F)
