// Disease Names ROM for MobileNetV3 Medical Diagnosis System
// Maps class indices (0-14) to disease names

module disease_names_rom #(
    parameter NUM_CLASSES = 15,
    parameter NAME_LENGTH = 32  // Max characters per disease name
) (
    input wire [$clog2(NUM_CLASSES)-1:0] class_index,
    output reg [NAME_LENGTH*8-1:0] disease_name,  // 8-bit ASCII per character
    output reg name_valid
);

    // ROM containing disease names (ASCII encoded)
    reg [NAME_LENGTH*8-1:0] disease_names_rom [0:NUM_CLASSES-1];
    
    // Initialize ROM with disease names
    initial begin
        // Actual 15 chest X-ray diseases
        disease_names_rom[0]  = "No Finding                   ";  // 32 chars
        disease_names_rom[1]  = "Infiltration                  ";
        disease_names_rom[2]  = "Atelectasis                  ";
        disease_names_rom[3]  = "Effusion                     ";
        disease_names_rom[4]  = "Nodule                       ";
        disease_names_rom[5]  = "Pneumothorax                 ";
        disease_names_rom[6]  = "Mass                         ";
        disease_names_rom[7]  = "Consolidation                ";
        disease_names_rom[8]  = "Pleural Thickening           ";
        disease_names_rom[9]  = "Cardiomegaly                 ";
        disease_names_rom[10] = "Emphysema                    ";
        disease_names_rom[11] = "Fibrosis                     ";
        disease_names_rom[12] = "Edema                        ";
        disease_names_rom[13] = "Pneumonia                    ";
        disease_names_rom[14] = "Hernia                       ";
    end
    
    // Output logic
    always @(*) begin
        if (class_index < NUM_CLASSES) begin
            disease_name = disease_names_rom[class_index];
            name_valid = 1'b1;
        end else begin
            disease_name = 0;
            name_valid = 1'b0;
        end
    end

endmodule 