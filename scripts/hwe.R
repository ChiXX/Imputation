hwe<-read.table (file="plink.hwe", header=TRUE)
png("histhwe.png", bg="transparent")
hist(hwe[,9],main="Histogram HWE")
dev.off()

hwe_zoom<-read.table (file="plinkzoomhwe.hwe", header=TRUE)
png("histhwe_below_theshold.png", bg="transparent")
hist(hwe_zoom[,9],main="Histogram HWE: strongly deviating SNPs only")
dev.off()
