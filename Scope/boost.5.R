boost =
function(data, steps = 5)
{
    model = mpg ~ cyl + wt
    
    ans = vector("list", steps)
    gof = numeric(steps)
    wts = rep(1, nrow(data))
    for(i in 1:steps) {
        ans[[i]] = fit = lm(model, data, weights  = wts)
        res = residuals(fit)
        gof[i] = sum(res^2)
        wts = abs(res)/sum(abs(res))
    }    

    list(fits = ans, gof = gof)
}
