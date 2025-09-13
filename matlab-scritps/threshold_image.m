%--------------------------------------------------------------------------
% threshold_image.m
%
% PURPOSE:
%   This script thresholds a color image into black and white using a
%   loop-based method (for instructional clarity). It prompts the user
%   to select an input image, converts it to grayscale, applies a fixed
%   threshold, displays the result, and allows optional saving.
%
% FUNCTIONALITY:
%   1) Select an input image via file dialog.
%   2) Convert it to grayscale.
%   3) Loop over all pixels and apply a binary threshold.
%   4) Display the black-and-white result.
%   5) Prompt the user to save the output image.
%
% INPUT:
%   - Image selected by user (JPG, PNG, BMP, etc.)
%
% OUTPUT:
%   - On-screen binary image (black and white)
%   - Optionally saved black-and-white image
%
% EXAMPLE USAGE:
%   >> threshold_image
%
% AUTHOR:
%   Art Casasa
%
% MODULE:
%   Module 2 - AI 879: Machine Vision, Penn State
%
% DATE:
%   August 2025
%
% MATLAB VERSION:
%   Developed in MATLAB R2023a. Compatible with recent versions.
%--------------------------------------------------------------------------

function threshold_image
    % Step 1: Select image
    [filename, pathname] = uigetfile( ...
        {'*.png;*.jpg;*.jpeg;*.bmp;*.tif','Image Files'; '*.*','All Files'}, ...
        'Select an Image to Threshold');
    if isequal(filename, 0)
        disp('No image selected. Exiting.');
        return;
    end
    fpath = fullfile(pathname, filename);
    
    try
        orig = imread(fpath);
    catch ME
        warning(['Could not read image: ' ME.message]);
        return;
    end

    % Step 2: Convert to grayscale
    gray = rgb2gray(orig);

    % Step 3: Preallocate output image (same size, uint8)
    [M, N] = size(gray);
    bw = zeros(M, N, 'uint8');

    % Step 4: Loop over pixels and apply threshold
    threshold = 90;  % Adjust as needed
    for i = 1:M
        for j = 1:N
            if gray(i,j) < threshold
                bw(i,j) = 0;    % black
            else
                bw(i,j) = 255;  % white
            end
        end
    end

    % Step 5: Display result
    figure('Name','Threshold Result','NumberTitle','off');
    imshow(bw);
    title(sprintf('Thresholded @ %d', threshold));
    drawnow; drawnow nocallbacks;

    % Step 6: Ask to save result
    resp = 'No';
    try
        r = questdlg('Save the black-and-white result?', ...
                     'Save Result', 'Yes', 'No', 'No');
        if ~isempty(r)
            resp = r;
        end
    catch
        disp('Save dialog failed or skipped.');
    end

    if strcmp(resp, 'Yes')
        [savefile, savepath] = uiputfile( ...
            {'*.png','PNG Image'; '*.jpg','JPEG Image'; '*.tif','TIFF Image'}, ...
            'Save Thresholded Image As', 'threshold_output.png');

        if ~isequal(savefile, 0)
            try
                imwrite(bw, fullfile(savepath, savefile));
                disp(['Saved: ' fullfile(savepath, savefile)]);
            catch ME
                warning(['Could not save image: ' ME.message]);
            end
        else
            disp('Save cancelled.');
        end
    else
        disp('Not saving. Done.');
    end
end
