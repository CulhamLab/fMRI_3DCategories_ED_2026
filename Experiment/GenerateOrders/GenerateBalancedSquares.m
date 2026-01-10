% function [squares] = GenerateBalancedSquares(args)
%
% Generates the specified number of balanced squares with the specified
% size. Three balancing modes are supported:
%   Positions Only:     Latin Square. Each condition occurs once in each postion.
%   Order Only:         Each condition follows each other condition once.
%   Both (default):     Both rules are applied together. Latin square with controlled order effects. Can be quite slow to compute.
%
% This method will slow down and/or crash if args.square_size is too large.
%
% By default, squares are generated from all possible permutations WITHOUT 
% replacement, which means that all rows will be unique. However, this
% method takes longer and may time out if solutions become too rare or if
% there are not enough solutions for the number of generated squares.
%
% Inputs
%   args.square_size             size of the squares to generate
%   args.square_count            how many squares to generate
%   balance_mode            position, order, or both (default: both)
%   replacement             whether permutations should be selected with/without replacement (default: false)
%   max_search_iterations   maximum number of search attempts per square (default: 1 million)
%
function [squares] = GenerateBalancedSquares(args)
arguments
    args.square_size (1,1) double {mustBePositive, mustBeInteger}
    args.square_count (1,1) double {mustBePositive, mustBeInteger}
    args.balance_mode (1,1) string {mustBeMember(args.balance_mode,["position" "order" "both"])} = "both"
    args.replacement (1,1) logical = false
    args.max_search_iterations (1,1) double {mustBePositive, mustBeInteger} = 1e6
end

%% Verify that args with no defaults have been provided
requiredFields = ["square_size","square_count"];
missing = requiredFields(~isfield(args, requiredFields));
if ~isempty(missing)
    error("Missing required arguments: %s", strjoin(missing,", "))
end


%% Display
if args.replacement
    str = "with";
else
    str = "without";
end
fprintf("Generating %d %dx%d squares %s replacement. Balancing mode is: %s. The maximum number of search iterations is set to %g...\n\n", args.square_count, args.square_size, args.square_size, str, args.balance_mode, args.max_search_iterations);


%% Initialize
squares = nan(args.square_size, args.square_size, args.square_count);


%% Generate all permuations

% generate all permutations
perms_values = perms(1:args.square_size);
perms_count = size(perms_values, 1);
perms_available = true(perms_count, 1);

% if without replacement, check if could be enough permutations
if ~args.replacement
    min_perms_needed = args.square_size * args.square_count;
    if perms_count < min_perms_needed
        error("There are not enough permutations to generate the squares without replacement")
    end
end

% populate order tables for each permutation to speed up the search
perms_order = false(args.square_size, args.square_size, perms_count);
for i = 1:perms_count
    for run = 2:args.square_size
        prior = perms_values(i, run-1);
        this = perms_values(i, run);
        perms_order(prior, this, i) = true;
    end
end


%% Find all valid permutation pairs

% default all to valid
perm_pairs_valid = true(perms_count, perms_count);

% set balance mode
balance_position = false;
balance_order = false;
switch args.balance_mode
    case "position"
        balance_position = true;
    case "order" 
        balance_order = true;
    case "both"
        balance_position = true;
        balance_order = true;
    otherwise
        error("Unsupported balance mode: %s", args.balance_mode)
end

% invalid if value in same position
if balance_position
    for i = 1:perms_count
        for j = i:perms_count
            if any(perms_values(i,:) == perms_values(j,:))
                perm_pairs_valid(i,j) = false;
                perm_pairs_valid(j,i) = false;
            end
        end
    end
end

% invalid if same ordered pair occurs
if balance_order
    for i = 1:perms_count
        for j = i:perms_count
            if any(any(perms_order(:,:,i) & perms_order(:,:,j)))
                perm_pairs_valid(i,j) = false;
                perm_pairs_valid(j,i) = false;
            end
        end
    end
end

% display info
n = sum(perm_pairs_valid(1, :));
npc = n / perms_count;
c = 1 / (npc ^ factorial(args.square_size-1));
fprintf("There are %d permutations of 1-%d. Each permutation pairs with %d of the others (%.2f%%).\n\nThe chance of randomly selecting a valid set to form a square is roughly 1 in %.1g.\nThis script uses a heuristic method that is much more efficient, but this should give you an idea of how long it might take to run.\n\n", perms_count, args.square_size, n, npc*100, c);

% % visualize?
% imagesc(perm_pairs_valid); axis square;


%%

for square = 1:args.square_count
    fprintf("Generating balanced square %d of %d...", square, args.square_count);

    % find a valid selection to form the square
    for i = 1:args.max_search_iterations
        % default to success
        success = true;
    
        % initialize selection
        selection = nan(1, args.square_size);
    
        % randomly select first row
        selection(1) = randperm(perms_count, 1);
    
        % add valid rows...
        for j = 2:args.square_size
            % must be valid with all other selections
            valid = prod(perm_pairs_valid(selection(1:(j-1)), :), 1);
    
            % find options
            options = find(valid);
            if isempty(options)
                % no options, try again
                success = false;
                break
            else
                % found one or more options, randomly select one of them
                selection(j) = randsample(repmat(options(:), [2 1]), 1);
            end
        end
    
        % still success after adding all rows, stop looking
        if success
            break
        end
    end
    
    % if the loop ended without success then it failed to find a solution
    if ~success
        fprintf("\n");
        error("Failed to find a solution after the maximum number of search iterations. Reattempting might work. Otherwise, you will need to adjust the parameters.")
    end

    % success!
    fprintf("found a solution after %d iterations\n", i);

    % store the square
    square_values = perms_values(selection, :);
    squares(:,:,square) = square_values;

    % if without replacement, then invalidate the selection
    if ~args.replacement
        perm_pairs_valid(selection, :) = false;
        perm_pairs_valid(:, selection) = false;
    end

end