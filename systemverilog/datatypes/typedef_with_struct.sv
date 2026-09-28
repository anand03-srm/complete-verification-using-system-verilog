module tb;

  typedef struct {
    bit [7:0]  addr;
    bit [31:0] data;
    bit        write;
  } transaction_t;

  transaction_t trans1;
  transaction_t trans2;

  initial begin

    trans1.addr  = 8'h10;
    trans1.data  = 32'hAAAA_BBBB;
    trans1.write = 1;

    trans2.addr  = 8'h20;
    trans2.data  = 32'h1234_5678;
    trans2.write = 0;

    $display("trans1 addr = %h", trans1.addr);
    $display("trans1 data = %h", trans1.data);
    $display("trans1 write = %b", trans1.write);

    $display("trans2 addr = %h", trans2.addr);
    $display("trans2 data = %h", trans2.data);
    $display("trans2 write = %b", trans2.write);

  end

endmodule