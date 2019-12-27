#pragma once

#include "type_config.hpp"
#include "bytewise.hpp"

#include "asio.h"

#include <cstddef>

namespace cynth::api::asio {

    enum class sample_domain { integral, floating };

    constexpr std::size_t   sample_type_size       (ASIOSampleType);
    constexpr std::size_t   sample_type_used_bits  (ASIOSampleType);
    constexpr sample_domain sample_type_domain     (ASIOSampleType);
    constexpr endianness    sample_type_endianness (ASIOSampleType);
    constexpr const char*   sample_type_name       (ASIOSampleType);

}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

namespace cynth::api::asio {

    constexpr std::size_t sample_type_size (ASIOSampleType type) {
        switch(type) {
        case ASIOSTInt16MSB:
        case ASIOSTInt16LSB:
            return 2;
        case ASIOSTInt24MSB:
        case ASIOSTInt24LSB:
            return 3;
        case ASIOSTInt32MSB:
        case ASIOSTInt32LSB:
        case ASIOSTInt32MSB16:
        case ASIOSTInt32LSB16:
        case ASIOSTInt32MSB18:
        case ASIOSTInt32LSB18:
        case ASIOSTInt32MSB20:
        case ASIOSTInt32LSB20:
        case ASIOSTInt32MSB24:
        case ASIOSTInt32LSB24:
            return 4;
        case ASIOSTFloat32MSB:
        case ASIOSTFloat32LSB:
            return 4;
        case ASIOSTFloat64MSB:
        case ASIOSTFloat64LSB:
            return 8;
        default:
            throw std::domain_error{"Unknown sample type provided for cynth::asio::tools::sample_type_size."};
        }
    }

    constexpr std::size_t sample_type_used_bits (ASIOSampleType type) {
        switch(type) {
        case ASIOSTInt16MSB:
        case ASIOSTInt16LSB:
        case ASIOSTInt24MSB:
        case ASIOSTInt24LSB:
        case ASIOSTInt32MSB:
        case ASIOSTInt32LSB:
        case ASIOSTFloat32MSB:
        case ASIOSTFloat32LSB:
        case ASIOSTFloat64MSB:
        case ASIOSTFloat64LSB:
            return sample_type_size(type) * 8;
        case ASIOSTInt32MSB16:
        case ASIOSTInt32LSB16:
            return 16;
        case ASIOSTInt32MSB18:
        case ASIOSTInt32LSB18:
            return 18;
        case ASIOSTInt32MSB20:
        case ASIOSTInt32LSB20:
            return 20;
        case ASIOSTInt32MSB24:
        case ASIOSTInt32LSB24:
            return 24;
        default:
            throw std::domain_error{"Unknown sample type provided for cynth::asio::tools::sample_type_size."};
        }
    }

    constexpr sample_domain sample_type_domain (ASIOSampleType type) {
        switch(type) {
        case ASIOSTInt16MSB:
        case ASIOSTInt16LSB:
        case ASIOSTInt24MSB:
        case ASIOSTInt24LSB:
        case ASIOSTInt32MSB:
        case ASIOSTInt32LSB:
        case ASIOSTInt32MSB16:
        case ASIOSTInt32LSB16:
        case ASIOSTInt32MSB18:
        case ASIOSTInt32LSB18:
        case ASIOSTInt32MSB20:
        case ASIOSTInt32LSB20:
        case ASIOSTInt32MSB24:
        case ASIOSTInt32LSB24:
            return sample_domain::integral;
        case ASIOSTFloat32MSB:
        case ASIOSTFloat32LSB:
        case ASIOSTFloat64MSB:
        case ASIOSTFloat64LSB:
            return sample_domain::floating;
        default:
            throw std::domain_error{"Unknown sample type provided for cynth::asio::tools::sample_type_domain."};
        }
    }

    constexpr endianness sample_type_endianness (ASIOSampleType type) {
        switch(type) {
        case ASIOSTInt16LSB:
        case ASIOSTInt24LSB:
        case ASIOSTInt32LSB:
        case ASIOSTInt32LSB16:
        case ASIOSTInt32LSB18:
        case ASIOSTInt32LSB20:
        case ASIOSTInt32LSB24:
        case ASIOSTFloat32LSB:
        case ASIOSTFloat64LSB:
            return endianness::little;
        case ASIOSTInt16MSB:
        case ASIOSTInt24MSB:
        case ASIOSTInt32MSB:
        case ASIOSTInt32MSB16:
        case ASIOSTInt32MSB18:
        case ASIOSTInt32MSB20:
        case ASIOSTInt32MSB24:
        case ASIOSTFloat32MSB:
        case ASIOSTFloat64MSB:
            return endianness::big;
        default:
            throw std::domain_error{"Unknown sample type provided for cynth::asio::tools::sample_type_endianness."};
        }
    }

