
###########
###table of contents
###########
#1. prep
####a. libraries
####b. system directories
#2. exogenous information
####a. var definitions
####b. user defined variables
####c. LookupTables
#######i. climate
#######ii. T|V
#######iii. x|R,V
#######iv. season characteristics|month|Stage 
#######v. N|x
#3. dp solver components
####a. approximations/discretizations
####b. state variables
####c. state transitions
####d. infeasible space 
####e. R|(V,y)
####f. keep R|min(x,f*) only if feasible except Oct else R|(V,y) (and R|min(N,N*{t+1}))
####g. calc end of period storage|(R,V,y)
####h. stores outcome variables (f*, x)
#4. dp solvers
####a. direct benefit function
####b. accumulative obj function
#5. dp model
####a. last stage
####b. intermediate stage
####c. first stage
#6. results
####a. best policy
####b. libraries
####c. 
###########

#profvis({

########
##prep
#######
####a. libraries
####b. set workspace
rm(list=ls(all=TRUE)) #start with empty workspace
setwd("C:/Users/leadams/Desktop/ShastaDam/DP")
getwd()
####c.global functions
mround <- function(x,base){ #this function ensures matching between stages
  base*round(x/base) 
} 
monthlist=vector()
for(i in 1:12){ #gets month
  monthlist[i]=month.name[i]
}
#######
##exogenous information
#######

#### user defined variables
#####
NoofStages=17 #number of stages in program
bin=10^6 #storage discretization unit
Tsep=52 #temperature at which layers were separated into "cold' and "warm" with file "ExploringInputDataEachVwVc"
roundingdigits=6 #10^6
Vcinitial=bin #initial conditions
Vwinitial=0#need to check the month bin #initial conditions
Vinitial=Vcinitial+Vwinitial #total storage in reservoir
K=4*10^6 #reservoir storage capacity
DP=0.2*10^3 #water is no longer passing through the turbines
Max=4*10^6#bin#mround(K+4*10^6,bin)+2*10^6 #max reservor storage + max(Qin)=4*10^6
RcstarWinter=0 #need to put in model at later date
p=0.99
#releases are at end of period
######### approximations/discretizations
######
#state vars
Vc=seq(0,Max, bin) #sequence of Vc choices 
Vw=seq(0,Max, bin) #sequence of Vw choices
V=Vc+Vw
L=seq(-0.5*bin, Max+0.5*bin, bin) #makes bins 
###state space
Vdiscretizations=function(Vc,Vw){
  i=j=1
  z=0
  Vcoptions=length(Vc)
  Vwoptions=length(Vw)
  Voptions=matrix(0, nrow=3, ncol=Vcoptions*Vwoptions)
  for(i in 1:Vcoptions){
    for (j in 1:Vwoptions){
      VH=Vc[i]+Vw[j]
      z=z+1
      Voptions[1,z]=Vw[j]
      Voptions[2,z]=Vc[i]
      Voptions[3,z]=VH
    }
  }
  rownames(Voptions)=c("Vw","Vc", "V")
  return(Voptions)
}
Voptions=t(Vdiscretizations(Vc,Vw)[c(1:2),])
colnames(Voptions)=c("Vc","Vw")
#apprximated states (vector)
Vcstates=Voptions[,1] #Vc is vector of discretized release possibliities
Vwstates=Voptions[,2]#Vw is vector of discretized release possibliities
Vstates=Vcstates+Vwstates

####action(decision) vars
#Rc=Vc #decision variables must equal bin discretizations to look forward and backward in time
nospillRc=Vc #seq(0,Max+4*10^6, bin)
nospillRw=Vw #Rc
nospillR=nospillRc+nospillRw
#approximated set of action choices
nospillRdiscretizations=Vdiscretizations(nospillRc,nospillRw)
nospillRoptions=t(Vdiscretizations(nospillRc,nospillRw)[c(1:2),])
colnames(nospillRoptions)=c("nospillRc","nospillRw")
#rownames(Rdiscretizations)=c("Rw","Rc","R")
#decisoin space options (vector)
nospillRcdecs=nospillRdiscretizations[2,]#Vcstates
nospillRwdecs=nospillRdiscretizations[1,]#"Vwstates
nospillRdecs=nospillRcdecs+nospillRwdecs

####d. non-release dependent LookupTables
#####
#######i. climate
###########

#joint probability of historical air temp and inflow
#synthetically calculatead per month based on pdf. each record of 0.01 occurs with 0.01 joint prob/month for each month
setwd("C:/Users/leadams/Desktop/ShastaDam/Input_data")
climate=read.csv("climateinputs5probs.csv") #climate data generated with InflowCleaningv2 oct 19 2017
setwd("C:/Users/leadams/Desktop/ShastaDam") #paper output goes to this file directory
#print(xtable(climate,type="latex"), file="yeartypes.tex") 
#probability of occurence
probs=c(0.01,0.1, 0.5, 0.9, 0.99) #probs

####change in air temp for mixed pool state transition
rawTa=climate[,5]
pn=length(climate[,5])/12 #number of probs in analysis calculated with inflowcleaningv2 in input_data
ifelse(length(probs)!=pn, print("PROBSERROR"),"")
deltaTa=matrix(0,nrow=length(rawTa),ncol=1) #creates matrix within which to store deltaTa per month for each historical climate record with prob p
for(i in (pn+1):length(rawTa)){ #calculates deltaTa
  deltaTa[i]=rawTa[i]-rawTa[i-pn]
}
for(i in pn:1){ #calculates deltaTa for the first observation 
  deltaTa[i]=rawTa[length(rawTa)-(i-1)]-rawTa[i] #digits=-3) 
}
deltaTa=mround(deltaTa,0.1) #uses mround function from global functions in this script

######monthly inflow
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
rawQ=climate[,6]
Q=mround(finalinflow(climate[,2],rawQ), bin)

###Markov Chains
ystates=probs

Lookupyprep=cbind(climate,Q,deltaTa)
Lookupy=Lookupyprep[,c(2,10,11,12)]

TaLookupprep=function(month,p){
  Ta=Lookupy[which(Lookupy[,1]==month & Lookupy[,2]==p),4] #the max is just in case there are multiples 
  return(Ta)
}
TaLookup=Vectorize(TaLookupprep)

