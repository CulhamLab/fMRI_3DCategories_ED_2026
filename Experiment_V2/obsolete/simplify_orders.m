% Copies and simplifies the orders from fMRI_3DCategories_ED_2026\Experiment
%   Removes unnecessary columns
%   Saves each order as as .mat and .csv


%% Folders
folder_in = "..\Experiment\Orders\";
folder_out = ".\Orders\";

if ~exist(folder_out, "dir")
    mkdir(folder_out)
end


%% Find Files
list = dir(folder_in + "*.xlsx");


%% Process Files
for file = list(:)'
    order = readtable([file.folder filesep file.name]);
    
    % no stims have motion
    % format is always image
    % fixation will be controlled by parameters instead of order file
    order = removevars(order, ["Motion" "Format" "Fixation"]);

    % convert stim to numeric to prevent format issue + change 0s to NaN
    order.Stim = str2double(order.Stim);
    order.Stim(~order.Stim) = nan;

    % convert {char} to strings
    order = convertvars(order, @iscell, "string");

    % filename
    [~,filename,~] = fileparts(file.name);

    % save
    writetable(order, folder_out + filename + ".csv")
    save(folder_out + filename + ".mat", "order")
end


%% Done
disp Done!