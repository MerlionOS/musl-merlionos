/*
 * Hello C++ — demonstrates C++ standard library on MerlionOS.
 *
 * Compile (after building libc++):
 *   clang++ -static -nostdinc++ -I../sysroot/include/c++/v1 \
 *       -L../sysroot/lib -lc++ -lc++abi -lc \
 *       -fno-exceptions -o hello_cpp hello_cpp.cpp
 *
 * Run on MerlionOS:
 *   run-user hello_cpp
 */
#include <cstdio>
#include <string>
#include <vector>
#include <map>

int main() {
    // std::string
    std::string greeting = "Hello from C++ on MerlionOS!";
    printf("%s\n", greeting.c_str());

    // std::vector
    std::vector<int> nums = {1, 2, 3, 4, 5};
    printf("Vector: ");
    for (int n : nums) {
        printf("%d ", n);
    }
    printf("\n");

    // std::map
    std::map<std::string, int> ages;
    ages["Alice"] = 30;
    ages["Bob"] = 25;
    ages["MerlionOS"] = 0;
    printf("Map entries: %zu\n", ages.size());

    // String formatting
    std::string result = "Computed " + std::to_string(nums.size()) + " items";
    printf("%s\n", result.c_str());

    printf("C++ stdlib works on MerlionOS!\n");
    return 0;
}
