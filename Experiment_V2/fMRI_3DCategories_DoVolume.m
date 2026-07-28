% Runs the current volume
%
% In case d ever becomes quite large, only the new row is returned:
%   volume_data = d.schedule(vol, :)
%
function [volume_data, s] = fMRI_3DCategories_DoVolume(p, d, s, vol)

%% Start of volume - Timing

% first volume?
is_first_volume = (vol == 1) || (vol == p.DEBUG.START_ON_VOLUME);

% Actual start time relative to d.t0
if is_first_volume
    % The first volume starts exactly at d.t0 (first trigger)
    d.schedule.Time_Start_Actual(vol) = 0;
else
    d.schedule.Time_Start_Actual(vol) = GetSecs - d.t0;
end

% Effective start time
if is_first_volume || d.schedule.Received_Trigger(vol-1)
    % use the actual time if the latest trigger was recieved
    d.schedule.Time_Start(vol) = d.schedule.Time_Start_Actual(vol);
else
    % otherwise, use the expected timing instead
    d.schedule.Time_Start(vol) = d.schedule.Time_Start(vol-1) + p.TIMING.TR;
end


%% Start of volume - Command Window Message

% volume number and timing
fprintf("\nStarting volume %d/%d at %.3f sec (actual %.3f sec):\n", vol, d.number_volumes, d.schedule.Time_Start(vol), d.schedule.Time_Start_Actual(vol));

% condition
if d.schedule.Trial(vol) == 0
    condition = "Baseline";
elseif ismissing(d.schedule.Condition(vol))
    condition = "ITI";
else
    condition = sprintf("%s (%s | %s)", d.schedule.Condition(vol), d.schedule.Filename_Left(vol), d.schedule.Filename_Right(vol));
end
fprintf("\tCondition: %s\n", condition);


%% Start of volume - Images

% set image
s = fMRI_3DCategories_PrepareVolumeFrame(p, s, d.schedule.Image_ID_Left(vol), d.schedule.Image_ID_Right(vol));

% will need to clear the image mid-volume?
%   needed if there is a stim and the presentation time is set to be less than a TR
need_to_clear_image = ~ismissing(d.schedule.Condition(vol)) && (p.TIMING.IMAGE_PRESENTATION < p.TIMING.TR);


%% Run Volunme

% initialize checks for image changes
countdown_is_on_screen_initial_state = 2;
countdown_is_on_screen_image_removed = 0;

% Loop until trigger is received or timeout
while 1
    % Time in this volume (using the effective start time)
    time_in_vol = (GetSecs - d.t0) - d.schedule.Time_Start(vol);

    % Check keys...
    [trigger_received, button_box_pressed] = fMRI_3DCategories_CheckKeys(p);

    % Trigger?
    if trigger_received && (time_in_vol >= p.TIMING.SECONDS_BEFORE_TRIGGER_CAN_BE_ACCEPTED)
        d.schedule.Received_Trigger(vol) = true;
        fprintf("\t~~Trigger received~~\n");
        break;
    end

    % Button Box?
    if button_box_pressed && ~d.schedule.Button_Box_Pressed(vol)
        d.schedule.Button_Box_Pressed(vol) = true;
        d.schedule.Button_Box_Time(vol) = time_in_vol;
        fprintf("\tButton box pressed\n");
    end

    % Clear image?
    if need_to_clear_image && (time_in_vol >= p.TIMING.IMAGE_PRESENTATION)
        s = fMRI_3DCategories_PrepareVolumeFrame(p, s, 0, 0);
        need_to_clear_image = false;
        countdown_is_on_screen_image_removed = 2;
    end

    % Queue next frame?
    if Screen('AsyncFlipCheckEnd', s.win)
        % store time when queuing the SECOND frame, this is when volume's first frame is on screen
        if countdown_is_on_screen_initial_state > 0
            countdown_is_on_screen_initial_state = countdown_is_on_screen_initial_state - 1;
            if ~countdown_is_on_screen_initial_state
                d.schedule.Time_Image_Updated(vol) = time_in_vol;
            end
        end

        % store time when queuing the SECOND frame after removing the image, this is when image is no longer on screen
        if countdown_is_on_screen_image_removed > 0
            countdown_is_on_screen_image_removed = countdown_is_on_screen_image_removed - 1;
            if ~countdown_is_on_screen_image_removed
                d.schedule.Time_Image_Removed(vol) = time_in_vol;
            end
        end

        s.current.is_left = fMRI_3DCategories_QueueNextFrame(s);
    end

    % Timeout?
    if time_in_vol >= (p.TIMING.TR + p.TIMING.SECONDS_MAXIMUM_OVERTIME_IF_NO_TRIGGER)
        % Warn if no trigger in volumes other than the last one
        if vol < d.number_volumes
            warning("No trigger was recieved. Continuing with expected timing...")
        end

        % Stop this volume's loop
        break
    end
end


%% End of volume

% timing
d.schedule.Time_End_Actual(vol) = GetSecs - d.t0;
d.schedule.Duration(vol) = d.schedule.Time_End_Actual(vol) - d.schedule.Time_Start(vol);
d.schedule.Duration_Actual(vol) = d.schedule.Time_End_Actual(vol) - d.schedule.Time_Start_Actual(vol);

% display
fprintf("\tDuration: %.3f sec\n", d.schedule.Duration(vol));


%% Return the volume data

volume_data = d.schedule(vol, :);