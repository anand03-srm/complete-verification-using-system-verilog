module random_tb;
  class packet;
    rand int addres;
    rand int data;
    rand int opcode;

  constraint addres_c{
    addres inside {[0:100]};
  }
  constraint data_c{
    data inside {[10:100]};
  }
  constraint opcode_c{
    opcode inside {1,3,4};
  }
  endclass
  packet p;
  initial begin
    p=new();
    repeat (10)begin
      if (p.randomize())begin
        $display("addres=%0d  data=%0d opcode=%0d ",p.addres,p.data,p.opcode);
      end
      else begin
        $display("randomize failed");
      end
    end
    $finish;
  end
endmodule


  
  
