rm(list = ls())
library(parallel)
library(foreach)
library(pryr)

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

# Assigning causes no change to the original
# variable even though the address space is 
# initially the same. 
b <- 0
cl<-makePSOCKcluster(2)
clusterExport(cl, "b")

parSapply(cl, X = 1:10, function(x) {b <- b + 1; b})
# [1] 1 1 1 1 1 1 1 1 1 1
parSapply(cl, X = 1:10, function(x) {b <<- b + 1; b})
# [1] 1 2 3 4 5 1 2 3 4 5
b
stopCluster(cl)

cl<-makeForkCluster(2)
parSapply(cl, X = 1:10, function(x) {b <- b + 1; b})
#  [1] 1 1 1 1 1 1 1 1 1 1
parSapply(cl, X = 1:10, function(x) {b <<- b + 1; b})
# [1] 1 2 3 4 5 1 2 3 4 5
b
stopCluster(cl)

# Any assignment in R causes a change in address space
cl<-makeForkCluster(4)
out <- parLapply(cl, X = 1:4, function(x) {
  ret <- list(start = address(b))
  b <<- b + 1
  ret$b <- b
  ret$end_address <- address(b)
  as.data.frame(ret)})
do.call(rbind, out)
#       start b end_address
# 1 0x5ebe448 3   0x5d2e708
# 2 0x5ebe448 3   0x5d21478
# 3 0x5ebe448 3   0x5d16ab8
# 4 0x5ebe448 3   0x5d12c28
address(b)
# [1] "0x5ebe448"

###################
# Memory overload #
###################
rm(list=ls())
gc()
library(pryr)
library(magrittr)
a <- matrix(1, ncol=10^4*2, nrow=10^4)
object_size(a)

system.time(mean(a))
system.time(mean(a + 1))

system.time(sapply(1:8, function(x) mean(a + 1)))

library(parallel)
cl <- makeCluster(4, type = "PSOCK")
system.time(clusterExport(cl, "a"))
system.time(parSapply(cl, 1:8, function(x) mean(a + 1)))
stopCluster(cl)

gc()
cl <- makeCluster(4, type = "FORK")
system.time(parSapply(cl, 1:8, function(x) mean(a + 1)))
stopCluster(cl)

# Now crash the memory...
cl <- makeCluster(8, type = "PSOCK")
system.time(clusterExport(cl, "a"))
system.time(parSapply(cl, 1:8, function(x) mean(a + 1)))
stopCluster(cl); gc();

cl <- makeCluster(8, type = "FORK")
system.time(parSapply(cl, 1:8, function(x) mean(a + 1)))
stopCluster(cl)

# Fork does can't save you  now :-)
gc()
a <- matrix(1, ncol=10^4*2.1, nrow=10^4)
cl <- makeCluster(8, type = "FORK")
parSapply(cl, 1:8, function(x) {
  b <- a + 1
  mean(b)
  })
stopCluster(cl)
