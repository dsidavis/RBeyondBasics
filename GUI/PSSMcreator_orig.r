blosum62 = read.table(choose.files(), header=TRUE)
aa.all = rownames(blosum62)


PSSMcreator.open = function () {

require(tcltk)
require(tcltk2)
require(ROC)

assign("positive.whole", NULL, envir = .GlobalEnv)
assign("positive", NULL, envir = .GlobalEnv)
assign("negative.whole", NULL, envir = .GlobalEnv)
assign("negative", NULL, envir = .GlobalEnv)
assign("PSSM", NULL,  envir = .GlobalEnv)
assign("pscores", NULL,  envir = .GlobalEnv)
assign("nscores", NULL,  envir = .GlobalEnv)
assign("jpscores", NULL,  envir = .GlobalEnv)
assign("jnscores", NULL,  envir = .GlobalEnv)
assign("cutoff.score", NULL,  envir = .GlobalEnv)
assign("unjacked", NULL,  envir = .GlobalEnv)
assign("jacked", NULL,  envir = .GlobalEnv)



####################
#### FUNCTIONS #####
####################

# Input positive sequences
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

# Input negative sequences
getnegfile = function () {
     neg.location = tclvalue(tkgetOpenFile())
	if (neg.location == "") {
          tkmessageBox(message = "No file was selected!")
     } else {
          msg = paste("File for negative sequences: '", neg.location, "' was loaded.\n", sep = "")
          add.messages(msg)
     }

	negative.whole = readLines(neg.location)
	negative.whole = negative.whole[-which(negative.whole == "")]
	negative.whole = negative.whole[lapply(negative.whole,length)>0]
  	negative = as.data.frame(matrix(unlist(strsplit(negative.whole, split="")),
                              nrow = length(negative.whole), ncol = 11, byrow = TRUE))
  colnames(negative) = -5:5
  negative[negative == "."] = NA

  assign("negative.whole", negative.whole, envir = .GlobalEnv)
	assign("negative", negative, envir = .GlobalEnv)
	assign("PSSM", NULL,  envir = .GlobalEnv)
	assign("pscores", NULL,  envir = .GlobalEnv)
	assign("nscores", NULL,  envir = .GlobalEnv)
	assign("jpscores", NULL,  envir = .GlobalEnv)
	assign("jnscores", NULL,  envir = .GlobalEnv)
	assign("cutoff.score", NULL,  envir = .GlobalEnv)
	assign("unjacked", NULL,  envir = .GlobalEnv)
	assign("jacked", NULL,  envir = .GlobalEnv)
}

# Add messages to message box
add.messages = function(msg) {
     tkconfigure(messages, state = "normal")
     tkinsert(messages, "end", paste(">>", msg, "\n"))
     tkyview.moveto(messages, 1)
     tkconfigure(messages, state = "disabled")
}

# Add messages to results box
add.results = function(msg) {
     tkconfigure(results, state = "normal")
     tkinsert(results, "end", paste(">>", msg, "\n"))
     tkyview.moveto(results, 1)
     tkconfigure(results, state = "disabled")
}

# Load work
loadb =
function() {
     file = tclvalue(tkgetOpenFile())
     load(file, envir = .GlobalEnv)
     msg = paste("'", file, "'", " loaded.\n", sep = "")
     add.messages(msg)
}

# Save work
saveb =
function() {
     file = tclvalue(tkgetSaveFile())
     save(positive, negative, PSSM, pscores, nscores,
          jpscores, jnscores, jacked, unjacked, file = file)
     msg = paste("Data saved under '", file, "'\n", sep = "")
     add.messages(msg)
}

# Creating the PSSM matrix
createpssmb =
function() {
     if(is.null(positive) | is.null(negative)) {
          msg = "Positive and/or negative sequences incorrectly loaded.  Please try loading them again.\n"
          add.messages(msg)
          tkmessageBox(message = msg, icon = "error", type = "ok")
     } else {
          msg = "Please wait a couple of minutes.\n"
          add.messages(msg)
          answer = tkmessageBox(message = msg,
                         icon = "info", type = "okcancel", default = "ok")
          if(as.character(answer) == "ok") {
               PSSM = PSSMtable(positive, negative)
               assign("PSSM", PSSM, envir = .GlobalEnv)
               msg = paste("p", length(positive.whole),
                              "n", length(negative.whole),
                              " PSSM created successfully.\n", sep = "")
               add.messages(msg)
               tkmessageBox(message = msg, icon = "info", type = "ok")
          } else {
               msg = "PSSM was not created.\n"
               add.messages(msg)
               tkmessageBox(message = msg, icon = "info", type = "ok")
          }
     }
}

# Show the PSSM
showpssmb =
function() {
     if(is.null(PSSM)) {
          msg = "Create the PSSM first.\n"
          add.messages(msg)
          tkmessageBox(message = msg, icon = "error", type = "ok")
     } else {
#          showData(PSSM, placement="-20+200", maxwidth=80, maxheight=30)

#if(FALSE) {
          PSSM.values = as.vector(t(round(PSSM, 3)), mode = "character")
          PSSM.display1 = c(paste(-5:5, collapse = "\t"),
                         sapply(0:19, function(i) paste(PSSM.values[(i*11+1):((i+1)*11)], collapse = "\t")))
          temp = c("  ", aa.all)
          PSSM.display2 = sapply(1:21, function(i) paste(temp[i], PSSM.display1[i], sep = "\t"))
          PSSM.display3 = sapply(1:21, function(i) paste(PSSM.display2[i], temp[i], sep = "\t"))
          msg.temp = paste(PSSM.display3, collapse = "\n")
          msg = paste("p", length(positive.whole),
                         "n", length(negative.whole),
                         " PSSM that was created:\n", msg.temp, "\n", sep = "")
          add.results(msg)
#}

     }
}

# Unjackknifed scores for positive and negative sequences
scoreb =
function() {
     if(is.null(PSSM)) {
          msg = "Please create the PSSM first.\n"
          add.messages(msg)
          tkmessageBox(message = msg, icon = "error", type = "ok")
     } else {
          pscores = score(positive.whole, PSSM = PSSM)
          nscores = score(negative.whole, PSSM = PSSM)
          assign("pscores", pscores, envir = .GlobalEnv)
          assign("nscores", nscores, envir = .GlobalEnv)
          msg = "Positive and negative sequences scored successfully.\n"
          add.messages(msg)
          tkmessageBox(message = msg, icon = "info", type = "ok")
     }
}

# Jackknifed scores for positive sequences
jpscoresb =
function() {
     if(is.null(positive) | is.null(negative)) {
          msg = "Positive and/or negative sequences incorrectly loaded. Please try loading them again.\n"
          add.messages(msg)
          tkmessageBox(message = msg, icon = "error", type = "ok")
     } else {
          msg = "Please wait about 5 minutes.\n"
          add.messages(msg)
          answer = tkmessageBox(message = msg,
                         icon = "info", type = "okcancel", default = "ok")
          if(as.character(answer) != "cancel") {
               jpscores = jackknife(positive.whole, positive, negative)
               assign("jpscores", jpscores, envir = .GlobalEnv)
               msg = "Jackknifed scores for positive sequences created successfully.\n"
               add.messages(msg)
               tkmessageBox(message = msg, icon = "info", type = "ok")
          } else {
               msg = "Jackknifed scores for positive sequences has not been created.\n"
               add.messages(msg)
               tkmessageBox(message = msg, icon = "info", type = "ok")
          }
     }
}

# Jackknifed scores for negative sequences
jnscoresb =
function() {
     if(is.null(positive) | is.null(negative)) {
          tkmessageBox(message = "Positive and/or negative sequences incorrectly loaded. Please try loading them again.",
               icon = "error", type = "ok")
     } else {
          msg = "Please wait about half an hour.\n"
          add.messages(msg)
          answer = tkmessageBox(message = msg,
                    icon = "info", type = "okcancel", default = "ok")
          if(as.character(answer) != "cancel") {
               jnscores = jackknife.neg(negative.whole, positive, negative)
               assign("jnscores", jnscores, envir = .GlobalEnv)
               msg = "Jackknifed scores for negative sequences created successfully.\n"
               add.messages(msg)
               tkmessageBox(message = msg, icon = "info", type = "ok")
          } else {
               msg = "Jackknifed scores for negative sequences has not been created.\n"
               add.messages(msg)
               tkmessageBox(message = msg, icon = "info", type = "ok")
          }
     }
}
# Doing everything in one go
onestepb =
function() {
     if(is.null(positive) | is.null(negative)) {
          msg = "Positive and/or negative sequences incorrectly loaded.  Please try loading them again.\n"
          add.messages(msg)
          tkmessageBox(message = msg, icon = "error", type = "ok")
     } else {
          msg = "Please wait about one hour.\n"
          add.messages(msg)
          answer = tkmessageBox(message = msg,
                         icon = "info", type = "okcancel", default = "ok")
          if(as.character(answer) == "ok") {
               PSSM = PSSMtable(positive, negative)
               pscores = score(positive.whole, PSSM = PSSM)
               nscores = score(negative.whole, PSSM = PSSM)
               jpscores = jackknife(positive.whole, positive, negative)
               jnscores = jackknife(negative.whole, positive, negative)

               assign("PSSM", PSSM, envir = .GlobalEnv)
               assign("pscores", pscores, envir = .GlobalEnv)
               assign("nscores", nscores, envir = .GlobalEnv)
               assign("jpscores", jpscores, envir = .GlobalEnv)
               assign("jnscores", jnscores, envir = .GlobalEnv)

               msg = paste("p", length(positive.whole),
                              "n", length(negative.whole),
                              " PSSM created successfully.\n", sep = "")

               add.messages(msg)
               tkmessageBox(message = msg, icon = "info", type = "ok")
          } else {
               msg = "PSSM was not created.\n"
               add.messages(msg)
               tkmessageBox(message = msg, icon = "info", type = "ok")
          }
     }
}

# Finding the cutoff
cutoffb =
function() {
     if(is.null(jpscores) | is.null(jnscores)) {
     tkmessageBox(message = "Please find the jackknifed scores for the positive and negative sequences.",
          icon = "error", type = "ok")
     } else {
          cutoffs = numeric(100)
          for(i in 1:100) cutoffs[i] = cutoff(jpscores, jnscores)
          cutoff.score = mean(cutoffs)
          msg = paste("Cutoff score:", signif(cutoff.score, 3), "\n")
          add.results(msg)
          tkmessageBox(message = msg, icon = "info", type = "ok" )
          assign("cutoff.score", cutoff.score, envir = .GlobalEnv)
     }
}

# Obtain ROC score for unjackknifed scores
unjackedROCscoreb =
function() {
     if(is.null(pscores) | is.null(nscores)) {
          msg = "Please find the unjackknifed scores for the positive and negative sequences.\n"
          tkmessageBox(message = msg, icon = "error", type = "ok")
     } else {
          unjacked = rocdemo.sca(c(rep(1, length(pscores)), rep(0, length(nscores))), c(pscores, nscores), dxrule.sca, caseLabel = "Sulfation", markerLabel = "Unjackknifed Scores")
          assign("unjacked", unjacked, envir = .GlobalEnv)
          msg = paste("Unjackknifed Scores - ROC Score:", signif(AUC(unjacked), 3), "\n")
          add.results(msg)
          tkmessageBox(message = msg, icon = "info", type = "ok")
     }
}

# Plot ROC plot for unjackknifed scores
unjackedROCplotb =
function() {
     if(is.null(unjacked)) {
          msg = "Please find the ROC Score first.\n"
          tkmessageBox(message = msg, icon = "error", type = "ok")
     } else {
          plot(unjacked, type = "l", lwd = 2, col = "blue", main = "ROC Curve for Unjackknifed Positive and Negative Sites")
          text(.9, 0, labels = paste("ROC Score =", signif(AUC(unjacked), 3)))
     }
}

# Obtain ROC score for jackknifed scores
jackedROCscoreb =
function() {
     if(is.null(jpscores) | is.null(jnscores)) {
          msg = "Please find the jackknifed scores for the positive and negative sequences.\n"
          add.messages(msg)
          tkmessageBox(message = msg, icon = "error", type = "ok")
     } else {
          jacked = rocdemo.sca(c(rep(1, length(jpscores)), rep(0, length(jnscores))), c(jpscores, jnscores), dxrule.sca, caseLabel = "Sulfation", markerLabel = "Jackknifed Scores")
          assign("jacked", jacked, envir = .GlobalEnv)
          msg = paste("Jackknifed Scores - ROC Score:", signif(AUC(jacked), 3), "\n")
          add.results(msg)
          tkmessageBox(message = msg, icon = "info", type = "ok")
     }
}

# Plot ROC plot for jackknifed scores
jackedROCplotb =
function() {
     if(is.null(jacked)) {
          msg = "Please find the ROC Score first.\n"
          tkmessageBox(message = msg, icon = "error", type = "ok")
     } else {
          plot(jacked, type = "l", lwd = 2, col = "blue", main = "ROC Curve for Jackknifed Positive and Negative Sites")
          text(.9, 0, labels = paste("ROC Score =", signif(AUC(jacked), 3)))
     }
}

# Save PSSM matrix
savePSSMb =
function() {
     if(is.null(PSSM)) {
          msg = "Please create PSSM matrix first.\n"
          tkmessageBox(message = msg, icon = "error", type = "ok")
     } else {
          file = tclvalue(tkgetSaveFile())
          write.table(PSSM, file = file, quote = FALSE, sep = "\t")
          msg = paste("PSSM matrix saved as '", file, "'\n", sep = "")
          add.messages(msg)
     }
}


# Save positive info (unjackknifed and jackknifed scores)
saveposinfob =
function() {
     if(is.null(pscores) & is.null(jpscores)) {
          msg = "Please score positive and jackknifed positive sequences first.\n"
          tkmessageBox(message = msg, icon = "error", type = "ok")
     } else if(is.null(pscores)) {
          msg = "Please score positive sequences first.\n"
          tkmessageBox(message = msg, icon = "error", type = "ok")
     } else if(is.null(jpscores)) {
          msg = "Please score jackknifed positive sequences first.\n"
          tkmessageBox(message = msg, icon = "error", type = "ok")
     } else {
          file = tclvalue(tkgetSaveFile())
          savepos = data.frame(positive.whole, pscores, jpscores)
          names(savepos) = c("Sequence", "Unjackknifed Score", "Jackknifed Score")
          write.table(savepos, file = file, quote = FALSE, sep = "\t")
          msg = paste("Positive info saved as '", file, "'\n", sep = "")
          add.messages(msg)
     }
}

# Save negative info (unjackknifed and jackknifed scores)
saveneginfob =
function() {
     if(is.null(nscores) & is.null(jnscores)) {
          msg = "Please score negative and jackknifed negative sequences first.\n"
          tkmessageBox(message = msg, icon = "error", type = "ok")
     } else if(is.null(nscores)) {
          msg = "Please score negative sequences first.\n"
          tkmessageBox(message = msg, icon = "error", type = "ok")
     } else if(is.null(jnscores)) {
          msg = "Please score jackknifed negative sequences first.\n"
          tkmessageBox(message = msg, icon = "error", type = "ok")
     } else {
          file = tclvalue(tkgetSaveFile())
          saveneg = data.frame(negative.whole, nscores, jnscores)
          names(saveneg) = c("Sequence", "Unjackknifed Score", "Jackknifed Score")
          write.table(saveneg, file = file, quote = FALSE, sep = "\t")
          msg = paste("Negative info saved as '", file, "'\n", sep = "")
          add.messages(msg)
     }
}

#############################
##### LAYOUT OF THE GUI #####
#############################

# Creating the panels
tt = tktoplevel()
tktitle(tt) = "Creating the PSSM"
main = tk2panedwindow(tt, orient = "horizontal")
buttonshere = tk2label(main, text = "")
outputhere = tk2label(main, text = "")
tkadd(main, buttonshere)
tkadd(main, outputhere)
submain = tk2panedwindow(buttonshere, orient = "vertical")
panel1 = tk2label(submain, text = "")
panel2 = tk2label(submain, text = "")
tkadd(submain, panel1)
tkadd(submain, panel2)
suboutput = tk2panedwindow(outputhere, orient = "vertical")
results.panel = tk2label(suboutput, text = "")
messages.panel = tk2label(suboutput, text = "")
tkadd(suboutput, messages.panel)
tkadd(suboutput, results.panel)

# Creating the fonts and blank lines
fontHeading = tkfont.create(size = 15, weight = "bold")
fontOutput = tkfont.create(family = "courier", size = 10)
fontBlankLine = tkfont.create(size = 1)
nothing.1 = tklabel(panel1, text = "      ")
nothing.2 = tklabel(panel2, text = "      ")

# Creating the scrollbars and packing it into the panels
xscrollbar.results = tkscrollbar(results.panel, repeatinterval = 5, orient = "horizontal",
                       command = function(...) tkxview(results,...))
yscrollbar.results = tkscrollbar(results.panel, repeatinterval = 5,
                       command = function(...) tkyview(results,...))
results = tktext(results.panel, bg = "white", font = fontOutput,
                    width = 80, height = 24, wrap = "none",
                    xscrollcommand = function(...) tkset(xscrollbar.results,...),
                    yscrollcommand = function(...) tkset(yscrollbar.results,...))
tkgrid(results, yscrollbar.results)
tkgrid(xscrollbar.results)
tkgrid.configure(yscrollbar.results, sticky = "ns")
tkgrid.configure(xscrollbar.results, sticky = "ew")
tkinsert(results, "end", "***** RESULTS WILL GO HERE *****\n\n")

scrollbar.messages = tkscrollbar(messages.panel, repeatinterval = 5,
                       command = function(...) tkyview(messages,...))
messages = tktext(messages.panel, bg = "white", font = fontOutput,
                    width = 80, height = 10,
                    yscrollcommand = function(...) tkset(scrollbar.messages,...))
tkgrid(messages, scrollbar.messages)
tkgrid.configure(scrollbar.messages, sticky="ns")
tkinsert(messages, "end", "***** IMPORTANT MESSAGES WILL GO HERE *****\n\n")

# Creating the labels and the buttons
title = tklabel(panel1, text ="Creating the PSSM", font = fontHeading)

saveloadlabel = tklabel(panel2, text = "Save/Load work")
load.but = tkbutton(panel2, text = "Load", width = 18, command = loadb)
save.but = tkbutton(panel2, text = "Save", width = 18, command = saveb)

openpos.but = tkbutton(panel2, text = "positive sequences", width = 18, command = getposfile)
openneg.but = tkbutton(panel2, text = "negative sequences", width = 18, command = getnegfile)
openfileslabel = tklabel(panel2, text = "Open files for...")

pssmlabel = tklabel(panel2, text = "PSSM Matrix")
createpssm.but = tkbutton(panel2, text = "Create", width = 18, command = createpssmb)
showpssm.but = tkbutton(panel2, text = "Show", width = 18, command = showpssmb)

scoreseqlabel = tklabel(panel2, text = "Score positive and\nnegative sequences")
score.but = tkbutton(panel2, text = "Score", width = 18, command = scoreb)

jackknifelabel = tklabel(panel2, text = "Jackknifed scores for...")
jpscores.but = tkbutton(panel2, text = "positive sequences", width = 18, command = jpscoresb)
jnscores.but = tkbutton(panel2, text = "negative sequences", width = 18, command = jnscoresb)

onesteplabel = tklabel(panel2, text = "Step-by-step\napproach in one-step")
onestep.but = tkbutton(panel2, text = "Click here", width = 18, command = onestepb)

cutofflabel = tklabel(panel2, text = "Cutoff Score")
cutoff.but = tkbutton(panel2, text = "Find cutoff score", width = 18, command = cutoffb)

unjackedROClabel = tklabel(panel2, text = "ROC: Unjackknifed Scores")
unjackedROCscore.but = tkbutton(panel2, text = "Score", width = 18, command = unjackedROCscoreb)
unjackedROCplot.but = tkbutton(panel2, text = "Plot", width = 18, command = unjackedROCplotb)

jackedROClabel = tklabel(panel2, text = "ROC: Jackknifed Scores")
jackedROCscore.but = tkbutton(panel2, text = "Score", width = 18, command = jackedROCscoreb)
jackedROCplot.but = tkbutton(panel2, text = "Plot", width = 18, command = jackedROCplotb)

saveoutputlabel = tklabel(panel2, text = "Save as text files")
savePSSM.but = tkbutton(panel2, text = "PSSM matrix", width = 18, command = savePSSMb)
saveposinfo.but = tkbutton(panel2, text = "Positive info", width = 18, command = saveposinfob)
saveneginfo.but = tkbutton(panel2, text = "Negative info", width = 18, command = saveneginfob)


quit.but = tkbutton(panel2, text = "Quit", command = function() tkdestroy(tt))


# Packing/laying out all of the stuff
  # Panel 1 layout
tkgrid(title)

  # Panel 2 layout
tkgrid(saveloadlabel, save.but)
tkgrid(nothing.2, load.but)
tkgrid(tklabel(panel2, text = "   ", font = fontBlankLine))

tkgrid(openfileslabel, openpos.but)
tkgrid(nothing.2, openneg.but)
tkgrid(tklabel(panel2, text = paste(rep("-", 150), collapse = ""), font = fontBlankLine))
tkgrid(tklabel(panel2, text = "STEP-BY-STEP APPROACH"))

tkgrid(pssmlabel, createpssm.but)
tkgrid(nothing.2, showpssm.but)
#tkgrid(tklabel(panel2, text = "   ", font = fontBlankLine))

tkgrid(scoreseqlabel, score.but)
#tkgrid(tklabel(panel2, text = "   ", font = fontBlankLine))

tkgrid(jackknifelabel, jpscores.but)
tkgrid(nothing.2, jnscores.but)
tkgrid(tklabel(panel2, text = "   ", font = fontBlankLine))

tkgrid(tklabel(panel2, text = paste(rep("-", 150), collapse = ""), font = fontBlankLine))
tkgrid(tklabel(panel2, text = "ONE-STEP APPROACH"))

tkgrid(onesteplabel, onestep.but)
tkgrid(tklabel(panel2, text = "   ", font = fontBlankLine))
tkgrid(tklabel(panel2, text = paste(rep("-", 150), collapse = ""), font = fontBlankLine))

tkgrid(tklabel(panel2, text = "CUTOFF & ROC SCORE"))
tkgrid(cutofflabel, cutoff.but)
tkgrid(tklabel(panel2, text = "   ", font = fontBlankLine))

tkgrid(unjackedROClabel, unjackedROCscore.but)
tkgrid(nothing.2, unjackedROCplot.but)
tkgrid(tklabel(panel2, text = "   ", font = fontBlankLine))

tkgrid(jackedROClabel, jackedROCscore.but)
tkgrid(nothing.2, jackedROCplot.but)
tkgrid(tklabel(panel2, text = "   "))
tkgrid(tklabel(panel2, text = paste(rep("-", 150), collapse = ""), font = fontBlankLine))

tkgrid(saveoutputlabel, savePSSM.but)
tkgrid(nothing.2, saveposinfo.but)
tkgrid(nothing.2, saveneginfo.but)
tkgrid(tklabel(panel2, text = "   "))

tkgrid(nothing.2, quit.but, sticky = "se")

tkpack(submain, fill = "both", expand = "yes")
tkpack(suboutput, fill = "both", expand = "yes")
tkpack(main, fill = "both", expand = "yes")


tkconfigure(messages, state="disabled")
tkconfigure(results, state="disabled")
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







