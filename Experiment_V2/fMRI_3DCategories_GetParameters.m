% fMRI_3DCategories_GetParameters
% 
% Returns all parameters, also calls PsychDefaultSetup
%
% All settings are in units of seconds and pixels.
%
function [p] = fMRI_3DCategories_GetParameters

%% Psychtoolbox

p.PTB.PSYCH_DEFAULT_SETUP_MODE = 2;             % see PTB documentation, 2 tests the Screen mex file + unifies key names + normalizes colour range
p.PTB.VISUAL_DEBUG_LEVEL =       3;             % see PTB documentation, 3 is "Full Warnings & Info"
p.PTB.SKIP_SYNC_TESTS =          1;             % see PTB documentation, 1 skips the sync test

% PsychDefaultSetup is called here because it is needed below
PsychDefaultSetup(p.PTB.PSYCH_DEFAULT_SETUP_MODE);


%% Projector

p.PROJECTOR.ENABLED = true;                     % disable for offline debugging


%% Screen

p.SCREEN.BACKGROUND_COLOUR = [128 128 128];  % RBG 0-255
p.SCREEN.TEXT_COLOUR =       [  0   0   0];  % RBG 0-255
p.SCREEN.TEXT_SIZE =                    40;  % font size

p.SCREEN.NUMBER =   max(Screen('Screens'));  % see PTB documentation, max index is often desired
p.SCREEN.RECT =                         [];  % [] is full screen, otherwise [left top right bottom] in pixels
p.SCREEN.EXPECTED_SIZE =       [1080 1920];  % expected size of the Screen rect, [height width] in pixels
p.SCREEN.HIDE_CURSOR =                true;  % disable for debugging

p.SCREEN.USE_LINEAR_CLUT =            true;  % enables Screen('LoadNormalizedGammaTable', s.win, linspace(0,1,256)'*[1,1,1]);
p.SCREEN.APPLY_BLEND_FUNCTION =       true;  % enables Screen('BlendFunction', s.win, 'GL_SRC_ALPHA', 'GL_ONE_MINUS_SRC_ALPHA');

p.SCREEN.LINE_WIDTH =                    2;  % in pixels
p.SCREEN.LINE_COLOUR_LEFT =  [  0   0   0];  % RGB 0-255          
p.SCREEN.LINE_COLOUR_RIGHT = [255 255 255];  % RGB 0-255

p.SCREEN.FLIP_HORIZONTAL =           false;  % if enabled: everything is inverted horizontally, may be needed if using a mirror


%% Fixation

p.FIXATION.ENABLED =  true;                     % is enabled, fixation is drawn at all times

p.FIXATION.SIZE =            [30 30];           % fixation is resized to [height width] in pixels
p.FIXATION.TRANSPARENCY_CUTOFF = 240;           % threshold for removing fixation image's background, 0-255

p.FIXATION.SHIFT_X =               0;           % moves fixation position, in pixels, positive is rightward
p.FIXATION.SHIFT_Y =            -115;           % moves fixation position, in pixels, positive is downward


%% Images

p.IMAGES.RESIZE_TO_HEIGHT = 1080;               % all images are resized to have this height in pixels

p.IMAGES.SHIFT_X =             0;               % moves images, in pixels, positive is rightward
p.IMAGES.SHIFT_Y =          -130;               % moves images, in pixels, positive is downward


%% Timing

p.TIMING.TR =                 1;                % TR in seconds
p.TIMING.IMAGE_PRESENTATION = 1;                % Duration that images are presented, must be <= TR

p.TIMING.SECONDS_BEFORE_TRIGGER_CAN_BE_ACCEPTED = 0.500;     % triggers will only be accepted after 500 msec in a volume, allowing earlier triggers could mistakenly see the prior trigger
p.TIMING.SECONDS_MAXIMUM_OVERTIME_IF_NO_TRIGGER = 0.005;     % 5 msec after the expected end of a volume, stop looking and proceed as if the trigger had arrived at the expected time


%% Paths

p.PATH.FOLDER_ORDERS =  string(pwd) + filesep + "Orders" + filesep;
p.PATH.FOLDER_DATA =    string(pwd) + filesep + "Data"   + filesep;
p.PATH.FOLDER_IMAGES =  string(pwd) + filesep + "Images" + filesep;

p.PATH.FILENAME_FIXATION = "fixation_transparent.png";

% Order and data filepaths are defined as functions 
p.PATH.FILEPATH_FUNC_ORDER = @(participant_number, run_number) p.PATH.FOLDER_ORDERS + sprintf("PAR%02d_RUN%02d.mat", participant_number, run_number);
p.PATH.FILEPATH_FUNC_DATA_ERROR = @(participant_number, run_number, timestamp) p.PATH.FOLDER_DATA + sprintf("PAR%02d_RUN%02d_%s_ERROR.mat", participant_number, run_number, timestamp);
p.PATH.FILEPATH_FUNC_DATA_COMPLETE = @(participant_number, run_number, timestamp) p.PATH.FOLDER_DATA + sprintf("PAR%02d_RUN%02d_%s.mat", participant_number, run_number, timestamp);


%% Keys

p.KEYS.STOP = KbName('ESCAPE');                                                      % Escape key ends the experiment
p.KEYS.TRIGGER = KbName({'5%' 't'});                                                 % Triggers can be 5 or T
p.KEYS.BUTTON_BOX = KbName({'1!' '2@' '3#' '4$' 'r' 'g' 'b' 'y' '1' '2' '3' '4'});   % Button box is any of: RGBY, 1-4 at top of keyboard, 1-4 numpad


%% Debugging

p.DEBUG.START_IMMEDIATELY = false;   % if true, do not wait for the first trigger
p.DEBUG.START_ON_VOLUME = 1;         % which volume to start on





%% Overrides for Debugging

% warning("Debug settings applied")
% 
% p.PROJECTOR.ENABLED = false;
% 
% p.SCREEN.NUMBER =   1;
% p.SCREEN.RECT =     [];
% 
% p.SCREEN.HIDE_CURSOR = false;
% 
% p.DEBUG.START_IMMEDIATELY = true;
% p.DEBUG.START_ON_VOLUME = 64;

