-- ----------------------------------------------------------------------
-- Copyright (C) 2015 Mahdi Sellami, Christoph Pflüger, Niklas Rosenstein
-- All rights reserved.
-- ----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- ----------------------------------------------------------------------
-- entity decoderMultiplexer_tb
-- TODO Documentation
-- ----------------------------------------------------------------------

entity decoderMultiplexer_tb is
end entity decoderMultiplexer_tb;

-- ----------------------------------------------------------------------
-- architecture behaviour of decoderMultiplexer_tb
-- TODO Documentation
-- ----------------------------------------------------------------------

architecture behaviour of decoderMultiplexer_tb is
	-- decoderMultiplexer component
	component decoderMultiplexer is
		port( MUX  : in  std_logic;
		      CAS  : in  std_logic;
		      CLK  : in  std_logic;
		      AD   : in  std_logic_vector (25 downto 2);
		      BE   : in  std_logic_vector ( 3 downto 0);
		      A    : out std_logic_vector (10 downto 0);
		      CAS0 : out std_logic_vector ( 3 downto 0);
		      CAS1 : out std_logic_vector ( 3 downto 0);
		      CAS2 : out std_logic_vector ( 3 downto 0);
		      CAS3 : out std_logic_vector ( 3 downto 0)
		);
	end component decoderMultiplexer;

	-- in
	signal MUX : std_logic := '1';
	signal CAS : std_logic := '1';
	signal CLK : std_logic := '0';
	signal AD  : std_logic_vector (25 downto 2);
	signal BE  : std_logic_vector ( 3 downto 0);

	-- out
	signal A    : std_logic_vector (10 downto 0);
	signal CAS0 : std_logic_vector ( 3 downto 0);
	signal CAS1 : std_logic_vector ( 3 downto 0);
	signal CAS2 : std_logic_vector ( 3 downto 0);
	signal CAS3 : std_logic_vector ( 3 downto 0);
begin
	-- Instantiate decoderMultiplexer (Unit Under Test - UUT)
	uut : decoderMultiplexer port map (
		MUX  => MUX,
		CAS  => CAS,
		CLK  => CLK,
		AD   => AD,
		BE   => BE,
		A    => A,
		CAS0 => CAS0,
		CAS1 => CAS1,
		CAS2 => CAS2,
		CAS3 => CAS3		
	);

	-- Handle clock signal
	CLK <= not CLK after 10 ns;

	-- Test Bench
	tb: process
	begin
		report "DecoderMultiplexer initiated.";
		report "Staring testbench process...";
		report "Initializing AD(25:2) with test value (100101010010111010110101).";
		AD <= "100101010010111010110101";
		report "Initializing BE(3:0) with test value (0011).";
		BE <= "0011";

		report "Simulating falling_edge(MUX)";
		MUX <= not MUX after 10 ns;
		
		-- Wait for component to process...
		wait for 20 ns;
		
		-- Printing contents of signals for comparison reasons.
		report "A = " & integer'image(to_integer(unsigned((A))));
		report "AD(25 downto 15) = " & integer'image(to_integer(unsigned((AD(25 downto 15)))));
		
		-- Test:
		assert A = AD(25 downto 15) report "Invalid row selected!" severity Error;

		report "Simulating falling_edge(CAS)";
		CAS <= not CAS after 10 ns;
		
		-- Wait for component to process...
		wait for 20 ns;
		
		-- Printing contents of signals for comparisons reasons.
		report "A = " & integer'image(to_integer(unsigned((A))));
		report "AD(12 downto 2) = " & integer'image(to_integer(unsigned((AD(12 downto 2)))));
		
		-- Test:
		assert A = AD(12 downto 2) report "Invalid column selected!" severity Error;
		
		-- Printing contents of signals for comparisons reasons.
		report "BE = " & integer'image(to_integer(unsigned((BE))));
		report "CAS1 = " & integer'image(to_integer(unsigned((CAS1))));
		
		-- Test:
		assert BE = CAS1 report "Invalid DRAM module selected!" severity Error;

		-- Resetting input signals.
		MUX <= not MUX after 10 ns;
		CAS <= not CAS after 10 ns;
		report "Test completed.";
		wait;
	end process;
end architecture behaviour;
