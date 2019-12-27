#pragma once

#include "bytewise.hpp"
#include "iterators.hpp"
#include "asio/sample_types.hpp"

#include "asio.h"

#include <cstddef>
#include <cstdint>
#include <array>
#include <cmath>
#include <algorithm>

namespace cynth::api::asio {

    template <std::size_t SIZE>
    using sample_spacer = std::array<std::uint8_t, SIZE>;

    template <bool CONST>
    class sample_base {
    public:
        using ptr_t = std::conditional_t<CONST, const void*, void*>;

        enum class sample_domain { integral, floating_single, floating_double };

        sample_base (ptr_t, ASIOSampleType);

        std::size_t    size       () const;
        std::size_t    used_bits  () const;
        endianness     endianness () const;
        sample_domain  domain     () const;
        ASIOSampleType asio_type  () const;

        template <typename T> T correct_endianness (T) const;

        void set (floating_t);
        
        template <typename T> T&       get     ();
        template <typename T> const T& get     () const;
        template <typename T> T*       get_ptr ();
        template <typename T> const T* get_ptr () const;

        sample_base&       operator*  ();
        const sample_base& operator*  () const;
        sample_base*       operator-> ();
        const sample_base* operator-> () const;

    private:
        ptr_t          ptr_;
        ASIOSampleType type_;
    };

    class sample_wrapper: public sample_base<false> {
        using sample_base<false>::sample_base;
    public:
        template <typename T> sample_wrapper& operator= (T);
    };
    
    class const_sample_wrapper: public sample_base<true> {
        using sample_base<true>::sample_base;
    };

    class buffer {
    public:
        using value_type      = sample_wrapper;
        using reference       = sample_wrapper&;
        using const_reference = const sample_wrapper&;
        using difference_type = std::ptrdiff_t;
        using size_type       = std::size_t;

        class iterator: public iterators::random_access_iterator_base<iterator, sample_wrapper> {
        public:
            /*using difference_type   = typename base_t::difference_type;
            using iterator_category = typename base_t::iterator_category;
            using value_type        = typename base_t::value_type;
            using reference         = typename base_t::reference;
            using pointer           = typename base_t::pointer;*/

            iterator (buffer&, std::size_t);

            reference operator*  ();
            reference operator*  () const;
            pointer   operator-> ();
            pointer   operator-> () const;

            std::size_t&       pos ();
            const std::size_t& pos () const;

        private:
            //using base_t = iterators::random_access_iterator_base<iterator, sample_wrapper>;

            buffer&     buffer_;
            std::size_t pos_;
        };

        class const_iterator: public iterators::random_access_iterator_base<iterator, const_sample_wrapper> {
        public:
            /*using difference_type   = typename base_t::difference_type;
            using iterator_category = typename base_t::iterator_category;
            using value_type        = typename base_t::value_type;
            using reference         = typename base_t::reference;
            using pointer           = typename base_t::pointer;*/

            const_iterator (const buffer&, std::size_t);
            
            reference operator*  () const;
            pointer   operator-> () const;

            std::size_t&       pos ();
            const std::size_t& pos () const;

        private:
            //using base_t = iterators::random_access_iterator_base<iterator, const_sample_wrapper>;
            
            const buffer& buffer_;
            std::size_t   pos_;
        };

        buffer (void*, ASIOSampleType, std::size_t);

        ASIOSampleType asio_type () const;

        void*       at (std::size_t);
        const void* at (std::size_t) const;

        sample_wrapper       operator[] (std::size_t);
        const_sample_wrapper operator[] (std::size_t) const;

        std::size_t size () const;

        iterator       begin  ();
        iterator       end    ();
        const_iterator cbegin () const;
        const_iterator cend   () const;
        const_iterator begin  () const;
        const_iterator end    () const;

    private:
        template <std::size_t>       void* at (std::size_t);
        template <std::size_t> const void* at (std::size_t) const;

        void* ptr_;
        ASIOSampleType type_;
        std::size_t size_;
        std::size_t spacing_;
    };

}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

namespace cynth::api::asio {

    template <bool CONST>
    sample_base<CONST>::sample_base (ptr_t ptr, ASIOSampleType type):
        ptr_{ptr},
        type_{type} {}

    template <bool CONST>
    std::size_t sample_base<CONST>::size () const {
        return sample_type_size(this->type_);
    }

    template <bool CONST>
    std::size_t sample_base<CONST>::used_bits () const {
        return sample_type_used_bits(this->type_);
    }

    template <bool CONST>
    endianness sample_base<CONST>::endianness () const {
        return sample_type_endianness(this->type_);
    }

    template <bool CONST>
    typename sample_base<CONST>::sample_domain sample_base<CONST>::domain () const {
        if (sample_type_domain(this->type_) == asio::sample_domain::integral)
            return sample_domain::integral;
        if (sample_type_domain(this->type_) == asio::sample_domain::floating) {
            if (this->size() == 4)
                return sample_domain::floating_single;
            if (this->size() == 4)
                return sample_domain::floating_double;
        }
        throw std::domain_error{"Unsupported sample type provided for cynth::api::asio::sample"};
    }

    template <bool CONST>
    ASIOSampleType sample_base<CONST>::asio_type () const {
        return this->type_;
    }

    template <bool CONST>
    template <typename T>
    T sample_base<CONST>::correct_endianness (T n) const {
        return this->endianness() == bytewise::system_endianness()
            ? n
            : bytewise::switch_endianness(n);
    }

