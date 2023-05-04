//	For Audio CODEC
wire		   AUD_CTRL_CLK;	//	For Audio Controller

//	For VGA Controller
wire		   VGA_CTRL_CLK;
wire  [9:0]	mVGA_R;
wire  [9:0]	mVGA_G;
wire  [9:0]	mVGA_B;
wire [19:0]	mVGA_ADDR;

wire			mVGA_CLK;
wire	[9:0]	mRed;
wire	[9:0]	mGreen;
wire	[9:0]	mBlue;
wire			VGA_Read;	//	VGA data request

wire  [9:0] recon_VGA_R;
wire  [9:0] recon_VGA_G;
wire  [9:0] recon_VGA_B;

wire		   DLY_RST;
reg  [31:0]	Cont;
wire [23:0]	mSEG7_DIG;

wire			mDVAL;

//audio count
reg [31:0] audio_count;
reg        key1_reg;


// initial //  
	         
assign DRAM_DQ 			= 16'hzzzz;

assign AUD_ADCLRCK    	= 1'bz;     					
assign AUD_DACLRCK 		= 1'bz;     					
assign AUD_DACDAT 		= 1'bz;     					
assign AUD_BCLK 		   = 1'bz;     						
assign AUD_XCK 		   = 1'bz;     						
   						
assign FPGA_I2C_SDAT		= 1'bz;     						
assign FPGA_I2C_SCLK		= 1'bz; 


assign GPIO_A  		=	36'hzzzzzzzz;
assign GPIO_B  		=	36'hzzzzzzzz;

assign AUD_XCK	       =	AUD_CTRL_CLK;
assign AUD_ADCLRCK	 =	AUD_DACLRCK;

//	Enable TV Decoder
assign	TD_RESET_N	=	KEY[0];

// assign	LEDR      	=	10'b0//KEY[0]? {	Cont[25:24],Cont[25:24],Cont[25:24],Cont[25:24],Cont[25:24]	}:10'h3ff;
assign	mSEG7_DIG	=	24'b0;//KEY[0]? {	Cont[27:24],Cont[27:24],Cont[27:24],Cont[27:24],Cont[27:24],Cont[27:24] } :{6{4'b1000}};
