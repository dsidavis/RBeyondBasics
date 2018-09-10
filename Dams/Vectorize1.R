finalinflowprep=function(month,Q){ #converts from cfs to taf
  monthlyQ=ifelse(month == "January"|| month=="March"|| month=="June"|| month=="July"||month=="August"||month=="October"||month=="December", 
                  Q*1.98*31, #Q*cfs to af* day number in month
                  ifelse(month=="February", 
                         Q*1.98*28,
                         #as.numeric(Lookupy[which(Lookupy[,1]==month),3])*1.98*28,
                         Q*1.98*30))
  return(monthlyQ)
}
finalinflow=Vectorize(finalinflowprep)
