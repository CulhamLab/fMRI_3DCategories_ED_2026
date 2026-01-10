%[text] # **fMRI\_3DCategories\_ED\_2026**
%[text] ## Generic Trial Counterbalancer
%[text] 
%[text] This tool is intended for generic trial counterbalancing. It is not suited to mixed designs (e.g., can not balance positions within blocks). It also does not do any balancing across runs - only within runs.
%[text] 
%[text] Additionally, this tool currently requires each unique condition to have an equal number of repetitions (but the unique conditions do not have to be balanced).
%[text] 
%[text] This tool <u>**balances within-run only**</u> with the exception that the first trial of each run may be set, which may be used to balance the first presented condition across runs.
%[text] 
%[text] The following rules are supported:
%[text] 1. (Optional) Predefine the first trial's condition (specify a row in the condition table)
%[text] 2. Order effects: define the minimum and maximum number of times that each ordered pair may occur, supports the indepedent use of any number of variables
%[text] 3. Per-half-run counts: define the minimum and maximum number of times that each level of a variable may occur in each half of each run \
%%
%[text] ## Load or create a table of conditions
%[text] Create or load a table of unique conditions
%[text] Columns that will be used in counterbalancing must be numeric or string, but not cell (i.e., no character arrays)
% initialize/clear table
conditions = table;

% parameters
stims_per_category = 16;
filetype = "png";
reps_per_stim = 1;

% generate list of all conditions
ID = 0;
for view = ["2D" "3D"]
    for category = ["Face" "Hand" "Object"]
        for stim = arrayfun(@(x) sprintf("%02d", x), 1:stims_per_category)
            % default to 3D view
            filename_left = sprintf("%s_%s_L.%s", category, stim, filetype);
            filename_right = sprintf("%s_%s_R.%s", category, stim, filetype);

            % if 2D, use two right eye views
            if view == "2D"
                filename_left = filename_right;
            end

            % increment ID
            ID = ID + 1;

            conditions{end+1,["ID" "View" "Category" "StimNum" "FilenameLeft" "FilenameRight"]} = [ID, view, category, stim, filename_left, filename_right];
        end
    end
end
%[text] Verify that all rows are unique
if height(unique(conditions, "rows")) ~= height(conditions)
    error("All rows must be unique in the condition table!")
end
%[text] Display for verification
disp(conditions)
%%
%[text] ## Create new columns with any combinations that will be used in counterblancing
%[text] e.g., combine "Category" (3 values) and "Task" (2 values) to create "Category x Task" (up to 6 values)
% create: View_x_Category
%   This variable has 6 unique values
conditions = GenericTrialCounterbalancer_CreateComboVariable(condition_table =      conditions, ...
                                                             variables_to_combine = ["View" "Category"] ...
                                                             );
%[text] Display for verification
disp(conditions)
%%
%[text] ## Initialize Rule Defaults
% note that first_condition_row is left NaN here, but will be set later for each participant/run
%
% also note that adding a rule but leaving the default constraints will still cause the generation to prioratize balancing that feature
%   e.g., adding a per-half rule but leaving the 0-inf default limits would
%   result in more balanced per-half counts even though there are no strict
%   limits set
rules = GenericTrialCounterbalancer_InitializeRules(condition_table =               conditions, ...
                                                    variables_with_order_rules =    ["View_x_Category"], ...
                                                    variables_with_perhalf_rules =  [], ...
                                                    first_condition_row =           nan ... % NaN = random first trial
                                                    );
%%
%[text] ## Overwrite the default order rules with desired limits
%[text] In the order effects matrices, the first dimension is the proceeding event and the second dimension is the following event. For example, the (1,2) cell corresponds to ID=1 being followed by ID=2.
%[text] 
%[text] (Optional) Check mapping of variable levels to matrix row/cols. The order is alphanumeric. Use GenericTrialCounterbalancer\_ConvertLabelsToIndices to verify.
% get lookup tables
[~, condition_labels_lookup] = GenericTrialCounterbalancer_ConvertLabelsToIndices(condition_table = conditions, ...
                                                                                  rules =           rules ...
                                                                                  );
