module constarint_tb;
  class transaction;
    rand bit[15:0]pktlength;
    constraint undersize{pktlength<=16'd64;}
  endclass
  transaction trans=new;
  initial begin
    int sucess;
    for (int i=0;i<16;i++)begin
      sucess=trans.randomize();
      $display("pkrlength transaction is =%0d",trans.pktlength);
    end
  end
endmodule
    
  