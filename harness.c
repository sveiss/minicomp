#include <stdio.h>

void run_tests(); // defined in generated .c runner script

int out_status = 0;

void run_test(int (*sut)(), int expected, const char *name)
{
    int actual = sut();
    if (actual != expected)
    {
        printf("F: %s\tE: %d\tA: %d\n", name, actual, expected);
        out_status = 1;
    }
}

int main()
{
    run_tests();
    return out_status;
}
