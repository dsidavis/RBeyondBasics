+ The rm(list = ls()) is extremely annoying. Each time I source the function, it removes all of my
  data, including the test data I created and am using to test the function!

+ codetools::findGlobals(tidy, FALSE)
  + [1] "CPUE"            "depth"           "effort"         
    [4] "n"               "site"            "site_total_CPUE"
    [7] "size"           
	Several of these are false positives (due to non-standard evaluation in dplyr, etc.)
	But effort is true positive.

+ `min(c(catch$start_depth, catch$end_depth))`
  Same as `min(catch$start_depth, catch$end_depth)`.
  No need for c().  Depending on how many rows in catch, this could be expensive.

+ `unique(x = subs...)`.  
   Why specifically identify x as parameter name?
   
+ Why c(dQuote(...)).  
   The c() is superfluous.
   
+ Why is total_CPUE defined and not computed?
  + In fact, where is it used?
  
  
+ Conditionally print information at each iteration.
   + Instead of print(x), use if(verbose) print(x).  Add verbose as a parameter for the function
     to allow the caller control this.
   + Or every n-th value:  if(verbose && x %% 10 == 0) print(x)

+ Why pmax() when called with scalars?

+ Calculating `deeper-shallower + 1` three times.

+ calling rbind each iteration.
   + Use do.call(rbind, results)
   + Use lapply() rather than for(x in 1:nrow(catch))
   
+ 1:nrow(catch) - what if catch has no rows?

+ In the call to data.frame() in the loop, again several unnecessary calls to c().


+ ** Note that we loop over each value of catch