QLookupprep=function(month,p){ #this could be VC, Vc or Vcstates
  Qprep=Lookupy[which(Lookupy[,1]==month & Lookupy[,2]==p),3]
  Q=as.numeric(Qprep)
  return(Q)
}    
QLookup=Vectorize(QLookupprep)
#########
#######ii. T|V
##########
####get raw temp and volume data
setwd("C:/Users/leadams/Desktop/ShastaDam/SDP")
all=read.csv("TwopoolAlldatav4.csv") #full reservoir storage and temp dataset generated from file exploringinputdataeachvwvc 2 Sept
#notes: all was created with 51F warm and cold pool stratification temperature
abbreviated=read.csv("GroupidExpectedVwVcTcTw.csv") #cleaned and analyzed/aggregated dataset for analysis 6 Sept

setwd("C:/Users/leadams/Desktop/ShastaDam/DP") #run analysis on VwVc to TcTw from this directory
groupingcorrelation=lm(all$Groupid~all$month) #checking to see if i can run the analysis by group id
#good correlation OK to group Vc and Vw by groupid
#Residual standard error: 22.91 on 217 degrees of freedom
#Multiple R-squared:  0.7583,	Adjusted R-squared:  0.7472 
#F-statistic: 68.09 on 10 and 217 DF,  p-value: < 2.2e-16

#order by storage volume size, first of Vw then Vc - hopefully this is relatively monotonic
OrderedVwVc=abbreviated[order(abbreviated$totalVw,-abbreviated$totalVc),] 
d=OrderedVwVc 
observedVc=all[,100] #raw Vc
observedVw=all[,99] #raw Vw
ObservedTc=all[,98] #raw reservoir Tc
ObservedTw=all[,97] #raw reservoir Tw
#full raw table of temp to volume relationships w 51F warm and cool split
ObservedLookupTable=cbind(observedVc,ObservedTc,observedVw,ObservedTw) 

#######iii. season characteristics|month|Stage
###############
#gets month based on stage number
monthcounter=function(Stage){ #gives month per stage number
  monthlocation=ifelse(Stage%%12==0, 12, Stage - floor(Stage/12)*12)
  month=month.name[monthlocation] #starts with january
  return(month)
}
#gets climate season based on month
seasonbin=function(month){
  season=ifelse(month== "December" || month== "January", "winter", 
                ifelse(month== "February" || month== "March", "earlyspring", 
                       ifelse(month== "April", "spring", 
                              ifelse(month== "May" || month=="June" || month== "July", "summer", 
                                     ifelse(month== "August" || month== "September" || month=="October", "latesummer",
                                            ifelse(month== "November", "fall", 
                                                   "ERROR"))))))
  return(season)
}
#determines if lake is stratified or not based on month
lakeseasonbin=function(month){
  lakeseason=ifelse(month== "December" || month== "January", "winter", 
                    ifelse(month== "February" || month== "March", "earlyspring", 
                           ifelse(month== "April" || month== "May" || month== "June" || month== "July" ||month== "August" || month== "September" || month=="October", "stratified",
                                  ifelse(month== "November", "overturn", 
                                         "ERROR"))))
  return(lakeseason)
}

#####################
#####-finding max Qc and Qw to include spill
##and to estimate range of possible end of period storage before releases (e.g., Vc+Qc-Rc)

######### mixed season coldpool transition
######
#coefficients
NickelsSpringCoefficients=c(3.324,0, -0.372, 0.264) #intercept, fall bypass(removed rather than replaced by -0.855*Rc releases), spring air temp, spring volume
#km3, km3/km3, km3/changeC, km3/km3 1km=810.714 TAF
#current units needed AF, AF/AF, AF/F, AF/AF
NickelsWinterCoefficients=c(0.887, -0.264, 0.322,-0.253) #intercept, winter air temp, winter inflow, oct/nov reservoir temp
#km3, km3/changeC, km3/km3, km3/C
#AF, AF/F, AF/AF, AF/F
afconversion=810714 #AF
springcoeff=NickelsSpringCoefficients*c(afconversion,1, afconversion,1) 
wintercoeff=NickelsWinterCoefficients*c(afconversion,afconversion,1,afconversion) 

WinterDeltaVcprep=function(month,p){ 
  DeltaVc=mround(wintercoeff[1]+wintercoeff[2]*as.numeric(TaLookup(month,p))+wintercoeff[3]*as.numeric(QLookup(month,p))+wintercoeff[4]*1.6, bin) 
  #round((0.855*Qin+0.264*TcLookup(VC,VW)+(0.253*0.12)*Qin+0.887)/2, digits=-6) #check eq and units
  return(DeltaVc)
}
WinterDeltaVc=Vectorize(WinterDeltaVcprep)

SpringDeltaVcprep=function(RcstarWinter,month, RC,p){
  DeltaVc=ifelse((springcoeff[1]+springcoeff[2]*RC+springcoeff[3]*as.numeric(TaLookup(month,p))+springcoeff[4]*as.numeric(QLookup(month,p))) <0,0,
                 (springcoeff[1]+springcoeff[2]*RC+springcoeff[3]*as.numeric(TaLookup(month,p))+springcoeff[4]*as.numeric(QLookup(month,p))))
  AdjustedforRcWinter=mround(DeltaVc#-1.5*10^6
                             ,bin)
  return(AdjustedforRcWinter)
}
SpringDeltaVc=Vectorize(SpringDeltaVcprep)

ColdDeltaprep=function(month, RcstarWinter,RC,p){ 
  DeltaVc=ifelse(lakeseasonbin(month)=="winter",WinterDeltaVc(month,p),
                 SpringDeltaVc(RcstarWinter,month,RC,p)) 
  return(DeltaVc)
}
ColdDelta=Vectorize(ColdDeltaprep)

#####################
###including spill/transition states in model state and action spaces
#####################

#get discretizations with spill (remember to line up the index)
VRdiscretizations=function(VC,VW,RC,RW){
  i=j=k=l=1
  z=0
  allVRoptions=matrix(0, nrow=length(VC)*length(VW)*length(RC)*length(RW), ncol=4)
  for(i in 1:length(RW)){
    for (j in 1:length(RC)){
      for(k in 1:length(VW)){
        for(l in 1:length(VC)){
          z=z+1
          allVRoptions[z,1]=VC[l]
          allVRoptions[z,2]=VW[k]
          allVRoptions[z,3]=RC[j]
          allVRoptions[z,4]=RW[i]
        }
      }
    }
  }
  colnames(allVRoptions)=c("Vc","Vw", "Rc","Rw")
  return(allVRoptions)
}
#get max available VC during fall overturn #calculations from fallsolve
MaxQcprep=max(ColdDelta("January",RcstarWinter, nospillRc, p),
              ColdDelta("February",RcstarWinter, nospillRc, p),
              ColdDelta("March",RcstarWinter, nospillRc, p),
              max(QLookup("November",p)+max(Vwstates)-min(nospillRw)+max(Vcstates)),
              ColdDelta("December",RcstarWinter, nospillRc, p))
