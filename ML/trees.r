library(HSAUR)
library(rpart)
library(rpart.plot)

F <- Forbes2000

F$profits[is.na(F$profits)] <- 0
F$profits <- factor(F$profits > 0.2)

test <- function (c) {

    set.seed(123)
    s <- sample(2000)
    data.train <- s[1:c]
    data.test <- s[(c + 1):2000]

    # train:
    forbes.train <- F[data.train, 1:8]
    model <- rpart(profits ~ category + sales + assets + marketvalue, forbes.train)

    # evaluate:
    forbes.test <- F[data.test, 1:8]
    prediction <- predict(model, forbes.test, type = 'class')
    model.cm <- table(prediction, forbes.test$profits)
    model.acc <- sum(diag(model.cm)) / (2000 - c)

    #rpart.plot(model)
    print(model.acc)
    #printcp(model)

    model.acc
}

range <- seq(from = 800, to = 1800, by = 100)
plot(range, lapply(range, function (x) test(x)))
