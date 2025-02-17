-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2025, Lars Asplund lars.anders.asplund@gmail.com

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.com_pkg.all;
use work.com_types_pkg.all;
use work.queue_pkg.all;
use work.sync_pkg.all;
use work.logger_pkg.all;
use work.vc_pkg.all;
use work.runner_pkg.all;
use work.run_pkg.all;
use work.run_types_pkg.all;
use work.log_levels_pkg.all;
use work.irq_controller_pkg.all;

entity irq_controller is
  generic (
    irq_handle        : irq_controller_t
  );
  port (
    clk               : in  std_logic;
    irq               : in  std_logic_vector
  );
end entity;

architecture behav of irq_controller is
  constant message_queue : queue_t := new_queue;
  signal idle_bus : boolean := true;

  impure function queues_empty return boolean is
  begin
    return is_empty(message_queue);
  end function;

  impure function is_idle return boolean is
  begin
    return idle_bus;
  end function;

begin

  PROC_MAIN: process
    variable request_msg, reply_msg : msg_t;
    variable irq_mask : std_logic_vector(irq'range);
    variable msg_type : msg_type_t;
  begin
    DISPATCH_LOOP : loop
      receive(net, irq_handle.p_actor, request_msg);
      msg_type := message_type(request_msg);

      if msg_type = wait_for_msg then
        irq_mask := (others => '0');
        irq_mask(pop_integer(request_msg)) := '1';
        wait until rising_edge(clk) and irq = irq_mask;
        reply_msg := new_msg;
        reply(net, request_msg, reply_msg);
      else
        if irq_handle.p_unexpected_msg_type_policy = fail then
          unexpected_msg_type(msg_type);
        end if;
      end if;
    end loop;
  end process;

end architecture;