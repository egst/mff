#pragma once

#include <stdexcept>
#include <string>

#include "asio.h"

namespace cynth::api::asio {

    static std::string error_status (ASIOError);

    class error_handler {
    public:
        error_handler (const std::string& = "");

        friend ASIOError operator>> (ASIOError, const error_handler&);

    private:
        std::string message (ASIOError) const;

        std::string source_;
    };

}

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

namespace cynth::api::asio {

    static std::string error_status (ASIOError er) {
        switch (er) {
        case ASE_OK:
            return "OK.";
        case ASE_SUCCESS:
            return "ASIOFurute success.";
        case ASE_NotPresent:
            return "Hardware input or output is not present or available.";
        case ASE_HWMalfunction:
            return "Hardware is malfunctioning.";
        case ASE_InvalidParameter:
            return "Invalid parameter.";
        case ASE_InvalidMode:
            return "Invalid mode.";
        case ASE_SPNotAdvancing:
            return "Hardware is not running when sample position is inquired.";
        case ASE_NoClock:
            return "No clock.";
        case ASE_NoMemory:
            return "No memory.";
        default:
            return std::to_string(er);
        }
    }

    error_handler::error_handler (const std::string& source):
        source_{source} {}

    std::string error_handler::message (ASIOError er) const {
        if (this->source_ != "")
            return this->source_ + ": " + error_status(er);
        else
            return error_status(er);
    }

    ASIOError operator>> (ASIOError er, const error_handler& self) {
        if (er != ASE_OK)
            throw std::runtime_error{self.message(er)};
        return er;
    }

}