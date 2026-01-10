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
disp(conditions) %[output:7640c753]
%%
%[text] ## Create new columns with any combinations that will be used in counterblancing
%[text] e.g., combine "Category" (3 values) and "Task" (2 values) to create "Category x Task" (up to 6 values)
% create: View_x_Category
%   This variable has 6 unique values
conditions = GenericTrialCounterbalancer_CreateComboVariable(condition_table =      conditions, ... %[output:group:2a77ddb1] %[output:3ab1bf76]
                                                             variables_to_combine = ["View" "Category"] ... %[output:3ab1bf76]
                                                             ); %[output:group:2a77ddb1] %[output:3ab1bf76]
%[text] Display for verification
disp(conditions) %[output:7ceb95e9]
%%
%[text] ## Initialize Rule Defaults
% note that first_condition_row is left NaN here, but will be set later for each participant/run
%
% also note that adding a rule but leaving the default constraints will still cause the generation to prioratize balancing that feature
%   e.g., adding a per-half rule but leaving the 0-inf default limits would
%   result in more balanced per-half counts even though there are no strict
%   limits set
rules = GenericTrialCounterbalancer_InitializeRules(condition_table =               conditions, ... %[output:group:91bbd7c3] %[output:547711d6]
                                                    variables_with_order_rules =    ["View_x_Category"], ... %[output:547711d6]
                                                    variables_with_perhalf_rules =  [], ... %[output:547711d6]
                                                    first_condition_row =           nan ... % NaN = random first trial %[output:547711d6]
                                                    ); %[output:group:91bbd7c3] %[output:547711d6]
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
disp(condition_labels_lookup.View_x_Category) %[output:97987fba]
%[text] Overwrites
% View_x_Category: each combination follows itself exactly twice and follows each other combination 2-3 times per run
rules.order.View_x_Category.min(:) = 2;
rules.order.View_x_Category.max(:) = 3;
rules.order.View_x_Category.max(eye(length(rules.order.View_x_Category.max))==1) = 2; % set diagonal to 2 to limit repeats
%[text] Visualize for verification
value_range = [min(rules.order.View_x_Category.min(:)) max(rules.order.View_x_Category.max(:))];
labels = strrep(condition_labels_lookup.View_x_Category.Label, "_", "\_");
for type = ["Min" "Max"] %[output:group:57413933]
    figure %[output:2ecebbee] %[output:471d3463]
    imagesc(rules.order.View_x_Category.(lower(type))) %[output:2ecebbee] %[output:471d3463]
    title(type);
    axis square;
    cb = colorbar;
    clim(value_range); 
    set(cb, Ticks=value_range(1):value_range(end))
    set(gca, XAxisLocation="top", XTick=1:length(rules.order.View_x_Category.min), YTick=1:length(rules.order.View_x_Category.min), YTickLabels=labels, XTickLabels=labels, XTickLabelRotation=30)
end %[output:group:57413933]
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
order = GenericTrialCounterbalancer_GenerateOrder(condition_table = conditions, ... %[output:group:2e4428d1] %[output:075ee2ce]
                                                  rules =           rules, ... %[output:075ee2ce]
                                                  repetitions =     reps_per_stim ... %[output:075ee2ce]
                                                  ); %[output:group:2e4428d1] %[output:075ee2ce]
%%
%[text] ## (Sanity Check) Verify that any order effect rules were followed in the test order
%[text] Need the matrix order lookups first
[~, condition_labels_lookup] = GenericTrialCounterbalancer_ConvertLabelsToIndices(condition_table = conditions, ...
                                                                                  rules =           rules ...
                                                                                  );
%[text] Verify each rule and display the order effect matrix
% for each order effect rule...
for f = string(fields(rules.order)') %[output:group:6722abea]
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
    fprintf("Order effects table for %s:\n", f); %[output:78dd0835]
    disp(order_effects) %[output:5faf67b1]
    imagesc(order_effects); axis square; colorbar; set(gca, XAxisLocation="top"); %[output:2a1da4de]
end %[output:group:6722abea]
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
squares = GenerateBalancedSquares(square_size=count, square_count=squares_needed, balance_mode="both", replacement=false); %[output:57ddf0e4]

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
fprintf("Par x Run order of first main conditions:\n"); %[output:6b2dc679]
disp(par_run_first_cond); %[output:189567f7]
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
fprintf("Orders will be written to: %s\n", folder); %[output:1ee9e075]
%%
%[text] ## Generate Orders
% use a fixed random number generator seed (1) so that the solution is replicable (unless any values or rules change)
rng(1);

% 
for par = 1:participants_count %[output:group:68aeb0c9]
    fprintf("Participant %d of %d:\n", par, participants_count); %[output:66913520] %[output:50520a15] %[output:757abf16] %[output:7222a736] %[output:95b79e57] %[output:60d97b2b] %[output:92ff5336] %[output:66c102cd] %[output:24bad6d0] %[output:44cdaad3] %[output:1db82714] %[output:12d1bec8] %[output:9a410260] %[output:2e2c0a72] %[output:55f084fa] %[output:8cbac861] %[output:21cad4cb] %[output:34f69694] %[output:800e3afa] %[output:068104a5] %[output:781d8635] %[output:8b1e2628] %[output:94e52f39] %[output:4570e1da] %[output:45f1e946] %[output:6208e189] %[output:699909ec] %[output:0347b1fa] %[output:2865d67d] %[output:5435d570]
    for run = 1:runs_count
        fprintf("\tRun %d of %d:\n", run, runs_count); %[output:375cf1ce] %[output:30d2e960] %[output:84299a1d] %[output:3f48b22a] %[output:320f16ca] %[output:11ee3fda] %[output:3f9e0825] %[output:703ec7f2] %[output:43e9c8ec] %[output:67c9e20a] %[output:802421e3] %[output:08af38e1] %[output:1f2cd5b7] %[output:8eae8d5c] %[output:8481fe07] %[output:96ab6e10] %[output:6fe1c95a] %[output:39a880c5] %[output:169c9065] %[output:0cfa323f] %[output:666781a6] %[output:630f4c7c] %[output:5b71544d] %[output:4b3530e1] %[output:474f4337] %[output:361d7928] %[output:9bfa6aa5] %[output:9bd17de8] %[output:9e479b3c] %[output:40c44ab9] %[output:8f2271a6] %[output:66a07890] %[output:3f5542f4] %[output:88645d49] %[output:212297d1] %[output:3b471d91] %[output:60f2b4e1] %[output:7da400eb] %[output:22346866] %[output:9365484a] %[output:4c92549b] %[output:062f495c] %[output:296a9368] %[output:34fac3aa] %[output:0cbfcf2a] %[output:5bbc4c11] %[output:46da00a1] %[output:4c2b92a6] %[output:96c1b0dd] %[output:62bbcacb] %[output:8342a175] %[output:93e24dec] %[output:1ca246a9] %[output:84344af6] %[output:400f37a2] %[output:1b767390] %[output:0f630e43] %[output:0c446d63] %[output:5a67b98a] %[output:382548ce] %[output:7c15dc17] %[output:865597fd] %[output:3a03562b] %[output:44cc7297] %[output:33ea87bf] %[output:64ef76b4] %[output:94764bb4] %[output:383887a1] %[output:7d365758] %[output:53909485] %[output:83157024] %[output:7e2fd1eb] %[output:35b5c0f0] %[output:60af5dd0] %[output:677d0940] %[output:3accfed8] %[output:69367e27] %[output:0915ced1] %[output:57d35a31] %[output:34fd0d58] %[output:1cfc9dd2] %[output:9f7db0a4] %[output:0f5690cf] %[output:70120cb2] %[output:95d070e6] %[output:625b8334] %[output:9c5da4ef] %[output:6f438208] %[output:7cbf2c80] %[output:8c8cd47a] %[output:155bce60] %[output:01361207] %[output:4d595b81] %[output:4ece0539] %[output:90bbf693] %[output:92b78ac4] %[output:477e5e73] %[output:0e8b36bc] %[output:9b1678b8] %[output:8b8b7e17] %[output:0ab67d32] %[output:99621b7d] %[output:9adbf5da] %[output:06ab7e28] %[output:3b00ad3a] %[output:2490f7ff] %[output:566ef83d] %[output:06dc6802] %[output:22011a27] %[output:2a690c37] %[output:03d9a5bc] %[output:4327ac5a] %[output:400a54da] %[output:6ad97823] %[output:80048932] %[output:7577ff64] %[output:704be9e7] %[output:2e05108d] %[output:6fb025df] %[output:31f2140c] %[output:79d0b9d0] %[output:79c39fee] %[output:8c7c488f] %[output:3222ca79] %[output:58b66e10] %[output:197fc0fb] %[output:62ce4394] %[output:00c250af] %[output:0ca0a8dd] %[output:0d06a180] %[output:74ff626c] %[output:488539b0] %[output:1cf9ae61] %[output:3e269db4] %[output:81cf4bb5] %[output:16bf8db3] %[output:2ceb601a] %[output:26ed917e] %[output:21bc0a16] %[output:573df5db] %[output:5165cb18] %[output:0c3385db] %[output:0f2f33da] %[output:7800db28] %[output:8f239aa9] %[output:117a3d40] %[output:2e755fa2] %[output:1ee04461] %[output:173f42f2] %[output:30bc1715] %[output:952206a1] %[output:892a88fd] %[output:814df403] %[output:136f55c1] %[output:46ac79aa] %[output:92c0389d] %[output:8b5216d3] %[output:9fa27244] %[output:81d7eb9f] %[output:3f5b5fb2] %[output:443b684f] %[output:3e7b065b] %[output:8c790f62] %[output:5e60f64c] %[output:0f81f65c] %[output:989aed57] %[output:6e6cbed4] %[output:2aeb734b] %[output:8a0aa71d] %[output:5a49876f] %[output:38fcdb31] %[output:67af97f3] %[output:0ee37845] %[output:19e5812b] %[output:80359588] %[output:28c39d45] %[output:31c73d31] %[output:4cc4a47c] %[output:838959ac] %[output:3b140c05] %[output:301b5343] %[output:11a080e7] %[output:8bcb48dd] %[output:7c6d4614] %[output:55c85944] %[output:8b998a88] %[output:5242d09e] %[output:7e3fccb7] %[output:6769a0b2] %[output:823a12a9] %[output:581b77c7] %[output:68bec040] %[output:45f9262a] %[output:9b7daaa0] %[output:4cdea382] %[output:50330406] %[output:4e2498c0] %[output:7f67574f] %[output:3dcc3654] %[output:0ed7fe5a] %[output:8a054ca9] %[output:629319d6] %[output:9797549b] %[output:34825f73] %[output:442df5dd] %[output:26a8d68e] %[output:21ef92f2] %[output:346c18fe] %[output:679898f5] %[output:42951761] %[output:7cd24134] %[output:4266dc4d] %[output:650dd670] %[output:224eac73] %[output:1ec5d34e] %[output:98549a8a] %[output:666def18] %[output:78e5a181] %[output:88b41e35] %[output:8688e69a] %[output:26c5afb5] %[output:6aba5cec] %[output:51ff4ef0] %[output:61208a58] %[output:25b3aa64] %[output:8b171040] %[output:25310801] %[output:0780d9e2] %[output:95cb39c0] %[output:4e7688e3] %[output:352905a5] %[output:422790aa] %[output:86e64f6f] %[output:82884503] %[output:8abd3a85] %[output:260130c9] %[output:760eed64] %[output:5ab0d9ed] %[output:56480ebb] %[output:8d76315c]

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
        trial_order = GenericTrialCounterbalancer_GenerateOrder(condition_table= conditions, ... %[output:1e22fb87] %[output:673cf78d] %[output:278f4cc0] %[output:6d73aa74] %[output:16a3e2d9] %[output:9e7f3753] %[output:47b5c823] %[output:17271fde] %[output:85acbb24] %[output:46ad78bf] %[output:9f9bb2ea] %[output:18b3e7b1] %[output:4498ca17] %[output:440e7d45] %[output:1fa33165] %[output:5bb902cf] %[output:673cd2f3] %[output:026d7706] %[output:96e50272] %[output:39e415d6] %[output:492c8d41] %[output:5f08ee56] %[output:98ed7f6a] %[output:68b12fb9] %[output:262f856d] %[output:9c5b1d19] %[output:047952c1] %[output:5ef4efe9] %[output:0d6fb69f] %[output:12e0e429] %[output:11287cce] %[output:6cc1cf24] %[output:40e24324] %[output:5df7d321] %[output:18bfb18d] %[output:5add4211] %[output:2c955740] %[output:98b5a3e2] %[output:67a7d6e9] %[output:8ca32cc1] %[output:2315b209] %[output:709e56b3] %[output:66b2b681] %[output:52a0fa2e] %[output:084d9d7d] %[output:6fa00275] %[output:4a36928c] %[output:88fb6b34] %[output:49ddfe54] %[output:0ef0be3d] %[output:8afb4722] %[output:40d53963] %[output:010cb6ff] %[output:2a336eb8] %[output:638969f4] %[output:8d7fe342] %[output:9300224d] %[output:2a222a20] %[output:28970bc5] %[output:5757096e] %[output:27d1c118] %[output:7139e4b6] %[output:31fbe3b7] %[output:7a33df34] %[output:483acdbc] %[output:4883ca4d] %[output:48df3ad5] %[output:6a071c77] %[output:49204fda] %[output:157679b7] %[output:426de9c3] %[output:6f944c28] %[output:6f43b99b] %[output:1fd79296] %[output:46828745] %[output:6d331cb3] %[output:643f9863] %[output:8e71bd2f] %[output:524cdd2f] %[output:624f6a14] %[output:6806e70d] %[output:66b49db0] %[output:563f64e5] %[output:5e823541] %[output:167a22bc] %[output:046610a1] %[output:645cd71d] %[output:70c09e0e] %[output:8c45965e] %[output:44f75939] %[output:411a50b7] %[output:87c05ce5] %[output:70600b36] %[output:2469f354] %[output:05c5dd03] %[output:6934fb8c] %[output:04bf898d] %[output:96be1319] %[output:90e822c4] %[output:2266e701] %[output:42925741] %[output:34efaf41] %[output:611d47e3] %[output:94792f17] %[output:12d7d6c4] %[output:28c47be2] %[output:77aabf22] %[output:44e63ea7] %[output:2d032691] %[output:9835a591] %[output:1740300f] %[output:725e211e] %[output:203cc677] %[output:6e986856] %[output:022abd85] %[output:9a082496] %[output:20e556cf] %[output:77bcd5ad] %[output:24d139a6] %[output:80defc8c] %[output:902539eb] %[output:421ce65f] %[output:60d30f52] %[output:4fe9b5b6] %[output:170808b7] %[output:873f4419] %[output:88b600dd] %[output:009b6121] %[output:1bc17f05] %[output:0dd5ccf0] %[output:8dfc0eae] %[output:28daf2ba] %[output:68c79f00] %[output:5ba5258a] %[output:14f4fe8d] %[output:2dcf86e5] %[output:36dad286] %[output:25fd4f59] %[output:19b44d7b] %[output:20524376] %[output:9ea0e82f] %[output:049f8c96] %[output:122f8a42] %[output:1a4fc085] %[output:458a683a] %[output:4acff999] %[output:0228c55e] %[output:3ce53fc9] %[output:539c5e83] %[output:6fb5fe06] %[output:87b404fd] %[output:77ec8ac0] %[output:78caa61f] %[output:0b033176] %[output:469baac7] %[output:5a4537d3] %[output:68ed0d31] %[output:4a623892] %[output:7acb9bb5] %[output:944573db] %[output:4f3ac1cb] %[output:9d615d7f] %[output:1593b43a] %[output:8a96c490] %[output:7554bd72] %[output:6d7b7192] %[output:1aa21c53] %[output:44deb5ab] %[output:39eda95b] %[output:9a39aa75] %[output:84735522] %[output:2f323f95] %[output:081f663c] %[output:96befcc3] %[output:99f54f84] %[output:06ced321] %[output:8b9e6e85] %[output:0c325270] %[output:259daf64] %[output:6bca1872] %[output:0602738a] %[output:4648b4b5] %[output:6d0016a3] %[output:7b673f0a] %[output:7b86dff2] %[output:84191c8d] %[output:0f50aae4] %[output:5f732d26] %[output:8a1dc187] %[output:54f83e0f] %[output:246ff07c] %[output:72bf059e] %[output:2ef136f1] %[output:0722ac6a] %[output:729cc3b5] %[output:8f946bd3] %[output:7f5e8e1f] %[output:3a91e388] %[output:48c38a17] %[output:52000d27] %[output:7530f86d] %[output:0ebd3723] %[output:1ecc6095] %[output:513ee371] %[output:90dac9a5] %[output:1b08779a] %[output:04bc407c] %[output:21100036] %[output:54f908c4] %[output:5482935a] %[output:3402654b] %[output:1a83025b] %[output:638fcab3] %[output:037456ad] %[output:7157e9c8] %[output:9b141338] %[output:5759cd56] %[output:51fbf084] %[output:54dae793] %[output:8f697b37] %[output:5cceaa4c] %[output:0f254b53] %[output:82207855] %[output:3a173ddd] %[output:2d81fbde] %[output:770fc2b7] %[output:4f82aab2] %[output:357320f6] %[output:134b9194] %[output:7395f145] %[output:4218d912] %[output:2c99d37d] %[output:126ea433] %[output:241e526f] %[output:0ae87b4d] %[output:5ee31460] %[output:8d6e632d] %[output:02035592] %[output:8a9bf27d] %[output:6439db60]
                                                                rules=           rules, ... %[output:1e22fb87] %[output:673cf78d] %[output:278f4cc0] %[output:6d73aa74] %[output:16a3e2d9] %[output:9e7f3753] %[output:47b5c823] %[output:17271fde] %[output:85acbb24] %[output:46ad78bf] %[output:9f9bb2ea] %[output:18b3e7b1] %[output:4498ca17] %[output:440e7d45] %[output:1fa33165] %[output:5bb902cf] %[output:673cd2f3] %[output:026d7706] %[output:96e50272] %[output:39e415d6] %[output:492c8d41] %[output:5f08ee56] %[output:98ed7f6a] %[output:68b12fb9] %[output:262f856d] %[output:9c5b1d19] %[output:047952c1] %[output:5ef4efe9] %[output:0d6fb69f] %[output:12e0e429] %[output:11287cce] %[output:6cc1cf24] %[output:40e24324] %[output:5df7d321] %[output:18bfb18d] %[output:5add4211] %[output:2c955740] %[output:98b5a3e2] %[output:67a7d6e9] %[output:8ca32cc1] %[output:2315b209] %[output:709e56b3] %[output:66b2b681] %[output:52a0fa2e] %[output:084d9d7d] %[output:6fa00275] %[output:4a36928c] %[output:88fb6b34] %[output:49ddfe54] %[output:0ef0be3d] %[output:8afb4722] %[output:40d53963] %[output:010cb6ff] %[output:2a336eb8] %[output:638969f4] %[output:8d7fe342] %[output:9300224d] %[output:2a222a20] %[output:28970bc5] %[output:5757096e] %[output:27d1c118] %[output:7139e4b6] %[output:31fbe3b7] %[output:7a33df34] %[output:483acdbc] %[output:4883ca4d] %[output:48df3ad5] %[output:6a071c77] %[output:49204fda] %[output:157679b7] %[output:426de9c3] %[output:6f944c28] %[output:6f43b99b] %[output:1fd79296] %[output:46828745] %[output:6d331cb3] %[output:643f9863] %[output:8e71bd2f] %[output:524cdd2f] %[output:624f6a14] %[output:6806e70d] %[output:66b49db0] %[output:563f64e5] %[output:5e823541] %[output:167a22bc] %[output:046610a1] %[output:645cd71d] %[output:70c09e0e] %[output:8c45965e] %[output:44f75939] %[output:411a50b7] %[output:87c05ce5] %[output:70600b36] %[output:2469f354] %[output:05c5dd03] %[output:6934fb8c] %[output:04bf898d] %[output:96be1319] %[output:90e822c4] %[output:2266e701] %[output:42925741] %[output:34efaf41] %[output:611d47e3] %[output:94792f17] %[output:12d7d6c4] %[output:28c47be2] %[output:77aabf22] %[output:44e63ea7] %[output:2d032691] %[output:9835a591] %[output:1740300f] %[output:725e211e] %[output:203cc677] %[output:6e986856] %[output:022abd85] %[output:9a082496] %[output:20e556cf] %[output:77bcd5ad] %[output:24d139a6] %[output:80defc8c] %[output:902539eb] %[output:421ce65f] %[output:60d30f52] %[output:4fe9b5b6] %[output:170808b7] %[output:873f4419] %[output:88b600dd] %[output:009b6121] %[output:1bc17f05] %[output:0dd5ccf0] %[output:8dfc0eae] %[output:28daf2ba] %[output:68c79f00] %[output:5ba5258a] %[output:14f4fe8d] %[output:2dcf86e5] %[output:36dad286] %[output:25fd4f59] %[output:19b44d7b] %[output:20524376] %[output:9ea0e82f] %[output:049f8c96] %[output:122f8a42] %[output:1a4fc085] %[output:458a683a] %[output:4acff999] %[output:0228c55e] %[output:3ce53fc9] %[output:539c5e83] %[output:6fb5fe06] %[output:87b404fd] %[output:77ec8ac0] %[output:78caa61f] %[output:0b033176] %[output:469baac7] %[output:5a4537d3] %[output:68ed0d31] %[output:4a623892] %[output:7acb9bb5] %[output:944573db] %[output:4f3ac1cb] %[output:9d615d7f] %[output:1593b43a] %[output:8a96c490] %[output:7554bd72] %[output:6d7b7192] %[output:1aa21c53] %[output:44deb5ab] %[output:39eda95b] %[output:9a39aa75] %[output:84735522] %[output:2f323f95] %[output:081f663c] %[output:96befcc3] %[output:99f54f84] %[output:06ced321] %[output:8b9e6e85] %[output:0c325270] %[output:259daf64] %[output:6bca1872] %[output:0602738a] %[output:4648b4b5] %[output:6d0016a3] %[output:7b673f0a] %[output:7b86dff2] %[output:84191c8d] %[output:0f50aae4] %[output:5f732d26] %[output:8a1dc187] %[output:54f83e0f] %[output:246ff07c] %[output:72bf059e] %[output:2ef136f1] %[output:0722ac6a] %[output:729cc3b5] %[output:8f946bd3] %[output:7f5e8e1f] %[output:3a91e388] %[output:48c38a17] %[output:52000d27] %[output:7530f86d] %[output:0ebd3723] %[output:1ecc6095] %[output:513ee371] %[output:90dac9a5] %[output:1b08779a] %[output:04bc407c] %[output:21100036] %[output:54f908c4] %[output:5482935a] %[output:3402654b] %[output:1a83025b] %[output:638fcab3] %[output:037456ad] %[output:7157e9c8] %[output:9b141338] %[output:5759cd56] %[output:51fbf084] %[output:54dae793] %[output:8f697b37] %[output:5cceaa4c] %[output:0f254b53] %[output:82207855] %[output:3a173ddd] %[output:2d81fbde] %[output:770fc2b7] %[output:4f82aab2] %[output:357320f6] %[output:134b9194] %[output:7395f145] %[output:4218d912] %[output:2c99d37d] %[output:126ea433] %[output:241e526f] %[output:0ae87b4d] %[output:5ee31460] %[output:8d6e632d] %[output:02035592] %[output:8a9bf27d] %[output:6439db60]
                                                                repetitions=     reps_per_stim, ... %[output:1e22fb87] %[output:673cf78d] %[output:278f4cc0] %[output:6d73aa74] %[output:16a3e2d9] %[output:9e7f3753] %[output:47b5c823] %[output:17271fde] %[output:85acbb24] %[output:46ad78bf] %[output:9f9bb2ea] %[output:18b3e7b1] %[output:4498ca17] %[output:440e7d45] %[output:1fa33165] %[output:5bb902cf] %[output:673cd2f3] %[output:026d7706] %[output:96e50272] %[output:39e415d6] %[output:492c8d41] %[output:5f08ee56] %[output:98ed7f6a] %[output:68b12fb9] %[output:262f856d] %[output:9c5b1d19] %[output:047952c1] %[output:5ef4efe9] %[output:0d6fb69f] %[output:12e0e429] %[output:11287cce] %[output:6cc1cf24] %[output:40e24324] %[output:5df7d321] %[output:18bfb18d] %[output:5add4211] %[output:2c955740] %[output:98b5a3e2] %[output:67a7d6e9] %[output:8ca32cc1] %[output:2315b209] %[output:709e56b3] %[output:66b2b681] %[output:52a0fa2e] %[output:084d9d7d] %[output:6fa00275] %[output:4a36928c] %[output:88fb6b34] %[output:49ddfe54] %[output:0ef0be3d] %[output:8afb4722] %[output:40d53963] %[output:010cb6ff] %[output:2a336eb8] %[output:638969f4] %[output:8d7fe342] %[output:9300224d] %[output:2a222a20] %[output:28970bc5] %[output:5757096e] %[output:27d1c118] %[output:7139e4b6] %[output:31fbe3b7] %[output:7a33df34] %[output:483acdbc] %[output:4883ca4d] %[output:48df3ad5] %[output:6a071c77] %[output:49204fda] %[output:157679b7] %[output:426de9c3] %[output:6f944c28] %[output:6f43b99b] %[output:1fd79296] %[output:46828745] %[output:6d331cb3] %[output:643f9863] %[output:8e71bd2f] %[output:524cdd2f] %[output:624f6a14] %[output:6806e70d] %[output:66b49db0] %[output:563f64e5] %[output:5e823541] %[output:167a22bc] %[output:046610a1] %[output:645cd71d] %[output:70c09e0e] %[output:8c45965e] %[output:44f75939] %[output:411a50b7] %[output:87c05ce5] %[output:70600b36] %[output:2469f354] %[output:05c5dd03] %[output:6934fb8c] %[output:04bf898d] %[output:96be1319] %[output:90e822c4] %[output:2266e701] %[output:42925741] %[output:34efaf41] %[output:611d47e3] %[output:94792f17] %[output:12d7d6c4] %[output:28c47be2] %[output:77aabf22] %[output:44e63ea7] %[output:2d032691] %[output:9835a591] %[output:1740300f] %[output:725e211e] %[output:203cc677] %[output:6e986856] %[output:022abd85] %[output:9a082496] %[output:20e556cf] %[output:77bcd5ad] %[output:24d139a6] %[output:80defc8c] %[output:902539eb] %[output:421ce65f] %[output:60d30f52] %[output:4fe9b5b6] %[output:170808b7] %[output:873f4419] %[output:88b600dd] %[output:009b6121] %[output:1bc17f05] %[output:0dd5ccf0] %[output:8dfc0eae] %[output:28daf2ba] %[output:68c79f00] %[output:5ba5258a] %[output:14f4fe8d] %[output:2dcf86e5] %[output:36dad286] %[output:25fd4f59] %[output:19b44d7b] %[output:20524376] %[output:9ea0e82f] %[output:049f8c96] %[output:122f8a42] %[output:1a4fc085] %[output:458a683a] %[output:4acff999] %[output:0228c55e] %[output:3ce53fc9] %[output:539c5e83] %[output:6fb5fe06] %[output:87b404fd] %[output:77ec8ac0] %[output:78caa61f] %[output:0b033176] %[output:469baac7] %[output:5a4537d3] %[output:68ed0d31] %[output:4a623892] %[output:7acb9bb5] %[output:944573db] %[output:4f3ac1cb] %[output:9d615d7f] %[output:1593b43a] %[output:8a96c490] %[output:7554bd72] %[output:6d7b7192] %[output:1aa21c53] %[output:44deb5ab] %[output:39eda95b] %[output:9a39aa75] %[output:84735522] %[output:2f323f95] %[output:081f663c] %[output:96befcc3] %[output:99f54f84] %[output:06ced321] %[output:8b9e6e85] %[output:0c325270] %[output:259daf64] %[output:6bca1872] %[output:0602738a] %[output:4648b4b5] %[output:6d0016a3] %[output:7b673f0a] %[output:7b86dff2] %[output:84191c8d] %[output:0f50aae4] %[output:5f732d26] %[output:8a1dc187] %[output:54f83e0f] %[output:246ff07c] %[output:72bf059e] %[output:2ef136f1] %[output:0722ac6a] %[output:729cc3b5] %[output:8f946bd3] %[output:7f5e8e1f] %[output:3a91e388] %[output:48c38a17] %[output:52000d27] %[output:7530f86d] %[output:0ebd3723] %[output:1ecc6095] %[output:513ee371] %[output:90dac9a5] %[output:1b08779a] %[output:04bc407c] %[output:21100036] %[output:54f908c4] %[output:5482935a] %[output:3402654b] %[output:1a83025b] %[output:638fcab3] %[output:037456ad] %[output:7157e9c8] %[output:9b141338] %[output:5759cd56] %[output:51fbf084] %[output:54dae793] %[output:8f697b37] %[output:5cceaa4c] %[output:0f254b53] %[output:82207855] %[output:3a173ddd] %[output:2d81fbde] %[output:770fc2b7] %[output:4f82aab2] %[output:357320f6] %[output:134b9194] %[output:7395f145] %[output:4218d912] %[output:2c99d37d] %[output:126ea433] %[output:241e526f] %[output:0ae87b4d] %[output:5ee31460] %[output:8d6e632d] %[output:02035592] %[output:8a9bf27d] %[output:6439db60]
                                                                fprintf_prefix=  sprintf("\t\t") ... %[output:1e22fb87] %[output:673cf78d] %[output:278f4cc0] %[output:6d73aa74] %[output:16a3e2d9] %[output:9e7f3753] %[output:47b5c823] %[output:17271fde] %[output:85acbb24] %[output:46ad78bf] %[output:9f9bb2ea] %[output:18b3e7b1] %[output:4498ca17] %[output:440e7d45] %[output:1fa33165] %[output:5bb902cf] %[output:673cd2f3] %[output:026d7706] %[output:96e50272] %[output:39e415d6] %[output:492c8d41] %[output:5f08ee56] %[output:98ed7f6a] %[output:68b12fb9] %[output:262f856d] %[output:9c5b1d19] %[output:047952c1] %[output:5ef4efe9] %[output:0d6fb69f] %[output:12e0e429] %[output:11287cce] %[output:6cc1cf24] %[output:40e24324] %[output:5df7d321] %[output:18bfb18d] %[output:5add4211] %[output:2c955740] %[output:98b5a3e2] %[output:67a7d6e9] %[output:8ca32cc1] %[output:2315b209] %[output:709e56b3] %[output:66b2b681] %[output:52a0fa2e] %[output:084d9d7d] %[output:6fa00275] %[output:4a36928c] %[output:88fb6b34] %[output:49ddfe54] %[output:0ef0be3d] %[output:8afb4722] %[output:40d53963] %[output:010cb6ff] %[output:2a336eb8] %[output:638969f4] %[output:8d7fe342] %[output:9300224d] %[output:2a222a20] %[output:28970bc5] %[output:5757096e] %[output:27d1c118] %[output:7139e4b6] %[output:31fbe3b7] %[output:7a33df34] %[output:483acdbc] %[output:4883ca4d] %[output:48df3ad5] %[output:6a071c77] %[output:49204fda] %[output:157679b7] %[output:426de9c3] %[output:6f944c28] %[output:6f43b99b] %[output:1fd79296] %[output:46828745] %[output:6d331cb3] %[output:643f9863] %[output:8e71bd2f] %[output:524cdd2f] %[output:624f6a14] %[output:6806e70d] %[output:66b49db0] %[output:563f64e5] %[output:5e823541] %[output:167a22bc] %[output:046610a1] %[output:645cd71d] %[output:70c09e0e] %[output:8c45965e] %[output:44f75939] %[output:411a50b7] %[output:87c05ce5] %[output:70600b36] %[output:2469f354] %[output:05c5dd03] %[output:6934fb8c] %[output:04bf898d] %[output:96be1319] %[output:90e822c4] %[output:2266e701] %[output:42925741] %[output:34efaf41] %[output:611d47e3] %[output:94792f17] %[output:12d7d6c4] %[output:28c47be2] %[output:77aabf22] %[output:44e63ea7] %[output:2d032691] %[output:9835a591] %[output:1740300f] %[output:725e211e] %[output:203cc677] %[output:6e986856] %[output:022abd85] %[output:9a082496] %[output:20e556cf] %[output:77bcd5ad] %[output:24d139a6] %[output:80defc8c] %[output:902539eb] %[output:421ce65f] %[output:60d30f52] %[output:4fe9b5b6] %[output:170808b7] %[output:873f4419] %[output:88b600dd] %[output:009b6121] %[output:1bc17f05] %[output:0dd5ccf0] %[output:8dfc0eae] %[output:28daf2ba] %[output:68c79f00] %[output:5ba5258a] %[output:14f4fe8d] %[output:2dcf86e5] %[output:36dad286] %[output:25fd4f59] %[output:19b44d7b] %[output:20524376] %[output:9ea0e82f] %[output:049f8c96] %[output:122f8a42] %[output:1a4fc085] %[output:458a683a] %[output:4acff999] %[output:0228c55e] %[output:3ce53fc9] %[output:539c5e83] %[output:6fb5fe06] %[output:87b404fd] %[output:77ec8ac0] %[output:78caa61f] %[output:0b033176] %[output:469baac7] %[output:5a4537d3] %[output:68ed0d31] %[output:4a623892] %[output:7acb9bb5] %[output:944573db] %[output:4f3ac1cb] %[output:9d615d7f] %[output:1593b43a] %[output:8a96c490] %[output:7554bd72] %[output:6d7b7192] %[output:1aa21c53] %[output:44deb5ab] %[output:39eda95b] %[output:9a39aa75] %[output:84735522] %[output:2f323f95] %[output:081f663c] %[output:96befcc3] %[output:99f54f84] %[output:06ced321] %[output:8b9e6e85] %[output:0c325270] %[output:259daf64] %[output:6bca1872] %[output:0602738a] %[output:4648b4b5] %[output:6d0016a3] %[output:7b673f0a] %[output:7b86dff2] %[output:84191c8d] %[output:0f50aae4] %[output:5f732d26] %[output:8a1dc187] %[output:54f83e0f] %[output:246ff07c] %[output:72bf059e] %[output:2ef136f1] %[output:0722ac6a] %[output:729cc3b5] %[output:8f946bd3] %[output:7f5e8e1f] %[output:3a91e388] %[output:48c38a17] %[output:52000d27] %[output:7530f86d] %[output:0ebd3723] %[output:1ecc6095] %[output:513ee371] %[output:90dac9a5] %[output:1b08779a] %[output:04bc407c] %[output:21100036] %[output:54f908c4] %[output:5482935a] %[output:3402654b] %[output:1a83025b] %[output:638fcab3] %[output:037456ad] %[output:7157e9c8] %[output:9b141338] %[output:5759cd56] %[output:51fbf084] %[output:54dae793] %[output:8f697b37] %[output:5cceaa4c] %[output:0f254b53] %[output:82207855] %[output:3a173ddd] %[output:2d81fbde] %[output:770fc2b7] %[output:4f82aab2] %[output:357320f6] %[output:134b9194] %[output:7395f145] %[output:4218d912] %[output:2c99d37d] %[output:126ea433] %[output:241e526f] %[output:0ae87b4d] %[output:5ee31460] %[output:8d6e632d] %[output:02035592] %[output:8a9bf27d] %[output:6439db60]
                                                                ); %[output:1e22fb87] %[output:673cf78d] %[output:278f4cc0] %[output:6d73aa74] %[output:16a3e2d9] %[output:9e7f3753] %[output:47b5c823] %[output:17271fde] %[output:85acbb24] %[output:46ad78bf] %[output:9f9bb2ea] %[output:18b3e7b1] %[output:4498ca17] %[output:440e7d45] %[output:1fa33165] %[output:5bb902cf] %[output:673cd2f3] %[output:026d7706] %[output:96e50272] %[output:39e415d6] %[output:492c8d41] %[output:5f08ee56] %[output:98ed7f6a] %[output:68b12fb9] %[output:262f856d] %[output:9c5b1d19] %[output:047952c1] %[output:5ef4efe9] %[output:0d6fb69f] %[output:12e0e429] %[output:11287cce] %[output:6cc1cf24] %[output:40e24324] %[output:5df7d321] %[output:18bfb18d] %[output:5add4211] %[output:2c955740] %[output:98b5a3e2] %[output:67a7d6e9] %[output:8ca32cc1] %[output:2315b209] %[output:709e56b3] %[output:66b2b681] %[output:52a0fa2e] %[output:084d9d7d] %[output:6fa00275] %[output:4a36928c] %[output:88fb6b34] %[output:49ddfe54] %[output:0ef0be3d] %[output:8afb4722] %[output:40d53963] %[output:010cb6ff] %[output:2a336eb8] %[output:638969f4] %[output:8d7fe342] %[output:9300224d] %[output:2a222a20] %[output:28970bc5] %[output:5757096e] %[output:27d1c118] %[output:7139e4b6] %[output:31fbe3b7] %[output:7a33df34] %[output:483acdbc] %[output:4883ca4d] %[output:48df3ad5] %[output:6a071c77] %[output:49204fda] %[output:157679b7] %[output:426de9c3] %[output:6f944c28] %[output:6f43b99b] %[output:1fd79296] %[output:46828745] %[output:6d331cb3] %[output:643f9863] %[output:8e71bd2f] %[output:524cdd2f] %[output:624f6a14] %[output:6806e70d] %[output:66b49db0] %[output:563f64e5] %[output:5e823541] %[output:167a22bc] %[output:046610a1] %[output:645cd71d] %[output:70c09e0e] %[output:8c45965e] %[output:44f75939] %[output:411a50b7] %[output:87c05ce5] %[output:70600b36] %[output:2469f354] %[output:05c5dd03] %[output:6934fb8c] %[output:04bf898d] %[output:96be1319] %[output:90e822c4] %[output:2266e701] %[output:42925741] %[output:34efaf41] %[output:611d47e3] %[output:94792f17] %[output:12d7d6c4] %[output:28c47be2] %[output:77aabf22] %[output:44e63ea7] %[output:2d032691] %[output:9835a591] %[output:1740300f] %[output:725e211e] %[output:203cc677] %[output:6e986856] %[output:022abd85] %[output:9a082496] %[output:20e556cf] %[output:77bcd5ad] %[output:24d139a6] %[output:80defc8c] %[output:902539eb] %[output:421ce65f] %[output:60d30f52] %[output:4fe9b5b6] %[output:170808b7] %[output:873f4419] %[output:88b600dd] %[output:009b6121] %[output:1bc17f05] %[output:0dd5ccf0] %[output:8dfc0eae] %[output:28daf2ba] %[output:68c79f00] %[output:5ba5258a] %[output:14f4fe8d] %[output:2dcf86e5] %[output:36dad286] %[output:25fd4f59] %[output:19b44d7b] %[output:20524376] %[output:9ea0e82f] %[output:049f8c96] %[output:122f8a42] %[output:1a4fc085] %[output:458a683a] %[output:4acff999] %[output:0228c55e] %[output:3ce53fc9] %[output:539c5e83] %[output:6fb5fe06] %[output:87b404fd] %[output:77ec8ac0] %[output:78caa61f] %[output:0b033176] %[output:469baac7] %[output:5a4537d3] %[output:68ed0d31] %[output:4a623892] %[output:7acb9bb5] %[output:944573db] %[output:4f3ac1cb] %[output:9d615d7f] %[output:1593b43a] %[output:8a96c490] %[output:7554bd72] %[output:6d7b7192] %[output:1aa21c53] %[output:44deb5ab] %[output:39eda95b] %[output:9a39aa75] %[output:84735522] %[output:2f323f95] %[output:081f663c] %[output:96befcc3] %[output:99f54f84] %[output:06ced321] %[output:8b9e6e85] %[output:0c325270] %[output:259daf64] %[output:6bca1872] %[output:0602738a] %[output:4648b4b5] %[output:6d0016a3] %[output:7b673f0a] %[output:7b86dff2] %[output:84191c8d] %[output:0f50aae4] %[output:5f732d26] %[output:8a1dc187] %[output:54f83e0f] %[output:246ff07c] %[output:72bf059e] %[output:2ef136f1] %[output:0722ac6a] %[output:729cc3b5] %[output:8f946bd3] %[output:7f5e8e1f] %[output:3a91e388] %[output:48c38a17] %[output:52000d27] %[output:7530f86d] %[output:0ebd3723] %[output:1ecc6095] %[output:513ee371] %[output:90dac9a5] %[output:1b08779a] %[output:04bc407c] %[output:21100036] %[output:54f908c4] %[output:5482935a] %[output:3402654b] %[output:1a83025b] %[output:638fcab3] %[output:037456ad] %[output:7157e9c8] %[output:9b141338] %[output:5759cd56] %[output:51fbf084] %[output:54dae793] %[output:8f697b37] %[output:5cceaa4c] %[output:0f254b53] %[output:82207855] %[output:3a173ddd] %[output:2d81fbde] %[output:770fc2b7] %[output:4f82aab2] %[output:357320f6] %[output:134b9194] %[output:7395f145] %[output:4218d912] %[output:2c99d37d] %[output:126ea433] %[output:241e526f] %[output:0ae87b4d] %[output:5ee31460] %[output:8d6e632d] %[output:02035592] %[output:8a9bf27d] %[output:6439db60]
        
        % add a one-back trial in each half with at least 5 trials between them
        trials_count = length(trial_order);
        midpoint = floor(trials_count/2);
        while 1
            inds_one_back = [randperm(midpoint, 1) (randperm(trials_count-midpoint, 1) + midpoint)];
            if diff(inds_one_back) >= 5
                break
            end
        end
        fprintf("\t\tAdding one-backs to trial IDs [%s] at positions [%s]\n", strjoin(string(trial_order(inds_one_back)), " "), strjoin(string(inds_one_back), " ")); %[output:941f71bc] %[output:7c83b789] %[output:524e02d7] %[output:97bd1181] %[output:852c7168] %[output:2fa9cc33] %[output:58afef70] %[output:5b4d39f0] %[output:4b3cbb76] %[output:10ec0ff5] %[output:68318461] %[output:57c1fdcb] %[output:0f0260aa] %[output:69866b9f] %[output:89b63740] %[output:8574bca1] %[output:55a5bc7c] %[output:6b087a1a] %[output:602e0d9a] %[output:3a8a8e74] %[output:74e138ae] %[output:946fc933] %[output:94cf541c] %[output:5c8f4a1f] %[output:8b75c763] %[output:549a2bf7] %[output:6b17a27b] %[output:471f8029] %[output:83d67e7c] %[output:97942101] %[output:748acb74] %[output:9aefdd8e] %[output:18e76962] %[output:11da0553] %[output:32ba927f] %[output:2af3edeb] %[output:45c17044] %[output:9490cae9] %[output:64734a51] %[output:291dea73] %[output:5ab7fadc] %[output:1eb3a33f] %[output:55deedbf] %[output:0d20ecdf] %[output:6e8afa82] %[output:23180a47] %[output:63ea14c2] %[output:90459310] %[output:63f320e9] %[output:0bdd8dfb] %[output:7c1f332c] %[output:711883b6] %[output:6f7d8921] %[output:4e7cf871] %[output:268adf04] %[output:9c886e0d] %[output:3438d3e1] %[output:5df57c4c] %[output:6c21a933] %[output:9475c891] %[output:266b7218] %[output:5f472d93] %[output:4e821fae] %[output:0d8b2a9a] %[output:8efcb587] %[output:49c46ff5] %[output:981e329e] %[output:30dd00d4] %[output:4b5dcc27] %[output:8e2887b4] %[output:6062f5ef] %[output:2c68e07a] %[output:98178078] %[output:35f23208] %[output:8fba43a5] %[output:24c39195] %[output:2dfa86b6] %[output:8b92d309] %[output:70dfc373] %[output:3162c55c] %[output:5a1bda66] %[output:75adc6bf] %[output:0951746a] %[output:124dc535] %[output:6ac771d0] %[output:9a09aa7c] %[output:2a93b671] %[output:45bf6283] %[output:43df5431] %[output:4b64f04b] %[output:1026b268] %[output:828dfe2e] %[output:895dcad1] %[output:1137a51f] %[output:2bce618c] %[output:467596a2] %[output:1c1391c1] %[output:883f9d7d] %[output:7c4d5ac9] %[output:50821e04] %[output:8347c93f] %[output:71a1937f] %[output:74c3705e] %[output:2b343092] %[output:86b1e115] %[output:11304965] %[output:07d287f0] %[output:6ac3ee48] %[output:9c3b7e71] %[output:861eceeb] %[output:00fca7b6] %[output:4c3a0619] %[output:67f34b41] %[output:1b178fa4] %[output:70d43430] %[output:6839c1de] %[output:5960bd3b] %[output:02714dac] %[output:3bc86d19] %[output:1caeb180] %[output:0458b293] %[output:6c5f2c58] %[output:5aa7534f] %[output:47497456] %[output:50cf39b4] %[output:4530fcec] %[output:71350662] %[output:931212be] %[output:03088a73] %[output:0bb601f6] %[output:931d213d] %[output:6a3af834] %[output:45f66fb6] %[output:002710e9] %[output:8afd5969] %[output:101e2def] %[output:560dbf6e] %[output:89c6b0c8] %[output:75188355] %[output:3f0c2601] %[output:4926caf0] %[output:5973caf8] %[output:6ef5fd66] %[output:2bb77a89] %[output:95b178a9] %[output:98db4f4d] %[output:82f70a3e] %[output:38c20393] %[output:27befc81] %[output:68f93d93] %[output:9af98d66] %[output:838a3567] %[output:1f20bd22] %[output:103ad2fc] %[output:065a8c28] %[output:8760b3b6] %[output:54a4e4a1] %[output:12e2f8c4] %[output:9239d324] %[output:3a5a399f] %[output:21e47195] %[output:36a0942f] %[output:633cdded] %[output:18228f61] %[output:3b4b44c1] %[output:7f0f8dd4] %[output:9a1e9bdc] %[output:84a44f0e] %[output:3f759f7f] %[output:18c67f13] %[output:719427cf] %[output:16174675] %[output:3c177f6c] %[output:32d01477] %[output:183edec5] %[output:5562de5e] %[output:02b49f8f] %[output:4b5ce014] %[output:0b743ee4] %[output:45c05951] %[output:0c561cf7] %[output:5059232e] %[output:2cea4f2b] %[output:2d91b236] %[output:21facb13] %[output:2cd66652] %[output:36fc23a7] %[output:0b1abc46] %[output:939b1992] %[output:0ce5e6ab] %[output:8a2bbb4f] %[output:5bfb0e98] %[output:48a9b5d4] %[output:1d1e4b06] %[output:3adb866c] %[output:3117aa58] %[output:7f53f393] %[output:07b13d6a] %[output:82c02a0a] %[output:1a88b1b8] %[output:4393ab77] %[output:8581a7c9] %[output:692783b2] %[output:26d2a418] %[output:09dd042c] %[output:7462c7ac] %[output:4b39dd41] %[output:7a4fb8cf] %[output:832cc327] %[output:652a90c1] %[output:558b7972] %[output:6f7dbf0a] %[output:40407667] %[output:0bd9fcb6] %[output:3a36f530] %[output:64ed80ae] %[output:4ffacd63] %[output:75d1dce4] %[output:483f25bf] %[output:14d67f70] %[output:4016262a] %[output:7c80a438] %[output:02182eba] %[output:8fc75886] %[output:41f54f3e] %[output:616d131f] %[output:209f34e8] %[output:9938e7c9] %[output:4db0085e] %[output:3182b1b5] %[output:7e440b4b] %[output:941d7d30] %[output:5abce73a] %[output:014d5c0d] %[output:8a2a1a72] %[output:73a1c677] %[output:2edbcc2c] %[output:8de74b02] %[output:24194907] %[output:14ccfe34]
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
        fprintf("\t\t%d long ITIs in trials: %s\n", length(inds_long_ITI), strjoin(string(inds_long_ITI), " ")); %[output:327e53b3] %[output:6d9a1fee] %[output:8b8a1577] %[output:393e1daa] %[output:9bbf4aee] %[output:47dddc49] %[output:2f6bffff] %[output:96c31271] %[output:188495fb] %[output:30e3d082] %[output:829d209a] %[output:9b2a0617] %[output:4871f95f] %[output:30722137] %[output:03bbe675] %[output:2cddf847] %[output:7c6098ee] %[output:5909236a] %[output:314985cd] %[output:4b514c53] %[output:14ffda35] %[output:70654d2e] %[output:89fc7e34] %[output:899ba951] %[output:86cd302b] %[output:8c23501e] %[output:22c7acbb] %[output:1dcdcd0a] %[output:7a8d0e9c] %[output:0ba49328] %[output:29031a43] %[output:08dbee80] %[output:49e23089] %[output:13c12d9f] %[output:9e43817f] %[output:3172e5ce] %[output:5d23ae1e] %[output:3755d1d6] %[output:86e039fb] %[output:5180fdba] %[output:6db7d448] %[output:40999b68] %[output:6a53094e] %[output:8a457e94] %[output:3b649b27] %[output:4302cf88] %[output:4680f5f8] %[output:9924b396] %[output:2cb5c46b] %[output:420e4989] %[output:25ff13ca] %[output:69b8c6d4] %[output:7cff0a8f] %[output:9a61aaf6] %[output:7f688202] %[output:5a8364cd] %[output:4583d8fa] %[output:93df87e8] %[output:82d2a850] %[output:63a03056] %[output:4b90717f] %[output:08e08a0b] %[output:3c3e35c5] %[output:4973fb07] %[output:469809c9] %[output:0f2abfe4] %[output:1f6b5544] %[output:7dff4a60] %[output:1d6c6796] %[output:6f6eb337] %[output:8d5552b7] %[output:419c4317] %[output:374f6542] %[output:04e1464f] %[output:7d092546] %[output:5d97ec37] %[output:7f79df38] %[output:7295160e] %[output:8fde4d58] %[output:7df12e3e] %[output:26407a74] %[output:3aaa6695] %[output:401e6ea3] %[output:1d73aa9f] %[output:17cfa2e9] %[output:6ac72f51] %[output:2e4ca148] %[output:60b10183] %[output:2262882b] %[output:88bab87f] %[output:1e62d335] %[output:8564acd2] %[output:32b347c0] %[output:041ba8f6] %[output:14f7518e] %[output:53573207] %[output:53ee9836] %[output:881a534c] %[output:2f864974] %[output:9df8060b] %[output:8ead68ca] %[output:88856124] %[output:28bcb3a1] %[output:3f3b2013] %[output:3d27e2b5] %[output:9b394387] %[output:307cf288] %[output:3599839a] %[output:4ca1a89a] %[output:23ad14c0] %[output:0d378df6] %[output:0e49875b] %[output:20fc5514] %[output:69073403] %[output:409d7539] %[output:928278f8] %[output:7392d664] %[output:408be159] %[output:93db2692] %[output:16283a74] %[output:48a91e02] %[output:36ef4e03] %[output:1ee70266] %[output:424c2080] %[output:26031d6f] %[output:62b52d5f] %[output:471b263b] %[output:611b505a] %[output:80324074] %[output:86307870] %[output:17d198b2] %[output:9230bcac] %[output:661fab50] %[output:31b85630] %[output:8d6e0797] %[output:79aa39f0] %[output:89eccf6a] %[output:7d12788a] %[output:01170a59] %[output:25f1bb48] %[output:6ea46f44] %[output:6345f846] %[output:4dd05a4b] %[output:34aae3d4] %[output:36dbc99a] %[output:8844443e] %[output:79c168cd] %[output:3ca1a947] %[output:9d8d732b] %[output:9a9f08c1] %[output:5a268c35] %[output:38033845] %[output:965bf336] %[output:8477977e] %[output:501cbf01] %[output:87ef1bcc] %[output:9afc1935] %[output:8c9345b8] %[output:9a391e3a] %[output:1225a2b6] %[output:557162bf] %[output:365e9a54] %[output:8b6b4c7c] %[output:1412398c] %[output:71c15df0] %[output:6a2bcc0e] %[output:71f2a9d8] %[output:05f38de8] %[output:8653b285] %[output:2a13eb49] %[output:16e8f1a0] %[output:56fa019c] %[output:8836e78e] %[output:20c5a935] %[output:8e5da6f5] %[output:7cfed1e0] %[output:6245dc70] %[output:135e476d] %[output:7fa109e0] %[output:8e71b4c5] %[output:7786c39c] %[output:6e4d251f] %[output:33eb920e] %[output:7b290331] %[output:39ce450d] %[output:057380a4] %[output:66461bae] %[output:8988cf49] %[output:23e41efc] %[output:1e56f650] %[output:261ba22a] %[output:9cc1d908] %[output:1dc9afad] %[output:39bfd5d0] %[output:58291146] %[output:9ced67cc] %[output:40ce1b15] %[output:2eded10b] %[output:7dc5799c] %[output:3820b4f3] %[output:69cc8441] %[output:4078ae8d] %[output:6b44ffc9] %[output:30ef791c] %[output:88b4dd44] %[output:7628d95e] %[output:9da1028d] %[output:4a9de0f4] %[output:839fb900] %[output:6aee9f15] %[output:9283f5d7] %[output:6f1267f1] %[output:7f25b4c9] %[output:620abe8f] %[output:392bdca1] %[output:7eb4044a] %[output:91ca2a1b] %[output:0cb637a3] %[output:1b765d9c] %[output:358dd9d9] %[output:01211a86] %[output:1555b35f] %[output:2520e71e] %[output:010e8386] %[output:1064ea1a] %[output:983fbc9c] %[output:1fe586c0] %[output:3b4d0cb1] %[output:5ed7f481] %[output:593ea2b8] %[output:24ac3667] %[output:52bdfd93] %[output:66ef5188] %[output:9fa66a23] %[output:44ea0f27] %[output:5ff0758c] %[output:55bd7449] %[output:52baf318] %[output:453fccbf] %[output:4621e4de]

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
        fprintf("\t\tWriting: %s\n", filepath); %[output:0915e614] %[output:1dd365e4] %[output:0491808d] %[output:257219d5] %[output:9d5cd559] %[output:31496711] %[output:2e7fd50c] %[output:086fe00e] %[output:83a44443] %[output:97967265] %[output:9dc17ae6] %[output:89fc5ad1] %[output:1bd18f94] %[output:7544fc68] %[output:5937d6d9] %[output:160fbb5b] %[output:4dbbcb3f] %[output:9faefcde] %[output:2681e3cc] %[output:33d88d69] %[output:510b79cc] %[output:456f8b1d] %[output:452bd54f] %[output:64ce36f3] %[output:701f1694] %[output:46fda84d] %[output:1dcb3d55] %[output:65d5d8e2] %[output:824bd090] %[output:41fc37af] %[output:0c487f88] %[output:15dc7a19] %[output:0b756a45] %[output:03de1abb] %[output:389b565f] %[output:97a1fa38] %[output:4e085815] %[output:3809b0e5] %[output:4d59f58b] %[output:1a31063f] %[output:4710932b] %[output:1c153562] %[output:48cfb475] %[output:1b2296e6] %[output:025e4b7a] %[output:52ef0057] %[output:0378dd5b] %[output:5c105a9a] %[output:6e4e6693] %[output:799f7bca] %[output:4c19f0d6] %[output:054e7af3] %[output:01069316] %[output:6dfd4abd] %[output:230b8064] %[output:48118b28] %[output:45d4c77d] %[output:29e19296] %[output:61825abc] %[output:1b27ff9f] %[output:42db484f] %[output:5fba7d1a] %[output:594d3763] %[output:72d55963] %[output:52276194] %[output:5b17fc2e] %[output:960afe3b] %[output:98c3d82c] %[output:52b37d20] %[output:7bb806cb] %[output:13bf6520] %[output:1bb78f68] %[output:97f0162b] %[output:1496324b] %[output:22a0c320] %[output:3455a9c5] %[output:080a3bba] %[output:9b2ddbb4] %[output:7c1eee64] %[output:56903ab8] %[output:41f3094c] %[output:459dae2e] %[output:59f9d0aa] %[output:42b4d1f6] %[output:2d22495a] %[output:5bfaa6e1] %[output:93cd9340] %[output:1ad26af0] %[output:33e0036d] %[output:486d0037] %[output:025c3058] %[output:300ba005] %[output:2aac7669] %[output:07326fd0] %[output:5486efcd] %[output:9070d6fa] %[output:729ab9c7] %[output:34528b31] %[output:26de9d45] %[output:0e465ff3] %[output:2182c669] %[output:1a976f33] %[output:18463486] %[output:0ffe69af] %[output:2d242ff0] %[output:62c9d280] %[output:8714b562] %[output:2fd3b2d9] %[output:9bcb1d5f] %[output:55471ca5] %[output:0301f257] %[output:316d19f5] %[output:981a8311] %[output:15b2aa9e] %[output:1310b2ea] %[output:6518269c] %[output:19f75e18] %[output:162674d8] %[output:5151ef74] %[output:6810e4ee] %[output:4604204d] %[output:2edd3131] %[output:15478d92] %[output:185369de] %[output:379388a2] %[output:6891f091] %[output:3142e626] %[output:65454485] %[output:145bac04] %[output:9ec0aa31] %[output:789c06fd] %[output:3f214357] %[output:0dd20b09] %[output:66af172a] %[output:96dfd2cb] %[output:9e2beaf5] %[output:8ffd3d82] %[output:9365c44c] %[output:27151d07] %[output:400409fb] %[output:7b3078ed] %[output:0437f084] %[output:852725e2] %[output:4654700e] %[output:59e0a077] %[output:4021584b] %[output:78fd5c5a] %[output:375cdb36] %[output:58872da8] %[output:92fb7570] %[output:99905ec6] %[output:00154d00] %[output:3d4a0afa] %[output:2567459d] %[output:4215b171] %[output:686eeb1b] %[output:436ba8da] %[output:66869f61] %[output:52fa9729] %[output:2db8f485] %[output:8286d44d] %[output:830c13fd] %[output:5a206186] %[output:0a45e9bb] %[output:69d97b36] %[output:65c92301] %[output:95d26b92] %[output:56dda654] %[output:384bb0e6] %[output:7f653fa5] %[output:4d7dfb21] %[output:17f42673] %[output:6449af3e] %[output:990a523a] %[output:26b46ec3] %[output:8d0e06b6] %[output:591f22a5] %[output:874e0862] %[output:2846d781] %[output:5060f6e8] %[output:8c44f61e] %[output:6ea55379] %[output:406ab500] %[output:9b7a971a] %[output:3f33159b] %[output:86aacc96] %[output:1f23221e] %[output:3dca21a4] %[output:89e42d91] %[output:7502cb5f] %[output:9c2ed4b0] %[output:81793cae] %[output:1f4df7f7] %[output:8846bf5a] %[output:413e38f4] %[output:5116c6d5] %[output:523a1bed] %[output:334e1a98] %[output:5419d9be] %[output:67d94ac5] %[output:6356e976] %[output:431d3460] %[output:6387c284] %[output:3c52297b] %[output:6bf7df64] %[output:95138a0e] %[output:4e312c94] %[output:87b07f7b] %[output:1eff04e3] %[output:45765435] %[output:60d12f14] %[output:16cb32cd] %[output:4730fef2] %[output:93c81b28] %[output:1ae18698] %[output:7a1e7c72] %[output:5365f2c2] %[output:31be3b2c] %[output:0056b7a1] %[output:98164806] %[output:28855311] %[output:1664b9d4] %[output:0050630e] %[output:09025270] %[output:3437a3b8] %[output:24caae8f] %[output:169b2202] %[output:298e79aa] %[output:54a08a10] %[output:80da19e9] %[output:4811c0d5] %[output:543df555] %[output:3c29aa0d] %[output:2c4d6368] %[output:65d9bfe5] %[output:33d5ba77] %[output:88602904] %[output:0375f615] %[output:5f53fdb2] %[output:54f5ae07]
        writetable(xlsx, filepath);
    end
end %[output:group:68aeb0c9]

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":34.5}
%---
%[output:7640c753]
%   data: {"dataType":"text","outputData":{"text":"     <strong>ID<\/strong>     <strong>View<\/strong>    <strong>Category<\/strong>    <strong>StimNum<\/strong>      <strong>FilenameLeft<\/strong>         <strong>FilenameRight<\/strong>  \n    <strong>____<\/strong>    <strong>____<\/strong>    <strong>________<\/strong>    <strong>_______<\/strong>    <strong>_________________<\/strong>    <strong>_________________<\/strong>\n\n    \"1\"     \"2D\"    \"Face\"       \"01\"      \"Face_01_R.png\"      \"Face_01_R.png\"  \n    \"2\"     \"2D\"    \"Face\"       \"02\"      \"Face_02_R.png\"      \"Face_02_R.png\"  \n    \"3\"     \"2D\"    \"Face\"       \"03\"      \"Face_03_R.png\"      \"Face_03_R.png\"  \n    \"4\"     \"2D\"    \"Face\"       \"04\"      \"Face_04_R.png\"      \"Face_04_R.png\"  \n    \"5\"     \"2D\"    \"Face\"       \"05\"      \"Face_05_R.png\"      \"Face_05_R.png\"  \n    \"6\"     \"2D\"    \"Face\"       \"06\"      \"Face_06_R.png\"      \"Face_06_R.png\"  \n    \"7\"     \"2D\"    \"Face\"       \"07\"      \"Face_07_R.png\"      \"Face_07_R.png\"  \n    \"8\"     \"2D\"    \"Face\"       \"08\"      \"Face_08_R.png\"      \"Face_08_R.png\"  \n    \"9\"     \"2D\"    \"Face\"       \"09\"      \"Face_09_R.png\"      \"Face_09_R.png\"  \n    \"10\"    \"2D\"    \"Face\"       \"10\"      \"Face_10_R.png\"      \"Face_10_R.png\"  \n    \"11\"    \"2D\"    \"Face\"       \"11\"      \"Face_11_R.png\"      \"Face_11_R.png\"  \n    \"12\"    \"2D\"    \"Face\"       \"12\"      \"Face_12_R.png\"      \"Face_12_R.png\"  \n    \"13\"    \"2D\"    \"Face\"       \"13\"      \"Face_13_R.png\"      \"Face_13_R.png\"  \n    \"14\"    \"2D\"    \"Face\"       \"14\"      \"Face_14_R.png\"      \"Face_14_R.png\"  \n    \"15\"    \"2D\"    \"Face\"       \"15\"      \"Face_15_R.png\"      \"Face_15_R.png\"  \n    \"16\"    \"2D\"    \"Face\"       \"16\"      \"Face_16_R.png\"      \"Face_16_R.png\"  \n    \"17\"    \"2D\"    \"Hand\"       \"01\"      \"Hand_01_R.png\"      \"Hand_01_R.png\"  \n    \"18\"    \"2D\"    \"Hand\"       \"02\"      \"Hand_02_R.png\"      \"Hand_02_R.png\"  \n    \"19\"    \"2D\"    \"Hand\"       \"03\"      \"Hand_03_R.png\"      \"Hand_03_R.png\"  \n    \"20\"    \"2D\"    \"Hand\"       \"04\"      \"Hand_04_R.png\"      \"Hand_04_R.png\"  \n    \"21\"    \"2D\"    \"Hand\"       \"05\"      \"Hand_05_R.png\"      \"Hand_05_R.png\"  \n    \"22\"    \"2D\"    \"Hand\"       \"06\"      \"Hand_06_R.png\"      \"Hand_06_R.png\"  \n    \"23\"    \"2D\"    \"Hand\"       \"07\"      \"Hand_07_R.png\"      \"Hand_07_R.png\"  \n    \"24\"    \"2D\"    \"Hand\"       \"08\"      \"Hand_08_R.png\"      \"Hand_08_R.png\"  \n    \"25\"    \"2D\"    \"Hand\"       \"09\"      \"Hand_09_R.png\"      \"Hand_09_R.png\"  \n    \"26\"    \"2D\"    \"Hand\"       \"10\"      \"Hand_10_R.png\"      \"Hand_10_R.png\"  \n    \"27\"    \"2D\"    \"Hand\"       \"11\"      \"Hand_11_R.png\"      \"Hand_11_R.png\"  \n    \"28\"    \"2D\"    \"Hand\"       \"12\"      \"Hand_12_R.png\"      \"Hand_12_R.png\"  \n    \"29\"    \"2D\"    \"Hand\"       \"13\"      \"Hand_13_R.png\"      \"Hand_13_R.png\"  \n    \"30\"    \"2D\"    \"Hand\"       \"14\"      \"Hand_14_R.png\"      \"Hand_14_R.png\"  \n    \"31\"    \"2D\"    \"Hand\"       \"15\"      \"Hand_15_R.png\"      \"Hand_15_R.png\"  \n    \"32\"    \"2D\"    \"Hand\"       \"16\"      \"Hand_16_R.png\"      \"Hand_16_R.png\"  \n    \"33\"    \"2D\"    \"Object\"     \"01\"      \"Object_01_R.png\"    \"Object_01_R.png\"\n    \"34\"    \"2D\"    \"Object\"     \"02\"      \"Object_02_R.png\"    \"Object_02_R.png\"\n    \"35\"    \"2D\"    \"Object\"     \"03\"      \"Object_03_R.png\"    \"Object_03_R.png\"\n    \"36\"    \"2D\"    \"Object\"     \"04\"      \"Object_04_R.png\"    \"Object_04_R.png\"\n    \"37\"    \"2D\"    \"Object\"     \"05\"      \"Object_05_R.png\"    \"Object_05_R.png\"\n    \"38\"    \"2D\"    \"Object\"     \"06\"      \"Object_06_R.png\"    \"Object_06_R.png\"\n    \"39\"    \"2D\"    \"Object\"     \"07\"      \"Object_07_R.png\"    \"Object_07_R.png\"\n    \"40\"    \"2D\"    \"Object\"     \"08\"      \"Object_08_R.png\"    \"Object_08_R.png\"\n    \"41\"    \"2D\"    \"Object\"     \"09\"      \"Object_09_R.png\"    \"Object_09_R.png\"\n    \"42\"    \"2D\"    \"Object\"     \"10\"      \"Object_10_R.png\"    \"Object_10_R.png\"\n    \"43\"    \"2D\"    \"Object\"     \"11\"      \"Object_11_R.png\"    \"Object_11_R.png\"\n    \"44\"    \"2D\"    \"Object\"     \"12\"      \"Object_12_R.png\"    \"Object_12_R.png\"\n    \"45\"    \"2D\"    \"Object\"     \"13\"      \"Object_13_R.png\"    \"Object_13_R.png\"\n    \"46\"    \"2D\"    \"Object\"     \"14\"      \"Object_14_R.png\"    \"Object_14_R.png\"\n    \"47\"    \"2D\"    \"Object\"     \"15\"      \"Object_15_R.png\"    \"Object_15_R.png\"\n    \"48\"    \"2D\"    \"Object\"     \"16\"      \"Object_16_R.png\"    \"Object_16_R.png\"\n    \"49\"    \"3D\"    \"Face\"       \"01\"      \"Face_01_L.png\"      \"Face_01_R.png\"  \n    \"50\"    \"3D\"    \"Face\"       \"02\"      \"Face_02_L.png\"      \"Face_02_R.png\"  \n    \"51\"    \"3D\"    \"Face\"       \"03\"      \"Face_03_L.png\"      \"Face_03_R.png\"  \n    \"52\"    \"3D\"    \"Face\"       \"04\"      \"Face_04_L.png\"      \"Face_04_R.png\"  \n    \"53\"    \"3D\"    \"Face\"       \"05\"      \"Face_05_L.png\"      \"Face_05_R.png\"  \n    \"54\"    \"3D\"    \"Face\"       \"06\"      \"Face_06_L.png\"      \"Face_06_R.png\"  \n    \"55\"    \"3D\"    \"Face\"       \"07\"      \"Face_07_L.png\"      \"Face_07_R.png\"  \n    \"56\"    \"3D\"    \"Face\"       \"08\"      \"Face_08_L.png\"      \"Face_08_R.png\"  \n    \"57\"    \"3D\"    \"Face\"       \"09\"      \"Face_09_L.png\"      \"Face_09_R.png\"  \n    \"58\"    \"3D\"    \"Face\"       \"10\"      \"Face_10_L.png\"      \"Face_10_R.png\"  \n    \"59\"    \"3D\"    \"Face\"       \"11\"      \"Face_11_L.png\"      \"Face_11_R.png\"  \n    \"60\"    \"3D\"    \"Face\"       \"12\"      \"Face_12_L.png\"      \"Face_12_R.png\"  \n    \"61\"    \"3D\"    \"Face\"       \"13\"      \"Face_13_L.png\"      \"Face_13_R.png\"  \n    \"62\"    \"3D\"    \"Face\"       \"14\"      \"Face_14_L.png\"      \"Face_14_R.png\"  \n    \"63\"    \"3D\"    \"Face\"       \"15\"      \"Face_15_L.png\"      \"Face_15_R.png\"  \n    \"64\"    \"3D\"    \"Face\"       \"16\"      \"Face_16_L.png\"      \"Face_16_R.png\"  \n    \"65\"    \"3D\"    \"Hand\"       \"01\"      \"Hand_01_L.png\"      \"Hand_01_R.png\"  \n    \"66\"    \"3D\"    \"Hand\"       \"02\"      \"Hand_02_L.png\"      \"Hand_02_R.png\"  \n    \"67\"    \"3D\"    \"Hand\"       \"03\"      \"Hand_03_L.png\"      \"Hand_03_R.png\"  \n    \"68\"    \"3D\"    \"Hand\"       \"04\"      \"Hand_04_L.png\"      \"Hand_04_R.png\"  \n    \"69\"    \"3D\"    \"Hand\"       \"05\"      \"Hand_05_L.png\"      \"Hand_05_R.png\"  \n    \"70\"    \"3D\"    \"Hand\"       \"06\"      \"Hand_06_L.png\"      \"Hand_06_R.png\"  \n    \"71\"    \"3D\"    \"Hand\"       \"07\"      \"Hand_07_L.png\"      \"Hand_07_R.png\"  \n    \"72\"    \"3D\"    \"Hand\"       \"08\"      \"Hand_08_L.png\"      \"Hand_08_R.png\"  \n    \"73\"    \"3D\"    \"Hand\"       \"09\"      \"Hand_09_L.png\"      \"Hand_09_R.png\"  \n    \"74\"    \"3D\"    \"Hand\"       \"10\"      \"Hand_10_L.png\"      \"Hand_10_R.png\"  \n    \"75\"    \"3D\"    \"Hand\"       \"11\"      \"Hand_11_L.png\"      \"Hand_11_R.png\"  \n    \"76\"    \"3D\"    \"Hand\"       \"12\"      \"Hand_12_L.png\"      \"Hand_12_R.png\"  \n    \"77\"    \"3D\"    \"Hand\"       \"13\"      \"Hand_13_L.png\"      \"Hand_13_R.png\"  \n    \"78\"    \"3D\"    \"Hand\"       \"14\"      \"Hand_14_L.png\"      \"Hand_14_R.png\"  \n    \"79\"    \"3D\"    \"Hand\"       \"15\"      \"Hand_15_L.png\"      \"Hand_15_R.png\"  \n    \"80\"    \"3D\"    \"Hand\"       \"16\"      \"Hand_16_L.png\"      \"Hand_16_R.png\"  \n    \"81\"    \"3D\"    \"Object\"     \"01\"      \"Object_01_L.png\"    \"Object_01_R.png\"\n    \"82\"    \"3D\"    \"Object\"     \"02\"      \"Object_02_L.png\"    \"Object_02_R.png\"\n    \"83\"    \"3D\"    \"Object\"     \"03\"      \"Object_03_L.png\"    \"Object_03_R.png\"\n    \"84\"    \"3D\"    \"Object\"     \"04\"      \"Object_04_L.png\"    \"Object_04_R.png\"\n    \"85\"    \"3D\"    \"Object\"     \"05\"      \"Object_05_L.png\"    \"Object_05_R.png\"\n    \"86\"    \"3D\"    \"Object\"     \"06\"      \"Object_06_L.png\"    \"Object_06_R.png\"\n    \"87\"    \"3D\"    \"Object\"     \"07\"      \"Object_07_L.png\"    \"Object_07_R.png\"\n    \"88\"    \"3D\"    \"Object\"     \"08\"      \"Object_08_L.png\"    \"Object_08_R.png\"\n    \"89\"    \"3D\"    \"Object\"     \"09\"      \"Object_09_L.png\"    \"Object_09_R.png\"\n    \"90\"    \"3D\"    \"Object\"     \"10\"      \"Object_10_L.png\"    \"Object_10_R.png\"\n    \"91\"    \"3D\"    \"Object\"     \"11\"      \"Object_11_L.png\"    \"Object_11_R.png\"\n    \"92\"    \"3D\"    \"Object\"     \"12\"      \"Object_12_L.png\"    \"Object_12_R.png\"\n    \"93\"    \"3D\"    \"Object\"     \"13\"      \"Object_13_L.png\"    \"Object_13_R.png\"\n    \"94\"    \"3D\"    \"Object\"     \"14\"      \"Object_14_L.png\"    \"Object_14_R.png\"\n    \"95\"    \"3D\"    \"Object\"     \"15\"      \"Object_15_L.png\"    \"Object_15_R.png\"\n    \"96\"    \"3D\"    \"Object\"     \"16\"      \"Object_16_L.png\"    \"Object_16_R.png\"\n\n","truncated":false}}
%---
%[output:3ab1bf76]
%   data: {"dataType":"text","outputData":{"text":"Created View_x_Category with 6 IDs:\n    <strong>ID<\/strong>     <strong>ID_Label<\/strong>      <strong>View<\/strong>    <strong>Category<\/strong>\n    <strong>__<\/strong>    <strong>___________<\/strong>    <strong>____<\/strong>    <strong>________<\/strong>\n\n    1     \"2D_Face\"      \"2D\"    \"Face\"  \n    2     \"2D_Hand\"      \"2D\"    \"Hand\"  \n    3     \"2D_Object\"    \"2D\"    \"Object\"\n    4     \"3D_Face\"      \"3D\"    \"Face\"  \n    5     \"3D_Hand\"      \"3D\"    \"Hand\"  \n    6     \"3D_Object\"    \"3D\"    \"Object\"\n\n","truncated":false}}
%---
%[output:7ceb95e9]
%   data: {"dataType":"text","outputData":{"text":"     <strong>ID<\/strong>     <strong>View<\/strong>    <strong>Category<\/strong>    <strong>StimNum<\/strong>      <strong>FilenameLeft<\/strong>         <strong>FilenameRight<\/strong>      <strong>View_x_Category<\/strong>\n    <strong>____<\/strong>    <strong>____<\/strong>    <strong>________<\/strong>    <strong>_______<\/strong>    <strong>_________________<\/strong>    <strong>_________________<\/strong>    <strong>_______________<\/strong>\n\n    \"1\"     \"2D\"    \"Face\"       \"01\"      \"Face_01_R.png\"      \"Face_01_R.png\"        \"2D_Face\"    \n    \"2\"     \"2D\"    \"Face\"       \"02\"      \"Face_02_R.png\"      \"Face_02_R.png\"        \"2D_Face\"    \n    \"3\"     \"2D\"    \"Face\"       \"03\"      \"Face_03_R.png\"      \"Face_03_R.png\"        \"2D_Face\"    \n    \"4\"     \"2D\"    \"Face\"       \"04\"      \"Face_04_R.png\"      \"Face_04_R.png\"        \"2D_Face\"    \n    \"5\"     \"2D\"    \"Face\"       \"05\"      \"Face_05_R.png\"      \"Face_05_R.png\"        \"2D_Face\"    \n    \"6\"     \"2D\"    \"Face\"       \"06\"      \"Face_06_R.png\"      \"Face_06_R.png\"        \"2D_Face\"    \n    \"7\"     \"2D\"    \"Face\"       \"07\"      \"Face_07_R.png\"      \"Face_07_R.png\"        \"2D_Face\"    \n    \"8\"     \"2D\"    \"Face\"       \"08\"      \"Face_08_R.png\"      \"Face_08_R.png\"        \"2D_Face\"    \n    \"9\"     \"2D\"    \"Face\"       \"09\"      \"Face_09_R.png\"      \"Face_09_R.png\"        \"2D_Face\"    \n    \"10\"    \"2D\"    \"Face\"       \"10\"      \"Face_10_R.png\"      \"Face_10_R.png\"        \"2D_Face\"    \n    \"11\"    \"2D\"    \"Face\"       \"11\"      \"Face_11_R.png\"      \"Face_11_R.png\"        \"2D_Face\"    \n    \"12\"    \"2D\"    \"Face\"       \"12\"      \"Face_12_R.png\"      \"Face_12_R.png\"        \"2D_Face\"    \n    \"13\"    \"2D\"    \"Face\"       \"13\"      \"Face_13_R.png\"      \"Face_13_R.png\"        \"2D_Face\"    \n    \"14\"    \"2D\"    \"Face\"       \"14\"      \"Face_14_R.png\"      \"Face_14_R.png\"        \"2D_Face\"    \n    \"15\"    \"2D\"    \"Face\"       \"15\"      \"Face_15_R.png\"      \"Face_15_R.png\"        \"2D_Face\"    \n    \"16\"    \"2D\"    \"Face\"       \"16\"      \"Face_16_R.png\"      \"Face_16_R.png\"        \"2D_Face\"    \n    \"17\"    \"2D\"    \"Hand\"       \"01\"      \"Hand_01_R.png\"      \"Hand_01_R.png\"        \"2D_Hand\"    \n    \"18\"    \"2D\"    \"Hand\"       \"02\"      \"Hand_02_R.png\"      \"Hand_02_R.png\"        \"2D_Hand\"    \n    \"19\"    \"2D\"    \"Hand\"       \"03\"      \"Hand_03_R.png\"      \"Hand_03_R.png\"        \"2D_Hand\"    \n    \"20\"    \"2D\"    \"Hand\"       \"04\"      \"Hand_04_R.png\"      \"Hand_04_R.png\"        \"2D_Hand\"    \n    \"21\"    \"2D\"    \"Hand\"       \"05\"      \"Hand_05_R.png\"      \"Hand_05_R.png\"        \"2D_Hand\"    \n    \"22\"    \"2D\"    \"Hand\"       \"06\"      \"Hand_06_R.png\"      \"Hand_06_R.png\"        \"2D_Hand\"    \n    \"23\"    \"2D\"    \"Hand\"       \"07\"      \"Hand_07_R.png\"      \"Hand_07_R.png\"        \"2D_Hand\"    \n    \"24\"    \"2D\"    \"Hand\"       \"08\"      \"Hand_08_R.png\"      \"Hand_08_R.png\"        \"2D_Hand\"    \n    \"25\"    \"2D\"    \"Hand\"       \"09\"      \"Hand_09_R.png\"      \"Hand_09_R.png\"        \"2D_Hand\"    \n    \"26\"    \"2D\"    \"Hand\"       \"10\"      \"Hand_10_R.png\"      \"Hand_10_R.png\"        \"2D_Hand\"    \n    \"27\"    \"2D\"    \"Hand\"       \"11\"      \"Hand_11_R.png\"      \"Hand_11_R.png\"        \"2D_Hand\"    \n    \"28\"    \"2D\"    \"Hand\"       \"12\"      \"Hand_12_R.png\"      \"Hand_12_R.png\"        \"2D_Hand\"    \n    \"29\"    \"2D\"    \"Hand\"       \"13\"      \"Hand_13_R.png\"      \"Hand_13_R.png\"        \"2D_Hand\"    \n    \"30\"    \"2D\"    \"Hand\"       \"14\"      \"Hand_14_R.png\"      \"Hand_14_R.png\"        \"2D_Hand\"    \n    \"31\"    \"2D\"    \"Hand\"       \"15\"      \"Hand_15_R.png\"      \"Hand_15_R.png\"        \"2D_Hand\"    \n    \"32\"    \"2D\"    \"Hand\"       \"16\"      \"Hand_16_R.png\"      \"Hand_16_R.png\"        \"2D_Hand\"    \n    \"33\"    \"2D\"    \"Object\"     \"01\"      \"Object_01_R.png\"    \"Object_01_R.png\"      \"2D_Object\"  \n    \"34\"    \"2D\"    \"Object\"     \"02\"      \"Object_02_R.png\"    \"Object_02_R.png\"      \"2D_Object\"  \n    \"35\"    \"2D\"    \"Object\"     \"03\"      \"Object_03_R.png\"    \"Object_03_R.png\"      \"2D_Object\"  \n    \"36\"    \"2D\"    \"Object\"     \"04\"      \"Object_04_R.png\"    \"Object_04_R.png\"      \"2D_Object\"  \n    \"37\"    \"2D\"    \"Object\"     \"05\"      \"Object_05_R.png\"    \"Object_05_R.png\"      \"2D_Object\"  \n    \"38\"    \"2D\"    \"Object\"     \"06\"      \"Object_06_R.png\"    \"Object_06_R.png\"      \"2D_Object\"  \n    \"39\"    \"2D\"    \"Object\"     \"07\"      \"Object_07_R.png\"    \"Object_07_R.png\"      \"2D_Object\"  \n    \"40\"    \"2D\"    \"Object\"     \"08\"      \"Object_08_R.png\"    \"Object_08_R.png\"      \"2D_Object\"  \n    \"41\"    \"2D\"    \"Object\"     \"09\"      \"Object_09_R.png\"    \"Object_09_R.png\"      \"2D_Object\"  \n    \"42\"    \"2D\"    \"Object\"     \"10\"      \"Object_10_R.png\"    \"Object_10_R.png\"      \"2D_Object\"  \n    \"43\"    \"2D\"    \"Object\"     \"11\"      \"Object_11_R.png\"    \"Object_11_R.png\"      \"2D_Object\"  \n    \"44\"    \"2D\"    \"Object\"     \"12\"      \"Object_12_R.png\"    \"Object_12_R.png\"      \"2D_Object\"  \n    \"45\"    \"2D\"    \"Object\"     \"13\"      \"Object_13_R.png\"    \"Object_13_R.png\"      \"2D_Object\"  \n    \"46\"    \"2D\"    \"Object\"     \"14\"      \"Object_14_R.png\"    \"Object_14_R.png\"      \"2D_Object\"  \n    \"47\"    \"2D\"    \"Object\"     \"15\"      \"Object_15_R.png\"    \"Object_15_R.png\"      \"2D_Object\"  \n    \"48\"    \"2D\"    \"Object\"     \"16\"      \"Object_16_R.png\"    \"Object_16_R.png\"      \"2D_Object\"  \n    \"49\"    \"3D\"    \"Face\"       \"01\"      \"Face_01_L.png\"      \"Face_01_R.png\"        \"3D_Face\"    \n    \"50\"    \"3D\"    \"Face\"       \"02\"      \"Face_02_L.png\"      \"Face_02_R.png\"        \"3D_Face\"    \n    \"51\"    \"3D\"    \"Face\"       \"03\"      \"Face_03_L.png\"      \"Face_03_R.png\"        \"3D_Face\"    \n    \"52\"    \"3D\"    \"Face\"       \"04\"      \"Face_04_L.png\"      \"Face_04_R.png\"        \"3D_Face\"    \n    \"53\"    \"3D\"    \"Face\"       \"05\"      \"Face_05_L.png\"      \"Face_05_R.png\"        \"3D_Face\"    \n    \"54\"    \"3D\"    \"Face\"       \"06\"      \"Face_06_L.png\"      \"Face_06_R.png\"        \"3D_Face\"    \n    \"55\"    \"3D\"    \"Face\"       \"07\"      \"Face_07_L.png\"      \"Face_07_R.png\"        \"3D_Face\"    \n    \"56\"    \"3D\"    \"Face\"       \"08\"      \"Face_08_L.png\"      \"Face_08_R.png\"        \"3D_Face\"    \n    \"57\"    \"3D\"    \"Face\"       \"09\"      \"Face_09_L.png\"      \"Face_09_R.png\"        \"3D_Face\"    \n    \"58\"    \"3D\"    \"Face\"       \"10\"      \"Face_10_L.png\"      \"Face_10_R.png\"        \"3D_Face\"    \n    \"59\"    \"3D\"    \"Face\"       \"11\"      \"Face_11_L.png\"      \"Face_11_R.png\"        \"3D_Face\"    \n    \"60\"    \"3D\"    \"Face\"       \"12\"      \"Face_12_L.png\"      \"Face_12_R.png\"        \"3D_Face\"    \n    \"61\"    \"3D\"    \"Face\"       \"13\"      \"Face_13_L.png\"      \"Face_13_R.png\"        \"3D_Face\"    \n    \"62\"    \"3D\"    \"Face\"       \"14\"      \"Face_14_L.png\"      \"Face_14_R.png\"        \"3D_Face\"    \n    \"63\"    \"3D\"    \"Face\"       \"15\"      \"Face_15_L.png\"      \"Face_15_R.png\"        \"3D_Face\"    \n    \"64\"    \"3D\"    \"Face\"       \"16\"      \"Face_16_L.png\"      \"Face_16_R.png\"        \"3D_Face\"    \n    \"65\"    \"3D\"    \"Hand\"       \"01\"      \"Hand_01_L.png\"      \"Hand_01_R.png\"        \"3D_Hand\"    \n    \"66\"    \"3D\"    \"Hand\"       \"02\"      \"Hand_02_L.png\"      \"Hand_02_R.png\"        \"3D_Hand\"    \n    \"67\"    \"3D\"    \"Hand\"       \"03\"      \"Hand_03_L.png\"      \"Hand_03_R.png\"        \"3D_Hand\"    \n    \"68\"    \"3D\"    \"Hand\"       \"04\"      \"Hand_04_L.png\"      \"Hand_04_R.png\"        \"3D_Hand\"    \n    \"69\"    \"3D\"    \"Hand\"       \"05\"      \"Hand_05_L.png\"      \"Hand_05_R.png\"        \"3D_Hand\"    \n    \"70\"    \"3D\"    \"Hand\"       \"06\"      \"Hand_06_L.png\"      \"Hand_06_R.png\"        \"3D_Hand\"    \n    \"71\"    \"3D\"    \"Hand\"       \"07\"      \"Hand_07_L.png\"      \"Hand_07_R.png\"        \"3D_Hand\"    \n    \"72\"    \"3D\"    \"Hand\"       \"08\"      \"Hand_08_L.png\"      \"Hand_08_R.png\"        \"3D_Hand\"    \n    \"73\"    \"3D\"    \"Hand\"       \"09\"      \"Hand_09_L.png\"      \"Hand_09_R.png\"        \"3D_Hand\"    \n    \"74\"    \"3D\"    \"Hand\"       \"10\"      \"Hand_10_L.png\"      \"Hand_10_R.png\"        \"3D_Hand\"    \n    \"75\"    \"3D\"    \"Hand\"       \"11\"      \"Hand_11_L.png\"      \"Hand_11_R.png\"        \"3D_Hand\"    \n    \"76\"    \"3D\"    \"Hand\"       \"12\"      \"Hand_12_L.png\"      \"Hand_12_R.png\"        \"3D_Hand\"    \n    \"77\"    \"3D\"    \"Hand\"       \"13\"      \"Hand_13_L.png\"      \"Hand_13_R.png\"        \"3D_Hand\"    \n    \"78\"    \"3D\"    \"Hand\"       \"14\"      \"Hand_14_L.png\"      \"Hand_14_R.png\"        \"3D_Hand\"    \n    \"79\"    \"3D\"    \"Hand\"       \"15\"      \"Hand_15_L.png\"      \"Hand_15_R.png\"        \"3D_Hand\"    \n    \"80\"    \"3D\"    \"Hand\"       \"16\"      \"Hand_16_L.png\"      \"Hand_16_R.png\"        \"3D_Hand\"    \n    \"81\"    \"3D\"    \"Object\"     \"01\"      \"Object_01_L.png\"    \"Object_01_R.png\"      \"3D_Object\"  \n    \"82\"    \"3D\"    \"Object\"     \"02\"      \"Object_02_L.png\"    \"Object_02_R.png\"      \"3D_Object\"  \n    \"83\"    \"3D\"    \"Object\"     \"03\"      \"Object_03_L.png\"    \"Object_03_R.png\"      \"3D_Object\"  \n    \"84\"    \"3D\"    \"Object\"     \"04\"      \"Object_04_L.png\"    \"Object_04_R.png\"      \"3D_Object\"  \n    \"85\"    \"3D\"    \"Object\"     \"05\"      \"Object_05_L.png\"    \"Object_05_R.png\"      \"3D_Object\"  \n    \"86\"    \"3D\"    \"Object\"     \"06\"      \"Object_06_L.png\"    \"Object_06_R.png\"      \"3D_Object\"  \n    \"87\"    \"3D\"    \"Object\"     \"07\"      \"Object_07_L.png\"    \"Object_07_R.png\"      \"3D_Object\"  \n    \"88\"    \"3D\"    \"Object\"     \"08\"      \"Object_08_L.png\"    \"Object_08_R.png\"      \"3D_Object\"  \n    \"89\"    \"3D\"    \"Object\"     \"09\"      \"Object_09_L.png\"    \"Object_09_R.png\"      \"3D_Object\"  \n    \"90\"    \"3D\"    \"Object\"     \"10\"      \"Object_10_L.png\"    \"Object_10_R.png\"      \"3D_Object\"  \n    \"91\"    \"3D\"    \"Object\"     \"11\"      \"Object_11_L.png\"    \"Object_11_R.png\"      \"3D_Object\"  \n    \"92\"    \"3D\"    \"Object\"     \"12\"      \"Object_12_L.png\"    \"Object_12_R.png\"      \"3D_Object\"  \n    \"93\"    \"3D\"    \"Object\"     \"13\"      \"Object_13_L.png\"    \"Object_13_R.png\"      \"3D_Object\"  \n    \"94\"    \"3D\"    \"Object\"     \"14\"      \"Object_14_L.png\"    \"Object_14_R.png\"      \"3D_Object\"  \n    \"95\"    \"3D\"    \"Object\"     \"15\"      \"Object_15_L.png\"    \"Object_15_R.png\"      \"3D_Object\"  \n    \"96\"    \"3D\"    \"Object\"     \"16\"      \"Object_16_L.png\"    \"Object_16_R.png\"      \"3D_Object\"  \n\n","truncated":false}}
%---
%[output:547711d6]
%   data: {"dataType":"text","outputData":{"text":"Initializing default order rules...\n\tView_x_Category (6 x 6): allowing 0 to infite occurances...\nInitializing default per-half count rules...\n","truncated":false}}
%---
%[output:97987fba]
%   data: {"dataType":"text","outputData":{"text":"    <strong>ID<\/strong>       <strong>Label<\/strong>   \n    <strong>__<\/strong>    <strong>___________<\/strong>\n\n    1     \"2D_Face\"  \n    2     \"2D_Hand\"  \n    3     \"2D_Object\"\n    4     \"3D_Face\"  \n    5     \"3D_Hand\"  \n    6     \"3D_Object\"\n\n","truncated":false}}
%---
%[output:2ecebbee]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAA\/wAAAJmCAYAAADhK4tqAAAAAXNSR0IArs4c6QAAIABJREFUeF7snQmYVcW1theDIJOIIjIYcUIERY0TEgW9Jg5E4sSgKL+iBBUIoIKCE\/wgKE4o+iMqYpTgEK5GJXo1xuslKhLnOCHTFTEyhHlqEJn+5yuz231On+4+p8+u7n3Oeet5fBLpvdeueldV41dr1apqe+211y6jQQACEIAABCAAAQhAAAIQgAAEIJBXBKoh+PPKnwwGAhCAAAQgAAEIQAACEIAABCDgCCD4mQgQgAAEIAABCEAAAhCAAAQgAIE8JIDgz0OnMiQIQAACEIAABCAAAQhAAAIQgACCnzkAAQhAAAIQgAAEIAABCEAAAhDIQwII\/jx0KkOCAAQgAAEIQAACEIAABCAAAQgg+JkDEIAABCAAAQhAAAIQgAAEIACBPCSA4M9DpzIkCEAAAhCAAAQgAAEIQAACEIAAgp85AAEIQAACEIAABCAAAQhAAAIQyEMCCP48dCpDggAEIBBHAnfeead16tSpRNeWLl1qQ4cOtUWLFpX4WdOmTW3ChAm2\/\/77l\/jZW2+9ZcOGDSv+8yeeeMJat27t\/v2HH36wiRMn2vTp0+OIgj5BAAIQgAAEIACBSiGA4K8UzHwEAhCAAARKE\/xbtmyxe++911555ZUSkE477TS78cYbrX79+gh+phAEIAABCEAAAhDIkACCP0NgPA4BCEAAAhUjUJrgl7WXXnrJxo0bV8LwwIEDrWfPnlatWjUEf8Ww8xYEIAABCEAAAgVMAMFfwM5n6BCAAAQqk0BZgn\/u3LnWt29f2759e0KXHn74YTvqqKNSdjM5pb8yx8K3IAABCEAAAhCAQC4QQPDngpfoIwQgAIE8IJAs+Hft2mX6p3r16rZ27VqXuv\/pp58Wj7RNmzYu6t+kSRPbsWOH+6dWrVrFP0fw58GkYAgQgAAEIAABCHglgOD3ihfjEIAABCAQEEgW\/OvWrXPF9STo9b9TpkyxqVOnFgPr0aOHDRgwwIl8bQioNWrUqFTBX1bRvvbt29uYMWOKawFos2DUqFHWu3dvO+OMM2yvvfay3XbbzbZu3Wqff\/65KxS4cOFCnAcBCEAAAhCAAARymgCCP6fdR+chAAEI5A6BZMGv6vxLliyx448\/3g0iOWI\/YsQI69y5s\/vZvHnzrEGDBta8efNIBP+HH37oRP5BBx2UEqA2GO666y6bOXNm7gCmpxCAAAQgAAEIQCCJAIKfKQEBCEAAApVCIJXgl8jv3r271ahRw8LX8zVs2NAmTZpkBx54oOvbq6++aocffnjC9XyZXMuXHOHX8QB9s6z22WefuQyD5LoClQKLj0AAAhCAAAQgAIEICCD4I4CICQhAAAIQKJ9AKsE\/bdo069+\/v0u1D1\/P16FDB5dyr6i+0v0feOAB+81vfmOtW7cu\/lA2gl9GZFcbCSoMuOeee5oyClQ3IGjr16+3W265xZQNQIMABCAAAQhAAAK5SADBn4teo88QgAAEcpBAKsGvonzDhg2zFi1auBEF1\/OpYv9ll13movArVqyw4cOHu+eiEvwqFjhjxoyEqwDDmwzqy6ZNm+yOO+6wN998Mwdp02UIQAACEIAABCBghuBnFkAAAhCAQKUQSBb8Or9\/7bXX2vXXX198jj+4nm\/8+PEl\/uyxxx6LTPAXFRXZyJEjbdasWcVj1\/GBe+65p7hOgDIAJk6caNOnT68UPnwEAhCAAAQgAAEIRE0AwR81UexBAAIQgEBKAsmCX4X4VCV\/4MCB1rNnT6tWrZqrxi\/RrbPzQYE+pd2PHj3awlX49YFsUvpTpesj+Jm4EIAABCAAAQjkGwEEf755lPFAAAIQiCmB0gT\/2WefbUOGDLE6deq4c\/VKoT\/llFOK\/13F+5599ll3bV\/btm2LR5eN4A8XCAwMIvhjOnHoFgQgAAEIQAACFSaA4K8wOl6EAAQgAIFMCJQm+HU1nqL6zZo1c+YUfVeVfjVF\/G+88Ub79NNPLfl9BH8m9HkWAhCAAAQgAIFCJIDgL0SvM2YIQAACVUCgNMGvrqhS\/lFHHVWiV4sWLbJ+\/fq5TQAEfxU4jU9CAAIQgAAEIJDTBBD8Oe0+Og8BCEAgdwiUJfhVhf\/cc88tMZiZM2e6CL8agj93fE1PIQABCEAAAhCIBwEEfzz8QC8gAAEI5D2BsgR7165dbdCgQVarVq1iDjrPr3P7U6dORfDn\/exggBCAAAQgAAEI+CCA4PdBFZsQgAAEIFCCQFmCv02bNjZu3Dhr0qRJ8XsbN250V+fNnj0bwc98ggAEIAABCEAAAhUggOCvADRegQAEIACBzAmUJfhr1qxpkydPtsMOO6zY8LfffmuDBw+25cuXuz\/T9X0XX3xx8c8p2pe5D3gDAhCAAAQgAIHCIoDgLyx\/M1oIQAACVUagvDP4I0aMsM6dOxf3b9asWTZ06NDif0fwV5nr+DAEIAABCEAAAjlKAMGfo46j2xCAAAQgAAEIQAACEIAABCAAgbIIIPiZHxCAAAQgAAEIQAACEIAABCAAgTwkgODPQ6cyJAhAAAIQgAAEIAABCEAAAhCAAIKfOQABCEAAAhCAAAQgAAEIQAACEMhDAgj+PHQqQ4IABCAAAQhAAAIQgAAEIAABCCD4mQMQgAAEIAABCEAAAhCAAAQgAIE8JIDgz0OnMiQIQAACEIAABCAAAQhAAAIQgACCnzkAAQhAAAIQgAAEIAABCEAAAhDIQwII\/jx0KkOCAAQgAAEIQAACEIAABCAAAQgg+JkDEIAABCAAAQhAAAIQgAAEIACBPCSA4M9DpzIkCEAAAhCAAAQgAAEIQAACEIAAgp85AAEIQAACEIAABCAAAQhAAAIQyEMCCP48dCpDggAEIAABCEAAAhCAAAQgAAEIIPiZAxCAAAQgAAEIQAACEIAABCAAgTwkgODPQ6cyJAhAAAIQyE8CvXv3to8\/\/tg+++yz\/Bwgo4JAhARYLxHCxBQEIJCzBBD8Oes6Og4BCEAAAoVE4OSTT7abbrrJ3nvvPRs1alQhDZ2xQiBjAqyXjJHxAgQgkKcEEPx56liGBQEIQAAC+UXgtttus1\/96le2fv16GzdunM2cOTO\/BshoIBAhAdZLhDAxBQEI5DQBBH9Ou4\/OQwACEIBAoRBQxPLmm2+2Pffc0\/7xj3\/Y2LFjrV+\/frZgwQJ74oknCgUD44RAWgRYL2lh4iEIQKAACCD4C8DJDBECEIAABPKDwMiRI+3MM8+07du3u3\/q1Klj3333nV177bXuf2kQgMBPBFgvzAYIQAACZgh+ZgEEIAABCFQagfr167tvbdq0qdK+mU8f6tmzp1111VVWu3Zt27Ztm82ePdsmTZpk33zzTT4Nk7GECLBmKj4dWC8VZ8ebEIBA\/hBA8OePLxkJBCAAgdgSqFmzpl122WXWrVs3V2F+2LBhse1rXDvWo0cPGzBggNWqVct1cceOHfbcc8\/Z\/fffH9cu068sCLBmsoBnZqyX7PjxNgQgkD8EEPz540tGAgEIQCC2BCRe7r33XjvhhBNs8+bNNmHCBJsxY0Zs+xvHjjVs2NBuvfVW+\/rrr03nkw888EBbsWKF+zOu6Yujx7LrE2smO36sl+z48TYEIJA\/BBD8+eNLRgIBCEAg1gSOOeYYGzNmjDVq1MjmzJlj1113nas4TytJQIX5LrroIjv66KOtRo0aNnfuXHv66adt2bJl7uGuXbvawIEDXWr\/W2+9RcZEnk4i1kx6jmW9pMeJpyAAgcIkgOAvTL8zaghAAAJVQmD48OF2zjnn2A8\/\/OAqy1NdPtEN4TRuiZhwU92DKVOm2LPPPmvh6K\/+\/O6777bXX3+9SnzKR\/0SYM2Uzpf14nfuYR0CEMgPAgj+\/PAjo4AABCCQEwSUhi5x2qJFC1u6dKkNHTrUFi1alBN9991JiZcbbrjBzjrrLCfoxefDDz+0Aw44wNq0aWO77babffXVV3bjjTe6VP7wtWNffvmlDRkyhIwJ306qAvusmdTQWS9VMBn5JAQgkJMEEPw56TY6DQEIQCB3CfTu3dv0j4rP6Rz\/uHHjcncwEfY8SNOvXr2646JifLp6T+3UU0+1ww47zKZOnepqIASN6G+EDoixKdZMSeewXmI8YekaBCAQKwII\/li5g85AAAIQyE8Cikaff\/75pjT1Xbt2WfPmzd1Z\/rVr19rYsWNt1qxZ+TnwNEelaOXkyZOdqFcBPlXjD8R+WSYU\/b3nnnscT13Np7oIwTn\/ND\/NYzElwJop3TGsl5hOWroFAQjEkgCCP5ZuoVMQgAAE8oNA3bp17aabbrJOnTq5lPRU7f3333fp6OkI3PygUnIUStlXpkOTJk1ccb4HH3ww7aGGo7\/vvvuuvfHGG9a9e3f7y1\/+YtOnT0\/bDg\/GgwBrpnw\/sF7KZ8QTEIAABAICCH7mAgQgAIGICLRv394uueQSO+SQQ5y4Xbdunaug\/oc\/\/MH9\/0JsI0eOtDPPPNO2bdtmf\/vb32zatGm2YcMGV4H+7LPPtvr163NNn5kdd9xx7gYDXSWWjuBX9PfII4+0hx56yL2jKw8PP\/zwhCm2atUqd97\/iy++iO3UY82UdA1rpvzpWqjrpXwyPAEBCECgJAEEP7MCAhCAQJYElKaus9QdOnRw59KTmwqs3XXXXQWXtq7\/KB89erTtscce9uKLL7rU83DTuXQVqVNq\/8KFC901c\/m6MaI5csYZZ9jPfvYzd0PB7NmzXUG+oOnP77vvPlfM8IMPPrBBgwaVOiuVMdGlSxdbuXKlm3cq5BdmqRc15yZNmmSvvfZalrPbz+usmdRcWTM\/cmG9+Fl3WIUABAqTAIK\/MP3OqCEAgYgI6CypzqB37NjRRbE\/+ugjV3BNTdfPHXvssW4TQGfVJfpnzpwZ0Zfjb6Z\/\/\/7Wq1cvJ+IVaf70009LdLpnz5521VVXmQrVKfr\/6KOPxn9gZq6KfrNmzeyf\/\/xnmf1VerbO4yuboXbt2sXPqo7B8uXL7YEHHiieE+PHj3ebRporI0aMSNgQCH+kR48ezqY2Dm655RZ77733ikXSL3\/5S1u9erW98847sT0iwZopfcrk65phveTErzU6CQEI5CkBBH+eOpZhQQAClUPgyiuvdKJ2586d9sgjj9gzzzyT8OFA0ErszZ0716699tq8jWInE1fE\/uKLLy7z+r3wffIqNqeI9fz58yvHeRX8iq7N69evnzu2IcH98ccfp7SkKKVS7du2bevmhwS+Nj\/0502bNnWbHJs2bbKHH37Ynn\/+ebdBpKJ7mis6CnLzzTenFO2lCf4KDqfSX2PNlI48H9cM66XSlxgfhAAEIJBAAMHPhIAABCBQQQLhStFK0ZZYC7fk6O7WrVvdmet8KqQmBjo7rnP5ixYtShh\/IF42btxoOpcsRqnaaaed5jIA6tWr5wrNjRo1qoIeqZzXJMwHDx5s8m9pwjwcxRYbbQa98MILxR3UjQXKbND5e0X0tXGg6vwq1nf00Ueb5kqqDSQZ0DGJ008\/3b799lvXD20k5EpjzfyYHVJIa4b1kiurk35CAAL5SgDBn6+eZVwQgIB3AuEr0ZILremMdd++fV3VdUV3dc5a164F6dfeO+f5AypMOHToUBe9VqRbKer\/+7\/\/a3feeWdxkTilsav6vo40KF1fkexUTdHuCRMm2P777+8i4DoioZT0uDYJtrvvvttF6bWB8\/bbb5foqjYxdNZezz7xxBPun3DTn6t+gRgp0h\/cVKBifEFdg82bN9vjjz9uTz31lHtV72hOXXjhhTl3BCIYO2um8NYM6yWuv8noFwQgUCgEEPyF4mnGCQEIVIiAorj\/8R\/\/4e5HLyoqsjfffLM45TzV1VA6y3\/FFVfYoYce6kSZiqdJ6L\/88stOsCm9VdfPxbWYWjqQunbtaldffbWrsJ\/clixZ4oSu0vJ1xl1n1Pfbb78y0\/plQ4K4devWztw\/\/vEPV8Avl6\/pC85iK\/qujZGvv\/66GJXmiH7esmVL92cqvhfMEf27UvYV\/dfc00aKzuTrGW0w6DiA\/kybDMoKiCMj1kzJVcSaKfs3SyGvl3R+5\/IMBCAAgWwIIPizoce7EIBA3hKQOL\/sssusW7duTmQFTYX5VEX9tttuswYNGhRXVlcEX6LsxBNPdBFtpWS\/8sorNnHiRHftnMSaivYpMi6xNmzYsJxkp6vgNPZ99tnHFi9e7CL32ggRp2OOOcaNSWnuOouvds0117ifafOjtHT9IOrbuHFjq1atmhO04pYLRx\/kTx3lULHGKVOmFPv01ltvtV\/\/+tcJGx0HHHCAO\/sfzBFlMzz33HP25JNPOuEuoaxCfPr\/qrqvSv2aN2ISNKX\/67x\/8E6cJhFrJrU3WDM\/cWG9xGnF0hcIQKBQCCD4C8XTjBMCEEibgISXzpwrEqumCKv+UaRa58wlSN944w1XST2orB4Yl2D7+9\/\/7q5E++abb4q\/GU5lliDOJcEf1CKQcNFVct27d3dHEyRqtZmhFr4LXoXolPL++uuvu80SnUvXf+iLzR\/\/+EeXBh9uEsznnXeeO8Nep04dV9ww2ChJ22lV8ODee+\/txibfLl261EXygzoGQf0CCXTVJOjUqVNxpf5gjtx\/\/\/2mQoVHHXWUi\/jrar7k6vy6pk2V+2vUqOEyH+JafZ81kzgBWTMlFyTrpQp+SfFJCEAAAmaG4GcaQAACEEgiIOEmAapIqwSq0q31\/5WiriJpq1atMok1\/Vm4IJXS91WVXYI+uYXT\/1966SUbN25cznDXuXJVjJeol5hXS1WEL3hOIn\/OnDku8r1+\/fqEO+JVz0CCXgxUzC64ulCbKBLPil7nUuvdu7fpH2V1hDMYgkr6qm+grBD9XGPXUQedyw+f+w82B8Q2fM1eLnFgzSR6izWTevayXnJpVdNXCEAgXwgg+PPFk4wDAhCIhICi2HfccYc1atTIZsyYUa4wD18rJ2H34osvuqh\/cgsE0ffff2+33367qwWQS00p+hLnSi9PjmaHxxE8pyh2uFjdSSed5IrRqYhhcist8l8ZfIJNHG3IKCsh02KB4cyGcMHBcP0CjSNcyyF5XIHg1+aIBL+yKHKpsWZSeysf1wzrJZdWJn2FAAQg8CMBBD8zAQIQgECIwEUXXeTOWUu8K4o9a9ascvno7PqYMWPcJkFySn\/43LbEcmkbAuV+pIofCB9JKOuavfBzKuB3\/fXXF6e5K81ZET4VQVQWgBgvXLjQVaGvqtsLzjjjDNdHFSAMKuWHC+Gpnyq49vOf\/9x54JNPPnFZCBL3QSvNRnDfvDaFFNFXlkRykT39TMcXJJoXLFjgihVK+OdSY82k9lY+rhnWSy6tTPoKAQhAAMHPHIAABCBQgkCm6dUSahLy++67rytQJ9GfqmkjQJX5FUWOY2V13R6g694OOuggd82eChCqDkH4NoGwgC0r+yHd5+Iy\/XSVoM7Yy0fhYoHanBCTcNFG9VliX0c9wlftpbKh9+677z53w4M2N1T34Z577imue6ANEGV+\/OpXv3Lp\/o888og988wzccGSdj9YM4W1ZlgvaS8NHoQABCAQCwJE+GPhBjoBAQhUFgFF3BWxlQjTGXJVgg9Hl4Oz1+pPWZXiVYBKqflHHHGESwNXEb7ku+llI4hi\/\/73v095X7uvcQdX5gVn7kv7TtDndu3auUr64aaCc7pZYObMme6PwwJWP1P6+ccff1zCtNLcdayhbdu2VtZzvsaeqd1whoYyDiRgO3fu7K7G09l7Xa2ncUigt2jRwm2IaHPghRdecLUc1FLZ0MZA8lEG\/ZkK9akpPVpMk21l2n\/fz7NmEgkX+pphvfhecdiHAAQgEC0BBH+0PLEGAQhUMgGlREtgqop+WU3iShH44Eq04FldnxeOrKpienCGf\/bs2a7wXGlN0VoJunnz5rlU9aBJGGpDQU0F6oJK9pWBJnw1mm4JKOs+e139pnP1ykoQB103qNRzVYY\/5ZRTnNgNF99T\/8NFClWcMFWaevJzqVLlK4NFJt8Irg\/UOzp2ocwNCV1lMgQFGvUzMbv22mtdLQIxCxcaDGwoWv+f\/\/mf7mdq2hTShtDBBx+ccMWeflbW2f5M+p\/Js6yZRFqsmUxmz4\/PFtJ6yZwOb0AAAhCIFwEEf7z8QW8gAIEMCCgN\/bLLLnNX5SnarGvdUrWzzz7bBgwY4IStxJiq7CvyLtGmaG1yFDq4ai98vVwqu0Fqa7Lgz2AIkT8ajq4np6iHP3booYe6DIXmzZu7yvGqQaDodtCCgmM6fjBt2jR79NFH3Y\/CRQq1kTFhwgQnipObnhs7dqzbYNF1cvr\/EreV2dQHVUv\/xS9+4a7Ok0DXOfn\/+Z\/\/KTFXtCEkv0vkFxUVuXF+++23Kc\/UhzdKtKmiTSFF7cM2NFZdWxjMSdlT6r7qFzRu3NjNQfVDaf6VecSDNVNyBrJmfmTCeqnM3058CwIQgEDlEUDwVx5rvgQBCEREIDmldseOHS4qq4h7cgvEmVKnFy9e7O6AD65E69mzp0vbrl27trtKL4hWhwtTKUKviG64SJu+IZGgCG6rVq3cu4rgxqWFo\/BBinpy\/3Xfu8SfCusNGjSoOM08GIM2SLp37+7YJFflD6f0JmcAhBlIAOvowxdffFGpaJRhocKLGl9wtCHcAW36fP31124TI3w9XnCcQ5kNaq+++qqNHj06Zd+DWxdkK7whojl19dVXu42k8DV9lQogxcdYM2V7oJDXDOulqlcn34cABCDglwCC3y9frEMAAhES0H+YSogqYi8hqlZWSrREvkS5xM67777rIq7h9HrZU1RXafzJ0epx48a5Qm5qOqeuDIJANCsSppRWiQRFjVWI7\/XXX49wpNmZCqLr6r82Q5577rnis+aBZRWca926tbuFQOI1aHp38ODBbmz6\/ypIqJZcpK+0DIDsep7928cff7yLuCtSr6ZMDkXsFVFXZF3ZIBLjasqAEBsVJ1SUXePVfDn66KPdz1966aVSr2VUhoQ2mPbZZx\/79NNPnchXC9soL0Mk+9GWb4E1Uz6jwG\/KQim0NcN6SW9+8BQEIACBXCaA4M9l79F3CBQIgfAZ26BiuoT2K6+84grrlXZGXhsDQ4YMcZTuvfde93xY2Or8uqLAgQAMR6v1Hb2jwnNqEvsfffSRE4k6361UeInEuF6zF47CJ6eXazxTpkxxY9OY+\/Tp48aoiLyuqGvfvr0b25\/+9Cd3nl8bJuE75vWsUuS10aEidskZAFU1LcOp9snXIwZ9Cl+TqEi+NgTCPpQNbWYog0Pp+NpgKi3lXtH\/008\/3WVHaNNEWQNq4QwRHWcoq46CL1asmczJFtqaYb1kPkd4AwIQgEAuEkDw56LX6DMECohAx44drX\/\/\/tayZUsXbS5NyKVCEqRo6x0V4nvzzTfdYxLzivbrfLkEn85hK2KbfF49\/FxyBftUV7NVhlskRNO9pz1IO1ffdexAQjZoujpPEe+nn37ajV+RPh1LkIDXBsrjjz9uTz31lF1yySXWt29fl1GRLF5VqFD\/SFw++eSTNnny5MpAkPIb4WwORdYffvhhe\/7550vtT69evey3v\/2tG1dy4caRI0famWee6TiozkEwb5KNlXUdXWBD86us2x58AGPNJFJlzZScZawXHysPmxCAAATiSQDBH0+\/0CsIFDwBRZUl9I899lhXLX7Xrl0lzuCXB6lDhw5O2CsCK9Gl1PywsA2EoQq53Xbbba6In56VMFYhu6Apon\/eeee5TYctW7a4NHile1dm9X3x0DGCILIeXJVXFoNwEbmy0svDkT5lA+ju+MB+mzZtXFp7UJVeRwGC++clpOSjTz75xF577bXy3OH150qpl4hPPlNf1keV+i+\/KsNDtQyU3bBo0SKXwRHMh7JuGAgEv5hpznz11VcJcyawofmlZ9PdqKkoKNZMIjnWTOkzifVS0VXGexCAAARyjwCCP\/d8Ro8hUBAEguJnEvsSq7rmTFHnTCqaK\/Ks9wNhrhR\/CS8J1WRhG1Tc18ZCcjQ8DsCDaHqqSHt5orZr166mKH+q9PJwhXKJ3ptuuilhsyMs+PUdiVadcw8fj6hqPuECipmI6\/CNA8m1DpQBEWwghDc5grHqXW0iaXOgtNR\/ZVhccMEF9v3335c4UuKDGWsmkSprJvUsY734WH3YhAAEIBBfAgj++PqGnkGgoAmEi58pLTpcCT0VGD0fCLSpU6eWeCR8PleiUFXqlcoetCBaq39PTvGOgyPSvTos6KuEqKLv7dq1c2I\/GFeyeD3ttNPsxhtvdBsjOtefzC4QTYpeK8NB0XBVr3\/ggQcy2nzxyVB1BnStoBiVVWgvVR90bZ9uZ1CKs67hU8HC5cuXu38PCj6GjzjIRrhoozIKdJRBxx+S20knnWSjRo1yhQJ1dEL2fDbWTCJd1kzq2cZ68bkKsQ0BCEAgfgQQ\/PHzCT2CAAT+TSBc\/KyswnDhM8srV65MuP88gCmB37lzZxfZD9+PHvxcAlYiWZsLuspNld31Z6numK8qB4WvDgvf\/x7uj9L4lfqv+gTBUQiNWQJW2QHJ7wV1DmQjWfDr+INYSeSrgrmuNdy4cWOJKwqrikfwXWUw6GpBNVXcf\/bZZzPqkm5q0PEPHdcIF3eUXW0EiZsyP1avXu3mj4436LpB\/Zmu9dMNDsmZJyoOqHdVAFHZA5V1jp81k+h61kzJpcB6yejXAw9DAAIQyHkCCP6cdyEDgEB+EwiKn2mUyVfDBWd0FcUOn\/OXgPvggw8SwATX0M2bN88Vmgu3QBQopV3HBn71q1+5c+q6wz5uLTh6kJyCnqoquwoL6to5FdRTBFxXjikirar0ulJOTVcSqqBho0aNXP0Cnd\/\/\/PPPTenh4qLodFxvIgh8E2xaaGNCmSAPPfRQRm679NJL3U0Fye8np\/yr+GOdOnWc7bVr17qigGKb6phJsIkQbAooiyCT4ygZDSDpYdZMIhDWTCIP1ks2q4t3IQABCOQeAQR\/7vmMHkOgoAiEC6gFV8Op+J6uS9N1V0AsAAAgAElEQVSZfEVf1RR5lUj\/85\/\/nFJYKVqviLXOoKsIXVCU7vzzz7errrrKdt99d5dyXVZl9ziAT3V12P777+82MXRVYHCTwezZs23ChAlOxKuFOUqsKiotjmrioc0AvRtuErgqxqfr9ypLrFaEsaLo2tBQZobqL+i2gUxa+H0dV9B1e0ELUv6VHi7b999\/v\/uR0v7LarrdQHPr5ZdfdpsQlcmPNZPoGdZMIg\/WSya\/HXgWAhCAQO4TQPDnvg8ZAQTynkBQQE0RWJ2\/l\/hSWrWazturgJxSpsuqmh++Xk7vKLVdUW1dTScx9sILLxSLubgDDa7bq1Gjhos0i4fO6St6r+i8ovepshOU6t+tWzfTe2FhrHR\/VZlXWrsyJWRH59kVva7q6vvp+OJnP\/uZy0zQlYLfffedS+8PNjrSeb8swa\/3xUYbImVF9NP5TmU+w5pJpM2a+YkH66UyVyLfggAEIFD1BBD8Ve8DegABCJRDIFxALXi0PHGbbFLp2YoC67x\/UMROz0gwq1Bdpue+q9Jp4ev2gn4ow0HF4xRRLq0lF6JTBkC4RkHdunWtVatW7qy+silyqSkqf\/rpp7saDOUVeEwelzJFhgwZ4rI8KnIkII6cWDOJXmHNJPJgvcRx1dInCEAAAn4IIPj9cMUqBCAQMYFwATWJdJ2RfuONNzL+ilK0u3Tp4o4CKO1dArmszICMP1BJL4SvHFO2gqrLS\/SX14Lzu4rkz5kzx3QXve\/74cvrUxQ\/DxerK62gYWnfCa7P0zy4\/fbb7c0334yiS1VugzWT6ALWzE88WC9VvjzpAAQgAIFKI4DgrzTUfAgCEMiGQLiAWkWiuNl8O47vhq9g0xGFVHfFp+p38nulXSkXxzGX1afw\/MikUF74vPtnn33makNU5nl7n5xZM4l0WTM\/8WC9+Fx52IYABCAQLwII\/nj5g95AAAJlEAjfma4z2jpbPX\/+\/IJlFo7S6YaB66+\/3hYtWlQuD3G84YYb3JVy5dU+KNdYjB4IF2fTplB5twsozVvHPNq2bWubNm1yxQlff\/31GI0o+66wZhIZsmZ+4sF6yX59YQECEIBALhBA8OeCl+gjBCBQTEAiX9fFqf3lL3+xUaNGFTSdoMK+ICRfW1iIYHSdoG5d0JENiX4d25g0aZIr0hhuOtbRt29fV\/wxnc2BXGbJmkn0HmvmJx6sl1xe2fQdAhCAQHoEEPzpceIpCECgHAIqEnbIIYe4CvA6Ez537lwvzA488EBXhV5X0AXX9L3zzjtevpWN0criUdZ1e9n038e7lcVEZ9evvvpqd02fmgS96htoXurqwaZNm5r6ov+v4xDTp0+3hx56yMeQy7RZWTxYM4luyJU1U1nzI1fWS6UvUD4IAQhAIE8IIPjzxJEMAwJVReCss86yiy66yA466CDTtXlBKyoqchF4Hynj4SvH\/vGPf9jAgQNjc+66Knho\/N27d3f833\/\/fVdxPk7n0KuCyRFHHGHXXnutHXbYYQm3MgTzU7c86DjI448\/7o42VGarCh6smUQPx3nNVMX8iPN6qcy1ybcgAAEI5CMBBH8+epUxQaASCChK1r9\/f2vXrl1KQRV0QWfL77zzTvvggw8i65XunVeVfp29\/uGHH9ymgqK0Vdmqkkd51+1VFZeqZBKMWX349a9\/bQcffLCbpxL6yj7585\/\/XOn1H6qSB2smcRXEcc1U5fyI43qpqt9bfBcCEIBAvhFA8OebRxkPBDwTUKGza665xk488UTT1W5qq1atsr\/+9a9OROnstApj6U70xo0bu5\/rGr277rrLZs6cGVnvdI5fV9Hp7vhMr2GLrBNmFhce4ev2JGgV3daRh6pocWFSFWNP9c248GDNJHonLmsmLvMjLuuFfkAAAhCAQLQEEPzR8sQaBPKWgK5xuuyyy6xbt27u\/LOaBOULL7xg06ZNK3GXvf4jdsSIEXbUUUe5s9JRi3L1Z+zYsS5lW1fLvfzyy5XKPo48VGVeRyuqgofgx41JpU6IFB+LGw\/WTKKTxKMq10zc5kdVrxe+DwEIQAACfggg+P1wxSoE8opA+\/bt3TVuEvES70qj\/\/vf\/27333+\/6Xq80po2Bu69916Xeq+70fOlqj48SnocJolM4AGPsv4SYH7k1V+RDAYCEIBArAkg+GPtHjoHgXgQkNDXmfkDDjjAVTV\/4okn3D\/ptPBdz3Guqp\/OWIJn4FGSFkwSmcADHmX9TmF+ZPIbl2chAAEIQCAbAgj+bOjxLgQKiIDua9ZVZzq3P2fOHLvuuuvcNWfpNJ3511EAXdn31ltv2bBhw9J5LdbPwKOke2CSyAQe8CjrlxjzI9a\/4ukcBCAAgbwhgODPG1cyEAj4JaDzpg8++KAdffTRGUf5w\/eAr1y50oYOHVrpFdKjpgOPkkRhksgEHvAo6\/cO8yPq38rYgwAEIACBVAQQ\/MwLCEDAETj55JNNVasPOeQQ9+8LFy50V9298847xYRUff\/666+3+vXr29KlS51wX7RoUVoEVcCvc+fOkV2j16VLF9Pd4u+++66NGzcurT5k8hA8StKCSSITXaN2yimnuKwX1bX429\/+Zp999lnCQ4W0ZuDB\/MjkdyzPQgACEIBA5RBA8FcOZ74CgdgSkMCXcG\/Xrp27pzzctm3bZq+99pq7Um\/79u3uRyNHjrQzzzzT\/f8ZM2akLba7du1qgwYNcuLo6aefdtkCFWkdO3Z0Ql\/V6NWnt99+226\/\/fYStwRUxLbegUdJcjBJZHLEEUe4aw91Q0R4zUj0p5qP+b5m4MH8qOjvW96DAAQgAAH\/BBD8\/hnzBQjElsBJJ53kqu83adLEioqKXOX9999\/36XtS1grkp9cpE9RvNtuu829s3btWnc13qxZs8odo6pSjxkzxtmsyDn+8F3Vu+22my1evNgeeughJ7CiavAoSRImiUxOPfVUt2YaNWrk1owyYfS\/uolCt1Kkuo0in9cMPJgfUf3+xQ4EIAABCPghgOD3wxWrEIg9AYkTRdkVvV2yZIn93\/\/7f+2LL74o7nf4P+S\/+eYbF9Fcvny5+\/nAgQOte\/fuJuGtDYIhQ4YUZwCUNvCw4H\/ppZfSzgyoW7eu9erVy84\/\/3wnqFasWOFuCPjzn\/9c7jczcQI8StKCSSKTMI8FCxaYjqlobahpQ+qOO+6w1q1bu42wG2+80T799NNiA\/m+ZuBh7vdT8DsVHpn89uVZCEAAAhDwSQDB75MutiEQYwKXXHKJ9e3b14lmpey\/\/vrrJXo7fPhwO\/fcc10EU2nJQSQ\/\/B+2ygDQf+Q+\/\/zzZY720ksvtT59+rhnpkyZYlOnTi2Xjs7pq4\/KJtB3XnnlFZs4cWJk6fvhDsCjpDtgkshENS4GDBhgOuqSas0EP9dbmqeqgRG0fFwz8GB+lPtLnAcgAAEIQKDKCSD4q9wFdAACVUMgKKJXVvG9sgRM8DOdyVdasyKY69atSzmYQw891J2zb9GihaVTpT98ZnzHjh3uGsB77rnHfcdXg0dJsjBJZKI5fvHFF5dasDLIYtH1k\/fee6\/boAq3fFsz8GB++Pp9jF0IQAACEIiOAII\/OpZYgkBOEQjE3LJly1zRvq+\/\/rpE\/wOBItGdLGB0pZT+7IQTTnARz2nTptmjjz5awsYBBxxgo0ePtlatWrnnXnzxRRs\/fnxKVkqLHjx4sHXo0MEdF\/BxTr80J8GjdMHPHPmRTSBwU6Xs6+fKYFEmi46dqECluIVbvq0ZeKQW\/MyPnPqrkM5CAAIQyHsCCP68dzEDhEBqAkqVv+yyy1xK\/+TJk+2pp54q8WB5\/0Gva9puvvnm4rP1t956a\/G1ZBI3st+tWzf38507d7oCe7fcckvKs\/eq9K0sgH322cdlCjz33HP25JNPRnpOv6y5AI+SdGCSyERi\/oorrrD169fbfffdZzNnzix+QPNXG1vatNq0aZP7c1Xt17WWqjkRiP98WjPwYH7w9ysEIAABCMSfAII\/\/j6ihxDwQkCVwxVN193hEtebN28u8Z0HHnjAjj\/+eFu0aJH169fPCZ3kpnP+55xzjvvjv\/zlLzZq1ChX4b9\/\/\/7WsmVLq1atmhM+KrJ3\/\/33lyngFWVXlfPHHnusRHTUC4SQUXiUJAyTRCbauNKcDhfj0xM9e\/Z0kX39PFVT9ozWxfz5892P82XNwIP54fv3MvYhAAEIQCB7Agj+7BliAQJ5SeDAAw905+abN29ur776qotepmrh5xTZVCRTafxKyZd4r8y0fJ+OgEdJujD5kYk2vLR5psrs2qz68MMP7bTTTnMFJ4NNr\/BVlPm+ZuCRuFbg4fM3M7YhAAEIQKA8Agj+8gjxcwgUKIGyzu8nI7nyyivd1XkS+UHzdX1eVbkDHiXJw+RHJg0bNrR27drZ3\/\/+94QMFkXAlfp\/2GGHuZsudGTlzTffdO\/k85qBR+JagUdV\/dbmuxCAAAQgIAIIfuYBBCCQkoAK66l43rfffuuil8uXLy+VlP6DVs+3bdvW+\/V5VeUueJQkD5PyZ2NwtaFqWqgmheplBJsE+b5mUtGBRyIVeJS\/hngCAhCAAASyI4Dgz44fb0MgLwnoGj2l86uA3ksvvWTjxo0rMc5jjjnGnc3\/4osv3M\/OOuss++Uvf2mPPPKI1+vzqgI4PEpSh0l6MzG4qq9+\/fr29NNP24MPPlj8Yj6vmdLowCORDDzSW0c8BQEIQAACFSeA4K84O96EQN4SUAEyXTGma\/TCacgasM7nq4DfiSeeaHPmzHFXlanSfz43eJT0LkzSm\/EnnXSSK9i3++67J0T403s7\/56CR6JP4ZF\/c5wRQQACEIgbAQR\/3DxCfyAQAwJBdX4VIZOgV3X+unXr2oABA+zss8+22rVru17qnP7dd9\/trh7L5waPkt6FyU9MlK5fq1atlDddXHPNNe5qyg0bNphuoVBBv3xv8Ej0MDzyfcYzPghAAALxJoDgj7d\/6B0EKp1AuIJ4kM7fpUsXV3G8SZMmrj9bt261V155xSZOnJhS5FR6pz1+EB4l4cLkJyZHHHGEDRs2zG2I6ejLBx98UPxDbY5pw2yPPfYwVenXdXz53uCR6GF45PuMZ3wQgAAE4k8AwR9\/H9FDCFQqgSDFVBX3Z8yYYUcffbQddNBBVr16ddu5c6d9\/vnn7nz\/woULK7VfVfUxeJQkD5OfmIwZM8ZdwVetWjW3EfbRRx\/Z0qVLrVWrVtamTRsX+dfRlyFDhti6deuqahpX2nfhkYgaHpU29fgQBCAAAQiUQgDBz9SAAAQSCARXrUmoBG3Xrl22ePFiV2E8uFasULDBo6SnYfITE6VrK1X\/lFNOceI+3FTUcvbs2S7yXwhiX2OHR+J6gUeh\/E3BOCEAAQjElwCCP76+oWcQqBICyWJOQuW5555zBcfyvThfKuDwKF\/wF\/ocEaEjjzzSzjvvPGvZsqUDpg2yF1980T777LMqWcdV\/VF4JHoAHlU9I\/k+BCAAgcIlgOAvXN8zcgikJHDUUUfZHXfcYfXq1XPRyQkTJtiyZcsKlhY8SroeJgW7HBg4BCAAAQhAAAI5RgDBn2MOo7sQ8E1AKai9evVylfcL5Zx+WUzhUZIOTHyvQuxDAAIQgAAEIACBaAgg+KPhiBUIQAACEIAABCAAAQhAAAIQgECsCCD4Y+UOOgMBCEAAAhCAAAQgAAEIQAACEIiGAII\/Go5YgQAEIAABCEAAAhCAAAQgAAEIxIoAgj9W7qAzEIAABCAAAQhAAAIQgAAEIACBaAgg+KPhiBUIQAACEIAABCAAAQhAAAIQgECsCCD4Y+UOOgMBCEAAAhCAAAQgAAEIQAACEIiGAII\/Go5YgQAEIAABCEAAAhCAAAQgAAEIxIoAgj9W7qAzEIAABCAAAQhAAAIQgAAEIACBaAgg+KPhiBUIQAACEIAABCAAAQhAAAIQgECsCCD4Y+UOOgMBCEAAAhCAAAQgAAEIQAACEIiGAII\/Go5YgQAEIAABCEAAAhCAQN4RqFmzpvXq1cvOP\/98a9y4sVWrVs02bdpk7733nj300EO2bNmyvBszA4JAPhFA8OeTNxkLBCAAAQhAAAIQgAAEIiIgsT9ixAg79dRTncUlS5bY1q1bbb\/99rN69erZd999ZzfffLPNnz8\/oi9iBgIQiJoAgj9qotiDAAQgAAEIQAACEIBAHhA455xzbPDgwVajRg175JFH7JlnnnGjOuCAA2z06NHWqlUre+utt2zYsGF5MFqGAIH8JIDgz0+\/MioIQAACEIAABCAAAQhkRWD8+PHWoUMH++CDD2zQoEEJti699FLr06ePrV692oYOHWpff\/11Vt\/iZQhAwA8BBL8frliFAAQgAAEIQAACEIBAzhLYe++9bezYsXbwwQfb9OnTbfLkyQlj6dGjhw0YMMC2bNlit9xyi3344Yc5O1Y6DoF8JoDgz2fvMjYIQAACEIAABCAAAQh4IKCU\/tNPP90WLFhgAwcOtPXr13v4CiYhAIFsCSD4syXI+xCAAAQgAAEIQAACECgQAoceeqhL5T\/xxBNt165dCWf7CwQBw4RAThFA8OeUu+hsIRBo1qxZpQxTf0nrap2qanwf\/lU1\/zT31Ph+1ax\/+Ff9\/Fu+fHlV\/erP2++m83d3MPer6vdP8P2K+v+ggw6ye+65x4KxFhUV2dSpU90\/NAhAIL4EEPzx9Q09K1ACZ599tjsLR4MABCAAAQj4IPDJJ59Y\/\/79fZguWJvHHHOMTZw4MSfGv2zZMrvgggsy7qvGqMJ9O3bssCZNmpjO+G\/bts1ee+01u\/vuu2379u0Z2+QFCEDAPwEEv3\/GfAECGRGQ4L\/6yhvs9\/cvzui9qB9ufUR9O+fiZnb3TQuiNp2T9vZuUsuuuKalPX7\/Ylu94oecHEPUnb7+9lbwCEG9\/JqW9u4bq23eF5uiRp2T9sRj9b9+sBnPLMvJ\/kfd6XN6\/pi9VdU8fvHLva3uXosR\/BE7OBD8jfcZazVrxjeDYtOmzrZg\/s8rJPjDyGrWrGnXXHON6dq+nTt3uoJ+Tz31VMRUMQcBCERBAMEfBUVsQCBCAoHgH97nywitZm6qdbv6JkH32998kvnLefiGBP+dUw63YX2+RPD\/27+P\/fnnbkNo3ucIXCEZN+Vwm\/H0Mnv3v9fk4QrIfEj6\/bFqxQ9VvnmZec\/9vKENkMZNalX5Juo5PZvaz9osR\/BH7OZA8O+3X\/dYC\/516y63r77qnLXgFz6JfmU1HHnkkfbpp5\/a1VdfHTFVzEEAAlEQQPBHQREbEIiQAII\/QpgRmkLwl4SJ4E9kguBP5IHgT+SB4I\/wF3IMTRWi4Jcbhg8fbueee67NmzfPevfuHUPP0CUIQADBzxyAQMwIIPhj5pB\/dwfBj+Avb2Yi+BH8Zc0RBH95Kyi3fx4I\/hYtLox5hL+3zZ17VloRfo1p5MiRVq9ePbvvvvvslVdeKeGkESNGWOfOnRH8uT196X2eE0Dw57mDGV7uEYiL4Bc5pfWTrv3THIJH4noSj1X\/+oEjDv\/GAo\/E+aFNMjVqXvzIRTwa71uryn+nktLv578LigV\/857xFvzrL7O5c89MS\/A3bdrUJkyYYPvvv7\/99a9\/NYn7cNtzzz3twQcftEMOOSTlz\/2QxioEIJApAQR\/psR4HgKeCcRJ8HseKuYhAAEIQKCSCSD4\/QDPR8EvUirM161bN9u0aZMT90GUv27dui7637FjR1u3bp2NHTvWZs2a5QcuViEAgawIIPizwsfLEIieAII\/eqZYhAAEIACBHwkg+P3MhEDwN296cawj\/Os3XGZz552RVoRfpBTFV2T\/xBNPdNfuLVmyxLZs2WLNmjVzP9u8ebM98sgjNn36dD9gsQoBCGRNAMGfNUIMQCBaAgj+aHliDQIQgAAEfiKA4PczG\/JV8IuWqvH36tXLzj\/\/fGvcuLFVr17dioqK7KuvvnIp\/wsXLvQDFasQgEAkBBD8kWDECASiI4Dgj44lliAAAQhAIJEAgt\/PjPhJ8F9iNWss9\/ORCKyu33CpzZ2ffoQ\/gk9iAgIQqGICCP4qdgCfh0AyAQQ\/cwICEIAABHwRQPD7IRsI\/mZNelnNGv\/y85EIrK7f+H9s3oLT007pj+CTmIAABKqYAIK\/ih3A5yGA4GcOQAACEIBAZRFA8PshjeD3wxWrEIBA9gQQ\/NkzxAIEIiVAhD9SnBiDAAQgAIEQAQS\/n+lQLPj3+T\/xjvBvUoT\/V0T4\/UwDrEIglgQQ\/LF0C50qZAII\/kL2PmOHAAQg4JcAgt8P32LBv\/el8Rb8Rb1s3kIEv59ZgFUIxJMAgj+efqFXBUwAwV\/AzmfoEIAABDwTQPD7AYzg98MVqxCAQPYEEPzZM8QCBCIlgOCPFCfGIAABCEAgRADB72c6BIK\/6V6XxTrCv0ER\/v\/9JSn9fqYBViEQSwII\/li6hU4VMgEEfyF7n7FDAAIQ8EsAwe+HL4LfD1esQgAC2RNA8GfPEAsQiJQAgj9SnBiDAAQgAAEi\/N7nQLHgb9TbalaP77V8GzZfYvO+JsLvfULwAQjEiACCP0bOoCsQEAEEP\/MAAhCAAAR8ESDC74dsseDf8\/J4C\/4tEvynkdLvZxpgFQKxJIDgj6Vb6FQhE0DwF7L3GTsEIAABvwQQ\/H74Ivj9cMUqBCCQPQEEf\/YMsQCBSAkg+CPFiTEIQAACEAgRQPD7mQ7Fgn+PK+Id4f\/+Ypu3iAi\/n1mAVQjEkwCCP55+oVcFTADBX8DOZ+gQgAAEPBNA8PsBXCz4G0jwr\/DzkQisbpDg\/+Y\/SOmPgCUmIJArBBD8ueIp+lkwBBD8BeNqBgoBCECg0gkg+P0gR\/D74YpVCEAgewII\/uwZxspCs2bNrF+\/fnbcccdZw4YNrXr16vbDDz\/YsmXLbNq0afbyyy+X6O8TTzxhrVu3LnUcO3futM2bN9vixYvtueees9deey3yMQ8cONAuvvjitO1qTBMnTrTp06en\/U6uPIjgzxVP0U8IQAACuUcAwe\/HZ8WCv16feEf4t\/a0eYuJ8PuZBViFQDwJIPjj6ZcK9erUU0+1G264wRo1apTyfQn3t99+22655Rbbvn178TPlCf6wMdn4+OOP7dZbb7V169ZVqJ+pXkLw\/0QFwR\/ZtMIQBCAAAQgkEUDw+5kSCH4\/XLEKAQhkTwDBnz3DWFg48MAD7e6777YWLVrY1q1bXRReQn7VqlV22mmn2eWXX24HHHCAbdu2zf7zP\/\/THnzwwRKCf8WKFS5qvn79+oQx7bvvvnbCCSdY+\/btrX79+u5nc+bMsSFDhkQm+gPBr8j9s88+6zYVymo7duywhQsXRvb9WDjx351A8MfJG\/QFAhCAQH4RQPD78Wex4K8b8wj\/D0T4\/cwArEIgvgQQ\/PH1TUY9u\/rqq61Xr14uci+hr3\/C7dBDD7Xbb7\/dbQh8++23NnjwYFu+fLl7JIjwL1261IYOHWqLFi1K+W1tGIwePdpatWplEtxK77\/\/\/vsz6mdpD4cFf76m6qcLCsGfLimegwAEIACBTAkg+DMllt7zxYK\/zm+tZrUYF+3b1tPmfXsqRfvScytPQSAvCCD488KNZg8\/\/LAdddRRJcR8eHjDhw+3c8891zZt2uTS+t97772MBL8e1l9oY8aMcccGVq5c6TYI5s+fnzVFBP9PCBH8WU8nDEAAAhCAQCkEEPx+pgaC3w9XrEIAAtkTQPBnz7DKLey9994unV8ReIlvRftTtUBUZyP4ZTfYONDRgcmTJ9tTTz2VNYMoBH\/NmjWte\/fublNDxQtr1arl+qVjAio4qAJ\/qYoW6hk937t3b+vYsWNxscOioiL76quvbMKECe74QHJL9Y6Y6LjDk08+WbyhkikcBH+mxHgeAhCAAATSJYDgT5dUZs8VC\/7afeMd4d9+kc37JxH+zLzL0xDIbQII\/tz2X0a9v\/POO61Tp062du1au\/HGG+3TTz9176eb0h98TIJU5\/fr1Kljr776qkvzz7ZlK\/j33HNPu+eee6xt27ZWrVq1lN1R\/YIXX3zRxo8fn\/Dz8ooditddd91lM2fOLH7vpJNOcgUSmzRpkvJbEv7aCNGGSKYNwZ8pMZ6HAAQgAIF0CSD40yWV2XOB4G9WK96Cf70E\/3cI\/sy8y9MQyG0CCP7c9l\/avT\/55JPt5ptvNgnjzz77zAYMGFBcqT9Twd+mTRsbN26cE7uKZvfp0yftfpT2YLaCf+TIkXbmmWe6Mc2ePdumTJnish003p49e7qzaio4mHwMIVzbIFzscMOGDa4mgjIG9N4333xj1113nbveMFwgUdkD\/\/3f\/21Tp0617777LqFAoq4yVHbAjBkzMuKD4M8IFw9DAAIQgEAGBBD8GcDK4FEEfwaweBQCEKhUAgj+SsVdNR+T6L333ntd9Fvp\/Er\/f\/3114s7k6ngl+BVNL158+Y2b948lwqfbcvkWr7k4oIS7erPPvvsY++\/\/77LPghfO6i+BUUNt2zZYnfccYe9+eabrsuqQaDNAEX\/VQfhmWeeSRiKxqZ\/dFxAafqK2Afv6BupMgbCmwjJmyvpcELwp0OJZyAAAQhAoCIEEPwVoVb+O8WCv+aVsU7pX7\/jIpu35BSK9pXvUp6AQN4QQPDnjStTDySc6l6aQM11wX\/GGWfY7373OxeJ11gUbU9uPXr0cFkNasEtABLxEvCHHXaYu5mgX79+Ja4k1Dl93USw1157uU2Chx56yCZNmuSi\/KW9o29oA0OZBdpgUfaBsg7SbQj+dEnxHAQgAAEIZEoAwZ8psfSeR\/Cnx4mnIACByieA4K985pX2RYnV2267zUX2JfZ1Bl3n7ZOj33ES\/EqRf\/bZZ+3jjz8uldP3339vX375ZYlxhF+QIG\/ZsqUde+yx1q5dO1fQsHbt2q6AXyD4DzroIJcZIE5io7oG5TXdhKAMAd1S8NZbb9mwYcNSvhLUOahRo4Y7XpBqE6K0byH4y\/MCP4cABCAAgYoSQPBXlFzZ7wWCv0W0C\/sAACAASURBVHmNq+Id4d95oc0lwu9nEmAVAjElgOCPqWOy7dYRRxxhN910k4tEK139tddec4XnksW+vpOp4D\/uuOPc1XwNGzZ0hf9KuxUgkzFke4Zf0XqduZdYVm2BoEJ\/ch\/Cgr99+\/ZuHMoMePrpp+3BBx8st8vhd8p9+N8PpGs7sKcx6NrE5Pbb33yS7id5DgIQgAAEIOAIXH5NSzvpl3sl0Pjkk0+sf\/\/+EIqQQLHgr36V1bQVEVqO1tT6XRfa3KWk9EdLFWsQiDcBBH+8\/VOh3inF\/ZprrnFRaAncP\/7xjy4VvbSWqeAP0uMlquNQpV9if+zYse5KPVXo37Vrl6lgngr0LV++3NUZ2Llzp11yySUOQRDhj7Pgv\/rKG+z39y9OcNm8zzdVaD7wEgQgAAEIFC6BvZvUssb7\/nhNrdovfrm31d1rMYI\/4imB4I8YKOYgAIHICCD4I0MZD0Ndu3Z1EXdFrSV6H3\/8cXc9XFktU8GvYwGnn356Qnp8tqPPJsIvId+3b18X1f\/ggw\/svvvuc1X1wy3VGf7wbQPppvSHsxu0kaLz\/VE3UvqjJoo9CEAAAhAICJDS72cuBIK\/hV0d6wj\/OrvQ5i7rRNE+P9MAqxCIJQEEfyzdUrFOhcW+7o6XGA1X4y\/NaiaCX3+hKQ1e2QO6hm7QoEHuqrpsWzaC\/84777ROnTqZxqxz+DpmkNyGDx9u5557bsImhY4kBAX4FixY4ArtrV+\/vsS7qt6vyvt6RtcR6p\/999+\/xPWG2TII3kfwR0USOxCAAAQgkEwAwe9nTgSCf79d\/WIu+HvYV8sR\/H5mAVYhEE8CCP54+iXjXh155JGuQJ\/Or0v46ry+otbptHQFvwrfKbrfqlUrVxdg2rRp9uijj6bziXKfiUrwjxgxwj788MOE76megfqt4nzhM\/x6qLxr+U499VTTZoE2B4LjC\/rGWWed5Ww98sgjJa7yC+x26dLFZVmoaN\/zzz9fLgMEf9qIeBACEIAABCpIAMFfQXDlvIbg98MVqxCAQPYEEPzZM4yFhfHjx1uHDh1s69atTlzqPvrS2o4dO2zhwoW2bt0690gg+FesWOHOtydHuVXNXqnsqlBfr149d0b+vffes+uvv77MSvmZgMlG8OsIgwr2qSK+ovAPPPCAE\/1Nmza1iy66yM4880zT9YRqyYJfkfvbb7\/dWrRo4cT5f\/3XfzmBruc6d+5svXv3tsaNG7tNFNUJmDVrlov2B++ItwoiiqHqBehnffr0sRNPPNEdMRBnjS1gnQ4TIvzpUOIZCEAAAhCoCAEEf0Wolf9OseDfoQj\/yvJfqKIn1lXrYV\/9qyMp\/VXEn89CoCoIIPirgnrE35TQHzVqlDVo0CAty8miNxD86bys4nd\/\/\/vfXTZBJiK2PNvZCH5F7pVmL7Gdqmm8SvM\/5JBDnPBXZkK4iKGi+DfccIM7ppCqaSNAkfzp06cX\/7i8d\/TgkiVLTMcNVFcgk4bgz4QWz0IAAhCAQCYEEPyZ0Er\/WQR\/+qx4EgIQqFwCCP7K5e3la+Gq+el8IFPBr\/T9oqIiFz2X6H3nnXfS+UxGz2Qj+PUhiX5dMaTK+ypYqGr96vP8+fPtySeftLlz57pr93Qc4bPPPrMBAwYkZCeU9v5XX31lEyZMcJH65KZ3lAGg2wGU8l+9enV31EEbIX\/7299cpkBFNkUQ\/BlNHR6GAAQgAIEMCCD4M4CVwaOB4P\/Z9v6xjvCvrd6dCH8GfuVRCOQDAQR\/PniRMeQVAQR\/XrmTwUAAAhCIFQEEvx93BIJ\/\/239reau+Kb0r63R3easIKXfzyzAKgTiSQDBH0+\/0KsCJoDgL2DnM3QIQAACngkg+P0ARvD74YpVCEAgewII\/uwZYgECkRJA8EeKE2MQgAAEIBAigOD3Mx2KBf8PA+If4V95MkX7\/EwDrEIglgQQ\/LF0C50qZAII\/kL2PmOHAAQg4JcAgt8P30Dwt\/z+d7EW\/GtqdrM5qxD8fmYBViEQTwII\/nj6Jad6pUJ5Y8aMccXyMm3JBQQzfT8fn0fw56NXGRMEIACBeBBA8PvxA4LfD1esQgAC2RNA8GfPsOAtHHbYYa7qfd26dTNmoar2zz77rM2cOTPjd\/P1BQR\/vnqWcUEAAhCoegIIfj8+KBb8mwfabjEu2rdmt2725eqTSOn3Mw2wCoFYEkDwx9ItdKqQCSD4C9n7jB0CEICAXwIIfj98Efx+uGIVAhDIngCCP3uGWIBApAQQ\/JHixBgEIAABCIQIIPj9TIdiwV8U8wh\/LSL8fmYAViEQXwII\/vj6hp4VKAEEf4E6nmFDAAIQqAQCCH4\/kIsF\/6ZBttvOlX4+EoHVNbW72pdrSOmPACUmIJAzBBD8OeMqOlooBBD8heJpxgkBCECg8gkg+P0wR\/D74YpVCEAgewII\/uwZYgECkRJA8EeKE2MQgAAEIBAigOD3Mx0CwX\/AxsGxjvCvVoR\/7S8o2udnGmAVArEkgOCPpVvoVCETQPAXsvcZOwQgAAG\/BBD8fvgWC\/7118Rb8O9+gX25DsHvZxZgFQLxJIDgj6df6FUBE0DwF7DzGToEIAABzwQQ\/H4AI\/j9cMUqBCCQPQEEf\/YMsQCBSAkg+CPFiTEIQAACEAgRQPD7mQ7Fgn+dIvyr\/HwkAqur6yjC34GU\/ghYYgICuUIAwZ8rnqKfBUMAwV8wrmagEIAABCqdAILfD3IEvx+uWIUABLIngODPniEWIBApAQR\/pDgxBgEIQAACIQIIfj\/ToVjwr7ku3hH+uufbl+tPJMLvZxpgFQKxJIDgj6Vb6FQhE0DwF7L3GTsEIAABvwQQ\/H74\/iT4h9huO2Kc0l\/3PPtyA4LfzyzAKgTiSQDBH0+\/0KsCJoDgL2DnM3QIQAACngkg+P0ARvD74YpVCEAgewII\/uwZYgECkRJA8EeKE2MQgAAEIBAigOD3Mx2KBf+qofGO8Nc7z77c2J6Ufj\/TAKsQiCUBBH8s3UKnCpkAgr+Qvc\/YIQABCPglgOD3w7dY8K+8Pt6Cv\/65CH4\/UwCrEIgtAQR\/bF1DxwqVAIK\/UD3PuCEAAQj4J4Dg98MYwe+HK1YhAIHsCSD4s2eIBQhESgDBHylOjEEAAhCAQIgAgt\/PdCgW\/CtuiH+Ef9MJpPT7mQZYhUAsCSD4Y+kWOlXIBBD8hex9xg4BCEDALwEEvx++CH4\/XLEKAQhkTwDBnz1DLEAgUgII\/khxYgwCEIAABIjwe58DxYJ\/+bB4R\/gbnGNfFhHh9z4h+AAEYkQAwR8jZ9AVCIgAgp95AAEIQAACvggQ4fdDtljwL5PgX+3nIxFYXb2HBP\/xpPRHwBITEMgVAgj+XPEU\/SwYAgj+gnE1A4UABCBQ6QQQ\/H6QI\/j9cMUqBCCQPQEEf\/YMsQCBSAkg+CPFiTEIQAACEAgRQPD7mQ6B4G+5bLjV3B7fCP+aPX5jczYT4fczC7AKgXgSQPDH0y\/0qoAJIPgL2PkMHQIQgIBnAgh+P4ADwb\/\/0ngL\/rUNEfx+ZgBWIRBfAgj++PqGnhUoAQR\/gTqeYUMAAhCoBAIIfj+QEfx+uGIVAhDIngCCP3uGWIBApAQQ\/JHixBgEIAABCIQIIPj9TIdA8O+3JN4R\/nUNf2NfbSGl388swCoE4kkAwR9Pv9CrAiaA4C9g5zN0CEAAAp4JIPj9AA4Ef\/Mlw2J9hn99w3NsLoLfzyTAKgRiSgDBH1PH0K3CJYDgL1zfM3IIQAACvgkg+P0QRvD74YpVCEAgewII\/uwZYgECkRJA8EeKE2MQgAAEIBAigOD3Mx0Cwd90yQ1Wc\/sqPx+JwOqGhufavC0n2AUXXBCBNUxAAAK5QADBnwteoo8FRQDBX1DuZrAQgAAEKpUAgt8PbgS\/H65YhQAEsieA4M+eIRYgECkBBH+kODEGAQhAAAIhAgh+P9MhEPz7LhlqNWIc4d\/Y8Dybv6U9EX4\/0wCrEIglAQR\/LN1CpwqZAIK\/kL3P2CEAAQj4JYDg98M3EPz7LLku1oJ\/U8PzbcGWExH8fqYBViEQSwII\/li6hU4VMgEEfyF7n7FDAAIQ8EsAwe+HL4LfD1esQgAC2RNA8GfPEAsQiJQAgj9SnBiDAAQgAIEQAQS\/n+kQCP69l1wT6wh\/UcMLbOGWDkT4\/UwDrEIglgQQ\/LF0C50qZAII\/kL2PmOHAAQg4JcAgt8P30DwN1oyyKpvX+nnIxFY3dywq3295SQEfwQsMQGBXCGA4M8VT9HPgiGA4C8YVzNQCEAAApVOAMHvBzmC3w9XrEIAAtkTQPBnzxALEIiUAII\/UpwYgwAEIACBEAEEv5\/pEAj+hkt+F+sI\/5aG3WzRlpOJ8PuZBliFQCwJIPhj6RY6VcgEEPyF7H3GDgEIQMAvAQS\/H74Ifj9csQoBCGRPAMGfPUMsQCBSAgj+SHFiDAIQgAAEiPB7nwOB4G+wtH+sI\/zfN+xu32zuSITf+4zgAxCIDwEEf3x8QU8g4Agg+JkIEIAABCDgiwARfj9kA8Ffb2m\/WAv+rQ172GIEv59JgFUIxJQAgj+mjqFbhUsAwV+4vmfkEIAABHwTQPD7IYzg98MVqxCAQPYEEPzZM8QCBCIlgOCPFCfGIAABCEAgRADB72c6BIK\/zrKrrdr2FX4+EoHVbXtcaN9u7kRKfwQsMQGBXCGA4M8VT9HPgiGA4C8YVzNQCEAAApVOAMHvB3kg+GsvuyrWgn\/7HhfaPzefguD3Mw2wCoFYEkDwx9ItdKqQCSD4C9n7jB0CEICAXwIIfj98Efx+uGIVAhDIngCCP3uGWIBApAQQ\/JHixBgEIAABCIQIIPj9TIdA8NdcdmWsI\/w79rjIlhDh9zMJsAqBmBJA8MfUMel2q0uXLtajRw9r2bKl1apVy3bu3GkbNmywDz\/80B566CFbtmxZgqn27dvbmDFjrH79+qV+4ocffrBNmzbZ559\/bo899pgtXLgw3e6k\/dwTTzxhrVu3tqVLl9rQoUNt0aJFZb575513WqdOnVy\/brnlFnvvvffS\/lZVPBiM76233rJhw4Zl1AUEf0a4eBgCEIAABDIggODPAFYGjyL4M4DFoxCAQKUSQPBXKu7oPlazZk0n3Dt27GjVq1dPaXjt2rV211132cyZM4t\/no7gDxvbunWrTZ8+3W0eRNkQ\/KXTRPBHOdOwBQEIQAACYQIIfj\/zIRD81Zf1NdsR36J9u\/a4yJYWncoZfj\/TAKsQiCUBBH8s3VJ+pwYOHGjdu3c3Cf\/Fixfb73\/\/e3vzzTetcePGdvnll9tZZ53lIv5Lliyx66+\/vjiCHhb877\/\/vj399NMlPnb44YfbCSecYG3atHE2tm3bZi+++KKNHz++\/I6l+QSCH8Gf5lThMQhAAAIQiJAAgj9CmCFTgeC35fEW\/NbgIluG4PczCbAKgZgSQPDH1DFldatZs2b2wAMP2H777efS7SX+161bl\/DKddddZ+edd56L\/j\/55JM2efJk9\/Ow4C8v3VyRZtlu2LChsz927Fh75513IiGG4EfwRzKRMAIBCEAAAhkRQPBnhCvthxH8aaPiQQhAoJIJIPgrGXgUn5MQHzJkiIu+h8V82Lai8+PGjbMmTZpYWNhnIvhl78orr7RevXrZbrvtZrNnzzZtJETREPwI\/ijmETYgAAEIQCAzAgj+zHil+3Qg+Hcs\/22sU\/qrNehp\/yLCn65beQ4CeUEAwZ+Dbrz00kvt4osvdun89913n73yyislRnHggQfaPffcY82bN89K8Cu6P2nSJJO9lStXugJ78+fPz5pa1IL\/kEMOsb59+9qRRx5pe+yxh8tsUAHD9evXuwKGGkO4gGGYj441\/OMf\/7DevXub7GgjRYUL9fy0adPs5ZdfTjle1U8Iv6N6Byp0OGHCBFdYUEUJy8uiSGWYM\/xZTy8MQAACEIBAKQQQ\/H6mRiD4t\/3rt7Yrxmf4azToaSs2cYbfzyzAKgTiSQDBH0+\/ZN2rDh062KhRo6xBgwb26quv2ujRo53NTCP8emfEiBHWuXNn27Jli917770pNxgy7XCUgl+3FFx11VVWt27dUruhWgY33XRT8WZFWPB\/8MEHproFqd6X8J8yZYpNnTo1wXbPnj3dN2vXrl3im\/rW9u3b3c0JCP5MZwbPQwACEICATwIIfj90Efx+uGIVAhDIngCCP3uGsbQQXGOnqLOK7c2YMaPCgl8ZBX369HFp\/Yp4R1GxPyrBr79gdVtBo0aNbNWqVSa72uDYvHmzHXfccU6US8yr\/elPf3JZD2phwa9\/13V\/+vkzzzzjovuK3GsjQYL+u+++s0GDBhVnCJx00kl28803u2\/qJgR9U1kAOj7Rr18\/O\/HEE12WgBqCP5bLg05BAAIQKFgCCH4\/rg8E\/\/cxj\/DXbNDTVhHh9zMJsAqBmBJA8MfUMdl0Kxx9ViV+nfdXxFmtIhF+Cd8BAwY4Eav09wcffDCb7rl3A8GfqSEJc6XLv\/fee+5VHTG44IILrKioyO6++257\/fXXE0yGCxwqki\/hniz4tTmgNPxgUyQwoIyA3\/zmN24z4I477nC3IKgpW+L00093xwVUJyF87aF+Pnz4cDvnnHOsWrVqCP5MHczzEIAABCDglQCC3w9eBL8frliFAASyJ4Dgz55hrCyE09uT09jzUfDriMFRRx3lou+\/+93vnAhPbsHmwrx581zkPlnwL1q0yEXmk98NNjr0\/MSJE2369On2s5\/9zNVNaNGihYU3EMLfLK1gYroThTP86ZLiOQhAAAIQyJQAgj9TYuk9Hwj+zSvifYZ\/t\/o9bTUR\/vScylMQyBMCCP48caSGcckll9gVV1zhzqKvWLHC7rrrLps1a1bCCOMW4Vc\/JaZTCfVwx1Wk8IQTTnDR9nCEP9l9Gvthhx3mCuYdffTR7v83btzYFfErTfCLkTIFklsqwR\/mV1a2g879t23blgh\/Hq0vhgIBCEAgHwgg+P14MRD8m1b2tZ0xLtpXu\/5FtmYjRfv8zAKsQiCeBBD88fRLRr1StX5FqLt16+bS7hXtVgq6ItDJrSKCv3\/\/\/u5qPlW9L+0awIw6HErpX7p0qRPbirKX1YKaBKkEvyrr68iBzurXr1\/fpdKnaqUJ\/tLO2acS\/F27di0+FpCqmF\/w3aC\/FT3Dr02NeZ9vShjG3TctyBQzz0MAAhCAQIETkMBv3a5BMYW9961l\/1zypenvdlp0BBD80bHEEgQgEC0BBH+0PCvdmiLaI0eOtJNPPtlFsb\/++mtXnb+0q\/MqIvgD8RrHKv2nnnqq3XDDDa6AnpoK7mlTYPny5bZ48WL76KOP7MILL7RWrVqVGuGPo+C\/+sob7N03VifMpxnPLK\/0+cUHIQABCEAgtwn84pd7WeMmPxaSVZP437x9AYI\/YrcGgn\/9yitjHeHfvf5Ftm7jKa7+EQ0CECgMAgj+HPbznnvu6SrU6y8ZtTlz5titt96acN988vAyFfzhonfpRuPTQRpFlf6GDRu6AoIS8zoSMHnyZHvppZeKCxQG\/SjvDH8mgj\/M749\/\/KPdf\/\/9KYf78MMPu9oCFY3wS\/AP7\/NlOih5BgIQgAAEIJA2AVL600aV0YOB4F+z6qpYC\/669S609Qj+jHzLwxDIdQII\/hz1YFjs79q1y9555x0X2VfF+bJapoL\/yiuvdOn8upLvr3\/9q40YMSISYlEI\/vBYdBWfqucnt3ABvShS+ps2beoq+u+\/\/\/722WefuaMEwQ0IwbfDV\/4h+COZLhiBAAQgAIGICCD4IwKZZAbB74crViEAgewJIPizZ1glFoKr3\/Txt99+290Lnyw8U3UsE8GvavEDBw40RdJ137zOlX\/88ceRjDdqwZ9qM0K1Da699lo799xzrUaNGpGk9GvwOkJx5plnuuMDjzzyiD3zzDMJTK677jo777zz3CYJgj+S6YIRCEAAAhCIiACCPyKQpQj+Vav72Y4YF+2rV6+HbdzQiZR+P9MAqxCIJQEEfyzdUnanTjvtNNMd8fXq1bNvvvnGJk2aZFu3bi31JaW7z5071\/08LPjff\/99U6X5cJNIViq6KuIfdNBBTrRK2JZVoK4iCKMQ\/OHjBhq\/rs3TeHSGXzUNlJmgCL9qG6hFEeGXnSOPPNJuu+02a9KkifvWn\/70Jyf6d999d7v88svtrLPOcsUT1RD8FZkdvAMBCEAAAr4IIPj9kA0i\/Ah+P3yxCgEIVJwAgr\/i7KrszaCIXrodCAvdsOBP530dEZCIluCPskUh+NWfSy+91Pr06VMssJP7qGv\/\/vnPf9qxxx5rS5YscRF\/\/Xs6afepqvQH9pX9oHT+oFhg+LtB4cC99toLwR\/lpMEWBCAAAQhkTQDBnzXClAYCwb\/cRfhX+vlIBFYb1OthRRs6EuGPgCUmIJArBBD8ueKpUD8DsZxu1zMV\/BKsygp499137dlnn3VZBFG3qAS\/+tWlSxcXzVfEX5H1bdu22Zo1a+z11183fef888+3vn37uiGMHz\/eZsyYkbXgly1dBzh48GCXRaBsC31XVyL+4Q9\/sI4dO1qnTp0Q\/FFPHOxBAAIQgEBWBBD8WeEr9eVA8C9dM8C2x1jwN6zb3TZvOBnB72caYBUCsSSA4I+lW+hUIRNQ9gBV+gt5BjB2CEAAAv4IIPj9sEXw++GKVQhAIHsCCP7sGWIBApESQPBHihNjEIAABCAQIoDg9zMdAsH\/zzUDYx3h37NuN\/t+w0lE+P1MA6xCIJYEEPyxdAudKmQCCP5C9j5jhwAEIOCXAILfD99A8H+zZrBt3xnfM\/x71e1qW9f\/AsHvZxpgFQKxJIDgj6Vb6FQhE0DwF7L3GTsEIAABvwQQ\/H74Ivj9cMUqBCCQPQEEf\/YMC85CprcEhAGFCwgWHLg0B4zgTxMUj0EAAhCAQMYEEPwZI0vrhUDwf732Gtu2c1Va71TFQ3vXucC2re9AhL8q4PNNCFQRAQR\/FYHP5c\/279\/fXXNXkbZ48WIbPXp0RV4tmHcQ\/AXjagYKAQhAoNIJIPj9IEfw++GKVQhAIHsCCP7sGWIBApESQPBHihNjEIAABCAQIoDg9zMdAsE\/f+11sY7w71PnfNux\/kQi\/H6mAVYhEEsCCP5YuoVOFTIBBH8he5+xQwACEPBLAMHvh28g+OeuG2o\/xDilf98659nOde0R\/H6mAVYhEEsCCP5YuoVOFTIBBH8he5+xQwACEPBLAMHvhy+C3w9XrEIAAtkTQPBnzxALEIiUAII\/UpwYgwAEIACBEAEEv5\/pEAj+L9bdEOsIf7M655qtO4EIv59pgFUIxJIAgj+WbqFThUwAwV\/I3mfsEIAABPwSQPD74RsI\/s\/WD7etO1f7+UgEVpvv\/hurvu54BH8ELDEBgVwhgODPFU\/Rz4IhgOAvGFczUAhAAAKVTgDB7wc5gt8PV6xCAALZE0DwZ88QCxCIlACCP1KcGIMABCAAgRABBL+f6RAI\/k\/W3xTrCP9+u3exGuuOI8LvZxpgFQKxJIDgj6Vb6FQhE0DwF7L3GTsEIAABvwQQ\/H74Ivj9cMUqBCCQPQEEf\/YMsQCBSAkg+CPFiTEIQAACECDC730OBIL\/gw23xjrCv\/\/uZ9tua48hwu99RvABCMSHAII\/Pr6gJxBwBBD8TAQIQAACEPBFgAi\/H7KB4H9vw0j7fucaPx+JwGrL3Ttb7bU\/R\/BHwBITEMgVAgj+XPEU\/SwYAgj+gnE1A4UABCBQ6QQQ\/H6QI\/j9cMUqBCCQPQEEf\/YMsQCBSAkg+CPFiTEIQAACEAgRQPD7mQ6B4J+1cVSsI\/wH1j7L6qw9mgi\/n2mAVQjEkgCCP5ZuoVOFTADBX8jeZ+wQgAAE\/BJA8PvhGwj+tzeOsS0xTuk\/uPaZVnftkQh+P9MAqxCIJQEEfyzdQqcKmQCCv5C9z9ghAAEI+CWA4PfDF8HvhytWIQCB7Akg+LNniAUIREoAwR8pToxBAAIQgECIAILfz3QIBP\/\/bLrdtuxc6+cjEVhtVft0q7+mHRH+CFhiAgK5QgDBnyueop8FQwDBXzCuZqAQgAAEKp0Agt8PcgS\/H65YhQAEsieA4M+eIRYgECkBBH+kODEGAQhAAAIhAgh+P9MhEPxvbLrTNsc4wt+69q9sjzWHE+H3Mw2wCoFYEkDwx9ItdKqQCSD4C9n7jB0CEICAXwIIfj98A8H\/l013x1rwH1b7l7bnmrYIfj\/TAKsQiCUBBH8s3UKnCpkAgr+Qvc\/YIQABCPglgOD3wxfB74crViEAgewJIPizZ4gFCERKAMEfKU6MQQACEIBAiACC3890CAT\/fxXda0U71\/n5SARW29b6D9trTRsi\/BGwxAQEcoUAgj9XPEU\/C4YAgr9gXM1AIQABCFQ6AQS\/H+SB4P9z0f2xFvxH1DrV9l7TGsHvZxpgFQKxJIDgj6Vb6FQhE0DwF7L3GTsEIAABvwQQ\/H74Ivj9cMUqBCCQPQEEf\/YMsQCBSAkg+CPFiTEIQAACEAgRQPD7mQ6B4H+h6IFYR\/iPrHWK7bPmUCL8fqYBViEQSwII\/li6hU4VMgEEfyF7n7FDAAIQ8EsAwe+HL4LfD1esQgAC2RNA8GfPEAsQiJQAgj9SnBiDAAQgAAEi\/N7nQCD4nyv6f7Zp53rv36voB46u1dH2XdOKCH9FAfIeBHKQAII\/B51Gl\/ObAII\/v\/3L6CAAAQhUJQEi\/H7oB4L\/j0WTYi34f17rZGu25mAEv59pgFUIxJIAgj+WbqFThUwAwV\/I3mfsEIAABPwSQPD74Yvg98MVqxCAQPYEEPzZM8QCBCIlgOCPFCfGIAABCEAgRADB72c6BIL\/6aJHbeOu+Kb0H1vrF9Zi9UFE+P1MA6xCIJYEEPyxdAudKmQCCP5C9j5jhwAEIOCXAILfD99A8E8tmmwbd23w85EIrB5fq4P9bPWBCP4IWGICArlCAMGfK56inwVDAMFfMK5moBCAAAQqnQCC3w9yBL8frliFAASyJ4Dgz54hFiAQ6klQXQAAIABJREFUKQEEf6Q4MQYBCEAAAiECCH4\/0yEQ\/E8UPW4bYhzhb1\/rRNt\/dUsi\/H6mAVYhEEsCCP5YuoVOFTIBBH8he5+xQwACEPBLAMHvhy+C3w9XrEIAAtkTQPBnzxALEIiUAII\/UpwYgwAEIAABIvze50Ag+B8rejLWEf4OtU6wA1bvT4Tf+4zgAxCIDwEEf3x8QU8g4Agg+JkIEIAABCDgiwARfj9kA8H\/aNEfbP2ujX4+EoHVX9Q63g5avR+CPwKWmIBArhBA8OeKp+hnwRBA8BeMqxkoBCAAgUongOD3gxzB74crViEAgewJIPizZ4gFCERKAMEfKU6MQQACEIBAiACC3890CAT\/pKKnYx3hP7nWsXbw6hZE+P1MA6xCIJYEEPyxdAudKmQCCP5C9j5jhwAEIOCXAILfD99A8P+\/omdjLfg71jrGWq1ujuD3Mw2wCoFYEkDwx9ItdKqQCSD4C9n7jB0CEICAXwIIfj98Efx+uGIVAhDIngCCP3uGWIBApAQQ\/JHixBgEIAABCIQIIPj9TIdA8E8omm7rdm7y85EIrJ5S6+fWek1TIvwRsMQEBHKFAII\/VzxFPwuGAIK\/YFzNQCEAAQhUOgEEvx\/kCH4\/XLEKAQhkTwDBnz1DLEAgUgII\/khxYgwCEIAABEIEEPx+pkMg+McXPR\/rCP9\/1DrKDluzLxF+P9MAqxCIJQEEfyzdQqcKmQCCv5C9z9ghAAEI+CWA4PfDNxD89xS9YGtjnNJ\/Wq0jre2aJgh+P9MAqxCIJQEEfyzdQqcKmQCCv5C9z9ghAAEI+CWA4PfDF8HvhytWIQCB7Akg+LNnGJmFLl26WI8ePaxly5ZWq1Yt27lzp23YsME+\/PBDe+ihh2zZsmUJ32rfvr2NGTPG6tevX2offvjhB9u0aZN9\/vnn9thjj9nChQsj629phk4++WQ3jlatWtkee+xh1atXLx7LggUL7KmnnrL33nsv5esHHnig3XPPPda8eXN76623bNiwYWn3d+DAgXbxxRe78d5yyy2lfiNtg1X0IIK\/isDzWQhAAAIFQADB78fJgeC\/s+glW7uzyM9HIrD6q1rt7PA1jYnwR8ASExDIFQII\/hh4qmbNmk64d+zY0YnjVG3t2rV211132cyZM4t\/nI7gD9vaunWrTZ8+3W0e+GgHHHCADR8+3Nq1a1fqOPRdbWR88sknNnbs2BKbGPkg+OvWrWu\/\/e1vTTyuu+66jFEj+DNGxgsQgAAEIJAmAQR\/mqAyfCwQ\/LcX\/TnWgv\/0WkdYuzV7I\/gz9C+PQyCXCSD4Y+A9Raa7d+9uEv6LFy+23\/\/+9\/bmm29a48aN7fLLL7ezzjrLRfyXLFli119\/vS1atMj1Oiz433\/\/fXv66adLjObwww+3E044wdq0aeNsbNu2zV588UUbP358pCM\/9NBD7fbbb7cWLVrYrl27bOnSpfbyyy\/ba6+9ZsuXL7emTZu6cSiLQdH7atWq2XfffWc333yzzZ8\/v7gv+SD477jjDjv11FNt3rx51rt374w5I\/gzRsYLEIAABCCQJgEEf5qgMnwMwZ8hMB6HAAQqjQCCv9JQp\/5Qs2bN7IEHHrD99tvPpdtL\/K9bty7hYUWJzzvvPBc1f\/LJJ23y5MklBH956e8SkbLdsGFDZ1\/R9XfeeSeS0e+555527733Wtu2bU1HCGbMmGETJkyw7du3l7CvTY0bbrjBif\/ddtvNvvzySxsyZIitX7\/ePZuN4I9kMBEYufPOO61Tp04I\/ghYYgICEIAABKIlgOCPlmdgLRD8Yzb9l62JcUr\/mbXb2pFr9iLC72caYBUCsSSA4K9it0iIS\/Aq+h4W8+FuKTo\/btw4a9KkScK59nCEvzzBL3tXXnml9erVywnt2bNnVyjdPBWuwK7EvMS++lpW03PacJAoVsbBtGnT7NFHH0Xw\/xsaEf4qXpR8HgIQgEAeE0Dw+3Eugt8PV6xCAALZE0DwZ88wKwuXXnqpKzQnEXzffffZK6+8UsJeaVHvTAW\/ovuTJk1yUfSVK1fa0KFDE9LpKzIQ2XzwwQddgb5MbB533HE2evRoa9SokamQn7IPFOVPHquOBWhDQYUMtVFRVFRkH330kctySC5AWF7RvkMOOcT69u1rP\/\/5z12hQx0rKMtewEO+0ZGLc88915SRoc0ZZTKoiKI2K9RHNRUqHDBggPt5uGVaRBDBX5GZyDsQgAAEIJAOAQR\/OpQyfyYQ\/KM2vWprdm7O3EAlvXFW7TZ29JpGRPgriTefgUAcCCD44+CFcvrQoUMHGzVqlDVo0MBeffVVJ5TVMhX8emfEiBHWuXNn27Jli0vDT7XBkAmS0047zW688UYnoNPJMgjb1lGG448\/3jZu3GgjR450WQdhwa96Bjr7X7t27RJdSlXEsCzB37VrV7v66qtLvdFAmw3auEjmoeMKujVAxxW0QZDcwjUREPyZzByehQAEIACBqiCA4PdDPRD8Iza9HmvB\/+vah9nP1zRE8PuZBliFQCwJIPhj6ZbETgVnwlVlX8X2lDZfUcGvjII+ffq4aLmi09lW7M\/GXiDQFS2fMmWKTZ06NUHwa4waswr\/Pfzww27MEu3asFAU\/ZtvvnHHEoLrCksT\/CeddJIrDqhsAkXbJeqfeOIJF6WXLRXWU4FEbSLoOr+PP\/7YfSs4eqDbE1SIMLjaUNckaqND2QKqxL9582ZXsyDwC2f4c2BR0UUIQAACBUoAwe\/H8Qh+P1yxCgEIZE8AwZ89Q68WevbsaVdddZWLcqsSv877B8XwKhLhD0ehVdVfUe1sWli0T5w40V37l25L1ZdwhF+CXEL\/mWeeSTAZLmKoTYtgM6A0wa9NEmVJaPPgkUceKWFPFfVVSFAbAn\/9619dFoSaRP1NN91k9erVc9kL2jQIFyI88sgj7bbbbnO1FT799FO3GaGG4E93BvAcBCAAAQhUNgEEvx\/igeC\/ZeMbtjrGKf1n125tx67dgwi\/n2mAVQjEkgCCP5Zu+bFTEsQS+7rXXVfySXyGr7DLd8E\/d+5cF0VPrvYfvtkgLLRTCf5wwcMPPvjABg0alNLjgUjXdYKqbaCrD2VPGy4656+r9nRVYnLT8YqTTz7Zvv32Wxs+fLi7ghDBH+NFRdcgAAEIFDgBBL+fCRAI\/ps2\/ret3rnFz0cisNql9qF23NoGCP4IWGICArlCAMEfU09dcskldsUVVzixv2LFCrvrrrts1qxZCb3Nd8H\/0ksvlVrxX+fqlaqvjZBrr73W\/vnPfzqBrgKI4SJ5wS0IderUsbIyGrSxcNlll7naBoG4T\/WNdKYLgj8dSjwDAQhAAAJVQQDB74c6gt8PV6xCAALZE0DwZ88wUgs6N96vXz\/r1q2bO6eu8+kSoIpOJ7eKCP7+\/fu7q\/l27txZ6jWAmQwoEMp6p7RrBUuzF\/RFhe9SneEvS6CXFpFPFvylFdIrrU86RhAcTdA5\/9atW9u8efPcOf90WxSCX7UEZjy9LOGTM55Znm4XeA4CEIAABCDgCLRuV99aH1G\/mEbrdg1s8\/YFpr+DadERCAT\/sI0zYx3hP6f2IXb82vpE+KNzPZYgEHsCCP4YuUjRfFWrV4p49erV7euvv3bV+cNp\/OHuVkTwB2I0F6r0F7Lgv\/rKG2z1v35ImJ1337QgRrOVrkAAAhCAQC4QUERfIj9ojfetZd8u+RLBH7HzEPwRA8UcBCAQGQEEf2QoszOk69\/GjBlj+gtDbc6cOXbrrbcWV6BPZT1TwR8++x4+q55Nzxs2bOgK\/7Vq1cpWrlzpzr+XtkER\/o7GqfGqUN6CBQtcOr6uxgsX7SsrpT+40k9n5wcPHuzOzqdK6dd1fMG5\/UmTJtmzzz6b9nCDb4SPDaTzchQRfgn+4X2+TOdzPAMBCEAAAhBImwAp\/WmjyujBQPDfsOEtWxXjM\/zn7n6wnbC2HhH+jLzLwxDIbQII\/hj4Lyz2df3bO++84yL7uu6trJap4L\/yyitdOr+u5AtXo88WQWBXxxHefvvtEtXsk+2Hr7tTQT5V2n\/0\/7d3J9BWVNe+\/yeNoEDoRVpRH70BQRAxCHJNVFC6iGJEghgQEUTsgm30iYggNqixj\/9rj2JzDRevxDx9xI6ABiI+UJBLI630KI20\/sdcubUtDudw9t5V8+y1T31rjIyRSO1Zqz5rqfnVWrXqqafcaeHAH96QL1wj\/OAivBFfYYH\/pJNOcq9EFNyBP5171k34+vTp4zbtGz9+fKGb9ukrDWqqDysmTZrk7p\/An44u5yCAAAII5EKAwG+jHgT+G777yOvA3\/fIE+TULZUI\/DbDgKoIeClA4PegWzRY9u7d27UkncAcNDmTwK+b12kg1hn5gt+bj0qgNe+\/\/3458cQTRd\/HnzFjhttksODu+nodDfv6Cbzu3bu7Bw+6kkE\/Nbh169ZDAn\/B79sH7dRVBH379nX1n376aXnppZfcHxX1Wb7HHntM2rVr5+5b2zVz5syDbjl4ANGpUyd3jgb2WbNmFftZPn1Q8+CDD0qLFi3cLv3BSoMg8OtO\/7ofgz4MyOTQvmKGPxMxzkUAAQQQSFeAwJ+uVGbnEfgz8+JsBBAoOQECf8lZF3ql8Lfely9fLrrsXL8XX9Sh4VE\/V6dHOPDPmTPH7UIfPjTI6gx3x44d5YQTTnABWzelCzbIi\/PWmzVrJnfffbc0bNhQdJWCvjIwffp0F\/51uX3dunVdyO\/Zs6fUr19fypQpI6tWrXKrAcKvAIRn+LV9uuP+a6+95lYB6Pfu9csFZ5xxhtvQcMGCBe5hQRCoiwr83bp1cw8ZdJZfHyxMmzZNpkyZ4v57hw4dZOjQodK6dWu3b4I6ak19mBBeiaD3NHfuXPeAYf78+e53+slEfcih52ob9dUGPXRFgV5THx7oSo3Zs2dnRE3gz4iLkxFAAAEEMhAg8GeAlcGpQeC\/ftvHsvHADxn8smRP7Xvk8dJp61HM8JcsO1dDIKcCBP6c8ktq+Xe6zQjvGB8O\/On8XmfM9aGABn6LQ5faa4DX2XQNz0Ud+oWAefPmuQcE+hWC8BEO\/J999pkL4hUrVjykVGEbGhYV+PXHulu\/BnTdGLGwQwO92mpA1wcvwaGz+Pp5vlatWrmHFAUPvRddlaG76gcrGvShhO7qrw9Y9NCHLLofwBtvvJEWO4E\/LSZOQgABBBDIQoDAnwVaGj8JAv+12\/7udeD\/9ZHHyWlbKxL40+hTTkGgtAgQ+HPck8Gn39JtRqaBX8OmzoB\/8sknbsO6cJhN95qZnqcPIi655BK3kV\/VqlVd+Nel\/jpb\/8UXX8ibb75Z5Kx3OPDrwwldFn\/ppZemVgXorPx7773nVkIU3OPgcIFf76FJkyai79zrA4kqVaq4AK8+69evdysRdNa\/sH0TdKZf39PX1whq1qyZWimhDyt05YGuZAgfer5uuKgrEfRhxf79+zP6ZCGBP9MRx\/kIIIAAAukKEPjTlcrsPAJ\/Zl6cjQACJSdA4C85a65kLFBc4De+fGzlCfyxUVIIAQQQQKCAAIHfZkgEgf+arXO8nuE\/\/6jGctrWCszw2wwDqiLgpQCB38tuoVHZCASBX1c06BJ7fSUgHw8Cfz72Gm1GAAEE8kOAwG\/TTwR+G1eqIoBAdAECf3RDKuRQQJfP694B+v68bpbXvHlzWb16tVx77bWycuXKHLYs+0sT+LO345cIIIAAAocXIPDbjJAg8I\/e+qlsOFD05ss2V0+\/ar+jjpVfbD2CGf70yTgTgbwXIPDnfRcm+wZatmwpEyZMcDv466Gb7\/3lL39xm+\/l60Hgz9eeo90IIICA\/wIEfps+CgL\/1Vv+4XngbySdt5Un8NsMA6oi4KUAgd\/Lbim5RgXfjM\/miuENBLP5fRy\/0c\/8jR492m3CpxvwzZo1yz0A0M398vUg8Odrz9FuBBBAwH8BAr9NHxH4bVypigAC0QUI\/NEN87rCiBEjpH379lndw4oVK2Ts2LFZ\/ZYfFS1A4Gd0IIAAAghYCRD4bWSDwD9q8zyvZ\/gvqNRQOm8rxwy\/zTCgKgJeChD4vewWGpVkAQJ\/knufe0cAAQRsBQj8Nr5B4B+5+XOvA\/+FlRrI6dvKEvhthgFVEfBSgMDvZbfQqCQLEPiT3PvcOwIIIGArQOC38SXw27hSFQEEogsQ+KMbUgGBWAUI\/LFyUgwBBBBAICRA4LcZDkHgH7F5vmzYv8fmIjFUvbBSfenyXRlm+GOwpAQC+SJA4M+XnqKdiREg8Cemq7lRBBBAoMQFCPw25AR+G1eqIoBAdAECf3RDKiAQqwCBP1ZOiiGAAAIIhAQI\/DbDIQj8V27+QtZ7PMPfv1I96coMv80goCoCngoQ+D3tGJqVXAECf3L7njtHAAEErAUI\/DbCQeAfvmmB14H\/osp1pet3wpJ+m2FAVQS8FCDwe9ktNCrJAgT+JPc+944AAgjYChD4bXwJ\/DauVEUAgegCBP7ohlRAIFYBAn+snBRDAAEEEAgJEPhthkMQ+Idt+tLrGf7fVD5GzvjuR2b4bYYBVRHwUoDA72W30KgkCxD4k9z73DsCCCBgK0Dgt\/ENAv\/QjYu8DvwXV64j3b4\/QOC3GQZURcBLAQK\/l91Co5IsQOBPcu9z7wgggICtAIHfxpfAb+NKVQQQiC5A4I9uSAUEYhUg8MfKSTEEEEAAgZAAgd9mOASB\/3cbF8v6\/XttLhJD1QGVj5Z\/+34\/M\/wxWFICgXwRIPDnS0\/RzsQIEPgT09XcKAIIIFDiAgR+G3ICv40rVRFAILoAgT+6IRUQiFWAwB8rJ8UQQAABBEICBH6b4RAE\/ss2fC3fejzDf0mVo+XM7\/cxw28zDKiKgJcCBH4vu4VGJVmAwJ\/k3ufeEUAAAVsBAr+NbxD4B234b68D\/8AqteVX3+8l8NsMA6oi4KUAgd\/LbqFRSRYg8Ce597l3BBBAwFaAwG\/jS+C3caUqAghEFyDwRzekAgKxChD4Y+WkGAIIIIBASIDAbzMcgsB\/yfplXs\/wD6pSS87avocZfpthQFUEvBQg8HvZLTQqyQIE\/iT3PveOAAII2AoQ+G18g8B\/8frlsm7\/PpuLxFD10io15Zztuwn8MVhSAoF8ESDw50tP0c7ECBD4E9PV3CgCCCBQ4gIEfhtyAr+NK1URQCC6AIE\/uiEVEIhVgMAfKyfFEEAAAQRCAgR+m+EQBP7+367weob\/sp\/VkO7M8NsMAqoi4KkAgd\/TjqFZyRUg8Ce377lzBBBAwFqAwG8jTOC3caUqAghEFyDwRzekAgKxChD4Y+WkGAIIIIAAM\/zmYyAI\/BesWylrPX6H\/3c\/qy7n7viBd\/jNRwQXQMAfAQK\/P31BSxBwAgR+BgICCCCAgJUAM\/w2skHg77tutdeBf+jPqknPHbsI\/DbDgKoIeClA4PeyW2hUkgUI\/Enufe4dAQQQsBUg8Nv4EvhtXKmKAALRBQj80Q2pgECsAgT+WDkphgACCCAQEiDw2wyHIPD3WrvW6xn+YVWrSq8dO5nhtxkGVEXASwECv5fdQqOSLEDgT3Lvc+8IIICArQCB38Y3CPznrl0ra\/bvt7lIDFWHV60qfXbsIPDHYEkJBPJFgMCfLz1FOxMjQOBPTFdzowgggECJCxD4bcgJ\/DauVEUAgegCBP7ohlRAIFYBAn+snBRDAAEEEAgJEPhthkMQ+M9Z+62s2efvDP+Iqj+Tvju3M8NvMwyoioCXAgR+L7uFRiVZgMCf5N7n3hFAAAFbAQK\/jS+B38aVqgggEF2AwB\/dkAoIxCpA4I+Vk2IIIIAAAszwm4+BIPCfvWaDrPZ5hr9aFTl\/5\/fM8JuPCC6AgD8CBH5\/+oKWIOAECPwMBAQQQAABKwFm+G1kg8D\/qzUbvQ78I6tVln4EfptBQFUEPBUg8HvaMTQruQIE\/uT2PXeOAAIIWAsQ+G2ECfw2rlRFAIHoAgT+6IZUQCBWAQJ\/rJwUQwABBBAICRD4bYZDEPh\/uXqz1zP8V1WrJP12fceSfpthQFUEvBQg8HvZLTQqyQIE\/iT3PveOAAII2AoQ+G18g8B\/5uotsnrfAZuLxFD1qmpHyQW7thH4Y7CkBAL5IkDgz5eeop2JESDwJ6aruVEEEECgxAUI\/DbkBH4bV6oigEB0AQJ\/dEMqIBCrAIE\/Vk6KIYAAAgiEBAj8NsMhFfhXbfV7hr+6zvBvZYbfZhhQFQEvBQj8XnYLjUqyAIE\/yb3PvSOAAAK2AgR+G18Cv40rVRFAILoAgT+6IRUQiFWAwB8rJ8UQQAABBJjhNx8DqcC\/8jvPZ\/iPlAt+2MIMv\/mI4AII+CNA4PenL2gJAk6AwM9AQAABBBCwEmCG30Y2tUv\/N9\/7HfhrVJR+BH6bQUBVBDwVIPB72jE0K7kCBP7k9j13jgACCFgLEPhthAn8Nq5URQCB6AIE\/uiGVEAgVgECf6ycFEMAAQQQCAkQ+G2GQxD4f\/XNDq9n+EfWqCD9ftjMkn6bYUBVBLwUIPB72S00KskCBP4k9z73jgACCNgKEPhtfIPAf\/aKnbJ63482F4mh6ogaR8j5uzcR+GOwpAQC+SJA4M+XnqKdiREg8Cemq7lRBBBAoMQFCPw25AR+G1eqIoBAdAECf3RDKiAQqwCBP1ZOiiGAAAIIhAQI\/DbDIQj85yzfJWt8nuGveYT03b2RGX6bYUBVBLwUIPB72S3ZN6pJkyYyevRoadmypVSuXFkOHDgg27Ztkw8\/\/FCeffZZWbt27SHF9a83b968yItqjZ07d8qKFSvk9ddflxkzZmTfwCJ+OWrUKBkwYEDadffs2SOPPvqoTJ06Ne3f5MuJBP586SnaiQACCOSfAIHfps8I\/DauVEUAgegCBP7oht5U6NevnwwfPlyqVKlSaJtWr14tEydOlE8\/\/fSgPy8u8IdP1vA\/d+5c+cMf\/iBbt26N7d4J\/D9REvhjG1YUQgABBBAoIEDgtxkSQeDvsXy3rNnr7zv8w2uWl757NjDDbzMMqIqAlwIEfi+7JfNGtWnTRu666y6pU6eObN++XV577TV58cUXpUKFCjJkyBDp1auXVKxYURYsWCDXX3+9m\/UPjiDwr1+\/3s2ah\/9MzznmmGOkY8eOcuqpp6YeJixcuNDViSv0B4FfZ+5feeUV91DhcMf+\/ftlyZIlsV0\/c3G7XxD47WypjAACCCRdgMBvMwKCwN9z2R6vA\/8VtcpJbwK\/zSCgKgKeChD4Pe2YTJt1ww03uKe1e\/fuLXSp+zXXXCMXXHCBaKC+\/\/775e233z4k8K9Zs0a0zrJlywq9\/HHHHSdjx46Vpk2bigZuXd4\/efLkTJta6PnhwF9al+qnC0XgT1eK8xBAAAEEMhUg8Gcqlt75BP70nDgLAQRKXoDAX\/LmJle8\/fbb5bTTTpONGzfKVVdddcgsvc7Ojxs3zs3Qv\/zyy\/LII49kHPj1B\/ovNK1To0YN2bBhg3tAsHjx4sj3ROD\/iZDAH3k4UQABBBBAoAgBAr\/N0AgCf+9l+2Stx0v6L69VVnrtWc+SfpthQFUEvBQg8HvZLfE3qnPnznLnnXe6jfyiBH5t2U033SR9+vSR3bt3y9NPPy0vvfRS5AbHEfjLly8vF154oWtbvXr13OsMeuiqBt1wUDf4mz59eqFt1fMHDx4sXbp0kWrVqknZsmVlx44d8uWXX8pDDz3kXh8oeBT2GzXR1x2ee+45mT17dlYuBP6s2PgRAggggEAaAgT+NJCyOCUI\/H2XauDPokAJ\/WRorbLSc++3BP4S8uYyCPggQOD3oRdKoA0a0nv37u122x8\/fry8\/\/77qasG7\/AXt6Q\/+IEGUn1\/\/6ijjpJ33nnHLfOPekQN\/NWrV5f77rtPWrVqJWXKlCm0Ofq6w1tvvSUPPPDAQX\/erVs3GTNmjFu1UNixZcsWuffee2XmzJmpP9YHKPob3TOhsEODvz4I0QcimR4E\/kzFOB8BBBBAIF0BAn+6UpmdR+DPzIuzEUCg5AQI\/CVnXeJX0hnv9u3by29\/+1vRTf30f+vn+W699VbZt29f1oFfP\/k3YcIEF3Z1Nls3BYx6RA38d9xxh5xzzjnuvmbNmiXPPPOMe9VAHwRcfPHF7km2vs5Q8DWEZs2auQcgDRo0cCsW9JOD+gDku+++k4EDB7oVA\/q75cuXy3XXXec+a3j88cfLpEmT3G909cB7770nzz\/\/vKxatUrOPPNMueyyy0T3O9CHK7o6YNq0aRnxEPgz4uJkBBBAAIEMBAj8GWBlcGoQ+M\/\/7\/1ez\/APqV1GzmOGP4Oe5VQE8l+AwJ\/\/fVjoHfTv319GjhyZWtYehNmHH37YBdHwkekMvwZenU2vX7++LFq0yC2Fj3pk8lm+gisRNLRre44++miZM2eOW30QfqChbdPPFWqA37Vrl9xzzz2pFQ7hzQ6feOIJmTJlykG3ovem\/9GHJbpMX2fsg9\/oNQpbMRB+iDB\/\/nzXDwXbczgvAn\/U0cTvEUAAAQSKEiDw24wNAr+NK1URQCC6AIE\/uqGXFQoL0Dob\/be\/\/c3NzodDf74H\/rPPPtttVKgz8XovOtte8AgegOhfD74CoCFeA3yLFi3clwmuvPLKQzY71Pf09UsENWvWdA8JHnvsMXn88cfdLH9Rv9FrqL+uLNBPJOrqA111kO5B4E9XivMQQAABBDIVIPBnKpbe+UHgv2DJj17P8P+utsi5+9bxDn963cpZCJQKAQJ\/qejGQ2+ibt267i\/qrv3BMvPGjRu7v\/bBBx+4jfeCw6fArw8lXnnlFZk7d26RPfPDDz\/IggULDjtrroFc71dfaWjdurVbYl+xYkW3BD8I\/CeccIJbGaChXt\/Pv\/nmm4sdDSeddJJbIaDv+6vjjTfeWOhvgn0OypUr514vKOwhRFEXI\/AX2w2cgAACCCCQpQCBP0u4Yn4WBP4LvxZZ5\/GmfZcdLdJj31oCv80woCoCXgoQ+L3slvgbpe+yP\/jgg242Wzeh08\/4ffbZZ+5Q0oKcAAAgAElEQVRCmQb+Dh06uE\/z6W72n3\/+uVsuH\/WI+g6\/ztbrkn0Ny7q3QLBDf8F2hQP\/4T5VWNT9hH+T7j0X\/CpCcb\/Te7jtttvk\/5u84qBTP3lvc3E\/5c8RQAABBBA4SKB56ypSq86\/vlqjR\/OfV5FKtb6RESNGIBWjAIE\/RkxKIYBArAIE\/lg5\/S42aNCg1AZ74VnnTAN\/eH8AH3bp17B\/9913u0\/q6Q79P\/74o3tlQTfoW7dundtn4MCBA3LJJZe4Dgpm+H0P\/AVH09Be8\/weYLQOAQQQQMA7gcuuaSydf1nzoHbNmzePwB9zTwWBv\/\/iMp7P8P8o3fczwx9z91MOAa8FCPxed0+8jQsH9fCsc6aBXz\/Dd9ZZZx20PD5qS6PM8GuQv\/zyy92s\/qeffupWMuiu+uGjsHf4w18bSHdJf3h1w6uvvure74\/7YEl\/3KLUQwABBBAIBFjSbzMWgsD\/m0XlvA78g+sckHP2r2FJv80woCoCXgoQ+L3slswa1ahRIzfD3bBhQ\/nnP\/\/pPh9X2BFsJKffo9fd+t944w13WiaBX\/+Fpsv59R12\/Qzd1Vdf7T5VF\/WIEvgnTpwoXbt2da8q6Hv4+ppBwUP3LOjTp89BDyn0lYRgA76vv\/7abbS3bdu2Q36ru\/frzvt6jm54qP859thjJZsd+NNxIvCno8Q5CCCAAALZCBD4s1Er\/jcE\/uKNOAMBBHIjQODPjXusV9Ul7bpMvU2bNi6waiDVGevwEf5UXMHP2qUb+HXjO53db9q0qehDgxdffFGeeuqpWO4lrsAf3psgaNjPf\/5z127dnC\/8Dr\/+eXGf5evWrZvb4FAfDgSvL+g1unfv7mo9+eSTh3zKL6jbs2dP92qBvj4RPFxJB4vAn44S5yCAAAIIZCNA4M9GrfjfBIH\/Yp3h31Om+B\/k6IxLdYb\/wGpm+HPkz2URyIUAgT8X6gbX7Nevn5uh1p3odWd+DfEaUPXo0aOH6Pv7upldYUE9CPzr1693Dw4KznLrbva6lF13qK9cubJ7R3727Nny+9\/\/PqPvyx\/utqMEft00UDfs0x3xdRZeVy\/ohoT6pYLf\/OY3cs4554huWqhHwcAffhCi4fy\/\/uu\/XEDX89Rt8ODBUrt2bbd6QFdRfPzxx262f\/z48dKgQQPZvXu3zJgxw3nrfgH6Z0OGDJFOnTq5VwyWLFni+mXr1q1p9zqBP20qTkQAAQQQyFCAwJ8hWJqnE\/jThOI0BBAocQECf4mT211Qd9y96KKLDrtDvb53rt+SDx9B4E+nZbr53d\/\/\/ne56667MgqxxdWOEvh15l5XNWjYLuzQ8K7L\/Js0aeKCv65MCBvoLP6YMWPcawqFHfogQGfyp06dmvrj4n6jJ65evVr0dQPdVyCTg8CfiRbnIoAAAghkIkDgz0Qr\/XODwD\/gq\/J+z\/Afs1\/OZoY\/\/Y7lTARKgQCBvxR0YvgWdOf5Sy+91IVfnY3XY8eOHbJ48WJ57rnn3Mx8waO4wK+rArSGzp5r6P3oo49iV4sS+LUxGvr1gYfef5UqVdxu\/eH7\/uqrr+SRRx5xryMU9u59Ub\/\/8ssv5aGHHnIz9QUP\/Y2uANCvA+iS\/7Jly7oVFDqb\/7e\/\/c2tFMhkZj+oT+CPfXhREAEEEEDgfwQI\/DZDIQj8l3x5hNeBf5AG\/h9XsaTfZhhQFQEvBQj8XnYLjUqyAIE\/yb3PvSOAAAK2AgR+G18Cv40rVRFAILoAgT+6IRUQiFWAwB8rJ8UQQAABBEICBH6b4ZAK\/AsryLceb9o3qO4+OYsZfptBQFUEPBUg8HvaMTQruQIE\/uT2PXeOAAIIWAsQ+G2EU4F\/QUX\/A7+sZEm\/zTCgKgJeChD4vewWGpVkAQJ\/knufe0cAAQRsBQj8Nr4EfhtXqiKAQHQBAn90w8RX0I3yxo0b5zbLy\/Qo+Jm8TH9fGs8n8JfGXuWeEEAAAT8ECPw2\/RAE\/oH\/z+8Z\/t\/W2ydnMcNvMwioioCnAgR+Tzsmn5rVokULGTlypFSqVCnjZuuu9q+88orMnDkz49+W1h8Q+Etrz3JfCCCAQO4FCPw2fUDgt3GlKgIIRBcg8Ec3pAICsQoQ+GPlpBgCCCCAQEiAwG8zHILA\/9svjvT6Hf7f1tsrvyrDO\/w2o4CqCPgpQOD3s19oVYIFCPwJ7nxuHQEEEDAWIPDbAAeBf9D8o7wO\/APra+D\/hk37bIYBVRHwUoDA72W30KgkCxD4k9z73DsCCCBgK0Dgt\/El8Nu4UhUBBKILEPijG1IBgVgFCPyxclIMAQQQQCAkQOC3GQ5B4L\/086Pk291lbC4SQ9WBDfbKL8sywx8DJSUQyBsBAn\/edBUNTYoAgT8pPc19IoAAAiUvQOC3MQ8C\/+B\/VvI68F\/SYI\/8shyB32YUUBUBPwUI\/H72C61KsACBP8Gdz60jgAACxgIEfhtgAr+NK1URQCC6AIE\/uiEVEIhVgMAfKyfFEEAAAQRCAgR+m+EQBP7L5nk+w99wj5zJDL\/NIKAqAp4KEPg97RialVwBAn9y+547RwABBKwFCPw2wgR+G1eqIoBAdAECf3RDKiAQqwCBP1ZOiiGAAAIIMMNvPgZSgX+uzvCXNb9ethe4RGf4y6\/gs3zZAvI7BPJQgMCfh51Gk0u3AIG\/dPcvd4cAAgjkUoAZfhv9IPD\/7h9+B\/4BjQj8NiOAqgj4K0Dg97dvaFlCBQj8Ce14bhsBBBAoAQECvw0ygd\/GlaoIIBBdgMAf3ZAKCMQqQOCPlZNiCCCAAAIhAQK\/zXBIBf7PKnu9pH9Ao91y5hEs6bcZBVRFwE8BAr+f\/UKrEixA4E9w53PrCCCAgLEAgd8GOBX4P60i63\/w9x3+Acfuln+rsJx3+G2GAVUR8FKAwO9lt9CoJAsQ+JPc+9w7AgggYCtA4LfxJfDbuFIVAQSiCxD4oxtSAYFYBQj8sXJSDAEEEEAgJEDgtxkOqcA\/52d+z\/A3\/oEZfpshQFUEvBUg8HvbNTQsqQIE\/qT2PPeNAAII2AsQ+G2MCfw2rlRFAIHoAgT+6IZUQCBWAQJ\/rJwUQwABBBBght98DASBf8hsv2f4L9YZ\/oq8w28+ILgAAh4JEPg96gyagoAKEPgZBwgggAACVgLM8NvIpgL\/36t6vaT\/4uM08C9j0z6bYUBVBLwUIPB72S00KskCBP4k9z73jgACCNgKEPhtfAn8Nq5URQCB6AIE\/uiGVEAgVgECf6ycFEMAAQQQCAkQ+G2GQxD4h86q5vkM\/y7pdiQz\/DajgKoI+ClA4PezX2hVggUI\/AnufG4dAQQQMBYg8NsApwL\/J9X9DvzHa+BfypJ+m2FAVQS8FCDwe9ktNCrJAgT+JPc+944AAgjYChD4bXwJ\/DauVEUAgegCBP7ohlRAIFYBAn+snBRDAAEEEAgJEPhthkMQ+C\/\/qIbXM\/y\/OWGndDuKGX6bUUBVBPwUIPD72S+0KsECBP4Edz63jgACCBgLEPhtgAn8Nq5URQCB6AIE\/uiGVEAgVgECf6ycFEMAAQQQYIbffAwEgX+YzvDvKmd+vWwvoDP8Z1T6b97hzxaQ3yGQhwIE\/jzsNJpcugUI\/KW7f7k7BBBAIJcCzPDb6AeB\/4oPa3od+C\/6XzsI\/DZDgKoIeCtA4Pe2a2hYUgUI\/Entee4bAQQQsBcg8NsYE\/htXKmKAALRBQj80Q2pgECsAgT+WDkphgACCCAQEiDw2wyHIPAP\/1stv2f4m+yQrpWXsKTfZhhQFQEvBQj8XnYLjUqyAIE\/yb3PvSOAAAK2AgR+G98g8F85s7bXgb9\/k+3StQqB32YUUBUBPwUI\/H72C61KsACBP8Gdz60jgAACxgIEfhtgAr+NK1URQCC6AIE\/uiEVEIhVgMAfKyfFEEAAAQRCAgR+m+GQCvz\/92i\/Z\/ib6gz\/1yzptxkGVEXASwECv5fdQqOSLEDgT3Lvc+8IIICArQCB38aXwG\/jSlUEEIguQOCPbkgFBGIVIPDHykkxBBBAAAFm+M3HQCrwv19HNuwqZ369bC\/Qv+n30uVnzPBn68fvEMhHAQJ\/PvYabS7VAgT+Ut293BwCCCCQUwFm+G34U4H\/vWNkw06PA3+z76VL1cUs6bcZBlRFwEsBAr+X3UKjkixA4E9y73PvCCCAgK0Agd\/Gl8Bv40pVBBCILkDgj25IBQRiFSDwx8pJMQQQQACBkACB32Y4pAL\/\/6nr9wx\/8++Y4bcZAlRFwFsBAr+3XUPDkipA4E9qz3PfCCCAgL0Agd\/GOBX4\/6qBv7zNRWKo2l8Df7VFLOmPwZISCOSLAIE\/X3qKdiZGgMCfmK7mRhFAAIESFyDw25AT+G1cqYoAAtEFCPzRDamAQKwCBP5YOSmGAAIIIBASIPDbDIdU4P9LPb9n+Ftsky7VmeG3GQVURcBPAQK\/n\/1CqxIsQOBPcOdz6wgggICxAIHfBpjAb+NKVQQQiC5A4I9uSAUEYhUg8MfKSTEEEEAAAWb4zcdAEPhHzKjv9Qz\/hS11hv8r3uE3HxFcAAF\/BAj8\/vQFLUHACRD4GQgIIIAAAlYCzPDbyKYC\/zsNPA\/8W6VLDQK\/zSigKgJ+ChD4\/ewXWpVgAQJ\/gjufW0cAAQSMBQj8NsAEfhtXqiKAQHQBAn90QyogEKsAgT9WToohgAACCIQECPw2wyEV+P+rgWzY4e9n+S5stVW61GSG32YUUBUBPwUI\/H72S1qtKl++vAwcOFD69u0rNWvWlCOOOEL27NkjS5culVdffVVmzJhxSJ1TTz1Vxo0bJ1WqVCnyGlpj+\/bt8sUXX8if\/vQnWbJkSVrtyeSkZ599Vpo3by5r1qyRG264QZYtW3bYn0+cOFG6du3q2nXbbbfJ7NmzM7lciZ8b3N8HH3wgN954Y0bXJ\/BnxMXJCCCAAAIZCBD4M8DK4NRU4H+7od+B\/0QN\/F\/yDn8GfcupCOS7AIE\/T3uwevXqLrjrv2DKlClzyF1oaNfAP2nSJNm3b1\/qz9MJ\/OFiu3fvlqlTp8pjjz0WqxSBv2hOAn+sQ41iCCCAAAIhAQK\/zXAg8Nu4UhUBBKILEPijG+akwk033SS9e\/d2116wYIE88sgjMn\/+fDn99NPliiuukCZNmoiGdf3rb7zxRqGBf86cOfLyyy8f0v4TTzxROnbsKC1btpQKFSrI3r175a233pIHHnggtnsl8BP4YxtMFEIAAQQQSFuAwJ82VUYnBoF\/5PRGns\/wb5HTazHDn1HncjICeS5A4M\/DDmzWrJncd999cvTRR8vChQvluuuuk23btqXu5Pjjj3d\/Xr9+ffn8889l+PDhhQb+4pab60zzqFGjpFq1arJ161a5++675aOPPopFjMBP4I9lIFEEAQQQQCAjAQJ\/Rlxpn0zgT5uKExFAoIQFCPwlDB7H5XQWf+TIkVK7dm154YUX5Pnnnz+kbPDOe8F35MNL+osL\/Fp02LBhbp8A3R9g1qxZ7uFCHAeBn8AfxziiBgIIIIBAZgIE\/sy80j07FfineT7D\/\/MtcnptZvjT7VfOQ6A0CBD4S0MvFnIPOsPfuXPnQzbFyzTw6+z+448\/LrpqYMOGDW6DvcWLF0dWizvw6ysMl19+ubRp00aqVq0qZcuWlQMHDriVD5999pm7h7Vr16baHV4Foa81\/POf\/5TBgwe7VyH0NQbdA0HPf\/HFF2X69OmF3m+XLl0O+o2+QqEbHT700ENuY0HdlDCdhyoFi\/MOf+ThRQEEEEAAgSIECPw2QyMI\/Ff9+Vivl\/Rf0FoD\/0I27bMZBlRFwEsBAr+X3RKtURp677rrLqlTp84hs\/KZBn5tye233y49evSQXbt2yf333y9vv\/12tAaKSJyBv3\/\/\/m7fgkqVKhXZrtWrV8stt9ySelgRDvyffvqp6L4Fhf1eg\/8zzzxzyCqKiy++2F2zYsWKh1xTr6UbJTZu3JjAH3mkUAABBBBAIE4BAn+cmj\/VIvDbuFIVAQSiCxD4oxt6U6Fu3bpuIz\/9TF+NGjVky5Ytcu+998rMmTNTbcwm8A8aNEiGDBnilvXrjHccO\/bHFfj1X7D6tQK9340bN7oHCe+8847s3LlTOnTo4EK5hnk93nzzTbe3gR7hwK\/\/Wz\/3p38+ZcoUN7uvs\/36IEED\/apVq+Tqq69OrRDQlRO33nprylivqasA9AHLlVdeKZ06dXKrBPRght+bvz1oCAIIIICAiBD4bYZBEPhH\/Udjv2f422yWzkczw28zCqiKgJ8CBH4\/+yXjVgUBOvjhN998I3\/84x\/lww8\/PKhWNoFfg6\/uGaAhVpe\/687\/UY+C7U23ngZzXS4\/e\/Zs9xN9xeD888+XHTt2uE8QvvvuuweVqlevnjz88MPSsGFD0Zl8De4FA78+HNBl+NOmTTvot7oioFevXu5hwD333CPvv\/+++\/OxY8fKWWed5V4XmDBhwkEPVPTPgy8o6OcSCfzp9iznIYAAAgiUhACB30Y5CPxXa+DfXt7mIjFU7aeBvw6BPwZKSiCQNwIE\/rzpqqIbWnC2Ws\/88ccfZd26dS7sRp3h9znw6ysGJ510kpt9v+qqqw76WkEgFjxcWLRokZu5Lxj4ly1b5mbmw1860HOC+9b\/\/uijj8rUqVOlUaNG8uCDD0qDBg0OeoAQ7h39nKE+CNAZfwJ\/KfgbjFtAAAEESpEAgd+mMwn8Nq5URQCB6AIE\/uiGOa9Qvnx5OfbYY0Vn9XXnfg213bt3d8vRdVm\/fk7v448\/du30bYZ\/\/fr1LkwXDNsFUQcMGCAdO3Z0s+3hGf6C5+l7+C1atHAb5rVt29b9dzXRTfyKCvxqoysFCh6FBf6w3+FWO+h7\/61atco68Os93jhkwUFN2rR+T87HGg1AAAEEEMgvgVp1\/vWKWXB0\/mVNadRynYwYMSK\/bsTz1gaBf\/QbOsN\/hLet7XfSZvnFMQvYtM\/bHqJhCMQvQOCP39SLirqp3PDhw90y\/L\/+9a9u471sA7\/+nwL9NJ\/uev\/cc8\/J008\/Hfke43qHXxuiO+vrKwf6rn6VKlVEl9IXdhQV+IuahS8s8Pfr1y\/1WkBhm\/kF1w0+i5jtDL8G\/oLH0F7zIrtTAAEEEEAgWQKXXdNYNOSHj3nz5hH4Yx4GBP6YQSmHAAKxCRD4Y6P0q1D4c3rhJevZzPAH4dXHXfq7desmY8aMcRvo6aEb7ukqAH2dYcWKFfKPf\/xDLrroImnatGmRM\/w+Bv7hw8bIv09ecdCgWvTFdr8GGa1BAAEEEPBeQGf4ax\/z0yz\/L35ZSyrVXEHgj7nngsB\/zeuNZaPHM\/znt90spzHDH3PvUw4BvwUI\/H73T6TWFTaLnmngD296t2bNGrf0XR8gRD3imOHXhxq6gaCGeX0lQFce\/PnPf3afxAsfxb3Dn0ngD\/u9+uqrMnny5EIpnnjiCbe3QLYz\/Br4byqwpD+qOb9HAAEEEECAd\/htxkAQ+K+depzXgf\/X7TbJaXVZ0m8zCqiKgJ8CBH4\/++Wwrbr88svdrPXevXvdzvTB7vHhH4U38lu4cKH7rJ4emQb+YcOGueX8+km+8KsBUdniCPzhe9FP8enu+QWP8AZ6cSzp108f6o7+umfC\/Pnz3asEBR8whO0J\/FFHCr9HAAEEEIhTgMAfp+ZPtQj8Nq5URQCB6AIE\/uiGJV6hd+\/ect1117lN+TRQ6jfhC4ZO\/fO+ffu6zepef\/311Ex0JoH\/vPPOk1GjRonOpOvmf\/pe+dy5c2O537gDf2EPI3Qzw2uvvVb69Okj5cqVi2VJv978HXfcIeecc457feDJJ5+UKVOmHGQS2OtDEgJ\/LMOFIggggAACMQkQ+GOCLFAmCPzXv+r3DH\/fdpukUz1m+G1GAVUR8FOAwO9nvxy2VRrA9XN0ukmdzvLPmjVLdAO5xYsXS7NmzdxsfqdOndyGfcuXL3cPB\/SzdXqEA\/+cOXNEd5oPHxqSdSm67oh\/wgknuJl9DbaH26AuG8I4An\/4dYPdu3e7z+bp\/eg7\/KeffrpbmaAz\/PrQQ484Zvi1Tps2beSuu+5yn93Ta7355psu9B955JFy2WWXuS8kqL0eBP5sRge\/QQABBBCwEiDw28gGgf+GV46Xjd\/7u0t\/35M3yan1\/x+79NsMA6oi4KUAgd\/Lbim+URrsdaZZQ3lRx9KlS+XOO+90DwKCIxz4i7+KyM6dO12I1sAf5xFH4Nf2DBo0yD3gCAJ2wTbqZ\/9Wrlwp7du3l9WrV7sZf\/3f6Sy7L2yX\/qC+rn7Q5fzBZoHh6wYbB9asWZPAH+egoRYCCCCAQGQBAn9kwkILEPhtXKmKAALRBQj80Q1zVkG\/OT948GA5++yzRcOlzsbrjP\/mzZvl3XffFQ3VGtjDRzqBXwOrboL3ySefyCuvvOJWCcR9xBX4tV09e\/Z0s\/k646\/Bv6DBr3\/9a9F9D\/R44IEHZNq0aZEDv9bSzwGOHj3arSKoXLmyu66upHjhhRekS5cu0rVrVwJ\/3AOHeggggAACkQQI\/JH4ivxxEPjHTPF7hr9P+03SkRl+m0FAVQQ8FSDwe9oxNCu5Arp6gF36k9v\/3DkCCCBgKUDgt9El8Nu4UhUBBKILEPijG1IBgVgFCPyxclIMAQQQQCAkQOC3GQ5B4L\/xJb9n+Ht32CQdG\/AOv80ooCoCfgoQ+P3sF1qVYAECf4I7n1tHAAEEjAUI\/DbAQeC\/6cXjZZPHm\/b16rBJTmlI4LcZBVRFwE8BAr+f\/UKrEixA4E9w53PrCCCAgLEAgd8GmMBv40pVBBCILkDgj26YuAoTJ050G9Jlc4Q\/jZfN75PwGwJ\/EnqZe0QAAQRyI0Dgt3EPAv\/Nz3s+w3\/KJunQiBl+m1FAVQT8FCDw+9kvXrdqxIgR7jN32RwrVqyQsWPHZvPTxPyGwJ+YruZGEUAAgRIXIPDbkAeB\/5bnjvN6SX\/Pjhr4F8j5559vA0FVBBDwToDA712X0KCkCxD4kz4CuH8EEEDAToDAb2NL4LdxpSoCCEQXIPBHN6QCArEKEPhj5aQYAggggEBIgMBvMxyCwH\/rs8fJpu+OsLlIDFV7nrpJ2h\/LDH8MlJRAIG8ECPx501U0NCkCBP6k9DT3iQACCJS8AIHfxpzAb+NKVQQQiC5A4I9uSAUEYhUg8MfKSTEEEEAAgZAAgd9mOASB\/7Z\/93uG\/zyd4W\/MDL\/NKKAqAn4KEPj97BdalWABAn+CO59bRwABBIwFCPw2wEHg\/8Mzngf+Tpvk5OMI\/DajgKoI+ClA4PezX2hVggUI\/AnufG4dAQQQMBYg8NsAE\/htXKmKAALRBQj80Q2pgECsAgT+WDkphgACCCAQEiDw2wyHVOD\/U2OvN+0777TNzPDbDAGqIuCtAIHf266hYUkVIPAntee5bwQQQMBegMBvYxwE\/tuf8jvwn\/uLzXLy8SzptxkFVEXATwECv5\/9QqsSLEDgT3Dnc+sIIICAsQCB3waYwG\/jSlUEEIguQOCPbkgFBGIVIPDHykkxBBBAAIGQAIHfZjiEA\/\/mbUfYXCSGqjrD3+4EZvhjoKQEAnkjQODPm66ioUkRIPAnpae5TwQQQKDkBQj8NuYEfhtXqiKAQHQBAn90QyogEKsAgT9WToohgAACCIQECPw2wyEV+J9oLJu3lbe5SAxVz+28Wdr9r4Vy\/vnnx1CNEgggkA8CBP586CXamCgBAn+iupubRQABBEpUgMBvwx0E\/jse9zvw9zidwG8zAqiKgL8CBH5\/+4aWJVSAwJ\/Qjue2EUAAgRIQIPDbIBP4bVypigAC0QUI\/NENqYBArAIE\/lg5KYYAAgggEBIg8NsMh1Tgf+xYr5f09zh9i7RrwpJ+m1FAVQT8FCDw+9kvtCrBAgT+BHc+t44AAggYCxD4bYBTgf+Pngf+LlukXVMCv80ooCoCfgoQ+P3sF1qVYAECf4I7n1tHAAEEjAUI\/DbABH4bV6oigEB0AQJ\/dEMqIBCrAIE\/Vk6KIYAAAgiEBAj8NsMhCPz\/+5FGfi\/p77pF2jb9kl36bYYBVRHwUoDA72W30KgkCxD4k9z73DsCCCBgK0Dgt\/El8Nu4UhUBBKILEPijG1IBgVgFCPyxclIMAQQQQIAZfvMxkAr8DzeSzVvLm18v2wv0OGOLtG3GDH+2fvwOgXwUIPDnY6\/R5lItQOAv1d3LzSGAAAI5FWCG34Y\/Ffgfauh54N8qbZsT+G1GAVUR8FOAwO9nv9CqBAsQ+BPc+dw6AgggYCxA4LcBJvDbuFIVAQSiCxD4oxtSAYFYBQj8sXJSDAEEEEAgJEDgtxkOqcA\/uYHfM\/zddIb\/KzbtsxkGVEXASwECv5fdQqOSLEDgT3Lvc+8IIICArQCB38Y3FfgfqO934P+3bdK2BYHfZhRQFQE\/BQj8fvYLrUqwAIE\/wZ3PrSOAAALGAgR+G2ACv40rVRFAILoAgT+6IRUQiFWAwB8rJ8UQQAABBEICBH6b4ZAK\/PfnwQx\/S2b4bUYBVRHwU4DA72e\/0KoECxD4E9z53DoCCCBgLEDgtwEm8Nu4UhUBBKILEPijG1IBgVgFCPyxclIMAQQQQIAZfvMxEAT+O++rJ5u3lDe\/XrYX6H7mNmnbahGb9mULyO8QyEMBAn8edhpNLt0CBP7S3b\/cHQIIIJBLAWb4bfRTgX9SXb8D\/y+\/I\/DbDAGqIuCtAIHf266hYUkVIPAntee5bwQQQMBegMBvY0zgt3GlKgIIRBcg8Ec3pAICsQoQ+GPlpBgCCCCAQEiAwG8zHFKB\/16d4S9nc5EYqnbXGf4TF7OkPwZLSiCQLwIE\/nzpKdqZGAECf2K6mhtFAAEESlyAwG9Dngr8E47xO\/D\/6ntp+3MCv80ooCoCfgoQ+P3sF1qVYAECf4I7n1tHAAEEjAUI\/DbABH4bV6oigEB0AQJ\/dEMqIBCrAIE\/Vk6KIYAAAgiEBAj8NsMhFfjvqeP3DP9ZOsP\/NUv6bYYBVRHwUoDA72W30KgkCxD4k9z73DsCCCBgK0Dgt\/El8GYJcPwAAB0eSURBVNu4UhUBBKILEPijG1IBgVgFCPyxclIMAQQQQIAZfvMxkAr844\/2fIZ\/u7RtzQy\/+YDgAgh4JEDg96gzaAoCKkDgZxwggAACCFgJMMNvI5sK\/HfXls2bPd6l\/+zt0rbNEpb02wwDqiLgpQCB38tuoVFJFiDwJ7n3uXcEEEDAVoDAb+NL4LdxpSoCCEQXIPBHN6QCArEKEPhj5aQYAggggEBIgMBvMxxSgX9cTb9n+M\/ZIW3b\/Dcz\/DbDgKoIeClA4PeyW2hUkgUI\/Enufe4dAQQQsBUg8Nv4pgL\/2Bp+B\/7uO6XtSQR+m1FAVQT8FCDw+9kvtCrBAgT+BHc+t44AAggYCxD4bYAJ\/DauVEUAgegCBP7ohlRAIFYBAn+snBRDAAEEEAgJEPhthkMq8N+pM\/xlbS4SQ9XuOsPfdilL+mOwpAQC+SJA4M+XnqKdiREg8Cemq7lRBBBAoMQFCPw25AR+G1eqIoBAdAECf3TDWCqUL19eBg4cKH379pWaNWvKEUccIXv27JGlS5fKq6++KjNmzDjkOqeeeqqMGzdOqlSpUmQbtMb27dvliy++kD\/96U+yZMmSWNp7uCKnn3669O\/fX5o2bSpVq1aVsmXLyoEDB+S7776Tr7\/+Wl566SWZPXt2oSWOP\/54ue+++6R+\/frywQcfyI033ph2e0eNGiUDBgxw93vbbbcVeY20C+boRAJ\/juC5LAIIIJAAAQK\/TScHgf9\/31Hd6xn+Hj12Sdt2zPDbjAKqIuCnAIHfg36pXr26C+76L4syZcoc0iIN7Rr4J02aJPv27Uv9eTqBP1xs9+7dMnXqVHnsscdM7vq4446Tm266SVq3bu1CflGHhv958+bJ3XffLWvXrj3otNIQ+CtVqiRDhw4V9bjuuusytibwZ0zGDxBAAAEE0hQg8KcJleFpqcB\/e1W\/A\/+5P0jbdstY0p9h\/3I6AvksQOD3oPc0JPfu3du1ZMGCBfLII4\/I\/PnzRWfKr7jiCmnSpIloWNe\/\/sYbbxQa+OfMmSMvv\/zyIXdz4oknSseOHaVly5ZSoUIF2bt3r7z11lvywAMPxHrnzZo1k\/Hjx0uDBg3kxx9\/lDVr1sj06dPdg4p169ZJ3bp1pXv37tKzZ083e68PNlatWiW33nqrLF68ONWW0hD477nnHunWrZssWrRIBg8enLEzgT9jMn6AAAIIIJCmAIE\/TagMTyPwZwjG6QggUGICBP4Soy78QhqUdQn70UcfLQsXLnQzwtu2bSs0AH\/++ecyfPjwQgN\/ccvfNUTqkvdq1arJ1q1b3ez6Rx99FMvd6wqF+++\/X1q1auVeQ5g2bZo89NBDB61GCC6kry6MGTPGhX99bUEfcFx\/\/fWpe44S+GO5mRiKTJw4Ubp27Urgj8GSEggggAAC8QoQ+OP1DKr9FPh\/Jps3+btpXw+d4T95OTP8NsOAqgh4KUDgz3G36Cz+yJEjpXbt2vLCCy\/I888\/f0iLggCps+Y33HCDLFu2zJ0TXtJfXODX84cNG+b2CdCgPWvWrKyWmxfGFdTVMK9hf8KECYdV1fP0gYOGYl1x8OKLL8pTTz3lfkPgF2GGP8d\/U3J5BBBAoBQLEPhtOjcV+G+r7HfgP2+3tG2\/gsBvMwyoioCXAgR+L7vl4EbpCoDOnTu7ZfJRAr\/O7j\/++OMuVG\/YsMHVCi+nz4ZCa+qrBrpBXyY1O3ToIGPHjpUaNWq4jfx09YGubCgY+PW1AH2g0LhxY\/egYseOHfKPf\/xDnn766UM2ICxu0z59NeLyyy+Xdu3auY0O9bWCw9ULPPQBxYUXXih9+vSRevXquVcjdCWD7j+gDyu0jXroRoX68Eb\/PHxkuokggT+bkchvEEAAAQTSESDwp6OU+TkE\/szN+AUCCJSMAIG\/ZJyzvkqbNm3krrvukjp16hwyK5\/pDL824vbbb5cePXrIrl273DL8t99+O+u26Q\/PPPNMufnmm12ATmeVQfhiDz\/8sJxyyiny\/fffyx133OHuLxz4V6xY4d79r1ix4iFt3LJli9x7770yc+bM1J8dLvD369fPvQ5R1BcN9GGDPrgo6KGvK+gDF31dobANFcN7IhD4Iw0lfowAAgggUAICBH4b5FTgv7WS3zP8Pfcww28zBKiKgLcCBH5Pu0aDrm7kp5\/p01nwwgJuNoF\/0KBBMmTIEDdbrrPTUXfsj1IvCOg6W\/7MM8+41xnCgV+7Rjcr1I3\/nnjiCddTGtr1gYXOoi9fvty9lhDs9F9U4NfVEbo5oDrqbLuG+meffdbN0mst3VhPX6lQY\/2c39y5c921glcPunTp4jYiDD5t+Nlnn7kHHbpaQHfi37lzp9uzQF9n0IN3+D39m4pmIYAAAggIgd9mEBD4bVypigAC0QUI\/NENY6+gYbR58+aput9884388Y9\/lA8\/\/PCga2UT+MOz0Lqrv85qRznCof3RRx91n\/1L9yisLeHAr4Fcg\/6UKVMOKqkhXx+E6Kf\/9KFF8DCgqMCvXyQ47bTT3MODJ5988pB6uqO+biSoDwT++te\/ulUQemiov+WWW6Ry5cpu9YI+NAh\/FjG8+iK8oSKBP90RwHkIIIAAAiUtQOC3EU8F\/puPks2bDv3Ess1VM6\/ao9deadvhG97hz5yOXyCQtwIEfs+6ruAMtzZPZ5f103a6BD68hL20B\/6vvvrKzaKHQ7Z66Hv0atGwYUMJB+3CAr9+jlA3EdRXIj799FO5+uqrC+3xwjZG1HoXX3yxe89fP7X3\/vvvH\/Jb3YdAN17UhzL6eUXtJwK\/Z39T0RwEEEAAgZQAgd9mMKQC\/00VPQ\/8+6TtKSsJ\/DbDgKoIeClA4PesW3QZ+bHHHusCpC4z1+Xm+gk7fY9dl5zr7vYff\/yxa3VpD\/x\/\/vOfi9zxP9jIcPXq1XLttdfKypUr3cZ\/AwYMcMv2dWn+7Nmz3Y73+tm\/o446Sg63okEfLFx66aVub4Mg3Bd2jXSGC4E\/HSXOQQABBBDIhQCB30adwG\/jSlUEEIguQOCPbmheQWeZ9d11fW89vOQ8m8A\/YsQI92m+AwcOyHPPPed2u49yBEFZa2RaL2iLbnxX2Dv8hwvoRc3IFwz8RW2kV9Q962sEwasJwasVixYtcg9e0j3iCPz6wGLj+j0HXfKmIQvSbQLnIYAAAggg4AQ04P\/iV7VSGrXrVJB58+aJ\/juYIz6BIPDfcWMFv2f4e++TdqesYoY\/vq6nEgLeCxD4ve8ikfDn9JYtWyZXXnml+4RdNoE\/CKP5sEt\/kgP\/8GFjZNrLaw8anZ+8tzkPRitNRAABBBDwSaB56ypSq85Pn4vt\/MtasnPf1wT+mDspFfjHlJfNGz1+h7\/PfmnXcTWBP+b+pxwCPgsQ+H3unVDbgtnmNWvWyA033CAa\/DMN\/OF338N1ohDowwjd+K9p06ayYcMG17bFixcXW1L\/xThu3Di3Ud7XX3\/tluPrQ4zwHgaHW9IffNJPX30YPXq0e3e+sCX9+jm+4L39xx9\/XF555ZVi2xacEFwj\/NpAOj+OY4ZfAz8z+ulocw4CCCCAQCYCLOnPRCv9cwn86VtxJgIIlKwAgb9kvQ+5mi6Jv+iii0SXtU+aNKnQjeHCIXjhwoXus3p6ZBr4hw0b5pbz6yf5wq8GRCUI6ur+A\/olgYK72ResH\/7cnW7IpzvtP\/XUU+608L2GN+QL1wg\/uAhvxFdY4D\/ppJPcO\/kFd+BP5551E74+ffq4TfvGjx9faN9o\/6mpPqzQ\/tP7J\/Cno8s5CCCAAAK5ECDw26inAv\/vy8nmjTbXiKNqjz4HpN2pa5jhjwOTGgjkiQCBP8cd1bt3b\/cted2Ur7BPv2nzwp+he\/3112Xy5MkZB37dvE4Dsc7IF\/zefFQCrXn\/\/ffLiSee6B5czJgxQ+69995DdtfX62jY10\/g6UaE+uBBH2Dopnpbt249JPAX\/L590E5dRaCf5dOHBboHwUsvveT+qKjP8j322GPSrl07d9\/arvCXDoI26WaInTp1cudoYJ81a1axn+WrXr26PPjgg9KiRQu3yWKw0iAI\/OHXLzIx1r5ihj8TMc5FAAEEEEhXgMCfrlRm56UC\/w3id+DvK9Lu1LUE\/sy6l7MRyGsBAn+Ou69gWNagqRvY6bL4Zs2audl8DaK6Yd\/y5ctd+F+79l\/vdodn+OfMmeN2oQ8fGq51hrtjx45ywgknuICtm9IFG+TFeevaVg3N+qk8\/YygvjIwffp0F\/51uX3dunVdyO\/Zs6fUr19fypQpI6tWrXKrAcKvABT8LKHuuP\/aa6+5VQD6ab3f\/e53csYZZziPBQsWuIcFOrt+uMDfrVs395BBZ\/n1wcK0adNkypQp7r936NBBhg4dKq1bt5ayZcuKOmpNfZgQXomg9zR37lz3gGH+\/Pnud1dccYV7yKHnahv11QY9dEWBXlMfHtx5553uawGZHAT+TLQ4FwEEEEAgEwECfyZa6Z9L4E\/fijMRQKBkBQj8Jetd6NU0LN9xxx0ulBd1LF261IXHcDgOB\/50bkNnzPWhgAZ+i0OX2muA19l0Dc9FHfqFAN0hWB8QBA8vgnPDgf+zzz5zQVxXPxQ8CvMoaoZff6u79WtAr1SpUqHN0kCvu\/GrsT5YCQ6dxdfP87Vq1co9pCh46L3oMn7dVV+Dvx76UEJ39dcHLHroQxbdD+CNN95Ii53AnxYTJyGAAAIIZCFA4M8CLY2fBIH\/9usPeD3Df27fMtKu0zpm+NPoU05BoLQIEPg96UkNohoSzz77bKlZs6YLi7o8fvPmzfLuu++KbtqngT18pBP4NWzqDPgnn3ziNqwLh1mrW9d2XXLJJW4jv6pVq7rwr\/eis\/VffPGFvPnmm0XOeocDvz6c0GXxl156aWpVgM7Kv\/fee6Ib8BX0OFzg13tt0qSJ6Dv3+kCiSpUqLsCrz\/r1691KBJ31L1hTf6cz\/fqevr5GEPSN\/k4fVujKA13JED70\/D\/84Q9uJYI+rNi\/f39Gnywk8FuNTOoigAACCBD4bcYAgd\/GlaoIIBBdgMAf3ZAKnggUF\/g9aWaxzSDwF0vECQgggAACWQoQ+LOEK+ZnqcB\/3T6\/Z\/h\/XVbadfqWGX6bYUBVBLwUIPB72S00KhuBIPDrigZdYq+vBOTjQeDPx16jzQgggEB+CBD4bfopFfiv2SObN\/5oc5EYqp57fjlpd9oGAn8MlpRAIF8ECPz50lO0s1ABXT6vewfo+\/O6WV7z5s1l9erVcu2118rKlSvzUo3An5fdRqMRQACBvBAg8Nt0E4HfxpWqCCAQXYDAH92QCjkUaNmypUyYMMHt4K+Hbr73l7\/8xW2+l68HgT9fe452I4AAAv4LEPht+uinwP+DbNrg8wx\/eTn5FxuZ4bcZBlRFwEsBAr+X3VJyjQq+GZ\/NFXVXe91oMJeHfuZv9OjRbhM+3UhPP2uoDwB0c798PQj8+dpztBsBBBDwX4DAb9NHqcA\/eoffgb9fBTn5F5sI\/DbDgKoIeClA4PeyW0quUSNGjJD27dtndcEVK1bI2LFjs\/otPypagMDP6EAAAQQQsBIg8NvIEvhtXKmKAALRBQj80Q2pgECsAgT+WDkphgACCCAQEiDw2wyHIPD\/4ervZdOGAzYXiaHqef0qysmdtzDDH4MlJRDIFwECf770FO1MjACBPzFdzY0igAACJS5A4LchJ\/DbuFIVAQSiCxD4oxtSAYFYBQj8sXJSDAEEEEAgJEDgtxkOqcA\/apvfM\/wXHCknd97KDL\/NMKAqAl4KEPi97BYalWQBAn+Se597RwABBGwFCPw2vqnAf9VmzwN\/JTn59G0EfpthQFUEvBQg8HvZLTQqyQIE\/iT3PveOAAII2AoQ+G18Cfw2rlRFAIHoAgT+6IZUQCBWAQJ\/rJwUQwABBBAICRD4bYZDEPhvG7lRNm3Yb3ORGKqed2FlaX\/698zwx2BJCQTyRYDAny89RTsTI0DgT0xXc6MIIIBAiQsQ+G3IU4F\/xLeeB\/6fSfsu2wn8NsOAqgh4KUDg97JbaFSSBQj8Se597h0BBBCwFSDw2\/gS+G1cqYoAAtEFCPzRDamAQKwCBP5YOSmGAAIIIBASIPDbDIcg8N965VqvZ\/h79q8q7bvsYIbfZhhQFQEvBQj8XnYLjUqyAIE\/yb3PvSOAAAK2AgR+G18Cv40rVRFAILoAgT+6IRUQiFWAwB8rJ8UQQAABBJjhNx8DPwX+1bJp\/T7z62V7gZ79q0n7rruY4c8WkN8hkIcCBP487DSaXLoFCPylu3+5OwQQQCCXAszw2+gHgf+W4d\/4HfgvqiEduv5A4LcZBlRFwEsBAr+X3UKjkixA4E9y73PvCCCAgK0Agd\/GtzQH\/vLly8vAgQOlb9++UrNmTTniiCNkz549snbtWnnxxRdl+vTpNqhURQCBWAQI\/LEwUgSB+AQI\/PFZUgkBBBBA4GABAr\/NiEgF\/iuWy6b1e20uEkPVnhfVlA5n7El7hr969eoybtw40fvbt2+frF+\/XrZt2yZ16tSRWrVqyd69e+U\/\/uM\/ZPLkyTG0jhIIIGAhQOC3UKUmAhEECPwR8PgpAggggMBhBQj8NgMkCPw3D1vqdeDv9Zta0uGMvWkH\/mHDhrnZ\/Z07d8ojjzwib7\/9tgPUWf9rrrlGevfu7Wb7x48fL++\/\/74NLlURQCCSAIE\/Eh8\/RiB+AQJ\/\/KZURAABBBD4lwCB32YklMbAr6H+6aeflhYtWsh\/\/ud\/ulAfPqpVq+YeAjRt2lTeeecdGTt2rA0uVRFAIJIAgT8SHz9GIH4BXwJ\/89ZV5LJrGstNQxbEf5N5WLFWnQry+3uayqSbv5ZN6\/fk4R3E3+QJz5wo\/z55hSz6Ynv8xfOw4u\/HN5WP39skn7y3OQ9bH3+T9Z8feugY4fhX0K51TMWcexD4bUZjKvBfrv+O8HdJf6\/fHC0duu1La4a\/UaNGLuTXr19fnnzySZk6deoheBMnTpSuXbvKBx98IDfeeKMNLlURQCCSAIE\/Eh8\/RiB+AZ8CvwaYob3mxX+TeVhRA\/\/EZ06UG4csIPD\/T\/\/96T\/byaRbvibw\/4+HPgCZ9vJaAv\/\/eOg\/Pzau35PzgOvLP270AUjtOhXc3zO5PAj8NvqlMfAXJxVeATBz5ky5+eabi\/sJf44AAjkQIPDnAJ1LInA4AQK\/n+ODwH9ovxD4DzYh8B\/sQeA\/2IPA7+c\/2+NqVRD4bxq6yOuHwr0uriOndDuQ1gx\/cTb6\/v7o0aOlXLlybun\/Sy+9VNxP+HMEEMiBAIE\/B+hcEgECf\/6NAQI\/gb+4UUvgJ\/AfbowQ+Iv7Oyi\/\/zwV+D1fBdbr4rpyyr9J5MDfrFkzt9y\/QYMGsmTJEhk1apRs3bo1vzuR1iNQSgUI\/KW0Y7mt\/BXQGf7bbrvNi2XS+h4\/72f\/NJbwOPjvK\/XQJdubvmVPA5XB4+DxUeuYCu4vMD7+5aIeuqQ\/1\/9M1XasXL1ARowYkb\/\/ovSw5UHgz3X\/FkdT+5gKsmf\/pkiBv169eu5Tfa1atZItW7bIvffeK7qknwMBBPwUIPD72S+0KsEC+n8a2rVrl2ABbh0BBBBAwFJg3bp1qc+rWV4nSbU1BJ977rl5c8vPPPNMVm097rjj3G78ujP\/tm3bDvpUX1YF+RECCJgLEPjNibkAAggggAACCCCAAAL5LXDKKae4nfh1Gb\/O7E+ePFnefffd\/L4pWo9AAgQI\/AnoZG4RAQQQQAABBBBAAIFsBc4++2y55pprpEaNGrJ27Vq555575NNPP822HL9DAIESFCDwlyA2l0IAAQQQQAABBBBAIJ8EunXrJmPGjHFhf+nSpXLnnXfK4sWL8+kWaCsCiRYg8Ce6+7l5BBBAAAEEEEAAAQQKF9B9hXSDPg37CxcudJsK6ww\/BwII5I8AgT9\/+oqWIoAAAggggAACCCBQIgLly5d3m\/K1bdtWVq9eLbfccgsz+yUiz0UQiFeAwB+vJ9UQQAABBBBAAAEEEMh7gTPPPNOF\/MqVKxd7Lx988IHb0I8DAQT8EyDw+9cntAgBBBBAAAEEEEAAgZwKjBgxQgYOHChlypQpth0E\/mKJOAGBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBMg8NvZUhkBBBBAAAEEEEAAAQQQQACBnAkQ+HNGz4URQAABBBBAAAEEEEAAAQQQsBP4\/wGIXcAk52IsvAAAAABJRU5ErkJggg==","height":319,"width":530}}
%---
%[output:471d3463]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAA\/wAAAJmCAYAAADhK4tqAAAAAXNSR0IArs4c6QAAIABJREFUeF7snQu8llPa\/68OiopE0oHEiJyNUzWU3oZJwzh1IPoTTaTkVBRRU4roQBpCGExiehk0GjTepnGYhpwPqfRKRodROtm7pNP\/81vee3c\/z3723vezn\/t+9v08z3d9Pn1mtNd93Wt917U2v\/u61rWq7bXXXjuMBgEIQAACEIAABCAAAQhAAAIQgEBeEaiG4M+r9WQyEIAABCAAAQhAAAIQgAAEIAABRwDBjyNAAAIQgAAEIAABCEAAAhCAAATykACCPw8XlSlBAAIQgAAEIAABCEAAAhCAAAQQ\/PgABCAAAQhAAAIQgAAEIAABCEAgDwkg+PNwUZkSBCAAAQhAAAIQgAAEIAABCEAAwY8PQAACEIAABCAAAQhAAAIQgAAE8pAAgj8PF5UpQQACEIAABCAAAQhAAAIQgAAEEPz4AAQgAAEIQAACEIAABCAAAQhAIA8JIPjzcFGZEgQgAIE4EDjwwANt3Lhx1rRp01LDef31123w4MEph3nmmWfawIEDbbfddkv4+Y8\/\/mj333+\/TZ8+PQ7TYwwQgAAEIAABCEAg9gQQ\/LFfIgYIAQhAIDcJlCf4v\/76a7v22mtt5cqVpSY3ZMgQO+ecc0r9PYI\/N\/2AUUMAAhCAAAQgUHUEEPxVx543QwACEMhrAuUJ\/qKiIrvzzjtt9uzZCQxq1qxpU6ZMsVatWiH489o7mBwEIAABCEAAAtkggODPBmXeAQEIQKAACZQn+Hfs2GFPP\/20TZo0KYHMMccc4z4ENGjQAMFfgD7DlCEAAQhAAAIQCJcAgj9cnliDAAQgAIH\/I5BK8G\/fvt2qVavm\/nz00UfWt2\/fBF6XXHKJ9e7d22rVqmVK4a9Ro4b7o0ZKP64FAQhAAAIQgAAE0iOA4E+PF70hAAEIQCAggVSCf9myZVa\/fn2rV6+effvtt6bz+p9\/\/nmJxbvuusvat2\/v\/lnn\/Bs3buzEf3mCv3Xr1nbppZday5YtrU6dOla9evWS\/nrHzJkzberUqbZ169aS9wwYMMC6detmu+yyi\/u7LVu2uD4PP\/xwSZ8uXbqY+tWuXbvMPgFR0A0CEIAABCAAAQhUCQEEf5Vg56UQgAAE8p9AKsE\/b948a9asmavcnxyxl7ifOHGiNW\/e3LZt22Zz5861k046qVzB369fP7vgggtK+qSiquMD77\/\/vt166622bt0610UfHcaPH29HHHFEySP6OHDbbbfZxx9\/bBr72LFj3Vi99uGHH7oPAP4PB\/m\/iswQAhCAAAQgAIFcJoDgz+XVY+wQgAAEYkwgleDXdXwS2zqrr+a\/nq9jx4528803u+i\/ivrNmDHDzjvvvJLr+ZI\/EJxyyik2dOhQ23PPPSukoAj+448\/bo899lhJ3+OOO85GjRqVUC9A45FN\/enUqZM7eqC2du1a98FAHw5oEIAABCAAAQhAIFcIIPhzZaUYJwQgAIEcI1CW4Jd49q7d81\/Pp+h5jx49nMhW6r\/S62+88Ub3AUAtWfCPHDnSTj\/99BIqX3zxhY0bN85F6JXmr2f9EXr\/xwXvoSuuuMJ69uxZktq\/efNme+mll5zY996rv9PHAv2hQQACEIAABCAAgVwigODPpdVirBCAAARyiEBZgv+dd96xa665xqXh+6\/ne\/DBB0si\/0r9f+qpp1wEvizBryMAp512mnXo0MH23Xdfu+eeexKu+dMHhIsuuqiEWKoigboGUDcFHHvssWWS1XgHDhxIKn8O+R5DhQAEIAABCEDgJwIIfjwBAhCAAAQiIZBK8M+ZM8eefPJJGzNmjDVq1Mi86\/lee+21Un8noV2e4C9r0HqvIvT6GOCP8C9cuNB69epV6rGjjz7abr\/9djee5LZixQpXWHDRokWRMMIoBCAAAQhAAAIQiJIAgj9KutiGAAQgUMAEUgn+adOm2eTJk23KlCnWqlUrR0eR99mzZ1v\/\/v1d1H\/Tpk2uoN7q1asDCX4J9nPPPdf0v\/vss0+ZBfzKEvwagz4E6I9XkV9\/pyMEyjp4+umnC3gVmToEIAABCEAAArlMAMGfy6vH2CEAAQjEmEBZgl8p9MOGDbPOnTu70as6viLoKsKnpqj6oEGDbK+99nKCX0X+PAF+\/\/332\/Tp090\/q1ifIvMqvuddxae\/Ly4utq+++sq+\/\/57a9OmTQmh8gT\/YYcdVpJh4D2wfv1693fKSqBBAAIQgAAEIACBXCSA4M\/FVWPMEIAABHKAQHmC\/8ILL7SrrrrKReNVFE9X3dWtW9fNyjtrn\/x8ctE+ifH27du7In\/e1Xsq9KeifWpBzvCrn87xjx492tq1a1dSld\/Du3jxYmfHu84vB7AzRAhAAAIQgAAEIFBCAMGPM0AAAhCAQCQEyhP8upbvzjvvTLgSzxvEiy++6CLr5Qn+5Oe9rIAvv\/yyZC7XXXedXXDBBSX\/nKpKv36omwH69u2b8iiAPiToekCNhwYBCEAAAhCAAARyjQCCP9dWjPFCAAIQyBEC5Ql+penrLL\/6+Jui+Pfdd58999xz5Qr+7t27l5z51\/PJgl\/p\/qra79UJUJ9Ugv+QQw5xYr5JkyZuGBL4qh3QsGHDkmi\/bhIYO3aszZo1K0fIM0wIQAACEIAABCDwEwEEP54AAQhAAAKREKgoJV8Rfl2p5286z6+q+J9\/\/nm5gr9jx4528803l1zZt23bNnvzzTedeG\/evLlLwz\/iiCMSUvTnz59vvXv3Lnmdl8qvYwFe09n\/4cOH22233WYHH3xwwt\/fcMMN7sMCDQIQgAAEIAABCOQKAQR\/rqwU44QABCCQYwQqEvyXXHKJE+A6x++1BQsWWJ8+fdyZ\/vKeV0R+woQJ1qJFi8BUkov2Jafyq5aACgoqu+Dss8+2a6+91urUqePsK\/L\/6quv2ogRIwK\/j44QgAAEIAABCECgqgkg+Kt6BXg\/BCAAgTwlUJHgb9u2rRPQu+++ewmBl19+2UaOHFnyz48\/\/rgdeuih7p+Ti\/Yprf\/KK68sEeV+jBLoKv6n1H7vo4A\/eyBVKv8bb7xhQ4cOdR8b1BTp79SpU0mWwMaNG23ixInuTD8NAhCAAAQgAAEI5AIBBH8urBJjhAAEIJCDBCoS\/I0bN3YCWin4nqDXuf5nnnkmkOBXJ1XW79Wrl0u\/V6bAli1b7D\/\/+Y\/NnDnTpk6darfcckvJ9X9K+9ffPfLII64qvz+VX6n6Okqg6wG9pvHr7H6zZs1K\/k4p\/6T256AzMmQIQAACEIBAgRJA8BfowjNtCEAAAhCAAAQgAAEIQAACEMhvAgj+\/F5fZgcBCEAAAhCAAAQgAAEIQAACBUoAwV+gC8+0IQABCEAAAhCAAAQgAAEIQCC\/CSD483t9mR0EIAABCEAAAhCAAAQgAAEIFCgBBH+BLjzThgAEIAABCEAAAhCAAAQgAIH8JoDgz+\/1ZXYQgAAEIAABCEAAAhCAAAQgUKAEEPwFuvBMGwIQgAAEIAABCEAAAhCAAATymwCCP7\/Xl9lBAAIQgAAEIAABCEAAAhCAQIESQPAX6MIzbQhAAAIQgAAEIAABCEAAAhDIbwII\/vxeX2YHAQhAAAIQgAAEIAABCEAAAgVKAMFfoAvPtCEAAQhAAAIQgAAEIAABCEAgvwkg+PN7fZkdBCAAAQhAAAIQgAAEIAABCBQoAQR\/gS4804YABCAAAQhAAAIQgAAEIACB\/CaA4M\/v9WV2EIAABCAAAQhAAAIQgAAEIFCgBBD8BbrwTBsCEIAABHKPQK9evez999+3jz\/+OPcGz4ghkGUC7JcsA+d1EIBALAkg+GO5LAwKAhCAAAQgkEjglFNOsVtuucXefvttGzFiBHggAIFyCLBfcA8IQAACPxFA8OMJEIAABCAAgRwgcPvtt9tpp51m69evtzFjxticOXNyYNQMEQJVQ4D9UjXceSsEIBA\/Agj++K0JI4IABCAAAQiUIqCI5dChQ23PPfe0Dz\/80EaPHm1XXXWVffHFF\/b4449DDAIQ8BFgv+AOEIAABH4igODHEyAAAQhAAAI5QmD48OHWqVMn27p1q\/uz22672TfffGPXX3+9+18aBCCwkwD7BW+AAAQggODHByAAAQhAIIsE6tWr595WVFSUxbfmz6t69OhhV155pdWuXdu2bNlic+fOtcmTJ9tXX32VP5NkJgkE2DOVdwj2S+XZ8SQEIJA\/BIjw589aMhMIQAACsSVQs2ZNu\/TSS61r166uwvzgwYNjO9a4Dqx79+7Wv39\/q1Wrlhvitm3b7Nlnn7V77703rkNmXBkQYM9kAM\/M2C+Z8eNpCEAgfwgg+PNnLZkJBCAAgdgSkHgZP368nXTSSbZx40abOHGizZgxI7bjjePA6tevb7fddpt9+eWXpvPJBx54oH377bfu77imL44rltmY2DOZ8WO\/ZMaPpyEAgfwhgODPn7VkJhCAAARiTeC4446zUaNGWYMGDWz+\/Pl2ww03uIrztNIEVJjvwgsvtGOPPdZq1KhhCxYssGnTptmKFStc5y5dutiAAQNcav\/rr79OxkSeOhF7JtjCsl+CcaIXBCBQmAQQ\/IW57swaAhCAQJUQGDJkiJ199tn2448\/usryVJdPXAZ\/GrdEjL+p7sGjjz5qzzzzjPmjv\/r7sWPH2qxZs6pkTXlptATYM2XzZb9E63tYhwAE8oMAgj8\/1pFZQAACEMgJAkpDlzht1qyZLV++3AYNGmRLlizJibFHPUiJl5tuusnOOOMMJ+jF591337UWLVrYYYcdZrvssot9\/vnndvPNN7tUfv+1Y5999pkNHDiQjImoF6kK7LNnUkNnv1SBM\/JKCEAgJwkg+HNy2Rg0BCAAgdwl0KtXL9MfFZ\/TOf4xY8bk7mRCHLmXpl+9enXHRcX4dPWeWocOHaxVq1b25JNPuhoIXiP6G+ICxNgUe6b04rBfYuywDA0CEIgVAQR\/rJaDwUAAAhDITwKKRp933nmmNPUdO3ZY06ZN3Vn+tWvX2ujRo+2tt97Kz4kHnJWilVOmTHGiXgX4VI3fE\/vlmVD0d9y4cY6nruZTXQTvnH\/AV9MtpgTYM2UvDPslpk7LsCAAgVgSQPDHclkYFAQgAIH8IFCnTh275ZZbrH379i4lPVV75513XDp6EIGbH1RKz0Ip+8p0aNSokSvON2nSpMBT9Ud\/\/\/nPf9prr71m3bp1s1dffdWmT58e2A4d40GAPVPxOrBfKmZEDwhAAAIeAQQ\/vgABCEAgJAKtW7e2iy++2A4++GAnbtetW+cqqP\/xj390\/78Q2\/Dhw61Tp062ZcsW+8c\/\/mFTp061DRs2uAr0Z555ptWrV49r+szshBNOcDcY6CqxIIJf0d+jjz7aHnjgAfeMrjw84ogjElxs9erV7rz\/p59+GlvXY8+UXhr2TMXuWqj7pWIy9IAABCBQmgCCH6+AAAQgkCEBpanrLHXbtm3dufTkpgJrd999d8Glres\/ykeOHGl77LGHvfDCCy713N90Ll1F6pTav3jxYnfNXL5+GJGP\/OpXv7L999\/f3VAwd+5cV5DPa\/r7e+65xxUznDdvnl1zzTVleqUyJs466yxbtWqV8zsV8vOz1IPyucmTJ9srr7ySoXdH8zh7JjVX9sxPXNgv0ew7rEIAAoVJAMFfmOvOrCEAgZAI6CypzqC3a9fORbHfe+89V3BNTdfPHX\/88e4jgM6qS\/TPmTMnpDfH30y\/fv2sZ8+eTsQr0vzRRx+VGnSPHj3syiuvNBWqU\/T\/4Ycfjv\/EzFwV\/SZNmti\/\/\/3vcser9Gydx1c2Q+3atUv6qo7BypUr7b777ivxiQkTJriPRvKVYcOGJXwQ8L+ke\/fuzqY+HNx666329ttvl4ikX\/7yl\/bdd9\/Zm2++GdsjEuyZsl0mX\/cM+yUnfq0xSAhAIE8JIPjzdGGZFgQgkB0CV1xxhRO127dvt4ceesiefvrphBd7glZib8GCBXb99dfnbRQ7mbgi9hdddFG51+\/575NXsTlFrBctWpSdxavkW3Rt3lVXXeWObUhwv\/\/++yktKUqpVPvDDz\/c+YcEvj5+6O8bN27sPnIUFRXZgw8+aM8995z7QKSie\/IVHQUZOnRoStFeluCv5HSy\/hh7pmzk+bhn2C9Z32K8EAIQgEACAQQ\/DgEBCECgkgT8laKVoi2x5m\/J0d3Nmze7M9f5VEhNDHR2XOfylyxZkjB\/T7x8\/\/33pnPJYpSqdezY0WUA1K1b1xWaGzFiRCVXJDuPSZhfe+21pvUtS5j7o9hio49Bzz\/\/fMkAdWOBMht0\/l4RfX04UHV+Fes79thjTb6S6gOSDOiYxOmnn25ff\/21G4c+JORKY8\/8lB1SSHuG\/ZIru5NxQgAC+UoAwZ+vK8u8IACByAn4r0RLLrSmM9Z9+vRxVdcV3dU5a1275qVfRz64iF+gwoSDBg1y0WtFupWi\/r\/\/+7921113lRSJUxq7qu\/rSIPS9RXJTtUU7Z44caI1b97cRcB1REIp6XFtEmxjx451UXp9wHnjjTdKDVUfMXTWXn0ff\/xx98ff9PeqXyBGivR7NxWoGJ9X12Djxo322GOP2VNPPeUe1TPyqQsuuCDnjkB4c2fPFN6eYb\/E9TcZ44IABAqFAIK\/UFaaeUIAApUioCjuf\/3Xf7n70YuLi2327NklKeeprobSWf7LL7\/cDjnkECfKVDxNQv+ll15ygk3prbp+Lq7F1IJA6tKli\/Xt29dV2E9uy5Ytc0JXafk6464z6vvtt1+5af2yIUF86KGHOnMffvihK+CXy9f0eWexFX3Xh5Evv\/yyBJV8RD8\/4IAD3N+p+J7nI\/pnpewr+i\/f04cUnclXH31g0HEA\/Z0+MigrII6M2DOldxF7pvzfLIW8X4L8zqUPBCAAgUwIIPgzocezEIBA3hKQOL\/00kuta9euTmR5TYX5VEX99ttvt913372ksroi+BJlbdq0cRFtpWTPnDnT7r\/\/fnftnMSaivYpMi6xNnjw4Jxkp6vgNPd99tnHli5d6iL3+hAiTscdd5ybk9LcdRZf7brrrnM\/08ePstL1vahvw4YNrVq1ak7QilsuHH3Qeuooh4o1PvrooyVretttt9mvf\/3rhA8dLVq0cGf\/PR9RNsOzzz5rTzzxhBPuEsoqxKf\/r6r7qtQvvxETryn9X+f9vWfi5ETsmdSrwZ7ZyYX9Eqcdy1ggAIFCIYDgL5SVZp4QgEBgAhJeOnOuSKyaIqz6o0i1zplLkL722muukrpXWd0zLsH2r3\/9y12J9tVXX5W805\/KLEGcS4Lfq0Ug4aKr5Lp16+aOJkjU6mOGmv8ueBWiU8r7rFmz3McSnUvXf+iLzZ\/+9CeXBu9vEsznnnuuO8O+2267ueKG3oeSwItWBR333ntvNzet7fLly10k36tj4NUvkEBXTYL27duXVOr3fOTee+81FSo85phjXMRfV\/MlV+fXNW2q3F+jRg2X+RDX6vvsmUQHZM+U3pDslyr4JcUrIQABCJgZgh83gAAEIJBEQMJNAlSRVglUpVvr\/ytFXUXSVq9ebRJr+jt\/QSql76squwR9cvOn\/7\/44os2ZsyYnOGuc+WqGC9RLzGvlqoIn9dPIn\/+\/Pku8r1+\/fqEO+JVz0CCXgxUzM67ulAfUSSeFb3OpdarVy\/TH2V1+DMYvEr6qm+grBD9XHPXUQedy\/ef+\/c+Doit\/5q9XOLAnklcLfZMau9lv+TSrmasEIBAvhBA8OfLSjIPCEAgFAKKYt95553WoEEDmzFjRoXC3H+tnITdCy+84KL+yc0TRD\/88IPdcccdrhZALjWl6EucK708OZrtn4fXT1Fsf7G6k08+2RWjUxHD5FZW5D8bfLyPOPogo6yEdIsF+jMb\/AUH\/fULNA9\/LYfkeXmCXx9HJPiVRZFLjT2TerXycc+wX3JpZzJWCEAAAj8RQPDjCRCAAAR8BC688EJ3zlriXVHst956q0I+Ors+atQo95EgOaXff25bYrmsDwIVvqSKO\/iPJJR3zZ6\/nwr43XjjjSVp7kpzVoRPRRCVBSDGixcvdlXoq+r2gl\/96ldujCpA6FXK9xfC0zhVcO3nP\/+5W4EPPvjAZSFI3HutLBveffP6KKSIvrIkkovs6Wc6viDR\/MUXX7hihRL+udTYM6lXKx\/3DPsll3YmY4UABCCA4McHIAABCJQikG56tYSahPy+++7rCtRJ9Kdq+hCgyvyKIsexsrpuD9B1bwcddJC7Zk8FCFWHwH+bgF\/Alpf9ELRfXNxPVwnqjL3WyF8sUB8nxMRftFFjltjXUQ\/\/VXupbOi5e+65x93woI8bqvswbty4kroH+gCizI\/TTjvNpfs\/9NBD9vTTT8cFS+BxsGcKa8+wXwJvDTpCAAIQiAUBIvyxWAYGAQEIZIuAIu6K2EqE6Qy5KsH7o8ve2WuNp7xK8SpApdT8I4880qWBqwhf8t30suFFsf\/whz+kvK89qnl7V+Z5Z+7Leo835qOOOspV0vc3FZzTzQJz5sxxf+0XsPqZ0s\/ff\/\/9UqaV5q5jDYcffriV1y+quadr15+hoYwDCdjOnTu7q\/F09l5X62keEujNmjVzH0T0ceD55593tRzUUtnQh4Hkowz6OxXqU1N6tJgm20p3\/FH3Z88kEi70PcN+iXrHYR8CEIBAuAQQ\/OHyxBoEIJBlAkqJlsBUFf3ymsSVIvDelWheX12f54+sqmK6d4Z\/7ty5rvBcWU3RWgm6hQsXulR1r0kY6oOCmgrUeZXss4HGfzWabgko7z57Xf2mc\/XKShAHXTeo1HNVhj\/11FOd2PUX39P4\/UUKVZwwVZp6cr9UqfLZYJHOO7zrA\/WMjl0oc0NCV5kMXoFG\/UzMrr\/+eleLQMz8hQY9G4rW\/\/d\/\/7f7mZo+CumD0M9+9rOEK\/b0s\/LO9qcz\/nT6smcSabFn0vGen\/oW0n5Jnw5PQAACEIgXAQR\/vNaD0UAAAmkQUBr6pZde6q7KU7RZ17qlameeeab179\/fCVuJMVXZV+Rdok3R2uQotHfVnv96uVR2vdTWZMGfxhRC7+qPrienqPtfdsghh7gMhaZNm7rK8apBoOi217yCYzp+MHXqVHv44Yfdj\/xFCvUhY+LEiU4UJzf1Gz16tPvAouvk9P8lbrPZNAZVS\/\/FL37hrs6TQNc5+b\/\/\/e+lfEUfhLTuEvnFxcVunl9\/\/XXKM\/X+DyX6qKKPQora+21orrq20PNJ2VPqvuoXNGzY0PmgxqE0\/2we8WDPlPZA9sxPTNgv2fztxLsgAAEIZI8Agj97rHkTBCAQEoHklNpt27a5qKwi7snNE2dKnV66dKm7A967Eq1Hjx4ubbt27druKj0vWu0vTKUIvSK6\/iJteodEgiK4LVu2dM8qghuX5o\/CeynqyePXfe8Sfyqsd80115SkmXtz0AeSbt26OTbJVfn9Kb3JGQB+BhLAOvrw6aefZhWNMixUeFHz8442+Aegjz5ffvml+4jhvx7PO86hzAa1l19+2UaOHJly7N6tC7Ll\/yAin+rbt6\/7kOS\/pi+rAFK8jD1T\/goU8p5hv1T17uT9EIAABKIlgOCPli\/WIQCBEAnoP0wlRBWxlxBVKy8lWiJfolxi55\/\/\/KeLuPrT62VPUV2l8SdHq8eMGeMKuanpnLoyCDzRrEiYUlolEhQ1ViG+WbNmhTjTzEx50XWNXx9Dnn322ZKz5p5lFZw79NBD3S0EEq9e07PXXnutm5v+vwoSqiUX6SsrAyCzkWf+9Iknnugi7orUqymTQxF7RdQVWVc2iMS4mjIgxEbFCRVl13zlL8cee6z7+YsvvljmtYzKkNAHpn322cc++ugjJ\/LV\/DYqyhDJfLYVW2DPVMzIWzdloRTanmG\/BPMPekEAAhDIZQII\/lxePcYOgQIh4D9j61VMl9CeOXOmK6xX1hl5fRgYOHCgozR+\/HjX3y9sdX5dUWBPAPqj1XqPnlHhOTWJ\/ffee8+JRJ3vViq8RGJcr9nzR+GT08s1n0cffdTNTXPu3bu3m6Mi8rqirnXr1m5uf\/7zn915fn0w8d8xr75KkdeHDhWxS84AqCq39KfaJ1+P6I3Jf02iIvn6IOBfQ9nQxwxlcCgdXx+Yykq5V\/T\/9NNPd9kR+miirAE1f4aIjjOUV0chKlbsmfTJFtqeYb+k7yM8AQEIQCAXCSD4c3HVGDMECohAu3btrF+\/fnbAAQe4aHNZQi4VEi9FW8+oEN\/s2bNdN4l5Rft1vlyCT+ewFbFNPq\/u75dcwT7V1WzZWBYJ0aD3tHtp5xq7jh1IyHpNV+cp4j1t2jQ3f0X6dCxBAl4fUB577DF76qmn7OKLL7Y+ffq4jIpk8apChfojcfnEE0\/YlClTsoEg5Tv82RyKrD\/44IP23HPPlTmenj172m9\/+1s3r+TCjcOHD7dOnTo5Dqpz4PlNsrHyrqPzbMi\/yrvtIQpg7JlEquyZ0l7Gfoli52ETAhCAQDwJIPjjuS6MCgIFT0BRZQn9448\/3lWL37FjR6kz+BVBatu2rRP2isBKdCk13y9sPWGoQm633367K+KnvhLGKmTnNUX0zz33XPfRYdOmTS4NXune2ay+Lx46RuBF1r2r8spj4C8iV156uT\/Sp2wA3R3v2T\/ssMNcWrtXlV5HAbz75yWktEYffPCBvfLKKxUtR6Q\/V0q9RHzymfryXqrUf62rMjxUy0DZDUuWLHEZHJ4\/lHfDgCf4xUw+8\/nnnyf4jGdD\/qW+QT\/UVBYUeyaRHHumbE9iv1R2l\/EcBCAAgdwjgODPvTVjxBAoCAJe8TOJfYlVXXOmqHM6Fc0VedbznjBXir+El4RqsrD1Ku7rw0JyNDwOwL1oeqpIe0WitkuXLqYof6r0cn+FconeW265JeFjh1\/w6z0SrTrn7j8eUdV8\/AUU0xHX\/hsHkmsdKAPC+4Dg\/8jhzVXP6iOSPg6UlfqvDIvzzz\/ffvjhh1JHSqJgxp5JpMqeSe1l7Jcodh82IQABCMSXAII\/vmvDyCBQ0AT8xc+UFu2vhJ4KjPq0ZMESAAAgAElEQVR7Au3JJ58s1cV\/PleiUFXqlcruNS9aq39OTvGOw0IEvTrMG6uEqKLvRx11lBP73rySxWvHjh3t5ptvdh9GdK4\/mZ0nmhS9VoaDouGqXn\/fffel9fElSoaqM6BrBcWovEJ7qcaga\/t0O4NSnHUNnwoWrly50v2zV\/DRf8RBNvxFG5VRoKMMOv6Q3E4++WQbMWKEKxSooxOyF2VjzyTSZc+k9jb2S5S7ENsQgAAE4kcAwR+\/NWFEEIDA\/xHwFz8rrzCc\/8zyqlWrEu4\/92BK4Hfu3NlF9v33o3s\/l4CVSNbHBV3lpsru+rtUd8xX1QL5rw7z3\/\/uH4\/S+JX6r\/oE3lEIzVkCVtkByc95dQ5kI1nw6\/iDWEnkq4K5rjX8\/vvvS11RWFU8vPcqg0FXC6qp4v4zzzyT1pB0U4OOf+i4hr+4o+zqQ5C4KfPju+++c\/6j4w26blB\/p2v9dINDcuaJigPqWRVAVPZAts7xs2cSl549U3orsF\/S+vVAZwhAAAI5TwDBn\/NLyAQgkN8EvOJnmmXy1XDeGV1Fsf3n\/CXg5s2blwDGu4Zu4cKFrtCcv3miQCntOjZw2mmnuXPqusM+bs07epCcgp6qKrsKC+raORXUUwRcV44pIq2q9LpSTk1XEqqgYYMGDVz9Ap3f\/+STT0zp4eKi6HRcbyLw1sb7aKEPE8oEeeCBB9JatksuucTdVJD8fHLKv4o\/7rbbbs722rVrXVFAsU11zMT7iOB9FFAWQTrHUdKaQFJn9kwiEPZMIg\/2Sya7i2chAAEI5B4BBH\/urRkjhkBBEfAXUPOuhlPxPV2XpjP5ir6qKfIqkf6Xv\/wlpbBStF4Ra51BVxE6ryjdeeedZ1deeaXtuuuuLuW6vMrucQCf6uqw5s2bu48YuirQu8lg7ty5NnHiRCfi1fwcJVYVlRZHNfHQxwA9628SuCrGp+v3siVWK8NYUXR90FBmhuov6LaBdJr\/eR1X0HV7XvNS\/pUeLtv33nuv+5HS\/strut1AvvXSSy+5jxDZ5MeeSVwZ9kwiD\/ZLOr8d6AsBCEAg9wkg+HN\/DZkBBPKegFdATRFYnb+X+FJatZrO26uAnFKmy6ua779eTs8otV1RbV1NJzH2\/PPPl4i5uAP1rturUaOGizSLh87pK3qv6Lyi96myE5Tq37VrV9NzfmGsdH9VmVdauzIlZEfn2RW9rurq+0HWYv\/993eZCbpS8JtvvnHp\/d6HjiDPlyf49bzY6INIeRH9IO\/JZh\/2TCJt9sxOHuyXbO5E3gUBCECg6gkg+Kt+DRgBBCBQAQF\/ATWva0XiNtmk0rMVBdZ5f6+InfpIMKtQXbrnvqty0fzX7XnjUIaDiscpolxWSy5EpwwAf42COnXqWMuWLd1ZfWVT5FJTVP700093NRgqKvCYPC9ligwcONBleVTmSEAcObFnEleFPZPIg\/0Sx13LmCAAAQhEQwDBHw1XrEIAAiET8BdQk0jXGenXXnst7bcoRfuss85yRwGU9i6BXF5mQNovyNID\/ivHlK2g6vIS\/RU17\/yuIvnz58833UUf9f3wFY0pjJ\/7i9WVVdCwrPd41+fJD+644w6bPXt2GEOqchvsmcQlYM\/s5MF+qfLtyQAgAAEIZI0Agj9rqHkRBCCQCQF\/AbXKRHEzeXccn\/VfwaYjCqnuik817uTnyrpSLo5zLm9Mfv9Ip1Ce\/7z7xx9\/7GpDZPO8fZSc2TOJdNkzO3mwX6LcediGAAQgEC8CCP54rQejgQAEyiHgvzNdZ7R1tnrRokUFy8wfpdMNAzfeeKMtWbKkQh7ieNNNN7kr5SqqfVChsRh18Bdn00ehim4XUJq3jnkcfvjhVlRU5IoTzpo1K0Yzynwo7JlEhuyZnTzYL5nvLyxAAAIQyAUCCP5cWCXGCAEIlBCQyNd1cWqvvvqqjRgxoqDpeBX2BSH52sJCBKPrBHXrgo5sSPTr2MbkyZNdkUZ\/07GOPn36uOKPQT4O5DJL9kzi6rFndvJgv+TyzmbsEIAABIIRQPAH40QvCECgAgIqEnbwwQe7CvA6E75gwYJImB144IGuCr2uoPOu6XvzzTcjeVcmRrPFo7zr9jIZfxTPZouJzq737dvXXdOnJkGv+gbyS1092LhxY9NY9P91HGL69On2wAMPRDHlcm1miwd7JnEZcmXPZMs\/cmW\/ZH2D8kIIQAACeUIAwZ8nC8k0IFBVBM444wy78MIL7aCDDjJdm+e14uJiF4GPImXcf+XYhx9+aAMGDIjNueuq4KH5d+vWzfF\/5513XMX5OJ1DrwomRx55pF1\/\/fXWqlWrhFsZPP\/ULQ86DvLYY4+5ow3ZbFXBgz2TuMJx3jNV4R9x3i\/Z3Ju8CwIQgEA+EkDw5+OqMicIZIGAomT9+vWzo446KqWg8oags+V33XWXzZs3L7RR6d55VenX2esff\/zRfVRQlLYqW1XyqOi6variUpVMvDlrDL\/+9a\/tZz\/7mfNTCX1ln\/zlL3\/Jev2HquTBnkncBXHcM1XpH3HcL1X1e4v3QgACEMg3Agj+fFtR5gOBiAmo0Nl1111nbdq0MV3tprZ69Wr729\/+5kSUzk6rMJbuRG\/YsKH7ua7Ru\/vuu23OnDmhjU7n+HUVne6OT\/cattAGYWZx4eG\/bk+CVtFtHXmoihYXJlUx91TvjAsP9kzi6sRlz8TFP+KyXxgHBCAAAQiESwDBHy5PrEEgbwnoGqdLL73Uunbt6s4\/q0lQPv\/88zZ16tRSd9nrP2KHDRtmxxxzjDsrHbYo13hGjx7tUrZ1tdxLL72UVfZx5KEq8zpaURU8BD9uTLLqECleFjce7JnERRKPqtwzcfOPqt4vvB8CEIAABKIhgOCPhitWIZBXBFq3bu2ucZOIl3hXGv2\/\/vUvu\/fee03X45XV9GFg\/PjxLvVed6PnS1V9eJRecZgkMoEHPMr7lwD+kVf\/imQyEIAABGJNAMEf6+VhcBCIBwEJfZ2Zb9Gihatq\/vjjj7s\/QZr\/ruc4V9UPMhevDzxK04JJIhN4wKO83yn4Rzq\/cekLAQhAAAKZEEDwZ0KPZyFQQAR0X7OuOtO5\/fnz59sNN9zgrjkL0nTmX0cBdGXf66+\/boMHDw7yWKz7wKP08sAkkQk84FHeLzH8I9a\/4hkcBCAAgbwhgODPm6VkIhCIloDOm06aNMmOPfbYtKP8\/nvAV61aZYMGDcp6hfSw6cCjNFGYJDKBBzzK+72Df4T9Wxl7EIAABCCQigCCH7+AAAQcgVNOOcVUtfrggw92\/7x48WJ31d2bb75ZQkjV92+88UarV6+eLV++3An3JUuWBCKoAn6dO3cO7Rq9s846y3S3+D\/\/+U8bM2ZMoDGk0wkepWnBJJGJrlE79dRTXdaL6lr84x\/\/sI8\/\/jihUyHtGXjgH+n8jqUvBCAAAQhkhwCCPzuceQsEYktAAl\/C\/aijjnL3lPvbli1b7JVXXnFX6m3dutX9aPjw4dapUyf3\/2fMmBFYbHfp0sWuueYaJ46mTZvmsgUq09q1a+eEvqrRa0xvvPGG3XHHHaVuCaiMbT0Dj9LkYJLI5Mgjj3TXHuqGCP+ekehP5Y\/5vmfggX9U9vctz0EAAhCAQPQEEPzRM+YNEIgtgZNPPtlV32\/UqJEVFxe7yvvvvPOOS9uXsFYkP7lIn6J4t99+u3tm7dq17mq8t956q8I5qir1qFGjnM3KnOP331W9yy672NKlS+2BBx5wAiusBo\/SJGGSyKRDhw5uzzRo0MDtGWXC6H91E4VupUh1G0U+7xl44B9h\/f7FDgQgAAEIREMAwR8NV6xCIPYEJE4UZVf0dtmyZfa73\/3OPv3005Jx+\/9D\/quvvnIRzZUrV7qfDxgwwLp162YS3vpAMHDgwJIMgLIm7hf8L774YuDMgDp16ljPnj3tvPPOc4Lq22+\/dTcE\/OUvf6nwneksAjxK04JJIhM\/jy+++MJ0TEV7Q00fpO6880479NBD3Yewm2++2T766KMSA\/m+Z+Bh7veT9zsVHun89qUvBCAAAQhESQDBHyVdbEMgxgQuvvhi69OnjxPNStmfNWtWqdEOGTLEzjnnHBfBVFqyF8n3\/4etMgD0H7nPPfdcubO95JJLrHfv3q7Po48+ak8++WSFdHROX2NUNoHeM3PmTLv\/\/vtDS9\/3DwAepZcDJolMVOOif\/\/+pqMuqfaM93M9JT9VDQyv5eOegQf+UeEvcTpAAAIQgECVE0DwV\/kSMAAIVA0Br4heecX3yhMw3s90Jl9pzYpgrlu3LuVkDjnkEHfOvlmzZhakSr\/\/zPi2bdvcNYDjxo1z74mqwaM0WZgkMpGPX3TRRWUWrPSyWHT95Pjx490HKn\/Ltz0DD\/wjqt\/H2IUABCAAgfAIIPjDY4klCOQUAU\/MrVixwhXt+\/LLL0uN3xMoEt3JAkZXSunvTjrpJBfxnDp1qj388MOlbLRo0cJGjhxpLVu2dP1eeOEFmzBhQkpWSou+9tprrW3btu64QBTn9MtaJHiULfjxkZ\/YeAI3Vcq+fq4MFmWy6NiJClSKm7\/l256BR2rBj3\/k1L8KGSwEIACBvCeA4M\/7JWaCEEhNQKnyl156qUvpnzJlij311FOlOlb0H\/S6pm3o0KElZ+tvu+22kmvJJG5kv2vXru7n27dvdwX2br311pRn71XpW1kA++yzj8sUePbZZ+2JJ54I9Zx+eb4Aj9J0YJLIRGL+8ssvt\/Xr19s999xjc+bMKekg\/9WHLX20Kioqcn+vqv261lI1Jzzxn097Bh74B\/9+hQAEIACB+BNA8Md\/jRghBCIhoMrhiqbr7nCJ640bN5Z6z3333WcnnniiLVmyxK666iondJKbzvmfffbZ7q9fffVVGzFihKvw369fPzvggAOsWrVqTvioyN69995broBXlF1Vzh955JFS0dFIIPiMwqM0YZgkMtGHK\/m0vxifevTo0cNF9vXzVE3ZM9oXixYtcj\/Olz0DD\/wj6t\/L2IcABCAAgcwJIPgzZ4gFCOQlgQMPPNCdm2\/atKm9\/PLLLnqZqvn7KbKpSKbS+JWSL\/GezbT8KBcCHqXpwuQnJvrgpY9nqsyuj1XvvvuudezY0RWc9D56+a+izPc9A4\/EvQKPKH8zYxsCEIAABCoigOCviBA\/h0CBEijv\/H4ykiuuuMJdnSeR77Wors+rquWAR2nyMPmJSf369e2oo46yf\/3rXwkZLIqAK\/W\/VatW7qYLHVmZPXu2eyaf9ww8EvcKPKrqtzbvhQAEIAABEUDw4wcQgEBKAiqsp+J5X3\/9tYterly5skxS+g9a9T\/88MMjvz6vqpYLHqXJw6Rib\/SuNlRNC9WkUL0M7yNBvu+ZVHTgkUgFHhXvIXpAAAIQgEBmBBD8mfHjaQjkJQFdo6d0fhXQe\/HFF23MmDGl5nnccce5s\/mffvqp+9kZZ5xhv\/zlL+2hhx6K9Pq8qgAOj9LUYRLME72r+urVq2fTpk2zSZMmlTyYz3umLDrwSCQDj2D7iF4QgAAEIFB5Agj+yrPjSQjkLQEVINMVY7pGz5+GrAnrfL4K+LVp08bmz5\/vripTpf98bvAovbowCebxJ598sivYt+uuuyZE+IM9nX+94JG4pvDIPx9nRhCAAATiRgDBH7cVYTwQiAEBrzq\/ipBJ0Ks6f506dax\/\/\/525plnWu3atd0odU5\/7Nix7uqxfG7wKL26MNnJROn6tWrVSnnTxXXXXeeuptywYYPpFgoV9Mv3Bo\/EFYZHvns884MABCAQbwII\/nivD6ODQNYJ+CuIe+n8Z511lqs43qhRIzeezZs328yZM+3+++9PKXKyPugIXwiP0nBhspPJkUceaYMHD3YfxHT0Zd68eSU\/1McxfTDbY489TFX6dR1fvjd4JK4wPPLd45kfBCAAgfgTQPDHf40YIQSySsBLMVXF\/RkzZtixxx5rBx10kFWvXt22b99un3zyiTvfv3jx4qyOq6peBo\/S5GGyk8moUaPcFXzVqlVzH8Lee+89W758ubVs2dIOO+wwF\/nX0ZeBAwfaunXrqsqNs\/ZeeCSihkfWXI8XQQACEIBAGQQQ\/LgGBCCQQMC7ak1CxWs7duywpUuXugrj3rVihYINHqVXGiY7mShdW6n6p556qhP3\/qailnPnznWR\/0IQ+5o7PBL3CzwK5d8UzBMCEIBAfAkg+OO7NowMAlVCIFnMSag8++yzruBYvhfnSwUcHhUL\/kL3ERE6+uij7dxzz7UDDjjAAdMHshdeeME+\/vjjKtnHVf1SeCSuADyq2iN5PwQgAIHCJYDgL9y1Z+YQSEngmGOOsTvvvNPq1q3ropMTJ060FStWFCwteJReepgU7HZg4hCAAAQgAAEI5BgBBH+OLRjDhUDUBJSC2rNnT1d5v1DO6ZfHFB6l6cAk6l2IfQhAAAIQgAAEIBAOAQR\/OByxAgEIQAACEIAABCAAAQhAAAIQiBUBBH+sloPBQAACEIAABCAAAQhAAAIQgAAEwiGA4A+HI1YgAAEIQAACEIAABCAAAQhAAAKxIoDgj9VyMBgIQAACEIAABCAAAQhAAAIQgEA4BBD84XDECgQgAAEIQAACEIAABCAAAQhAIFYEEPyxWg4GAwEIQAACEIAABCAAAQhAAAIQCIcAgj8cjliBAAQgAAEIQAACEIAABCAAAQjEigCCP1bLwWAgAAEIQAACEIAABCAAAQhAAALhEEDwh8MRKxCAAAQgAAEIQAACEIAABCAAgVgRQPDHajkYDAQgAAEIQAACEIAABCAAAQhAIBwCCP5wOGIFAhCAAAQgAAEIQAACeUegZs2a1rNnTzvvvPOsYcOGVq1aNSsqKrK3337bHnjgAVuxYkXezZkJQSCfCCD482k1mQsEIAABCEAAAhCAAARCIiCxP2zYMOvQoYOzuGzZMtu8ebPtt99+VrduXfvmm29s6NChtmjRopDeiBkIQCBsAgj+sIliDwIQgAAEIAABCEAAAnlA4Oyzz7Zrr73WatSoYQ899JA9\/fTTblYtWrSwkSNHWsuWLe3111+3wYMH58FsmQIE8pMAgj8\/15VZQQACEIAABCAAAQhAICMCEyZMsLZt29q8efPsmmuuSbB1ySWXWO\/eve27776zQYMG2ZdffpnRu3gYAhCIhgCCPxquWIUABCAAAQhAAAIQgEDOEth7771t9OjR9rOf\/cymT59uU6ZMSZhL9+7drX\/\/\/rZp0ya79dZb7d13383ZuTJwCOQzAQR\/Pq8uc4MABCAAAQhAAAIQgEAEBJTSf\/rpp9sXX3xhAwYMsPXr10fwFkxCAAKZEkDwZ0qQ5yEAAQhAAAIQgAAEIFAgBA455BCXyt+mTRvbsWNHwtn+AkHANCGQUwQQ\/Dm1XAy2EAg0adIkK9PUv6R1tU5VNd4P\/6ryP\/meGu+vmv0P\/6r3v5UrV1bVr\/68fW+Qf3d7vl9Vv3+891d2\/Q866CAbN26ceXMtLi62J5980v2hQQAC8SWA4I\/v2jCyAiVw5plnurNwNAhAAAIQgEAUBD744APr169fFKYL1uZxxx1n999\/f07Mf8WKFXb++eenPVbNUYX7tm3bZo0aNTKd8d+yZYu98sorNnbsWNu6dWvaNnkAAhCIngCCP3rGvAECaRGQ4O97xU32h3uXpvVc2J0PPbKenX1RExt7yxdhm07b3vg\/TEz7mbAf2Lq1ia1eNdQa7jPaatZcEbb5nLS3csXv4eFbOflHvXp\/tV13+yAn1zPsQYtHzZorbc8Gj4ZtOiftrVvb2427qnkUff9re+ONJgj+kL3IE\/w\/\/TsivhkURUWd7YtFP6+U4Pcjq1mzpl133XWma\/u2b9\/uCvo99dRTIVPFHAQgEAYBBH8YFLEBgRAJeIJ\/SO\/PQrSavqlDj6pnN97R0n77m6oXL699enX6Ewj5CQn+b\/79rO23f1cE\/\/+x\/WrJW9a4ydW2665V7yMhL3elzMk\/9mzwmBP9NDN9ENLHMQkgmrkPhvo9oj1TlW3d2svt738\/DsEf8iJ4gn+\/\/brFWvCvW3eZff5554wFv\/BJ9Cur4eijj7aPPvrI+vbtGzJVzEEAAmEQQPCHQREbEAiRAIK\/NEwEf4gOFqIpBH8iTAR\/Ig8EfyIPBH+Iv3xiaKoQBb+WYciQIXbOOefYwoULrVevXjFcGYYEAQgg+PEBCMSMAIIfwR8zlyxzOAh+BH95vorgR\/Dnyu+yMMbpCf5mzS6IeYS\/ly1YcEagCL\/mNHz4cKtbt67dc889NnPmzFKohg0bZp07d0bwh+FE2IBARAQQ\/BGBxSwEKksgLoJf41da\/8JPiio7ldCei0OEX5P54Yefk77uW1Xx0FlVahr8BAUeiVte6etq+MdPXMRj69bGVf47hJT+0P7VlGCoRPA37RFvwb\/+UluwoFMgwd+4cWObOHGiNW\/e3P72t7+ZxL2\/7bnnnjZp0iQ7+OCDU\/48GtJYhQAE0iWA4E+XGP0hEDGBOAn+iKca2HxcBH\/gAdMRAhCAQEwJIPijWZh8FPwipcJ8Xbt2taKiIifuvSh\/nTp1XPS\/Xbt2tm7dOhs9erS99dZb0cDFKgQgkBEBBH9G+HgYAuETQPCXZorgD9\/PsAgBCBQmAQR\/NOvuCf6mjS+KdYR\/\/YZLbcHCXwWK8IuUoviK7Ldp08Zdu7ds2TLbtGmTNWnSxP1s48aN9tBDD9n06dOjAYtVCEAgYwII\/owRYgAC4RJA8CP4w\/UorEEAAhDYSQDBH4035KvgFy1V4+\/Zs6edd9551rBhQ6tevboVFxfb559\/7lL+Fy9eHA1UrEIAAqEQQPCHghEjEAiPAIIfwR+eN2EJAhCAQCIBBH80HrFT8F9sNWusjOYlIVhdv+ESW7AoeIQ\/hFdiAgIQqGICCP4qXgBeD4FkAgh+BD+7AgIQgEBUBBD80ZD1BH+TRj2tZo3\/RPOSEKyu\/\/7\/2cIvTg+c0h\/CKzEBAQhUMQEEfxUvAK+HAIK\/Yh\/gDH\/FjOgBAQhAIAgBBH8QSun3QfCnz4wnIACB7BBA8GeHM2+BQGACRPhLo0LwB3YfOkIAAhAolwCCPxoHKRH8+\/y\/eEf4ixThP40IfzRugFUIxJIAgj+Wy8KgCpkAgh\/BX8j+z9whAIFoCSD4o+FbIvj3viTegr+4py1cjOCPxguwCoF4EkDwx3NdGFUBE0DwI\/gL2P2ZOgQgEDEBBH80gBH80XDFKgQgkDkBBH\/mDLEAgVAJIPgR\/KE6FMYgAAEI+Agg+KNxB0\/wN97r0lhH+Dcowv+\/vySlPxo3wCoEYkkAwR\/LZWFQhUwAwY\/gL2T\/Z+4QgEC0BBD80fBF8EfDFasQgEDmBBD8mTPEAgRCJYDgR\/CH6lAYgwAEIECEP3IfKBH8DXpZzerxvZZvw8aLbeGXRPgjdwheAIEYEUDwx2gxGAoERADBj+BnJ0AAAhCIigAR\/mjIlgj+PS+Lt+DfJMHfkZT+aNwAqxCIJQEEfyyXhUEVMgEEP4K\/kP2fuUMAAtESQPBHwxfBHw1XrEIAApkTQPBnzhALEAiVAIIfwR+qQ2EMAhCAgI8Agj8adygR\/HtcHu8I\/w8X2cIlRPij8QKsQiCeBBD88VwXRlXABBD8CP4Cdn+mDgEIREwAwR8N4BLBv7sE\/7fRvCQEqxsk+L\/6L1L6Q2CJCQjkCgEEf66sFOMsGAIIfgR\/wTg7E4UABLJOAMEfDXIEfzRcsQoBCGROAMGfOcNYWWjSpIldddVVdsIJJ1j9+vWtevXq9uOPP9qKFSts6tSp9tJLL5Ua7+OPP26HHnpomfPYvn27bdy40ZYuXWrPPvusvfLKK6HPecCAAXbRRRcFtqs53X\/\/\/TZ9+vTAz+RKRwQ\/gj9XfJVxQgACuUcAwR\/NmpUI\/rq94x3h39zDFi4lwh+NF2AVAvEkgOCP57pUalQdOnSwm266yRo0aJDyeQn3N954w2699VbbunVrSZ+KBL\/fmGy8\/\/77dtttt9m6desqNc5UDyH4d1JB8CP4Q9tYGIIABCCQRADBH41LIPij4YpVCEAgcwII\/swZxsLCgQceaGPHjrVmzZrZ5s2bXRReQn716tXWsWNHu+yyy6xFixa2ZcsW++\/\/\/m+bNGlSKcH\/7bffuqj5+vXrE+a077772kknnWStW7e2evXquZ\/Nnz\/fBg4cGJro9wS\/IvfPPPOM+6hQXtu2bZstXrw4tPfHYhH\/bxAIfgR\/nPyRsUAAAvlFAMEfzXqWCP46MY\/w\/0iEPxoPwCoE4ksAwR\/ftUlrZH379rWePXu6yL2Evv742yGHHGJ33HGH+yDw9ddf27XXXmsrV650XbwI\/\/Lly23QoEG2ZMmSlO\/WB4ORI0day5YtTYJb6f333ntvWuMsq7Nf8Odrqn5QUAh+BH9QX6EfBCAAgXQJIPjTJRasf4ng3+23VrNajIv2belhC7\/uQNG+YMtKLwjkBQEEf14so9mDDz5oxxxzTCkx75\/ekCFD7JxzzrGioiKX1v\/222+nJfjVWf9CGzVqlDs2sGrVKveBYNGiRRlTRPDvRIjgR\/BnvKEwAAEIQKAMAgj+aFwDwR8NV6xCAAKZE0DwZ86wyi3svffeLp1fEXiJb0X7UzVPVGci+GXX+3CgowNTpkyxp556KmMGYQj+mjVrWrdu3dxHDRUvrFWrlhuXjgmo4KAK\/KUqWqg+6t+rVy9r165dSbHD4uJi+\/zzz23ixInu+EByS\/WMmOi4wxNPPFHyQSVdOAh+BH+6PkN\/CEAAAkEJIPiDkkqvX4ngr90n3hH+rRfawn8T4U9vdekNgdwmgODP7fVLa\/R33XWXtW\/f3tauXWs333yzffTRR+75oCn93sskSHV+f7fddrOXX37Zpfln2jIV\/HvuuaeNGzfODj\/8cKtWrVrK4ah+wQsvvGATJkxI+HlFxQ7F6+6777Y5c+aUPHfyySe7AomNGjVK+S4Jf30I0QeRdBuCH8Gfrs\/QHwIQgEBQAgj+oKTS6z1BOYoAACAASURBVOcJ\/ia14i3410vwf4PgT2916Q2B3CaA4M\/t9Qs8+lNOOcWGDh1qEsYff\/yx9e\/fv6RSf7qC\/7DDDrMxY8Y4satodu\/evQOPo6yOmQr+4cOHW6dOndyc5s6da48++qjLdtB8e\/To4c6qqeBg8jEEf20Df7HDDRs2uJoIyhjQc1999ZXdcMMN7npDf4FEZQ\/8z\/\/8jz355JP2zTffJBRI1FWGyg6YMWNGWnwQ\/Aj+tByGzhCAAATSIIDgTwNWGl0R\/GnAoisEIJBVAgj+rOKumpdJ9I4fP95Fv5XOr\/T\/WbNmlQwmXcEvwatoetOmTW3hwoUuFT7Tls61fMnFBSXaNZ599tnH3nnnHZd94L92UGPzihpu2rTJ7rzzTps9e7YbsmoQ6GOAov+qg\/D0008nTEVz0x8dF1CaviL23jN6R6qMAf9HhOSPK0E4IfgR\/EH8hD4QgAAEKkMAwV8ZahU\/UyL4a14R65T+9dsutIXLTqVoX8VLSg8I5A0BBH\/eLGXqifhT3csSqLku+H\/1q1\/Z1Vdf7SLxmoui7cmte\/fuLqtBzbsFQCJeAr5Vq1buZoKrrrqq1JWEOqevmwj22msv95HggQcesMmTJ7sof1nP6B36gKHMAn1gUfaBsg6CNgQ\/gj+or9APAhCAQLoEEPzpEgvWH8EfjBO9IACB7BNA8GefedbeKLF6++23u8i+xL7OoOu8fXL0O06CXynyzzzzjL3\/\/vtlcvrhhx\/ss88+KzUP\/wMS5AcccIAdf\/zxdtRRR7mChrVr13YF\/DzBf9BBB7nMAHESG9U1qKjpJgRlCOiWgtdff90GDx6c8hGvzkGNGjXc8YJUHyHKeheCH8FfkR\/ycwhAAAKVJYDgryy58p\/zBH\/TGlfGO8K\/\/QJbQIQ\/GifAKgRiSgDBH9OFyXRYRx55pN1yyy0uEq109VdeecUVnksW+3pPuoL\/hBNOcFfz1a9f3xX+K+tWgHTmkOkZfkXrdeZeYlm1BbwK\/clj8Av+1q1bu3koM2DatGk2adKkCofsf6bCzv\/XIahtz57moGsTk9tvf\/NB0FfmXb\/XPr067+bEhCAAAQhkg8DqVUOtqOjXCa\/64IMPrF+\/ftl4fcG8o0TwV7\/Satq3sZ33+h0X2ILlpPTHdoEYGAQiIIDgjwBqVZtUivt1113notASuH\/6059cKnpZLV3B76XHS1THoUq\/xP7o0aPdlXqq0L9jxw5TwTwV6Fu5cqWrM7B9+3a7+OKLHQIvwh9nwd\/3ipvsD\/cuTViyhZ8UVbVrVdn7EfxVhp4XQwACOU5g69YmtnVr45JZFH3\/a3vjjSYI\/pDXFcEfMlDMQQACoRFA8IeGMh6GunTp4iLuilpL9D722GPuerjyWrqCX8cCTj\/99IT0+Exnn0mEX0K+T58+Lqo\/b948u+eee1xVfX9LdYbff9tA0JR+f3aDPqTofH\/YjZT+0kQR\/GF7GfYgAIFCJUBKfzQr7wn+ZtY31hH+dXaBLVjRnqJ90bgBViEQSwII\/lguS+UG5Rf7ujteYtRfjb8sq+kIfv0LTWnwyh7QNXTXXHONu6ou05aJ4L\/rrrusffv2pjnrHL6OGSS3IUOG2DnnnJPwkUJHErwCfF988YUrtLd+\/fpSz6p6vyrvq4+uI9Sf5s2bl7reMFMG3vMIfgR\/WL6EHQhAAALJBBD80fiEJ\/j323FVzAV\/d\/t8JYI\/Gi\/AKgTiSQDBH891SXtURx99tCvQp\/PrEr46r6+odZAWVPCr8J2i+y1btnR1AaZOnWoPP\/xwkFdU2CcswT9s2DB79913E96negYat4rz+c\/wq1NF1\/J16NDB9LFAHwe84wt6xxlnnOFsPfTQQ6Wu8vPsnnXWWS7LQkX7nnvuuQoZIPjLRkSEP7D70BECEIBAuQQQ\/NE4CII\/Gq5YhQAEMieA4M+cYSwsTJgwwdq2bWubN2924lL30ZfVtm3bZosXL7Z169a5Lp7g\/\/bbb9359uQot6rZK5VdFerr1q3rzsi\/\/fbbduONN5ZbKT8dMJkIfh1hUME+VcRXFP6+++5zor9x48Z24YUXWqdOnUzXE6olC35F7u+44w5r1qyZE+d\/\/etfnUBXv86dO1uvXr2sYcOG7iOK6gS89dZbLtrvPSPeKogohqoXoJ\/17t3b2rRp444YiLPm5rEOwoQIf2lKCP4gnkMfCEAAAhUTQPBXzKgyPUoE\/zZF+FdVxkRWnllXrbt9\/p92pPRnhTYvgUA8CCD447EOGY1CQn\/EiBG2++67B7KTLHo9wR\/kYRW\/+9e\/\/uWyCdIRsRXZzkTwK3KvNHuJ7VRN81Wa\/8EHH+yEvzIT\/EUMFcW\/6aab3DGFVE0fAhTJnz59esmPK3pGHZctW2Y6bqC6Auk0BD+CPx1\/oS8EIACBdAgg+NOhFbwvgj84K3pCAALZJYDgzy7vSN7mr5of5AXpCn6l7xcXF7vouUTvm2++GeQ1afXJRPDrRRL9umJIlfdVsFDV+jXmRYsW2RNPPGELFixw1+7pOMLHH39s\/fv3T8hOKOv5zz\/\/3CZOnOgi9clNzygDQLcDKOW\/evXq7qiDPoT84x\/\/cJkClfkoguBH8Ke1eegMAQhAIA0CCP40YKXR1RP8+2\/tF+sI\/9rq3Yjwp7GudIVAPhBA8OfDKjKHvCKA4Efw55VDMxkIQCBWBBD80SyHJ\/ibb+lnNXfEN6V\/bY1uNv9bUvqj8QKsQiCeBBD88VwXRlXABBD8CP4Cdn+mDgEIREwAwR8NYAR\/NFyxCgEIZE4AwZ85QyxAIFQCCH4Ef6gOhTEIQAACPgII\/mjcoUTw\/9g\/\/hH+VadQtC8aN8AqBGJJAMEfy2VhUIVMAMGP4C9k\/2fuEIBAtAQQ\/NHw9QT\/AT9cHWvBv6ZmV5u\/GsEfjRdgFQLxJIDgj+e65NSoVChv1KhRrlheui25gGC6z+djfwQ\/gj8f\/Zo5QQAC8SCA4I9mHRD80XDFKgQgkDkBBH\/mDAveQqtWrVzV+zp16qTNQlXtn3nmGZszZ07az+brAwh+BH+++jbzggAEqp4Agj+aNSgR\/BsH2C4xLtq3Zpeu9tl3J5PSH40bYBUCsSSA4I\/lsjCoQiaA4EfwF7L\/M3cIQCBaAgj+aPgi+KPhilUIQCBzAgj+zBliAQKhEkDwI\/hDdSiMQQACEPARQPBH4w4lgr845hH+WkT4o\/EArEIgvgQQ\/PFdG0ZWoAQQ\/Aj+AnV9pg0BCGSBAII\/Gsglgr\/oGttl+6poXhKC1TW1u9hna0jpDwElJiCQMwQQ\/DmzVAy0UAgg+BH8heLrzBMCEMg+AQR\/NMwR\/NFwxSoEIJA5AQR\/5gyxAIFQCSD4EfyhOhTGIAABCPgIIPijcQdP8Lf4\/tpYR\/i\/U4R\/7S8o2heNG2AVArEkgOCP5bIwqEImgOBH8Bey\/zN3CEAgWgII\/mj4lgj+9dfFW\/Dver59tg7BH40XYBUC8SSA4I\/nujCqAiaA4EfwF7D7M3UIQCBiAgj+aAAj+KPhilUIQCBzAgj+zBliAQKhEkDwI\/hDdSiMQQACEPARQPBH4w4lgn+dIvyro3lJCFa\/200R\/rak9IfAEhMQyBUCCP5cWSnGWTAEEPwI\/oJxdiYKAQhknQCCPxrkCP5ouGIVAhDInACCP3OGWIBAqAQQ\/Aj+UB0KYxCAAAR8BBD80bhDieBfc0O8I\/x1zrPP1rchwh+NG2AVArEkgOCP5bIwqEImgOBH8Bey\/zN3CEAgWgII\/mj47hT8A22XbTFO6a9zrn22AcEfjRdgFQLxJIDgj+e6MKoCJoDgR\/AXsPszdQhAIGICCP5oACP4o+GKVQhAIHMCCP7MGWIBAqESQPAj+EN1KIxBAAIQ8BFA8EfjDiWCf\/WgeEf4655rn33fmpT+aNwAqxCIJQEEfyyXhUEVMgEEP4K\/kP2fuUMAAtESQPBHw7dE8K+6Md6Cv945CP5oXACrEIgtAQR\/bJeGgRUqAQQ\/gr9QfZ95QwAC0RNA8EfDGMEfDVesQgACmRNA8GfOEAsQCJUAgh\/BH6pDYQwCEICAjwCCPxp3KBH8394U\/wh\/0Umk9EfjBliFQCwJIPhjuSwMqpAJIPgR\/IXs\/8wdAhCIlgCCPxq+CP5ouGIVAhDInACCP3OGWIBAqAQQ\/Aj+UB0KYxCAAASI8EfuAyWCf+XgeEf4dz\/bPismwh+5Q\/ACCMSIAII\/RovBUCAgAgh+BD87AQIQgEBUBIjwR0O2RPCvkOD\/LpqXhGD1uz0k+E8kpT8ElpiAQK4QQPDnykoxzoIhgOBH8BeMszNRCEAg6wQQ\/NEgR\/BHwxWrEIBA5gQQ\/JkzxAIEQiWA4Efwh+pQGIMABCDgI4Dgj8YdPMF\/wIohVnNrfCP8a\/b4jc3fSIQ\/Gi\/AKgTiSQDBH891YVQFTECC\/3e\/62377d+1gCkkTv20I38PiyQCr316NUwgAAEIpE0AwZ82skAPeIK\/+fJ4C\/619RH8gRaUThDIIwII\/jxaTKaSHwQQ\/KXXEcFfmgmCPz\/2O7OAQLYJIPijIY7gj4YrViEAgcwJIPgzZ4gFCIRKAMGP4A\/iUAj+IJToAwEIJBNA8EfjE57g329ZvCP86+r\/xj7fREp\/NF6AVQjEkwCCP57rwqgKmACCH8EfxP0R\/EEo0QcCEEDwZ8cHPMHfdNngWJ\/hX1\/\/bFuA4M+OU\/AWCMSEAII\/JgvBMCDgEUDwI\/iD7AYEfxBK9IEABBD82fEBBH92OPMWCEAgfQII\/vSZ8QQEIiWA4EfwB3EwBH8QSvSBAAQQ\/NnxAU\/wN152k9Xcujo7L63EWzbUP8cWbjrJzj\/\/\/Eo8zSMQgEAuEkDw5+KqMea8JoDgR\/AHcXAEfxBK9IEABBD82fEBBH92OPMWCEAgfQII\/vSZ8QQEIiWA4EfwB3EwBH8QSvSBAAQQ\/NnxAU\/w77tskNWIcYT\/+\/rn2qJNrYnwZ8cteAsEYkEAwR+LZWAQENhJAMGP4A+yHxD8QSjRBwIQQPBnxwc8wb\/PshtiLfiL6p9nX2xqg+DPjlvwFgjEggCCPxbLwCAggOAvzwdOO\/L3uEgSAQQ\/LgEBCFSGANfyVYZaxc8g+CtmRA8IQKBqCCD4q4Y7b4VAmQSI8JdGg+AvzQTBzy8RCECgMgQQ\/JWhVvEznuDfe9l1sY7wF9c\/3xZvakuEv+IlpQcE8oYAgj9vlpKJ5AsBBD+CP4gvI\/iDUKIPBCCQTADBH41PeIK\/wbJrrPrWVdG8JASrG+t3sS83nYzgD4ElJiCQKwQQ\/LmyUoyzYAgg+BH8QZwdwR+EEn0gAAEEf3Z8AMGfHc68BQIQSJ8Agj99ZjwBgUgJIPgR\/EEcDMEfhBJ9IAABBH92fMAT\/PWXXR3rCP+m+l1tyaZTiPBnxy14CwRiQQDBH4tlYBAQ2EkAwY\/gD7IfEPxBKNEHAhBA8GfHBxD82eHMWyAAgfQJIPjTZ8YTEIiUAIIfwR\/EwRD8QSjRBwIQQPBnxwc8wb\/78n6xjvD\/UL+bfbWxHRH+7LgFb4FALAgg+GOxDAwCAjsJIPgR\/EH2A4I\/CCX6QAACCP7s+IAn+OsuvyrWgn9z\/e62FMGfHafgLRCICQEEf0wWgmFAwCOA4EfwB9kNCP4glOgDAQgg+LPjAwj+7HDmLRCAQPoEEPzpM+MJCERKAMGP4A\/iYAj+IJToAwEIIPiz4wOe4N9tRV+rtvXb7Ly0Em\/ZsscF9vXG9qT0V4Idj0AgVwkg+HN15Rh33hJA8CP4gzg3gj8IJfpAAAII\/uz4gCf4a6+4MtaCf+seF9i\/N56K4M+OW\/AWCMSCAII\/FsvAICCwkwCCH8EfZD8g+INQog8EIIDgz44PIPizw5m3QAAC6RNA8KfPjCcgECkBBD+CP4iDIfiDUKIPBCCA4M+OD3iCv+aKK2Id4d+2x4W2jAh\/dpyCt0AgJgQQ\/DFZiMoO46yzzrLu3bvbAQccYLVq1bLt27fbhg0b7N1337UHHnjAVqxYkWC6devWNmrUKKtXr16Zr\/zxxx+tqKjIPvnkE3vkkUds8eLFlR1emc89\/vjjduihh9ry5ctt0KBBtmTJknLfcdddd1n79u3duG699VZ7++23Qx9TmAa9+b3++us2ePDgtEwj+BH8QRwGwR+EEn0gAAEEf3Z8AMGfHc68BQIQSJ8Agj99ZrF4ombNmk64t2vXzqpXr55yTGvXrrW7777b5syZU\/LzIILfb2zz5s02ffp09\/EgzIbgL5smgh\/BH2SvIfiDUKIPBCCA4M+OD3iCv\/qKPmbb4lu0b8ceF9ry4g6c4c+OW\/AWCMSCAII\/FsuQ\/iAGDBhg3bp1Mwn\/pUuX2h\/+8AebPXu2NWzY0C677DI744wzXMR\/2bJlduONN5ZE0P2C\/5133rFp06aVevkRRxxhJ510kh122GHOxpYtW+yFF16wCRMmpD\/QMp5A8CP403Gm0478fTrdC6Ivgr8glplJQiB0AuvWXm5\/\/\/tx1q9fv9BtF7JBT\/DbyngLftv9QluB4C9kV2XuBUgAwZ+Di96kSRO77777bL\/99nPp9hL\/69atS5jJDTfcYOeee66L\/j\/xxBM2ZcoU93O\/4K8o3VyRZtmuX7++sz969Gh78803QyGG4Efwp+NICP7StBD86XgQfSEAAY8Agj8aX0DwR8MVqxCAQOYEEPyZM8y6BQnxgQMHuui7X8z7B6Lo\/JgxY6xRo0bmF\/bpCH7Zu+KKK6xnz562yy672Ny5c00fEsJoCH4Efzp+hOBH8KfjL\/SFAATKJoDgj8Y7PMG\/beVvY53SX233HvYfIvzROAFWIRBTAgj+mC5MecO65JJL7KKLLnLp\/Pfcc4\/NnDmzVPcDDzzQxo0bZ02bNs1I8Cu6P3nyZJO9VatWuQJ7ixYtypha2IL\/4IMPtj59+tjRRx9te+yxh8tsUAHD9evXuwKGmoO\/gKGfj441fPjhh9arVy+THX1IUeFC9Z86daq99NJLKeer+gn+Z1TvQIUOJ06c6AoLqihhRVkUqQxzhr80FQQ\/gj\/jXzoYgAAEHAEEfzSO4An+Lf\/5re2I8Rn+Grv3sG+LOMMfjRdgFQLxJIDgj+e6ZDyqtm3b2ogRI2z33Xe3l19+2UaOHOlsphvh1zPDhg2zzp0726ZNm2z8+PEpPzCkO+AwBb9uKbjyyiutTp06ZQ5DtQxuueWWko8VfsE\/b948U92CVM9L+D\/66KP25JNPJtju0aOHe2ft2rVLvVPv2rp1q7s5AcGfrmek7o\/gR\/CH40lYgQAEEPzR+ACCPxquWIUABDIngODPnGEsLXjX2CnqrGJ7M2bMqLTgV0ZB7969XVq\/It5hVOwPS\/DrX7C6raBBgwa2evVqk1194Ni4caOdcMIJTpRLzKv9+c9\/dlkPan7Br3\/WdX\/6+dNPP+2i+4rc60OCBP0333xj11xzTUmGwMknn2xDhw5179RNCHqnsgB0fOKqq66yNm3auCwBNQR\/ONsDwY\/gD8eTsAIBCCD4o\/EBT\/D\/EPMIf83de9hqIvzROAFWIRBTAgj+mC5MJsPyR59ViV\/n\/RVxVqtMhF\/Ct3\/\/\/k7EKv190qRJmQzPPesJ\/nQNSZgrXf7tt992j+qIwfnnn2\/FxcU2duxYmzVrVoJJf4FDRfIl3JMFvz4OKA3f+yjiGVBGwG9+8xv3MeDOO+90tyCoKVvi9NNPd8cFVCfBf+2hfj5kyBA7++yzrVq1agj+dBe4jP4IfgR\/SK6EGQgUPAEEfzQugOCPhitWIQCBzAkg+DNnGCsL\/vT25DT2fBT8OmJwzDHHuOj71Vdf7UR4cvM+LixcuNBF7pMF\/5IlS1xkPvlZ70OH+t9\/\/\/02ffp023\/\/\/V3dhGbNmpn\/A4L\/nWUVTAzqKJzhL00KwY\/gD7p\/6AcBCJRPAMEfjYd4gn\/jt\/E+w79LvR72HRH+aJwAqxCIKQEEf0wXpjLDuvjii+3yyy93Z9G\/\/fZbu\/vuu+2tt95KMBW3CL\/GKTGdSqj7B64ihSeddJKLtvsj\/MmcNPdWrVq5gnnHHnus+\/8NGzZ0RfzKEvxipEyB5JZK8Pv5lZftoHP\/hx9+OBH+yjhyimcQ\/Aj+kFwJMxAoeAII\/mhcwBP8Rav62PYYF+2rXe9CW\/M9Rfui8QKsQiCeBBD88VyXtEalav2KUHft2tWl3SvarRR0RaCTW2UEf79+\/dzVfKp6X9Y1gGkN2JfSv3z5cie2FWUvr3k1CVIJflXW15EDndWvV6+eS6VP1coS\/GWds08l+Lt06VJyLCBVMT\/vvd54K3uGXx81dt31g4RpNG5ydbqY86Y\/gh\/BnzfOzEQgkGUCEvg\/\/HBcyVu3bm1s8+atNP27nRYeAQR\/eCyxBAEIhEsAwR8uz6xbU0R7+PDhdsopp7go9pdffumq85d1dV5lBL8nXuNYpb9Dhw520003uQJ6aiq4p48CK1eutKVLl9p7771nF1xwgbVs2bLMCH8cBf\/vftfb6tX7a4I\/7dngsaz7V1xeiOBH8MfFFxkHBHKNQFHRr23rlsYlw5b4nzvXEPwhL6Qn+NevuiLWEf5d611o674\/1dU\/okEAAoVBAMGfw+u85557ugr1+peM2vz58+22225LuG8+eXrpCn5\/0bug0fggSMOo0l+\/fn1XQFBiXkcCpkyZYi+++GJJgUJvHBWd4U9H8Pv5\/elPf7J777035XQffPBBV1ugshF+Cf799u8aBGVB9EHwI\/gLwtGZJASyQICU\/mgge4J\/zeorYy3469S9wNYj+KNxAqxCIKYEEPwxXZiKhuUX+zt27LA333zTRfZVcb68lq7gv+KKK1w6v67k+9vf\/mbDhg2raGiBfh6G4PfPRVfxqXp+cvMX0Asjpb9x48auon\/z5s3t448\/dkcJvBsQvHf7r\/xD8Adyhwo7IfgR\/BU6CR0gAIFABBD8gTCl3QnBnzYyHoAABLJEAMGfJdBhv8a7+k1233jjDXcvfLLwTPXOdAS\/qsUPGDDAFEnXffM6V\/7++++HMpWwBX+qjxGqbXD99dfbOeecYzVq1AglpV+T1xGKTp06ueMDDz30kD399NMJTG644QY799xz3UcSBH8o7mIIfgR\/OJ6EFQhAAMEfjQ94gn\/1d1fZthgX7atbt7t9v6E9Kf3RuAFWIRBLAgj+WC5L+YPq2LGj6Y74unXr2ldffWWTJ0+2zZs3l\/mQ0t0XLFjgfu4X\/O+8846p0ry\/SSQrFV0V8Q866CAnWiVsyytQVxmEYQh+\/3EDzV\/X5mk+OsOvmgbKTFCEX7UN1MKI8MvO0Ucfbbfffrs1atTIvevPf\/6zE\/277rqrXXbZZXbGGWe44olqCP7KeEfpZxD8CP5wPAkrEIAAgj8aH0DwR8MVqxCAQOYEEPyZM8y6Ba+IXtAX+4WuX\/AHeV5HBCSiJfjDbGEIfo3nkksusd69e5cI7OQx6tq\/f\/\/733b88cfbsmXLXMRf\/xwk7T5VlX7PvrIflM7vFQv0v9crHLjXXnsh+ENyGgQ\/gj8kV8IMBAqeAII\/GhfwBP9KF+FfFc1LQrC6e93uVryhHRH+EFhiAgK5QgDBnysr5RunJ5aDDj1dwS\/BqqyAf\/7zn\/bMM8+4LIKwW1iCX+M666yzXDRfEX9F1rds2WJr1qyxWbNmmd5z3nnnWZ8+fdwUJkyYYDNmzMhY8MuWrgO89tprXRaBsi30Xl2J+Mc\/\/tHatWtn7du3R\/CH5DgIfgR\/SK6EGQgUPAEEfzQu4An+5Wv629YYC\/76dbrZxg2nIPijcQOsQiCWBBD8sVwWBlXIBJQ9QJX+RA9A8CP4C\/l3AnOHQJgEEPxh0txpC8EfDVesQgACmRNA8GfOEAsQCJUAgr80TgQ\/gj\/UTYYxCBQwAQR\/NIvvCf5\/rxkQ6wj\/nnW62g8bTibCH40bYBUCsSSA4I\/lsjCoQiaA4EfwB\/H\/1z69Okg3+kAAAhBIIIDgj8YhPMH\/1Zprbev2+J7h36tOF9u8\/hcI\/mjcAKsQiCUBBH8sl4VBFTIBBD+CP4j\/I\/iDUKIPBCCQTADBH41PIPij4YpVCEAgcwII\/swZFpyFdG8J8APyFxAsOHABJ4zgR\/AHcRUEfxBK9IEABBD82fEBT\/B\/ufY627J9dXZeWom37L3b+bZlfVsi\/JVgxyMQyFUCCP5cXbkqHHe\/fv3cNXeVaUuXLrWRI0dW5tGCeQbBj+AP4uwI\/iCU6AMBCCD4s+MDCP7scOYtEIBA+gQQ\/Okz4wkIREoAwY\/gD+JgCP4glOgDAQgg+LPjA57gX7T2hlhH+PfZ7Tzbtr4NEf7suAVvgUAsCCD4Y7EMDAICOwkg+BH8QfYDgj8IJfpAAAII\/uz4gCf4F6wbZD\/GOKV\/393Ote3rWiP4s+MWvAUCsSCA4I\/FMjAICCD4y\/MBruUrTQfBz28NCECgMgQo2lcZahU\/g+CvmBE9IACBqiGA4K8a7rwVAmUSIMJfGg2CH8HPrwwIQCAcAgj+cDgmW\/EE\/6frbop1hL\/JbueYrTuJCH80boBVCMSSAII\/lsvCoAqZAIIfwR\/E\/4nwB6FEHwhAIJkAgj8an\/AE\/8frh9jm7d9F85IQrDbd9TdWfd2JCP4QWGICArlCAMGfKyvFOAuGAIIfwR\/E2RH8QSjRBwIQQPBnxwcQ\/NnhzFsgAIH0CSD402fGExCIlACCH8EfxMEQ\/EEo0QcCEEDwZ8cHPMH\/wfpbYh3h32\/Xs6zGuhOI8GfHLXgLBGJBAMEfi2VgEBDYSQDBj+APsh8Q\/EEo0QcCEEDwZ8cHEPzZ4cxbIACB9Akg+NNnxhMQiJQAgh\/BH8TBEPxBKNEHAhBA8GfHBzzBP2\/DbbGO8Dff9UzbZe1xRPiz4xa8BQKxIIDgj8UyMAgI7CSA4EfwB9kPCP4glOgDAQgg+LPjA57gf3vDcPth+5rsvLQSbzlg185We+3PEfyVYMcjEMhVAgj+XF05xp23BBD8CP4gzo3grfwDFQAAIABJREFUD0KJPhCAAII\/Oz6A4M8OZ94CAQikTwDBnz4znoBApAQQ\/Aj+IA6G4A9CiT4QgACCPzs+4An+t74fEesI\/4G1z7Dd1h5LhD87bsFbIBALAgj+WCwDg4DATgIIfgR\/kP2A4A9CiT4QgACCPzs+4An+N74fZZtinNL\/s9qdrM7aoxH82XEL3gKBWBBA8MdiGRgEBBD85fnAaUf+HhdJIoDgxyUgAIHKEFi39nL7+9+Ps379+lXmcZ4pgwCCH9eAAATiSgDBH9eVYVwFS4AIf+mlR\/CXZoLgL9hfEUwcAhkRQPBnhK\/Mhz3B\/\/eiO2zT9rXRvCQEqy1rn2711hxFhD8ElpiAQK4QQPDnykoxzoIhgOBH8AdxdgR\/EEr0gQAEkgkg+KPxCQR\/NFyxCgEIZE4AwZ85QyxAIFQCCH4EfxCHQvAHoUQfCEAAwZ8dH\/AE\/2tFd9nGGEf4D619mu2x5ggi\/NlxC94CgVgQQPDHYhkYBAR2EkDwI\/iD7AcEfxBK9IEABBD82fEBT\/C\/WjQ21oK\/Ve1f2p5rDkfwZ8cteAsEYkEAwR+LZWAQEEDwl+cDnOEvTQfBz28NCECgMgRI6a8MtYqfQfBXzIgeEIBA1RBA8FcNd94KgTIJEOEvjQbBj+DnVwYEIBAOAQR\/OByTrXiC\/6\/F4614+7poXhKC1cNr\/ZftteYwIvwhsMQEBHKFAII\/V1aKcRYMAQQ\/gj+IsxPhD0KJPhCAQDIBBH80PuEJ\/r8U3xtrwX9krQ6295pDEfzRuAFWIRBLAgj+WC4LgypkAgj+Ql794HMn6yGRFR9AgvsOPQubAII\/mvVH8EfDFasQgEDmBBD8mTPEAgRCJYDgDxVn3hpD8CP489a5mVikBBD80eD1BP\/zxffFOsJ\/dK1TbZ81hxDhj8YNsAqBWBJA8MdyWRhUIRNA8Bfy6gefO4IfwR\/cW+gJgZ0EEPzReAOCPxquWIUABDIngODPnCEWIBAqAQR\/qDjz1hiCH8Gft87NxCIlgOCPBq8n+J8t\/r0VbV8fzUtCsHpsrXa275qWRPhDYIkJCOQKAQR\/rqwU4ywYAgj+glnqjCaK4EfwZ+RAPFywBBD80Sy9J\/j\/VDw51oL\/57VOsSZrfobgj8YNsAqBWBJA8MdyWRhUIRNA8Bfy6gefO4IfwR\/cW+gJgZ0EEPzReAOCPxquWIUABDIngODPnCEWIBAqAQR\/qDjz1hiCH8Gft87NxCIlgOCPBq8n+KcVP2zf74hvSv\/xtX5hzb47iAh\/NG6AVQjEkgCCP5bLwqAKmQCCv5BXP\/jcEfwI\/uDeQk8IEOGP2gc8wf9k8RT7fseGqF9Xafsn1mpr+393IIK\/0gR5EAK5RwDBn3trxojznACCP88XOKTpIfgR\/CG5EmYKjAAR\/mgWHMEfDVesQgACmRNA8GfOEAsQCJUAgj9UnHlrDMGP4M9b52ZikRJA8EeD1xP8jxc\/ZhtiHOFvXauNNf\/uACL80bgBViEQSwII\/lguC4MqZAII\/kJe\/eBzR\/Aj+IN7Cz0hsJMAgj8ab0DwR8MVqxCAQOYEEPyZM8QCBEIlgOAPFWfeGkPwI\/jz1rmZWKQEEPzR4PUE\/yPFT8Q6wt+21knW4rvmRPijcQOsQiCWBBD8sVwWBlXIBBD8hbz6weeO4EfwB\/cWekKACH\/UPuAJ\/oeL\/2jrd3wf9esqbf8XtU60g77bD8FfaYI8CIHcI4Dgz701Y8R5TgDBn+cLHNL0EPwI\/pBcCTMFRoAIfzQLjuCPhitWIQCBzAkg+DNniAUIhEoAwR8qzrw1huBH8OetczOxSAkg+KPB6wn+ycXTYh3hP6XW8faz75oR4Y\/GDbAKgVgSQPDHclkYVCETQPAX8uoHnzuCH8Ef3FvoCYGdBBD80XiDJ\/h\/X\/xMrAV\/u1rHWcvvmiL4o3EDrEIglgQQ\/LFcFgZVyAQQ\/IW8+sHnjuBH8Af3FnpCAMEftQ8g+KMmjH0IQKCyBBD8lSXHcxCIiACCPyKweWYWwY\/gzzOXZjpZIkCEPxrQnuCfWDzd1m0viuYlIVg9tdbP7dA1jYnwh8ASExDIFQII\/lxZKcZZMAQQ\/AWz1BlNFMGP4M\/IgXi4YAkg+KNZegR\/NFyxCgEIZE4AwZ85QyxAIFQCCP5QceatMQQ\/gj9vnZuJRUoAwR8NXk\/wTyh+LtYR\/v+qdYy1WrMvEf5o3ACrEIglAQR\/LJeFQRUyAQR\/Ia9+8Lkj+BH8wb2FnhDYSQDBH403eIJ\/XPHztjbGKf0dax1th69phOCPxg2wCoFYEkDwx3JZGFQhE0DwF\/LqB587gh\/BH9xb6AkBBH\/UPoDgj5ow9iEAgcoSQPBXllwEz5111lnWvXt3O+CAA6xWrVq2fft227Bhg7377rv2wAMP2IoVKxLe2rp1axs1apTVq1evzNH8+OOPVlRUZJ988ok98sgjtnjx4ghGnmjylFNOcfNo2bKl7bHHHla9evWSuXzxxRf21FNP2dtvv51yHAceeKCNGzfOmjZtaq+\/\/roNHjw48HgHDBhgF110kZvvrbfeWuY7Ahusoo4I\/ioCn2OvRfAj+HPMZRluTAgQ4Y9mITzBf1fxi7Z2e3E0LwnB6mm1jrIj1jQkwh8CS0xAIFcIIPhjsFI1a9Z0wr1du3ZOHKdqa9eutbvvvtvmzJlT8uMggt9va\/PmzTZ9+nT38SCK1qJFCxsyZIgdddRRZc5D79WHjA8++MBGjx5d6iNGPgj+OnXq2G9\/+1sTjxtuuCFt1Aj+tJEV5AMIfgR\/QTo+k86YAII\/Y4QpDXiC\/47iv8Ra8J9e60g7as3eCP5o3ACrEIglAQR\/DJZFkelu3bqZhP\/SpUvtD3\/4g82ePdsaNmxol112mZ1xxhku4r9s2TK78cYbbcmSJW7UfsH\/zjvv2LRp00rN5ogjjrCTTjrJDjvsMGdjy5Yt9sILL9iECRNCnfkhhxxid9xxhzVr1sx27Nhhy5cvt5deesleeeUVW7lypTVu3NjNQ1kMit5Xq1bNvvnmGxs6dKgtWrSoZCz5IPjvvPNO69Chgy1cuNB69eqVNmcEf9rICvIBBD+CvyAdn0lnTADBnzFCBH80CLEKAQhERADBHxHYoGabNGli9913n+23334u3V7if926dQmPK0p87rnnuqj5E088YVOmTCkl+CtKf5eIlO369es7+4quv\/nmm0GHWW6\/Pffc08aPH2+HH3646QjBjBkzbOLEibZ169ZSz+mjxk033eTE\/y677GKfffaZDRw40NavX+\/6ZiL4Q5lMCEbuuusua9++PYI\/BJaYKJsAgh\/Bz\/6AQGUIIPgrQ63iZ7wI\/6iiv9qaGKf0d6p9uB29Zi8i\/BUvKT0gkDcEEPxVvJQS4hK8ir77xbx\/WIrOjxkzxho1apRwrt0f4a9I8MveFVdcYT179nRCe+7cuZVKN0+Fy7MrMS+xr7GW19RPHxwkipVxMHXqVHv44YcR\/P8HjQh\/FW\/KHHk9gh\/BnyOuyjBjRgDBH82CIPij4YpVCEAgcwII\/swZZmThkksucYXmJILvuecemzlzZil7ZUW90xX8iu5PnjzZRdFXrVplgwYNSkinr8xEZHPSpEmuQF86Nk844QQbOXKkNWjQwFTIT9kHivInz1XHAvRBQYUM9aGiuLjY3nvvPZflkFyAsKKifQcffLD16dPHfv7zn7tChzpWUJ49j4fWRkcuzjnnHFNGhj7OKJNBRRT1sUJjVFOhwv79+7uf+1u6RQQR\/JXxxMJ7BsGP4C88r2fGYRBA8IdBsbQNT\/CPKHrZ1mzfGM1LQrB6Ru3D7Ng1DYjwh8ASExDIFQII\/hxYqbZt29qIESNs9913t5dfftkJZbV0Bb+eGTZsmHXu3Nk2bdrk0vBTfWBIB0nHjh3t5ptvdgI6SJaB37aOMpx44on2\/fff2\/Dhw13WgV\/wq56Bzv7Xrl271JBSFTEsT\/B36dLF+vbtW+aNBvrYoA8XyTx0XEG3Bui4gj4QJDd\/TQQEfzqeQ99MCSD4EfyZ+hDPFyYBBH806+4J\/mFFs2It+H9du5X9fE19BH80boBVCMSSAII\/lsuSOCjvTLiq7KvYntLmKyv4lVHQu3dvFy1XdDrTiv2Z2PMEuqLljz76qD355JMJgl9z1JxV+O\/BBx90c5Zo1wcLRdG\/+uordyzBu66wLMF\/8sknu+KAyiZQtF2i\/vHHH3dRetlSYT0VSNRHBF3n9\/7777t3eUcPdHuCChF6VxvqmkR96FC2gCrxb9y40dUs8NaFM\/w5sKnyYIgIfgR\/HrgxU6gCAgj+aKAj+KPhilUIQCBzAgj+zBlGaqFHjx7\/v70zgbaiuBb2Bq+ggEwCMjo9ZiOCIGIYJCYOKAIRh6DECUW9iqjxOQ8RERVnjXN8vzNI1Bd5GIk+fcSJAAYiPlDAxyBjmJEZLvivXUkfz7333Hv7dHf1qXP667WyViJdu6q+2gfz9a6ulssuu8xUufUkfn3f3zsML0iFP70Kraf6a1U7zJUu7U8++aT57J\/fK9NY0iv8KuQq+uPGjSsVMv0QQ31o4T0MqEj49SGJ7pLQhwfPPvtsuXh6or4eJKgPBD744AOzC0IvlfpbbrlFateubXYv6EOD9IMIO3XqJHfffbc5W+HLL780DyP0Qvj9ZgD3hSGA8CP8YfKHtsklgPDbWXtP+G\/b\/N+yzuEt\/afVbCddN9Slwm8nDYgKAScJIPxOLss\/B6VCrLKv33XXT\/KpfKZ\/wq7Qhf+bb74xVfSyp\/2nf9kgXbQzCX\/6gYczZsyQq6++OuOKe5KunxPUsw3004caTx+46Hv++qk9\/VRi2Utfr+jVq5d89913ctNNN5lPECL8Dv+oCmhoCD\/CX0DpzFRiJIDw24HtCf8tmz+UdXu32+kkgqj9a7aVbhsOQPgjYEkICOQLAYTf0ZU677zz5OKLLzayv3r1ahk7dqx89tlnpUZb6ML\/zjvvVHjiv75Xr1v19UHItddeK0uXLjWCrgcgph+S530FYf\/995fKdjTog4ULLrjAnG3gyX2mPvykC8LvhxL3hCWA8CP8YXOI9skkgPDbWXeE3w5XokIAAuEJIPzhGUYaQd8bv+KKK+TMM88076nr++kqoFqdLnsFEf7i4mLzab69e\/dW+BnAbCbkibK2qeizghXF88aiB99leoe\/MkGvqCJfVvgrOkivojHpawTeqwn6nn+7du1k3rx55j1\/v1cUwq9nCdSv\/0KpLus3+A+\/Q+C+BBBA+BH+BKQ5U4yAwI4dXWTH9i6pSDt2HC1Tp4rov4O5oiPgCf+Nm6c4XeEfULO1HLOhDhX+6JaeSBBwngDC79ASaTVfT6vXLeLVq1eXhQsXmtP507fxpw83iPB7MpoPp\/QnWfh\/+9thUlS0qlR2Nm12lUPZylByTQDhR\/hznYP0nx8EtKKvku9dJSXNZMaMlQh\/xMuH8EcMlHAQgEBkBBD+yFCGC6Sffxs9erTovzD0mjt3rtx+++2pE+gzRc9W+NPffU9\/Vz3MyOvVq2cO\/mvTpo2sWbPGvP9e0QOK9H50njpfPShvwYIFZju+fhov\/dC+yrb0e5\/003fnR44cad6dz7SlXz\/H5723\/\/TTT8v48eN9T9frI\/21AT+No6jwq\/C3bHWmn+64J6EEEH6EP6Gpz7RDEmBLf0iAFTT3hP+G7z+WtQ6\/wz9wv3+T7htqU+G3kwZEhYCTBBB+B5YlXfb182+ffvqpqezr594qu7IV\/uHDh5vt\/PpJvvTT6MMi8OLq6wiffPJJudPsy8ZP\/9ydHsinJ+0\/99xz5rZ04U8\/kC89RvqDi\/SD+DIJ\/1FHHWVeiSh7Ar+fOeshfAMHDjSH9o0ZMybjoX36SoMy1YcVDzzwgJk\/wu+HLveEJYDwI\/xhc4j2ySSA8NtZd0\/4r\/\/+U6eFf9B+h8uxG2oh\/HbSgKgQcJIAwu\/AsqhYDhgwwIzEjzB7Q85G+PXwOhVirciX\/d58WAQa86GHHpIjjjhC9H38yZMnm0MGy56ur\/2o7Osn8E455RTz4EF3MuinBjdu3FhO+Mt+394bp+4iGDRokIn\/\/PPPy2uvvWb+qKLP8j311FPSpUsXM28d15QpU0pN2XsA0aNHD3OPCvvUqVOr\/CyfPqh55JFHpH379uaUfm+ngSf8etK\/nsegDwOyuXStqPBnQyyZ9yL8CH8yM59ZhyWA8IclmLk9wm+HK1EhAIHwBBD+8AxDRUj\/1vvixYtFt53r9+IrulQe9XN1eqUL\/\/Tp080p9OmXiqxWuLt37y6HH364EWw9lM47IC\/UwMs0btu2rdxzzz3SsmVL0V0K+srApEmTjPzrdvumTZsaye\/fv780b95cqlWrJsuWLTO7AdJfAUiv8GsXeuL+H\/7wB7MLQL93r18uOP74482BhnPmzDEPCzyhrkj4+\/btax4yaJVfHyxMnDhRxo0bZ\/57t27d5JJLLpEjjzzSnJugHDWmPkxI34mgc5o5c6Z5wDB79mzTTj+ZqA859F4do77aoJfuKNA+9eGB7tSYNm1aVqgR\/qxwJfZmhB\/hT2zyM\/FQBBD+UPgqbOwJ\/282fSZr9+6w00kEUQftd5j02Lg\/Ff4IWBICAvlCAOHP8Up51WC\/w0g\/MT5d+P2014q5PhRQ4bdx6VZ7FXitpqs8V3TpFwJmzZplHhDoVwjSr3Th\/+KLL4yI16xZs1yoTAcaViT82lhP61dB14MRM10q9MpWBV0fvHiXVvH183wdO3Y0DynKXjoX3ZWhp+p7Oxr0oYSe6q8PWPTShyx6HsBbb73lCzvC7wtT4m9C+EunwH\/\/L4daJv5HAQBfBBB+X5iyvskT\/ms3\/dVp4f\/lfofKcRtrIvxZrzANIJC\/BBD+HK+d9+k3v8PIVvhVNrUC\/vnnn5sD69Jl1m+f2d6nDyLOO+88c5Bf3bp1jfzrVn+t1n\/11Vfy9ttvV1j1Thd+fTih2+IvuOCC1K4Arcp\/+OGHZidE2TMOKhN+nUPr1q1F37nXBxJ16tQxAq98Vq9ebXYiaNU\/07kJWunX9\/T1NYKGDRumdkrowwrdeaA7GdIvvV8PXNSdCPqwYs+ePVl9shDhzzbjknk\/wo\/wJzPzmXVYAgh\/WIKZ2yP8drgSFQIQCE8A4Q\/PkAiOEKhK+B0ZZpXDQPirRMQNIoLwI\/z8ECAQhADCH4Ra1W084b9m43SnK\/xn7H+IHLexBhX+qpeUOyBQMAQQ\/oJZSibiCb\/uaNAt9vpKQD5eCH8+rlr8Y0b4Ef74s44eC4EAwm9nFRF+O1yJCgEIhCeA8IdnSIQcEtDt83p2gL4\/r4fltWvXTpYvXy7XXnutLF26NIcjC941wh+cXZJaIvwIf5LynblGRwDhj45leiRP+EdunCFr9lZ8+LKd3v1HHbz\/wfLTjftS4fePjDshkPcEEP68X8JkT6BDhw5y3333mRP89dLD9\/785z+bw\/fy9UL483Xl4h03wo\/wx5tx9FYoBBB+OyvpCf\/VG\/7muPC3kp6bihB+O2lAVAg4SQDhd3JZ4htUtl8JSB9Z+gGC8Y24dE\/6mb+RI0eaQ\/j0AL6pU6eaBwB6uF++Xgh\/vq5cvONG+BH+eDOO3gqFAMJvZyURfjtciQoBCIQngPCHZ5jXEYqLi6Vr166B5rBkyRIZNWpUoLY0qpgAwk92+CGA8CP8fvKEeyBQlgDCbycnPOEfsX6W0xX+M2u1lJ6b9qHCbycNiAoBJwkg\/E4uC4NKMgGEP8mr73\/uCD\/C7z9buBMCPxJA+O1kgyf8V67\/0mnhP6tWC+m1qTrCbycNiAoBJwkg\/E4uC4NKMgGEP8mr73\/uCD\/C7z9buBMCCL\/tHED4bRMmPgQgEJQAwh+UHO0gYIkAwm8JbIGFRfgR\/gJLaaYTEwEq\/HZAe8JfvH62rNmzy04nEUQ9q1Zz6f19NSr8EbAkBATyhQDCny8rxTgTQwDhT8xSh5oowo\/wh0ogGieWAMJvZ+kRfjtciQoBCIQngPCHZ0gECERKAOGPFGfBBkP4Ef6CTW4mZpUAwm8Hryf8V6z\/SlY7XOE\/u1Yz6UOF304SEBUCjhJA+B1dGIaVXAIIf3LXPpuZI\/wIfzb5wr0Q8Agg\/HZywRP+y9fNcVr4z6ndVPp8L2zpt5MGRIWAkwQQfieXhUElmQDCn+TV9z93hB\/h958t3AmBHwkg\/HayAeG3w5WoEIBAeAIIf3iGRIBApAQQ\/khxFmwwhB\/hL9jkZmJWCSD8dvB6wj983ddOV\/h\/VfsgOf77H6jw20kDokLASQIIv5PLwqCSTADhT\/Lq+587wo\/w+88W7oQAFX7bOeAJ\/yVr5zkt\/ENqN5G+m\/ci\/LYTgvgQcIgAwu\/QYjAUCCgBhJ888EMA4Uf4\/eQJ90CgLAEq\/HZyAuG3w5WoEIBAeAIIf3iGRIBApAQQ\/khxFmwwhB\/hL9jkZmJWCSD8dvB6wn\/x2vmyes9uO51EEPXc2o3lZ5v3UOGPgCUhIJAvBBD+fFkpxpkYAgh\/YpY61EQRfoQ\/VALROLEEEH47S4\/w2+FKVAhAIDwBhD88QyJAIFICCH+kOAs2GMKP8BdscjMxqwQQfjt4PeG\/aM0C+YfDFf7z6jSWEzaXUOG3kwZEhYCTBBB+J5eFQSWZAMKf5NX3P3eEH+H3ny3cCYEfCSD8drLBE\/7z1\/yf08I\/tE4j+cXm3Qi\/nTQgKgScJIDwO7ksDCrJBBD+JK++\/7kj\/Ai\/\/2zhTggg\/LZzAOG3TZj4EIBAUAIIf1BytIOAJQIIvyWwBRYW4Uf4CyylmU5MBKjw2wHtCf95qxc5XeE\/v86BcuKWXVT47aQBUSHgJAGE38llYVBJJoDwJ3n1\/c8d4Uf4\/WcLd0KACr\/tHPCEf8jqxbJqT4nt7gLHv6BOQzl5y06EPzBBGkIg\/wgg\/Pm3Zoy4wAkg\/AW+wBFND+FH+CNKJcIkjAAVfjsLjvDb4UpUCEAgPAGEPzxDIkAgUgIIf6Q4CzYYwo\/wF2xyMzGrBBB+O3g94T\/7H0ucrvBfdEADOYUKv50kICoEHCWA8Du6MAwruQQQ\/uSufTYzR\/gR\/mzyhXsh4BFA+O3kAsJvhytRIQCB8AQQ\/vAMiQCBSAkg\/JHiLNhgCD\/CX7DJzcSsEkD47eD1hP\/MVUtlpcPv8F98QH05desO3uG3kwZEhYCTBBB+J5eFQSWZAMKf5NVn7kEJ8ACEByBBcydp7RB+OyvuCf+gVcudFv5LDqgn\/bduR\/jtpAFRIeAkAYTfyWVhUEkmgPAnefWZe1ACCD\/CHzR3ktYO4bez4gi\/Ha5EhQAEwhNA+MMzJAIEIiWA8EeKk2AJIYDwI\/wJSfXQ00T4QyPMGMAT\/tNXrnS6wj+8bl05fes2Kvx20oCoEHCSAMLv5LIwqCQTQPiTvPrMPSgBhB\/hD5o7SWuH8NtZcU\/4T125Ulbs2WOnkwiiXl63rgzcuhXhj4AlISCQLwQQ\/nxZKcaZGAIIf2KWmolGSADhR\/gjTKeCDoXw21lehN8OV6JCAALhCSD84RkSAQKREkD4I8VJsIQQQPgR\/oSkeuhpIvyhEWYM4An\/ySv\/IStK3K3wF9c9QAZt20KF304aEBUCThJA+J1cFgaVZAIIf5JXn7kHJYDwI\/xBcydp7RB+OyuO8NvhSlQIQCA8AYQ\/PEMiQCBSAgh\/pDgJlhACCD\/Cn5BUDz1NhD80wkor\/CetWCPLXa7w16sjZ2zbTIXfThoQFQJOEkD4nVwWBpVkAgh\/klefuQclgPAj\/EFzJ2ntEH47K+5V+H+xYq3Twn9lvdoyGOG3kwREhYCjBBB+RxeGYSWXAMKf3LVn5sEJIPwIf\/DsSVZLhN\/OeiP8drgSFQIQCE8A4Q\/PkAgQiJQAwh8pToIlhADCj\/AnJNVDTxPhD40wYwBP+H++fL3TFf6r6tWSwdu\/Z0u\/nTQgKgScJIDwO7ksDCrJBBD+JK8+cw9KAOFH+IPmTtLaIfx2VtwT\/hOWb5DlJXvtdBJB1Kvq7S9nbt+E8EfAkhAQyBcCCH++rBTjTAwBhD8xS81EIySA8CP8EaZTQYdC+O0sL8JvhytRIQCB8AQQ\/vAMiQCBSAkg\/JHiJFhCCCD8CH9CUj30NBH+0AgzBkgJ\/7KNblf462uFfyMVfjtpQFQIOEkA4XdyWRhUkgkg\/ElefeYelADCj\/AHzZ2ktUP47aw4wm+HK1EhAIHwBBD+8AyJAIFICSD8keIkWEIIIPwIf0JSPfQ0Ef7QCCuv8C\/93vEK\/35y5o4NVPjtpAFRIeAkAYTfyWVhUEkmgPAnefWZe1ACCD\/CHzR3ktYO4bez4qlT+r\/b7LbwN6gpgxF+O0lAVAg4SgDhd3RhGFZyCSD8yV17Zh6cAMKP8AfPnmS1RPjtrDfCb4crUSEAgfAEEP7wDIkAgUgJIPyR4iRYQggg\/Ah\/QlI99DQR\/tAIMwbwhP8X3211usJ\/ZYMaMnjHerb020kDokLASQIIv5PLwqCSTADhT\/LqM\/egBBB+hD9o7iStHcJvZ8U94T9pyTZZXvKDnU4iiFrcYF85Y+c6hD8CloSAQL4QQPjzZaUYZ2IIIPyJWWomGiEBhB\/hjzCdCjoUwm9neRF+O1yJCgEIhCeA8IdnSAQIREoA4Y8UJ8ESQgDhR\/gTkuqhp4nwh0aYMYAn\/Ccv3i4rXK7wN9xXBu1cS4XfThoQFQJOEkD4nVyW4INq3bq1jBw5Ujp06CC1a9eWvXv3yqZNm+STTz6RF198UVauXFkuuP7zdu3aVdipxti2bZssWbJE3nzzTZk8eXLwAVbQcsSIEXLuuef6jrtr1y558sknZcKECb7b5MuNCH++rBTjdIkAwo\/wu5SPLo8F4bezOgi\/Ha5EhQAEwhNA+MMzdCbC4MGD5fLLL5c6depkHNPy5cvl\/vvvlxkzZpT686qEP\/1mlf+ZM2fK7bffLhs3boxs7gj\/jygR\/sjSikAJIoDwI\/wJSvfCGieXAAAgAElEQVRQU0X4Q+GrsLEn\/P0W75QVu919h\/\/yhkUyaNcaKvx20oCoEHCSAMLv5LJkP6hOnTrJ3XffLU2aNJEtW7bIH\/7wB3n11VelRo0aMmzYMDn99NOlZs2aMmfOHPnNb35jqv7e5Qn\/6tWrTdU8\/c\/0noMOOki6d+8uxx57bOphwty5c02cqKTfE36t3I8fP948VKjs2rNnj3z77beR9Z89cXstEH57bIlcuAQQfoS\/cLM72pkh\/NHy9KJ5wt9\/0S6nhf+yA\/eRAQi\/nSQgKgQcJYDwO7ow2Q7r+uuvN09rd+\/enXGr+zXXXCNnnnmmqFA\/9NBD8u6775YT\/hUrVojGWbRoUcbuDz30UBk1apS0adNGVLh1e\/+jjz6a7VAz3p8u\/IW6Vd8vKITfLynug8CPBBB+hJ\/fgz8CCL8\/TtnehfBnS4z7IQCBuAgg\/HGRttzPHXfcIccdd5ysXbtWrrrqqnJVeq3Ojx492lToX3\/9dXniiSeyFn5toP9C0zgNGjSQNWvWmAcE8+fPDz07hP9HhAh\/6HQiQAIJIPwIfwLTPtCUEf5A2Kps5An\/gEUlstLhLf2XHlhdTt+1mi39Va4oN0CgcAgg\/IWzlpXOpGfPnnLXXXeZg\/zCCL92ctNNN8nAgQNl586d8vzzz8trr70WmmIUwl9UVCRnnXWWGVuzZs3M6wx66a4GPXBQD\/ibNGlSxrHq\/RdeeKH07t1b6tWrJ9WrV5etW7fK119\/LY899ph5faDslamNMtHXHV566SWZNm1aIC4IfyBsNEo4AYQf4U\/4T8D39BF+36iyutET\/kELVfizahrrzZccWF367\/4Hwh8rdTqDQG4JIPy55R9b7yrpAwYMMKftjxkzRj766KNU3947\/FVt6fcaqJDq+\/v777+\/vPfee2abf9grrPDXr19fHnzwQenYsaNUq1Yt43D0dYc\/\/vGP8vDDD5f68759+8oNN9xgdi1kujZs2CBjx46VKVOmpP5YH6BoGz0zIdOl4q8PQvSBSLYXwp8tMe6HgAjCj\/DzO\/BHAOH3xynbuxD+bIlxPwQgEBcBhD8u0jnoRyveXbt2lV\/\/+teih\/rp\/9bP8916661SUlISWPj1k3\/33XefkV2tZuuhgGGvsMJ\/5513ysknn2zmNXXqVHnhhRfMqwb6IGDIkCHmSba+zlD2NYS2bduaByAtWrQwOxb0k4P6AOT777+XoUOHmh0D2m7x4sVy3XXXmc8aHnbYYfLAAw+YNrp74MMPP5SXX35Zli1bJieccIJcdNFFoucd6MMV3R0wceLErPAg\/Fnh4mYIGAIIP8LPT8EfAYTfH6ds7\/KE\/4z\/2+N0hX9Yo2pyGhX+bJeX+yGQ1wQQ\/rxevooHf\/bZZ8uVV16Z2tbuyezjjz9uRDT9yrbCr8Kr1fTmzZvLvHnzzFb4sFc2n+UruxNBpV3H07hxY5k+fbrZfZD+QEPHpp8rVIHfvn273HvvvakdDumHHT7zzDMybty4UlPRuel\/9GGJbtPXir3XRvvItGMg\/SHC7NmzzTqUHU9lvBD+sNlE+yQSQPgR\/iTmfZA5I\/xBqFXdBuGvmhF3QAACuSGA8OeGu\/VeMwm0VqP\/8pe\/mOp8uvTnu\/CfdNJJ5qBCrcTrXLTaXvbyHoDoP\/e+AqASrwLfvn1782WCK664otxhh\/qevn6JoGHDhuYhwVNPPSVPP\/20qfJX1Eb7UP66s0A\/kai7D3TXgd8L4fdLivsg8CMBhB\/h5\/fgjwDC749Ttnd5wn\/mtz84XeG\/uJHIqSWreIc\/2wXmfgjkMQGEP48Xr7KhN23a1PyxntrvbTM\/5JBDzD\/7+OOPzcF73uWS8OtDifHjx8vMmTMrnN6OHTtkzpw5lVbNVch1vvpKw5FHHmm22NesWdNswfeE\/\/DDDzc7A1Tq9f38m2++ucpsOOqoo8wOAX3fXzneeOONGdt45xzss88+5vWCTA8hKuoM4a9yGbgBAuUIIPwIPz8LfwQQfn+csr3LE\/6zFoiscvjQvosai\/QrWYnwZ7vA3A+BPCaA8Ofx4mUzdH2X\/ZFHHjHVbD2ETj\/j98UXX5gQ2Qp\/t27dzKf59DT7L7\/80myXD3uFfYdfq\/W6ZV9lWc8W8E7oLzuudOGv7FOFFc0nvY3fOZf9KkJV7XQOt912mzRqfE+pW+vU+VNVTflzCCSWAMKP8Cc2+auY+I4dXaSkpFnqrh3bu8gnnzST4uJikEVIAOGPECahIACBSAkg\/JHidDvY+eefnzpgL73qnK3wp58P4MIp\/Sr799xzj\/mknp7Q\/8MPP5hXFvSAvlWrVplzBvbu3SvnnXeeWSCvwu+68JfNpkMP6+l2gjE6COSQAMKP8Ocw\/Zzueu2aW2XLllNLjXHWrFkIf8Sr5gn\/2fOrOV7h\/0FO2UOFP+LlJxwEnCaA8Du9PNEOLl3U06vO2Qq\/fobvxBNPLLU9PuxIw1T4VeQvvfRSU9WfMWOG2cmgp+qnX5ne4U\/\/2oDfLf3puxveeOMN835\/1Bdb+qMmSrwkEED4Ef4k5HkUc2RLfxQUy8fwhP9X8\/ZxWvgvbLJXTt6zgi39dtKAqBBwkgDC7+SyZDeoVq1amQp3y5Yt5e9\/\/7v5fFymyztITr9Hr6f1v\/XWW+a2bIRf\/4Wm2\/n1HXb9DN3VV19tPlUX9goj\/Pfff7\/06dPHvKqg7+HrawZlLz2zYODAgaUeUugrCd4BfAsWLDAH7W3atKlcWz29X0\/e13v0wEP9z8EHHyxBTuD3wwnh90OJeyBQmgDCj\/Dzm\/BHAOH3xynbuxD+bIlxPwQgEBcBhD8u0hb70S3tuk29U6dORlhVSLVinX6lfyqu7Gft\/Aq\/Hnyn1f02bdqIPjR49dVX5bnnnotkZlEJf\/rZBN7AfvKTn5hx6+F86e\/w659X9Vm+vn37mgMO9eGA9\/qC9nHKKaeYWM8++2y5T\/l5cfv3729eLdDXJ7yHK35gIfx+KHEPBBD+ynLgv\/\/3KlIEAhkJIPx2EsMT\/iFa4d9VzU4nEUS9QCv8e5dT4Y+AJSEgkC8EEP58Wakqxjl48GBTodaT6PVkfpV4FVS9+vXrJ\/r+vh5ml0nUPeFfvXq1eXBQtsqtp9nrVnY9ob527drmHflp06bJv\/\/7v2f1ffnKphBG+PXQQD2wT0\/E1yq87l7QAwn1SwW\/+tWv5OSTTxY9tFCvssKf\/iBE5fxPf\/qTEXS9T7ldeOGF0qhRI7N7QHdRfPbZZ6baP2bMGGnRooXs3LlTJk+ebHjreQH6Z8OGDZMePXqYVwy+\/fZbsy4bN270nWkIv29U3AiBFAEq\/KWTAeHnx1ERAYTfTm4g\/Ha4EhUCEAhPAOEPz9CZCHri7jnnnFPpCfX63rl+Sz798oTfz0T08Lu\/\/vWvcvfdd2clsVXFDiP8WrnXXQ0q25kulXfd5t+6dWsj\/rozIZ2BVvFvuOEG85pCpksfBGglf8KECak\/rqqN3rh8+XLR1w30XIFsLoQ\/G1rcC4F\/EkD4EX5+C\/4IIPz+OGV7lyf8535T5HaF\/6A9chIV\/myXl\/shkNcEEP68Xr7yg9eT5y+44AIjv1qN12vr1q0yf\/58eemll0xlvuxVlfDrrgCNodVzld5PP\/00cmphhF8Ho9KvDzx0\/nXq1DGn9afP+5tvvpEnnnjCvI6Q6d37itp\/\/fXX8thjj5lKfdlL2+gOAP06gG75r169utlBodX8v\/zlL2anQDaVfS8+wh95ehEwAQQQfoQ\/AWkeyRQR\/kgwlgviCf95X+\/rtPCfr8L\/wzK29NtJA6JCwEkCCL+Ty8KgkkwA4U\/y6jP3oAQQfoQ\/aO4krR3Cb2fFEX47XIkKAQiEJ4Dwh2dIBAhESgDhjxQnwRJCAOFH+BOS6qGnifCHRpgxQEr459aQfzh8aN\/5TUvkRCr8dpKAqBBwlADC7+jCMKzkEkD4k7v2zDw4AYQf4Q+ePclqifDbWe+U8M+p6b7wy1K29NtJA6JCwEkCCL+Ty8KgkkwA4U\/y6jP3oAQQfoQ\/aO4krR3Cb2fFEX47XIkKAQiEJ4Dwh2eY+Ah6UN7o0aPNYXnZXmU\/k5dt+0K8H+EvxFVlTrYJIPwIv+0cK5T4CL+dlfSEf+j\/ul3h\/3WzEjmRCr+dJCAqBBwlgPA7ujD5NKz27dvLlVdeKbVq1cp62Hqq\/fjx42XKlClZty3UBgh\/oa4s87JJAOFH+G3mVyHFRvjtrCbCb4crUSEAgfAEEP7wDIkAgUgJIPyR4iRYQggg\/Ah\/QlI99DQR\/tAIMwbwhP\/XX+3n9Dv8v262W35RjXf47WQBUSHgJgGE3811YVQJJoDwJ3jxmXpgAgg\/wh84eRLWEOG3s+Ce8J8\/e3+nhX9ocxX+7zi0z04aEBUCThJA+J1cFgaVZAIIf5JXn7kHJYDwI\/xBcydp7RB+OyuO8NvhSlQIQCA8AYQ\/PEMiQCBSAgh\/pDgJlhACCD\/Cn5BUDz1NhD80wowBPOG\/4Mv95R87q9npJIKoQ1vslp9Xp8IfAUpCQCBvCCD8ebNUDDQpBBD+pKw084ySAMKP8EeZT4UcC+G3s7qe8F\/491pOC\/95LXbJz\/dB+O1kAVEh4CYBhN\/NdWFUCSaA8Cd48Zl6YAIIP8IfOHkS1hDht7PgCL8drkSFAATCE0D4wzMkAgQiJYDwR4qTYAkhgPAj\/AlJ9dDTRPhDI8wYwBP+i2Y5XuFvuUtOoMJvJwmICgFHCSD8ji4Mw0ouAYQ\/uWvPzIMTQPgR\/uDZk6yWCL+d9Ub47XAlKgQgEJ4Awh+eIREgECkBhD9SnARLCAGEH+FPSKqHnibCHxph5RX+mVrhr26nkwiinqcV\/qIlfJYvApaEgEC+EED482WlGGdiCCD8iVlqJhohAYQf4Y8wnQo6FMJvZ3m9Cv\/Ff3Nb+M9thfDbyQCiQsBdAgi\/u2vDyBJKAOFP6MIz7VAEEH6EP1QCJagxwm9nsRF+O1yJCgEIhCeA8IdnSAQIREoA4Y8UJ8ESQgDhR\/gTkuqhp4nwh0aYMUBK+L+o7fSW\/nNb7ZQT9mVLv50sICoE3CSA8Lu5LowqwQQQ\/gQvPlMPTADhR\/gDJ0\/CGiL8dhY8Jfwz6sjqHe6+w3\/uwTvlZzUW8w6\/nTQgKgScJIDwO7ksDCrJBBD+JK8+cw9KAOFH+IPmTtLaIfx2Vhzht8OVqBCAQHgCCH94hkSAQKQEEP5IcRIsIQQQfoQ\/IakeepoIf2iEGQOkhH\/6AW5X+A\/ZQYXfTgoQFQLOEkD4nV0aBpZUAgh\/UleeeYchgPAj\/GHyJ0ltEX47q43w2+FKVAhAIDwBhD88QyJAIFICCH+kOAmWEAIIP8KfkFQPPU2EPzTCSiv8w6a5XeEfohX+mrzDbycLiAoBNwkg\/G6uC6NKMAGEP8GLz9QDE0D4Ef7AyZOwhgi\/nQX3KvzD\/lrX6S39Qw5V4V\/EoX120oCoEHCSAMLv5LIwqCQTQPiTvPrMPSgBhB\/hD5o7SWuH8NtZcYTfDleiQgAC4Qkg\/OEZEgECkRJA+CPFSbCEEED4Ef6EpHroaSL8oRFmDOAJ\/yVT6zle4d8uffejwm8nC4gKATcJIPxurgujSjABhD\/Bi8\/UAxNA+BH+wMmTsIYIv50FTwn\/5\/XdFv7DVPgXsqXfThoQFQJOEkD4nVwWBpVkAgh\/klefuUMgGgI8AOEBSEWZhPBH8xsrGwXht8OVqBCAQHgCCH94hkSAQKQEEP5IcRIMAokkgPAj\/Ah\/vD99T\/gv\/bSB0xX+Xx2+TfruT4U\/3uygNwjklgDCn1v+9A6BcgQQfpICAhAISwDhR\/gR\/rC\/ouzaI\/zZ8eJuCEAgPgIIf3ys6QkCvggg\/L4wcRMEIFAJAYQf4Uf44\/0rwhP+4Vrh375PvJ1n0ZtW+I+v9X+8w58FM26FQL4TQPjzfQUZf8ERQPgLbkmZEARiJ4DwI\/wIf7w\/O0\/4L\/ukodPCf86\/bUX4400NeoNAzgkg\/DlfAgYAgdIEEH4yAgIQCEsA4Uf4Ef6wv6Ls2iP82fHibghAID4CCH98rOkJAr4IIPy+MHETBCBQCQGEH+FH+OP9K8IT\/sv\/cqDbFf7WW6VP7W\/Z0h9vetAbBHJKAOHPKX46h0B5Agg\/WQEBCIQlgPAj\/Ah\/2F9Rdu094b9iSiOnhf\/s1lukTx2EP7vV5W4I5DcBhD+\/14\/RFyABhL8AF5UpQSBmAgg\/wo\/wx\/ujQ\/jj5U1vEICAfwIIv39W3AmBWAgg\/LFgphMIFDQBhB\/hR\/jj\/YmnhP9\/Grtd4W+jFf4FbOmPNz3oDQI5JYDw5xQ\/nUOgPAGEn6yAAATCEkD4EX6EP+yvKLv2CH92vLgbAhCIjwDCHx9reoKALwIIvy9M3AQBCFRCAOFH+BH+eP+KSAn\/R01kzfZ94u08i97ObrNZeh9AhT8LZNwKgbwngPDn\/RIygUIjgPAX2ooyHwjETwDhR\/gR\/nh\/dynh\/\/AgWbPNYeFvu1l6153Plv5404PeIJBTAgh\/TvHTOQTKE0D4yQoIQCAsAYQf4Uf4w\/6KsmuP8GfHi7shAIH4CCD88bGmJwj4IoDw+8LETRCAQCUEEH6EH+GP96+IlPD\/d1O3K\/ztvqfCH29q0BsEck4A4c\/5EjAACJQmgPCTERCAQFgCCD\/Cj\/CH\/RVl1z4l\/B+o8Bdl1zjGu89W4a83jy39MTKnKwjkmgDCn+sVoH8IlCGA8JMSEIBAWAIIP8KP8If9FWXXHuHPjhd3QwAC8RFA+ONjTU8Q8EUA4feFiZsgAIFKCCD8CD\/CH+9fESnh\/3Mztyv87TdJ7\/pU+OPNDnqDQG4JIPy55U\/vEChHAOEnKSAAgbAEEH6EH+EP+yvKrj3Cnx0v7oYABOIjgPDHx5qeIOCLAMLvCxM3QQAClRBA+BF+hD\/evyI84S+e3NzpCv9ZHbTC\/w3v8MebHvQGgZwSQPhzip\/OIVCeAMJPVkAAAmEJIPwIP8If9leUXfuU8L\/XwnHh3yi9GyD82a0ud0Mgvwkg\/Pm9foy+AAkg\/AW4qEwJAjETQPgRfoQ\/3h8dwh8vb3qDAAT8E0D4\/bPiTgjEQgDhjwUznUCgoAkg\/Ag\/wh\/vTzwl\/H9qIWu2uvtZvrM6bpTeDanwx5sd9AaB3BJA+HPLP1TvRUVFMnToUBk0aJA0bNhQ9t13X9m1a5csXLhQ3njjDZk8eXK5+Mcee6yMHj1a6tSpU2HfGmPLli3y1Vdfye9\/\/3v59ttvQ40zU+MXX3xR2rVrJytWrJDrr79eFi1aVGkf999\/v\/Tp08eM67bbbpNp06ZFPqYoA3rz+\/jjj+XGG2\/MKjTCnxUuboYABDIQQPgRfoQ\/3r8aUsL\/bku3hf8IFf6veYc\/3vSgNwjklADCn1P8wTuvX7++EXf9F0y1atXKBVJpV+F\/4IEHpKSkJPXnfoQ\/PdjOnTtlwoQJ8tRTTwUfbIaWCH\/FOBH+SFONYBBIJAGEH+FH+OP96SP88fKmNwhAwD8BhN8\/K6fuvOmmm2TAgAFmTHPmzJEnnnhCZs+eLb169ZLLLrtMWrduLSrr+s\/feuutjMI\/ffp0ef3118vN64gjjpDu3btLhw4dpEaNGrJ792754x\/\/KA8\/\/HBkDBB+hD+yZCIQBCBQjgDCj\/Aj\/PH+xeAJ\/5WTWjle4d8gvQ6kwh9vdtAbBHJLAOHPLf9Avbdt21YefPBBady4scydO1euu+462bRpUyrWYYcdZv68efPm8uWXX8rll1+eUfir2m6uleYRI0ZIvXr1ZOPGjXLPPffIp59+GmjMZRsh\/Ah\/JIlEEAhAICMBhB\/hR\/jj\/csB4Y+XN71BAAL+CSD8\/lk5c6dW8a+88kpp1KiRvPLKK\/Lyyy+XG5v3znvZd+TTt\/RXJfwadPjw4eacAD0fYOrUqebhQhQXwo\/wR5FHxIAABDITQPgRfoQ\/3r8dUsI\/0fEK\/082SK9GVPjjzQ56g0BuCSD8ueVvrXet8Pfs2bPcoXjZCr9W959++mnRXQNr1qwxB+zNnz8\/9LijFn59heHSSy+VTp06Sd26daV69eqyd+9es\/Phiy++MHNYuXJlatzpuyD0tYa\/\/\/3vcuGFF5pXIfQ1Bj0DQe9\/9dVXZdKkSRnn27t371Jt9BUKPejwscceMwcL6qGEfh6qlA3OO\/yh04sAEEg8AYQf4Uf44\/1rwBP+q9452Okt\/WceqcI\/l0P74k0PeoNATgkg\/DnFb6dzld67775bmjRpUq4qn63w6wjvuOMO6devn2zfvl0eeugheffdd0MPPErhP\/vss825BbVq1apwXMuXL5dbbrkl9bAiXfhnzJghem5BpvYq\/i+88EK5XRRDhgwxfdasWbNcn9qXHpR4yCGHIPyhM4UAEIBAEAIIP8KP8Af55QRvg\/AHZ0dLCEDALgGE3y7fWKM3bdrUHOSnn+lr0KCBbNiwQcaOHStTpkxJjSOI8J9\/\/vkybNgws61fK95RnNgflfDrv2D1awU637Vr14rGfe+992Tbtm3SrVs3I+Uq83q9\/fbb5mwDvdKFX\/+3fu5P\/3zcuHGmuq\/Vfn2QoEK\/bNkyufrqq1M7BHTnxK233ppirH3qLgB9wHLFFVdIjx49zC4Bvajwx\/oToDMIQOBfBBB+hB\/hj\/evA0\/4R\/znIW5X+Dutl56NqfDHmx30BoHcEkD4c8s\/st49gfYCfvfdd\/K73\/1OPvnkk1J9BBF+FV89M0AlVre\/68n\/Ya+y4\/UbT8Vct8tPmzbNNNFXDM444wzZunWr+QTh+++\/XypUs2bN5PHHH5eWLVuKVvJV3MsKvz4c0G34EydOLNVWdwScfvrp5mHAvffeKx999JH581GjRsmJJ55oXhe47777Sj1Q0T\/3vqCgn0tE+P2uLPdBAAJREkD4EX6EP8pfVNWxPOG\/WoV\/S1HVDXJ0x2AV\/iYIf47w0y0EckIA4c8J9mg7LVut1ug\/\/PCDrFq1yshu2Aq\/y8KvrxgcddRRpvp+1VVXlfpagUfZe7gwb948U7kvK\/yLFi0ylfn0Lx3oPd689b8\/+eSTMmHCBGnVqpU88sgj0qJFi1IPENJXVD9nqA8CtOKP8Eeb60SDAAT8EUD4EX6E399vJaq7EP6oSBIHAhCImgDCHzXRHMQrKiqSgw8+WLSqryf3q9SecsopZju6buvXz+l99tlnZmSuVfhXr15tZLqsbJfFeO6550r37t1NtT29wl\/2Pn0Pv3379ubAvM6dO5v\/rkz0EL+KhF\/Z6E6Bslcm4U\/nV9luB33vv2PHjoGFX+fYstWZpYZUVPTjoYM5SDO6hAAE8ogAwo\/wewRKSpqVgrFlcz\/5n\/85WoqLi\/Moo90fqif8I9\/SCv++zg548FHr5acHzeHQPmdXiIFBIHoCCH\/0TJ2IqIfKXX755WYb\/gcffGAO3gsq\/Pp\/CvTTfHrq\/UsvvSTPP\/986DlG9Q6\/DkRP1tdXDvRd\/Tp16ohupc90VST8FVXhMwn\/4MGDU68FZDrMz+vX+yxi0Aq\/Cn\/Z69DDeobmTgAIQCAZBBB+hN8jsHbNrbJly6mlgMyaNQvhj\/ivAoQ\/YqCEgwAEIiOA8EeG0q1A6Z\/TS9+yHqTC78mri6f09+3bV2644QZzgJ5eeuCe7gLQ1xmWLFkif\/vb3+Scc86RNm3aVFjhd1H4f\/vbYdKo8T2lkmq\/\/Wa5lWSMBgIQcJYAwo\/wewS0wl9S0jQFZMvmU+WTT5oh\/BH\/ej3hv+bNQ2StwxX+Mzqvl+Oo8Ee8+oSDgNsEEH631yfU6DJV0bMV\/vRD71asWGG2vusDhLBXFBV+faihBwiqzOsrAbrz4J133jGfxEu\/qnqHPxvhT+f3xhtvyKOPPpoRxTPPPGPOFgha4VfhL7ulPyxz2kMAAskhgPAj\/BVl+8YNF7Ol38JfBZ7wXzvhUKeF\/5dd1slxTdnSbyEFCAkBZwkg\/M4uTcUDu\/TSS03Vevfu3eZkeu\/0+PQW6Qf5zZ0713xWT69shX\/48OFmO79+ki\/91YCw2KIQ\/vS56Kf49PT8slf6AXpRbOnXTx\/qif56ZsLs2bPNqwRlHzCks0f4w2YK7SEAgSAEEH6EH+EP8ssJ3gbhD86OlhCAgF0CCL9dvlaiDxgwQK677jpzKJ8KpX4Tvqx06p8PGjTIHFb35ptvpirR2Qj\/aaedJiNGjBCtpOvhf\/pe+cyZMyOZU9TCn+lhhB5meO2118rAgQNln332iWRLv07+zjvvlJNPPtm8PvDss8\/KuHHjSjHx2OtDEoQ\/knQhCAQgkCUBhB\/hR\/iz\/NGEvN0T\/t+84XaFf1CXddKjGRX+kMtNcwjkFQGEP6+W65+DVQHXz9HpIXVa5Z86daroAXLz58+Xtm3bmmp+jx49zIF9ixcvNg8H9LN1eqUL\/\/Tp00VPmk+\/VJJ1K7qeiH\/44Yebyr6KbWUH1AVBGIXwp79usHPnTvPZPJ2PvsPfq1cvszNBK\/z60EOvKCr8GqdTp05y9913m8\/uaV9vv\/22kf799ttPLrroIvOFBGWvF8IfJDtoAwEIhCWA8CP8CH\/YX1F27T3hv378YbJ2s7un9A86ep0c2\/x\/OaU\/u+XlbgjkNQGEP0+XT8VeK80q5RVdCxculLvuuss8CPCudOH3M\/Vt27YZiVbhj\/KKQvh1POeff755wOEJdtkx6mf\/li5dKl27dpXly5ebir\/+bz\/b7jOd0u\/F190Pup3fOywwvV\/v4MCGDRsi\/FEmDbEgAAHfBBB+hB\/h9\/1zieRGhD8SjASBAAQsEED4LUCNK6R+c\/7CCy+Uk046SVQutRqvFf\/169fL+++\/LyrVKuzplx\/hV2HVQ\/A+\/\/xzGT9+vNklEPUVlfDruPr372+q+VrxV\/Evy+CXv\/yl6LkHej388MMyceLE0MKvsfRzgCNHjjS7CGrXrm361Z0Ur7zyivTu3Vv69OmD8EedOMSDAAR8EUD4EX6E39dPJbKbPOG\/YZzbFf6BXefdE7YAACAASURBVNdJdyr8ka07gSCQDwQQ\/nxYJcaYKAK6e4BT+hO15EwWApETQPgRfoQ\/8p9VpQER\/nh50xsEIOCfAMLvnxV3QiAWAgh\/LJjpBAIFTQDhR\/gR\/nh\/4p7w3\/ia2xX+Ad3WSfcWvMMfb3bQGwRySwDhzy1\/eodAOQIIP0kBAQiEJYDwI\/wIf9hfUXbtPeG\/6dXDZJ3Dh\/ad3m2dHNMS4c9udbkbAvlNAOHP7\/Vj9AVIAOEvwEVlShCImQDCj\/Aj\/PH+6BD+eHnTGwQg4J8Awu+fFXf+i8D9999vDqQLcqV\/Gi9I+yS0QfiTsMrMEQJ2CSD8CD\/Cb\/c3Vja6J\/w3v+x4hf+YddKtFRX+eLOD3iCQWwIIf27552XvxcXF5jN3Qa4lS5bIqFGjgjRNTBuEPzFLzUQhYI0Awo\/wI\/zWfl4ZA3vCf8tLhzq9pb9\/dxX+OXLGGWfEC4jeIACBnBFA+HOGno4hkJkAwk9mQAACYQkg\/Ag\/wh\/2V5Rde4Q\/O17cDQEIxEcA4Y+PNT1BwBcBhN8XJm6CAAQqIYDwI\/wIf7x\/RXjCf+uLh8q67\/eNt\/Mseut\/7DrpejAV\/iyQcSsE8p4Awp\/3S8gECo0Awl9oK8p8IBA\/AYQf4Uf44\/3dIfzx8qY3CEDAPwGE3z8r7oRALAQQ\/lgw0wkECpoAwo\/wI\/zx\/sQ94b\/t\/7ld4T9NK\/yHUOGPNzvoDQK5JYDw55Y\/vUOgHAGEn6SAAATCEkD4EX6EP+yvKLv2nvDf\/oLjwt9jnRx9KMKf3epyNwTymwDCn9\/rx+gLkADCX4CLypQgEDMBhB\/hR\/jj\/dEh\/PHypjcIQMA\/AYTfPyvuhEAsBBD+WDDTCQQKmgDCj\/Aj\/PH+xFPC\/\/tDnD6077Tj1lPhjzc16A0COSeA8Od8CRgABEoTQPjJCAhAICwBhB\/hR\/jD\/oqya+8J\/x3PuS38p\/50vRx9GFv6s1td7oZAfhNA+PN7\/Rh9ARJA+AtwUZkSBGImgPAj\/Ah\/vD86hD9e3vQGAQj4J4Dw+2fFnRCIhQDCHwtmOoFAQRNA+BF+hD\/en3i68K\/ftG+8nWfRm1b4uxxOhT8LZNwKgbwngPDn\/RIygUIjgPAX2ooyHwjETwDhR\/gR\/nh\/dwh\/vLzpDQIQ8E8A4ffPijshEAsBhD8WzHQCgYImgPAj\/Ah\/vD\/xlPA\/c4is31QUb+dZ9HZqz\/XS5d\/myhlnnJFFK26FAATymQDCn8+rx9gLkgDCX5DLyqQgECsBhB\/hR\/hj\/cmJJ\/x3Pu228PfrhfDHmxn0BoHcE0D4c78GjAACpQgg\/CQEBCAQlgDCj\/Aj\/GF\/Rdm1R\/iz48XdEIBAfAQQ\/vhY0xMEfBFA+H1h4iYIQKASAgg\/wo\/wx\/tXREr4nzrY6S39\/XptkC6t2dIfb3bQGwRySwDhzy1\/eodAOQIIP0kBAQiEJYDwI\/wIf9hfUXbtU8L\/O8eFv\/cG6dIG4c9udbkbAvlNAOHP7\/Vj9AVIAOEvwEVlShCImQDCj\/Aj\/PH+6BD+eHnTGwQg4J8Awu+fFXdCIBYCCH8smOkEAgVNAOFH+BH+eH\/invD\/9olWbm\/p77NBOrf5mlP6400PeoNATgkg\/DnFT+cQKE8A4ScrIACBsAQQfoQf4Q\/7K8quPcKfHS\/uhgAE4iOA8MfHmp4g4IsAwu8LEzdBAAKVEED4EX6EP96\/IlLC\/3grWb+xKN7Os+it3\/EbpHNbKvxZIONWCOQ9AYQ\/75eQCRQaAYS\/0FaU+UAgfgIIP8KP8Mf7u0sJ\/2MtHRf+jdK5HcIfb3bQGwRySwDhzy1\/eodAOQIIP0kBAQhAIFoCPAD5keeAIU2lVYdVUlxcHC3khEdD+BOeAEwfAg4TQPgdXhyGlkwCCH8y151ZQwAC9ggg\/Ai\/vez6Z+SU8D\/awu0Kf1+t8H\/DoX22E4L4EHCIAMLv0GIwFAgoAYSfPIAABCAQLQGEH+GPNqPKR0sJ\/8PN3Rb+n22Szu0Rftv5QHwIuEQA4XdpNRgLBBB+cgACEIBA5AQQfoQ\/8qQqExDht02Y+BCAQFACCH9QcrSDgCUCVPgtgSUsBCCQWAIIP8JvO\/lTwv9QHlT4O1Dht50PxIeASwQQfpdWg7FAgAo\/OQABCEAgcgIIP8IfeVJVVOFH+G2jJj4EIJAlAYQ\/S2DcDgHbBKjw2yZMfAhAIGkEEH6E33bOexX+ux5sJus3FNnuLnD8U07YJJ07zuPQvsAEaQiB\/COA8OffmjHiAieA8Bf4AjM9CEAgdgIIP8JvO+lSwv9AU7eF\/+ffI\/y2k4H4EHCMAMLv2IIwHAgg\/OQABCAAgWgJIPwIf7QZVT4awm+bMPEhAIGgBBD+oORoBwFLBBB+S2AJCwEIJJYAwo\/w207+lPCP1Qr\/Pra7Cxz\/FK3wHzGfLf2BCdIQAvlHAOHPvzVjxAVOAOEv8AVmehCAQOwEEH6E33bSpYT\/voPcFv5fbJbOP0H4becD8SHgEgGE36XVYCwQ4JR+cgACEIBA5AQQfoQ\/8qQqExDht02Y+BCAQFACCH9QcrSDgCUCVPgtgSUsBCCQWAIIP8JvO\/lTwn9vE7cr\/CdqhX8BW\/ptJwTxIeAQAYTfocVgKBBQAgg\/eQABCEAgWgIIP8IfbUaVj4bw2yZMfAhAICgBhD8oOdpBwBIBhN8SWMJCAAKJJYDwI\/y2kz8l\/GMaO17h3yKdj6TCbzsfiA8Blwgg\/C6tBmOBABV+cgACEIBA5AQQfoQ\/8qQqEzAl\/Pc0kvXrHT6l\/6Qt0rnTt2zpt50QxIeAQwQQfocWg6FAQAlQ4ScPIAABCERLAOFH+KPNqPLREH7bhIkPAQgEJYDwByVHOwhYIoDwWwJLWAhAILEEEH6E33byp4R\/dEO3K\/wnb5XOnf6PCr\/thCA+BBwigPA7tBgMBQJU+MkBCEAAAtETQPgR\/uizqnTElPCPauC28J+yTTofhfDbzgfiQ8AlAgi\/S6vBWCDAln5yAAIQgEDkBBB+hD\/ypCoTEOG3TZj4EIBAUAIIf1BytIOAJQJs6bcElrAQgEBiCSD8CL\/t5E8J\/11a4a9uu7vA8U\/RCn\/nhWzpD0yQhhDIPwIIf\/6tGSMucAIIf4EvMNODAARiJ4DwI\/y2kw7ht02Y+BCAQFACCH9QchG3KyoqkqFDh8qgQYOkYcOGsu+++8quXbtk4cKF8sYbb8jkyZPL9XjsscfK6NGjpU6dOhWORmNs2bJFvvrqK\/n9738v3377bcQjLx+uV69ecvbZZ0ubNm2kbt26Ur16ddm7d698\/\/33smDBAnnttddk2rRpGcdx2GGHyYMPPijNmzeXjz\/+WG688Ubf4x0xYoSce+65Zr633XZbhX34DpijGxH+HIGnWwhAoGAJIPwIv+3k9oT\/t3fWd7rC36\/fdunchQq\/7XwgPgRcIoDwO7Aa9evXN+Ku\/7KoVq1auRGptKvwP\/DAA1JSUpL6cz\/Cnx5s586dMmHCBHnqqaeszPrQQw+Vm266SY488kgj+RVdKv+zZs2Se+65R1auXFnqtkIQ\/lq1askll1wiyuO6667LmjXCnzUyGkAAAhColADCj\/Db\/omkhP+Oum4L\/6k7pHOXRWzpt50QxIeAQwQQfgcWQyV5wIABZiRz5syRJ554QmbPni1aKb\/sssukdevWorKu\/\/ytt97KKPzTp0+X119\/vdxsjjjiCOnevbt06NBBatSoIbt375Y\/\/vGP8vDDD0c687Zt28qYMWOkRYsW8sMPP8iKFStk0qRJ5kHFqlWrpGnTpnLKKadI\/\/79TfVeH2wsW7ZMbr31Vpk\/f35qLIUg\/Pfee6\/07dtX5s2bJxdeeGHWnBH+rJHRAAIQgADC7zMHBgxpKq06rJLi4mKfLbjNDwGE3w8l7oEABHJBAOHPBfW0PlWUdQt748aNZe7cuaYivGnTpowC\/OWXX8rll1+eUfir2v6uEqlb3uvVqycbN2401fVPP\/00ktnrDoWHHnpIOnbsaF5DmDhxojz22GOldiN4HemrCzfccIORf31tQR9w\/OY3v0nNOYzwRzKZCILcf\/\/90qdPH4Q\/ApaEgAAEIBAFASr8P1JE+KPIqPIxfhT+A2T9OncP7eunFf6jF1Pht5MGRIWAkwQQ\/hwvi1bxr7zySmnUqJG88sor8vLLL5cbkSeQWjW\/\/vrrZdGiReae9C39VQm\/3j98+HBzToCK9tSpUwNtN8+Ey4urMq+yf99991VKVe\/TBw4qxbrj4NVXX5XnnnvOtEH4Rajw5\/hHSfcQgEDBEUD4EX7bSZ0S\/ttquy38p+2Uzl2XIPy2E4L4EHCIAMLv0GJUNBTdAdCzZ0+zTT6M8Gt1\/+mnnzZSvWbNGhMrfTt9EBQaU1810AP6sonZrVs3GTVqlDRo0MAc5Ke7D3RnQ1nh19cC9IHCIYccYh5UbN26Vf72t7\/J888\/X+4AwqoO7dNXIy699FLp0qWLOehQXyuoLJ7HQx9QnHXWWTJw4EBp1qyZeTVCdzLo+QP6sELHqJceVKgPb\/TP069sDxFE+INkIm0gAAEIVEwA4Uf4bf8+EH7bhIkPAQgEJYDwByUXU7tOnTrJ3XffLU2aNClXlc+2wq9DvuOOO6Rfv36yfft2sw3\/3XffDTWTE044QW6++WYj0H52GaR39vjjj8sxxxwjmzdvljvvvNPML134lyxZYt79r1mzZrkxbtiwQcaOHStTpkxJ\/Vllwj948GDzOkRFXzTQhw364KIsD31dQR+46OsKmQ5UTD8TAeEPlUo0hgAEIGCNAMKP8FtLrn8FTgn\/rbXcrvD330WF33YyEB8CjhFA+B1bEG84Krp6kJ9+pk+r4JkEN4jwn3\/++TJs2DBTLdfqdNgT+8PE8wRdq+UvvPCCeZ0hXfiVhR5WqAf\/PfPMMwaNSrs+sNAq+uLFi81rCd5J\/xUJv+6O0MMBlaNW21XqX3zxRVOl11h6sJ6+UqGM9XN+M2fONH15rx707t3bHETofdrwiy++EH3QobsF9CT+bdu2mTML9HUGvXiH39EfFcOCAAQSSwDhR\/htJz\/Cb5sw8SEAgaAEEP6g5Cy2Uxlt165dqofvvvtOfve738knn3xSqtcgwp9ehdZT\/bWqHeZKl\/Ynn3zSfPbP75VpLOnCr0Kuoj9u3LhSIVXy9UGIfvpPH1p4DwMqEn79IsFxxx1nHh48++yz5eLpifp6kKA+EPjggw\/MLgi9VOpvueUWqV27ttm9oA8N0j+LmL77Iv1ARYTfbwZwHwQgAIF4CCD8CL\/tTEsJ\/837y\/p15T+xbLt\/v\/H7nb5bOnf7jnf4\/QLjPggUAAGE37FFLFvh1uFpdVk\/badb4NO3sBe68H\/zzTemip4u2cpD36NXFi1btpR00c4k\/Po5Qj1EUF+JmDFjhlx99dUZVzzTwYgab8iQIeY9f\/3U3kcffVSurZ5DoAcv6kMZ\/byirhPC79iPiuFAAAKJJ4DwI\/y2fwQp4b+ppuPCXyKdj1mK8NtOCOJDwCECCL9Di6FD0W3kBx98sBFI3Wau2831E3b6HrtuOdfT7T\/77DMz6kIX\/nfeeafCE\/+9gwyXL18u1157rSxdutQc\/Hfuueeabfu6NX\/atGnmxHv97N\/+++8vle1o0AcLF1xwgTnbwJP7TH34SReE3w8l7oEABCAQHwGEH+G3nW0Iv23CxIcABIISQPiDkouxnVaZ9d11fW89fct5EOEvLi42n+bbu3evvPTSS+a0+zCXJ8oaI9t43lj04LtM7\/BXJugVVeTLCn9FB+lVNGd9jcB7NcF7tWLevHnmwYvfKwrh1wcWRUUrS3XZstWZfofAfRCAAAQgkEYgycI\/YEhT+ekvDkzRaNSkhsyaNUv038Fc0RHwhP\/OG2u4XeEfUCJdjllGhT+6pScSBJwngPA7v0Qi6Z\/TW7RokVxxxRXmE3ZBhN+T0Xw4pT\/Jwv\/b3w6T+g3+o1R21qnzpzzIVoYIAQhAwD0CSRb+dkfWkQOb\/Pi52J4\/P1C2lSxA+CNO05Tw31Ak69c6\/A7\/wD3SpftyhD\/i9SccBFwmgPC7vDppY\/OqzStWrJDrr79eVPyzFf70d9\/T44RBoA8j9OC\/Nm3ayJo1a8zY5s+fX2VI\/Rfj6NGjzUF5CxYsMNvx9SFG+hkGlW3p9z7pp68+jBw50rw7n2lLv36Oz3tv\/+mnn5bx48dXOTbvBq+P9NcG\/DSOosKvwk9F3w9t7oEABCBQNYEkC39ZOlrxb9VhFcJfddpkdQfCnxUuboYABGIkgPDHCDtTV7ol\/pxzzhHd1v7AAw9kPBguXYLnzp1rPqunV7bCP3z4cLOdXz\/Jl\/5qQFgEXlw9f0C\/JFD2NPuy8dM\/d6cH8ulJ+88995y5LX2u6QfypcdIf3CRfhBfJuE\/6qijzDv5ZU\/g9zNnPYRv4MCB5tC+MWPGZFwbXT9lqg8rdP10\/gi\/H7rcAwEIQCA+Agj\/j6wRfjt5lxL+f99H1q+100cUUfsN3Ctdjl1BhT8KmMSAQJ4QQPhzvFADBgww35LXQ\/kyffpNh5f+Gbo333xTHn300ayFXw+vUyHWinzZ782HRaAxH3roITniiCPMg4vJkyfL2LFjy52ur\/2o7Osn8PQgQn3woA8w9FC9jRs3lhP+st+398apuwj0s3z6sEDPIHjttdfMH1X0Wb6nnnpKunTpYuat40r\/0oE3Jj0MsUePHuYeFfapU6dW+Vm++vXryyOPPCLt27c3hyx6Ow084U9\/\/SIbxrpWVPizIca9EIAABCongPAj\/LZ\/Iynhv17cFv5BIl2OXYnw204I4kPAIQIIf44Xo6wsq2jqAXa6Lb5t27ammq8iqgf2LV682Mj\/ypX\/PMwtvcI\/ffp0cwp9+qVyrRXu7t27y+GHH24EWw+l8w7Ii3LqOlaVZv1Unn5GUF8ZmDRpkpF\/3W7ftGlTI\/n9+\/eX5s2bS7Vq1WTZsmVmN0D6KwBlP0uoJ+7\/4Q9\/MLsA9NN6F198sRx\/\/PGGx5w5c8zDAq2uVyb8ffv2NQ8ZtMqvDxYmTpwo48aNM\/+9W7ducskll8iRRx4p1atXF+WoMfVhQvpOBJ3TzJkzzQOG2bNnm3aXXXaZecih9+oY9dUGvXRHgfapDw\/uuusu87WAbC6EPxta3AsBCECgagIIP8JfdZaEuwPhD8eP1hCAgD0CCL89tr4jqyzfeeedRsoruhYuXGjkMV2O04XfT2daMdeHAir8Ni7daq8Cr9V0leeKLv1CgJ4QrA8IvIcX3r3pwv\/FF18YEdfdD2WvTDwqqvBrWz2tXwW9Vq1aGYelQq+n8StjfbDiXVrF18\/zdezY0TykKHvpXHQbv56qr+Kvlz6U0FP99QGLXvqQRc8DeOutt3xhR\/h9YeImCEAAAr4JIPw\/omJLv++0yepGT\/jv+M1epyv8pw6qJl16rKLCn9XqcjME8psAwu\/I+qmIqiSedNJJ0rBhQyOLuj1+\/fr18v7774se2qfCnn75EX6VTa2Af\/755+bAunSZtTV1Hdd5551nDvKrW7eukX+di1brv\/rqK3n77bcrrHqnC78+nNBt8RdccEFqV4BW5T\/88EPRA\/jK8qhM+HWurVu3Fn3nXh9I1KlTxwi88lm9erXZiaBV\/7IxtZ1W+vU9fX2NwFsbbacPK3Tnge5kSL\/0\/ttvv93sRNCHFXv27Mnqk4UIv63MJC4EIJBUAgg\/wm879xF+24SJDwEIBCWA8AclRzvnCFQl\/M4NuIIBIfz5slKMEwIQyBcCCD\/CbztXU8J\/XYnbFf5fVpcuPf5Bhd92QhAfAg4RQPgdWgyGEo6AJ\/y6o0G32OsrAfl4Ifz5uGqMGQIQcJkAwo\/w287PlPBfs0vWr\/3BdneB4596xj7S5bg1CH9ggjSEQP4RQPjzb80YcRoB3T6vZwfo+\/N6WF67du1k+fLlcu2118rSpUvzkhXCn5fLxqAhAAGHCSD8CL\/t9ET4bRMmPgQgEJQAwh+UHO2cINChQwe57777zAn+eunhe3\/+85\/N4Xv5eiH8+bpyjBsCEHCVAMKP8NvOzR+Ff4esW+Nyhb9Ijv7pWir8thOC+BBwiADC79Bi5GIo3jfjg\/Stp9rrQYO5vPQzfyNHjjSH8OlBevpZQ30AoIf75euF8OfryjFuCEDAVQIIP8JvOzdTwj9yq9vCP7iGHP3TdQi\/7YQgPgQcIoDwO7QYuRhKcXGxdO3aNVDXS5YskVGjRgVqS6OKCSD8ZAcEIACBaAkg\/Ah\/tBlVPhrCb5sw8SEAgaAEEP6g5GgHAUsEEH5LYAkLAQgklgDCj\/DbTn5P+G+\/erOsW7PXdneB4582uKYc3XMDFf7ABGkIgfwjgPDn35ox4gIngPAX+AIzPQhAIHYCCD\/CbzvpEH7bhIkPAQgEJYDwByVHOwhYIoDwWwJLWAhAILEEEH6E33byp4R\/xCa3K\/xn7idH99xIhd92QhAfAg4RQPgdWgyGAgElgPCTBxCAAASiJYDwI\/zRZlT5aCnhv2q948JfS47utQnht50QxIeAQwQQfocWg6FAAOEnByAAAQhETwDhR\/ijz6rSERF+24SJDwEIBCWA8AclRzsIWCJAhd8SWMJCAAKJJYDwI\/y2k98T\/tuuXCvr1uyx3V3g+KedVVu69tpMhT8wQRpCIP8IIPz5t2aMuMAJIPwFvsBMDwIQiJ0Awo\/w2066lPAX\/8Nx4T9AuvbegvDbTgjiQ8AhAgi\/Q4vBUCCgBBB+8gACEIBAtAQQfoQ\/2owqHw3ht02Y+BCAQFACCH9QcrSDgCUCCL8lsISFAAQSSwDhR\/htJ78n\/LdesdLpCn\/\/s+tK195bqfDbTgjiQ8AhAgi\/Q4vBUCBAhZ8cgAAEIBA9AYQf4Y8+q0pHRPhtEyY+BCAQlADCH5Qc7SBgiQAVfktgCQsBCCSWAMKP8NtO\/h+Ff7msW11iu7vA8fufXU+69tlOhT8wQRpCIP8IIPz5t2aMuMAJIPwFvsBMDwIQiJ0Awo\/w2046T\/hvufw7t4X\/nAbSrc8OhN92QhAfAg4RQPgdWgyGAgElgPCTBxCAAASiJYDwI\/zRZlT5aIUs\/EVFRTJ06FAZNGiQNGzYUPbdd1\/ZtWuXrFy5Ul599VWZNGmSbbzEhwAEQhBA+EPAoykEbBBA+G1QJSYEIJBkAgg\/wm87\/1PCf9liWbd6t+3uAsfvf05D6Xb8Lt8V\/vr168vo0aNF51dSUiKrV6+WTZs2SZMmTeTAAw+U3bt3y3\/+53\/Ko48+GnhMNIQABOwSQPjt8iU6BLImgPBnjYwGEIAABColgPAj\/LZ\/Ip7w3zx8odPCf\/qvDpRux+\/2LfzDhw831f1t27bJE088Ie+++65BqVX\/a665RgYMGGCq\/WPGjJGPPvrINmbiQwACAQgg\/AGg0QQCNgkg\/DbpEhsCEEgiAYQf4bed94Uo\/Cr1zz\/\/vLRv317+67\/+y0h9+lWvXj3zEKBNmzby3nvvyahRo2xjJj4EIBCAAMIfABpNIGCTgCvCv2NHF1m75lZp2epMm9PNm9glJc1k1conpGmzEVJUtDJvxm1zoMuWvimNGt8j++03y2Y3eRN71crfSZ0D\/iR16vwpb8Zsc6D694demiO5vlwQ\/gFDmsqBB9WU\/\/fokpzi0HG06rBKiouLczqOQus8JfyXLnC8wt9YuvUt8VXhb9WqlZH85s2by7PPPisTJkwot2z333+\/9OnTRz7++GO58cYbC21ZmQ8ECoIAwl8Qy8gkComAS8KvAnPoYT0LCW\/guajwq+DqAxCE\/58YFy\/6TJo2uwrh\/1dWaX7Ub\/AfCP+\/eOjfH\/pbQfj\/CeSiaw6RRk1qyAO3LAj891AUDRH+KCiWj1GIwl8VqfQdAFOmTJGbb765qib8OQQgkAMCCH8OoNMlBCojgPC7mR8If\/l1QfhLM0H4S\/NA+EvzQPjd\/Ls9qlF5wn\/TJfNk3epdUYWNPM7pQ5rIMX33+qrwV9W5vr8\/cuRI2WeffczW\/9dee62qJvw5BCCQAwIIfw6g0yUEEP78ywGEH+GvKmsRfoS\/shxB+Kv6BeX3n6eEf9gcx4W\/qRzzMwkt\/G3btjXb\/Vu0aCHffvutjBgxQjZu3Jjfi8joIVCgBBD+Al1YppW\/BLTCf9tttzmxTVrf4+f97B9zCR6lf1fKQ7dsFxWtyt8fXIQjh0dpmCUlTc0\/cCE\/vpzRJsKVDhbqwINqmC39877aEixARK10HEuXz+Ed\/oh4emE84c\/1+lY1rUYH1ZBde9aFEv5mzZqZT\/V17NhRNmzYIGPHjhXd0s8FAQi4SQDhd3NdGFWCCej\/aejSpUuCCTB1CEAAAhCwSWDVqlWpz6vZ7CdJsVWCTz311LyZ8gsvvBBorIceeqg5jV9P5t+0aVOpT\/UFCkgjCEDAOgGE3zpiOoAABCAAAQhAAAIQgEB+EzjmmGPMSfy6jV8r+48++qi8\/\/77+T0pRg+BBBBA+BOwyEwRAhCAAAQgAAEIQAACQQmcdNJJcs0110iDBg1k5cqVcu+998qMGTOChqMdBCAQIwGEP0bYdAUBCEAAAhCAAAQgAIF8ItC3b1+54YYbjOwvXLhQ7rrrLpk\/f34+TYGxQiDRBBD+RC8\/k4cABCAAAQhAAAIQgEBmAnqukB7Qp7I\/d+5cc6iwVvi5IACB\/CGA8OfPWjFSCEAAAhCAAAQgAAEIxEKgqKjIHMrXuXNnWb58udxyyy1U9mMhTycQiJYAwh8tT6JBAAIQgAAEIAABCEAg7wmccMIJRvJr165d5Vw+\/vhjc6AfFwQg4B4BhN+9NWFEEIAABCAAAQhAAAIQyCmB4uJiGTp0qFSrVq3KcSD8VSLiBgjkjADCnzP0dAwBCEAAAhCAAAQgAAEIQAACELBHAOG3x5bIEIAABCAAAQhAAAIQgAAEIACBnBFA+HOGno4hAAEIQAACEIAABCAAAQhAAAL2CCD89tgSGQIQgAAEIAABCEAADT1+eAAABZtJREFUAhCAAAQgkDMCCH\/O0NMxBCAAAQhAAAIQgAAEIAABCEDAHgGE3x5bIkMAAhCAAAQgAAEIQAACEIAABHJGAOHPGXo6hgAEIAABCEAAAhCAAAQgAAEI2COA8NtjS2QIQAACEIAABCAAAQhAAAIQgEDOCCD8OUNPxxCAAAQgAAEIQAACEIAABCAAAXsEEH57bIkMAQhAAAIQgAAEIAABCEAAAhDIGQGEP2fo6RgCEIAABCAAAQhAAAIQgAAEIGCPAMJvjy2RIQABCEAAAhCAAAQgAAEIQAACOSOA8OcMPR1DAAIQgAAEIAABCEAAAhCAAATsEUD47bElMgQgAAEIQAACEIAABCAAAQhAIGcEEP6coadjCEAAAhCAAAQgAAEIQAACEICAPQIIvz22RIYABCAAAQhAAAIQgAAEIAABCOSMAMKfM\/R0DAEIQAACEIAABCAAAQhAAAIQsEcA4bfHlsgQgAAEIAABCEAAAhCAAAQgAIGcEUD4c4aejiEAAQhAAAIQgAAEIAABCEAAAvYIIPz22BIZAhCAAAQgAAEIQAACEIAABCCQMwIIf87Q0zEEIAABCEAAAhCAAAQgAAEIQMAeAYTfHlsiQwACEIAABCAAAQhAAAIQgAAEckYA4c8ZejqGAAQgAAEIQAACEIAABCAAAQjYI4Dw22NLZAhAAAIQgAAEIAABCEAAAhCAQM4IIPw5Q0\/HEIAABCAAAQhAAAIQgAAEIAABewQQfntsiQwBCEAAAhCAAAQgAAEIQAACEMgZAYQ\/Z+jpGAIQgAAEIAABCEAAAhCAAAQgYI8Awm+PLZEhAAEIQAACEIAABCAAAQhAAAI5I4Dw5ww9HUMAAhCAAAQgAAEIQAACEIAABOwRQPjtsSUyBCAAAQhAAAIQgAAEIAABCEAgZwQQ\/pyhp2MIQAACEIAABCAAAQhAAAIQgIA9Agi\/PbZEhgAEIAABCEAAAhCAAAQgAAEI5IwAwp8z9HQMAQhAAAIQgAAEIAABCEAAAhCwRwDht8eWyBCAAAQgAAEIQAACEIAABCAAgZwRQPhzhp6OIQABCEAAAhCAAAQgAAEIQAAC9ggg\/PbYEhkCEIAABCAAAQhAAAIQgAAEIJAzAgh\/ztDTMQQgAAEIQAACEIAABCAAAQhAwB4BhN8eWyJDAAIQgAAEIAABCEAAAhCAAARyRgDhzxl6OoYABCAAAQhAAAIQgAAEIAABCNgjgPDbY0tkCEAAAhCAAAQgAAEIQAACEIBAzggg\/DlDT8cQgAAEIAABCEAAAhCAAAQgAAF7BBB+e2yJDAEIQAACEIAABCAAAQhAAAIQyBkBhD9n6OkYAhCAAAQgAAEIQAACEIAABCBgjwDCb48tkSEAAQhAAAIQgAAEIAABCEAAAjkjgPDnDD0dQwACEIAABCAAAQhAAAIQgAAE7BFA+O2xJTIEIAABCEAAAhCAAAQgAAEIQCBnBBD+nKGnYwhAAAIQgAAEIAABCEAAAhCAgD0CCL89tkSGAAQgAAEIQAACEIAABCAAAQjkjADCnzP0dAwBCEAAAhCAAAQgAAEIQAACELBHAOG3x5bIEIAABCAAAQhAAAIQgAAEIACBnBFA+HOGno4hAAEIQAACEIAABCAAAQhAAAL2CCD89tgSGQIQgAAEIAABCEAAAhCAAAQgkDMCCH\/O0NMxBCAAAQhAAAIQgAAEIAABCEDAHgGE3x5bIkMAAhCAAAQgAAEIQAACEIAABHJGAOHPGXo6hgAEIAABCEAAAhCAAAQgAAEI2COA8NtjS2QIQAACEIAABCAAAQhAAAIQgEDOCCD8OUNPxxCAAAQgAAEIQAACEIAABCAAAXsEEH57bIkMAQhAAAIQgAAEIAABCEAAAhDIGQGEP2fo6RgCEIAABCAAAQhAAAIQgAAEIGCPwP8H0ygqfotqYzMAAAAASUVORK5CYII=","height":319,"width":530}}
%---
%[output:075ee2ce]
%   data: {"dataType":"text","outputData":{"text":"Found solution after 1 attempt(s): 5 9 47 79 34 42 57 59 12 72 60 82 66 31 93 21 55 26 43 13 27 18 65 83 37 30 14 61 35 81 6 89 62 76 3 17 95 88 90 22 80 68 74 96 48 45 15 63 24 46 58 33 71 1 7 39 29 51 4 67 23 32 16 86 10 49 92 70 50 64 78 44 91 56 87 38 19 69 53 28 40 77 11 84 52 36 85 2 41 54 73 25 8 75 94 20\n","truncated":false}}
%---
%[output:78dd0835]
%   data: {"dataType":"text","outputData":{"text":"Order effects table for View_x_Category:\n","truncated":false}}
%---
%[output:5faf67b1]
%   data: {"dataType":"text","outputData":{"text":"     2     2     3     3     3     3\n     3     2     3     2     3     2\n     2     3     2     3     3     3\n     2     3     3     2     3     3\n     3     3     2     3     2     3\n     3     3     3     3     2     2\n\n","truncated":false}}
%---
%[output:2a1da4de]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAAA\/wAAAJmCAYAAADhK4tqAAAAAXNSR0IArs4c6QAAIABJREFUeF7s3Qt4VNW99\/E\/5CYJkoRAJCAUkQRIEGkqKi8vHEqPtNZTpO0pXkotjxdEeBGq3EEoCAgKFESsFPFWqIJHQZDSgwdeX6xtOVCt1KIgglowCAhEQwJJlPdZuyc0kTCzZ\/Lfe9bM\/s7z+PSStf977c9aM85v1r40at68+RnhhQACCCCAAAIIIIAAAggggAACCSXQiMCfUOPJwSCAAAIIIIAAAggggAACCCDgCBD4mQgIIIAAAggggAACCCCAAAIIJKAAgT8BB5VDQgABBBBAAAEEEEAAAQQQQIDAzxxAAAEEEEAAAQQQQAABBBBAIAEFCPwJOKgcEgIIIIAAAggggAACCCCAAAIEfuYAAggggAACCCCAAAIIIIAAAgkoQOBPwEHlkBBAAAEEEEAAAQQQQAABBBAg8DMHEEAAAQQQQAABBBBAAAEEEEhAAQJ\/Ag4qh4QAAggggAACCCCAAAIIIIAAgZ85gAACCCCAAAIIIIAAAggggEACChD4E3BQOSQEEEAAAQQQQAABBBBAAAEECPzMAQQQOCswZMgQMf9s27ZNxo8fj0yEAh07dpQRI0ZIUVGRNG3aVBo1aiQVFRWyf\/9+eeqpp+S1116LsGJwm\/fu3duZi8Y0NTVVqqqq5NixY7Jp0ybHsry8PLg4DTzyrKwsmT9\/vhQWFsrWrVt5r0fgecUVV8jMmTMlMzMz5Fa\/+c1vZPHixRFUDmbT5ORkGTx4sFx33XWSm5vrvNcrKyulpKREVqxYIS+\/\/HIwYThqBBBAQFGAwK+ISSkE4lmgoKBA5syZI3l5eYSAKAZy0KBBcuedd0p6enq9W5svsWvWrJGFCxdGUT1YmwwfPlxuuOEG58v\/V19nzpyR3bt3y\/Tp0+WDDz4IFozS0U6YMEEGDBjg\/CBF4I8M1bzPzY969c3N2pUI\/OFdzQ9P5seT4uJiZy5+9cVnZnhDWiCAAAJuBAj8bpRog0CCC5iwP3v2bGnTpo1zpISAyAa8V69eMnnyZMnOzpYTJ07IunXr5Nlnn3VWqq699lpnpbpFixZy+vRpZ9XvhRdeiGwHAWrdv39\/GTt2rHOGxNGjR+WJJ56Q9evXy8UXXyy333679OnTR8yqoJmjJrjyikzghz\/8oYwcOVLS0tJ4r0dG57QePXq082OUmZtLliyR48eP11vlww8\/lEOHDkWxh+BsYn5gNu9n8\/rb3\/7mfDbu2rVLvve978mtt97qfGaWlZXJQw895JzZwwsBBBBAIDoBAn90bmyFQMII9O3bV372s585p1PWvAj8kQ3vjBkz5Jprrjnvl1NjPG7cOOcHgbfeekuGDRsW2Q4C1HrBggXSs2dP54eTWbNmye9\/\/\/s6Rz937lwnJJigNXHiRMeTlzuBmh\/2WrduLeZMicaNG\/Pjnju6s63mzZsn5ge+9957zwml1dXVEVaguRHo16+fTJo0STIyMuS\/\/\/u\/5d57761jWfuHP\/59xJxBAAEEGiZA4G+YH1sjELcC5tR9s1p19dVXO6enHj582PlPc5olX7DcD2urVq1k0aJF0q5du5Bh\/uGHH5YePXrIxx9\/LGPGjHGu6+dVVyAnJ8c5U6Jbt27Oit+oUaPOIao5pdr8waywrl69GkYXAuasCPMDirk3wvvvv+9cg96yZUve6y7sapoYs1\/+8pdyySWX4BaBW31Np06d6pz9ZH64M\/99x44ddZqZ+Wre3507d5Z3333X+VGa+3Y0EJ3NEUAgsAIE\/sAOPQcedAFzWu\/NN9\/snHb+pz\/9SVatWuWELbP6R+B3Pzu6du0q06ZNc86Q2Lx5s5jV\/vpeNSvTBH73tvW1vPHGG+Wuu+5y\/kTgd29Zc0NOE5qMm1md5r3u3s+07NKli3OfE\/NDibmh3KOPPhpZAVo7ArV\/ONm+fbvcfffdyCCAAAIIeChA4PcQl9II2CxgQpNZcX7yySedu8ebVStzuiohQH\/UzGrVsmXLnNWqjz76yFm55vreyJ2No7m7\/JVXXilHjhxxzpTYs2dP5IUCtkXNPSbMfRFMUH3llVd4r0cxB8yd5M2p5+b13HPPSffu3Z0nHZj7IZgfTvfu3cvTOFy4Xn755fLAAw84lzhxc0MXYDRBAAEEGihA4G8gIJsjkCgCBH7vRrL2nb1N2DKnsPJyL2CefGCu27\/pppskPz\/fudZ37dq1Yq735xVa4KuP4DNn8bRt25bAH8XEueOOO+SnP\/2pc0d5cw+EpKSkc6pwZ\/nwsOb6fXP\/DXMJmTnb5I033nB+BL3sssvO\/njCY\/nCO9ICAQQQcCtA4HcrRTsEElyAwO\/NANd+AoK5T8J9990nO3fu9GZnCVi15tKTmkMzd+1+\/vnnnbv3c8O08AN+zz33yMCBA517dJibpJkzInivh3err4VZlTY34DQv4\/nMM8\/Ixo0bneBqfowyjzo0P7CYp3EsXbrUeVIHr3MFat+Hw1wGZe4rYc4++eqLH0+YPQgggICOAIFfx5EqCMS9ACFAfwhN2Dc3SjOPlCMEROdbc++D2lufPHlS1qxZ44QqQv\/5XWvudJ6SklIngPJej24umsfGFRUVybFjx87+eFK7Uu2ncZi7+Jsfq0pLS6PbWQJvVRP4zbw0Z0qcOnVKfvvb38ry5cvPPsr0lltuce6LwudmAk8EDg0BBHwTIPD7Rs2OELBbgBCgOz41N\/MzYd+sVJmbInKTr8iNzennn3\/++TlBoKqqylnpNyGM17kC5v1snl9ec0+OCRMmnG3Ee927GVP7EZ3mjIAtW7Z4t7M4rVz7EqfzBXrzpI7777\/fCf38eBKnA023EUDAGgECvzVDQUcQiK0AIUDP36z0mcdI1axQrVy50rlpH6+GC5izJsyd0s1jJQ8cOODc4dtc78vrnwK1H8H34Ycfijmtv7YR73XvZkvtp0iYR\/iZm\/vxqitQO\/Cby5tGjBhR75k65keq66+\/3jlLYsqUKec8ug9XBBBAAAF3AgR+d060QiDhBQgBOkP84x\/\/2HnkmbnRnLne\/LHHHpMXXnhBpzhVHIGaIGB8WUU9d1LUfi+7nTLG0oSqbdu2ud2EdvUI1L4+3Zyibq7z51VXwDw1Yvr06ZKRkRHyEbDmtP7bbrtNvvjiC+fpHBs2bIASAQQQQCAKAQJ\/FGhsgkAiChD4Gz6qw4cPlxtuuMG5idfx48dl4cKFsmnTpoYXpkIdgZob+ZlLJcxdvlevXo1QLQECvzfTwZw5Ya7h\/+STT877WM2aO\/mbkPrwww\/zY189Q9GlSxfnLB1zBtTWrVtl\/Pjx9Q5YjWVFRQU\/7HkzpamKAAIBESDwB2SgOUwEwgkQ+MMJhf577bBvTjU3K1hvv\/12w4oGbOvi4mJnlTknJ0fWr1\/vPDquvlfNjfw41Te6CcJ7PXK3q666SmbOnOncTT5USDWPiuzZs6fzg5959Nxbb70V+c4CsIU58+nyyy8PeVlOzf0QzBMRzFk977zzTgBkOEQEEEBAX4DAr29KRQTiUoAQEP2w1dwN3YSBgwcP1nsH7+irB2dLc12+WRU1Nzo015ybL\/nmMXK1X7XvhL5r1y7n+nTuhB7ZHOG9HpmXaZ2ZmencIDI\/P98J8+aHKfP8+Nov82i+O++803mW\/B\/\/+EdnbvKqX2Do0KEyePBg549r164V80PJ+d7nWDKLEEAAgYYJEPgb5sfWCCSMACEguqGsHQTM4+KefPJJ2bt373mLmbvLv\/vuu1JeXh7dDhN8K3O6\/o9+9CMxj+z64IMPHE9zp3PzY0rtZ50bv0WLFsm6desSXET\/8HivR2c6ZMgQMf+YQH\/06FF56qmnZOPGjc4lPOZa8+9+97vOvTvO94NAdHtNzK2ysrKc6\/ILCwudJ3Bs3rzZud+BWc2\/9tprHecWLVo4P+aZ0\/9fffXVxITgqBBAAAEfBAj8PiCzCwTiQYAQEN0o1b7jtJsK3BwttJK5Tnrq1KliVvJN6K\/vxc0Q3cy087fhvR6dn5mbY8eOle985ztOyK\/vxb073NuaJ25MmzZNOnToUO9G5pF9POHEvSctEUAAgfMJEPiZGwgg4AgQAqKbCDU3kHO7NYHfnZQJVeYGiCYMmHB15swZ56kHb775pvOIw1BnUbjbQ3Bb8V5v2NjXzM2vfe1r0qRJk7Nz0zzh4NFHH+UxkRHwmjMihg0bJv\/yL\/\/irOg3btxYTNA3l+s8\/fTTPDUiAkuaIoAAAgR+5gACCCCAAAIIIIAAAggggAACARJghT9Ag82hIoAAAggggAACCCCAAAIIBEeAwB+cseZIEUAAAQQQQAABBBBAAAEEAiRA4A\/QYHOoCCCAAAIIIIAAAggggAACwREg8AdnrDlSBBBAAAEEEEAAAQQQQACBAAkQ+AM02BwqAggggAACCCCAAAIIIIBAcAQI\/MEZa44UAQQQQAABBBBAAAHPBZKTk2Xw4MHy\/e9\/33nkYqNGjZxHq\/L4Ss\/p2QEC5wgQ+JkUCCCAAAIIIIAAAgggoCJgwv7UqVOlb9++Tr2DBw\/K6dOn5eKLL5aMjAw5cOCATJ48Wfbs2aOyP4oggEBoAQI\/MwQBBBBAAAEEEEAAAQRUBAYMGCCjRo2SpKQkWbp0qTz77LNO3fbt28uMGTMkPz9ftm7dKuPHj1fZH0UQQIDAzxxAAAEEEEAAAQQQQAABHwQWLFggPXv2lO3bt8vdd99dZ4+33HKL3HbbbfLpp5\/KmDFjZN++fT70iF0gEGwBVviDPf4cPQIIIIAAAggggAACKgI5OTkya9YsufTSS2X16tWybNmyOnUHDRokI0aMkIqKCpkyZYrs2LFDZb8UQQCB8wsQ+JkdCCCAAAIIIIAAAggg4LmAOaX\/mmuukffee09GjhwppaWlnu+THSAQdAECf9BnAMePAAIIIIAAAggggICHAgUFBc6p\/FdffbWcOXOmzrX9Hu6W0gggICIEfqYBAggggAACCCCAAAIIqAt06NBB5s2bJ3l5eU7tkydPyjPPPOP8wwsBBPwRIPD748xeAi5w3XXXnSNgfuE2z6WN1Yv94x\/U+WfmvnnF6vjZP\/7Mv9i8\/2reew31f+ONN6SkpET9X9\/1fVfQ3ElDj3\/Dhg0Rd6e4uNi5cd8XX3whubm5Yq7xr6qqkt\/97nfy0EMPSXV1dcQ12QABBCITIPBH5kVrBKISePHFFyUlKafOtibq\/+Nrb2xeX91\/i9xUpyNHD1f60iHbjl\/7oI1nKEtbjr9V60+1D91lPfcC1dV5kpys+eW65oe2WL0DY7d\/Y2leycmHYvgJFLvj\/8fk1Nt\/dHNTb\/8u32xfaWbn\/qOzjFSg9o\/s0b3\/TT8ff\/xxWb58eaQ7D9t+yZIlcuWV\/3iPevOK7vhrPjfMnfcb8kpOTpbRo0eLeWzfl19+6dzQb+XKlQ0pybYIIOBCgMDvAokmCDRUwAT+jasq5Q+bjzW0lGfbd7qsqYydnS+3f+9Nz\/YRpMJzlhfJut+UWD3mZjz+6+3\/Y\/2wnDh+q5w6VSyt8uzvq+2Y5ov7gb\/\/h1zc9t+Vf0Sx\/ci96Z+xbNr0t5KV\/YQ3OwhQ1Xh5nx8qeUQeeeTPngX+ft\/6i3Xz6VTF1+VQyWLnUXsNfZnQb37Y6Natm7z11lsybNiwhpZkewQQCCNA4GeKIOCDAIHfB2TLdkHg1xuQeAkCekfsXSUCv64tgV\/PM17e554H\/n5\/kaysJ\/VgFSqdOvV1OXToYZXAb7ozYcIEuf7662X37t0yZMgQhR5SAgEEQgkQ+JkfCPggQOD3AdmyXRD49QYkXoKA3hF7V4nAr2tL4NfzjJf3OYE\/9Jiba\/anTZsmGRkZ8otf\/ELqu+5\/6tSpcu211xL49d4+VEIgpACBnwmCgA8CBH4fkC3bBYFfb0DiJQjoHbF3lQj8urYEfj3PeHmfex34v\/nNtyQr6yk9WIVKp051l08+WeRqhb9Vq1ayaNEiadeunbzyyitiwn3tV1ZWlixevFg6duxY798VuksJBBD4igCBnymBgA8C8RD4c3JTZewD+TLhtr\/5IJL4uzD3Q3h986dcw68w1GVl35Wyz7\/LNfwKlqbEgb+\/4Fjq3ghRqXNxVsaEvwsueMO6a67jjNHpbry8zwn84WeXuTHfv\/\/7v0tZWZkT7mtW+dPT053V\/969e8uJEydk1qxZ8vrrr4cvSAsEEGiQAIG\/QXxsjIA7gXgI\/O6OhFaJJhAPN+1LNHOOBwEE4lfA+8C\/U7Iyn7YKyFnhP\/wLVyv8puNmFd+s7F999dXOY\/cOHjwoFRUVkpeX5\/ytvLxcli5dKqtXr7bqOOkMAokqQOBP1JHluKwSIPBbNRx0ppYAgZ\/pgAACCLgXIPC7szJ34x88eLB8\/\/vflxYtWkjjxo3l5MmT8s477zin\/O\/du9ddIVohgECDBQj8DSakAALhBQj84Y1oERsBAn9s3NkrAgjEp4Dngb\/vXyWzmWUr\/Kcvl8NH3K\/wx+fI0msEEleAwJ+4Y8uRWSRA4LdoMOhKHQECPxMCAQQQcC9A4HdvRUsEELBDgMBvxzjQiwQXIPAn+ADH8eER+ON48Og6Agj4LuB54P8Xs8L\/jO\/HFWqHp8wK\/9EFrq\/ht6rzdAYBBITAzyRAwAcBAr8PyOwiKgECf1RsbIQAAgEVIPAHdOA5bATiWIDAH8eDR9fjR4DAHz9jFbSeEviDNuIcLwIINETA68Dft8\/bknnhrxvSRfVtT1deLoc\/nccKv7osBRHwR4DA748zewm4AIE\/4BPA4sMn8Fs8OHQNAQSsEyDwWzckdAgBBMIIEPiZIgj4IEDg9wGZXUQlQOCPio2NEEAgoALeB\/6\/SWZT21b4u8nhY6zwB3TKc9gJIEDgT4BB5BDsFyDw2z9GQe0hgT+oI89xI4BANAIE\/mjU2AYBBGIpQOCPpT77DowAgT8wQx13B0rgj7sho8MIIBBDAc8Df++\/SWbGihge4bm7Pl3ZTQ6feIhr+K0aFTqDgHsBAr97K1oiELUAgT9qOjb0WIDA7zEw5RFAIKEECPwJNZwcDAKBECDwB2KYOchYCxD4Yz0C7P98AgR+5gYCCCDgXsDzwP+\/d0kz21b4q7rJkRMPssLvfprQEgGrBAj8Vg0HnUlUAQJ\/oo5s\/B8XgT\/+x5AjQAAB\/wQI\/P5ZsycEENARIPDrOFIFgZACBH4miK0CBH5bR4Z+IYCAjQKeB\/5eu6RZ+kqrDv20WeH\/bC4r\/FaNCp1BwL0Agd+9FS0RiFqAwB81HRt6LEDg9xiY8gggkFACBP6EGk4OBoFACBD4AzHMHGSsBQj8sR4B9n8+AQI\/cwMBBBBwL+B94H9HmjWxbYX\/MjnyOSv87mcJLRGwS4DAb9d40JsEFSDwJ+jAJsBhEfgTYBA5BAQQ8E2AwO8bNTtCAAElAQK\/EiRlEAglQOBnftgqQOC3dWToFwII2CjgeeD\/X+9Iswt+Y9Whn66+TI6UzeEafqtGhc4g4F6AwO\/eipYIRC1A4I+ajg09FiDwewxMeQQQSCgBAn9CDScHg0AgBAj8gRhmDjLWAgT+WI8A+z+fAIGfuYEAAgi4F\/A88Pd8184V\/pMPsMLvfprQEgGrBAj8Vg0HnUlUAQJ\/oo5s\/B8XgT\/+x5AjQAAB\/wQI\/P5ZsycEENARIPDrOFIFgZACBH4miK0CBH5bR4Z+IYCAjQKeB\/6r35Vmac9adeinv7hMjpTPZoXfqlGhMwi4FyDwu7eiJQJRCxD4o6ZjQ48FCPweA1MeAQQSSoDAn1DDycEgEAgBAn8ghpmDjLUAgT\/WI8D+zydA4GduIIAAAu4FfAn8qRau8Fewwu9+ltASAbsECPx2jQe9sVRgyJAhYv7Ztm2bjB8\/PuJeEvgjJmMDnwQI\/D5BsxsEEEgIAQJ\/QgwjB4FAoAQI\/IEabg42GoGCggKZM2eO5OXlydatWwn80SCyjbUCBH5rh4aOIYCAhQKeB\/6rdkuzFNtW+LvKkdOs8Fs4HekSAq4ECPyumGgUVAET9mfPni1t2rRxCAj8QZ0JiXvcBP7EHVuODAEE9AU8D\/xX7pZmyc\/pd7wBFU9\/2VWOVM7ipn0NMGRTBGIpQOCPpT77tlqgb9++8rOf\/Uxyc3PP9pPAb\/WQ0bkoBAj8UaCxCQIIBFaAwB\/YoefAEYhbAQJ\/3A4dHfdKwJy6P3r0aLn66qslNTVVDh8+7PxnVlYWK\/xeoVM3ZgIE\/pjRs2MEEIhDAc8Df4\/dkmnhCv\/hKlb443C60mUEHAECPxMBga8IjBw5Um6++WaprKyUP\/3pT7Jq1SqZPHmytG7dmsDPbEk4AQJ\/wg0pB4QAAh4KEPg9xKU0Agh4IkDg94SVovEscNddd0mPHj3kySeflNdee00uueQSmTdvHoE\/ngeVvp9XgMDP5EAAAQTcC3ge+K\/YI5lJll3Df6arHK6eyTX87qcJLRGwSoDAb9Vw0BkbBQj8No4KfdISIPBrSVIHAQSCIEDgD8Ioc4wIJJYAgT+xxpOj8UCAwO8BKiWtESDwWzMUdAQBBOJAwOvA\/02zwt94lVUSp8wK\/xf3s8Jv1ajQGQTcCxD43VvRMqACBP6ADnxADpvAH5CB5jARQEBFgMCvwkgRBBDwUYDA7yM2u4pPAa3An5KUI59+UlkHYd2zJbL7r2XxCUOvE0KAwJ8Qw8hBIICABwJHj0yW6uq8OpWrq1vJY49tkOXLl6vvccmSJfLNb+yRzEYWrvCfiWyFPzk5WQYPHiwDBw6U5s2bS0pKinMz5JKSElmxYoW8\/PLLEfn17t1bhgwZIh07dnSenGRqvfvuu\/LEE0\/Itm3bIqpFYwSCJkDgD9qIc7wRC2gF\/s+OXihHD\/8z8DcSkdc3f0rgj3hE2EBTgMCvqUktBBBIJIGysu\/KqYqv1zkk8\/89\/vjjBP4QA20eYzxz5kwpLi6W6upq5\/HGpaWlkpubKzk5OVJVVSVr1qyRhQsXupouN910k9x5552SlpYmJ0+elAMHDsiFF14orVq1klOnTsnSpUtl9erVrmrRCIEgChD4gzjqHHNEAlqBf+OqSvnD5mMR7ZvGCHgtQOD3Wpj6CCCQSAKen9Jf\/J5kiWUr\/FIkn4j7Ff6hQ4c6q\/vl5eWyePFi2bBhgzMFzKr\/6NGjZcCAAc4K\/ezZs2XLli0hp4f50cD8eGB+RHjjjTdkypQpcuLECWcbs4\/bb7\/d2c+sWbPk9ddfT6SpxrEgoCZA4FejpFCiChD4E3VkOS4jQOBnHiCAAALuBQj8oa1MqF+2bJl07txZ1q9f74T62q\/MzEznR4D8\/HzZuHGjzJgxI2TBCRMmyPXXX++cJXDffffJzp0767RfsGCBczPBV155RaZOnep+IGmJQIAECPwBGmwONToBAn90bmwVHwIE\/vgYJ3qJAAJ2CHgd+Pt93azw23V6+ikpkkONZri6S3\/btm2dkN+6devznmo\/d+5c6dOnj2zdulXGjx8fcmDNvRIKCwud1fsxY8ac0\/aWW26R2267TQ4dOiSjRo1y\/pMXAgjUFSDwMyMQCCNA4GeKJLIAgT+RR5djQwABbQECf8NEa58B8Oqrr8rEiRNDFnzqqaekU6dO8pvf\/MY5M+Crr0GDBsmIESOkoqLCOd1\/x44dDesgWyOQgAIE\/gQcVA5JV4DAr+tJNbsECPx2jQe9QQABuwU8D\/zd90rWGctW+BsVyaHG012t8IcbPXP9vlmJT0pKck79X7lypavAf77T\/2+88Ua56667nBsBTps2jev4ww0Afw+kAIE\/kMPOQUciQOCPRIu28SZA4I+3EaO\/CCAQSwECf\/T6BQUFzun+bdq0kb1798rIkSPP3oDvfFXNdfnXXnvtedubewBcc801zk0AzWMNuVt\/9OPDlokrQOBP3LHlyJQECPxKkJSxUoDAb+Ww0CkEELBUwI\/An\/3l8zE7+mppKacaFdXZf1WjlnKi8aAGrfDn5eU5d9s31+MfP35cHnzwQTGn9Id79evXTyZNmiSpqanONf\/mBwNzV37zqrlLv3lcH4E\/nCR\/D7IAgT\/Io8+x+ybw4osvCo\/l842bHUUgQOCPAIumCCAQeIEgBP6SpOl1xrm6UUvnf5u74Ufzat++vXM3fnNn\/tLS0jqP6nNTzzzK7\/vf\/74T+s0j+UpKSsTc7b9Vq1ayb98+5783adJEHnjggbCP+XOzP9ogkGgCBP5EG1GOx0oBAr+Vw0KneCwfcwABBBCISMDrwP+ty\/dK9hexW+GvD6OiUZGUpPw8qsDfo0cP50785jR+s7K\/cOFC2bRpU0TmpvG\/\/du\/yU9+8hMxZwqYG\/+Z4L9582b505\/+JD\/\/+c+deuamfdu2bYu4NhsgkOgCBP5EH2GOzwoBAr8Vw0An6hFghZ9pgQACCLgXIPC7t+rfv7+Y1fns7GxnVd6swG\/fvt19ARctr7vuOrn33nudHwDMY\/vMij8vBBCoK0DgZ0Yg4IMAgd8HZHYRlQCBPyo2NkIAgYAKeB74u71v3wp\/48KIV\/j79u0r48aNc8K+CeHTp0+XPXv2qM8aE\/J\/8IMfyM6dO2XYsGHq9SmIQCIIEPgTYRQ5BusFCPzWD1FgO0jgD+zQc+AIIBCFAIE\/PFpxcbFzgz4T9nft2uWcam9W+KN53XHHHc7N+cyPBua\/V1dXny1jTu9fsGCBtG3bVlasWCGPPfZYNLtgGwQSXoDAn\/BDzAHaIEDgt2EU6EN9AgR+5gUCCCDgXsDzwH\/Z+9K8+j\/cd8iHlhWNC+XjtGmuruE319cvXrxYunfvLgcPHnTusN+Qlf2au\/SbukuXLpVnn33WOeL09HSZNm2a9O7dWz788EO55557ov5RwQdCdoFATAUI\/DHlZ+dBESDwB2Wk4+84CfzxN2b0GAEEYidA4A9tXxPQMzIywg6SecyeuaGfeV111VXOWQHmTvxLliyR1atXn93e\/P\/f\/OY35YsvvnB+RKioqHBu3peVlRXRI\/7CdogGCCSoAIE\/QQeWw7JLgMB0m4WJAAAgAElEQVRv13jQm38KEPiZDQgggIB7Aa8D\/7923SfNqyxb4U8qlIMXTHW1wj98+HDnFPxGjRqFRXUb+M3qvqlpHs3XokULady4sZw8eVL+\/Oc\/y7Jly2Tv3r1h90UDBIIsQOAP8uhz7L4JEPh9o2ZHEQoQ+CMEozkCCARagMAf6OHn4BGISwECf1wOG52ONwECf7yNWHD6S+APzlhzpAgg0HABXwJ\/pYUr\/E3crfA3XJgKCCCgLUDg1xalHgL1CBD4mRa2ChD4bR0Z+oUAAjYKEPhtHBX6hAACoQQI\/MwPBHwQIPD7gMwuohIg8EfFxkYIIBBQAc8Df9E+aX76Bat0K8w1\/Bn3ubqG36qO0xkEEHAECPxMBAR8ECDw+4DMLqISIPBHxcZGCCAQUAECf0AHnsNGII4FCPxxPHh0PX4ECPzxM1ZB6ymBP2gjzvEigEBDBDwP\/IX7Jce2Ff7kLnKAFf6GTBu2RSCmAgT+mPKz86AIEPiDMtLxd5wE\/vgbM3qMAAKxEyDwx86ePSOAQHQCBP7o3NgKgYgECPwRcdHYRwECv4\/Y7AoBBOJewPPA32W\/5Jx60SqnCrPCf+EUruG3alToDALuBQj87q1oiUDUAgT+qOnY0GMBAr\/HwJRHAIGEEiDwJ9RwcjAIBEKAwB+IYeYgYy1A4I\/1CLD\/8wkQ+JkbCCCAgHsB7wP\/B5JTYeEKf7PJrPC7nya0RMAqAQK\/VcNBZxJVgMCfqCMb\/8dF4I\/\/MeQIEEDAPwECv3\/W7AkBBHQECPw6jlRBIKQAgZ8JYqsAgd\/WkaFfCCBgo4Dngb\/zh5JTvsaqQ69I6SIHMieywm\/VqNAZBNwLEPjdW9ESgagFCPxR07GhxwIEfo+BKY8AAgklQOBPqOHkYBAIhACBPxDDzEHGWoDAH+sRYP\/nEyDwMzcQQAAB9wKeB\/5OZoV\/rfsO+dCyIqWzHMhihd8HanaBgCcCBH5PWCmKQF0BAj8zwlYBAr+tI0O\/EEDARgECv42jQp8QQCCUAIGf+YGADwIEfh+Q2UVUAgT+qNjYCAEEAirgeeAv+EhyTlq2wp\/aWQ5kT+Aa\/oDOeQ47\/gUI\/PE\/hhxBHAgQ+ONgkALaRQJ\/QAeew0YAgagECPxRsbERAgjEUIDAH0N8dh0cAQJ\/cMY63o6UwB9vI0Z\/EUAglgK+BP6yl2J5iOfsu8Ks8Dcfzwq\/VaNCZxBwL0Dgd29FSwSiFiDwR03Hhh4LEPg9BqY8AggklIDngT\/\/75JjXeDvJAdyCPwJNZE5mEAJEPgDNdwcbKwECPyxkme\/4QQI\/OGE+DsCCCDwTwECP7MBAQTiTYDAH28jRn\/jUoDAH5fDFohOE\/gDMcwcJAIIKAl4Hvg7\/l1yPl+n1FudMhVpneRAi3Gc0q\/DSRUEfBcg8PtOzg6DKEDgD+Kox8cxE\/jjY5zoJQII2CFA4LdjHOgFAgi4FyDwu7eiJQJRCxD4o6ZjQ48FCPweA1MeAQQSSsD7wH9Acj6zcIW\/5VhW+BNqJnMwQRIg8AdptDnWmAkQ+GNGz47DCBD4mSIIIICAewECv3srWiKAgB0CBH47xoFeJLgAgT\/BBziOD4\/AH8eDR9cRQMB3Aa8D\/7cuPSDNP1vv+3GF2qG5hv\/j3DGs8Fs1KnQGAfcCBH73VrREIGoBAn\/UdGzosQCB32NgyiOAQEIJEPgTajg5GAQCIUDgD8Qwc5CxFjCB\/7JuT0jTpr+NdVcSYv\/\/2vWRhDgOGw6CwK87CsxNPU\/mpp4l81LPcuzsfHlt23OyfPlyvaL\/U2nJkiViVvizS+1b4S+5iBV+9QGnIAI+CRD4fYJmN8EWIPDrjj9fXvU8CVV6lqYSc1PPk7mpZ8m81LMk8OtZUgkBBPwRIPD748xeAi5A4NedAHx51fMkVOlZEvh1LZmbep58ZupZeh34+3U4IFmWrfCfuqCTHGKFX28SUQkBnwUI\/D6Ds7tgChD4dcedL696noQqPUsCv64lc1PPk89MPUsCv54llRBAwB8BAr8\/zuwl4AIEft0JwJdXPU9ClZ4lgV\/Xkrmp58lnpp6l14H\/mx0OSGbpOr0OK1QyK\/yHLxrLXfoVLCmBQCwECPyxUGefgRMg8OsOOV9e9TwJVXqWBH5dS+amniefmXqWBH49SyohgIA\/AgR+f5zZS8AFCPy6E4Avr3qehCo9SwK\/riVzU8+Tz0w9S68Df98Of5dmpS\/pdVih0ukLOsmRi8azwq9gSQkEYiFA4I+FOvsMnACBX3fI+fKq50mo0rMk8OtaMjf1PPnM1LMk8LuzTE5OlsGDB8vAgQOlefPmkpKSIpWVlVJSUiIrVqyQl19+2V2h\/2nVsWNHGTVqlFx22WWSlpYmVVVVTq1f\/\/rXEdeKaMc0RiABBAj8CTCIHIL9AgR+3THiy6ueJ6FKz5LAr2vJ3NTz5DNTz9LrwP8vHT6SC0vX6nVYodLpCzrLpxdNcL3Cn5WVJTNnzpTi4mKprq6Ww4cPS2lpqeTm5kpOTo4T1tesWSMLFy501bu+ffvKuHHjJDs7W06cOOEE\/czMTGnVqpV88cUXsnbtWlmwYIGrWjRCIIgCBP4gjjrH7LsAgV+XnC+vep6EKj1LAr+uJXNTz5PPTD1LAn94y6FDhzqr++Xl5bJ48WLZsGGDs5FZ9R89erQMGDDAWe2fPXu2bNmyJWRBE+xNjfz8fNm1a5fce++9Tug3r3vuucc5g8BtrfA9pwUCiSlA4E\/MceWoLBMg8OsOCF9e9TwJVXqWBH5dS+amniefmXqWXgf+Ph0+lKala\/Q6rFCp8oIucuyiia5W+E2oX7ZsmXTu3FnWr1\/vhPrar9oBfuPGjTJjxoyQPbziiiucswVSU1Nl\/vz5Z388MBuZFf5FixZJu3btZNWqVa7PGFAgoQQCcSVA4I+r4aKz8SpA4NcdOb686nkSqvQsCfy6lsxNPU8+M\/UsCfyhLdu2beuE\/NatW8vSpUtl9erV52wwd+5c6dOnj2zdulXGjx8fsuBVV13lBH7zmjJlimzbtq1O+6eeeko6deokr776qkycOFFvoKmEQAIJEPgTaDA5FHsFCPy6Y8OXVz1PQpWeJYFf15K5qefJZ6aepdeBv3eHDySj9EW9DitUMiv8Jy6a7GqFP9zuap8B4Cakd+nSRebMmSPmvgDPPPOMLF++\/OwuunXrJvfff79zX4Cnn37aObOAFwIInCtA4GdWIOCDAIFfF5kvr3qehCo9SwK\/riVzU8+Tz0w9SwJ\/wyzN9fvmbvtJSUlOQF+5cmXYgjXX6pt7AphtXnrpJSksLJQxY8Y41\/Z\/8MEHzvX85mZ+vBBAgMDPHEAgJgIEfl12vrzqeRKq9CwJ\/LqWzE09Tz4z9Sy9Dvy9OuyT9NIX9DqsUKnqgkL57KL7GrzCX1BQ4Jzu36ZNG9m7d6+MHDny7A34QnXTnBVw6623yqBBgyQjI+Ns0y+\/\/FJ27NjhnAFA2FcYaEokrAAr\/Ak7tByYTQIEft3R4MurniehSs+SwK9rydzU8+QzU88y0QP\/l8kt5YvklnXAzP9XljOsQYE\/Ly\/PuRbfrMwfP35cHnzwQee6ezevIUOGyA033OA8is\/cof\/QoUPSrFkz5zF\/Z86ckddee835IcGcAcALAQTOFSDwMysQ8EGAwK+LzJdXPU9ClZ4lgV\/Xkrmp58lnpp6l14H\/f3V4X5qU\/odehyOsVH1BoXx+0bR6t+rZs2eE1f7RvH379s7d+M3p96WlpXUe1ReuYM0lACkpKbJu3TrnTvzV1dXOZv3793ce82eu7\/\/P\/\/xPmT59erhy\/B2BQAoQ+AM57By03wIEfl1xvrzqeRKq9CwJ\/LqWzE09Tz4z9SwTPfDXJ1XzI0A0gb9Hjx7OnfjNafxmZd8E9k2bNrkekAULFjhnFuzcuVNGjBhxNuzXFBg2bJgMHjxYjh075lzTv2fPHte1aYhAUAQI\/EEZaY4zpgIEfl1+vrzqeRKq9CwJ\/LqWzE09Tz4z9Sy9Dvw9L90rF5Q+r9dhhUrVaUVy8qKfR3xKf80KfHZ2tnON\/QMPPCDbt2+PqEc1j91btWqV82PBV181j+0zNwGcP3++bNiwIaL6NEYgCAIE\/iCMMscYcwECv+4Q8OVVz5NQpWdJ4Ne1ZG7qefKZqWdJ4Hdn2bdvXxk3bpyYsL9v3z7ndPtoVt9rAr+5M7+5OR+B350\/rRCoLUDgZz4g4IMAgV8XmS+vep6EKj1LAr+uJXNTz5PPTD1LrwP\/1ZfulbTS1XodVqj0RVqRlF803fUKf3FxsXODPhP2d+3aJVOmTIn6Lvpz586VPn36yHvvvefc1d\/cA6D267bbbpNbbrnFuZnfhAkT5J133lE4YkogkFgCBP7EGk+OxlIBAr\/uwPDlVc+TUKVnSeDXtWRu6nnymalnSeAPbWkeobd48WLp3r27HDx4UCZNmhTVyn7NXsxlAWPHjpW0tDT53e9+59zdn5v26c1nKgVDgMAfjHHmKGMsQODXHQC+vOp5Eqr0LAn8upbMTT1PPjP1LL0O\/Fdd+p6kfLZKr8MKlcwK\/+nc+12t8Pfr188J+RkZGWH3vHXrVueGfuZVcy1+amqqLFmyRFav\/udZDsOHD3cey2f+Zlbyzf0AmjRp4twI0PzAYM4iMDfsM3\/jhQAC5woQ+JkVCPggQODXRebLq54noUrPksCva8nc1PPkM1PPksAf2tKEc3PX\/EaNGoVFdxv4TaHevXvLkCFDpGPHjk7wr6qqcu7Mb+74b67zLy8vD7s\/GiAQVAECf1BHnuP2VYDAr8vNl1c9T0KVniWBX9eSuannyWemnqXXgf\/KS\/dIsmUr\/F+mdZVKlyv8etJUQgABLQECv5YkdRAIIUDg150efHnV8yRU6VkS+HUtmZt6nnxm6lkS+PUsqYQAAv4IEPj9cWYvARcg8OtOAL686nkSqvQsCfy6lsxNPU8+M\/UsvQ78V1y6R5I+e06vwwqVzqR1lercma6u4VfYHSUQQEBZgMCvDEo5BOoTIPDrzgu+vOp5Eqr0LAn8upbMTT1PPjP1LAn8epZUQgABfwQI\/P44s5eACxD4dScAX171PAlVepYEfl1L5qaeJ5+ZepZeB\/5vdNwtjSxc4T\/TchYr\/HrTiEoI+CpA4PeVm50FVYDArzvyfHnV8yRU6VkS+HUtmZt6nnxm6lkS+PUsqYQAAv4IEPj9cWYvcSZgHvsyYsQIKSoqkqZNmzqPl6moqJD9+\/c7j3957bXXIjoiAn9EXGEb8+U1LJHrBoQq11SuGjI3XTG5asTcdMXkqhHz0hWTq0ZeB\/7ijrtFPrfrGn5J6yrSghV+VxOERghYKEDgt3BQ6FJsBQYNGiR33nmnpKen19uRyspKWbNmjSxcuNB1Rwn8rqlcNeTLqysmV40IVa6YXDdibrqmCtuQuRmWyHUD5qVrqrANCfxhiWiAAAKWCRD4LRsQuhNbgV69esnkyZMlOztbTpw4IevWrZNnn31WTMi\/9tprZciQIdKiRQs5ffq0LF68WF544QVXHSbwu2Jy3Ygvr66pwjYkVIUliqgBczMirpCNmZt6lsxLPUuvA3\/3jrvlzOfP6nVYoVKjtK7SuMVsruFXsKQEArEQIPDHQp19WiswY8YMueaaa6SsrEweeugh2bRpU52+9u3bV8aNG+f8IPDWW2\/JsGHDXB0Lgd8Vk+tGfHl1TRW2IaEqLFFEDZibEXER+PW4QlZiXupBE\/j1LKmEAAL+CBD4\/XFmL3Eg0KpVK1m0aJG0a9cuZJh\/+OGHpUePHvLxxx\/LmDFjnOv6w70I\/OGEIvs7X14j8wrVmsCvZ2kqMTf1PJmbepbMSz1LrwP\/5fm75QvbVvhTu0oKK\/x6k4hKCPgsQOD3GZzd2SvQtWtXmTZtmuTm5srmzZvFrPbX95o7d6706dOHwB\/DoeTLqx4+oUrPksCva8nc1PPkM1PPksCvZ0klBBDwR4DA748ze0kQgeTkZFm2bJl07txZPvroIxk1apQcOnQo7NGxwh+WKKIGfHmNiCtkY0KVniWBX9eSuannyWemnqXXgf+y\/N1SbdkKf+PUrpLGCr\/eJKISAj4LEPh9Bmd38S1g7uBvHteXmpoqr7zyikydOtXVARH4XTG5bsSXV9dUYRsSqsISRdSAuRkRFz9G6XGFrMS81IP2OvB3zd8tVWV23bQvKbWrXJDDTfv0ZhGVEPBXgMDvrzd7i2OBgoICmT17trRp00YOHz4s9913n+zcudPVERH4XTG5bsSXV9dUYRsS+MMSRdSAuRkRF4Ffj4vA75Mlgd8naHaDAAJqAgR+NUoKJbKACfuzZs2Siy++2Hkk39KlS53H9bl9EfjdSrlrR6hy5+SmFYHfjZL7NsxN91bhWjI3wwm5\/zvz0r1VuJZeB\/6igt1yuuy5cN3w9e9mhT+j+Swey+erOjtDQE+AwK9nSaUEFai5mZ8J+5WVlbJq1Sp59NFHIzpaE\/i7dPmtXNDkzVrbnZHk5E8kObkkolo05k7omnOAUKWpydzU1GRu6mkS+KOz7HRZ03M2HHBTnry27TlZvnx5dEVDbLVkyRIh8KuzUhCBwAsQ+AM\/BQAIJdC3b1\/52c9+5ty536zsr1y50rlpX6QvE\/jz8vLO2axFy1nStOlvIy0X+PZ8edWbAoQqPUtTibmp58nc1LNkXkZnaVbz6wv9jz\/+uGeBv0vBHjll2Qp\/cmpXubD5TFb4o5tGbIVAzAUI\/DEfAjpgq8CPf\/xjufXWWyU9PV3KysrksccekxdeeCGq7nJKf1Rs592IL696noQqPUsCv64lc1PPk89MPUuvT+kn8OuNFZUQQOAfAgR+ZgIC9QgMHz5cbrjhBudu\/MePH5eFCxfKpk2borYi8EdNV++GfHnV8yRU6VkS+HUtmZt6nnxm6ll6Hfg7F+yR8pOr9DqsUCkltatkZt\/PCr+CJSUQiIUAgT8W6uzTaoHaYf\/AgQMyffp0efvttxvUZwJ\/g\/jO2Zgvr3qehCo9SwK\/riVzU8+Tz0w9SwK\/niWVEEDAHwECvz\/O7CVOBPr37y9jx46Vpk2bysGDB2XSpEmyZ8+eBveewN9gwjoF+PKq50mo0rMk8OtaMjf1PPnM1LP0OvAXdHpPTp5crddhhUqpKUWSnT2DFX4FS0ogEAsBAn8s1NmnlQKZmZmyePFiyc\/Pl5MnT8qTTz4pe\/fuPW9fq6qq5N1335Xy8vKwx0PgD0sUUQO+vEbEFbIxoUrPksCva8nc1PPkM1PPksCvZ0klBBDwR4DA748ze4kDgUGDBsmIESOc6\/bdvMyN\/KZMmSLbtm0L25zAH5YoogZ8eY2Ii8CvxxW2EnMzLJHrBgR+11RhGzIvwxK5buB14O\/Yaa98btkKf1pKkbTIns4Kv+tZQkME7BIg8Ns1HvQmhgIjR46Um2++2XUPCPyuqdQb8uVVj5RQpWdpKjE39TyZm3qWzEs9SwK\/niWVEEDAHwECvz\/O7CXgAqzw604AvrzqeRKq9CwJ\/LqWzE09Tz4z9Sy9DvyXdnpfSsuf1+uwQqW0lEK5KOvnrPArWFICgVgIEPhjoc4+AydA4Ncdcr686nkSqvQsCfy6lsxNPU8+M\/UsCfx6llRCAAF\/BAj8\/jizl4ALEPh1JwBfXvU8CVV6lgR+XUvmpp4nn5l6ll4H\/ks67ZMT5f+h12GFShekFEpe1lRW+BUsKYFALAQI\/LFQZ5+BEyDw6w45X171PAlVepYEfl1L5qaeJ5+ZepYEfj1LKiGAgD8CBH5\/nNlLwAUI\/LoTgC+vep6EKj1LAr+uJXNTz5PPTD1LrwN\/+8775Vj5C3odVqjUJKWLtMm8jxV+BUtKIBALAQJ\/LNTZZ+AECPy6Q86XVz1PQpWeJYFf15K5qefJZ6aeJYFfz5JKCCDgjwCB3x9n9hJwAQK\/7gTgy6ueJ6FKz5LAr2vJ3NTz5DNTz9LrwN+u8wfyacWLeh1WqJSe0kXaNpvMCr+CJSUQiIUAgT8W6uwzcAIEft0h58urniehSs+SwK9rydzU8+QzU8+SwK9nSSUEEPBHgMDvjzN7CbgAgV93AvDlVc+TUKVnSeDXtWRu6nnymaln6XXgv7jzh3KkYo1ehxUqZaR0kfbNJka0wp+cnCyDBw+WgQMHSvPmzSUlJUUqKyulpKREVqxYIS+\/\/LKrns2dO1f69OkTtq2pvWTJElm9enXYtjRAIGgCBP6gjTjHGxMBAr8uO19e9TwJVXqWBH5dS+amniefmXqWBP7wlllZWTJz5kwpLi6W6upqOXz4sJSWlkpubq7k5ORIVVWVrFmzRhYuXBi2mNvAf\/LkSZk3b5787ne\/C1uTBggETYDAH7QR53hjIkDg12Xny6ueJ6FKz5LAr2vJ3NTz5DNTz9LrwN+my0fyScVavQ4rVMpI7iyXNpvgeoV\/6NChzup+eXm5LF68WDZs2OD0wqz6jx49WgYMGOCs9s+ePVu2bNkSdQ+7desm999\/v2RnZ8vatWtlwYIFUddiQwQSWYDAn8ijy7FZI0Dg1x0KvrzqeRKq9CwJ\/LqWzE09Tz4z9SwJ\/KEtTahftmyZdO7cWdavX++E+tqvzMxM50eA\/Px82bhxo8yYMSOqwTF15s+fL0VFRfKXv\/xFRo4c6ZxNwAsBBM4VIPAzKxDwQYDAr4vMl1c9T0KVniWBX9eSuannyWemnqXXgT+vy9+lpOIlvQ4rVGqa3EkKmo13tcLftm1bJ+S3bt1ali5dWu819TWn6W\/dulXGjx8fVQ9rziIoKyuTKVOmyBtvvBFVHTZCIAgCBP4gjDLHGHMBAr\/uEPDlVc+TUKVnSeDXtWRu6nnymalnSeBvmGXtMwBeffVVmThxYsQFa07lb9mypaxbt07mzJkTcQ02QCBIAgT+II02xxozAQK\/Lj1fXvU8CVV6lgR+XUvmpp4nn5l6ll4H\/ou6HJCPT63X67BCpQuTO0nnC8e4WuEPtztz\/f6oUaMkKSnJOfV\/5cqV4TY55+8TJkxw7gNg7vg\/ZswY2b9\/f8Q12ACBIAkQ+IM02hxrzAQI\/Lr0fHnV8yRU6VkS+HUtmZt6nnxm6lkS+KO3LCgocE73b9Omjezdu9e57v7EiRMRFTQ1zN34W7RoIea7lfnvvBBAILQAgZ8ZgoAPAgR+XWS+vOp5Eqr0LAn8upbMTT1PPjP1LL0O\/LldDsqBU+6eUa93VP+slNY4R8w\/tV\/mf1+aMaRBK\/x5eXnOo\/oKCwvl+PHj8uCDD4o5pT\/S17Bhw5wnABw7dsxZ3d+zZ0+kJWiPQOAECPyBG3IOOBYCBH5ddb686nkSqvQsCfy6lsxNPU8+M\/UsEz3wN0sukMIL760XrGfPnlFBtm\/f3rkbv7kzf2lpaZ1H9UVSsPYd\/l955RWZOnVqJJvTFoHAChD4Azv0HLifAgR+XW2+vOp5Eqr0LAn8upbMTT1PPjP1LL0O\/C0KS+SjU\/94br0tr8zkfLms6c+iWuHv0aOHcyd+cxq\/WdlfuHChbNq0KapD69evn3OTv5SUFFmwYIFzwz5eCCAQXoDAH96IFgg0WIDA32DCOgX48qrnSajSsyTw61oyN\/U8+czUsyTwu7fs37+\/jB49WrKzs50b7D3wwAOyfft29wW+0tJc83\/TTTfJwYMH5e6773Zq8kIAgfACBP7wRrRAoMECBP4GExL4dQnPViNU6cISrPQ8mZt6lsxLPUuvA3\/zwkPy4amNeh1WqJSVnC+XN707ohX+vn37yrhx45ywv2\/fPpk+fXqDr7d\/7LHH5PLLL5etW7c6Zw3wQgABdwIEfndOtEKgQQIE\/gbxnbMxX171PAlVepamEnNTz5O5qWfJvNSzJPCHtywuLnZu0GfC\/q5du2TKlCkNXo3v0KGDc0f+3Nxcefrpp51H+vFCAAF3AgR+d060QqBBAgT+BvER+HX56lQjVOniEqz0PJmbepbMSz1LrwN\/VuEnsv\/07\/Q6rFApO7mjFGeMdLXCn5yc7NyUr3v37s6p95MmTWrwyr45hF69ejlnCTRu3Fjmz58vGzbYdZ8DBWZKIOCZAIHfM1oKI\/BPAQK\/7mzgy6ueJ6FKz9JUYm7qeTI39SyZl3qWBP7QlubGeibkZ2RkhEWvfWr+VVdd5ZwVkJqaKkuWLJHVq1fX2X7QoEEyYsQIqaiocM4Y2LFjR9j6NEAAgX8IEPiZCQj4IEDg10Xmy6ueJ6FKz5LAr2vJ3NTz5DNTz9LrwJ9ZeETeP\/2feh1WqJSdfKn0yBjhaoV\/+PDhMnjwYGnUqFHYPUcS+O+44w756U9\/Kp988omMGTNG9u\/fH7Y+DRBAgMDPHEDANwECvy41X171PAlVepYEfl1L5qaeJ5+ZepYEfj1LKiGAgD8CrPD748xeAi5A4NedAHx51fMkVOlZEvh1LZmbep58ZupZeh34Lyw6Ku+dfkWvwwqVmiddKldnDHO1wq+wO0oggICyAIFfGZRyCNQnQODXnRd8edXzJFTpWRL4dS2Zm3qefGbqWRL49SyphAAC\/ggQ+P1xZi8BFyDw604AvrzqeRKq9CwJ\/LqWzE09Tz4z9Sy9DvwZRcdk9+n\/0uuwQqWcpA7SK2MoK\/wKlpRAIBYCBP5YqLPPwAkQ+HWHnC+vep6EKj1LAr+uJXNTz5PPTD1LAr+eJZUQQMAfAQK\/P87sJeACBH7dCcCXVz1PQpWeJYFf15K5qefJZ6aepdeBv0nRcXn39Ga9DitUapF0ifTOuIMVfgVLSiAQCwECfyzU2WfgBAj8ukPOl1c9T0KVniWBX9eSuannyWemnqXXgT+t6ITsqvy\/eh1WqNQy6RLpm34rgV\/BkhIIxEKAwB8LdfYZOAECv+6Q8+VVz5NQpWdJ4Ne1ZG7qefKZqWdJ4NezpBICCPgjQOD3x5m9BFyAwK87AfjyqudJqNKzJPDrWjI39Tz5zNSz9DrwpxZ9Jm9XvqrXYYVKuUntpV\/6EFb4FUB966YAACAASURBVCwpgUAsBAj8sVBnn4ETMIF\/46pK+cPmY4E7di8OmCCgp0oQ0LM0lZibup5UQ8A2gUMlj8gjj\/xZli9frt61JUuWCIFfnZWCCARegMAf+CkAgB8CBH5dZUKVnieBX8+SwK9rSTUEbBTwOvAnF30uOyv\/n1WHflHS1+Sa9J+ywm\/VqNAZBNwLEPjdW9ESgagFCPxR09W7IYFfz5PAr2dJ4Ne1pBoCNgoQ+G0cFfqEAAKhBAj8zA8EfBAg8OsiE\/j1PAn8epYEfl1LqiFgo4DXgb9xUZn8pfI1qw69VdLX5Dvpg1nht2pU6AwC7gUI\/O6taIlA1AIE\/qjp6t2QwK\/nSeDXsyTw61pSDQEbBQj8No4KfUIAgVACBH7mBwI+CBD4dZEJ\/HqeBH49SwK\/riXVELBRwOvAL0Xl8mbl76069LykdvLd9JtZ4bdqVOgMAu4FCPzurWiJQNQCBP6o6erdkMCv50ng17Mk8OtaUg0BGwUI\/DaOCn1CAIFQAgR+5gcCPggQ+HWRCfx6ngR+PUsCv64l1RCwUcDrwP9l1wr5c+UfrDr01klt5XtNbmSF36pRoTMIuBcg8Lu3oiUCUQsQ+KOmq3dDAr+eJ4Ffz5LAr2tJNQRsFCDw2zgq9AkBBEIJEPiZHwj4IEDg10Um8Ot5Evj1LAn8upZUQ8BGAa8Df3XXU7K98o9WHXqbpLYysMkgVvitGhU6g4B7AQK\/eytaIhC1AIE\/arp6NyTw63kS+PUsCfy6llRDwEYBAr+No0KfEEAglACBn\/mBgA8CBH5dZAK\/nieBX8+SwK9rSTUEbBTwOvBXda2UbZV\/surQ2yRdLD9s8u+s8Fs1KnQGAfcCBH73VrREIGoBAn\/UdPVuSODX8yTw61kS+HUtqYaAjQIEfhtHhT4hgEAoAQI\/8wMBHwQI\/LrIBH49TwK\/niWBX9eSagjYKOB14D\/dtUr+WPnfVh36xUltZFCTH7DCb9Wo0BkE3AsQ+N1b0RKBqAUI\/FHT1bshgV\/Pk8CvZ0ng17WkGgI2ChD4bRwV+oQAAqEECPzMDwR8ECDw6yIT+PU8Cfx6lgR+XUuqIWCjgNeBv6LrF\/KHyu1WHXrbpNZyY5OBrPBbNSp0BgH3AgR+91a0RCBqAQJ\/1HT1bkjg1\/Mk8OtZEvh1LamGgI0CBH4bR4U+IYBAKAECP\/MDAR8ECPy6yAR+PU8Cv54lgV\/XkmoI2CjgdeAv7\/ql\/L7yz1Yderuk1nJzk++xwm\/VqNAZBNwLEPjdW9ESgagFCPxR09W7IYFfz5PAr2dJ4Ne1pBoCNgoQ+G0cFfqEAAKhBAj8zA8EfBAg8OsiE\/j1PAn8epYEfl1LqiFgo4DXgb+s6xl5rfINqw79a0l5MrjJv7HCb9Wo0BkE3AsQ+N1b0RKBqAUI\/FHT1bshgV\/Pk8CvZ0ng17WkGgI2ChD4bRwV+oQAAqEECPzMDwR8ECDw6yIT+PU8Cfx6lgR+XUuqIWCjgNeB\/7OiRvL\/Kt+06tDbJ7WSn6Z\/lxV+q0aFziDgXoDA796KlghELUDgj5qu3g0J\/HqeBH49SwK\/riXVELBRgMBv46jQJwQQCCVA4Gd+IOCDAIFfF5nAr+dJ4NezJPDrWlINARsFvA78pUWN5f9WvmXVoZsV\/lvTv80Kv1WjQmcQcC9A4HdvRUsEohYg8EdNV++GBH49TwK\/niWBX9eSagjYKEDgdzcqycnJMnjwYBk4cKA0b95cUlJSpLKyUkpKSmTFihXy8ssvuyv0P63S09Plrrvukm9961uSmZkpjRo1krKyMtm2bZs8+uijTl1eCCBQvwCBn5mBgA8CBH5dZAK\/nieBX8+SwK9rSTUEbBTwOvAfL0qSLZU7rTr0S5IuktvT+7te4c\/KypKZM2dKcXGxVFdXy+HDh6W0tFRyc3MlJydHqqqqZM2aNbJw4UJXx2nqzZs3TwoLC51tP\/roI2e7du3aSWpqqvO\/J0yYIPv373dVj0YIBE2AwB+0Eed4YyJA4NdlJ\/DreRL49SwJ\/LqWVEPARgECf\/hRGTp0qLO6X15eLosXL5YNGzY4G5lV\/9GjR8uAAQOc1f7Zs2fLli1bwhacNm2afPvb35aPP\/5Yfv7zn8vbb7\/tbNOjRw+57777pEWLFmK+Z5kfBXghgMC5AgR+ZgUCPggQ+HWRCfx6ngR+PUsCv64l1RCwUcDrwH+sKEX+q\/KvVh16h6RcGZr+r65W+E2oX7ZsmXTu3FnWr1\/vhPraL3M6vvkRID8\/XzZu3CgzZswIeaxXXHGF0yYtLU0WLVok69atq9PerOybHxD++te\/yp133mmVG51BwBYBAr8tI0E\/ElqAwK87vAR+PU8Cv54lgV\/XkmoI2ChA4A89Km3btnVCfuvWrWXp0qWyevXqczaYO3eu9OnTR7Zu3Srjx48PWfCOO+6Qn\/70p\/Lee++J+e\/mEgFeCCAQmQCBPzIvWiMQlQCBPyq2825E4NfzJPDrWRL4dS2phoCNAl4H\/qNFqfJK5T9OWbfldWlSrgxL7+dqhT9cn2ufAfDqq6\/KxIkTQ25iTtPv1auXvPTSSzJnzpxw5fk7AgjUI0DgZ1og4IMAgV8XmcCv50ng17Mk8OtaUg0BGwUI\/A0bFXP6\/ahRoyQpKck59X\/lypUhCz711FNSUFDg3Nnf3JzvJz\/5ieTl5Tn3Azhx4oRs3rxZfvnLXzr3C+CFAAL1CxD4mRkI1CPQu3dvGTJkiHTs2NG5A6y5K+yxY8dk06ZNYv7lE+m\/WAj8utOMwK\/nSeDXsyTw61pSDQEbBbwO\/EeK0uQ\/T++y6tAvTWopIzL6NniF3wR3c7p\/mzZtZO\/evTJy5EgntJ\/vZS4P+MUvfiEtW7Z0rtHv1q2bc7O\/AwcOONf0mzom+O\/atUvGjBkTspZVoHQGAZ8FCPw+g7M7+wWGDx8uN9xwgxP0v\/o6c+aM7N69W6ZPny4ffPCB64Mh8LumctWQwO+KyVUjAr8rJteNmJuuqWiIQFwKJHrgb94445xxyW6U3uDAb1blzaP6zKP1jh8\/Lg8++KCYU\/pDvS655BLnzvvmfgDm+9cbb7whU6ZMORvs+\/fv79z13zy2z9zMj1P+4\/ItRad9ECDw+4DMLuJHwPzLY+zYsdK0aVM5evSoPPHEE85dZi+++GK5\/fbbnZvMmF+TzY1mzJ1h3b4I\/G6l3LUjVLlzctOKwO9GyX0b5qZ7K1oiEI8CXgf+T4oukN+dfidmNB2TWsrIjD717r9nz55R9at9+\/bOnfbNnflLS0vrPKrPbeA\/fPiw8wi+nTt31tnErOz\/4Ac\/kL\/\/\/e\/OpQKHDh2Kqo9shEAiCxD4E3l0ObaIBRYsWOCcsmZOMZs1a5b8\/ve\/r1Oj5s6y5tdpc6OZt956y9U+CPyumFw3IlS5pgrbkMAfliiiBszNiLhojEDcCSR64DcD0rxxep1xMT8C\/LjJFVGd0t+jRw\/nTvzm9Hvz3WnhwoXO5ZFuXuYRfub6fLPSv337drn77rvP2axfv35nb\/xnVv+3bdvmpjRtEAiUAIE\/UMPNwYYSyMnJkcmTJzvXiP3tb39zfin+6mvQoEEyYsQI5\/9esmRJvY+bqW8fBH7duUeo0vMk8OtZmkrMTV1PqiFgm4DXgf9QUbr89vS7Vh12flILGZXxvyMO\/DWn3GdnZ0tJSYk88MADTnCP5LV8+XLnMoDzPcLvqquuci4VMC8CfySytA2SAIE\/SKPNsTZY4MYbb5S77rqLwN9gyYYVIFQ1zK\/21gR+PUsCv64l1RCwUYDA725U+vbtK+PGjRMT9vft2+fc+2jPnj3uNq7VaurUqXLttdfKe++9J7feeqtUV1fXqXHdddfJvffe69zMzwT+HTt2RLwPNkAg0QUI\/Ik+whyfmoC5dn\/+\/Ply5ZVXypEjR5w7wrr9lxcr\/GrD4BQi8Ot5Evj1LJmbupZUQ8BGAa8D\/8eFGbLh9G6rDr0gOUd+ltHL9Qp\/cXGxs+puwr65g74J4maFP5qXeYzfPffc4zwt6aGHHjrncgBzPyXTpuau\/+YeAbwQQKCuAIGfGYFAGIH09HTnZn033XSTc8MZ8+vy2rVrxVzv7\/ZF4Hcr5a4dgd+dk5tWBH43Su7bMDfdW9ESgXgUIPCHHjWzOLJ48WLp3r27HDx4UCZNmuR6caS+yuY6frPYUlRU5KzymxX\/mqckmdV982g\/8z1txYoV8qtf\/SoepxR9RsBzAQK\/58TsIJ4FzL9Ibr755rOHUFZWJs8\/\/7xz9\/6vnlYW6jgJ\/LqzgFCl50ng17M0lZibup5UQ8A2Aa8D\/8HCpvLy6chPfffSyazw35vR09UKv7mJngn5GRnnPt7vq32sfV1+zbX45pHIX71HUkFBgXMjZfPEJHPq\/kcffeQ8McncCND852uvvebcgymS72VeelEbAdsECPy2jQj9sUqg5q78tTt18uRJWbNmjSxdutT1v1wI\/LrDSqjS8yTw61kS+HUtqYaAjQIE\/tCjMnz4cBk8eLA0atQo7PC5DfymUF5enpja5ocB8+jkM2fOOI9PNt\/HzOo+YT8sNw0CLEDgD\/Dgc+jhBdq2bSuff\/6584uyuWnMLbfcIrm5uc61ZGal35y25uZlAn9KUs45Tdf9pkT+sPmYmxK0qSVA4NebDgR+PUsCv64l1RCItcDRI5Pl1Kmv1+lGdXWePP7442LuHq\/9MivbBwovlHWn92qXblC9TsnNZWzGVa5W+Bu0IzZGAAFPBAj8nrBSNFEFzGllc+bMcX5pPnDggPNMWDc3ojGB\/7OjF8ruv35eh+b1zcfk08OVicrl2XER+PVoCfx6lgR+XUuqIRBrgbKy70p1Vas63TD\/32OPbfAs8P+9sJm8dOr9WB96nf2bwD++aQ8Cv1WjQmcQcC9A4HdvRUsEHAFzR9jrr79ezPX85pmyW7ZsCSvDKf1hiSJqQOCPiCtkYwK\/niWBX9eSagjYKOD1Kf0EfhtHnT4hEN8CBP74Hj96HwOBmhv5mdP8v3pjmfN1h8CvO1AEfj1PAr+eJYFf15JqCNgo4HXg\/6gwU9ae2mfVoXdOzpYJTa9ghd+qUaEzCLgXIPC7t6JlgguY58aaZ8Xm5OTI+vXrZd68efUecc2N\/MyzXk37HTt2hJUh8IcliqgBgT8irpCNCfx6lgR+XUuqIWCjAIHfxlGhTwggEEqAwM\/8QOB\/BMx1+Q8\/\/LDz2BdzXb45dX\/PnrqPxunbt6+MGzdOsrOzZdeuXXLPPfeICf7hXgT+cEKR\/Z3AH5lXqNYEfj1LAr+uJdUQsFHA68D\/YZcsWXtqv1WHblb4J15YzAq\/VaNCZxBwL0Dgd29FywAImNP1f\/SjH0lKSop88MEH8uSTTzrX6JtHwNx0000yYMAAycrKkvLyclm0aJGsW7fOlQqB3xWT60YEftdUYRsS+MMSRdSAuRkRF40RiDsBAn\/cDRkdRiDwAgT+wE8BAGoLJCcny9SpU8Ws5JvQX9\/L3KzvsccekxdeeME1HoHfNZWrhoQqV0yuGhH4XTG5bsTcdE1FQwTiUsDrwP9Bl+ay5tQHVtl0Sc6SSRd2Z4XfqlGhMwi4FyDwu7eiZYAEvvOd78gNN9wgHTp0kNTUVDlz5oxzV\/4333xTli1bJnv3RvaMXAK\/7uQhVOl5Evj1LE0l5qauJ9UQsE2AwG\/biNAfBBAIJ0DgDyfE3xFQECDwKyDWKkGo0vMk8OtZEvh1LamGgI0C3gf+HHmx4kOrDr1LcqZMbnY5K\/xWjQqdQcC9AIHfvRUtEYhagMAfNV29GxL49TwJ\/HqWBH5dS6ohYKMAgd\/GUaFPCCAQSoDAz\/xAwAcBAr8uMoFfz5PAr2dJ4Ne1pBoCNgp4Hfj3d2khL1R8ZNWhmxX++5pdxgq\/VaNCZxBwL0Dgd29FSwSiFiDwR01X74YEfj1PAr+eJYFf15JqCNgoQOC3cVToEwIIhBIg8DM\/EPBBgMCvi0zg1\/Mk8OtZEvh1LamGgI0CXgf+fZ1bygsVf7fq0AtTmsl9zbqywm\/VqNAZBNwLEPjdW9ESgagFCPxR09W7IYFfz5PAr2dJ4Ne1pBoCNgoQ+G0cFfqEAAKhBAj8zA8EfBAg8OsiE\/j1PAn8epYEfl1LqiFgo4D3gT9X\/qP8gFWHblb4p2YWssJv1ajQGQTcCxD43VvREoGoBQj8UdPVuyGBX8+TwK9nSeDXtaQaAjYKEPhtHBX6hAACoQQI\/MwPBHwQIPDrIhP49TwJ\/HqWBH5dS6ohYKOA14H\/\/c4XyfPlB6069MKUC+XnmV1Y4bdqVOgMAu4FCPzurWiJQNQCBP6o6erdkMCv50ng17Mk8OtaUg0BGwUI\/DaOCn1CAIFQAgR+5gcCPggQ+HWRCfx6ngR+PUsCv64l1RCwUcDrwL+3Uyt5vvxjqw69yKzwZ3Vihd+qUaEzCLgXIPC7t6IlAlELEPijpqt3QwK\/nieBX8+SwK9rSTUEbBQg8Ns4KvQJAQRCCRD4mR8I+CBA4NdFJvDreRL49SwJ\/LqWVEPARgGvA\/97nVrJ6vISqw7drPDPyCpghd+qUaEzCLgXIPC7t6IlAlELEPijpqt3QwK\/nieBX8+SwK9rSTUEbBQg8Ns4KvQJAQRCCRD4mR8I+CBA4NdFJvDreRL49SwJ\/LqWVEPARgHvA3+erDp5yKpDL0ppKvdn57PCb9Wo0BkE3AsQ+N1b0RKBqAUI\/FHT1bshgV\/Pk8CvZ0ng17WkGgI2ChD4bRwV+oQAAqEECPzMDwR8ECDw6yIT+PU8Cfx6lgR+XUuqIWCjgNeBf0+n1vLcyU+sOvSuKU1lZvalrPBbNSp0BgH3AgR+91a0RCBqAQJ\/1HT1bkjg1\/Mk8OtZEvh1LamGgI0CBH4bR4U+IYBAKAECP\/MDAR8ECPy6yAR+PU8Cv54lgV\/XkmoI2CjgdeDfXdBGnj152KpD75qaIbOzO7DCb9Wo0BkE3AsQ+N1b0RKBqAUI\/FHT1bshgV\/Pk8CvZ0ng17WkGgI2ChD4bRwV+oQAAqEECPzMDwR8ECDw6yIT+PU8Cfx6lgR+XUuqIWCjgNeB\/92Ci+U3J49YdeiXpWbIA9ntWeG3alToDALuBQj87q1oiUDUAgT+qOnq3ZDAr+dJ4NezJPDrWlINARsFCPw2jgp9QgCBUAIEfuYHAj4IEPh1kQn8ep4Efj1LAr+uJdUQsFHA68D\/TkFbWVlm2wp\/usxtzgq\/jfORPiHgRoDA70aJNgg0UIDA30DAr2xO4NfzJPDrWRL4dS2phoCNAgR+G0eFPiGAQCgBAj\/zAwEfBAj8usgEfj1PAr+eJYFf15JqCNgo4HXg\/1tBO1lRdtSqQ++Wmi4PNW\/HNfxWjQqdQcC9AIHfvRUtEYhagMAfNV29GxL49TwJ\/HqWBH5dS6ohYKMAgd\/dqCQnJ8vgwYNl4MCB0rx5c0lJSZHKykopKSmRFStWyMsvv+yukIh06NBB5s2bJ3l5eefdZuvWrTJ+\/HjXNWmIQJAECPxBGm2ONWYCBH5degK\/nieBX8+SwK9rSTUEbBTwOvC\/nf81eabsU6sO\/fLUJjI\/p63rFf6srCyZOXOmFBcXS3V1tRw+fFhKS0slNzdXcnJypKqqStasWSMLFy50dZy9evWS6dOnS0ZGBoHflRiNEKgrQOBnRiDggwCBXxeZwK\/nSeDXsyTw61pSDQEbBQj84Udl6NChzup+eXm5LF68WDZs2OBsZFb9R48eLQMGDHBW+2fPni1btmwJW\/CWW26R2267TQ4dOiSjRo1y\/pMXAgi4FyDwu7eiJQJRCxD4o6ard0MCv54ngV\/PksCva0k1BGwU8Drw78xvL0+XHbPq0LunNpFf5LRxtcJvQv2yZcukc+fOsn79eifU135lZmY6PwLk5+fLxo0bZcaMGWGPdcKECXL99dfL9u3b5e677w7bngYIIFBXgMDPjEDABwECvy4ygV\/Pk8CvZ0ng17WkGgI2ChD4Q49K27ZtnZDfunVrWbp0qaxevfqcDebOnSt9+vQRt9fdP\/zww9KjRw956aWXZM6cOTZOC\/qEgNUCBH6rh4fOJYoAgV93JAn8ep4Efj1LAr+uJdUQsFHA68D\/Vn57efLz41Ydulnhf7hFa1cr\/OE6XvsMgFdffVUmTpwYcpNWrVrJokWLxPznL3\/5S3nuuefC7YK\/I4DAVwQI\/EwJBHwQIPDrIhP49TwJ\/HqWBH5dS6ohYKMAgb9ho2Ku3zfX4SclJTmn\/q9cuTJkwcsvv1weeOABSU9Pl\/fff1\/MGQRNmzZ1tjlx4oRs3rzZ+SHA3C+AFwII1C9A4GdmIOCDAIFfF5nAr+dJ4NezJPDrWlINARsFvA78b3a8RJ74\/ETMDj0vKfmcfbdKTpZHWuQ1eIW\/oKDAOd2\/TZs2snfvXhk5cqQT2kO9fvjDHzrX7aempsqXX37p3LDPbGPuBWDu+m8e97dv3z7nLv579uyJmRs7RsBmAQK\/zaND3xJGgMCvO5QEfj1PAr+eJYFf15JqCNgokOiB\/+tpFzjhvr5Xz549ox6SvLw851F9hYWFcvz4cXnwwQfFnNIf7mXuzn\/jjTc6j\/d75JFHzt7x32zXv39\/567\/2dnZru8HEG5\/\/B2BRBQg8CfiqHJM1gkQ+HWHhMCv60k1PQF+QNGz5H2uZ0klPQGvA\/+fO3aQxz8v1etwFJWK0y6os1Vxaprc0Swr6hX+9u3bO3fjN3fmLy0trfOovii6V2eTYcOGOY8A\/Oyzz5z7Abz11lsNLcn2CCScAIE\/4YaUA7JRgMCvOyoEAV1PqukJEPj1LHmf61lSSU8gCIH\/q1rmB4BftrgoqsBv7q4\/fvx45zR+s7K\/cOFC2bRpk9qA9OrVyzmd35zav2TJknqfCqC2MwohEKcCBP44HTi6HV8CBH7d8SII6HpSTU+AwK9nyftcz5JKegJeB\/4dHS+VX332mV6HFSp9Iy1NlrbMjTjw1z7lvqSkxLn53vbt2yPu0SWXXOJss3\/\/\/nO2veqqq5xLBcw1\/gT+iGnZICACBP6ADDSHGVsBAr+uP0FA15NqegIEfj1L3ud6llTSE\/A68P93x47ymGWB\/4q0NHm8ZcuIAn\/fvn1l3LhxzvX1Dbmp3vLly53r\/l9\/\/XUZM2bMOQPZr18\/51R+c9f\/+fPn17nGX2\/UqYRAfAsQ+ON7\/Oh9nAgQ+HUHiiCg60k1PQECv54l73M9SyrpCRD4w1sWFxc7q+4m7O\/atUumTJkiZoU\/mteECRPk+uuvlyNHjjiB\/6t34jd\/N4\/6O3jwoHM3\/2j3E03f2AaBeBEg8MfLSNHPuBYg8OsOH0FA15NqegIEfj1L3ud6llTSE\/A68G+7NF8e\/exzvQ4rVOqRlipP5LZwtcKfnJzs3JSve\/fuTgifNGlSgx6XV\/PjQVZWlrz22mvO9frl5eXOUZmb9d1+++3SuHFjWbFihfzqV79SOFpKIJB4AgT+xBtTjshCAQK\/7qAQBHQ9qaYnQODXs+R9rmdJJT0BAn9oS3OKvQn5GRkZYdG3bt3q3NDPvEJdi3\/TTTfJnXfeKWlpaXLixAlnFT8zM1NatWrlbGt+CDBnEZhH9\/FCAIFzBQj8zAoEfBAg8OsiEwR0PammJ0Dg17Pkfa5nSSU9Aa8D\/x8vLZBHS8v0OqxQyazwP3VRc1cr\/MOHD3dW3hs1ahR2z24DvynUu3dvGTJkiHTs2NG5QV9VVZUT\/NeuXSvPP\/88YT+sNg2CLEDgD\/Loc+y+CRD4dakJArqeVNMTIPDrWfI+17Okkp4AgV\/PkkoIIOCPAIHfH2f2EnABAr\/uBCAI6HpSTU+AwK9nyftcz5JKegJeB\/4\/XFogS0pP6nVYodKVaany9EXZrlb4FXZHCQQQUBYg8CuDUg6B+gQI\/LrzgiCg60k1PQECv54l73M9SyrpCRD49SyphAAC\/ggQ+P1xZi8BFyDw604AgoCuJ9X0BAj8epa8z\/UsqaQn4Hng79BJHin9x13obXldeUGKPHNRFiv8tgwI\/UAgQgECf4RgNEcgGgECfzRq59+GIKDrSTU9AQK\/niXvcz1LKukJEPj1LKmEAAL+CBD4\/XFmLwEXIPDrTgCCgK4n1fQECPx6lrzP9SyppCfgdeB\/vUNneaS0Qq\/DCpXMCv+vL2rGCr+CJSUQiIUAgT8W6uwzcAIEft0hJwjoelJNT4DAr2fJ+1zPkkp6AgR+PUsqIYCAPwIEfn+c2UvABQj8uhOAIKDrSTU9AQK\/niXvcz1LKukJeB\/4u8gjJ2xb4U+WX7dihV9vFlEJAX8FCPz+erO3gAoQ+HUHniCg60k1PQECv54l73M9SyrpCRD49SyphAAC\/ggQ+P1xZi8BFyDw604AgoCuJ9X0BAj8epa8z\/UsqaQn4Hngv6RQHjlxSq\/DCpWuvCBZfp3XlGv4FSwpgUAsBAj8sVBnn4ETIPDrDjlBQNeTanoCBH49S97nepZU0hMg8OtZUgkBBPwRIPD748xeAi5A4NedAAQBXU+q6QkQ+PUseZ\/rWVJJT8DrwP8Hs8J\/\/LRehxUqmRX+Z1pnsMKvYEkJBGIhQOCPhTr7DJwAgV93yAkCup5U0xMg8OtZ8j7Xs6SSngCBX8+SSggg4I8Agd8fZ\/YScAECv+4EIAjoelJNT4DAr2fJ+1zPkkp6At4H\/iJZcrxSr8MKla68IEmebp3OCr+CJSUQiIUAgT8W6uwzcAIEft0hJwjoelJNT4DAr2fJ+1zPkkp6AgR+PUsqIYCAPwIEfn+c2UvABQj8uhOAIKDrSTU9AQK\/niXvcz1LKukJeB34\/9i+qzx6vEqvwwqVejRJkqdaX8AKv4IlJRCIhQCBPxbq7DNwAgR+3SEnCOh6Uk1PgMCvZ8n7XM+SSnoCBH49SyohgIA\/AgR+f5zZS8AFCPy6E4AgoOtJNT0BAr+eJe9zPUsq6Ql4Hfi3tb9MHj1m2wp\/Y3miDSv8erOISgj4JfWVRwAAIABJREFUK0Dg99ebvQVUgMCvO\/AEAV1PqukJEPj1LHmf61lSSU+AwK9nSSUEEPBHgMDvjzN7CbgAgV93AhAEdD2ppidA4Nez5H2uZ0klPQHPA\/\/Xusljx6r1OqxQ6YomjWX5xalcw69gSQkEYiFA4I+FOvsMnACBX3fICQK6nlTTEyDw61nyPtezpJKeAIFfz5JKCCDgjwCB3x9n9hJwAQK\/7gQgCOh6Uk1PgMCvZ8n7XM+SSnoCXgf+7V\/rJks\/\/UKvwwqVvtGksSxrm8IKv4IlJRCIhQCBPxbq7DPuBLKysmT+\/PlSWFgoW7dulfHjx0d0DAT+iLjCNiYIhCWiQYwECPx68LzP9SyppCdA4NezpBICCPgjQOD3x5m9xLnAhAkTZMCAAdKoUSMCvwVjSRCwYBDoQr0CBH69icH7XM+SSnoCXgf+HV+7XJZ9+qVehxUqfaNJI3msbTIr\/AqWlEAgFgIE\/lios8+4EvjhD38oI0eOlLS0NKffrPDHfvgIArEfA3pQvwCBX29m8D7Xs6SSngCBX8+SSggg4I8Agd8fZ\/YSpwIFBQUye\/Zsad26tZw5c0YaN25M4LdgLAkCFgwCXahXgMCvNzF4n+tZUklPwOvA\/+d23eVxy1b4i9MbyS\/bJrHCrzeNqISArwIEfl+52Vk8CSQnJ8usWbOkd+\/e8v7770tmZqa0bNmSwG\/BIBIELBgEukDg93gO8D73GJjyUQkQ+KNiYyMEEIihAIE\/hvjs2m6BIUOGiPmnvLxclixZIrfeequz0s8p\/bEfN4JA7MeAHtQvwAq\/3szgfa5nSSU9Aa8D\/xvtusvyo2f0OqxQyazwL2nXmBV+BUtKIBALAQJ\/LNTZp\/UCvXr1ksmTJ0vTpk1lxYoV8sorr8i8efMI\/JaMHEHAkoGgG+cIEPj1JgXvcz1LKukJEPj1LKmEAAL+CBD4\/XFmL3Ek8NVH8Jng37ZtWwK\/RWNIELBoMOhKHQECv96E4H2uZ0klPQGvA\/+bbb8uTxzV669Gpa+nizzytUas8GtgUgOBGAgQ+GOAzi7tFrjnnntk4MCBcvjwYZk0aZLs2bNHLrnkEgK\/RcNGELBoMOgKgd+jOcD73CNYyjZIgMDfID42RgCBGAgQ+GOAzi7tFejfv7+MHTtWUlJSZOnSpfLss886nSXw2zVmBAG7xoPe\/FOAFX692cD7XM+SSnoCXgf+v7QtlieP6PVXo5JZ4X+4vbDCr4FJDQRiIEDgjwE6u7RTwIT6hx566Ox1+hMmTDjbUY3Av29Xmuz+6+d1Dn73X8vk08OVdoJY3CuCgMWDE\/CuEfj1JgDvcz1LKkUnUFb23XM2LPv8u\/LII3+W5cuXR1c0xFbmBsEEfnVWCiIQeAECf+CnAABGoPYj+D788EMxp\/WXlJSoBv6UpJw62I1E5KXflMgfNh9jECIUIAhECEZz3wQI\/HrUvM\/1LKkUncDRI5Pl1Kmv19m4ujpPHn\/8cc8C\/1sXmxV+8w3Bnlf3DLPCfyaiFX7zvWrw4MHOJZLNmzd3zpysrKx0vluZmyG\/\/PLLDTrAm266SYYNGyZHjx6VMWPGyP79+xtUj40RSGQBAn8ijy7H5lqg9gq+243KyspkypQpsm3btrCbvPjii7JxVSXhPqyUuwYEAXdOtPJfgMCvZ877XM+SSnoCXp\/SnwiB39z8eObMmVJcXCzV1dXOPZFKS0slNzdXcnJypKqqStasWSMLFy6MamAKCgpkzpw5kpeXJx9\/\/DGBPypFNgqSAIE\/SKPNsZ5XgMAfX5ODIBBf4xWk3hL49Uab97meJZX0BLwO\/Dsv\/oY8dbixXocVKnXPOCMLL\/nS9Qr\/0KFDndX98vJyWbx4sWzYsMHphVn1Hz16tAwYMMBZ7Z89e7Zs2bIloh6aGvPnz5crr7zS2Y7AHxEfjQMqQOAP6MBz2JEJaFzDzwp\/ZOahWhME9CyppCtA4Nfz5H2uZ0klPQECf2hLE8iXLVsmnTt3lvXr1zuhvvYrMzPT+REgPz9fNm7cKDNmzIhocIYMGSLmH\/NjQkZGBqf0R6RH46AKEPiDOvIcd0QCBP6IuDxvTBDwnJgdRClA4I8Srp7NeJ\/rWVJJT8DzwN\/mCnnawhX+X3T4wtUKf9u2bZ2Q37p1a+dpR6tXrz4Hf+7cudKnTx\/ZunWrjB8\/3vXgmEsEzKUC5rV582bnTAGu4XfNR8MACxD4Azz4HLp7AQK\/eys\/WhIE\/FBmH9EIEPijUat\/G97nepZU0hPwOvD\/1QT+T5L0OqxQ6fKMM\/KLS6tdBf5wu6t9BsCrr74qEydODLeJ83eznTkzoKioSNauXSsHDhyQESNGEPhd6dEo6AIE\/qDPAI7flQCB3xWTb40IAr5Rs6MIBQj8EYKFaM77XM+SSnoCBP6GWZpV+VGjRklSUpJz6v\/KlStdFRw5cqT86Ec\/kj179si9994r3\/72twn8ruRohIAIgZ9ZgIALAQK\/CyQfmxAEfMRmVxEJEPgj4grZmPe5niWV9AQ8D\/yt\/397dwNdZXXvefyPhCAETQJKeWmu0EsiBF9orhQpBSMqY2VKaZ3BWjOV0UIVLhAReRO1vMibSrMug8ii3OX1gthQL1RewjAXholtKaWjY+8tKlKoFQikaIhFXkKAWftp8fKWnOec\/J999jn7e9aateYunue\/9\/7s\/1n2l33Oc3rLK66d8Lc5IwsUTvjN0\/XNx\/07d+4su3fvFhPijxw5EnNziouLZeLEicF1zz77rPziF7+QYcOGEfhjynEBAn8RIPDTCQhYEOBn+XSRCQK6nlTTEyDw61nyPtezpJKeQLoH\/pv\/Gu4vJ9a3b9+EIc1P6Jnv3xcWFkpNTY3Mnz9fzEf6Y73MT\/yZp\/Kbh\/ytWrUq+Fi\/eRH4Y8nx7wj8hwCBn25AwIIAgV8XmSCg60k1PQECv54l73M9SyrpCUQd+P\/dnPAfzNCbcAKVTOg\/\/2X+7+91CPfQvssN16VLl+Bp\/Ca019bWXvBTfbGmN378eBk6dOjnH+U39xP4Y6nx7whcKEDgpyMQsCBA4NdFJgjoelJNT4DAr2fJ+1zPkkp6Aj4E\/ou1TOB\/oduphB7a17t37+BJ\/OZj\/OZkv6ysTDZt2hRqQ8xH+SdPnixnzpz5\/KP8527khD8UIRchEAgQ+GkEBCwIEPh1kQkCup5U0xMg8OtZ8j7Xs6SSnkDkgb\/jV5J+wn\/ZwJ9fF3fgHzRokJSWlkpubq5UVVXJnDlzZMeOHaE3w3zH\/7vf\/W6o648ePSrTpk2T7du3h7qeixDwSYDA79Nus9akCRD4dekJArqeVNMTIPDrWfI+17Okkp4AgT+c5bkH7Zmwv2fPHpk+fXrwsfx4Xvfee6\/cc889l72ldevWkpeXJydPnpQ\/\/vGPYgL\/okWL5L333otnCK5FwAsBAr8X28wiky1A4NfdAYKArifV9AQI\/HqWvM\/1LKmkJ2Aj8P9zVXK\/w3+xlvlI\/\/MF4U\/4i4qKggf0mbC\/c+fO4OTdnPBrvvhIv6YmtdJdgMCf7jvM+pwQIPDrbgNBQNeTanoCBH49S97nepZU0hMg8DdumZGRETyUr1evXrJ\/\/36ZOnVq3Cf7YXaLwB9GiWsQ+IsAgZ9OQMCCAIFfF5kgoOtJNT0BAr+eJe9zPUsq6QlEHfh\/1+Er8s9VLfQmrFDppqvMCf\/JUN\/hHzhwYBDys7KyYo5cWVkZPNDPvPr06RN8KiAzMzP4aH55eXmj9xP4Y\/JyAQKfCxD4aQYELAgQ+HWRCQK6nlTTEyDw61nyPtezpJKeAIG\/cctRo0ZJSUmJNGvWLCY6gT8mERcgoCJA4FdhpAgCjQsQ+HU7hCCg60k1PQECv54l73M9SyrpCUQf+PvI8gOunfCflueuD3fCrydNJQQQ0BIg8GtJUgeBRgQI\/LrtQRDQ9aSangCBX8+S97meJZX0BAj8epZUQgABOwIEfjvOjOK5AIFftwEIArqeVNMTIPDrWfI+17Okkp5A1IF\/5xf6yPL97p3wz+\/BCb9eF1EJAbsCBH673ozmqQCBX3fjCQK6nlTTEyDw61nyPtezpJKeAIFfz5JKCCBgR4DAb8eZUTwXIPDrNgBBQNeTanoCBH49S97nepZU0hOIPPC37yMr9mfqTVih0k1Xn5Z5PU6Eekq\/wnCUQAABZQECvzIo5RC4nACBX7cvCAK6nlTTEyDw61nyPtezpJKeAIFfz5JKCCBgR4DAb8eZUTwXIPDrNgBBQNeTanoCBH49S97nepZU0hOIOvC\/a07497l1wn+jOeEv5IRfr4uohIBdAQK\/XW9G81SAwK+78QQBXU+q6QkQ+PUseZ\/rWVJJT4DAr2dJJQQQsCNA4LfjzCieCxD4dRuAIKDrSTU9AQK\/niXvcz1LKukJRB74r73VzRP+nsf5Dr9eG1EJAasCBH6r3AzmqwCBX3fnCQK6nlTTEyDw61nyPtezpJKeAIFfz5JKCCBgR4DAb8eZUTwXIPDrNgBBQNeTanoCBH49S97nepZU0hOwEfhf\/ci97\/DPvYETfr0uohICdgUI\/Ha9Gc1TAQK\/7sYTBHQ9qaYnQODXs+R9rmdJJT0BAr+eJZUQQMCOAIHfjjOjeC5A4NdtAIKArifV9AQI\/HqWvM\/1LKmkJxB54L\/mVnn1o5Z6E1aodGP2aZl7wzG+w69gSQkEkiFA4E+GOmN6J0Dg191ygoCuJ9X0BAj8epa8z\/UsqaQnQODXs6QSAgjYESDw23FmFM8FCPy6DUAQ0PWkmp4AgV\/Pkve5niWV9ASiDvzvtesrr\/7RtRP+eplzEyf8el1EJQTsChD47XozmqcCBH7djScI6HpSTU+AwK9nyftcz5JKegIEfj1LKiGAgB0BAr8dZ0bxXIDAr9sABAFdT6rpCRD49Sx5n+tZUklPwErg\/\/BKvQkrVLoxu17m3PwZ3+FXsKQEAskQIPAnQ50xvRMg8OtuOUFA15NqegIEfj1L3ud6llTSEyDw61lSCQEE7AgQ+O04M4rnAgR+3QYgCOh6Uk1PgMCvZ8n7XM+SSnoCkQf+tn1lpWsn\/Dn1MpsTfr0mohIClgUI\/JbBGc5PAQK\/7r4TBHQ9qaYnQODXs+R9rmdJJT0BAr+eJZUQQMCOAIHfjjOjeC5A4NdtAIKArifV9AQI\/HqWvM\/1LKmkJxB94P+qrPyDY9\/hNyf8vY7yHX69NqISAlYFCPxWuRnMVwECv+7OEwR0PammJ0Dg17Pkfa5nSSU9AQK\/niWVEEDAjgCB344zo3guQODXbQCCgK4n1fQECPx6lrzP9SyppCcQdeB\/P9ec8LfSm7BCpRvMCf+X\/8wJv4IlJRBIhgCBPxnqjOmdAIFfd8sJArqeVNMTIPDrWfI+17Okkp4AgV\/PkkoIIGBHgMBvx5lRPBcg8Os2AEFA15NqegIEfj1L3ud6llTSE4g+8PeTlXtdO+E\/JbOLOOHX6yIqIWBXgMBv15vRPBUwgf\/Gm\/5R2rTZ4KkAy3ZVgICquzOEVD1PelPPkr7UsyTw61lSCQEE7AgQ+O04M4rnAgR+zxvA4eUTqnQ3h2Cl50lv6lnSl3qWkQf+nH7y2p7WehNWqHRD7il59u8+5Tv8CpaUQCAZAgT+ZKgzpncCBH7vtjxlFkyo0t0qgpWeJ72pZ0lf6lkS+PUsqYQAAnYECPx2nBnFcwECv+cN4PDyCVW6m0Ow0vOkN\/Us6Us9y6gD\/67srzl5wj\/rllpO+PXaiEoIWBUg8FvlZjBfBQj8vu68++smVOnuEcFKz5Pe1LOkL\/UsCfx6llRCAAE7AgR+O86M4rkAgd\/zBnB4+YQq3c0hWOl50pt6lvSlnqWNwP+T32fpTVihkvkO\/8zeRzjhV7CkBALJECDwJ0OdMb0TIPB7t+Ups2BCle5WEaz0POlNPUv6Us+SwK9nSSUEELAjQOC348wongsQ+D1vAIeXT6jS3RyClZ4nvalnSV\/qWUYd+D+4ur\/8ZLdbJ\/w929bJzK9wwq\/XRVRCwK4Agd+uN6N5KkDg93TjU2DZhCrdTSJY6XnSm3qW9KWeZeSB\/6r+Ur67jd6EFSqZwD+jT01cH+nPyMiQkpISGTp0qLRt21ZatGghdXV1UlVVJcuXL5d169bFNbP+\/fvL8OHDpVu3bpKZmRnU2r17t7z88svy5ptvxlWLixHwTYDA79uOs96kCBD4k8LOoCEECFUhkOK4hGAVB1aMS+lNPUv6Us+SwB\/bMicnR2bNmiVFRUVSX18v1dXVUltbK+3bt5d27drJqVOnZPXq1VJWVha7mIjce++98sgjj0hWVpZ8\/PHHQb1ztY4fPy5LliyR8vLyULW4CAEfBQj8Pu46a7YuQOC3Ts6AIQUIVSGhQl5GsAoJFeIyejMEUshL6MuQUCEuiz7wD5DyDxw84b\/1k9An\/CNHjgxO948dOyYLFy6U9evXB7Lm1L+0tFSGDBkSnNDPnj1btmzZ0qh6x44dZcGCBXLdddcFJ\/lPPvlk8EcEU2vq1KkyaNAgOXTokEyYMEH27t0bYge5BAH\/BAj8\/u05K06CAIE\/CegMGUqAUBWKKfRFBKvQVDEvpDdjEoW+gL4MTRXzQgJ\/40QmiC9dulS6d+8ua9euDUL9+a\/s7OzgjwD5+flSUVEhM2bMaLTgAw88ICNGjAg+ITB58mR59913P7++R48eMnfuXDGfKFi8eLG89tprMfePCxDwUYDA7+Ous2brAgR+6+QMGFKAUBUSKuRlBKuQUCEuozdDIIW8hL4MCRXisqgD\/+425oT\/qhAzsXdJz3Z1Mv3Wj0Od8Ofl5QUhv1OnTg1+1H7evHkyYMAAqayslEmTJjW6EPOJgMGDBwff13\/00UcvuLZr167y\/PPPi\/kUgHkuwIsvvmgPhZEQSCEBAn8KbRZTTV0BAn\/q7l26z5xQpbvDBCs9T3pTz5K+1LMk8DfN8vxPAGzdulWmTJmScEHz1YDx48cHH\/EP8\/WAhAfiRgRSXIDAn+IbyPRTQ4DAnxr75OMsCVW6u06w0vOkN\/Us6Us9y8gDf9ZtUr7LtRP+kzL9q+FO+GNJm5A+btw4ad68efDR\/xUrVsS65ZJ\/Nx\/hv\/\/++4NnAZivCJz\/3f64i3EDAh4IEPg92GSWmHwBAn\/y94AZXF6AUKXbGQQrPU96U8+SvtSzJPAnbllQUBCcxHfu3Dn4iP6YMWPkyJEjcRU0H+Hv169fcM+ZM2fk5z\/\/ucycOVOOHj0aVx0uRsAnAQK\/T7vNWpMmQOBPGj0DxxAgVOm2CMFKz5Pe1LOkL\/UsrQT+96\/Wm3CclXq2OynT+x2+7F19+\/aNs9p\/XG6+Z29+qq+wsFBqampk\/vz5Yj7SH+\/LPLHfnPC3atUq+MOB+YrA+++\/L9OnT5c\/\/OEP8ZbjegS8ECDwe7HNLDLZAgT+ZO8A4zckQKjS7Q2ClZ4nvalnSV\/qWaZ74DdSxXnHLgDrec1JuT3vWKiH9l1OukuXLsHT+M2T+c3T9s\/\/qb6m7Iz5ST7zUL\/c3FzZtm1b8H1+XgggcKkAgZ+uQMCCAIHfAjJDJCRAqEqIrcGbCFZ6nvSmniV9qWcZeeBvXSzlSTzhv5yUCfzT+\/0pocDfu3fv4En85jTenOyXlZXJpk2b1DbkkUcekZKSEvn000+DBwC+8847arUphEC6CBD402UnWYfTAgR+p7fH68kRqnS3n2Cl50lv6lnSl3qWBP7wluefwFdVVcmcOXNkx44d4QuEuHLgwIGfP+l\/2rRpsn379hB3cQkCfgkQ+P3ab1abJAECf5LgGTamAKEqJlFcFxCs4uJq9GJ6U8+SvtSzjDzwtyqW8vey9SasUCk44e9fHdcJf3FxsUycODH4uP2ePXuC79jv2rUr7tksXrw4+N7\/5s2bg68FXPwaPHiwPP7443L69Gkh8MfNyw2eCBD4PdlolplcAQJ\/cv0ZvWEBQpVudxCs9DzpTT1L+lLPksAf27KoqCh4QJ8J+zt37gyCuDnhT+T19NNPy9e\/\/nXZt2+fjB079pI6kydPDn6eb\/\/+\/Zf990TG5B4E0k2AwJ9uO8p6nBQg8Du5LUxKRAhVum1AsNLzpDf1LOlLPcvoA\/\/tsupd1074T8gPB4Q74TdPzTcP5evVq1cQwqdOnZrQyf65Hfva174mTz75pGRlZcnGjRuDp\/vX19cH\/2y+u\/\/9739frrjiClm1alUwLi8EELhUgMBPVyBgQYDAbwGZIRISIFQlxNbgTQQrPU96U8+SvtSzJPA3bmm+U29CvgnosV6VlZXBA\/3Mq0+fPsGnAjIzM2XRokVSXl7++e0jRoyQBx54IPi3jz\/+WKqrq4Of5uvQoUNwzZtvvhl8iuDcHwJijcu\/I+CbAIHftx1nvUkRIPAnhZ1BQwgQqkIgxXEJwSoOrBiX0pt6lvSlnmXkgf9Kc8KfozdhhUo9rzUn\/IdCfYd\/1KhRwcl7s2bNYo4cNvCbQv3795fhw4dLt27dguBfV1cXfLx\/+fLlsm7duphjcQECPgsQ+H3efdZuTYDAb42ageIUIFTFCRbjcoKVnie9qWdJX+pZEvj1LKmEAAJ2BAj8dpwZxXMBAr\/nDeDw8glVuptDsNLzpDf1LOlLPcvIA3\/L22XVTgdP+IvDnfDrSVMJAQS0BAj8WpLUQaARAQI\/7eGqAKFKd2cIVnqe9KaeJX2pZ0ng17OkEgII2BEg8NtxZhTPBQj8njeAw8snVOluDsFKz5Pe1LOkL\/Usow\/8A2XV7xw84b\/9YKjv8OtJUwkBBLQECPxaktRBgBN+eiAFBQhVuptGsNLzpDf1LOlLPUsCv54llRBAwI4Agd+OM6N4LsAJv+cN4PDyCVW6m0Ow0vOkN\/Us6Us9y6gD\/+8zzQl\/rt6EFSoVtj8hP7y9ihN+BUtKIJAMAQJ\/MtQZ02mBW265Jfgt2Ozs7Ebn+eqrr8rChQtDrYXAH4qJi5IgQKjSRSdY6XnSm3qW9KWeJYFfz5JKCCBgR4DAb8eZUVJIYNiwYTJ69Ojgd14bexH4U2hTmWqDAoQq3eYgWOl50pt6lvSlnmXkgb\/FQFn17w6e8N\/BCb9eF1EJAbsCBH673oyWAgKlpaVy3333yeHDh2XRokVSU1Nz2Vl\/+OGHcvDgwVAr4oQ\/FBMXJUGAUKWLTrDS86Q39SzpSz1LAr+eJZUQQMCOAIHfjjOjpJDA888\/L\/369ZMPPvhAHnroIamvr2\/y7An8TSakQEQChCpdWIKVnie9qWdJX+pZRh\/475Cf\/ptrJ\/zH5Zk7OeHX6yIqIWBXgMBv15vRHBcw39tfvHixdO3aVSorK2XSpEkqMybwqzBSJAIBQpUuKsFKz5Pe1LOkL\/UsCfx6llRCAAE7AgR+O86MkiICPXr0kLlz58q1114ry5cvlxdffFFl5gR+FUaKRCBAqNJFJVjpedKbepb0pZ5l1IF\/T8Yd8tPfttWbsEKlwi8cl6fvOsBT+hUsKYFAMgQI\/MlQZ0xnBQYPHiyPP\/54ML\/XXntNevXqJYWFhdKyZUupq6uT3bt3y8svvyxvvvlmXGsg8MfFxcUWBQhVutgEKz1PelPPkr7UsyTw61lSCQEE7AgQ+O04M0qKCIwYMUIefPBBadasmZw9e1aaN29+ycxN8F+9erWUlZWFXhWBPzQVF1oWIFTpghOs9DzpTT1L+lLPMvLA3\/wOed3BE\/6nBnHCr9dFVELArgCB3643ozkuMGfOHCkuLg5mWV1dLa+88opUVFQEP9F3\/\/33y5AhQyQnJ0dOnjwpS5YskZUrV4ZaEYE\/FBMXJUGAUKWLTrDS86Q39SzpSz1LAr+eJZUQQMCOAIHfjjOjpIjAwoULpWfPnvLJJ5\/I1KlTZdeuXRfM3PwxYOLEiZKbmxs8xX\/MmDFSW1sbc3UE\/phEXJAkAUKVLjzBSs+T3tSzpC\/1LKMO\/HuvuFNef8et7\/D36HBcnvpP+\/kOv14bUQkBqwIEfqvcDJYOAjNmzJC77rpLjh49KuYTAVu2bIm5LBP48\/IuvSwn9x+lTZsNMe\/nAgSiEiBU6coSrPQ86U09S\/oyMcvDf3pSTpz48gU319d3lB\/\/+MeybNmyxIo2cteiRYuEwK\/OSkEEvBcg8HvfAgDEK\/Cd73xHHn300eA28xN+5uF+sV4m8Ofnvy1Xtnr7gkuvvPJtycioinU7\/45AZAKEKl1agpWeJ72pZ0lfJmZpwr4J+Oe\/jtQ8JC+9tD6ywP+HK+6Uf\/l\/7p3wP3k3J\/yJdRF3IZB8AQJ\/8veAGaSYwLBhw2T06NHBrM1f+M33\/GO9+Eh\/LCH+PVkChCpdeYKVnie9qWdJX+pZRv2RfgK\/3l5RCQEE\/iJA4KcTEDhPICMjI\/gO\/6FDh+TgwYOXtTn3JP\/Tp0\/LP\/zDP8jrr78e05DAH5OIC5IkQKjShSdY6XnSm3qW9KWeZeSBv9mdsvrtdnoTVqhkvsM\/9Z59fIdfwZISCCRDgMCfDHXGdFKgT58+MmvWLGnTpo1UVlbKpEmTLjvPBQsWBP\/Rq6mpkSlTpsg777wTcz0E\/phEXJAkAUKVLjzBSs+T3tSzpC\/1LAn8epZUQgABOwIEfjvOjJICAtnZ2WKe0p+fnx+E+WnTpslbb711wczNT\/P94Ac\/kJYtW8q2bdtk\/PjxoVZG4A\/FxEVJECBU6aITrPQ86U09S\/pSzzLqwP+h3ClrHDvh797xuEzhhF+viaiEgGUBAr9lcIZzW2D48OFi\/p8J9IcPH5aXX35ZKioqJDMzUx5++GG55557pHXr1g3+QaCh1RH43d53n2dHqNLdfYKVnie9qWdJX+pZEvj1LKmEAAJ2BAj8dpwZJUUEzHf4n3jiCbn77ruDkH+5lzn9Lysrk02bNoVeFYE\/NBUXWhYgVOmCE6z0POlNPUv6Us8y6sD\/x7N3yZq33PoOf\/eOx2Tyf+Y7\/HpdRCUE7AoQ+O16M1qKCJjAf99998l1110nrVq1krNnz8rRo0c+thi8AAAgAElEQVRl+\/bt8uKLL0pVVXw\/pUfgT5GN93CahCrdTSdY6XnSm3qW9KWeJYFfz5JKCCBgR4DAb8eZUTwXIPB73gAOL59Qpbs5BCs9T3pTz5K+1LOMOvB\/dPYu+dn\/deuE\/\/qOx2TSNzjh1+siKiFgV4DAb9eb0TwVIPB7uvEpsGxCle4mEaz0POlNPUv6Us8y8sB\/5i554zeOBf5Ox2TiEAK\/XhdRCQG7AgR+u96M5qkAgd\/TjU+BZROqdDeJYKXnSW\/qWdKXepYEfj1LKiGAgB0BAr8dZ0bxXIDA73kDOLx8QpXu5hCs9DzpTT1L+lLPMurAv+\/0XbLWwRP+Cd\/khF+vi6iEgF0BAr9db0bzVIDA7+nGp8CyCVW6m0Sw0vOkN\/Us6Us9SwK\/niWVEEDAjgCB344zo3guQOD3vAEcXj6hSndzCFZ6nvSmniV9qWcZdeDfX3+XrN3h1nf4CzofkwlDOeHX6yIqIWBXgMBv15vRPBUg8Hu68SmwbEKV7iYRrPQ86U09S\/pSz5LAr2dJJQQQsCNA4LfjzCieCxD4PW8Ah5dPqNLdHIKVnie9qWdJX+pZRh\/475R1v3bthP+4PP4tTvj1uohKCNgVIPDb9WY0TwUI\/J5ufAosm1Clu0kEKz1PelPPkr7UsyTwh7PMyMiQkpISGTp0qLRt21ZatGghdXV1UlVVJcuXL5d169aFK\/TXq\/r37y\/Dhw+Xbt26SWZmppw5c0Zqa2tl8+bNsnjxYjl27Fhc9bgYAZ8ECPw+7TZrTZoAgT9p9AwcQ4BQpdsiBCs9T3pTz5K+1LOMOvAfOHWnrNvu3gn\/+HvDn\/Dn5OTIrFmzpKioSOrr66W6ujoI5+3bt5d27drJqVOnZPXq1VJWVhZqY0aNGiX33Xdf8EeDI0eOyMGDB6VVq1bSuXNnMX9Y2Llzp0yYMCH4N14IIHCpAIGfrkDAggCB3wIyQyQkQKhKiK3BmwhWep70pp4lfalnSeCPbTly5MjgdN+cui9cuFDWr18f3GTCeWlpqQwZMiQ47Z89e7Zs2bKl0YLmjwbmjwdt2rSRjRs3yvz584M\/IpjXoEGDgnrmDwzmf2c9\/\/zzsSfHFQh4KEDg93DTWbJ9AQK\/fXNGDCdAqArnFPYqglVYqdjX0ZuxjcJeQV+GlYp9XeSBv+5OWe\/aCf8Xj8tjIU\/4TahfunSpdO\/eXdauXRuE+vNf2dnZwR8B8vPzpaKiQmbMmNEo+pgxY+T++++XDz\/8UB599NFLTvHNyf63v\/1t+eijj2TcuHHB6T8vBBC4UIDAT0cgYEGAwG8BmSESEiBUJcTW4E0EKz1PelPPkr7UsyTwN26Zl5cXhPxOnTrJkiVLpLy8\/JIb5s2bJwMGDJDKykqZNGlSowWfeeYZGThwoPzqV7+67LXDhg2T0aNHy+HDh4OP9e\/du1dvs6mEQJoIEPjTZCNZhtsCBH6398fn2RGqdHefYKXnSW\/qWdKXepZRB\/6qk3fK+l+59R3+fHPC\/1\/Df4e\/Me3zPwGwdetWmTJlSpM259wnAA4cOCCPPfZYcNLPCwEELhQg8NMRCFgQIPBbQGaIhAQIVQmxNXgTwUrPk97Us6Qv9SwJ\/E2zNN\/fNx+9b968efDR\/xUrViRcsGPHjrJgwQLp0qWLbNu2TcaPH59wLW5EIJ0FCPzpvLuszRkBAr8zW8FELhIgVOm2BMFKz5Pe1LOkL\/UsrQT+bW31JqxQKTjhH7Zf+vbt26RqBQUFwcf9zdP1d+\/eLeZ0PtEn65tPCjz77LNifq7vs88+k+eee042bdrUpPlxMwLpKkDgT9edZV1OCRD4ndoOJnOeAKFKtx0IVnqe9KaeJX2pZ5nugd+E++\/dfegSsHZX1zcp8JvTePO0\/cLCQqmpqQmetm8+0p\/I6\/yn\/Zv716xZE5z080IAgcsLEPjpDAQsCBD4LSAzREIChKqE2Bq8iWCl50lv6lnSl3qWkQf+E3fKhl8m94T\/1p6fXgCWn3dcbr3hzwkHfvORe\/M0fvNk\/tra2gt+qi\/enTFhf+LEiXL33XcHt178U33x1uN6BHwQIPD7sMusMekCBP6kbwETaECAUKXbGgQrPU96U8+SvtSz9CHwX6xlAn\/pfYl9pL93797B0\/XNx\/jNyX5ZWVnCH73PycmRp556Sm699VY5ffq0vPHGG0G9+vp6vQ2mEgJpKEDgT8NNZUnuCRD43dsTZvQXAUKVbicQrPQ86U09S\/pSzzLqwH\/wePJP+C8X+Md9J\/7AP2jQICktLZXc3FypqqqSOXPmyI4dOxLaDPOVgJkzZwZfCairqwse9mce+scLAQRiCxD4YxtxBQJNFiDwN5mQAhEJEKp0YQlWep70pp4lfalnSeAPZ1lcXBx89N6E\/T179sj06dNl165d4W6+6Cpzsv\/CCy8EYf\/o0aPy0ksvyeuvv55QLW5CwEcBAr+Pu86arQsQ+K2TM2BIAUJVSKiQlxGsQkKFuIzeDIEU8hL6MiRUiMsiD\/zH7pANv0jud\/gvZsj\/m+My7v4Dob\/DX1RUFDygz4T9nTt3yrRp04IT\/kRe5jv7CxculF69ejX5KwGJjM89CKSDAIE\/HXaRNTgvQOB3fou8nSChSnfrCVZ6nvSmniV9qWdJ4G\/c8vyAvn\/\/fpk6dWrCJ\/tmpJEjR0pJSYmcOXNGlixZIitXrtTbTCoh4IkAgd+TjWaZyRUg8CfXn9EbFiBU6XYHwUrPk97Us6Qv9SxtBP6Kn7t3wj\/2u+FO+AcOHBiE\/KysrJjolZWVwQP9zKtPnz7BpwIyMzNl0aJFUl5eLtnZ2cHpvnm6f6zXgQMHZMKECbJ3795Yl\/LvCHgnQOD3bstZcDIECPzJUGfMMAKEqjBK4a8hWIW3inUlvRlLKPy\/05fhrWJdSeBvXGjUqFHBiXyzZs1iUUqswH\/LLbcEfwQwwT\/Wi8AfS4h\/91mAwO\/z7rN2awIEfmvUDBSnAKEqTrAYlxOs9DzpTT1L+lLPMvLA\/9kdUvHzXL0JK1Qy3+Ef+0BV6O\/wKwxJCQQQUBQg8CtiUgqBhgQI\/PSGqwKEKt2dIVjpedKbepb0pZ4lgV\/PkkoIIGBHgMBvx5lRPBcg8HveAA4vn1CluzkEKz1PelPPkr7Us4w88B+9QyredOyE\/7rjMraEE369LqISAnYFCPx2vRnNUwECv6cbnwLLJlTpbhLBSs+T3tSzpC\/1LAn8epZUQgABOwIEfjvOjOK5AIHf8wZwePmEKt3NIVjpedKbepb0pZ5l1IH\/0NGBUlHp1gl\/t+tOyNj\/xgm\/XhdRCQG7AgR+u96M5qkAgd\/TjU+BZROqdDeJYKXnSW\/qWdKXepYEfj1LKiGAgB0BAr8dZ0bxXIDA73kDOLx8QpXu5hCs9DzpTT1L+lLPMvLA\/+eBUvF\/HDzhf5ATfr0uohICdgUI\/Ha9Gc1TAQK\/pxufAssmVOluEsFKz5Pe1LOkL\/UsCfx6llRCAAE7AgR+O86M4rkAgd\/zBmD5CCAQtwCBP24ybrAg8MTsfHlz+2uybNky9dEWLVokhz41J\/w56rWbUrBblxMy9sGD0rdv36aU4V4EEEiSAIE\/SfAM65cAgd+v\/Wa1CCDQdAECf9MNqaAvQODXN6UiAghEK0Dgj9aX6ggEAgR+GgEBBBCIT4DAH58XV9sRiD7w3y4VWx084R9+iBN+Oy3GKAioCxD41UkpiMClAgR+ugIBBBCIT4DAH58XV9sRIPDbcWYUBBDQEyDw61lSCYEGBQj8NAcCCCAQnwCBPz4vrrYjEHngr71dKv53tp3FhBwl+A7\/Q9Wc8If04jIEXBMg8Lu2I8wnLQUI\/Gm5rSwKAQQiFCDwR4hL6YQFCPwJ03EjAggkSYDAnyR4hvVLgMDv136zWgQQaLoAgb\/phlTQF4g88B9x8IS\/Kyf8+p1ERQTsCRD47VkzkscCBH6PN5+lI4BAQgIE\/oTYuCliAQJ\/xMCURwABdQECvzopBRG4VIDAT1cggAAC8QkQ+OPz4mo7ApEH\/ppi2bjFse\/wdz0pY77Pd\/jtdBijIKAvQODXN6UiApcIEPhpCgQQQCA+AQJ\/fF5cbUeAwG\/HmVEQQEBPgMCvZ0klBBoUIPDTHAgggEB8AgT++Ly42o6AlcC\/+Wo7iwk5Sjdzwj\/iTzylP6QXlyHgmgCB37UdYT5pKUDgT8ttZVEIIBChAIE\/QlxKJyxA4E+YjhsRQCBJAgT+JMEzrF8CBH6\/9pvVIoBA0wUI\/E03pIK+QOSB\/5PbZKNrJ\/xfMif8hznh128nKiJgRYDAb4WZQXwXIPD73gGsHwEE4hUg8McrxvU2BCIP\/B\/fJhv\/9SobSwk9RjcT+H\/wMYE\/tBgXIuCWAIHfrf1gNmkqQOBP041lWQggEJkAgT8yWgo3QYDA3wQ8bkUAgaQIEPiTws6gvgkQ+H3bcdaLAAJNFSDwN1WQ+6MQiD7wD5CN\/8u1E\/46GfMIJ\/xR9BM1EbAhQOC3ocwY3gsQ+L1vAQAQQCBOAQJ\/nGBcbkWAwG+FmUEQQEBRgMCviEkpBBoSIPDTGwgggEB8AgT++Ly42o5A5IH\/sDnhb2NnMSFH6fa35oT\/E77DH9KLyxBwTYDA79qOMJ+0FCDwp+W2sigEEIhQgMAfIS6lExYg8CdMx40IIJAkAQJ\/kuAZ1i8BAr9f+81qEUCg6QIE\/qYbUkFfIPLA\/6f+snGTgyf8o2o44ddvJyoiYEWAwG+FmUF8FyDw+94BrB8BBOIVIPDHK8b1NgQI\/DaUGQMBBDQFCPyamtRCoAEBAj+tgQACCMQnQOCPz4ur7QhEH\/i\/Jhv\/Z5adxYQcpdvfnpIxo49wwh\/Si8sQcE2AwO\/ajjCftBQg8KfltrIoBBCIUIDAHyEupRMWIPAnTMeNCCCQJAECf5LgGdYvAQK\/X\/vNahFAoOkCBP6mG1JBXyDywF\/9Ndm4sbX+xJtQsVu3UzLm72s54W+CIbcikEwBAn8y9RnbGwECvzdbzUIRQEBJgMCvBEkZVQECvyonxRBAwIIAgd8CMkMgQOCnBxBAAIH4BAj88XlxtR2ByAP\/oX5unvCP+TSuE\/6MjAwpKSmRoUOHStu2baVFixZSV1cnVVVVsnz5clm3bl3CG5aTkyM\/+tGP5Oqrr5YJEybI3r17E67FjQj4IEDg92GXWWPSBQj8Sd8CJoAAAikmQOBPsQ3zZLoE\/tgbbQL5rFmzpKioSOrr66W6ulpqa2ulffv20q5dOzl16pSsXr1aysrKYhe76IrWrVvLM888I\/379w\/+eEDgj5uQGzwUIPB7uOks2b4Agd++OSMigEBqCxD4U3v\/0nX2kQf+g\/2koqKVU3zd8k\/J2LF\/Dn3CP3LkyOB0\/9ixY7Jw4UJZv359sB5z6l9aWipDhgwJTvtnz54tW7ZsCb3Wjh07ytNPPy0333yzNGvWTA4cOEDgD63HhT4LEPh93n3Wbk2AwG+NmoEQQCBNBAj8abKRabYMAn\/jG2pC\/dKlS6V79+6ydu3aINSf\/8rOzg7+CJCfny8VFRUyY8aMmB1iTvXNHxC+9a1vifn0wJkzZ4LAzwl\/TDouQCAQIPDTCAhYECDwW0BmCAQQSCsBAn9abWfaLCb6wP9VqdhwpVNe3fLrZey4o6FO+PPy8oKQ36lTJ1myZImUl5dfspZ58+bJgAEDpLKyUiZNmhRzrcOGDZPRo0cHzwH48MMPZfv27UH4P3z4MCf8MfW4AAECPz2AgBUBAr8VZgZBAIE0EiDwp9FmptFSCPxN28zzPwGwdetWmTJlSsyC9957r5jQv2bNGlm1apV8+9vfDv4AQOCPSccFCAQCnPDTCAhcRuDc02UHDx4cPGQmMzOzSU+XJfDTZggggEB8AgT++Ly42o5A5IG\/qq+bJ\/yln4U64Y+1C+b7++PGjZPmzZsHH\/1fsWJFrFsu+fdzJ\/4E\/rjpuMFTAQK\/pxvPshsWOP\/psuY7Yhe\/zINm4n26LIGfjkMAAQTiEyDwx+fF1XYECPyJOxcUFAQf9+\/cubPs3r1bxowZI0eOHIm7IIE\/bjJu8FyAwO95A7D8SwXmzp0bfLfMvH73u98FD5fZuXOnfOMb35CHHnpIrrnmGjl69Kg899xzsmnTplCEBP5QTFyEAAIIfC5A4KcZXBSIPPAfuFUq1rdM2tK7FZyWku+duGT8tu3ONOmE3zxh3\/xUX2FhodTU1Mj8+fPFfKQ\/kReBPxE17vFZgMDv8+6z9ksEBg4cKFOnTpWsrCz59a9\/LY8\/\/njwG7LnXoMGDZInnnhC2rRpE\/phM+ZeAj\/NhgACCMQnQOCPz4ur7Qike+A3wb7PracuwGzb7qz06Xsq4cDfpUuX4Gn85sn8tbW1F\/xUXyK7RuBPRI17fBYg8Pu8+6z9EgHz+65f\/\/rXg78+m\/\/\/b37zmwuuMd\/tX7RoUfBzM++995489thjwe\/MxnoR+GMJ8e8IIIDAhQIEfjrCRQErgX9dplNLN6f+Y8cfTyjw9+7dO3gSv\/kYv\/nfVmVlZaE\/HdkQAoHfqfZgMikgQOBPgU1iinYEzG\/DLl68WLp27So7duyQsWPHqg1M4FejpBACCHgiQOD3ZKNTbJkE\/vAbZj4VWVpaKrm5uVJVVSVz5swJ\/vdVU18E\/qYKcr9vAgR+33ac9TYocPPNNwf\/MTL\/YXr11VeDj5xpvQj8WpLUQQABXwQI\/L7sdGqtM\/LAv7+PVKxt4RRKcMI\/4WRcJ\/zFxcUyceLE4H9T7dmzR6ZPny67du1SWReBX4WRIh4JEPg92myW2riA+f6++T1Y8xN85mP7b731VvDTMTfeeKO0bNmSn+WjgRBAAAGLAgR+i9gMFVqAwB+bqqioKHhAnwn75qHH06ZNC074tV4Efi1J6vgiQOD3ZadZZ0yBc\/8BMRdu3rxZ+vfvHzyc7+IXP8sXk5ILEEAAgSYLEPibTEiBCAQiD\/z7viIVazMimHniJbtdf0bGTqgLdcJvnnVkPiHZq1cv2b9\/f\/AgZK2T\/XMrIPAnvpfc6acAgd\/PfWfVlxE49x+QFi1ayNmzZ+XEiROyYcMGWbZsWXC6bx7m973vfU\/at28vJ0+elCVLlsjKlStDWfKR\/lBMXIQAAgh8LkDgpxlcFCDwN74r5\/\/aUaz9q6ysDB7oZ159+vQJPhVw7lOW5eXlDd5O4I8ly78jcKEAgZ+OQOCvAuf+A2L+Y9NQoL\/ppptk5syZQej\/4IMPZMyYMcFPzMR6mcCfn\/+2ZGRc+JG2K1u9LVde+Xas2\/l3BBBAwDsBAr93W+7cgr96R1u5pv2FT8z\/6p3tZM0brwSHAdov83XCg\/t6S8Ubbp3w55sT\/ifC\/SzfqFGjpKSkRJo1axaTh8Afk4gLEFARIPCrMFIkHQTOD\/y\/\/e1vZfTo0VJfX3\/J0iZPnizf\/OY3g6Bvvpd28U\/3Xc7CBP68PJGMjIMX\/HNO7jICfzo0D2tAAAF1AQK\/OikF4xQYcn8Huf7Gqy646\/ob28iPf\/xjAn+cllyOAALJEyDwJ8+ekR0T6NevX\/AU2aysLDn\/r84XT9N8rP\/hhx+W06dPywsvvCDr16+PuRI+0h+TiAsQQACBCwQI\/DSEiwJRf6T\/4Ee3SMXPmju19Pzrz8rYSfWhvsPv1MSZDAIIBAIEfhoBgb8K9OjRQ+bOnRt8XL+xwD9ixAh58MEH5fjx48HP+G3ZsiWmIYE\/JhEXIIAAAgR+esB5AQK\/81vEBBFA4CIBAj8tgcB5Ai+99JLcfPPNsm\/fPhk7duxlf0ZmxowZctddd0l1dbWYj\/e\/++67MQ0J\/DGJuAABBBAg8NMDzgtEHvj\/+HdS8bMrnHLI725O+M9wwu\/UrjAZBMILEPjDW3GlBwIjR44MHjZjXmvWrJEFCxZcsOri4mKZOHFi8Nuy27Ztk\/Hjx4dSIfCHYuIiBBBA4HMBPtJPM7goQOB3cVeYEwIINCZA4Kc\/EDhPICcnJ\/hefmFhYfBTfJs3b5ZXXnklOM03P8s3fPhwueaaa4IH9pmP\/2\/dujWUH4E\/FBMXIYAAAgR+esBpgegDf5FUrHGLIL+7yNjJwgm\/W9vCbBAILUDgD03Fhb4IFBQUyDPPPCNf+tKXLrtk85N9K1askKVLl4YmIfCHpuJCBBBAIBDghJ9GcFGAwO\/irjAnBBBoTIDAT38gcBmB1q1byyOPPCK33XZbcKJ\/xRVXiAn6O3fulH\/6p3+S7du3x+VG4I+Li4sRQAABAj894KRA5IH\/wy\/LhjVnnVq7OeEfN+UKTvid2hUmg0B4AQJ\/eCuuRCBhAQJ\/wnTciAACngpwwu\/pxju+bAK\/4xvE9BBA4BIBAj9NgYAFAQK\/BWSGQACBtBIg8KfVdqbNYqIP\/L1kw+ozTnnl92gm46Y054TfqV1hMgiEFyDwh7fiSgQSFiDwJ0zHjQgg4KkAgd\/TjXd82QR+xzeI6SGAACf89AACyRAg8CdDnTERQCCVBQj8qbx76Tv3yAP\/H26SDf9y2inA\/B5XyLgnW3DC79SuMBkEwgtwwh\/eiisRSFiAwJ8wHTcigICnAgR+Tzfe8WUT+B3fIKaHAAKc8NMDCCRDgMCfDHXGRACBVBYg8Kfy7qXv3KMO\/FV7b5QN\/1LvFKA54S+d1pITfqd2hckgEF6AE\/7wVlyJQMICBP6E6bgRAQQ8FSDwe7rxji87+sB\/g2x4vc4phfwezaX0qVYEfqd2hckgEF6AwB\/eiisRSFiAwJ8wHTcigICnAgR+Tzfe8WUT+B3fIKaHAAKXCBD4aQoELAgQ+C0gMwQCCKSVAIE\/rbYzbRYTeeDfUyjrXz\/plFd+YYY89lQWJ\/xO7QqTQSC8AIE\/vBVXIpCwAIE\/YTpuRAABTwUI\/J5uvOPLJvA7vkFMDwEEOOGnBxBIhgCBPxnqjIkAAqksQOBP5d1L37lHH\/h7yPqfnnAKMDjhf\/oqTvid2hUmg0B4AU74w1txJQIJCxD4E6bjRgQQ8FSAwO\/pxju+bAK\/4xvE9BBAgBN+egCBZAgQ+JOhzpgIIJDKAgT+VN699J175IH\/991l\/U+POQWYX9hCHnsmmxN+p3aFySAQXoAT\/vBWXIlAwgIE\/oTpuBEBBDwVIPB7uvGOL5vA7\/gGMT0EEOCEnx5AIBkCBP5kqDMmAgiksgCBP5V3L33nHnXgP\/D7Alm\/6jOnAAsKM+WxH+Zywu\/UrjAZBMILcMIf3oorEUhYgMCfMB03IoCApwIEfk833vFlE\/gd3yCmhwACnPDTAwgkQ4DAnwx1xkQAgVQWIPCn8u6l79wjD\/y782X9qj87BVjQ05zwX8MJv1O7wmQQCC\/ACX94K65EIGEBAn\/CdNyIAAKeChD4Pd14x5dN4Hd8g5geAghwwk8PIJAMAQJ\/MtQZEwEEUlmAwJ\/Ku5e+c48+8HeTdeWfOgVY0LOljJ9+LSf8Tu0Kk0EgvAAn\/OGtuBKBhAUI\/AnTcSMCCHgqQOD3dOMdXzaB3\/ENYnoIIMAJPz2AQDIECPzJUGdMBBBIZQECfyrvXvrOPfLA\/8GXZF15rVOABT2vlPEzvsAJv1O7wmQQCC\/ACX94K65EIGEBAn\/CdNyIAAKeChD4Pd14x5dN4Hd8g5geAghwwk8PIJAMAQJ\/MtQZEwEEUlmAwJ\/Ku5e+c4868O\/\/oKus+0mNU4DmhP\/xmZ044XdqV5gMAuEFOOEPb8WVCCQsQOBPmI4bEUDAUwECv6cb7\/iyCfyObxDTQwABTvjpAQSSIUDgT4Y6YyKAQCoLEPhTeffSd+6RB\/5d18m6n3ziFGDBDa3k8Zlf5ITfqV1hMgiEF+CEP7wVVyKQsACBP2E6bkQAAU8FCPyebrzjyybwh9ugjIwMKSkpkaFDh0rbtm2lRYsWUldXJ1VVVbJ8+XJZt25duEJchQACTRYg8DeZkAIIxBYg8Mc24goEEEDgfAECP\/3gokD0gf9vZO1rHzu19IIbWsuEWXmhT\/hzcnJk1qxZUlRUJPX19VJdXS21tbXSvn17adeunZw6dUpWr14tZWVlTq2TySCQrgIE\/nTdWdbllACB36ntYDIIIJACAgT+FNgkD6dI4I+96SNHjgxO948dOyYLFy6U9evXBzeZU\/\/S0lIZMmRIcNo\/e\/Zs2bJlS+yCXIEAAk0SIPA3iY+bEQgnkAqB\/8SJL8uRmoelQ8e\/D7cormpU4PCfnpQ2V22QK698G6kmChw9eo\/Un+ogObn\/2MRK3F5f31FMb15z7bOSkVHlNEgqBP7\/XnqdvP9vf5ZfbnbrO9dOb2wDk\/vqHW3lmvaZ8sbKg05PP\/LA\/36erH3tT04ZBCf8z3YJdcJvQv3SpUule\/fusnbt2iDUn\/\/Kzs4O\/giQn58vFRUVMmPGDKfWymQQSEcBAn867iprck4gVQL\/war\/IV269nPOLxUntO+jnwYBtU2bDak4fafmfKTmITlxoog\/Rinsign8pje\/mPdfCPwKnnOX9ZRf\/uvHzodUhaVGXmLI\/R3k+huvkuemfhD5WE0ZgMDfuF5eXl4Q8jt16iRLliyR8vLyS26YN2+eDBgwQCorK2XSpElN2Q7uRQCBEAIE\/hBIXIJAUwUI\/E0VTL37Cfx6e0bg17Mk8OtZmkoEfj1PAr\/IokWLZN\/7nWXtymo9WIVK19+QJRNmfynUCX+s4c7\/BMDWrVtlypQpsW7h3xFAoIkCBP4mAnI7AmEECPxhlNLrGgK\/3n4S+PUsCfx6lgR+XUsCvx+B33x\/f9y4cdK8efPgo\/8rVqzQbSSqIYDAJQIEfpoCAQsCBH4LyI4NQeDX2xACv54lgV\/PksCva0ng\/2vgf6+jrHXsOQbX39hGJszOb\/IJf0FBQfBx\/86dO8vu3btlzJgxcuTIEd1GohoCCBD46QEEkiFgAn9ennlCrdsPIzIP7uMhczodYizNQ9Fc33Od1UZbpb6+g5igSm\/qOKfK+\/ydHfk6C46wiglCh6vr5ONDdRGO4kfpdl\/IDB7a9\/6\/HYv2gzwAAAdUSURBVHV6wWaea954RZYtW6Y+T\/OR\/uu+eIMcdrCfTK\/37ds34TV37Ngx+Km+wsJCqampkfnz54v5SD8vBBCIXoAT\/uiNGQEBefjhh1FAAAEEEEAAgTQQePvtt+Wtt95SX8ngwYOlQ4cO6nW1Cib6R44uXboET+M3T+avra294Kf6tOZGHQQQaFiAwE93IIAAAggggAACCCCAgLpA7969gyfxm4\/xm5P9srIy2bRpk\/o4FEQAAQI\/PYAAAggggAACCCCAAAKWBAYNGiSlpaWSm5srVVVVMmfOHNmxY4el0RkGAQTOCXDCTy8ggAACCCCAAAIIIICAmkBxcbFMnDgxCPt79uyR6dOny65du9TqUwgBBMILEPjDW3ElAggggAACCCCAAAIINCJQVFQUPKDPhP2dO3fKtGnTghN+XgggkBwBAn9y3BkVAQQQQAABBBBAAIG0EsjIyAgeyterVy\/Zv3+\/TJ06lZP9tNphFpOKAgT+VNw15owAAggggAACCCCAgGMCAwcODEJ+VlZWzJlVVlYGD\/TjhQAC0QoQ+KP1pToCCCCAAAIIIIAAAl4IjBo1SkpKSqRZs2Yx10vgj0nEBQioCBD4VRgpggACCCCAAAIIIIAAAggggIBbAgR+t\/aD2SCAAAIIIIAAAggggAACCCCgIkDgV2GkCAIIIIAAAggggAACCCCAAAJuCRD43doPZoMAAggggAACCCCAAAIIIICAigCBX4WRIggggAACCCCAAAIIIIAAAgi4JUDgd2s\/mA0CCCCAAAIIIIAAAggggAACKgIEfhVGiiCAAAIIIIAAAggggAACCCDglgCB3639YDYIIIAAAggggAACCCCAAAIIqAgQ+FUYKYIAAggggAACCCCAAAIIIICAWwIEfrf2g9kggAACCCCAAAIIIIAAAgggoCJA4FdhpAgCCCCAAAIIIIAAAggggAACbgkQ+N3aD2aDAAIIIIAAAggggAACCCCAgIoAgV+FkSIIIIAAAggggAACCCCAAAIIuCVA4HdrP5gNAggggAACCCCAAAIIIIAAAioCBH4VRooggAACCCCAAAIIIIAAAggg4JYAgd+t\/WA2CCCAAAIIIIAAAggggAACCKgIEPhVGCmCAAIIIIAAAggggAACCCCAgFsCBH639oPZIIAAAggggAACCCCAAAIIIKAiQOBXYaQIAggggAACCCCAAAIIIIAAAm4JEPjd2g9mgwACCCCAAAIIIIAAAggggICKAIFfhZEiCCCAAAIIIIAAAggggAACCLglQOB3az+YDQIIIIAAAggggAACCCCAAAIqAgR+FUaKIIAAAggggAACCCCAAAIIIOCWAIHfrf1gNggggAACCCCAAAIIIIAAAgioCBD4VRgpggACCCCAAAIIIIAAAggggIBbAgR+t\/aD2SCAAAIIIIAAAggggAACCCCgIkDgV2GkCAIIIIAAAggggAACCCCAAAJuCRD43doPZoMAAggggAACCCCAAAIIIICAigCBX4WRIggggAACCCCAAAIIIIAAAgi4JUDgd2s\/mA0CCCCAAAIIIIAAAggggAACKgIEfhVGiiCAAAIIIIAAAggggAACCCDglgCB3639YDYIIIAAAggggAACCCCAAAIIqAgQ+FUYKYIAAggggAACCCCAAAIIIICAWwIEfrf2g9kggAACCCCAAAIIIIAAAgggoCJA4FdhpAgCCCCAAAIIIIAAAggggAACbgkQ+N3aD2aDAAIIIIAAAggggAACCCCAgIoAgV+FkSIIIIAAAggggAACCCCAAAIIuCVA4HdrP5gNAggggAACCCCAAAIIIIAAAioCBH4VRooggAACCCCAAAIIIIAAAggg4JYAgd+t\/WA2CCCAAAIIIIAAAggggAACCKgIEPhVGCmCAAIIIIAAAggggAACCCCAgFsCBH639oPZIIAAAggggAACCCCAAAIIIKAiQOBXYaQIAggggAACCCCAAAIIIIAAAm4JEPjd2g9mgwACCCCAAAIIIIAAAggggICKAIFfhZEiCCCAAAIIIIAAAggggAACCLglQOB3az+YDQIIIIAAAggggAACCCCAAAIqAgR+FUaKIIAAAggggAACCCCAAAIIIOCWAIHfrf1gNggggAACCCCAAAIIIIAAAgioCBD4VRgpggACCCCAAAIIIIAAAggggIBbAgR+t\/aD2SCAAAIIIIAAAggggAACCCCgIkDgV2GkCAIIIIAAAggggAACCCCAAAJuCRD43doPZoMAAggggAACCCCAAAIIIICAigCBX4WRIggggAACCCCAAAIIIIAAAgi4JUDgd2s\/mA0CCCCAAAIIIIAAAggggAACKgIEfhVGiiCAAAIIIIAAAggggAACCCDglgCB3639YDYIIIAAAggggAACCCCAAAIIqAgQ+FUYKYIAAggggAACCCCAAAIIIICAWwIEfrf2g9kggAACCCCAAAIIIIAAAgggoCJA4FdhpAgCCCCAAAIIIIAAAggggAACbgn8fzRZKepES9rZAAAAAElFTkSuQmCC","height":319,"width":530}}
%---
%[output:57ddf0e4]
%   data: {"dataType":"text","outputData":{"text":"Generating 5 6x6 squares without replacement. Balancing mode is: both. The maximum number of search iterations is set to 1e+06...\n\nThere are 720 permutations of 1-6. Each permutation pairs with 102 of the others (14.17%).\n\nThe chance of randomly selecting a valid set to form a square is roughly 1 in 7e+101.\nThis script uses a heuristic method that is much more efficient, but this should give you an idea of how long it might take to run.\n\nGenerating balanced square 1 of 5...found a solution after 18 iterations\nGenerating balanced square 2 of 5...found a solution after 23 iterations\nGenerating balanced square 3 of 5...found a solution after 27 iterations\nGenerating balanced square 4 of 5...found a solution after 24 iterations\nGenerating balanced square 5 of 5...found a solution after 7 iterations\n","truncated":false}}
%---
%[output:6b2dc679]
%   data: {"dataType":"text","outputData":{"text":"Par x Run order of first main conditions:\n","truncated":false}}
%---
%[output:189567f7]
%   data: {"dataType":"text","outputData":{"text":"    \"2D_Object\"    \"3D_Object\"    \"2D_Face\"      \"3D_Hand\"      \"2D_Hand\"      \"3D_Face\"      \"2D_Object\"    \"2D_Hand\"  \n    \"2D_Hand\"      \"2D_Face\"      \"3D_Face\"      \"2D_Object\"    \"3D_Hand\"      \"3D_Object\"    \"3D_Hand\"      \"3D_Face\"  \n    \"2D_Face\"      \"2D_Object\"    \"2D_Hand\"      \"3D_Object\"    \"3D_Face\"      \"3D_Hand\"      \"2D_Face\"      \"3D_Object\"\n    \"3D_Object\"    \"3D_Hand\"      \"2D_Object\"    \"3D_Face\"      \"2D_Face\"      \"2D_Hand\"      \"3D_Object\"    \"2D_Object\"\n    \"3D_Hand\"      \"3D_Face\"      \"3D_Object\"    \"2D_Hand\"      \"2D_Object\"    \"2D_Face\"      \"2D_Hand\"      \"2D_Face\"  \n    \"3D_Face\"      \"2D_Hand\"      \"3D_Hand\"      \"2D_Face\"      \"3D_Object\"    \"2D_Object\"    \"3D_Hand\"      \"3D_Face\"  \n    \"2D_Hand\"      \"2D_Object\"    \"3D_Face\"      \"3D_Hand\"      \"2D_Face\"      \"3D_Object\"    \"3D_Hand\"      \"3D_Face\"  \n    \"3D_Hand\"      \"3D_Object\"    \"2D_Object\"    \"2D_Face\"      \"2D_Hand\"      \"3D_Face\"      \"2D_Face\"      \"2D_Object\"\n    \"2D_Face\"      \"3D_Face\"      \"3D_Object\"    \"2D_Hand\"      \"3D_Hand\"      \"2D_Object\"    \"3D_Object\"    \"2D_Hand\"  \n    \"2D_Object\"    \"3D_Hand\"      \"2D_Hand\"      \"3D_Object\"    \"3D_Face\"      \"2D_Face\"      \"2D_Hand\"      \"3D_Hand\"  \n    \"3D_Face\"      \"2D_Hand\"      \"2D_Face\"      \"2D_Object\"    \"3D_Object\"    \"3D_Hand\"      \"2D_Face\"      \"3D_Object\"\n    \"3D_Object\"    \"2D_Face\"      \"3D_Hand\"      \"3D_Face\"      \"2D_Object\"    \"2D_Hand\"      \"2D_Object\"    \"3D_Face\"  \n    \"2D_Hand\"      \"3D_Hand\"      \"3D_Face\"      \"3D_Object\"    \"2D_Object\"    \"2D_Face\"      \"3D_Hand\"      \"3D_Face\"  \n    \"2D_Face\"      \"2D_Object\"    \"3D_Object\"    \"3D_Face\"      \"3D_Hand\"      \"2D_Hand\"      \"2D_Face\"      \"2D_Object\"\n    \"3D_Hand\"      \"3D_Object\"    \"2D_Face\"      \"2D_Hand\"      \"3D_Face\"      \"2D_Object\"    \"2D_Hand\"      \"3D_Object\"\n    \"3D_Object\"    \"2D_Hand\"      \"2D_Object\"    \"3D_Hand\"      \"2D_Face\"      \"3D_Face\"      \"3D_Hand\"      \"3D_Object\"\n    \"3D_Face\"      \"2D_Face\"      \"3D_Hand\"      \"2D_Object\"    \"2D_Hand\"      \"3D_Object\"    \"2D_Face\"      \"2D_Object\"\n    \"2D_Object\"    \"3D_Face\"      \"2D_Hand\"      \"2D_Face\"      \"3D_Object\"    \"3D_Hand\"      \"2D_Hand\"      \"3D_Face\"  \n    \"2D_Object\"    \"3D_Object\"    \"2D_Hand\"      \"2D_Face\"      \"3D_Face\"      \"3D_Hand\"      \"3D_Face\"      \"2D_Face\"  \n    \"3D_Face\"      \"2D_Hand\"      \"3D_Hand\"      \"2D_Object\"    \"2D_Face\"      \"3D_Object\"    \"3D_Hand\"      \"2D_Hand\"  \n    \"3D_Object\"    \"2D_Face\"      \"2D_Object\"    \"3D_Hand\"      \"2D_Hand\"      \"3D_Face\"      \"3D_Object\"    \"2D_Object\"\n    \"3D_Hand\"      \"3D_Face\"      \"2D_Face\"      \"2D_Hand\"      \"3D_Object\"    \"2D_Object\"    \"3D_Face\"      \"2D_Object\"\n    \"2D_Face\"      \"3D_Hand\"      \"3D_Object\"    \"3D_Face\"      \"2D_Object\"    \"2D_Hand\"      \"2D_Face\"      \"3D_Hand\"  \n    \"2D_Hand\"      \"2D_Object\"    \"3D_Face\"      \"3D_Object\"    \"3D_Hand\"      \"2D_Face\"      \"3D_Object\"    \"2D_Hand\"  \n    \"3D_Object\"    \"2D_Face\"      \"3D_Face\"      \"3D_Hand\"      \"2D_Object\"    \"2D_Hand\"      \"2D_Face\"      \"3D_Face\"  \n    \"2D_Hand\"      \"2D_Object\"    \"3D_Hand\"      \"3D_Face\"      \"2D_Face\"      \"3D_Object\"    \"2D_Object\"    \"3D_Hand\"  \n    \"3D_Face\"      \"3D_Object\"    \"2D_Object\"    \"2D_Face\"      \"2D_Hand\"      \"3D_Hand\"      \"3D_Object\"    \"2D_Hand\"  \n    \"2D_Face\"      \"3D_Hand\"      \"3D_Object\"    \"2D_Hand\"      \"3D_Face\"      \"2D_Object\"    \"3D_Face\"      \"3D_Object\"\n    \"3D_Hand\"      \"2D_Hand\"      \"2D_Face\"      \"2D_Object\"    \"3D_Object\"    \"3D_Face\"      \"2D_Face\"      \"2D_Object\"\n    \"2D_Object\"    \"3D_Face\"      \"2D_Hand\"      \"3D_Object\"    \"3D_Hand\"      \"2D_Face\"      \"2D_Hand\"      \"3D_Hand\"  \n\n","truncated":false}}
%---
%[output:1ee9e075]
%   data: {"dataType":"text","outputData":{"text":"Orders will be written to: ..\\Orders\\\n","truncated":false}}
%---
%[output:66913520]
%   data: {"dataType":"text","outputData":{"text":"Participant 1 of 30:\n","truncated":false}}
%---
%[output:375cf1ce]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:1e22fb87]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 46 1 30 15 9 44 45 58 55 35 82 21 88 3 80 41 67 13 54 85 95 49 68 89 77 20 18 39 31 52 14 96 40 69 60 27 78 65 73 94 71 17 75 5 42 87 24 25 8 2 76 37 22 59 7 63 29 83 62 36 34 56 70 50 84 81 16 93 43 12 19 33 51 53 28 79 64 91 48 74 23 10 90 26 92 61 47 4 72 11 38 86 6 32 57 66\n","truncated":false}}
%---
%[output:941f71bc]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [75 81] at positions [43 66]\n","truncated":false}}
%---
%[output:327e53b3]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 5 6 9 10 15 20 21 27 38 39 40 46 48 49 50 54 61 64 65 69 75 78 79 82 87 88 89 92 94 95\n","truncated":false}}
%---
%[output:0915e614]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR01_RUN01.xlsx\n","truncated":false}}
%---
%[output:50520a15]
%   data: {"dataType":"text","outputData":{"text":"Participant 2 of 30:\n","truncated":false}}
%---
%[output:757abf16]
%   data: {"dataType":"text","outputData":{"text":"Participant 3 of 30:\n","truncated":false}}
%---
%[output:7222a736]
%   data: {"dataType":"text","outputData":{"text":"Participant 4 of 30:\n","truncated":false}}
%---
%[output:95b79e57]
%   data: {"dataType":"text","outputData":{"text":"Participant 5 of 30:\n","truncated":false}}
%---
%[output:1dd365e4]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR01_RUN02.xlsx\n","truncated":false}}
%---
%[output:6d9a1fee]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 8 12 13 16 20 21 23 27 28 35 38 39 43 44 45 51 54 60 68 69 73 74 80 82 83 84 86 87 88 91 97\n","truncated":false}}
%---
%[output:7c83b789]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [78 50] at positions [3 53]\n","truncated":false}}
%---
%[output:673cf78d]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 82 37 78 32 49 60 47 10 61 66 77 59 23 93 19 45 29 31 7 16 41 57 87 52 5 86 65 3 18 68 48 43 92 4 69 96 88 89 20 95 11 73 91 55 42 15 44 33 75 36 26 35 50 8 6 51 76 2 17 13 94 79 54 24 53 90 40 83 72 80 28 71 25 30 14 63 62 27 74 34 67 64 38 58 1 70 81 21 46 85 39 9 84 12 22 56\n","truncated":false}}
%---
%[output:30d2e960]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:0491808d]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR01_RUN03.xlsx\n","truncated":false}}
%---
%[output:60d97b2b]
%   data: {"dataType":"text","outputData":{"text":"Participant 6 of 30:\n","truncated":false}}
%---
%[output:8b8a1577]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 6 9 11 13 15 19 21 22 24 25 27 33 44 45 46 52 57 62 63 66 68 70 71 73 80 83 84 86 87 89 96\n","truncated":false}}
%---
%[output:92ff5336]
%   data: {"dataType":"text","outputData":{"text":"Participant 7 of 30:\n","truncated":false}}
%---
%[output:524e02d7]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [6 18] at positions [37 62]\n","truncated":false}}
%---
%[output:257219d5]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR01_RUN04.xlsx\n","truncated":false}}
%---
%[output:66c102cd]
%   data: {"dataType":"text","outputData":{"text":"Participant 8 of 30:\n","truncated":false}}
%---
%[output:278f4cc0]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 9 51 80 86 67 66 21 76 61 3 36 24 41 65 7 90 22 63 88 93 62 48 55 50 26 17 1 70 39 15 28 91 45 35 85 11 6 34 49 10 4 84 2 69 46 95 79 52 44 13 29 25 47 42 75 12 60 92 31 54 72 18 77 68 94 33 19 14 96 59 20 82 83 16 23 78 32 8 53 57 74 81 43 87 27 40 56 38 73 5 71 37 30 58 89 64\n","truncated":false}}
%---
%[output:393e1daa]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 9 11 12 15 17 20 22 29 30 39 41 42 44 45 47 50 53 55 56 58 60 62 69 70 71 72 81 88 91 94 97\n","truncated":false}}
%---
%[output:24bad6d0]
%   data: {"dataType":"text","outputData":{"text":"Participant 9 of 30:\n","truncated":false}}
%---
%[output:9d5cd559]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR01_RUN05.xlsx\n","truncated":false}}
%---
%[output:84299a1d]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:97bd1181]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [68 56] at positions [35 75]\n","truncated":false}}
%---
%[output:44cdaad3]
%   data: {"dataType":"text","outputData":{"text":"Participant 10 of 30:\n","truncated":false}}
%---
%[output:9bbf4aee]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 7 8 9 12 18 20 29 32 33 37 39 40 44 45 47 54 58 59 60 63 65 69 71 73 80 81 82 83 84 89 98\n","truncated":false}}
%---
%[output:31496711]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR01_RUN06.xlsx\n","truncated":false}}
%---
%[output:1db82714]
%   data: {"dataType":"text","outputData":{"text":"Participant 11 of 30:\n","truncated":false}}
%---
%[output:6d73aa74]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 76 44 36 6 53 45 58 7 17 61 91 63 60 28 12 67 71 95 79 9 14 94 81 11 43 87 30 18 80 20 39 22 93 47 68 59 73 38 23 24 5 27 70 86 16 37 66 4 65 52 3 85 26 49 62 88 48 83 72 77 32 42 13 50 21 90 82 55 41 34 54 74 31 84 56 33 64 19 8 10 40 75 89 46 2 25 69 35 96 29 57 15 51 78 1 92\n","truncated":false}}
%---
%[output:12d1bec8]
%   data: {"dataType":"text","outputData":{"text":"Participant 12 of 30:\n","truncated":false}}
%---
%[output:852c7168]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [93 73] at positions [3 75]\n","truncated":false}}
%---
%[output:2e7fd50c]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR01_RUN07.xlsx\n","truncated":false}}
%---
%[output:47dddc49]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 8 19 22 24 28 33 34 36 40 41 42 43 46 47 50 52 58 59 60 62 63 66 68 69 79 81 82 88 92 98\n","truncated":false}}
%---
%[output:9a410260]
%   data: {"dataType":"text","outputData":{"text":"Participant 13 of 30:\n","truncated":false}}
%---
%[output:3f48b22a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:2e2c0a72]
%   data: {"dataType":"text","outputData":{"text":"Participant 14 of 30:\n","truncated":false}}
%---
%[output:086fe00e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR01_RUN08.xlsx\n","truncated":false}}
%---
%[output:16a3e2d9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 28 49 93 18 80 32 42 46 58 34 84 94 37 12 44 65 52 72 6 2 55 30 9 21 31 91 59 16 92 69 79 89 11 74 39 29 35 27 50 56 24 95 40 43 1 36 86 85 60 33 76 45 53 61 10 51 96 3 70 54 66 25 22 13 19 68 83 75 14 15 90 23 5 57 73 77 47 20 88 63 87 67 64 38 82 7 41 62 17 48 4 81 26 78 8 71\n","truncated":false}}
%---
%[output:2f6bffff]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 15 17 18 20 23 25 27 28 33 39 43 45 47 49 50 52 55 60 64 67 69 71 73 76 83 84 86 93 95 97\n","truncated":false}}
%---
%[output:2fa9cc33]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [12 23] at positions [43 93]\n","truncated":false}}
%---
%[output:55f084fa]
%   data: {"dataType":"text","outputData":{"text":"Participant 15 of 30:\n","truncated":false}}
%---
%[output:8cbac861]
%   data: {"dataType":"text","outputData":{"text":"Participant 16 of 30:\n","truncated":false}}
%---
%[output:83a44443]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR02_RUN01.xlsx\n","truncated":false}}
%---
%[output:21cad4cb]
%   data: {"dataType":"text","outputData":{"text":"Participant 17 of 30:\n","truncated":false}}
%---
%[output:96c31271]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 8 9 10 15 18 21 22 25 29 31 33 36 37 38 44 53 63 65 71 74 77 80 81 82 83 86 88 89 90 92 94\n","truncated":false}}
%---
%[output:320f16ca]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:58afef70]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [70 31] at positions [16 58]\n","truncated":false}}
%---
%[output:97967265]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR02_RUN02.xlsx\n","truncated":false}}
%---
%[output:9e7f3753]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 55 52 67 85 20 4 5 58 7 29 18 54 86 84 49 38 50 26 81 14 93 45 75 6 80 79 57 30 33 48 15 34 91 72 46 22 68 21 3 43 24 59 12 17 37 1 8 96 2 73 71 40 44 65 19 82 25 66 88 51 42 61 89 36 92 70 56 77 16 62 60 90 87 9 78 39 63 27 32 74 83 28 94 35 13 64 41 76 53 10 95 69 23 47 31 11\n","truncated":false}}
%---
%[output:34f69694]
%   data: {"dataType":"text","outputData":{"text":"Participant 18 of 30:\n","truncated":false}}
%---
%[output:800e3afa]
%   data: {"dataType":"text","outputData":{"text":"Participant 19 of 30:\n","truncated":false}}
%---
%[output:188495fb]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 3 4 7 13 15 16 19 33 34 36 38 39 46 48 55 62 63 69 70 74 77 79 81 83 85 88 89 91 97 98\n","truncated":false}}
%---
%[output:9dc17ae6]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR02_RUN03.xlsx\n","truncated":false}}
%---
%[output:068104a5]
%   data: {"dataType":"text","outputData":{"text":"Participant 20 of 30:\n","truncated":false}}
%---
%[output:5b4d39f0]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [49 8] at positions [22 87]\n","truncated":false}}
%---
%[output:781d8635]
%   data: {"dataType":"text","outputData":{"text":"Participant 21 of 30:\n","truncated":false}}
%---
%[output:47b5c823]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 48 56 75 57 91 17 15 86 13 10 38 87 93 45 6 70 90 49 22 23 79 41 34 69 2 28 43 20 84 67 73 21 53 4 50 62 46 58 72 14 55 51 37 42 7 71 61 95 16 44 85 25 59 8 89 36 65 31 9 3 19 39 29 26 68 80 35 30 96 74 83 64 24 52 66 32 94 81 76 54 18 5 77 12 33 88 63 11 82 27 40 1 60 47 78 92\n","truncated":false}}
%---
%[output:89fc5ad1]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR02_RUN04.xlsx\n","truncated":false}}
%---
%[output:30e3d082]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 9 10 13 14 16 17 22 24 26 27 33 36 37 40 42 53 57 59 67 68 69 70 73 77 78 81 87 91 94 95 97\n","truncated":false}}
%---
%[output:11ee3fda]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:8b1e2628]
%   data: {"dataType":"text","outputData":{"text":"Participant 22 of 30:\n","truncated":false}}
%---
%[output:94e52f39]
%   data: {"dataType":"text","outputData":{"text":"Participant 23 of 30:\n","truncated":false}}
%---
%[output:1bd18f94]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR02_RUN05.xlsx\n","truncated":false}}
%---
%[output:4b3cbb76]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [53 92] at positions [46 52]\n","truncated":false}}
%---
%[output:829d209a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 9 10 11 12 14 19 23 27 30 33 34 38 45 46 48 50 55 59 61 62 63 67 74 76 78 79 81 85 89 90 94\n","truncated":false}}
%---
%[output:4570e1da]
%   data: {"dataType":"text","outputData":{"text":"Participant 24 of 30:\n","truncated":false}}
%---
%[output:17271fde]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 26 48 55 1 50 73 16 65 21 69 78 96 91 37 4 41 94 27 62 45 76 49 82 15 29 93 66 34 42 23 9 95 60 61 30 18 58 51 77 22 72 64 84 54 11 2 81 31 12 44 71 33 28 25 40 43 87 10 7 53 46 52 19 86 68 90 83 36 3 80 13 32 89 38 5 57 24 75 67 47 63 35 70 14 39 85 8 88 74 56 92 17 6 79 20 59\n","truncated":false}}
%---
%[output:7544fc68]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR02_RUN06.xlsx\n","truncated":false}}
%---
%[output:45f1e946]
%   data: {"dataType":"text","outputData":{"text":"Participant 25 of 30:\n","truncated":false}}
%---
%[output:3f9e0825]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:9b2a0617]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 8 11 13 14 17 19 20 22 24 27 31 45 46 47 48 50 53 58 72 73 74 79 81 82 83 87 89 90 91 93 98\n","truncated":false}}
%---
%[output:10ec0ff5]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [36 96] at positions [15 60]\n","truncated":false}}
%---
%[output:5937d6d9]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR02_RUN07.xlsx\n","truncated":false}}
%---
%[output:6208e189]
%   data: {"dataType":"text","outputData":{"text":"Participant 26 of 30:\n","truncated":false}}
%---
%[output:699909ec]
%   data: {"dataType":"text","outputData":{"text":"Participant 27 of 30:\n","truncated":false}}
%---
%[output:0347b1fa]
%   data: {"dataType":"text","outputData":{"text":"Participant 28 of 30:\n","truncated":false}}
%---
%[output:4871f95f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 6 9 10 11 12 18 23 26 27 33 36 38 39 44 54 58 61 62 63 64 65 67 71 73 74 79 92 93 95 96\n","truncated":false}}
%---
%[output:160fbb5b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR02_RUN08.xlsx\n","truncated":false}}
%---
%[output:85acbb24]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 21 73 63 65 27 90 29 38 74 88 94 16 6 28 7 77 3 57 83 36 20 24 58 2 89 62 47 81 68 71 34 52 49 17 33 11 43 45 82 66 86 42 15 70 76 53 4 40 46 80 12 92 26 84 91 64 55 22 56 67 18 30 5 14 25 75 35 61 85 10 51 48 23 41 13 54 44 69 87 19 72 8 93 60 32 96 9 31 59 78 39 95 79 50 1 37\n","truncated":false}}
%---
%[output:68318461]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [32 79] at positions [12 88]\n","truncated":false}}
%---
%[output:2865d67d]
%   data: {"dataType":"text","outputData":{"text":"Participant 29 of 30:\n","truncated":false}}
%---
%[output:703ec7f2]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:30722137]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 5 7 14 15 16 19 26 27 33 34 36 38 43 48 49 51 56 58 65 66 68 73 76 84 85 86 89 90 92 93 97\n","truncated":false}}
%---
%[output:4dbbcb3f]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR03_RUN01.xlsx\n","truncated":false}}
%---
%[output:5435d570]
%   data: {"dataType":"text","outputData":{"text":"Participant 30 of 30:\n","truncated":false}}
%---
%[output:43e9c8ec]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:57c1fdcb]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [51 80] at positions [45 96]\n","truncated":false}}
%---
%[output:46ad78bf]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 7 75 43 87 33 46 1 30 73 55 28 51 92 10 36 65 79 95 80 22 45 25 21 85 17 2 3 93 49 59 16 61 78 14 60 44 56 31 77 13 90 83 91 18 62 5 42 48 68 66 81 39 94 6 67 37 15 8 23 96 74 50 71 29 26 34 27 9 24 69 52 64 41 54 86 53 32 4 70 38 88 63 47 58 84 12 57 11 40 19 35 72 82 76 20 89\n","truncated":false}}
%---
%[output:9faefcde]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR03_RUN02.xlsx\n","truncated":false}}
%---
%[output:03bbe675]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 11 14 16 21 22 24 28 29 32 35 38 40 42 44 49 50 51 54 55 59 61 62 75 77 80 81 85 89 91 96 97\n","truncated":false}}
%---
%[output:67c9e20a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:802421e3]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:08af38e1]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:2681e3cc]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR03_RUN03.xlsx\n","truncated":false}}
%---
%[output:0f0260aa]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [17 42] at positions [19 63]\n","truncated":false}}
%---
%[output:2cddf847]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 10 11 13 15 23 24 28 29 33 34 38 46 47 48 54 59 60 61 64 65 66 68 72 74 75 81 89 90 94 98\n","truncated":false}}
%---
%[output:1f2cd5b7]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:9f9bb2ea]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 50 31 40 80 14 96 95 58 46 33 4 32 21 12 35 19 92 5 56 66 83 28 74 62 51 85 41 60 15 67 38 86 75 23 63 91 29 57 6 10 17 2 88 49 42 89 82 68 77 87 3 59 78 39 34 72 25 94 37 16 71 7 9 36 22 47 55 52 30 18 70 69 64 65 24 11 53 44 76 90 27 48 20 61 84 54 13 79 8 26 81 73 43 1 45 93\n","truncated":false}}
%---
%[output:33d88d69]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR03_RUN04.xlsx\n","truncated":false}}
%---
%[output:8eae8d5c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:8481fe07]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:69866b9f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [26 4] at positions [30 88]\n","truncated":false}}
%---
%[output:7c6098ee]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 13 15 16 20 21 23 29 32 35 37 38 41 46 48 50 52 55 57 61 62 64 68 74 76 81 82 84 91 93 96\n","truncated":false}}
%---
%[output:510b79cc]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR03_RUN05.xlsx\n","truncated":false}}
%---
%[output:96ab6e10]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:6fe1c95a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:18b3e7b1]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 39 96 21 22 88 69 60 82 35 77 18 58 67 95 84 7 87 49 11 46 3 54 45 27 74 79 14 30 47 36 64 53 17 12 71 48 68 52 93 66 34 41 5 10 51 76 75 32 44 31 9 94 91 15 65 2 4 20 70 92 19 83 56 62 24 23 57 42 61 1 37 89 38 59 40 6 55 16 29 43 85 50 90 13 81 26 86 73 33 28 78 8 72 25 63 80\n","truncated":false}}
%---
%[output:39a880c5]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:456f8b1d]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR03_RUN06.xlsx\n","truncated":false}}
%---
%[output:5909236a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 5 6 9 10 11 13 25 26 27 28 32 35 38 40 53 56 61 63 68 70 72 77 84 85 88 90 93 94 95 97\n","truncated":false}}
%---
%[output:89b63740]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [2 92] at positions [13 80]\n","truncated":false}}
%---
%[output:169c9065]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:0cfa323f]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:452bd54f]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR03_RUN07.xlsx\n","truncated":false}}
%---
%[output:666781a6]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:314985cd]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 6 7 8 10 11 13 15 18 29 32 35 42 44 46 48 49 51 57 61 63 64 65 67 68 72 74 77 82 85 89 90 97\n","truncated":false}}
%---
%[output:4498ca17]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 69 87 62 16 7 22 40 34 14 96 80 33 82 81 11 55 49 86 17 3 74 61 71 19 24 65 13 48 31 53 44 58 29 88 43 70 76 27 50 73 75 60 57 39 72 6 85 64 21 36 5 28 84 12 38 18 1 63 94 78 93 91 42 59 9 66 46 92 26 32 77 54 25 2 10 79 37 41 23 83 47 90 15 89 51 35 56 68 8 45 67 95 20 52 4 30\n","truncated":false}}
%---
%[output:8574bca1]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [84 73] at positions [36 87]\n","truncated":false}}
%---
%[output:64ce36f3]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR03_RUN08.xlsx\n","truncated":false}}
%---
%[output:630f4c7c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:5b71544d]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:4b514c53]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 8 10 14 15 16 21 22 24 25 32 37 43 45 46 49 52 54 60 61 62 67 72 74 78 79 81 82 83 85 87 89\n","truncated":false}}
%---
%[output:4b3530e1]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:474f4337]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:701f1694]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR04_RUN01.xlsx\n","truncated":false}}
%---
%[output:440e7d45]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 95 1 2 42 64 10 77 16 90 87 70 29 86 32 40 71 56 79 35 38 31 66 91 44 5 18 8 58 59 26 25 55 89 50 41 92 69 72 12 20 96 62 82 47 34 53 19 74 78 81 84 30 27 33 7 63 68 51 11 73 23 52 45 85 14 6 43 28 13 88 80 39 67 60 49 9 57 22 75 37 61 48 21 94 36 3 83 4 46 93 17 15 76 24 54 65\n","truncated":false}}
%---
%[output:55a5bc7c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [34 32] at positions [27 68]\n","truncated":false}}
%---
%[output:14ffda35]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 14 20 25 26 27 28 31 35 38 39 40 41 45 46 49 51 53 59 62 63 64 66 68 77 81 84 93 94 95 96 97\n","truncated":false}}
%---
%[output:361d7928]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:46fda84d]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR04_RUN02.xlsx\n","truncated":false}}
%---
%[output:9bfa6aa5]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:9bd17de8]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:9e479b3c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:70654d2e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 7 10 20 21 22 23 29 30 33 34 37 38 39 41 50 52 58 59 62 64 68 70 72 74 78 80 81 82 92 94\n","truncated":false}}
%---
%[output:1dcb3d55]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR04_RUN03.xlsx\n","truncated":false}}
%---
%[output:6b087a1a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [33 5] at positions [13 94]\n","truncated":false}}
%---
%[output:1fa33165]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 65 69 31 40 52 70 5 45 75 35 14 82 2 78 56 9 62 33 28 93 24 4 27 23 64 87 76 91 48 88 51 30 77 21 55 57 53 22 44 47 32 20 10 8 95 85 6 49 94 39 73 12 66 36 46 16 19 89 18 74 54 38 90 71 83 63 3 43 58 68 72 42 26 37 50 7 11 60 80 92 84 13 34 1 79 17 81 25 15 96 41 86 59 29 67 61\n","truncated":false}}
%---
%[output:40c44ab9]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:8f2271a6]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:65d5d8e2]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR04_RUN04.xlsx\n","truncated":false}}
%---
%[output:89fc7e34]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 12 13 15 18 19 21 24 28 33 35 39 41 45 46 47 51 53 55 58 60 66 70 77 80 81 82 84 86 87 89 98\n","truncated":false}}
%---
%[output:66a07890]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:602e0d9a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [93 9] at positions [35 88]\n","truncated":false}}
%---
%[output:3f5542f4]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:824bd090]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR04_RUN05.xlsx\n","truncated":false}}
%---
%[output:5bb902cf]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 62 57 44 52 31 34 69 29 53 68 7 89 5 14 63 16 65 36 38 83 79 94 64 85 32 15 40 25 67 55 48 13 22 19 96 84 42 23 78 75 1 26 58 95 9 91 21 17 10 80 41 59 51 3 6 39 87 66 60 74 70 28 35 71 92 46 47 11 54 24 81 61 8 43 12 18 33 72 4 82 88 56 45 30 90 27 73 93 37 49 86 2 76 50 77 20\n","truncated":false}}
%---
%[output:899ba951]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 9 12 13 14 18 20 24 25 28 31 33 34 42 43 49 51 52 55 59 67 68 70 73 74 78 79 80 88 91 93 97\n","truncated":false}}
%---
%[output:88645d49]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:212297d1]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:41fc37af]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR04_RUN06.xlsx\n","truncated":false}}
%---
%[output:3a8a8e74]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [51 35] at positions [2 77]\n","truncated":false}}
%---
%[output:3b471d91]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:60f2b4e1]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:86cd302b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 7 9 11 16 17 20 23 25 30 32 38 42 46 48 50 52 53 55 61 63 65 69 71 76 79 82 85 89 90 96\n","truncated":false}}
%---
%[output:0c487f88]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR04_RUN07.xlsx\n","truncated":false}}
%---
%[output:7da400eb]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:673cd2f3]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 14 11 51 69 77 15 94 20 24 7 38 68 40 48 10 30 88 43 91 49 93 70 95 2 79 31 34 17 80 54 50 21 61 6 72 73 59 41 62 9 64 63 75 28 60 47 67 8 84 85 39 19 5 18 92 76 33 83 57 25 36 3 16 37 53 90 87 32 78 81 12 65 55 22 23 35 46 86 26 58 4 89 66 1 29 82 56 96 42 27 13 44 74 45 52 71\n","truncated":false}}
%---
%[output:74e138ae]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [63 67] at positions [20 63]\n","truncated":false}}
%---
%[output:22346866]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:15dc7a19]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR04_RUN08.xlsx\n","truncated":false}}
%---
%[output:8c23501e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 5 12 15 18 19 20 21 29 34 40 43 44 47 48 62 64 66 69 71 72 79 84 85 86 89 90 91 96 97 98\n","truncated":false}}
%---
%[output:9365484a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:4c92549b]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:062f495c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:946fc933]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [70 32] at positions [33 63]\n","truncated":false}}
%---
%[output:0b756a45]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR05_RUN01.xlsx\n","truncated":false}}
%---
%[output:22c7acbb]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 6 7 13 14 17 18 19 22 25 26 27 28 29 35 37 43 54 55 56 60 62 63 67 69 70 71 82 83 86 88 91 98\n","truncated":false}}
%---
%[output:026d7706]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 44 81 41 2 67 64 76 46 36 61 86 53 33 78 18 48 27 87 84 3 34 66 82 73 4 90 19 52 59 28 14 20 26 71 69 31 93 95 62 9 7 58 8 40 63 88 21 16 85 45 24 42 37 91 77 11 70 75 35 15 51 22 60 79 57 47 55 49 6 29 30 72 83 10 13 56 43 25 54 89 68 50 17 65 39 1 23 94 38 74 12 92 32 5 80 96\n","truncated":false}}
%---
%[output:296a9368]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:34fac3aa]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:03de1abb]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR05_RUN02.xlsx\n","truncated":false}}
%---
%[output:0cbfcf2a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:1dcdcd0a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 6 9 11 12 14 16 19 30 31 37 38 41 42 44 49 52 55 58 62 63 69 70 72 73 74 77 81 82 90 91 95\n","truncated":false}}
%---
%[output:94cf541c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [95 44] at positions [29 77]\n","truncated":false}}
%---
%[output:5bbc4c11]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:389b565f]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR05_RUN03.xlsx\n","truncated":false}}
%---
%[output:96e50272]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 23 87 13 53 63 66 34 50 88 90 74 24 56 1 79 55 28 75 65 14 6 32 2 91 20 19 45 85 52 37 46 10 33 70 93 44 25 4 83 42 8 78 84 31 35 76 17 89 51 22 57 7 58 54 82 11 29 68 80 3 15 39 26 21 62 67 38 86 73 64 43 49 5 95 92 61 69 40 48 27 94 47 60 18 72 16 41 9 71 96 12 30 36 77 59 81\n","truncated":false}}
%---
%[output:46da00a1]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:7a8d0e9c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 9 12 13 14 30 31 32 36 39 41 43 46 48 49 53 55 57 59 60 62 64 65 73 78 79 80 86 89 91 98\n","truncated":false}}
%---
%[output:4c2b92a6]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:97a1fa38]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR05_RUN04.xlsx\n","truncated":false}}
%---
%[output:5c8f4a1f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [87 96] at positions [1 76]\n","truncated":false}}
%---
%[output:96c1b0dd]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:62bbcacb]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:0ba49328]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 8 9 18 20 23 25 26 27 29 36 39 41 42 47 49 52 54 57 60 63 67 74 75 78 79 86 87 88 93 94 98\n","truncated":false}}
%---
%[output:4e085815]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR05_RUN05.xlsx\n","truncated":false}}
%---
%[output:39e415d6]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 93 51 86 7 92 24 3 5 54 6 68 66 88 46 87 96 78 52 74 45 77 1 25 50 56 42 23 37 59 19 75 18 81 60 34 4 38 36 27 28 65 32 63 15 83 33 61 22 94 21 26 41 85 73 13 48 8 10 62 69 95 12 31 2 71 70 44 72 53 58 89 91 49 43 40 90 35 57 76 14 47 17 55 82 30 84 9 64 16 20 67 29 11 80 39 79\n","truncated":false}}
%---
%[output:8342a175]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:93e24dec]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:8b75c763]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [96 20] at positions [27 78]\n","truncated":false}}
%---
%[output:3809b0e5]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR05_RUN06.xlsx\n","truncated":false}}
%---
%[output:29031a43]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 5 6 8 17 22 23 25 26 36 39 40 45 46 49 51 52 54 55 56 58 60 64 67 71 73 74 78 80 94 95\n","truncated":false}}
%---
%[output:1ca246a9]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:84344af6]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:492c8d41]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 49 17 90 41 43 52 46 74 33 12 29 65 51 10 7 80 86 4 85 63 61 71 24 31 13 42 82 91 79 77 11 62 81 27 35 18 60 84 6 3 83 64 57 45 70 2 69 21 78 37 9 39 26 56 32 30 93 92 48 34 55 76 67 96 73 58 5 53 15 20 14 25 36 94 22 16 38 19 75 88 50 72 1 68 59 40 87 47 66 28 44 54 23 95 8 89\n","truncated":false}}
%---
%[output:4d59f58b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR05_RUN07.xlsx\n","truncated":false}}
%---
%[output:400f37a2]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:08dbee80]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 9 10 12 13 14 17 20 22 24 25 26 34 40 43 44 46 50 58 60 61 67 68 70 74 75 80 82 83 84 91 95 98\n","truncated":false}}
%---
%[output:549a2bf7]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [67 63] at positions [34 60]\n","truncated":false}}
%---
%[output:1b767390]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:1a31063f]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR05_RUN08.xlsx\n","truncated":false}}
%---
%[output:0f630e43]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:0c446d63]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:5f08ee56]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 67 29 83 93 64 73 78 62 4 21 1 42 82 28 68 8 71 95 6 50 39 11 92 35 40 59 96 77 43 31 18 34 70 47 81 45 38 12 5 89 27 52 30 56 60 80 10 79 74 26 94 76 63 17 19 46 57 13 54 85 7 48 32 69 86 61 49 36 66 84 87 75 22 3 23 51 90 53 44 16 2 72 9 58 14 25 88 15 41 20 37 91 33 65 55 24\n","truncated":false}}
%---
%[output:49e23089]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 6 13 16 17 19 20 24 28 29 30 32 41 44 46 49 52 54 63 64 67 70 71 73 78 83 86 87 88 90 94 98\n","truncated":false}}
%---
%[output:6b17a27b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [30 66] at positions [3 70]\n","truncated":false}}
%---
%[output:4710932b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR06_RUN01.xlsx\n","truncated":false}}
%---
%[output:5a67b98a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:382548ce]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:7c15dc17]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:13c12d9f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 9 11 12 14 15 20 21 22 26 29 36 40 42 48 49 50 55 56 57 58 70 71 74 75 76 77 86 87 90 91 97\n","truncated":false}}
%---
%[output:1c153562]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR06_RUN02.xlsx\n","truncated":false}}
%---
%[output:865597fd]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:471f8029]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [93 32] at positions [19 62]\n","truncated":false}}
%---
%[output:98ed7f6a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 16 62 74 24 21 12 8 47 59 18 34 42 27 54 37 84 4 70 9 90 71 56 60 2 29 78 82 58 95 33 15 26 89 23 41 69 36 65 80 91 81 30 57 22 75 68 20 6 77 7 39 1 51 92 38 94 87 73 46 49 40 25 96 55 67 53 50 14 83 13 11 19 17 86 76 48 44 64 85 63 3 61 31 45 10 66 28 79 52 72 88 32 5 43 93 35\n","truncated":false}}
%---
%[output:3a03562b]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:48cfb475]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR06_RUN03.xlsx\n","truncated":false}}
%---
%[output:9e43817f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 8 11 12 18 19 22 23 29 31 34 35 37 47 49 51 53 57 64 74 75 77 80 81 83 85 89 93 94 97 98\n","truncated":false}}
%---
%[output:44cc7297]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:33ea87bf]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:83d67e7c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [41 19] at positions [37 56]\n","truncated":false}}
%---
%[output:1b2296e6]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR06_RUN04.xlsx\n","truncated":false}}
%---
%[output:64ef76b4]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:3172e5ce]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 7 8 10 11 12 18 20 21 29 36 40 42 44 46 53 59 62 64 71 72 73 75 80 82 83 86 91 93 94 95\n","truncated":false}}
%---
%[output:68b12fb9]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 87 73 69 6 88 95 50 85 41 68 59 4 11 75 38 47 20 91 18 19 3 22 80 32 40 51 70 81 10 53 30 54 58 34 2 36 89 8 93 94 48 23 21 84 78 79 5 9 52 7 42 56 72 28 57 24 12 67 46 71 62 35 14 17 65 82 31 33 83 55 64 92 74 13 29 96 15 43 37 76 45 90 27 61 26 44 16 77 25 66 60 1 86 63 39 49\n","truncated":false}}
%---
%[output:94764bb4]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:025e4b7a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR06_RUN05.xlsx\n","truncated":false}}
%---
%[output:383887a1]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:97942101]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [87 33] at positions [38 78]\n","truncated":false}}
%---
%[output:5d23ae1e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 5 10 13 22 24 26 33 36 37 38 42 43 46 47 56 58 59 62 63 70 74 79 83 88 90 91 92 93 94 96\n","truncated":false}}
%---
%[output:7d365758]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:52ef0057]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR06_RUN06.xlsx\n","truncated":false}}
%---
%[output:53909485]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:83157024]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:262f856d]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 82 55 18 1 46 86 43 24 87 94 5 4 51 6 67 23 65 90 29 44 39 64 61 83 66 9 96 59 35 76 56 72 74 37 2 22 54 53 25 30 85 93 71 13 77 26 60 34 89 33 27 31 69 91 7 81 28 47 3 12 49 80 50 15 48 52 95 73 78 45 40 75 62 41 58 17 16 20 42 32 8 63 92 21 57 10 36 14 84 38 68 19 70 88 11 79\n","truncated":false}}
%---
%[output:3755d1d6]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 7 9 11 12 16 17 19 22 26 28 30 40 41 42 46 54 57 58 59 60 63 64 65 72 75 78 81 82 87 91 98\n","truncated":false}}
%---
%[output:0378dd5b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR06_RUN07.xlsx\n","truncated":false}}
%---
%[output:748acb74]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [21 75] at positions [46 68]\n","truncated":false}}
%---
%[output:7e2fd1eb]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:35b5c0f0]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:60af5dd0]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:5c105a9a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR06_RUN08.xlsx\n","truncated":false}}
%---
%[output:86e039fb]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 7 10 11 15 20 22 25 26 27 28 30 31 32 38 39 50 53 59 67 69 72 78 79 81 82 83 87 91 95 96 98\n","truncated":false}}
%---
%[output:677d0940]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:9aefdd8e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [71 12] at positions [47 55]\n","truncated":false}}
%---
%[output:9c5b1d19]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 75 62 49 93 34 16 52 45 77 88 92 25 66 15 13 86 79 73 36 42 84 60 11 48 29 81 8 72 32 33 61 23 57 67 65 22 10 18 30 69 90 68 12 1 85 58 82 9 20 55 39 43 74 59 17 31 3 70 46 63 56 14 35 83 24 47 27 95 91 40 5 50 80 41 53 38 6 87 51 76 96 21 44 94 2 26 54 7 78 28 4 37 19 89 71 64\n","truncated":false}}
%---
%[output:3accfed8]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:6e4e6693]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR07_RUN01.xlsx\n","truncated":false}}
%---
%[output:5180fdba]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 8 10 11 15 17 19 20 23 33 35 39 42 43 44 46 50 55 56 59 61 63 64 66 67 70 72 77 79 85 90 98\n","truncated":false}}
%---
%[output:69367e27]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:0915ced1]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:57d35a31]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:799f7bca]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR07_RUN02.xlsx\n","truncated":false}}
%---
%[output:18e76962]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [60 63] at positions [47 76]\n","truncated":false}}
%---
%[output:047952c1]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 34 83 30 77 44 32 96 75 69 11 16 35 4 18 47 63 9 73 61 39 48 76 24 12 88 81 54 62 82 45 5 49 23 29 52 79 94 13 64 57 25 67 59 65 80 20 60 91 90 21 41 56 1 19 17 6 33 27 87 43 40 78 42 95 71 7 84 51 36 66 89 2 10 72 8 68 31 15 53 28 85 58 38 86 70 50 3 92 37 14 46 26 55 74 93 22\n","truncated":false}}
%---
%[output:6db7d448]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 6 8 11 15 17 18 25 28 29 36 38 41 42 49 50 51 64 69 71 72 74 75 76 77 83 84 87 88 93 95\n","truncated":false}}
%---
%[output:34fd0d58]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:4c19f0d6]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR07_RUN03.xlsx\n","truncated":false}}
%---
%[output:1cfc9dd2]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:9f7db0a4]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:11da0553]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [78 67] at positions [28 96]\n","truncated":false}}
%---
%[output:40999b68]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 7 11 13 14 15 20 21 25 28 30 31 32 33 44 46 50 53 54 61 69 71 73 74 77 78 85 86 90 92 96 97\n","truncated":false}}
%---
%[output:054e7af3]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR07_RUN04.xlsx\n","truncated":false}}
%---
%[output:0f5690cf]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:5ef4efe9]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 50 41 83 12 54 57 90 89 67 34 19 75 25 8 35 49 30 17 93 64 80 52 5 79 68 1 22 61 20 46 36 15 13 92 26 45 72 84 40 11 77 37 94 2 96 39 47 73 56 14 9 60 44 58 62 81 53 66 29 28 85 32 4 38 21 69 7 31 51 10 63 88 71 82 87 55 27 42 95 76 70 24 78 16 91 6 74 48 23 59 33 3 43 65 86 18\n","truncated":false}}
%---
%[output:70120cb2]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:95d070e6]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:01069316]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR07_RUN05.xlsx\n","truncated":false}}
%---
%[output:6a53094e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 4 7 9 11 16 17 31 32 34 36 38 39 42 45 51 54 56 66 69 70 77 79 80 81 84 88 89 92 94 97\n","truncated":false}}
%---
%[output:32ba927f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [27 56] at positions [44 81]\n","truncated":false}}
%---
%[output:625b8334]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:9c5da4ef]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:6dfd4abd]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR07_RUN06.xlsx\n","truncated":false}}
%---
%[output:0d6fb69f]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 12 3 23 20 80 62 27 13 56 11 75 1 39 60 67 28 63 85 38 14 92 86 59 54 45 43 65 90 69 70 46 89 16 79 35 32 41 2 42 21 82 24 55 44 74 30 7 81 72 9 49 76 50 58 17 19 84 95 25 36 51 4 22 68 73 88 6 5 61 91 52 83 33 96 40 48 64 34 15 37 18 8 87 77 53 78 94 57 10 31 66 26 93 29 47 71\n","truncated":false}}
%---
%[output:8a457e94]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 9 10 11 14 16 17 18 27 29 30 32 33 35 38 43 44 52 57 59 62 63 64 68 69 73 78 80 82 83 85 90 91\n","truncated":false}}
%---
%[output:6f438208]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:2af3edeb]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [25 67] at positions [9 49]\n","truncated":false}}
%---
%[output:230b8064]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR07_RUN07.xlsx\n","truncated":false}}
%---
%[output:7cbf2c80]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:8c8cd47a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:3b649b27]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 4 5 10 11 12 13 17 20 24 28 41 45 47 48 50 51 52 64 65 67 71 73 76 77 84 88 92 96 97 98\n","truncated":false}}
%---
%[output:155bce60]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:48118b28]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR07_RUN08.xlsx\n","truncated":false}}
%---
%[output:12e0e429]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 19 9 85 76 22 31 86 54 69 70 40 93 28 34 55 59 29 51 90 44 24 66 82 91 12 43 77 7 58 39 13 26 95 50 5 75 57 87 68 83 6 11 79 73 48 41 72 60 37 61 78 3 18 36 27 80 17 63 56 1 53 30 4 47 94 23 20 71 96 38 8 84 89 32 42 46 92 33 21 64 65 62 14 16 74 2 35 52 81 67 45 15 25 10 88 49\n","truncated":false}}
%---
%[output:45c17044]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [33 43] at positions [7 83]\n","truncated":false}}
%---
%[output:01361207]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:4302cf88]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 5 12 22 24 25 26 27 31 32 34 35 44 47 49 51 53 56 62 66 68 73 75 77 78 81 82 83 85 90 92\n","truncated":false}}
%---
%[output:4d595b81]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:45d4c77d]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR08_RUN01.xlsx\n","truncated":false}}
%---
%[output:4ece0539]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:90bbf693]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:9490cae9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [73 42] at positions [15 73]\n","truncated":false}}
%---
%[output:4680f5f8]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 5 8 10 12 24 31 35 36 37 40 41 43 46 48 50 52 53 59 61 62 71 73 77 78 88 91 93 95 96 97\n","truncated":false}}
%---
%[output:29e19296]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR08_RUN02.xlsx\n","truncated":false}}
%---
%[output:11287cce]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 95 63 1 85 7 34 30 23 44 61 62 25 69 82 42 3 8 27 91 81 28 64 77 33 35 68 67 57 46 84 73 20 11 52 92 71 6 70 56 53 13 38 60 36 88 21 37 19 58 83 86 54 65 87 9 94 47 12 4 26 32 96 14 79 2 55 17 75 24 5 40 43 72 48 93 51 45 18 59 89 78 74 50 16 90 22 39 66 41 15 49 76 31 80 10 29\n","truncated":false}}
%---
%[output:92b78ac4]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:477e5e73]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:0e8b36bc]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:61825abc]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR08_RUN03.xlsx\n","truncated":false}}
%---
%[output:9924b396]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 6 9 11 13 23 25 28 30 31 32 34 38 41 48 55 63 66 67 70 74 75 81 82 84 87 91 92 95 96 98\n","truncated":false}}
%---
%[output:64734a51]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [56 55] at positions [13 74]\n","truncated":false}}
%---
%[output:9b1678b8]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:6cc1cf24]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 41 75 11 43 34 15 69 17 29 36 24 68 67 44 53 80 61 50 37 94 87 4 3 64 88 52 2 27 62 31 92 72 85 18 14 90 45 46 78 1 63 30 28 86 32 57 71 26 74 84 73 54 60 48 12 33 58 16 9 77 47 93 56 82 39 22 6 81 10 23 40 91 96 49 65 76 95 79 51 42 5 20 59 25 13 83 21 38 55 7 70 19 89 8 35 66\n","truncated":false}}
%---
%[output:1b27ff9f]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR08_RUN04.xlsx\n","truncated":false}}
%---
%[output:8b8b7e17]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:0ab67d32]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:2cb5c46b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 9 10 12 16 17 18 20 21 23 26 30 32 34 36 49 53 54 55 58 59 61 67 70 74 75 78 80 85 89 90 97\n","truncated":false}}
%---
%[output:291dea73]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [71 85] at positions [7 81]\n","truncated":false}}
%---
%[output:42db484f]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR08_RUN05.xlsx\n","truncated":false}}
%---
%[output:99621b7d]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:9adbf5da]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:06ab7e28]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:420e4989]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 5 7 12 15 20 25 27 29 30 35 43 44 46 48 50 51 56 58 61 63 67 69 72 74 75 76 79 80 83 94\n","truncated":false}}
%---
%[output:5fba7d1a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR08_RUN06.xlsx\n","truncated":false}}
%---
%[output:40e24324]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 72 20 38 28 82 37 13 77 34 87 53 94 2 42 76 80 81 26 78 52 75 5 6 25 21 64 9 84 92 65 8 61 36 35 49 51 24 3 45 66 83 86 23 54 11 16 60 47 33 22 74 79 27 41 50 95 10 70 62 29 19 1 85 57 71 48 88 44 4 18 89 69 32 40 59 63 30 96 46 67 15 68 58 39 17 55 7 31 14 90 56 91 12 43 93 73\n","truncated":false}}
%---
%[output:3b00ad3a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:5ab7fadc]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [23 94] at positions [30 54]\n","truncated":false}}
%---
%[output:2490f7ff]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:594d3763]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR08_RUN07.xlsx\n","truncated":false}}
%---
%[output:25ff13ca]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 5 7 9 18 20 25 26 28 30 33 35 42 44 49 50 57 58 62 63 65 70 71 72 83 84 85 87 88 90 97\n","truncated":false}}
%---
%[output:566ef83d]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:06dc6802]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:5df7d321]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 60 55 43 64 13 77 71 58 30 16 27 69 41 38 1 34 85 68 31 57 86 9 94 93 22 87 44 78 2 5 52 74 91 61 26 17 37 18 21 73 25 4 66 35 8 6 89 90 79 83 56 82 11 53 45 62 10 23 95 36 76 80 51 65 3 39 81 24 40 47 29 49 50 14 19 70 15 63 88 72 20 33 54 46 92 59 28 96 32 7 42 75 84 48 12 67\n","truncated":false}}
%---
%[output:72d55963]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR08_RUN08.xlsx\n","truncated":false}}
%---
%[output:1eb3a33f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [18 76] at positions [47 60]\n","truncated":false}}
%---
%[output:69b8c6d4]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 5 11 14 15 16 18 28 31 34 37 39 40 42 43 46 57 58 59 61 73 74 76 77 82 83 85 88 89 93 97 98\n","truncated":false}}
%---
%[output:22011a27]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:2a690c37]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:03d9a5bc]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:52276194]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR09_RUN01.xlsx\n","truncated":false}}
%---
%[output:4327ac5a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:7cff0a8f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 8 9 15 16 19 23 28 29 31 32 36 42 43 44 49 50 53 56 61 63 65 68 69 75 77 79 84 86 87 91 98\n","truncated":false}}
%---
%[output:55deedbf]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [42 72] at positions [38 56]\n","truncated":false}}
%---
%[output:18bfb18d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 94 of 96\n\t\tFound solution after 2 attempt(s): 85 58 40 45 1 50 78 72 18 95 38 83 23 49 55 5 17 44 75 82 73 42 62 94 9 66 57 19 68 2 91 90 59 31 25 16 15 47 30 64 92 33 26 27 37 8 52 46 35 61 65 29 89 3 79 86 71 74 13 32 70 51 6 12 88 20 4 39 80 36 93 84 21 96 48 69 10 34 11 67 56 60 7 81 63 76 87 77 28 41 53 24 14 22 54 43\n","truncated":false}}
%---
%[output:5b17fc2e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR09_RUN02.xlsx\n","truncated":false}}
%---
%[output:400a54da]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:6ad97823]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:9a61aaf6]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 5 10 11 12 17 21 35 36 37 38 41 44 47 49 50 52 59 61 66 70 73 75 76 87 91 92 93 95 97 98\n","truncated":false}}
%---
%[output:80048932]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:960afe3b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR09_RUN03.xlsx\n","truncated":false}}
%---
%[output:0d20ecdf]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [85 23] at positions [46 68]\n","truncated":false}}
%---
%[output:7577ff64]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:5add4211]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 29 59 6 64 85 8 69 31 25 82 76 71 50 66 14 91 56 17 36 18 65 33 61 41 15 23 9 10 44 79 92 19 12 89 39 38 83 94 5 2 62 58 80 3 46 21 42 72 67 26 84 24 55 45 49 13 20 75 87 68 34 90 37 16 73 63 53 28 22 74 35 43 86 93 51 96 52 7 54 30 4 95 78 32 48 70 81 27 60 47 11 40 57 88 1 77\n","truncated":false}}
%---
%[output:7f688202]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 5 10 13 15 19 21 24 26 31 36 39 42 47 49 59 60 61 63 64 67 68 69 70 71 73 76 78 84 96 98\n","truncated":false}}
%---
%[output:98c3d82c]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR09_RUN04.xlsx\n","truncated":false}}
%---
%[output:704be9e7]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:2e05108d]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:6e8afa82]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [94 92] at positions [47 64]\n","truncated":false}}
%---
%[output:6fb025df]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:52b37d20]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR09_RUN05.xlsx\n","truncated":false}}
%---
%[output:5a8364cd]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 6 12 16 20 21 22 23 26 31 34 36 39 40 45 50 57 62 65 66 67 70 74 81 83 86 91 93 94 96 97\n","truncated":false}}
%---
%[output:31f2140c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:2c955740]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 47 18 90 49 24 28 33 53 96 89 5 86 29 64 40 10 38 85 79 82 35 67 65 37 34 36 75 57 80 8 21 71 19 13 61 56 7 69 74 17 58 30 11 6 23 44 51 39 83 73 55 59 91 94 22 92 50 77 42 15 81 9 12 66 88 48 32 27 70 14 62 3 45 76 41 52 72 25 46 2 54 93 43 87 31 16 84 4 68 95 63 20 78 1 26 60\n","truncated":false}}
%---
%[output:79d0b9d0]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:7bb806cb]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR09_RUN06.xlsx\n","truncated":false}}
%---
%[output:23180a47]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [16 71] at positions [31 77]\n","truncated":false}}
%---
%[output:79c39fee]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:4583d8fa]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 6 7 11 15 22 23 27 36 40 41 42 44 46 47 51 60 63 64 71 72 74 82 83 85 86 87 90 94 96 98\n","truncated":false}}
%---
%[output:8c7c488f]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:13bf6520]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR09_RUN07.xlsx\n","truncated":false}}
%---
%[output:3222ca79]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:98b5a3e2]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 8 26 7 58 10 1 46 84 92 54 41 50 76 16 73 32 47 9 90 77 36 30 56 93 13 18 80 52 49 28 81 38 45 69 71 96 24 17 20 91 95 43 44 14 63 35 59 94 29 65 33 68 25 6 66 60 78 4 88 74 87 3 40 27 39 85 51 64 23 57 15 2 42 86 21 82 11 79 72 48 19 34 12 83 67 5 53 70 31 62 89 55 37 75 61 22\n","truncated":false}}
%---
%[output:63ea14c2]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [62 39] at positions [34 70]\n","truncated":false}}
%---
%[output:93df87e8]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 10 15 16 18 22 23 24 25 28 35 36 37 43 48 51 55 57 58 59 63 65 66 72 81 82 83 85 86 87 93\n","truncated":false}}
%---
%[output:1bb78f68]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR09_RUN08.xlsx\n","truncated":false}}
%---
%[output:58b66e10]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:197fc0fb]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:62ce4394]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:00c250af]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:82d2a850]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 5 7 8 9 18 19 30 34 35 42 43 45 46 48 55 56 61 67 74 76 77 86 87 91 92 93 94 95 96 97\n","truncated":false}}
%---
%[output:97f0162b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR10_RUN01.xlsx\n","truncated":false}}
%---
%[output:90459310]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [89 13] at positions [25 95]\n","truncated":false}}
%---
%[output:67a7d6e9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 93 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 32 90 95 38 70 89 19 25 7 71 15 22 56 9 83 63 29 34 54 62 41 30 80 61 82 69 65 46 3 2 47 91 12 50 73 20 53 86 11 84 59 67 4 44 37 75 49 42 64 31 1 74 23 68 88 36 93 28 48 14 17 24 81 87 72 79 35 21 16 52 57 13 10 55 43 40 77 8 85 33 26 58 92 27 66 60 5 78 96 76 45 94 6 39 51 18\n","truncated":false}}
%---
%[output:0ca0a8dd]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:0d06a180]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:1496324b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR10_RUN02.xlsx\n","truncated":false}}
%---
%[output:63a03056]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 8 9 10 19 21 23 26 27 32 34 36 41 44 45 48 51 52 56 57 59 62 65 68 72 73 76 80 82 84 91 98\n","truncated":false}}
%---
%[output:74ff626c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:488539b0]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:63f320e9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [90 70] at positions [25 92]\n","truncated":false}}
%---
%[output:22a0c320]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR10_RUN03.xlsx\n","truncated":false}}
%---
%[output:8ca32cc1]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 7 84 30 65 81 47 71 41 54 13 66 24 1 46 38 91 56 33 17 53 19 94 72 64 70 6 63 88 89 5 10 29 22 36 2 93 4 12 37 35 57 60 96 95 58 44 87 32 43 76 67 3 50 16 75 92 42 11 27 90 77 78 20 62 74 39 26 8 28 23 68 55 18 14 51 61 15 45 79 59 85 34 9 80 25 73 40 86 52 31 82 69 83 21 49 48\n","truncated":false}}
%---
%[output:4b90717f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 3 4 5 11 16 19 20 24 29 32 37 43 44 48 50 52 56 60 61 68 69 70 71 76 82 83 90 94 96 97\n","truncated":false}}
%---
%[output:1cf9ae61]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:3e269db4]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:3455a9c5]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR10_RUN04.xlsx\n","truncated":false}}
%---
%[output:81cf4bb5]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:0bdd8dfb]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [39 26] at positions [8 58]\n","truncated":false}}
%---
%[output:08e08a0b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 10 11 14 17 22 24 25 26 33 37 38 41 44 45 52 55 57 60 66 68 69 72 73 76 79 81 82 88 89 95\n","truncated":false}}
%---
%[output:16bf8db3]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:080a3bba]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR10_RUN05.xlsx\n","truncated":false}}
%---
%[output:2ceb601a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:2315b209]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 56 20 41 31 12 27 76 90 63 4 7 49 72 59 62 45 35 1 95 38 68 29 51 82 89 74 3 48 60 23 32 92 13 71 44 81 24 25 40 30 75 78 57 37 87 6 50 64 69 14 17 9 66 94 73 42 36 55 96 46 77 22 86 84 28 54 16 47 11 85 58 33 67 80 88 8 15 39 91 19 70 26 43 21 83 34 52 18 5 65 53 2 61 93 79 10\n","truncated":false}}
%---
%[output:26ed917e]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:3c3e35c5]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 9 12 13 15 16 17 21 22 24 28 30 31 34 36 45 54 55 60 63 65 68 70 77 78 79 80 81 82 83 96 98\n","truncated":false}}
%---
%[output:9b2ddbb4]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR10_RUN06.xlsx\n","truncated":false}}
%---
%[output:7c1f332c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [44 81] at positions [5 93]\n","truncated":false}}
%---
%[output:21bc0a16]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:573df5db]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:5165cb18]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:7c1eee64]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR10_RUN07.xlsx\n","truncated":false}}
%---
%[output:4973fb07]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 12 15 17 19 21 26 29 30 31 32 35 36 44 45 49 51 59 61 67 72 75 77 78 80 87 90 91 92 95 96 98\n","truncated":false}}
%---
%[output:709e56b3]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 27 2 87 6 70 43 3 59 96 31 95 81 56 8 38 71 7 26 32 58 39 62 22 35 85 41 48 19 74 49 52 72 91 69 79 29 45 1 14 84 36 86 12 46 75 44 18 77 11 24 9 67 61 40 42 60 5 51 65 76 94 66 20 93 88 54 90 25 28 63 17 68 55 53 13 15 73 16 64 83 34 4 89 50 21 10 47 30 92 80 37 78 82 23 33 57\n","truncated":false}}
%---
%[output:711883b6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [23 62] at positions [23 88]\n","truncated":false}}
%---
%[output:0c3385db]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:56903ab8]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR10_RUN08.xlsx\n","truncated":false}}
%---
%[output:0f2f33da]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:7800db28]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:469809c9]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 12 15 25 30 32 36 37 38 39 40 41 42 46 48 49 50 51 52 53 59 62 66 67 68 85 86 88 89 91 93 98\n","truncated":false}}
%---
%[output:8f239aa9]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:6f7d8921]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [20 11] at positions [40 52]\n","truncated":false}}
%---
%[output:41f3094c]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR11_RUN01.xlsx\n","truncated":false}}
%---
%[output:66b2b681]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 70 64 53 12 21 85 68 17 73 65 1 33 30 9 59 32 23 48 79 94 14 3 69 39 50 40 7 92 86 18 58 82 46 91 54 66 45 42 24 13 8 20 95 55 29 49 87 80 2 34 11 61 74 31 19 72 81 37 51 43 36 90 25 44 77 75 60 15 93 16 71 96 88 56 62 67 41 84 47 5 76 4 27 57 26 89 22 78 63 38 52 83 10 35 28 6\n","truncated":false}}
%---
%[output:117a3d40]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:0f2abfe4]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 5 8 12 14 17 21 22 25 31 34 35 36 39 45 50 51 59 70 73 74 79 81 83 84 86 88 89 92 93 95\n","truncated":false}}
%---
%[output:2e755fa2]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:459dae2e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR11_RUN02.xlsx\n","truncated":false}}
%---
%[output:1ee04461]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:4e7cf871]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [92 36] at positions [24 88]\n","truncated":false}}
%---
%[output:173f42f2]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:1f6b5544]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 6 9 14 18 20 21 29 35 36 44 45 46 47 49 54 55 58 60 61 65 67 72 73 75 77 78 87 90 93 96\n","truncated":false}}
%---
%[output:59f9d0aa]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR11_RUN03.xlsx\n","truncated":false}}
%---
%[output:52a0fa2e]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 16 64 94 5 41 74 56 46 28 30 90 26 68 84 60 13 72 69 21 63 17 14 95 78 44 55 71 2 29 33 83 47 11 7 43 45 15 58 53 81 82 73 67 49 20 85 39 34 89 10 65 88 57 61 38 76 18 1 92 93 25 24 40 22 50 77 3 23 80 35 62 9 12 37 8 86 31 42 54 4 51 70 87 66 36 32 96 52 91 48 79 27 59 19 75 6\n","truncated":false}}
%---
%[output:30bc1715]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:952206a1]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:268adf04]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [37 59] at positions [26 89]\n","truncated":false}}
%---
%[output:42b4d1f6]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR11_RUN04.xlsx\n","truncated":false}}
%---
%[output:7dff4a60]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 7 14 15 17 18 20 21 24 31 33 37 42 44 45 48 57 69 71 72 75 76 83 85 88 89 90 92 93 95 96 97\n","truncated":false}}
%---
%[output:892a88fd]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:814df403]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:084d9d7d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 94 of 96\n\t\tFound solution after 4 attempt(s): 95 65 37 43 77 3 52 36 83 33 25 31 51 58 5 27 67 80 63 17 14 81 55 72 89 24 34 49 90 96 9 79 21 82 53 71 40 10 4 42 22 60 2 69 88 6 94 23 32 68 59 86 85 38 39 7 45 61 56 35 66 11 18 92 75 74 20 13 64 30 46 87 41 78 19 91 15 1 76 54 26 48 28 12 62 84 73 44 16 93 57 70 8 29 50 47\n","truncated":false}}
%---
%[output:2d22495a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR11_RUN05.xlsx\n","truncated":false}}
%---
%[output:136f55c1]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:1d6c6796]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 6 14 15 18 20 21 26 30 33 40 42 43 44 46 47 50 52 58 63 65 67 68 73 79 81 83 85 89 92 94 95\n","truncated":false}}
%---
%[output:9c886e0d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [18 50] at positions [30 90]\n","truncated":false}}
%---
%[output:46ac79aa]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:5bfaa6e1]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR11_RUN06.xlsx\n","truncated":false}}
%---
%[output:92c0389d]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:8b5216d3]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:6f6eb337]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 7 10 11 12 14 26 28 29 31 33 34 35 37 42 49 54 62 63 66 71 73 76 79 80 81 84 87 90 93 94 97\n","truncated":false}}
%---
%[output:6fa00275]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 43 37 8 83 85 22 84 66 39 63 80 92 49 7 68 74 3 45 31 13 30 17 79 52 50 36 77 25 59 82 16 61 18 34 86 46 48 19 21 75 67 81 11 12 72 32 95 26 42 62 57 10 38 94 65 40 6 58 69 2 87 35 78 53 33 90 56 96 91 51 28 1 4 24 55 88 71 54 73 89 44 27 70 14 93 23 47 64 29 5 41 15 76 20 60 9\n","truncated":false}}
%---
%[output:93cd9340]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR11_RUN07.xlsx\n","truncated":false}}
%---
%[output:9fa27244]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:3438d3e1]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [65 28] at positions [36 81]\n","truncated":false}}
%---
%[output:81d7eb9f]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:8d5552b7]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 6 8 12 15 17 18 20 22 25 26 28 35 39 41 44 51 59 60 61 62 63 64 65 72 73 76 82 89 90 94 98\n","truncated":false}}
%---
%[output:1ad26af0]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR11_RUN08.xlsx\n","truncated":false}}
%---
%[output:3f5b5fb2]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:443b684f]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:4a36928c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 66 12 79 34 51 83 47 25 15 45 68 52 46 85 64 23 76 92 90 20 33 14 24 26 94 1 54 59 7 91 74 73 19 62 80 82 18 2 11 67 32 43 36 48 9 96 49 22 86 13 42 87 35 56 95 65 41 29 57 10 60 61 77 78 8 27 31 75 58 39 72 28 38 84 88 44 55 37 70 40 4 6 50 93 63 5 69 16 30 53 21 71 81 17 89 3\n","truncated":false}}
%---
%[output:5df57c4c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [82 39] at positions [22 55]\n","truncated":false}}
%---
%[output:419c4317]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 6 10 14 20 23 27 28 31 34 36 37 38 44 47 49 59 63 64 65 68 69 74 75 77 78 82 85 89 93 94 95\n","truncated":false}}
%---
%[output:33e0036d]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR12_RUN01.xlsx\n","truncated":false}}
%---
%[output:3e7b065b]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:8c790f62]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:5e60f64c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:0f81f65c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:486d0037]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR12_RUN02.xlsx\n","truncated":false}}
%---
%[output:6c21a933]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [65 23] at positions [17 79]\n","truncated":false}}
%---
%[output:374f6542]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 8 12 17 22 23 25 26 34 35 36 39 44 46 47 51 55 56 58 63 69 73 74 79 87 90 91 92 93 94 97\n","truncated":false}}
%---
%[output:88fb6b34]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tAttempt 3 ran out of options at trial 95 of 96\n\t\tFound solution after 4 attempt(s): 49 95 88 3 81 35 84 70 96 26 15 22 34 71 44 8 6 67 20 51 46 41 57 25 89 63 72 65 9 47 30 32 79 50 16 61 54 12 80 42 53 18 52 37 7 45 69 4 23 27 40 39 29 11 10 87 21 90 33 94 75 28 68 86 92 62 59 76 58 91 5 56 31 14 60 1 66 77 43 93 64 85 19 38 17 74 55 73 83 2 24 82 48 78 13 36\n","truncated":false}}
%---
%[output:989aed57]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:025c3058]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR12_RUN03.xlsx\n","truncated":false}}
%---
%[output:6e6cbed4]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:2aeb734b]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:04e1464f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 9 12 16 17 18 19 22 25 26 27 28 32 41 46 50 51 57 59 60 63 64 73 74 76 78 83 89 91 92 93\n","truncated":false}}
%---
%[output:9475c891]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [87 42] at positions [19 76]\n","truncated":false}}
%---
%[output:300ba005]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR12_RUN04.xlsx\n","truncated":false}}
%---
%[output:8a0aa71d]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:5a49876f]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:49ddfe54]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 31 83 94 13 36 77 89 46 24 74 41 3 32 35 82 55 75 27 6 58 1 86 67 49 90 28 64 20 30 22 69 4 2 79 68 39 42 59 43 87 81 72 57 52 16 9 25 92 14 51 62 80 26 10 76 84 17 47 18 54 34 63 85 61 29 60 65 5 38 71 73 37 45 12 96 44 53 91 11 56 48 66 15 40 8 88 21 95 33 23 7 70 19 78 93 50\n","truncated":false}}
%---
%[output:7d092546]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 6 7 11 13 17 19 20 28 32 38 40 42 43 44 47 50 51 59 60 62 65 69 70 78 79 83 89 93 94 96 97\n","truncated":false}}
%---
%[output:2aac7669]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR12_RUN05.xlsx\n","truncated":false}}
%---
%[output:38fcdb31]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:266b7218]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [96 94] at positions [9 74]\n","truncated":false}}
%---
%[output:67af97f3]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:0ee37845]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:07326fd0]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR12_RUN06.xlsx\n","truncated":false}}
%---
%[output:5d97ec37]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 3 4 6 12 15 16 17 19 32 34 41 44 47 48 51 53 61 63 65 67 77 78 80 81 84 85 89 93 96 98\n","truncated":false}}
%---
%[output:19e5812b]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:0ef0be3d]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 46 93 15 94 30 57 17 39 79 24 95 81 73 47 43 63 82 35 5 2 51 74 75 1 23 71 87 50 48 19 6 36 40 52 16 69 61 56 83 42 89 25 20 54 4 27 33 3 92 68 32 14 59 62 67 88 55 26 31 86 85 13 9 65 78 11 34 29 77 44 72 64 37 76 18 84 10 91 21 45 53 90 66 60 41 28 70 96 49 12 38 8 80 7 22 58\n","truncated":false}}
%---
%[output:5f472d93]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [50 32] at positions [37 60]\n","truncated":false}}
%---
%[output:5486efcd]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR12_RUN07.xlsx\n","truncated":false}}
%---
%[output:80359588]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:7f79df38]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 7 8 12 13 20 25 28 29 31 37 39 40 44 45 51 53 55 56 63 64 65 67 68 69 72 80 82 92 93 94\n","truncated":false}}
%---
%[output:28c39d45]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:31c73d31]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:9070d6fa]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR12_RUN08.xlsx\n","truncated":false}}
%---
%[output:4cc4a47c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:4e821fae]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [40 61] at positions [43 71]\n","truncated":false}}
%---
%[output:7295160e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 12 13 16 18 19 20 24 25 31 33 37 40 41 43 46 47 50 59 60 61 64 68 69 73 76 77 78 79 81 94 95 97\n","truncated":false}}
%---
%[output:8afb4722]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 52 4 73 68 44 40 57 51 33 24 84 14 25 39 82 65 2 38 66 60 22 54 78 90 63 95 30 10 87 42 9 11 50 72 18 29 74 67 64 41 20 3 16 80 89 96 17 61 21 92 55 5 34 8 56 59 83 77 15 31 79 27 26 37 49 43 86 7 88 91 35 69 48 47 75 93 70 46 94 13 85 19 36 1 76 6 53 12 45 28 58 23 81 62 71 32\n","truncated":false}}
%---
%[output:838959ac]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:729ab9c7]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR13_RUN01.xlsx\n","truncated":false}}
%---
%[output:3b140c05]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:301b5343]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:8fde4d58]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 5 6 14 15 23 24 26 28 29 36 41 42 47 48 51 55 56 58 59 65 66 67 71 72 77 78 83 87 90 95\n","truncated":false}}
%---
%[output:0d8b2a9a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [9 36] at positions [30 49]\n","truncated":false}}
%---
%[output:34528b31]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR13_RUN02.xlsx\n","truncated":false}}
%---
%[output:11a080e7]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:40d53963]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 80 26 30 10 55 57 38 42 7 87 4 37 78 9 11 19 53 66 47 82 56 90 23 65 68 93 48 58 8 74 50 17 83 94 67 25 46 18 15 89 64 88 12 27 72 5 36 75 60 63 71 44 31 34 33 85 73 84 21 51 1 76 70 49 41 6 2 54 28 96 95 45 59 39 81 43 16 52 32 29 61 79 13 24 92 14 40 62 91 20 35 77 86 69 22 3\n","truncated":false}}
%---
%[output:8bcb48dd]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:7df12e3e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 5 10 11 22 23 25 30 32 34 37 38 40 42 48 53 54 56 63 70 72 74 75 84 86 87 88 95 96 97 98\n","truncated":false}}
%---
%[output:26de9d45]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR13_RUN03.xlsx\n","truncated":false}}
%---
%[output:7c6d4614]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:55c85944]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:8efcb587]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [66 24] at positions [41 56]\n","truncated":false}}
%---
%[output:8b998a88]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:0e465ff3]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR13_RUN04.xlsx\n","truncated":false}}
%---
%[output:010cb6ff]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 15 85 69 57 14 1 37 47 77 42 54 84 94 50 22 4 62 36 92 3 74 83 41 6 18 96 32 49 63 76 7 60 66 27 73 67 61 45 26 20 39 72 44 40 31 43 64 29 71 23 55 11 48 93 68 70 8 81 82 17 12 21 95 38 10 79 89 56 87 2 13 78 9 46 86 52 59 90 80 35 58 28 30 51 34 75 88 5 19 91 33 24 16 53 65 25\n","truncated":false}}
%---
%[output:26407a74]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 5 7 10 12 15 18 20 21 22 23 27 39 42 49 52 53 54 56 57 65 66 67 69 74 78 88 91 92 93 94\n","truncated":false}}
%---
%[output:5242d09e]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:7e3fccb7]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:2182c669]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR13_RUN05.xlsx\n","truncated":false}}
%---
%[output:49c46ff5]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [80 53] at positions [32 90]\n","truncated":false}}
%---
%[output:6769a0b2]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:3aaa6695]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 6 7 8 10 19 20 22 23 24 27 32 36 40 42 45 53 54 56 63 65 68 71 74 75 77 81 87 89 90 91 93\n","truncated":false}}
%---
%[output:823a12a9]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:1a976f33]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR13_RUN06.xlsx\n","truncated":false}}
%---
%[output:2a336eb8]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tFound solution after 5 attempt(s): 96 27 76 54 67 3 16 55 31 28 33 51 58 85 37 23 83 65 34 68 82 90 5 92 53 39 13 45 48 91 1 72 73 29 59 8 18 14 38 12 17 56 77 30 93 95 22 41 26 25 6 70 81 78 62 7 11 50 60 44 89 47 52 20 69 46 79 10 88 57 84 35 40 15 94 74 66 32 43 75 86 49 19 87 9 80 64 36 21 61 71 2 42 63 4 24\n","truncated":false}}
%---
%[output:581b77c7]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:981e329e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [84 50] at positions [35 73]\n","truncated":false}}
%---
%[output:401e6ea3]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 12 16 19 21 25 28 29 30 31 33 35 40 46 47 49 53 54 55 58 61 71 72 73 76 78 80 82 87 91 94 98\n","truncated":false}}
%---
%[output:18463486]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR13_RUN07.xlsx\n","truncated":false}}
%---
%[output:68bec040]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:45f9262a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:9b7daaa0]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:638969f4]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 77 32 57 69 39 44 1 78 52 93 74 79 5 33 63 20 4 24 66 81 3 84 41 22 19 37 67 96 85 21 86 51 42 90 30 14 2 49 55 13 43 23 87 36 64 54 8 83 50 31 73 9 62 72 34 80 29 53 95 94 65 60 46 89 7 11 68 75 92 35 10 18 38 47 15 45 27 25 16 76 28 70 12 17 91 26 48 88 59 40 61 6 56 71 58 82\n","truncated":false}}
%---
%[output:0ffe69af]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR13_RUN08.xlsx\n","truncated":false}}
%---
%[output:1d73aa9f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 5 9 11 14 16 18 21 25 27 32 34 37 41 47 48 55 56 63 64 68 77 79 80 81 82 83 86 87 88 89 91\n","truncated":false}}
%---
%[output:30dd00d4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [7 42] at positions [23 85]\n","truncated":false}}
%---
%[output:4cdea382]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:50330406]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:4e2498c0]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:2d242ff0]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR14_RUN01.xlsx\n","truncated":false}}
%---
%[output:17cfa2e9]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 4 5 14 15 17 18 19 24 25 26 27 28 31 49 50 52 54 62 70 72 73 76 78 79 81 89 90 91 97 98\n","truncated":false}}
%---
%[output:7f67574f]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:4b5dcc27]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [52 74] at positions [14 67]\n","truncated":false}}
%---
%[output:8d7fe342]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 61 46 7 65 32 45 92 73 83 31 71 42 64 24 13 52 16 48 40 76 14 85 57 81 38 22 82 95 9 18 51 74 69 63 59 62 17 25 87 49 11 15 54 91 67 12 75 36 3 10 34 21 72 28 47 39 55 37 90 96 5 93 26 19 1 30 58 77 88 44 66 60 23 6 89 2 20 41 27 79 68 33 84 53 94 70 29 86 43 50 78 4 80 56 35 8\n","truncated":false}}
%---
%[output:62c9d280]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR14_RUN02.xlsx\n","truncated":false}}
%---
%[output:3dcc3654]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:6ac72f51]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 16 18 19 21 22 23 25 28 30 31 36 37 38 42 48 49 50 51 58 60 61 62 64 67 70 74 75 85 88 92 93 95\n","truncated":false}}
%---
%[output:0ed7fe5a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:8a054ca9]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:8714b562]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR14_RUN03.xlsx\n","truncated":false}}
%---
%[output:8e2887b4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [76 88] at positions [17 63]\n","truncated":false}}
%---
%[output:629319d6]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:2e4ca148]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 6 9 16 17 19 20 28 29 30 31 32 36 37 47 49 52 53 56 57 60 66 68 74 79 83 85 89 90 92 95 96\n","truncated":false}}
%---
%[output:9797549b]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:2fd3b2d9]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR14_RUN04.xlsx\n","truncated":false}}
%---
%[output:9300224d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tFound solution after 3 attempt(s): 72 50 70 69 27 15 12 77 46 81 3 21 93 67 88 61 90 31 52 30 19 68 8 35 22 44 45 13 89 48 53 62 6 55 43 65 38 58 41 84 94 34 71 1 47 36 26 37 7 87 9 80 91 73 32 29 83 85 49 16 18 60 96 20 5 10 64 79 56 63 17 74 76 4 33 57 66 92 75 51 28 2 25 59 42 86 11 78 40 23 39 14 82 54 95 24\n","truncated":false}}
%---
%[output:34825f73]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:6062f5ef]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [55 41] at positions [17 79]\n","truncated":false}}
%---
%[output:60b10183]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 4 5 10 13 14 25 27 29 31 32 39 40 45 46 60 63 65 66 68 73 74 79 83 84 87 88 89 90 91 96\n","truncated":false}}
%---
%[output:9bcb1d5f]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR14_RUN05.xlsx\n","truncated":false}}
%---
%[output:442df5dd]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:26a8d68e]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:21ef92f2]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:2a222a20]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 94 80 87 61 33 65 30 35 42 22 4 28 96 18 77 6 57 56 93 12 84 82 46 11 74 55 73 75 37 83 43 52 24 21 50 1 5 45 49 8 3 85 78 38 70 92 19 14 62 59 90 81 2 34 39 16 67 9 32 51 23 66 31 27 88 54 48 91 68 76 60 79 44 29 40 7 47 25 64 86 36 71 15 95 63 26 13 20 89 10 69 53 72 17 41 58\n","truncated":false}}
%---
%[output:55471ca5]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR14_RUN06.xlsx\n","truncated":false}}
%---
%[output:2c68e07a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [20 80] at positions [1 66]\n","truncated":false}}
%---
%[output:2262882b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 6 10 11 15 17 18 19 27 29 34 36 39 40 42 46 50 54 55 56 57 58 63 65 67 71 72 74 75 77 78 86\n","truncated":false}}
%---
%[output:346c18fe]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:679898f5]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:0301f257]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR14_RUN07.xlsx\n","truncated":false}}
%---
%[output:42951761]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:7cd24134]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:88bab87f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 6 10 12 14 18 19 22 25 30 33 41 43 47 49 56 62 63 65 66 68 70 71 74 75 77 79 80 82 93 97\n","truncated":false}}
%---
%[output:28970bc5]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 36 1 5 46 58 24 31 78 74 64 15 30 39 75 13 82 65 93 32 84 7 77 35 81 60 69 20 2 56 41 40 18 55 87 92 44 59 61 37 26 19 80 88 54 14 63 29 57 67 76 12 11 25 38 45 89 22 9 33 16 71 51 50 85 4 95 34 68 21 83 70 47 17 91 90 72 94 49 23 42 8 52 73 53 48 79 28 66 3 43 96 10 27 62 6 86\n","truncated":false}}
%---
%[output:316d19f5]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR14_RUN08.xlsx\n","truncated":false}}
%---
%[output:98178078]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [70 69] at positions [48 70]\n","truncated":false}}
%---
%[output:4266dc4d]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:650dd670]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:1e62d335]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 4 7 8 9 12 16 19 26 28 29 36 41 44 45 50 52 54 55 64 67 68 69 74 75 76 77 81 82 83 84\n","truncated":false}}
%---
%[output:224eac73]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:981a8311]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR15_RUN01.xlsx\n","truncated":false}}
%---
%[output:1ec5d34e]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:35f23208]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [49 26] at positions [5 54]\n","truncated":false}}
%---
%[output:5757096e]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 15 58 57 39 54 79 70 85 21 66 59 27 16 33 6 3 78 23 87 43 93 64 1 29 51 89 95 10 94 65 38 71 4 11 31 41 40 22 30 81 96 8 88 80 56 13 74 34 28 5 44 67 77 20 62 37 49 24 32 48 14 53 76 12 69 91 63 60 83 17 68 2 19 86 47 42 82 52 90 25 35 18 72 92 36 84 9 50 75 61 45 55 26 7 46 73\n","truncated":false}}
%---
%[output:8564acd2]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 7 8 16 20 24 26 27 31 33 35 40 43 44 47 49 51 52 58 59 62 67 69 71 72 76 80 81 82 91 92 95\n","truncated":false}}
%---
%[output:15b2aa9e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR15_RUN02.xlsx\n","truncated":false}}
%---
%[output:98549a8a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:666def18]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:78e5a181]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:8fba43a5]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [93 59] at positions [17 84]\n","truncated":false}}
%---
%[output:1310b2ea]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR15_RUN03.xlsx\n","truncated":false}}
%---
%[output:32b347c0]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 7 12 14 15 18 22 23 25 28 29 30 31 47 48 55 56 63 65 68 70 72 73 78 80 81 85 90 93 94 98\n","truncated":false}}
%---
%[output:88b41e35]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:27d1c118]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 23 7 29 85 59 72 63 53 96 80 3 81 18 60 36 25 48 93 9 13 33 74 83 89 46 4 64 28 19 75 27 37 42 55 14 76 43 41 26 51 91 87 58 1 6 90 35 49 78 66 57 24 22 77 38 88 65 86 5 67 31 84 30 11 20 61 62 44 73 70 2 50 32 94 39 8 45 16 92 10 56 95 79 21 15 69 52 12 47 68 82 17 71 40 54 34\n","truncated":false}}
%---
%[output:8688e69a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:6518269c]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR15_RUN04.xlsx\n","truncated":false}}
%---
%[output:26c5afb5]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:041ba8f6]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 5 6 7 13 23 27 30 32 34 35 38 39 40 41 45 53 61 68 69 73 75 76 79 82 83 84 85 86 91 92 98\n","truncated":false}}
%---
%[output:24c39195]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [67 65] at positions [11 71]\n","truncated":false}}
%---
%[output:6aba5cec]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:19f75e18]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR15_RUN05.xlsx\n","truncated":false}}
%---
%[output:51ff4ef0]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:7139e4b6]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 57 77 94 73 7 44 1 64 40 30 14 10 20 49 91 39 47 51 8 68 29 71 67 62 22 36 82 5 83 17 31 88 93 52 59 12 50 84 92 48 70 37 13 74 69 25 55 53 78 45 21 41 79 96 72 3 87 60 18 32 75 61 35 43 58 81 23 15 27 89 9 11 42 85 24 90 54 2 80 6 86 76 28 16 26 65 38 56 46 95 34 4 33 19 63 66\n","truncated":false}}
%---
%[output:14f7518e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 6 8 10 16 23 24 30 33 36 37 41 44 46 48 50 52 56 62 64 68 70 73 74 75 76 79 91 92 96 98\n","truncated":false}}
%---
%[output:61208a58]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:162674d8]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR15_RUN06.xlsx\n","truncated":false}}
%---
%[output:2dfa86b6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [11 66] at positions [37 63]\n","truncated":false}}
%---
%[output:25b3aa64]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:8b171040]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:53573207]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 6 7 8 18 21 22 27 29 30 34 38 39 41 43 45 49 52 57 58 61 62 64 70 74 76 78 79 81 92 93 94 97\n","truncated":false}}
%---
%[output:5151ef74]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR15_RUN07.xlsx\n","truncated":false}}
%---
%[output:25310801]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:31fbe3b7]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 7 74 92 46 88 2 31 63 65 68 50 37 73 10 62 22 79 47 64 6 3 83 69 20 35 27 82 32 13 41 14 95 85 52 58 90 53 5 19 29 66 44 40 42 86 48 54 34 9 77 25 96 1 57 93 26 12 15 43 70 76 16 38 21 55 60 78 81 87 71 61 18 30 36 59 11 56 75 45 67 94 4 89 24 8 72 28 80 51 33 84 39 23 91 49 17\n","truncated":false}}
%---
%[output:8b92d309]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [79 90] at positions [10 92]\n","truncated":false}}
%---
%[output:0780d9e2]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:6810e4ee]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR15_RUN08.xlsx\n","truncated":false}}
%---
%[output:95cb39c0]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:53ee9836]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 6 8 10 14 15 17 22 23 27 32 37 38 40 42 47 53 60 64 66 67 68 73 77 81 83 85 86 87 90 92 96\n","truncated":false}}
%---
%[output:4e7688e3]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:352905a5]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:70dfc373]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [23 3] at positions [36 94]\n","truncated":false}}
%---
%[output:4604204d]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR16_RUN01.xlsx\n","truncated":false}}
%---
%[output:7a33df34]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 37 63 45 47 14 85 82 66 1 78 33 74 23 20 96 49 51 19 56 89 25 69 60 73 94 13 31 38 30 9 50 11 35 91 41 39 52 5 2 59 83 32 92 67 72 46 4 81 36 79 29 53 18 10 43 27 40 86 93 7 3 24 71 55 77 75 6 65 84 57 54 34 8 61 21 28 15 70 95 44 90 17 42 80 58 88 62 12 87 76 22 68 16 26 64 48\n","truncated":false}}
%---
%[output:881a534c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 6 9 11 17 25 27 29 31 32 33 37 39 41 43 51 59 60 61 63 64 70 74 75 76 78 79 80 85 89 97\n","truncated":false}}
%---
%[output:422790aa]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:86e64f6f]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:2edd3131]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR16_RUN02.xlsx\n","truncated":false}}
%---
%[output:82884503]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:3162c55c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [63 28] at positions [24 67]\n","truncated":false}}
%---
%[output:2f864974]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 8 13 14 15 16 20 22 23 25 26 30 32 37 41 51 53 56 58 61 62 63 67 69 73 79 90 91 92 93 94\n","truncated":false}}
%---
%[output:8abd3a85]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:15478d92]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR16_RUN03.xlsx\n","truncated":false}}
%---
%[output:260130c9]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:483acdbc]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 3 84 2 21 32 42 46 17 86 77 60 85 93 28 74 38 68 11 54 15 13 35 50 69 23 16 65 95 55 45 89 33 10 75 70 58 61 19 56 81 66 1 6 48 39 18 57 12 63 41 87 5 90 62 29 24 7 30 91 26 79 31 36 71 80 92 37 64 52 78 40 4 82 94 20 14 73 59 67 44 76 88 51 34 96 8 27 72 9 53 83 47 22 43 49 25\n","truncated":false}}
%---
%[output:760eed64]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:9df8060b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 7 9 10 13 14 18 21 26 27 29 30 31 35 40 41 46 50 52 54 59 64 66 68 69 73 74 77 78 85 89 92 94\n","truncated":false}}
%---
%[output:185369de]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR16_RUN04.xlsx\n","truncated":false}}
%---
%[output:5ab0d9ed]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:5a1bda66]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [80 41] at positions [2 77]\n","truncated":false}}
%---
%[output:56480ebb]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:8d76315c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:379388a2]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR16_RUN05.xlsx\n","truncated":false}}
%---
%[output:8ead68ca]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 6 10 14 18 20 21 27 29 30 31 34 35 36 40 50 52 53 54 56 57 60 63 70 71 72 73 75 95 97 98\n","truncated":false}}
%---
%[output:4883ca4d]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 50 12 10 54 36 64 61 84 85 2 25 70 78 81 79 43 1 88 31 39 30 52 22 92 40 90 60 74 57 77 5 80 32 18 15 41 33 72 16 66 71 28 7 59 82 38 56 37 76 42 35 26 58 9 24 73 91 51 17 46 95 96 29 19 86 11 48 13 89 65 63 55 27 67 4 14 49 93 45 87 62 75 23 94 8 47 68 34 21 53 6 20 44 3 83 69\n","truncated":false}}
%---
%[output:48df3ad5]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 95 10 75 47 90 29 7 54 18 62 40 26 19 68 25 82 45 16 46 72 57 56 88 89 73 2 31 33 35 61 4 83 59 70 84 28 80 78 3 8 71 42 20 32 11 48 81 36 15 58 79 96 12 13 23 85 74 27 60 93 52 21 41 51 34 65 69 64 6 87 92 22 50 55 94 63 77 5 53 9 86 1 76 38 44 66 24 14 43 91 37 30 39 49 17 67\n","truncated":false}}
%---
%[output:75adc6bf]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [36 34] at positions [38 93]\n","truncated":false}}
%---
%[output:6891f091]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR16_RUN06.xlsx\n","truncated":false}}
%---
%[output:6a071c77]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 31 1 55 73 54 63 82 64 33 24 22 84 87 71 37 10 35 38 49 30 53 13 7 28 47 77 96 9 76 67 15 83 17 78 32 26 16 8 21 85 46 81 94 3 79 65 57 90 39 88 72 36 69 14 61 25 80 20 40 51 4 45 29 60 48 34 11 93 62 56 75 95 27 58 92 5 91 41 52 18 66 2 68 23 42 74 43 6 44 86 19 89 50 12 59 70\n","truncated":false}}
%---
%[output:88856124]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 7 8 15 20 21 25 26 28 31 38 39 40 43 45 48 51 52 53 59 61 63 73 75 80 82 87 89 90 93 95 97\n","truncated":false}}
%---
%[output:49204fda]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 66 48 73 63 50 76 69 4 57 14 81 6 22 52 92 71 30 7 43 15 8 65 84 40 44 26 18 95 93 61 29 78 35 54 38 85 23 47 20 67 9 2 90 58 77 89 91 79 80 32 31 82 12 72 55 25 62 53 13 56 46 37 1 33 88 45 74 21 41 64 83 27 5 28 39 51 17 59 10 86 24 87 16 75 42 68 49 94 36 96 70 3 19 11 60 34\n","truncated":false}}
%---
%[output:157679b7]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 44 20 4 41 68 11 31 59 37 5 72 93 19 24 84 77 76 17 65 33 94 82 51 70 58 83 35 47 62 3 8 61 32 38 23 87 14 90 40 9 80 13 18 39 91 86 16 89 22 73 43 78 75 63 64 30 12 1 48 53 2 52 88 69 25 56 45 34 27 21 36 74 81 60 67 26 57 49 85 6 55 42 15 92 66 7 29 95 46 54 28 10 79 96 50 71\n","truncated":false}}
%---
%[output:3142e626]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR16_RUN07.xlsx\n","truncated":false}}
%---
%[output:426de9c3]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 91 20 68 38 58 78 18 82 87 37 5 67 66 9 15 81 55 16 35 90 14 17 50 39 43 80 95 79 59 57 93 74 6 61 30 48 32 1 29 25 63 19 89 4 92 40 11 72 53 49 83 52 70 21 71 33 84 27 36 47 54 44 77 85 86 76 69 13 2 46 23 10 51 12 31 22 62 26 41 8 96 60 3 56 88 42 28 73 34 65 94 24 7 45 64 75\n","truncated":false}}
%---
%[output:0951746a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [51 47] at positions [38 72]\n","truncated":false}}
%---
%[output:28bcb3a1]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 3 8 9 11 12 14 18 20 26 28 31 34 42 45 51 60 62 64 66 70 71 74 75 81 84 86 87 89 90 91\n","truncated":false}}
%---
%[output:6f944c28]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 20 70 37 2 72 29 56 38 82 47 48 75 6 40 55 28 31 34 30 5 11 17 95 54 86 10 89 69 91 90 26 71 61 52 9 57 74 78 64 83 39 46 60 18 93 62 13 84 22 15 35 73 65 7 16 19 50 43 4 49 77 32 25 42 85 80 41 21 67 81 96 8 79 27 44 3 59 58 92 45 24 51 68 33 76 14 36 63 12 87 53 23 94 1 66 88\n","truncated":false}}
%---
%[output:65454485]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR16_RUN08.xlsx\n","truncated":false}}
%---
%[output:6f43b99b]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 35 27 19 55 15 72 8 36 77 40 44 4 95 22 16 49 94 61 37 83 39 62 54 28 90 96 67 82 9 21 48 57 73 56 17 79 24 60 65 66 30 25 34 84 46 41 71 70 6 7 29 13 3 64 11 42 26 76 89 58 63 38 5 87 85 14 68 45 93 69 50 92 32 86 53 43 75 52 91 10 74 2 23 59 78 47 51 12 88 18 33 31 81 80 20 1\n","truncated":false}}
%---
%[output:1fd79296]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 69 82 55 21 49 74 57 11 34 75 6 60 42 3 91 76 79 45 53 64 90 31 7 27 68 20 96 86 4 12 66 33 18 38 36 93 37 62 92 32 28 95 46 16 84 65 71 17 29 44 94 88 2 26 1 73 15 50 22 67 52 51 8 40 30 58 35 47 70 89 61 80 10 14 43 19 83 72 87 25 41 81 54 5 59 77 48 63 39 13 85 9 23 78 56 24\n","truncated":false}}
%---
%[output:46828745]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 18 5 89 79 66 26 64 30 96 14 3 23 36 53 9 56 93 85 19 24 67 7 77 86 51 40 12 39 82 46 37 80 45 22 32 76 52 65 83 54 60 81 74 38 13 43 28 34 50 71 75 4 6 25 95 47 33 94 27 57 61 44 72 29 1 87 88 8 70 49 20 68 15 58 16 78 17 2 48 21 55 35 11 59 92 41 90 63 10 84 69 42 62 73 91 31\n","truncated":false}}
%---
%[output:3f3b2013]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 10 12 26 27 28 29 30 32 33 34 40 42 43 44 47 50 55 57 59 68 69 77 78 79 85 88 91 92 94 96 97\n","truncated":false}}
%---
%[output:124dc535]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [1 16] at positions [24 84]\n","truncated":false}}
%---
%[output:145bac04]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR17_RUN01.xlsx\n","truncated":false}}
%---
%[output:6d331cb3]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 95 79 76 18 77 55 61 20 85 9 67 10 11 30 48 32 49 42 81 34 58 1 86 26 4 40 47 73 92 50 96 90 60 66 36 5 59 19 27 37 93 29 3 38 54 82 72 94 46 21 52 15 71 23 68 43 7 63 39 78 2 14 84 6 22 88 83 31 17 12 65 57 69 80 24 74 53 62 44 41 75 16 64 25 91 35 8 33 89 51 87 13 28 56 70 45\n","truncated":false}}
%---
%[output:643f9863]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 95 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tFound solution after 5 attempt(s): 55 7 6 40 81 67 58 65 72 18 39 62 27 93 57 37 32 64 95 12 85 35 43 3 25 5 77 2 50 53 19 76 92 89 24 29 11 33 71 38 23 28 34 90 61 10 30 54 60 45 9 88 36 52 96 68 48 70 51 73 14 4 66 91 94 13 56 41 46 84 22 79 69 21 86 26 63 16 59 17 8 80 83 75 42 78 49 87 1 44 20 74 31 47 15 82\n","truncated":false}}
%---
%[output:8e71bd2f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 5 82 67 75 84 31 66 58 45 79 47 34 94 8 46 20 38 49 65 6 1 80 22 50 81 39 10 26 3 52 32 30 83 60 15 19 71 78 41 88 91 74 63 61 69 21 13 64 85 54 18 42 25 93 44 72 95 16 70 11 37 2 12 89 92 29 56 55 48 35 62 14 76 96 4 33 87 68 7 23 28 73 53 43 51 77 24 36 27 57 17 90 59 9 86 40\n","truncated":false}}
%---
%[output:524cdd2f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 32 57 95 61 18 35 33 1 52 68 80 25 21 74 36 60 6 28 92 10 87 89 67 62 40 30 2 9 46 82 47 65 7 73 88 23 5 37 64 51 12 11 59 42 75 54 63 20 56 76 26 69 41 94 38 48 16 86 58 84 22 43 29 19 85 13 70 93 91 72 4 17 8 39 49 96 77 78 50 14 53 45 15 79 24 71 44 66 81 34 83 31 90 3 27 55\n","truncated":false}}
%---
%[output:9ec0aa31]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR17_RUN02.xlsx\n","truncated":false}}
%---
%[output:3d27e2b5]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 4 6 14 17 23 24 25 26 34 36 38 42 46 47 50 53 56 57 72 75 80 81 82 85 86 88 93 95 97 98\n","truncated":false}}
%---
%[output:6ac771d0]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [70 11] at positions [22 72]\n","truncated":false}}
%---
%[output:624f6a14]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 75 27 11 10 20 86 47 36 83 12 74 54 50 19 44 61 80 45 78 8 59 39 30 63 82 62 2 96 76 95 90 29 73 72 7 40 1 16 31 23 17 15 48 51 24 89 94 26 69 32 46 91 60 81 13 84 66 70 57 58 68 41 6 49 42 43 28 55 4 67 92 34 65 35 71 21 37 88 79 64 25 14 87 52 38 56 77 3 33 5 18 53 93 22 85 9\n","truncated":false}}
%---
%[output:6806e70d]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 49 80 45 56 6 42 74 85 53 62 86 36 28 75 25 90 24 22 1 27 51 18 34 94 82 7 64 47 15 14 84 72 3 68 67 57 50 73 12 69 83 38 43 59 26 77 31 61 8 23 21 4 55 88 19 89 66 78 48 29 35 10 13 33 40 76 63 39 81 54 93 92 9 87 52 17 41 91 65 5 20 71 46 11 58 79 60 44 32 95 2 96 30 16 37 70\n","truncated":false}}
%---
%[output:789c06fd]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR17_RUN03.xlsx\n","truncated":false}}
%---
%[output:66b49db0]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 29 86 31 46 17 30 15 57 96 44 38 79 67 39 95 13 21 63 33 52 28 66 10 90 91 73 61 11 48 6 70 81 64 62 72 22 49 36 88 26 69 32 5 1 35 7 93 50 18 27 47 78 43 40 53 74 56 14 54 58 85 42 24 89 16 80 77 82 84 76 12 4 25 94 68 2 60 37 20 71 83 51 19 8 65 45 92 23 41 55 87 9 34 75 59 3\n","truncated":false}}
%---
%[output:9b394387]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 11 16 20 21 22 23 24 28 29 34 39 40 43 45 47 53 58 59 62 66 70 74 77 80 81 86 87 90 95 97 98\n","truncated":false}}
%---
%[output:563f64e5]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 7 16 83 12 53 74 21 18 75 73 89 68 41 63 29 35 66 52 10 46 22 59 95 28 15 30 96 58 43 93 86 39 48 11 65 2 64 51 69 56 85 91 50 49 37 84 77 9 42 71 24 62 19 80 33 61 5 3 25 13 82 26 17 38 36 27 94 14 67 72 90 47 1 60 45 57 70 32 34 23 8 81 54 31 92 6 76 44 87 78 88 20 55 4 40 79\n","truncated":false}}
%---
%[output:9a09aa7c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [78 26] at positions [6 75]\n","truncated":false}}
%---
%[output:3f214357]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR17_RUN04.xlsx\n","truncated":false}}
%---
%[output:5e823541]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 94 of 96\n\t\tFound solution after 3 attempt(s): 40 22 82 66 18 34 51 65 37 85 50 64 8 60 94 24 4 41 72 5 84 81 7 1 79 89 46 11 30 68 67 52 31 55 42 44 77 39 58 92 54 69 3 26 27 80 73 17 12 74 56 6 10 53 36 87 86 29 32 96 75 93 15 48 14 90 43 21 38 45 61 20 57 63 9 95 19 2 28 71 25 59 88 16 78 62 70 33 13 47 76 91 35 23 83 49\n","truncated":false}}
%---
%[output:167a22bc]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 95 84 74 77 50 38 68 2 34 82 26 48 3 10 28 30 65 92 52 27 6 70 44 23 62 90 43 61 67 17 96 7 87 64 16 54 53 81 78 89 21 18 40 39 19 80 59 66 32 12 8 45 63 37 73 1 88 94 13 25 93 47 33 85 57 31 56 14 76 71 42 11 60 55 83 69 22 91 36 51 29 4 58 5 24 46 15 41 79 49 72 35 20 75 9 86\n","truncated":false}}
%---
%[output:307cf288]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 6 7 10 15 17 23 25 27 31 32 34 43 45 48 51 52 54 61 63 66 67 68 70 71 72 78 80 83 85 97\n","truncated":false}}
%---
%[output:046610a1]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 77 32 37 50 34 78 82 46 35 16 1 63 83 28 57 71 52 31 2 33 91 56 61 12 80 74 43 25 86 75 6 20 21 65 36 66 49 39 54 67 85 7 87 96 94 76 29 24 93 13 51 19 4 84 64 15 41 27 69 3 22 48 90 42 11 68 70 59 53 92 23 62 14 5 26 40 47 60 17 55 44 81 10 88 72 9 45 8 73 30 79 89 38 18 95 58\n","truncated":false}}
%---
%[output:0dd20b09]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR17_RUN05.xlsx\n","truncated":false}}
%---
%[output:645cd71d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 12 14 45 31 37 52 23 72 74 6 81 92 58 38 90 18 91 9 79 36 16 55 89 75 56 71 17 8 19 51 62 15 7 84 35 43 67 83 24 25 63 48 69 95 60 27 22 65 44 47 49 80 57 53 5 77 20 13 40 28 96 94 39 11 21 34 93 4 59 87 70 2 86 76 73 50 42 68 3 41 85 32 10 66 29 61 26 88 54 78 46 1 64 82 33 30\n","truncated":false}}
%---
%[output:2a93b671]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [23 70] at positions [7 71]\n","truncated":false}}
%---
%[output:70c09e0e]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 84 28 41 15 36 17 79 8 21 31 81 6 16 82 88 39 77 53 90 55 49 71 96 80 74 19 4 50 7 68 43 85 24 64 18 91 33 58 37 47 29 1 12 94 83 56 65 52 57 95 72 14 76 70 34 86 10 46 73 32 51 26 44 38 9 61 11 27 25 75 89 45 63 48 13 60 22 3 35 54 5 87 67 30 78 2 20 62 69 93 23 42 66 59 40 92\n","truncated":false}}
%---
%[output:3599839a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 7 14 20 23 25 27 29 30 31 34 38 40 46 47 48 51 54 58 59 61 67 69 70 71 74 79 80 83 87 96 98\n","truncated":false}}
%---
%[output:66af172a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR17_RUN06.xlsx\n","truncated":false}}
%---
%[output:8c45965e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 82 43 83 51 58 69 76 31 20 79 11 62 17 14 41 5 9 27 37 38 57 91 80 85 3 86 94 23 90 54 39 72 48 18 59 1 78 52 19 33 64 67 15 10 35 92 30 7 60 16 21 22 95 81 36 40 26 71 34 6 88 2 68 66 25 56 49 87 75 89 29 63 42 73 55 77 24 65 50 46 53 32 44 4 28 84 47 96 12 45 70 13 93 61 8 74\n","truncated":false}}
%---
%[output:44f75939]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 5 93 95 6 49 35 36 85 62 76 11 40 55 54 92 68 17 63 32 70 80 52 1 18 39 4 15 72 96 33 71 46 24 22 83 28 9 66 37 53 20 59 75 8 81 79 88 89 57 87 2 61 64 42 38 13 43 67 78 60 10 16 19 65 27 91 45 26 23 14 73 94 31 48 86 56 77 3 90 7 50 30 58 47 84 25 82 44 74 21 41 29 69 34 51 12\n","truncated":false}}
%---
%[output:411a50b7]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 74 63 42 85 43 57 64 89 88 52 11 48 41 70 7 82 2 71 39 3 23 35 21 75 73 25 32 8 12 58 65 91 26 59 30 83 72 29 56 78 37 47 69 9 14 79 90 1 18 94 54 81 44 50 22 45 27 6 61 4 92 67 66 60 33 87 84 24 68 96 77 31 19 15 36 10 51 49 28 55 38 5 76 13 86 46 53 93 62 16 20 80 34 17 40 95\n","truncated":false}}
%---
%[output:45bf6283]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [4 44] at positions [27 63]\n","truncated":false}}
%---
%[output:96dfd2cb]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR17_RUN07.xlsx\n","truncated":false}}
%---
%[output:4ca1a89a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 5 13 17 18 19 29 35 37 38 41 42 45 46 48 49 51 52 55 56 62 67 68 69 73 75 78 84 88 94 96 98\n","truncated":false}}
%---
%[output:87c05ce5]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 59 32 25 12 44 37 82 83 75 60 55 70 95 30 80 74 22 46 9 64 13 16 29 94 45 58 36 79 5 67 42 18 51 87 7 96 61 78 14 1 73 84 35 88 50 11 23 54 34 10 39 68 20 8 90 21 28 71 52 31 41 27 85 93 6 62 49 86 69 65 40 56 17 43 38 89 26 63 33 19 76 48 72 4 66 53 77 92 15 57 3 24 91 47 2 81\n","truncated":false}}
%---
%[output:70600b36]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 37 13 62 42 31 20 45 65 11 91 61 76 70 36 94 68 92 43 54 63 86 16 17 72 30 56 21 15 75 57 6 8 46 40 87 32 82 96 9 4 33 80 47 60 78 66 14 67 25 51 52 12 93 59 22 3 24 35 38 5 55 44 19 28 77 84 18 88 90 48 2 69 53 95 73 34 23 64 74 10 49 83 7 27 1 89 79 26 85 41 71 81 58 39 50 29\n","truncated":false}}
%---
%[output:2469f354]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 20 77 48 71 25 33 5 53 40 30 22 83 78 72 50 90 36 34 52 24 49 1 12 91 17 6 47 87 54 74 85 4 26 37 16 69 8 81 86 51 59 70 68 88 66 2 29 7 15 44 82 21 55 11 61 63 94 96 10 67 62 31 84 45 38 64 42 23 32 79 28 57 9 73 46 75 92 43 93 58 35 19 14 27 95 18 65 3 41 56 89 13 60 80 39 76\n","truncated":false}}
%---
%[output:9e2beaf5]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR17_RUN08.xlsx\n","truncated":false}}
%---
%[output:05c5dd03]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 44 43 30 47 56 66 65 61 94 16 79 21 5 23 70 84 55 60 3 85 88 18 86 41 75 7 34 96 68 48 15 8 57 25 26 49 46 31 62 10 17 95 19 69 42 36 93 67 50 45 58 90 1 81 59 74 24 4 11 64 32 29 39 77 87 37 2 40 13 72 73 6 92 82 20 35 71 63 54 38 28 14 52 91 53 9 76 89 80 27 83 33 51 22 78 12\n","truncated":false}}
%---
%[output:23ad14c0]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 6 10 11 18 20 21 22 24 26 34 38 40 42 48 50 55 65 69 71 73 74 76 77 79 85 86 89 90 94 97\n","truncated":false}}
%---
%[output:6934fb8c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tFound solution after 5 attempt(s): 55 86 28 92 80 59 10 16 61 51 32 21 75 3 23 7 85 15 40 82 64 70 31 39 44 11 72 87 33 29 57 36 78 35 49 90 96 43 71 69 68 8 30 6 77 47 53 46 12 38 81 9 95 56 74 52 26 34 37 27 94 25 19 54 5 14 62 58 79 88 84 73 17 67 45 65 2 48 60 13 20 50 93 4 66 22 83 41 1 91 76 63 18 42 89 24\n","truncated":false}}
%---
%[output:43df5431]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [11 6] at positions [11 60]\n","truncated":false}}
%---
%[output:04bf898d]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 24 55 79 86 3 66 37 75 15 4 34 27 88 41 50 54 40 94 26 21 36 14 30 9 83 71 32 69 60 19 82 56 10 53 95 84 80 74 48 47 25 39 13 16 92 63 76 2 57 93 33 85 8 78 96 28 65 52 23 58 12 42 38 77 20 11 31 29 35 64 45 70 72 5 89 91 73 51 62 22 49 44 90 17 1 61 7 68 87 6 43 59 67 46 18 81\n","truncated":false}}
%---
%[output:8ffd3d82]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR18_RUN01.xlsx\n","truncated":false}}
%---
%[output:96be1319]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 72 48 53 58 45 29 6 81 83 75 13 59 74 55 5 79 87 61 88 7 20 35 85 39 9 47 73 71 32 66 95 31 86 60 23 22 62 28 91 34 46 78 50 4 16 70 36 26 49 54 77 17 8 25 27 65 69 12 44 41 15 14 57 92 3 89 68 93 30 38 51 40 84 96 42 2 80 24 82 1 64 43 56 10 21 76 52 18 33 19 11 90 63 67 37 94\n","truncated":false}}
%---
%[output:0d378df6]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 6 7 8 10 12 13 19 26 27 28 30 31 45 48 51 53 59 60 63 64 65 68 76 79 81 83 86 90 92 94\n","truncated":false}}
%---
%[output:90e822c4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tFound solution after 5 attempt(s): 54 11 85 64 95 70 18 23 37 55 42 35 80 90 21 62 77 57 17 16 4 32 71 79 40 15 75 13 46 22 88 9 60 49 96 41 91 87 8 28 74 39 20 33 34 89 69 14 5 59 24 7 94 29 50 51 66 27 92 48 10 45 52 2 72 81 63 36 73 61 76 68 83 82 25 30 65 44 78 31 1 43 19 58 38 84 47 12 56 86 6 26 93 53 3 67\n","truncated":false}}
%---
%[output:2266e701]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 85 4 95 89 80 45 65 22 66 87 54 38 94 31 18 46 10 2 19 56 25 12 57 5 40 50 60 86 39 47 20 81 28 3 71 16 37 11 78 64 77 76 13 1 96 70 27 21 35 68 51 88 15 63 23 73 79 44 36 93 91 41 52 8 26 84 59 74 82 34 29 58 61 33 83 9 48 67 55 24 92 30 7 17 42 49 6 62 69 43 14 75 32 53 90 72\n","truncated":false}}
%---
%[output:9365c44c]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR18_RUN02.xlsx\n","truncated":false}}
%---
%[output:4b64f04b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [55 65] at positions [13 64]\n","truncated":false}}
%---
%[output:42925741]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 38 21 40 60 44 82 36 10 59 23 58 1 34 70 63 85 87 53 67 35 41 6 29 79 78 96 75 4 74 18 30 3 92 16 14 73 42 62 64 76 15 84 20 91 65 72 57 81 32 61 52 47 94 39 80 24 13 11 37 33 17 88 90 8 27 43 7 54 22 66 89 51 2 45 83 12 77 95 50 86 26 19 5 28 71 46 49 69 56 9 93 48 68 25 55 31\n","truncated":false}}
%---
%[output:0e49875b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 6 7 9 11 12 13 15 21 24 29 36 37 43 45 51 54 57 62 67 72 75 80 81 82 86 87 92 93 96 97\n","truncated":false}}
%---
%[output:34efaf41]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 8 76 45 90 79 74 1 23 6 13 92 16 62 39 64 53 32 69 93 88 21 31 35 25 84 33 40 7 38 70 49 4 47 36 55 96 54 68 19 56 5 27 17 51 41 28 75 63 61 18 46 65 82 80 48 10 66 78 9 95 59 83 22 2 57 77 24 91 81 43 86 12 3 60 67 50 29 44 26 87 30 58 14 34 15 89 37 72 85 71 11 20 73 42 52 94\n","truncated":false}}
%---
%[output:27151d07]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR18_RUN03.xlsx\n","truncated":false}}
%---
%[output:611d47e3]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 77 12 14 67 38 5 45 36 18 74 88 89 54 7 93 80 60 43 49 85 17 4 51 58 22 21 55 68 31 46 91 10 23 94 35 69 75 72 56 62 8 44 42 15 82 30 25 41 65 26 63 33 20 11 76 3 59 95 92 47 87 66 40 50 32 96 16 2 24 73 90 53 79 37 9 39 84 6 71 81 27 34 61 19 57 48 29 70 1 86 52 13 28 83 78 64\n","truncated":false}}
%---
%[output:94792f17]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 94 of 96\n\t\tFound solution after 5 attempt(s): 60 12 18 85 93 79 62 48 65 1 87 52 82 40 88 23 39 47 31 56 17 25 78 26 6 38 4 61 53 77 42 57 9 2 74 90 10 32 92 43 3 63 37 46 67 75 49 70 80 94 55 95 91 11 72 28 14 33 64 59 30 27 58 76 13 86 21 41 83 68 45 22 73 7 16 36 29 96 34 8 51 35 54 15 24 44 66 89 5 81 71 20 50 84 19 69\n","truncated":false}}
%---
%[output:1026b268]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [41 92] at positions [13 61]\n","truncated":false}}
%---
%[output:12d7d6c4]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 15 66 20 9 37 52 16 7 19 56 59 22 34 33 25 21 83 43 68 72 45 96 5 82 71 60 39 11 61 70 95 50 91 92 28 79 13 73 69 51 81 17 1 62 80 3 8 86 55 46 57 63 29 26 36 23 77 93 88 65 47 75 30 53 4 24 84 44 90 14 42 40 12 85 54 48 10 74 18 76 58 2 64 67 35 27 49 89 31 94 38 78 6 32 41 87\n","truncated":false}}
%---
%[output:400409fb]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR18_RUN04.xlsx\n","truncated":false}}
%---
%[output:20fc5514]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 6 7 8 9 10 15 18 25 26 29 31 35 36 44 48 51 55 59 60 63 64 65 70 71 73 75 80 82 87 91 94\n","truncated":false}}
%---
%[output:28c47be2]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 43 28 56 50 83 81 66 71 26 40 77 16 73 87 24 27 94 55 46 4 36 37 92 48 60 69 38 30 5 29 75 64 18 51 14 62 15 11 88 10 8 95 52 20 32 91 42 7 47 89 1 70 49 76 34 39 68 80 9 57 58 85 21 44 53 45 17 72 22 2 25 84 74 96 86 23 54 41 82 61 6 63 93 65 90 13 31 3 79 59 19 78 35 67 12 33\n","truncated":false}}
%---
%[output:77aabf22]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 91 44 63 60 20 19 70 86 96 62 93 9 84 73 42 83 28 7 26 64 16 55 77 65 49 46 31 36 45 12 11 43 76 13 69 23 85 67 21 37 80 89 3 39 94 92 61 82 47 58 56 40 14 8 72 52 32 18 10 22 59 75 6 57 2 95 24 78 34 27 88 50 48 38 54 15 41 71 74 5 90 1 30 66 87 29 33 25 53 68 51 17 4 79 35 81\n","truncated":false}}
%---
%[output:44e63ea7]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 56 68 60 23 53 8 45 58 42 91 24 84 43 22 36 72 1 61 51 93 83 9 88 59 78 75 27 30 71 47 3 26 6 69 81 70 18 73 94 50 37 38 7 10 28 16 13 66 15 96 44 31 49 92 76 77 39 67 52 14 48 55 19 95 4 64 57 65 41 90 82 20 34 40 21 32 12 87 63 29 79 85 2 46 89 17 62 86 35 5 74 11 54 33 80 25\n","truncated":false}}
%---
%[output:7b3078ed]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR18_RUN05.xlsx\n","truncated":false}}
%---
%[output:828dfe2e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [16 31] at positions [22 60]\n","truncated":false}}
%---
%[output:69073403]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 5 6 13 15 17 20 27 33 37 38 41 42 44 45 50 51 56 57 58 60 66 67 68 70 81 82 84 85 91 94\n","truncated":false}}
%---
%[output:2d032691]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 94 of 96\n\t\tFound solution after 4 attempt(s): 69 93 89 74 49 11 41 65 22 44 42 1 14 76 45 62 94 9 85 35 92 17 21 77 71 3 52 55 19 58 40 26 12 25 96 64 68 59 10 79 30 75 84 82 33 83 8 50 36 29 51 87 57 72 13 34 2 28 38 43 63 53 20 90 67 78 47 80 6 4 95 32 24 16 46 73 86 18 60 15 56 27 88 61 39 7 70 31 66 54 91 48 81 5 23 37\n","truncated":false}}
%---
%[output:9835a591]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 19 50 46 34 14 10 23 13 70 48 26 78 1 33 64 49 96 63 25 87 37 65 71 18 29 36 90 6 58 72 85 83 22 27 57 15 91 69 62 82 84 73 5 54 53 8 24 66 47 44 79 95 32 11 39 9 88 55 45 21 38 59 28 93 35 92 2 3 75 74 30 81 61 76 51 94 41 68 7 31 40 86 4 56 12 42 16 77 52 67 17 80 89 20 60 43\n","truncated":false}}
%---
%[output:0437f084]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR18_RUN06.xlsx\n","truncated":false}}
%---
%[output:1740300f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 16 45 53 54 34 10 2 18 28 81 42 75 64 85 11 56 12 74 65 88 52 66 9 91 68 40 48 23 71 20 4 58 30 60 24 35 93 19 70 7 46 51 3 92 87 94 47 89 55 36 43 14 25 84 29 8 5 67 44 26 63 62 83 80 22 31 41 79 49 73 86 1 33 50 90 38 77 72 6 76 57 78 39 96 69 32 61 21 37 17 95 59 15 82 13 27\n","truncated":false}}
%---
%[output:725e211e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 35 47 18 20 44 6 76 25 9 17 70 14 58 64 15 92 34 69 93 3 11 39 49 26 85 61 74 67 63 40 91 32 51 81 79 46 37 88 84 82 59 53 72 13 27 2 86 48 29 31 83 4 54 12 65 38 80 57 19 43 5 33 55 36 68 77 95 22 66 30 50 90 78 21 10 1 45 94 73 7 23 41 62 89 56 42 28 75 60 24 52 16 71 96 8 87\n","truncated":false}}
%---
%[output:409d7539]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 5 12 13 15 16 17 18 24 27 28 35 36 39 41 50 58 59 63 65 67 69 71 74 75 76 78 82 83 86 94\n","truncated":false}}
%---
%[output:895dcad1]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [70 24] at positions [13 57]\n","truncated":false}}
%---
%[output:852725e2]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR18_RUN07.xlsx\n","truncated":false}}
%---
%[output:203cc677]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 75 17 11 72 56 50 20 81 62 14 84 46 7 49 65 76 42 71 95 94 73 15 9 35 48 30 34 88 2 27 77 32 22 60 45 63 82 25 79 6 28 59 1 89 26 33 31 83 40 64 29 16 54 41 85 10 80 69 47 68 90 87 70 57 51 67 37 4 5 36 44 92 52 86 78 21 23 53 38 19 74 8 39 66 91 55 12 61 93 3 24 13 96 43 58 18\n","truncated":false}}
%---
%[output:6e986856]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 95 81 28 5 86 47 46 82 63 52 45 27 43 75 4 76 92 10 13 44 56 16 19 70 18 90 74 72 55 26 21 64 85 1 58 71 34 15 57 54 79 69 93 62 96 24 20 91 89 38 2 80 37 39 23 36 77 22 60 35 50 8 94 66 53 29 7 42 88 12 6 17 68 14 59 31 73 33 49 83 61 48 65 25 87 78 3 32 41 11 84 40 30 51 9 67\n","truncated":false}}
%---
%[output:022abd85]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 8 76 79 26 17 35 56 3 7 64 36 39 83 73 16 40 5 86 14 31 82 33 24 61 81 89 57 71 41 77 59 32 67 85 21 4 96 48 34 23 94 62 55 58 46 54 11 53 95 15 70 88 84 65 66 30 72 51 19 1 25 50 74 6 43 91 18 44 75 47 12 2 60 90 68 10 29 22 42 78 38 28 49 20 13 87 52 80 27 93 37 63 45 9 69 92\n","truncated":false}}
%---
%[output:928278f8]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 7 8 13 14 18 21 22 23 37 38 41 42 46 48 54 55 56 58 64 66 67 68 74 79 82 83 88 94 97 98\n","truncated":false}}
%---
%[output:4654700e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR18_RUN08.xlsx\n","truncated":false}}
%---
%[output:9a082496]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tFound solution after 3 attempt(s): 27 41 74 45 92 18 58 89 85 33 20 26 13 72 4 8 81 9 53 43 38 51 16 29 91 50 71 88 73 31 75 54 28 2 35 5 24 47 63 52 80 67 17 32 83 12 77 84 90 65 79 48 11 7 82 62 93 39 69 6 46 30 70 57 23 49 34 87 19 55 59 15 60 40 37 10 76 1 95 66 25 78 56 96 42 86 64 22 3 61 14 36 21 44 68 94\n","truncated":false}}
%---
%[output:1137a51f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [24 92] at positions [20 77]\n","truncated":false}}
%---
%[output:20e556cf]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 54 18 69 11 89 57 87 92 39 29 14 52 79 73 47 3 12 28 64 37 66 95 10 71 59 55 4 36 85 76 24 93 27 38 33 49 8 35 31 19 91 63 94 32 75 86 13 21 2 5 72 51 25 40 50 56 46 7 60 78 70 26 58 83 80 48 65 16 88 81 34 96 68 90 53 41 44 15 45 30 23 1 84 22 74 6 62 17 61 77 42 67 20 43 82 9\n","truncated":false}}
%---
%[output:77bcd5ad]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 43 46 71 81 14 17 65 10 84 33 54 86 74 57 56 75 35 83 95 28 64 30 23 34 18 4 41 9 63 42 85 58 7 80 31 89 94 12 5 79 66 32 73 90 44 25 50 51 39 3 11 92 78 55 96 19 8 21 37 60 76 68 2 53 15 48 45 67 38 82 61 20 93 6 69 88 52 22 24 72 59 13 40 26 62 47 77 27 36 1 29 87 70 16 49 91\n","truncated":false}}
%---
%[output:7392d664]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 10 12 13 15 17 19 23 31 32 35 41 42 45 48 50 52 53 54 66 67 71 75 77 78 84 87 88 90 91 94\n","truncated":false}}
%---
%[output:59e0a077]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR19_RUN01.xlsx\n","truncated":false}}
%---
%[output:24d139a6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 22 5 68 37 91 13 60 7 15 26 82 43 41 56 32 79 83 87 70 23 20 50 44 18 35 67 54 72 6 88 63 96 19 16 33 12 90 47 40 55 61 10 39 65 78 77 48 1 53 27 59 36 17 46 85 94 14 74 29 92 30 21 76 57 62 71 9 2 28 81 49 95 75 89 73 3 38 11 51 42 69 25 8 24 64 86 45 58 80 93 52 31 34 84 4 66\n","truncated":false}}
%---
%[output:80defc8c]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 93 2 92 45 52 83 30 18 7 37 33 24 39 91 89 74 25 57 66 75 40 11 16 73 3 54 34 67 84 59 31 77 60 5 21 82 41 87 64 55 6 49 17 58 46 69 61 71 72 19 88 90 32 1 22 48 42 28 29 78 13 43 56 94 9 14 76 85 68 35 15 86 65 62 51 79 96 12 23 8 63 27 50 81 38 70 44 95 26 36 20 80 10 47 53 4\n","truncated":false}}
%---
%[output:2bce618c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [44 40] at positions [1 68]\n","truncated":false}}
%---
%[output:902539eb]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 85 35 78 82 88 65 42 18 5 9 71 67 31 86 11 33 54 84 27 38 8 28 60 3 92 49 59 70 64 21 69 10 51 39 46 95 43 50 44 12 47 40 81 52 56 16 19 20 41 26 22 58 79 37 76 77 96 29 83 80 14 90 91 4 62 93 55 24 72 32 6 1 66 63 15 23 45 68 57 73 87 36 61 30 2 89 25 53 48 13 75 7 34 17 94 74\n","truncated":false}}
%---
%[output:4021584b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR19_RUN02.xlsx\n","truncated":false}}
%---
%[output:408be159]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 6 9 11 17 18 19 20 23 31 35 44 45 47 48 56 61 62 63 67 73 74 75 79 81 84 86 88 89 96 98\n","truncated":false}}
%---
%[output:421ce65f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 18 23 69 76 9 33 4 78 55 54 74 96 48 59 92 13 49 17 84 19 7 8 29 60 41 35 94 65 40 77 27 47 25 66 37 1 83 82 64 10 15 95 43 72 89 30 11 45 81 52 75 22 31 34 32 90 16 28 61 62 20 14 79 2 56 91 86 68 71 63 42 51 6 57 12 21 38 46 88 36 53 93 73 50 44 24 85 26 67 3 87 58 80 39 5 70\n","truncated":false}}
%---
%[output:60d30f52]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 48 31 17 2 53 25 76 10 13 81 68 19 54 96 60 51 66 93 16 39 73 43 11 80 69 59 38 35 86 84 18 44 56 7 28 91 33 92 82 45 78 49 34 24 9 41 12 89 22 65 4 79 72 40 50 52 88 14 3 58 71 94 55 6 26 63 21 42 46 32 95 74 29 30 70 27 85 1 23 5 57 36 67 64 15 47 90 37 61 87 75 8 77 83 62 20\n","truncated":false}}
%---
%[output:4fe9b5b6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 72 23 67 39 59 34 71 64 32 11 24 86 88 5 95 44 17 26 52 69 12 74 79 96 50 92 70 38 9 2 61 6 37 91 29 46 36 14 85 30 66 53 60 8 7 49 77 75 27 15 73 84 1 31 58 45 65 3 41 93 42 51 83 54 21 33 47 28 90 87 78 48 68 16 22 25 56 55 4 89 40 20 81 80 19 10 63 94 62 35 13 76 82 18 43 57\n","truncated":false}}
%---
%[output:78fd5c5a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR19_RUN03.xlsx\n","truncated":false}}
%---
%[output:467596a2]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [35 65] at positions [34 76]\n","truncated":false}}
%---
%[output:93db2692]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 4 7 12 14 18 20 21 22 32 33 36 41 47 48 53 55 56 61 66 71 73 75 81 88 91 92 93 94 96 98\n","truncated":false}}
%---
%[output:170808b7]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 16 51 36 72 33 46 2 94 18 15 30 26 80 54 92 1 77 82 42 63 6 43 84 67 68 17 39 28 53 66 12 4 58 19 87 96 50 62 44 38 8 41 25 81 21 69 23 10 22 52 95 7 74 89 83 64 14 88 75 48 90 34 73 55 24 40 49 61 78 65 5 9 85 59 11 20 31 93 27 47 79 29 13 57 91 3 71 45 60 76 56 35 32 70 86 37\n","truncated":false}}
%---
%[output:873f4419]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 55 37 66 73 88 5 54 6 90 50 96 20 85 72 47 42 64 65 27 28 13 22 56 26 38 93 45 16 48 17 75 15 67 52 60 74 94 95 69 32 24 57 29 68 80 8 3 31 91 4 1 82 21 43 30 2 35 76 34 36 14 70 63 83 59 10 62 49 44 89 81 40 61 84 19 87 33 23 58 77 92 71 41 12 79 25 7 18 39 78 53 11 51 46 86 9\n","truncated":false}}
%---
%[output:375cdb36]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR19_RUN04.xlsx\n","truncated":false}}
%---
%[output:88b600dd]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 80 76 87 66 11 33 55 36 47 73 37 94 26 30 9 22 61 58 71 59 19 69 20 85 6 10 70 89 42 25 46 16 50 5 88 52 95 90 41 62 60 29 23 39 31 2 56 43 91 17 67 3 92 53 75 32 81 77 79 40 12 48 34 65 54 83 8 74 15 14 21 57 13 45 84 82 7 27 51 44 78 18 38 64 68 49 86 35 4 93 72 96 28 1 63 24\n","truncated":false}}
%---
%[output:009b6121]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 89 75 70 55 14 42 81 30 39 48 74 94 52 38 22 95 33 2 82 3 54 77 19 61 59 32 8 9 80 13 31 17 71 34 64 92 86 62 41 60 88 15 72 21 84 76 36 37 16 51 27 10 20 28 49 79 11 47 23 67 90 85 43 69 50 1 96 24 44 83 78 68 35 7 6 65 91 58 53 40 26 46 66 12 63 87 18 56 25 73 57 5 29 4 93 45\n","truncated":false}}
%---
%[output:16283a74]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 7 11 12 17 20 23 25 31 34 35 37 39 40 41 46 49 53 66 70 74 77 78 80 85 87 88 89 90 91 93 94 97\n","truncated":false}}
%---
%[output:1bc17f05]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 58 77 13 52 12 16 22 40 79 74 24 87 37 85 29 75 84 71 48 61 59 81 86 5 90 49 20 1 69 51 36 27 63 3 38 15 44 45 14 30 17 41 55 35 73 94 54 31 91 33 21 67 32 2 89 95 26 23 64 65 50 57 92 68 10 78 76 34 93 4 11 56 8 62 43 46 88 6 28 66 53 83 42 18 9 72 7 47 60 80 82 70 25 96 19 39\n","truncated":false}}
%---
%[output:58872da8]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR19_RUN05.xlsx\n","truncated":false}}
%---
%[output:1c1391c1]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [54 20] at positions [16 65]\n","truncated":false}}
%---
%[output:0dd5ccf0]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 94 of 96\n\t\tFound solution after 4 attempt(s): 12 63 86 77 60 39 57 25 48 88 13 69 7 16 81 54 68 95 31 82 87 41 26 67 71 19 23 64 15 38 37 78 34 11 20 1 30 80 33 51 52 43 85 62 22 59 61 10 2 56 89 29 46 45 65 3 93 47 32 90 73 17 14 42 9 79 66 96 83 5 53 74 50 18 27 36 75 49 92 8 44 84 58 6 24 70 4 94 76 21 91 40 28 55 72 35\n","truncated":false}}
%---
%[output:8dfc0eae]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 75 28 10 31 20 94 86 64 5 72 53 19 38 68 46 18 69 4 56 74 67 85 70 13 12 89 1 45 34 6 76 93 27 54 82 35 62 33 95 55 50 92 71 42 58 30 48 14 59 65 49 8 32 84 2 41 78 21 79 73 39 87 23 22 60 40 37 24 7 81 83 43 96 66 63 61 3 9 80 16 17 15 44 51 47 11 91 25 57 88 52 77 26 36 29 90\n","truncated":false}}
%---
%[output:28daf2ba]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 47 78 13 23 6 57 2 65 43 4 95 74 69 25 70 86 58 37 54 71 60 84 31 41 81 42 30 91 93 12 44 45 62 32 29 49 59 51 15 3 11 80 7 82 40 27 28 38 8 20 63 90 61 39 73 50 17 85 75 77 33 35 88 21 76 18 5 36 68 92 16 53 79 48 96 87 64 14 34 24 94 67 56 89 10 26 55 22 46 9 52 66 83 19 1 72\n","truncated":false}}
%---
%[output:92fb7570]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR19_RUN06.xlsx\n","truncated":false}}
%---
%[output:48a91e02]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 9 12 13 14 16 17 18 21 34 35 38 39 44 49 52 53 54 56 61 62 65 72 73 75 78 85 87 91 95 96\n","truncated":false}}
%---
%[output:68c79f00]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 25 32 49 36 69 94 51 4 88 35 62 79 16 18 48 24 91 86 28 2 63 93 5 13 46 14 78 27 75 68 54 17 81 65 33 34 89 9 20 1 96 64 55 50 40 10 41 82 76 52 90 43 26 23 45 77 7 74 22 66 95 87 31 58 12 11 56 73 39 57 30 47 44 8 21 61 6 59 80 71 84 70 29 85 60 92 37 67 38 83 3 72 53 42 19 15\n","truncated":false}}
%---
%[output:883f9d7d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [85 54] at positions [23 50]\n","truncated":false}}
%---
%[output:5ba5258a]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 90 27 72 32 46 77 63 69 94 58 4 16 48 42 2 65 5 54 36 92 71 70 33 50 61 81 7 23 87 86 41 26 24 62 17 11 91 38 22 53 64 30 93 85 6 60 1 96 74 39 47 56 75 3 18 13 12 78 25 29 34 82 20 68 73 55 83 51 37 67 88 59 10 35 8 79 52 95 31 89 76 15 45 84 40 57 44 14 21 49 80 19 66 43 28 9\n","truncated":false}}
%---
%[output:99905ec6]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR19_RUN07.xlsx\n","truncated":false}}
%---
%[output:14f4fe8d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tFound solution after 5 attempt(s): 2 41 15 90 62 64 42 74 6 53 27 4 5 32 26 52 13 72 86 23 70 19 83 94 33 59 96 79 38 40 82 16 28 44 18 46 20 67 51 77 69 88 80 39 1 85 47 37 57 31 10 14 68 12 35 84 30 91 49 8 58 66 63 81 93 3 45 73 25 56 48 24 21 55 54 9 60 71 65 17 76 36 50 34 7 95 29 92 43 89 61 22 11 75 87 78\n","truncated":false}}
%---
%[output:36ef4e03]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 9 10 12 13 19 22 23 25 28 29 30 32 33 35 38 53 57 58 59 60 61 73 74 79 82 89 90 91 93 94 97\n","truncated":false}}
%---
%[output:2dcf86e5]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 48 89 96 8 16 50 24 81 38 67 92 60 85 20 27 69 11 33 36 28 51 47 13 66 26 34 64 3 88 79 75 56 70 44 22 2 18 65 30 19 55 53 74 90 39 87 91 14 80 12 15 58 54 21 93 63 82 68 49 40 45 76 42 52 6 41 7 17 4 84 25 35 77 72 95 23 94 46 57 31 78 29 37 9 61 5 86 73 10 43 83 1 32 59 71 62\n","truncated":false}}
%---
%[output:36dad286]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 41 12 52 86 45 66 17 78 39 25 16 36 91 58 71 85 74 10 3 65 63 18 26 87 27 33 51 9 92 95 2 30 60 46 42 13 7 64 57 56 44 88 80 70 19 82 34 40 20 1 28 49 77 76 81 29 43 69 5 35 59 31 68 55 94 53 15 83 14 72 38 67 21 23 8 48 24 90 89 6 62 75 4 79 84 37 61 11 22 47 96 50 93 73 54 32\n","truncated":false}}
%---
%[output:00154d00]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR19_RUN08.xlsx\n","truncated":false}}
%---
%[output:7c4d5ac9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [16 81] at positions [20 66]\n","truncated":false}}
%---
%[output:25fd4f59]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 49 87 63 32 79 1 71 31 20 57 78 94 29 46 93 38 22 95 4 81 67 60 11 44 16 54 36 73 72 42 34 50 52 28 3 12 30 21 88 90 70 40 17 45 96 84 15 89 25 14 75 59 56 35 39 80 91 33 61 5 8 64 82 51 76 19 66 10 37 9 27 62 86 48 2 26 65 68 23 41 92 55 18 53 6 83 74 58 47 24 85 13 43 69 7 77\n","truncated":false}}
%---
%[output:1ee70266]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 9 10 11 13 15 19 21 27 29 30 32 33 36 41 47 48 52 58 61 64 65 67 70 73 77 81 82 85 88 95 97 98\n","truncated":false}}
%---
%[output:19b44d7b]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 32 58 18 45 91 71 60 11 30 77 94 41 79 68 19 92 6 67 48 9 90 95 51 37 17 27 3 49 96 26 21 52 73 16 10 47 40 63 64 39 7 78 14 42 29 46 84 76 89 31 8 28 70 24 81 56 69 62 2 82 44 33 66 75 35 55 54 83 93 12 13 53 25 1 61 74 85 15 72 23 34 88 65 4 86 38 20 59 22 80 50 87 57 43 5 36\n","truncated":false}}
%---
%[output:20524376]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 12 2 75 32 79 15 81 60 37 94 14 61 31 59 16 22 26 41 73 86 93 66 48 29 88 33 49 91 23 9 34 38 13 64 52 74 72 55 82 43 85 7 40 68 3 6 77 35 44 54 56 17 46 27 71 51 8 89 70 18 21 84 25 58 42 11 24 4 39 53 69 83 63 65 76 36 5 90 92 28 1 62 10 67 50 19 47 95 45 30 80 96 57 87 78 20\n","truncated":false}}
%---
%[output:3d4a0afa]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR20_RUN01.xlsx\n","truncated":false}}
%---
%[output:9ea0e82f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 88 8 49 73 36 31 91 30 61 33 46 7 21 19 67 10 87 77 95 90 50 84 47 60 29 2 65 57 64 5 41 76 18 48 82 39 15 12 13 38 71 66 25 44 43 28 81 62 11 54 86 69 74 3 79 34 52 55 70 58 40 93 27 1 85 4 17 68 83 89 59 26 51 37 72 92 23 32 53 78 45 63 22 94 9 80 16 96 35 6 56 14 20 75 24 42\n","truncated":false}}
%---
%[output:50821e04]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [1 26] at positions [44 65]\n","truncated":false}}
%---
%[output:424c2080]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 7 8 11 12 14 15 16 19 20 31 34 44 46 49 53 55 58 59 61 62 64 65 67 72 77 81 86 91 96 97\n","truncated":false}}
%---
%[output:049f8c96]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 70 96 30 45 95 42 32 24 71 64 21 4 72 79 43 44 1 52 13 39 59 47 74 28 82 86 54 62 90 66 2 3 81 10 20 58 68 37 67 16 14 80 27 9 35 41 7 92 40 55 6 53 75 88 85 5 25 63 61 22 38 94 76 60 34 29 31 77 78 23 84 18 65 87 49 89 11 46 73 50 48 19 12 26 36 83 56 15 51 91 33 57 69 8 93 17\n","truncated":false}}
%---
%[output:2567459d]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR20_RUN02.xlsx\n","truncated":false}}
%---
%[output:122f8a42]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 19 30 5 46 79 48 21 96 36 15 83 52 7 63 55 75 2 78 50 81 14 9 32 67 20 34 88 92 18 51 39 38 57 29 26 82 76 87 56 70 68 71 42 85 94 35 16 3 23 73 12 74 22 10 60 59 33 27 49 6 91 24 47 44 64 93 69 84 13 40 80 58 31 53 25 89 66 17 1 28 65 90 4 86 61 77 45 72 54 11 62 43 8 41 95 37\n","truncated":false}}
%---
%[output:1a4fc085]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 63 69 6 78 20 55 3 81 21 16 41 18 75 59 42 93 8 57 64 88 70 73 84 82 34 14 22 32 85 60 31 36 33 49 28 61 77 44 79 83 95 62 54 11 12 90 29 35 56 91 13 23 94 80 5 50 47 27 1 68 65 58 72 26 25 66 43 9 38 76 86 37 89 19 10 7 67 39 45 92 4 51 87 71 53 17 40 15 30 96 48 24 74 2 46 52\n","truncated":false}}
%---
%[output:458a683a]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 47 64 41 84 9 78 65 16 29 75 22 40 80 85 79 48 31 54 61 7 53 95 89 26 82 58 20 1 39 34 14 90 43 11 13 19 28 37 93 5 76 62 77 86 56 12 81 36 67 72 38 32 25 88 21 70 52 68 27 59 51 87 94 69 6 60 17 2 46 45 50 44 49 23 4 10 71 15 57 96 66 30 91 3 92 63 33 74 35 83 24 42 18 73 55 8\n","truncated":false}}
%---
%[output:26031d6f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 5 6 7 12 22 23 26 31 33 34 36 37 41 45 47 50 51 54 55 56 60 65 74 76 84 85 86 91 92 96 98\n","truncated":false}}
%---
%[output:4215b171]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR20_RUN03.xlsx\n","truncated":false}}
%---
%[output:8347c93f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [60 80] at positions [4 55]\n","truncated":false}}
%---
%[output:4acff999]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 94 of 96\n\t\tFound solution after 4 attempt(s): 89 96 31 77 37 40 78 67 61 26 12 32 48 95 14 72 29 25 92 42 6 45 24 54 82 65 83 53 59 69 1 84 74 86 34 58 16 11 55 46 5 18 85 21 9 36 79 3 93 63 73 68 43 88 7 4 76 64 27 22 39 60 50 47 30 49 13 51 90 87 44 35 20 75 23 71 52 2 91 56 38 57 19 15 33 70 41 94 17 81 8 28 62 66 10 80\n","truncated":false}}
%---
%[output:0228c55e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 19 53 79 45 7 72 85 5 17 6 91 66 15 13 40 43 28 75 65 31 42 70 50 35 82 24 93 56 11 59 89 92 46 62 22 20 57 52 30 48 49 71 8 88 44 68 23 90 27 29 80 84 60 37 10 73 76 51 14 58 87 1 16 18 9 38 33 94 78 36 25 81 86 39 96 3 55 63 34 2 41 61 77 32 74 64 95 21 47 67 4 69 83 54 12 26\n","truncated":false}}
%---
%[output:3ce53fc9]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 15 10 47 65 89 29 1 62 42 93 2 20 77 30 96 52 68 4 83 46 39 3 69 63 87 74 70 48 54 17 34 32 27 51 59 6 80 14 9 57 72 21 56 26 8 37 66 82 90 50 44 85 13 95 41 16 24 92 94 19 71 40 53 58 88 78 60 5 79 73 49 75 7 25 36 23 18 61 28 12 86 67 43 33 64 11 38 76 91 45 31 35 81 22 84 55\n","truncated":false}}
%---
%[output:686eeb1b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR20_RUN04.xlsx\n","truncated":false}}
%---
%[output:62b52d5f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 6 9 12 15 18 23 24 26 29 32 36 37 40 45 52 54 56 60 62 64 69 73 76 79 82 83 91 93 95 98\n","truncated":false}}
%---
%[output:539c5e83]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 60 24 59 51 69 87 72 37 92 18 67 22 5 61 48 75 74 15 21 38 30 26 89 94 36 46 49 81 64 4 10 78 57 25 33 3 95 2 34 42 20 88 23 54 85 79 28 9 7 43 80 40 90 45 56 73 6 70 96 11 31 19 71 55 13 86 62 63 35 8 52 12 39 77 68 41 17 84 93 1 82 58 47 53 29 50 83 66 32 14 65 16 27 76 91 44\n","truncated":false}}
%---
%[output:71a1937f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [28 48] at positions [46 55]\n","truncated":false}}
%---
%[output:6fb5fe06]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 77 56 45 90 23 28 74 13 19 42 12 88 58 66 65 22 87 34 59 3 33 31 14 57 26 62 53 81 91 2 68 39 37 72 85 78 63 73 83 79 30 93 60 41 38 32 54 17 48 52 7 10 6 89 4 71 47 80 9 29 1 35 5 49 50 84 94 24 70 67 18 21 16 92 43 95 75 64 11 27 82 51 20 76 8 40 25 61 96 15 69 44 55 46 86 36\n","truncated":false}}
%---
%[output:436ba8da]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR20_RUN05.xlsx\n","truncated":false}}
%---
%[output:87b404fd]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 60 50 26 90 5 95 79 82 30 58 75 45 38 63 42 88 39 18 7 3 62 96 49 12 32 77 78 8 41 67 55 28 22 44 13 74 19 86 87 15 56 53 33 24 64 68 21 2 89 85 20 35 57 6 69 54 91 61 72 37 4 46 94 34 65 70 9 27 23 73 92 71 17 10 11 29 52 16 80 83 36 40 59 84 1 43 81 51 31 76 14 93 25 48 66 47\n","truncated":false}}
%---
%[output:471b263b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 6 7 11 15 16 17 24 29 30 33 39 45 46 47 50 51 54 55 59 71 72 74 81 82 83 84 85 87 92 95\n","truncated":false}}
%---
%[output:77ec8ac0]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 10 11 85 17 20 94 48 88 96 4 63 8 44 27 70 71 21 41 80 50 76 35 55 91 77 6 28 14 73 81 52 37 13 87 84 58 61 18 59 83 40 45 23 47 89 19 1 65 2 43 60 66 93 16 12 56 38 36 15 31 68 24 92 78 34 79 67 57 25 30 49 54 9 86 3 33 72 62 42 53 69 7 22 75 90 26 51 5 64 82 39 32 46 95 74 29\n","truncated":false}}
%---
%[output:78caa61f]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 55 26 85 7 90 74 37 52 77 87 42 81 57 8 17 56 64 89 25 3 48 66 12 79 78 28 71 49 39 35 16 62 36 22 21 41 53 76 72 59 11 13 4 73 44 2 43 91 82 69 92 86 24 47 27 14 23 96 34 68 20 65 9 95 15 63 50 30 60 93 54 80 83 19 29 84 40 33 61 10 38 94 6 88 51 45 32 1 18 75 58 31 46 70 5 67\n","truncated":false}}
%---
%[output:66869f61]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR20_RUN06.xlsx\n","truncated":false}}
%---
%[output:74c3705e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [54 70] at positions [13 88]\n","truncated":false}}
%---
%[output:0b033176]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 26 40 95 72 54 78 91 55 4 75 46 68 79 3 22 56 39 35 57 18 5 10 45 7 94 16 52 89 88 23 80 30 27 93 37 21 1 32 85 84 66 15 34 44 12 92 24 59 58 8 74 53 33 73 31 76 90 42 49 51 17 48 29 25 63 70 67 43 83 13 62 87 50 14 11 86 61 82 69 19 96 9 20 6 38 60 41 65 2 71 64 77 81 36 28 47\n","truncated":false}}
%---
%[output:611b505a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 5 8 14 15 16 17 19 20 23 26 32 34 41 45 49 50 51 54 56 58 63 65 66 72 73 77 89 91 92 95 98\n","truncated":false}}
%---
%[output:469baac7]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 73 67 9 28 86 5 79 38 72 95 36 27 34 46 64 75 55 53 10 96 70 21 63 45 85 23 4 33 15 2 56 88 81 49 30 68 74 51 12 17 20 31 8 43 14 7 77 26 57 78 89 35 50 18 83 80 44 93 54 48 71 6 91 92 24 39 25 66 94 16 52 90 76 1 65 47 42 69 29 13 82 40 58 60 37 32 41 3 19 61 11 62 22 87 59 84\n","truncated":false}}
%---
%[output:52fa9729]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR20_RUN07.xlsx\n","truncated":false}}
%---
%[output:5a4537d3]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 43 36 94 51 46 75 86 42 8 15 56 20 40 62 3 81 65 29 30 63 72 4 34 21 7 76 47 77 69 55 54 91 92 16 22 88 18 74 80 44 26 17 93 35 49 96 50 23 13 39 83 9 24 41 48 5 82 66 64 78 10 58 1 67 84 87 31 61 33 79 25 73 52 59 19 57 85 71 12 2 90 6 60 68 89 27 95 37 28 70 32 38 53 14 45 11\n","truncated":false}}
%---
%[output:68ed0d31]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 93 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tFound solution after 5 attempt(s): 2 91 86 22 4 68 69 63 77 85 66 26 24 54 49 16 64 39 82 53 18 93 33 27 73 35 76 9 25 38 14 1 43 36 50 92 12 31 88 40 81 62 10 46 55 47 79 19 37 20 52 75 48 7 3 78 96 90 13 84 80 72 57 58 83 29 8 60 17 32 67 6 59 44 34 95 30 11 94 74 89 56 23 42 71 45 61 87 5 28 70 21 51 65 15 41\n","truncated":false}}
%---
%[output:2b343092]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [74 20] at positions [35 92]\n","truncated":false}}
%---
%[output:4a623892]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 84 6 47 42 71 64 32 87 55 94 27 22 52 34 54 4 15 26 45 20 1 76 65 37 3 91 46 90 92 67 19 69 83 13 57 60 79 8 39 14 16 95 58 21 74 78 38 68 7 49 73 56 10 75 23 36 40 88 41 30 9 17 53 48 50 63 81 31 28 96 93 80 86 5 24 72 33 12 89 61 77 11 44 85 29 35 25 62 43 70 51 82 66 18 2 59\n","truncated":false}}
%---
%[output:2db8f485]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR20_RUN08.xlsx\n","truncated":false}}
%---
%[output:80324074]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 9 10 12 16 18 19 20 26 34 35 41 42 44 47 52 54 55 58 65 70 72 76 77 79 81 86 90 95 97 98\n","truncated":false}}
%---
%[output:7acb9bb5]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 73 64 76 16 68 91 39 18 25 1 41 66 38 7 5 30 42 92 61 49 9 53 31 58 88 21 86 6 83 95 67 26 69 65 46 55 47 33 81 3 62 84 40 35 2 45 32 89 50 51 75 22 4 15 96 72 94 17 23 70 12 74 78 54 13 28 60 20 36 52 48 77 11 29 8 34 90 82 56 37 71 93 27 44 19 87 43 14 57 24 59 85 10 80 63 79\n","truncated":false}}
%---
%[output:944573db]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 94 of 96\n\t\tFound solution after 3 attempt(s): 29 10 20 43 88 32 94 49 56 75 62 22 53 16 92 6 11 39 1 66 48 73 7 54 84 33 41 63 38 18 76 17 21 80 68 96 83 71 45 60 69 72 57 59 5 65 4 37 26 3 19 55 27 34 89 81 50 36 44 12 86 77 31 30 93 9 2 51 95 47 78 85 23 70 42 67 87 28 8 82 15 79 24 61 74 52 40 14 35 90 58 25 91 46 64 13\n","truncated":false}}
%---
%[output:4f3ac1cb]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 82 77 60 95 87 9 12 20 80 37 13 64 68 22 16 74 75 7 46 52 43 86 54 56 26 85 23 48 36 25 27 57 11 93 34 66 92 78 89 21 47 14 31 61 39 30 70 58 76 65 10 53 50 90 44 42 83 81 49 32 18 1 79 40 55 4 88 6 35 73 28 84 5 15 33 29 51 2 19 94 17 45 71 3 63 38 91 62 96 72 24 67 59 69 41 8\n","truncated":false}}
%---
%[output:9d615d7f]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 5 20 58 71 18 76 38 31 93 40 79 61 84 1 64 17 45 53 36 9 77 13 39 96 65 78 87 22 21 12 10 95 51 50 15 4 47 34 62 3 24 80 90 91 68 46 19 60 81 35 86 56 26 85 83 29 7 52 43 8 92 14 66 6 67 25 27 42 74 57 69 75 88 32 2 55 63 48 41 82 16 89 72 28 59 70 33 30 94 37 73 49 11 23 44 54\n","truncated":false}}
%---
%[output:8286d44d]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR21_RUN01.xlsx\n","truncated":false}}
%---
%[output:86307870]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 7 8 9 12 13 17 20 21 26 28 30 36 37 45 48 49 57 59 60 62 66 68 70 78 79 84 87 88 90 94 95 96\n","truncated":false}}
%---
%[output:86b1e115]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [28 42] at positions [35 71]\n","truncated":false}}
%---
%[output:1593b43a]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 43 35 63 53 84 52 78 62 29 9 65 69 25 36 79 38 17 55 34 92 16 1 42 14 54 4 83 40 27 90 74 93 26 77 10 30 23 71 2 58 33 95 94 15 88 50 31 6 19 46 13 12 75 89 32 28 96 37 49 64 5 48 73 66 47 39 8 91 76 60 85 81 24 59 67 18 87 51 70 45 72 20 80 86 44 82 7 22 56 41 57 11 61 21 3 68\n","truncated":false}}
%---
%[output:8a96c490]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 69 60 66 1 22 6 72 28 86 62 24 59 33 81 67 71 88 83 44 51 61 92 20 21 35 74 45 15 38 48 18 70 12 52 11 84 10 16 57 19 82 41 75 36 50 87 85 63 39 32 29 40 4 30 3 37 34 93 31 58 9 95 2 8 68 89 65 53 73 80 27 76 14 25 90 7 55 64 78 54 91 43 13 79 17 42 96 49 46 77 47 26 5 94 23 56\n","truncated":false}}
%---
%[output:830c13fd]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR21_RUN02.xlsx\n","truncated":false}}
%---
%[output:7554bd72]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 20 1 74 11 58 66 96 21 33 43 52 35 10 36 88 16 90 53 55 84 87 47 23 62 4 30 80 26 86 75 70 64 24 25 2 13 72 37 71 69 54 49 78 85 34 92 5 59 81 68 45 41 3 22 18 44 73 15 40 50 42 27 89 83 29 77 32 63 12 95 51 28 7 9 46 67 17 39 61 31 82 19 76 48 14 91 57 8 56 79 60 94 6 65 93 38\n","truncated":false}}
%---
%[output:17d198b2]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 6 7 22 25 26 31 32 34 35 39 41 43 47 48 54 60 61 63 69 72 75 78 80 86 87 91 92 94 96 97\n","truncated":false}}
%---
%[output:6d7b7192]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 56 66 25 15 64 32 61 55 46 80 96 1 65 76 49 2 42 93 53 90 44 33 60 88 70 4 6 20 35 30 78 43 13 82 94 21 19 91 3 75 18 69 81 40 17 62 39 86 23 14 9 83 73 54 67 12 57 50 11 29 28 85 87 63 24 47 59 31 92 22 16 36 72 71 48 34 7 41 26 58 10 89 68 84 38 95 51 74 37 77 52 45 8 79 5 27\n","truncated":false}}
%---
%[output:11304965]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [42 31] at positions [47 87]\n","truncated":false}}
%---
%[output:5a206186]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR21_RUN03.xlsx\n","truncated":false}}
%---
%[output:1aa21c53]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 82 59 9 46 55 45 31 53 62 22 38 42 66 90 84 21 74 12 95 6 52 88 44 94 80 37 16 77 24 32 87 15 25 10 3 20 19 68 71 54 69 14 81 47 23 35 33 72 89 86 75 26 4 48 96 56 49 17 50 36 51 7 57 85 29 91 27 60 79 39 13 65 73 64 11 1 30 40 5 93 61 43 76 34 58 83 2 67 28 8 63 70 92 41 18 78\n","truncated":false}}
%---
%[output:44deb5ab]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 43 95 61 26 60 54 37 23 44 45 50 75 18 7 25 82 39 12 65 62 91 87 74 38 70 78 85 14 83 27 66 1 48 84 79 24 21 22 57 2 4 51 15 80 13 32 34 55 52 20 71 92 58 81 36 28 93 3 89 31 10 59 77 42 5 9 33 67 64 46 40 19 94 88 76 73 35 68 29 72 53 6 49 86 16 69 8 17 11 90 41 56 30 63 47 96\n","truncated":false}}
%---
%[output:9230bcac]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 9 12 17 21 22 23 33 35 36 37 39 40 42 47 49 51 56 58 65 66 68 71 74 75 79 80 82 84 89 95 97\n","truncated":false}}
%---
%[output:39eda95b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 94 of 96\n\t\tFound solution after 2 attempt(s): 76 92 72 61 63 11 34 36 32 44 66 37 57 41 88 18 71 23 55 31 95 60 89 1 73 5 22 20 3 84 46 8 53 75 69 39 79 64 28 24 7 4 58 45 21 74 16 2 91 86 78 87 12 17 56 85 47 93 96 52 54 70 68 25 40 15 65 49 6 48 33 59 42 81 29 94 9 35 80 90 51 14 27 10 77 38 13 83 26 67 19 82 43 50 30 62\n","truncated":false}}
%---
%[output:0a45e9bb]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR21_RUN04.xlsx\n","truncated":false}}
%---
%[output:9a39aa75]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 49 24 53 66 45 33 18 77 59 63 90 31 23 88 61 2 36 74 25 41 8 76 73 93 92 43 87 10 95 72 6 29 13 7 62 48 57 3 82 39 52 70 17 60 34 1 65 15 19 16 11 46 86 32 96 58 55 21 27 47 26 78 56 81 89 14 50 80 75 44 40 79 94 71 9 30 35 69 85 22 91 12 37 28 64 42 4 83 54 20 5 67 38 84 68 51\n","truncated":false}}
%---
%[output:07d287f0]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [62 30] at positions [10 83]\n","truncated":false}}
%---
%[output:84735522]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 2 80 5 14 51 95 60 9 37 65 86 68 53 54 32 69 78 26 96 20 30 8 28 44 11 82 89 16 15 58 73 33 22 56 34 94 40 49 13 18 67 75 41 39 90 76 21 43 29 81 92 3 77 83 36 12 91 27 19 6 35 47 74 62 85 64 23 52 57 45 63 66 4 25 79 55 48 61 84 31 93 7 59 1 88 38 70 10 42 17 46 87 72 24 50 71\n","truncated":false}}
%---
%[output:661fab50]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 10 11 16 17 18 21 22 23 25 29 33 39 41 46 48 49 50 55 57 58 62 65 66 69 72 75 82 83 84 89 92 94\n","truncated":false}}
%---
%[output:69d97b36]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR21_RUN05.xlsx\n","truncated":false}}
%---
%[output:2f323f95]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 32 58 50 74 43 4 71 82 9 16 57 28 18 95 75 54 48 25 6 92 87 51 96 22 36 84 47 72 69 31 76 2 42 59 14 26 67 70 49 46 38 35 81 21 7 20 93 66 89 63 80 19 55 17 40 5 60 85 10 44 27 24 88 91 33 53 1 3 78 12 90 77 34 65 86 39 73 8 56 62 41 13 23 52 83 64 68 61 11 94 29 15 37 30 79 45\n","truncated":false}}
%---
%[output:081f663c]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 90 3 51 86 42 73 61 36 59 76 13 37 5 23 19 78 20 54 6 16 88 24 91 95 71 83 55 31 33 47 18 7 77 38 81 40 9 8 57 52 65 66 29 4 79 58 43 45 22 17 84 72 69 87 62 63 92 28 46 89 10 39 64 11 85 94 41 70 48 49 27 80 14 25 60 34 21 12 50 1 93 2 68 82 75 30 44 96 26 67 56 32 53 74 15 35\n","truncated":false}}
%---
%[output:96befcc3]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 40 46 64 3 51 84 77 47 22 63 52 27 68 31 12 92 28 93 91 37 73 82 2 79 9 29 24 34 88 60 39 15 1 36 67 78 57 76 65 55 48 96 62 83 25 41 23 90 43 44 8 19 11 94 75 42 56 66 26 17 70 14 38 95 4 74 89 81 61 7 6 54 18 53 59 45 10 69 21 85 80 5 20 35 72 49 32 16 50 71 86 33 58 13 87 30\n","truncated":false}}
%---
%[output:6ac3ee48]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [37 92] at positions [41 54]\n","truncated":false}}
%---
%[output:65c92301]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR21_RUN06.xlsx\n","truncated":false}}
%---
%[output:31b85630]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 6 11 13 16 19 20 25 27 29 30 36 40 41 44 52 54 57 62 64 65 68 70 76 78 79 90 93 94 95 96\n","truncated":false}}
%---
%[output:99f54f84]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 51 75 28 7 42 72 55 52 38 26 65 90 15 5 76 74 36 82 62 9 94 34 16 32 23 95 21 35 43 50 25 58 87 93 71 2 59 13 1 88 53 45 41 84 14 17 81 78 64 61 86 46 12 77 20 39 31 24 68 69 4 60 22 49 67 92 85 27 6 37 57 83 73 33 79 56 80 48 10 29 44 70 3 91 8 66 96 40 89 30 11 54 19 63 47 18\n","truncated":false}}
%---
%[output:06ced321]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 36 94 30 57 19 87 35 56 50 91 5 75 32 15 95 74 71 54 73 38 42 2 8 60 4 37 17 43 79 10 20 18 69 96 93 62 41 24 16 14 52 89 3 66 78 11 84 33 7 48 80 22 29 47 58 67 53 45 34 81 63 64 26 68 83 92 25 85 76 46 77 59 6 23 55 12 88 70 40 27 51 39 49 82 44 1 21 13 65 31 86 9 61 28 72 90\n","truncated":false}}
%---
%[output:8b9e6e85]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 12 62 74 56 41 70 2 67 83 61 85 48 88 18 96 93 77 35 45 13 20 16 46 52 49 1 6 82 14 31 17 50 24 44 32 79 29 66 65 36 25 81 21 51 68 54 87 91 5 4 37 86 57 60 7 69 89 80 11 59 33 34 10 90 39 64 30 8 53 42 76 26 22 40 95 73 78 63 92 55 9 23 72 94 28 84 15 43 58 19 3 71 27 47 75 38\n","truncated":false}}
%---
%[output:95d26b92]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR21_RUN07.xlsx\n","truncated":false}}
%---
%[output:0c325270]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 93 of 96\n\t\tFound solution after 2 attempt(s): 68 84 79 75 56 62 20 15 9 61 5 66 8 28 70 34 63 85 25 82 42 71 26 51 76 72 49 47 14 46 38 27 18 35 89 10 87 57 37 30 17 77 32 6 43 1 52 11 3 24 45 58 60 86 81 54 73 95 21 90 33 65 48 92 13 88 93 78 4 67 2 36 41 96 29 55 31 59 7 64 39 23 40 53 22 74 19 94 50 69 91 12 80 44 16 83\n","truncated":false}}
%---
%[output:8d6e0797]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 11 14 17 19 24 26 27 29 31 32 35 41 43 45 46 50 51 54 59 60 69 70 72 77 78 87 88 89 92 94 95\n","truncated":false}}
%---
%[output:9c3b7e71]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [21 57] at positions [23 53]\n","truncated":false}}
%---
%[output:259daf64]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 89 46 82 27 95 61 14 86 9 23 15 64 59 83 91 76 90 39 79 36 26 55 69 1 66 51 17 45 13 35 57 34 42 88 60 65 78 25 21 67 68 11 8 40 38 32 37 73 87 22 49 31 2 3 52 94 75 18 28 84 96 4 80 62 47 5 20 72 41 50 6 81 77 7 48 53 63 12 71 43 16 29 70 58 92 33 74 19 93 24 10 85 56 30 54 44\n","truncated":false}}
%---
%[output:56dda654]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR21_RUN08.xlsx\n","truncated":false}}
%---
%[output:6bca1872]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 58 32 87 65 4 26 42 61 33 20 5 9 46 73 18 30 72 94 3 66 36 84 91 22 63 89 49 10 64 60 75 80 50 23 78 2 82 38 47 13 81 92 79 48 25 96 44 74 51 68 67 83 19 17 37 53 45 86 12 16 71 31 62 88 56 55 8 24 14 41 34 7 52 90 59 35 85 1 40 6 69 43 21 70 28 54 29 95 76 57 11 27 15 93 39 77\n","truncated":false}}
%---
%[output:0602738a]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 37 25 50 81 79 77 54 45 95 83 3 8 47 66 18 94 23 40 59 52 2 91 42 15 55 74 84 64 24 29 65 10 72 46 36 56 6 28 4 19 14 92 1 16 39 78 61 27 75 9 60 67 96 69 32 93 48 30 53 82 88 26 20 33 89 63 62 35 38 5 80 44 7 51 71 76 87 21 12 73 43 90 70 17 68 11 85 13 34 49 86 57 41 22 58 31\n","truncated":false}}
%---
%[output:79aa39f0]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 8 9 14 15 25 26 28 32 36 37 38 39 43 45 48 51 52 54 62 65 67 68 73 74 79 80 88 89 90 92 93\n","truncated":false}}
%---
%[output:4648b4b5]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 29 91 78 16 18 55 19 24 15 96 52 79 70 39 1 43 21 65 20 37 82 88 6 57 47 48 77 59 4 2 66 85 17 13 34 53 50 92 44 51 72 75 11 90 69 40 74 95 62 25 38 42 31 83 3 54 81 23 73 30 22 49 41 9 10 68 58 60 12 27 67 63 71 86 87 35 94 33 84 26 56 36 8 64 7 76 45 32 93 80 14 46 61 89 5 28\n","truncated":false}}
%---
%[output:861eceeb]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [37 7] at positions [21 79]\n","truncated":false}}
%---
%[output:384bb0e6]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR22_RUN01.xlsx\n","truncated":false}}
%---
%[output:6d0016a3]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 6 69 44 79 20 12 10 42 35 50 64 13 18 43 24 88 48 82 61 85 1 51 71 96 25 52 23 30 68 60 40 3 83 67 9 72 76 59 84 86 33 29 56 78 34 37 74 15 16 31 90 92 11 47 14 94 66 22 77 80 93 28 5 54 2 39 87 55 49 27 36 53 45 58 73 57 41 95 32 21 8 63 26 65 17 81 38 4 91 70 46 75 89 7 19 62\n","truncated":false}}
%---
%[output:7b673f0a]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 77 69 32 37 75 14 12 80 85 73 60 23 20 86 41 22 59 57 3 33 58 90 54 47 9 51 72 46 83 25 15 27 78 91 5 81 87 6 93 40 38 45 8 28 74 13 36 61 56 1 62 92 64 68 18 82 89 79 53 43 71 34 17 42 84 30 63 19 4 67 70 44 50 26 29 35 31 88 16 11 96 49 66 2 48 65 55 10 24 76 95 39 94 21 7 52\n","truncated":false}}
%---
%[output:7b86dff2]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 21 79 37 80 76 87 91 19 92 70 64 33 86 45 46 6 69 32 57 90 59 2 88 8 28 42 58 55 20 27 3 13 34 29 89 50 78 15 53 39 73 9 77 23 14 5 63 18 68 94 67 62 75 48 22 54 84 93 16 85 25 36 81 38 49 61 1 40 12 24 26 83 74 72 30 41 47 10 96 35 82 31 7 71 11 60 17 66 95 51 43 56 4 44 65 52\n","truncated":false}}
%---
%[output:89eccf6a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 5 8 10 14 17 21 22 26 28 29 33 39 41 48 55 56 57 60 63 64 66 68 70 72 78 84 87 89 95 96\n","truncated":false}}
%---
%[output:7f653fa5]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR22_RUN02.xlsx\n","truncated":false}}
%---
%[output:84191c8d]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 36 86 73 92 12 55 88 83 40 80 78 59 17 46 14 79 37 31 63 57 71 27 76 5 8 81 62 3 38 34 58 41 75 16 24 21 90 32 13 4 72 23 30 66 42 85 28 56 87 77 65 94 61 35 44 6 82 39 25 11 53 50 15 33 64 22 43 20 95 96 2 18 74 49 70 52 45 68 1 69 29 54 19 48 84 47 10 60 7 89 51 67 93 9 26 91\n","truncated":false}}
%---
%[output:00fca7b6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [35 77] at positions [36 77]\n","truncated":false}}
%---
%[output:0f50aae4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 95 of 96\n\t\tAttempt 5 ran out of options at trial 96 of 96\n\t\tAttempt 6 ran out of options at trial 95 of 96\n\t\tAttempt 7 ran out of options at trial 96 of 96\n\t\tFound solution after 8 attempt(s): 54 92 50 55 80 12 88 17 63 26 85 13 58 35 23 40 94 33 73 95 96 65 71 37 11 42 53 3 76 27 2 15 21 78 49 91 90 32 22 24 72 9 81 61 60 8 70 57 75 93 36 38 74 46 30 10 59 19 52 43 14 25 83 77 29 48 62 69 79 34 89 6 41 44 20 1 5 51 7 66 4 39 56 82 64 31 67 86 47 68 28 84 16 18 45 87\n","truncated":false}}
%---
%[output:5f732d26]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 85 68 96 16 45 39 23 15 93 83 50 82 41 5 61 26 74 10 72 48 77 75 49 79 17 27 51 38 86 21 90 36 62 63 11 2 22 33 8 65 57 19 20 1 95 94 4 54 3 24 46 29 91 69 30 70 80 47 67 87 52 88 28 56 35 81 78 14 6 37 59 76 64 55 89 9 44 34 84 53 42 73 7 25 60 13 58 66 40 32 92 31 12 71 18 43\n","truncated":false}}
%---
%[output:4d7dfb21]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR22_RUN03.xlsx\n","truncated":false}}
%---
%[output:7d12788a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 7 8 10 11 14 23 26 27 29 30 33 44 48 49 53 55 64 67 68 71 72 75 77 83 87 89 90 91 92 93\n","truncated":false}}
%---
%[output:8a1dc187]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 65 96 26 8 31 90 48 51 4 7 88 57 92 6 71 35 37 86 75 79 5 42 2 63 68 55 19 56 38 72 18 44 25 70 76 22 28 83 89 14 45 20 78 3 61 64 39 74 46 15 1 95 59 69 52 27 62 10 66 81 40 36 82 87 23 9 30 17 33 60 84 77 21 80 41 50 58 12 49 73 91 54 34 29 13 94 47 93 32 53 24 85 11 67 16 43\n","truncated":false}}
%---
%[output:54f83e0f]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 9 67 93 33 8 32 77 65 57 56 20 25 14 48 89 5 96 55 74 19 85 30 36 45 63 43 70 2 15 64 4 29 58 86 71 34 28 66 60 73 10 79 31 22 84 91 11 1 47 76 81 21 6 94 83 35 52 59 12 54 95 68 37 90 53 44 17 62 26 40 38 3 24 61 42 23 46 88 49 18 78 72 16 75 92 39 13 50 80 41 51 7 87 69 27 82\n","truncated":false}}
%---
%[output:4c3a0619]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [44 8] at positions [5 95]\n","truncated":false}}
%---
%[output:17f42673]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR22_RUN04.xlsx\n","truncated":false}}
%---
%[output:246ff07c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 91 95 60 24 14 64 84 19 34 5 71 36 50 62 80 23 82 46 68 67 2 26 65 56 12 41 32 58 39 83 6 87 72 93 44 45 30 22 52 70 92 13 15 29 94 90 79 57 53 16 3 85 55 48 76 69 18 27 47 38 9 33 88 25 78 35 51 21 10 49 89 37 4 73 11 40 20 8 75 7 63 42 54 86 1 17 81 59 74 96 66 31 43 77 61 28\n","truncated":false}}
%---
%[output:01170a59]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 6 9 11 12 13 14 15 19 23 29 30 37 39 43 46 50 51 54 59 60 65 71 72 74 77 78 86 87 91 97 98\n","truncated":false}}
%---
%[output:72bf059e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 26 31 95 42 4 17 3 72 88 2 91 59 43 24 75 10 33 35 69 37 62 21 46 90 23 64 5 55 89 73 28 52 58 77 65 60 11 12 19 96 83 61 29 15 48 63 81 41 47 92 1 7 51 76 49 44 27 20 78 32 39 9 86 80 82 22 38 79 40 30 68 74 6 71 36 53 54 85 93 66 87 56 16 25 13 70 14 94 45 84 18 50 67 57 34 8\n","truncated":false}}
%---
%[output:2ef136f1]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 86 30 11 2 48 51 36 71 24 88 75 42 26 68 67 60 7 73 96 44 5 58 50 28 49 87 59 80 6 89 95 3 32 46 94 47 45 14 52 84 76 91 22 31 64 19 90 8 70 77 63 78 33 23 18 13 35 41 69 16 29 40 93 81 62 4 12 83 56 61 38 53 17 72 21 39 10 79 82 9 55 34 65 25 85 27 54 15 20 1 43 92 66 57 74 37\n","truncated":false}}
%---
%[output:6449af3e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR22_RUN05.xlsx\n","truncated":false}}
%---
%[output:0722ac6a]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 10 9 41 3 79 95 58 64 77 47 76 72 25 67 16 27 7 53 20 42 87 44 52 94 18 32 49 14 85 4 78 60 37 40 24 83 65 82 81 74 15 23 38 48 5 86 90 63 8 56 55 93 12 43 88 35 75 54 17 68 28 92 19 57 66 71 34 21 22 13 1 51 36 62 91 6 46 31 2 70 61 30 33 89 29 59 69 26 73 39 80 84 50 11 96 45\n","truncated":false}}
%---
%[output:729cc3b5]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 94 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tFound solution after 5 attempt(s): 57 82 29 42 31 13 34 90 81 80 8 76 19 65 48 70 87 50 15 6 83 33 1 26 59 53 17 25 89 3 55 41 58 68 54 78 74 94 95 24 14 46 47 27 45 92 37 12 23 32 72 11 71 20 93 79 69 62 30 49 16 85 51 96 2 7 63 38 75 35 39 60 61 86 22 4 56 9 43 91 64 21 67 88 44 66 28 52 77 5 18 36 10 84 73 40\n","truncated":false}}
%---
%[output:25f1bb48]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 5 6 16 17 19 20 21 22 23 26 28 35 38 39 41 50 55 60 62 66 68 69 70 71 75 80 84 90 91 95 98\n","truncated":false}}
%---
%[output:67f34b41]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [88 70] at positions [28 63]\n","truncated":false}}
%---
%[output:990a523a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR22_RUN06.xlsx\n","truncated":false}}
%---
%[output:8f946bd3]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 75 81 23 35 31 10 67 41 11 6 82 61 66 28 79 62 53 5 36 42 78 14 52 46 55 18 87 16 20 64 91 83 72 76 73 26 22 12 29 85 48 93 32 80 9 95 89 63 37 40 2 34 74 43 49 94 77 86 45 84 7 54 1 15 68 51 57 25 60 70 17 27 39 30 44 90 50 33 19 8 56 69 58 88 21 65 4 38 13 24 96 3 71 92 47 59\n","truncated":false}}
%---
%[output:7f5e8e1f]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 45 71 35 2 94 89 48 60 79 90 1 5 36 18 69 4 73 65 50 27 63 51 39 87 80 22 32 47 34 52 10 61 91 19 15 31 86 58 42 83 16 13 33 67 43 28 95 40 41 3 23 12 64 9 70 21 55 53 72 84 96 49 92 26 76 59 29 17 38 11 81 75 77 7 37 62 74 57 93 56 8 88 44 68 20 46 25 66 82 24 85 78 14 54 30 6\n","truncated":false}}
%---
%[output:3a91e388]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 28 82 83 21 79 24 60 89 9 41 66 40 3 29 30 33 39 52 18 14 76 78 59 6 61 73 7 16 85 49 58 42 93 68 84 43 19 22 11 5 91 37 71 57 23 75 46 32 54 51 80 67 94 2 72 1 56 10 26 86 31 47 12 45 48 87 53 36 50 96 74 20 15 64 4 34 92 90 77 81 27 69 35 55 88 38 25 62 65 63 44 13 17 95 8 70\n","truncated":false}}
%---
%[output:6ea46f44]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 9 11 14 15 17 20 22 29 30 32 33 34 37 42 49 53 54 61 63 65 67 72 73 76 80 82 85 88 91 97 98\n","truncated":false}}
%---
%[output:26b46ec3]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR22_RUN07.xlsx\n","truncated":false}}
%---
%[output:48c38a17]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 4 28 70 58 59 90 56 13 38 35 81 23 18 94 47 55 26 1 10 63 66 2 71 69 30 52 33 76 82 85 9 89 80 43 25 42 6 45 48 19 24 40 75 41 5 17 88 62 54 95 15 74 83 86 20 67 65 12 92 34 91 78 50 21 11 60 72 32 61 44 64 8 16 27 68 37 31 49 22 84 73 29 7 46 51 79 53 36 14 93 3 57 87 39 77 96\n","truncated":false}}
%---
%[output:1b178fa4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [76 9] at positions [16 95]\n","truncated":false}}
%---
%[output:52000d27]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 58 84 63 62 75 65 5 33 76 31 30 12 64 3 81 43 92 2 6 24 37 11 73 41 29 85 78 55 46 42 52 26 57 50 18 80 86 19 20 56 4 49 68 70 93 88 47 87 32 89 16 39 1 96 71 45 35 66 7 9 79 59 34 22 14 25 74 27 38 53 94 82 60 8 61 77 54 40 91 69 21 36 17 10 83 48 51 90 13 44 67 95 28 72 15 23\n","truncated":false}}
%---
%[output:7530f86d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 17 40 35 10 7 79 95 42 23 54 77 34 57 19 78 56 60 3 21 14 41 96 88 25 28 94 8 61 81 75 22 26 83 58 46 68 9 90 31 2 16 50 44 38 72 66 53 18 47 84 71 4 39 55 93 51 67 86 13 91 92 43 32 64 52 6 70 36 12 29 73 30 62 87 27 11 80 65 48 1 33 20 85 69 59 74 89 45 82 15 24 76 5 49 37 63\n","truncated":false}}
%---
%[output:8d0e06b6]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR22_RUN08.xlsx\n","truncated":false}}
%---
%[output:6345f846]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 6 10 12 21 22 23 25 28 29 35 36 40 44 47 49 52 54 55 57 62 64 66 67 68 74 75 79 89 94 96 98\n","truncated":false}}
%---
%[output:0ebd3723]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 37 50 75 51 91 12 58 2 78 72 30 80 82 94 25 92 56 21 36 7 11 33 45 17 61 44 69 13 20 14 81 38 83 76 43 9 4 57 49 63 35 39 77 89 23 31 5 18 71 68 1 93 55 26 96 85 42 86 10 66 59 70 24 28 53 88 79 47 52 15 34 32 41 22 90 74 95 3 40 54 73 48 84 27 62 16 60 19 6 87 64 46 65 29 67 8\n","truncated":false}}
%---
%[output:1ecc6095]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 69 48 83 43 28 64 91 32 38 1 2 27 30 12 81 11 41 72 49 54 44 40 61 68 22 67 16 78 85 65 66 86 63 19 95 88 26 56 9 62 45 36 79 51 93 37 59 20 24 39 21 8 80 29 75 10 4 25 96 77 76 34 3 33 94 82 60 74 6 92 5 55 13 35 7 57 53 84 42 73 90 50 23 15 31 52 71 17 70 46 87 18 47 58 14 89\n","truncated":false}}
%---
%[output:70d43430]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [34 63] at positions [39 92]\n","truncated":false}}
%---
%[output:513ee371]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 62 41 73 11 75 65 54 74 95 40 31 83 96 21 68 35 50 87 67 23 25 43 14 18 56 27 5 81 6 42 82 59 2 64 53 91 57 63 80 93 1 8 70 39 37 29 69 71 52 16 55 24 48 3 30 10 7 46 58 38 94 36 79 28 49 77 4 84 17 86 88 78 45 34 85 22 19 76 12 51 26 92 47 61 89 9 72 32 33 66 90 60 13 44 15 20\n","truncated":false}}
%---
%[output:591f22a5]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR23_RUN01.xlsx\n","truncated":false}}
%---
%[output:4dd05a4b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 9 11 13 16 23 24 27 29 33 36 39 40 42 43 46 51 55 59 62 64 65 66 70 71 76 79 83 87 88 92 96\n","truncated":false}}
%---
%[output:90dac9a5]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 16 48 62 19 57 43 11 63 50 76 52 6 77 87 88 39 90 71 69 44 70 21 74 12 9 26 83 30 24 34 38 18 4 85 5 49 82 59 20 17 10 86 46 47 91 78 66 94 14 29 60 36 28 92 51 67 56 3 80 7 40 1 15 81 25 73 31 42 65 35 55 89 96 72 45 64 53 13 22 58 37 8 68 84 41 32 79 23 33 75 2 54 95 61 27 93\n","truncated":false}}
%---
%[output:1b08779a]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 81 50 62 87 16 95 92 77 80 31 23 85 43 68 83 29 66 49 32 36 93 7 51 72 35 63 46 41 3 39 25 55 14 8 78 10 19 13 75 67 26 9 53 90 76 45 28 54 57 74 88 22 17 37 47 96 52 30 82 34 15 12 48 60 40 70 4 91 94 1 18 65 61 2 38 64 89 69 86 59 11 79 5 24 71 20 33 21 84 42 6 56 44 73 58 27\n","truncated":false}}
%---
%[output:04bc407c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 48 64 30 89 5 40 81 90 50 53 95 43 39 12 13 79 27 73 78 6 20 33 68 55 34 24 54 7 57 80 87 17 14 86 76 46 35 11 82 58 1 61 36 62 22 18 2 3 42 25 69 96 45 92 32 88 4 71 28 23 51 83 74 67 10 31 38 75 41 9 37 21 49 59 66 60 19 65 56 8 72 29 44 77 15 94 85 52 93 70 91 16 63 47 84 26\n","truncated":false}}
%---
%[output:874e0862]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR23_RUN02.xlsx\n","truncated":false}}
%---
%[output:6839c1de]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [20 79] at positions [11 51]\n","truncated":false}}
%---
%[output:34aae3d4]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 11 15 19 21 23 24 30 32 35 36 39 40 45 49 50 52 54 57 66 67 75 77 78 79 81 83 88 92 95 98\n","truncated":false}}
%---
%[output:21100036]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 69 79 96 82 41 68 4 77 24 33 34 55 84 6 60 25 87 75 36 94 58 11 45 19 18 50 76 53 40 14 5 21 80 61 63 30 13 85 28 8 47 52 62 81 38 65 1 16 92 12 78 29 89 73 37 35 26 54 46 10 27 32 44 95 56 67 70 86 22 74 42 20 9 57 7 49 93 88 17 90 3 31 48 59 71 91 72 51 39 15 43 83 64 2 66 23\n","truncated":false}}
%---
%[output:54f908c4]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 53 72 51 9 31 33 77 17 13 34 41 81 65 76 83 94 14 2 52 40 61 57 91 36 19 68 35 1 90 20 22 93 56 24 49 39 79 3 80 10 12 32 84 23 44 55 54 88 47 48 29 75 95 6 43 16 66 67 37 85 78 18 7 87 63 5 64 70 62 30 28 59 89 86 71 4 60 45 11 73 46 26 15 27 50 69 58 21 38 82 8 96 42 74 92 25\n","truncated":false}}
%---
%[output:2846d781]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR23_RUN03.xlsx\n","truncated":false}}
%---
%[output:5482935a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 94 37 12 6 75 3 18 34 56 31 22 86 50 93 26 62 53 77 25 67 83 84 10 85 65 73 48 45 27 16 64 46 69 59 15 38 81 42 36 87 29 68 4 1 82 79 44 32 43 14 55 91 63 61 70 74 96 95 5 23 92 20 8 39 78 17 21 60 41 49 11 80 58 28 33 7 51 30 2 71 19 66 35 76 57 9 47 24 90 54 88 40 52 72 89 13\n","truncated":false}}
%---
%[output:3402654b]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 33 70 62 38 19 65 3 10 35 53 58 1 50 20 47 41 87 91 56 73 83 75 24 13 79 66 46 15 94 5 30 23 57 95 36 17 90 31 64 80 69 52 26 7 45 74 88 29 25 48 40 85 16 84 92 51 6 8 32 77 39 11 49 86 43 59 60 34 9 76 2 78 21 89 67 63 96 61 12 27 44 82 18 54 28 71 37 55 72 22 14 42 68 93 4 81\n","truncated":false}}
%---
%[output:5960bd3b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [27 77] at positions [33 90]\n","truncated":false}}
%---
%[output:36dbc99a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 12 15 17 18 22 26 34 35 36 37 42 44 45 46 49 50 52 55 63 67 68 70 75 84 85 90 91 94 95 96 98\n","truncated":false}}
%---
%[output:5060f6e8]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR23_RUN04.xlsx\n","truncated":false}}
%---
%[output:1a83025b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tFound solution after 3 attempt(s): 8 16 67 17 50 51 69 37 1 63 19 85 95 62 47 35 55 84 75 81 23 36 89 10 40 22 21 73 54 13 92 45 74 4 29 3 77 76 82 48 11 18 31 79 60 12 90 52 24 91 83 14 56 65 71 28 43 25 15 34 39 58 46 93 80 9 2 78 38 66 94 30 49 64 96 27 70 44 59 5 41 6 61 86 42 72 26 7 88 53 33 32 87 68 57 20\n","truncated":false}}
%---
%[output:638fcab3]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 24 35 10 60 45 55 54 11 82 58 71 75 33 81 69 8 16 78 29 59 86 39 73 84 14 46 41 32 5 17 88 83 19 66 63 31 28 62 4 57 48 87 3 67 18 94 74 90 23 44 64 50 80 42 77 2 25 72 70 61 92 43 36 6 12 38 30 13 96 53 20 27 15 37 89 93 22 85 7 68 47 52 21 49 76 95 79 56 34 26 40 65 9 51 1 91\n","truncated":false}}
%---
%[output:037456ad]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 94 of 96\n\t\tFound solution after 2 attempt(s): 71 94 1 86 88 31 29 83 56 66 52 62 8 33 23 67 40 92 37 58 91 74 69 13 4 22 45 46 5 80 27 50 30 2 57 35 78 75 49 47 63 10 93 70 20 54 68 14 73 38 19 6 53 84 55 24 43 42 12 32 90 95 48 82 3 16 36 79 89 21 28 65 81 64 59 26 15 18 41 96 44 51 77 39 25 87 76 9 61 7 72 17 60 85 11 34\n","truncated":false}}
%---
%[output:7157e9c8]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 95 32 7 19 24 66 89 81 43 88 2 86 54 5 13 67 12 34 60 48 76 44 35 1 55 72 61 20 37 27 56 57 92 73 65 21 83 51 79 59 18 46 47 58 36 93 8 50 62 6 91 28 63 94 38 25 82 74 11 29 26 80 69 40 10 68 84 96 64 78 22 15 3 33 71 14 75 53 90 70 85 30 16 42 31 87 9 23 41 52 39 77 45 4 49 17\n","truncated":false}}
%---
%[output:8c44f61e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR23_RUN05.xlsx\n","truncated":false}}
%---
%[output:8844443e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 5 8 11 12 13 15 16 18 26 27 29 36 41 44 51 57 60 64 68 72 73 77 78 79 80 81 82 83 96 98\n","truncated":false}}
%---
%[output:02714dac]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [14 92] at positions [5 52]\n","truncated":false}}
%---
%[output:9b141338]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 23 31 82 85 39 88 6 69 9 48 14 22 54 45 20 37 33 49 70 21 12 5 83 66 35 79 60 24 67 77 95 19 32 81 56 55 15 58 91 18 3 40 89 74 90 59 68 13 52 87 92 43 11 75 71 29 61 41 73 57 63 28 47 34 17 72 44 53 7 2 30 94 8 84 78 26 80 10 65 62 4 86 46 51 76 42 93 64 36 27 16 25 50 96 1 38\n","truncated":false}}
%---
%[output:5759cd56]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 8 87 29 78 76 42 65 19 17 41 16 44 21 89 75 92 3 1 68 64 31 58 10 60 52 93 96 59 38 62 74 5 23 2 71 85 45 94 34 39 88 77 69 36 49 61 86 30 81 83 51 72 26 53 7 11 24 22 47 6 48 32 14 95 9 57 37 80 55 27 67 15 56 20 54 46 35 63 82 4 66 40 25 73 50 79 13 18 33 12 84 70 90 43 91 28\n","truncated":false}}
%---
%[output:6ea55379]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR23_RUN06.xlsx\n","truncated":false}}
%---
%[output:51fbf084]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 70 48 59 12 91 69 14 9 46 44 5 30 58 41 29 34 88 18 74 95 33 78 26 81 86 2 51 77 79 61 85 49 50 17 3 75 28 25 68 56 71 36 22 4 76 93 31 55 19 21 42 16 57 47 52 64 1 82 13 43 66 65 15 7 23 83 38 84 72 37 35 92 62 96 89 67 32 60 8 94 27 39 80 54 45 11 73 90 63 24 10 53 87 6 40 20\n","truncated":false}}
%---
%[output:79c168cd]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 9 11 15 16 18 19 22 23 29 30 31 34 35 40 42 43 50 51 58 63 64 67 69 70 78 87 89 91 93 94 95 98\n","truncated":false}}
%---
%[output:54dae793]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 83 5 23 14 53 64 9 12 36 33 63 96 54 21 77 66 47 31 38 82 72 52 69 85 95 20 55 35 15 84 46 76 2 75 24 87 11 67 57 71 93 34 45 65 10 42 25 32 49 6 13 51 19 7 30 22 80 17 44 59 88 79 40 94 56 48 4 90 18 92 81 73 70 62 60 74 16 78 29 1 43 27 39 58 37 89 41 3 26 68 86 8 61 91 50 28\n","truncated":false}}
%---
%[output:3bc86d19]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [88 53] at positions [30 49]\n","truncated":false}}
%---
%[output:406ab500]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR23_RUN07.xlsx\n","truncated":false}}
%---
%[output:8f697b37]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 18 28 1 25 51 42 67 32 93 69 48 87 24 39 16 79 82 90 8 62 77 72 4 2 45 34 30 66 49 13 81 60 22 92 44 61 54 91 70 31 21 47 71 15 95 94 6 55 96 27 3 36 37 86 33 53 10 76 89 58 29 63 74 46 12 9 19 80 73 52 38 26 78 88 40 68 14 57 64 83 65 50 7 20 56 75 23 85 59 43 17 41 84 11 35 5\n","truncated":false}}
%---
%[output:5cceaa4c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 60 38 16 14 79 11 23 9 45 31 73 29 44 54 5 84 62 56 86 65 40 34 85 28 17 90 8 52 72 80 95 37 66 58 18 49 24 57 76 32 70 6 77 87 83 30 21 12 92 71 74 51 59 33 68 36 91 15 64 1 35 20 81 94 48 42 3 22 43 53 93 61 96 26 67 2 4 55 10 41 82 75 27 63 69 89 7 19 47 13 78 46 25 88 50 39\n","truncated":false}}
%---
%[output:3ca1a947]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 6 7 9 10 13 17 18 20 21 27 28 33 34 35 36 46 50 51 53 54 65 66 68 69 71 77 78 83 85 88 92 93\n","truncated":false}}
%---
%[output:0f254b53]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 41 71 66 21 87 81 13 36 26 33 10 57 30 65 7 3 93 75 60 83 42 59 68 94 23 58 16 67 47 88 51 37 46 63 53 2 25 28 6 19 14 54 72 64 31 91 48 38 18 80 82 12 15 70 29 34 11 84 56 35 69 9 45 85 17 27 55 92 77 74 44 32 95 96 49 52 79 22 78 50 40 5 86 1 20 39 61 24 4 76 8 62 89 73 90 43\n","truncated":false}}
%---
%[output:9b7a971a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR23_RUN08.xlsx\n","truncated":false}}
%---
%[output:82207855]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 51 73 95 88 44 6 26 89 68 37 45 56 41 85 14 34 19 3 77 1 94 21 60 11 50 27 31 33 75 52 86 55 64 12 9 42 82 76 28 69 72 49 58 43 36 17 65 46 80 81 62 74 32 16 20 48 4 93 18 23 90 40 57 96 7 71 70 8 5 54 29 61 67 22 92 87 79 13 59 15 38 53 47 83 10 30 63 84 35 2 66 91 24 78 39 25\n","truncated":false}}
%---
%[output:1caeb180]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [46 29] at positions [45 59]\n","truncated":false}}
%---
%[output:3a173ddd]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 83 14 21 3 40 23 59 86 69 29 75 55 50 68 5 53 42 39 78 67 85 58 24 17 82 48 8 73 38 57 13 1 95 90 19 33 96 32 70 30 31 84 93 79 54 71 91 7 9 72 46 4 63 34 52 87 36 88 56 10 44 35 28 41 80 2 25 51 49 18 11 89 22 76 66 26 60 77 62 15 94 64 20 45 81 47 6 37 74 43 27 16 65 12 61 92\n","truncated":false}}
%---
%[output:9d8d732b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 11 14 16 20 22 23 24 27 28 30 34 38 39 40 45 47 52 54 55 56 57 58 59 61 62 76 77 78 80 81 94 97\n","truncated":false}}
%---
%[output:2d81fbde]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 94 of 96\n\t\tAttempt 3 ran out of options at trial 95 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tAttempt 5 ran out of options at trial 96 of 96\n\t\tAttempt 6 ran out of options at trial 95 of 96\n\t\tFound solution after 7 attempt(s): 68 48 69 2 3 21 93 25 65 87 89 46 47 22 34 11 60 28 54 63 78 31 5 80 49 88 1 84 72 77 73 14 41 94 61 38 58 9 13 56 10 26 32 71 83 59 92 33 91 8 86 24 39 37 55 45 30 17 90 70 42 74 27 51 52 19 7 40 6 76 50 66 20 81 95 75 4 44 79 64 96 36 82 12 29 62 67 35 53 15 85 23 43 16 57 18\n","truncated":false}}
%---
%[output:3f33159b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR24_RUN01.xlsx\n","truncated":false}}
%---
%[output:770fc2b7]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 22 54 89 39 66 95 82 25 20 40 9 92 51 34 45 55 3 29 5 1 33 32 84 68 19 69 46 91 11 61 18 77 78 57 70 13 79 64 60 35 14 93 4 80 85 21 41 53 27 50 88 38 31 90 58 63 74 67 44 75 17 12 36 86 81 65 16 23 28 76 52 8 2 59 10 47 43 83 26 37 30 94 73 15 62 42 49 71 87 48 6 72 24 56 96 7\n","truncated":false}}
%---
%[output:4f82aab2]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 9 54 10 84 85 39 35 72 8 6 33 15 80 92 63 78 17 77 79 50 32 88 7 27 21 62 60 38 24 1 5 64 83 75 41 59 49 44 95 19 36 23 89 65 2 48 74 58 67 26 12 22 61 81 13 70 66 91 86 43 37 51 28 20 42 87 57 14 96 31 71 45 11 29 55 34 90 46 52 18 69 4 94 3 40 16 53 82 25 47 73 30 93 68 56 76\n","truncated":false}}
%---
%[output:357320f6]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 38 26 87 31 59 15 79 53 58 30 74 18 16 40 78 84 75 8 94 91 42 44 85 3 32 25 35 1 55 73 45 64 83 52 39 76 72 13 10 65 34 7 47 28 77 17 62 92 24 4 63 51 36 89 12 96 49 66 67 61 19 93 43 54 9 20 21 33 41 95 68 82 88 29 80 50 11 2 46 69 81 70 6 90 57 37 56 22 48 23 5 60 71 27 86 14\n","truncated":false}}
%---
%[output:9a9f08c1]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 9 10 11 12 14 15 17 24 27 29 35 40 45 47 49 56 58 60 63 64 70 71 74 76 80 81 82 84 86 88 90\n","truncated":false}}
%---
%[output:86aacc96]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR24_RUN02.xlsx\n","truncated":false}}
%---
%[output:0458b293]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [60 66] at positions [23 73]\n","truncated":false}}
%---
%[output:134b9194]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 86 75 93 49 61 41 16 45 82 38 53 94 88 13 80 74 48 34 77 62 1 24 14 3 60 66 21 18 39 29 81 20 57 19 68 8 92 89 63 47 70 7 76 71 55 87 32 35 50 10 52 79 25 67 33 30 26 9 90 42 46 12 23 95 11 43 96 73 84 51 17 58 64 31 59 69 27 78 83 65 6 2 22 44 85 36 4 72 40 28 15 56 37 54 5 91\n","truncated":false}}
%---
%[output:7395f145]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 55 38 76 21 69 66 62 93 19 60 29 42 87 68 36 9 57 70 83 4 24 6 91 53 10 12 33 28 20 82 88 43 56 59 37 46 64 94 30 63 67 2 78 73 44 92 15 49 26 31 11 8 41 74 95 54 5 71 61 52 77 32 72 16 96 48 34 13 25 85 89 75 39 22 35 7 90 14 79 86 40 23 45 65 3 17 1 58 27 81 51 84 80 18 50 47\n","truncated":false}}
%---
%[output:4218d912]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 8 75 64 61 89 12 24 36 32 77 33 57 40 42 91 48 4 81 94 30 22 52 15 13 62 18 7 45 65 76 85 71 20 96 54 72 11 3 35 10 19 80 88 83 47 51 2 78 34 74 67 9 63 44 17 6 87 79 59 27 53 56 86 58 73 28 84 14 21 39 93 31 26 69 55 70 41 38 95 23 46 29 92 16 60 90 37 1 66 5 82 49 25 50 43 68\n","truncated":false}}
%---
%[output:1f23221e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR24_RUN03.xlsx\n","truncated":false}}
%---
%[output:5a268c35]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 6 11 12 14 17 18 23 24 25 28 39 41 43 45 46 48 55 58 64 68 74 75 76 78 84 86 87 89 92 93 95 96\n","truncated":false}}
%---
%[output:2c99d37d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tAttempt 5 ran out of options at trial 95 of 96\n\t\tAttempt 6 ran out of options at trial 96 of 96\n\t\tAttempt 7 ran out of options at trial 96 of 96\n\t\tAttempt 8 ran out of options at trial 95 of 96\n\t\tAttempt 9 ran out of options at trial 96 of 96\n\t\tFound solution after 10 attempt(s): 40 55 93 1 20 33 43 78 69 54 9 90 34 88 87 26 92 80 27 52 71 15 51 17 75 42 25 28 7 8 35 2 65 84 58 47 23 61 49 22 73 10 32 29 95 74 79 18 36 16 14 37 83 86 56 46 77 94 31 6 63 59 91 12 66 53 72 48 45 62 4 82 39 70 30 11 76 64 13 60 85 38 57 19 44 3 96 68 41 24 89 21 50 67 81 5\n","truncated":false}}
%---
%[output:6c5f2c58]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [9 91] at positions [5 66]\n","truncated":false}}
%---
%[output:126ea433]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 43 60 87 53 20 36 17 56 64 80 33 96 1 72 59 37 73 9 88 23 5 52 7 15 41 35 12 28 70 95 44 85 76 22 30 82 83 86 54 74 71 63 34 75 29 55 8 65 84 27 19 94 4 2 24 66 68 3 58 91 40 16 45 46 49 21 11 81 67 39 25 48 92 10 57 62 90 26 69 61 6 47 79 38 31 42 13 78 18 51 77 14 93 50 32 89\n","truncated":false}}
%---
%[output:3dca21a4]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR24_RUN04.xlsx\n","truncated":false}}
%---
%[output:241e526f]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 60 88 4 86 58 48 69 79 5 61 29 22 76 87 89 27 12 18 64 50 66 34 30 44 10 70 24 81 36 49 14 40 82 78 54 26 90 55 80 56 42 45 41 95 33 67 39 13 15 92 68 94 23 20 1 16 47 32 73 77 9 28 57 62 8 74 31 37 51 84 6 53 17 38 72 85 93 21 59 2 71 35 91 75 52 83 63 65 7 46 19 3 25 96 43 11\n","truncated":false}}
%---
%[output:38033845]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 6 16 18 20 21 23 24 27 30 31 34 35 40 43 52 54 56 57 64 65 67 68 71 76 78 81 89 90 95 97\n","truncated":false}}
%---
%[output:0ae87b4d]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 22 6 52 51 87 55 13 32 72 28 45 36 83 74 46 2 90 48 66 79 49 25 20 58 44 30 86 91 14 9 78 82 18 65 11 34 54 73 92 17 16 94 70 71 38 60 76 61 95 63 33 35 15 12 50 53 21 40 31 64 7 27 23 85 39 89 88 3 42 67 26 1 77 10 62 81 4 68 56 37 19 47 84 57 24 75 93 43 5 41 59 69 8 96 80 29\n","truncated":false}}
%---
%[output:5ee31460]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 96 79 84 27 30 46 73 41 28 60 1 3 86 14 35 48 63 51 67 53 44 7 76 18 11 61 32 89 90 42 85 52 81 15 24 78 13 36 87 64 22 71 68 59 83 94 23 91 47 17 21 12 8 74 88 69 38 39 6 50 16 93 4 20 34 49 77 80 19 58 33 65 10 82 40 5 75 45 25 57 62 26 72 29 95 56 43 92 70 54 2 55 66 9 31 37\n","truncated":false}}
%---
%[output:89e42d91]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR24_RUN05.xlsx\n","truncated":false}}
%---
%[output:5aa7534f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [84 72] at positions [30 53]\n","truncated":false}}
%---
%[output:8d6e632d]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 72 63 61 32 22 71 84 42 68 17 57 13 85 12 10 64 94 75 70 47 40 4 69 14 27 45 26 1 36 58 34 88 60 79 78 30 83 25 74 39 56 16 6 55 37 48 89 92 21 51 28 31 86 11 93 87 62 90 41 3 29 43 20 15 33 80 50 76 96 73 7 66 95 59 52 23 44 9 54 35 67 5 81 19 82 8 18 2 38 53 77 49 91 46 24 65\n","truncated":false}}
%---
%[output:02035592]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 4 23 53 16 12 87 21 66 49 32 15 75 10 58 84 96 76 22 81 1 45 85 57 54 74 40 69 82 36 31 30 33 6 20 26 62 42 34 56 24 71 72 50 9 67 7 37 80 68 95 94 77 19 89 2 91 64 43 25 14 52 78 38 41 13 11 86 18 44 61 60 83 47 88 46 27 55 90 29 93 70 28 39 3 63 5 48 51 65 92 8 17 73 59 35 79\n","truncated":false}}
%---
%[output:965bf336]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 11 18 20 25 26 31 35 37 38 40 42 43 45 47 48 52 57 59 61 63 67 69 70 73 79 81 82 88 90 91 95\n","truncated":false}}
%---
%[output:7502cb5f]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR24_RUN06.xlsx\n","truncated":false}}
%---
%[output:8a9bf27d]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 24 21 44 62 73 76 28 78 53 45 72 46 27 52 86 74 81 6 48 87 56 10 12 61 59 18 5 23 84 31 16 75 7 92 33 47 11 60 93 85 37 90 3 17 64 25 20 42 41 22 70 40 50 8 4 82 66 15 69 32 89 96 26 63 77 68 55 43 2 39 65 94 49 58 38 67 29 91 34 30 35 88 1 79 51 13 36 9 19 80 95 54 71 14 57 83\n","truncated":false}}
%---
%[output:6439db60]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 77 11 13 49 39 47 23 42 63 29 78 53 4 74 90 69 70 26 3 87 20 50 85 38 79 43 92 12 17 96 82 52 56 73 6 44 2 14 65 64 45 5 37 41 81 19 25 60 94 9 61 75 76 32 68 86 58 1 24 40 71 34 59 31 22 89 93 36 21 16 95 72 7 51 54 33 27 48 55 30 57 88 10 18 83 46 66 91 67 35 84 28 8 80 62 15\n","truncated":false}}
%---
%[output:47497456]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [71 1] at positions [7 53]\n","truncated":false}}
%---
%[output:50cf39b4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [96 24] at positions [36 65]\n","truncated":false}}
%---
%[output:9c2ed4b0]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR24_RUN07.xlsx\n","truncated":false}}
%---
%[output:8477977e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 6 10 12 16 18 20 24 27 28 30 32 33 40 41 44 56 59 61 69 70 71 72 73 76 80 83 86 87 88 92 93\n","truncated":false}}
%---
%[output:4530fcec]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [69 25] at positions [39 86]\n","truncated":false}}
%---
%[output:71350662]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [10 14] at positions [26 70]\n","truncated":false}}
%---
%[output:931212be]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [88 45] at positions [41 96]\n","truncated":false}}
%---
%[output:81793cae]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR24_RUN08.xlsx\n","truncated":false}}
%---
%[output:03088a73]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [61 39] at positions [20 96]\n","truncated":false}}
%---
%[output:501cbf01]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 7 10 18 19 22 23 24 25 28 29 32 38 46 48 53 56 62 63 65 66 67 68 79 82 84 85 86 95 96 98\n","truncated":false}}
%---
%[output:0bb601f6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [38 74] at positions [30 72]\n","truncated":false}}
%---
%[output:931d213d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [20 37] at positions [5 67]\n","truncated":false}}
%---
%[output:6a3af834]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [43 87] at positions [9 76]\n","truncated":false}}
%---
%[output:1f4df7f7]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR25_RUN01.xlsx\n","truncated":false}}
%---
%[output:45f66fb6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [24 58] at positions [16 64]\n","truncated":false}}
%---
%[output:87ef1bcc]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 6 8 11 13 14 17 25 26 31 32 33 36 37 38 39 48 55 58 64 65 70 73 76 78 80 84 85 89 93 96 97 98\n","truncated":false}}
%---
%[output:002710e9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [94 57] at positions [9 86]\n","truncated":false}}
%---
%[output:8afd5969]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [4 54] at positions [12 75]\n","truncated":false}}
%---
%[output:8846bf5a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR25_RUN02.xlsx\n","truncated":false}}
%---
%[output:101e2def]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [11 71] at positions [17 95]\n","truncated":false}}
%---
%[output:560dbf6e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [64 11] at positions [38 88]\n","truncated":false}}
%---
%[output:9afc1935]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 7 9 10 13 15 16 18 19 20 32 33 39 41 45 53 54 59 60 67 70 74 76 78 82 85 89 90 93 96 97\n","truncated":false}}
%---
%[output:89c6b0c8]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [21 9] at positions [38 70]\n","truncated":false}}
%---
%[output:413e38f4]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR25_RUN03.xlsx\n","truncated":false}}
%---
%[output:75188355]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [76 82] at positions [48 60]\n","truncated":false}}
%---
%[output:3f0c2601]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [59 58] at positions [14 64]\n","truncated":false}}
%---
%[output:4926caf0]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [50 93] at positions [21 62]\n","truncated":false}}
%---
%[output:8c9345b8]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 3 5 9 10 15 16 18 21 24 25 31 42 47 48 53 54 56 61 62 68 69 72 78 79 82 85 88 93 94 96\n","truncated":false}}
%---
%[output:5116c6d5]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR25_RUN04.xlsx\n","truncated":false}}
%---
%[output:5973caf8]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [86 50] at positions [26 80]\n","truncated":false}}
%---
%[output:6ef5fd66]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [30 17] at positions [2 78]\n","truncated":false}}
%---
%[output:2bb77a89]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [85 37] at positions [29 72]\n","truncated":false}}
%---
%[output:95b178a9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [29 27] at positions [9 59]\n","truncated":false}}
%---
%[output:523a1bed]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR25_RUN05.xlsx\n","truncated":false}}
%---
%[output:9a391e3a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 7 10 13 17 18 20 25 26 27 28 31 37 40 47 48 55 57 59 60 64 66 68 70 73 76 80 82 85 86 90 94\n","truncated":false}}
%---
%[output:98db4f4d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [25 87] at positions [18 70]\n","truncated":false}}
%---
%[output:82f70a3e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [56 60] at positions [28 53]\n","truncated":false}}
%---
%[output:38c20393]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [69 7] at positions [23 73]\n","truncated":false}}
%---
%[output:334e1a98]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR25_RUN06.xlsx\n","truncated":false}}
%---
%[output:27befc81]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [18 1] at positions [10 80]\n","truncated":false}}
%---
%[output:1225a2b6]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 9 10 22 23 25 26 29 31 32 42 44 45 46 48 50 53 56 60 68 70 71 77 79 83 88 90 92 94 95 96\n","truncated":false}}
%---
%[output:68f93d93]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [2 29] at positions [30 60]\n","truncated":false}}
%---
%[output:9af98d66]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [50 57] at positions [2 53]\n","truncated":false}}
%---
%[output:5419d9be]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR25_RUN07.xlsx\n","truncated":false}}
%---
%[output:838a3567]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [44 12] at positions [13 55]\n","truncated":false}}
%---
%[output:1f20bd22]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [64 82] at positions [17 49]\n","truncated":false}}
%---
%[output:103ad2fc]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [32 13] at positions [38 70]\n","truncated":false}}
%---
%[output:557162bf]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 15 16 22 23 24 31 32 33 35 36 37 39 40 41 52 56 57 61 66 67 69 70 71 72 80 81 82 85 86 94\n","truncated":false}}
%---
%[output:67d94ac5]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR25_RUN08.xlsx\n","truncated":false}}
%---
%[output:065a8c28]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [53 25] at positions [18 67]\n","truncated":false}}
%---
%[output:8760b3b6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [3 95] at positions [15 87]\n","truncated":false}}
%---
%[output:54a4e4a1]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [91 32] at positions [2 70]\n","truncated":false}}
%---
%[output:12e2f8c4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [1 96] at positions [21 70]\n","truncated":false}}
%---
%[output:365e9a54]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 8 11 15 25 28 30 32 33 34 35 38 41 42 47 50 51 58 59 60 67 71 75 78 81 82 84 86 88 95 97\n","truncated":false}}
%---
%[output:6356e976]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR26_RUN01.xlsx\n","truncated":false}}
%---
%[output:9239d324]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [41 71] at positions [11 81]\n","truncated":false}}
%---
%[output:3a5a399f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [18 28] at positions [30 78]\n","truncated":false}}
%---
%[output:21e47195]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [60 81] at positions [3 58]\n","truncated":false}}
%---
%[output:36a0942f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [12 26] at positions [30 53]\n","truncated":false}}
%---
%[output:431d3460]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR26_RUN02.xlsx\n","truncated":false}}
%---
%[output:8b6b4c7c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 5 6 12 13 19 21 23 25 27 28 34 38 40 41 47 50 52 55 59 61 62 68 69 70 73 77 81 85 90 92 98\n","truncated":false}}
%---
%[output:633cdded]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [27 66] at positions [29 64]\n","truncated":false}}
%---
%[output:18228f61]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [72 14] at positions [7 73]\n","truncated":false}}
%---
%[output:3b4b44c1]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [87 57] at positions [21 87]\n","truncated":false}}
%---
%[output:6387c284]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR26_RUN03.xlsx\n","truncated":false}}
%---
%[output:7f0f8dd4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [15 72] at positions [4 73]\n","truncated":false}}
%---
%[output:1412398c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 10 12 15 16 17 23 28 31 32 35 36 41 44 46 48 49 53 58 60 62 65 76 78 79 80 81 82 83 84 85 92 94\n","truncated":false}}
%---
%[output:9a1e9bdc]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [10 27] at positions [34 67]\n","truncated":false}}
%---
%[output:84a44f0e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [23 59] at positions [8 62]\n","truncated":false}}
%---
%[output:3c52297b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR26_RUN04.xlsx\n","truncated":false}}
%---
%[output:3f759f7f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [45 54] at positions [44 61]\n","truncated":false}}
%---
%[output:18c67f13]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [23 58] at positions [13 56]\n","truncated":false}}
%---
%[output:71c15df0]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 10 13 14 20 24 26 27 33 39 41 44 45 47 48 50 52 54 57 58 63 67 68 72 73 74 80 86 88 89 97\n","truncated":false}}
%---
%[output:719427cf]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [16 57] at positions [28 69]\n","truncated":false}}
%---
%[output:6bf7df64]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR26_RUN05.xlsx\n","truncated":false}}
%---
%[output:16174675]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [58 55] at positions [2 53]\n","truncated":false}}
%---
%[output:3c177f6c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [86 12] at positions [4 78]\n","truncated":false}}
%---
%[output:32d01477]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [57 5] at positions [37 82]\n","truncated":false}}
%---
%[output:6a2bcc0e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 6 8 10 15 22 23 27 31 32 35 37 39 40 44 50 61 65 69 70 73 75 76 79 86 89 91 93 95 96 97\n","truncated":false}}
%---
%[output:95138a0e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR26_RUN06.xlsx\n","truncated":false}}
%---
%[output:183edec5]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [65 12] at positions [11 53]\n","truncated":false}}
%---
%[output:5562de5e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [50 77] at positions [9 71]\n","truncated":false}}
%---
%[output:02b49f8f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [93 33] at positions [16 61]\n","truncated":false}}
%---
%[output:4b5ce014]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [52 39] at positions [47 81]\n","truncated":false}}
%---
%[output:4e312c94]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR26_RUN07.xlsx\n","truncated":false}}
%---
%[output:71f2a9d8]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 5 10 15 19 22 30 33 35 36 41 42 43 48 49 51 52 55 58 69 73 75 78 79 81 84 85 86 87 88 96\n","truncated":false}}
%---
%[output:0b743ee4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [11 84] at positions [42 60]\n","truncated":false}}
%---
%[output:45c05951]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [75 12] at positions [31 59]\n","truncated":false}}
%---
%[output:0c561cf7]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [77 93] at positions [6 56]\n","truncated":false}}
%---
%[output:87b07f7b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR26_RUN08.xlsx\n","truncated":false}}
%---
%[output:5059232e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [78 58] at positions [3 67]\n","truncated":false}}
%---
%[output:05f38de8]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 7 9 10 14 16 17 22 23 28 35 36 37 38 40 48 50 52 54 56 58 73 74 77 78 81 86 88 94 96 97 98\n","truncated":false}}
%---
%[output:2cea4f2b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [68 91] at positions [29 89]\n","truncated":false}}
%---
%[output:2d91b236]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [5 29] at positions [35 75]\n","truncated":false}}
%---
%[output:21facb13]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [14 7] at positions [45 83]\n","truncated":false}}
%---
%[output:1eff04e3]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR27_RUN01.xlsx\n","truncated":false}}
%---
%[output:2cd66652]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [57 82] at positions [20 57]\n","truncated":false}}
%---
%[output:36fc23a7]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [9 77] at positions [42 64]\n","truncated":false}}
%---
%[output:8653b285]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 6 7 10 18 20 21 22 25 27 31 32 34 38 39 50 54 61 63 65 66 67 73 78 80 81 82 84 89 90 93\n","truncated":false}}
%---
%[output:0b1abc46]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [62 73] at positions [33 82]\n","truncated":false}}
%---
%[output:45765435]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR27_RUN02.xlsx\n","truncated":false}}
%---
%[output:939b1992]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [28 81] at positions [37 60]\n","truncated":false}}
%---
%[output:0ce5e6ab]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [36 39] at positions [23 86]\n","truncated":false}}
%---
%[output:8a2bbb4f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [57 73] at positions [48 74]\n","truncated":false}}
%---
%[output:2a13eb49]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 8 12 17 18 22 23 27 33 35 36 40 42 45 47 51 53 55 61 63 67 70 71 72 74 75 79 81 92 96 98\n","truncated":false}}
%---
%[output:60d12f14]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR27_RUN03.xlsx\n","truncated":false}}
%---
%[output:5bfb0e98]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [17 53] at positions [6 76]\n","truncated":false}}
%---
%[output:48a9b5d4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [68 18] at positions [14 55]\n","truncated":false}}
%---
%[output:1d1e4b06]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [64 35] at positions [8 56]\n","truncated":false}}
%---
%[output:3adb866c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [25 77] at positions [28 89]\n","truncated":false}}
%---
%[output:16cb32cd]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR27_RUN04.xlsx\n","truncated":false}}
%---
%[output:16e8f1a0]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 6 8 9 11 15 16 21 26 29 32 34 37 40 42 44 50 53 56 61 63 65 67 69 72 74 77 81 85 93 96 97\n","truncated":false}}
%---
%[output:3117aa58]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [46 68] at positions [24 65]\n","truncated":false}}
%---
%[output:7f53f393]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [61 62] at positions [32 76]\n","truncated":false}}
%---
%[output:07b13d6a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [9 74] at positions [9 71]\n","truncated":false}}
%---
%[output:4730fef2]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR27_RUN05.xlsx\n","truncated":false}}
%---
%[output:82c02a0a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [9 39] at positions [31 94]\n","truncated":false}}
%---
%[output:56fa019c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 5 7 11 17 20 21 23 24 25 28 29 31 33 39 43 50 53 54 57 62 64 66 74 75 79 84 86 87 88 90 93\n","truncated":false}}
%---
%[output:1a88b1b8]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [5 69] at positions [7 80]\n","truncated":false}}
%---
%[output:4393ab77]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [83 82] at positions [33 89]\n","truncated":false}}
%---
%[output:93c81b28]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR27_RUN06.xlsx\n","truncated":false}}
%---
%[output:8581a7c9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [94 8] at positions [14 96]\n","truncated":false}}
%---
%[output:692783b2]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [72 8] at positions [18 52]\n","truncated":false}}
%---
%[output:8836e78e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 5 6 10 13 15 17 18 20 21 22 26 27 33 48 49 50 56 57 59 64 68 69 71 75 84 85 86 87 88 90 91\n","truncated":false}}
%---
%[output:26d2a418]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [71 48] at positions [48 53]\n","truncated":false}}
%---
%[output:1ae18698]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR27_RUN07.xlsx\n","truncated":false}}
%---
%[output:09dd042c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [9 54] at positions [25 92]\n","truncated":false}}
%---
%[output:7462c7ac]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [66 52] at positions [17 57]\n","truncated":false}}
%---
%[output:4b39dd41]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [73 29] at positions [18 82]\n","truncated":false}}
%---
%[output:20c5a935]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 6 8 12 19 21 28 29 33 36 38 43 44 45 47 52 58 60 61 64 65 67 72 75 79 80 81 82 84 85 90\n","truncated":false}}
%---
%[output:7a1e7c72]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR27_RUN08.xlsx\n","truncated":false}}
%---
%[output:7a4fb8cf]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [76 83] at positions [27 92]\n","truncated":false}}
%---
%[output:832cc327]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [77 43] at positions [7 55]\n","truncated":false}}
%---
%[output:652a90c1]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [68 72] at positions [42 94]\n","truncated":false}}
%---
%[output:558b7972]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [46 51] at positions [27 56]\n","truncated":false}}
%---
%[output:8e5da6f5]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 5 6 7 10 13 15 18 21 22 26 32 33 38 39 50 51 52 56 58 59 62 67 71 72 74 84 85 86 87 90\n","truncated":false}}
%---
%[output:5365f2c2]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR28_RUN01.xlsx\n","truncated":false}}
%---
%[output:6f7dbf0a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [51 20] at positions [6 96]\n","truncated":false}}
%---
%[output:40407667]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [63 47] at positions [35 81]\n","truncated":false}}
%---
%[output:0bd9fcb6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [74 19] at positions [22 51]\n","truncated":false}}
%---
%[output:3a36f530]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [47 85] at positions [43 81]\n","truncated":false}}
%---
%[output:31be3b2c]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR28_RUN02.xlsx\n","truncated":false}}
%---
%[output:7cfed1e0]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 10 11 15 16 18 19 22 24 28 30 32 37 39 44 45 49 50 57 59 64 70 74 77 78 79 81 86 87 92 93 96 98\n","truncated":false}}
%---
%[output:64ed80ae]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [35 7] at positions [25 69]\n","truncated":false}}
%---
%[output:4ffacd63]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [23 12] at positions [33 90]\n","truncated":false}}
%---
%[output:75d1dce4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [46 72] at positions [9 69]\n","truncated":false}}
%---
%[output:0056b7a1]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR28_RUN03.xlsx\n","truncated":false}}
%---
%[output:483f25bf]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [53 22] at positions [5 56]\n","truncated":false}}
%---
%[output:14d67f70]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [30 88] at positions [27 74]\n","truncated":false}}
%---
%[output:6245dc70]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 5 6 9 12 14 16 18 23 24 26 29 32 33 35 40 51 53 55 57 62 65 68 74 75 76 83 84 87 88 91 94\n","truncated":false}}
%---
%[output:4016262a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [86 13] at positions [19 90]\n","truncated":false}}
%---
%[output:98164806]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR28_RUN04.xlsx\n","truncated":false}}
%---
%[output:7c80a438]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [72 43] at positions [43 96]\n","truncated":false}}
%---
%[output:02182eba]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [76 96] at positions [38 64]\n","truncated":false}}
%---
%[output:8fc75886]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [30 63] at positions [40 53]\n","truncated":false}}
%---
%[output:135e476d]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 5 7 10 11 26 27 28 31 33 36 37 39 43 45 56 57 58 59 60 66 67 68 78 80 81 84 85 92 94 98\n","truncated":false}}
%---
%[output:28855311]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR28_RUN05.xlsx\n","truncated":false}}
%---
%[output:41f54f3e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [34 4] at positions [15 77]\n","truncated":false}}
%---
%[output:616d131f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [54 83] at positions [2 78]\n","truncated":false}}
%---
%[output:209f34e8]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [58 34] at positions [48 76]\n","truncated":false}}
%---
%[output:9938e7c9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [73 12] at positions [30 55]\n","truncated":false}}
%---
%[output:1664b9d4]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR28_RUN06.xlsx\n","truncated":false}}
%---
%[output:7fa109e0]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 8 9 14 18 19 26 30 31 32 34 37 38 39 44 48 49 50 51 52 53 54 60 64 66 74 75 77 81 92 93 95 98\n","truncated":false}}
%---
%[output:4db0085e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [24 10] at positions [22 50]\n","truncated":false}}
%---
%[output:3182b1b5]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [82 14] at positions [30 78]\n","truncated":false}}
%---
%[output:7e440b4b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [24 46] at positions [7 81]\n","truncated":false}}
%---
%[output:0050630e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR28_RUN07.xlsx\n","truncated":false}}
%---
%[output:941d7d30]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [69 5] at positions [9 96]\n","truncated":false}}
%---
%[output:8e71b4c5]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 9 10 14 15 17 18 24 29 30 39 40 41 46 47 48 49 51 53 55 61 62 65 68 71 72 76 77 80 81 86 88 90\n","truncated":false}}
%---
%[output:5abce73a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [7 16] at positions [23 62]\n","truncated":false}}
%---
%[output:014d5c0d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [58 37] at positions [5 68]\n","truncated":false}}
%---
%[output:09025270]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR28_RUN08.xlsx\n","truncated":false}}
%---
%[output:8a2a1a72]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [36 68] at positions [12 78]\n","truncated":false}}
%---
%[output:73a1c677]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [64 8] at positions [40 53]\n","truncated":false}}
%---
%[output:7786c39c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 7 9 12 14 16 20 27 28 31 36 37 38 40 41 50 51 54 56 63 67 68 71 72 73 78 84 88 89 94 98\n","truncated":false}}
%---
%[output:2edbcc2c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [88 82] at positions [32 85]\n","truncated":false}}
%---
%[output:8de74b02]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [75 44] at positions [12 69]\n","truncated":false}}
%---
%[output:3437a3b8]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR29_RUN01.xlsx\n","truncated":false}}
%---
%[output:24194907]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [53 94] at positions [9 72]\n","truncated":false}}
%---
%[output:14ccfe34]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [38 75] at positions [24 52]\n","truncated":false}}
%---
%[output:6e4d251f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 8 10 11 12 14 18 19 21 23 27 28 30 36 38 42 45 50 51 52 58 63 64 66 70 72 73 87 90 93 94 96 97\n","truncated":false}}
%---
%[output:33eb920e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 8 10 13 16 19 21 23 26 28 32 35 40 41 43 44 50 56 60 61 63 67 74 79 82 83 86 88 90 94 95 96\n","truncated":false}}
%---
%[output:24caae8f]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR29_RUN02.xlsx\n","truncated":false}}
%---
%[output:7b290331]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 7 12 15 16 17 19 20 21 23 26 32 34 37 39 41 53 55 56 57 58 59 65 71 73 75 81 82 84 90 92 95\n","truncated":false}}
%---
%[output:39ce450d]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 6 9 16 17 18 19 24 29 36 37 38 41 46 49 54 55 58 59 65 69 71 83 87 88 91 92 93 94 95 97\n","truncated":false}}
%---
%[output:057380a4]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 5 7 9 10 11 12 15 19 20 21 31 37 41 45 48 53 54 56 58 61 65 66 69 70 72 73 74 75 80 81 91\n","truncated":false}}
%---
%[output:66461bae]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 6 10 16 19 23 27 30 32 33 35 37 40 41 44 45 47 50 51 52 53 58 59 62 63 70 71 72 73 75 78 85 90\n","truncated":false}}
%---
%[output:169b2202]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR29_RUN03.xlsx\n","truncated":false}}
%---
%[output:8988cf49]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 6 15 17 20 23 24 25 29 31 35 36 39 40 44 47 48 58 59 61 67 70 71 72 76 82 84 86 87 88 92 96 97\n","truncated":false}}
%---
%[output:23e41efc]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 8 10 11 12 14 16 20 21 28 31 36 37 39 41 44 48 51 54 64 65 71 73 74 76 77 83 86 88 90 91 92 96\n","truncated":false}}
%---
%[output:1e56f650]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 8 12 13 16 17 18 25 28 31 33 34 38 43 47 54 56 57 58 62 63 64 67 68 73 75 76 80 81 82 92\n","truncated":false}}
%---
%[output:261ba22a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 3 8 15 17 19 21 26 27 29 31 33 40 45 49 51 52 53 57 61 69 73 75 78 82 85 88 90 94 95 97\n","truncated":false}}
%---
%[output:298e79aa]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR29_RUN04.xlsx\n","truncated":false}}
%---
%[output:9cc1d908]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 8 17 18 24 25 26 27 30 31 35 42 43 44 46 51 53 56 59 61 63 65 68 69 72 80 87 91 93 94 96\n","truncated":false}}
%---
%[output:1dc9afad]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 5 9 10 16 17 18 19 21 22 31 36 41 43 49 51 53 63 65 67 68 78 83 86 89 91 93 95 96 97 98\n","truncated":false}}
%---
%[output:39bfd5d0]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 6 9 10 15 18 20 21 26 29 33 34 39 44 46 49 50 51 56 64 65 67 68 69 73 77 83 87 90 91 92 96\n","truncated":false}}
%---
%[output:58291146]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 6 8 9 10 20 21 26 28 31 35 41 42 43 46 48 51 54 55 58 59 61 63 65 80 81 83 86 89 94 95 97\n","truncated":false}}
%---
%[output:54a08a10]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR29_RUN05.xlsx\n","truncated":false}}
%---
%[output:9ced67cc]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 7 9 13 14 16 20 23 25 29 30 39 41 42 44 46 49 52 54 56 57 59 67 68 70 75 76 82 86 92 93 95 97\n","truncated":false}}
%---
%[output:40ce1b15]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 7 11 13 15 17 19 24 26 35 36 37 43 44 47 48 49 56 59 60 62 68 69 75 76 77 82 90 91 93 94 95 96\n","truncated":false}}
%---
%[output:2eded10b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 7 14 15 18 25 29 32 34 38 43 44 45 47 49 53 57 59 61 65 70 76 82 84 85 88 89 91 94 95 96\n","truncated":false}}
%---
%[output:7dc5799c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 10 12 15 16 19 20 22 24 27 28 29 36 42 44 47 50 58 62 65 66 67 71 74 75 81 85 93 94 96 97 98\n","truncated":false}}
%---
%[output:80da19e9]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR29_RUN06.xlsx\n","truncated":false}}
%---
%[output:3820b4f3]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 9 11 18 19 21 23 24 26 30 40 41 45 46 48 52 55 59 60 67 71 75 77 78 81 84 89 92 93 94 97\n","truncated":false}}
%---
%[output:69cc8441]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 4 7 8 16 17 18 25 28 35 37 38 40 46 48 51 52 54 55 61 67 71 76 81 82 85 87 88 90 97 98\n","truncated":false}}
%---
%[output:4078ae8d]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 10 11 14 15 16 17 18 20 26 29 31 36 39 43 48 50 53 58 60 65 66 68 72 73 75 76 77 79 83 91 92\n","truncated":false}}
%---
%[output:6b44ffc9]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 7 11 13 14 15 19 23 25 29 31 34 38 42 43 48 49 50 56 59 64 68 69 71 74 76 79 80 84 86 91 93 94\n","truncated":false}}
%---
%[output:4811c0d5]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR29_RUN07.xlsx\n","truncated":false}}
%---
%[output:30ef791c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 8 9 11 17 19 21 24 25 31 39 40 42 44 45 48 52 54 56 58 61 62 71 73 75 76 82 84 92 95 97 98\n","truncated":false}}
%---
%[output:88b4dd44]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 5 9 11 18 19 22 26 28 29 32 37 44 46 48 49 50 54 55 57 59 62 63 64 68 76 84 85 89 91 93 94\n","truncated":false}}
%---
%[output:7628d95e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 7 8 10 15 16 18 19 24 36 37 38 42 45 48 51 58 60 61 62 65 68 69 74 76 77 83 89 93 94 95\n","truncated":false}}
%---
%[output:9da1028d]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 5 6 11 13 18 20 22 23 25 29 30 42 45 48 49 56 57 60 62 63 65 67 68 69 74 83 90 91 92 97 98\n","truncated":false}}
%---
%[output:543df555]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR29_RUN08.xlsx\n","truncated":false}}
%---
%[output:4a9de0f4]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 9 11 12 16 19 20 33 34 36 42 45 46 47 48 49 52 54 61 64 67 70 71 75 76 83 86 87 89 94 95 96\n","truncated":false}}
%---
%[output:839fb900]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 9 10 14 24 25 28 32 33 37 38 40 41 43 44 49 53 55 59 61 65 69 71 77 79 84 87 91 92 93 97 98\n","truncated":false}}
%---
%[output:6aee9f15]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 5 9 10 12 13 23 27 29 30 37 39 41 44 48 49 53 61 62 66 69 70 74 78 80 82 85 87 89 95 96 97\n","truncated":false}}
%---
%[output:9283f5d7]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 11 18 19 20 23 28 32 33 38 39 41 42 43 46 50 51 56 61 62 63 67 69 74 76 78 79 83 92 94 95\n","truncated":false}}
%---
%[output:6f1267f1]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 5 10 11 14 17 18 27 30 31 32 34 41 42 43 45 50 51 52 54 55 64 71 76 77 78 79 81 85 92 96 97\n","truncated":false}}
%---
%[output:3c29aa0d]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR30_RUN01.xlsx\n","truncated":false}}
%---
%[output:7f25b4c9]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 6 8 15 19 22 26 28 32 36 37 40 42 43 48 49 53 58 59 60 61 64 65 68 69 75 76 79 83 87 90 97\n","truncated":false}}
%---
%[output:620abe8f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 5 6 7 14 19 22 27 31 37 42 43 46 48 49 51 55 63 64 65 67 70 72 74 76 81 83 84 88 91 97\n","truncated":false}}
%---
%[output:392bdca1]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 12 17 20 25 29 34 35 36 38 39 40 42 43 46 49 52 55 60 61 62 71 73 78 79 83 85 87 88 89 92 98\n","truncated":false}}
%---
%[output:7eb4044a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 8 9 10 13 17 21 23 30 33 34 35 44 46 47 49 55 60 61 62 64 65 67 69 75 77 78 80 82 88 89 94\n","truncated":false}}
%---
%[output:2c4d6368]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR30_RUN02.xlsx\n","truncated":false}}
%---
%[output:91ca2a1b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 11 13 15 16 20 25 27 29 32 34 43 45 47 49 53 60 62 63 64 65 67 73 77 79 82 84 89 91 93 94\n","truncated":false}}
%---
%[output:0cb637a3]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 8 9 11 13 15 17 21 24 27 30 31 33 35 39 47 54 60 62 63 64 66 67 68 74 75 82 85 86 89 90 96\n","truncated":false}}
%---
%[output:1b765d9c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 7 8 9 13 14 17 18 23 27 30 37 39 41 43 44 46 52 53 54 61 64 65 66 69 71 72 74 83 84 88 95 98\n","truncated":false}}
%---
%[output:358dd9d9]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 6 9 12 13 15 16 21 23 24 25 30 33 37 39 41 43 50 53 58 59 62 63 70 73 76 79 80 86 88 91 92 97\n","truncated":false}}
%---
%[output:65d9bfe5]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR30_RUN03.xlsx\n","truncated":false}}
%---
%[output:01211a86]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 7 9 10 15 16 20 23 29 36 39 41 42 44 46 47 52 53 54 59 60 66 67 68 70 72 74 76 77 82 86 87\n","truncated":false}}
%---
%[output:1555b35f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 7 17 18 19 20 27 30 32 33 35 38 44 48 49 53 54 55 62 73 74 76 79 80 81 84 86 88 92 93 94\n","truncated":false}}
%---
%[output:2520e71e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 12 14 15 16 17 19 21 28 32 36 39 40 45 46 54 55 56 57 58 67 68 69 70 77 81 84 86 94 97 98\n","truncated":false}}
%---
%[output:010e8386]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 9 11 16 17 18 19 23 25 26 33 35 39 46 48 50 54 56 57 59 65 68 73 74 75 76 77 83 84 93 95\n","truncated":false}}
%---
%[output:33d5ba77]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR30_RUN04.xlsx\n","truncated":false}}
%---
%[output:1064ea1a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 8 10 13 17 18 21 23 24 28 30 37 40 41 42 46 56 57 61 63 66 67 68 71 74 75 76 78 80 83 90 98\n","truncated":false}}
%---
%[output:983fbc9c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 5 7 18 24 25 27 31 32 34 37 40 42 46 47 50 54 59 60 65 67 68 69 72 75 77 79 82 92 93 94\n","truncated":false}}
%---
%[output:1fe586c0]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 7 8 10 17 18 21 23 28 34 36 40 41 43 47 49 59 60 68 74 77 79 81 82 83 84 86 89 92 94 96 98\n","truncated":false}}
%---
%[output:3b4d0cb1]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 6 7 12 13 17 20 22 23 25 30 34 35 39 47 48 50 57 59 61 62 64 65 69 70 72 81 82 87 88 90 98\n","truncated":false}}
%---
%[output:88602904]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR30_RUN05.xlsx\n","truncated":false}}
%---
%[output:5ed7f481]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 9 10 20 26 27 29 32 33 34 38 42 46 47 48 49 51 56 57 58 70 78 80 82 84 86 89 92 93 95 96 97\n","truncated":false}}
%---
%[output:593ea2b8]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 4 13 15 19 23 25 26 27 33 34 38 39 43 46 51 52 54 56 62 70 71 73 75 84 86 87 90 95 96 97\n","truncated":false}}
%---
%[output:24ac3667]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 22 23 24 28 30 31 38 40 41 42 44 46 47 49 51 61 64 65 68 70 71 74 75 78 80 82 86 87 88 90\n","truncated":false}}
%---
%[output:52bdfd93]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 14 15 17 21 25 27 40 41 42 43 44 45 47 48 50 51 54 56 64 72 77 78 79 81 82 86 92 93 94 95\n","truncated":false}}
%---
%[output:0375f615]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR30_RUN06.xlsx\n","truncated":false}}
%---
%[output:66ef5188]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 12 16 18 22 23 24 32 36 38 39 40 41 45 47 54 55 56 57 59 60 65 73 75 81 86 87 88 90 92 94\n","truncated":false}}
%---
%[output:9fa66a23]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 12 19 24 26 29 30 31 35 38 40 43 45 46 48 54 55 56 62 64 65 67 70 72 73 77 81 86 90 94 98\n","truncated":false}}
%---
%[output:44ea0f27]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 5 7 10 14 16 20 25 30 33 37 39 44 46 47 49 53 54 56 58 63 64 69 71 76 79 80 88 89 90 95 96\n","truncated":false}}
%---
%[output:5ff0758c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 8 14 15 17 22 26 28 32 35 38 40 42 43 44 46 49 51 52 53 54 56 66 72 82 87 88 89 90 91 93 95 98\n","truncated":false}}
%---
%[output:5f53fdb2]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR30_RUN07.xlsx\n","truncated":false}}
%---
%[output:55bd7449]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 7 8 14 22 23 26 28 29 30 37 40 41 45 48 51 53 56 61 62 73 76 78 79 81 82 84 86 88 93 94\n","truncated":false}}
%---
%[output:52baf318]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 5 11 13 14 15 18 21 22 28 33 36 37 38 44 50 53 54 58 60 62 65 66 67 69 71 73 83 84 96 98\n","truncated":false}}
%---
%[output:453fccbf]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 12 17 19 20 22 23 25 28 29 31 35 36 41 42 43 51 53 56 57 60 61 62 63 67 75 76 82 84 87 92 96\n","truncated":false}}
%---
%[output:4621e4de]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 4 7 9 10 12 16 21 25 31 36 39 46 47 48 50 57 58 60 62 63 66 71 74 75 76 77 78 80 88 93\n","truncated":false}}
%---
%[output:54f5ae07]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR30_RUN08.xlsx\n","truncated":false}}
%---
