Continuing on from boost.md .....


Let's print  the value of weights that are computed in the lm() function.
(See below for how we know where this happens in the lm code.)
These occur in the 14th "line"/expression in the body of the lm() function (including the opening
`{`).  (Use `as.list(body(lm))` to figure out where w is assigned.)
So we'll tell trace to print the value  of the variable named w within the body of the lm()
function just after it is assigned:
```
trace(lm, quote(print(w)), at = 15, print = FALSE)
```
(The `print = FALSE` has nothing to do with the `print(w)` but merely controls
whether print displays a message announcing itself `trace` as being in use.)
Note that we passed `quote(print(w))` as the second argument (corresponding
to the parameter named `tracer`).
We didn't want to print the value of w when we call trace.  Instead
we want to defer the call to print(w)  until lm() is called and to print
the value of w within the call frame of that call to lm().

So now we run our boost function again and trace will arrange to print
the weights.


```
a = boost(mpg ~ cyl + wt, mtcars)
```
```
 [1] 0.020808443 0.007571640 0.056155721 0.016584418 0.033397799
 [6] 0.024380509 0.031430880 0.015033083 0.013071224 0.007524476
[11] 0.030298929 0.028685316 0.025676965 0.005889263 0.007666825
[16] 0.001365347 0.067214640 0.093782873 0.030881156 0.099237276
[21] 0.069776618 0.014505371 0.023797879 0.033682907 0.062554690
[26] 0.002937100 0.013443454 0.025586435 0.027793293 0.034169795
[31] 0.020043653 0.055052020
 [1] 0.020808443 0.007571640 0.056155721 0.016584418 0.033397799
 [6] 0.024380509 0.031430880 0.015033083 0.013071224 0.007524476
[11] 0.030298929 0.028685316 0.025676965 0.005889263 0.007666825
[16] 0.001365347 0.067214640 0.093782873 0.030881156 0.099237276
[21] 0.069776618 0.014505371 0.023797879 0.033682907 0.062554690
[26] 0.002937100 0.013443454 0.025586435 0.027793293 0.034169795
[31] 0.020043653 0.055052020
....
```
The vector of weights are the same for each of the 5 calls!!


Could it be that we have a global variable in our boost() function:
```
codetools::findGlobals(boost, FALSE)
$functions
 [1] ":"         "[[<-"      "[<-"       "{"         "/"        
 [6] "^"         "="         "abs"       "for"       "list"     
[11] "lm"        "nrow"      "numeric"   "rep"       "residuals"
[16] "sum"       "vector"   

$variables
character(0)
```

So let's debug our boost() function and see if they vector `wts`
is changing?  Or alternatively, check if the value we are passing
to lm() via the `weights = wts` element is what we expect it to be, i.e., 
different for each call?

BTW, why didn't we see the vector of 1's the first time around?

```
untrace(lm)
debug(lm)
a = boost(mpg ~ cyl + wt, mtcars)
```
When we stop in lm() each time, we print the value of the `weights`  parameter
(with the simple command `weights`).

In the first call, we get a vector of 1's.
We enter the command 'c' for continue and we stop again in the second call.
Printing the weights we get 
```
          Mazda RX4       Mazda RX4 Wag          Datsun 710 
        0.032360477         0.019353359         0.062475938 
		..............
```
So these are different.
But on subsequent calls, we get the same weights again!

So let's debug boost().
```
undebug(lm)
debug(boost)
a = boost(mpg ~ cyl + wt, mtcars)
```
We step through the code in the function and examine each value of wts as it is created.
Again, we do see the vector of 1's and then the updates and all of these are the same,
i.e. across the different iterations in the loop.
So what is happening?


## Restart R

So things are not working as we anticipated.
One thing to do is restart R with a new empty/clean session and
global environment.
This is like rebooting your printer or your wifi router or cable modem.
It is good to get back to a known starting point with no assumptions.
So let's do that.
This involves ensuring that we don't restore any of the variables in the global environment.
So we can quit R and don't save the session.  Or we can start R with the instruction not
to restore the variables from the .RData.   If you see any variables in the global
environment with `ls()` that you don't create in your ~/.Rprofile, then you didn't restore
a virgin R session.
So I start R from the command line with
```
R --vanilla
```
Then I run ls() and see  no variable names.
So we have a fresh session.


