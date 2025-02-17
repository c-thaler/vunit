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

  constant null_memory_model : memory_model_t := (ptr => memory_model_ptr_t'low);

  impure function new_memory_model return memory_model_t;
  procedure write(model : memory_model_t; address : integer; value : integer);
  impure function read(model : memory_model_t; address : integer) return integer;
  impure function is_empty(model : memory_model_t) return boolean;
  procedure clear(model : memory_model_t);
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
    procedure clear(memory : memory_model_t);
  end protected mem_array_list_t;
  
  type mem_array_list_t is protected body

    constant block_addr_width : integer := 10;
    constant block_addr_div : integer := 2**22;
    constant block_length : integer := 2**22;

    type mem_block_t is array (0 to block_length-1) of integer;
    type mem_block_ptr_t is access mem_block_t;
    type mem_array_t is array (natural range<>) of mem_block_ptr_t;
    type mem_array_ptr_t is access mem_array_t;

    type mem_array_ptr_at is array (natural range<>) of mem_array_ptr_t;
    type mem_array_ptr_ptr_at is access mem_array_ptr_at;
    variable root : mem_array_ptr_ptr_at := null;
    variable length : integer := 4;
    variable count : integer := 0;

    impure function new_array return memory_model_t is
      variable model : memory_model_t;
      variable next_array : mem_array_ptr_ptr_at;
    begin
      if root = null then
        root := new mem_array_ptr_at(0 to length-1);
      else
        if count = length then
          length := length * 2;
          next_array := new mem_array_ptr_at(0 to length-1);
          for i in root.all'range loop
            next_array.all(i) := root.all(i);
          end loop;
          deallocate(root);
          root := next_array;
        end if;
      end if;
      model.ptr := count;
      root.all(count) := new mem_array_t(0 to 2**block_addr_width-1);
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

    procedure clear(memory : memory_model_t) is
    variable memptr : mem_array_ptr_t := root(memory.ptr);
    begin
      for i in memptr.all'range loop
        if memptr(i) /= null then
          deallocate(memptr(i));
          memptr(i) := null;
        end if;
      end loop;
    end procedure;

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

  procedure clear(model : memory_model_t) is
  begin
    mem_array_list.clear(model);
  end procedure;
end package body;