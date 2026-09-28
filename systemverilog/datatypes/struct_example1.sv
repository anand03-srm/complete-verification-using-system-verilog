module tb;
  struct{
    bit[31:0]data;
    bit[7:0]address;
    bit write;
  }trans;
  initial begin
    trans.data=32'h12345678;
    trans.address=8'h20;
    trans.write=1'b1;
    $display("data=%h ",trans.data);
    $display("address=%h ",trans.address);
    $display("write=%b ",trans.write);
  end
endmodule
    