MaxQw=max(Lookupy[Lookupy[,1]=="April" | Lookupy[,1]=="May" | Lookupy[,1]=="June" | Lookupy[,1]=="July" | Lookupy[,1]=="August" | Lookupy[,1]=="September" | Lookupy[,1]=="October",3])

##need max Q included in lookup temp table 
AvailVcprep=seq(0,MaxQcprep+max(Vc),bin)
AvailVw=seq(0,MaxQw+max(Vw),bin) #vc and Vw includes inflow and atm conditions

MaxQc=max(MaxQcprep,MaxQcprep+max(AvailVcprep)-max(AvailVw)) #fall overturn creates situations in which more than maxQ enters

AvailVc=seq(0,MaxQc+max(Vc),bin)
AvailVw=seq(0,MaxQw+max(Vw),bin) #vc and Vw includes inflow and atm conditions

#Voutoptions=Vdiscretizations(AvailVc,AvailVw)
#Voutoptions=t(Vdiscretizations(AvailVc,AvailVw)[c(1:2),])
#colnames(Voutoptions)=c("Vc","Vw")

########make V| T to include start and end of period storage possibilities (excluding releas options)
#aggregated into uniform bins of width "bin" for DP 

MakingBins=function(ObservedLookupTable,observedVc,observedVw,Vc,Vw,L){
  Vcintervalbin=cut(as.numeric(observedVc),breaks=L, labels=Vc)
  Vwintervalbin=cut(as.numeric(observedVw),breaks=L, labels=Vw)
  allbinned=cbind(as.numeric(as.character(Vcintervalbin)),as.numeric(as.character(Vwintervalbin)),ObservedLookupTable)
  colnames(allbinned)[[1]]=c("Vcbin") 
  colnames(allbinned)[[2]]=c("Vwbin") 
  return(allbinned)
}

allbins=MakingBins(ObservedLookupTable,observedVc,observedVw,Vc,Vw,L)
preppeddata=allbins
preppeddata[is.na(preppeddata)]=0 #this includes observations for which there is some of one pool but not the other
#gets median cold pool temperature for each possible combination of cold and warm pool volumes
Tc=aggregate(as.numeric(preppeddata[,4])~Vcbin+Vwbin, 
             preppeddata, FUN=median, na.action=na.pass,na.rm=TRUE)
#gets median warm pool temperature for all observationseach possible combination of cold and warm pool volumes
Tw=aggregate(as.numeric(preppeddata[,6])~Vcbin+Vwbin, 
             preppeddata, FUN=median, na.action=na.pass,na.rm=TRUE)

LookupTableprep=merge(Tc,Tw,by=c("Vcbin","Vwbin"), all=TRUE)
colnames(LookupTableprep)=c("Vc","Vw","Tc","Tw")
LookupTableprep2=merge(Voptions,LookupTableprep, by=c("Vc","Vw"), all=TRUE) #get full range of DP states

#catches observations with volumes less than lowest discretization
LookupTableprep2[,3]=ifelse(LookupTableprep2[,3]==0,NA,LookupTableprep2[,3])
LookupTableprep2[,4]=ifelse(LookupTableprep2[,4]==0,NA,LookupTableprep2[,4])
LookupTable=LookupTableprep2

#either have all possible Vc and Vw functions in the lookup table or have a function that assumes
#anything above K etc as equivalent to a full Vc /Vw


#interpolate missing values either by carrying forward last observation or spline (polynomial interpolation)
LookupTableprep2[,3]=ifelse(LookupTableprep2[,3]>0, LookupTableprep2[,3],NA)
LookupTableprep2[,4]=ifelse(LookupTableprep2[,4]>0, LookupTableprep2[,4],NA)
require(zoo)
#install.packages("zoo")
#library(zoo)

#the data was prepped to use this form of interpolation. all 0 are NA
#such that the data is carried forward always
LookupTableprep3=na.locf(LookupTableprep2) #last observation carried forward 

#if vol is 0 then no release with 0 temp 
LookupTableprep3[,3]=ifelse(LookupTableprep3[,1]==0, 0, LookupTableprep3[,3])
LookupTableprep3[,4]=ifelse(LookupTableprep3[,2]==0, 0, LookupTableprep3[,4])
LookupTable=LookupTableprep3[order(LookupTableprep3[,1],LookupTableprep3[,2],LookupTableprep3[,3],LookupTableprep3[,4]),]

greaterTc=LookupTable[LookupTable[,1]==max(Vc) & LookupTable[,2]==0,3]
greaterTw=LookupTable[LookupTable[,1]==0 & LookupTable[,2]==max(Vw),4]
##########get T from R and V
ReleaseTempprep=function(VC,VW, RC, RW){
 # Tc=LookupVRTprep[(LookupVRTprep[,1]==VC) & (LookupVRTprep[,2]==VW) & (LookupVRTprep[,3]==RC) & (LookupVRTprep[,4]==RW),5]
#  Tw=LookupVRTprep[(LookupVRTprep[,1]==VC) & (LookupVRTprep[,2]==VW) & (LookupVRTprep[,3]==RC) & (LookupVRTprep[,4]==RW),6] 
  Tc=ifelse(VC>max(Vc), greaterTc,
            ifelse(VW>max(Vw), LookupTable[(LookupTable[,1]==VC) & (LookupTable[,2]==max(Vw)),3],
            LookupTable[(LookupTable[,1]==VC) & (LookupTable[,2]==VW),3]))
  Tw=ifelse(VW>max(Vw), greaterTw,
            ifelse(VC>max(Vc), LookupTable[(LookupTable[,1]==max(Vc)) & (LookupTable[,2]==VW),4],
            LookupTable[(LookupTable[,1]==VC) & (LookupTable[,2]==VW),4]))
  T=ifelse(Tc==0, Tw,
           ifelse(Tw==0, Tc,
                  (Tw*RW+Tc*RC)/(RC+RW)))
  return(T)
} 
ReleaseTemp=Vectorize(ReleaseTempprep)

