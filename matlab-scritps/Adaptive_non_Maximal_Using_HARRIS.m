% =========================================================================
% Adaptive Non-Maximal Suppression (ANMS) with Harris Corners
% Author: Art Casasa
% Date: September 2025
% Course: AI 879 Machine Vision, Penn State
%
% Description:
% ------------
% This script detects interest points in an image using the Harris corner
% detector and refines them using ANMS to retain spatially distributed and
% high-response corners.
%
% Features:
% ---------
% - Prompts user to select a grayscale or color image
% - Asks for desired number of output points (e.g., 1000)
% - Implements ANMS to retain only the most relevant interest points
% - Displays and optionally saves the output with corner markers
%
% Output:
% -------
% - A figure showing the selected ANMS interest points
% - Optional saved output image
%
% Notes:
% ------
% ANMS enforces spatial diversity by keeping points with the largest
% suppression radii, defined as the minimum distance to a stronger neighbor.
% =========================================================================

% --- Step 1: Select image file ---
[file, path] = uigetfile({'*.jpg;*.png;*.bmp','Image Files (*.jpg, *.png, *.bmp)'}, ...
                         'Select an image for ANMS');
if isequal(file, 0)
    disp('User canceled.');
    return;
end

img_path = fullfile(path, file);
I = imread(img_path);

% Convert to grayscale if RGB
if size(I,3) == 3
    I = rgb2gray(I);
end
I = im2double(I);

% --- Step 2: Ask user for number of points ---
prompt = {'Enter number of desired corners (e.g., 1000):'};
dlgtitle = 'ANMS Settings';
dims = [1 50];
definput = {'1000'};
answer = inputdlg(prompt, dlgtitle, dims, definput);

if isempty(answer)
    disp('User canceled input.');
    return;
end

N = str2double(answer{1});
if isnan(N) || N <= 0
    error('Invalid number of corners.');
end

% --- Step 3: Detect Harris corners ---
corners = detectHarrisFeatures(I);
corner_points = corners.Location;
corner_metrics = corners.Metric;

% --- Step 4: Sort corners by strength ---
[~, sorted_indices] = sort(corner_metrics, 'descend');
sorted_points = corner_points(sorted_indices, :);
sorted_metrics = corner_metrics(sorted_indices);

% --- Step 5: Initialize radii ---
num_corners = length(sorted_metrics);
radii = inf(num_corners, 1);

% --- Step 6: Compute ANMS suppression radius ---
for i = 2:num_corners
    for j = 1:i-1
        if sorted_metrics(j) > sorted_metrics(i)
            dist = norm(sorted_points(i,:) - sorted_points(j,:));
            if dist < radii(i)
                radii(i) = dist;
            end
        end
    end
end

% --- Step 7: Keep top N points with largest radii ---
[~, rad_sorted_indices] = sort(radii, 'descend');
anms_points = sorted_points(rad_sorted_indices(1:min(N, num_corners)), :);

% --- Step 8: Show results ---
figure('Name','ANMS Corners','NumberTitle','off');
imshow(I); hold on;
plot(anms_points(:,1), anms_points(:,2), 'ro');
title(sprintf('ANMS Result with Top %d Points', N), 'FontSize', 12);

% --- Step 9: Prompt to save image ---
choice = questdlg('Do you want to save the output image with corners?', ...
    'Save ANMS Output', ...
    'Yes', 'No', 'Yes');

if strcmp(choice, 'Yes')
    [saveFile, savePath] = uiputfile({'*.png'}, 'Save Result As');
    if ischar(saveFile)
        frame = getframe(gca);
        imwrite(frame.cdata, fullfile(savePath, saveFile));
        fprintf('Saved to: %s\n', fullfile(savePath, saveFile));
    else
        disp('Save canceled.');
    end
end
