% =========================================================================
% Script: interactive_segmentation_tool.m
% Author: [Your Name]
% Date: August 2025
%
% Description:
% This script performs marker-controlled watershed segmentation on an input
% image selected by the user. It allows interactive image selection and 
% prompts the user to save the final labeled output.
%
% Steps:
% 1. Prompt user to select input image (any format supported by imread)
% 2. Convert to grayscale (if needed) and preprocess
% 3. Compute image gradient and foreground markers
% 4. Apply watershed segmentation
% 5. Display results and prompt for save location
%
% Dependencies: MATLAB Image Processing Toolbox
% =========================================================================

% Clear and close
clear; close all; clc;

% --- Step 1: Load Image ---
[filename, pathname] = uigetfile({'*.jpg;*.png;*.bmp', 'Image Files (*.jpg, *.png, *.bmp)'}, 'Select an image file');
if isequal(filename,0)
    disp('User canceled image selection.');
    return;
end
img_path = fullfile(pathname, filename);
I = imread(img_path);

% Convert to grayscale if RGB
if size(I,3) == 3
    Igray = rgb2gray(I);
else
    Igray = I;
end

% --- Step 2: Preprocessing ---
Igray = im2double(Igray);
Ieq = adapthisteq(Igray);                   % Contrast enhancement
Ifilt = imgaussfilt(Ieq, 1);                % Noise reduction
hy = fspecial('sobel'); hx = hy';           % Sobel filters
Iy = imfilter(Ifilt, hy, 'replicate'); 
Ix = imfilter(Ifilt, hx, 'replicate');
gradmag = sqrt(Ix.^2 + Iy.^2);              % Gradient magnitude

% --- Step 3: Foreground Markers via Morphological Opening ---
se = strel('disk', 3);
Io = imopen(Ifilt, se);                     % Opening
Ie = imerode(Ifilt, se);                    % Erosion
Iobr = imreconstruct(Ie, Ifilt);            % Morphological reconstruction
Iobrd = imdilate(Iobr, se);                 
Iobrcbr = imreconstruct(imcomplement(Iobrd), imcomplement(Iobr));
Iobrcbr = imcomplement(Iobrcbr);

% Threshold to get sure foreground
bw = imbinarize(Iobrcbr);
bw = bwareaopen(bw, 20);                    % Remove small blobs
D = bwdist(~bw);                            % Distance transform
D = -D;
D(~bw) = -Inf;

% --- Step 4: Apply Watershed ---
L = watershed(D);
labels = label2rgb(L, 'jet', 'w', 'shuffle');

% --- Step 5: Show and Save ---
figure;
imshow(labels);
title('Watershed Segmentation Result');

% Ask user to save result
[savefile, savepath] = uiputfile({'*.png'; '*.jpg'; '*.tif'}, 'Save Segmented Image As');
if isequal(savefile, 0)
    disp('User canceled save operation.');
else
    imwrite(labels, fullfile(savepath, savefile));
    disp(['Segmented image saved to ', fullfile(savepath, savefile)]);
end
