# TESTBENCHFILE = tb.v
TESTBENCHFILE = tb_top_0.v
TEST = $(basename $(TESTBENCHFILE))

run:
	iverilog $(TESTBENCHFILE) -y . -o $(TEST)
# if you cant find .vcd, check if there have
# $dumpfile("xxx.vcd");
# $dumpvars(0, xxx);
# xxx should be the top module name, and the file name and equal 
# to TESTBENCHFILE name here.
# in your testbench's initial block
	vvp -n $(TEST) -vcd

wave:
	gtkwave $(TEST).vcd 

clean:
	rm $(TEST) $(TEST).vcd
