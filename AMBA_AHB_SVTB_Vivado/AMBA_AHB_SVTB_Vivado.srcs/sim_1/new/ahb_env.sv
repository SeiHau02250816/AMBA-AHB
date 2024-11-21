//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 21.11.2024 
// Design Name: ahb_environment
// Module Name: ahb_env
// Project Name: AHB SVTB
// 
// Description:
//    AHB Environment for AMBA AHB-Lite Testbench
//    - Configures and connects all testbench components
//    - Manages generator, driver, monitor, and scoreboard
//    - Coordinates transaction flow between components
//    - Provides main test execution task
//
// Key Features:
//    - Uses mailbox-based communication between components
//    - Supports parallel execution of testbench elements
//    - Provides controlled test duration
//    - Centralizes testbench configuration
//
// Dependencies:
//    - Requires ahb_gen, ahb_drv, ahb_mon, ahb_sb classes
//    - Requires ahb_intf interface
//
// Revision:
//    v1.0 - Initial implementation of AHB testbench environment.
//////////////////////////////////////////////////////////////////////////////////

class ahb_env;
    // Virtual interface for AHB signals
    virtual ahb_intf vintf;
    ahb_gen ahb_gen_h;
    ahb_drv ahb_drv_h;
    mailbox g2d_mb;
    
    ahb_mon ahb_mon_h;
    ahb_sb  ahb_sb_h;
    mailbox m2s_mb;
    
    // Configuration parameters (optional, for future extensibility)
    int unsigned test_duration = 1500;  // Default test duration
    
    // Constructor
    function new(virtual ahb_intf vintf);
        // Store the virtual interface
        this.vintf = vintf;
        
        // Create mailbox for generator-driver communication
        g2d_mb = new();
        ahb_gen_h = new(g2d_mb);
        ahb_drv_h = new(this.vintf, g2d_mb);
        
        // Create mailbox for monitor-scoreboard communication
        m2s_mb = new();
        ahb_mon_h = new(this.vintf, m2s_mb);
        ahb_sb_h = new(m2s_mb);
    endfunction
    
    // Main test execution task
    task main;
        $display("Task main :: ahb_env");
        
        // Fork parallel execution of testbench components
        fork 
            ahb_gen_h.gen();
            ahb_drv_h.drive();
            ahb_mon_h.sample();
            ahb_sb_h.check();
        join_any
        
        // Wait for specified test duration
        #(test_duration);
        $finish;
    endtask
    
    // Optional: Method to set custom test duration
    function void set_test_duration(input int unsigned duration);
        test_duration = duration;
    endfunction
endclass