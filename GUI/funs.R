PSSMtable = function(pos, neg, allaa = aa.all, mut.matrix = blosum62, pos.weights = NULL, neg.weights = NULL, position.weights = NULL, N = 5) {
     # pos = matrix of positive sequences splitted by individual amino acids.  Each
     #       row corresponds to a sequence.  Each column corresponds to its position.
     # neg = similar to pos
     # allaa = vector of all the of the amino acids
     # blosum = matrix of amino acid mutational rates.  Row and column names should
     #         correspond to the amino acid.
     # pos.weights = vector of weights to put on the positive sequences
     # neg.weights = similar to pos.weights

     PSSM = matrix(nrow=20,ncol=11)
     rownames(PSSM) = allaa
     colnames(PSSM) = -5:5

     for(i in 1:20) {
       for(j in -5:5) {
         PSSM[i,(j+6)] = PSSMentry(allaa[i], as.character(j), pos, neg, mut.matrix, allaa, pos.weights, neg.weights, pos.weights, N)
       }
     }

     PSSM[,6] = numeric(20)
     rownames(PSSM) = allaa
     colnames(PSSM) = -5:5

     return(PSSM)
}


PSSMentry = function(aa, p, pos, neg, mut.matrix = blosum62, allaa = aa.all, pos.weights = NULL, neg.weights = NULL, position.weights = NULL, N = 5) {
     # aa = amino acid: capital character
     # p = position number
     # pos = matrix of positive sequences splitted by individual amino acids.  Each
     #       row corresponds to a sequence.  Each column corresponds to its position.
     # neg = similar to pos
     # mut.matrix = matrix of amino acid mutational rates.  Row and column names should
     #         correspond to the amino acid.
     # pos.weights = vector of weights to put on the positive sequences
     # neg.weights = similar to pos.weights

     pp = list()
     nn = list()
     p = as.character(p)

     if(is.null(pos.weights)) pos.weights = rep(1, dim(pos)[1])
     if(is.null(neg.weights)) neg.weights = rep(1, dim(neg)[1])
     if(is.null(position.weights)) position.weights = rep(1, dim(pos)[2])
     names(position.weights) = -5:5

     # positive portion, i.e. numerator, of Henikoff's eqn
     pp$counts = sapply(1:length(allaa), function(i) sum(pos.weights[which(pos[,p] == allaa[i])], na.rm = TRUE))
     pp$counts = position.weights[p]*pp$counts
     names(pp$counts) = allaa

     pp$total.aa = sum(pp$counts) # total number of aa in the position
     pp$unique.aa = length(levels(factor(pos[,p]))) # total number of unique aa in position

     pp$p.obs = pp$counts / pp$total.aa # probability of seeing aa in position
     names(pp$p.obs) = allaa


     pp$w.obs = ( pp$total.aa ) / ( pp$total.aa + N * pp$unique.aa )
     pp$w.pseudo = ( N * pp$unique.aa ) / ( pp$total.aa + N * pp$unique.aa )
     pp$mutation = sum(sapply(aa.all, function(i) ( mut.matrix[aa,i] /
       sum(mut.matrix[i,]) ) * pp$p.obs[i]), na.rm=TRUE)

     numerator = pp$w.obs * pp$p.obs[aa] + pp$w.pseudo * pp$mutation

     # negative portion, i.e. denominator, of Henikoff's eqn
     nn$counts = sapply(1:length(allaa), function(i) sum(neg.weights[which(neg[,p] == allaa[i])], na.rm = TRUE))
     nn$counts = position.weights[p]*nn$counts
     names(nn$counts) = allaa

     nn$total.aa = sum(nn$counts) # total number of aa in the position
     nn$unique.aa = length(levels(factor(neg[,p]))) # total number of unique aa in position

     nn$p.obs = nn$counts / nn$total.aa # probability of seeing aa in position
     names(nn$p.obs) = allaa


     nn$w.obs = ( nn$total.aa ) / ( nn$total.aa + N * nn$unique.aa )
     nn$w.pseudo = ( 5 * nn$unique.aa ) / ( nn$total.aa + N * nn$unique.aa )
     nn$mutation = sum(sapply(aa.all, function(i) ( mut.matrix[aa,i] /
       sum(mut.matrix[i,]) ) * nn$p.obs[i]), na.rm=TRUE)

     denominator = nn$w.obs * nn$p.obs[aa] + nn$w.pseudo * nn$mutation

     # the PSSM entry score
     return(log(numerator/denominator)/log(2))
}



