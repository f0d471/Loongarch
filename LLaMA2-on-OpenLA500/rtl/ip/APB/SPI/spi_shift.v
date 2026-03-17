module spi_shift
(
    input   wire            clk,
    input   wire            rst_n,
    input   wire            SPE,
    input   wire            BIDIMODE,
    input   wire            RXONLY,
    input   wire            BIDIOE,
    input   wire            DFF,
    input   wire            LSB,
    input   wire            CPOL,
    input   wire            CPHA,
    input   wire    [2:0]   BR,
    input   wire            DR,
    input   wire            s_in,
    output  reg             s_out,
    output  wire            sclk_out,
    input   wire    [15:0]  p_in,
    output  wire    [15:0]  p_out,
    output  reg             TXD,
    output  reg             RXD,
    output  reg             BSY
);

parameter IDEL = 3'b001, START = 3'b010,
          TX_RX = 3'b100;

reg [15:0]  tx_shift;
reg [15:0]  rx_shift;
reg [15:0]  rx_data;
reg [6:0]   div_value;
reg [3:0]   bit_counter;
reg [6:0]   div_counter;
reg         inv_counter;
reg [2:0]   state;
reg         enable;
reg         sclk;

wire [3:0]  bit_counter_minus_1 = bit_counter - 1'b1;
wire        inv_counter_plus_1 = ~inv_counter;
assign      p_out = rx_data;
assign      sclk_out = sclk ^ CPOL;

always @(posedge clk) begin
    if (!rst_n)
        rx_data <= 16'd0;
    else if (RXD)
        rx_data <= rx_shift;
end

always @(posedge clk) begin
    if (!rst_n) begin
        tx_shift <= 16'd0;
        rx_shift <= 16'd0;
        bit_counter <= 4'd0;
        inv_counter <= 1'b0;
        s_out <= 1'b0;
        sclk <= 1'b0;
        state <= IDEL;
        BSY <= 1'b0;
        RXD <= 1'b0;
        TXD <= 1'b0;
    end
    else begin
        case (state)
            IDEL : begin
                bit_counter <= DFF ? 4'b1111 : 4'b0111;
                BSY <= 1'b0;
                RXD <= 1'b0;
                if (BIDIMODE & ~BIDIOE) begin
                    BSY <= 1'b0;
                    tx_shift <= 16'd0;
                    state <= START;
                end
                else if (DR) begin
                    BSY <= 1'b1;
                    tx_shift <= p_in;
                    state <= START;
                end
                else if (enable) begin
                    sclk <= 1'b0;
                end
            end
            START : begin
                if (enable) begin
                    s_out <= LSB ? tx_shift[0] : (DFF ? tx_shift[15] : tx_shift[7]);
                    state <= TX_RX;
                    if (sclk ^ CPHA)
                        sclk <= ~sclk;
                end
            end
            TX_RX : begin
                TXD <= 1'b0;
                if (enable) begin
                    inv_counter <= inv_counter_plus_1;
                    sclk <= ~sclk;
                    if (~|bit_counter) begin
                        state <= IDEL;
                        RXD <= 1'b1;
                        inv_counter <= 1'b0;
                    end
                    if (inv_counter == 1'b0) begin
                        tx_shift <= LSB ? {1'b0, tx_shift[15:1]} : {tx_shift[14:0], 1'b0};
                        rx_shift <= LSB ? (DFF ? {s_in, rx_shift[15:1]} : {8'd0, s_in, rx_shift[7:1]}) : {rx_shift[14:0], s_in};
                    end
                    else if (inv_counter == 1'b1) begin
                        bit_counter <= bit_counter_minus_1;
                        s_out <= LSB ? tx_shift[0] : (DFF ? tx_shift[15] : tx_shift[7]);
                        if (BIDIMODE & ~BIDIOE)
                            TXD <= 1'b0;
                        else if (bit_counter == (DFF ? 4'b1111 : 4'b0111))
                            TXD <= 1'b1;
                    end
                end
            end
            default: state <= IDEL;
        endcase
    end
end

always @(*) begin
    case (BR)
        3'b000 : div_value = 7'b000_0000;
        3'b001 : div_value = 7'b000_0001;
        3'b010 : div_value = 7'b000_0011;
        3'b011 : div_value = 7'b000_0111;
        3'b100 : div_value = 7'b000_1111;
        3'b101 : div_value = 7'b001_1111;
        3'b110 : div_value = 7'b011_1111;
        3'b111 : div_value = 7'b111_1111;
        default: div_value = 7'b0;
    endcase
end

always @(posedge clk) begin
    if (!rst_n) begin
        enable <= 1'b0;
        div_counter <= 7'd0;
    end
    else if (SPE) begin
        if (div_counter == div_value) begin
            div_counter <= 7'd0;
            enable <= 1'b1;
        end
        else begin
            div_counter <= div_counter + 1'b1;
            enable <= 1'b0;
        end
    end
    else begin
        enable <= 1'b0;
        div_counter <= 7'd0;
    end
end

endmodule
