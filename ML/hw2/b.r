
model <- lm(mpg ~. -name, Auto)
message("1.1 results:")
print(summary(model))

