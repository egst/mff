#pragma once

#include "type_config.hpp"

#include <cstddef>
#include <array>
#include <algorithm>
#include <stdexcept>

namespace cynth::bytewise {

    enum class endianness { big, little };

    constexpr endianness system_endianness ();
    constexpr std::size_t system_word_size ();

    template <typename T> T switch_endianness (T);

    template <typename T>
    byte_t at (T, std::size_t);
    template <std::size_t, typename T>
    byte_t at (T);

    template <typename, typename, typename = void> struct match_constness;
    template <typename T, typename U>
    struct match_constness<T, U, std::enable_if_t<!std::is_const<T>::value>> { using type = U; };
    template <typename T, typename U>
    struct match_constness<T, U, std::enable_if_t<std::is_const<T>::value>> { using type = const U; };
    template <typename T, typename U>
    using match_constness_t = typename match_constness<T, U, void>::type;

    template <typename T>
    class byte_view: public std::array<match_constness_t<T, byte_t>, sizeof(T) / sizeof(byte_t)> {
        //using base_t = std::array<match_constness_t<T, byte_t>, sizeof(T) / sizeof(byte_t)>;
        //using base_t::array;
    };

    template <typename T>
    match_constness_t<T, byte_view<T>> bytes (T&);

    constexpr std::int_least64_t  int_limit      (std::size_t);
    constexpr std::uint_least64_t uint_limit     (std::size_t);
    constexpr std::int_least64_t  bit_int_limit  (std::size_t);
    constexpr std::uint_least64_t bit_uint_limit (std::size_t);

}

namespace cynth {

    using bytewise::endianness;

    const char* show (endianness e);

}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

namespace cynth::bytewise {

    template <typename T>
    match_constness_t<T, byte_view<T>> bytes (T& val) {
        static_assert(sizeof(byte_view<T>) == sizeof(T), "cynth::bytewise::byte_view implementation failed to match the required type size.");
        return *reinterpret_cast<match_constness_t<T, byte_view<T>>*>(&val);
    }

    constexpr endianness system_endianness () {
        std::uint16_t x = 0x0102;
        return reinterpret_cast<byte_t*>(&x)[0] == 1 ? endianness::big : endianness::little;
    }

    template <typename T>
    T switch_endianness (T val) {
        std::reverse(bytes(val).begin(), bytes(val).end());
        return val;
    }

    template <typename T>
    byte_t at (T val, std::size_t i) {
        if (i >= sizeof(T) || i < 0)
            throw std::range_error{"Index for cynth::bitwise_tools::at out of range."};
        return bytes(val)[i];
    }

    template <std::size_t I, typename T>
    byte_t at (T val) {
        static_assert(I < sizeof(T) && I >= 0, "Index for cynth::bitwise_tools::at out of range.");
        return bytes(val)[I];
    }

    constexpr std::int_least64_t int_limit (std::size_t bytes) {
        return (static_cast<std::int_least64_t>(1) << (bytes * 8 - 1)) - 1;
    }
    constexpr std::uint_least64_t uint_limit (std::size_t bytes) {
        return (static_cast<std::uint_least64_t>(1) << (bytes * 8)) - 1;
    }
    constexpr std::int_least64_t bit_int_limit (std::size_t bits) {
        return (static_cast<std::int_least64_t>(1) << (bits - 1)) - 1;
    }
    constexpr std::uint_least64_t bit_uint_limit (std::size_t bits) {
        return (static_cast<std::uint_least64_t>(1) << bits) - 1;
    }

}

namespace cynth {

    const char* show (endianness e) {
        if (e == endianness::big)
            return "big endian";
        if (e == endianness::little)
            return "little endian";
        throw std::domain_error{"Invalid endianness value."};
    }

}