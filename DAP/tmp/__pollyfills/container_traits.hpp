#pragma once

#include "detector.hpp"

namespace stdp {

    namespace ops {
        template <typename T>
        using begin_t = decltype(std::begin(std::declval<T>()));
        template <typename T>
        using end_t = decltype(std::end(std::declval<T>()));
        template <typename T, typename U>
        using swap_t = decltype(std::swap(std::declval<T>(), std::declval<U>()));
    }

}