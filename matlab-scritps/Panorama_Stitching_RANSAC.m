%% PANORAMA STITCHING WITH RANSAC
% Author: Art Casasa
%
% Course: AI 879 — Machine Vision
% Assignment: Apply RANSAC for Image Stitching
% Date: August 2025
%
% Purpose:
%   Stitch at least three overlapping photos into one panorama and compare
%   a robust RANSAC-based pipeline against a direct non-robust fit.
%
% What this script does:
%   1) Prompts you to select 3+ images shot in sequence.
%   2) Lets you choose the transform estimation method:
%        - "ransac": robust fit with outlier trimming
%        - "direct": non-robust fit with health checks
%   3) Lets you choose a feature detector (SURF, BRISK, ORB).
%   4) Computes and displays the panorama, prints match and inlier stats.
%   5) Prompts to save the panorama as PNG and metadata as MAT.
%
% Outputs:
%   - Panorama PNG
%   - Optional .MAT with transforms and stats for your report

clear; close all; clc;

%% ------------------------- Select images -------------------------
[files, path] = uigetfile( ...
    {'*.jpg;*.jpeg;*.png;*.tif;*.tiff;*.bmp','Image Files'}, ...
    'Select 3+ images in order (left->right)', ...
    'MultiSelect', 'on');

if isequal(files,0)
    disp('No images selected. Exiting.');
    return;
end

if ischar(files)
    files = {files};
end
if numel(files) < 3
    error('Please select at least 3 images.');
end

images = cellfun(@(f) imread(fullfile(path,f)), files, 'UniformOutput', false);

%% ------------------------- Choose method -------------------------
method = questdlg('Choose transform estimation method:', ...
                  'Method', 'ransac', 'direct', 'ransac');
if isempty(method)
    method = 'ransac';
end

%% ------------------------- Choose feature detector -------------------------
featChoice = questdlg('Feature detector:', 'Features', ...
                      'SURF','BRISK','ORB','SURF');
switch featChoice
    case 'SURF'
        detectF = @(I) detectSURFFeatures(I, 'MetricThreshold', 500);
    case 'BRISK'
        detectF = @(I) detectBRISKFeatures(I, 'MinContrast', 0.02);
    case 'ORB'
        if exist('detectORBFeatures','file') == 2
            detectF = @(I) detectORBFeatures(I, 'ScaleFactor', 1.2, 'NumLevels', 8);
        else
            warndlg('detectORBFeatures not found; falling back to BRISK.');
            detectF = @(I) detectBRISKFeatures(I, 'MinContrast', 0.02);
            featChoice = 'BRISK';
        end
    otherwise
        detectF = @(I) detectSURFFeatures(I, 'MetricThreshold', 500);
        featChoice = 'SURF';
end

%% ------------------------- Stitch panorama -------------------------
[panorama, tforms, imageSize, stats] = stitch_panorama(images, method, detectF);

%% ------------------------- Show results -------------------------
figure('Name','Panorama','Position',[100 100 1200 500]);
imshow(panorama);
title(sprintf('Panorama (%s, %s features)', method, featChoice), ...
      'FontSize', 14, 'FontWeight','bold');