    template <bool CONST>
    void sample_base<CONST>::set (floating_t val) {
        if (this->domain() == sample_domain::floating_single)
            this->get<double>() = this->correct_endianness(val);
        else if (this->domain() == sample_domain::floating_double)
            this->get<float>() = this->correct_endianness(val);
        else if (this->domain() == sample_domain::integral) {
            const int  delta      = 100;
            const auto limit      = bytewise::bit_int_limit(this->used_bits()) - delta;
            const auto normalized = static_cast<std::int_least64_t>(std::floor(val * limit));
            const auto bytes      = bytewise::bytes(normalized);
            if (this->endianness() == endianness::big)
                std::copy(bytes.end() - this->size() - 1, bytes.end(), this->get_ptr<byte_t>());
            else if (this->endianness() == endianness::little)
                std::copy(bytes.begin(), bytes.begin() + this->size(), this->get_ptr<byte_t>());
        }
    }

    template <bool CONST>
    template <typename T>
    T& sample_base<CONST>::get () {
        return *reinterpret_cast<T*>(this->ptr_);
    }

    template <bool CONST>
    template <typename T>
    const T& sample_base<CONST>::get () const {
        return *reinterpret_cast<const T*>(this->ptr_);
    }

    template <bool CONST>
    template <typename T>
    T* sample_base<CONST>::get_ptr () {
        return reinterpret_cast<T*>(this->ptr_);
    }

    template <bool CONST>
    template <typename T>
    const T* sample_base<CONST>::get_ptr () const {
        return reinterpret_cast<const T*>(this->ptr_);
    }

    template <bool CONST>
    sample_base<CONST>& sample_base<CONST>::operator* () {
        return *this;
    }

    template <bool CONST>
    const sample_base<CONST>& sample_base<CONST>::operator* () const {
        return *this;
    }

    template <bool CONST>
    sample_base<CONST>* sample_base<CONST>::operator-> () {
        return this;
    }

    template <bool CONST>
    const sample_base<CONST>* sample_base<CONST>::operator-> () const {
        return this;
    }

    template <typename T>
    sample_wrapper& sample_wrapper::operator= (T val) {
        this->set(val);
        return *this;
    }

    buffer::iterator::iterator (buffer& buff, std::size_t pos):
        buffer_{buff},
        pos_   {pos} {}
    
    buffer::const_iterator::const_iterator (const buffer& buff, std::size_t pos):
        buffer_{buff},
        pos_   {pos} {}
    
    buffer::iterator::reference buffer::iterator::operator* () {
        return this->buffer_[this->pos_];
    }

    buffer::iterator::reference buffer::iterator::operator* () const {
        return this->buffer_[this->pos_];
    }

    buffer::iterator::pointer buffer::iterator::operator-> () {
        return this->buffer_[this->pos_];
    }

    buffer::iterator::pointer buffer::iterator::operator-> () const {
        return this->buffer_[this->pos_];
    }

    buffer::const_iterator::reference buffer::const_iterator::operator* () const {
        return this->buffer_[this->pos_];
    }

    buffer::const_iterator::pointer buffer::const_iterator::operator-> () const {
        return this->buffer_[this->pos_];
    }

    buffer::buffer (void* ptr, ASIOSampleType type, std::size_t size):
        ptr_    {ptr},
        type_   {type},
        size_   {size},
        spacing_{sample_type_size(type)} {}

    ASIOSampleType buffer::asio_type () const {
        return this->type_;
    }

    sample_wrapper buffer::operator[] (std::size_t pos) {
        return {this->at(pos), this->type_};
    }
    const_sample_wrapper buffer::operator[] (std::size_t pos) const {
        return {this->at(pos), this->type_};
    }

    template <std::size_t SIZE>
    void* buffer::at (std::size_t pos) {
        return reinterpret_cast<sample_spacer<SIZE>*>(this->ptr_) + pos;
    }

    template <std::size_t SIZE>
    const void* buffer::at (std::size_t pos) const {
        return reinterpret_cast<const sample_spacer<SIZE>*>(this->ptr_) + pos;
    }

    void* buffer::at (std::size_t pos) {
        switch (this->spacing_) {
        case 2:
            return this->at<2>(pos);
        case 3:
            return this->at<3>(pos);
        case 4:
            return this->at<4>(pos);
        case 8:
            return this->at<8>(pos);
        default:
            throw std::domain_error{"Unsupported sample type set for cynth::api::asio::buffer_wrapper."};
        }
    }

    const void* buffer::at (std::size_t pos) const {
        switch (this->spacing_) {
        case 2:
            return this->at<2>(pos);
        case 3:
            return this->at<3>(pos);
        case 4:
            return this->at<4>(pos);
        case 8:
            return this->at<8>(pos);
        default:
            throw std::domain_error{"Unsupported sample type set for cynth::api::asio::buffer_wrapper."};
        }
    }

    std::size_t buffer::size () const {
        return this->size_;
    }

    buffer::iterator buffer::begin () {
        return {*this, 0};
    }

    buffer::iterator buffer::end () {
        return {*this, this->size()};
    }

    buffer::const_iterator buffer::cbegin () const {
        return const_iterator{*this, 0};
    }

    buffer::const_iterator buffer::cend () const {
        return {*this, this->size()};
    }

    buffer::const_iterator buffer::begin () const {
        return this->cbegin();
    }

    buffer::const_iterator buffer::end () const {
        return this->cend();
    }

}