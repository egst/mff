#pragma once

//#define IEEE754_64FLOAT 1
// For some reason, this macro has different value in my code and in the asio code.
// As a result, ASIOSampleRate is defined as double in one place and as a struct holding an array in other.
// This produces an "undefined reference to ASIOGetSampleRate(ASIOSampleRate*)" linker error.

#undef min

#include "type_config.hpp"
#include "asio/buffer.hpp"
#include "asio/error_handler.hpp"
#include "asio/types.hpp"

#include "asio.h"
#include "asiodrivers.h"
//#include "asiosys.h"

#include <iostream>
#include <vector>
#include <string>
#include <cstddef>
#include <cstdint>
#include <mutex>
#include <shared_mutex>
#include <condition_variable>
#include <atomic>
//#include <chrono>
//#include <timeapi.h>
//#include <windows.h>

// This should be implemented by ASIO SDK, but, for some reason, needs manual declaration:
extern AsioDrivers* asioDrivers;
bool loadAsioDriver (char *name);

namespace cynth::api::asio {
    struct driver {
    public:
        // Interactive prompt to choose the driver (the sound card):
        static void chose_driver ();

        // After the driver is chosen, start (in the same thread):
        static void start ();

        // The wave function representing the signal:
        using function = floating_t (*) (floating_t);
        inline static function sample;
        
    private:
        // Available drivers:
        static std::vector<std::string> list_drivers ();

        // asioDrivers:
        static AsioDrivers& drivers ();
        // loadAsioDriver:
        static bool load_driver (std::string);

        // Initialization:
        static void full_init ();
        static void init      ();

        // Initialization steps:
        static void get_channel_count           ();
        static void get_buffer_sizes            ();
        static void get_sample_rate             ();
        static void check_outready_optimization ();
        static void set_callbacks               ();
        static void configure_channels          ();
        static void create_buffers              ();
        static void get_channel_info            ();
        static void get_latencies               ();

        // Maximum number of input/output channels:
        constexpr static std::size_t max_input_channel_count  = 32;
        constexpr static std::size_t max_output_channel_count = 32;

        // Initialization data:
        inline static ASIODriverInfo  driver_info;
        inline static std::size_t     input_channel_count;
        inline static std::size_t     output_channel_count;
        inline static std::size_t     min_buffer_size;
        inline static std::size_t     max_buffer_size;
        inline static std::size_t     preferred_buffer_size;
        inline static std::ptrdiff_t  buffer_sizes_granularity;
        inline static floating_t      sample_rate; // ASIOSampleRate
        inline static bool            outready_optimization;
        inline static std::size_t     input_latency;
        inline static std::size_t     output_latency;
        inline static std::size_t     input_buffer_count;
        inline static std::size_t     output_buffer_count;
        inline static ASIOBufferInfo  buffer_infos[max_input_channel_count + max_output_channel_count];
        inline static ASIOChannelInfo channel_infos[max_input_channel_count + max_output_channel_count];
        
        // Mutable data:
        // TODO: Lock-free implementation of atomic<ASIOTime>
        inline static std::atomic<floating_t>  sample_pos_ns;
        inline static std::atomic<floating_t>  sample_pos_samples;
        inline static std::atomic<floating_t>  time_code_samples;
        inline static std::atomic<ASIOTime>    time;
        inline static std::atomic<std::size_t> system_reference_time;
        
        // Stop requests and synchronization:
        enum stop_enum { FULL, RESET, SRATE_RESET };
        inline static std::mutex              stop_mutex;
        inline static std::shared_mutex       operation_mutex;
        inline static std::condition_variable stop_signal;
        inline static std::atomic<stop_enum>  stop_type;
        static void request_stop (stop_enum = FULL);

        // Callbacks for the driver:
        inline static ASIOCallbacks callbacks;
        static void      buffer_switch           (long, ASIOBool);
        static void      sample_rate_changed     (ASIOSampleRate);
        static long      asio_messages           (long, long, void*, double*);
        static ASIOTime* buffer_switch_time_info (ASIOTime*, long, ASIOBool);
    };

}

static_assert(std::atomic<std::size_t>::is_always_lock_free);
static_assert(std::atomic<std::ptrdiff_t>::is_always_lock_free);

////////////////////////////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////

namespace cynth::api::asio {

