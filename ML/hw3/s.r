### dataset data.d (Caravan from ISLR)
##  5822 samples
##  86 attributes:
##   1-43: sociodemographic data
##  44-85: product ownership
##  86 (Purchase): purchase of caravan insurance policy

library(ISLR)
data.d <- Caravan
size.d <- nrow(data.d)

### subset data.d.train
##  4822 samples from data.d
### subset data.d.test
##  1000 samples from data.d

size.test  <- 1000
size.train <- size.d - 1000
set.seed(420)
s <- sample(size.d)
data.d.train <- data.d[s[1 : size.test], ]
data.d.train <- data.d[s[(size.test + 1) : size.d], ]

### dataset data.t - blind test
##  1000 samples
##  attributes 1-85 from Caravan (without Purchase)

data.t <- read.csv(url('https://ufal.mff.cuni.cz/~holub/2019/docs/caravan.test.1000.csv'), sep = '\t')
size.t <- nrow(data.t)

### Task 1 - data analysis

##  TODO: First, check the distribution of the target attribute. What would be your precision if you select 100 examples by chance?

##  1.a

perc.purchase <- function (attr) {
    count.attr          <- table(data.d[, attr])
    count.attr.purchase <- table(data.d[, c(attr, 'Purchase')])[, 'Yes']
    perc.attr.purchase  <- count.attr.purchase / count.attr
}
perc.maintype.purchase <- perc.purchase('MOSHOOFD')
perc.subtype.purchase  <- perc.purchase('MOSTYPE')

##  1.b - TODO: Analyze the relationship between features MOSHOOFD and MOSTYPE.

