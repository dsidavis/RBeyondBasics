doSim =
function(i, verbose = TRUE)
{    
    if(verbose)
        print(i)
    
    simDataSave1 = vector("list", 1000)
    
    for (j in 1:1000) { # draw 1000 samples per sample size
        simData <- data.frame(matrix(rbeta(n = i*16, shape1 = alpha, shape2 = beta), i, 16)) # simulate data (16 trials per participant)
        row_mean <- apply(simData, 1, mean, na.rm = T) # mean from each row of simulated data across the 16 trials
        sd_row <- apply(simData,1, sd,  na.rm = T) # sd from each row of simulated data across the 16 trials
        simDataSaveSummary[[j]] <- data.frame(row_mean, sd_row) # save these summary stat results in simDataSaveSummary
    } #j
    simDataSave1
}    
