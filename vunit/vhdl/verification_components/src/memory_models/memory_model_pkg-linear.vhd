-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,
-- You can obtain one at http://mozilla.org/MPL/2.0/.
--
-- Copyright (c) 2014-2025, Lars Asplund lars.anders.asplund@gmail.com

use work.integer_vector_ptr_pkg.all;

package memory_model_pkg is
  type memory_model_t is record
    data : integer_vector_ptr_t;
  end record;

  impure function new_memory_model return memory_model_t;

  constant null_memory_model : memory_model_t := (data => null_ptr);
end package;

package body memory_model_pkg is

  impure function new_memory_model return memory_model_t is
    variable model : memory_model_t;
  begin
    model.data := new_integer_vector_ptr(0);
    return model;
  end function;

end package body;