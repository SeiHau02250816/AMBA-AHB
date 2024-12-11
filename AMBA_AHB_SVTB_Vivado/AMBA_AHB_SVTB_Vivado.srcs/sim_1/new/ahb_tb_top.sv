//////////////////////////////////////////////////////////////////////////////////
// Engineer: 
// 
// Create Date: 21.11.2024
// Design Name: AHB Testbench Top
// Module Name: ahb_tb_top
// Project Name: AHB SVTB
// 
// Description:
//    Top-level testbench module for AHB protocol verification
//    Instantiates DUT, interface, and test environment
//    Generates clock and reset signals
//    Manages test execution
//
// Revision:
//    v1.0 - Initial version
//////////////////////////////////////////////////////////////////////////////////

`include "ahb_intf.sv"
`include "ahb_txn.sv"
`include "ahb_env.sv"
`include "ahb_drv.sv"
`include "tests/ahb_single_write_single_read_test.sv"
`include "tests/ahb_multiple_non_consecutive_txns_test.sv"
`include "tests/write_strobe/ahb_full_word_write_test.sv"
`include "tests/write_strobe/ahb_sparse_write_test.sv"
`include "tests/write_strobe/ahb_no_write_test.sv"
`include "tests/write_strobe/ahb_halfword_strobe_test.sv"
`include "tests/txn_types/ahb_idle_transfer_test.sv"
`include "tests/txn_types/ahb_busy_transfer_test.sv"
`include "ahb_gen.sv"
`include "ahb_mon.sv"
`include "ahb_sb.sv"

module ahb_tb_top();
    // Test instantiations
    ahb_single_write_single_read_test test_01_h;
    ahb_full_word_write_test test_02_h;
    ahb_sparse_write_test test_03_h;
    ahb_no_write_test test_04_h;
    ahb_halfword_strobe_test test_05_h;
    ahb_idle_transfer_test test_06_h;
    ahb_busy_transfer_test test_07_h; 
    ahb_multiple_non_consecutive_txns_test test_08_h; 

    logic hclk, hresetn;
    
    // Interface instantiation
    ahb_intf intf(hclk, hresetn);
    
    // AHB DUT instantiation
    ahb_top dut (
        .hclk        (intf.hclk),
        .hresetn     (intf.hresetn),
        .haddr       (intf.haddr),
        .hwrite      (intf.hwrite),
        .hsize       (intf.hsize),
        .hburst      (intf.hburst),
        .hprot       (intf.hprot),
        .htrans      (intf.htrans),
        .hmastlock   (intf.hmastlock),
        .hwdata      (intf.hwdata),
        .hreadyout   (intf.hreadyout),
        .hresp       (intf.hresp),
        .hrdata      (intf.hrdata),
        .hwstrb      (intf.hwstrb)
    );

    always #5 hclk = ~hclk;
    
    initial begin
        hresetn = 0;
        #30 hresetn = 1;
    end
    
    initial begin
        hclk = 0;
        
        // Run the single write + single read test
//         test_01_h = new(intf);
//         test_01_h.main();

        // Run the full word write test
//        test_02_h = new(intf);
//        test_02_h.main();
        
        // Run the sparse write test
//        test_03_h = new(intf);
//        test_03_h.main();
        
        // Run the no write test
        test_04_h = new(intf);
        test_04_h.main();
        
        // Run the halfword strobe test
//        test_05_h = new(intf);
//        test_05_h.main();

        // Run the idle transfer test
//        test_06_h = new(intf);
//        test_06_h.main();

        // Run the busy transfer test
//        test_07_h = new(intf);
//        test_07_h.main();

        // Run the multiple non-consecutive transactions test
//        test_08_h = new(intf);
//        test_08_h.main();
    end
endmodule