library(data.table)

examples <- read.csv('data/mov.development.csv', sep = '\t')

examples$timestamp <- as.POSIXct(examples$timestamp, origin = '1970-01-01')
names(examples)

## get votes
votes <- examples[, c(2, 1, 3, 4)]
names(votes)

## get users
u <- unique(examples[, c(2, 5:8)])
attach(u)
users <- u[order(user), ]
detach(u)
names(users)

## get movies
movies <- unique(examples[, c(1, 9:33)])
names(movies)

################################################################################

m <- movies[, c(4:21)]

