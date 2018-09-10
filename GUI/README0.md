Look at the code in PSSMcreator.r
How can we improve it?


+ choose.files() - not portable.
+ Global variables when we source this, i.e. blosum62, aa.all.
+ Use of require(), but no check on the result.
+ assign to global variable - but within a locally scoped function.
+ getposfile and getnegfile are almost identical, but with a change of variable name
  + There is a bug in both, so needs to get fixed in both.
+ assigns to global environment and variables.
+ Separate GUI and functions that do the work so that the functions can be called in a script.
+ is.null(positive) | is.null(negative) - probably better to use ||


+ Most importantly
```
positive.whole = positive.whole[-which(positive.whole == "")]
```
We have ^M (linefeed, newline on Windows).  These give rise to "" elements.
So the code discards those. However, if these are not there, 
we don't necessarily have any "" elements.

Having removed the ^M, let's read the new file
```
a = readLines("positiveinput2.txt")
```
Then 
```
table(a == "")
```
consists of all `FALSE` value.

So `which(a == "")` returns an empty integer vector.
And when we subset with this empty integer
```
 a[ - which( a == "") ]
```
we get an empty character vector!

We want
```
a[ a != "" ]
```

Subsetting by integer and logicals are different.






## Separate the GUI and the Computations
We start with
```
getposfile = function () {
	pos.location = tclvalue(tkgetOpenFile())
	if (pos.location == "") {
          tkmessageBox(message = "No file was selected!")
     } else {
          msg = paste("File for positive sequences: '", pos.location, "' was loaded.\n", sep = "")
          add.messages(msg)
     }

	
	positive.whole = readLines(pos.location)
	positive.whole = positive.whole[-which(positive.whole == "")]
	positive.whole = positive.whole[lapply(positive.whole,length)>0]
	positive = as.data.frame(matrix(unlist(strsplit(positive.whole, split="")),
                              nrow = length(positive.whole), ncol = 11, byrow = TRUE))
  colnames(positive) = -5:5
  positive[positive == "."] = NA

    assign("positive.whole", positive.whole, envir = .GlobalEnv)
	assign("positive", positive, envir = .GlobalEnv)
	assign("PSSM", NULL,  envir = .GlobalEnv)
	assign("pscores", NULL,  envir = .GlobalEnv)
	assign("nscores", NULL,  envir = .GlobalEnv)
	assign("jpscores", NULL,  envir = .GlobalEnv)
	assign("jnscores", NULL,  envir = .GlobalEnv)
	assign("cutoff.score", NULL,  envir = .GlobalEnv)
	assign("unjacked", NULL,  envir = .GlobalEnv)
	assign("jacked", NULL,  envir = .GlobalEnv)
}
```

At the very least, let's allow the caller to specify the name of a file.
If they don't we can open a file selection dialog.
We can do this with 
```
getposfile = function (pos.location = tclvalue(tkgetOpenFile())) 
{
	if (pos.location == "") {
          tkmessageBox(message = "No file was selected!")
     } else {
          msg = paste("File for positive sequences: '", pos.location, "' was loaded.\n", sep = "")
          add.messages(msg)
     }
}
```
Now we can call this with
```
pos = getposfile("positiveinput.txt")
```


Note that our if-else statement assumes a GUI and that we can display the message
with tkmessageBox.
We'd be better using the regular message() function, in the code so that it can run in regular
R, but then redefining message in our our GUI.

Even better would be to use stop() and message() in our non-GUI computations
and then to catch these in our GUI to call tkmessageBox() and add.messages().


## Global Assignments

The function creates numerous variables in the global environment, e.g., positive.whole,
positive, PSSM, ...

Firstly, what if we want to assign these to a different environment?
We should allow the caller to specify the environment:
```
getposfile = function (pos.location = tclvalue(tkgetOpenFile()), env = .GlobalEnv) 
{
   assign("positive.whole", positive.whole, envir = env)
   assign("positive", positive, envir = env)
}
```
So this is now a parameter and the caller can change where the values are assigned.


Since this function is defined within PSSMcreator.open(), we can actually use closures
```
PSSMcreator.open =
function() 
{
  positive.whole = NULL
  positive = NULL
  
  
  
  getposfile = function() {
     
	  positive.whole <<- readLines(pos.location)
	   ..
	  positive <<- as.data.frame(....)
  
  }

}
```


However, this still "traps" the function inside the PSSMcreator.open() function.
We cannot use or test it outside of PSSMcreator.open().
This slows many things down. We have to build PSSMcreator.open() and the GUI first.
We have to run it each time to get to the point we call getposfile().
Repeating this many times in the development cycle is tedious and wastes time.
