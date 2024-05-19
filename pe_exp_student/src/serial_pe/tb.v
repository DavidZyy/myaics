`timescale 1ns / 1ps

module tb;

// Inputs
reg clk;
reg rst_n;
reg signed [15:0] neuron;
reg signed [15:0] weight;
reg [1:0] ctl;
reg vld_i;

// Outputs
wire [31:0] result;
wire vld_o;

// Instantiate the module under test
serial_pe uut (
    .clk(clk),
    .rst_n(rst_n),
    .neuron(neuron),
    .weight(weight),
    .ctl(ctl),
    .vld_i(vld_i),
    .result(result),
    .vld_o(vld_o)
);

// Test stimulus
initial begin
    // Dumping VCD file
    $dumpfile("tb.vcd");
    $dumpvars(0, tb);

    clk = 0;
    rst_n = 0;
    neuron = 16'd5;
    weight = 16'd3;
    ctl = 2'b00;
    vld_i = 0;
    
    #10; // Allow one clock cycle for reset to settle
    rst_n = 1;
    
    // Test case 1: Basic multiplication and addition
    vld_i = 1;
    ctl = 2'b01;
    #10; // Wait for one clock cycle
    $display("Result: %h, vld_o: %b", result, vld_o);

    // Test case 2: Control signal for bypassing addition (ctl[0])
    ctl = 2'b00;
    #10; // Wait for one clock cycle
    $display("Result: %h, vld_o: %b", result, vld_o);

    // Test case 3: Control signal for enabling vld_o (ctl[1])
    ctl = 2'b10;
    vld_i = 1;
    #10; // Wait for one clock cycle
    $display("Result: %h, vld_o: %b", result, vld_o);

    // Terminate the simulation
    $finish;
end

// Clock generation
always #5 clk = ~clk;

endmodule
