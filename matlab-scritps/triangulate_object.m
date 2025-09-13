% =========================================================================
% AI 879 – Machine Vision
% Penn State University – August 2025
% Author: Art Casasa
%
% Project: Object Triangulation Using Multi-View Geometry
% Purpose: To identify a user-defined object from multiple images (P1–P5),
%          detect its position in each, and use triangulation to estimate
%          its 3D coordinates.
%
% Instructions:
% • Make sure the image files P1.jpg to P5.jpg are in the selected folder.
% • You will be prompted to select the object name.
% • The program will detect the object manually (user selects in each view).
% • It will estimate the 3D position using linear triangulation.
% • You can optionally export a CSV and save annotated images.
% =========================================================================

clear; close all; clc;

%% --- USER SETTINGS ---

% Prompt for object name
prompt = 'Enter the name of the object you want to triangulate: ';
objectName = input(prompt, 's');

% Select folder containing images
imgFolder = uigetdir(pwd, 'Select folder with P1–P5 images');
if imgFolder == 0
    error('Folder selection canceled.');
end

% Define image file names
numViews = 5;
imageFiles = fullfile(imgFolder, arrayfun(@(i) sprintf('P%d.jpg', i), 1:numViews, 'UniformOutput', false));

% Pre-allocate
imagePoints = zeros(numViews, 2);
cameraMatrices = cell(numViews, 1);

% Optional: Ask to save results
saveOutput = questdlg('Do you want to save results (CSV and marked images)?', ...
                      'Save Output?', 'Yes', 'No', 'Yes');
saveFlag = strcmp(saveOutput, 'Yes');

%% --- DEFINE CAMERA MATRICES FOR VIEWS P1 TO P5 ---
% These should be your calibrated projection matrices
% [3x4 matrices]: P = K [R | t]
% For demo purposes, we assume example matrices
for i = 1:numViews
    % For now, mock matrices (replace with real calibration data)
    theta = (i - 1) * pi / 10;
    R = [cos(theta) 0 sin(theta); 0 1 0; -sin(theta) 0 cos(theta)];
    t = [i * 0.5; 0; 0];
    K = [1000 0 256; 0 1000 256; 0 0 1];
    cameraMatrices{i} = K * [R, t];
end

%% --- MANUAL SELECTION OF OBJECT IN EACH VIEW ---
fprintf('\nSelect the object "%s" in each image (P1 to P5)...\n', objectName);

for i = 1:numViews
    img = imread(imageFiles{i});
    figure('Name', sprintf('View %d: %s', i, objectName));
    imshow(img);
    title(sprintf('Click on the center of the "%s" in P%d', objectName, i));
    [x, y] = ginput(1);
    imagePoints(i, :) = [x, y];
    
    if saveFlag
        hold on;
        plot(x, y, 'rx', 'MarkerSize', 12, 'LineWidth', 2);
        text(x + 10, y, sprintf('%s (%d)', objectName, i), 'Color', 'red', 'FontSize', 12);
        saveas(gcf, fullfile(imgFolder, sprintf('Marked_P%d.jpg', i)));
    end
    
    close(gcf);
end

%% --- TRIANGULATION FUNCTION ---
% Solve DLT for Ax = 0 for each view, stack equations

A = [];
for i = 1:numViews
    P = cameraMatrices{i};
    x = imagePoints(i, 1);
    y = imagePoints(i, 2);

    A = [A;
         x * P(3,:) - P(1,:);
         y * P(3,:) - P(2,:)];
end

[~, ~, V] = svd(A);
X = V(:, end);
X = X ./ X(4);  % Homogeneous to Cartesian

fprintf('\nEstimated 3D Coordinates of "%s":\n', objectName);
fprintf('X = %.2f, Y = %.2f, Z = %.2f\n', X(1), X(2), X(3));

%% --- OPTIONAL: SAVE CSV OUTPUT ---
if saveFlag
    outputFile = fullfile(imgFolder, sprintf('Triangulation_Result_%s.csv', objectName));
    data = [X(1:3)'];
    headers = {'X', 'Y', 'Z'};
    writematrix([headers; num2cell(data)], outputFile);
    fprintf('Results saved to: %s\n', outputFile);
end