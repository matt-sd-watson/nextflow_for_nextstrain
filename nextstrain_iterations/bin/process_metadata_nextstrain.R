library(data.table)
library(dplyr)
library(plyr)
library(stringr)
library(argparse)

parser <- ArgumentParser(description='Generate a random subset of metadata for Nextstrain')
parser$add_argument('--input_metadata', type = "character", 
                    help='path to metadata sheet')
parser$add_argument('--output_file', type = "character", 
                    help='output file for the sub-sampled metadata sheet')
parser$add_argument('--subset_number', type = "integer", 
                    help='Number of PHO sequences for the Nextstrain build')
parser$add_argument('--rep', type = "character", 
                    help='the character specifying the iteration for the metadata sheet')

args <- parser$parse_args()

# read in metadata from the qc90 list
pho_data <- read.table(
  args$input_metadata,
  header = T,
  sep = ',',
  fill = TRUE,
  quote = ""
)

pho_data <- pho_data[!duplicated(pho_data$WGS_Id), ]
pho_data <- pho_data[pho_data$Date != "--",]
pho_data <- pho_data[pho_data$Pango.Lineage != "None",]

pho_data <- pho_data[order(as.Date(pho_data$Date, format = "%Y-%m-%d")),]

samples_ignore <- c("PHLON21-SARS08947", "PHLON21-SARS08968", "PHLON21-SARS08971",
                    "PHLON21-SARS08946", "PHLON21-SARS12146", "PHLON21-SARS01262",
                    "PHLON21-SARS01274", "PHLON21-SARS01288", "PHLON21-SARS01291",
                    "PHLON21-SARS08025", "PHLON21-SARS07900", "PHLON21-SARS07829",
                    "PHLON21-SARS07829", "PHLON21-SARS07811", "PHLON21-SARS01324",
                    "PHLON21-SARS07827", "PHLON21-SARS13134", "PHLON20-SARS03285",
                    "PHLON20-SARS03544")

pho_data <- pho_data[!pho_data$WGS_Id %in% samples_ignore,]

pho_data <- pho_data[pho_data$GISAID.Clade != "",]

# group by the outbreak id and keep only the first 2 observations from each outbreak
# split into samples that have outbreak ID and not, retain all samples without outbreak designation
# re-merge the outbreak and non-outbreak samples before random subsetting

gisaid_no_outbreak <- pho_data[pho_data$OB_Id == "",]
gisaid_outbreak <- pho_data[pho_data$OB_Id != "",]

gisaid_filter_outbreak <- gisaid_outbreak[with(gisaid_outbreak, do.call(order, list(OB_Id))), ]
# specify the fields to group by in list
# specify how many samples per grouping to retain with head
gisaid_filter_outbreak <- do.call(rbind, by(gisaid_filter_outbreak, list(gisaid_filter_outbreak$OB_Id), 
                                            FUN=function(x) head(x, 2)))

final_gisaid <- rbind(gisaid_no_outbreak, gisaid_filter_outbreak)

final_subset <- sample_n(final_gisaid, args$subset_number)
setnames(final_subset, "PHO.WGS.Id", "strain")
setnames(final_subset, "Date", "date")

output_file <- paste("rep_", args$rep, ".csv", sep="") # replace with desired output directory
write.csv(final_subset,
          output_file,
          row.names = F,
          quote = F)
