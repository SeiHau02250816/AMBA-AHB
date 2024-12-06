//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 21.11.2024 
// Design Name: ahb_monitor
// Module Name: ahb_mon
// Project Name: AHB SVTB
// 
// Description:
//    AHB Monitor for AMBA AHB-Lite Testbench
//    - Captures and logs AHB bus transactions
//    - Samples bus signals during active transfers
//    - Writes detailed transaction logs to a file
//    - Sends transactions to scoreboard via mailbox
//
// Key Features:
//    - Monitors full AHB transaction details
//    - Logs transactions with timestamp and full details
//    - Supports read and write transactions
//    - Captures transfer type, address, data, and response
//
// Dependencies:
//    - Requires ahb_intf interface
//    - Requires ahb_txn transaction class (not shown)
//
// Revision:
//    v1.0 - Initial implementation of ahb monitor.
//////////////////////////////////////////////////////////////////////////////////

class ahb_mon;
    // Virtual interface for monitoring AHB signals
    virtual ahb_intf vintf;

    // Mailbox for sending transactions to scoreboard
    mailbox m2s_mb; 

    // Transaction handle
    ahb_txn txn_h;

    // Log file handle
    integer log_file;

    // Constructor
    function new(virtual ahb_intf vintf, mailbox m2s_mb);
        this.vintf = vintf;
        this.m2s_mb = m2s_mb;

        // Open the log file in write mode
        log_file = $fopen("results/ahb_transactions.log", "w");
        if (!log_file) $display("Error: Could not open ahb_transactions.log file.");
        else begin
            $display("Logging AHB transactions to results/ahb_transactions.log");
            // Write the header row with right-aligned fields and separator line
            $fwrite(log_file, "%20s | %10s | %15s | %10s | %10s | %10s | %10s | %10s | %10s | %10s | %10s\n",
                    "TIME(NS)", "OPERATION", "ADDR", "WRITE", "SIZE", "BURST", "TRANS", "WRITE DATA", "WRITE STROBE", "READ DATA", "RESPONSE");
            $fwrite(log_file, "--------------------------------------------------------------------------------------------------------------------------------------------------------------------------------\n");
        end
    endfunction
    
    // Destructor to close the log file
    function void close();
        if (log_file) $fclose(log_file);
    endfunction
    
    // Main sampling task
    task sample;
        forever begin
            txn_h = new();
            $display("Task sample :: ahb_mon");
            
            ahb_sample();
            ahb_log(); // Log the transaction after sampling
        end
    endtask
    
    // Sample AHB bus signals
    task ahb_sample;
        // Capture all relevant AHB signals
        txn_h.haddr = vintf.mon_cb.haddr;
        txn_h.hwrite = vintf.mon_cb.hwrite;
        txn_h.hsize = vintf.mon_cb.hsize;
        txn_h.hburst = vintf.mon_cb.hburst;
        txn_h.hprot = vintf.mon_cb.hprot;
        txn_h.htrans = vintf.mon_cb.htrans;
        txn_h.hmastlock = vintf.mon_cb.hmastlock;
        txn_h.hwdata = vintf.mon_cb.hwdata;
        txn_h.hwstrb = vintf.mon_cb.hwstrb;
        
        @(vintf.mon_cb);
        
        // Capture slave response signals
        txn_h.hreadyout = vintf.mon_cb.hreadyout;
        txn_h.hresp = vintf.mon_cb.hresp;
        txn_h.hrdata = vintf.mon_cb.hrdata;
        
        // Send transaction to mailbox for further processing
        m2s_mb.put(txn_h);
    endtask

    // Log the transaction details
    task ahb_log;
        string operation;
        string wdata_str;
        string rdata_str;
        string trans_str;
        string hwstrb_str;
        
        // Determine operation type
        if (txn_h.hwrite) begin
            operation = "WRITE";
            rdata_str = "0xXXXXXXXX"; 
            $sformat(wdata_str, "0x%08h", txn_h.hwdata);  // Pad write data with leading zeros
            $sformat(hwstrb_str, "%04b", txn_h.hwstrb);  // Format write strobe as 4-bit binary
        end else begin
            operation = "READ ";
            wdata_str = "0xXXXXXXXX"; 
            $sformat(rdata_str, "0x%08h", txn_h.hrdata);  // Pad read data with leading zeros
            hwstrb_str = "0000"; 
        end
        
        // Convert transfer type to string
        case(txn_h.htrans)
            2'b00:   trans_str = "IDLE";
            2'b01:   trans_str = "BUSY";
            2'b10:   trans_str = "NONSEQ";
            2'b11:   trans_str = "SEQ";
            default: trans_str = "UNDEF";
        endcase
        
        // Log the transaction details in right-aligned, table format with padded values
        $fwrite(log_file, "%12t | %10s | 0x%08h | %10d | %10d | %10d | %10s | %10s | %10s | %10s | %10d\n",
                $time, operation, txn_h.haddr, txn_h.hwrite, txn_h.hsize, 
                txn_h.hburst, trans_str, wdata_str, hwstrb_str, rdata_str, txn_h.hresp);
    endtask
endclass