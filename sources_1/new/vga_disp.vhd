library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

ENTITY vga_disp IS
    Port ( clk      : IN STD_LOGIC;
           rst      : IN STD_LOGIC;
           rl_down  : IN STD_LOGIC;
           rl_up    : IN STD_LOGIC;
           rr_down  : IN STD_LOGIC;
           rr_up    : IN STD_LOGIC;
           addr_x   : IN STD_LOGIC_VECTOR (10 DOWNTO 0);
           addr_y   : IN STD_LOGIC_VECTOR (10 DOWNTO 0);
           addr_en  : IN STD_LOGIC;
           vsync    : IN STD_LOGIC;
           vga_data : OUT STD_LOGIC_VECTOR (11 DOWNTO 0));
END vga_disp;

ARCHITECTURE rtl OF vga_disp IS
    CONSTANT racket_size_x : INTEGER := 30;
    CONSTANT racket_size_y : INTEGER := 300;
    CONSTANT racket_start_pos : INTEGER := 300;
    CONSTANT racket_speed : INTEGER := 5;
    
    CONSTANT ball_size : INTEGER := 10;
    CONSTANT ball_speed : INTEGER := 10; -- Pixel per frame
    CONSTANT ball_start_pos_x : INTEGER := 1920/2;
    CONSTANT ball_Start_pos_y : INTEGER := 1080/2;
    
    TYPE BALL_STATE_TYPE IS (IDLE, RIGHT_UP, RIGHT_DOWN, LEFT_UP, LEFT_DOWN);
    SIGNAL BALL_STATE : BALL_STATE_TYPE;
    
    SIGNAL vsync_dly : STD_LOGIC;
    SIGNAL sync_rl_down, sync_rl_up : STD_LOGIC_VECTOR(1 DOWNTO 0);
    SIGNAL sync_rr_down, sync_rr_up : STD_LOGIC_VECTOR(1 DOWNTO 0);
    
    SIGNAL racket_left_pos, racket_left_pos_dly : INTEGER RANGE -racket_speed TO 1079 := racket_start_pos;
    SIGNAL racket_right_pos, racket_right_pos_dly : INTEGER RANGE -racket_speed TO 1079 := racket_start_pos;
    
    SIGNAL ball_pos_x, ball_pos_x_dly : INTEGER RANGE -ball_speed TO 1919 := ball_start_pos_x;
    SIGNAL ball_pos_y, ball_pos_y_dly : INTEGER RANGE -ball_speed TO 1919 := ball_start_pos_y;
    
    SIGNAL vga_pos_x : INTEGER;
    SIGNAL vga_pos_y : INTEGER; 
