module lcd_driver(
    input               lcd_pclk,
    input               rst_n,
    input       [23:0]  pixel_data,

    output wire         lcd_clk,
    output wire         lcd_hs,
    output wire         lcd_vs,
    output wire         lcd_bl,
    output reg          lcd_de,
    output wire         lcd_rst,
    output wire [23:0]  lcd_rgb,
    output reg  [10:0]  pixel_xpos,
    output reg  [10:0]  pixel_ypos,
    output wire [10:0]  h_disp,
    output wire [10:0]  v_disp,
    output reg          data_req
);

parameter H_SYNC  = 11'd128;   //行同步
parameter H_BACK  = 11'd88;    //行显示后沿
parameter H_DISP  = 11'd800;   //行有效数据
parameter H_FRONT = 11'd40;    //行显示前沿
parameter H_TOTAL = 11'd1056;  //行扫描周期

parameter V_SYNC  = 11'd2;     //场同步
parameter V_BACK  = 11'd33;    //场显示后沿
parameter V_DISP  = 11'd480;   //场有效数据
parameter V_FRONT = 11'd10;    //场显示前沿
parameter V_TOTAL = 11'd525;   //场扫描周期

wire [10:0] h_sync ;
wire [10:0] h_back ;
wire [10:0] h_total;
wire [10:0] v_sync ;
wire [10:0] v_back ;
wire [10:0] v_total;
reg  [10:0] h_cnt  ;
reg  [10:0] v_cnt  ;

assign h_sync  = H_SYNC;
assign h_back  = H_BACK;
assign h_disp  = H_DISP;
assign h_total = H_TOTAL;
assign v_sync  = V_SYNC;
assign v_back  = V_BACK;
assign v_disp  = V_DISP;
assign v_total = V_TOTAL;

assign lcd_clk = lcd_pclk ;
assign lcd_hs  = 1'b1 ;
assign lcd_vs  = 1'b1 ;
assign lcd_bl  = 1'b1 ;
assign lcd_rst = 1'b1 ;
assign lcd_rgb = lcd_de ? pixel_data : 24'b0;

always@(posedge lcd_pclk or negedge rst_n)begin
    if(!rst_n)
        data_req <= 1'b0;
    else if((h_cnt >= h_sync + h_back - 2'd2) && (h_cnt < h_sync + h_back + h_disp - 2'd2)
            &&(v_cnt >= v_sync + v_back) && (v_cnt < v_sync + v_back + v_disp))
        data_req <= 1'b1;
    else
        data_req <= 1'b0;
end

always@(posedge lcd_pclk or negedge rst_n)begin
    if(!rst_n)
        lcd_de <= 1'b0;
    else
        lcd_de <= data_req;
end

always@(posedge lcd_pclk or negedge rst_n)begin
    if(!rst_n)
        pixel_xpos <= 11'd0;
    else if(data_req)
        pixel_xpos <= h_cnt + 2'd2 - h_sync - h_back ;
    else
        pixel_xpos <= 11'd0;
end

always@(posedge lcd_pclk or negedge rst_n)begin
    if(!rst_n)
        pixel_ypos <= 11'd0;
    else if((v_cnt >= (v_sync + v_back)) && v_cnt < (v_sync + v_back + v_disp))
        pixel_ypos <= v_cnt + 1'b1 - (v_sync + v_back);
    else
        pixel_ypos <= 11'd0;
end

always@(posedge lcd_pclk or negedge rst_n)begin
    if(!rst_n)
        h_cnt <= 11'd0;
    else begin
        if(h_cnt == h_total - 1'b1)
            h_cnt <= 11'd0;
        else
            h_cnt <= h_cnt + 1'b1;
    end
end

always@(posedge lcd_pclk or negedge rst_n)begin
    if(!rst_n)
        v_cnt <= 11'd0;
    else begin
        if(h_cnt == h_total - 1'b1)begin
            if(v_cnt == v_total - 1'b1)
                v_cnt <= 11'd0;
            else
                v_cnt <= v_cnt + 1'b1;
        end
    end
end

endmodule