%--------------------------------------------------------------------------
% colorBalanceDemo.m
%
% PURPOSE:
%   Perform simple color balancing on an image by applying user-defined
%   scaling factors to the red, green, and blue channels. Lets you load an
%   image, set multipliers, preview side-by-side, and optionally save.
%
% FUNCTIONALITY:
%   1) Select an input image via file dialog.
%   2) Enter R/G/B scaling multipliers (with defaults).
%   3) Converts grayscale or indexed images to RGB; strips alpha if present.
%   4) Applies scaling, clamps to [0,1], shows before/after side-by-side.
%   5) Optionally saves the processed image using a safe dialog.
%
% INPUT:
%   - Image chosen via dialog (PNG, JPEG, TIFF, BMP, etc.)
%   - R, G, B multipliers via dialog
%
% OUTPUT:
%   - On-screen figure with Original vs Balanced image
%   - Optional saved balanced image
%
% EXAMPLE:
%   >> colorBalanceDemo
%
% AUTHOR:
%   Art Casasa
%
% DATE:
%   August 2025
%
% COURSE:
%   AI 879 - Machine Vision, Penn State
%
% MATLAB VERSION:
%   Developed in MATLAB R2023a. Compatible with recent versions.
%--------------------------------------------------------------------------

function ColorBalancedDemo
    % Step 1: Select image
    [filename, pathname] = uigetfile( ...
        {'*.png;*.jpg;*.jpeg;*.tif;*.tiff;*.bmp','Image Files'; '*.*','All Files'}, ...
        'Select an Image');
    if isequal(filename, 0)
        disp('No image selected. Exiting.');
        return;
    end
    fpath = fullfile(pathname, filename);

    % Step 2: Read image and handle formats
    try
        [A, map] = imread(fpath);
    catch ME
        warning(['Could not read image: ' ME.message]);
        return;
    end

    if ~isempty(map)
        I = ind2rgb(A, map);  % indexed image
    else
        I = im2double(A);     % standard RGB
    end

    if size(I,3) == 4
        I = I(:,:,1:3);
        disp('Alpha channel detected and removed.');
    end

    if size(I,3) == 1
        I = cat(3, I, I, I);
        disp('Grayscale image detected. Converted to RGB.');
    end

    % Step 3: Ask for channel multipliers
    defaults = {'1.20','0.80','1.00'};
    prompt = {'Enter red multiplier (default 1.20):', ...
              'Enter green multiplier (default 0.80):', ...
              'Enter blue multiplier (default 1.00):'};
    answer = inputdlg(prompt, 'Channel Scaling', [1 48], defaults);

    if isempty(answer)
        disp('Input cancelled. Exiting.');
        return;
    end

    rFactor = parsePositive(answer{1}, str2double(defaults{1}));
    gFactor = parsePositive(answer{2}, str2double(defaults{2}));
    bFactor = parsePositive(answer{3}, str2double(defaults{3}));

    % Step 4: Apply scaling and clamp
    I2 = I;
    I2(:,:,1) = I(:,:,1) * rFactor;
    I2(:,:,2) = I(:,:,2) * gFactor;
    I2(:,:,3) = I(:,:,3) * bFactor;
    I2 = min(max(I2, 0), 1);

    % Step 5: Display side-by-side
    figure('Name','Color Balance Demo','NumberTitle','off');
    subplot(1,2,1);
    imshow(I, 'InitialMagnification','fit');
    title('Original');
    drawnow; drawnow nocallbacks;

    subplot(1,2,2);
    imshow(I2, 'InitialMagnification','fit');
    title(sprintf('Balanced  R=%.3g  G=%.3g  B=%.3g', rFactor, gFactor, bFactor));
    try
        sgtitle(['Color Balance: ' filename]);
    catch
    end
    drawnow; drawnow nocallbacks;

    % Step 6: Ask user if they want to save the result
    resp = 'No';  % default response
    try
        r = questdlg('Save the balanced image?', 'Save', 'Yes','No','No');
        if ~isempty(r)
            resp = r;
        end
    catch
        disp('Save dialog failed or skipped.');
    end

    % Step 7: Save if requested
    if strcmp(resp, 'Yes')
        [savefile, savepath] = uiputfile( ...
            {'*.png','PNG Image'; '*.jpg','JPEG Image'; '*.tif','TIFF Image'}, ...
            'Save Balanced Image As', 'balanced_image.png');

        if ~isequal(savefile,0)
            try
                imwrite(I2, fullfile(savepath, savefile));
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

% -------------------
% Helper function
% -------------------
function val = parsePositive(str, fallback)
    val = str2double(str);
    if isnan(val) || ~isfinite(val) || val <= 0
        val = fallback;
        disp(['Invalid input. Using default: ' num2str(fallback)]);
    end
end
