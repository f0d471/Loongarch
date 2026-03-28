module spi_top
(
    input   wire            PCLK,
    input   wire            PCLKG,
    input   wire            PRESETn,
    input   wire            PSEL,
    input   wire    [11:2]  PADDR,
    input   wire            PENABLE,
    input   wire            PWRITE,
    input   wire    [31:0]  PWDATA,
    input   wire    [3:0]   ECOREVNUM,
    output  wire    [31:0]  PRDATA,
    output  wire            PREADY,
    output  wire            PSLVERR,

    input   wire            MISO,
    output  wire            MOSI,
    output  wire            SCLK
);

parameter   CR1_ADDR    = 10'd0;
parameter   CR2_ADDR    = 10'd1;
parameter   SR_ADDR     = 10'd2;
parameter   DR_ADDR     = 10'd3;

reg [15:0]  CR1;
reg [7:0]   CR2;
wire[7:0]   SR;
reg [15:0]  SPI_DR;
wire[15:0]  RDR;

wire    read_enable, write_enable;
wire    write_CR1, write_CR2, write_DR;
wire    read_CR1, read_CR2, read_SR, read_DR;
assign  read_enable  = PSEL & (~PWRITE) & PENABLE;
assign  write_enable = PSEL & (~PENABLE) & PWRITE;

assign  write_CR1 = write_enable & (PADDR[11:2] == CR1_ADDR);
assign  write_CR2 = write_enable & (PADDR[11:2] == CR2_ADDR);
assign  write_DR  = write_enable & (PADDR[11:2] == DR_ADDR);

assign  read_CR1 = read_enable & (PADDR[11:2] == CR1_ADDR);
assign  read_CR2 = read_enable & (PADDR[11:2] == CR2_ADDR);
assign  read_SR  = read_enable & (PADDR[11:2] == SR_ADDR);
assign  read_DR  = read_enable & (PADDR[11:2] == DR_ADDR);

wire[31:0]  read_data;
assign  read_data = read_CR1 ? {16'd0, CR1} :
                    read_CR2 ? {24'd0, CR2} :
                    read_SR  ? {24'd0, SR}  :
                    read_DR  ? {16'd0, RDR} : 32'd0;

wire    BIDIMODE = CR1[15];
wire    BIDIOE = CR1[14];
wire    DFF = CR1[11];
wire    RXONLY = CR1[10];
wire    LSB = CR1[7];
wire    SPE = CR1[6];
wire[2:0] BR = CR1[5:3];
wire    CPOL = CR1[1];
wire    CPHA = CR1[0];
always @(posedge PCLK) begin
    if (!PRESETn)
        CR1 <= 16'd0;
    else if (write_CR1)
        CR1 <= PWDATA[15:0];
end

always @(posedge PCLK) begin
    if (!PRESETn)
        CR2 <= 8'd0;
    else if (write_CR2)
        CR2 <= PWDATA[7:0];
end

wire    BSY;
wire    TXD;
wire    RXD;
reg     TXE;
reg     RXNE;
assign SR = {BSY, 5'b0, TXE, RXNE};
always @(posedge PCLK) begin
    if (!PRESETn)
        TXE <= 1'b1;
    else begin
        if (write_DR & SPE)
            TXE <= 1'b0;
        else if (TXD)
            TXE <= 1'b1;
    end
end

always @(posedge PCLK) begin
    if (!PRESETn)
        RXNE <= 1'b0;
    else begin
        if (read_DR)
            RXNE <= 1'b0;
        else if (RXD)
            RXNE <= 1'b1;
    end
end

always @(posedge PCLK) begin
    if (!PRESETn)
        SPI_DR <= 16'd0;
    else if (write_DR)
        SPI_DR <= PWDATA[15:0];
end

spi_shift u_spi_shift
(
    .clk            (PCLK),
    .rst_n          (PRESETn),
    .SPE            (SPE),
    .BIDIMODE       (BIDIMODE),
    .RXONLY         (RXONLY),
    .BIDIOE         (BIDIOE),
    .DFF            (DFF),
    .LSB            (LSB),
    .CPOL           (CPOL),
    .CPHA           (CPHA),
    .BR             (BR),
    .DR             (~TXE),
    .s_in           (MISO),
    .s_out          (MOSI),
    .sclk_out       (SCLK),
    .p_in           (SPI_DR),
    .p_out          (RDR),
    .TXD            (TXD),
    .RXD            (RXD),
    .BSY            (BSY)
);

assign PREADY = 1'b1;
assign PSLVERR = 1'b0;
assign PRDATA = read_data;

endmodule
