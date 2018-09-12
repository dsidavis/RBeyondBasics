
doSim =
function(i, N = 1000, verbose = TRUE)
{
    if(verbose)  print(i)
    
    replicate(N, {
        simData <- matrix(rbeta(n = i*16, shape1 = alpha, shape2 = beta), i, 16) # simulate data (16 trials per participant)
        # mean from each row of simulated data across the 16 trials
        # sd from each row of simulated data across the 16 trials
        t(apply(simData, 1, function(x) c(mean = mean(x, na.rm = TRUE), sd = sd(x, na.rm = TRUE))) )
    }, simplify = FALSE)
}
