
doSim =
function(i, alpha = 1, beta = 1, N = 1000, verbose = TRUE)
{
    if(verbose)
       print(i)

    simData <- matrix(rbeta(n = N*i*16, shape1 = alpha, shape2 = beta), N*i, 16) # simulate data (16 trials per participant)  
    t(apply(simData, 1, function(x) c(mean = mean(x, na.rm = TRUE), sd = sd(x, na.rm = TRUE))) )
}
