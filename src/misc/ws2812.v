module ws2812 #(
    parameter CLK_FRE = 28_375_160, // kept for existing instantiations
    parameter USE_CLK7_EN = 0
) (
    input         clk,
    input         reset,
    input         clk7_en,
    input  [23:0] color,             // bytes are pre-reversed by sysctrl
    output reg    data = 1'b0
);

// One bit takes nine 7 MHz ticks (1.27 us). A zero is high for two
// ticks; a one is high for six. Hold low for at least 2048 ticks
// (289 us) between frames so newer WS2812 variants also latch.
wire tick;
generate if (USE_CLK7_EN) begin : external_enable
    assign tick = clk7_en;
end else begin : local_enable
    reg [1:0] divider = 0;
    always @(posedge clk) begin
        if (reset) divider <= 0;
        else       divider <= divider + 2'd1;
    end
    assign tick = (divider == 0);
end endgenerate

reg        sending = 1'b0;
reg [10:0] count = 0;
reg [4:0]  bit_index = 0;
reg        bit_value = 0;

always @(posedge clk) begin
    if (reset) begin
        sending   <= 1'b0;
        count     <= 0;
        bit_index <= 0;
        bit_value <= 0;
        data      <= 1'b0;
    end else if (tick) begin
        if (!sending) begin
            count <= count + 11'd1;
            if (count == 11'd2047) begin
                sending   <= 1'b1;
                count     <= 0;
                bit_index <= 0;
                bit_value <= color[0];
                data      <= 1'b1;
            end
        end else if (count == 11'd8) begin
            count <= 0;
            if (bit_index == 5'd23) begin
                sending <= 1'b0;
                data    <= 1'b0;
            end else begin
                bit_index <= bit_index + 5'd1;
                bit_value <= color[bit_index + 5'd1];
                data      <= 1'b1;
            end
        end else begin
            count <= count + 11'd1;
            if ((count == 11'd1 && !bit_value) ||
                (count == 11'd5 && bit_value))
                data <= 1'b0;
        end
    end
end

endmodule
