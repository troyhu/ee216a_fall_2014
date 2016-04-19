module SGDE (ready, done, clk, reset, sprite, start, type, X, Y, SR0_CEN, SR0_A, SR0_Q, SR1_CEN, 
SR1_A, SR1_Q, FB_CEN, FB_WEN, FB_A, FB_D, FB_Q, bg_color, game_mode   );
            // , count ,state, next_state, player_state, state_record, flag_flip);


  //------------------------------------------------------------------
  //  Inputs
  //------------------------------------------------------------------
  input     clk;
  input     reset;
  input     sprite;
  input     start;
  input [1:0] type;
  input [5:0] X;
  input [5:0] Y;
  input [12:0]  SR0_Q;
  input [12:0]  SR1_Q;
  input [11:0]  FB_Q;
  input [11:0]  bg_color;
  input [1:0] game_mode;

  //------------------------------------------------------------------
  //  Outputs
  //------------------------------------------------------------------
  output      ready;
  output      done;
  output      SR0_CEN;
  output      SR1_CEN;
  output      FB_CEN;
  output      FB_WEN;
  output  [8:0] SR0_A;
  output  [8:0] SR1_A;
  output  [11:0]  FB_A;
  output  [11:0]  FB_D;
  
  // output   [12:0]  count;
  // output  [4:0]   state;
  // output  [4:0]   next_state;
  // output  [1:0] player_state;
  // output  [1:0] state_record;
  // output   [4:0]     flag_flip;
  // reg      [4:0]      flag_flip;

  reg     ready;
  reg     done;
  reg     SR0_CEN;
  reg     SR1_CEN;
  reg     FB_CEN;
  reg     FB_WEN;
  reg [8:0] SR0_A;
  reg [8:0] SR1_A;
  reg [11:0]  FB_A;
  reg [11:0]  FB_D;
  //-----------------------------------
  // reg [11:0]  buf_player;           // buf_player means the player coordinate
  // reg [13:0]  buf_powerup_enemy [0:19]; // two bits more means 
  // reg [11:0]  buf_background [0:19];
  // let's try to use only two kinds of buf for player and nonplayer! total # is 20
  // reg [11:0]  buf_player;          
  reg [13:0]  buf_obj [0:19]; 
  // let's try to read from the rom every time if we need to make a judgement of overlapping
  // reg [12:0]  image_player[0:191];  // image means object info: R+G+B+mask (13bits)
  // reg [12:0]  image_powerup[0:63];
  // reg [12:0]  image_enemy[0:63];
  // reg [12:0]  image_background[0:63];
  //
  // reg [4:0] num_bg;
  reg [4:0] count_npc;
  reg [5:0] count;
  reg [5:0] deltaX;
  reg [5:0] deltaY;
  // reg [5:0] count_image;
  // reg [2:0]  i;
  // reg [2:0]  j;
  // reg [4:0]  count_player;
  reg [1:0] position_record; // record the emy or pwrup position relative to the player 00 01 10 11
  reg [4:0]   num_npc;
  reg       is_pwrup;
  // reg [4:0]   count_powerup_enemy;
  // reg [4:0]  count_powerup_enemy_reg;
  // reg [4:0]   count_background;
  // reg [4:0]  count_background_reg;
  reg [4:0]   next_state;
  reg [4:0]   state;
  reg [1:0] player_state;
  reg [1:0] state_record;
  reg [1:0] flag_wr_fb;
  parameter rst = 0,
            beready = 1,
            detect_start_sprite = 2,
            adding  = 3,
            add_count_npc = 4,
            is_pwr_emy  = 5,
            position_pwr_emy  = 6,
            is_possible = 7,
            pre_judge = 8,
            prepare_judge0  = 9,
            prepare_judge1  = 10,
            prepare_judge2  = 11,
            prepare_judge3  = 12,
            judge = 13,
            pos_judge = 14,
            pre_write_buf = 15,
            write_bgcolor = 16,
            is_bg = 17,
            write_bg  = 18,
            after_bg  = 19,
            is_pwr_emy2 = 20,
            write_pwr_emy = 21,
            after_pwr_emy = 22,
            write_player  = 23,
            finish_write  = 24,
            all_over  = 25;



  always @(posedge clk or posedge reset) begin
    if (reset) begin
      state <= rst;
      
    end
    else begin
      state <= next_state;
      // $display(state);
    end
  end

  // always @(posedge clk) begin
  //  if (sprite) begin
  //    case(type)
  //      2'b00: begin
  //        buf_player <= {X, Y};
  //      end
  //      2'b11: begin
  //        buf_background[count_background_reg] <= {X, Y};

  //        count_background_reg <= count_background_reg + 1;
  //      end
  //      default: begin
  //        buf_powerup_enemy[count_powerup_enemy_reg] <= {type, X, Y};
  //        count_powerup_enemy_reg <= count_powerup_enemy_reg + 1;
  //      end
  //    endcase
  //  end
  // end

  always @(state or sprite or start or count_npc or FB_A) begin
    case(state)
      rst: begin
        // player_state = 0;
        // state_record = 0;
        // flag_flip = 0;

        next_state = beready;
        
      end
      beready: begin
        next_state = detect_start_sprite;
      end
      detect_start_sprite: begin
        if(sprite)
          if(!start)
            next_state = adding;
          else
            next_state = add_count_npc;
        else
          if(!start)
            next_state = beready;
          else 
            next_state = add_count_npc;
      end

      adding: begin
        // if(sprite)
        //  next_state = beready;
        // else
        //  next_state = position_pwr_emy;
        // if(start) 
        //  next_state = position_pwr_emy;
        // else 
          next_state = beready;
      end

      add_count_npc: begin
        next_state = (flag_wr_fb[0]==0)? is_pwr_emy:(flag_wr_fb[1]==0)? is_bg:is_pwr_emy2;
      end

      is_pwr_emy: begin
        if(player_state == 1 || count_npc == num_npc+1)
          next_state = pre_write_buf;
        else if(buf_obj[count_npc][13] == buf_obj[count_npc][12])
          next_state = add_count_npc;
        else begin
          next_state = position_pwr_emy;
          if(buf_obj[count_npc][12]==0)
            is_pwrup = 1;
          else
            is_pwrup = 0;
        end
        // flag_flip = flag_flip + 1;
        
      end

      position_pwr_emy: begin
        
        next_state = is_possible;

      end

      is_possible: begin    // whether it is possible of overlapping comparing delta X,Y
        if(deltaX>7 || deltaY>7)
            next_state = add_count_npc;
        else
            next_state = pre_judge;
      end

      pre_judge: begin
        if(position_record == 0) begin
          if(count - (count>>3)*8 >= deltaX && (count>>3)>=deltaY) 
            next_state = prepare_judge0;
          else 
            next_state = pos_judge;
        end
        else if(position_record == 1) begin
          if(count - (count>>3)*8 >= deltaX && (count>>3)<=deltaY)
            next_state = prepare_judge1;
          else 
            next_state = pos_judge;
        end
        else if(position_record == 2) begin
          if(count - (count>>3)*8 >= deltaX && (count>>3)>=deltaY)
            next_state = prepare_judge2;
          else 
            next_state = pos_judge;
        end
        else begin
          if(count - (count>>3)*8 >= deltaX && (count>>3)<=deltaY)
            next_state = prepare_judge3;
          else 
            next_state = pos_judge;
        end
      end


      prepare_judge0: begin
        next_state = judge;
      end
      prepare_judge1: begin
        next_state = judge;
      end
      prepare_judge2: begin
        next_state = judge;
      end
      prepare_judge3: begin
        next_state = judge;
      end

      judge: begin
        next_state = pos_judge;
      end

      pos_judge: begin
        
        if(count <= 62)
          if(state_record==0)
            next_state = pre_judge;
          else
            next_state = add_count_npc;
        else
          next_state = add_count_npc;  // after we have judged the buf_powerup_enemy[count_npc], we need to judge [count_npc+1]!

      end

      pre_write_buf: begin  // prepare to write the bg color into the FB 
        next_state = write_bgcolor;
        
      end

      write_bgcolor: begin
        
        if(FB_A == 4095)
          next_state = add_count_npc;
        else
          next_state = write_bgcolor;
      end

      is_bg: begin
        if(count_npc == num_npc+1)
          next_state = after_bg;
        else if(buf_obj[count_npc][13:12]!=3)
          next_state = add_count_npc;
        else
          next_state = write_bg;
      end

      write_bg: begin
        // $display(buf_obj[count_npc][13:12]);
        if(count == 0)
          next_state = add_count_npc;
        else
          next_state = write_bg;
      end

      after_bg: begin
        next_state = add_count_npc;
        
      end

      is_pwr_emy2: begin
        
        if(count_npc == num_npc+1)
          next_state = after_pwr_emy;
        else if(buf_obj[count_npc][13] == buf_obj[count_npc][12])
          next_state = add_count_npc;
        else begin
          next_state = write_pwr_emy;
          if(buf_obj[count_npc][12]==0)
            is_pwrup = 1;
          else
            is_pwrup = 0;
        end
        // flag_flip = flag_flip + 1;
        
      end

      write_pwr_emy: begin
        
        if(count == 0)
          next_state = add_count_npc;
        else
          next_state = write_pwr_emy;
      end

      after_pwr_emy: begin
        next_state = write_player;
      end

      write_player: begin
        if(count == 0)
          next_state = finish_write;
        else
          next_state = write_player;
      end

      finish_write: begin
        next_state = all_over;
      end

      all_over: begin
        next_state = all_over;
      end

      default: begin
        next_state = rst;
      end

    endcase
  end


  always @(negedge clk) begin
    case(state)
      rst: begin
        // count_powerup_enemy <= 0;
        // count_background <= 0;
        num_npc <= 0;
        player_state <= 0;
        state_record <= 0;
        position_record <= 0;
        // if(game_mode[0:0] == 0)
        //   SR0_A <= 0;
        // else
        //   SR0_A <= 192;
        // if(game_mode[1:1] == 0)
        //   SR1_A <= 0;
        // else
        //   SR1_A <= 192;
        // SR0_CEN <= 0;
        // SR1_CEN <= 1;
        count <= 0;
        flag_wr_fb <= 0;
      end
      
      beready: begin
        SR1_CEN <= 1;
        ready <= 1;
      end
      detect_start_sprite: begin
        ready <= 0;
        count_npc <= 0;
      end
      adding: begin
        
        if(type == 2'b00) begin
          buf_obj[0] <= {type, X, Y};
        end
        else begin
          
          buf_obj[num_npc+1] <= {type, X, Y};
          num_npc <= num_npc + 1;
          
        end

        // $display(buf_powerup_enemy[0]);
      end

      add_count_npc: begin
        count_npc <= count_npc + 1;
      end

      is_pwr_emy: begin
        // count_npc <= count_npc + 1;

      end

      position_pwr_emy: begin // judge where the NPC is relative to the player
        
        if(buf_obj[count_npc][11:6] > buf_obj[0][11:6]) 
          if(buf_obj[count_npc][5:0] > buf_obj[0][5:0]) begin
            position_record <= 2'b10; // right-down
            deltaX <= buf_obj[count_npc][11:6] - buf_obj[0][11:6];
            deltaY <= buf_obj[count_npc][5:0] - buf_obj[0][5:0];
          end
          else begin
          position_record <= 2'b01; // right-up
          deltaX <= buf_obj[count_npc][11:6] - buf_obj[0][11:6];
          deltaY <= buf_obj[0][5:0] - buf_obj[count_npc][5:0];
          end
          
        else if(buf_obj[count_npc][11:6] <= buf_obj[0][11:6]) 
          if(buf_obj[count_npc][5:0] > buf_obj[0][5:0]) begin
            position_record <= 2'b11; // left-down
            deltaX <= buf_obj[0][11:6] - buf_obj[count_npc][11:6];
            deltaY <= buf_obj[count_npc][5:0] - buf_obj[0][5:0];
          end
          
          else begin
            position_record <= 2'b00; // left-up
            deltaX <= buf_obj[0][11:6] - buf_obj[count_npc][11:6];
            deltaY <= buf_obj[0][5:0] - buf_obj[count_npc][5:0];
          end 

        count <= 0;
        // count_npc <= count_npc + 1;

      end

      is_possible: begin

        // if(state_record == 2)
        //   player_state[1] <= ~player_state[0];
        // else if(state_record == 1)
        //   player_state <= 1;
        state_record <= 0;
      end

      pre_judge: begin
        
      end

      prepare_judge0: begin
        SR0_CEN <= 0;
        SR0_A <= count - deltaX - deltaY*8 + player_state*64 + (game_mode[0]==1)*192;
        SR1_CEN <= 0;
        SR1_A <= count + is_pwrup*64 + (game_mode[1]==1)*192;
      end

      prepare_judge1: begin
        SR0_CEN <= 0;
        SR0_A <= count + player_state*64 + (game_mode[0]==1)*192;
        SR1_CEN <= 0;
        SR1_A <= count + deltaY*8 - deltaX + is_pwrup*64 + (game_mode[1]==1)*192;
      end

      prepare_judge2: begin
        SR0_CEN <= 0;
        SR0_A <= count + player_state*64 + (game_mode[0]==1)*192;
        SR1_CEN <= 0;
        SR1_A <= count - deltaX - deltaY*8 + is_pwrup*64 + (game_mode[1]==1)*192;
      end

      prepare_judge3: begin
        SR0_CEN <= 0;
        SR0_A <= count + deltaY*8 - deltaX + player_state*64 + (game_mode[0]==1)*192;
        SR1_CEN <= 0;
        SR1_A <= count + is_pwrup*64 + (game_mode[1]==1)*192;
      end

      judge: begin
         SR0_CEN <= 1;
         SR1_CEN <= 1;
        if(is_pwrup==0) begin
          if(SR0_Q[0]&SR1_Q[0]==1) begin
            state_record <= 2;  // overlap enemy
          end
          else begin
            state_record <= 0;
          end
        end
        else begin
          if(SR0_Q[0]&SR1_Q[0]==1) begin
            state_record <= 1;  // overlap pwrup
          end
          else begin
            state_record <= 0;
          end
        end
      end
    
      pos_judge: begin
        count <= count + 1;
        if(state_record == 2)
          player_state[1] <= ~player_state[0];
        else if(state_record == 1)
          player_state <= 1;
      end
      

      pre_write_buf: begin  // prepare to write the bg color into the FB

        FB_CEN <= 0;
        FB_WEN <= 0;
        FB_D <= bg_color;
        FB_A <= 0;
        // num_bg <= 0;
        count_npc <= 0;
        count <= 0;
        flag_wr_fb <= 1;
      end
      write_bgcolor: begin
        FB_A <= FB_A + 1;
      end

      is_bg:begin
        // count_npc <= count_npc + 1;
        SR1_A <= 128 + (game_mode[1]==1)*192;
        SR1_CEN <= 0;
        count <= 0;
      end

      write_bg: begin
        FB_A <= buf_obj[count_npc][11:6] + count - (count>>3)*8 + (buf_obj[count_npc][5:0] + (count>>3)) * 64;

        FB_D <= SR1_Q[12:1];

        FB_CEN <= ~SR1_Q[0];

        count <= count + 1;
        SR1_A <= SR1_A + 1;
        
      end
      after_bg: begin
        count_npc <= 0;
        count <= 0;
        flag_wr_fb <= 3;
      end
      is_pwr_emy2: begin
        // count_npc <= count_npc + 1;
        SR1_A <= (game_mode[1]==1)*192 + (is_pwrup==1)*64;
        SR1_CEN <= 0;
        count <= 0;
      end
      write_pwr_emy: begin
       
        FB_A <= buf_obj[count_npc][11:6] + count - (count>>3)*8 + (buf_obj[count_npc][5:0] + (count>>3)) * 64;
       
        FB_D <= SR1_Q[12:1];

        FB_CEN <= ~SR1_Q[0];
 
        count <= count + 1;
        SR1_A <= SR1_A + 1;
      end
      after_pwr_emy: begin
        SR1_CEN <= 1;
        SR0_CEN <= 0;
        SR0_A <= player_state*64 + (game_mode[0]==1)*192;
        count <= 0;
      end
      write_player: begin
        FB_A <= buf_obj[0][11:6] + count - (count>>3)*8 + (buf_obj[0][5:0] + (count>>3)) * 64;

        FB_D <= SR0_Q[12:1];

        FB_CEN <= ~SR0_Q[0];

        count <= count + 1;
        SR0_A <= SR0_A + 1;
        
      end
      finish_write: begin
        ready <= 1;
        done <= 1;
      end
      all_over: begin
        ready <= 0;
        done <= 0;
      end
    endcase
  end
endmodule