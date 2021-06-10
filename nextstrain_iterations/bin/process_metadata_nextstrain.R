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

### IGNORE CODE BLOCK BELOW: TESTING PURPOSES ONLY ###

# ### experimental code: random subset that loop until conditions are met####
# 
# ### test filter: keep two observations for each combination of health region and lineage
# gisaid_filter_test <- do.call(rbind, by(gisaid_no_outbreak, list(gisaid_no_outbreak$Health_Region,
#                                                                  gisaid_no_outbreak$PANGO_lineage), 
#                                         FUN=function(x) head(x, 2)))
# 
# 100 * (nrow(pho_data[pho_data$Health.Region == "Eastern", ]) / nrow(pho_data))
# 100 * (nrow(pho_data[pho_data$Health.Region == "Toronto", ]) / nrow(pho_data))
# 
# # establish a repeat with two conditions for the percentage of sampples in each region
# # once the percentages drop below the values, the loop will terminate with the appropriate subset
# subset_with_condition_2 <- function(nextstrain_data) {
#   subset_nextstrain <- nextstrain_data
#   percent_eastern <-
#     100 * nrow(nextstrain_data[nextstrain_data$Health.Region == "Eastern",]) /
#     nrow(nextstrain_data)
#   percent_toronto <-
#     100 * nrow(nextstrain_data[nextstrain_data$Health.Region == "Toronto",]) /
#     nrow(nextstrain_data)
#   repeat {
#     subset_nextstrain <- sample_n(nextstrain_data, 5000)
#     percent_eastern <-
#       100 * nrow(subset_nextstrain[subset_nextstrain$Health.Region == "Eastern",]) /
#       nrow(subset_nextstrain)
#     percent_toronto <-
#       100 * nrow(subset_nextstrain[subset_nextstrain$Health.Region == "Toronto",]) /
#       nrow(subset_nextstrain)
#     print(paste(percent_eastern, percent_toronto, sep = ","))
#     if (as.numeric(percent_eastern) <= 7.9 && as.numeric(percent_toronto) <= 28) {
#       break
#     }
#   }
#   return(subset_nextstrain)
#   }
#   
# subset_test <- subset_with_condition_2(pho_data)
# 
# subset_test <- subset_test[!duplicated(subset_test$WGS_Id),]
# 
# 100 * nrow(subset_test[subset_test$Health.Region == "Eastern", ]) / nrow(subset_test)
# 100 * nrow(subset_test[subset_test$Health.Region == "Toronto", ]) / nrow(subset_test)
# 
# nextstrain_5000 <- sample_n(pho_data, 5000)
# 
# nextstrain_5000 <-
#   nextstrain_5000[!duplicated(nextstrain_5000$WGS_Id), ]
# 
# write.csv(nextstrain_5000,
#           "all_metadata.csv",
#           row.names = F,
#           quote = F)
# 
# 
# gisaid_metadata <- read.table(
#   file.choose(),
#   header = T,
#   sep = '\t',
#   fill = TRUE,
#   quote = ""
# )
# 
# #### Extra code ######
# 
# pho_data$country <- "Canada"
# 
# # read in gisaid metadata for select gisaid context sequences
# metadata <- read.table(
#   file.choose(),
#   header = F,
#   sep = '\t',
#   fill = TRUE,
#   quote = ""
# )
# 
# head(metadata)
# 
# # keep certain metadata fields
# meta_keep <- subset(metadata, select = c(V1, V5, V6, V7, V19))
# 
# colnames(meta_keep) <-
#   c("strain", "date", "region", "country", "PANGO_lineage")
# 
# pho_data$Variant_of_Concern <-
#   ifelse(
#     pho_data$PANGO_lineage == "B.1.1.7",
#     "B.1.1.7",
#     ifelse(
#       pho_data$PANGO_lineage == "B.1.351",
#       "B.1.351",
#       ifelse(pho_data$PANGO_lineage == "P.1", "P.1", "Other Lineage")
#     )
#   )
# 
# # merge metadata and pho data by rows, keep records without all matching rows
# all <- rbind.fill(pho_data, meta_keep)
# 
# # remove duplicate sample name entries
# all <- all[!duplicated(all$strain), ]
# 
# write.csv(all, "all_metadata.csv", row.names = F)
