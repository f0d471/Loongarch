`timescale 1ns / 1ps
//****************************************VSCODE PLUG-IN**********************************//
//----------------------------------------------------------------------------------------
// IDE :                   VSCODE     
// VSCODE plug-in version: Verilog-Hdl-Format-3.5.20250220
// VSCODE plug-in author : Jiang Percy
//----------------------------------------------------------------------------------------
//****************************************Copyright (c)***********************************//
// Copyright(C)            Please Write Company name
// All rights reserved     
// File name:              
// Last modified Date:     2025/06/16 13:49:36
// Last Version:           V1.0
// Descriptions:           
//----------------------------------------------------------------------------------------
// Created by:             Freddy 
// Created date:           2025/06/16 13:49:36
// mail      :             Please Write mail 
// Version:                V1.0
// TEXT NAME:              apb_gpio.v
// PATH:                   C:\Users\20676\Desktop\gpio_test\axi4lite_gpio\apb_gpio.v
// Descriptions:           
//                         
//----------------------------------------------------------------------------------------
//****************************************************************************************//
////////////////////////////////////////////////////////////////////////////////
// GPIO Register Map
//
// | Name  | Addr | Width | Access | Reset Value | Description                        |
// |-------|------|-------|--------|-------------|------------------------------------|
// | GPDAT | 0x00 | 32    | RW     | 0x00000000  | GPIO Data Register                 |
// | GPDIR | 0x04 | 32    | RW     | 0x00000000  | GPIO Direction Register 0-in 1-out |
// | GPIEN | 0x08 | 1     | RW     | 0x0         | GPIO Interrupt Enable              |
// | GPINT | 0x0C | 1     | RW     | 0x0         | GPIO Interrupt Status              |
////////////////////////////////////////////////////////////////////////////////

module apb_gpio( 
    input   wire            PCLK,     // Clock
    input   wire            PCLKG,    // Gated Clock
    input   wire            PRESETn,  // Reset
    input   wire            PSEL,     // Device select
    input   wire    [11:2]  PADDR,    // Address
    input   wire            PENABLE,  // Transfer control
    input   wire            PWRITE,   // Write control
    input   wire    [31:0]  PWDATA,   // Write data
    input   wire    [3:0]   ECOREVNUM,// Engineering-change-order revision bits
    output  wire    [31:0]  PRDATA,   // Read data
    output  wire            PREADY,   // Device ready
    output  wire            PSLVERR,  // Device error response
    input   wire    [31:0] 	iGPIN,
    output  wire    [31:0] 	oGPOUT,
    output	wire	        oINT,
    output	wire	        oERR
);

wire    read_enable, write_enable;
assign  read_enable  = PSEL & (~PWRITE) & PENABLE; // 读操作
assign  write_enable = PSEL & (~PENABLE) & PWRITE; // 写操作
wire [7:0] gpio_addr;
assign gpio_addr = {PADDR[9:2], 2'b00}; // 使用低8位地址

GPCORE u_GPCORE(
  .iCLK  (PCLK),            //input		   时钟	    
  .iRSTN (PRESETn),         //input		   复位信号           
  .iWADR (gpio_addr),       //input [7:0]  写地址		  
  .iWR   (write_enable),    //input	       写使能		       
  .iWDAT (PWDATA),          //input [31:0] 写数据 		  
  .iRADR (gpio_addr),       //input [7:0]  读地址		  
  .oRDAT (PRDATA),          //output[31:0] 读数据		         
  .iGPIN (iGPIN),           //input [31:0] GPIO输入端口		  
  .oGPOUT(oGPOUT),          //output[31:0] GPIO输出端口		  
  .oINT  (oINT),            //output	   中断输出     
  .oERR  (oERR)             //output	   错误输出      
);

assign  PREADY = 1'b1;
assign  PSLVERR = 1'b0;
                                                                  

endmodule



