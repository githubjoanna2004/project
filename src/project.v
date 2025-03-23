/*
 * Copyright- (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module tt_um_adder_multiplier(
    input  wire [7:0] ui_in,    // Dedicated inputs
    output wire [7:0] uo_out,   // Dedicated outputs
    input  wire [7:0] uio_in,   // IOs: Input path
    output wire [7:0] uio_out,  // IOs: Output path
    output wire [7:0] uio_oe,   // IOs: Enable path (active high: 0=input, 1=output)
    input  wire       ena,      // always 1 when the design is powered, so you can ignore it
    input  wire       clk,      // clock
    input  wire       rst_n     // reset_n - low to reset
);
    wire [3:0] adder_output;
    wire[5:0] multiplier_output;
    kogge_stone_adder_3bit adder_inst(
        .A(ui_in[2:0]),
        .B(ui_in[5:3]),
        .Enable(ui_in[6]),
        .Sum_Carry(adder_output)
    );
    array_multiplier_3bit multiplier_inst(
        .A(ui_in[2:0]),
        .B(ui_in[5:3]),
        .Enable(ui_in[6]),
        .Product(multiplier_output)
    );
    assign uo_out[5:0] = ui_in[6]? {2'b00,adder_output}:multiplier_output;
    assign uo_out[7:6]=2'b00;

  // All output pins must be assigned. If not used, assign to 0.
  //assign uo_out  = ui_in + uio_in;  // Example: ou_out is the sum of ui_in and uio_in
   // assign uo_out[0] = ui_in[0] ^ ui_in[1] ^ ui_in[2];
  //  assign uo_out[1] = (ui_in[0] & ui_in[1]) |(ui_in[0] & ui_in[2]) |(ui_in[1] & ui_in[2]);
 //   assign uo_out[7:2] = 6'b0;
  assign uio_out = 0;
  assign uio_oe  = 0;

  // List all unused inputs to prevent warnings
  wire _unused =  &{ena, clk, rst_n, 1'b0};

endmodule
// ----------------- 3-BIT KOGGE-STONE ADDER -----------------
module kogge_stone_adder_3bit (
    input  wire [2:0] A, B,
    input  wire Enable,
    output wire [3:0] Sum_Carry  // {Cout, Sum[2:0]}
);
    wire [2:0] G, P, C; // Generate, Propagate, Carry
    wire [2:0] sum;
    wire cout;

    // Step 1: Compute Generate and Propagate
    assign G = A & B;  // Generate (Gi = Ai * Bi)
    assign P = A ^ B;  // Propagate (Pi = Ai ⊕ Bi)

    // Step 2: Parallel Prefix Carry Computation (Gray & Black Cells)
    wire G1_0, P1_0;  // First level (pairwise)
    assign G1_0 = G[1] | (P[1] & G[0]);
    assign P1_0 = P[1] & P[0];

    wire G2_0;  // Second level (final carry)
    assign G2_0 = G[2] | (P[2] & G1_0);

    // Step 3: Compute Carry Bits
    assign C[0] = 1'b0;   // No carry-in for first bit
    assign C[1] = G[0];   // First carry
    assign C[2] = G1_0;   // Second carry
    assign cout  = G2_0;  // Final carry out

    // Step 4: Compute Sum
    assign sum = P ^ C;

    // Step 5: Assign Output (Enable Control)
    assign Sum_Carry = Enable ? {cout, sum} : 4'b0000;

endmodule 
// ----------------- Array Multiplier (3-bit x 3-bit) -----------------
module array_multiplier_3bit (
    input wire [2:0] A,      // 3-bit Input A
    input wire [2:0] B,      // 3-bit Input B
    input wire Enable,       // Enable signal
    output reg [5:0] Product      // 6-bit Product Output
);

    wire [2:0] pp0, pp1, pp2;     // Partial products
    wire [5:0] sum1, sum2, product1; // Intermediate sums and final product

    // Generate partial products (AND each bit of A with the entire B)
    assign pp0 = A[0] ? B : 3'b000;   // Partial product 0 (A[0] * B)
    assign pp1 = A[1] ? B : 3'b000;   // Partial product 1 (A[1] * B)
    assign pp2 = A[2] ? B : 3'b000;   // Partial product 2 (A[2] * B)

    // Shift and add partial products
    assign sum1 = {2'b00, pp0} + {pp1, 1'b0};  // Shift pp1 left by 1 and add to pp0
    assign sum2 = sum1 + {pp2, 2'b00};         // Shift pp2 left by 2 and add to sum1

    // Assign product
    assign product1 = sum2;

    // Always block to output product when Enable is 0 and output 0 when Enable is 1
    always @(*) begin
        if (Enable) begin
            Product = 6'b000000;  // If Enable is 1, output 0 (disabled state)
        end else begin
            Product = product1;    // If Enable is 0, output the product
        end
    end
endmodule
