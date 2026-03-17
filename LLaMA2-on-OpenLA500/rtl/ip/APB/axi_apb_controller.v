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

// axi_apb_controller: AXI-to-APB bridge controller for APB peripherals
// Renamed from axi_uart_controller to reflect multi-device APB bus.
// Contains: axi2apb_bridge + apb_mux2 + UART0 (apb dev0) + GPIO/SPI/WDT (apb dev1 sub-decode)
//
// APB Device Address Map (within 0x1F00_0000 region):
//   dev0 (UART): offset 0x0000 ~ 0x3FFF  (addr[19:14] == 6'h00)
//   dev1 (sub decode by addr[13:12]):
//     2'b00: GPIO base 0x1F00_4000
//     2'b01: SPI  base 0x1F00_5000
//     2'b10: WDT  base 0x1F00_6000
//   GPIO registers at absolute address 0x1F00_4000:
//     GPDAT: 0x1F004000
//     GPDIR: 0x1F004004
//     GPIEN: 0x1F004008
//     GPINT: 0x1F00400C

`include "config.h"

module axi_apb_controller
(
clk,
rst_n,

axi_s_awid,
axi_s_awaddr,
axi_s_awlen,
axi_s_awsize,
axi_s_awburst,
axi_s_awlock,
axi_s_awcache,
axi_s_awprot,
axi_s_awvalid,
axi_s_awready,
axi_s_wid,
axi_s_wdata,
axi_s_wstrb,
axi_s_wlast,
axi_s_wvalid,
axi_s_wready,
axi_s_bid,
axi_s_bresp,
axi_s_bvalid,
axi_s_bready,
axi_s_arid,
axi_s_araddr,
axi_s_arlen,
axi_s_arsize,
axi_s_arburst,
axi_s_arlock,
axi_s_arcache,
axi_s_arprot,
axi_s_arvalid,
axi_s_arready,
axi_s_rid,
axi_s_rdata,
axi_s_rresp,
axi_s_rlast,
axi_s_rvalid,
axi_s_rready,

apb_rw_dma,
apb_psel_dma,
apb_enab_dma,
apb_addr_dma,
apb_valid_dma,
apb_wdata_dma,
apb_rdata_dma,
apb_ready_dma,
dma_grant,

dma_req_o,
dma_ack_i,

uart0_txd_i,
uart0_txd_o,
uart0_txd_oe,
uart0_rxd_i,
uart0_rxd_o,
uart0_rxd_oe,
uart0_rts_o,
uart0_dtr_o,
uart0_cts_i,
uart0_dsr_i,
uart0_dcd_i,
uart0_ri_i,

uart0_int,

gpio_in,
gpio_out,
gpio_int,

spi_miso_i,
spi_mosi_o,
spi_sclk_o,

wdt_int,
wdt_res
);

parameter ADDR_APB = 20,
          DATA_APB = 8;

input          clk;
input                  rst_n;

input  [`LID            :0] axi_s_awid;
input  [`Lawaddr     -1 :0] axi_s_awaddr;
input  [`Lawlen      -1 :0] axi_s_awlen;
input  [`Lawsize     -1 :0] axi_s_awsize;
input  [`Lawburst    -1 :0] axi_s_awburst;
input  [`Lawlock     -1 :0] axi_s_awlock;
input  [`Lawcache    -1 :0] axi_s_awcache;
input  [`Lawprot     -1 :0] axi_s_awprot;
input                       axi_s_awvalid;
output                      axi_s_awready;
input  [`LID            :0] axi_s_wid;
input  [`Lwdata      -1 :0] axi_s_wdata;
input  [`Lwstrb      -1 :0] axi_s_wstrb;
input                       axi_s_wlast;
input                       axi_s_wvalid;
output                      axi_s_wready;
output [`LID            :0] axi_s_bid;
output [`Lbresp      -1 :0] axi_s_bresp;
output                      axi_s_bvalid;
input                       axi_s_bready;
input  [`LID            :0] axi_s_arid;
input  [`Laraddr     -1 :0] axi_s_araddr;
input  [`Larlen      -1 :0] axi_s_arlen;
input  [`Larsize     -1 :0] axi_s_arsize;
input  [`Larburst    -1 :0] axi_s_arburst;
input  [`Larlock     -1 :0] axi_s_arlock;
input  [`Larcache    -1 :0] axi_s_arcache;
input  [`Larprot     -1 :0] axi_s_arprot;
input                       axi_s_arvalid;
output                      axi_s_arready;
output [`LID            :0] axi_s_rid;
output [`Lrdata      -1 :0] axi_s_rdata;
output [`Lrresp      -1 :0] axi_s_rresp;
output                      axi_s_rlast;
output                      axi_s_rvalid;
input                       axi_s_rready;

output                 apb_ready_dma;
input                  apb_rw_dma;
input                  apb_psel_dma;
input                  apb_enab_dma;
input [ADDR_APB-1:0]   apb_addr_dma;
input [31:0]   	       apb_wdata_dma;
output[31:0]   	       apb_rdata_dma;
input                  apb_valid_dma;
output                 dma_grant;

output                 dma_req_o;
input                  dma_ack_i;

input               uart0_txd_i;
output              uart0_txd_o;
output              uart0_txd_oe;
input               uart0_rxd_i;
output              uart0_rxd_o;
output              uart0_rxd_oe;
output              uart0_rts_o;
output              uart0_dtr_o;
input               uart0_cts_i;
input               uart0_dsr_i;
input               uart0_dcd_i;
input               uart0_ri_i;

output uart0_int;

input  [15:0] gpio_in;
output [15:0] gpio_out;
output        gpio_int;

input         spi_miso_i;
output        spi_mosi_o;
output        spi_sclk_o;

output        wdt_int;
output        wdt_res;

assign  dma_req_o      = 1'b0;
assign  nand_dma_ack_i = dma_ack_i; 

// Internal APB signals (CPU side, from axi2apb bridge)
wire                    apb_ready_cpu;
wire                    apb_rw_cpu;
wire                    apb_psel_cpu;
wire                    apb_enab_cpu;
wire [ADDR_APB-1 :0]    apb_addr_cpu;
wire [DATA_APB-1:0]     apb_datai_cpu;
wire [DATA_APB-1:0]     apb_datao_cpu;
wire                    apb_clk_cpu;
wire                    apb_reset_n_cpu; 
wire                    apb_word_trans_cpu;
wire                    apb_valid_cpu;
wire                    dma_grant;
wire  [23:0]            apb_high_24b_rd;
wire  [23:0]            apb_high_24b_wr;

wire                    apb_rw_dma;
wire                    apb_psel_dma;
wire                    apb_enab_dma;
wire [31:0]             apb_wdata_dma;
wire [31:0]             apb_rdata_dma;
wire                    apb_clk_dma;
wire                    apb_reset_n_dma; 

// APB device 0: UART
wire                apb_uart0_req;
wire                apb_uart0_ack;
wire                apb_uart0_rw;
wire                apb_uart0_enab;
wire                apb_uart0_psel;
wire  [ADDR_APB -1:0] apb_uart0_addr;
wire  [DATA_APB -1:0] apb_uart0_datai;
wire  [DATA_APB -1:0] apb_uart0_datao;

// APB device 1: GPIO
wire                apb_gpio0_req; 
wire                apb_gpio0_ack; 
wire                apb_gpio0_rw; 
wire                apb_gpio0_enab; 
wire                apb_gpio0_psel; 
wire  [ADDR_APB -1:0] apb_gpio0_addr; 
wire  [31:0]        apb_gpio0_datai; 
wire  [31:0]        apb_gpio0_datao; 

wire                apb_gpio_psel;
wire                apb_gpio_enab;
wire [31:0]         apb_gpio_datao;

wire                apb_spi_psel;
wire                apb_spi_enab;
wire [31:0]         apb_spi_datao;

wire                apb_wdt_psel;
wire                apb_wdt_enab;
wire [31:0]         apb_wdt_datao;

wire                apb_gpio_sel;
wire                apb_spi_sel;
wire                apb_wdt_sel;

axi2apb_bridge AA_axi2apb_bridge_cpu 
(
.clk                (clk                ),
.rst_n              (rst_n              ),
.axi_s_awid         (axi_s_awid         ),
.axi_s_awaddr       (axi_s_awaddr       ),
.axi_s_awlen        (axi_s_awlen        ),
.axi_s_awsize       (axi_s_awsize       ),
.axi_s_awburst      (axi_s_awburst      ),
.axi_s_awlock       (axi_s_awlock       ),
.axi_s_awcache      (axi_s_awcache      ),
.axi_s_awprot       (axi_s_awprot       ),
.axi_s_awvalid      (axi_s_awvalid      ),
.axi_s_awready      (axi_s_awready      ),
.axi_s_wid          (axi_s_wid          ),
.axi_s_wdata        (axi_s_wdata        ),
.axi_s_wstrb        (axi_s_wstrb        ),
.axi_s_wlast        (axi_s_wlast        ),
.axi_s_wvalid       (axi_s_wvalid       ),
.axi_s_wready       (axi_s_wready       ),
.axi_s_bid          (axi_s_bid          ),
.axi_s_bresp        (axi_s_bresp        ),
.axi_s_bvalid       (axi_s_bvalid       ),
.axi_s_bready       (axi_s_bready       ),
.axi_s_arid         (axi_s_arid         ),
.axi_s_araddr       (axi_s_araddr       ),
.axi_s_arlen        (axi_s_arlen        ),
.axi_s_arsize       (axi_s_arsize       ),
.axi_s_arburst      (axi_s_arburst      ),
.axi_s_arlock       (axi_s_arlock       ),
.axi_s_arcache      (axi_s_arcache      ),
.axi_s_arprot       (axi_s_arprot       ),
.axi_s_arvalid      (axi_s_arvalid      ),
.axi_s_arready      (axi_s_arready      ),
.axi_s_rid          (axi_s_rid          ),
.axi_s_rdata        (axi_s_rdata        ),
.axi_s_rresp        (axi_s_rresp        ),
.axi_s_rlast        (axi_s_rlast        ),
.axi_s_rvalid       (axi_s_rvalid       ),
.axi_s_rready       (axi_s_rready       ),

.apb_word_trans     (apb_word_trans_cpu ),
.apb_high_24b_rd    (apb_high_24b_rd    ),
.apb_high_24b_wr    (apb_high_24b_wr    ),
.apb_valid_cpu      (apb_valid_cpu      ),
.cpu_grant          (~dma_grant         ),

.apb_clk            (apb_clk_cpu        ),
.apb_reset_n        (apb_reset_n_cpu    ),
.reg_psel           (apb_psel_cpu       ),
.reg_enable         (apb_enab_cpu       ),
.reg_rw             (apb_rw_cpu         ),
.reg_addr           (apb_addr_cpu       ),
.reg_datai          (apb_datai_cpu      ),
.reg_datao          (apb_datao_cpu      ),
.reg_ready_1        (apb_ready_cpu      )
);

apb_mux2 u_apb_mux2
(
.clk                (clk                ),
.rst_n              (rst_n              ),
.apb_ready_dma      (apb_ready_dma      ),
.apb_rw_dma         (apb_rw_dma         ),
.apb_addr_dma       (apb_addr_dma       ),
.apb_psel_dma       (apb_psel_dma       ),
.apb_enab_dma       (apb_enab_dma       ),
.apb_wdata_dma      (apb_wdata_dma      ),
.apb_rdata_dma      (apb_rdata_dma      ),
.apb_valid_dma      (apb_valid_dma      ),
.apb_valid_cpu      (apb_valid_cpu      ),
.dma_grant          (dma_grant          ),

.apb_ack_cpu        (apb_ready_cpu      ),
.apb_rw_cpu         (apb_rw_cpu         ),
.apb_addr_cpu       (apb_addr_cpu       ),
.apb_psel_cpu       (apb_psel_cpu       ),
.apb_enab_cpu       (apb_enab_cpu       ),
.apb_datai_cpu      (apb_datai_cpu      ),
.apb_datao_cpu      (apb_datao_cpu      ),
.apb_high_24b_rd    (apb_high_24b_rd),
.apb_high_24b_wr    (apb_high_24b_wr),
.apb_word_trans_cpu (apb_word_trans_cpu ),

.apb0_req           (apb_uart0_req      ),
.apb0_ack           (apb_uart0_ack      ),
.apb0_rw            (apb_uart0_rw       ),
.apb0_psel          (apb_uart0_psel     ),
.apb0_enab          (apb_uart0_enab     ),
.apb0_addr          (apb_uart0_addr     ),
.apb0_datai         (apb_uart0_datai    ),
.apb0_datao         (apb_uart0_datao    ),
                                        
.apb1_req           (apb_gpio0_req      ),
.apb1_ack           (apb_gpio0_ack      ),
.apb1_rw            (apb_gpio0_rw       ),
.apb1_enab          (apb_gpio0_enab     ),
.apb1_psel          (apb_gpio0_psel     ),
.apb1_addr          (apb_gpio0_addr     ),
.apb1_datai         (apb_gpio0_datai    ),
.apb1_datao         (apb_gpio0_datao    )
                                        
);

//----------------------------------------------------------------------
// APB Device 0: UART0  (addr[19:14] == 6'h00, offset 0x0000~0x3FFF)
//----------------------------------------------------------------------
assign apb_uart0_ack = apb_uart0_enab;
UART_TOP uart0
(
.PCLK              (clk              ),
.clk_carrier       (1'b0             ),
.PRST_             (rst_n            ),
.PSEL              (apb_uart0_psel   ),
.PENABLE           (apb_uart0_enab   ),
.PADDR             (apb_uart0_addr[7:0] ),
.PWRITE            (apb_uart0_rw     ),
.PWDATA            (apb_uart0_datai  ),
.URT_PRDATA        (apb_uart0_datao  ),
.INT               (uart0_int         ),
.TXD_o             (uart0_txd_o       ),
.TXD_i             (uart0_txd_i       ),
.TXD_oe            (uart0_txd_oe      ),
.RXD_o             (uart0_rxd_o       ),
.RXD_i             (uart0_rxd_i       ),
.RXD_oe            (uart0_rxd_oe      ),
.RTS               (uart0_rts_o       ),
.CTS               (uart0_cts_i       ),
.DSR               (uart0_dsr_i       ),
.DCD               (uart0_dcd_i       ),
.DTR               (uart0_dtr_o       ),
.RI                (uart0_ri_i        )
);

//----------------------------------------------------------------------
// APB Device 1 sub decode (GPIO/SPI/WDT)
//----------------------------------------------------------------------
assign apb_gpio_sel = (apb_gpio0_addr[13:12] == 2'b00);
assign apb_spi_sel  = (apb_gpio0_addr[13:12] == 2'b01);
assign apb_wdt_sel  = (apb_gpio0_addr[13:12] == 2'b10);

assign apb_gpio_psel = apb_gpio0_psel & apb_gpio_sel;
assign apb_spi_psel  = apb_gpio0_psel & apb_spi_sel;
assign apb_wdt_psel  = apb_gpio0_psel & apb_wdt_sel;

assign apb_gpio_enab = apb_gpio0_enab & apb_gpio_sel;
assign apb_spi_enab  = apb_gpio0_enab & apb_spi_sel;
assign apb_wdt_enab  = apb_gpio0_enab & apb_wdt_sel;

assign apb_gpio0_ack = apb_gpio0_enab;
assign apb_gpio0_datao = apb_gpio_sel ? apb_gpio_datao :
                         apb_spi_sel  ? apb_spi_datao  :
                         apb_wdt_sel  ? apb_wdt_datao  :
                         32'h0;

// GPIO: 0x1F00_4000 ~ 0x1F00_4FFF
apb_gpio u_apb_gpio
(
.PCLK              (clk                    ),
.PCLKG             (clk                    ),
.PRESETn           (rst_n                  ),
.PSEL              (apb_gpio_psel          ),
.PADDR             (apb_gpio0_addr[11:2]   ),
.PENABLE           (apb_gpio_enab          ),
.PWRITE            (apb_gpio0_rw           ),
.PWDATA            (apb_gpio0_datai        ),
.ECOREVNUM         (4'b0                   ),
.PRDATA            (apb_gpio_datao         ),
.PREADY            (                       ),
.PSLVERR           (                       ),
.iGPIN             (gpio_in                ),
.oGPOUT            (gpio_out               ),
.oINT              (gpio_int               ),
.oERR              (                       )
);

// SPI: 0x1F00_5000 ~ 0x1F00_5FFF
spi_top u_apb_spi
(
.PCLK              (clk                    ),
.PCLKG             (clk                    ),
.PRESETn           (rst_n                  ),
.PSEL              (apb_spi_psel           ),
.PADDR             (apb_gpio0_addr[11:2]   ),
.PENABLE           (apb_spi_enab           ),
.PWRITE            (apb_gpio0_rw           ),
.PWDATA            (apb_gpio0_datai        ),
.ECOREVNUM         (4'b0                   ),
.PRDATA            (apb_spi_datao          ),
.PREADY            (                       ),
.PSLVERR           (                       ),
.MISO              (spi_miso_i             ),
.MOSI              (spi_mosi_o             ),
.SCLK              (spi_sclk_o             )
);

// WDT: 0x1F00_6000 ~ 0x1F00_6FFF
apb_wdt_top u_apb_wdt
(
.PCLK              (clk                    ),
.PRESETn           (rst_n                  ),
.PSEL              (apb_wdt_psel           ),
.PADDR             (apb_gpio0_addr[11:2]   ),
.PENABLE           (apb_wdt_enab           ),
.PWRITE            (apb_gpio0_rw           ),
.PWDATA            (apb_gpio0_datai        ),
.PRDATA            (apb_wdt_datao          ),
.PREADY            (                       ),
.PSLVERR           (                       ),
.WDT_INT           (wdt_int                ),
.WDT_RES           (wdt_res                )
);

endmodule
