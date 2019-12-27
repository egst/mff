library(ISLR)
library(rpart)
library(rpart.plot)

par(mfrow = c(2, 2))

split <- function (data, ratio = 0.5) {
    count       <- nrow(data)
    count.train <- floor(count * ratio)
    count.test  <- count - count.train
    set.seed(420)
    s <- sample(count)
    list(
        whole       = data,
        train       = data[s[1 : count.train], ],
        test        = data[s[(count.train + 1) : count], ],
        count       = count,
        count.train = count.train,
        count.test  = count.test,
        count.cols  = ncol(data))
}

mod <- function (x) names(sort(table(x), decreasing = T))[1]

cm   <- function (eval) table(eval)
tp   <- function (cm)   cm[1, 1]
tn   <- function (cm)   cm[2, 2]
fp   <- function (cm)   cm[1, 2]
fn   <- function (cm)   cm[2, 1]
acc  <- function (cm)   sum(diag(cm)) / sum(cm)
err  <- function (cm)   1 - acc(cm)
prec <- function (cm)   tp(cm) / (tp(cm) + fp(cm))
rec  <- function (cm)   tp(cm) / (tp(cm) + fn(cm))
spec <- function (cm)   tn(cm) / (tn(cm) + fp(cm))
fm   <- function (cm)   2 * (prec(cm) * rec(cm)) / (prec(cm) + rec(cm))

round. <- function (x) round(x, digits = 3)

######## 1.1 ###################################################################

message('\n## 1.1 results: ##')

linear <- lm(mpg ~ . - name, Auto)

print(summary(linear))

######## 1.2 ###################################################################

message('## 1.2 results: ##')

Auto <- Auto[order(Auto$acceleration), ]

#pdf('hw2/poly.pdf')
plot(Auto$acceleration, Auto$mpg, main = '1.2')

max.degree <- 5
colours <- (function (x) hsv(0.5, 0.7, x, 1))(seq(from = 0, to = 1, length.out = max.degree))

r.squared <- do.call(rbind.data.frame, lapply(1:max.degree, (function (i) {
    model <- lm(mpg ~ poly(acceleration, i), Auto)
    points(Auto$acceleration, predict(model), type = 'l', lwd = 4, col = colours[i])
    list(degree = i, r.squared = summary(model)$r.squared)
})))

legend('bottomright', legend = 1:max.degree, fill = colours)

message('\nPlots drawn.')

message('\nAssosiated R-squared values:')
print(round.(r.squared), row.names = F)

#dev.off()

######## 2.1 ###################################################################

median <- median(Auto$mpg)

d <- Auto[, -which(names(Auto) == 'mpg')]
d$mpg01 <- as.integer(Auto$mpg > median)

p.mpg01 <- table(d$mpg01) / nrow(d)

entropy.mpg01 <- -sum(p.mpg01 * log2(p.mpg01))

message('\n## 2.1 results:')

message('\nEntropy of mpg01:')
message(round.(entropy.mpg01))

######## 2.2 ###################################################################

d.split <- split(d, 0.8)

######## 2.3 ###################################################################

trivial <- mod(d.split$train$mpg01)

trivial.eval <- data.frame(
    prediction = rep(trivial, times = d.split$count.test),
    value      = d.split$test$mpg01)
trivial.cm   <- cm(trivial.eval)
trivial.acc  <- acc(trivial.cm)

message('\n## 2.3 results: ##')
message('\nTrivial predicted value:')
message(trivial)
message('\nAccuracy of the trivial classifier:')
message(round.(trivial.acc))

######## 2.4 ###################################################################

logistic <- glm(mpg01 ~ . - name, data = d.split$train, family = binomial)
logistic$xlevels[["name"]] <- levels(d.split$test$name)
logistic.predict <- function (data, threshhold)
    as.integer(predict(logistic, type = 'response', newdata = data) > threshhold)

logistic.5.eval.train <- data.frame(
    prediction = logistic.predict(d.split$train, 0.5),
    value      = d.split$train$mpg01)
logistic.5.cm.train   <- cm(logistic.5.eval.train)
logistic.5.err.train  <- err(logistic.5.cm.train)

logistic.5.eval <- data.frame(
    prediction = logistic.predict(d.split$test, 0.5),
    value      = d.split$test$mpg01)
logistic.5.cm   <- cm(logistic.5.eval)
logistic.5.err  <- err(logistic.5.cm)
logistic.5.prec <- prec(logistic.5.cm)
logistic.5.rec  <- rec(logistic.5.cm)
logistic.5.spec <- spec(logistic.5.cm)
logistic.5.fm   <- fm(logistic.5.cm)

