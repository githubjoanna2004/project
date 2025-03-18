/*
 * Copyright (c) 2024 Your Name
 * SPDX-License-Identifier: Apache-2.0
 */

`default_nettype none

module top_module (
    input wire [2:0] A, B,
    input wire Enable,  // 1 -> Adder, 0 -> Multiplier
    output wire [5:0] Result
);
    wire [3:0] sum_carry;  // Stores {Cout, Sum[2:0]}
    wire [5:0] product;

    // Instantiate Kogge-Stone Adder
    kogge_stone_adder_3bit adder (
        .A(A),
        .B(B),
        .Enable(Enable),
        .Sum_Carry(sum_carry)
    );

    // Instantiate 3-bit Array Multiplier
    array_multiplier_3bit multiplier (
        .A(A),
        .B(B),
        .Enable(Enable),
        .P(product)
    );

    // Assign result based on Enable
    assign Result = Enable ? {2'b00, sum_carry} : product; 

endmodule


// ----------------- KOGGE-STONE ADDER -----------------
module kogge_stone_adder_3bit (
    input  wire [2:0] A, B,
    input  wire Enable,
    output wire [3:0] Sum_Carry  // {Cout, Sum[2:0]}
);
    wire [2:0] G, P, C;
    wire [2:0] sum;
    wire cout;

    // Generate and Propagate
    assign G = A & B;  // Generate
    assign P = A ^ B;  // Propagate

    // Compute Carry
    assign C[0] = 1'b0;
    assign C[1] = G[0] | (P[0] & C[0]);
    assign C[2] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & C[0]);
    assign cout = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & C[0]);

    // Compute Sum
    assign sum = P ^ C;

    // Assign result based on Enable
    assign Sum_Carry = Enable ? {cout, sum} : 4'b0000;

endmodule


// ----------------- ARRAY MULTIPLIER -----------------
module array_multiplier_3bit (
    input wire [2:0] A,
    input wire [2:0] B,
    input wire Enable,
    output wire [5:0] P
);
    wire [2:0] pp0, pp1, pp2;
    wire [5:0] sum1, sum2, product;

    // Generate partial products
    assign pp0 = A[0] ? B : 3'b000;
    assign pp1 = A[1] ? B : 3'b000;
    assign pp2 = A[2] ? B : 3'b000;

    // Shift and add partial products
    assign sum1 = {2'b00, pp0} + {pp1, 1'b0};  // Shift pp1 left by 1 bit
    assign sum2 = sum1 + {pp2, 2'b00};        // Shift pp2 left by 2 bits
    assign product = sum2;

    // Assign result based on Enable
    assign P = Enable ? 6'b000000 : product;

endmodule
