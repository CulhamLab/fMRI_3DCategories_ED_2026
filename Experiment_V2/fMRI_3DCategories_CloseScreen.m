% Unhides the cursor and closes the Screen
%
% Called when the main script closes
%
function fMRI_3DCategories_CloseScreen
ShowCursor;     % if something goes wrong, at least show cursor if it was hidden
sca; sca;       % sometimes requires a second call