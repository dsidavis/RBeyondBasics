
doTTests =
function(x)
  sapply(x[seq(1, ncol(x) - 1, by = 2)],
         function(col)
             tryCatch(t.test(col, mu = .5)$p.value, error = function(...) NA))
