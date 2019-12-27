## probability, conditional probability, statistical independence

## simple statistical data analysis: expected values, variation, correlation, median, quantiles

EX = sum x_i * P(x_i)

var(X) = E((X - EX)^2) = E(X^2) - (EX)^2

cov(X, Y) = E((X - EX) * (Y - EY)) = E(XY) - EX * EY

corr(X, Y) = cov(X, Y) / sqrt(var(X) * var(Y))
for independent X, Y: corr(X, Y) = 0

## confusion matrices, inter-annotator agreement

probability of random agreement:
sum prod P(a chooses c) for each class c, for each annotator a
(P((Ao & Bo) | (A- & B-)) = P(Ao) * P(Bo) + P(A-) * P(B-))

Cohen's kappa: (agreement - chance agreement) / (1 - chance agreement)

## classifier evaluation

sample accuracy:   correct predictions / all predictions
sample error rate: 1 - accuracy

for binary classification:
precision:          TP / TP+FP (predicted positives)
recall/sensitivity: TP / TP+FN (actual positives)
specificity:        TN / TN+FP (actual negatives)
f-meassure:         2 * (prec * sens) / (prec + sens)

sample error:
regresion - mean square error (MSE): 1/n * sum (pred_i - truth_i)^2
classification error:                1/n * sum I(pred_i != truth_i)

generalization error (true/expected error):
regression:     E(pred_i - truth_i)^2
classification: P(pred_i != truth_i)
with respect to the distribution of the unseen data set.

## entropy, conditional entropy

ammount of information contained in an event, that occurs with probability p:
log_2 1/p = -log_2 1/p

entropy (H) - average ammount of information in random values:
-sum P(i) * log_2 1/P(i) for each random value i

max. entropy: H(1/n, 1/n, ..., 1/n)
min. entropy: 0

conditional entropy:
H(A|B) = -sum P(a, b) * log_2 P(a|b) for each a in A, b in B

mutual information (information gain):
I(A, B) = H(A) - H(A|B) = H(B) - H(B|A)

## majority voting for ensemble classifiers

n classifiers with success rate (accuracy) p
success of k classifiers is distributed binomially Bi(n, p)
P(k) = n chose k * p^k * (1-p)^(n-k)
majority voting means chosing at least ceil n/2 results over the rest
success of the majority vote is sum P(i) for i from ceil n/2 to n