COMPONENT = ../src/decoderMultiplexer.vhd
TESTBENCH = ../testbench/decoderMultiplexer_tb.vhd

all:
	ghdl -a $(COMPONENT)
	ghdl -s $(COMPONENT)
	
	ghdl -a $(TESTBENCH)
	ghdl -s $(TESTBENCH)
	ghdl -e decoderMultiplexer_tb

clean distclean::
	ghdl --clean
	ghdl --remove
	find . ! -name 'Makefile' -delete

run: all
	ghdl -r decoderMultiplexer_tb --stop-time=15sec --wave=decoderMultiplexer.ghw