% display the mapping of IDs to Category labels
disp(condition_labels_lookup.View_x_Category)
%[text] Overwrites
% View_x_Category: each combination follows itself exactly twice and follows each other combination 2-3 times per run
rules.order.View_x_Category.min(:) = 2;
rules.order.View_x_Category.max(:) = 3;
rules.order.View_x_Category.max(eye(length(rules.order.View_x_Category.max))==1) = 2; % set diagonal to 2 to limit repeats
%[text] Visualize for verification
value_range = [min(rules.order.View_x_Category.min(:)) max(rules.order.View_x_Category.max(:))];
labels = strrep(condition_labels_lookup.View_x_Category.Label, "_", "\_");
for type = ["Min" "Max"]
    figure
    imagesc(rules.order.View_x_Category.(lower(type)))
    title(type);
    axis square;
    cb = colorbar;
    clim(value_range); 
    set(cb, Ticks=value_range(1):value_range(end))
    set(gca, XAxisLocation="top", XTick=1:length(rules.order.View_x_Category.min), YTick=1:length(rules.order.View_x_Category.min), YTickLabels=labels, XTickLabels=labels, XTickLabelRotation=30)
end
%%
%[text] ## Overwrite the default per-half order rules with desired limits
%[text] Set the limits for the number of times that each variable level may occur in each half of each run.
% not used in this case, but an example is outlined below

% would need to first add "View_x_Category" to variables_with_perhalf_rules above

% % Each View_x_Category may occur 6-10 times (out of 16) in each half of each run
% rules.perhalfcount.View_x_Category.min = 6;
% rules.perhalfcount.View_x_Category.max = 10;
%%
%[text] ## Generate a test order
order = GenericTrialCounterbalancer_GenerateOrder(condition_table = conditions, ...
                                                  rules =           rules, ...
                                                  repetitions =     reps_per_stim ...
                                                  );
%%
%[text] ## (Sanity Check) Verify that any order effect rules were followed in the test order
%[text] Need the matrix order lookups first
[~, condition_labels_lookup] = GenericTrialCounterbalancer_ConvertLabelsToIndices(condition_table = conditions, ...
                                                                                  rules =           rules ...
                                                                                  );
