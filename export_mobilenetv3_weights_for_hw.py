import torch
import numpy as np
import os
import sys
sys.path.append('.')  # Ensure current directory is in path
from models import MobileNetV3_Small, SeModule

CHECKPOINT = 'models/mobilenet_fixed_point_16_8.pth'
OUTPUT_DIR = 'memory_files'
BIT_WIDTH = 16
FRAC_BITS = 8

def quantize(x, bit_width=16, frac_bits=8):
    scale = 2 ** frac_bits
    min_val = -2**(bit_width-1)
    max_val = 2**(bit_width-1) - 1
    x_q = np.round(x * scale)
    x_q = np.clip(x_q, min_val, max_val).astype(np.int16)
    return x_q

def save_mem(filename, arr):
    with open(filename, 'w') as f:
        for v in arr.flatten():
            v16 = np.uint16(v)
            f.write(f'{v16:04x}\n')

if not os.path.exists(OUTPUT_DIR):
    os.makedirs(OUTPUT_DIR)

# Instantiate the model and load the state dict
model = MobileNetV3_Small(in_channels=1, num_classes=15)
state_dict = torch.load(CHECKPOINT, map_location='cpu')
model.load_state_dict(state_dict)
model.eval()

# Export first conv layer
conv1_w = model.conv1.weight.detach().cpu().numpy()
save_mem(f'{OUTPUT_DIR}/conv1_conv.mem', quantize(conv1_w))

# Export first batchnorm
bn1_gamma = model.bn1.weight.detach().cpu().numpy()
bn1_beta = model.bn1.bias.detach().cpu().numpy()
save_mem(f'{OUTPUT_DIR}/bn1_gamma.mem', quantize(bn1_gamma))
save_mem(f'{OUTPUT_DIR}/bn1_beta.mem', quantize(bn1_beta))

# Export all bneck blocks
for idx, block in enumerate(model.bneck):
    # Conv1
    save_mem(f'{OUTPUT_DIR}/bneck_{idx}_conv1_conv.mem', quantize(block.conv1.weight.detach().cpu().numpy()))
    if hasattr(block, 'bn1') and isinstance(block.bn1, torch.nn.BatchNorm2d):
        save_mem(f'{OUTPUT_DIR}/bneck_{idx}_bn1_gamma.mem', quantize(block.bn1.weight.detach().cpu().numpy()))
        save_mem(f'{OUTPUT_DIR}/bneck_{idx}_bn1_beta.mem', quantize(block.bn1.bias.detach().cpu().numpy()))
    # Conv2
    save_mem(f'{OUTPUT_DIR}/bneck_{idx}_conv2_conv.mem', quantize(block.conv2.weight.detach().cpu().numpy()))
    if hasattr(block, 'bn2') and isinstance(block.bn2, torch.nn.BatchNorm2d):
        save_mem(f'{OUTPUT_DIR}/bneck_{idx}_bn2_gamma.mem', quantize(block.bn2.weight.detach().cpu().numpy()))
        save_mem(f'{OUTPUT_DIR}/bneck_{idx}_bn2_beta.mem', quantize(block.bn2.bias.detach().cpu().numpy()))
    # Conv3
    save_mem(f'{OUTPUT_DIR}/bneck_{idx}_conv3_conv.mem', quantize(block.conv3.weight.detach().cpu().numpy()))
    if hasattr(block, 'bn3') and isinstance(block.bn3, torch.nn.BatchNorm2d):
        save_mem(f'{OUTPUT_DIR}/bneck_{idx}_bn3_gamma.mem', quantize(block.bn3.weight.detach().cpu().numpy()))
        save_mem(f'{OUTPUT_DIR}/bneck_{idx}_bn3_beta.mem', quantize(block.bn3.bias.detach().cpu().numpy()))
    # SE module if present
    if hasattr(block, 'se') and isinstance(block.se, SeModule):
        if hasattr(block.se, 'se') and isinstance(block.se.se, torch.nn.Sequential):
            for se_idx, se_layer in enumerate(block.se.se):
                if isinstance(se_layer, torch.nn.Conv2d):
                    save_mem(f'{OUTPUT_DIR}/bneck_{idx}_se_se_{se_idx}_conv.mem', quantize(se_layer.weight.detach().cpu().numpy()))
                if isinstance(se_layer, torch.nn.BatchNorm2d):
                    save_mem(f'{OUTPUT_DIR}/bneck_{idx}_se_se_{se_idx}_gamma.mem', quantize(se_layer.weight.detach().cpu().numpy()))
                    save_mem(f'{OUTPUT_DIR}/bneck_{idx}_se_se_{se_idx}_beta.mem', quantize(se_layer.bias.detach().cpu().numpy()))

# Export final conv2, bn2, hswish2
save_mem(f'{OUTPUT_DIR}/conv2_conv.mem', quantize(model.conv2.weight.detach().cpu().numpy()))
save_mem(f'{OUTPUT_DIR}/bn2_bn.mem', quantize(model.bn2.weight.detach().cpu().numpy()))

# Export final linear layers
save_mem(f'{OUTPUT_DIR}/linear3_weights.mem', quantize(model.linear3.weight.detach().cpu().numpy()))
save_mem(f'{OUTPUT_DIR}/linear3_biases.mem', quantize(model.linear3.bias.detach().cpu().numpy()))
save_mem(f'{OUTPUT_DIR}/bn3_gamma.mem', quantize(model.bn3.weight.detach().cpu().numpy()))
save_mem(f'{OUTPUT_DIR}/bn3_beta.mem', quantize(model.bn3.bias.detach().cpu().numpy()))
save_mem(f'{OUTPUT_DIR}/linear4_weights.mem', quantize(model.linear4.weight.detach().cpu().numpy()))
save_mem(f'{OUTPUT_DIR}/linear4_biases.mem', quantize(model.linear4.bias.detach().cpu().numpy()))

print("All weights and parameters exported to memory_files/ as .mem files.") 