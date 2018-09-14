
# Scope


## Closures

Consider Michaela's simulation problem from Wednesday.
We generated samples with the doSim() function that we defined
in [funs3.R](funs3.R).
```
doSim =
function(i, alpha = 1, beta = 1, N = 1000, numPerParticipant = 16, verbose = TRUE)
{
    if(verbose)  print(i)

    simData <- matrix(rbeta(n = N*i*16, shape1 = alpha, shape2 = beta), N*i, numPerParticipant) # simulate data per participant)  
    ans = t(apply(simData, 1, function(x) c(mean = mean(x, na.rm = TRUE), sd = sd(x, na.rm = TRUE))) )
    cbind(ans, obs = rep(1:N, i), sampleSize = rep(i, N*i))
}
```

This generated data from a Beta distribution.
We allow the caller to specify different parameters for the Beta distribution so that they can use different
distributions, but only the Beta.

How can we extend this to use the same framework but for different ways to generate the data?

A second question is how do we adapt this code to work with say the median rather than 
the mean, or the 75% quantile or maximum?


In this case, a good approach is to separate the generation of the data and the computation
of the statistics for each row. Each of these is just one line of code so we can easily 
separate them into two functions and then the caller can replace either of them.
To be concrete, we could have  two functions
```
simData = 
function(i, alpha = 1, beta = 1, N = 1000, numPerParticipant = 16)
{
   matrix(rbeta(n = N*i*16, shape1 = alpha, shape2 = beta), N*i, numPerParticipant) # simulate data per participant 
}

simResults = 
function(simData, i, N)
{
  ans = t(apply(simData, 1, function(x) c(mean = mean(x, na.rm = TRUE), sd = sd(x, na.rm = TRUE))))
  cbind(ans, obs = rep(1:N, i), sampleSize = rep(i, N*i))
}
```
Then we could combine these with
```
simResults(simData(24))
```

Note that we have to pass values for i and N to simResults as this information cannot be recovered
from the result returned by simData().  We can fix this. See below.



When the simData() function  is more complex and does more than arrange the generated values into a
matrix,  we may want to seperate generating the values and processing them.
One approach to this is to allow the caller to specify the values.
We could write this as 
```
simData = 
function(i, alpha = 1, beta = 1, N = 1000, numPerParticipant = 16,
         values = rbeta(n = N*i*16, shape1 = alpha, shape2 = beta))
{
   matrix(values, N*i, numPerParticipant) # simulate data per participant 
}
```
We have just moved the call to rbeta() into the default value of a new parameter named values.
If the caller doesn't specfy a value for the values parameter, it is computed as before.
This uses the values of the parameters `alpha` and `beta` and also `N` and `i`.
The defaults are used for each of these if none are provided.

However, if the caller specifies a vector of values, then these are used. So we can call this with
```
simData(24, values = rnorm(1000*24*16, 10, 4))
```
to generate data from a Normal(10, 4) distribution,
The 24*1000 is `i*N*numPerParticipant` which we have to specify ourselves, and repeat the information in `i` and
the default for `N`.
Or we could use
```
simData(10, values = rexp(1000*10, .1))
```
to generate data from an Exponential().

Note that alpha and beta are now redundant and a little confusing.


We can use a different approach to try to clean up the problems of 
+ specifying `i*N*numPerParticipant` when creating `values`
+ redundant parameters alpha and beta.
We can have the user specify the function to use to generate
the values.
A simple implementation is 
```
simData = 
function(i, rgen = rbeta, ..., N = 1000, numPerParticipant = 16)
{ 
   values = rgen(N*i*numPerParticipant, ...)
   matrix(values, N*i, numPerParticipant) # simulate data per participant 
}
```
We can call this, e.g., with
```
simData(24, , .5, .5)
```
Note that we skipped the second parameter which is the generator function.
We could have also written this as
```
simData(24, , shape1 = .5, shape2 = .5)
```
as these parameter names (shape1 and shape2) will be matched to ...
and passed on to the call to the rbeta function where they will match
the second and third parameter of that function.

We can also generate the values from the Exponential distribution with
```
simData(24, rexp, .1)
```







