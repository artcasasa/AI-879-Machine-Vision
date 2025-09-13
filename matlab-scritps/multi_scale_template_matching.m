%--------------------------------------------------------------------------
% multi_scale_template_matching.m
%
% PURPOSE:
%   Visualize and detect template matches across multiple pyramid levels by
%   manually resizing the target image and template using a fixed scale (e.g., 0.8).
%   This replaces the use of impyramid with imresize and shows how matching
%   performance varies across different image resolutions.
%
% FUNCTIONALITY:
%   1. User selects a main image and a template image via dialog boxes.
%   2. Images are converted to grayscale if needed.
%   3. A Gaussian-like pyramid is simulated by resizing the images with scale^level.
%   4. At each level, normalized cross-correlation (NCC) detects matches.
%   5. Bounding boxes are drawn at detected positions.
%   6. Frames are saved for each level, and a final montage is displayed.
%   7. User is prompted to optionally save the montage and per-level images.
%
% PYRAMID NOTES:
%   - This implementation simulates a true Gaussian pyramid using `imresize`.
%   - The template is also resized at each level to maintain proportionality.
%   - More pyramid iterations can be added by increasing `num_levels`.
%   - Use of smaller templates and higher-resolution images improves scale detection.
%
% INPUT:
%   - Main image (e.g., 'flower.png')
%   - Template image (e.g., 'flower_part.png')
%
% OUTPUT:
%   - On-screen montage of template matches at different scales
%   - Optional PNGs for the montage and per-level images
%
% EXAMPLE USAGE:
%   >> multi_scale_template_matching
%
% AUTHOR:
%   Art Casasa
%
% MODULE:
%   Section 6.1 – AI 879: Machine Vision, Penn State
%
% DATE:
%   August 2025
%
% MATLAB VERSION:
%   Developed and tested in MATLAB R2023a. Compatible with recent versions.
%--------------------------------------------------------------------------

function multi_scale_template_matching

    % --- Parameters ---
    scale = 0.8;
    num_levels = 6;
    min_peak_threshold = 0.5;

    % --- Step 1: Select images ---
    [imgFile, imgPath] = uigetfile({'*.png;*.jpg;*.jpeg','Select Main Image'});
    if isequal(imgFile, 0), disp('Cancelled.'); return; end
    I_orig = im2gray(imread(fullfile(imgPath, imgFile)));

    [tmplFile, tmplPath] = uigetfile({'*.png;*.jpg;*.jpeg','Select Template Image'});
    if isequal(tmplFile, 0), disp('Cancelled.'); return; end
    T_orig = im2gray(imread(fullfile(tmplPath, tmplFile)));

    [H, W] = size(I_orig);         % Original canvas size
    frames = cell(1, num_levels);  % Store frames for montage

    % --- Step 2–6: Loop through pyramid levels ---
    for lvl = 1:num_levels
        s = scale^(lvl - 1);

        % Resize image and template
        I = imresize(I_orig, s);
        T = imresize(T_orig, s);

        % Normalized cross-correlation and peak detection
        c = normxcorr2(T, I);
        mask = c > min_peak_threshold * max(c(:)) & islocalmax(c,1) & islocalmax(c,2);
        [ypeak, xpeak] = find(mask);
        yoff = ypeak - size(T,1);
        xoff = xpeak - size(T,2);

        % Create full-size canvas centered
        canvas = zeros(H, W, 'like', I_orig);
        y0 = floor((H - size(I,1))/2) + 1;
        x0 = floor((W - size(I,2))/2) + 1;
        canvas(y0:y0+size(I,1)-1, x0:x0+size(I,2)-1) = I;

        % Annotate matches on canvas
        hfig = figure('Visible','off','Position',[0 0 W H]);
        imshow(canvas); hold on;

        for k = 1:numel(xoff)
            bx = x0 + xoff(k) - 1;
            by = y0 + yoff(k) - 1;
            rectangle('Position', [bx, by, size(T,2), size(T,1)], ...
                      'EdgeColor', [1-lvl/num_levels, 0, lvl/num_levels], ...
                      'LineWidth', 1.5);
        end

        % Label scale level
        text(10, 20, sprintf('Scale %.0f%%', s*100), ...
             'Color','y','FontSize',14,'FontWeight','bold', ...
             'BackgroundColor','black','Margin',2);
        drawnow;

        % Capture result as image frame
        F = getframe(gca);
        frames{lvl} = frame2im(F);
        close(hfig);
    end

    % --- Step 7: Display montage of all levels ---
    figure('Name','Multi-Scale Pyramid Matching','NumberTitle','off');
    montage(frames, 'Size', [1 num_levels], 'BorderSize', [5 5]);
    sgtitle(sprintf('Multi-Scale Template Matching (%d Levels)', num_levels));

    % --- Step 8: Ask to save final montage ---
    saveResp = questdlg('Save final montage image?', ...
        'Save Montage', 'Yes', 'No', 'No');

    if strcmp(saveResp, 'Yes')
        [savefile, savepath] = uiputfile({'*.png','PNG Image'}, ...
            'Save Montage As', 'montage_result.png');
        if ischar(savefile)
            montageImage = getframe(gcf);
            imwrite(montageImage.cdata, fullfile(savepath, savefile));
            disp(['Montage saved to: ' fullfile(savepath, savefile)]);
        else
            disp('Montage save cancelled.');
        end
    end

    % --- Step 9: Ask to save all pyramid frames ---
    saveEach = questdlg('Also save each level image?', ...
        'Save All Frames', 'Yes', 'No', 'No');

    if strcmp(saveEach, 'Yes')
        outDir = fullfile(savepath, [erase(imgFile, ' ') '_levels']);
        mkdir(outDir);
        for i = 1:num_levels
            fname = sprintf('level_%02d.png', i);
            imwrite(frames{i}, fullfile(outDir, fname));
        end
        disp(['All levels saved to: ' outDir]);
    end
end
