module random_tb;
 class packet;
   rand int address;
   rand int data;
   constraint data_c{
     data inside{[10:50]};
   }
 endclass
  class child extends packet;
    constraint write_data_c{
      data inside {[10:20]};//if the range having[10:100]more than parent class we can use the constraint_mode() to override.
    }
  endclass
  child p;
  initial begin
    p=new();
    repeat (3) begin
      if(p.randomize())begin
        $display("address =%0d",p.address);
        $display("data =%0d",p.data);
      end
    else begin
      $display("randomization failed");
    end
    end
  end
endmodule
    
    