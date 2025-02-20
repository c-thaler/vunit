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
use work.logger_pkg.all;
use work.sync_pkg.all;
use work.id_pkg.all;
use work.vc_pkg.all;

package signal_detector_pkg is

  type signal_detector_t is record
    -- Private
    p_id : id_t;
    p_actor : actor_t;
    p_logger : logger_t;
    p_unexpected_msg_type_policy : unexpected_msg_type_policy_t;
    p_std_cfg : std_cfg_t;
  end record;

  impure function new_signal_detector(
    id : id_t := null_id;
    logger : logger_t := null_logger;
    actor : actor_t := null_actor;
    unexpected_msg_type_policy : unexpected_msg_type_policy_t := fail
  ) return signal_detector_t;

  function get_logger(handle : signal_detector_t) return logger_t;

  procedure wait_for_signal(signal net : inout network_t; handle : signal_detector_t; index : integer; level : std_logic);
  procedure wait_for_clock(signal net : inout network_t; handle : signal_detector_t; cycles : integer := 1);

  constant wait_for_msg : msg_type_t := new_msg_type("wait for irq");
  constant wait_for_clock_msg : msg_type_t := new_msg_type("wait for clock");
end package;

package body signal_detector_pkg is

  impure function new_signal_detector(
    id : id_t := null_id;
    logger : logger_t := null_logger;
    actor : actor_t := null_actor;
    unexpected_msg_type_policy : unexpected_msg_type_policy_t := fail
  ) return signal_detector_t is
    variable logger_tmp : logger_t := null_logger;
    variable id_tmp : id_t := null_id;
    variable actor_tmp : actor_t := null_actor;
    constant parent : id_t := get_id("vunit_lib:signal_detector");
    variable std_cfg : std_cfg_t;
  begin
    std_cfg := create_std_cfg(
      id => get_id(to_string(num_children(parent) + 1), parent),
      provider => "vunit_lib",
      vc_name => "signal_detector",
      unexpected_msg_type_policy => unexpected_msg_type_policy
    );
    if id = null_id then
      id_tmp := get_id(to_string(num_children(parent) + 1), parent);
    else
      id_tmp := id;
    end if;
    if logger = null_logger then
      logger_tmp := get_logger(id_tmp);
    else
      logger_tmp := logger;
    end if;
    if actor = null_actor then
      actor_tmp := new_actor;
    else
      actor_tmp := actor;
    end if;
    return (
      p_id => id_tmp,
      p_actor => actor_tmp,
      p_logger => logger_tmp,
      p_unexpected_msg_type_policy => unexpected_msg_type_policy,
      p_std_cfg => std_cfg
    );
  end;

  function get_logger(handle : signal_detector_t) return logger_t is
  begin
    return handle.p_logger;
  end function;

  procedure wait_for_signal(signal net : inout network_t; handle : signal_detector_t; index : integer; level : std_logic) is
    variable request_msg, reply_msg : msg_t;
  begin
    request_msg := new_msg(wait_for_msg);
    push_std_ulogic(request_msg, level);
    push_integer(request_msg, index);
    request(net, handle.p_actor, request_msg, reply_msg);
    delete(reply_msg);
  end procedure;

  procedure wait_for_clock(signal net : inout network_t; handle : signal_detector_t; cycles : integer := 1) is
    variable request_msg, reply_msg : msg_t;
  begin
    request_msg := new_msg(wait_for_clock_msg);
    push_integer(request_msg, cycles);
    request(net, handle.p_actor, request_msg, reply_msg);
    delete(reply_msg);
  end procedure;

end package body;