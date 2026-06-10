% Load image files (both fixation and stims), apply any adjustments (e.g., resizing), and create their "Screen" textures
%
function [s] = fMRI_3DCategories_PrepareImageTextures(p, s)

%% Display

msg = 'Loading images and preparing textures...';
disp(msg)
DrawFormattedText(s.win, msg, 'center', 'center');
Screen('Flip', s.win);


%% Fixation

if p.FIXATION.ENABLED

    % load image with alpha channel
    filepath = p.PATH.FOLDER_IMAGES + p.PATH.FILENAME_FIXATION;
    [img, ~, alpha] = imread(filepath);

    % resize to target size
    img = imresize(img,   p.FIXATION.SIZE);
    alpha = imresize(alpha, p.FIXATION.SIZE);

    % threshold alpha to remove background
    alpha = uint8((alpha > p.FIXATION.TRANSPARENCY_CUTOFF) * 255);

    % attach alpha as 4th channel
    img(:,:,4) = alpha;

    % create PTB texture
    s.fixation.texture = Screen('MakeTexture', s.win, img);

    % destination rect: centred on screen, then shifted
    rect = [-1 -1 +1 +1] .* [p.FIXATION.SIZE p.FIXATION.SIZE]/2;                                    % (0,0) is center of image
    rect = rect + [s.center s.center];                                                              % center on screen
    rect = rect + [p.FIXATION.SHIFT_X p.FIXATION.SHIFT_Y p.FIXATION.SHIFT_X p.FIXATION.SHIFT_Y];    % apply shift
    s.fixation.rect = rect;

end


%% Images

% pre-allocate
s.images.textures = nan(1, s.images.count);
s.images.rects = nan(s.images.count, 4);

% process each image...
for i = 1:s.images.count
    % load image
    img = imread(p.PATH.FOLDER_IMAGES + s.images.filenames(i));

    % resize?
    h = size(img, 1);
    if h ~= p.IMAGES.RESIZE_TO_HEIGHT
        ratio = p.IMAGES.RESIZE_TO_HEIGHT / h;
        img = imresize(img, ratio);
    end

    % create texture
    s.images.textures(i) = Screen('MakeTexture', s.win, img);

    % destination rect: centred on screen, then shifted
    [h, w, ~] = size(img);                              
    rect = [-w -h +w +h] / 2;                                                               % (0,0) is center of image
    rect = rect + [s.center s.center];                                                      % center on screen
    rect = rect + [p.IMAGES.SHIFT_X p.IMAGES.SHIFT_Y p.IMAGES.SHIFT_X p.IMAGES.SHIFT_Y];    % apply shift
    s.images.rects(i,:) = rect;
end


%% Display

msg = 'Textures have been prepared';
disp(msg)
DrawFormattedText(s.win, msg, 'center', 'center');
Screen('Flip', s.win);