###plot RC and RW and TC and TW
 #plot(LookupVRT[,3],LookupVRT[,7],ylim=c(40,65)) #Rc v T
 #plot(LookupVRT[,4],LookupVRT[,7],ylim=c(40,65)) #Rw v T

#####add maximum spill potential option to spill 

#Rcprep=seq(0,MaxQcprep+max(nospillRc),bin) #releases include spill
Rc=seq(0,MaxQc+max(nospillRc),bin) #releases include spill
Rw=seq(0,MaxQw+max(nospillRw),bin)

#LookupVR=VRdiscretizations(AvailVc,AvailVw,Rc,Rw)
#LookupVRTraw=merge(LookupVR,LookupTable,by=c("Vc","Vw"), all=TRUE)

#######################
#######iii. x|(R,V)
##########################
#make table of Rc, Rw, Vc, Tc, Tw, month, x (of several policy choices,x, e.g. x from monthly thresholds and constant thresh)
#get x from T

##consistent monthly target of 56F
ClrCk=function(RT){
  x=ifelse(2.67491 + 0.95678*RT <30,0,
             2.67491 + 0.95678*RT)
  return(x)
}
Balls=function(RT){
  x=ifelse(11.26688 + 0.81206*RT<30,0,
             11.26688 + 0.81206*RT)
  return(x)
}
Jelly=function(RT){
  x=ifelse(7.74007 + 0.88836*RT <30, 0,
       7.74007 + 0.88836*RT)
  return(x)
}
#Bend=ifelse(31.69574 + 0.41228*LookupVRT$ReleaseT <33, 0, #additional Bend influences?
 #     31.69574 + 0.41228*LookupVRT$ReleaseT)
RBDD=function(RT){
  x=ifelse(15.8956 + 0.7529*RT <30, 0,
      15.8956 + 0.7529*RT)
  return(x)
}

#Lookupx=cbind(ClrCk,Balls,Jelly)#,#Bend,
                    #RBDD)
#LookupVRTx=LookupVRTxsac

 #plot(LookupVRT$ReleaseT,ClrCk, ylim=c(45,65), xlim=c(45,65), type="l", ylab="",xlab="")
 #par(new=T)
 #plot(LookupVRT$ReleaseT,Balls,ylim=c(45,65),xlim=c(45,65),col="red", type="l", ylab="",xlab="")
 #par(new=T)
 #plot(LookupVRT$ReleaseT,Jelly,ylim=c(45,65),xlim=c(45,65),col="blue",type="l", ylab="",xlab="")
 #par(new=T)
 #plot(LookupVRT$ReleaseT,Bend,ylim=c(45,65), xlim=c(45,65),col="green",type="l", ylab="",xlab="")
 #par(new=T)
 #plot(LookupVRT$ReleaseT,RBDD,ylim=c(45,65), xlim=c(45,65),col="purple", type="l", ylab="",xlab="")

rivermiles=c(302,302,289,276,266#,#256,
             #243
             )#,39,37,6) #shasta dam river mile not provided but not important since mgmt starts with keswick
distance=302-rivermiles #distance from Shasta

#######
###fish temp reqs
#########
ConstantTempThreshold=56
ReturningAdults=64
EmbryoIncubation=55
Emergents=68
OutmigratingJuveniles=66

fishtemp=function(month){
  temp=ifelse(month=="March"|| month=="April",ReturningAdults,
              ifelse(month=="May" || month=="June" || month=="July", EmbryoIncubation,
                     ifelse(month=="August", Emergents,
                            OutmigratingJuveniles)
              ))
  return(temp)
}

#LookupVRTx=cbind(LookupVRT,ConstantTempx)
 #plot(ReleaseT,ConstantTempx)
###############
#################
#######v. N|x
##############
#eventually add N to the x|(T,month,R,V) table

#######
##DP solver components
######
###########
####a. including spill in action space
#########
#approximated set of action choices
Rdiscretizations=Vdiscretizations(Rc,Rw)
Roptions=t(Vdiscretizations(Rc,Rw)[c(1:2),])
colnames(Roptions)=c("Rc","Rw")
#rownames(Rdiscretizations)=c("Rw","Rc","R")
#decisoin space options (vector)
Rcdecs=Rdiscretizations[2,]#Vcstates
Rwdecs=Rdiscretizations[1,]#"Vwstates
Rdecs=Rcdecs+Rwdecs
############
####b. state, action and outcome spaces
###########
#to create state and action spaces
basics=matrix(0, nrow=length(Vstates),ncol=length(Rdecs))
onestage=matrix(0, nrow=length(Vstates), ncol=length(Rdecs)) #*length(ystates)
allstages=array(0, dim=c(length(Vstates),length(Rdecs),length(ystates), NoofStages)) #length(ystates)
#dimnames(allstages)[[1]]=as.list(Vstates)
#dimnames(allstages)[[2]]=as.list(Rdecs)
#dimnames(allstages)[[3]]=as.list(ystates)
stageslist=seq(1,NoofStages,1)
#dimnames(allstages)[[4]]=as.list(stageslist)

#state space (matrix)
VcSpace=apply(basics,2,function(x)Vcstates)
VwSpace=apply(basics,2,function(x)Vwstates)
VSpace=apply(basics,2,function(x)Vstates)

#choice space (matrix)
Rcspace=t(apply(basics,1,function(x)Rcdecs))
Rwspace=t(apply(basics,1,function(x)Rwdecs))
Rspace=t(apply(basics,1,function(x)Rdecs))

