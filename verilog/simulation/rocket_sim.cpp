#include "Vtb.h"             // Include generated header file
#include "verilated.h"       // Verilator header
#include "verilated_vcd_c.h" // VCD dump support

int main(int argc, char **argv)
{
    Verilated::commandArgs(argc, argv); // Initialize Verilator arguments

    Vtb *tb = new Vtb; // Instantiate Verilog top module
    VerilatedVcdC *vcd = nullptr;

    // Enable waveform dump
    Verilated::traceEverOn(true);
    vcd = new VerilatedVcdC;
    tb->trace(vcd, 99);
    vcd->open("verilog/simulation/rocket.vcd");

    tb->clk = 0;
    tb->rst = 1;
    // Run simulation for 1000 cycles
    for (int i = 0; i < 1000; i++)
    {
        if (i == 10)
            tb->rst = 0; // Release reset

        tb->clk = !tb->clk; // Toggle clock every cycle
        tb->eval(); // Evaluate model
        vcd->dump(i);
    }

    vcd->close();
    delete vcd;
    delete tb;

    return 0;
}