score = function(aaseq, PSSM = NULL, pos = NULL, neg = NULL, allaa = aa.all, mut.matrix = blosum62, pos.weights = NULL, neg.weights = NULL, position.weights = NULL, N = 5) {
     # aaseq = amino acid sequence with 5 aa on each side of tyrosine to score
     # PSSM = PSSM table, if already calculated
     # pos = if PSSM is not specified, then provide a matrix of positive sequences
     #       splitted by individual amino acids.  Each row corresponds to a sequence.
     #       Each column corresponds to its position.
     # allaa = vector of all the of the amino acids

     aaseq = strsplit(as.character(aaseq), split='')
     aaseq = lapply(aaseq, toupper)
     for(i in 1:length(aaseq)) aaseq[[i]][aaseq[[i]] == "."] = NA
     for(i in 1:length(aaseq)) aaseq[[i]] = aaseq[[i]][aaseq[[i]] %in% c(allaa, NA)]

     if(length(aaseq) != 1 & is.null(PSSM)) {
          PSSM = PSSMtable(pos, neg, allaa, mut.matrix, pos.weights, neg.weights, N)
     }

     if(length(aaseq) == 1) {
          sum.score = sum(sapply(-5:5, function(i) PSSMentry(unlist(aaseq)[i+6], as.character(i), pos, neg, mut.matrix, allaa, pos.weights, neg.weights, position.weights, N)), na.rm = TRUE)
     } else {
          sum.score = numeric(length(aaseq))
          for(j in 1:length(aaseq)) {
               for(i in -5:5) {
                    if(is.na(aaseq[[j]][(i+6)])) {} else {
                         score = PSSM[aaseq[[j]][(i+6)], as.character(i)]
                         sum.score[j] = sum(sum.score[j], score)
                    }
               }
          }
     }


     return(sum.score)
}

jackknife = function(pos.whole, pos, neg, allaa = aa.all, mut.matrix = blosum62, pos.weights = NULL, neg.weights = NULL, position.weights = NULL, N = 5) {
     # pos.whole = vector of positive sequences
     # pos = matrix of positive sequences splitted by individual amino acids.  Each
     #       row corresponds to a sequence.  Each column corresponds to its position.
     # neg = similar to pos

     j.scores = numeric(length(pos.whole))

     for(i in 1:dim(pos)[1]) {
       holdout = pos.whole[i] # sequence holding out
       pos.new = pos[-i,] # sequences without the holdout to calculate new PSSM

       j.scores[i] = score(holdout, pos = pos.new, neg = neg, allaa = aa.all, mut.matrix = mut.matrix, pos.weights = pos.weights, neg.weights = neg.weights, position.weights = position.weights, N = 5) # scores holdout with the new PSSM
     }

     return(j.scores)
}

jackknife.neg = function(neg.whole, pos, neg, allaa = aa.all, mut.matrix = blosum62, pos.weights = NULL, neg.weights = NULL, position.weights = NULL, N = 5) {
     # neg.whole = vector of negative sequences
     # pos = matrix of positive sequences splitted by individual amino acids.  Each
     #       row corresponds to a sequence.  Each column corresponds to its position.
     # neg = similar to pos

     j.scores = numeric(length(neg.whole))

     for(i in 1:dim(neg)[1]) {
       holdout = neg.whole[i] # sequence holding out
       neg.new = neg[-i,] # sequences without the holdout to calculate new PSSM

       j.scores[i] = score(holdout, pos = pos, neg = neg.new, allaa = aa.all, mut.matrix = mut.matrix, pos.weights = pos.weights, neg.weights = neg.weights, position.weights = position.weights, N = 5) # scores holdout with the new PSSM
     }

     return(j.scores)
}

cutoff = function(jpscores, jnscores, min = -10, max = 10) {
     # This function tries to find the cutoff which will equilibrate the number
     # of false positives and false negatives.
     #
     # jpscores = jackknifed positives sequences
     # jnscores = jackknifed negative sequences

     # initializing the parameters
     cutoff = 0
     min = min
     max = max
     i = 1
     fn = 1 # false negatives
     fp = 0 # false positives

     while(fn != fp) {
          fn = sum(jpscores < cutoff[i])
          fp = sum(jnscores >= cutoff[i])
          if(fn < fp) {
               min = cutoff[i]
               cutoff[i+1] = runif(1, min, max)
          } else if(fn > fp) {
               max = cutoff[i]
               cutoff[i+1] = runif(1, min, max)
          } else {
               cutoff[i+1] = cutoff[i]
          }
          i = i + 1
     }

     return(cutoff[length(cutoff)])
}