#outcome spaces (matrices)
##creates matrix for holding each stage calculation
#can include y
stagepolicy=function(VSpace,NoofStages){
  holdingmatrix=matrix(0, nrow=length(Vstates), #ncol=length(ystates)*NoofStages) 
                       ncol=NoofStages)
  dim(holdingmatrix)=c(length(Vstates),#length(ystates), 
                       NoofStages)
  rownames(holdingmatrix)=Vstates
  #colnames(holdingmatrix)=ystates
  return(holdingmatrix)
}
fstar=stagepolicy(Vstates,NoofStages)
#whichf    #could possible shorten code by saying whichxstar=f, for all below options
whichxstar=stagepolicy(Vstates,NoofStages)
#stores the position of the optimal f to find xstar
xstar=stagepolicy(Vstates,NoofStages) #river mile number
Rcstar=stagepolicy(Vstates,NoofStages)
Rwstar=stagepolicy(Vstates,NoofStages)
#############
####c. state transitions
#############
####d. end of period storage |(R,V,y)
############
OutgoingVcprep=function(S,VC, RcstarWinter,VW,RC,RW,p){ #put month in quotations, add O #all matrices
  month=monthcounter(S)
  endperiodVc=ifelse(lakeseasonbin(month)=="winter", VC+WinterDeltaVc(month,p)-RC,
                     ifelse(lakeseasonbin(month)=="earlyspring", VC+SpringDeltaVc(RcstarWinter,month, RC,p)-RC, 
                            ifelse(lakeseasonbin(month)=="stratified", VC-RC, 
                                   ifelse(lakeseasonbin(month)=="overturn", VC+QLookup(month,p)-RC+VW-RW,
                                          "ERROR"))))
  return(endperiodVc)
}
OutgoingVc=Vectorize(OutgoingVcprep)
OutgoingVwprep=function(S,VW,RW,p){ #put month in quotations
  month=monthcounter(S)
  Vwnext=ifelse(lakeseasonbin(month)=="winter" || lakeseasonbin(month)=="earlyspring" ||lakeseasonbin(month)=="overturn",0,
                ifelse(lakeseasonbin(month)=="stratified", VW+QLookup(month,p)-RW,#+E 
                       #ifelse(lakeseasonbin(month)=="overturn", Vw-Rw, 
                       "ERROR"))
  return(Vwnext)
}
OutgoingVw=Vectorize(OutgoingVwprep)

##############

#######
##DP solvers
######
####a. direct benefit function
############
benefitprep=function(Vc,Vw,Rc,Rw,month){
  RT=ReleaseTemp(Vc,Vw,Rc,Rw)
  #xrow=LookupVRTx[which(LookupVRTx[,1]==Vc & LookupVRTx[,2]==Vw & LookupVRTx[,3]==Rc & LookupVRTx[,4]==Rw),]
  tempthreshold=fishtemp(month)
  x=ifelse(RT==0, 0, #if release temp is 0
                       #ifelse(xrow$RBDD<tempthreshold,distance[6], 
                             # ifelse(xrow$Bend<tempthreshold,distance[6],
                                     ifelse(Jelly(RT)<tempthreshold,distance[5],   
                                            ifelse(Balls(RT)<tempthreshold, distance[4],
                                                   ifelse(ClrCk(RT)<tempthreshold, distance[3],
                                                          0))))#)#)
  
  return(x)
}
benefit=Vectorize(benefitprep)

####each lake and climate season's benefits | end of month storage
mixedsolveprep=function(VW,VC,RC, RW, R, V, month, RcstarWinter, K, DP,p){ #when lake is mixed #matrices
  deltaVC=#ifelse(month=="February" || month=="March", deltaVC-springcoeff[2]*RC, WinterDeltaVc(month,p))
         ColdDelta(month, RcstarWinter,RC,p)
  AvailableVc=ifelse(VC+deltaVC<0,0,VC+deltaVC)
  x=ifelse(VW>0 || RW>0, -9999, #no warmpool
           ifelse(VC +deltaVC < RC, -9999, #consv of mass (not enough VC) 
                  ifelse(V + deltaVC- R < DP || 
                           V + deltaVC - R > K, -9999, #infrastructure limitations
                         benefit(AvailableVc,VW,RC,RW,month) #ifelse(Nmax< x, Nmax, x)
                  )))
  return(x)
}
mixedsolve=Vectorize(mixedsolveprep)
springsolveprep=function(VW,VC,RC, RW, R, V,K, DP,month,p){ #initial conditions are no warm 
  deltaVw=QLookup(month,p)
  AvailableVw=ifelse(VW+deltaVw <0, 0,
                     #ifelse(Vw+deltaVw >max(VW), max(VW),
                            Vw+deltaVw)#)
  x=ifelse(VW>0, -9999, #no warmpool at start, all warm comes from inflows
    ifelse(V + deltaVw - R < DP | V + deltaVw - R > K, -9999, #inflow is warm, cold stays, #infrastructure limitations
           ifelse(VC < RC | VW + deltaVw < RW, -9999, #consv of mass
                  benefit(VC,AvailableVw,RC,RW,month)  #ifelse(Nmax< x, Nmax, x)
           )))
  return(x)
}
springsolve=Vectorize(springsolveprep)
summersolveprep=function(VW,VC,RC, RW, R, V,K, DP,month,p){ #initial conditions are no warm (i dont like this, want VW to organically come online)
  deltaVw=QLookup(month,p)
  AvailableVW=ifelse(VW+deltaVw<0, 0, VW+deltaVw)
  x= ifelse(V + deltaVw - R < DP | V + deltaVw- R > K, -9999, #infrastructure limitations
            ifelse(VC < RC, -9999, #consv mass
                   ifelse(VW + deltaVw < RW, -9999,
                          benefit(VC,AvailableVW,RC,RW,month)  #ifelse(Nmax< x, Nmax, x)
                   )))
  return(x)
}
summersolve=Vectorize(summersolveprep)
fallsolveprep=function(VW,VC,RC,RW,K,DP,month,p){ #initial conditions are no warm (i dont like this, want VW to organically come online)
  deltaVc=QLookup(month,p)+VW-RW
  AvailableVC=ifelse(VC+deltaVc<0, 0, VC+deltaVc)
  x=ifelse(#RW > 0, -9999, #all cold at the end
    VC + deltaVc - RC < DP || VC + deltaVc - RC > K, -9999, #infrastructure limitations, no spill allowed
    ifelse(VC+deltaVc < RC, -9999, #all water becomes cold #|| VW < RW, -9999, #consv mass
           ifelse(VW<RW,-9999,
                  benefit(AvailableVC,VW,RC,RW,month)  #ifelse(Nmax< x, Nmax, x)
           )))
  return(x)
}
fallsolve=Vectorize(fallsolveprep)

