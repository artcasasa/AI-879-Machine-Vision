% -------------------------------------------------------------------------
% Module 2 – AI 879 Machine Vision – Penn State
% Laplacian Pyramid Image Blending with Soft Mask Refinement
% Based on Section 3.5.5 of Szeliski’s textbook
% -------------------------------------------------------------------------
% Features:
% - Select any two images to blend
% - Auto-generate soft binary mask using k-means + superpixels + Chan-Vese
% - Multi-scale Gaussian and Laplacian pyramids with controllable levels
% - Output final blend, intermediate steps, and export to PDF
% -------------------------------------------------------------------------

clc; close all; clear;

%% CONFIGURATION
num_levels    = 5;        % pyramid depth
reduce_factor = 0.8;      % downsample factor
chan_iter     = 300;      % Chan-Vese iterations
sp_count      = 300;      % number of superpixels

%% SELECT INPUT FILES
[img1_file, path1] = uigetfile({'*.jpg;*.png;*.jpeg','Images'}, 'Select FIRST image (foreground)');
if isequal(img1_file,0), error('No image selected.'); end
[img2_file, path2] = uigetfile({'*.jpg;*.png;*.jpeg','Images'}, 'Select SECOND image (background)');
if isequal(img2_file,0), error('No image selected.'); end

img1_path = fullfile(path1, img1_file);
img2_path = fullfile(path2, img2_file);

%% 1) READ & RESIZE BG TO MATCH FG
I1  = im2double(imread(img1_path));
I2o = im2double(imread(img2_path));
[H1,W1,~] = size(I1);
[H2,W2,~] = size(I2o);

% Resize background to be at least 20% larger than foreground
scale_up = 1.2 * max(H1/H2, W1/W2);
I2s = imresize(I2o, scale_up);

% Crop center to match foreground size
y0 = floor((size(I2s,1)-H1)/2)+1;
x0 = floor((size(I2s,2)-W1)/2)+1;
I2 = I2s(y0:y0+H1-1, x0:x0+W1-1, :);

%% 2) PRECOMPUTE K-MEANS SEED FOR SUPERPIXELS
lab       = rgb2lab(I1);
ab        = lab(:,:,2:3);
[idx,~]   = kmeans(reshape(ab,[],2), 3, 'Replicates',3);
labels    = reshape(idx, H1, W1);
seedLabel = labels(round(H1/2), round(W1/2));
seedMask  = (labels==seedLabel);

%% 3) BUILD & REFINE BINARY MASK
[SP,N] = superpixels(I1, sp_count);
idxSP  = label2idx(SP);
mask0  = false(H1,W1);
for s = 1:N
    if any(seedMask(idxSP{s}))
        mask0(idxSP{s}) = true;
    end
end

% Chan-Vese refinement
mask1 = activecontour(I1, mask0, chan_iter, 'Chan-Vese');

% Hole filling, convex hull, morph cleanup
mask1 = bwconvhull(mask1, 'objects');
mask1 = imopen(mask1,  strel('disk',10));
mask1 = imclose(mask1, strel('disk',25));
mask1 = imfill(mask1,'holes');
mask1 = bwareaopen(mask1,5000);
mask1 = imerode(mask1, strel('disk',3));  % remove stray bits

% Soften mask to float range [0,1]
mask = imgaussfilt(double(mask1), 7);
mask = mask ./ max(mask(:));

%% Show final binary mask
figure('Name','Final Binary Mask');
imshow(mask1);
title('Final Hole-Free Binary Mask','FontSize',14);

%% WAITBAR
h = waitbar(0,'Building pyramids...','Name','Progress');

%% 4) BUILD GAUSSIAN PYRAMIDS
GP1 = cell(num_levels,1); GP2 = GP1; GM = GP1;
GP1{1}=I1; GP2{1}=I2; GM{1}=mask;
for L = 2:num_levels
    GP1{L} = imresize(GP1{L-1}, reduce_factor);
    GP2{L} = imresize(GP2{L-1}, reduce_factor);
    GM{L}  = imresize(GM{L-1},  reduce_factor);
end
waitbar(0.5,h,'Blending levels...');

%% 5) BUILD LAPLACIAN PYRAMIDS
LP1 = cell(num_levels,1); LP2 = LP1;
for L = 1:num_levels-1
    up1    = imresize(GP1{L+1}, size(GP1{L}(:,:,1)));
    up2    = imresize(GP2{L+1}, size(GP2{L}(:,:,1)));
    LP1{L} = GP1{L} - up1;
    LP2{L} = GP2{L} - up2;
end
LP1{num_levels} = GP1{num_levels};
LP2{num_levels} = GP2{num_levels};

%% 6) BLEND & RECONSTRUCT
LPb = cell(num_levels,1);
for L = 1:num_levels
    M       = repmat(GM{L},[1 1 3]);
    LPb{L}  = LP1{L}.*M + LP2{L}.*(1 - M);
end
out = LPb{num_levels};
for L = num_levels-1:-1:1
    out = imresize(out, size(LPb{L}(:,:,1))) + LPb{L};
end
waitbar(1,h,'Done!');
close(h);

%% 7) DISPLAY FINAL BLEND
figure('Name','Final Laplacian Pyramid Blend');
imshow(out);
title('Laplacian Pyramid Blend – No Leaks','FontSize',14);

%% 8) COMPOSITE CANVAS + EXPORT
fig = figure('Units','inches','Position',[0 0 8.5 11], ...
             'PaperUnits','inches','PaperSize',[8.5 11], ...
             'PaperPosition',[0 0 8.5 11]);
t = tiledlayout(2,2,'TileSpacing','Compact','Padding','Compact');
nexttile; imshow(I1);   title('Image 1','FontSize',12);
nexttile; imshow(I2);   title('Image 2 - oversized','FontSize',12);
nexttile; imshow(mask1);title('Hole-Free Mask','FontSize',12);
nexttile; imshow(out);  title('Blend Result','FontSize',12);
drawnow;

% Prompt for output filename
[filename, pathname] = uiputfile('*.pdf','Save blended output as...');
if filename
    print(fig, fullfile(pathname, filename), '-dpdf', '-r300');
    disp(['Saved as: ' fullfile(pathname, filename)]);
end
