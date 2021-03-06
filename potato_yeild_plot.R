
if(!interactive()){
  postscript(file="potato_yeild_plot.ps")
  par(mar=c(5,5,4,2)+0.1)
  par(pty="s")
}

my.data <-
  read.csv("StatisticalData.0.csv", sep="\t")

my.data[,1:6]



my.years <-
  paste("X", 2000:2007, sep="")

col.index <-
  colnames(my.data) %in% my.years


my.data[,col.index]

my.result <-
  apply(my.data[,col.index], 1, mean)

colors()

barplot(my.result,
        col=c("yellow1", "sienna", "#FFF8C6", "wheat"),
        main="Yeild", ylab="Hg/Ha",
        names=c("Maize", "Potatoes", "Rice", "Wheat"),
        cex.axis=1.5, cex.lab=2.0, cex.names=2.0, cex.main=3.0
        )

