% Main function
%
% Requirements:
%   MATLAB R2021a or later (tested with 2025a)
%   Psychtoolbox (tested with 3.0.19)
%   (Optional) https://github.com/CulhamLab/Git-Version
%
% Inputs:
%   participant_number  selects order, must be a positive integer
%   run_number          selects order, must be a positive integer
%
% Core Structures:
%   VARIABLE    FULL NAME       DESCRIPTION            
%   p           Parameters      Contains all parameters
%   d           Data            Contains the order, volume schedule, timestamps, etc.
%   s           Screen          Contains all active Screen info (e.g., window pointer) including image texture pointers
%
% Overview:
%   1. This function should be called from the command window with the participant and run number
%   2. fMRI_3DCategories_GetParameters          Get all parameters
%   3. fMRI_3DCategories_Setup                  Perform setup tasks
%   4. fMRI_3DCategories_LoadOrder              Load the run order
%   5. fMRI_3DCategories_CreateVolumeSchedule   Create volume-wise schedule
%   6. fMRI_3DCategories_VerifyImageFiles       Assign an ID to each unique image and verifies that all required image files exist
%   7. fMRI_3DCategories_OpenScreen             Open the Psychtoolbox "Screen" and perform PROPixx setup
%   8. fMRI_3DCategories_PrepareImageTextures   Load image files (both fixation and stims), apply any adjustments (e.g., resizing), and create their "Screen" textures
%   9. fMRI_3DCategories_WaitFirstTrigger       Display 3D test while waiting for the first trigger, then sets time-zero (d.t0)
%   10. fMRI_3DCategories_DoVolume              Called for each volume to run events
%   11. After all volumes, this function will save the data and close the screen
%   
% 
function fMRI_3DCategories(participant_number, run_number)
arguments
    participant_number  (1,1) {mustBePositive, mustBeInteger}
    run_number          (1,1) {mustBePositive, mustBeInteger}
end


%% Get Parameters
% This step also calls PsychDefaultSetup

p = fMRI_3DCategories_GetParameters;


%% Perform Setup
%   - Store a timestamp (initializes d)
%   - Store participant and run numbers in d
%   - Set order and data filepaths for this participant/run
%   - Create output folder
%   - Verify that expected files/folders exist
%   - Attempt to store git repo info
%   - Apply Psychtoolbox Settings
%   - Validate timing parameters
%   - Pre-call time-sensitive functions for better performance when it matters

[p,d] = fMRI_3DCategories_Setup(p, participant_number, run_number);


%% Load the run order
% Reads the order table from the mat file into d.order

d = fMRI_3DCategories_LoadOrder(p, d);


%% Create volume-wise event schedule

d = fMRI_3DCategories_CreateVolumeSchedule(p, d);


%% Assign an ID to each unique image and verifies that all required image files exist

[d,s] = fMRI_3DCategories_VerifyImageFiles(p, d);


%% Try...
% If anything goes wrong from here on, make sure that the screen closes

% will be set true once volumes start
save_error_dump = false;
try


%% Open the Psychtoolbox "Screen" and perform PROPixx setup 

s = fMRI_3DCategories_OpenScreen(p, s);


%% Load image files (both fixation and stims), apply any adjustments (e.g., resizing), and create their "Screen" textures

s = fMRI_3DCategories_PrepareImageTextures(p, s);


%% Display 3D test while waiting for the first trigger
%   Left eye should see the word "Left" on the left side of the screen
%   Right eye should see the word "Right" on the right side of the screen

[d, s] = fMRI_3DCategories_WaitFirstTrigger(p, d, s);


%% Ready to begin volumes...

% If an error occurs after this point, save before closing
save_error_dump = true;


%% Run each volume

for vol = 1 : d.number_volumes
    % DEBUG: skip any of the first volumes?
    if vol < p.DEBUG.START_ON_VOLUME
        continue
    end

    % store the current volume index (can be helpful for troubleshooting)
    d.current_volume = vol;

    % run the current volume
    [d.schedule(d.current_volume,:), s] = fMRI_3DCategories_DoVolume(p, d, s, vol);
end


%% Successful End

% save p, d, and s
fprintf("Saving: %s\n", p.PATH.DATA_COMPLETE);
save(p.PATH.DATA_COMPLETE, "p", "d", "s")

% close screen
fMRI_3DCategories_CloseScreen

% complete!
disp("Complete!")


%% Catch...
% Need to close screen and save error dump before throwing the error
catch err
    % save everything to error dump
    if save_error_dump
        fprintf("Saving error dump: %s\n", p.PATH.DATA_ERROR);
        save(p.PATH.DATA_ERROR)
    end
    
    % close screen
    fMRI_3DCategories_CloseScreen

    % add the main structures to the workspace for debugging
    assignin("base" ,"p", p)
    assignin("base" ,"d", d)
    assignin("base" ,"s", s)

    % throw error
    rethrow(err)
end
