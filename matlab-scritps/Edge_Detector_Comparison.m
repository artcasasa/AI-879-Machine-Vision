%% EDGE DETECTOR COMPARISON — AI 879 MACHINE VISION
% Author: Art Casasa
%
% Course: AI 879 — Machine Vision
% Assignment: Edge Detector Comparison
% Date: August 2025
%
% Purpose:
%   This script compares four classic edge detection methods — Canny, Sobel, 
%   Prewitt, and Roberts — on a user-selected image. The goal is to understand 
%   differences in edge localization, sensitivity to noise, and output quality.
%
% Learning Objectives:
%   1) Implement four edge detection algorithms using MATLAB.
%   2) Compare qualitative results visually and interpret key differences.
%   3) Provide optional quantitative edge counts for basic analysis.
%   4) Save visual results for inclusion in a written report.
%
% Methods Summary:
%   - Canny: Gaussian smoothing, gradient computation, non-maximum suppression, 
%     hysteresis thresholding. Known for accurate and thin edges with low noise.
%   - Sobel: Gradient magnitude using Sobel kernels. Thicker edges, robust for 
%     simple tasks, moderate noise sensitivity.
%   - Prewitt: Similar to Sobel but with different convolution weights. Produces 
%     slightly different gradient responses.
%   - Roberts: 2x2 diagonal operators. Sensitive to noise; useful for detecting 
%     fine details but less robust overall.
%
% Usage Instructions:
%   1) Save this file as edge_detector_comparison.m
%   2) Run in MATLAB → Select input image when prompted.
%   3) Review the 2x2 montage and save results if desired.
%
% Outputs:
%   - One montage PNG showing all detectors.
%   - Four binary edge maps as individual PNGs if chosen.
%
% -------------------------------------------------------------------------

clear; close all; clc;

%% ------------------------- Parameters -------------------------
targetMaxDim = 512;    % Resize longer dimension to this (preserve aspect ratio)
cannyThresh   = [];    % [] uses MATLAB defaults; or specify e.g., [0.05 0.15]
cannySigma    = 1.0;   % Smoothing for Canny detector
sobelThresh   = [];    
prewittThresh = [];    
robertsThresh = [];    

figureSize = [100 100 1000 1000];  % Montage window size

%% ------------------------- File Selection -------------------------
[imgFile, imgPath] = uigetfile( ...
    {'*.jpg;*.jpeg;*.png;*.bmp;*.tif;*.tiff','Image Files'; ...
     '*.*','All Files'}, ...
    'Select input image');

if isequal(imgFile,0)
    disp('No file selected. Exiting script.');
    return;
end

imgFull = fullfile(imgPath, imgFile);

%% ------------------------- Load & Preprocess -------------------------
img = imread(imgFull);

% Convert to grayscale if necessary
if size(img,3) == 3
    imgGray = rgb2gray(img);
else
    imgGray = img;
end

% Resize if needed
[h, w] = size(imgGray);
scaleFactor = targetMaxDim / max(h, w);
if scaleFactor < 1
    imgResized = imresize(imgGray, scaleFactor);
else
    imgResized = imgGray;
end

%% ------------------------- Edge Detection -------------------------
edgeCanny   = edge(imgResized, 'Canny',   cannyThresh,   cannySigma);
edgeSobel   = edge(imgResized, 'Sobel',   sobelThresh);
edgePrewitt = edge(imgResized, 'Prewitt', prewittThresh);
edgeRoberts = edge(imgResized, 'Roberts', robertsThresh);

%% ------------------------- Visualization -------------------------
fig = figure('Name','Edge Detector Comparison','Position',figureSize);
tiledlayout(2,2, "Padding","compact", "TileSpacing","compact");

nexttile; imshow(edgeCanny);   title('Canny',   'FontSize', 16, 'FontWeight', 'bold');
nexttile; imshow(edgeSobel);   title('Sobel',   'FontSize', 16, 'FontWeight', 'bold');
nexttile; imshow(edgePrewitt); title('Prewitt', 'FontSize', 16, 'FontWeight', 'bold');
nexttile; imshow(edgeRoberts); title('Roberts', 'FontSize', 16, 'FontWeight', 'bold');

sgtitle(sprintf('Edge Detector Comparison — %s', imgFile), ...
        'FontSize', 14, 'FontWeight', 'bold');
drawnow;

%% ------------------------- Save Results -------------------------
saveChoice = questdlg('Do you want to save the montage and edge maps?', ...
                      'Save Outputs', 'Yes','No','Yes');

if strcmp(saveChoice,'Yes')
    [outFile, outPath] = uiputfile({'*.png','PNG Image (*.png)'}, ...
                                   'Save montage as', ...
                                   'edge_comparison_montage.png');
    if isequal(outFile,0)
        disp('Save canceled. No files written.');
        return;
    end

    % Save montage
    montagePath = fullfile(outPath, outFile);
    exportgraphics(fig, montagePath, 'Resolution', 300);
    fprintf('Saved montage: %s\n', montagePath);

    % Save individual edge maps
    [baseName, ~] = strtok(outFile, '.');
    imwrite(edgeCanny,   fullfile(outPath, [baseName '_canny.png']));
    imwrite(edgeSobel,   fullfile(outPath, [baseName '_sobel.png']));
    imwrite(edgePrewitt, fullfile(outPath, [baseName '_prewitt.png']));
    imwrite(edgeRoberts, fullfile(outPath, [baseName '_roberts.png']));
    fprintf('Saved individual edge maps in: %s\n', outPath);
end

%% ------------------------- Optional Quick Metrics -------------------------
edgeCounts = [nnz(edgeCanny), nnz(edgeSobel), nnz(edgePrewitt), nnz(edgeRoberts)];
fprintf('\nEdge pixel counts [Canny, Sobel, Prewitt, Roberts] = [%d, %d, %d, %d]\n', edgeCounts);
fprintf('Use counts to compare edge density quantitatively.\n');