% Console summary for report
fprintf('\n=== PANORAMA STATS ===\n');
fprintf('Images: %d\n', numel(images));
if isfield(stats,'matches')
    fprintf('Matches per adjacent pair: ');
    disp(stats.matches(:).');
end
if isfield(stats,'inliers') && any(~isnan(stats.inliers))
    fprintf('RANSAC inliers per adjacent pair: ');
    disp(stats.inliers(:).');
    ratios = stats.inliers(:) ./ max(stats.matches(:),1);
    % Fix: nanmean -> mean(...,'omitnan')
    fprintf('Average inlier ratio: %.2f%%\n', 100*mean(ratios,'omitnan'));
end
fprintf('Image size used for features (HxW per tile):\n');
disp(imageSize);

%% ------------------------- Save outputs -------------------------
saveChoice = questdlg('Save panorama and metadata?', 'Save', 'Yes','No','Yes');
if strcmp(saveChoice,'Yes')
    [pngName, outPath] = uiputfile('panorama.png','Save panorama as');
    if ~isequal(pngName,0)
        exportgraphics(gcf, fullfile(outPath,pngName), 'Resolution', 300);
        fprintf('Saved panorama: %s\n', fullfile(outPath,pngName));
        matName = [pngName(1:end-4) '_meta.mat'];
        save(fullfile(outPath, matName), 'tforms','imageSize','stats','method','featChoice','files');
        fprintf('Saved metadata: %s\n', fullfile(outPath,matName));
    else
        disp('Save canceled.');
    end
end

%% ========================= Local functions =========================
function [panorama, tforms, imageSize, stats] = stitch_panorama(images, method, detectF)
% Build a panorama from a cell array of images using the selected method.
% method: 'direct' or 'ransac'

    % Initialize outputs to safe defaults
    panorama  = [];
    tforms    = projective2d(eye(3));
    imageSize = zeros(numel(images),2);
    stats.matches = zeros(max(numel(images)-1,0),1);
    stats.inliers = nan(max(numel(images)-1,0),1);

    numImages = numel(images);
    if numImages == 0
        warning('No images provided to stitch_panorama.');
        return;
    end

    tforms(numImages) = projective2d(eye(3));  % expand array

    % First image features
    I1 = images{1};
    G1 = toGray(I1);
    imageSize(1,:) = size(G1);
    p1 = detectF(G1);
    [f1, v1] = extractFeatures(G1, p1);

    % Process remaining images
    for n = 2:numImages
        In = images{n};
        Gn = toGray(In);
        imageSize(n,:) = size(Gn);

        pn = detectF(Gn);
        [fn, vn] = extractFeatures(Gn, pn);

        pairs = matchFeatures(fn, f1, 'Unique', true, 'MatchThreshold', 60, 'MaxRatio', 0.7);
        stats.matches(n-1) = size(pairs,1);

        matchedN  = vn(pairs(:,1));
        matchedP1 = v1(pairs(:,2));

        switch lower(method)
            case 'ransac'
                [tforms(n), stats.inliers(n-1)] = robustFit(matchedN, matchedP1, 'projective');
                if isempty(tforms(n))
                    [tforms(n), stats.inliers(n-1)] = robustFit(matchedN, matchedP1, 'affine');
                end
                if isempty(tforms(n))
                    [tforms(n), stats.inliers(n-1)] = robustFit(matchedN, matchedP1, 'similarity');
                end
            case 'direct'
                tforms(n) = safeDirectFit(matchedN, matchedP1);
            otherwise
                error('Unknown method "%s"', method);
        end

        if isempty(tforms(n))
            warning('Transform estimation failed for image %d; using identity.', n);
            tforms(n) = projective2d(eye(3));
        end

        % Chain transforms relative to first
        tforms(n).T = tforms(n-1).T * tforms(n).T;

        % Slide window
        I1 = In; %#ok<NASGU>
        G1 = Gn; %#ok<NASGU>
        p1 = pn; %#ok<NASGU>
        f1 = fn; 
        v1 = vn; 
    end

    % Recenter on middle image to reduce distortion
    [xlim, ~] = limitsForAll(tforms, imageSize);
    avgXLim = mean(xlim,2);
    [~, idx] = sort(avgXLim);
    centerIdx = floor((numImages+1)/2);
    centerImageIdx = idx(centerIdx);
    Tinv = invert(tforms(centerImageIdx));
    for n = 1:numImages
        tforms(n).T = Tinv.T * tforms(n).T;
    end

    % Compute panorama canvas with guardrails
    [xlim, ylim] = limitsForAll(tforms, imageSize);
    maxImageSize = max(imageSize, [], 1);
    baseW = maxImageSize(2);
    baseH = maxImageSize(1);
    limFactor = 3;

    xMin = max(min([1; xlim(:)]), -limFactor*baseW);
    xMax = min(max([baseW; xlim(:)]),  limFactor*baseW);
    yMin = max(min([1; ylim(:)]), -limFactor*baseH);
    yMax = min(max([baseH; ylim(:)]),  limFactor*baseH);

    width  = max(1, round(xMax - xMin));
    height = max(1, round(yMax - yMin));

    panoramaView = imref2d([height width], [xMin xMax], [yMin yMax]);
    panorama = zeros([height width 3], 'like', images{1});

    % Warp and alpha blend
    blender = vision.AlphaBlender('Operation','Binary mask','MaskSource','Input port');
    for n = 1:numImages
        warped = imwarp(images{n}, tforms(n), 'OutputView', panoramaView);
        mask   = imwarp(true(size(images{n},1), size(images{n},2)), tforms(n), 'OutputView', panoramaView);
        panorama = step(blender, panorama, warped, mask);
    end
end

function G = toGray(I)
    if size(I,3) > 1
        G = rgb2gray(I);
    else
        G = I;
    end
end

function [tform, inliers] = robustFit(mp, mp1, model)
    % Robust transform with RANSAC and inlier count
    tform = [];
    inliers = 0;

    need = reqPoints(model);
    if mp.Count < need || mp1.Count < need
        return;
    end

    try
        [tform, inlierIdx] = estimateGeometricTransform2D( ...
            mp, mp1, model, ...
            'Confidence', 99.9, ...
            'MaxNumTrials', 5000, ...
            'MaxDistance', 3);
        inliers = sum(inlierIdx);
    catch
        tform = [];
        inliers = 0;
    end
end

function tform = safeDirectFit(mp, mp1)
    % Non-robust fit with conditioning checks and fallbacks
    tform = projective2d(eye(3));  % default to identity

    try
        if mp.Count >= 3 && mp1.Count >= 3
            T = fitgeotrans(mp.Location, mp1.Location, 'affine');
            A = T.T(1:2,1:2);
            d = det(A);
            c = cond(A);
            if ~isfinite(d) || abs(d) < 1e-6 || ~isfinite(c) || c > 1e6
                if mp.Count >= 2 && mp1.Count >= 2
                    T = fitgeotrans(mp.Location, mp1.Location, 'similarity');
                else
                    T = affine2d(eye(3));
                end
            end
            tform = projective2d(T.T);
        elseif mp.Count >= 2 && mp1.Count >= 2
            T = fitgeotrans(mp.Location, mp1.Location, 'similarity');
            tform = projective2d(T.T);
        end
    catch
        % keep identity default
    end
end

function n = reqPoints(model)
    switch lower(model)
        case 'projective'
            n = 4;
        case 'affine'
            n = 3;
        case 'similarity'
            n = 2;
        otherwise
            n = 4;
    end
end

function [xlim, ylim] = limitsForAll(tforms, imageSize)
    numImages = numel(tforms);
    xlim = zeros(numImages,2);
    ylim = zeros(numImages,2);
    for k = 1:numImages
        [xlim(k,:), ylim(k,:)] = outputLimits(tforms(k), [1 imageSize(k,2)], [1 imageSize(k,1)]);
    end
end
