# Array Dimension Adapter: Block Diagram

```mermaid
graph TD
    subgraph "Array Dimension Adapter"
        Input["3D Input Tensor<br>[CHANNELS][HEIGHT][WIDTH]"] --> GAP["Global Average Pooling"]
        GAP --> Output["1D Output Array<br>[CHANNELS]"]
        
        subgraph "Control Logic"
            CLK["Clock"] --> Control
            RST["Reset"] --> Control
            VALID_IN["valid_in"] --> Control
        end
        
        Control --> GAP
        Control --> VALID_OUT["valid_out"]
        
        subgraph "Global Average Pooling (Per Channel)"
            SUM["Sum all H×W values"]
            DIV["Divide by H×W"]
            SUM --> DIV
        end
    end
    
    style Input fill:#d0e0ff,stroke:#0066cc
    style Output fill:#d0ffe0,stroke:#00cc66
    style GAP fill:#ffe0d0,stroke:#cc6600
    style Control fill:#e0d0ff,stroke:#6600cc
```

## Detailed Data Flow

1. **Input**: 3D tensor with dimensions [CHANNELS][HEIGHT][WIDTH]
   - Each element is a DATA_WIDTH-bit value (typically 16-bit fixed point)
   - Example: [160][7][7] for final MobileNetV3 feature maps

2. **Processing**: Global Average Pooling
   - For each of the CHANNELS:
     - Sum all HEIGHT×WIDTH values (e.g., sum all 49 values in a 7×7 feature map)
     - Divide by HEIGHT×WIDTH (e.g., divide by 49)
   - Result is a single representative value per channel

3. **Output**: 1D array with dimension [CHANNELS]
   - Each element is the average value of the corresponding channel
   - Example: [160] for final MobileNetV3 feature vector

4. **Control Signals**:
   - Clock: Synchronizes all operations
   - Reset: Clears valid_out signal
   - valid_in: Indicates when input data is valid
   - valid_out: Indicates when output data is valid