#pragma once

#include <cstddef>
#include <iterator>

namespace cynth::iterators {

    template <typename Derived, typename ValueType, typename Reference = ValueType, typename Pointer = Reference>
    class random_access_iterator_base {
    public:
        using value_type        = ValueType;
        using reference         = Reference;
        using pointer           = Pointer;
        using difference_type   = std::ptrdiff_t;
        using iterator_category = std::random_access_iterator_tag;
        
        Derived  operator+  (std::size_t) const;
        Derived  operator-  (std::size_t) const;
        Derived& operator+= (std::size_t);
        Derived& operator-= (std::size_t);
        Derived& operator++ ();
        Derived  operator++ (int);

        difference_type operator-  (const Derived& other) const;
        difference_type operator<  (const Derived& other) const;
        difference_type operator>  (const Derived& other) const;
        difference_type operator<= (const Derived& other) const;
        difference_type operator>= (const Derived& other) const;
        difference_type operator== (const Derived& other) const;
        difference_type operator!= (const Derived& other) const;

        reference operator[] (std::size_t);
        reference operator[] (std::size_t) const;

    private:
        Derived&           derived ();
        const Derived&     derived () const;
        std::size_t&       pos     ();
        const std::size_t& pos     () const;
    };

    template <typename T>
    using is_rait_derived = std::is_base_of<
        cynth::iterators::random_access_iterator_base<T, typename T::value_type, typename T::reference, typename T::pointer>,
        T>;

}

template <typename Derived, typename = std::enable_if_t<cynth::iterators::is_rait_derived<Derived>::value>>
Derived operator+ (std::size_t, const Derived&);

template <typename Derived, typename = std::enable_if_t<cynth::iterators::is_rait_derived<Derived>::value>>
Derived operator- (std::size_t, const Derived&);

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

#define rait_free_func_tpl_head template <typename Derived, typename = std::enable_if_t<cynth::iterators::is_rait_derived<Derived>::value>>
#define rait_tpl_head           template <typename Derived, typename Value, typename Reference, typename Pointer>
#define rait_tpl                cynth::iterators::random_access_iterator_base<Derived, Value, Reference, Pointer>
#define rait_tpl_t              typename rait_tpl

namespace cynth::iterators {

    rait_tpl_head
    Derived rait_tpl::operator+ (std::size_t i) const {
        auto copy = this->derived();
        copy.pos() += i;
        return copy;
    }

    rait_tpl_head
    Derived rait_tpl::operator- (std::size_t i) const {
        auto copy = this->derived();
        copy.pos() -= i;
        return copy;
    }

    rait_tpl_head
    Derived& rait_tpl::operator+= (std::size_t i) {
        this->pos() += i;
        return this->derived();
    }

    rait_tpl_head
    Derived& rait_tpl::operator-= (std::size_t i) {
        this->pos() -= i;
        return this->derived();
    }

    rait_tpl_head
    Derived& rait_tpl::operator++ () {
        ++this->pos();
        return this->derived();
    }

    rait_tpl_head
    Derived rait_tpl::operator++ (int) {
        auto copy = this->derived();
        ++(*this);
        return copy;
    }

    rait_tpl_head
    rait_tpl_t::difference_type rait_tpl::operator- (const Derived& other) const {
        return this->pos() - other.pos();
    }

    rait_tpl_head
    rait_tpl_t::difference_type rait_tpl::operator< (const Derived& other) const {
        return this->pos() < other.pos();
    }

    rait_tpl_head
    rait_tpl_t::difference_type rait_tpl::operator> (const Derived& other) const {
        return this->pos() > other.pos();
    }

    rait_tpl_head
    rait_tpl_t::difference_type rait_tpl::operator<= (const Derived& other) const {
        return this->pos() <= other.pos();
    }

    rait_tpl_head
    rait_tpl_t::difference_type rait_tpl::operator>= (const Derived& other) const {
        return this->pos() >= other.pos();
    }

    rait_tpl_head
    rait_tpl_t::difference_type rait_tpl::operator== (const Derived& other) const {
        return this->pos() == other.pos();
    }

    rait_tpl_head
    rait_tpl_t::difference_type rait_tpl::operator!= (const Derived& other) const {
        return this->pos() != other.pos();
    }

    rait_tpl_head
    rait_tpl_t::reference rait_tpl::operator[] (std::size_t i) {
        return *(*this + i);
    }

    rait_tpl_head
    rait_tpl_t::reference rait_tpl::operator[] (std::size_t i) const {
        return *(*this + i);
    }

    rait_tpl_head
    Derived& rait_tpl::derived () {
        return *static_cast<Derived*>(this);
    }

    rait_tpl_head
    const Derived& rait_tpl::derived () const {
        return *static_cast<const Derived*>(this);
    }

    rait_tpl_head
    std::size_t& rait_tpl::pos () {
        return this->derived().pos();
    }

    rait_tpl_head
    const std::size_t& rait_tpl::pos () const {
        return this->derived().pos();
    }

}

rait_free_func_tpl_head
Derived operator+ (std::size_t i, const Derived& self) {
    return self + i;
}

rait_free_func_tpl_head
Derived operator- (std::size_t i, const Derived& self) {
    return self - i;
}

#undef rait_free_func_tpl_head
#undef rait_tpl_head
#undef rait_tpl
#undef rait_tpl_t