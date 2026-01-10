% [condition_table] = GenericTrialCounterbalancer_CreateComboVariable(args)
%
% Input:
%   condition_table         table of unique conditions, values in the columns used must be numeric or string
%   variables_to_combine    [1xN] string array of the conditions variables to combine
%
% Output:
%   condition_table         same as input except the combo variable will have been added
%
function [condition_table] = GenericTrialCounterbalancer_CreateComboVariable(args)
arguments
    args.condition_table                table
    args.variables_to_combine   (1,:)   string
end

%% Verify that args with no defaults have been provided
requiredFields = ["condition_table","variables_to_combine"];
missing = requiredFields(~isfield(args, requiredFields));
if ~isempty(missing)
    error("Missing required arguments: %s", strjoin(missing,", "))
end

%%
% create name for new variable
var_name = strjoin(args.variables_to_combine, "_x_");

% get unique combinations and add as variable
[vals, ~, args.condition_table.(var_name)] = unique(args.condition_table(:, args.variables_to_combine), "rows");

% convert to index to generated label
lookup = vals.Variables;
vals.ID_Label = arrayfun(@(x) strjoin(lookup(x,:),"_"), 1:size(lookup,1))';
args.condition_table.(var_name) = vals.ID_Label(args.condition_table.(var_name));
vals = vals(:,[end 1:end-1]);

% number of unique combinations
count = height(vals);
eval(var_name + "_count = count;");

% display
fprintf("Created %s with %d IDs:\n", var_name, count);
vals.ID = (1:count)';
vals = vals(:,[end 1:end-1]);
disp(vals);

% output
condition_table = args.condition_table;