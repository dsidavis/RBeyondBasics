# Most Important

1. Implement simple/straightforward, slow  version first.
1. Make certain it is correct
   + Develop tests for the results for different inputs.
1. Then, make faster
   + Test the new implementation with the tests for the original.
   
1. Focus on the code that 
   1. accounts for the most time and 
   1. can be made faster.
   

# Avoid Bad Practices


## Preallocation versus Concatenation



## Avoid redundant computations! (Sounds obvious)
+ Don't recompute things.
  + Compute things once and reuse.
  + If it consumes lots of memory, maybe better to recompute.
     + Trade-off


```
tapply(d, group, function(x) (x - mean(d))/sd(d)
```

```
tapply(d, group, function(x, mu, sd) (x - mu)/sd, mean(d), sd(d))
```
Compute mean and sd of d just once.


Repeating computations.
Compare
```
tapply(d, group, mean)
tapply(d, group, sd)
```
versus
```
tmp = split(d, group)
sapply(tmp, mean)
sapply(tmp, sd)
```
versus
tapply(d, group, function(x) c(mean(x), sd(x)))

Split just once and compute the statistics


	 
## Use Vectorized Functions/Operations
What's the difference between
```
log(x)
```
and
```
sapply(x, log)
```

```
z = rpois(1e6, 3)
system.time(log(z))  # 0.014 seconds
system.time(sapply(z, log)) # 0.358
```
A factor of 25.

For 1e7
```
z = rpois(1e7, 3)
tm1 = system.time(log(z))  # 0.014 seconds
tm2 = system.time(sapply(z, log)) # 0.358
```

Let's do an explicit loop
```
system.time({ for(i in z)  log(i) }) # no assignment
system.time({ ans = numeric(length(z)) ; for(i in z)  ans[i] = log(i) })
```

Let's compare them all for various vector lengths:
```
N = 10^(2:7)
tms = lapply(N, function(n) {
                    print(n)
	                z = rpois(n, 3)
					list(log = system.time(log(z)),
  					     vapply = system.time(vapply(z, log, 0.0)),
						 loop = system.time({ ans = numeric(length(z)) ; for(i in z)  ans[i] = log(i) }))
						 
   			    })
```

```
tm = sapply(tms, function(x) sapply(x, `[`,3))
colnames(tm) = N
rownames(tm) = gsub(".elapsed", "", rownames(tm))
matplot(N, t(tm), type = "b")
```


What is going on here?


Matters gets more complicated to analyze with byte-code compilation.
The byte-code compilation may not occur until after a few calls to a
function or a few iterations of a loop.






# URLs
+ https://csgillespie.github.io/efficientR/programming.html