#objective function/calculate current benefits
choosesolveprep=function(month,VW,VC,RC, RW, R, V,RcstarWinter,K, DP,p){ #matrix
  x=ifelse(seasonbin(month)=="winter" || seasonbin(month)=="earlyspring", mixedsolve(VW,VC,RC, RW, R, V, month, RcstarWinter,K, DP,p),
           ifelse(seasonbin(month)=="spring", springsolve(VW,VC,RC, RW, R, V,K, DP,month,p),
                  ifelse(seasonbin(month)=="summer" || seasonbin(month)=="latesummer" , summersolve(VW,VC,RC, RW, R, V,K, DP,month,p),
                         #ifelse(seasonbin(month)=="october", octobersolve(VW,VC,RC, RW, R, V,K, DP,month,p),
                           ifelse(seasonbin(month)=="fall", fallsolve(VW,VC,RC, RW, K, DP,month,p),
                                "ERROR"))))#)
  return(x)
} 
choosesolve=Vectorize(choosesolveprep)

###############
####b. accumulative obj function
#######################
accumulate=function(month,S,Vcstates,Vwstates,VcSpace,RcstarWinter,VwSpace,Rcspace,Rwspace,VSpace,Rspace,p){  #lookup f*t+1 
  for(j in 1:length(Rdecs)){ 
    for(i in 1:length(Vstates)){ 
      fs[i,j]=ifelse(choosesolve(month,VwSpace[i,j],VcSpace[i,j],Rcspace[i,j], Rwspace[i,j], Rspace[i,j],VSpace[i,j],RcstarWinter,K, DP,p)<0,-9999, #remove infeasibles
                     which(Vcstates==OutgoingVc(S,VcSpace[i,j],RcstarWinter,VwSpace[i,j],Rcspace[i,j],Rwspace[i,j],p) & #,Vcstates)[i,j] & #this gives the location of Vcstates
                             Vwstates==OutgoingVw(S, VwSpace[i,j], Rwspace[i,j],p))) #match Vw and Vc in LookupV table #location of Vw states
      fstarvalue[i,j]=ifelse(is.na(fs[i,j]), -9999, ifelse(fs[i,j]<0, -9999, #remove infeasibles
                                                           fstar[fs[i,j],(S+1)])) #get the fstar from t+1 with the matching Vw and Vc states
    } 
  } 
  return(fstarvalue) #produces a matrix of fstartt+1 values to accumulate in the benefit function, looking backwards
}

firststageaccumulate=function(month, S, Vcstates,Vwstates,Vcinitial,RcstarWinter,Vwinitial,Rcdecs,Rwdecs,Rdecs, Vinitial,p){
  for(j in 1:length(Rdecs)){#calculates f*t+1 from next stage
    fs[j]=ifelse(choosesolve(month,Vwinitial,Vcinitial,Rcdecs[j], Rwdecs[j], Rdecs[j],Vinitial,RcstarWinter,K, DP,p)<0,-9999, #remove infeasibles
                which(Vcstates==OutgoingVc(S,Vcinitial,RcstarWinter,Vwinitial,Rcdecs[j],Rwdecs[j],p) & #,Vcstates)[i,j] & 
                        Vwstates==OutgoingVw(S, Vwinitial, Rwdecs[j],p))) 
                #which(Vcstates==OutgoingVc(S,Vcinitial,RcstarWinter,Vwinitial,Rcdecs[j],Rwdecs[j],p) & #,Vcstates)[i,j] & 
                 #        Vwstates==OutgoingVw(S, Vwinitial, Rwdecs[j],p))) #match Vw and Vc in LookupV table
 
# }
    fstarvalue[j]=ifelse(is.na(fs[j]), -9999, ifelse(fs[j]<0, -9999, fstar[fs[j],(S+1)])) #get the fstar from t+1 with the matching Vw and Vc states
 #   print(test)
    }
  return(fstarvalue) #produces a matrix of fstartt+1 values to accumulate in the benefit function, looking backwards
}

#######
##DP model
######

####a. last stage
#p=0.5
S=NoofStages
##############
  #for(S in 11:11){
month=monthcounter(S)

for(i in 1:pn){
  p=ystates[i]
  lastStage=matrix(choosesolve(month,VwSpace,VcSpace,Rcspace, Rwspace, Rspace,VSpace,RcstarWinter,K, DP,p)
                   ,nrow=length(Vcstates),ncol=length(Rdecs))
  #colnames(lastStage)=Rdecs
  #rownames(lastStage)=Vstates
  #  print(LastStage) checking results
  allstages[,,i,S]=lastStage
  #print(allstages[,,i,S])
}
LastStage=#ifelse(obj==11, 
  (allstages[,,1,S]+allstages[,,2,S]+allstages[,,3,S]+allstages[,,4,S]+allstages[,,5,S])/pn #,

#  print(LastStage) checking results
#store data
fstar[,S]=ifelse(apply(LastStage,1,max, na.rm=TRUE)<0, -9999, apply(LastStage,1,max, na.rm=TRUE))
whichxstar[,S]=apply(LastStage,1,which.max) 
Rcstar[,S]=ifelse(fstar[,S]<0, -9999, Rcdecs[whichxstar[,S]])
Rwstar[,S]=ifelse(fstar[,S]<0, -9999, Rwdecs[whichxstar[,S]])
Rstar=Rcstar+Rwstar
 # }

