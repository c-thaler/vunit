-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2024, Lars Asplund lars.anders.asplund@gmail.com

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

context work.vunit_context;
context work.com_context;
use work.logger_pkg.all;
use work.signal_detector_pkg.all;

library osvvm;
use osvvm.RandomPkg.all;

entity tb_signal_detector is
  generic (
    runner_cfg : string
  );
end entity;

architecture a of tb_signal_detector is

  constant CLOCK_PERIOD : time := 10 ns;
  constant SIGNALS_WIDTH    : natural := 2;

  signal clk     : std_logic := '0';
  
  constant detector_handle : signal_detector_t := new_signal_detector;
  
  signal signals, signals_nxt : std_logic_vector(SIGNALS_WIDTH-1 downto 0) := (others => '0');
  signal start : boolean := false;
begin

  main_stim : process
    constant unexpected_message_type : msg_type_t := new_msg_type("unexpected message");
    variable unexpected_message : msg_t := new_msg(unexpected_message_type);
  begin
    show(get_logger("signal detector"), display_handler, debug);

    test_runner_setup(runner, runner_cfg);
    start <= true;
    wait for 0 ns;

    if run("wait_on_signals") then
      signals_nxt <= "01";
      wait_for_signal(net, detector_handle, 0, '1');
      check(signals = "01", "signal check");
      signals_nxt <= "10";
      wait_for_signal(net, detector_handle, 1, '1');
      check(signals = "10", "signal check");
    end if;

    wait for 100 ns;

    test_runner_cleanup(runner);
    wait;
  end process;
  test_runner_watchdog(runner, 100 us);

  process
  begin
    wait for 5*CLOCK_PERIOD;
    wait until rising_edge(clk);
    signals <= signals_nxt;
  end process;

  DUT: entity work.signal_detector
    generic map (
      detector_handle => detector_handle
    )
    port map (
      clk         => clk,
      signals     => signals
    );

  clk <= not clk after CLOCK_PERIOD/2;
end architecture;