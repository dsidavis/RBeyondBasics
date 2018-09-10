+ The calls to library() are inside the function PSSMcreator.open. So they
  won't fail until that function is called.
  
+ We read blosum62.txt regardless of whether the variable blosum62 is already defined.

+ The name of the txt file is hard-coded. We should allow the user/caller specify a different file.
  Instead, we can check if this variable is defined and if not, then read the blosum62.txt file.
  
+ Use of global variables via assign() and .GlobalEnv.

+ Functions (e.g. getposfile) defined inside PSSMcreator.open(), so why not use closures for shared variables
 rather than the global environment?
 
+ We cannot test the functions defined within PSSMcreator.open() separately, i.e,
  idenpendently of PSSMcreator.open. So we have to rerun the entire GUI to test any of these.
  
+ The functions mix the GUI and the data computations.  So we can only run the data computations
  through the GUI. This means they are not reusable.

+ Make the functions take their inputs directly rather than extract the inputs from the GUI.
```
getposfile = function(file) {
	positive.whole = readLines(pos.location)
	positive.whole = positive.whole[-which(positive.whole == "")]
	positive.whole = positive.whole[lapply(positive.whole,length)>0]
	positive = as.data.frame(matrix(unlist(strsplit(positive.whole, split="")),
                              nrow = length(positive.whole), ncol = 11, byrow = TRUE))
    colnames(positive) = -5:5
    positive[positive == "."] = NA

    positive
}
```
We then change the GUI code to 
```
getposfile.gui = function () {
	pos.location = tclvalue(tkgetOpenFile())
	if (pos.location == "") {
          tkmessageBox(message = "No file was selected!")
     } else {
          msg = paste("File for positive sequences: '", pos.location, "' was loaded.\n", sep = "")
          add.messages(msg)
     }
 positive = getposfile(pos.location)
 assign("positive", positive, envir = .GlobalEnv)
```
(Note that this misses assigning positive.whole as the original code does.
This is needed in subsequent computations. So we should have getposfile
return both positive and positive.whole and assign both.)



+ Look at flow.R or PSSMcreator.r.  The code for reading the positive file is repeated
 almost exactly for reading the negative file.
  + See readInput.R
  
  
  + Whenever we see hard-coded numbers, e.g., 11 and -5:5, ask 
     + where do they come from?
     + can we understand them when we read the code? and 
      + don't we need to test the data have that many elements?

  + When copying the code from flow.R into a function, we need to return the value, not the last
    assignment.
	
  + Change `-which(positive.whole  == "")` to `positive.whole  == ""`.

  + lapply to sapply.
     + Not clear what `positive.whole[lapply(positive.whole,length)>0]` is actually doing
	   + Depends on the type of positive.whole.

  + Does `positive[positive == "."] = NA` do what we want?

