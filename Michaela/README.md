
+ michaela_orig.R - the original code.

We focus first on generating the data, step 1.
There are 2 loops, nested within each other.
We loop from 2 through 24 as the number of observations in each sample.
We then generate 1000 samples for each sample size.

As it stands, the code in the interior loop (1:1000) cannot be tested separately from the
outer loop. Instead, we turn this into a function, named, say, doSim.  
Then we can call this function with
```
simDataSaveSummaryList = lapply(2:24, doSim)
```
Now we can focus on writing doSim() well.

So let's start by copying the inner loop to a function in funs0.R.


One thing we note is that the function uses alpha and beta and we don't pass them as parameters.
These are global variables. We can find these with
```
codetools::findGlobals(doSim, FALSE)
```

# T versus TRUE (and F and FALSE)
Note that T is also a global variable. We should avoid using T and instead use the constant TRUE.

What if we were to use T to stand for time and we set
```
T = 0
```
Then T would be equivalent to FALSE.
However,
```
TRUE = 0
```
is an error.

# NA values
The calls to mean() and sd() have `na.rm = TRUE` to ignore missing values.
How would these arise? We should not get NA values from rbeta if we use sensible values
for alpha and beta. And if we do give inappropriate values for either of these
(shape) parameters, we get NaN, not NA.  So the `na.rm = TRUE` won't help here.
But it doesn't hurt.



# Data frame and Matrix.

Consider the call 
```
simData = data.frame(matrix(rbeta(n = i*16, shape1 = alpha, shape2 = beta), i, 16)) 
apply(simData, 1, function(x) mean(x, na.rm = T)) # mean from each row of simulated data across the 16 trials
```
(actually 2 calls to apply)

We create a matrix, convert it to a data frame and then the apply calls convert the data frame to a
matrix.
How do we know this? Well, we just do! But we could also verify or discover this 
by debugging the apply function and/or seeing if the function as.matrix is called.
```
trace(as.matrix)
z = data.frame(x = 1:10, y = rnorm(10))
apply(z, 1, sum)
```
Sure enough, we see a call to as.matrix.
If we wanted to see where this is done, we might use
```
debug(as.matrix)
apply(z, 1, sum)
```
Then at the Browse prompt, we can use the command where to see the stack of current calls,
i.e., which function was called by which other function to lead to the current point in the
evaluation:
```
Browse[2]> where
where 1: as.matrix(X)
where 2: apply(z, 1, sum)
```
So apply() called as.matrix.
When we are done debugging as.matrix, we call undebug(as.matrix) so that we won't stop in it when it
is called in the future.


So rather than creating a data.frame, let's just leave the random values in a matrix and pass that to apply



# Passing arguments to the Function in apply()

We have 
```
apply(simData, 1, function(x) mean(x, na.rm = TRUE)) 
```
This is good. However, we take this oppportunity to note that we can do this more simply as
```
apply(simData, 1,  mean, na.rm = TRUE) 
```
See [funs0.5.R](funs0.5.R).
Specifically, we are passing the function mean as the function to apply to each row of the matrix.
But we are also arranging to have na.rm = TRUE passed in each of the calls to the mean function,
i.e. for each row.  So this is the same as what we had, but is very marginally more efficient (faster and
uses less memory). This is because it doesn't create an extra call to a function which then calls
mean.


Again, we can see this using the debugger and looking at the call stack.
Let's debug the mean function:
```
debug(mean)
apply(matrix(1:4, 2, 2), 1, function(x) mean(x, na.rm = TRUE)) 
```
```
Browse[2]> where
where 1 at #1: mean(x, na.rm = TRUE)
where 2: FUN(newX[, i], ...)
where 3: apply(matrix(1:4, 2, 2), 1, function(x) mean(x, na.rm = TRUE))
```
However, with 
```
apply(matrix(1:4, 2, 2), 1, mean, na.rm = TRUE) 
```
```
where 1: FUN(newX[, i], ...)
where 2: apply(matrix(1:4, 2, 2), 1, mean, na.rm = TRUE)
```

Remember to call 
```
undebug(mean)
```


# Two calls to apply()

We have two calls to apply() - one to compute the mean of a row and another to compute the standard
deviation.
This means we visit/process each row twice.
Instead of two calls to apply, we could use a single call and have our function calculate 
both the mean and sd of the row:
```
apply(simData, 1, function(x) c(mean = mean(x), stdDev = sd(x)))
```
Note here we have to define a new function which calls mean and sd, unlike what we
did above which was just to pass the mean function to apply. This is because
we have to define what to compute and there isn't a single function that returns
the mean and the sd as a vector.

Note that I put names on the vector to identify the mean and standard deviation. We don't
need this, but it helps to make the result clearer.

