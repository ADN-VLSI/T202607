package pkg_101;

  typedef struct packed {
    logic [3:0] id;
    logic [3:0] data;
    logic [3:0] phone;
  } my_struct_t;

  int my_phone = 530285;

  function int multiple(input int a, input int b);
    return a * b;
  endfunction

endpackage
