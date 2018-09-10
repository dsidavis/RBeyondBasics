
```
sp = read.csv("../../data/BothSpecies.csv", stringsAsFactors = FALSE)
e = read.csv("../../data/effort.csv", stringsAsFactors = FALSE)
```

# return after the loop.

+ tidy1.R - added verbose = FALSE to suppress print(x) in each iteration of the loop.

+ tidy2.R - avoid call to rbind() in each iteration, but defer to the end after the loop.
We collect all of the individual data frames into a list and then combine them in one step.
This avoids the concatenation that is so  bad in any language.

```
source("tidy1.R")
system.time(replicate(100, {a = tidy(sp, e)}))
source("tidy2.R")
system.time(replicate(100, {a = tidy(sp, e)}))
```
1.553/1.088 = 1.43 - 43% longer.
These are for small sp and e.

So let's create a larger data set. We basically repeat the original 
sp 100 times so that it contains 100 times the original number of rows.

```
sp.big = do.call(rbind, replicate(100, sp , simplify = FALSE))
library(microbenchmark)
source("tidy1.R")
tm1 = microbenchmark(tidy(sp.big, e), times = 50)
source("tidy2.R")
tm2 = microbenchmark(tidy(sp.big, e), times = 50)
median(tm1[,2])/median(tm2[,2])
```
177.197/69.445 - 2.65
So for larger data, we get a speedup factor of over 2.5.



We'll now replace the for loop and filling in the elements of the preallocated
list with a single call to lapply(). This is slightly simpler code.
```
source("tidy3.R")
tm3 = microbenchmark(tidy(sp.big, e), times = 50)
median(tm2[,2])/median(tm3[,2])
```
There results is about the same time as tm2. (Sometimes shorter, sometimes longer.)
So there is no real difference between the lapply() and the for loop().


Let's compute the number of rows in the data frame for each iteration just once `(deeper -
shallower + 1)` and let's also remove the pmax and pmin. Since there are only 2 numbers,
we can just sort these and we have the min and max.
```
source("tidy4.R")
tm4 = microbenchmark(tidy(sp.big, e), times = 50)
median(tm2[,2])/median(tm4[,2])
```
Again, there isn't much difference, perhaps even a slight slow down.


We can also avoid calling `substr` in each iteration by vectorizing the call outside of the loop.
```
source("tidy5.R")
tm5 = microbenchmark(tidy(sp.big, e), times = 50)
median(tm2[,2])/median(tm5[,2])
```




## Proper Vectorization
By looking at the code, we see that the loop  iterates
over each row in the data frame `catch`.
In each iteration, the code computes the difference between the min and the max for start and depth.
Originally, I thought this difference alone determines the number and content of the rows.
If this had been the case, we could have computed the difference between start and end and then for
each unique value, generated the rows "in bulk".
However, the computation involves repeating the siteName and the catch$size value for each row
based on the difference between the end and start depth.
So a vectorized way to do this is 

```
source("tidy6.R")
tm6 = microbenchmark(tidy(sp.big, e), times = 50)
median(tm2[,2])/median(tm6[,2])
median(tm1[,2])/median(tm6[,2])
```
So the speedup over the initial code is a factor of between 1100 and 1200.

## Check the Results
Before we declare a speedup, we need to check the results are the same as
the original function.

```
b = tidy(sp.big, e)
source("tidy1.R")
a = tidy(sp.big, e)
identical(a, b)
```
These are not the same!
So we have to determine how they differ?

```
all.equal(a, b)
```
```
[1] "Component “site”: Attributes: < Component “levels”: 6 string mismatches >"
```

So it seems that only the site column is different.
Let's first check whether they are both data frames and have the same dimensions:
```
c(class(a), class(b))
all.equal(dim(a), dim(b))
```

Let's compare each column:
```
mapply(all.equal, a, b)
```
```
                                                     site 
"Attributes: < Component “levels”: 6 string mismatches >" 
                                                     size 
                                                   "TRUE" 
                                                    depth 
                                                   "TRUE" 
                                                    catch 
                                                   "TRUE" 
```

```
c(class(a$site), class(b$site))
```
These are both factors.

The issue is that we have created the two factors in quite different ways
and order so the levels for the two are different.
So let's compare the levels:
```
all.equal(sort(levels(a$site)), sort(levels(a$site)))
```

Now compare the counts for each level:
```
tt1 = table(a$site)
tt2 = table(b$site)
tt1 == tt2[names(tt1)]
```
So these are the same.


So now that we know we have the same result, let's
compare the times.
Comparing medians, we get
```
median(tm1$time)/median(tm6$time)
```
and a factor of 1214!

Comparing the distributions of times for the two measures

```
tm = rbind(tm1, tm6)
tm$version = factor(rep(c(1, 6), each = nrow(tm1)))
library(ggplot2)
ggplot(tm) + geom_density(aes(time, group = version, colour = version))
```


Comparing the distributions for all versions:
```
tm = rbind(tm1, tm2, tm3, tm4, tm5, tm6)
tm$version = factor(rep(1:6, each = nrow(tm1)))
library(ggplot2)
ggplot(tm) + geom_density(aes(time, group = version, colour = version))
```


Basically, we have a huge win here, at least for large datasets.

We didn't complete the entire function. Recall we returned the
result after the loop.
