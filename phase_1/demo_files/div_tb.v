`timescale 1ns/10ps

module div_tb; 	
    reg pc_out; 
    reg zlo_out; 
    reg zhi_out;
    reg mdr_out; 
    reg mar_enable; 
    reg z_enable;
    reg hi_enable;
    reg lo_enable;
    reg pc_enable; 
    reg mdr_enable; 
    reg read;
    reg ir_enable; 
    reg y_enable;
    reg pc_increment; 
    //reg r1_enable; 
    reg r4_enable; 
    reg r5_enable;
    reg r4_out; 
    reg r5_out;
    reg clk; 
    reg clr;
    reg [4:0] op_code; 
    reg [31:0] m_data_in;
    wire [31:0] zlo_data;

    // FSM signals
    parameter start = 4'b0000; 
    parameter reg_load1a = 4'b0001; 
    parameter reg_load1b = 4'b0010; 
    parameter reg_load2a = 4'b0011; 
    parameter reg_load2b = 4'b0100; 
    parameter reg_load3a = 4'b0101; 
    parameter reg_load3b = 4'b0110; 
    parameter T0 = 4'b0111; 
    parameter T1 = 4'b1000; 
    parameter T2 = 4'b1001; 
    parameter T3 = 4'b1010; 
    parameter T4 = 4'b1011; 
    parameter T5 = 4'b1100; 
    parameter T6 = 4'b1101;
    reg	[3:0] present_state = start;

    // Opcodes for operations
    parameter ld_opcode = 5'b00000;
    parameter ldi_opcode = 5'b00001;
    parameter st_opcode = 5'b00010;
    parameter add_opcode = 5'b00011;
    parameter sub_opcode = 5'b00100;
    parameter shr_opcode = 5'b00101;
    parameter shra_opcode = 5'b00110;
    parameter shl_opcode = 5'b00111;
    parameter ror_opcode = 5'b01000;
    parameter rol_opcode = 5'b01001;
    parameter and_opcode = 5'b01010;
    parameter or_opcode = 5'b01011;
    parameter addi_opcode = 5'b01100;
    parameter andi_opcode = 5'b01101;
    parameter ori_opcode = 5'b01110;
    parameter mul_opcode = 5'b01111;
    parameter div_opcode = 5'b10000;
    parameter neg_opcode = 5'b10001;
    parameter not_opcode = 5'b10010;
    
    mult_datapath DUT(
        .pc_out(pc_out), 
        .zlo_out(zlo_out), 
        .mdr_out(mdr_out), 
        .mar_enable(mar_enable), 
        .z_enable(z_enable), 
        // Added hi and lo inputs
        .hi_enable(hi_enable),
        .lo_enable(lo_enable),
        .pc_enable(pc_enable), 
        .mdr_enable(mdr_enable), 
        .read(read), 
        .ir_enable(ir_enable), 
        .y_enable(y_enable), 
        .pc_increment(pc_increment),
        .op_code(op_code),
        .m_data_in(m_data_in),
        // removed r1
        //.r1_enable(r1_enable),
        .r4_enable(r4_enable),
        .r5_enable(r5_enable),
        .r4_out(r4_out),
        .r5_out(r5_out),
        .clr(clr), 
        .clk(clk),
        .zlo_data(zlo_data)
    );

    // FSM changes on positive edge of clock every two clock cycles
    reg toggle = 0;

    // Toggle the counter on every clock cycle
    always @(posedge clk)
    begin
        toggle <= ~toggle;
    end

    always @(posedge clk)
    begin
        if (toggle == 1)  // Check if toggle is set to change the state
        begin
            case (present_state)
                start       : present_state = reg_load1a;
                reg_load1a  : present_state = reg_load1b;
                reg_load1b  : present_state = reg_load2a;
                reg_load2a  : present_state = reg_load2b;
                reg_load2b  : present_state = reg_load3a;
                // reg_load3a  : present_state = reg_load3b;
                // reg_load3b  : present_state = T0;
                T0          : present_state = T1;
                T1          : present_state = T2;
                T2          : present_state = T3;
                T3          : present_state = T4;
                T4          : present_state = T5;
                // Added this state
                T5          : present_state = T6;
            endcase
        end
    end

    always @(present_state)
    begin
        case (present_state)
            // present_state: 0
            // Set all signals to 0
            start: begin	
                pc_out <= 0; zlo_out <= 0; mdr_out <= 0;
                r4_out <= 0; r5_out <= 0; mar_enable <= 0;
                z_enable <= 0; pc_enable <= 0; mdr_enable <= 0;
                ir_enable <= 0; y_enable <= 0; pc_increment <= 0;   
                read <= 0; op_code <= 0; z_enable <= 0;
                r1_enable <= 0; r2_enable <= 0; r3_enable <= 0; 
                m_data_in <= 32'h00000000;
            end
            
            // present_state: 1
            // Load 0xA0A0A0A0 into MDR
            reg_load1a: begin
                m_data_in <= 32'hA0A0A0A0;
                read <= 1; mdr_enable <= 1;
                #20 read <= 0; mdr_enable <= 0;
            end

            // present_state: 2
            // Load MDR into R2
            reg_load1b: begin
                mdr_out <= 1; r4_enable <= 1;
                #20 mdr_out <= 0; r4_enable <= 0;
            end

            // present_state: 3
            // Load 0x00000000 into MDR
            reg_load2a: begin
                m_data_in <= 32'h0000000F;
                read <= 1; mdr_enable <= 1;
                #20 read <= 0; mdr_enable <= 0;
            end
            
            // present_state: 4
            // Load MDR into R3
            reg_load2b: begin	
                mdr_out <= 1; r5_enable <= 1;
                #20 mdr_out <= 0; r5_enable <= 0;
            end
        
            // present_state: 5
            // Load PC into MAR and increment PC. 
            T0: begin
                pc_out <= 1; mar_enable <= 1; pc_increment <= 1; 
                #20 mar_enable <= 0; pc_increment <= 0; //z_enable <= 1;
                #20 pc_out <= 0; //z_enable <= 0;
            end

            // present_state: 6
            // Load "AND R1, R2, R3" into MDR
            T1: begin
                m_data_in <= 32'h28918000; 
                read <= 1; mdr_enable <= 1; pc_enable <= 1; //zlo_out <= 1;
                #20 read <= 0; mdr_enable <= 0; pc_enable <= 0; //zlo_out <= 0;		
            end

            // present_state: 7
            // Load MDR into IR
            T2: begin
                mdr_out<= 1; ir_enable <= 1; 
                #20 mdr_out<= 0; ir_enable <= 0; 
            end

            // present_state: a
            // Load R2 into Y
            T3: begin	
                r4_out<= 1; y_enable <= 1;
                #20 r4_out<= 0; y_enable <= 0;  
            end

            // present_state: b
            // Put R3 into alu.b and put or opcode into ALU. Store ALU restults in ZLO
            // Replace mul_opcode with div_opcode to test for division
            T4: begin
                r5_out<= 1; op_code <= mul_opcode; z_enable <= 1; 
                #20 r5_out<= 0; z_enable <= 0;
            end

            // present_state: c
            // Store ZLO into lo register
            T5: begin	
                zlo_out<= 1; lo_enable <= 1;
                #20 zlo_out <= 1; lo_enable <= 1;
            end

            // present_state: d
            // Store ZHI into hi register
            T6: begin
                zhi_out <= 1; hi_enable <= 1;
                #20 zhi_out <= 0; hi_enable <= 0;
            end
        endcase
    end
endmodule