library(ROC)
source('funs.R')
blosum62 = read.table("blosum62.txt", header=TRUE)
aa.all = rownames(blosum62)

pos.location = "positiveinput.txt"
positive.whole = readLines(pos.location)
positive.whole = positive.whole[-which(positive.whole == "")]
positive.whole = positive.whole[lapply(positive.whole,length)>0]
positive = as.data.frame(matrix(unlist(strsplit(positive.whole, split="")),
                                        nrow = length(positive.whole), ncol = 11, byrow = TRUE))
colnames(positive) = -5:5
positive[positive == "."] = NA


neg.location = "negativeinput.txt"
negative.whole = readLines(neg.location)
negative.whole = negative.whole[-which(negative.whole == "")]
negative.whole = negative.whole[lapply(negative.whole,length)>0]
negative = as.data.frame(matrix(unlist(strsplit(negative.whole, split="")),
                                nrow = length(negative.whole), ncol = 11, byrow = TRUE))
colnames(negative) = -5:5
negative[negative == "."] = NA



#jnscores = jackknife.neg(negative.whole, positive, negative)
#assign("jnscores", jnscores, envir = .GlobalEnv)


PSSM = PSSMtable(positive, negative)
#               assign("PSSM", PSSM, envir = .GlobalEnv)



pscores = score(positive.whole, PSSM = PSSM)
nscores = score(negative.whole, PSSM = PSSM)

jpscores = jackknife(positive.whole, positive, negative)

#jnscores = jackknife.neg(negative.whole, positive, negative)
jnscores = jackknife(negative.whole, positive, negative)

cutoffs = numeric(100)
for(i in 1:100)
     cutoffs[i] = cutoff(jpscores, jnscores)
cutoff.score = mean(cutoffs)


unjacked = rocdemo.sca(c(rep(1, length(pscores)), rep(0, length(nscores))), c(pscores, nscores), dxrule.sca, caseLabel = "Sulfation", markerLabel = "Unjackknifed Scores")
jacked = rocdemo.sca(c(rep(1, length(jpscores)), rep(0, length(jnscores))), c(jpscores, jnscores), dxrule.sca, caseLabel = "Sulfation", markerLabel = "Jackknifed Scores")


plot(unjacked, type = "l", lwd = 2, col = "blue", main = "ROC Curve for Unjackknifed Positive and Negative Sites")
text(.9, 0, labels = paste("ROC Score =", signif(AUC(unjacked), 3)))

plot(jacked, type = "l", lwd = 2, col = "blue", main = "ROC Curve for Jackknifed Positive and Negative Sites")
text(.9, 0, labels = paste("ROC Score =", signif(AUC(jacked), 3)))
