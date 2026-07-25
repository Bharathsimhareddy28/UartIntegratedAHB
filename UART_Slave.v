module UART_Slave #(
                            parameter DataWidth = 32,
                            parameter SamplingWidth = 16
                      )
                      (
                                // input common
                                input HSel,
                                input[1:0] HTrans,
                                // inputs to tx
                                input t_clk,
                                input HWrite, 
                                input HResetn,   // common for both    
                                input load_in, 
                                input [DataWidth-1:0] HWdata,
                                // inputs to rx
                                input rx,    
                                input r_clk,
                                // outputs to tx
                                output tx,
                                output uart_busy,
                                // outputs to rx
                                output[DataWidth-1:0] HRdata,
                                output uart_done,
                                output load_out,
                                // output common
                                output HResp,
                                output HReadyOut

                        );


wire Tx;

UART_TRANSMITTER   #(
                        .DataWidth(DataWidth)
                    )Transmitter(
                                .HSel(HSel),
                                .t_clk(t_clk),
                                .reset(HResetn),
                                .HTrans(HTrans),
                                .send(HWrite),
                                .load(load_in),
                                .data_in(HWdata),
                                .Tx(Tx),
                                .busy(uart_busy)
                                );

stage2_sync    Tx_synchronisation(
                    .in(Tx),
                    .reset(HResetn),
                    .clk(r_clk),
                    .sync(tx)
                );


UART_RECEIVER    #(
                        .DataWidth(DataWidth),
                        .SamplingWidth(SamplingWidth)

                  )  Receiver(
                                .HSel(HSel),
                                .r_clk(r_clk),
                                .reset(HResetn),
                                .HWrite(HWrite),
                                .rx(rx),
                                .data_out(HRdata),
                                .done(uart_done),
                                .load(load_out)                            
                            );

assign HReadyOut = (HWrite) ? ~uart_busy : uart_done;
assign HResp = load_out;

endmodule





