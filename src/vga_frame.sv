/*******************************************************************************
 * CS220: Digital Circuit Lab
 * Computer Science Department
 * University of Crete
 * 
 * Date: 2019/XX/XX
 * Author: Your name here
 * Filename: vga_frame.sv
 * Description: Your description here
 *
 ******************************************************************************/

`timescale 1ns/1ps

module vga_frame(
  input logic clk,
  input logic rst,

  input logic i_rom_en,
  input logic [10:0] i_rom_addr,
  output logic [15:0] o_rom_data,

  input logic i_pix_valid,
  input logic [9:0] i_col,
  input logic [9:0] i_row,

  input logic [5:0] i_player_bcol,
  input logic [5:0] i_player_brow,

  input logic [5:0] i_exit_bcol,
  input logic [5:0] i_exit_brow,

  output logic [3:0] o_red,
  output logic [3:0] o_green,
  output logic [3:0] o_blue,
  output logic [4:0] o_painted,
  input logic i_update_bar
);


/*variables for managing the maze*/
logic [15:0] maze_pixel;
logic [10:0] maze_addr;
logic maze_en;

/*variables for managing the player*/
logic [15:0] player_pixel;
logic [7:0] player_addr;
logic player_en;

/*variables for managing the exit*/
logic [15:0] exit_pixel;
logic [7:0] exit_addr;
logic exit_en;

logic exit_en_tmp;
logic player_en_tmp;
logic maze_en_tmp;
logic pixel_valid_tmp;



/*instance for the maze ROM*/
rom_dp #(
  .size(2048),
  .file("C:/Users/alexander/Desktop/220/lab3_4383/roms/maze1.rom") 
)
maze_rom (
  .clk(clk),
  .en(maze_en_tmp),
  .addr(maze_addr),
  .dout(maze_pixel),
  .en_b(i_rom_en),
  .addr_b(i_rom_addr),
  .dout_b(o_rom_data)
);

/*instance for the player ROM*/
rom #(
  .size(256),
  .file("C:/Users/alexander/Desktop/220/lab3_4383/roms/player.rom")
)
player_rom (
  .clk(clk),
  .en(player_en_tmp),
  .addr(player_addr),
  .dout(player_pixel)
);

/*instance for the exit ROM*/
rom #(
  .size(256),
  .file("C:/Users/alexander/Desktop/220/lab3_4383/roms/exit.rom")
)
exit_rom (
  .clk(clk),
  .en(exit_en_tmp),
  .addr(exit_addr),
  .dout(exit_pixel)
);



/*combinatorial logic for the memory enable bit*/
always_comb begin
  if((i_col/16 == i_player_bcol) && (i_row/16 == i_player_brow)) begin  /*the pixel belongs to the player*/
    maze_en_tmp = 0;                                                        /*disable reading from maze ROM*/
    exit_en_tmp = 0;                                                        /*disable reading from exit ROM*/
    player_en_tmp = 1;                                                      /*enable reading from player ROM*/                                       
  end
  else if((i_col/16 == i_exit_bcol) && (i_row/16 == i_exit_brow)) begin /*the pixel belongs to the exit*/
    maze_en_tmp = 0;                                                        /*disable reading from maze ROM*/
    player_en_tmp = 0;                                                      /*disable reading from player ROM*/
    exit_en_tmp = 1;                                                        /*enable reading from exit ROM*/
  end
  else begin                                                            /*the pixel belongs to the maze*/
    maze_en_tmp = 1;                                                        /*enable reading from maze ROM*/
    player_en_tmp = 0;                                                      /*disable reading from player ROM*/
    exit_en_tmp = 0;                                                        /*disable reading from exit ROM*/
  end
end

/*calculate the addresses*/
always_comb begin
  maze_addr = ((i_row/16) + (i_col/16*32));
  player_addr = ((i_col%16) + (i_row%16*16));
  exit_addr = ((i_col%16) + (i_row%16*16));
end



always_ff @(posedge clk or posedge rst)begin
  if(rst)
    o_painted <= 0;
  else begin
    if((i_update_bar == 1) && (i_col >= 20 && i_col <= 620) && (i_row == 450 || i_row == 451))begin
      o_painted <= o_painted + 1;
    end
    if(o_painted == 16)
      o_painted <= 0;
  end
end


/*give o_red output*/
always_comb begin
  if (rst) begin
    o_red = 4'h0;
  end
  else begin
    if (pixel_valid_tmp) begin
      if(player_en)
        o_red = player_pixel[3:0];
      else if(exit_en)
        o_red = exit_pixel[3:0];
      else
        o_red = maze_pixel[15:12];
    end
    else begin
      o_red = 4'h0;
    end
    if(o_painted != 0)
      o_red = 4'hf;
  end
end



/*give o_green ouput*/
always_comb begin
  if (rst) begin
    o_green = 4'h0;
  end
  else begin
    if (pixel_valid_tmp) begin
      if(player_en)
        o_green = player_pixel[7:4];
      else if(exit_en)
        o_green = exit_pixel[7:4];
      else
        o_green = maze_pixel[11:8];
    end
    else begin
      o_green = 4'h0;
    end
  end
end

/*give o_blue output*/
always_comb begin
  if (rst) begin
    o_blue = 4'h0;
  end
  else begin
    if (pixel_valid_tmp) begin
      if(player_en)
        o_blue = player_pixel[11:8];
      else if(exit_en)
        o_blue = exit_pixel[11:8];
      else
        o_blue = maze_pixel[7:4];
    end
    else begin
      o_blue = 4'h0;
    end
  end
end

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    player_en <= 0;
  end
  else begin
    player_en <= player_en_tmp;
  end
end

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    exit_en <= 0;
  end
  else begin
    exit_en <= exit_en_tmp;
  end
end

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    maze_en <= 0;
  end
  else begin
    maze_en <= maze_en_tmp;
  end
end

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    pixel_valid_tmp <= 0;
  end
  else begin
    pixel_valid_tmp <= i_pix_valid;
  end
end

endmodule
