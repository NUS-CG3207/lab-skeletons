def convert_hex_to_verilog(hex_file_path, output_file_path, instruction_memory_name="INSTR_MEM", data_memory_name="DATA_CONST_MEM", num_memory_slots=128):
    # Initialize lists to store Verilog lines for instruction and data memory
    instr_verilog_lines = []
    data_verilog_lines = []
    
    # Open the .hex file and read the hex instructions
    with open(hex_file_path, 'r') as file:
        hex_lines = [line.strip() for line in file if line.strip()]

    # Split the hex lines into instructions and data constants
    # Assuming a delimiter line (e.g., "DATA") exists between instructions and data in the file
    # Change this as per your actual file format or delimiter
    data_start_index = hex_lines.index("DATA")
    instr_hex_lines = hex_lines[:data_start_index]
    data_hex_lines = hex_lines[data_start_index + 1:]
    
    # Process instruction memory
    for i, instruction in enumerate(instr_hex_lines):
        verilog_line = f"\t{instruction_memory_name}[{i}] = 32'h{instruction};"
        instr_verilog_lines.append(verilog_line)

    if len(instr_hex_lines) < num_memory_slots:
        instr_verilog_lines.append(f"\tfor (i = {len(instr_hex_lines)}; i < {num_memory_slots}; i = i + 1) begin")
        instr_verilog_lines.append(f"\t\t{instruction_memory_name}[i] = 32'h0;")
        instr_verilog_lines.append(f"\tend")
    
    # Process data memory
    for i, data in enumerate(data_hex_lines):
        verilog_line = f"\t{data_memory_name}[{i}] = 32'h{data};"
        data_verilog_lines.append(verilog_line)

    if len(data_hex_lines) < num_memory_slots:
        data_verilog_lines.append(f"\tfor (i = {len(data_hex_lines)}; i < {num_memory_slots}; i = i + 1) begin")
        data_verilog_lines.append(f"\t\t{data_memory_name}[i] = 32'h0;")
        data_verilog_lines.append(f"\tend")
    
    # Combine the instruction and data memory Verilog lines
    combined_verilog_code = (
        "module memory_initialization;\n"
        "integer i;\n\n"
        "// Instruction Memory Initialization\n"
        + "\n".join(instr_verilog_lines) +
        "\n\n"
        "// Data Constant Memory Initialization\n"
        + "\n".join(data_verilog_lines) +
        "\nendmodule"
    )

    # Write the Verilog code to the output file
    with open(output_file_path, 'w') as output_file:
        output_file.write(combined_verilog_code)

    print(f"Verilog code successfully written to {output_file_path}")

# Example usage
if __name__ == "__main__":
    hex_file_path = 'instructions_data.hex'  # Specify your .hex file path here
    output_file_path = 'memory_initialization.v'  # Specify the output Verilog file path here
    
    convert_hex_to_verilog(hex_file_path, output_file_path)
