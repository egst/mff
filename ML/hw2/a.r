library(ISLR)

#plot.func <- function (f) plot(f(1:100), type = 'l')

# Divide data into learning and testing datasets:
divide <- function (data, ratio = 0.5) {
    count       <- nrow(data)
    count.train <- floor(count * ratio)
    count.test  <- count - count.train
    set.seed(420)
    s <- sample(count)
    list(           


        dddddd
        whole       = data,
        train       = data[s[1 : count.train], ],
        test        = data[s[(count.train + 1) : count], ],
        count       = count,
        count.train = count.train,
        count.test  = count.test,
        count.cols  = ncol(data))
}

# Initialize a linear regression predictor:
# (Expects data divided into training and testing datasets with divide().)
make.predictor <- function (data, output, input) {
    count.params <- length(input) + 1
    list(
        params     = rep(1, count.params),      # Initial parameters (theta) may be configured here.
        steps      = rep(0.000000001, count.params), # Step sizes (alpha) may be configured here.
        data.train = list(
            count  = data$count.train,
            output = data$train[, output],
            input  = data$train[, input]),
        data.test  = list(
            count  = data$count.test,
            output = data$test[, output],
            input  = data$test[, input]))
}

# Predict output for the given input vector:
#predict <- function (predictor, input)
#    sum(predictor$params * c(1, input))

# Calculate predictions for all entries in the given dataset (the training data by default).
get.predictions <- function (predictor, dataset = predictor$data.train)
    rowSums(t(predictor$params * t(cbind(1, dataset$input))))

# Calculate loss for the given dataset (the training data by default).
get.loss <- function (predictor, dataset = predictor$data.train)
    sum((get.predictions(predictor, dataset) - dataset$output)^2)

# Calculate gradient of the loss function for the given dataset (the training data by default.)
get.grad <- function (predictor, dataset = predictor$data.train)
    2 * colSums((get.predictions(predictor, dataset) - dataset$output) * cbind(1, dataset$input))

# Calculate normalized gradient of the loss function:
get.norm.grad <- function (predictor, dataset = predictor$data.train)
    get.grad(predictor, dataset) / dataset$count

# Perform one step of linear regression:
# Returns a new predictor.
train <- function (predictor, dataset = predictor$data.train, times = 1) {
    for (i in 1:times)
        predictor$params <- predictor$params - predictor$steps * get.norm.grad(predictor, dataset)
    predictor
}

################################################################################

#data <- data.frame( # The data
    #height = c( 120, 180, 150, 190, 175, 160 ),
    #age    = c(  10,  20,  30,  40,  50,  60 ),
    #sex    = c(   0,   0,   1,   0,   1,   0 ))

data <- divide(Auto)

predictor <- make.predictor(data, 'mpg', c('cylinders', 'displacement', 'horsepower', 'weight', 'acceleration', 'year', 'origin'))

get.predictions. <- function () cbind(get.predictions(predictor, predictor$data.test), predictor$data.test$output)

get.cm. <- function () table(get.predictions.())

################################################################################

model <- lm(mpg ~ . - name, Auto)
message('1.1 results:')
print(summary(model))

################################################################################

plot(Auto$acceleration, Auto$mpg)

attach(Auto)

cols <- c("blue", "orange", "red", "green", "pink")

labels <- c()

message("1.2 results:")
for(i in 1:5) {
    pmodel <- lm(mpg ~ poly(acceleration, i), Auto)
    labels[i] <- paste("Degree", i, "(R^2=", summary(pmodel)$r.squared, ")")

    message(labels[i])
    points(acceleration, predict(pmodel), type="l", lwd=5, col = cols[i])
}
message("")

legend("topright",
	labels,
	col = cols,
	lty = c(1,1,1),
	lwd = c(5,5,5))

detach(Auto)