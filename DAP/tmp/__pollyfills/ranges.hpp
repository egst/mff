#pragma once

#include <type_traits>

#include "detector.hpp"
#include "container_traits.hpp"

namespace ranges {

    /** Range concept: **/
    template <typename T> constexpr bool range = is_range<T>::value;

    /** View concept: **/
    template <typename T> constexpr bool view = is_view<T>::value;

    /** Helpers: **************************************************************/

    template <typename T>
    using are_swappable = is_detected<ops::swap_t, T, T>;

    template <typename T, typename U>
    using is_assignable_from = is_detected<ops::assignment_t, T, U>;

    template <typename T>
    using is_movable = std::conjunction<
        std::is_object<T>,
        std::is_move_constructible<T>,
        is_assignable_from<T&, T>,
        are_swappable<T, T>>;

    template <typename T>
    using is_copyable = std::conjunction<
        std::is_copy_constructible<T>,
        is_movable<T>,
        is_assignable_from<T&, const T&>>;

    template <typename T>
    using is_semiregular = std::conjunction<
        is_copyable<T>,
        std::is_default_constructible<T>>;

    template <typename T, template <typename...> typename U>
    struct is_specialization_of: std::false_type {};
    
    template <template <typename...> typename U, typename... Args>
    struct is_specialization_of<U<Args...>, U>: std::true_type {};

    template <typename T>
    using enable_view = std::conditional<
        std::derived_from<T, view_base>,
        std::true_type,
        std::conditional<
            std::disjunction<
                is_specialization_of<T, std::initializer_list>,
                is_specialization_of<T, std::set>,
                is_specialization_of<T, std::multiset>,
                is_specialization_of<T, std::unordered_set>,
                is_specialization_of<T, std::unordered_multiset>,
                is_specialization_of<T, std::match_results>
            >,
            std::false_type,
            std::conditional<
                std::conjunction<
                    is_range<T>,
                    is_range<const T>,
                    
                >,
                std::false_type,
                std::true_type
            >
        >;

    template <typename T>
    using is_range = std::conjunction<
        is_detected<ops::begin_t, T>,
        is_detected<ops::end_t, T>>;

    template <typename T>
    using is_view = std::conjunction<
        is_range<T>,
        is_semiregular<T>,
        enable_view<T>>;

}