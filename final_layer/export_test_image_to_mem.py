import numpy as np
from PIL import Image
import argparse

# Configuration: adjust as needed for your hardware
BIT_WIDTH = 16
FRAC_BITS = 8  # Number of fractional bits for fixed-point
MAX_VAL = 2 ** (BIT_WIDTH - 1) - 1
MIN_VAL = -2 ** (BIT_WIDTH - 1)


def quantize_to_fixed_point(arr, bit_width=BIT_WIDTH, frac_bits=FRAC_BITS):
    """
    Quantize a numpy array to fixed-point representation.
    """
    scaled = np.round(arr * (2 ** frac_bits))
    clipped = np.clip(scaled, MIN_VAL, MAX_VAL)
    return clipped.astype(np.int16)


def save_mem_file(arr, filename):
    """
    Save a 1D or 2D numpy array as a .mem file (hex, one value per line).
    """
    arr_flat = arr.flatten()
    with open(filename, 'w') as f:
        for val in arr_flat:
            # Convert to unsigned for hex representation
            val_u = np.uint16(val)
            f.write(f"{val_u:04x}\n")


def load_image_as_array(image_path, mode='L'):
    """
    Load an image and return as a numpy array (grayscale by default).
    """
    img = Image.open(image_path).convert(mode)
    arr = np.array(img).astype(np.float32) / 255.0  # Normalize to [0,1]
    return arr


def main():
    parser = argparse.ArgumentParser(description="Quantize and export test image to .mem file for hardware.")
    parser.add_argument('--image', type=str, default='test_image.png', help='Path to input image file (e.g., .png, .jpg). Default: test_image.png')
    parser.add_argument('--output', type=str, default='test_image.mem', help='Output .mem file path. Default: test_image.mem')
    parser.add_argument('--mode', type=str, default='L', help='Image mode: L=grayscale, RGB, etc. Default: L')
    args = parser.parse_args()

    arr = load_image_as_array(args.image, mode=args.mode)
    quantized = quantize_to_fixed_point(arr)
    save_mem_file(quantized, args.output)
    print(f"Saved quantized image to {args.output}")


if __name__ == "__main__":
    main() 