-- ----------------------------------------------------------------------
-- Copyright (C) 2015 Mahdi Sellami, Christoph Pflüger, Niklas Rosenstein
-- All rights reserved.
-- ----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;

-- ----------------------------------------------------------------------
-- entity decoderMultiplexer
-- TODO Documentation
-- ----------------------------------------------------------------------

entity decoderMultiplexer is
port( MUX  : in  std_logic;
	
	  -- a.k.a /CAS
      CAS  : in  std_logic;
      CLK  : in  std_logic;
      AD   : in  std_logic_vector (25 downto 2);
      
      -- a.k.a /BE
      BE   : in  std_logic_vector ( 3 downto 0);
      A    : out std_logic_vector (10 downto 0);
      
      -- a.k.a /CASx(3:0) (x:0-3)
      CAS0 : out std_logic_vector ( 3 downto 0);
      CAS1 : out std_logic_vector ( 3 downto 0);
      CAS2 : out std_logic_vector ( 3 downto 0);
      CAS3 : out std_logic_vector ( 3 downto 0)
);
end entity decoderMultiplexer;

-- ----------------------------------------------------------------------
-- architecture behaviour of decoderMultiplexer
-- TODO Documentation
-- ----------------------------------------------------------------------

architecture behaviour of decoderMultiplexer is
begin
	process(CLK)
	begin
		if rising_edge(CLK) then					
			-- Signal to handle upper 11 bits
			if falling_edge(MUX) then
				report "falling_edge(MUX)";
				A <= AD(25 downto 15);
			end if;
			
			-- Signal to handle lower 11 bits and signal all modules to wake up
			-- and check whether or not the row-column-address fits their module.
			-- Fitting module then reads/writes data according to the BE 4-byte
			-- enable signals.
			if falling_edge(CAS) then
				report "falling_edge(CAS)";
				A <= AD(12 downto 2);
				
				-- Select module via 2-bits in AD between 11 upper bits (row) and 11 lower bits (column).
				case AD(14 downto 13) is
					when "00" =>
						CAS0 <= BE;
					when "01" =>
						CAS1 <= BE;
					when "10" =>
						CAS2 <= BE;
					when "11" =>
						CAS3 <= BE;
					when others =>
				end case;
			end if;
		end if;	
	end process;
end architecture behaviour;
