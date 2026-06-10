% Draws the next frame and queues it with AsyncFlipBegin
%
% Should be called only when AsyncFlipCheckEnd is true
%    if Screen('AsyncFlipCheckEnd', s.win)
%        s.current.is_left = fMRI_3DCategories_QueueNextFrame(s);
%    end
%
function [next_is_left] = fMRI_3DCategories_QueueNextFrame(s)

%% Select view

if s.current.is_left
    view = s.current.left;
else
    view = s.current.right;
end


%% Draw texture(s)
% textures is 1xN texture indices
% texture_rects is Nx4 corresponding rects

for i = 1:length(view.textures)
    Screen('DrawTexture', s.win, view.textures(i), [], view.texture_rects(i,:));
end


%% Draw text(s)
% text is Nx3 of {message , y , x}

for i = 1:size(view.text, 1)
    DrawFormattedText(s.win, view.text{i,1}, view.text{i,2}, view.text{i,3});
end


%% Draw line

Screen('DrawLine', s.win, view.line_colour, s.rect(1), s.rect(4)-1, s.rect(3), s.rect(4)-1, view.line_width);


%% Queue async flip

Screen('AsyncFlipBegin', s.win);


%% Return other view for next call

next_is_left = ~s.current.is_left;