Now we run our call to boost() again:
```
source("../Scope/boost.R")
a = boost(mpg ~ cyl + wt, mtcars)
```
This time, we get an error
```
Error in eval(extras, data, env) : object 'wts' not found

Enter a frame number, or 0 to exit   

1: boost(mpg ~ cyl + wt, mtcars)
2: boost.R#8: lm(model, data, weights = wts)
3: eval(mf, parent.frame())
4: eval(mf, parent.frame())
5: stats::model.frame(formula = model, data = data, weights = wts, d
6: model.frame.default(formula = model, data = data, weights = wts, 
7: eval(extras, data, env)
8: eval(extras, data, env)
```

This is actually a lot better. We don't get the wrong answer
and we get information about where the errror occurred.

Note that I get the call stack (the stack of currently active function calls)
because I always set the R option 
```
options(error = recover)
```

The error message says the variable `wts` was not found.
This is a surprise, but in fact, it subtley points to the explanation of the entire problem.
But we have some sleuthing to do.

If we look at the call stack, reading from top to bottom, we see a call to
boost(), to lm() and two calls to eval() and then a call to stats::model.frame() and so on.
We see `wts` in the call to lm() from the boost() function, and also in the call to
stats::model.frame().

The two calls to eval() indicate Non-Standard Evaluation (NSE).
This is strong evidence that we have to think hard and that this is the likely cause of
the problem.

Since this is probably NSE, let's read the help page for lm().


## RTFM - Read the F.* Manual.
Let's read the help page for lm().
```
 weights: an optional vector of weights to be used in the fitting
          process.  Should be ‘NULL’ or a numeric vector.  If non-NULL,
          weighted least squares is used with weights ‘weights’ (that
          is, minimizing ‘sum(w*e^2)’); otherwise ordinary least
          squares is used.  See also ‘Details’,
```
So this doesn't suggest much, except the "See also Details".

```
Non-NULL weights can be used to indicate that different observations have different variances 
(with the values in weights being inversely proportional to the variances); or equivalently, 
when the elements of weights are positive integers wi, that each response yi is the mean of 
wi unit-weight observations (including the case that there are wi observations equal to yi and 
the data have been summarized). However, in the latter case, notice that within-group variation is
not used. Therefore, the sigma estimate and residual degrees of freedom may be suboptimal; in the 
case of replication weights, even wrong. Hence, standard errors and analysis of variance tables 
should be treated with care.
```

We might think we are done, but the very last sentence in the Details section
reads:
```
All of weights, subset and offset are evaluated in the same way as variables in formula, that is first in data and then in the environment of formula.
```

What this means is that the lm() function evaluates the R expression given for the weights
parameter in a call to lm() by evaluating that expression relative to a) the data frame given by
data, and then by looking in the environment where the formula was defined.
Our R expression for the weights parameter is simply `wts`.
We know that mtcars doesn't have  a variable named `wts`.  It does, coincidentally
and possibly confusingly, have a variable named wt, but that is entirely different!
So we won't find `wts` in the data.frame given by the `data` variable.

What about the formula and its environment?
Let's explore that.
We provide the formula `mpg ~ cyl + wt` in the call to boost.
Let's do this separately, in 2 steps by assigning the formula to a variable, say `f`,
```
f = mpg ~ cyl + wt
```
and then passing that to `boost()`.
Having defined `f`, we can query the environment of the formula with
```
environment(f)
```
This shows
```
<environment: R_GlobalEnv>
```
This is our workspace, the global environment on our search path.

If we think about what happened, we had a variable named `wts` defined
in our global environment before we restarted R.
This was from our initial, manual computations to do the first two iterations
of the boosting algorithm.  
When we restarted R, this variable was no longer present.
Then we got an error saying the computations (some part of it) couldn't find `wts`.
This "suggests" that when the boost() function didn't give an error but gave
identical results for all 5 iterations, it was finding and using the same
value for `wts` and this was coming from the global environment.
And in fact, that is what was happening.

How could we have determined this earlier?
One thing was to look at the value of `w` in each call to lm()
(as printed by our call to trace())
and compare the values with those in the global variable `wts`.
But this is a post-hoc approach where we already know the explanation.


# Changing the Environment of the Model Formula