    constexpr const char* sample_type_name (ASIOSampleType type) {
        switch (type) {
        case ASIOSTInt16MSB:
            return "INT 16 MSB";
        case ASIOSTInt24MSB:
            return "INT 24 MSB";
        case ASIOSTInt32MSB:
            return "INT 32 MSB";
        case ASIOSTFloat32MSB:
            return "FLOAT 32 MSB";
        case ASIOSTFloat64MSB:
            return "FLOAT 64 MSB";
        case ASIOSTInt32MSB16:
            return "INT 32 MSB 16";
        case ASIOSTInt32MSB18:
            return "INT 32 MSB 18";
        case ASIOSTInt32MSB20:
            return "INT 32 MSB 20";
        case ASIOSTInt32MSB24:
            return "INT 32 MSB 24";
        case ASIOSTInt16LSB:
            return "INT 16 LSB";
        case ASIOSTInt24LSB:
            return "INT 24 LSB";
        case ASIOSTInt32LSB:
            return "INT 32 LSB";
        case ASIOSTFloat32LSB:
            return "FLOAT 32 LSB";
        case ASIOSTFloat64LSB:
            return "FLOAT 64 LSB";
        case ASIOSTInt32LSB16:
            return "INT 32 LSB 16";
        case ASIOSTInt32LSB18:
            return "INT 32 LSB 18";
        case ASIOSTInt32LSB20:
            return "INT 32 LSB 20";
        case ASIOSTInt32LSB24:
            return "INT 32 LSB 24";
        case ASIOSTDSDInt8LSB1:
            return "DSD INT 8 LSB 1";
        case ASIOSTDSDInt8MSB1:
            return "DSD INT 8 MSB 1";
        case ASIOSTDSDInt8NER8:
            return "DSD INT 8 NER 8";
        case ASIOSTLastEntry:
            return "Last Entry";
        default:
            throw std::domain_error{"Unknown sample type provided for cynth::asio::tools::sample_type_name."};
        }
    }

}

/*
    *  From the docs:
    * 
    *  ASIOSTInt16MSB
    *  ASIOSTInt24MSB    -- used for 20 bits as well
    *  ASIOSTInt32MSB
    *  ASIOSTFloat32MSB  -- IEEE 754 32 bit float
    *  ASIOSTFloat64MSB  -- IEEE 754 64 bit double float
    * 
    *  These are used for 32 bit data buffer, with different alignment of the data inside.
    *  32 bit PCI bus systems can be more easily used with these.
    * 
    *  ASIOSTInt32MSB16  -- 32 bit data with 16 bit alignment
    *  ASIOSTInt32MSB18  -- 32 bit data with 18 bit alignment
    *  ASIOSTInt32MSB20  -- 32 bit data with 20 bit alignment
    *  ASIOSTInt32MSB24  -- 32 bit data with 24 bit alignment
    *  ASIOSTInt16LSB
    *  ASIOSTInt24LSB    -- used for 20 bits as well
    *  ASIOSTInt32LSB
    *  ASIOSTFloat32LSB  -- IEEE 754 32 bit float, as found on Intel x86 architecture
    *  ASIOSTFloat64LSB  -- IEEE 754 64 bit double float, as found on Intel x86 architecture
    * 
    *  These are used for 32 bit data buffer, with different alignment of the data inside.
    *  32 bit PCI bus systems can more easily used with these.
    * 
    *  ASIOSTInt32LSB16  -- 32 bit data with 18 bit alignment
    *  ASIOSTInt32LSB18  -- 32 bit data with 18 bit alignment
    *  ASIOSTInt32LSB20  -- 32 bit data with 20 bit alignment
    *  ASIOSTInt32LSB24  -- 32 bit data with 24 bit alignment
    * 
    *  ASIO DSD format.
    *  ASIOSTDSDInt8LSB1 -- DSD 1 bit data, 8 samples per byte. First sample in Least significant bit.
    *  ASIOSTDSDInt8MSB1 -- DSD 1 bit data, 8 samples per byte. First sample in Most significant bit.
    *  ASIOSTDSDInt8NER8 -- DSD 8 bit data, 1 sample per byte. No Endianness required.
    *  ASIOSTLastEntry
    */

/*
    *  assuming little endian and arithmetic right shift:
    *  ASIOSTInt16LSB:        2B int     min..max
    *  case ASIOSTInt24LSB:   3B int     min..max
    *  case ASIOSTInt32LSB:   4B int     min..max
    *  case ASIOSTFloat32LSB: 4B float   -1..1  -- TODO: Handle cases, when sizeof(float)  != 4B (or even isn't IEEE 754?)
    *  case ASIOSTFloat64LSB: 8B double  -1..1  -- TODO: Handle cases, when sizeof(double) != 8B (or even isn't IEEE 754?)
    *  ASIOSTInt32LSB16:      4B int     min<16b>..max<16b> >> 16
    *  ASIOSTInt32LSB18:      4B int     min<18b>..max<18b> >> 14
    *  ASIOSTInt32LSB20:      4B int     min<20b>..max<20b> >> 12
    *  ASIOSTInt32LSB24:      4B int     min<24b>..max<24b> >> 8
    * 
    *  assuming big endian and arithmetic right shift:
    *  ASIOSTInt16MSB:        2B int     min..max
    *  case ASIOSTInt24MSB:   3B int     min..max
    *  case ASIOSTInt32MSB:   4B int     min..max
    *  case ASIOSTFloat32MSB: 4B float   -1..1  -- TODO: Handle cases, when sizeof(float)  != 4B (or even isn't IEEE 754?)
    *  case ASIOSTFloat64MSB: 8B double  -1..1  -- TODO: Handle cases, when sizeof(double) != 8B (or even isn't IEEE 754?)
    *  ASIOSTInt32MSB16:      4B int     min<16b>..max<16b> >> 16
    *  ASIOSTInt32MSB18:      4B int     min<18b>..max<18b> >> 14
    *  ASIOSTInt32MSB20:      4B int     min<20b>..max<20b> >> 12
    *  ASIOSTInt32MSB24:      4B int     min<24b>..max<24b> >> 8
    * 
    *  TODO: Handle cases, when right shift is not arithmetic.
    *  When samples are "LSB" on big endian platforms or vice-versa, the value is simply reversed.
    */