/*------------------------------------------------------------------------------
--------------------------------------------------------------------------------
Copyright (c) 2016, Loongson Technology Corporation Limited.

All rights reserved.

Redistribution and use in source and binary forms, with or without modification,
are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this 
list of conditions and the following disclaimer.

2. Redistributions in binary form must reproduce the above copyright notice, 
this list of conditions and the following disclaimer in the documentation and/or
other materials provided with the distribution.

3. Neither the name of Loongson Technology Corporation Limited nor the names of 
its contributors may be used to endorse or promote products derived from this 
software without specific prior written permission.

THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND 
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED 
WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE 
DISCLAIMED. IN NO EVENT SHALL LOONGSON TECHNOLOGY CORPORATION LIMITED BE LIABLE
TO ANY PARTY FOR DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR 
CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE 
GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) 
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT 
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF
THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
--------------------------------------------------------------------------------
------------------------------------------------------------------------------*/

`include "config.h"
`include "iopad.svh"

module soc_top #(parameter SIMULATION=1'b0)
(
    input           clk,                //50MHz 时钟输入
    output          clk_o,              //XTALO
    input           reset,              //BTN6手动复位按钮开关，带消抖电路，按下时为1

    input  [3:0]    touch_btn,          //BTN1~BTN4，按钮开关，按下时为1
    input  [31:0]   dip_sw,             //32位拨码开关，拨到“ON”时为1
    output [15:0]   leds,               //16位LED，输出时1点亮
    output [7:0]    dpy0,               //数码管低位信号，包括小数点，输出1点亮
    output [7:0]    dpy1,               //数码管高位信号，包括小数点，输出1点亮

    //BaseRAM信号
    inout  [31:0]   base_ram_data,      //BaseRAM数据，低8位与CPLD串口控制器共享
    output [19:0]   base_ram_addr,      //BaseRAM地址
    output [ 3:0]   base_ram_be_n,      //BaseRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output          base_ram_ce_n,      //BaseRAM片选，低有效
    output          base_ram_oe_n,      //BaseRAM读使能，低有效
    output          base_ram_we_n,      //BaseRAM写使能，低有效
    //ExtRAM信号
    inout  [31:0]   ext_ram_data,       //ExtRAM数据
    output [19:0]   ext_ram_addr,       //ExtRAM地址
    output [ 3:0]   ext_ram_be_n,       //ExtRAM字节使能，低有效。如果不使用字节使能，请保持为0
    output          ext_ram_ce_n,       //ExtRAM片选，低有效
    output          ext_ram_oe_n,       //ExtRAM读使能，低有效
    output          ext_ram_we_n,       //ExtRAM写使能，低有效

    //------uart-------
    inout           UART_RX,            //串口RX接收
    inout           UART_TX             //串口TX发送
);


wire clk_i;
PX3W PAD_CLK_IN (.XIN(clk), .XOUT(clk_o), .XC(clk_i));
`IPADU_GEN_SIMPLE(reset)
`IPAD_GEN_VEC_SIMPLE(touch_btn)
`IPAD_GEN_VEC_SIMPLE(dip_sw)
`OPAD_GEN_VEC_SIMPLE(leds)
`OPAD_GEN_VEC_SIMPLE(dpy0)
`OPAD_GEN_VEC_SIMPLE(dpy1)
`IOPAD_GEN_VEC_SIMPLE(base_ram_data)
`OPAD_GEN_VEC_SIMPLE(base_ram_addr)
`OPAD_GEN_VEC_SIMPLE(base_ram_be_n)
`OPAD_GEN_SIMPLE(base_ram_ce_n)
`OPAD_GEN_SIMPLE(base_ram_oe_n)
`OPAD_GEN_SIMPLE(base_ram_we_n)
`IOPAD_GEN_VEC_SIMPLE(ext_ram_data)
`OPAD_GEN_VEC_SIMPLE(ext_ram_addr)
`OPAD_GEN_VEC_SIMPLE(ext_ram_be_n)
`OPAD_GEN_SIMPLE(ext_ram_ce_n)
`OPAD_GEN_SIMPLE(ext_ram_oe_n)
`OPAD_GEN_SIMPLE(ext_ram_we_n)
`IOPAD_GEN_SIMPLE(UART_RX)
`IOPAD_GEN_SIMPLE(UART_TX)

wire cpu_clk;
wire cpu_resetn;
wire sys_clk;
wire sys_resetn;

generate if(SIMULATION) begin: sim_clk
    //simulation clk.
    reg clk_sim;
    initial begin
        clk_sim = 1'b0;
    end
    always #15 clk_sim = ~clk_sim;

    assign cpu_clk = clk_sim;
    assign sys_clk = clk_i;
    rst_sync u_rst_sys(
        .clk(sys_clk),
        .rst_n_in(~reset_i),
        .rst_n_out(sys_resetn)
    );
    rst_sync u_rst_cpu(
        .clk(cpu_clk),
        .rst_n_in(sys_resetn),
        .rst_n_out(cpu_resetn)
    );
end
else begin: pll_clk
    clk_pll u_clk_pll(
        .cpu_clk    (cpu_clk),
        .sys_clk    (sys_clk),
        .resetn     (~reset_i),
        .locked     (pll_locked),
        .clk_in1    (clk_i)
    );
    rst_sync u_rst_sys(
        .clk(sys_clk),
        .rst_n_in(pll_locked),
        .rst_n_out(sys_resetn)
    );
    rst_sync u_rst_cpu(
        .clk(cpu_clk),
        .rst_n_in(sys_resetn),
        .rst_n_out(cpu_resetn)
    );
end
endgenerate

//TODO: add your code

endmodule

