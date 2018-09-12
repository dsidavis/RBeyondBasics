# this code has 3 parts: 
# 1. specify distribution, 2. simulate data, 
# 3. run t-tests and save results, & 4. tidy up the data.


# install.packages("beepr")
# install.packages("tidyr")
library(beepr)
library(tidyr)
############################################################################
# 1. specify parameters for a beta distribution ############################

#function to get a and b: 
get.ab <- function(mu, var){
  v <- var
  w <- mu/(1-mu)
  b <- ((w/ (v*(w^2 + 2*w + 1))) - 1)  / (w + 1)
  a <- b*w
  return(list(a = a, b = b))
}

ab <- get.ab(mu = .56, var = .05) # set the mean and variance
alpha <- ab[[1]] 
beta <- ab[[2]]

############################################################################
# 2. simulate data using a beta distribution ###############################

# i = sample size; 2-i currently. 
# j = number of samples to draw from the population--should be 1000. 

# create some container lists 
simDataSave1 = list()
simDataSaveSummary = list()
simDataSaveSummaryList = list()

for (i in 2:24){ # draw samples sizes of 2, 3, 4,...24.
  print(i)
  for (j in 1:1000) { # draw 1000 samples per sample size
    simData <- data.frame(matrix(rbeta(n = i*16, shape1 = alpha, shape2 = beta), i, 16)) # simulate data (16 trials per participant)
    simDataSave1[[j]] <- simData
    row_mean <- apply(simData, 1, function(x) mean(x, na.rm = T)) # mean from each row of simulated data across the 16 trials
    sd_row <- apply(simData,1, function(x) sd(x, na.rm = T)) # sd from each row of simulated data across the 16 trials
    simDataSaveSummary[[j]] <- data.frame(row_mean, sd_row) # save these summary stat results in simDataSaveSummary
    simData <- NULL # "erase" simData to start again
  } #j
  simDataSaveSummaryList[[i-1]] <- as.data.frame(simDataSaveSummary) # save the summary data in a list
} #i 
beep()

############################################################################
# 3. run t-tests on simulated data sample means and save p values ##########

# create some container lists
results = list()
results2 = list()

for (i in 1:length(simDataSaveSummaryList)){ # the length of simDataSaveSummaryList will be 23 long, but within each list, there are 2000 cols
  print(i)
  for (j in 1:length(simDataSaveSummaryList[[i]])) { 
    if (j %% 2 > 0){ # only want to take the mean (first, third, fifth....nth column in the dataframe)
      output = try(t.test(simDataSaveSummaryList[[i]][,j], mu = .5), silent = TRUE)
      if (inherits(output, "try-error")) # throws an error sometimes with smaller n, can't rememebr exactly what it said...but this code gets around an error.
      {
        cat(output) 
        output <- NA
      }
      if (is.atomic(output) == TRUE) {
        results[(j+1)/2] = NA} else { 
          results[(j+1)/2] = output$p.value
        }
    } else {
      next() 
    }
    results = as.data.frame(results)  
    colnames(results) = paste(i+1, seq(1,j/2+1), sep = "_") # added i+1 to shift the n number forward one because our i loop starts at 2 above.
    results2[[i]] = results
  }# for i
}
beep()
results2 = as.data.frame(results2)

# check things out
tail(t(results2))
head(t(results2))

############################################################################
# 4. make the data long & rearrange ########################################

# make the data long/rearrage

# head(long.p.values) check
long.p.values %>% separate(colName, c("sampleSize", "iter"), sep = "_") -> long.p.values # separate the colName column into two columns
long.p.values$sampleSize <- gsub('\\X', '', long.p.values$sampleSize) # replace "X" with nothing
long.p.values$sampleSize = as.factor(long.p.values$sampleSize)
# head(long.p.values) 

# done!
