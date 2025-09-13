% =========================================================================
% Feature Matching Comparison using Harris, SURF, and ORB
% Author: Art Casasa
% Date: August 2025
% Course: AI 879 Machine Vision, Penn State
%
% Description:
% ------------
% This script compares feature matching performance using Harris corners,
% SURF, and ORB detectors on three selected Penn State images.
%
% Features:
% ---------
% - Prompts user to select the three image files
% - Applies Harris, SURF, and ORB feature detectors to all pairwise image
%   combinations
% - Displays match results in a grid for visual comparison
% - Prompts user to save the final match visualization image
%
% Output:
% -------
% - A figure showing matched features for all combinations and methods
% - Option to save the visual output
%
% Notes:
% ------
% - Harris is not scale or rotation invariant, so its matches may be sparse.
% - SURF is more robust but requires the Computer Vision Toolbox.
% - ORB is fast and rotation invariant, but may yield fewer matches.
% =========================================================================

% --- Step 1: Select the three input images ---
[files, path] = uigetfile({'*.jpg;*.png','Image Files (*.jpg, *.png)'}, ...
    'Select 3 images (hold Ctrl or Shift)', 'MultiSelect', 'on');

if isequal(files, 0)
    disp('User canceled.');
    return;
end

if ischar(files)
    files = {files}; % Wrap single file in a cell
end

if numel(files) ~= 3
    error('Please select exactly 3 images.');
end

images = fullfile(path, files);
methodNames = {'Harris', 'SURF', 'ORB'};
pairs = [1 2; 1 3; 2 3];  % All unique combinations

% --- Step 2: Prepare display figure ---
figure('Name','Feature Matching Comparison','Units','normalized','Position',[0 0 1 1]);
plotNum = 1;

% --- Step 3: Loop through methods and image pairs ---
for m = 1:length(methodNames)
    method = methodNames{m};

    for p = 1:size(pairs,1)
        i = pairs(p,1);
        j = pairs(p,2);

        % Read and preprocess images
        I1 = imread(images{i});
        I2 = imread(images{j});
        if size(I1,3) > 1, I1 = rgb2gray(I1); end
        if size(I2,3) > 1, I2 = rgb2gray(I2); end

        % Feature detection
        switch method
            case 'Harris'
                points1 = detectHarrisFeatures(I1);
                points2 = detectHarrisFeatures(I2);
            case 'SURF'
                points1 = detectSURFFeatures(I1);
                points2 = detectSURFFeatures(I2);
            case 'ORB'
                points1 = detectORBFeatures(I1);
                points2 = detectORBFeatures(I2);
        end

        % Extract and match
        [features1, valid_points1] = extractFeatures(I1, points1);
        [features2, valid_points2] = extractFeatures(I2, points2);
        indexPairs = matchFeatures(features1, features2);

        matchedPoints1 = valid_points1(indexPairs(:,1));
        matchedPoints2 = valid_points2(indexPairs(:,2));

        % Plot in a grid: rows = method, cols = pair
        subplot(length(methodNames), size(pairs,1), plotNum);
        showMatchedFeatures(I1, I2, matchedPoints1, matchedPoints2, 'montage');
        title(sprintf('%s\n%s vs %s', method, files{i}, files{j}), ...
            'Interpreter', 'none', 'FontSize', 8);
        axis off;
        plotNum = plotNum + 1;
    end 
end

% --- Step 4: Save output image if user desires ---
choice = questdlg('Do you want to save the results as an image?', ...
    'Save Output', ...
    'Yes','No','Yes');

if strcmp(choice, 'Yes')
    [saveFile, savePath] = uiputfile({'*.png'}, 'Save Results As');
    if ischar(saveFile)
        frame = getframe(gcf);
        imwrite(frame.cdata, fullfile(savePath, saveFile));
        fprintf('Saved to: %s\n', fullfile(savePath, saveFile));
    else
        disp('Save canceled.');
    end
end
