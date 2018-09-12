+ Hard coding 1000, 24.  
  + We want to be able to change these and rerun the code.  Set early in the script as variables.

+ Preallocate list length for simDataSave1, simDataSaveSummary.
   + However, we can avoid this explicit allocation.
   
+ Instead of for(i in 2:24), use replicate ? or lapply(2:24, fun)   
   + This allows us to test the function before we call it repeatedly
   + And to test it with different values of i.
   
+ Why create the data.frame(matrix()) and not just leave as a matrix.
   + apply() converts the data.frame to a matrix so the data.frame(matrix) followed by apply()
     converts from matrix to data.frame to matrix again. And then we do this again in the next call
     to apply.
	 
+ 2 sucecssive calls to apply() can be replaced by one call where we compute both values inside a
  function.
  
+ Why do we need the na.rm = TRUE. There is no chance of getting a NA since we generate values.

+ Can we vectorize the entire computation in the first loop?

+ simDataSave1 is never used.

+ as.data.frame(simDataSaveSummary) - what does that do for a list of data.frame objects?
  + a data frame ?
  + how many rows? columns?
    + what you expect?

+ cleaning up simData <- NULL is good
   + but probably more important to avoid simDataSave1 as simData will get garbage collected (GC) in the
     next iteration since simData is overwritten.  So the previous value is GC'ed



+ When performing simulations, set the seed for reproducability
   + set.seed(someValue)


+ CAVEAT: Given that this takes very little time, do we really need to make it faster
+ And we can use theory - CLT - to determine how this performs.
