#pragma once

#include <type_traits>

namespace cynth::bitwise {

    template <typename T>
    constexpr T shar (T, int);

}

template <typename T>
constexpr T cynth::bitwise::shar (T n, int i) {
    if constexpr (std::is_unsigned<T>::value || (-1 >> 1) < 0)
        return n >> i;
    else if (n >= 0)
        return n >> i;
    else
        return (n >> i) | ~(static_cast<T>(-1) >> i);
}