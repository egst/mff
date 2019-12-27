plot.func <- function (from, to, gran, func) {
    int <- seq(from = from, to = to, by = gran)
    plot(int, lapply(int, func), type = 'l')
}

f <- function(x) 1.2 + (x - 2)^2 + 3.2

df <- function(x) 2.4 * (x - 2)

theta1 <- 0.1
alpha  <- 0.3
iter   <- 5

# theta_k+1 = theta_k - alpha f. (theta_k)
# theta_k = theta_k-1 - alpha f. (theta_k-1)

theta <- function (k)
    if (k == 1) {
        theta1
    } else {
        theta(k-1) - alpha * df(theta(k-1))
    }

thetas <- function (k) lapply(1:k, theta)

draw <- function () {
    plot.func(-0.5, 3, 0.01, f)
    lines(thetas(iter), sapply(thetas(iter), f), pch = 19, col = 'red', type = 'b')
}