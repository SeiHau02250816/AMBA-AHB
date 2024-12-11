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

    // Transaction objects for various transfer types
    ahb_txn write_txn, idle_txn;
    ahb_txn read_setup_txn, read_txn;

    // Class to encapsulate randomizable properties
    class txn_properties;
        rand int unsigned haddr_value;
        rand logic [2:0] hsize_value;
        rand logic [3:0] hwstrb_value;
        rand logic [1:0] htrans_value;

        constraint valid_hsize {
            hsize_value inside {3'b000, 3'b001, 3'b010}; // Byte, Halfword, Word
        }

        constraint valid_htrans {
            htrans_value inside {2'b00, 2'b01, 2'b10, 2'b11}; // IDLE, BUSY, NONSEQ, SEQ
        }

        constraint valid_hwstrb {
            solve hsize_value before hwstrb_value;
            if (hsize_value == 3'b000) hwstrb_value <= 4'b0001; // BYTE
            else if (hsize_value == 3'b001) hwstrb_value <= 4'b0011; // HALFWORD
            else if (hsize_value == 3'b010) hwstrb_value <= 4'b1111; // WORD
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
            end
            $fclose(file);
        end else begin
            $display("Error: Could not open configuration file ahb_config.cfg");
        end

        // Display loaded configurations
        $display("Loaded Configurations:");
        $display("NUM_OF_TXN = %0d", num_txns);
        $display("CONSECUTIVE = %0d", consecutive);
        $display("TRANSFER_SIZE = %b", transfer_size);
        $display("WRITE_STROBE = %b", write_strobe);
        $display("TRANSFER_TYPE = %b", transfer_type);
    endfunction

    task gen_single();
        txn_properties props = new();
        
        // Randomize properties
        assert(props.randomize() with {
            props.haddr_value inside {[32'h0000_0000 : 32'h0FFF_FFFF]};  // Address range
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

        // Write transaction
        write_txn = new();
        write_txn.randomize() with {
            hwrite == 1'b1;      // Write transfer
            hsize == props.hsize_value;
            haddr == props.haddr_value; // Use the same randomized address
            hwstrb == props.hwstrb_value; // Use configured write strobe or randomized value
            htrans == props.htrans_value; // Use the specified htrans value
        };
        g2d_mb.put(write_txn);
        
        // Read transaction
        read_txn = new();
        read_txn.randomize() with {
            hwrite == 1'b0;      // Read transfer
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
    
    // Main generation task
    task gen;
        #30;
        $display("Task generate :: ahb_txn_gen with %0d transaction(s), CONSECUTIVE=%0d", num_txns, consecutive);
        
        gen_non_consecutive();
    endtask
endclass