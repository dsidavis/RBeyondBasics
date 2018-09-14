
We have been talking about writing short, flexible, customizable functions.
Short means they are easier to read, understand and maintain.
Flexible and customizable mean that the caller/user can parameterize
the function to make it do things differently. This means adding parameters
to control different aspects of the function.

We are now going to look at a slightly different aspect of this goal of writing
short, customizable functions.
We'll use an example from the Rtesseract package.
This is a package that interfaces to the Optical Character Recognition 
engine tesseract.  The idea is that we have an image, typically a scan
of a typed text, and we use Rtesseract to recover the letters or words
in the text from that image. tesseract is a sophisticated piece of 
software, using neural networks/deep learning to "predict" the text.
Rtesseract interfaces to it.  But that is all we need to know about OCR for this 
discussion.

The primary/workhorse function in Rtesseract GetBoxes().
+ We pass it an image.
+ It performs the OCR.
+ It returns a data frame giving the x, y, width, height, value and confidence of each text element
  (character, word or line) in the image.
  
```
library(Rtesseract)
img = system.file("images", "OCRSample2.png", package = "Rtesseract")
b = GetBoxes(img)
```
Note how we used system.file() to portably find a file within a package
rather than hard-coding the name of the file relative to my particular machine.

We can explore the result with
```
class(b)
[1] "OCRResults" "data.frame"
names(b)
[1] "left"       "bottom"     "right"      "top"        "text"      
[6] "confidence"
```
We'll come back to the fact that the class is an OCRResults and a data.frame.
This is useful.

However, let's focus on GetBoxes().
We said we pass it an image. What is an image?
In fact, we passed it a string (or character vector of length 1).
This is the name of the file containing the contents of an image.

In many cases for OCR, we need to preprocess the image before passing it
to GetBoxes().  We may, for example, need to turn it into a black and white image
by thresholding the colors so that very light colors (yellow) don't get washed out and appear as
empty space. We may need to rotate the image so that it is "straight".
We may want to remove non-text elements, e.g., pictures or lines.
We may want to zoom in to a subregion of the image, i.e., subset the origial image and pass the new
image to GetBoxes(). And so on....

We also may want to specify any of the many, many options/parameters tesseract gives us 
that control how it behaves. 
And we may want to specify these once but reuse them across multiple images.
One way to do this is to create a tesseract engine object once, set these parameters
and then reuse this engine object in each call to GetBoxes().
(Before we call GetBoxes(), we set  the new image in the engine object.)

What this means is that our GetBoxes() function should be able to accept
+ a file name
+ a preprocessed image object
+ a tesseract engine object.

GetBoxes() should also 
+ allow the caller to specify whether to recover letters, words or lines,
+ whether to return the confidence or not
+ whether to return a data.frame or a matrix (with the rownames containing the text)
+ accept any number of the parameters/settings tesseract allows us set.


One approach to making our function sufficiently flexible to handle these different
types of inputs  is to use if-else statements that examine the class/type of the input.
We might start to define GetBoxes() with
```
GetBoxes =
function(obj, level = 3L, keepConfidence = TRUE, asMatrix = FALSE, ...) 
{
   if(inherits(obj, "character"))
     # file name
   else if(inherits(obj, "Pix"))
     # a preprocessed image
   else if(inherits(obj, "TesseractAPI"))
     # tesseract engine object
   else
     stop("Don't understand how to work with a ", class(obj), " object")
   
   ....
}
```

inherits() is a function that checks the class() of an object for being
an instance of a class, e.g., "character"

The level argument controls whether the OCR works at the level of letters, words, lines or blocks/paragraphs.
The 3L seems like a hard-coded constant which is bad.


Inside the bodyu of each if() statement, we can add lots of code to process this type of input.
The result will be GetBoxes becomes a large, complicated function.
Some of the code will be common to, say, 2 of the input types but not the third.
This will mean we want to avoid repeating it so we'll have to have subsequent if() statements
that share code for 2 input types but not the third.

