-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2025, Lars Asplund lars.anders.asplund@gmail.com

use work.types_pkg.byte_t;

package memory_model_pkg is
  subtype memory_model_ptr_t is integer;

  type memory_model_t is record
    ptr : memory_model_ptr_t;
  end record;

  constant null_memory_model : memory_model_t := (ptr => -1);

  impure function new_memory_model return memory_model_t;
  procedure write(model : memory_model_t; address : integer; value : integer);
  impure function read(model : memory_model_t; address : integer) return integer;
  impure function is_empty(model : memory_model_t) return boolean;
end package;

package body memory_model_pkg is

  type mem_array_list_t is protected
    impure function new_array return memory_model_t;
    procedure write(memory : memory_model_t;
                    address : natural;
                    value : integer);
    impure function read(memory : memory_model_t;
                         address : natural) return integer;
    impure function block_count(memory : memory_model_t) return integer;
  end protected mem_array_list_t;
  
  type mem_array_list_t is protected body

    constant block_addr_width : integer := 10;
    constant block_addr_div : integer := 2**22;
    constant block_length : integer := 2**22;

    type mem_block_t is array (0 to block_length-1) of integer;
    type mem_block_ptr_t is access mem_block_t;
    type mem_array_t is array (natural range<>) of mem_block_ptr_t;
    type mem_array_ptr_t is access mem_array_t;

    type mem_array_ptr_at is array (0 to 9) of mem_array_ptr_t;
    variable root : mem_array_ptr_at := (others => null);
    variable count : integer := 0;

    impure function new_array return memory_model_t is
      variable model : memory_model_t;
    begin
      assert count < 10
        report "mem_array_list is full"
        severity failure;
      model.ptr := count;
      root(count) := new mem_array_t(0 to 2**block_addr_width-1);
      --for i in 0 to 1023 loop
      --  root(count).all(i) := null;
      --end loop;
      count := count + 1;
      return model;
    end function;

    function block_index(address : natural) return integer is
    begin
      return address / block_addr_div;
    end function;

    function block_addr(address : natural) return integer is
    begin
      return address mod block_addr_div;
    end function;

    procedure allocate_block(memory : memory_model_t; block_idx : integer) is
    begin
      if root(memory.ptr).all(block_idx) = NULL then
        root(memory.ptr).all(block_idx) := new mem_block_t;
      end if;
    end procedure;

    procedure write(memory : memory_model_t;
                    address : natural;
                    value : integer) is
      variable block_idx : integer := block_index(address);
    begin
      allocate_block(memory, block_idx);
      root(memory.ptr).all(block_idx).all(block_addr(address)) := value;
    end procedure;

    impure function read(memory : memory_model_t;
                         address : natural) return integer is
    begin
      return root(memory.ptr).all(block_index(address)).all(block_addr(address));
    end function;

    impure function block_count(memory : memory_model_t) return integer is
      variable arr : mem_array_t(root(memory.ptr).all'range) := root(memory.ptr).all;
      variable bcount : integer := 0;
    begin
      for i in arr'range loop
        if arr(i) /= null then
          bcount := bcount + 1;
        end if;
      end loop;
      return bcount;
    end;

  end protected body mem_array_list_t;

  shared variable mem_array_list : mem_array_list_t;

  impure function new_memory_model return memory_model_t is
  begin
    return mem_array_list.new_array;
  end function;

  procedure write(model : memory_model_t; address : integer; value : integer) is
  begin
    mem_array_list.write(model, address, value);
  end;

  impure function read(model : memory_model_t; address : integer) return integer is
  begin
    return mem_array_list.read(model, address);
  end function;

  impure function is_empty(model : memory_model_t) return boolean is
  begin
    return mem_array_list.block_count(model) = 0;
  end function;
end package body;