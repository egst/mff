#include "def.h"

// Predefined:
inline floating lowpass (floating, integral);
inline floating saw	(integral);

/* User defined: */
// Objects generated for user-defined entries are named with __[name] postfix,
// where name is the name given by the user.

/*
    Example of the configuration:

    filter = lowpass 800
    signal = sin

    filtered = signal | filter
*/

// User defines a filter function "filter" and a simple oscillator function "oscillator":
inline floating func__filter	 (integral f) { return lowpass(800, f); }
inline floating func__oscillator (integral t) { return saw(t); }

// User defines a function "filtered" - a convolution of filter and oscillator.
// The provided convolution operation is asymetric - it assumes one signal
// is a filter and the other is the input signal to be filtered.

// Space for the dft and fftw plan is allocated:
dft_space dft_input__filtered;
dft_space dft_filter__filtered;
fftw_plan fftw_plan_input__filtered;
fftw_plan fftw_plan_inverse__filtered;
fftw_plan fftw_plan_filter__filtered;
// The fftw plans are created and destroyed with functions defined below.
// The filter dft is precomputed with a function defined below.

// The whole function then periodically computes a buffer of the convolved signal:
inline floating func__filtered (integral t) {
    static struct cache computed;
    if (!computed.computed || t < computed.begin || t >= computed.begin + overlap_step) {
        // X = dft(x):
        for (int i = t - filter_order; i < t - filter_order + dft_size; ++i)
            dft_input__filtered[i][0] = func__oscillator(i);
        fftw_execute(fftw_plan_input__filtered);
        // X' = X <*> H:
        for (int i = 0; i < dft_size; ++i) {
            dft_input__filtered[i][0] = dft_input__filtered[i][0] * dft_filter__filtered[i][0];
            dft_input__filtered[i][1] = dft_input__filtered[i][1] * dft_filter__filtered[i][1];
        }
        // Y = idft(X'):
        fftw_execute(fftw_plan_inverse__filtered);
        for (int i = t; i < overlap_step; ++i) {
            computed.buffer[i] = dft_input__filtered[i + overlap_step][0];
        }
        computed.computed = true;
    }
    return computed.buffer[t - computed.begin];
}

inline floating func__filtered (integral t) {
	floating result = -1;
	for (int i = 0; i < filter_order; )
		func__filtered(t - filter_order);
}

// Precomputed dfts:
void compute_dfts () {
    for (int i = 0; i < filter_order; ++i)
	dft_filter__filtered[i][0] = func__filter(i);
    fftw_execute(fftw_plan_filter__filtered);
    // ...
}

void fftw_create_plans () {
    fftw_plan_input__filtered	= fftw_plan_dft_1d(dft_size, dft_input__filtered,  dft_input__filtered,  FFTW_FORWARD,	FFTW_MEASURE);
    fftw_plan_inverse__filtered = fftw_plan_dft_1d(dft_size, dft_input__filtered,  dft_input__filtered,  FFTW_BACKWARD, FFTW_MEASURE);
    fftw_plan_filter__filtered	= fftw_plan_dft_1d(dft_size, dft_filter__filtered, dft_filter__filtered, FFTW_FORWARD,	FFTW_MEASURE);
    // ...
}

void fftw_destroy_plans () {
    fftw_destroy_plan(fftw_plan_input__filtered);
    fftw_destroy_plan(fftw_plan_inverse__filtered);
    fftw_destroy_plan(fftw_plan_filter__filtered);
    // ...
}

/*
    Overlap-save method:

    dft     discrete fourier transform with N = sft_size
    idft    iverse discrete fourier transform with N = sft_size
    x	    input signal
    H	    dft of filter impulse response padded with zeros
    y	    convolved signal
    <*>     member-wise multiplication

    for pos in range(0, inf, overlap_step):
	y[pos, pos + overlap_step] =
	    idft(dft(x[pos - filter_order, pos - filter_order + dft_size]) <*> H)[filter_order, dft_size]
*/
