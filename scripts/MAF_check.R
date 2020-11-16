maf_freq <- read.table("MAF_check.frq", header =TRUE, as.is=T)
png("MAF_distribution.png", bg="transparent")
hist(maf_freq[,5],main = "MAF distribution", xlab = "MAF")
dev.off()


