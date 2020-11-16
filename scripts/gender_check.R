gender <- read.table("plink.sexcheck", header=T,as.is=T)

png("Gender_check.png", bg="transparent")
hist(gender[,6],main="Gender", xlab="F")
dev.off()

png("Men_check.png", bg="transparent")
male=subset(gender, gender$F>0.8)
hist(male[,6],main="Men",xlab="F")
dev.off()

png("Women_check.png", bg="transparent")
female=subset(gender, gender$F<0.2)
hist(female[,6],main="Women",xlab="F")
dev.off()

