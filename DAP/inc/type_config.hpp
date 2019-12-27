#pragma once

#include <cstddef>
#include <cstdint>
#include <atomic>

namespace cynth {

    using byte_t     = std::uint8_t;
    using unsigned_t = std::uint_least64_t;
    using signed_t   = std::int_least64_t;
    using floating_t = float;

    static_assert(std::atomic<unsigned_t>::is_always_lock_free);
    static_assert(std::atomic<signed_t>::is_always_lock_free);
    static_assert(std::atomic<floating_t>::is_always_lock_free);

}