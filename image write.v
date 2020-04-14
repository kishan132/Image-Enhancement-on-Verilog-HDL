//**************************************************************************
//********** MODULE FOR WRITING .BMP IMAGES ********************************
//**************************************************************************

module image_write
#( parameter   width=256,    
					height=256,
					INFILE="outputMRI.bmp",
					BMP_HEADER_NUM=54
)
(
	input clk,   // CLOCK
	input reset,   // RESET(ACTIVE LOW)
	input [7:0]in_red,
	input [7:0]in_green,
	input [7:0]in_blue,
	output reg done     // DONE FLAG
);

reg [7:0]BMP_header[0:53];
reg [7:0]out_bmp[0:width*height*3-1];
reg [9:0]row=0;
reg [10:0]col=0;
integer i,fid;

//---------------------------------------------------------------------------
//----------------  HEADER DATA FOR BMP IMAGE   -----------------------------
//---------------------------------------------------------------------------

initial begin
	BMP_header[ 0] = 66;BMP_header[28] =24;
	BMP_header[ 1] = 77;BMP_header[29] = 0;
	BMP_header[ 2] = 54;BMP_header[30] = 0;
	BMP_header[ 3] =  0;BMP_header[31] = 0;
	BMP_header[ 4] =  3;BMP_header[32] = 0;
	BMP_header[ 5] =  0;BMP_header[33] = 0;
	BMP_header[ 6] =  0;BMP_header[34] = 0;
	BMP_header[ 7] =  0;BMP_header[35] = 0;
	BMP_header[ 8] =  0;BMP_header[36] = 3;
	BMP_header[ 9] =  0;BMP_header[37] = 0;
	BMP_header[10] = 54;BMP_header[38] = 19;
	BMP_header[11] =  0;BMP_header[39] = 11;
	BMP_header[12] =  0;BMP_header[40] = 0;
	BMP_header[13] =  0;BMP_header[41] = 0;
	BMP_header[14] = 40;BMP_header[42] = 19;
	BMP_header[15] =  0;BMP_header[43] = 11;
	BMP_header[16] =  0;BMP_header[44] = 0;
	BMP_header[17] =  0;BMP_header[45] = 0;
	BMP_header[18] =  0;BMP_header[46] = 0;
	BMP_header[19] =  1;BMP_header[47] = 0;
	BMP_header[20] =  0;BMP_header[48] = 0;
	BMP_header[21] =  0;BMP_header[49] = 0;
	BMP_header[22] =  0;BMP_header[50] = 0;
	BMP_header[23] =  1;BMP_header[51] = 0;	
	BMP_header[24] =  0;BMP_header[52] = 0;
	BMP_header[25] =  0;BMP_header[53] = 0;
	BMP_header[26] =  1;
	BMP_header[27] =  0;
end

//---------------------------------------------------------------------------
//-----  ROW AND COLUMN COUNTING FOR TEMPORARY MEMORY OF IMAGE   ------------
//---------------------------------------------------------------------------		

always@(posedge clk or negedge reset)
begin
	if(!reset)
	begin
		row<=0;    
		col<=0;
	end
	else begin
		if(col==width-1)
		begin
			row<=row+1;
			col<=0;
			if(row==height-1)
			begin
				row<=0;    // TO OBTAIN ROW INDEX OD DATA
				done<=1'b1;  // AFTER COUNTING ALL PIXEL DONE WILL HIGH
			end
		end
		else
			col<=col+1;   // TO OBTAIN COLUMN INDEX OD DATA
	end	
end
	
always@(posedge clk or negedge reset or done)
begin
	if(!reset)
	begin
		for(i=0;i<width*height*3;i=i+1)
			out_bmp[i]<=0;
	end
	else begin
		if(done==1'b0)
		begin
			out_bmp[width*3*(height-1-row)+3*col+2]<=in_red;
			out_bmp[width*3*(height-1-row)+3*col+1]<=in_green;
			out_bmp[width*3*(height-1-row)+3*col+0]<=in_blue;
		end
	end
end

//---------------------------------------------------------------------------
//-----  WRITING .BMP FILE   ------------------------------------------------
//---------------------------------------------------------------------------

initial begin

	done=1'b0;
	fid=$fopen(INFILE,"wb+");
	
end

always@(done)
begin
	if(done==1'b1)    // ONCE PROCESSING WAS DONE IMAGE IS CREATED 
	begin
		for(i=0;i<BMP_HEADER_NUM;i=i+1)
		begin
			$fwrite(fid,"%c",BMP_header[i]);  // INITIALIZE FILE WITH HEADER BMP FORMAT
		end
		
		for(i=0;i<width*3*height;i=i+3)   // WRITE RGB DATA INA A LOOP
		begin
			$fwrite(fid,"%c",out_bmp[i+0][7:0]);
			$fwrite(fid,"%c",out_bmp[i+1][7:0]);
			$fwrite(fid,"%c",out_bmp[i+2][7:0]);
		end
		
		#10;
		$fclose(fid);	
		#10;
		$finish;         // SIMULATION WILL OVER 
	end
end

endmodule