#####################
####b. intermediate stage
#####################
for(S in (NoofStages-1):2){
  month=monthcounter(S)
  for(i in 1:pn){
    p=ystates[i]
    currentB=matrix(choosesolve(month,VwSpace,VcSpace,Rcspace, Rwspace, Rspace,VSpace,RcstarWinter,K, DP,p),
                  nrow=length(Vstates),ncol=length(Rdecs))
    fs=matrix(0,nrow=length(Vstates),ncol=length(Rdecs))
    fstarvalue=matrix(0,nrow=length(Vstates),ncol=length(Rdecs))
  accumB=matrix(accumulate(month,S,Vcstates,Vwstates,VcSpace,RcstarWinter,VwSpace,Rcspace,Rwspace,VSpace,Rspace,p),
                    nrow=length(Vstates),ncol=length(Rdecs))
  intstage=pmin(currentB, accumB)
  
  ##get Rcstar
  #if choose accumulate then need to pick R from accumulate not choose, unless R is infeasible from accumulate (in which case use R from choose)
  isaccum=ifelse(intstage<currentB, 1, NA)
  
  ##get Rc_t+1
  
  #1. get Vc and Vw out for this S
  Vcoutdirect=matrix(OutgoingVc(S,VcSpace, RcstarWinter,VwSpace,Rcspace,Rwspace,p),nrow=length(Vstates),ncol=length(Rdecs)) #gets end period storage VC
  Vwoutdirect=matrix(OutgoingVw(S,VwSpace,Rwspace,p),nrow=length(Vstates),ncol=length(Rdecs)) #gets end period storage Vw

  #2. get Rc_t+1 for those combinations for which accB < direct B
      #rule out infeasible outs with directR
  Rcaccumstar=matrix(0,nrow=length(Vstates),ncol=length(Rdecs))
  Rwaccumstar=matrix(0,nrow=length(Vstates),ncol=length(Rdecs))
  
   #lookup Rc_t+1 for each x based on its start of period storage ==current period end of storage (Vc and Vw out), only for feasible R_t+1 options
  for (r in 1:length(Rdecs)){
    for (v in 1:length(Vstates)){
      Rcaccumstar[v,r]=ifelse(is.na(isaccum[v,r]), NA, 
                              Rcstar[which(Vcstates==Vcoutdirect[v,r] & Vwstates==Vwoutdirect[v,r]),S+1]
      )
      Rwaccumstar[v,r]=ifelse(is.na(isaccum[v,r]), NA, 
                              Rwstar[which(Vcstates==Vcoutdirect[v,r] & Vwstates==Vwoutdirect[v,r]),S+1]
      )
    }
  }
  #colnames(Rcaccumstar)=Rcdecs
  #colnames(Rwaccumstar)=Rwdecs
  
  #3. use R direct t if R acc t+1 is infeasible
  Vcoutacc=matrix(OutgoingVc(S, VcSpace,0,VwSpace,Rcaccumstar,Rwspace,p),nrow=length(Vstates),ncol=length(Rdecs))
  Vwoutacc=matrix(OutgoingVw(S,VwSpace,Rwaccumstar,p),nrow=length(Vstates),ncol=length(Rdecs))
  Voutacc=ifelse(Vcoutacc<0, NA,
                 ifelse(Vwoutacc<0, NA,
                        Vcoutacc+Vwoutacc))
  
  #4. is R acc infeasible
  feasibleRcac=ifelse(Vcoutacc<Rcspace, NA,
                      ifelse(Vwoutacc<Rwspace,NA, 
                             ifelse(Voutacc > K | Voutacc <DP, NA, 
                                    Rcaccumstar)))
  feasibleRwac=ifelse(Vcoutacc<Rcspace, NA,
                      ifelse(Vwoutacc<Rwspace,NA, 
                             ifelse(Voutacc > K | Voutacc <DP, NA, 
                                    Rwaccumstar)))
  feasibleR=feasibleRcac*feasibleRwac
  
  #5. get final R
  finalRc=ifelse(is.na(feasibleRcac),Rcspace, feasibleRcac)
  finalRw=ifelse(is.na(feasibleRwac),Rwspace, feasibleRwac)
  finalR=finalRc+finalRw
  
  ###get final x with final R
  finalx=matrix(choosesolve(month,VwSpace,VcSpace,finalRc,finalRw, finalR, VSpace, 0, K, DP, p),
                nrow=length(Vstates),ncol=length(Rdecs))
  
  allstages[,,i,S]=finalx
  #print(head(allstages[,,i,S]))[,1:20]
  }
  onestage=(allstages[,,1,S]+allstages[,,2,S]+allstages[,,3,S]+allstages[,,4,S]+allstages[,,5,S])/pn 
  
  
 #store data
  fstar[,S]=ifelse(apply(onestage,1,max, na.rm=TRUE)<0, -9999, apply(onestage,1,max, na.rm=TRUE))
whichxstar[,S]=apply(onestage,1,which.max) 
  Rcstar[,S]=Rcdecs[whichxstar[,S]]
  Rwstar[,S]=Rwdecs[whichxstar[,S]]
}
########################
####c. first stage
#######################
S=1
month=monthcounter(S)
firststageholding=array(0, dim=c(1, #length(Vstates)==1
                                 length(Rdecs),
                                 pn)) #length(ystates)==pn
#1)) 
#dimnames(firststageholding)[[1]]=as.list(Vinitial)
#dimnames(firststageholding)[[2]]=as.list(Rdecs)
#dimnames(firststageholding)[[3]]=as.list(ystates)

