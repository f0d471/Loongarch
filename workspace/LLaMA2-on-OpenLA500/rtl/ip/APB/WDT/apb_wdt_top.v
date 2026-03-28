module apb_wdt_top
(
    input   wire            PCLK,
    input   wire            PRESETn,
    input   wire            PSEL,
    input   wire    [11:2]  PADDR,
    input   wire            PENABLE,
    input   wire            PWRITE,
    input   wire    [31:0]  PWDATA,
    output  wire    [31:0]  PRDATA,
    output  wire            PREADY,
    output  wire            PSLVERR,
    output  wire            WDT_INT,
    output  wire            WDT_RES
);

reg         enable;
reg         irq_enable;
reg [31:0]  load_reg;
reg [31:0]  cnt_reg;
reg         timeout_irq;
reg         timeout_res;

wire write_enable = PSEL & PWRITE & (~PENABLE);
wire read_enable  = PSEL & (~PWRITE) & PENABLE;

wire sel_ctrl  = (PADDR[11:2] == 10'h000);
wire sel_load  = (PADDR[11:2] == 10'h001);
wire sel_cnt   = (PADDR[11:2] == 10'h002);
wire sel_stat  = (PADDR[11:2] == 10'h003);

always @(posedge PCLK or negedge PRESETn) begin
    if (!PRESETn) begin
        enable      <= 1'b0;
        irq_enable  <= 1'b0;
        load_reg    <= 32'd1000000;
        cnt_reg     <= 32'd0;
        timeout_irq <= 1'b0;
        timeout_res <= 1'b0;
    end
    else begin
        if (write_enable && sel_ctrl) begin
            enable     <= PWDATA[0];
            irq_enable <= PWDATA[1];
            if (PWDATA[2])
                timeout_irq <= 1'b0;
            if (PWDATA[3])
                timeout_res <= 1'b0;
            if (PWDATA[4])
                cnt_reg <= 32'd0;
        end

        if (write_enable && sel_load)
            load_reg <= (PWDATA == 32'd0) ? 32'd1 : PWDATA;

        if (enable) begin
            if (cnt_reg >= load_reg - 1'b1) begin
                cnt_reg <= 32'd0;
                timeout_res <= 1'b1;
                if (irq_enable)
                    timeout_irq <= 1'b1;
            end
            else begin
                cnt_reg <= cnt_reg + 1'b1;
            end
        end
    end
end

reg [31:0] read_data;
always @(*) begin
    if (!read_enable) begin
        read_data = 32'd0;
    end
    else if (sel_ctrl) begin
        read_data = {27'd0, 1'b0, timeout_res, timeout_irq, irq_enable, enable};
    end
    else if (sel_load) begin
        read_data = load_reg;
    end
    else if (sel_cnt) begin
        read_data = cnt_reg;
    end
    else if (sel_stat) begin
        read_data = {30'd0, timeout_res, timeout_irq};
    end
    else begin
        read_data = 32'd0;
    end
end

assign PRDATA = read_data;
assign PREADY = 1'b1;
assign PSLVERR = 1'b0;
assign WDT_INT = timeout_irq;
assign WDT_RES = timeout_res;

endmodule
