clc; clear; close all;
rng(42);

try
    original = imread('Bike.png');
catch
    original = im2uint8(phantom(256));
end

I = im2double(original);
if size(I, 3) == 3
    I = rgb2gray(I);
end

I_noisy = imnoise(I, 'gaussian', 0, 0.003);

% ═══════════════════════════════════════
% Extract frequency layers
% ═══════════════════════════════════════
Blur1 = imgaussfilt(I_noisy, 1.0);
Blur2 = imgaussfilt(I_noisy, 2.5);
HPF1  = I_noisy - Blur1;   
HPF2  = Blur1   - Blur2;   

% ═══════════════════════════════════════
% Check the actual amplitude range of the signals
% ═══════════════════════════════════════
fprintf('=== دامنه سیگنال‌ها ===\n');
fprintf('Max |HPF1|: %.4f\n', max(abs(HPF1(:))));
fprintf('Max |HPF2|: %.4f\n', max(abs(HPF2(:))));
fprintf('Std  HPF1 : %.4f\n', std(HPF1(:)));
fprintf('Std  HPF2 : %.4f\n', std(HPF2(:)));

% ═══════════════════════════════════════
% Optimal parameters
% ═══════════════════════════════════════

Tau1   = 0.08;   Slope1 = 0.65;
Tau2   = 0.02;   Slope2 = 1.15;

Core1 = MySoftCoring(HPF1, Tau1, Slope1);
Core2 = MySoftCoring(HPF2, Tau2, Slope2);

% ═══════════════════════════════════════
% Reconstruction + brightness correction
% ═══════════════════════════════════════
I_final = Blur2 + Core1 + Core2;

% Brightness correction via histogram matching
mean_orig  = mean(I_noisy(:));
mean_final = mean(I_final(:));
I_final    = I_final + (mean_orig - mean_final);
I_final    = max(0, min(I_final, 1));

% ═══════════════════════════════════════
% Evaluation metrics
% ═══════════════════════════════════════
psnr_noisy = psnr(I_noisy, I);
ssim_noisy = ssim(I_noisy, I);
psnr_final = psnr(I_final, I);
ssim_final = ssim(I_final, I);

fprintf('\n=== نتایج کمی ===\n');
fprintf('PSNR ورودی : %.2f dB\n', psnr_noisy);
fprintf('PSNR خروجی : %.2f dB\n', psnr_final);
fprintf('بهبود PSNR : %+.2f dB\n', psnr_final - psnr_noisy);
fprintf('SSIM ورودی : %.4f\n',     ssim_noisy);
fprintf('SSIM خروجی : %.4f\n',     ssim_final);
fprintf('بهبود SSIM : %+.4f\n',    ssim_final - ssim_noisy);

% ═══════════════════════════════════════
% Smart ROI selection
% ═══════════════════════════════════════
[H, W]   = size(I);
roi_r    = max(1, round(H*0.25)) : min(H, round(H*0.65));
roi_c    = max(1, round(W*0.35)) : min(W, round(W*0.80));
roi_zoom = I_noisy(roi_r, roi_c);

% ═══════════════════════════════════════
% Display results
% ═══════════════════════════════════════
figure('Name',        'Nonlinear Denoising & Sharpening', ...
       'NumberTitle', 'off', ...
       'Position',    [50, 50, 1300, 750]);

% --- subplot 1: noisy input ---
subplot(2, 3, 1);
imshow(I_noisy);
title(sprintf('1. Input Noisy\nPSNR: %.2f dB  |  SSIM: %.3f', ...
              psnr_noisy, ssim_noisy), ...
      'FontSize', 10);

% --- subplot 2: final output ---
subplot(2, 3, 2);
imshow(I_final);
title(sprintf('2. Final Output\nPSNR: %.2f dB  |  SSIM: %.3f', ...
              psnr_final, ssim_final), ...
      'FontSize', 10);

% --- subplot 3: Soft Coring curve ---
subplot(2, 3, 3);
x_range = linspace(-0.2, 0.2, 1000);
y1 = MySoftCoring(x_range, Tau1, Slope1);
y2 = MySoftCoring(x_range, Tau2, Slope2);
hold on;
plot(x_range, x_range, 'k--', 'LineWidth', 1.2, ...
     'DisplayName', 'Linear (y=x)');
plot(x_range, y1, 'r', 'LineWidth', 2.5, ...
     'DisplayName', sprintf('HPF1-Denoise (τ=%.2f, m=%.2f)', Tau1, Slope1));
plot(x_range, y2, 'b', 'LineWidth', 2.5, ...
     'DisplayName', sprintf('HPF2-Sharp   (τ=%.2f, m=%.2f)', Tau2, Slope2));

% Threshold lines
xline( Tau1, 'r:', 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline(-Tau1, 'r:', 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline( Tau2, 'b:', 'LineWidth', 1.5, 'HandleVisibility', 'off');
xline(-Tau2, 'b:', 'LineWidth', 1.5, 'HandleVisibility', 'off');

% Zero line
yline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');
xline(0, 'k-', 'LineWidth', 0.8, 'HandleVisibility', 'off');

grid on;
legend('Location', 'NorthWest', 'FontSize', 8);
title('3. Soft Coring Functions', 'FontSize', 10);
xlabel('Input Amplitude');
ylabel('Output Amplitude');
xlim([-0.2  0.2]);
ylim([-0.25 0.25]);
hold off;

% --- subplot 4: zoom input ---
subplot(2, 3, 4);
imshow(I_noisy(roi_r, roi_c));
title(sprintf('4. Zoom Input\nSSIM: %.3f', ssim_noisy), ...
      'FontSize', 10);

% --- subplot 5: zoom output ---
subplot(2, 3, 5);
imshow(I_final(roi_r, roi_c));
title(sprintf('5. Zoom Output\nSSIM: %.3f', ssim_final), ...
      'FontSize', 10);

% --- subplot 6: Signal Profile ---
subplot(2, 3, 6);
row = round(H * 0.40);   % middle row of the image
hold on;
plot(I(row, :),       'k--', 'LineWidth', 1.5, 'DisplayName', 'Original');
plot(I_noisy(row, :), 'r',   'LineWidth', 1.0, 'DisplayName', 'Noisy');
plot(I_final(row, :), 'b',   'LineWidth', 2.0, 'DisplayName', 'Output');
legend('Location', 'NorthEast', 'FontSize', 8);
grid on;
title(sprintf('6. Signal Profile (Row %d)', row), 'FontSize', 10);
xlabel('Pixel Index');
ylabel('Intensity');
ylim([0 1]);
hold off;

% ═══════════════════════════════════════
% Soft Coring function
% ═══════════════════════════════════════
function out = MySoftCoring(x, Tau, Slope)
    n           = 6;
    suppression = 1 - exp(-(abs(x) ./ Tau) .^ n);
    out         = Slope .* x .* suppression;
end