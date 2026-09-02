package mem_if_pkg;

    typedef struct packed {
        logic [7:0]  addr;
        logic [31:0] wdata;
        logic        write;  // 1 = write, 0 = read
        logic        valid;  // request valid (held until ready)
    } mem_req_t;

    typedef struct packed {
        logic        ready;  // slave accepts / completes the request this cycle
        logic [31:0] rdata;  // read data, valid when (ready & !write)
        logic        error;  // optional slave error response
    } mem_resp_t;

endpackage : mem_if_pkg