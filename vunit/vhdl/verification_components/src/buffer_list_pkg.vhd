library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

use work.memory_pkg.all;
use work.checker_pkg.all;
use work.check_pkg.all;
use work.logger_pkg.all;
use work.integer_vector_ptr_pkg.all;

package buffer_list_pkg is

  type buffer_list_t is protected

    procedure insert(element : in buffer_t);
    impure function get(address : natural) return buffer_t;
    procedure remove(address : natural);
    procedure clear;
    impure function len return integer;
    procedure print;
  
  end protected buffer_list_t;

end package buffer_list_pkg;

package body buffer_list_pkg is
  constant logger : logger_t := get_logger("vunit_lib:buffer_list");
  constant checker : checker_t := new_checker(logger);
  
  type buffer_list_t is protected body
    type item_t;
    type item_ptr_t is access item_t;

    type item_t is record
      buf : buffer_t;
      mapping : natural; -- Mapping of buffer address to actual data
      nxt : item_ptr_t;
    end record;

    variable head : item_ptr_t := NULL;
    variable count : integer := 0;

    procedure insert(element : in buffer_t) is
      variable new_item : item_ptr_t;
      variable current : item_ptr_t := head;
      variable previous : item_ptr_t := NULL;
    begin      
      while current /= NULL and element.p_address > current.buf.p_address loop
        check(checker, element.p_address >= current.buf.p_address + current.buf.p_num_bytes, "Overlapping buffer found");
        
        previous := current;
        current := current.nxt;
      end loop;

      check(checker, current = NULL or element.p_address + element.p_num_bytes <= current.buf.p_address, "Overlapping buffer found");

      new_item := new item_t;
      new_item.buf := element;
      new_item.nxt := current;
      if previous = NULL then
        head := new_item;
        check(checker, head /= NULL, "Buffer list is empty");        
      else
        previous.nxt := new_item;
      end if;

      count := count + 1;
    end procedure insert;

    impure function get(address : natural) return buffer_t is
      variable current : item_ptr_t := head;
    begin
      while current /= NULL and address >= current.buf.p_address + current.buf.p_num_bytes loop
        current := current.nxt;
      end loop;
      
      if current /= NULL then
        check(checker, address >= current.buf.p_address, "Address not within list");
        return current.buf;
      else
        error(logger, "Buffer not found");
        return null_buffer;
      end if;      
    end function get;

    procedure remove(address : natural) is
      variable current : item_ptr_t := head;
      variable previous : item_ptr_t := NULL;
    begin
      while current /= NULL loop
        if address = current.buf.p_address then
          if previous = NULL then
            head := current.nxt;
          else
            previous.nxt := current.nxt;
          end if;
          deallocate(current);
          count := count - 1;
          return;
        else
          previous := current;
          current := current.nxt;
        end if;
      end loop;
      error("Address not within list. Cannot remove buffer.");
    end procedure remove;

    procedure clear is
      variable current : item_ptr_t := head;
      variable nxt : item_ptr_t;
    begin
      while current /= NULL loop
        nxt := current.nxt;
        deallocate(current);
        current := nxt;
      end loop;
      count := 0;
    end procedure clear;

    impure function len return integer is
    begin
      return count;
    end function len;

    procedure print is
      variable current : item_ptr_t := head;
    begin
      info("Buffer list content:");
      if current = NULL then
        info("  Empty list");
        return;
      end if;
      while current /= NULL loop
        info("  Buffer: " & integer'image(current.buf.p_address)
             & " - " & integer'image(current.buf.p_address + current.buf.p_num_bytes - 1)
             & " (" & integer'image(current.buf.p_num_bytes) & " bytes)");
        current := current.nxt;
      end loop;
    end procedure print;

  end protected body buffer_list_t;
end package body buffer_list_pkg;