    std::vector<std::string> driver::list_drivers () {
        constexpr std::size_t driver_count     = 32;
        constexpr std::size_t driver_name_size = 32;
        
        char* driver_names[driver_count];
        for (char** it = driver_names; it != driver_names + driver_count; ++it)
            *it = new char[driver_name_size];

        AsioDrivers drivers;
        drivers.getDriverNames(driver_names, driver_count);

        std::vector<std::string> result;
        for (char** it = driver_names; it != driver_names + driver_count; ++it) {
            result.push_back(*it);
            delete[] it;
        }
        
        return result;
    }

    AsioDrivers& driver::drivers () {
        if (!asioDrivers)
            throw std::runtime_error{"asioDrivers not initialized."};
        return *asioDrivers;
    }

    bool driver::load_driver (std::string name) {
        return loadAsioDriver(name.data());
    }

    void driver::chose_driver () {
        auto driver_names = driver::list_drivers();

        std::cout << "ASIO setup:\n\n";
        std::cout << "Available drivers:\n";

        std::size_t driver_count = 0;
        for (auto&& driver_name: driver_names) {
            std::cout << driver_count << ": " << driver_name << '\n';
            ++driver_count;
        }
        std::cout << '\n';

        std::cout
            << "Choose a driver to use:\n"
            << "Enter a number from 0" << " to " << driver_count - 1 << ".\n";

        std::size_t chosen;
        while (std::cin >> chosen) {
            if (!(chosen >= 0 && chosen < driver_count)) {
                std::cout << "No such driver::\n";
                continue;
            }
            break;
        }

        bool loaded = driver::load_driver(driver_names[chosen]);
        if (loaded)
            std::cout << driver_names[chosen] << " was loaded.\n\n";
        else
            std::cout << driver_names[chosen] << " could not be loaded.\n\n";
    }

    void driver::start () {
        driver::full_init();
        
        while (true) {
            ASIOStart() >> error_handler{"ASIOStart"};

            /* The locking process:
            ASIO callbacks remain lock-free as they acquire a shared ownership of the operation_mutex.
            These callbacks owning the operation_mutex means, that at this moment
            it is not safe to dispose buffers or even exit ASIO completely (ASIODisposeBuffers, ASIOExit).
            To stop or reset ASIO, the operation_mutex must be owned exclusively.
            When anyone manages to acquire exclusive ownership,
            ASIO callbacks fail to acquire shared ownership and return immediately.
            Callbacks that are writing to buffers cannot write when the mutex is owned exclusively
            as the driver may be in the process of stopping/restarting and the buffers may not be valid.
            Callbacks that are responsible for various events notifications are simply ignored,
            as no such events are relevant when the driver is stopping/restarting.
            */

            std::unique_lock<std::mutex> stop_guard {driver::stop_mutex};
            driver::stop_signal.wait(stop_guard);
            std::unique_lock<std::shared_mutex> operation_guard {driver::operation_mutex};

            switch (driver::stop_type) {
            case driver::stop_enum::RESET:
                ASIOStop()           >> error_handler{"ASIOStop"};
                ASIODisposeBuffers() >> error_handler{"ASIODisposeBuffers"};
                ASIOExit()           >> error_handler{"ASIOExit"};
                driver::full_init();
                continue;
            case driver::stop_enum::SRATE_RESET:
                driver::full_init();
                continue;
            case driver::stop_enum::FULL:
            default:
                break;
            }

            ASIOStop() >> error_handler{"ASIOStop"};
            break;
        }
    }

    void driver::full_init () {
        driver::init();
        driver::get_channel_count();
        driver::get_buffer_sizes();
        driver::get_sample_rate();
        driver::check_outready_optimization();
        driver::set_callbacks();
        driver::configure_channels();
        driver::create_buffers();
        driver::get_channel_info();
        driver::get_latencies();
    }

    void driver::init () {
        ASIOInit(&driver::driver_info) >> error_handler{"ASIOInit"};
    }

    void driver::get_channel_count () {
        long input_channel_count;
        long output_channel_count;
        ASIOGetChannels(
            &input_channel_count,
            &output_channel_count) >> error_handler{"ASIOGetChannels"};
        driver::input_channel_count  = static_cast<std::size_t>(input_channel_count);
        driver::output_channel_count = static_cast<std::size_t>(output_channel_count);
    }

    void driver::get_buffer_sizes () {
        long min_buffer_size;
        long max_buffer_size;
        long preferred_buffer_size;
        long buffer_sizes_granularity;
        ASIOGetBufferSize(
            &min_buffer_size,
            &max_buffer_size,
            &preferred_buffer_size,
            &buffer_sizes_granularity) >> error_handler{"ASIOGetBufferSize"};
        driver::min_buffer_size          = static_cast<std::size_t>(min_buffer_size);
        driver::max_buffer_size          = static_cast<std::size_t>(max_buffer_size);
        driver::preferred_buffer_size    = static_cast<std::size_t>(preferred_buffer_size);
        driver::buffer_sizes_granularity = static_cast<std::ptrdiff_t>(buffer_sizes_granularity);
    }

