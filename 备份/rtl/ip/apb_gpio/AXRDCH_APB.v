
module AXRDCH (
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
    output [31:0] PRDATA,     // 读数据
    output        PREADY,     // 设备就绪
    output        PSLVERR,    // 设备错误响应
    // 寄存器块接口信号
    output [7:0]  oPRADR,     // 外设读地址
    input [31:0]  iPRDAT,     // 外设读数据
    input         iPERR       // 外设错误指示
);

//------------------------ 内部寄存器定义 ------------------------//
reg [7:0]   rAddr;      // 地址寄存器
reg [31:0]  rData;      // 数据寄存器
reg         rdAct;      // 读操作激活标志
reg         pReady;     // APB就绪状态寄存器
reg         pSlvErr;    // 错误响应寄存器

//------------------------ APB状态定义 --------------------------//
parameter IDLE   = 2'b00,
          SETUP  = 2'b01,
          ACCESS = 2'b10;

reg [1:0] apbState;  // APB状态寄存器

//------------------------ 输出信号赋值 ------------------------//
assign PRDATA  = rData;    // 输出读数据
assign PREADY  = pReady;   // APB就绪信号
assign PSLVERR = pSlvErr;  // APB错误响应
assign oPRADR  = PADDR[9:2]; 

//================================================================
// APB接口控制逻辑
//================================================================
always @(posedge PCLK or negedge PRESETn) begin
    if (~PRESETn) begin
        rAddr    <= 8'h0;      // 复位地址
        rData    <= 32'h0;     // 复位数据
        rdAct    <= 1'b0;      // 复位读激活标志
        pReady   <= 1'b1;      // 初始状态就绪
        pSlvErr  <= 1'b0;      // 初始无错误
        apbState <= IDLE;      // 初始空闲状态
    end
    else begin
        case (apbState)
            IDLE: begin
                if (PSEL && !PENABLE && !PWRITE) begin  // 只处理读请求
                    apbState <= SETUP; // 进入SETUP阶段
                    pReady <= 1'b0;     // 在传输过程中PREADY为低
                end
            end
            
            SETUP: begin
                if (PSEL && PENABLE && !PWRITE) begin
                    apbState <= ACCESS; // 进入ACCESS阶段
                    rdAct <= 1'b1;      // 激活读操作
                end
                else begin
                    apbState <= IDLE;   // 返回IDLE状态
                    pReady <= 1'b1;     // 传输结束
                end
            end
            
            ACCESS: begin
                if (rdAct) begin
                    rData <= iPRDAT;   // 锁存读数据
                    pSlvErr <= iPERR;  // 捕获外设错误状态
                    rdAct <= 1'b0;      // 清除读激活标志
                end
                
                // 结束当前传输
                pReady <= 1'b1;
                apbState <= IDLE;
            end
            
            default: apbState <= IDLE;
        endcase
    end
end
endmodule