for(i in 1:pn){
 p=ystates[i]
fs=vector(length=length(Rdecs))
fstarvalue=vector(length=length(Rdecs))
currentfirstB=matrix(choosesolve(month,Vwinitial, Vcinitial,Rcdecs, Rwdecs, Rdecs, Vinitial,RcstarWinter,K, DP,p),nrow=length(1),ncol=length(Rdecs))
accumfirstB=matrix(firststageaccumulate(month, S, Vcstates,Vwstates,Vcinitial,RcstarWinter,Vwinitial,Rcdecs,Rwdecs,Rdecs, Vinitial,p),
                   nrow=length(1), ncol=length(Rdecs))
firststageprep=matrix(pmin(currentfirstB,accumfirstB),nrow=length(1),ncol=length(Rdecs))
firststage=firststageprep

##get Rcstar
#if choose accumulate then need to pick R from accumulate not choose, unless R is infeasible from accumulate (in which case use R from choose)
isaccumfirst=ifelse(firststage<currentfirstB, 1, NA)

##get Rc_t+1

#1. get Vc and Vw out for this S
Vcoutdirectfirst=matrix(OutgoingVc(S,Vcinitial,RcstarWinter,Vwinitial,Rcdecs,Rwdecs,p),nrow=length(1),ncol=length(Rdecs)) #gets end period storage VC
Vwoutdirectfirst=matrix(OutgoingVw(S,Vwinitial,Rwdecs,p),nrow=length(1),ncol=length(Rdecs)) #gets end period storage Vw

#2. get Rc_t+1 for those combinations for which accB < direct B
#rule out infeasible outs with directR
Rcaccumstarfirst=matrix(0,nrow=length(1),ncol=length(Rdecs))
Rwaccumstarfirst=matrix(0,nrow=length(1),ncol=length(Rdecs))

#lookup Rc_t+1 for each x based on its start of period storage ==current period end of storage (Vc and Vw out), only for feasible R_t+1 options
for (r in 1:length(Rdecs)){
  for (v in 1:length(1)){
    Rcaccumstarfirst[v,r]=ifelse(is.na(isaccumfirst[v,r]), NA, 
                                 Rcstar[which(Vcstates==Vcoutdirectfirst[v,r] & Vwstates==Vwoutdirectfirst[v,r]),S+1]
    )
    Rwaccumstarfirst[v,r]=ifelse(is.na(isaccumfirst[v,r]), NA, 
                                 Rwstar[which(Vcstates==Vcoutdirectfirst[v,r] & Vwstates==Vwoutdirectfirst[v,r]),S+1]
    )
  }
}
#colnames(Rcaccumstarfirst)=Rcdecs
#colnames(Rwaccumstarfirst)=Rwdecs

#3. use R direct t if R acc t+1 is infeasible
Vcoutaccfirst=matrix(OutgoingVc(S, Vcinitial,0,Vwinitial,Rcaccumstarfirst,Rwdecs,p),nrow=length(1),ncol=length(Rdecs))
Vwoutaccfirst=matrix(OutgoingVw(S,Vwinitial,Rwaccumstarfirst,p),nrow=length(1),ncol=length(Rdecs))
Voutaccfirst=ifelse(Vcoutaccfirst<0, NA,
               ifelse(Vwoutaccfirst<0, NA,
                      Vcoutaccfirst+Vwoutaccfirst))

#4. is R acc infeasible
feasibleRcacfirst=ifelse(Vcoutaccfirst<Rcdecs, NA,
                    ifelse(Vwoutaccfirst<Rwdecs,NA, 
                           ifelse(Voutaccfirst > K | Voutaccfirst <DP, NA, 
                                  Rcaccumstarfirst)))
feasibleRwacfirst=ifelse(Vcoutaccfirst<Rcdecs, NA,
                    ifelse(Vwoutaccfirst<Rwdecs,NA, 
                           ifelse(Voutaccfirst > K | Voutaccfirst <DP, NA, 
                                  Rwaccumstarfirst)))
feasibleRfirst=feasibleRcacfirst*feasibleRwacfirst

#5. get final R
finalRcfirst=ifelse(is.na(feasibleRcacfirst),Rcdecs, feasibleRcacfirst)
finalRwfirst=ifelse(is.na(feasibleRwacfirst),Rwdecs, feasibleRwacfirst)
finalRfirst=finalRcfirst+finalRwfirst

###get final x with final R
finalxfirst=matrix(choosesolve(month,Vwinitial,Vcinitial,finalRcfirst,finalRwfirst, finalRfirst, Vinitial, 0, K, DP, p),nrow=length(1),ncol=length(Rdecs))
 #allstages[,,i,S]=firststageprep
firststageholding[,,i]=finalxfirst
}
firststage=(
  firststageholding[,,1]
  + firststageholding[,,2]+ firststageholding[,,3]+ firststageholding[,,4]+ firststageholding[,,5])/pn 
fstarone=ifelse(max(firststage)<=0, -9999, max(firststage))
whichxstarone=which.max(firststage) 
Rcstarone=ifelse(fstarone<0, -9999, Rcdecs[whichxstarone])
Rwstarone=ifelse(fstarone<0, -9999, Rwdecs[whichxstarone])
#Rwstar[,1]=Rwstarone
#Rcstar[,1]=Rcstarone
xstarone=matrix(choosesolve(month,Vwinitial, Vcinitial,finalRcfirst, finalRwfirst, finalR, Vinitial,RcstarWinter,K, DP,p))[whichxstarone]

#6. results
####a. best policy
Best=matrix(0,nrow=NoofStages,ncol=6)
colnames(Best)=c("Vc","Vw","Rc","Rw","x","month")
Best[1,]=c(Vcinitial, Vwinitial,Rcstarone,Rwstarone,xstarone,monthcounter(1))
for(S in 2:NoofStages){
  ###for Vc 
  month=monthcounter(S-1)
  rangeVc=vector()
  for(i in 1:pn){
    p=ystates[i]
    rangeVc[i]=OutgoingVcprep((S-1),as.numeric(Best[(S-1),1]), RcstarWinter, as.numeric(Best[(S-1),2]),as.numeric(Best[(S-1),3]), as.numeric(Best[(S-1),4]),p)
  }
  Best[S,1]=mround(sum(rangeVc)/pn,bin)
  ###for Vw
  rangeVw=vector()
  for(i in 1:pn){
    p=ystates[i]
    rangeVw[i]=OutgoingVwprep((S-1),as.numeric(Best[(S-1),2]), as.numeric(Best[(S-1),4]),p)
  }
  Best[S,2]=mround(sum(rangeVw)/pn,bin)
  #month=monthcounter(S)
  #plocation=3 #p=0.5 is the third value
  Best[S,3]=Rcstar[which(Vcstates==as.numeric(Best[S,1]) & Vwstates==as.numeric(Best[S,2])),S]
  Best[S,4]=Rwstar[which(Vcstates==as.numeric(Best[S,1]) & Vwstates==as.numeric(Best[S,2])),S]
  month=monthcounter(S)
  rangex=vector()
  for(i in 1:pn){
    p=ystates[i]
    rangex[i]=matrix(choosesolve(month,VwSpace,VcSpace,Rcspace, Rwspace, Rspace,VSpace,RcstarWinter,K, DP,p)
                     ,nrow=length(Vcstates),ncol=length(Rdecs))[which(Vcstates==as.numeric(Best[S,1]) & Vwstates==as.numeric(Best[S,2])),whichxstar[which(Vcstates==as.numeric(Best[S,1]) & Vwstates==as.numeric(Best[S,2])),S]]
    
    print(rangex[i])
  }
  Best[S,5]=sum(rangex)/pn
  Best[S,6]=monthcounter(S)
  print(S)
}
print(Best)
#write.csv(Best,"VariableTempRBDDToyxp01.csv")                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                 
#})

#file traken from 
#BASELINEBaselinePersistencev2cleanedDP_realdatav5wInflowsMONTHLYDPJaysdisplayUpdatedBenFxYearTypesv2
#jan 4 2018
##rewriting old code
#updating to run off several loopkup tables to reduce number of computations
#includes persistence functions
#could also re-write to run off different include files so that basic file is updated when choosing policies

#januar 29 2018
#rewriting lookup tables for V|R and improving efficiency of persistence constraint
#from DP_Code7VariableTempToy_persistencev4_EVv2
