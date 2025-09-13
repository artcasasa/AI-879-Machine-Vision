%% CIRCLE DETECTION WITH HOUGH TRANSFORM — AI 879 MACHINE VISION
% Author: Art Casasa
%
% Course: AI 879 — Machine Vision
% Assignment: Circle Detection Using Hough Transform
% Date: August 2025
%
% Purpose:
%   Demonstrate how to detect circular objects in an image using the
%   Circular Hough Transform (via MATLAB's imfindcircles function). 
%   Output detected circles overlaid on the original image for visual 
%   verification and analysis.
%
% Learning Objectives:
%   1) Apply imfindcircles to detect circular features in real images.
%   2) Adjust parameters (radius, sensitivity, edge threshold) for robust detection.
%   3) Interpret results and optionally save outputs for reports.
%
% Methods Summary:
%   - Grayscale conversion for processing.
%   - Gaussian smoothing for noise reduction.
%   - imfindcircles: Hough Transform-based circle detection with tunable 
%     sensitivity, edge thresholds, and radius constraints.
%   - Visualization via viscircles overlay.
%
% Usage Instructions:
%   1) Save this script as circle_detection_hough.m
%   2) Run in MATLAB → Select input image when prompted.
%   3) Adjust parameters (radius, sensitivity, thresholds) as needed.
%   4) Save detected circle overlays if desired.
%
% Outputs:
%   - Figure with detected circles overlaid on the original image.
%   - Optional PNG output with all detected circles drawn.
%
% -------------------------------------------------------------------------

clear; close all; clc;

%% ------------------------- Parameters -------------------------
% Radius range in pixels (adjust as needed for your image)
Rmin = 40;       % Minimum circle radius
Rmax = 80;       % Maximum circle radius

% Detection sensitivity and edge threshold
sensitivity   = 0.94;   % Higher → more detections (0–1)
edgeThreshold = 0.10;   % Lower → detect weaker edges (0–1)

% Gaussian smoothing to reduce noise (sigma in pixels)
gaussianSigma = 2;

figureSize = [100 100 900 700];  % Figure size for display

%% ------------------------- File Selection -------------------------
[imgFile, imgPath] = uigetfile( ...
    {'*.jpg;*.jpeg;*.png;*.bmp;*.tif;*.tiff','Image Files'; ...
     '*.*','All Files'}, ...
    'Select input image for circle detection');

if isequal(imgFile,0)
    disp('No file selected. Exiting script.');
    return;
end

imgFull = fullfile(imgPath, imgFile);

%% ------------------------- Load & Preprocess -------------------------
I = imread(imgFull);

% Convert to grayscale
Igray = im2gray(I);

% Apply Gaussian blur for smoothing (optional)
Iblur = imgaussfilt(Igray, gaussianSigma);

%% ------------------------- Detect Circles -------------------------
[centers, radii, metrics] = imfindcircles(Iblur, [Rmin Rmax], ...
    'ObjectPolarity','bright', ...
    'Sensitivity',   sensitivity, ...
    'EdgeThreshold', edgeThreshold);

%% ------------------------- Visualization -------------------------
fig = figure('Name','Hough Circle Detection','Position',figureSize);

imshow(I); hold on;
viscircles(centers, radii, ...
    'EdgeColor','b', ...
    'LineWidth',1.5);
title(sprintf('Detected Circles: %d objects', numel(radii)), ...
    'FontSize',14, 'FontWeight','bold');
hold off;

drawnow;

%% ------------------------- Save Results -------------------------
saveChoice = questdlg('Do you want to save the detected circle overlay?', ...
                      'Save Output', 'Yes','No','Yes');

if strcmp(saveChoice,'Yes')
    [outFile, outPath] = uiputfile({'*.png','PNG Image (*.png)'}, ...
                                   'Save detected circles as', ...
                                   'detected_circles.png');
    if isequal(outFile,0)
        disp('Save canceled. No files written.');
        return;
    end

    % Save figure with detections
    outFull = fullfile(outPath, outFile);
    exportgraphics(fig, outFull, 'Resolution', 300);
    fprintf('Saved detected circles overlay: %s\n', outFull);
end

%% ------------------------- Optional Quick Metrics -------------------------
% Print simple metrics for analysis
fprintf('\nNumber of circles detected: %d\n', numel(radii));
if ~isempty(radii)
    fprintf('Average radius: %.2f pixels\n', mean(radii));
    fprintf('Radius range: min=%.2f, max=%.2f\n', min(radii), max(radii));
end
