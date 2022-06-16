/*******************************************************************************
 * CS220: Digital Circuit Lab
 * Computer Science Department
 * University of Crete
 * 
 * Date: 2019/XX/XX
 * Author: Your name here
 * Filename: vga_sync.sv
 * Description: Implements VGA HSYNC and VSYNC timings for 640 x 480 @ 60Hz
 *
 ******************************************************************************/

`timescale 1ns/1ps

module vga_sync(
  input logic clk,
  input logic rst,

  output logic o_pix_valid,
  output logic [9:0] o_col,
  output logic [9:0] o_row,

  output logic o_hsync,
  output logic o_vsync
);


parameter FRAME_HPIXELS           = 640;
parameter FRAME_HFPORCH           = 16;
parameter FRAME_HSPULSE           = 96;
parameter FRAME_HBPORCH           = 48;
parameter FRAME_MAX_HCOUNT        = 800;

parameter FRAME_VLINES            = 480;
parameter FRAME_VFPORCH           = 10;
parameter FRAME_VSPULSE           = 2;
parameter FRAME_VBPORCH           = 29;
parameter FRAME_MAX_VCOUNT        = 521;

logic [9:0] hcnt;                    /*the first flipflop output 10 bit from 0 to 1024 to fit all the 800 horizontal pixels*/
logic hcnt_clr;                      /*stores 0 or 1*/
logic [9:0] vcnt;                    /*the second flipflop output 10 bit from 0 to 1024 to fit all the 800 horizontal pixels*/
logic vcnt_clr;                      /*stores 0 or 1*/
logic hs_set;
logic hs_clr;
logic vs_set;
logic vs_clr;
logic hsync;
logic vsync;
logic hsync_2;

/*implementing equality check (upper part)*/
always_comb begin
  hcnt_clr = (hcnt == (FRAME_MAX_HCOUNT - 1));
  hs_set = (hcnt == (FRAME_HPIXELS + FRAME_HFPORCH - 1));
  hs_clr = (hcnt == (FRAME_HPIXELS + FRAME_HFPORCH + FRAME_HSPULSE - 1));
end

/*implementing equality check (lower part)*/
always_comb begin
  vcnt_clr = ((vcnt == FRAME_MAX_VCOUNT-1) & (hcnt_clr == 1));
  vs_set = ((vcnt == FRAME_VLINES + FRAME_VFPORCH - 1) & (hcnt_clr == 1));
  vs_clr = ((vcnt == FRAME_VLINES + FRAME_VFPORCH + FRAME_VSPULSE - 1) & (hcnt_clr == 1));
end

/*implementing the general output*/
always_comb begin
  o_col = hcnt;
  o_row = vcnt;
  o_pix_valid = ((hcnt < FRAME_HPIXELS) & (vcnt < FRAME_VLINES));
end

/*o_vsync output*/
always_comb begin
    o_hsync = (~hsync_2);
    o_vsync = (~vsync);
end



/*iterate all the pixels of a row (RED #1)*/
always_ff @(posedge clk or posedge rst) begin        /*at positive clock edge*/
    if(rst)
        hcnt <= 0;
    else    
        if(hcnt_clr == 1)                 /*if the counter reatches the max number of horizontal pixels*/
            hcnt <= 0;                      /*zero the counter*/
        else
            hcnt <= hcnt + 1;               /*else continue counting*/
end

/*hsync flipflop (RED #2)*/
always_ff @(posedge clk or posedge rst) begin
    if(rst)
        hsync <= 0;
    else
        hsync <= ((hs_set | hsync) & (~hs_clr));
end

/*o_hsync flipflpop (RED #3)*/
always_ff @(posedge clk or posedge rst) begin
    if(rst)
        hsync_2 <= 0;
    else
        hsync_2 <= hsync;
end

/*iterate all the rows (GREEN #1)*/
always_ff @(posedge clk or posedge rst) begin
    if(rst)
        vcnt <= 0;
    else
        if(vcnt_clr==1) begin            /*if clear the vertical counter, output zero*/
          vcnt <= 0;
        end else begin                   /*else*/
          if(hcnt_clr == 1)              /*if clearing the horizontal counter*/
            vcnt <= (vcnt + 1);          /*go to the next row*/
                                         /*else keep the old value*/
        end
end

/*vsync flipflpop (GREEN #2)*/
always_ff @(posedge clk or posedge rst) begin
    if(rst)
        vsync <= 0;
    else
        vsync <= ((vs_set | vsync) & (~vs_clr));
end

endmodule
