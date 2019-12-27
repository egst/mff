# Configuration language specification

```

# Constant definition:
const srate = 48000

# Nullary function definition:
freq = input "frequency"

# Unary function definition:
osc t = lfo t * sin (2 * pi * (freq / srate) * t)

# + - * / on values (constants, nullary functions and applied unary functions)

filter t = lowpass 200

# Convolution - on unary functions
out t = (osc | filter) t

# Implicit unary function definition:

foo t = sin t
foo = sin

bar t = (osc | filter) t
bar = osc | filter

```
