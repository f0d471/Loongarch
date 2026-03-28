
module GPCORE (
  // 系统接口
    input   wire            PCLK,     // 时钟
    input   wire            PCLKG,    // Gated Clock
    input   wire            PRESETn,  // 系统复位
    input   wire            PSEL,     // Device select
    input   wire    [11:2]  PADDR,    // Address
    input   wire            PENABLE,  // Transfer control
    input   wire            PWRITE,   // 写使能
    input   wire    [31:0]  PWDATA,   // 写数据
    input   wire    [3:0]   ECOREVNUM,// Engineering-change-order revision bits
    output  wire    [31:0]  PRDATA,   // 读数据
    output  wire            PREADY,   // Device ready
    output  wire            PSLVERR,  // Device error response
  // GPIO接口
  input [31:0]  iGPIN,     // GPIO输入信号(32位)
  output[31:0]  oGPOUT,    // GPIO输出信号(32位)
  output        oINT,      // 中断输出信号
  // 错误指示
  output        oERR       // 寄存器访问错误指示
);
  //------------
  // 内部寄存器定义
  //------------
  reg[31:0]    rGpDat;    // GPIO数据寄存器 ： 存储值
  reg[31:0]    rGpDir;    // GPIO方向寄存器 ： 1=输入，0=输出  控制输出位
  reg          rGpIen;    // 中断使能寄存器  ： 
  reg          rGpInt;    // 中断状态寄存器  ： 
  reg          rGpClr;    // 中断清除标志
  reg[7:0]     regAdr;           // 当前访问的寄存器地址
  reg[31:0]    regDat, regDatQ;  // 读数据寄存器和输出寄存器
  reg          isErr, isErrQ;    // 错误标志寄存器和输出寄存器
  // 中断逻辑生成相关的
  wire[31:0]   gpInDir;   // 方向为输入的GPIO输入值
  reg          gpInt;     // 中断生成逻辑
  //-------------
  // 寄存器地址定义
  //-------------
  parameter[9:0] 
    GPDAT = 10'h0,   // GPIO数据寄存器地址
    GPDIR = 10'h1,   // GPIO方向寄存器地址
    GPIEN = 10'h2,   // 中断使能寄存器地址
    GPINT = 10'h3;   // 中断状态寄存器地址
  
  //------------
  // 输出信号赋值
  //------------
  assign oRDAT  = regDatQ;  // 读数据输出
  assign oERR   = isErrQ;   // 错误指示输出
  assign oINT   = rGpInt;   // 中断信号输出
  // GPIO输出值 = 数据寄存器值 & 方向为输出的位
  assign oGPOUT = rGpDat & ~rGpDir;
  assign PRDATA = regDatQ;  // AXI4-Lite读数据输出
  assign PREADY = 1'b1;     // 始终准备好
  assign PSLVERR = isErrQ;  // 错误响应

reg [31:0] iGPIN_d1;
reg [31:0] iGPIN_d2;

always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
      iGPIN_d1 <= 32'h0;
    end
    else begin
      iGPIN_d1 <= iGPIN;
    end
end

always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
      iGPIN_d2 <= 32'h0;
    end
    else begin
      iGPIN_d2 <= iGPIN_d1;
    end
end

wire [31:0] iGPIN_vary = iGPIN_d1 ^ iGPIN_d2;

  //-----------
  //中断逻辑
  //-----------
  // 有效的输入信号
  assign gpInDir = rGpDir & iGPIN_vary;
  // 中断生成逻辑：当中断使能(rGpIen为1)且至少有一个配置为输入的GPIO有信号时，gpInt为1
  always @* gpInt = (rGpIen & |gpInDir);
  // 中断状态寄存器
  always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
      rGpInt <= 1'b0;  // 复位时清除中断
    end
    else begin
      if (~rGpInt) begin             
        // 当前无中断，检测是否满足中断条件
        rGpInt <= gpInt;
      end
      else if (rGpClr) begin
        // 已有中断，等待清除
        rGpInt <= 1'b0;  // rGpClr为1时清除中断
      end      
    end
  end  
  
  //------------------------------------------
  // 寄存器访问地址选择
  //------------------------------------------
  // 根据是读还是写操作选择地址
  //always @* regAdr = PWRITE ? PADDR : PRDATA;
  always @* regAdr =  PADDR ;
  //------------------------------------------
  // 寄存器写入逻辑
  //------------------------------------------
  always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
      // 复位初始化
      rGpDat <= 32'h0;  // 数据寄存器清零
      rGpDir <= 32'h0;  // 方向寄存器清零
      rGpIen <= 1'b0;   // 中断禁用
      rGpInt <= 1'b0;   // 中断状态清零
      rGpClr <= 1'b0;   // 中断清除标志清零
    end
    else if (PWRITE)  begin
      case (regAdr)
        GPDAT: begin  // GPIO数据寄存器
            // (方向为0表示输出)
            rGpDat <= PWDATA & ~rGpDir;
        end
        GPDIR: begin  // GPIO方向寄存器
            rGpDir <= PWDATA;  // 1=输入，0=输出
        end
        GPIEN: begin  // 中断使能寄存器
            rGpIen <= PWDATA[0];  // 1中断
        end
        GPINT: begin  // 中断状态寄存器(写操作用于清除中断)
            // 写1到该寄存器且当前有中断时，清除中断
            rGpClr <= PWDATA[0] & rGpInt;
        end
      endcase
    end 
    else  begin
      rGpClr <= 1'b0;
    end
  end  
  
  //------------------------------------------
  // 寄存器访问错误检测
  //------------------------------------------
  always @* begin
    isErr = 1'b0;  // 默认无错误
    case (regAdr)
      GPDAT,        // 合法地址
      GPDIR,
      GPIEN,
      GPINT:   isErr = 1'b0;
      default: isErr = PWRITE;  // 写入非法地址时产生错误
    endcase
  end
  //------------------------------------------
  // 寄存器读取逻辑
  //------------------------------------------
  always @* begin
    regDat = 32'h0;  // 默认读0
    case (regAdr)
      GPDAT:   regDat = rGpDat;           // 读取数据寄存器
      GPDIR:   regDat = rGpDir;           // 读取方向寄存器
      GPIEN:   regDat = {31'h0, rGpIen};  // 读取中断使能(扩展到32位)
      GPINT:   regDat = {31'h0, rGpInt};  // 读取中断状态(扩展到32位)
      default: regDat = 32'h0;            // 非法地址返回0
    endcase
  end
  //------------------------------------------
  // 输出寄存器
  //------------------------------------------
  always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
      isErrQ  <= 1'b0;    // 复位错误标志
      regDatQ <= 32'h0;   // 复位读数据
    end
    else begin
      isErrQ  <= isErr;   // 锁存错误标志
      regDatQ <= regDat;  // 锁存读数据
    end 
  end
  
endmodule