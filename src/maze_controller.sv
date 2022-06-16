/*******************************************************************************
 * CS220: Digital Circuit Lab
 * Computer Science Department
 * University of Crete
 * 
 * Date: 2019/XX/XX
 * Author: Your name here
 * Filename: maze_controller.sv
 * Description: Your description here
 *
 ******************************************************************************/

`timescale 1ns/1ps

module maze_controller(
  input clk,
  input rst,

  input  i_control,
  input  i_up,
  input  i_down,
  input  i_left,
  input  i_right,

  output logic        o_rom_en,
  output logic [10:0] o_rom_addr,
  input  logic [15:0] i_rom_data,

  output logic [5:0] o_player_bcol,
  output logic [5:0] o_player_brow,

  input  logic [5:0] i_exit_bcol,
  input  logic [5:0] i_exit_brow,

  output logic [7:0] o_leds,

  input logic [4:0] i_painted,
  output logic o_update_bar                   // 1 IF THE BAR NEEDS UPDATE
);

typedef enum logic[3:0]{
  IDLE_S = 4'h1,
  PLAY_S = 4'h2,
  UP_S = 4'h3,
  DOWN_S = 4'h4,
  LEFT_S = 4'h5,
  RIGHT_S = 4'h6,
  READROM_S = 4'h7,
  CHECK_S = 4'h8,
  UPDATE_S = 4'h9,
  END_S = 4'h10
} FSM_State_t;

FSM_State_t CurrentState, NextState;


logic [1:0] start_counter = 0;        // HOLDS THE COUNT OF THE START BTN (3 TIMES TO START)
logic [5:0] tmp_row;                  // HOLDS THE NEXT ROW
logic [5:0] tmp_col;                  // HOLDS THE NEXT COLUMN
logic [2:0] restart_counter;          // HOLDS THE COUNT OF THE RESTART BTN (5 TIMES TO RESTART)
logic is_valid;                       // ZERO IF NOT VALID MOVE ELSE ONE

logic [25:0] circle_cnt;              // COUNTS THE CIRCLES. 1 SECOND EVRY 25MhZ
logic [5:0] seconds;

always_ff @(posedge clk or posedge rst)begin
  if(rst)
    circle_cnt <= 0;
  else begin
    if(CurrentState == PLAY_S)begin
      circle_cnt <= circle_cnt + 1;
      if(circle_cnt == 25000000)begin
        circle_cnt <= 0;
      end
    end
  end
end

always_ff @(posedge clk or posedge rst) begin
  if(rst)
    seconds <= 0;
  else begin
    if(circle_cnt == 25000000)begin
      seconds <= seconds + 1;
    end
    if(seconds == 40)begin
      seconds <= 0;
    end
  end
end

always_ff @(posedge clk or posedge rst)begin
  if(rst)
    o_update_bar <= 0;
  else
    if(circle_cnt == 25000000)
      o_update_bar <= 1;
    if(i_painted == 16)
      o_update_bar <= 0;
end

always_ff @(posedge clk or posedge rst) begin
  if(rst) begin
    CurrentState <= IDLE_S;               // IF RESET START FROM THE BEGINING
  end
  else
    CurrentState <= NextState;            // ELSE GO TO THE NEXT STATE
end

// FOR THE PLAYER_ROW
always_ff @(posedge clk or posedge rst)begin
    if(rst)begin
        o_player_brow <= 0;
    end
    else begin
        if(CurrentState == IDLE_S)begin
            o_player_brow <= 0;
        end
        if(CurrentState == UPDATE_S)begin
            o_player_brow <= tmp_row;
        end
    end
end

//FOR THE COL
always_ff @(posedge clk or posedge rst)begin
    if(rst)begin
        o_player_bcol <= 1;
    end
    else begin
        if(CurrentState == IDLE_S)begin
            o_player_bcol <= 1;
        end
        if(CurrentState == UPDATE_S)begin
            o_player_bcol <= tmp_col;
        end
    end
end

//  FOR THE START BUTTON
always_ff @(posedge clk or posedge rst)begin
    if(rst)
        start_counter <= 0;
    else begin
        if(CurrentState == IDLE_S || CurrentState == END_S) begin
            if(i_control)
                start_counter <= start_counter + 1;
                if(start_counter == 3)
                    start_counter <= 0;
            else if(i_up || i_down || i_left || i_right)
                start_counter <= 0;
        end
    end
end


// FOR THE RESTART BUTTON
always_ff @(posedge clk or posedge rst) begin
    if(rst)
        restart_counter <= 0;
    else begin
        if(CurrentState == PLAY_S) begin
            if(i_control == 1)
                restart_counter <= restart_counter + 1;
            if(restart_counter == 5) begin
                restart_counter <= 0;
            end
        end
    end
end

// FOR THE TMP_ROW
always_ff @(posedge clk or posedge rst)begin
    if(rst)
        tmp_row <= 0;
    else begin
        if(CurrentState == UP_S) 
            tmp_row <= o_player_brow - 1;
        else if(CurrentState == DOWN_S) 
            tmp_row <= o_player_brow + 1;
        else if(CurrentState == RIGHT_S)
            tmp_row <= o_player_brow;
        else if(CurrentState == LEFT_S)
            tmp_row <= o_player_brow;
    end
            
end

// FOR THE TMP_COL
always_ff @(posedge clk or posedge rst)begin
    if(rst)
        tmp_col <= 0;
    else begin
        if(CurrentState == UP_S)
            tmp_col <= o_player_bcol;
        else if(CurrentState == DOWN_S)
            tmp_col <= o_player_bcol;
        else if(CurrentState == RIGHT_S)
            tmp_col <= o_player_bcol+1;
        else if(CurrentState == LEFT_S)
            tmp_col <= o_player_bcol-1;
    end
end

/* THE FSM */
always_comb begin
  NextState = CurrentState;
  o_leds = 7'hf;
  o_rom_en = 0;
  o_rom_addr = 0;
  case (CurrentState)

    IDLE_S: begin
      o_leds = 7'h1;
      if(start_counter == 3) begin                  // IF YOU PRESSED THE BUTTON 3 TIMES YOU CAN START
        NextState = PLAY_S;
      end
    end
      
    PLAY_S: begin
      o_leds = 7'h2;
      if(seconds == 40)
        NextState <= END_S;
      else begin
        if(i_up == 1)
          NextState = UP_S;
        else if(i_down == 1)
          NextState = DOWN_S;
        else if(i_right == 1)
          NextState = RIGHT_S;
        else if(i_left == 1)
          NextState = LEFT_S;

        if (o_player_bcol == i_exit_bcol) begin         // IF PLAYER RECHES THE EXIT
          if(o_player_brow == i_exit_brow)
            NextState = END_S;
        end

        if(restart_counter == 5)                  // IF RESTART BTN IS PRESSED 5 TIMES RESTART
          NextState = IDLE_S;
      end
    end

    UP_S: begin
      o_leds = 7'h3;
      if(o_player_brow == 0)
        NextState = PLAY_S;
      else
        NextState = READROM_S;
    end

    DOWN_S: begin
      o_leds = 7'h4;
      
      NextState = READROM_S;
    end

    LEFT_S: begin
      o_leds = 7'h5;
      if(o_player_bcol == 0)
        NextState = PLAY_S;
      else
        NextState = READROM_S;
    end

    RIGHT_S: begin
      o_leds = 7'h6;
      NextState = READROM_S;
    end

    READROM_S: begin
      o_leds = 7'h7;
      o_rom_en = 1;
      o_rom_addr = ((tmp_row) + (tmp_col*32));
      NextState = CHECK_S;
    end

    CHECK_S: begin
      o_leds = 7'h8;
      // CHECK IF THERE IS A WALL
      if(i_rom_data != 16'h0000)
        NextState = UPDATE_S;           // IF NOT UPDATE
      else
        NextState = PLAY_S;             // IF YES PLAY AGAIN
    end

    UPDATE_S: begin
      o_leds = 7'h9;
      NextState = PLAY_S;
    end

    END_S: begin
      o_leds = 7'ha;
      if(i_control == 1)
        NextState = IDLE_S;
    end

    default: begin
    end
  endcase
end

endmodule
