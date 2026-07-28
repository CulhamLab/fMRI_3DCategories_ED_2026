% Creates a volume-wise schedule of events
%
function [d] = fMRI_3DCategories_CreateVolumeSchedule(p, d)

%% Calcualte number of volumes

% Duration in seconds
d.total_seconds = sum(d.order.Duration_Seconds);

% Number of volumes
d.number_volumes = d.total_seconds / p.TIMING.TR;

% Display
fprintf("Created schedule for %d volumes spanning %g seconds (TR = %g sec)\n", d.number_volumes, d.total_seconds, p.TIMING.TR);

% Number of volumes must be an integer
if d.number_volumes ~= round(d.number_volumes)
    error("Number of volumes must be an even integer");
end

% all events must be evenly divisibly by TR
if any(mod(d.order.Duration_Seconds, p.TIMING.TR))
    error("All durations in the order must be divisible by TIMING.TR")
end

% all non-NULL conditions must be one volume
if any( d.order.Duration_Seconds(d.order.Condition ~= "NULL") ~= p.TIMING.TR )
    error("All image presentation events must be 1 volume")
end


%% Initialize volume schedule

% table fields
%   do not use logical, it breaks the default nan shortcut method below
vars = ["Volume"                "double"        % volume in run
        "Order_Row"             "double"        % row in order table
        "Trial"                 "double"        % order.Trial
        "Condition"             "string"        % order.Condition
        "Display_Type"          "string"        % order.Display
        "Category"              "string"        % order.Category
        "Index_in_Category"     "double"        % order.Stim
        "Is_Repeat"             "double"        % 1 if volume has an image that matches the prior trial, else 0
        "Has_Image_Left"        "double"        % 1 if volume has a left eye image, else 0
        "Has_Image_Right"       "double"        % 1 if volume has a right eye image, else 0
        "Filename_Left"         "string"        % name of left view image (empty if no image)
        "Filename_Right"        "string"        % name of right view image (empty if no image)
        "Image_ID_Left"         "double"        % set during VerifyImageFiles
        "Image_ID_Right"        "double"        % set during VerifyImageFiles
        "Time_Start_Actual"     "double"        % actual start time, can be late if the prior trigger was missed
        "Time_Start"            "double"        % effective start time, if the prior trigger was missed then this is corrected to continue as if the trigger had been exactly on time
        "Time_End_Actual"       "double"        % actual end time, can be late if the trigger was missed
        "Duration"              "double"        % Time_End_Actual - Time_Start
        "Duration_Actual"       "double"        % Time_End_Actual - Time_Start_Actual
        "Received_Trigger"      "double"        % 1 if the trigger was received at end of this volume
        "Button_Box_Pressed"    "double"        % 1 if any button on the box was pressed during this volume
        "Button_Box_Time"       "double"        % time of first button press relative to Time_Start
        "Time_Image_Updated"    "double"        % time of the second frame queue, at which point the first frame is now on screen
        "Time_Image_Removed"    "double"        % if (p.TIMING.IMAGE_PRESENTATION < p.TIMING.TR), then this is when the image is no longer on the screen
        ];

% initialize table
d.schedule = table(Size=[d.number_volumes size(vars,1)], VariableNames=vars(:,1), VariableTypes=vars(:,2));

% default all fields to NaN, also sets strings to missing
d.schedule{:,:} = nan;


%% Populate volume schedule

% initialize counter
vol = 0;

% process order rows
for row = 1:height(d.order)
    % how many volumes does this event occupy?
    event_volumes = d.order.Duration_Seconds(row) / p.TIMING.TR;

    % for each volume...
    for v = 1:event_volumes
        % increment counter
        vol = vol +1;

        % populate basic fields
        d.schedule.Volume(vol) = vol;
        d.schedule.Order_Row(vol) = row;
        d.schedule.Trial(vol) = d.order.Trial(row);
        d.schedule.Index_in_Category(vol) = d.order.Stim(row);
        d.schedule.Is_Repeat(vol) = d.order.Is_repeat(row);

        % add Condition unless it is null
        condition = d.order.Condition(row);
        if condition ~= "NULL"
            d.schedule.Condition(vol) = condition;
        end

        % add 2D/3D unless it is ""
        dim = d.order.Display(row);
        if dim.strlength
            d.schedule.Display_Type(vol) = dim;
        end

        % add Category unless it is ""
        category = d.order.Category(row);
        if category.strlength
            d.schedule.Category(vol) = category;
        end

        % Has_Image_Left and Filename_Left
        filename = d.order.Filename_left(row);
        d.schedule.Has_Image_Left(vol) = filename.strlength > 0;
        if d.schedule.Has_Image_Left(vol)
            d.schedule.Filename_Left(vol) = filename;
        end

        % Has_Image_Right and Filename_Right
        filename = d.order.Filename_right(row);
        d.schedule.Has_Image_Right(vol) = filename.strlength > 0;
        if d.schedule.Has_Image_Right(vol)
            d.schedule.Filename_Right(vol) = filename;
        end
    end
end


%% Vol counter should now match number_volumes

if vol ~= d.number_volumes
    error("Unexpected number of volumes in schedule. There is a bug in the schedule creation.")
end


%% Convert to logical fields for easier checks

d.schedule = convertvars(d.schedule, ["Is_Repeat" "Has_Image_Left" "Has_Image_Right"], @logical);
d.schedule.Received_Trigger(:) = false;
d.schedule.Button_Box_Pressed(:) = false;

