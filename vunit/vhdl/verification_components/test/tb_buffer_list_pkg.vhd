-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2025, Lars Asplund lars.anders.asplund@gmail.com

library ieee;
use ieee.std_logic_1164.all;

library vunit_lib;
context vunit_lib.vunit_context;
use vunit_lib.log_levels_pkg.all;
use vunit_lib.logger_pkg.all;
use vunit_lib.check_pkg.all;

use work.memory_pkg.all;
use work.buffer_list_pkg.all;

entity tb_buffer_list is
  generic (runner_cfg : string);
end entity;

architecture a of tb_buffer_list is
  shared variable list : buffer_list_t;
  constant logger : logger_t := get_logger("vunit_lib:buffer_list");
begin

  main : process
    function new_buffer(addr : natural; size : natural) return buffer_t is
      variable buf : buffer_t;
    begin
      buf.p_address := addr;
      buf.p_num_bytes := size;
      return buf;
    end function;

    variable buf : buffer_t;
  begin
    test_runner_setup(runner, runner_cfg);

    if run("insert_and_get_buffer") then
      list.insert(new_buffer(1000, 10));
      buf := list.get(1000);
      check_equal(buf.p_address, 1000, "Address mismatch");
    elsif run("get_from_empty_list") then
      mock(logger, error);
      buf := list.get(1000);
      check_only_log(logger, "Buffer not found", error);
      unmock(logger);
    elsif run("insert_overlapping_buffer") then
      list.insert(new_buffer(1000, 10));

      mock(logger, error);
      list.insert(new_buffer(1005, 10));
      check_only_log(logger, "Overlapping buffer found", error);
      unmock(logger);
    elsif run("get_buffers") then
      list.insert(new_buffer(4096, 4096));
      list.insert(new_buffer(1024, 1024));
      list.insert(new_buffer(65536, 65536));
      list.insert(new_buffer(3000, 500));
      buf := list.get(5000);
      check_equal(buf.p_address, 4096, "Address mismatch");
      buf := list.get(3200);
      check_equal(buf.p_address, 3000, "Address mismatch");
      buf := list.get(100000);
      check_equal(buf.p_address, 65536, "Address mismatch");
      buf := list.get(2047);
      check_equal(buf.p_address, 1024, "Address mismatch");
      check_equal(list.len, 4, "Length mismatch");
    elsif run("remove_buffers") then
      list.insert(new_buffer(4096, 4096));
      list.insert(new_buffer(1024, 1024));
      list.insert(new_buffer(3000, 500));
      list.print;
      info("Removing buffer at address 3000");
      list.remove(3000);
      list.print;
      buf := list.get(5000);
      check_equal(buf.p_address, 4096, "Address mismatch");
      check_equal(list.len, 2, "Length mismatch");
      mock(logger, error);
      buf := list.get(3200);
      check_only_log(logger, "Address not within list", error);
      unmock(logger);
      buf := list.get(2047);
      check_equal(buf.p_address, 1024, "Address mismatch");
      info("Removing first buffer in list at address 1024.");
      list.remove(1024);
      list.print;
      mock(logger, error);
      buf := list.get(2047);
      check_only_log(logger, "Address not within list", error);
      unmock(logger);
      info("Removing last buffer in list at address 4096.");
      list.remove(4096);
      list.print;
      check_equal(list.len, 0, "Length mismatch");
    elsif run("clear_list") then
      list.insert(new_buffer(4096, 4096));
      list.insert(new_buffer(1024, 1024));
      list.insert(new_buffer(3000, 500));
      list.print;
      info("Clearing buffer list");
      list.clear;
      list.print;
      check_equal(list.len, 0, "Length mismatch");
    end if;

    test_runner_cleanup(runner);
  end process;
end architecture;
