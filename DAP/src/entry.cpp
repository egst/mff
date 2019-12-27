#include <iostream>

#include "bytewise.hpp"
#include "asio/sample_types.hpp"
#include "iterators.hpp"
#include "asio/buffer.hpp"
#include "asio/driver.hpp"

#include <cstddef>
#include <cstdint>
#include <iostream>
#include <cstdlib>
#include <thread>
//#include <mutex>

//std::mutex m;

using namespace cynth;

int main () {
    
    
    //std::thread{&cynth::api::asio::driver::start}.detach();

    /*
    std::cout << show(bytewise::system_endianness()) << '\n';

    std::uint64_t i = 0x0001020304050607;
    std::cout << (int) bytewise::at<0>(i) << '\n';
    std::cout << (int) bytewise::at(i, 1) << '\n';
    std::cout << (int) bytewise::at(i, 2) << '\n';
    */

    /*
    std::vector v {1, 2, 3};
    iterator it {v};
    iterator it2 {v};

    std::cout << *(it + 0) << '\n';
    std::cout << *(1 + it) << '\n';
    std::cout << *((it + 3) - 1) << '\n';
    */

    /*
    constexpr std::size_t buff_size = 16;
    void* raw_buff = std::malloc(sizeof(std::int32_t) * buff_size);
    std::int32_t* typed_buff = (std::int32_t*) raw_buff;
    api::asio::buffer buff {raw_buff, ASIOSTInt32LSB, buff_size};
    */

    /*
    std::cout << std::hex << buff[1].get_ptr<void>() << '\n';
    std::cout << std::hex << typed_buff + 1 << '\n';
    */

    /*
    buff[0] = 0;
    buff[1] = 0.5;
    buff[2] = 1;
    buff[3] = 0.5;
    buff[4] = 0;
    buff[5] = -0.5;
    buff[6] = -1;

    std::cout << typed_buff[0] << '\n';
    std::cout << typed_buff[1] << '\n';
    std::cout << typed_buff[2] << '\n';
    std::cout << typed_buff[3] << '\n';
    std::cout << typed_buff[4] << '\n';
    std::cout << typed_buff[5] << '\n';
    std::cout << typed_buff[6] << '\n';
    */

}