BEGIN

    vga_pos_x <= TO_INTEGER(UNSIGNED(addr_x));
    vga_pos_y <= TO_INTEGER(UNSIGNED(addr_y));
    
    UpdateGame_Proc : PROCESS (clk) 
    BEGIN
        IF rising_edge(clk) THEN
            IF rst /= '0' THEN
                BALL_STATE <= IDLE;
                racket_left_pos <= racket_start_pos;
                racket_right_pos <= racket_start_pos;
            ELSE
                -- Synchronize input buttons
                sync_rl_down(0) <= rl_down;     sync_rl_down(1) <= sync_rl_down(0);
                sync_rl_up(0)   <= rl_up;       sync_rl_up(1)   <= sync_rl_up(0);
                sync_rr_down(0) <= rr_down;     sync_rr_down(1) <= sync_rr_down(0);
                sync_rr_up(0)   <= rr_up;       sync_rr_up(1)   <= sync_rr_up(0);
                
                -- Pipeline stages for timing optimizations
                racket_right_pos_dly <= racket_right_pos;
                racket_left_pos_dly  <= racket_left_pos;
                
                ball_pos_y_dly <= ball_pos_y;
                ball_pos_x_dly <= ball_pos_x;
                
                vsync_dly <= vsync;
                
                -- Update Image at VSYNC pos edge
                IF vsync = '1' AND vsync_dly = '0' THEN
                
                    -- Start racket movement and ball movement depenend on push buttons
                    IF sync_rl_down(1) = '1' AND sync_rl_up(1) = '1' THEN
                        racket_left_pos <= racket_left_pos;
                    ELSIF sync_rl_down(1) = '1' AND racket_left_pos_dly + racket_size_y <= 1079 THEN
                        racket_left_pos <= racket_left_pos + racket_speed;
                        
                        IF BALL_STATE = IDLE THEN 
                            BALL_STATE <= LEFT_DOWN; 
                        END IF;
                    ELSIF sync_rl_up(1) = '1' AND racket_left_pos_dly >= 0 THEN
                        racket_left_pos <= racket_left_pos - racket_speed;
                        
                        IF BALL_STATE = IDLE THEN 
                            BALL_STATE <= LEFT_UP; 
                        END IF;
                    END IF;
                    
                    IF sync_rr_down(1) = '1' AND sync_rr_up(1) = '1' THEN
                        racket_right_pos <= racket_right_pos;
                    ELSIF sync_rr_down(1) = '1' AND racket_right_pos_dly + racket_size_y <= 1079 THEN
                        racket_right_pos <= racket_right_pos + racket_speed;
                        
                        IF BALL_STATE = IDLE THEN 
                            BALL_STATE <= RIGHT_DOWN; 
                        END IF;
                    ELSIF sync_rr_up(1) = '1' AND racket_right_pos_dly >= 0 THEN
                        racket_right_pos <= racket_right_pos - racket_speed;
                        
                        IF BALL_STATE = IDLE THEN 
                            BALL_STATE <= RIGHT_UP; 
                        END IF;
                    END IF;  
                    
                    -- Ball movement depend on state 
                    CASE BALL_STATE IS
                        WHEN IDLE =>
                            ball_pos_x <= ball_start_pos_x;
                            ball_pos_y <= ball_start_pos_y;   
                        WHEN RIGHT_UP => 
                            ball_pos_x <= ball_pos_x + ball_speed;
                            ball_pos_y <= ball_pos_y - ball_speed;
                        WHEN RIGHT_DOWN =>
                            ball_pos_x <= ball_pos_x + ball_speed;
                            ball_pos_y <= ball_pos_y + ball_speed;
                        WHEN LEFT_UP =>
                            ball_pos_x <= ball_pos_x - ball_speed;
                            ball_pos_y <= ball_pos_y - ball_speed;
                        WHEN LEFT_DOWN =>
                            ball_pos_x <= ball_pos_x - ball_speed;
                            ball_pos_y <= ball_pos_y + ball_speed;
                    END CASE;
                    
                    -- check collision with wall
                    IF ball_pos_y_dly <= 0 THEN
                        IF BALL_STATE = LEFT_UP THEN
                            BALL_STATE <= LEFT_DOWN;
                        ELSIF BALL_STATE = RIGHT_UP THEN
                            BALL_STATE <= RIGHT_DOWN;
                        END IF;      
                    ELSIF ball_pos_y_dly + ball_size >= 1079 THEN
                        IF BALL_STATE = LEFT_DOWN THEN
                            BALL_STATE <= LEFT_UP;
                        ELSIF BALL_STATE = RIGHT_DOWN THEN
                            BALL_STATE <= RIGHT_UP;
                        END IF; 
                    END IF;
                    
                    -- check collision with left racket
                    IF ball_pos_x_dly <= racket_size_x AND ball_pos_y_dly + ball_size >= racket_left_pos_dly AND ball_pos_y_dly <= racket_left_pos_dly + racket_size_y  THEN
                        IF BALL_STATE = LEFT_UP THEN
                            BALL_STATE <= RIGHT_UP;
                        ELSIF BALL_STATE = LEFT_DOWN THEN
                            BALL_STATE <= RIGHT_DOWN;
                        END IF;      
                    ELSIF ball_pos_x_dly >= 1919-racket_size_x AND ball_pos_y_dly + ball_size >= racket_right_pos_dly AND ball_pos_y_dly <= racket_right_pos_dly + racket_size_y  THEN
                        IF BALL_STATE = RIGHT_UP THEN
                            BALL_STATE <= LEFT_UP;
                        ELSIF BALL_STATE = RIGHT_DOWN THEN
                            BALL_STATE <= LEFT_DOWN;
                        END IF; 
                    END IF;
                    
                    -- check collision with goal
                    IF ball_pos_x_dly + ball_size >= 1919 OR ball_pos_x_dly <= 0 THEN
                        BALL_STATE <= IDLE;
                    END IF;
                END IF;
            END IF;
        END IF;
    END PROCESS UpdateGame_Proc;
        
    DrawFrame_Proc : PROCESS(clk) 
    BEGIN
        IF rising_edge(clk) THEN
            vga_data <= b"0000_0000_0000"; -- green playing field
            
            IF addr_en = '1' THEN
                IF vga_pos_x = 0 OR vga_pos_x = 1919 OR vga_pos_y = 0 OR vga_pos_y = 1079 THEN
                    vga_data <= b"1111_0000_0000"; -- draw red border
                ELSIF vga_pos_x >= ball_pos_x AND vga_pos_x <= ball_pos_x + ball_size AND vga_pos_y >= ball_pos_y AND vga_pos_y <= ball_pos_y + ball_size THEN
                    vga_data <= b"1111_1111_1111"; -- draw white ball
                ELSIF vga_pos_x >= 0 AND vga_pos_x <= racket_size_x AND vga_pos_y >= racket_left_pos AND vga_pos_y <= racket_left_pos + racket_size_y THEN 
                    vga_data <= b"1111_1111_1111"; -- draw white left racket
                ELSIF vga_pos_x >= 1919-racket_size_x AND vga_pos_x <= 1919 AND vga_pos_y >= racket_right_pos AND vga_pos_y <= racket_right_pos + racket_size_y THEN 
                    vga_data <= b"1111_1111_1111"; -- draw white right racket        
                END IF;
            END IF;
        END IF;
    END PROCESS DrawFrame_Proc;
    
END rtl;
