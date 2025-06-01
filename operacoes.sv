`timescale 1ns / 1ps

module operacoes;
    reg clk;
    reg reset;
    reg [31:0] registers [0:31];
    reg [31:0] data_mem [0:1023];
    reg [31:0] pc;
    integer instruction_count;

    localparam
        OP_LH   = 0,
        OP_SH   = 1,
        OP_SUB  = 2,
        OP_OR   = 3,
        OP_ANDI = 4,
        OP_SRL  = 5,
        OP_BEQ  = 6,
        OP_ADDI = 7;    

    integer op_code [0:1023];
    integer rd     [0:1023];
    integer rs1    [0:1023];
    integer rs2_or_imm [0:1023];

    function void load_instructions(input string filename);
        integer file, i, code;
        reg [1023:0] line;
        int tmp_rd, tmp_rs1, tmp_rs2_or_imm;

        file = $fopen(filename, "r");
        if (file == 0) begin
            $display("Erro ao abrir arquivo %s", filename);
            $finish;
        end

        i = 0;
        while (!$feof(file)) begin
            code = $fgets(line, file);
            if (code != 0) begin
                if ($sscanf(line, "addi x%d, x%d, %d", tmp_rd, tmp_rs1, tmp_rs2_or_imm)) begin
                    op_code[i] = OP_ADDI;
                    rd[i] = tmp_rd;
                    rs1[i] = tmp_rs1;
                    rs2_or_imm[i] = tmp_rs2_or_imm;
                end else if ($sscanf(line, "lh x%d, %d(x%d)", tmp_rd, tmp_rs2_or_imm, tmp_rs1)) begin
                    op_code[i] = OP_LH;
                    rd[i] = tmp_rd;
                    rs1[i] = tmp_rs1;
                    rs2_or_imm[i] = tmp_rs2_or_imm;
                end else if ($sscanf(line, "sh x%d, %d(x%d)", tmp_rs2_or_imm, tmp_rs1, tmp_rd)) begin
                    op_code[i] = OP_SH;
                    rd[i] = tmp_rd;  
                    rs1[i] = tmp_rs1;
                    rs2_or_imm[i] = tmp_rs2_or_imm;
                end else if ($sscanf(line, "sub x%d, x%d, x%d", tmp_rd, tmp_rs1, tmp_rs2_or_imm)) begin
                    op_code[i] = OP_SUB;
                    rd[i] = tmp_rd;
                    rs1[i] = tmp_rs1;
                    rs2_or_imm[i] = tmp_rs2_or_imm;
                end else if ($sscanf(line, "or x%d, x%d, x%d", tmp_rd, tmp_rs1, tmp_rs2_or_imm)) begin
                    op_code[i] = OP_OR;
                    rd[i] = tmp_rd;
                    rs1[i] = tmp_rs1;
                    rs2_or_imm[i] = tmp_rs2_or_imm;
                end else if ($sscanf(line, "andi x%d, x%d, %d", tmp_rd, tmp_rs1, tmp_rs2_or_imm)) begin
                    op_code[i] = OP_ANDI;
                    rd[i] = tmp_rd;
                    rs1[i] = tmp_rs1;
                    rs2_or_imm[i] = tmp_rs2_or_imm;
                end else if ($sscanf(line, "srl x%d, x%d, x%d", tmp_rd, tmp_rs1, tmp_rs2_or_imm)) begin
                    op_code[i] = OP_SRL;
                    rd[i] = tmp_rd;
                    rs1[i] = tmp_rs1;
                    rs2_or_imm[i] = tmp_rs2_or_imm;
                end else if ($sscanf(line, "beq x%d, x%d, %d", tmp_rs1, tmp_rs2_or_imm, tmp_rd)) begin
                    op_code[i] = OP_BEQ;
                    rd[i] = -1;
                    rs1[i] = tmp_rs1;
                    rs2_or_imm[i] = tmp_rs2_or_imm;
                end else begin
                    $display("Instrucao nao reconhecida: %s", line);
                    $finish;
                end
                i = i + 1;
            end
        end
        instruction_count = i;
        $fclose(file);
    endfunction

    task print_registers;
        integer i;
        begin
            for (i = 0; i < 32; i = i + 1) begin
                $display("Register[x%0d]: %0d", i, registers[i]);
            end
        end
    endtask

    task execute_instruction;
        integer op, d, s1, s2i;
        begin
            op = op_code[pc];
            d = rd[pc];
            s1 = rs1[pc];
            s2i = rs2_or_imm[pc];

            case (op)
                OP_ADDI: registers[d] = registers[s1] + s2i;
                OP_LH:   registers[d] = $signed(data_mem[registers[s1] + s2i][15:0]);  
                OP_SH:   data_mem[registers[s1] + s2i][15:0] = registers[d][15:0];     
                OP_SUB:  registers[d] = registers[s1] - registers[s2i];
                OP_OR:   registers[d] = registers[s1] | registers[s2i];
                OP_ANDI: registers[d] = registers[s1] & s2i;
                OP_SRL:  registers[d] = registers[s1] >> (registers[s2i] & 5'b11111);
                OP_BEQ:  if (registers[s1] == registers[s2i]) begin
                             pc = pc + s2i;
                             disable execute_instruction;
                         end
                default: ;
            endcase
            pc = pc + 1;
        end
    endtask

    always #5 clk = ~clk;

    initial begin
        integer i;
        clk = 0;
        reset = 1;
        pc = 0;

        for (i = 0; i < 32; i = i + 1)
            registers[i] = 0;

        for (i = 0; i < 1024; i = i + 1)
            data_mem[i] = 0;

        load_instructions("instrucoes.txt");
        #10 reset = 0;

        while (pc < instruction_count) begin
            execute_instruction();
            #10;
        end

        print_registers();
        $finish;
    end
endmodule
