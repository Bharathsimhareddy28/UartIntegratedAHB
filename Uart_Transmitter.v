/* TRANSMITTER */

module UART_TRANSMITTER #(
                            parameter DataWidth = 32
                        )(
                            input t_clk,
                            input HSel,
                            input [1:0] HTrans,
                            input reset,
                            input send,
                            input load,
                            input [DataWidth-1:0] data_in,
                            output Tx,
                            output busy
                        );
wire baud_tick;
wire [DataWidth+2 : 0] packet;
baud_gen B_T(
                .t_clk(t_clk),
                .reset(reset),
                .baud_tick(baud_tick)
            );

frame_data #(.DataWidth(DataWidth))
                            P_T(
                                .data_in(data_in),
                                .packet(packet)
                                );

transmitter #(.DataWidth(DataWidth))
            T(
            .HSel(HSel),
            .t_clk(t_clk),
            .HTrans(HTrans),
            .baud_tick(baud_tick),
            .reset(reset),
            .send(send),
            .load(load),
            .packet(packet),
            .Tx(Tx),
            .busy(busy)
            );

endmodule

// baudrate of transmitter = 3906250bps i.e 260ns
// transmitter clk period  = 16ns 
// hence for 260ns we use clock divider of 16 (since 16*16 = 256 approx(260) )

module baud_gen (
    input t_clk,
    input reset,
    output baud_tick
);

reg [4:0] count = 1;
reg baud_tick_reg;
always @(posedge t_clk,negedge reset) 
begin
    if(!reset)
    begin 
        count <= 1;
        baud_tick_reg <= 1'b0;
    end
    else if(count==16)     // count = 16 since // time period of clock = 16ns  // one baud tick of transmitter occurs for every 256ns i.e 260ns
    begin
        count <= 1;
        baud_tick_reg <= 1'b1;
    end
    else 
    begin
        count <= count + 1;
        baud_tick_reg <= 1'b0;
    end        
end

assign baud_tick = baud_tick_reg;

endmodule

module frame_data#(
                    parameter DataWidth = 32
                )(
            
                        input  [DataWidth-1:0] data_in,
                        output [DataWidth+2:0] packet
                );

wire p ;
assign p = ~(^data_in);
// packet making 
assign packet = {1'b1,p,data_in,1'b0};

endmodule

module transmitter  #(
                        parameter DataWidth = 32
                     )
                        (

                            input t_clk,
                            input HSel,
                            input [1:0] HTrans,
                            input baud_tick,
                            input send,
                            input reset,
                            input load,
                            input [DataWidth+2:0] packet,
                            output Tx,
                            output busy

                        );



reg tx;                        // shows the output of transmitter
reg [DataWidth+2:0] packet_temp;        // to shift data and transmit
reg [DataWidth+2:0] packet_load_ready ; // for storing data to resend if data sent isn't correct 
reg [5:0] b ;                  // for counting no of bits transmitted
reg transmitting;              // can be used to check if transmitting

wire valid_transfer = HSel && ((HTrans == 2'b11) | (HTrans == 2'b10));
initial 
begin 
    b =6'd0 ; 
    transmitting = 1'b0;           // initializing them to start transmission 
    tx = 1'b1;                     // initially transmitter is in idle state 
    packet_load_ready = {35{1'b1}};   // if load occurs before send this treats as an idle state
end  
       
 
always @(posedge t_clk,negedge reset)
begin
    if(!reset)
    begin
        tx           <= 1'b1;
        b            <= 0;
        packet_temp  <= {35{1'b1}};
        transmitting <= 1'b0;
    end
    else if(load && send && valid_transfer)
    begin
        packet_temp   <=  packet_load_ready;
        transmitting  <=  1'b1;
    end
    else if (send && ~transmitting && valid_transfer)
    begin
            packet_temp       <= packet;
            packet_load_ready <= packet;
            transmitting      <= 1'b1;
    end
    else 
    begin
        if(baud_tick && transmitting && send && valid_transfer)
            begin
                tx                 <=  packet_temp[0];
                packet_temp        <=  {1'b1,packet_temp[DataWidth+2:1]};
                if(b==6'd34)
                begin
                    b              <=    6'd0;
                    transmitting   <=    1'b0;
                end
                else
                b                  <=  b + 6'd1;   
            end
    end
end


assign Tx = tx;
wire loading = valid_transfer && send && ~transmitting;
assign busy = transmitting | loading;


endmodule


