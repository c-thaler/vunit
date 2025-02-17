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
use work.irq_controller_pkg.all;

library osvvm;
use osvvm.RandomPkg.all;

entity tb_irq_controller is
  generic (
    runner_cfg : string
  );
end entity;

architecture a of tb_irq_controller is

  constant CLOCK_PERIOD : time := 10 ns;
  constant IRQ_WIDTH    : natural := 2;

  signal clk     : std_logic := '0';
  
  constant irq_handle : irq_controller_t := new_irq_controller;
  
  signal irq, irq_nxt : std_logic_vector(IRQ_WIDTH-1 downto 0) := (others => '0');
  signal start : boolean := false;
begin

  main_stim : process
    constant unexpected_message_type : msg_type_t := new_msg_type("unexpected message");
    variable unexpected_message : msg_t := new_msg(unexpected_message_type);
  begin
    show(get_logger("irq controller"), display_handler, debug);

    test_runner_setup(runner, runner_cfg);
    start <= true;
    wait for 0 ns;

    if run("wait_on_irqs") then
      irq_nxt <= "01";
      wait_for_irq(net, irq_handle, 0);
      check(irq = "01", "IRQ check");
      irq_nxt <= "10";
      wait_for_irq(net, irq_handle, 1);
      check(irq = "10", "IRQ check");
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
    irq <= irq_nxt;
  end process;

  U_IRQ_CONTROLLER: entity work.irq_controller
    generic map (
      irq_handle => irq_handle
    )
    port map (
      clk         => clk,
      irq         => irq
    );

  clk <= not clk after CLOCK_PERIOD/2;
end architecture;