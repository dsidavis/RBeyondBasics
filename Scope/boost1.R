boost =
function(model, data, steps = 5)
{
    ans = vector("list", steps)
    gof = numeric(steps)    
    wts = rep(1, nrow(data))
    data$wts = wts
    for(i in 1:steps) {
        ans[[i]] = fit = lm(model, data, weights  = wts)
        res = residuals(fit)
        gof[i] = sum(res^2)        
        data$wts = wts = abs(res)/sum(abs(res))
    }

    list(fits = ans, gof = gof)
}
