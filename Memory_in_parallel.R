library("parallel")
library("foreach")
library("doParallel")

library(pryr)
rm(list = ls())
no_cores <- detectCores()
a <- rnorm(10^7)
address(a)

cl<-makeCluster(no_cores)
clusterExport(cl, "a")
clusterEvalQ(cl, library(pryr))

parSapply(cl, X = 1:10, function(x) {address(a)}) == address(a)
# [1] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
stopCluster(cl)

cl<-makePSOCKcluster(no_cores)
clusterEvalQ(cl, library(pryr))
clusterExport(cl, "a")

parSapply(cl, X = 1:10, function(x) address(a)) == address(a)
# [1] FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE FALSE
stopCluster(cl)

cl<-makeForkCluster(no_cores)
parSapply(cl, X = 1:10, function(x) address(a)) == address(a)
# [1] TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE TRUE
stopCluster(cl)