An important aspect of this approach is that only the owner (or a new owner) of the function
can add support for a new type.
We have to add a new 
```
else if(inherits(obj, "NewType")) {
   ...
}
```
clause to the existing function.
If 2 or more people do this, there are 2 different versions of the function,
each containing only one update for one new type.
Alternatively, they have to persuade the original author/owner to incorporate their
changes so that they are merged and synchronized. And this makes for  a lot of testing
and potentially resolving conflicts in the extensions.  We want to avoid
changes to existing code, but extending the functionality externally from the existing code.
This is what object oriented programming allows us to do - reasonably well.


The basic idea is that we put a class label on an object to identify 
it as a character, a Pix or a TesseractAPI object.
There are 3 class mechanisms in R - S3, S4 and reference classes - 
but we'll only focus on the first 2 here.
S3 is very simple. To make an object an instance of a class, 
we use
```
class(myObject) = c("ClassName1", "ClassName2", ...)
```
In other words, we assign a character vector as the class.
This can be a character vector with one element to indicate a single
class, or with multiple elements to indicate the object can be considered
to be from multiple classes. The order matters.  The first element of the
class vector is the primary class, and so on.

Putting an S3 class vector on an object doesn't require that object
have a particular structure. It is just a convention that all instances of that class
have the same structure.  But I can say
```
x = 1
class(x) = "lm"
```

The S4 class mechanism is more formal and structured.
We specify the structure for a class by defining the slots/fields that each instance needs
to contain and also what type of each of these slots must be.
For writing reliable software, S4 is good. S3 is useful  and convenient also.
The modeling software in R is almost all implemented in S3.


Returning to our GetBoxes() function ...
We want to avoid the if-else that implements different code
for different types of inputs.
Instead, we'd like to have different functions for each class of input.
So we could define functions
named, e.g.,  GetBoxes.character, GetBoxes.Pix, GetBoxes.TesseractAPI.
And in fact, this is what we do (when using S3).
But this alone would be annoying/inconvenient for the user.
They have to remember and type the full name of the function,
e.g., GetBoxes.character.  And if an object has two classes,
e.g. OCRResults and data.frame as we saw above, 
should we call plot.OCRResults or plot.data.frame. 

OOP takes care of this for us.  We define a generic function
GetBoxes and tell it to use an appropriate method depending on the
class of the input.
We define this generic function in S3 with
```
GetBoxes =
function(obj, level = 3L, keepConfidence = TRUE, asMatrix = FALSE, ...) 
{
   UseMethod("GetBoxes")
}
```

Then we define GetBoxes.character, GetBoxes.Pix, etc. 
Then GetBoxes will find the appropriate method based on the class of `obj`.

So let's implement GetBoxes.character.
This takes  the file name identifying the image.
We'll use this to create a TesseractAPI object and then call GetBoxes on that.
```
GetBoxes.character =
function(obj, level = 3L, keepConfidence = TRUE, asMatrix = FALSE, ...) 
{
   api = tesseract(obj, ...)
   GetBoxes(api, level, keepConfidence, asMatrix)
}
```
Note that we are calling GetBoxes again, but this time with a TesseractAPI object.
So GetBoxes will inv oke a different method.


Next we implement the GetBoxes.TesseractAPI method.
This takes the tesseract api object and the level and passes these
to C code. Then it takes the results and organizes 
```
GetBoxes.character =
function(obj, level = 3L, keepConfidence = TRUE, asMatrix = FALSE, ...) 
{
    ans = .Call("R_TesseractBaseAPI_getBoundingBoxes", obj, as(level, "PageIteratorLevel"))
    m = do.call(rbind, ans)
    colnames(m) = c("confidence", "left", "bottom", "right", "top") #XXXX
    if(asMatrix) {
        rownames(m) = names(ans)
        cols = 2:5
    } else {
        m = as.data.frame(m)
        m$text = names(ans)
        rownames(m) = NULL
        cols = 2:6
    }

    ans = m[, c(cols, if(keepConfidence) 1)] 
    class(ans) = c("OCRResults", class(ans))
         
    ans
}
```



# Coercion

coercion from array to pix






