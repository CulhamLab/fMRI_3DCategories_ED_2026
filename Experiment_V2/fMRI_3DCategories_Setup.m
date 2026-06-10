% Performs an assortment of setup tasks and initializes the data structure
%   - Store a timestamp (initializes d)
%   - Store participant and run numbers in d
%   - Set order and data filepaths for this participant/run
%   - Create output folder
%   - Verify that expected files/folders exist
%   - Attempt to store git repo info
%   - Apply Psychtoolbox Settings
%   - Validate timing parameters
%   - Pre-call time-sensitive functions for better performance when it matters
%
function [p,d] = fMRI_3DCategories_Setup(p, participant_number, run_number)
arguments
    p                   (1,1) {mustBeA(p,"struct")}
    participant_number  (1,1) {mustBePositive, mustBeInteger}
    run_number          (1,1) {mustBePositive, mustBeInteger}
end

%% Store a timestamp

d.timestamp_setup = datetime("now", Format="yyyy-MM-dd_HH-mm-ss");


%% Store participant and run numbers in d

d.participant_number = participant_number;
d.run_number = run_number;


%% Set filepaths for order and data

p.PATH.ORDER = p.PATH.FILEPATH_FUNC_ORDER(d.participant_number, d.run_number);
p.PATH.DATA_ERROR = p.PATH.FILEPATH_FUNC_DATA_ERROR(d.participant_number, d.run_number, d.timestamp_setup);
p.PATH.DATA_COMPLETE = p.PATH.FILEPATH_FUNC_DATA_COMPLETE(d.participant_number, d.run_number, d.timestamp_setup);


%% Create Data output folder if it doesn't already exist

if ~exist(p.PATH.FOLDER_DATA, "dir")
    mkdir(p.PATH.FOLDER_DATA);
end


%% Verify that expected files and folders exists

% order file
if ~exist(p.PATH.ORDER, "file")
    error("Order file does not exist: %s", p.PATH.ORDER)
end

% images folder
if ~exist(p.PATH.FOLDER_IMAGES, "dir")
    error("Image folder does not exist: %s", p.PATH.FOLDER_IMAGES)
end


%% Attempt to store information about the git repo's current status
% Uses https://github.com/CulhamLab/Git-Version

if exist('IsGitRepo','file') && ~IsGitRepo
    warning('This project does not appear to be part of a git repository. No git data will be saved.');
elseif exist('GetGitInfo','file')
    d.GitInfo = GetGITInfo(pwd);
else
    warning('The "CulhamLab/Git-Version" repo has not been configured. Information about this project''s current repository status (version, etc.) will NOT be saved to the data file.');
end


%% Apply Psychtoolbox Settings

Screen('Preference', 'VisualDebugLevel', p.PTB.VISUAL_DEBUG_LEVEL);
Screen('Preference', 'SkipSyncTests', p.PTB.SKIP_SYNC_TESTS);


%% Validate timing parameters

% image presentation duration must be less than TR
if p.TIMING.IMAGE_PRESENTATION > p.TIMING.TR
    error("TIMING.IMAGE_PRESENTATION must not be longer than TIMING.TR")
end

% warn if SECONDS_BEFORE_TRIGGER_CAN_BE_ACCEPTED >= TR
if p.TIMING.SECONDS_BEFORE_TRIGGER_CAN_BE_ACCEPTED >= p.TIMING.TR
    error("TIMING.SECONDS_BEFORE_TRIGGER_CAN_BE_ACCEPTED must be less than TIMING.TR")
end

% warn if (TR - SECONDS_BEFORE_TRIGGER_CAN_BE_ACCEPTED) is less than 200 msec
if (p.TIMING.TR - p.TIMING.SECONDS_BEFORE_TRIGGER_CAN_BE_ACCEPTED) < 0.2
    warning("TIMING.SECONDS_BEFORE_TRIGGER_CAN_BE_ACCEPTED might be too late. Triggers may be missed.")
end

% warn if SECONDS_MAXIMUM_OVERTIME_IF_NO_TRIGGER is more than 10 msec
if p.TIMING.SECONDS_MAXIMUM_OVERTIME_IF_NO_TRIGGER > 0.01
    warning("TIMING.SECONDS_MAXIMUM_OVERTIME_IF_NO_TRIGGER might be too long. Volume events may be noticably delayted when triggers are missed.")
end


%% Call time-sensitive functions a few times in advance to improve later timing

for i = 1:10
    GetSecs;
    KbCheck;
end