    void driver::get_sample_rate () {
        ASIOSampleRate sample_rate;
        ASIOGetSampleRate(&sample_rate) >> error_handler{"ASIOGetSampleRate"};
        // TODO: ASIOCanSampleRate, ASIOSetSampleRate when the sample rate is not stored in the driver.
        driver::sample_rate = tools::native_floating(sample_rate);
        //wave_function::sample_rate = driver::sample_rate;
    }

    void driver::check_outready_optimization () {
        driver::outready_optimization = ASIOOutputReady() == ASE_OK;
    }

    void driver::set_callbacks () {
        driver::callbacks = {
            driver::buffer_switch,
            driver::sample_rate_changed,
            driver::asio_messages,
            driver::buffer_switch_time_info
        };
    }

    void driver::configure_channels () {
        driver::input_buffer_count = std::min(driver::input_channel_count, driver::max_input_channel_count);
        for(std::size_t i = 0; i < driver::input_buffer_count; ++i) {
            auto& buffer_info = driver::buffer_infos[i];
            buffer_info.isInput    = ASIOTrue;
            buffer_info.channelNum = i;
            buffer_info.buffers[0] = 0;
            buffer_info.buffers[1] = 0;
        }
        
        driver::output_buffer_count = std::min(driver::output_channel_count, driver::max_output_channel_count);
        for(std::size_t i = 0; i < driver::output_buffer_count; ++i) {
            auto& buffer_info = driver::buffer_infos[i + driver::input_buffer_count];
            buffer_info.isInput    = ASIOFalse;
            buffer_info.channelNum = i;
            buffer_info.buffers[0] = 0;
            buffer_info.buffers[1] = 0;
        }
    }

    void driver::create_buffers () {
        ASIOCreateBuffers(
            driver::buffer_infos,
            driver::input_channel_count + driver::output_channel_count,
            driver::preferred_buffer_size,
            &driver::callbacks) >> error_handler{"ASIOCreateBuffers"};
    }

    void driver::get_channel_info () {
        for (std::size_t i = 0; i < driver::input_buffer_count + driver::output_channel_count; ++i) {
            auto& buffer_info  = driver::buffer_infos[i];
            auto& channel_info = driver::channel_infos[i];

            channel_info.channel = buffer_info.channelNum;
            channel_info.isInput = buffer_info.isInput;

            ASIOGetChannelInfo(&channel_info) >> error_handler{"ASIOGetChannelInfo"};
        }
    }

    void driver::get_latencies () {
        // Note from the docs:
        // input latency is the age of the first sample in the currently returned audio block
        // output latency is the time the first sample in the currently returned audio block requires to get to the output

        long input_latency;
        long output_latency;
        ASIOGetLatencies(
            &input_latency,
            &output_latency) >> error_handler{"ASIOGetLatencies"};
        driver::input_latency  = static_cast<unsigned_t>(input_latency);
        driver::output_latency = static_cast<unsigned_t>(output_latency);
    }

    void driver::request_stop (stop_enum type) {
        driver::stop_type = type;
        driver::stop_signal.notify_all();
    }

    void driver::buffer_switch (long index, ASIOBool direct_process) {
        ASIOTime time {};

        if (ASIOGetSamplePosition(&time.timeInfo.samplePosition, &time.timeInfo.systemTime) == ASE_OK)
            time.timeInfo.flags = AsioTimeInfoFlags::kSystemTimeValid | AsioTimeInfoFlags::kSamplePositionValid;

        driver::buffer_switch_time_info (&time, index, direct_process);
    }

    void driver::sample_rate_changed (ASIOSampleRate srate) {
        (void) srate;

        std::shared_lock<std::shared_mutex> guard {operation_mutex, std::try_to_lock};
        if (!guard.owns_lock())
            return;

        /* From the docs:
            Do whatever you need to do if the sample rate changed.
            Usually this only happens during external sync.
            Audio processing is not stopped by the driver, actual sample rate
            might not have even changed, maybe only the sample rate status of an
            AES/EBU or S/PDIF digital input at the audio device.
            You might have to update time/sample related conversion routines, etc. */
        
        driver::request_stop(SRATE_RESET);
    }

