//**************************************************************************
//********** MODULE FOR READING AND PROCESSING OF IMAGES *******************
//**************************************************************************
`include "parameter.v"

module image_read
#( parameter   width=256,                 // WIDTH OF INPUT IMAGE
					height=256,                // HEIGHT OF INPUT IMAGE
					INFILE="MRImedical.hex",   // INPUT IMAGE FILE NAME
					value=100,                  // VALUE FOR BRIGHTNESS OPERATION
					threshold=90,         // THRESHOLD VALUE FOR THRESHOLD OPERATION
					sign=0                // SIGN=0: BRIGHTNESS SUBTRACTION
					                      // SIGN=1: BRIGHTNESS ADDITION
)
(
	input clk,               // CLOCK
	input reset,             // RESET SIGNAL(ACTIVE LOW)
	output reg [7:0]red,     // 8 BIT RED COMPONENT OF IMAGE DATA
	output reg [7:0]green,   // 8 BIT GREEN COMPONENT OF IMAGE DATA
	output reg [7:0]blue     // 8 BIT BLUE COMPONENT OF IMAGE DATA
 );

//---------------------------------------------------------------------------
//----------------  INTERNAL SIGNALS   --------------------------------------
//---------------------------------------------------------------------------	 

reg [7:0]mem[0:width*height*3-1];     // MEMORY TO STORE 8 BIT DATA IMAGE
integer temp_mem[0:width*height*3-1];  // TEMPORARY MEMORY TO STORE DATA
integer org_r[0:width*height-1];      // MEMORY TO STORE RED COMPONENT OF DATA
integer org_g[0:width*height-1];      // MEMORY TO STORE GREEN COMPONENT OF DATA
integer org_b[0:width*height-1];      // MEMORY TO STORE BLUE COMPONENT OF DATA
reg [9:0]row=0;      // STORE ROW INDEX OF DATA
reg [10:0]col=0;     // STORE COLUMN INDEX OF DATA
reg done=0;         // DONE FLAG
reg start=0;           // START SIGNAL
integer temp_r,temp_g,temp_b;    // TEMPORARY VARIABLE FOR BRIGHTNESS OPERATION
integer value1,value2;      // TEMPORARY VARIABLE FOR THRESHOLD AND INVERT OPERATION
integer i,j;  // COUNTING VARIABLE

//---------------------------------------------------------------------------
//-----------  READING IMAGE DATA FROM INPUT FILE   -------------------------
//---------------------------------------------------------------------------

initial begin
	$readmemh(INFILE,mem);   // READ FILE FROM INFILE
end

always@(start)
begin
	if(start==1'b1)
	begin
		for(i=0;i<width*height*3;i=i+1)
			begin
				temp_mem[i]=mem[i][7:0];
			end

		for(i=0;i<height;i=i+1)
		begin
			for(j=0;j<width;j=j+1)
			begin
				org_r[width*i+j]=temp_mem[width*3*(height-1-i)+3*j+0];  // READING RED COMPONENT
				org_g[width*i+j]=temp_mem[width*3*(height-1-i)+3*j+1];  // READING GREEN COMPONENT
				org_b[width*i+j]=temp_mem[width*3*(height-1-i)+3*j+2];  // READING BLUE COMPONENT
			end
		end
	end	
end 	


//---------------------------------------------------------------------------
//-----------  CREATE STARTING PULSE    -------------------------------------
//---------------------------------------------------------------------------

always@(posedge clk or negedge reset)
begin
	if(!reset)
	start<=0;
	else
	start<=1;
end


//---------------------------------------------------------------------------
//-----------  CALCULATING ROW AND COLUMN IMAGE FILE   ----------------------
//---------------------------------------------------------------------------

always@(posedge clk or negedge reset)
begin
	if(!reset)
	begin
		row<=0;     // INITIALIZE ROW TO ZERO WHEN RESET IS LOW
		col<=0;     // INITIALIZE COLUMN TO ZERO WHEN RESET IS LOW
	end
	else begin
		if(col==width-1)
		begin
			row<=row+1;
			col<=0;
			if(row==height-1)
			begin
				row<=0;
				done<=1'b1;
			end	
		end
		else
			col<=col+1;    // READING ONE PIXEL AT A TIME 
	end		
end

//---------------------------------------------------------------------------
//-----------  IMAGE PROCESSING OPERATION   ---------------------------------
//---------------------------------------------------------------------------

always@(*)
begin
	if(done==1'b0)
	begin		
		//---------------------------------------------------------------------------
		//-----------  ORIGINAL IMAGE FILE   ----------------------------------------
		//---------------------------------------------------------------------------
		`ifdef ORIGINAL_IMAGE
			red   =org_r[width*row+col];   
			green =org_g[width*row+col];
			blue  =org_b[width*row+col];
		`endif
		
		//---------------------------------------------------------------------------
		//-----------  INVERT OPERATION OF IMAGE   ----------------------------------
		//---------------------------------------------------------------------------
		`ifdef INVERT_OPERATION
			value1=(org_r[width*row+col]+org_g[width*row+col]+org_b[width*row+col])/3;
			red   =255-value1;
			green =255-value1;
			blue  =255-value1;
		`endif
		
		//---------------------------------------------------------------------------
		//-----------  BRIGHTNESS ADDITION OPERATION OF IMAGE   ---------------------
		//---------------------------------------------------------------------------
		`ifdef BRIGHTNESS_OPERATION
			if(sign==1)
			begin
				temp_r=org_r[width*row+col]+value;
				if(temp_r>255)
				red=255;
				else
				red=temp_r;
				
				temp_g=org_g[width*row+col]+value;
				if(temp_g>255)
				green=255;
				else
				green=temp_g;
				
				temp_b=org_b[width*row+col]+value;
				if(temp_b>255)
				blue=255;
				else
				blue=temp_b;			
			end
		//---------------------------------------------------------------------------
		//-----------  BRIGHTNESS SUBTRACTION OPERATION FOR IMAGE   -----------------
		//---------------------------------------------------------------------------

			else begin
				temp_r=org_r[width*row+col]-value;
				if(temp_r<0)
				red=0;
				else
				red=temp_r;
				
				temp_g=org_g[width*row+col]-value;
				if(temp_g<0)
				green=0;
				else
				green=temp_g;
				
				temp_b=org_b[width*row+col]-value;
				if(temp_b<0)
				blue=0;
				else
				blue=temp_b;		
			end
		`endif
		
		//---------------------------------------------------------------------------
		//-----------  THRESHOLD OPERATION FOR IMAGE   ------------------------------
		//---------------------------------------------------------------------------
		`ifdef THRESHOLD_OPERATION
			value2=(org_r[width*row+col]+org_g[width*row+col]+org_b[width*row+col])/3;
			if(value2>threshold)
			begin
				red=255;
				green=255;
				blue=255;
			end
			else begin
				red=0;
				green=0;
				blue=0;
			end
		`endif
	end
end

endmodule