%[text] Verify each rule and display the order effect matrix
% for each order effect rule...
for f = string(fields(rules.order)')
    % get the order of variable levels
    levels = conditions.(f)(order);

    % convert to numeric indices
    levels_IDs = arrayfun(@(x) find(condition_labels_lookup.(f).Label == x), levels);

    % create order effects matrix
    order_effects = zeros(size(rules.order.(f).min));

    % add each trial
    for trial = 2:length(levels_IDs)
        prior = levels_IDs(trial - 1);
        this = levels_IDs(trial);
        order_effects(prior, this) = order_effects(prior, this) + 1;
    end

    % verify that order_effects >= min
    if any(order_effects(:) < rules.order.(f).min(:))
        error("Failed to satisfy rules.order.%s.min", f)
    end

    % verify that order_effects <= max
    if any(order_effects(:) > rules.order.(f).max(:))
        error("Failed to satisfy rules.order.%s.max", f)
    end

    % display
    fprintf("Order effects table for %s:\n", f);
    disp(order_effects)
    imagesc(order_effects); axis square; colorbar; set(gca, XAxisLocation="top");
end
%%
%[text] ## (Sanity Check) Verify that any per-half-run count rules were followed in the test order
% how many trials are there?
trials_count = length(order);

% indices of first/second half
trials_midpoint = floor(trials_count / 2);
trials_halves = {1:trials_midpoint , (trials_midpoint+1):trials_count};

% for each per-half count rule...
names = ["First" "Last"];
for f = string(fields(rules.perhalfcount)')
    fprintf("Per-half-run counts for %s (%d-%d):\n", f, rules.perhalfcount.(f).min, rules.perhalfcount.(f).max);
    for half = 1:2
        % get the variabel levels
        levels = conditions.(f)(order(trials_halves{half}));

        % convert to numeric indices
        levels_IDs = arrayfun(@(x) find(condition_labels_lookup.(f).Label == x), levels);

        % count
        counts = arrayfun(@(x) sum(levels_IDs==x), 1:length(unique(conditions.(f))));

        % display
        fprintf("\t%s Half:\t%s\n", names(half), sprintf("%d ", counts));

        % check min/max
        if any(counts < rules.perhalfcount.(f).min)
            error("Failed to satisfy rules.perhalfcount.%s.min", f)
        elseif any(counts > rules.perhalfcount.(f).max)
            error("Failed to satisfy rules.perhalfcount.%s.max", f)
        end
    end
end
%%
%[text] # Start of order generation
%%
%[text] ## General Parameters (not counterbalancing)
participants_count = 30;
runs_count = 8;
folder = "..\Orders\";
overwrite = false; % if false, existing orders will be skipped

fixation = "On"; % On or Off

duration_baseline = 16;
duration_stim = 1;
duration_ITI_short = 3;
duration_ITI_long = 7;

ITI_long_count_per_half = 16;
%%
%[text] ## Predetermine the first View\_x\_Category for each participant-run
% get lookup tables
[conditions_indices, condition_labels_lookup] = GenericTrialCounterbalancer_ConvertLabelsToIndices( condition_table= conditions, ...
                                                                                                    rules=           rules ...
                                                                                                    );

% count the number of View_x_Category
count = height(condition_labels_lookup.View_x_Category);

% initialize
par_run_first_cond = nan(participants_count, runs_count);

% PART 1: populate the first 6 runs with a perfectly balanced selection...
%   -start with all permulations (720 for n=6)
%   -populate participants in groups of 6 such that each forms a balanced square (latin square with additional balancing for ordered pairs)
%   -selections are without replacement, i.e., each permuation can only be used once

% how many of these squares will be needed for the number of participants?
squares_needed = ceil(participants_count / count);

% use a fixed random number generator seed (1) so that the solution is replicable (unless the numbers change)
rng(1);

% generate the squares
%   -squares are 6x6 for the 6 main conditions (2D/3D x 3 categories)
%   -5 squares is exactly enough for 30 orders
%   -the "both" balance_mode is overkill (position would be fine), but it's fast to generate with square_size=6 so we might as well
%   -replacement=false means that every participant will have a unique order for first conditions
squares = GenerateBalancedSquares(square_size=count, square_count=squares_needed, balance_mode="both", replacement=false);

% convert the squares into the first 6 runs of each participant (30x6)
squares_stacked = cell2mat(arrayfun(@(x) squares(:,:,x), 1:size(squares,3), UniformOutput=false)');
par_run_first_cond(:,1:count) =  squares_stacked(1:participants_count, :);

% PART 2: fill in the remaining runs with random but balanced conditions
%   Avoid having having two sequential runs start with the same condition
while any(isnan(par_run_first_cond(:)))
    % start with current set rotated
    par_run_first_cond_temp = par_run_first_cond';

    % find next NaNs
    inds = find(isnan(par_run_first_cond_temp), count);

    % randomly assign conditions to those NaNs
    par_run_first_cond_temp(inds) = randperm(count, length(inds));

    % if no sequential runs start with same condition, then set this as the new par_run_first_cond
    d = diff(par_run_first_cond_temp, [], 1);
    if ~any(d(:) == 0)
        par_run_first_cond = par_run_first_cond_temp';
    end
end

% Convert to labels
par_run_first_cond = condition_labels_lookup.View_x_Category.Label(par_run_first_cond);

% display
fprintf("Par x Run order of first main conditions:\n");
disp(par_run_first_cond);
%%
%[text] ## Make Output Folder
% convert slashes to OS file separator
folder = folder.replace("/",filesep).replace("\",filesep);

% folder must end with file separator
if ~folder.endsWith(filesep)
    folder = folder + filesep;
end

% create folder if needed
if ~exist(folder, "dir")
    mkdir(folder);
end

% display
fprintf("Orders will be written to: %s\n", folder);
%%
%[text] ## Generate Orders
% use a fixed random number generator seed (1) so that the solution is replicable (unless any values or rules change)
rng(1);

% 
for par = 1:participants_count
    fprintf("Participant %d of %d:\n", par, participants_count);
    for run = 1:runs_count
        fprintf("\tRun %d of %d:\n", run, runs_count);

        % filepath
        filepath = folder + sprintf("PAR%02d_RUN%02d.xlsx", par, run);
        if exist(filepath, "file")
            if overwrite
                fprintf("\t\tDeleting prior file: %s\n", filepath);
                delete(filepath);
            else
                fprintf("\t\tFile already exists and overwrite=false, skipping this run!\n");
                continue;
            end
        end

        % which main condition will be first?
        first_main_cond = par_run_first_cond(par, run);

        % randomly select a trial from this condition
        rows = find(conditions.View_x_Category == first_main_cond);
        row = randsample(repmat(rows(:), [2 1]), 1);

        % set first trial
        rules.first_condition_index = row;

        % generate base trial order
        trial_order = GenericTrialCounterbalancer_GenerateOrder(condition_table= conditions, ...
                                                                rules=           rules, ...
                                                                repetitions=     reps_per_stim, ...
                                                                fprintf_prefix=  sprintf("\t\t") ...
                                                                );
        
        % add a one-back trial in each half with at least 5 trials between them
        trials_count = length(trial_order);
        midpoint = floor(trials_count/2);
        while 1
            inds_one_back = [randperm(midpoint, 1) (randperm(trials_count-midpoint, 1) + midpoint)];
            if diff(inds_one_back) >= 5
                break
            end
        end
        fprintf("\t\tAdding one-backs to trial IDs [%s] at positions [%s]\n", strjoin(string(trial_order(inds_one_back)), " "), strjoin(string(inds_one_back), " "));
        for ind = sort(inds_one_back, "descend")
            trial_order(ind+1:end+1) = trial_order(ind:end);
        end

        % randomly assign ITIs such that:
        %   -32 trials have 7sec ITI, 16 in each half
        %   -The other 66 trials have 3sec ITI (inherently 33 in each half)
        %   -Each of the 6 main conditions has at least 5 of the longer ITI
        %       (remaining 2 are randomly distributed)
        trials_condition = conditions_indices.View_x_Category(trial_order);
        trials_count = length(trial_order);
        midpoint = floor(trials_count/2);
        while 1
            % randomly select 16 trials in each half
            inds_long_ITI = sort([randperm(midpoint, ITI_long_count_per_half) (randperm(trials_count-midpoint, ITI_long_count_per_half) + midpoint)]);

            % if each main condition has at least 5 long ITI, then accept this selection
            if all(histcounts(trials_condition(inds_long_ITI), BinMethod="integers") >= 5)
                break;
            end
        end
        fprintf("\t\t%d long ITIs in trials: %s\n", length(inds_long_ITI), strjoin(string(inds_long_ITI), " "));

        % generate run's trial table with ITI duration and IsRepeat
        conditions_run = conditions(trial_order, :);
        conditions_run.ITI(:) = duration_ITI_short;
        conditions_run.ITI(inds_long_ITI) = duration_ITI_long;
        conditions_run.IsRepeat = [false; conditions_run.ID(1:end-1) == conditions_run.ID(2:end)];

        % organize for experiment script
        number_rows = 2 + (trials_count * 2);
        vars = ["Trial"             "double"
                "Condition"         "string"
                "Duration_Seconds"  "double"
                "Filename_left"     "string"
                "Filename_right"    "string"
                "Format"            "string"
                "Is_repeat"	        "logical"
                "Motion"            "string"
            	"Fixation"          "string"
                "Display"           "string"
                "Category"          "string"
            	"Stim"              "string"];
        xlsx = table(Size=[number_rows size(vars,1)], VariableNames=vars(:,1), VariableTypes=vars(:,2));
        % initial baseline
        row = 1;
        xlsx(row, :) = {0 "NULL" duration_baseline "" "" "NULL" false "" fixation "" "" 0};
        % trials
        for trial = 1:trials_count
            % stim
            row = row + 1;
            xlsx.Trial(row) = trial;
            xlsx.Condition(row) = conditions_run.View_x_Category(trial);
            xlsx.Duration_Seconds(row) = duration_stim;
            xlsx.Filename_left(row) = conditions_run.FilenameLeft(trial);
            xlsx.Filename_right(row) = conditions_run.FilenameRight(trial);
            xlsx.Format(row) = "image";
            xlsx.Is_repeat(row) = conditions_run.IsRepeat(trial);
            xlsx.Motion(row) = "";
            xlsx.Fixation(row) = fixation;
            xlsx.Display(row) = conditions_run.View(trial);
            xlsx.Category(row) = conditions_run.Category(trial);
            xlsx.Stim(row) = conditions_run.StimNum(trial);

            % ITI
            row = row + 1;
            xlsx(row, :) = {trial "NULL" conditions_run.ITI(trial) "" "" "NULL" false "" fixation "" "" 0};
        end
        % final baseline
        row = row + 1;
        xlsx(row, :) = {0 "NULL" duration_baseline "" "" "NULL" false "" fixation "" "" 0};

        % write
        fprintf("\t\tWriting: %s\n", filepath);
        writetable(xlsx, filepath);
    end
end

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":34.5}
%---
