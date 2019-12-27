#pragma once

#include "cstddef"

#include "bitwise_tools.hpp"

namespace cynth {
    
    class system {
    public:
        using endianness_t = bitwise_tools::endianness_t;

        constexpr static std::size_t  word_size  = sizeof(std::size_t);
        constexpr static endianness_t endianness = bitwise_tools::system_endianness();
    }

}