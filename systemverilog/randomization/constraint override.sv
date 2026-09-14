module random_tb;
 class packet;
   
   rand int data;
   constraint data_c{
     data inside{[10:50]};
   }
 endclass
  class child extends packet;
    constraint data_c{
      data inside {[10:20]};
    }
  endclass
  child p;
  initial begin
    p=new();
    repeat (3) begin
      if(p.randomize())begin
        
        $display("data =%0d",p.data);
      end
    else begin
      $display("randomization failed");
    end
    end
  end
endmodule
    
    