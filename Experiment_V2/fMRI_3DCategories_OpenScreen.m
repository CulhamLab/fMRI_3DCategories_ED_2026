% Open the Psychtoolbox "Screen" and make PROPixx-specific calls 
%
function [s] = fMRI_3DCategories_OpenScreen(p, s)

%% Enable PROPixx RB3D Sequencer
if p.PROJECTOR.ENABLED
    Datapixx('Open'); 
    Datapixx('EnableVideoStereoBlueline');
    Datapixx('RegWr');
end


%% Open Screen

% allow up to 5 attempts with 0.5 sec delay
for attempt = 1:5
    try
        [s.win, s.rect] = Screen('OpenWindow', p.SCREEN.NUMBER, p.SCREEN.BACKGROUND_COLOUR, p.SCREEN.RECT);
        HideCursor;
        break;
    catch err
        if attempt < 5
            WaitSecs(0.5);
        else
            warning('Failed to open screen 5 times')
            rethrow(err)
        end
    end
end


%% Show/Hide Cursor

if p.SCREEN.HIDE_CURSOR
    HideCursor;
else
    ShowCursor;
end


%% Check Dimensions

% verify that screen rect is expected
if s.rect(1)~=0 || s.rect(2)~=0 || s.rect(3)~=p.SCREEN.EXPECTED_SIZE(2) || s.rect(4)~=p.SCREEN.EXPECTED_SIZE(1)
    error('Unexpected screen size! [%s]',num2str(s.rect))
end

% store dimensions
s.width = s.rect(3);
s.height = s.rect(4);
s.center = [s.width/2 s.height/2];


%% Set Text Size/Colour

Screen('TextSize', s.win, p.SCREEN.TEXT_SIZE);
Screen('TextColor', s.win, p.SCREEN.TEXT_COLOUR);


%% Horizontal Flip?

if p.SCREEN.FLIP_HORIZONTAL
    Screen('glTranslate', s.win, s.width, 0, 0);
    Screen('glScale', s.win, -1, 1, 1);
end


%% Set GPU CLUTs to linear

% set linear CLUT?
if p.SCREEN.USE_LINEAR_CLUT
    Screen('LoadNormalizedGammaTable', s.win, linspace(0,1,256)'*[1,1,1]);
end

% set blend function?
if p.SCREEN.APPLY_BLEND_FUNCTION
    Screen('BlendFunction', s.win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');
end


%% Display

msg = 'Screen setup complete';
disp(msg)
DrawFormattedText(s.win, msg, 'center', 'center');
Screen('Flip', s.win);