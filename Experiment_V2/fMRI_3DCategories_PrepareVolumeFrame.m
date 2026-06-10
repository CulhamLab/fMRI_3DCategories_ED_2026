% Prepares a volume frame in s.current 
%
% Should be called as:
%   s.current = fMRI_3DCategories_PrepareVolumeFrame(p, s, texture_left, texture_right);
%
function [s] = fMRI_3DCategories_PrepareVolumeFrame(p, s, ID_left, ID_right)

%% Clear textures, rects, and text

for view = ["left" "right"]
    s.current.(view).textures =      [];
    s.current.(view).texture_rects = [];
    s.current.(view).text =          {};
end


%% Set textures and their rects

for view = ["left" "right"]
    % start with provided ID
    ID = eval("ID_" + view);

    % add if valid
    if ID > 0
        s.current.(view).textures(end+1) = s.images.textures(ID);
        s.current.(view).texture_rects(end+1,:) = s.images.rects(ID, :);
    end

    % add fixation?
    if p.FIXATION.ENABLED
        s.current.(view).textures(end+1) = s.fixation.texture;
        s.current.(view).texture_rects(end+1,:) = s.fixation.rect;
    end

end
