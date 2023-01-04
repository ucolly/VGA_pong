LIBRARY IEEE;
USE     IEEE.STD_LOGIC_1164.ALL;
USE     IEEE.NUMERIC_STD.ALL;

ENTITY vga IS
   PORT( 
      clk_vga                 : IN     STD_LOGIC; -- 148.5 Mhz at 1920x1080
      rst_vga                 : IN     STD_LOGIC;
      -- VRAM data ------------------------------------------------------------
	  vga_data				  : IN 	   STD_LOGIC_VECTOR(11 DOWNTO 0);
	  addr_x				  : OUT    STD_LOGIC_VECTOR(10 DOWNTO 0);
	  addr_y				  : OUT    STD_LOGIC_VECTOR(10 DOWNTO 0);
	  addr_en                 : OUT    STD_LOGIC;
	  -- VGA data  ------------------------------------------------------------
	  vsync					  : OUT    STD_LOGIC;
	  hsync					  : OUT    STD_LOGIC;
	  rgb					  : OUT    STD_LOGIC_VECTOR(11 DOWNTO 0)  -- 4 bit red, 4 bit green, 4 bit blue
   );

-- Declarations

END ENTITY vga ;

-------------------------------------------------------------------------------
-- Description:
-- VGA driver
-------------------------------------------------------------------------------
ARCHITECTURE rtl OF vga IS
    -- VGA sync timings from:
    -- https://projectf.io/posts/video-timings-vga-720p-1080p/#hd-1920x1080-60-hz
	CONSTANT HSYNC_DISP_CONST 	: INTEGER := 1920;
	CONSTANT HSYNC_FP_CONST 	: INTEGER := 88;
	CONSTANT HSYNC_BP_CONST		: INTEGER := 148;
	CONSTANT HSYNC_PW_CONST 	: INTEGER := 44;
	
	TYPE HSYNC_VGA_STATE_TYPE IS (HSYNC_FP, HSYNC_PW, HSYNC_BP, HSYNC_DISP);
	TYPE VSYNC_VGA_STATE_TYPE IS (VSYNC_FP, VSYNC_PW, VSYNC_BP, VSYNC_DISP);
	
	SIGNAL HSYNC_VGA_STATE : HSYNC_VGA_STATE_TYPE;
	SIGNAL VSYNC_VGA_STATE : VSYNC_VGA_STATE_TYPE;
	
	CONSTANT VSYNC_DISP_CONST  : INTEGER := 1080;
	CONSTANT VSYNC_FP_CONST	   : INTEGER := 4;
	CONSTANT VSYNC_BP_CONST	   : INTEGER := 36;
	CONSTANT VSYNC_PW_CONST    : INTEGER := 5;
	
	SIGNAL vga_hsync_cnt : INTEGER RANGE 0 TO HSYNC_DISP_CONST;
	SIGNAL vga_vsync_cnt : INTEGER RANGE 0 TO VSYNC_DISP_CONST;
    
    SIGNAL addr_x_en : STD_LOGIC;
    SIGNAL addr_y_en : STD_LOGIC;
    SIGNAL vga_vsync_refresh : STD_LOGIC;
    
    SIGNAL int_vsync, int_vsync_dly : STD_LOGIC;
    SIGNAL int_hsync, int_hsync_dly : STD_LOGIC;
BEGIN
     
   VRAM_read_Proc : PROCESS (clk_vga)
   BEGIN
       IF rising_edge(clk_vga) THEN
           IF addr_x_en = '1' AND addr_y_en = '1' THEN
               addr_x <= STD_LOGIC_VECTOR(TO_UNSIGNED(vga_hsync_cnt, 11));
               addr_y <= STD_LOGIC_VECTOR(TO_UNSIGNED(vga_vsync_cnt, 11));
               addr_en <= '1';
           ELSE
               addr_x <= (OTHERS => '0');
               addr_y <= (OTHERS => '0');
               addr_en <= '0';
           END IF;
        END IF;
   END PROCESS VRAM_read_Proc;
  
   
   VGA_Proc : PROCESS (clk_vga) IS
   BEGIN
      IF rising_edge(clk_vga) THEN
         IF rst_vga = '1' THEN
			vga_hsync_cnt <= 0;
			vga_vsync_cnt <= 0;
			
			addr_x_en <= '0';
			addr_y_en <= '0';
			
			int_vsync <= '0';
			int_hsync <= '0';
         ELSE
			vga_hsync_cnt <= vga_hsync_cnt + 1;
			
			-- delay hsync and vsync by 2 clock cycle, because pixel data read out needs 1 cycle
			int_vsync_dly <= int_vsync; 
			int_hsync_dly <= int_hsync;
			
			vsync <= int_vsync_dly;
			hsync <= int_hsync_dly;
			
			rgb <= vga_data;
			
			CASE HSYNC_VGA_STATE IS
            WHEN HSYNC_FP => 	         
                IF vga_hsync_cnt = HSYNC_FP_CONST-1 THEN 
                    HSYNC_VGA_STATE <= HSYNC_PW;
                    vga_hsync_cnt <= 0;
                    int_hsync <= '0';
                END IF;
            WHEN HSYNC_PW =>	
                IF vga_hsync_cnt = HSYNC_PW_CONST-1 THEN
                    HSYNC_VGA_STATE <= HSYNC_BP;
                    vga_hsync_cnt <= 0;
                    int_hsync <= '1';
                END IF;
            WHEN HSYNC_BP =>	
                IF vga_hsync_cnt = HSYNC_BP_CONST-1 THEN 
                    HSYNC_VGA_STATE <= HSYNC_DISP;
                    vga_hsync_cnt <= 0;
                    addr_x_en <= '1';
                END IF;
            WHEN HSYNC_DISP => 	              
                IF vga_hsync_cnt = HSYNC_DISP_CONST-1 THEN
                    addr_x_en <= '0';
                    HSYNC_VGA_STATE <= HSYNC_FP;
                    vga_hsync_cnt <= 0;
                    vga_vsync_refresh <= '1';
                END IF;						
			END CASE;
			
			IF vga_vsync_refresh = '1' THEN
			
			    vga_vsync_refresh <= '0';
			    vga_vsync_cnt <= vga_vsync_cnt + 1;
			    
                CASE VSYNC_VGA_STATE IS
                WHEN VSYNC_FP => 	
                    IF vga_vsync_cnt = VSYNC_FP_CONST-1 THEN 
                        VSYNC_VGA_STATE <= VSYNC_PW;
                        int_vsync <= '0';
                        vga_vsync_cnt <= 0;
                    END IF;
                WHEN VSYNC_PW =>	
                    IF vga_vsync_cnt = VSYNC_PW_CONST-1 THEN
                        VSYNC_VGA_STATE <= VSYNC_BP;
                        vga_vsync_cnt <= 0;  
                        int_vsync <= '1';
                    END IF;
                WHEN VSYNC_BP =>	
                    IF vga_vsync_cnt = VSYNC_BP_CONST-1 THEN 
                        VSYNC_VGA_STATE <= VSYNC_DISP;
                        vga_vsync_cnt <= 0;
                        addr_y_en <= '1';
                    END IF;
                WHEN VSYNC_DISP => 	
                    IF vga_vsync_cnt = VSYNC_DISP_CONST-1 THEN
                        addr_y_en <= '0';
                        VSYNC_VGA_STATE <= VSYNC_FP;
                        vga_vsync_cnt <= 0;
                    END IF;						
                END CASE;
             END IF;
         END IF;
      END IF;
   END PROCESS VGA_Proc; 
END ARCHITECTURE rtl;

