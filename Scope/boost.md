

This is a discussion of non-standard evaluation and "scope" related to formulae.
We'll discuss in the relation to linear models and to boosting, but don't worry about 
the statistical concepts.

The idea behind boosting is that we have a model and some data.
We will fit a sequence of models - an ensemble. Our overall model is
predicts the value of a new observation using the entire sequence of models,
weighting the predictions from each of the models in the sequence.

More specifically,
+ We fit the model to the data. 
+ Then we look at the residuals.
+ We increase the weight of the observations with the larger residuals and decrease the weights for
those observations that were fit well by the current model.
+ We then refit the model using these modified weights with the idea that it will fit those
previously hard-to-fit observations better.
+ Each iteration results in a new fitted model, and a measure of how good the overall fit is.
+ Then we combine the prediuctions from each model and weight by the relative accuracy of that model.

The lm() function takes a vector of weights indicating the relative accuracy of each observation.
The higher the weight, the more accurate it is.

```
data(mtcars)
```

We'll perform the first two iterations manually to ensure we have the correct idea.
We start with equal weights:
```
wts = rep(1, nrow(mtcars))
```
Now we fit our model
```
f1 = lm(mpg ~ cyl + wt, mtcars, weights = wts)
```

The first residual is 
```
residuals(f1)[1]
```
```
Mazda RX4 
-1.279145 
```

Now, we'll change the weights using a very simple (and inappropriate) formula:
```
wts = abs(residuals(f1))/sum(abs(residuals(f1)))
```
(The lm() function would normalize the weights for us, but we can do it ourselves.)

Now we refit the model to get f2
```
f2 = lm(mpg ~ cyl + wt, mtcars, weights = wts)
```
Again, let's look at the first residual but under 
```
residuals(f2)[1]
```
```
Mazda RX4 
-2.220263 
```
As we planned, the residuals are different
and we can see this for all of them with
```
plot(residuals(f1), residuals(f2))
```


We would repeat this for S iterations/steps.
So let's put this into a function.
See [boost.R](boost.R).
```
boost =
function(model, data, steps = 5)
{
    ans = vector("list", steps)
    gof = numeric(steps)
    wts = rep(1, nrow(data))
    for(i in 1:steps) {
        ans[[i]] = fit = lm(model, data, weights  = wts)
        res = residuals(fit)
        wts = abs(res)/sum(abs(res))
        gof[i] = sum(res^2)
    }

    list(fits = ans, gof = gof)
}
```
We provide the formula for the model and the data set. The number of  steps defaults to 5.
We preallocate the list() with space for `steps` fits.
We also return the goodness-of-fit for each of the `steps` fits.

Since the i-th fit depends on the weights computed at the previous step, we cannot
use lapply(). Instead, we have to use an explicit loop so that the (i-1)th fit and
residuals can be used in the i-th iteration.


So now we have a reasonable function. There are probably bugs in it, but let's use it:
```
a = boost(mpg ~ cyl + wt, mtcars)
```

How should we look at the result to see if it is correct?


```
a$gof
```
This doesn't look good. Why?  What's wrong? How will we go about finding out what is wrong?

This is a job for debugging (debug() and/or trace())


