# Copied from Michaela/funs3.R
# Changed hard-coded 16 to a parameter value.

doSim =
function(i, alpha = 1, beta = 1, N = 1000, numPerParticipant = 16, verbose = TRUE)
{
    if(verbose)  print(i)

    simData <- matrix(rbeta(n = N*i*16, shape1 = alpha, shape2 = beta), N*i, numPerParticipant) # simulate data per participant)  
    ans = t(apply(simData, 1, function(x) c(mean = mean(x, na.rm = TRUE), sd = sd(x, na.rm = TRUE))) )
    cbind(ans, obs = rep(1:N, i), sampleSize = rep(i, N*i))
}
