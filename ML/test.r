library(data.table)

# Without data.table:
cry.A <- read.csv(
    'data/cry-A.csv',
    header = F,
    sep = ';',
    col.names = c('id', 'class', 'void'))

cry.A$void = NULL

cry.A <- data.table(cry.A)

# With data.table:
cry.B <- fread(
    'data/cry-B.csv',
    header = F,
    sep = ';',
    select = c(1, 2),
    col.names = c('id', 'class'))

setkey(cry.A, 'id')
setkey(cry.B, 'id')

cry.AB <- cry.A[cry.B]
setnames(cry.AB, c('id', 'A', 'B'))

cry.gs <- fread(
    'data/cry-gs.csv',
    header = F,
    sep = ';',
    col.names = c('id', 'class'),
    key = 'id')

cry.F1 <- fread(
    'data/cry-F1.csv',
    header = F,
    sep = ';',
    col.names = c('id', 'class'),
    key = 'id')

#setkey(cry.gs, 'id')

hist <- function (x) {
    barplot(
        table(cry.A$class),
        main = 'CRY\nAnnotated histogram',
        col = rainbow(5),
        ylim = c(0, max(table(cry.A$class)) + 10))
}

## Exercise A:

confusion <- table(cry.A$class, cry.B$class)
#table(cry.AB[, c(2, 3), with = F])

agreements <- sum(diag(confusion)) / sum(confusion)

chance_agreement <- sum(table(cry.A$class) * table(cry.B$class)) / nrow(cry.A)^2

kappa <- (agreements - chance_agreement) / (1 - chance_agreement)

## Exercise B:

confusionB <- table(cry.F1$class, cry.gs$class)

accuracy <- sum(diag(confusionB)) / nrow(cry.gs)

percentages <- confusionB / nrow(cry.gs)

percentagesCols <- confusionB / colSums(confusionB)

# Probability of errors?