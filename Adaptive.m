clc; clear; close all;

img_name = 'Lenna.png';  

try
    original = imread(img_name);
catch
    original = im2uint8(phantom(256));
end

I = im2double(original);
if size(I, 3) == 3
    I = rgb2gray(I);
end

I_noisy = imnoise(I, 'gaussian', 0, 0.003);

% ═══════════════════════════════════════
% Frequency layers
% ═══════════════════════════════════════
Blur1 = imgaussfilt(I_noisy, 1.2);
Blur2 = imgaussfilt(I_noisy, 4.0);
HPF1  = I_noisy - Blur1;
HPF2  = Blur1   - Blur2;

% ═══════════════════════════════════════
% Local analysis
% ═══════════════════════════════════════
WIN    = 15;
lambda = 15;

noise_global = median(abs(HPF1(:))) / 0.6745;

abs_hpf1  = abs(HPF1);
local_med = medfilt2(abs_hpf1, [WIN WIN], 'symmetric');
sigma_loc = max(local_med / 0.6745, 0.001);
strong    = double(abs_hpf1 > 2 * sigma_loc);
h_avg     = fspecial('average', [WIN WIN]);
D_local   = imfilter(strong, h_avg, 'replicate');
D_local   = min(max(D_local, 0), 1);
decay     = exp(-lambda .* D_local);

% ═══════════════════════════════════════
% Three-level decision based on Mean D
% ═══════════════════════════════════════
mean_D = mean(D_local(:));

if mean_D > 0.055
    mode_name   = 'TEXTURED (Protective)';
    Tau1_base   = max(0.04, min(1.5 * noise_global, 0.08));
    Slope1_base = 0.75;
    Slope2_base = 1.05;
    tau_range   = 0.15;
elseif mean_D > 0.04
    mode_name   = 'MIXED (Balanced)';
    Tau1_base   = max(0.06, min(2.5 * noise_global, 0.12));
    Slope1_base = 0.55;
    Slope2_base = 1.10;
    tau_range   = 0.30;
else
    mode_name   = 'SMOOTH (Aggressive)';
    Tau1_base   = max(0.08, min(3.0 * noise_global, 0.15));
    Slope1_base = 0.45;
    Slope2_base = 1.05;
    tau_range   = 0.35;
end

fprintf('Mean D = %.4f → Mode: %s\n', mean_D, mode_name);

% ═══════════════════════════════════════
% Local parameters
% ═══════════════════════════════════════
Tau1_local = Tau1_base * ((1 - tau_range/2) + tau_range .* decay);
Tau1_local = min(max(Tau1_local, 0.005), 0.15);

Slope1_local = Slope1_base * (1.10 - 0.20 .* decay);
Slope1_local = min(max(Slope1_local, 0.35), 0.85);

Tau2_base    = 0.03;
Tau2_local   = Tau2_base * (0.90 + 0.20 .* decay);
Tau2_local   = min(max(Tau2_local, 0.005), 0.06);
Slope2_local = Slope2_base * ones(size(D_local));

% ═══════════════════════════════════════
% Apply Soft Coring
% ═══════════════════════════════════════
Core1 = AdaptiveSoftCoring(HPF1, Tau1_local, Slope1_local);
Core2 = AdaptiveSoftCoring(HPF2, Tau2_local, Slope2_local);

I_final = Blur2 + Core1 + Core2;
I_final = I_final + (mean(I_noisy(:)) - mean(I_final(:)));
I_final = max(0, min(I_final, 1));

% ═══════════════════════════════════════
% Metrics
% ═══════════════════════════════════════
psnr_noisy = psnr(I_noisy, I);
ssim_noisy = ssim(I_noisy, I);
psnr_final = psnr(I_final, I);
ssim_final = ssim(I_final, I);

fprintf('PSNR: %.2f → %.2f dB (%+.2f)\n', ...
        psnr_noisy, psnr_final, psnr_final - psnr_noisy);
fprintf('SSIM: %.3f → %.3f (%+.3f)\n', ...
        ssim_noisy, ssim_final, ssim_final - ssim_noisy);

% ═══════════════════════════════════════
% Display (same as before)
% ═══════════════════════════════════════
[H, Wimg] = size(I);
roi_r = max(1,round(H*0.20))    : min(H,round(H*0.70));
roi_c = max(1,round(Wimg*0.20)) : min(Wimg,round(Wimg*0.75));

figure('Name', ['Texture-Aware: ' img_name], ...
       'NumberTitle', 'off', 'Position', [50, 50, 1400, 800]);

subplot(2,3,1);
imshow(I_noisy);
title(sprintf('1. Input Noisy\nPSNR: %.2f | SSIM: %.3f', ...
              psnr_noisy, ssim_noisy), 'FontSize', 10);

subplot(2,3,2);
imshow(I_final);
title(sprintf('2. Output [%s]\nPSNR: %.2f | SSIM: %.3f', ...
              mode_name, psnr_final, ssim_final), 'FontSize', 10);

subplot(2,3,3);
imagesc(D_local); colormap(gca,'parula'); colorbar; axis off image;
title(sprintf('3. Edge Density Map\nMean D = %.4f', mean_D), 'FontSize', 10);

subplot(2,3,4);
imagesc(Tau1_local); colormap(gca,'hot'); colorbar; axis off image;
title(sprintf('4. Adaptive Tau1 Map\n[%.3f - %.3f]', ...
              min(Tau1_local(:)), max(Tau1_local(:))), 'FontSize', 10);

subplot(2,3,5);
imshow(I_noisy(roi_r, roi_c));
title(sprintf('5. Zoom Input\nSSIM: %.3f', ssim_noisy), 'FontSize', 10);

subplot(2,3,6);
imshow(I_final(roi_r, roi_c));
title(sprintf('6. Zoom Output\nSSIM: %.3f', ssim_final), 'FontSize', 10);

function out = AdaptiveSoftCoring(x, Tau, Slope)
    n           = 6;
    suppression = 1 - exp(-(abs(x) ./ Tau).^n);
    out         = Slope .* x .* suppression;
end