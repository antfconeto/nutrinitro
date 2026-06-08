import cv2
import numpy as np

# Load original high-res image
img = cv2.imread('/home/antonio/Documents/owner-projects/nutrinitro/tcc/data/image/26-05/P1.JPG')
ch, cw, _ = img.shape
print(f"Original shape: {ch}x{cw}")

# Preprocess steps mimicking Python:
# 1. Blur
img_blur = cv2.GaussianBlur(img, (5, 5), 0)
# 2. Gamma
inv_gamma = 1.0 / 0.8
table = np.array([((i / 255.0) ** inv_gamma) * 255 for i in range(256)]).astype(np.uint8)
img_gamma = cv2.LUT(img_blur, table)
# 3. Crop
y_start, y_end = int(0.20 * ch), int((1.0 - 0.20) * ch)
x_start, x_end = int(0.20 * cw), int((1.0 - 0.20) * cw)
img_cropped = img_gamma[y_start:y_end, x_start:x_end]
ch_crop, cw_crop, _ = img_cropped.shape
print(f"Cropped shape: {ch_crop}x{cw_crop}")

# Block average (10x10)
BLOCK_SIZE = 10
new_w = cw_crop // BLOCK_SIZE
new_h = ch_crop // BLOCK_SIZE
h_trimmed = new_h * BLOCK_SIZE
w_trimmed = new_w * BLOCK_SIZE
img_trimmed = img_cropped[:h_trimmed, :w_trimmed]

reshaped = img_trimmed.reshape(new_h, BLOCK_SIZE, new_w, BLOCK_SIZE, 3)
img_down = np.mean(reshaped, axis=(1, 3))

print(f"Downsampled grid: {new_h}x{new_w} (Total: {new_h * new_w} blocks)")

veg_count = 0
for r in range(new_h):
    for c in range(new_w):
        b_val = img_down[r, c, 0]
        g_val = img_down[r, c, 1]
        r_val = img_down[r, c, 2]
        
        total = r_val + g_val + b_val
        if total == 0:
            total = 1.0
        r_chrom = r_val / total
        g_chrom = g_val / total
        b_chrom = b_val / total
        
        denom_vari = g_chrom + r_chrom - b_chrom
        if denom_vari == 0:
            denom_vari = 1.0
        vari = (g_chrom - r_chrom) / denom_vari
        
        if vari > 0.10:
            veg_count += 1
            
        if r == 0 and c < 5:
            print(f"Bloco [0][{c}] - BGR bruto: ({b_val:.1f}, {g_val:.1f}, {r_val:.1f}) | chrom: ({r_chrom:.4f}, {g_chrom:.4f}, {b_chrom:.4f}) | VARI: {vari:.4f}")

print(f"Blocos de vegetação detectados: {veg_count} de {new_h * new_w} ({veg_count / (new_h * new_w) * 100:.2f}%)")