And curiously, the result of this call is a matrix with 2 rows and as many columns as there are rows
in simData. I typically want the transpose of this, i.e. 2 columns corresponding to the mean and SD.
So we'll use t() to transpose this.


# for() and replicate()
Finally, we note that the code in the body of the `for(j in 1:1000)` loop doesn't actually use the
value of j. In other words, we do the same thing in each iteration.
To make this more explicit and clearer to the reader who has to verify this by looking for a use of
j,  we'll replace the for() loop with a call to replicate.
See [funs.R](funs.R)

Note the {} around the code in the call to replicate.

Note that replicate will try to simplify its result, just as apply() and sapply() do.
Sometimes this is good. Other times we prohibit it from doing so via 
```
replicate(N, myCode, simplify = FALSE)
```

## Our New doSim() Function

So now our [funs.R](funs.R) looks like
```
doSim =
function(i, N = 1000, verbose = TRUE)
{
    if(verbose)  print(i)
    
    replicate(N, {
        simData <- matrix(rbeta(n = i*16, shape1 = alpha, shape2 = beta), i, 16) # simulate data (16 trials per participant)
        # mean from each row of simulated data across the 16 trials
        # sd from each row of simulated data across the 16 trials
        t(apply(simData, 1, function(x) c(mean = mean(x, na.rm = T), sd = sd(x, na.rm = TRUE))) )
     }, simplify = FALSE)
}
```
This is more succinct and hopefully easier to read and understand.

But does it do the same thing as our original doSim() function?
We care about whether we get the same structure.
We don't necessarily care about getting the same values, since this is  random.
However we can control the random number generation (RNG) using set.seed().
We specify some arbitrary seed value, e.g.,
```
set.seed(124123)
```
and we set this before we run the call to doSim() and running the original nested loop.


So let's run the loop
```
set.seed(124123)
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
``
Next, we'll call doSim() from funs0.R with the sample size being i = 24.
We use i = 24 because simDataSaveSummary is overwritten for each iteration of the i loop.
So we want to compare the output from our function doSim() with the results left in
simDataSaveSummary.
As a result, setting the seed isn't going to give the same values as in the entire loop over all
  values of i since we are only doing i = 24.
```
set.seed(124123)
v = doSim(24)
```
So we can now compare simDataSaveSummary with  v.
For convenience, we'll call simDataSaveSummary o for original.
```
o = simDataSaveSummary
```
We check they have the same structure:
```
class(v) == class(o)
length(v) == length(o)

table(sapply(v, class))
table(sapply(o, class))

table(sapply(v, nrow))
table(sapply(o, nrow))

table(sapply(v, ncol))
table(sapply(o, ncol))
```
So these appear to be the same except that each element in the original is a data.frame
and each element returned by our doSim() function is a matrix. But they have the same dimensions.
We can look at one or two elements in each to see if they values are similar.
Alternatively, we can compare summary statistics, e.g.,
```
sv = t(sapply(v, colMeans))
so = t(sapply(o, colMeans))
boxplot(list(sv[,1], so[,1]))
boxplot(list(sv[,2], so[,2]))
```

Alternatively, we could plot the densities of the original and the doSim results:
```
tmp = as.data.frame(rbind(sv, so))
tmp$version = rep(c("doSim", "original"), each = nrow(sv))
library(ggplot2)
ggplot(tmp, aes(x = mean, colour = version)) + geom_density()
```

It is essential we check the results before we go further.




# simDataSaveSummaryList and as.data.frame

In the original code, we have 
```
for(i in 2:24) {
  ....
  simDataSaveSummaryList[[i-1]] <- as.data.frame(simDataSaveSummary)
}
```
This converts the list of 1000 data frames (each with i rows) into a data.frame.
What is the dimension of each element?
What are the names of the columns?
```
class(simDataSaveSummaryList[[1]])
dim(simDataSaveSummaryList[[1]])
names(simDataSaveSummaryList[[1]])
```
Is this what you were expecting?
The names are suboptimal.

The way I think about the






### Aside - Best Practice.
Note that when accessing elements in simDataSaveSummaryList, the elements corresponding to i are off
by 1, e.g., element 1 corresponds to i = 2.
Perhaps we should put names on this list to indicate the value of i
```
names(simDataSaveSummaryList) = 2:24
```
Now we can use
```
simDataSaveSummaryList[[ "2" ]]
```
which is very different from 
```
simDataSaveSummaryList[[ 2 ]]
```

And note that we have now repeated the value 2:24, i.e., it is used in 2 places. If we ever change that in the loop, we need to change it
here also.  So we should make that a variable. Or better yet, avoid preallocating the
simDataSaveSummaryList object and separately filling its elements and then separately setting the
names of those elements.

