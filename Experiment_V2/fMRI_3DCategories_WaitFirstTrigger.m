% Display a 3D test screen and wait for the first trigger
%
function [d, s] = fMRI_3DCategories_WaitFirstTrigger(p, d, s)

%% Initialize s.current with a 3D test screen

% start with left view
s.current.is_left = 1;

% initialize left and right structs
s.current.left =  struct(textures=[], texture_rects=[], text=cell(1), line_colour=p.SCREEN.LINE_COLOUR_LEFT,  line_width=p.SCREEN.LINE_WIDTH);
s.current.right = struct(textures=[], texture_rects=[], text=cell(1), line_colour=p.SCREEN.LINE_COLOUR_RIGHT, line_width=p.SCREEN.LINE_WIDTH);

% only texture is the fixation cross
if p.FIXATION.ENABLED
    % add to left
    s.current.left.textures = s.fixation.texture;
    s.current.left.texture_rects = s.fixation.rect;

    % add to right
    s.current.right.textures = s.fixation.texture;
    s.current.right.texture_rects = s.fixation.rect;
end

% both views will display the waiting message in the top middle
msg = sprintf('Waiting for first trigger (%d volumes)', d.number_volumes);
s.current.left.text(end+1,:) = {msg , 'center' , 3 * p.SCREEN.TEXT_SIZE};
s.current.right.text(end+1,:) = {msg , 'center' , 3 * p.SCREEN.TEXT_SIZE};

% each view will display Left/Right on the corresponding side of the screen to verify 3D
s.current.left.text(end+1,:) =  {'Left' ,  s.center(1) - (15 *   p.SCREEN.TEXT_SIZE) , 'center'};
s.current.right.text(end+1,:) = {'Right' , s.center(1) + (15.5 * p.SCREEN.TEXT_SIZE) , 'center'};


%% Draw the first frame

s.current.is_left = fMRI_3DCategories_QueueNextFrame(s);


%% Loop until trigger or stop key

while 1
    % Stop once trigger is detected
    [trigger_received, button_box_pressed] = fMRI_3DCategories_CheckKeys(p);
    if trigger_received || p.DEBUG.START_IMMEDIATELY
        break
    end

    % If prior frame is up, then queue the next frame
    if Screen('AsyncFlipCheckEnd', s.win)
        s.current.is_left = fMRI_3DCategories_QueueNextFrame(s);
    end
end


%% This is time-zero (d.t0)

d.t0 = GetSecs;