Since lm() looks for `wts` in the environment of the formula,
perhaps we can change the environment of the formula.
One way to do this is to create the formula inside the function
See [boost.5.R](boost.5.R).
The key change is at the start of the file:
```
boost =
function(data, steps = 5)
{
    model = mpg ~ cyl + wt
  ....
```

So now we run our boost() function:
```
source("boost.5.R")
a = boost(mpg ~ cyl + wt, mtcars)
Error in vector("list", steps) : invalid 'length' argument

Enter a frame number, or 0 to exit   

1: boost(mpg ~ cyl + wt, mtcars)
```
So this is bad news!

Oh, it is because we just cut-and-pasted the original call
that contains the formula. So the value for the steps parameter
is now mtcars since we removed the first parameter.

```
a = boost(mtcars)
```
This seems to run.
Let's check the results are reasonable.
Again we check the values of the goodness of fit statistics
```
a$gof
[1] 191.1720 211.6150 191.1721 211.6005 191.1723
```
These are different.  So this suggests things may be working.
However, to determine they are working correctly, we have to compare the results
more carefully with what we would get if we did this manually. We need to convince
ourselves things are working or that we understand how they are working and it is correct.

# Formula Outside of the Function

Defining the formula inside the boost() function is not a good approach.
This has hard coded the formula and makes the boost function quite limited - only
able to deal with this formula. If we wanted to do this for different models,
e.g., `mpg ~ cyl` and `mpg ~ cyl^2 + log(wt)`, we need different functions.
However, if we define the formula in the global environment, the boost() and lm()
functions will look for the weights in that environment.

One approach we can use is to set the environment of the formula to the empty environment:
```
source("../Scope/boost.R")
f = mpg ~ cyl + wt
environment(f) = emptyenv()
boost(f, mtcars)
```
But this fails more spectacularly with the error
```
Error in list(mpg, cyl, wt) : could not find function "list"
```
We cannot find the list() function.


Perhaps we might use a different environment, e.g., the base environment 
which does contain the function list():
```
f = mpg ~ cyl + wt
environment(f) = asNamespace("base")
boost(f, mtcars)
```
This gives the original error message from earlier about not finding `wts`:
```
Error in eval(extras, data, env) : object 'wts' not found
```


So this not working.
One bad approach is to create a new environment and use that for the formula.
Then we put assign the value of `wts` to that environment in each iteration of 
our boost() function. This will work, but is not ideal.

Instead, we'll assign our vector of weights in each iteration as a column
in our data frame being used in the call to lm().
We do this in our new boost() function in [boost1.R](boost1.R)
```
boost =
function(model, data, steps = 5)
{
    ans = vector("list", steps)
    gof = numeric(steps)    
    wts = rep(1, nrow(data))
    data$wts = wts
    for(i in 1:steps) {
        ans[[i]] = fit = lm(model, data, weights = wts)
        res = residuals(fit)
        gof[i] = sum(res^2)        
        data$wts = wts = abs(res)/sum(abs(res))
    }

    list(fits = ans, gof = gof)
}
```

Now we run this as before
```
source("boost1.R")
a = boost(mpg ~ cyl + wt, mtcars)
```


# Why Does lm() Work This Way?

Why does lm() evaluate the expression for weights by looking
in the data frame and then the environment of the formula?

First, consider the commands
```
logWeight = log(mtcars$weight)
mpg ~ cyl + logWeight
```
We first create a new variable for logWeight but keep it outside of the data frame.
Then we refer to that in our formula.
How would lm() fund logWeight since it is not in the data frame.
To be "sane", lm() needs to know where to look for these external terms mentioned
in the formula. So it uses the environment of the formula.
This is a very good computational model.
It also allows us to omit the data frame all together and specify the
formula using variables that are not arranged together in a data frame
but as free standing R variables.
And not only that, it allows us to find those variables where they "should" be
found, regardless of whether that is in the global environment
or within a function call in which the formula was defined.


However, for computing the weights, one could argue lm() should use standard
evaluation and hence just the regular value that it is given via the `weights` parameter.
However, lm() also has a subset() parameter. This allows the caller to filter/subset
the specified data frame.  When subset is specified, lm() first
filters the data frame. It also filters the weights using the same logical condition.
This allows the weights to be defined relative to the original data frame.
This is a design decision and is justifiable, although it does potentially lead to some confusion
and perhaps wrong answers.  This is NSE!



