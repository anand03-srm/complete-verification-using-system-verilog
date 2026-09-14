module random_tb;
 class packet;
   rand int address;
   rand int data;
 endclass
  packet p;
  initial begin
    p=new();
    p.data.rand_mode(0);//we can disable data variables
    p.data=100;
    repeat (5) begin
      if(p.randomize())begin
        $display("address =  %0d ",p.address);
        $display("data = %0d ",p.data);
      end
      else begin
        $display("randomization failed");
      end
    end
    p.data.rand_mode(1);//again we enable the data variable
    repeat (5) begin
      if(p.randomize())begin
        $display("address =  %0d ",p.address);
        $display("data = %0d ",p.data);
      end
      else begin
        $display("randomization failed");
      end
    end
  end
endmodule
    
    