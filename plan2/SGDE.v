module SGDE (ready, done, clk, reset, sprite, start, type, X, Y, SR0_CEN, SR0_A, SR0_Q, SR1_CEN, 
SR1_A, SR1_Q, FB_CEN, FB_WEN, FB_A, FB_D, FB_Q, bg_color, game_mode   );
            // , count ,state, next_state, player_state, state_record);


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
  reg [11:0]  buf_player;
  reg [13:0]  buf_powerup_enemy [0:19];
  reg [11:0]  buf_background [0:19];
  reg [12:0]  image_player[0:191];
  reg [12:0]  image_powerup[0:63];
  reg [12:0]  image_enemy[0:63];
  reg [12:0]  image_background[0:63];
  reg [4:0] num_bg;
  reg [4:0] num_pwr_emy;
  reg [12:0]  count;
  reg [5:0] deltaX;
  reg [5:0] deltaY;
  reg [5:0] count_image;
  // reg [2:0]  i;
  // reg [2:0]  j;
  // reg [4:0]  count_player;
  reg [1:0] position_record; // record the emy or pwrup position relative to the player 00 01 10 11
  reg [4:0]   count_powerup_enemy;
  // reg [4:0]  count_powerup_enemy_reg;
  reg [4:0]   count_background;
  // reg [4:0]  count_background_reg;
  reg [4:0]   next_state;
  reg [4:0]   state;
  reg [1:0] player_state;
  reg [1:0] state_record;
  parameter rst = 0,
        store_sr0 = 1,
        store_breath = 17,
        store_sr1 = 2,
        beready = 3,
        detect_start_sprite = 18,
        adding = 4,
        position_pwr_emy = 5,
        is_possible= 6,
        pre_judge = 19,
        judge0 = 20,
        judge1 = 21,
        judge2 = 22,
        judge3 = 23,
        pos_judge = 24,
        // judge = 7,
        pre_write_buf = 8,
        write_bgcolor = 9,
        write_bg = 10,
        bg_next = 11,
        write_pwr_emy = 12,
        pwr_emy_next = 13,
        write_player = 14,
        finish_write = 15,
        all_over = 16;

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

  always @(*) begin
    case(state)
      rst: begin
        // player_state = 0;
        // state_record = 0;
        next_state = store_sr0;
      end
      store_sr0: begin
        // $display(count);
        if(count<192)
          next_state = store_sr0;
        else
          next_state = store_breath;
      end
      store_breath: begin
        next_state = store_sr1;
      end
      store_sr1: begin
        if(count<192)
          next_state = store_sr1;
        else
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
            next_state = position_pwr_emy;
        else
          if(!start)
            next_state = beready;
          else 
            next_state = position_pwr_emy;
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

      position_pwr_emy: begin
        // $display(buf_powerup_enemy[1]);

        next_state = is_possible;
        

        // if(player_state == 1)
        //  next_state = pre_write_buf;
        // else
        //  next_state = is_possible;
        // $display(num_pwr_emy,": ", player_state);
      end

      is_possible: begin    // whether it is possible of overlapping comparing delta X,Y

        if(deltaX>7 || deltaY>7)
          if(num_pwr_emy < count_powerup_enemy)
            next_state = position_pwr_emy;
          else
            next_state = pre_write_buf;
        else
          if(num_pwr_emy < count_powerup_enemy)
            next_state = pre_judge;
          else
            next_state = pre_write_buf;

        // if(deltaX>7 || deltaY>7)
        //  if(num_pwr_emy < count_powerup_enemy)
        //    next_state = position_pwr_emy;
        //  else
        //    next_state = pre_write_buf;
        // else
        //  if(num_pwr_emy < count_powerup_enemy)
        //    next_state = judge;
        //  else
        //    next_state = pre_write_buf;

        // if(player_state == 1)
        //  next_state = pre_write_buf;
        // else
        
        // next_state = judge;
      end

      pre_judge: begin
        if(position_record == 0) begin
          if(count - (count>>3)*8 >= deltaX && (count>>3)>=deltaY) 
            next_state = judge0;
          else 
            next_state = pos_judge;
        end
        else if(position_record == 1) begin
          if(count - (count>>3)*8 >= deltaX && (count>>3)<=deltaY)
            next_state = judge1;
          else 
            next_state = pos_judge;
        end
        else if(position_record == 2) begin
          if(count - (count>>3)*8 >= deltaX && (count>>3)>=deltaY)
            next_state = judge2;
          else 
            next_state = pos_judge;
        end
        else begin
          if(count - (count>>3)*8 >= deltaX && (count>>3)<=deltaY)
            next_state = judge3;
          else 
            next_state = pos_judge;
        end
      end

      judge0: begin
        next_state = pos_judge;
      end
      judge1: begin
        next_state = pos_judge;
      end
      judge2: begin
        next_state = pos_judge;
      end
      judge3: begin
        next_state = pos_judge;
      end

      pos_judge: begin
        
        if(count[6] == 0)
          if(state_record==0)
            next_state = pre_judge;
          else
            next_state = position_pwr_emy;
        else
          next_state = position_pwr_emy;  // after we have judged the buf_powerup_enemy[num_pwr_emy], we need to judge [num_pwr_emy+1]!

      end

      pre_write_buf: begin  // prepare to write the bg color into the FB 
        next_state = write_bgcolor;
      end

      write_bgcolor: begin
        if(FB_A == 4095)
          next_state = write_bg;
        else
          next_state = write_bgcolor;
      end

      write_bg: begin
        if(count_image == 63)
          next_state = bg_next;
        else
          next_state = write_bg;
      end

      bg_next: begin
        if(num_bg == count_background)
          next_state = write_pwr_emy;
        else
          next_state = write_bg;
      end

      write_pwr_emy: begin
        if(count_image == 63)
          next_state = pwr_emy_next;
        else
          next_state = write_pwr_emy;
      end

      pwr_emy_next: begin
        if(num_pwr_emy == count_powerup_enemy)
          next_state = write_player;
        else 
          next_state = write_pwr_emy;
      end

      write_player: begin
        if(count_image == 63)
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
        count_powerup_enemy <= 0;
        count_background <= 0;
        player_state <= 0;
        state_record <= 0;
        position_record <= 0;
        if(game_mode[0:0] == 0)
          SR0_A <= 0;
        else
          SR0_A <= 192;
        if(game_mode[1:1] == 0)
          SR1_A <= 0;
        else
          SR1_A <= 192;
        SR0_CEN <= 0;
        SR1_CEN <= 1;
        count <= 0;
      end
      store_sr0: begin
        // $display(image_player[0]);
        image_player[count] <= SR0_Q;
        // $display(image_player[count[6:0]-(count[6:0]>>3)*8][count[7:0]>>3]);
        SR0_A <= SR0_A + 1;
        // $display(count);
        // $display(SR0_Q);
        // $display(image_player[count-1]); // store the value into the reg need one clock cycle. That is true!
        
        count <= count + 1;
        
        
      end

      store_breath: begin
        SR0_CEN <= 1;
        SR1_CEN <= 0;
        count <= 0;
      end

      store_sr1: begin
        // $display(count);
        if(count < 64) begin
          image_enemy[count] <= SR1_Q;
          
          SR1_A <= SR1_A + 1;
          // SR1_CEN <= 0;
        end
        else if(count < 128) begin
          image_powerup[count-64] <= SR1_Q;
          
          SR1_A <= SR1_A + 1;
          // SR1_CEN <= 0;
        end
        else if(count < 192) begin
          image_background[count-128] <= SR1_Q;
          // $display(image_enemy[count-128]);
          
          SR1_A <= SR1_A + 1;
          // SR1_CEN <= 0;
        end
        else begin
          // count <= 0;
          SR1_A <= 0;
          // SR1_CEN <= 1;
        end
        count <= count + 1;     
      end

      beready: begin
        SR1_CEN <= 1;
        ready <= 1;
      end
      detect_start_sprite: begin
        ready <= 0;
        num_pwr_emy <= 0;
      end
      adding: begin
        
        case(type)
          2'b00: begin
            buf_player <= {X, Y};
          end
          2'b11: begin
            buf_background[count_background] <= {X, Y};

            count_background <= count_background + 1;
          end
          default: begin
            buf_powerup_enemy[count_powerup_enemy] <= {type, X, Y};
            count_powerup_enemy <= count_powerup_enemy + 1;
          end
        endcase
        // $display(buf_powerup_enemy[0]);
      end

      position_pwr_emy: begin // judge where the NPC is relative to the player
        if(buf_powerup_enemy[num_pwr_emy][11:6] > buf_player[11:6]) 
          if(buf_powerup_enemy[num_pwr_emy][5:0] > buf_player[5:0]) begin
            position_record <= 2'b10; // right-down
            deltaX <= buf_powerup_enemy[num_pwr_emy][11:6] - buf_player[11:6];
            deltaY <= buf_powerup_enemy[num_pwr_emy][5:0] - buf_player[5:0];
          end
          else begin
          position_record <= 2'b01; // right-up
          deltaX <= buf_powerup_enemy[num_pwr_emy][11:6] - buf_player[11:6];
          deltaY <= buf_player[5:0] - buf_powerup_enemy[num_pwr_emy][5:0];
          end
          
        else if(buf_powerup_enemy[num_pwr_emy][11:6] <= buf_player[11:6]) 
          if(buf_powerup_enemy[num_pwr_emy][5:0] > buf_player[5:0]) begin
            position_record <= 2'b11; // left-down
            deltaX <= buf_player[11:6] - buf_powerup_enemy[num_pwr_emy][11:6];
            deltaY <= buf_powerup_enemy[num_pwr_emy][5:0] - buf_player[5:0];
          end
          
          else begin
            position_record <= 2'b00; // left-up
            deltaX <= buf_player[11:6] - buf_powerup_enemy[num_pwr_emy][11:6];
            deltaY <= buf_player[5:0] - buf_powerup_enemy[num_pwr_emy][5:0];
          end 

        count <= 0;
        num_pwr_emy <= num_pwr_emy + 1;

      end

      is_possible: begin
        // count <= 0;
        if(state_record == 2)
          player_state[1] <= ~player_state[0];
        else if(state_record == 1)
          player_state <= 1;
        // else
        //  player_state <= player_state;

      end
      pre_judge: begin
        state_record <= 0;
      end
      judge0: begin
        if(buf_powerup_enemy[num_pwr_emy-1][12]==1) begin
          if(image_enemy[count][0]&image_player[count - deltaX - deltaY*8 + player_state*64][0]==1) begin
            state_record <= 2;  // overlap enemy
          end
          else begin
            state_record <= 0;
          end
        end
        else begin
          if(image_powerup[count][0]&image_player[count - deltaX - deltaY*8 + player_state*64][0]==1) begin
            state_record <= 1;
          end
          else begin
            state_record <= 0;
          end
        end
      end
      judge1: begin
        if(buf_powerup_enemy[num_pwr_emy-1][12]==1) begin
          if(image_enemy[count + deltaY*8 - deltaX][0]&image_player[count + player_state*64][0]==1) begin
            state_record <= 2;
          end
          else begin
            state_record <= 0;
          end
        end
        else begin
          if(image_powerup[count + deltaY*8 - deltaX][0]&image_player[count + player_state*64][0]==1) begin
            state_record <= 1;
          end
          else begin
            state_record <= 0;
          end
        end
      end
      judge2: begin
        if(buf_powerup_enemy[num_pwr_emy-1][12]==1) begin
          if(image_player[count + player_state*64][0]&image_enemy[count - deltaX - deltaY*8][0]==1) begin
            state_record <= 2;  // overlap enemy
          end
          else begin
            state_record <= 0;
          end
        end 
        else begin
          if(image_player[count + player_state*64][0]&image_powerup[count - deltaX - deltaY*8][0]==1) begin
            state_record <= 1;
          end
          else begin
            state_record <= 0;
          end
        end
      end
      judge3: begin
        if(buf_powerup_enemy[num_pwr_emy-1][12]==1) begin
          if(image_player[count + deltaY*8 - deltaX + player_state*64][0]&image_enemy[count][0]==1) begin
            state_record <= 2;
          end
          else begin
            state_record <= 0;
          end
        end
        else begin
          if(image_player[count + deltaY*8 - deltaX + player_state*64][0]&image_powerup[count][0]==1) begin
            state_record <= 1;
          end
          else begin
            state_record <= 0;
          end
        end
      end

      pos_judge: begin
        count <= count + 1;
      end
      /*
      judge: begin
      //============================================================JUDGE
        if(position_record == 0) begin
          if(buf_powerup_enemy[num_pwr_emy-1][12]==1) begin
            if(count - (count>>3)*8 >= deltaX && (count>>3)>=deltaY) begin
              if(image_enemy[count][0]&image_player[count - deltaX - deltaY*8 + player_state*64][0]==1) begin
                state_record <= 2;  // overlap enemy
              end
              else begin
                state_record <= 0;
              end
            end
            else begin
              state_record <= 0;
            end
          end
          else begin
            if(count - (count>>3)*8 >= deltaX && (count>>3)>=deltaY) begin
              if(image_powerup[count][0]&image_player[count - deltaX - deltaY*8 + player_state*64][0]==1) begin
                state_record <= 1;
              end
              else begin
                state_record <= 0;
              end
            end
            else begin
              state_record <= 0;
            end
          end
        end

        else if(position_record == 1) begin
          if(buf_powerup_enemy[num_pwr_emy-1][12]==1) begin
            if(count - (count>>3)*8 >= deltaX && (count>>3)<=deltaY) begin
              if(image_enemy[count + deltaY*8 - deltaX][0]&image_player[count + player_state*64][0]==1) begin
                state_record <= 2;
              end
              else begin
                state_record <= 0;
              end
            end
            else begin
              state_record <= 0;
            end
          end
          else begin
            if(count - (count>>3)*8 >= deltaX && (count>>3)<=deltaY) begin
              if(image_powerup[count + deltaY*8 - deltaX][0]&image_player[count + player_state*64][0]==1) begin
                state_record <= 1;
              end
              else begin
                state_record <= 0;
              end
            end
            else begin
              state_record <= 0;
            end
          end

        end

        else if(position_record == 2) begin
          if(buf_powerup_enemy[num_pwr_emy-1][12]==1) begin
            if(count - (count>>3)*8 >= deltaX && (count>>3)>=deltaY) begin
              if(image_player[count + player_state*64][0]&image_enemy[count - deltaX - deltaY*8][0]==1) begin
                state_record <= 2;  // overlap enemy
              end
              else begin
                state_record <= 0;
              end
            end
            else begin
              state_record <= 0;
            end
          end
          else begin
            if(count - (count>>3)*8 >= deltaX && (count>>3)>=deltaY) begin
              if(image_player[count + player_state*64][0]&image_powerup[count - deltaX - deltaY*8][0]==1) begin
                state_record <= 1;
              end
              else begin
                state_record <= 0;
              end
            end
            else begin
              state_record <= 0;
            end
          end
        end

        else begin
          if(buf_powerup_enemy[num_pwr_emy-1][12]==1) begin
            if(count - (count>>3)*8 >= deltaX && (count>>3)<=deltaY) begin
              if(image_player[count + deltaY*8 - deltaX + player_state*64][0]&image_enemy[count][0]==1) begin
                state_record <= 2;
              end
              else begin
                state_record <= 0;
              end
            end
            else begin
              state_record <= 0;
            end
          end
          else begin
            if(count - (count>>3)*8 >= deltaX && (count>>3)<=deltaY) begin
              if(image_player[count + deltaY*8 - deltaX + player_state*64][0]&image_powerup[count][0]==1) begin
                state_record <= 1;
              end
              else begin
                state_record <= 0;
              end
            end
            else begin
              state_record <= 0;
            end
          end
        end
      //
        count <= count + 1;
      end
      */

      pre_write_buf: begin  // prepare to write the bg color into the FB
        
        // $display(image_player[165]);
        // $display(image_player[190]);
        // $display(image_player[191]);

        //count <= 0;
        FB_CEN <= 0;
        FB_WEN <= 0;
        FB_D <= bg_color;
        FB_A <= 0;
        num_bg <= 0;
        num_pwr_emy <= 0;
        count <= 0;
        count_image <= 0;
      end
      write_bgcolor: begin
        FB_A <= FB_A + 1;
      end
      write_bg: begin
        FB_A <= buf_background[num_bg][11:6] + count_image - (count_image>>3)*8 + (buf_background[num_bg][5:0] + (count_image>>3)) * 64;
        // $display(buf_background[num_bg]);
        // $display(num_bg);
        // $display(FB_A);

        
        FB_D <= image_background[count_image][12:1];
        // $display(image_background[0]);
        FB_CEN <= ~image_background[count_image][0];
        // $display(image_background[count_image - (count_image>>3)*8]);
        // $display(FB_D);
        // $display(FB_CEN);
        count_image <= count_image + 1;
      end
      bg_next: begin
        num_bg <= num_bg + 1;
      end
      write_pwr_emy: begin
        FB_A <= buf_powerup_enemy[num_pwr_emy][11:6] + count_image - (count_image>>3)*8 + (buf_powerup_enemy[num_pwr_emy][5:0] + (count_image>>3)) * 64;
        if(buf_powerup_enemy[num_pwr_emy][12] == 1) begin
          FB_D <= image_enemy[count_image][12:1];
          FB_CEN <= ~image_enemy[count_image][0];
        end
        else begin
          FB_D <= image_powerup[count_image][12:1];
          FB_CEN <= ~image_powerup[count_image][0];
        end
        count_image <= count_image + 1;
      end
      pwr_emy_next: begin
        num_pwr_emy <= num_pwr_emy + 1;
      end
      write_player: begin
        FB_A <= buf_player[11:6] + count_image - (count_image>>3)*8 + (buf_player[5:0] + (count_image>>3)) * 64;
        FB_D <= image_player[count_image + player_state*64][12:1];
        FB_CEN <= ~image_player[count_image + player_state*64][0];
        count_image <= count_image + 1;
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