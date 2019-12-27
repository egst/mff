#pragma once

#include <type_traits>

namespace stdp {

    namespace ops {
        template <typename T, typename U>
        using assignment_t = decltype(operator=(std::declval<T>(), std::declval<U>()));
        template <typename T, typename U>
        using construction_t = decltype(std::declval<T>{std::declval<U>()});
    }

    /*
     *  # Detector idiom
     * 
     *  An idiom that made it into std, but remains under experimental features.
     *  Provides a way to check whether an overload of the given operation
     *  is available for the given types.
     *  The operation (function, method, operator, ...) must be "embedded"
     *  in a type. For example:
     *      template <typename first_t, typename second_t>
     *      using addition_t = decltype(std::declval<first_t>() + std::declval<second_t>());
     *  Then it may be used in the detector as follows:
     *      template <typename first_t, typename second_t>
     *      using are_addable = is_detected<addition_t, first_t, second_t>;
     *  
     *  The implementation below is taken from cppreference.com.
     */
    // Detector, undetected case:
    template <
        typename default_t,
        typename always_void_t,
        template <typename...> typename operation_t,
        typename... operand_ts>
    struct detector {
        using value_t = std::false_type;
        using type = default_t;
    };
    // Detector, detected case:
    template <
        typename default_t,
        template <typename...> typename operation_t,
        typename... operand_ts>
    struct detector<
        default_t,
        std::void_t<operation_t<operand_ts...>>,
        operation_t,
        operand_ts...> {
            
        using value_t = std::true_type;
        using type = operation_t<operand_ts...>;
    };
    // Default type fallback:
    struct nonesuch_t {
        nonesuch_t(nonesuch_t const&) = delete;
        void operator=(nonesuch_t const&) = delete;
        ~nonesuch_t() = delete;
    };
    // ::value is true when detected, false otherwise:
    template <
        template<typename...> typename operation_t,
        typename... operand_ts>
    using is_detected = typename detector<nonesuch_t, void, operation_t, operand_ts...>::value_t;
    // Detected operation type or nonesuch_t:
    template <
        template<typename...> typename operation_t,
        typename... operand_ts>
    using detected_t = typename detector<nonesuch_t, void, operation_t, operand_ts...>::type;
    // Detected operation type or the given default_t:
    template <
        typename default_t,
        template<typename...> typename operation_t,
        typename... operand_ts>
    using detected_or = detector<default_t, void, operation_t, operand_ts...>;
}