effort.rds: effort.csv
# Works but creates an RDS, not an RDA.
	Rscript -e 'saveRDS(read.csv("effort.csv", stringsAsFactors = FALSE), file = "effort.rds")'

BothSpecies.rda: BothSpecies.csv
# Works but have to repeat the name of the file and variable in 3 places.
	Rscript -e 'BothSpecies = read.csv("BothSpecies.csv", stringsAsFactors = FALSE); save(BothSpecies, file = "BothSpecies.rda")'


%.rda: %.csv
	Rscript -e "$* = read.csv(\"$*.csv\", stringsAsFactors = FALSE); saveRDS($*, file = \"$*.rda\")"
