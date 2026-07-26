# Texture-Aware Adaptive Soft Coring for Image Denoising

This repository contains the official MATLAB implementation of the **Texture-Aware Adaptive Soft Coring** algorithm.

## Overview
The proposed method introduces a dynamic framework that combines global context-based mode selection (categorizing images into Smooth, Mixed, or Textured tiers) with local pixel-level mapping via exponential decay functions. Utilizing a high-degree nonlinear soft coring function and Gaussian edge density maps, this approach preserves structural edges while suppressing noise across different frequency layers.

## Repository Structure
- `Adaptive.m` - Main adaptive soft coring algorithm implementation.
- `Bike_Static.m` & `cameraman_Static.m` - Benchmark static comparison scripts.
- `*.png / *.jpg` - Test images used for experiments (`Bike`, `Lenna`, `Statue`, `Building`, `Smooth Surface`).

## Prerequisites
- MATLAB R2021b or later
- Image Processing Toolbox

## Usage
1. Open MATLAB and set the repository folder as your working directory.
2. Run `Adaptive.m` to apply the adaptive denoising on the test images.
3. Run `Bike_Static.m` or `cameraman_Static.m` for baseline comparison.

## Citation
If you use this code in your research, please cite our paper:
> *Author Name(s)*, "Texture-Aware Adaptive Soft Coring for Image Denoising", 2026.
