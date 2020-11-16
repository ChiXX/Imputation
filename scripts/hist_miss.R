indmiss<-read.table(file="plink.imiss", header=TRUE)
snpmiss<-read.table(file="plink.lmiss", header=TRUE)
# read data into R 

png("histimiss.png", bg="transparent") #indicates png format and gives title to file
hist(indmiss[,6],main="Histogram individual missingness") #selects column 6, names header of file

png("histlmiss.png", bg="transparent") 
hist(snpmiss[,5],main="Histogram SNP missingness")  
dev.off() # shuts down the current device
