module lcd_display(
    input               lcd_pclk,
    input               rst_n,
    input       [10:0]  pixel_xpos,
    input       [10:0]  pixel_ypos,
    input       [10:0]  h_disp,
    input       [10:0]  v_disp,
    output reg  [23:0]  pixel_data
);

parameter WHITE  = 24'hff_ff_ff;
parameter BLACK  = 24'h00_00_00;
parameter RED    = 24'hff_00_00;
parameter GREEN  = 24'h00_ff_00;
parameter BLUE   = 24'h00_00_ff;

always@(posedge lcd_pclk or negedge rst_n)begin
    if(!rst_n)
        pixel_data <= BLACK;
    else begin
        if((pixel_xpos >= 11'd0)&&(pixel_xpos < h_disp/5))
            pixel_data <= WHITE;
        else if((pixel_xpos >= h_disp/5)&&(pixel_xpos < h_disp/5*2))
            pixel_data <= BLACK;
        else if((pixel_xpos >= h_disp/5*2)&&(pixel_xpos < h_disp/5*3))
            pixel_data <= RED;
        else if((pixel_xpos >= h_disp/5*3)&&(pixel_xpos < h_disp/5*4))
            pixel_data <= GREEN;
        else
            pixel_data <= BLUE;
    end
end

endmodule