message('\n## 2.4 results: ##')
message('\nTraining error rate:')
message(round.(logistic.5.err.train))
message('\nTesting confusion matrix:')
print(logistic.5.cm)
message('\nTesting error rate:')
message(round.(logistic.5.err))
message('\nTesting sensitivity:')
message(round.(logistic.5.rec))
message('\nTesting specificity:')
message(round.(logistic.5.spec))

######## 2.5 ###################################################################

logistic.1.eval <- data.frame(
    prediction = logistic.predict(d.split$test, 0.1),
    value      = d.split$test$mpg01)
logistic.1.cm   <- cm(logistic.1.eval)
logistic.1.prec <- prec(logistic.1.cm)
logistic.1.rec  <- rec(logistic.1.cm)
logistic.1.fm   <- fm(logistic.1.cm)

logistic.9.eval <- data.frame(
    prediction = logistic.predict(d.split$test, 0.9),
    value      = d.split$test$mpg01)
logistic.9.cm   <- cm(logistic.9.eval)
logistic.9.prec <- prec(logistic.9.cm)
logistic.9.rec  <- rec(logistic.9.cm)
logistic.9.fm   <- fm(logistic.9.cm)

cm.all <- cbind(logistic.1.cm, logistic.5.cm, logistic.9.cm)
attr(cm.all, 'dimnames')[2][[1]] <- c('0.1:  0', '1', '| 0.5:  0', '1', '| 0.9:  0', '1')

prec.all <- as.data.frame(cbind('0.1' = logistic.1.prec, '0.5' = logistic.5.prec, '0.9' = logistic.9.prec))
rec.all  <- as.data.frame(cbind('0.1' = logistic.1.rec,  '0.5' = logistic.5.rec,  '0.9' = logistic.9.rec))
fm.all   <- as.data.frame(cbind('0.1' = logistic.1.fm,   '0.5' = logistic.5.fm,   '0.9' = logistic.9.fm))

message('\n## 2.5 results: ##')
message('\nConfusion matrices:')
print(round.(cm.all))

message('\nPrecision:')
print(round.(prec.all), row.names = F)
message('\nSensitivity:')
print(round.(rec.all), row.names = F)
message('\nF-meassure:')
print(round.(fm.all), row.names = F)

######## 2.6 ###################################################################

make.tree <- function (cp = 0.01) {
    model <- rpart(mpg01 ~ . - name, d.split$train, method = 'class', cp = cp, model = T)

    eval.train <- data.frame(
        prediction = predict(model, newdata = d.split$train, type = 'class'),
        value      = d.split$train$mpg01)
    eval.test <- data.frame(
        prediction = predict(model, newdata = d.split$test, type = 'class'),
        value      = d.split$test$mpg01)

    cm.train <- table(eval.train)
    cm.test  <- table(eval.test)

    list(
        model     = model,
        cm.train  = cm.train,
        cm.test   = cm.test,
        err.train = err(cm.train),
        err.test  = err(cm.test))
}

get.best.cp <- function (model) {
    cp  <- as.data.frame(model$cp)
    min <- cp[order(cp$xerror), ][1, ]
    cp[cp$xerror <= min$xerror + min$xstd, 'CP'][1]
}

cp.performance <- function (cp = 0.01) tree.performance(make.tree(cp))

tree.performance <- function (tree)
    data.frame(
        err.train = err(tree$cm.train),
        err.test  = err(tree$cm.test),
        acc.train = acc(tree$cm.train),
        acc.test  = acc(tree$cm.test))

tree.01 <- make.tree(0.01)

tree.01.performance <- tree.performance(tree.01)

best.cp   <- get.best.cp(tree.01$model)
tree.best <- make.tree(best.cp)

tree.best.performance <- tree.performance(tree.best)

cps <- seq(from = 0.01, to = 0.1, by = 0.01)
performances <- do.call(rbind, lapply(cps, cp.performance))
rownames(performances) = cps

#pdf('hw2/tree.01.pdf')
rpart.plot(tree.01$model)
#dev.off()
#pdf('hw2/tree.best.pdf')
rpart.plot(tree.best$model)
#dev.off()
#pdf('hw2/tree.cp.pdf')
plotcp(tree.01$model)
#dev.off()

message('\n## 2.6 results: ##')
message('\nTree with cp = 0.01 performance:')
print(round.(tree.01.performance), row.names = F)
message('\nTree with the "best" cp performance:')
print(round.(tree.best.performance), row.names = F)
message('\nThe "best" cp:')
message(round.(best.cp))
message('\nPerformance of trees with cp from 0.01 to 0.1:')
print(performances)
message('\nCross-validation errors for different cp values:')
print(tree.01$model$cp, row.names = F)

#dev.off()