% Assign an ID to each unique image and verifies that all required image files exist
%
function [d,s] = fMRI_3DCategories_VerifyImageFiles(p, d)

%% Assign an ID to each unique image (excluding fixation)

% get all filenames
filenames = [d.schedule.Filename_Left(d.schedule.Has_Image_Left)
             d.schedule.Filename_Right(d.schedule.Has_Image_Right)
             ];

% reduce to unique filenames
filenames = unique(filenames);

% store
s.images.filenames = filenames;

% count
s.images.count = length(s.images.filenames);

% display
fprintf("Order has %d unique image files\n", s.images.count);


%% Add textures indices to d.schedule

d.schedule.Image_ID_Left (d.schedule.Has_Image_Left ) = arrayfun(@(x) find(s.images.filenames == x), d.schedule.Filename_Left (d.schedule.Has_Image_Left ));
d.schedule.Image_ID_Right(d.schedule.Has_Image_Right) = arrayfun(@(x) find(s.images.filenames == x), d.schedule.Filename_Right(d.schedule.Has_Image_Right));


%% Verify that required image files exist

% fixation (only needed if enabled)
if p.FIXATION.ENABLED
    if ~exist(p.PATH.FOLDER_IMAGES + p.PATH.FILENAME_FIXATION, "file")
        error("Fixation image does not exist: %s", p.PATH.FIXATION)
    end
end

% each stim
for filename = s.images.filenames(:)'
    if ~exist(p.PATH.FOLDER_IMAGES + filename, "file")
        error("Missing image file: %s", filenameN)
    end
end
