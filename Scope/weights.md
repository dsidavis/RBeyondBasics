
data(mtcars)

wts = rep(1, nrow(mtcars))
f1 = lm(mpg ~ cyl + wt, mtcars, weights = wts)


wts2 = 1:nrow(mtcars)
f2 = lm(mpg ~ cyl + wt, mtcars, weights = wts2)


mtcars$weights = wts

