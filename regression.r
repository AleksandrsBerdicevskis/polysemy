#Read in data
adjs <- read.csv("adjectives.csv", sep="\t",header=TRUE)
adjs$pos = "adj"
verbs <- read.csv("verbs.csv", sep="\t",header=TRUE)
verbs$pos = "verb"
nouns <- read.csv("nouns.csv", sep="\t",header=TRUE)
nouns$pos = "noun"

#Merge
allpos <- rbind(adjs, verbs, nouns)

#All entries that have entries dated earlier than 951 seem to be errors
allpos <- allpos[allpos$year >=951,]

#Code categorica predictors as factors
allpos$pos <- as.factor(allpos$pos)
allpos$freq <- as.factor(allpos$freq)

#Applying Helmert coding to frequency
contrasts(allpos$freq) <- contr.helmert(7)

#Set intercept to 1
allpos$year2 <- allpos$year - 950

#Fit the Poisson model
myf <- glm(nmeanings ~ year2*freq*pos, family = "poisson", data = allpos)
print(summary(myf))

#Look at the residuals
plot(fitted(myf),residuals(myf))

