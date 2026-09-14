module rand_diffr_randc_tb;
  class random_example;
    rand bit[2:0]rand_num;
    randc bit[2:0]randc_num;
  endclass
  random_example obj;
  initial begin
    obj=new();
    $display("rand numbers");
    repeat (10) begin
      obj.randomize();
      $display("rand_num =%0d",obj.rand_num);
    end
    $display("randc number");
    repeat (10)begin
      obj.randomize();
      $display("randc_num =%0d",obj.randc_num);
    end
  end
endmodule