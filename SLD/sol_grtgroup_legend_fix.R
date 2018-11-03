## fix legend
x = read.csv("~/Downloads/TAXOUSDA_GreatGroups_complete.csv", stringsAsFactors = FALSE)
summary(as.numeric(x$Count)>6)
x$sample = ifelse(as.numeric(x$Count)>6, x$X, NA)
xs = x[!is.na(x$sample),]
str(xs)
cat(paste(xs$SLD_code), file = "~/Downloads/sld.txt", sep = "\n")
