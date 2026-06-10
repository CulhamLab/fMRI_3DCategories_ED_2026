% Reads the order table from the mat file into d.order
%
function [d] = fMRI_3DCategories_LoadOrder(p, d)
arguments
    p   (1,1)   {mustBeA(p,"struct")}
    d   (1,1)   {mustBeA(d,"struct")}
end

% load from mat file
file = load(p.PATH.ORDER);

% should contain a table called "order"
if ~isfield(file, "order")
    error("Order file does not contain the ""order"" field: %s", p.PATH.ORDER)
elseif ~istable(file.order)
    error("Order file contains the ""order"" field, but it is not a table: %s", p.PATH.ORDER)
end

% store order table
d.order = file.order;

% display
fprintf("Loaded order file with %d rows\n", height(d.order));