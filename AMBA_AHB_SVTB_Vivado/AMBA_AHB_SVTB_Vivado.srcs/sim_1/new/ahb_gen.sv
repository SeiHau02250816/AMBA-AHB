//////////////////////////////////////////////////////////////////////////////////
// Engineer: SeiHau Teo
// 
// Create Date: 21.11.2024
// Design Name: ahb_generator
// Module Name: ahb_gen
// Project Name: AHB SVTB
// 
// Revision:
//    v1.0: Created AHB transaction generator.
// 
// Additional Comments: 
// - Generator for AMBA AHB Testbench 
// - Unlike APB, AHB doesn't have operating states, and thus we don't need to consider
//   transactions for state transfer.
//////////////////////////////////////////////////////////////////////////////////

class ahb_gen;
    // Configuration properties as global class members
    int num_txns;
    int consecutive;
    mailbox g2d_mb;
    int transfer_size;
    int write_strobe;
    int transfer_type;  // Added transfer type configuration
    bit burst; // Configuration to determine if burst transactions are to be generated
    int burst_type; // Configuration to determine the type of burst transaction
    int addr; // Configuration for the starting address of transactions
    int wdata; // Configuration for the data to be written

    // Transaction objects for various transfer types
    ahb_txn write_txn, idle_txn;
    ahb_txn read_setup_txn, read_txn;

    // Class to encapsulate randomizable properties
    class txn_properties;
        rand int unsigned haddr_value;
        rand logic [2:0] hsize_value;
        rand logic [3:0] hwstrb_value;
        rand logic [1:0] htrans_value;
        rand logic [3:0] hprot_value;
        rand int unsigned hwdata_value;

        constraint valid_hsize {
            hsize_value inside {3'b000, 3'b001, 3'b010}; // Byte, Halfword, Word
        }

        constraint valid_htrans {
            htrans_value inside {2'b00, 2'b01, 2'b10, 2'b11}; // IDLE, BUSY, NONSEQ, SEQ
        }

        constraint aligned_and_valid_addr {
            solve hsize_value before haddr_value;

            // Alignment based on hsize
            if (hsize_value == 3'b010) { // WORD transfer
                haddr_value[1:0] == 2'b00; // Ensure word alignment
            } else if (hsize_value == 3'b001) { // HALFWORD transfer
                haddr_value[0] == 1'b0; // Ensure halfword alignment
            }

            // Ensure valid address range
            haddr_value <= 32'hbfff_ffff;
        }

        constraint valid_hwstrb_value { 
            solve hsize_value before hwstrb_value;
            solve haddr_value before hwstrb_value;

            if (hsize_value == 3'b000) { // BYTE
                if (haddr_value[1:0] == 2'b00) hwstrb_value[3:1] == 3'b000; // Only hwstrb[0] can be randomized
                else if (haddr_value[1:0] == 2'b01) hwstrb_value[3:2] == 2'b00 && hwstrb_value[0] == 1'b0; // hwstrb[1] can be randomized
                else if (haddr_value[1:0] == 2'b10) hwstrb_value[3] == 1'b0 && hwstrb_value[1:0] == 2'b00; // hwstrb[2] can be randomized
                else if (haddr_value[1:0] == 2'b11) hwstrb_value[2:0] == 3'b000; // Only hwstrb[3] can be randomized
            } 
            else if (hsize_value == 3'b001) { // HALFWORD
                if (haddr_value[1] == 1'b0) hwstrb_value[3:2] == 2'b00; // hwstrb[1:0] can be randomized
                else if (haddr_value[1] == 1'b1) hwstrb_value[1:0] == 2'b00; // hwstrb[3:2] can be randomized
            }
            // For hsize == 3'b010 (WORD), no constraint is added to hwstrb for fine-grained masking
        }

        function new();
            // Constructor
        endfunction
    endclass

    // Constructor
    function new(mailbox g2d_mb);
        this.g2d_mb = g2d_mb;
        load_configurations();  // Load configurations on instantiation
    endfunction

    // Method to load configurations from the config file
    function void load_configurations();
        int file;
        string line;
        num_txns = 0;      // Default value if not specified in the file
        consecutive = 0;   // Default to non-consecutive if not specified
        transfer_size = -1;
        write_strobe = -1;
        transfer_type = -1; // Default value for transfer type
        burst = 0; // Default to non-burst if not specified
        burst_type = -1; // Default burst type (can be set to specific values)
        addr = -1; // Default starting address
        wdata = -1;

        file = $fopen("ahb_config.cfg", "r");
        if (file) begin
            while (!$feof(file)) begin
                line = "";
                $fgets(line, file);
                if ($sscanf(line, "NUM_OF_TXN=%d", num_txns) == 1) continue;
                if ($sscanf(line, "CONSECUTIVE=%d", consecutive) == 1) continue;
                if ($sscanf(line, "TRANSFER_SIZE=%d", transfer_size) == 1) continue;
                if ($sscanf(line, "WRITE_STROBE=%d", write_strobe) == 1) continue;
                if ($sscanf(line, "TRANSFER_TYPE=%d", transfer_type) == 1) continue;
                if ($sscanf(line, "BURST=%d", burst) == 1) continue;
                if ($sscanf(line, "BURST_TYPE=%d", burst_type) == 1) continue;
                if ($sscanf(line, "ADDRESS=%d", addr) == 1) continue;
                if ($sscanf(line, "DATA=%d", wdata) == 1) continue;
            end
            $fclose(file);
        end else begin
            $display("Error: Could not open configuration file ahb_config.cfg");
        end

        // Display loaded configurations
        $display("Loaded Configurations:");
        $display("NUM_OF_TXN = %0d", num_txns);
        $display("CONSECUTIVE = %0d", consecutive);
        $display("TRANSFER_SIZE = %0d", transfer_size);
        $display("WRITE_STROBE = %0b", write_strobe);
        $display("TRANSFER_TYPE = %0d", transfer_type);
        $display("BURST = %0b", burst);
        $display("BURST_TYPE = %0b", burst_type);
        $display("ADDRESS = %0h", addr);
    endfunction

    task gen_single();
        txn_properties props = new();
        
        // Randomize properties
        assert(props.randomize() with {
            props.htrans_value <= 2'b10; // Randomize to IDLE, BUSY, or NONSEQ
        }) else $fatal(1, "Failed to randomize transaction properties");

        // Overwrite props if configurations are specified
        if (transfer_size != -1 && write_strobe != -1) begin
            props.hsize_value = transfer_size[2:0]; // Use transfer_size from config
            props.hwstrb_value = write_strobe; // Use write_strobe from config
        end
        
        // Overwrite transfer type if specified in config
        if (transfer_type != -1) begin
            props.htrans_value = transfer_type[1:0];
        end

        // Overwrite address if specified in config
        if (addr != -1) begin
            props.haddr_value = addr;
        end

        // Overwrite data if specified in config
        if (wdata != -1) begin
            props.hwdata_value = wdata;
        end

        // Write transaction
        write_txn = new();
        write_txn.randomize() with {
            hwrite == 1'b1;      // Write transfer
            hburst == 3'b000; // Set hburst to SINGLE
            hsize == props.hsize_value;
            haddr == props.haddr_value; // Use the same randomized address
            hwdata == props.hwdata_value;
            hwstrb == props.hwstrb_value; // Use configured write strobe or randomized value
            htrans == props.htrans_value; // Use the specified htrans value
        };
        g2d_mb.put(write_txn);
        
        // Read transaction
        read_txn = new();
        read_txn.randomize() with {
            hwrite == 1'b0;      // Read transfer
            hburst == 3'b000; // Set hburst to SINGLE
            haddr  == props.haddr_value; // Read from the same address
            hsize == props.hsize_value; // Use the same randomized hsize
            htrans == props.htrans_value; // Use the specified htrans value
        };
        g2d_mb.put(read_txn);
    endtask: gen_single

    // Task to generate non-consecutive transactions
    task gen_non_consecutive();
        for (int i = 0; i < this.num_txns; i++) begin
            gen_single();
        end
    endtask: gen_non_consecutive

    // Task to generate burst transactions
    task gen_burst();
        int num_burst_txns;
        txn_properties props = new();
        
        // Randomize properties
        assert(props.randomize()) else $fatal(1, "Failed to randomize transaction properties");

        // Overwrite props if configurations are specified
        if (transfer_size != -1 && write_strobe != -1) begin
            props.hsize_value = transfer_size[2:0]; // Use transfer_size from config
            props.hwstrb_value = write_strobe; // Use write_strobe from config
        end
        
        // Determine number of transactions based on burst_type
        if (burst_type == 0) num_burst_txns = 1; // SINGLE
        else if (burst_type == 1) num_burst_txns = num_txns; // INCR (use provided num_txns)
        else if (burst_type == 2 || burst_type == 3) num_burst_txns = 4; // WRAP4 / INCR4
        else if (burst_type == 4 || burst_type == 5) num_burst_txns = 8; // WRAP8 / INCR8
        else num_burst_txns = 16; // WRAP16 / INCR16

        // Display the number of burst transactions
        $display("Number of burst transactions: %0d", num_burst_txns);

        // Generate first transaction with NONSEQ
        write_txn = new();
        write_txn.randomize() with {
            hwrite == 1'b1; // Write transfer
            haddr == addr; // Start address
            htrans == 2'b01; // NONSEQ
            hsize == props.hsize_value;
            hburst == burst_type;
            hwstrb == props.hwstrb_value;
            hprot == props.hprot_value;
        };
        g2d_mb.put(write_txn);

        // Generate remaining write transactions
        for (int i = 1; i < num_burst_txns; i++) begin
            write_txn = new();
            write_txn.randomize() with {
                hwrite == 1'b1; // Write transfer
                haddr == addr + (i * props.hsize_value); // Increment address
                htrans == 2'b11; // SEQ
                hsize == props.hsize_value;
                hburst == burst_type;
                hwstrb == props.hwstrb_value;
                hprot == props.hprot_value;
            };
            g2d_mb.put(write_txn);
        end

        // Generate first read transaction
        read_txn = new();
        read_txn.randomize() with {
            hwrite == 1'b0; // Read transfer
            haddr == addr; // Start address
            htrans == 2'b01; // NONSEQ for first read
            hsize == props.hsize_value;
            hburst == burst_type;
            hprot == props.hprot_value;
        };
        g2d_mb.put(read_txn);

        // Generate remaining read transactions
        for (int i = 1; i < num_burst_txns; i++) begin
            read_txn = new();
            read_txn.randomize() with {
                hwrite == 1'b0; // Read transfer
                haddr == addr + (i * props.hsize_value); // Increment address
                htrans == 2'b11; // SEQ
                hsize == props.hsize_value;
                hburst == burst_type;
                hprot == props.hprot_value;
            };
            g2d_mb.put(read_txn);
        end
    endtask: gen_burst
    
    // Main generation task
    task gen;
        #30;
        $display("Task generate :: ahb_txn_gen with %0d transaction(s), CONSECUTIVE=%0d", num_txns, consecutive);
        
        if(burst && burst_type != -1)
            gen_burst();
        else
            gen_non_consecutive();

    endtask
endclass