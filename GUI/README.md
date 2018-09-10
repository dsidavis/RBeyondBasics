This example comes fro a Graphical User Interface written 10 years
ago but being used this summer.  This shows how code persists
longer than we anticipate and how other code we use also evolves and changes
the behavior of our code. 
Importantly, this example illustrates the benefits of 
+ separating code into smaller functions so that it can be used in different
  ways and from different starting points, i.e. tested separately from the GUI
+ avoiding repeating the same code in very similar functions.
+ debugging
+ writing code defensively.




## Separating the Code

There is one very large function - PSSMcreator.open.


How can we quickly examine the code?  Use parse (rather than source()
as we don't want to evaluate/run the code).
Then we can query the language objects:
```
e = parse("PSSMcreator.r")
sapply(e, class)
sapply(e, `[[`, 2)

sapply(e, function(x) class(x[[3]]))
sapply(e, function(x) x[[3]][[1]])
```





## Debugging
We now have a non-GUI based version of the code that replicates what is 
expected to happen within the GUI. This allows us to test the code
without the GUI, making it faster (in human time) to test and 
programmatic and hence reproducible. 
So let's run the code as it stands at this point:
```
source("flow.R", echo = TRUE)
```

We get an error.
```
NA in cutpts forces recomputation using smallest gap
NA in cutpts forces recomputation using smallest gap
Error in plot.default(x, y, type = "l", ...) : 
  formal argument "type" matched by multiple actual arguments
```
The messages about the "NA in cutpts" should concern us and 
we should perhaps resolve these first as these may be causing the error.
Rather than assuming, instead, we can explore the error directly to see if this is the case.
We can can call traceback or arrange to enter the debugger
whenever an error occurs with
```
options(error = recover)
```

Using recover() or traceback(), we get
```
traceback()
9: plot(x, y, type = "l", ...)
8: plot(x, y, type = "l", ...)
7: .local(x, y, ...)
6: plot(unjacked, type = "l", lwd = 2, col = "blue", main = "ROC Curve for Unjackknifed Positive and Negative Sites")
5: plot(unjacked, type = "l", lwd = 2, col = "blue", main = "ROC Curve for Unjackknifed Positive and Negative Sites") at flow.R#54
4: eval(ei, envir)
3: eval(ei, envir)
2: withVisible(eval(ei, envir))
1: source("flow.R")
```
This is a call stack. It shows which functions were called and in which order.
We started with the call to source().
This called withVisible(eval()). There were two calls to eval. (Why 2?).
Now we get to our code in flow.R, i.e. the call to plot().
We see 2 calls to plot(), then .local() and then two more calls to plot().



```
selectMethod("plot", "rocc")
```

```
showMethods("plot")
```

