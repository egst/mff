library(ISLR)
library(class)

Caravan$Purchase <- as.numeric(Caravan$Purchase)

count <- nrow(Caravan)
count.train <- count / 2
count.test  <- count - count.train

set.seed(420)
s       <- sample(count)
s.train <- s[1 : count.train]
s.test  <- s[(count.train + 1) : count]

caravan.train <- Caravan[s.train, ]
caravan.test  <- Caravan[s.test, ]

t <- table(caravan.train[, 86])
prediction <- names(t[which.max(t)])

#model      <- rpart(..., carvan.train)
#prediction <- predict(model, caravan.test, type = 'class')

mfc.cm   <- table(rep(prediction, count.test), caravan.test[, 86])
mfc.acc  <- sum(diag(mfc.cm)) / (count / 2)
#mfc.prec <- mfc.cm['Yes', 'Yes'] / sum(mfc.cm[, 'Yes'])
#mfc.rec  <- mfc.cm['Yes', 'Yes'] / sum(mfc.cm['Yes', ])


log <- glm(Purchase ~ ., data = caravan.train)#, type = 'response')
log.probs <- predict(log, caravan.test, type = 'response')



pdf('plot.pdf')
#...
dev.off()

