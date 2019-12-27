# Machine learning

A computer program is said to learn from **experience** E with respect to some **class of tasks** T and **performance measure** P, if its performance at tasks in T, as measured by P, improves with experience E.

**Feature vector** is a list of **features** characterizing an **object** (e.g. a sentence). **Features** (attributes) are context clues in the object.

**Example** is a feature vector + output value.

**Data instance** is a feature vector or a complete example.

## Supervised machine learning

Learning essential knowledge extracted from a large set of examples.

> training examples $\xrightarrow\text{machine learning}$ **predictor** (trained model representing the learned knowledge)
>
> real world object $\xrightarrow\text{feature extraction}$ feature vectors ( $x_i$ ) $\xrightarrow\text{predictor}$ output (target, response) values (class) - predictions ( $\hat{y}_i$ )
>
> real world object $\xrightarrow\text{true prediction}$ output values - true predictions ( $y_i$ )

* For continious output values: **regression** - estimating / predicting a continuous response.

* For discrete / categorical output values: **classification** - identifying group membership.

**Learning process**: Searching the **hypothesis space** of hypotheses $\hat{f}$ for the "best" hypothesis $\hat{f}^*$ and minimizing a loss function.

Ideal result: $\hat{y}_i = \hat{f}^*(x_i) = y_i$

**Loss function** (cost function): $L(\hat{y}, y)$

* For regression: **squared loss** $L(\hat{y}, y) = (\hat{y} - y)^2$
* For classification: **zero-one loss** $L(\hat{y}, y) = I(\hat{y} \ne y)$

The goal is to minimize the average $L(\hat{y}, y)$ over all examples.

The set of all examples is randomly split into **training data** (used for the learning process) and **testing data** (used for evaluation of the training model).

**Learning parameters** (hyperparameters): Parameters of a learning algorithm.

**Hypothesis parameters**: Parameters of a prediction function.

**Method**: Approach to learning - to building predictors.

**Model**: Method + set of features + learning parameters.

**Predictor**: Trained model - an output of the machine learning process (particular method trained on a particular training data).

**Prediction function**: (= predictor) A function calculating a response value using predictor variables.

**Hypothesis**: = prediction function


