module AXWRCH (
  // 系统信号
  input         PCLK,       // APB时钟
  input         PRESETn,    // 低电平有效复位
  // APB接口信号
  input         PSEL,       // 设备选择
  input [11:2]  PADDR,      // 地址总线
  input         PENABLE,    // 传输使能
  input         PWRITE,     // 写使能
  input [31:0]  PWDATA,     // 写数据
  input [3:0]   ECOREVNUM,  // 
  output [31:0] PRDATA,     // 读数据(未使用，保持为0)
  output        PREADY,     // 设备就绪
  output        PSLVERR,    // 设备错误响应
  // 寄存器块接口
  output[7:0]   oPWADR,     // 外设写地址(8位)
  output[31:0]  oPWDAT,     // 外设写数据
  output        oPWRTE,     // 外设写使能
  input         iPERR       // 外设错误指示
);
  // 内部寄存器定义
  reg [7:0]     wAddr;      // 地址寄存器(锁存写地址)
  reg [31:0]    wData;      // 数据寄存器(锁存写数据)
  reg           wEna;       // 写使能寄存器
  reg           wrAct;      // 写操作激活标志
  reg           pReady;     // APB就绪状态寄存器
  reg           pSlvErr;    // 错误响应寄存器
  
  // APB接口信号输出
  assign PREADY  = pReady;   // APB就绪信号
  assign PSLVERR = pSlvErr;  // APB错误响应
  
  // 寄存器块接口信号输出
  assign oPWADR = wAddr;     // 输出外设写地址
  assign oPWDAT = wData;     // 输出外设写数据
  assign oPWRTE = wEna;      // 输出外设写使能
  
  // APB状态机状态定义
  parameter IDLE   = 2'b00,
            SETUP  = 2'b01,
            ACCESS = 2'b10;
  
  reg [1:0] apbState;  // APB状态寄存器
  
  // APB接口控制逻辑
  always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
      wAddr    <= 8'h0;      // 复位地址
      wData    <= 32'h0;     // 复位数据
      wEna     <= 1'b0;      // 禁用写操作
      pReady   <= 1'b1;      // 初始状态就绪
      pSlvErr  <= 1'b0;      // 初始无错误
      apbState <= IDLE;      // 初始空闲状态
      wrAct    <= 1'b0;      // 复位写激活标志
    end
    else begin
      // 默认情况下保持wEna为低
      wEna <= 1'b0;
      
      case (apbState)
        IDLE: begin
          if (PSEL && !PENABLE) begin
            apbState <= SETUP; // 进入SETUP阶段
            pReady <= 1'b0;     // 在传输过程中PREADY为低
          end
        end
        
        SETUP: begin
          if (PSEL && PENABLE) begin
            apbState <= ACCESS; // 进入ACCESS阶段
            if (PWRITE) begin
              // 写操作处理
              wAddr <= PADDR[9:2];  // 使用PADDR[11:2]的低8位
              wData <= PWDATA;      // 锁存写数据
              wrAct <= 1'b1;        // 激活写操作
            end
          end
          else begin
            apbState <= IDLE; // 返回IDLE状态
            pReady <= 1'b1;   // 传输结束
          end
        end
        
        ACCESS: begin
          if (PWRITE && wrAct) begin
            wEna <= 1'b1;     // 产生写脉冲（保持一个时钟周期）
            pSlvErr <= iPERR; // 捕获外设错误状态
          end
          
          // 结束当前传输
          pReady <= 1'b1;
          apbState <= IDLE;
          wrAct <= 1'b0;
        end
        
        default: apbState <= IDLE;
      endcase
    end
  end
  
  // PRDATA保持为0（根据模块描述未使用）
  assign PRDATA = 32'h0;
endmodule