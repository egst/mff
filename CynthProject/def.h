// FFTW interface:
typedef int fftw_plan;
int FFTW_FORWARD  = 0;
int FFTW_BACKWARD = 0;
int FFTW_MEASURE  = 0;
int fftw_plan_dft_1d (int, void*, void*, int, int);
void fftw_execute (fftw_plan);
void fftw_destroy_plan (fftw_plan);

typedef unsigned char bool;
bool false = 0;
bool true  = 1;

typedef float              floating;
typedef unsigned long long integral;

typedef floating (*func) (integral);

typedef floating complex[2];
typedef complex  dft_space[dft_size];

struct cache {
    integral begin;
    bool     computed;
    floating buffer[overlap_step];
};

// Setup:
const integral sample_rate  = 44000;
const integral filter_order = 257;   // should be a power of 2 + 1
const integral overlap      = 256;   // filter_order - 1
const integral dft_size     = 1024;  // 4 * overlap
const integral overlap_step = 768;   // dft_size - overlap