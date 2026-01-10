% [rules] = GenericTrialCounterbalancer_InitializeRules(args)
%
% IMPORTANT: This step initializes the specified order rules allowing for 0
% to infinite occurances of each combination (i.e., no limitations). An 
% important consequence of this is that the GenerateOrder step will
% partially balance these occurances even if they are left as 0 to inf.
%
% Input:
%   condition_table                 table of unique conditions, values in the columns used must be numeric or string
%   variables_with_order_rules      [1xN] string array of the variables names that will have order rules
%   variables_with_eachhalf_rules   [1xN] string array of the variables names that will have per-half count rules
%   first_condition_row             row in the condition table of the condition to place in the first trial, leave NaN to randomize
%
% Output:
%   rules                           structure of rules for use in GenericTrialCounterbalancer_GenerateOrder
%
function [rules] = GenericTrialCounterbalancer_InitializeRules(args)
arguments
    args.condition_table                     table
    args.variables_with_order_rules    (1,:) string = []
    args.variables_with_perhalf_rules  (1,:) string = []
    args.first_condition_row           (1,1) double = nan
end

%% Verify that args with no defaults have been provided
requiredFields = ["condition_table"];
missing = requiredFields(~isfield(args, requiredFields));
if ~isempty(missing)
    error("Missing required arguments: %s", strjoin(missing,", "))
end

%%
% initialize
rules = struct;

% add first condition index (NaN = random)
if isempty(args.first_condition_row)
    args.first_condition_row = nan;
end
rules.first_condition_index = args.first_condition_row;

% initialize order rules to allow 0 to infinite occurances
fprintf("Initializing default order rules...\n");
rules.order = struct;
for f = args.variables_with_order_rules
    count = length(unique(args.condition_table.(f)));
    fprintf("\t%s (%d x %d): allowing 0 to infite occurances...\n", f, count, count);
    rules.order.(f).min = zeros(count, count);
    rules.order.(f).max = ones(count, count) * inf;
end

% initialize per-half count rules to allow 0 to infinite occurances in each half of the runs
fprintf("Initializing default per-half count rules...\n");
rules.perhalfcount = struct;
for f = args.variables_with_perhalf_rules
    fprintf("\t%s: allowing 0 to infite occurances in each half of runs...\n", f);
    rules.perhalfcount.(f).min = 0;
    rules.perhalfcount.(f).max = inf;
end