% Checks for triggers, button box, and stop key
%
function [trigger_received, button_box_pressed] = fMRI_3DCategories_CheckKeys(p)

% Get key status
[~, ~, keys] = KbCheck(-1); %get key(s)

% trigger?
trigger_received = any(keys(p.KEYS.TRIGGER));

% button box?
button_box_pressed = any(keys(p.KEYS.BUTTON_BOX));

% error if stop key
if any(keys(p.KEYS.STOP))
    error('Stop key was pressed.')
end