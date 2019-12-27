library(data.table)

data <- read.csv(
    'data/xy.100.csv',
    sep = '\t',
)

marg.x <- table(data$x) / 100
marg.y <- table(data$y) / 100

joint <- table(data) / nrow(data)

cond.x.y <- table(data) / nrow(data) / c(p.y[0], p.y[1])

entr.x     <- -sum(marg.x * log2(marg.x))
entr.y     <- -sum(marg.y * log2(marg.y))
entr.x.max <- log2(3)
entr.y.max <- log2(2)

entr.joint     <- -sum(joint * log2(joint))
entr.joint.max <- log2(6)

# Pokud X a Y jsou stat. nezavisle => H(X) + H(Y) = H(X, Y)

# Vzajemna informace I(X; Y):

#vz <- sum(joint * log2(joint / (p.x * p.y)))

# -> H(X) - H(X|Y) = I(X;Y) = X(Y) - H(Y|X)

entr.cond.x.y = -sum(joint * log2(cond.x.y))
