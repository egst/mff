#pragma once

#include <cstdint>

namespace cynth::api::asio {

    template <typename T> const std::uint_least64_t& native_uint64   (const T&z);
    template <typename T> std::uint_least64_t&       native_uint64   (T&);
    template <typename T> const std::int_least64_t&  native_int64    (const T&);
    template <typename T> std::int_least64_t&        native_int64    (T&);
    template <typename T> floating_t                 native_floating (T);

}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

namespace cynth::api::asio {

    template <typename T>
    const std::uint_least64_t& native_uint64 (const T& aggr) {
        return *reinterpret_cast<const std::uint_least64_t*>(&aggr);
    }

    template <typename T>
    std::uint_least64_t& native_uint64 (T& aggr) {
        return *reinterpret_cast<std::uint_least64_t*>(&aggr);
    }

    template <typename T>
    const std::int_least64_t& native_int64 (const T& aggr) {
        return *reinterpret_cast<const std::int_least64_t*>(&aggr);
    }

    template <typename T>
    std::int_least64_t& native_int64 (T& aggr) {
        return *reinterpret_cast<std::int_least64_t*>(&aggr);
    }

    template <>
    floating_t native_floating (double from) {
        return static_cast<floating_t>(from);
    }

    template <typename T>
    floating_t native_floating (T aggr) {
        return aggr.lo + static_cast<floating_t>(aggr.hi) * (1ULL << 32);
    }

}