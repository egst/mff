examples <- read.csv('hw1/mov.development.csv', sep = '\t')
examples$timestamp <- as.POSIXct(examples$timestamp, origin = '1970-01-01')

votes <- examples[, c(2, 1, 3, 4)]

users <- unique(examples[, c(2, 5:8)])
users <- users[order(users$user), ]

movies <- unique(examples[, c(1, 9:33)])

count.examples <- nrow(examples)
count.votes    <- nrow(votes)
count.users    <- nrow(users)
count.movies   <- nrow(movies)

## 1. conditional entropy H(occupation|rating) in examples ##

table.occup        <- table(examples$occupation)
table.rating       <- table(examples$rating)
#table.occup.rating <- table(examples[, c('occupation', 'rating')])
table.occup.rating <- table(examples[, c('rating', 'occupation')])

p_marg.occup  <- table.occup  / count.examples
p_marg.rating <- table.rating / count.examples

p_joint.occup.rating <- table.occup.rating   / count.examples
p_cond.occup.rating  <- p_joint.occup.rating / rep(p_marg.rating)

# result:
entr_cond.occup.rating <- -sum(p_joint.occup.rating * log2(p_cond.occup.rating))

message('\n## Conditional entropy:')
print(entr_cond.occup.rating)

## 2. boxplots of movie ratings ##

selected.votes  <- votes[unsplit(table(votes$movie), votes$movie) == 67, ]
table.votes     <- t(table(selected.votes[, c('movie', 'rating')]))
entries.votes   <- apply(table.votes, 2, function (x) rep(as.integer(names(x)), x))
avg.ratings     <- apply(entries.votes, 2, mean)

table.movie.title <- table(examples[, c(1, 9)])
movie.title       <- function (movie) colnames(table.movie.title)[table.movie.title[movie, ] != 0]

# result:
#pdf('hw1/boxplot.pdf')
par(mar = c(13, 2, 1, 1), cex.axis = 0.5)
boxplot(entries.votes, las = 2, names = lapply(colnames(entries.votes), movie.title))
points(avg.ratings, pch = 19, col = 'red')
#dev.off()

message('\n## Boxplot drawn.')

## 3. clusters ##

user.votes      <- table(merge(users, votes)[, c('user', 'rating')])
user.vote_freqs <- round(user.votes / replicate(5, rowSums(user.votes)), digits = 2)

users$one   <- user.vote_freqs[, 1]
users$two   <- user.vote_freqs[, 2]
users$three <- user.vote_freqs[, 3]
users$four  <- user.vote_freqs[, 4]
users$five  <- user.vote_freqs[, 5]

#users <- users[order(users$user), ]
rownames(users) <- users$user

age.rating <- users[, c('age', 'one', 'two', 'three', 'four', 'five')]

clusters <- hclust(dist(age.rating), method = "average")
clusters <- cutree(clusters, 20)

cluster.age <- data.frame(cluster = clusters, age = users$age)

# results:
result.count      <- table(clusters)
result.age        <- colSums(t(table(cluster.age)) * as.integer(rownames(t(table(cluster.age))))) / result.count
result.duplicates <- nrow(age.rating) != nrow(unique(age.rating))

message('\n## Number of users in each cluster:')
print(result.count)
message('\n## Average age in each cluster:')
print(result.age)
message('\n## Duplicates in the whole data set:')
print(result.duplicates)