    long driver::asio_messages (long selector, long value, void* message, double* opt) {
        (void) message;
        (void) opt;

        std::shared_lock<std::shared_mutex> guard{operation_mutex, std::try_to_lock};
        if (!guard.owns_lock())
            return 0;
        
        // TODO: This was just coppied from the docs.
        // The messages, that are not implemented perform a full stop of the driver.
        switch (selector) {
        case kAsioSelectorSupported:
            if(value == kAsioResetRequest
            || value == kAsioEngineVersion
            || value == kAsioResyncRequest
            || value == kAsioLatenciesChanged
            || value == kAsioSupportsTimeInfo
            || value == kAsioSupportsTimeCode
            || value == kAsioSupportsInputMonitor) {

                driver::request_stop();
                return 1;
            }
            break;
        case kAsioResetRequest:
            /* From the docs:
                defer the task and perform the reset of the driver during the next "safe" situation
                You cannot reset the driver right now, as this code is called from the driver.
                Reset the driver is done by completely destruct is. I.e. ASIOStop(), ASIODisposeBuffers(), Destruction
                Afterwards you initialize the driver again. */
            driver::request_stop(RESET);
            return 1;
        case kAsioResyncRequest:
            /* From the docs:
                This informs the application, that the driver encountered some non fatal data loss.
                It is used for synchronization purposes of different media.
                Added mainly to work around the Win16Mutex problems in Windows 95/98 with the
                Windows Multimedia system, which could loose data because the Mutex was hold too long
                by another thread.
                However a driver can issue it in other situations, too. */
            driver::request_stop();
            return 1;
        case kAsioLatenciesChanged:
            /* From the docs:
                This will inform the host application that the drivers were latencies changed.
                Beware, it this does not mean that the buffer sizes have changed!
                You might need to update internal delay data. */
            driver::request_stop();
            return 1;
        case kAsioEngineVersion:
            /* From the docs:
                return the supported ASIO version of the host application
                If a host applications does not implement this selector, ASIO 1.0 is assumed
                by the driver */
            driver::request_stop();
            return 2;
        case kAsioSupportsTimeInfo:
            /* From the docs:
                informs the driver wether the asioCallbacks.bufferSwitchTimeInfo() callback
                is supported.
                For compatibility with ASIO 1.0 drivers the host application should always support
                the "old" bufferSwitch method, too. */
            /*driver::stop_type = FULL;
            driver::stop_signal.notify_all();*/
            return 1;
        case kAsioSupportsTimeCode:
            /* From the docs:
                informs the driver wether application is interested in time code info.
                If an application does not need to know about time code, the driver has less work
                to do. */
            driver::request_stop();
            return 0;
        }
        return 0;
    }

    ASIOTime* driver::buffer_switch_time_info (ASIOTime* time_ptr, long index, ASIOBool direct_process) {
        // TODO: Docs, page 8: First few call to bufferSwitch should be ignored.

        std::shared_lock<std::shared_mutex> guard {operation_mutex, std::try_to_lock};
        if (!guard.owns_lock())
            return 0;

        driver::time = *time_ptr;

        // From the docs: get the time stamp of the buffer (for synchronization with other media)
        driver::sample_pos_ns = time_ptr->timeInfo.flags & kSystemTimeValid
            ? tools::native_floating(time_ptr->timeInfo.systemTime)
            : 0;
        driver::sample_pos_samples = time_ptr->timeInfo.flags & kSamplePositionValid
            ? tools::native_floating(time_ptr->timeInfo.samplePosition)
            : 0;
        driver::time_code_samples = time_ptr->timeCode.flags & kTcValid
            ? tools::native_floating(time_ptr->timeCode.timeCodeSamples)
            : 0;

        // From the docs: get the system reference time
        driver::system_reference_time = timeGetTime(); // TODO: From which header is this?

        auto buffer_size = driver::preferred_buffer_size;
        
        for (std::size_t i = 0; i < driver::input_buffer_count + driver::output_buffer_count; ++i) {
            auto& buffer_info  = driver::buffer_infos[i];
            auto& channel_info = driver::channel_infos[i];
            if (buffer_info.isInput == ASIOFalse) {
                auto buff = buffer{buffer_info.buffers[index], channel_info.type, buffer_size};
                {
                    std::size_t j = 0; for (auto&& s: buff) {
                        auto seconds = (sample_pos_samples + j) / driver::sample_rate;
                        s = driver::sample(seconds);
                        ++j;
                    }
                }
            }
        }

        // From the docs: finally if the driver supports the ASIOOutputReady() optimization, do it here, all data are in place
        if (driver::outready_optimization)
            ASIOOutputReady() >> error_handler{"ASIOOutputReady"};

        return 0;
    }

}