module random_tb;
 class packet;
   rand int address;
   rand int data;
   constraint data_c{
     data inside{[10:50]};
   }
 endclass
  packet p;
  initial begin
    p=new();
    p.data_c.constraint_mode(0);//we can disable data constraint
    
    repeat (5) begin
      if(p.randomize())begin
        $display("address =  %0d ",p.address);
        $display("data = %0d ",p.data);
      end
      else begin
        $display("randomization failed");
      end
    end
    p.data_c.constraint_mode(1);//again we enable the data constarint
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
    
    