readInput =
function(pos.location = "positiveinput.txt",
         positive.whole = readLines(pos.location))    
{
    positive.whole = positive.whole[ positive.whole != "" ]
    positive.whole = positive.whole[sapply(positive.whole, length) > 0]

    if(!all(nchar(positive.whole) == 11))
        stop("some values in ", pos.location, " do not have 11 characters")

    positive = as.data.frame(matrix(unlist(strsplit(positive.whole, split="")),
                                    nrow = length(positive.whole), ncol = 11, byrow = TRUE))
    colnames(positive) = -5:5
    positive[positive == "."] = NA
    positive
}

