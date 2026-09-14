module tb;
  class packet;
    rand int data;
    rand int address;
    function void pre_randomize();
      $display("randomization is start");
    endfunction
    function void post_randomize();
      $display("randomization is complated");
      $display("data =%0d",data);
      $display("address =%0d \n",address);
    endfunction
  endclass
  packet p;
  initial begin 
    p=new();
    repeat(3)begin
      p.randomize();
    end
    $finish;
  end
endmodule
    