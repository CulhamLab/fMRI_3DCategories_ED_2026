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
disp(conditions) %[output:66a76530]
%%
%[text] ## Create new columns with any combinations that will be used in counterblancing
%[text] e.g., combine "Category" (3 values) and "Task" (2 values) to create "Category x Task" (up to 6 values)
% create: View_x_Category
%   This variable has 6 unique values
conditions = GenericTrialCounterbalancer_CreateComboVariable(condition_table =      conditions, ... %[output:group:876d0d86] %[output:8ed97dba]
                                                             variables_to_combine = ["View" "Category"] ... %[output:8ed97dba]
                                                             ); %[output:group:876d0d86] %[output:8ed97dba]
%[text] Display for verification
disp(conditions) %[output:6bb7a9d2]
%%
%[text] ## Initialize Rule Defaults
% note that first_condition_row is left NaN here, but will be set later for each participant/run
%
% also note that adding a rule but leaving the default constraints will still cause the generation to prioratize balancing that feature
%   e.g., adding a per-half rule but leaving the 0-inf default limits would
%   result in more balanced per-half counts even though there are no strict
%   limits set
rules = GenericTrialCounterbalancer_InitializeRules(condition_table =               conditions, ... %[output:group:935eee73] %[output:8c8d9bb1]
                                                    variables_with_order_rules =    ["View_x_Category"], ... %[output:8c8d9bb1]
                                                    variables_with_perhalf_rules =  ["View_x_Category"], ... %[output:8c8d9bb1]
                                                    first_condition_row =           nan ... % NaN = random first trial %[output:8c8d9bb1]
                                                    ); %[output:group:935eee73] %[output:8c8d9bb1]
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
disp(condition_labels_lookup.View_x_Category) %[output:571d0108]
%[text] Overwrites
% View_x_Category: each combination follows itself exactly twice and follows each other combination 2-3 times per run
rules.order.View_x_Category.min(:) = 2;
rules.order.View_x_Category.max(:) = 3;
rules.order.View_x_Category.max(eye(length(rules.order.View_x_Category.max))==1) = 2; % set diagonal to 2 to limit repeats
%[text] Visualize for verification
value_range = [min(rules.order.View_x_Category.min(:)) max(rules.order.View_x_Category.max(:))];
labels = strrep(condition_labels_lookup.View_x_Category.Label, "_", "\_");
for type = ["Min" "Max"] %[output:group:854e2614]
    figure %[output:55390eb9] %[output:023d549c]
    imagesc(rules.order.View_x_Category.(lower(type))) %[output:55390eb9] %[output:023d549c]
    title(type);
    axis square;
    cb = colorbar;
    clim(value_range); 
    set(cb, Ticks=value_range(1):value_range(end))
    set(gca, XAxisLocation="top", XTick=1:length(rules.order.View_x_Category.min), YTick=1:length(rules.order.View_x_Category.min), YTickLabels=labels, XTickLabels=labels, XTickLabelRotation=30)
end %[output:group:854e2614]
%%
%[text] ## Overwrite the default per-half order rules with desired limits
%[text] Set the limits for the number of times that each variable level may occur in each half of each run.
% Each View_x_Category may occur 6-10 times (out of 16) in each half of each run
rules.perhalfcount.View_x_Category.min = 7;
rules.perhalfcount.View_x_Category.max = 9;
%%
%[text] ## Generate a test order
order = GenericTrialCounterbalancer_GenerateOrder(condition_table = conditions, ... %[output:group:36a7d85c] %[output:0d26fa3a]
                                                  rules =           rules, ... %[output:0d26fa3a]
                                                  repetitions =     reps_per_stim ... %[output:0d26fa3a]
                                                  ); %[output:group:36a7d85c] %[output:0d26fa3a]
%%
%[text] ## (Sanity Check) Verify that any order effect rules were followed in the test order
%[text] Need the matrix order lookups first
[~, condition_labels_lookup] = GenericTrialCounterbalancer_ConvertLabelsToIndices(condition_table = conditions, ...
                                                                                  rules =           rules ...
                                                                                  );
%[text] Verify each rule and display the order effect matrix
% for each order effect rule...
for f = string(fields(rules.order)') %[output:group:2bc6cf34]
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
    fprintf("Order effects table for %s:\n", f); %[output:37e3ff76]
    disp(order_effects) %[output:20a2ef1f]
    imagesc(order_effects); axis square; colorbar; set(gca, XAxisLocation="top"); %[output:10342261]
end %[output:group:2bc6cf34]
%%
%[text] ## (Sanity Check) Verify that any per-half-run count rules were followed in the test order
% how many trials are there?
trials_count = length(order);

% indices of first/second half
trials_midpoint = floor(trials_count / 2);
trials_halves = {1:trials_midpoint , (trials_midpoint+1):trials_count};

% for each per-half count rule...
names = ["First" "Last"];
for f = string(fields(rules.perhalfcount)') %[output:group:63afcc88]
    fprintf("Per-half-run counts for %s (%d-%d):\n", f, rules.perhalfcount.(f).min, rules.perhalfcount.(f).max); %[output:6aec2274]
    for half = 1:2
        % get the variabel levels
        levels = conditions.(f)(order(trials_halves{half}));

        % convert to numeric indices
        levels_IDs = arrayfun(@(x) find(condition_labels_lookup.(f).Label == x), levels);

        % count
        counts = arrayfun(@(x) sum(levels_IDs==x), 1:length(unique(conditions.(f))));

        % display
        fprintf("\t%s Half:\t%s\n", names(half), sprintf("%d ", counts)); %[output:38d6f7c2]

        % check min/max
        if any(counts < rules.perhalfcount.(f).min)
            error("Failed to satisfy rules.perhalfcount.%s.min", f)
        elseif any(counts > rules.perhalfcount.(f).max)
            error("Failed to satisfy rules.perhalfcount.%s.max", f)
        end
    end
end %[output:group:63afcc88]
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
squares = GenerateBalancedSquares(square_size=count, square_count=squares_needed, balance_mode="both", replacement=false); %[output:51a68621]

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
fprintf("Par x Run order of first main conditions:\n"); %[output:4a850fbb]
disp(par_run_first_cond); %[output:688b897f]
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
fprintf("Orders will be written to: %s\n", folder); %[output:5b49398e]
%%
%[text] ## Generate Orders
% use a fixed random number generator seed (1) so that the solution is replicable (unless any values or rules change)
rng(1);

% 
for par = 1:participants_count %[output:group:9f458673]
    fprintf("Participant %d of %d:\n", par, participants_count); %[output:296cc0eb] %[output:6b49dc12] %[output:7b8952a3] %[output:93cd5356] %[output:8d62fcfd] %[output:080c6b01] %[output:6a123b1e] %[output:1b16023a] %[output:93137596] %[output:36ca69c2] %[output:51382c5e] %[output:686b11ad] %[output:2417a6e9] %[output:09d4f68a] %[output:85753cef] %[output:8950383e] %[output:3b09a922] %[output:8b4535a4] %[output:063b34ff] %[output:843450f9] %[output:41b86dcd] %[output:982abd94] %[output:5e574608] %[output:741f549a] %[output:0f8d53ae] %[output:7916dbf2] %[output:833fca4f] %[output:59f8ec4d] %[output:4b76dda2] %[output:12450fbf]
    for run = 1:runs_count
        fprintf("\tRun %d of %d:\n", run, runs_count); %[output:31cb35b6] %[output:4d6774ba] %[output:66342917] %[output:22ba55c3] %[output:94e12901] %[output:4e721f98] %[output:81b23ac1] %[output:89117f25] %[output:781454c6] %[output:761b9583] %[output:3ac63172] %[output:34efbc60] %[output:6bbcc06d] %[output:952a9a63] %[output:818d4cb0] %[output:8ce4dd8a] %[output:543ebb4d] %[output:126b4e8c] %[output:658dc280] %[output:091653ae] %[output:71afaa04] %[output:0e7861b5] %[output:3bd8f542] %[output:32d8391e] %[output:705e7abc] %[output:5fec1c78] %[output:5ba7ad6e] %[output:6be0b0ee] %[output:69c22ea5] %[output:03f1a468] %[output:209a562b] %[output:27f444cf] %[output:84835964] %[output:2c7abcf3] %[output:3d524f89] %[output:9bb752c9] %[output:054ae947] %[output:7ad656c2] %[output:7b4f1678] %[output:5f42d776] %[output:500ea915] %[output:7ca993e4] %[output:574abcab] %[output:98c0aaf4] %[output:2ca8d6f7] %[output:207af2df] %[output:934a4705] %[output:4a701c70] %[output:7a80708f] %[output:735608c8] %[output:630b1bc0] %[output:309fae85] %[output:58f46b2a] %[output:17553d1a] %[output:3380168b] %[output:3421fc87] %[output:79942a55] %[output:30bfef14] %[output:603996f9] %[output:53710f85] %[output:51c9783b] %[output:51579a64] %[output:77448363] %[output:36d6d748] %[output:8e68f2e2] %[output:1fe00075] %[output:138cd657] %[output:3859ae07] %[output:22a1bb61] %[output:180a7b75] %[output:274a00f9] %[output:08455fa5] %[output:4f463106] %[output:9ea77f12] %[output:87aa9b1f] %[output:7b33e19d] %[output:33de0f59] %[output:2047ee71] %[output:76094b64] %[output:7719f595] %[output:832d81fa] %[output:691ef61c] %[output:875b06c5] %[output:435f61bf] %[output:928b7257] %[output:6423451a] %[output:784593cd] %[output:1d3569d5] %[output:8db04d09] %[output:8d6eeef6] %[output:8cb509ec] %[output:09dbe979] %[output:3460895f] %[output:736084e6] %[output:0218bdaf] %[output:28ae6444] %[output:0a9a744e] %[output:65b9deb2] %[output:9bd5ab8f] %[output:36e6494f] %[output:0c11d8c4] %[output:2b235591] %[output:4a69950f] %[output:917f490b] %[output:71c5c9d5] %[output:771418ca] %[output:7e584aa2] %[output:52ddb769] %[output:8447d816] %[output:7bd7bf44] %[output:0d3bff18] %[output:17e3468a] %[output:39929606] %[output:4c47d97e] %[output:465c1efe] %[output:68036b0c] %[output:485f3da9] %[output:531d54f0] %[output:617e93de] %[output:1266aff0] %[output:0a7c899c] %[output:957f8c71] %[output:0f7843e9] %[output:6690a629] %[output:71fe57b4] %[output:75d6af77] %[output:7b2da144] %[output:41e1dbe1] %[output:7613e9ab] %[output:57b7579f] %[output:0b684c97] %[output:17a7e95a] %[output:20f2193f] %[output:08bf2066] %[output:7aa0fa15] %[output:3390f4ce] %[output:8367a995] %[output:8a985156] %[output:41898a8a] %[output:4aa60f17] %[output:634278ae] %[output:8265963c] %[output:78f3348f] %[output:80d7be1c] %[output:75eb7016] %[output:3fb89419] %[output:3a267872] %[output:746a9448] %[output:6bf48875] %[output:160e8452] %[output:62ec9fde] %[output:6646d07d] %[output:8b9b38cd] %[output:20758266] %[output:851b2a7d] %[output:68926865] %[output:3e8a2d57] %[output:0d0d70cf] %[output:14b2b438] %[output:73c7d7c6] %[output:00a34e30] %[output:57b3c13c] %[output:6eb3ecde] %[output:8514605b] %[output:14aedf0f] %[output:77b411eb] %[output:19d17fc8] %[output:4ced56d3] %[output:506086b6] %[output:9a76431d] %[output:970336f0] %[output:72a60886] %[output:1330aaf4] %[output:47e6267e] %[output:5a3fdaaf] %[output:73bc84ad] %[output:0e2ac19f] %[output:9f360604] %[output:2f389876] %[output:5ec50fdd] %[output:895df9ab] %[output:24a8740c] %[output:4a26f662] %[output:0e4ee201] %[output:2174dabe] %[output:37bb7bb1] %[output:67b74023] %[output:0e992f6b] %[output:63c4c299] %[output:697d5abd] %[output:3ed4ca11] %[output:154868f3] %[output:8a8693d4] %[output:42a3a1b5] %[output:4066dadb] %[output:70c3253e] %[output:15d66906] %[output:81bbac54] %[output:72307564] %[output:802d860b] %[output:2fa43489] %[output:7b2bb931] %[output:05f8e4de] %[output:3b74149b] %[output:279af393] %[output:006dc622] %[output:1e1013ef] %[output:260cfae6] %[output:2a29aa48] %[output:1c2cff74] %[output:751bca7c] %[output:564a7c47] %[output:4de9b467] %[output:61080dfc] %[output:53bb0948] %[output:0a9da888] %[output:7c79873e] %[output:68c50c41] %[output:0c9d7265] %[output:2e8b72fd] %[output:84ece5a3] %[output:6ae4bc43] %[output:66a2837d] %[output:2f9718f6] %[output:5021a138] %[output:5f1b0cc9] %[output:039603d1] %[output:695b1229] %[output:9d0546d6] %[output:3ccc1673] %[output:862e02e9] %[output:5df1f4a3] %[output:1090bfc3] %[output:8f671769] %[output:949fa601] %[output:5fb7c387] %[output:2a02280e] %[output:6a8ac409] %[output:959bff54] %[output:1faec969]

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
        trial_order = GenericTrialCounterbalancer_GenerateOrder(condition_table= conditions, ... %[output:6a978c51] %[output:495ed668] %[output:5d79b18b] %[output:2ad3bfa6] %[output:68e22f03] %[output:22d6018c] %[output:18a613e4] %[output:2e916823] %[output:4e6da2c4] %[output:53139cd9] %[output:91d0e64c] %[output:01c1e81d] %[output:5561dd04] %[output:8af33d12] %[output:42adb24e] %[output:0cc17b7b] %[output:4a824dd5] %[output:527eaf56] %[output:5c89f9b9] %[output:638f610a] %[output:9b4cc254] %[output:714110f4] %[output:1934e115] %[output:46cf3306] %[output:1a140c9c] %[output:42d39266] %[output:2995bee0] %[output:23eee78a] %[output:944fa3ca] %[output:4d356723] %[output:74ca0a72] %[output:9d202556] %[output:00ee3e30] %[output:74213ce3] %[output:0e300748] %[output:3df8cda0] %[output:3e780f27] %[output:6bc3419e] %[output:66fc08ed] %[output:2767c64f] %[output:22f0de2c] %[output:019b00a8] %[output:879cca4e] %[output:368150de] %[output:4cbcdb30] %[output:58e09d40] %[output:047a7651] %[output:6a1184cc] %[output:0253f3e7] %[output:3bd55bf6] %[output:071dc71a] %[output:7c708117] %[output:816596e7] %[output:1afecc3a] %[output:513625fc] %[output:2ed9304e] %[output:1cb0052f] %[output:46399b1b] %[output:94053c58] %[output:14b59b3c] %[output:258310c4] %[output:6501adbb] %[output:28047844] %[output:5e101379] %[output:2b8f766c] %[output:3231ca43] %[output:1a0d4727] %[output:1b320bd0] %[output:33d21721] %[output:774a3dc0] %[output:164e7a59] %[output:934fcc47] %[output:2f04b7f6] %[output:9f488873] %[output:8c48330a] %[output:892d6659] %[output:48dbd6a6] %[output:592bb57c] %[output:3ea7ec37] %[output:17b8f7f1] %[output:2b667024] %[output:760c4e97] %[output:971b8fdd] %[output:8cf8ede1] %[output:47b1c4f9] %[output:6e533f0f] %[output:97b2b291] %[output:44c01840] %[output:23e752cf] %[output:66b77e95] %[output:717a270e] %[output:78ced79a] %[output:91a35211] %[output:6cd70103] %[output:3521f915] %[output:1a7d7c1d] %[output:87080f43] %[output:2fc4af36] %[output:9b6d7fae] %[output:4821820d] %[output:86e9b93d] %[output:2d283408] %[output:19d1785d] %[output:78651e75] %[output:4ff688f6] %[output:39e4141f] %[output:5e875e27] %[output:3f420047] %[output:431e2396] %[output:228a2b96] %[output:9e46ae8b] %[output:8cb2da4a] %[output:441fd8a3] %[output:59d939a6] %[output:468ae12c] %[output:45230fb5] %[output:93adff9e] %[output:4df0b406] %[output:66f9148a] %[output:98a9a365] %[output:4f4c872b] %[output:1d4d3413] %[output:6883677f] %[output:881fd128] %[output:72c2e945] %[output:763b73c8] %[output:8f8fd5ad] %[output:81d95673] %[output:571c7e17] %[output:86ae51f9] %[output:0a22ac35] %[output:1c690cd1] %[output:6ff5f10a] %[output:51dede73] %[output:212f97ae] %[output:3a056fd5] %[output:3442f0ac] %[output:798f4e7b] %[output:26576271] %[output:4e64ed14] %[output:43c5572f] %[output:67e093b6] %[output:9db055e8] %[output:82a524dc] %[output:3ccbe344] %[output:87e8f35d] %[output:5dea2cc1] %[output:13e01fc0] %[output:5e2bcbb7] %[output:8bb464a6] %[output:745ee0dd] %[output:5c778e8b] %[output:9a64de15] %[output:00e83291] %[output:03736277] %[output:7265088a] %[output:5df0ad86] %[output:5fc523bd] %[output:97ac8b5f] %[output:397f9b93] %[output:727a8d16] %[output:23cb293b] %[output:93a34d83] %[output:294d1949] %[output:151ebc13] %[output:50e8760f] %[output:015c3e7f] %[output:4ebeb166] %[output:2bd201b9] %[output:744ccfac] %[output:34d7a9af] %[output:022b1ee2] %[output:4cef3f27] %[output:523f8dc7] %[output:9798d36f] %[output:896bcb7e] %[output:145bb15f] %[output:520b3a81] %[output:2c22e474] %[output:219cb43a] %[output:6c0dfdd5] %[output:1f01d362] %[output:6222db44] %[output:2a38be67] %[output:8045a9f8] %[output:617f2bf5] %[output:7d747d8c] %[output:7751d73a] %[output:4384c2ce] %[output:70913744] %[output:362a61ed] %[output:5c49a499] %[output:5f4ce603] %[output:1aebf737] %[output:3e9602cf] %[output:5eeffb0e] %[output:390cb0f1] %[output:152f54ff] %[output:1c568d8a] %[output:0bf38b76] %[output:1d3f9857] %[output:4478a645] %[output:29746942] %[output:5e5afdd0] %[output:1579b812] %[output:2042ae1a] %[output:08f94a4e] %[output:1c78b57a] %[output:3dd498fb] %[output:9548ec22] %[output:613f97a1] %[output:5c0ecd31] %[output:8a308455] %[output:91e9487a] %[output:416adb8c] %[output:3e3337e6] %[output:18e2c003] %[output:62d6ac28] %[output:2411c03f] %[output:5478998b] %[output:3d30479a] %[output:81c481bb] %[output:60ea2d01] %[output:176f5ba7] %[output:8b264771] %[output:40b8f46d] %[output:6b7d6fbc] %[output:82824551] %[output:8eecbd17] %[output:49f3c040] %[output:48fa191b] %[output:6ee0c979] %[output:902c8878] %[output:7176279e] %[output:056262d8] %[output:1a272362] %[output:5826e72d] %[output:03b32715] %[output:8daa754b] %[output:85d1303d]
                                                                rules=           rules, ... %[output:6a978c51] %[output:495ed668] %[output:5d79b18b] %[output:2ad3bfa6] %[output:68e22f03] %[output:22d6018c] %[output:18a613e4] %[output:2e916823] %[output:4e6da2c4] %[output:53139cd9] %[output:91d0e64c] %[output:01c1e81d] %[output:5561dd04] %[output:8af33d12] %[output:42adb24e] %[output:0cc17b7b] %[output:4a824dd5] %[output:527eaf56] %[output:5c89f9b9] %[output:638f610a] %[output:9b4cc254] %[output:714110f4] %[output:1934e115] %[output:46cf3306] %[output:1a140c9c] %[output:42d39266] %[output:2995bee0] %[output:23eee78a] %[output:944fa3ca] %[output:4d356723] %[output:74ca0a72] %[output:9d202556] %[output:00ee3e30] %[output:74213ce3] %[output:0e300748] %[output:3df8cda0] %[output:3e780f27] %[output:6bc3419e] %[output:66fc08ed] %[output:2767c64f] %[output:22f0de2c] %[output:019b00a8] %[output:879cca4e] %[output:368150de] %[output:4cbcdb30] %[output:58e09d40] %[output:047a7651] %[output:6a1184cc] %[output:0253f3e7] %[output:3bd55bf6] %[output:071dc71a] %[output:7c708117] %[output:816596e7] %[output:1afecc3a] %[output:513625fc] %[output:2ed9304e] %[output:1cb0052f] %[output:46399b1b] %[output:94053c58] %[output:14b59b3c] %[output:258310c4] %[output:6501adbb] %[output:28047844] %[output:5e101379] %[output:2b8f766c] %[output:3231ca43] %[output:1a0d4727] %[output:1b320bd0] %[output:33d21721] %[output:774a3dc0] %[output:164e7a59] %[output:934fcc47] %[output:2f04b7f6] %[output:9f488873] %[output:8c48330a] %[output:892d6659] %[output:48dbd6a6] %[output:592bb57c] %[output:3ea7ec37] %[output:17b8f7f1] %[output:2b667024] %[output:760c4e97] %[output:971b8fdd] %[output:8cf8ede1] %[output:47b1c4f9] %[output:6e533f0f] %[output:97b2b291] %[output:44c01840] %[output:23e752cf] %[output:66b77e95] %[output:717a270e] %[output:78ced79a] %[output:91a35211] %[output:6cd70103] %[output:3521f915] %[output:1a7d7c1d] %[output:87080f43] %[output:2fc4af36] %[output:9b6d7fae] %[output:4821820d] %[output:86e9b93d] %[output:2d283408] %[output:19d1785d] %[output:78651e75] %[output:4ff688f6] %[output:39e4141f] %[output:5e875e27] %[output:3f420047] %[output:431e2396] %[output:228a2b96] %[output:9e46ae8b] %[output:8cb2da4a] %[output:441fd8a3] %[output:59d939a6] %[output:468ae12c] %[output:45230fb5] %[output:93adff9e] %[output:4df0b406] %[output:66f9148a] %[output:98a9a365] %[output:4f4c872b] %[output:1d4d3413] %[output:6883677f] %[output:881fd128] %[output:72c2e945] %[output:763b73c8] %[output:8f8fd5ad] %[output:81d95673] %[output:571c7e17] %[output:86ae51f9] %[output:0a22ac35] %[output:1c690cd1] %[output:6ff5f10a] %[output:51dede73] %[output:212f97ae] %[output:3a056fd5] %[output:3442f0ac] %[output:798f4e7b] %[output:26576271] %[output:4e64ed14] %[output:43c5572f] %[output:67e093b6] %[output:9db055e8] %[output:82a524dc] %[output:3ccbe344] %[output:87e8f35d] %[output:5dea2cc1] %[output:13e01fc0] %[output:5e2bcbb7] %[output:8bb464a6] %[output:745ee0dd] %[output:5c778e8b] %[output:9a64de15] %[output:00e83291] %[output:03736277] %[output:7265088a] %[output:5df0ad86] %[output:5fc523bd] %[output:97ac8b5f] %[output:397f9b93] %[output:727a8d16] %[output:23cb293b] %[output:93a34d83] %[output:294d1949] %[output:151ebc13] %[output:50e8760f] %[output:015c3e7f] %[output:4ebeb166] %[output:2bd201b9] %[output:744ccfac] %[output:34d7a9af] %[output:022b1ee2] %[output:4cef3f27] %[output:523f8dc7] %[output:9798d36f] %[output:896bcb7e] %[output:145bb15f] %[output:520b3a81] %[output:2c22e474] %[output:219cb43a] %[output:6c0dfdd5] %[output:1f01d362] %[output:6222db44] %[output:2a38be67] %[output:8045a9f8] %[output:617f2bf5] %[output:7d747d8c] %[output:7751d73a] %[output:4384c2ce] %[output:70913744] %[output:362a61ed] %[output:5c49a499] %[output:5f4ce603] %[output:1aebf737] %[output:3e9602cf] %[output:5eeffb0e] %[output:390cb0f1] %[output:152f54ff] %[output:1c568d8a] %[output:0bf38b76] %[output:1d3f9857] %[output:4478a645] %[output:29746942] %[output:5e5afdd0] %[output:1579b812] %[output:2042ae1a] %[output:08f94a4e] %[output:1c78b57a] %[output:3dd498fb] %[output:9548ec22] %[output:613f97a1] %[output:5c0ecd31] %[output:8a308455] %[output:91e9487a] %[output:416adb8c] %[output:3e3337e6] %[output:18e2c003] %[output:62d6ac28] %[output:2411c03f] %[output:5478998b] %[output:3d30479a] %[output:81c481bb] %[output:60ea2d01] %[output:176f5ba7] %[output:8b264771] %[output:40b8f46d] %[output:6b7d6fbc] %[output:82824551] %[output:8eecbd17] %[output:49f3c040] %[output:48fa191b] %[output:6ee0c979] %[output:902c8878] %[output:7176279e] %[output:056262d8] %[output:1a272362] %[output:5826e72d] %[output:03b32715] %[output:8daa754b] %[output:85d1303d]
                                                                repetitions=     reps_per_stim, ... %[output:6a978c51] %[output:495ed668] %[output:5d79b18b] %[output:2ad3bfa6] %[output:68e22f03] %[output:22d6018c] %[output:18a613e4] %[output:2e916823] %[output:4e6da2c4] %[output:53139cd9] %[output:91d0e64c] %[output:01c1e81d] %[output:5561dd04] %[output:8af33d12] %[output:42adb24e] %[output:0cc17b7b] %[output:4a824dd5] %[output:527eaf56] %[output:5c89f9b9] %[output:638f610a] %[output:9b4cc254] %[output:714110f4] %[output:1934e115] %[output:46cf3306] %[output:1a140c9c] %[output:42d39266] %[output:2995bee0] %[output:23eee78a] %[output:944fa3ca] %[output:4d356723] %[output:74ca0a72] %[output:9d202556] %[output:00ee3e30] %[output:74213ce3] %[output:0e300748] %[output:3df8cda0] %[output:3e780f27] %[output:6bc3419e] %[output:66fc08ed] %[output:2767c64f] %[output:22f0de2c] %[output:019b00a8] %[output:879cca4e] %[output:368150de] %[output:4cbcdb30] %[output:58e09d40] %[output:047a7651] %[output:6a1184cc] %[output:0253f3e7] %[output:3bd55bf6] %[output:071dc71a] %[output:7c708117] %[output:816596e7] %[output:1afecc3a] %[output:513625fc] %[output:2ed9304e] %[output:1cb0052f] %[output:46399b1b] %[output:94053c58] %[output:14b59b3c] %[output:258310c4] %[output:6501adbb] %[output:28047844] %[output:5e101379] %[output:2b8f766c] %[output:3231ca43] %[output:1a0d4727] %[output:1b320bd0] %[output:33d21721] %[output:774a3dc0] %[output:164e7a59] %[output:934fcc47] %[output:2f04b7f6] %[output:9f488873] %[output:8c48330a] %[output:892d6659] %[output:48dbd6a6] %[output:592bb57c] %[output:3ea7ec37] %[output:17b8f7f1] %[output:2b667024] %[output:760c4e97] %[output:971b8fdd] %[output:8cf8ede1] %[output:47b1c4f9] %[output:6e533f0f] %[output:97b2b291] %[output:44c01840] %[output:23e752cf] %[output:66b77e95] %[output:717a270e] %[output:78ced79a] %[output:91a35211] %[output:6cd70103] %[output:3521f915] %[output:1a7d7c1d] %[output:87080f43] %[output:2fc4af36] %[output:9b6d7fae] %[output:4821820d] %[output:86e9b93d] %[output:2d283408] %[output:19d1785d] %[output:78651e75] %[output:4ff688f6] %[output:39e4141f] %[output:5e875e27] %[output:3f420047] %[output:431e2396] %[output:228a2b96] %[output:9e46ae8b] %[output:8cb2da4a] %[output:441fd8a3] %[output:59d939a6] %[output:468ae12c] %[output:45230fb5] %[output:93adff9e] %[output:4df0b406] %[output:66f9148a] %[output:98a9a365] %[output:4f4c872b] %[output:1d4d3413] %[output:6883677f] %[output:881fd128] %[output:72c2e945] %[output:763b73c8] %[output:8f8fd5ad] %[output:81d95673] %[output:571c7e17] %[output:86ae51f9] %[output:0a22ac35] %[output:1c690cd1] %[output:6ff5f10a] %[output:51dede73] %[output:212f97ae] %[output:3a056fd5] %[output:3442f0ac] %[output:798f4e7b] %[output:26576271] %[output:4e64ed14] %[output:43c5572f] %[output:67e093b6] %[output:9db055e8] %[output:82a524dc] %[output:3ccbe344] %[output:87e8f35d] %[output:5dea2cc1] %[output:13e01fc0] %[output:5e2bcbb7] %[output:8bb464a6] %[output:745ee0dd] %[output:5c778e8b] %[output:9a64de15] %[output:00e83291] %[output:03736277] %[output:7265088a] %[output:5df0ad86] %[output:5fc523bd] %[output:97ac8b5f] %[output:397f9b93] %[output:727a8d16] %[output:23cb293b] %[output:93a34d83] %[output:294d1949] %[output:151ebc13] %[output:50e8760f] %[output:015c3e7f] %[output:4ebeb166] %[output:2bd201b9] %[output:744ccfac] %[output:34d7a9af] %[output:022b1ee2] %[output:4cef3f27] %[output:523f8dc7] %[output:9798d36f] %[output:896bcb7e] %[output:145bb15f] %[output:520b3a81] %[output:2c22e474] %[output:219cb43a] %[output:6c0dfdd5] %[output:1f01d362] %[output:6222db44] %[output:2a38be67] %[output:8045a9f8] %[output:617f2bf5] %[output:7d747d8c] %[output:7751d73a] %[output:4384c2ce] %[output:70913744] %[output:362a61ed] %[output:5c49a499] %[output:5f4ce603] %[output:1aebf737] %[output:3e9602cf] %[output:5eeffb0e] %[output:390cb0f1] %[output:152f54ff] %[output:1c568d8a] %[output:0bf38b76] %[output:1d3f9857] %[output:4478a645] %[output:29746942] %[output:5e5afdd0] %[output:1579b812] %[output:2042ae1a] %[output:08f94a4e] %[output:1c78b57a] %[output:3dd498fb] %[output:9548ec22] %[output:613f97a1] %[output:5c0ecd31] %[output:8a308455] %[output:91e9487a] %[output:416adb8c] %[output:3e3337e6] %[output:18e2c003] %[output:62d6ac28] %[output:2411c03f] %[output:5478998b] %[output:3d30479a] %[output:81c481bb] %[output:60ea2d01] %[output:176f5ba7] %[output:8b264771] %[output:40b8f46d] %[output:6b7d6fbc] %[output:82824551] %[output:8eecbd17] %[output:49f3c040] %[output:48fa191b] %[output:6ee0c979] %[output:902c8878] %[output:7176279e] %[output:056262d8] %[output:1a272362] %[output:5826e72d] %[output:03b32715] %[output:8daa754b] %[output:85d1303d]
                                                                fprintf_prefix=  sprintf("\t\t") ... %[output:6a978c51] %[output:495ed668] %[output:5d79b18b] %[output:2ad3bfa6] %[output:68e22f03] %[output:22d6018c] %[output:18a613e4] %[output:2e916823] %[output:4e6da2c4] %[output:53139cd9] %[output:91d0e64c] %[output:01c1e81d] %[output:5561dd04] %[output:8af33d12] %[output:42adb24e] %[output:0cc17b7b] %[output:4a824dd5] %[output:527eaf56] %[output:5c89f9b9] %[output:638f610a] %[output:9b4cc254] %[output:714110f4] %[output:1934e115] %[output:46cf3306] %[output:1a140c9c] %[output:42d39266] %[output:2995bee0] %[output:23eee78a] %[output:944fa3ca] %[output:4d356723] %[output:74ca0a72] %[output:9d202556] %[output:00ee3e30] %[output:74213ce3] %[output:0e300748] %[output:3df8cda0] %[output:3e780f27] %[output:6bc3419e] %[output:66fc08ed] %[output:2767c64f] %[output:22f0de2c] %[output:019b00a8] %[output:879cca4e] %[output:368150de] %[output:4cbcdb30] %[output:58e09d40] %[output:047a7651] %[output:6a1184cc] %[output:0253f3e7] %[output:3bd55bf6] %[output:071dc71a] %[output:7c708117] %[output:816596e7] %[output:1afecc3a] %[output:513625fc] %[output:2ed9304e] %[output:1cb0052f] %[output:46399b1b] %[output:94053c58] %[output:14b59b3c] %[output:258310c4] %[output:6501adbb] %[output:28047844] %[output:5e101379] %[output:2b8f766c] %[output:3231ca43] %[output:1a0d4727] %[output:1b320bd0] %[output:33d21721] %[output:774a3dc0] %[output:164e7a59] %[output:934fcc47] %[output:2f04b7f6] %[output:9f488873] %[output:8c48330a] %[output:892d6659] %[output:48dbd6a6] %[output:592bb57c] %[output:3ea7ec37] %[output:17b8f7f1] %[output:2b667024] %[output:760c4e97] %[output:971b8fdd] %[output:8cf8ede1] %[output:47b1c4f9] %[output:6e533f0f] %[output:97b2b291] %[output:44c01840] %[output:23e752cf] %[output:66b77e95] %[output:717a270e] %[output:78ced79a] %[output:91a35211] %[output:6cd70103] %[output:3521f915] %[output:1a7d7c1d] %[output:87080f43] %[output:2fc4af36] %[output:9b6d7fae] %[output:4821820d] %[output:86e9b93d] %[output:2d283408] %[output:19d1785d] %[output:78651e75] %[output:4ff688f6] %[output:39e4141f] %[output:5e875e27] %[output:3f420047] %[output:431e2396] %[output:228a2b96] %[output:9e46ae8b] %[output:8cb2da4a] %[output:441fd8a3] %[output:59d939a6] %[output:468ae12c] %[output:45230fb5] %[output:93adff9e] %[output:4df0b406] %[output:66f9148a] %[output:98a9a365] %[output:4f4c872b] %[output:1d4d3413] %[output:6883677f] %[output:881fd128] %[output:72c2e945] %[output:763b73c8] %[output:8f8fd5ad] %[output:81d95673] %[output:571c7e17] %[output:86ae51f9] %[output:0a22ac35] %[output:1c690cd1] %[output:6ff5f10a] %[output:51dede73] %[output:212f97ae] %[output:3a056fd5] %[output:3442f0ac] %[output:798f4e7b] %[output:26576271] %[output:4e64ed14] %[output:43c5572f] %[output:67e093b6] %[output:9db055e8] %[output:82a524dc] %[output:3ccbe344] %[output:87e8f35d] %[output:5dea2cc1] %[output:13e01fc0] %[output:5e2bcbb7] %[output:8bb464a6] %[output:745ee0dd] %[output:5c778e8b] %[output:9a64de15] %[output:00e83291] %[output:03736277] %[output:7265088a] %[output:5df0ad86] %[output:5fc523bd] %[output:97ac8b5f] %[output:397f9b93] %[output:727a8d16] %[output:23cb293b] %[output:93a34d83] %[output:294d1949] %[output:151ebc13] %[output:50e8760f] %[output:015c3e7f] %[output:4ebeb166] %[output:2bd201b9] %[output:744ccfac] %[output:34d7a9af] %[output:022b1ee2] %[output:4cef3f27] %[output:523f8dc7] %[output:9798d36f] %[output:896bcb7e] %[output:145bb15f] %[output:520b3a81] %[output:2c22e474] %[output:219cb43a] %[output:6c0dfdd5] %[output:1f01d362] %[output:6222db44] %[output:2a38be67] %[output:8045a9f8] %[output:617f2bf5] %[output:7d747d8c] %[output:7751d73a] %[output:4384c2ce] %[output:70913744] %[output:362a61ed] %[output:5c49a499] %[output:5f4ce603] %[output:1aebf737] %[output:3e9602cf] %[output:5eeffb0e] %[output:390cb0f1] %[output:152f54ff] %[output:1c568d8a] %[output:0bf38b76] %[output:1d3f9857] %[output:4478a645] %[output:29746942] %[output:5e5afdd0] %[output:1579b812] %[output:2042ae1a] %[output:08f94a4e] %[output:1c78b57a] %[output:3dd498fb] %[output:9548ec22] %[output:613f97a1] %[output:5c0ecd31] %[output:8a308455] %[output:91e9487a] %[output:416adb8c] %[output:3e3337e6] %[output:18e2c003] %[output:62d6ac28] %[output:2411c03f] %[output:5478998b] %[output:3d30479a] %[output:81c481bb] %[output:60ea2d01] %[output:176f5ba7] %[output:8b264771] %[output:40b8f46d] %[output:6b7d6fbc] %[output:82824551] %[output:8eecbd17] %[output:49f3c040] %[output:48fa191b] %[output:6ee0c979] %[output:902c8878] %[output:7176279e] %[output:056262d8] %[output:1a272362] %[output:5826e72d] %[output:03b32715] %[output:8daa754b] %[output:85d1303d]
                                                                ); %[output:6a978c51] %[output:495ed668] %[output:5d79b18b] %[output:2ad3bfa6] %[output:68e22f03] %[output:22d6018c] %[output:18a613e4] %[output:2e916823] %[output:4e6da2c4] %[output:53139cd9] %[output:91d0e64c] %[output:01c1e81d] %[output:5561dd04] %[output:8af33d12] %[output:42adb24e] %[output:0cc17b7b] %[output:4a824dd5] %[output:527eaf56] %[output:5c89f9b9] %[output:638f610a] %[output:9b4cc254] %[output:714110f4] %[output:1934e115] %[output:46cf3306] %[output:1a140c9c] %[output:42d39266] %[output:2995bee0] %[output:23eee78a] %[output:944fa3ca] %[output:4d356723] %[output:74ca0a72] %[output:9d202556] %[output:00ee3e30] %[output:74213ce3] %[output:0e300748] %[output:3df8cda0] %[output:3e780f27] %[output:6bc3419e] %[output:66fc08ed] %[output:2767c64f] %[output:22f0de2c] %[output:019b00a8] %[output:879cca4e] %[output:368150de] %[output:4cbcdb30] %[output:58e09d40] %[output:047a7651] %[output:6a1184cc] %[output:0253f3e7] %[output:3bd55bf6] %[output:071dc71a] %[output:7c708117] %[output:816596e7] %[output:1afecc3a] %[output:513625fc] %[output:2ed9304e] %[output:1cb0052f] %[output:46399b1b] %[output:94053c58] %[output:14b59b3c] %[output:258310c4] %[output:6501adbb] %[output:28047844] %[output:5e101379] %[output:2b8f766c] %[output:3231ca43] %[output:1a0d4727] %[output:1b320bd0] %[output:33d21721] %[output:774a3dc0] %[output:164e7a59] %[output:934fcc47] %[output:2f04b7f6] %[output:9f488873] %[output:8c48330a] %[output:892d6659] %[output:48dbd6a6] %[output:592bb57c] %[output:3ea7ec37] %[output:17b8f7f1] %[output:2b667024] %[output:760c4e97] %[output:971b8fdd] %[output:8cf8ede1] %[output:47b1c4f9] %[output:6e533f0f] %[output:97b2b291] %[output:44c01840] %[output:23e752cf] %[output:66b77e95] %[output:717a270e] %[output:78ced79a] %[output:91a35211] %[output:6cd70103] %[output:3521f915] %[output:1a7d7c1d] %[output:87080f43] %[output:2fc4af36] %[output:9b6d7fae] %[output:4821820d] %[output:86e9b93d] %[output:2d283408] %[output:19d1785d] %[output:78651e75] %[output:4ff688f6] %[output:39e4141f] %[output:5e875e27] %[output:3f420047] %[output:431e2396] %[output:228a2b96] %[output:9e46ae8b] %[output:8cb2da4a] %[output:441fd8a3] %[output:59d939a6] %[output:468ae12c] %[output:45230fb5] %[output:93adff9e] %[output:4df0b406] %[output:66f9148a] %[output:98a9a365] %[output:4f4c872b] %[output:1d4d3413] %[output:6883677f] %[output:881fd128] %[output:72c2e945] %[output:763b73c8] %[output:8f8fd5ad] %[output:81d95673] %[output:571c7e17] %[output:86ae51f9] %[output:0a22ac35] %[output:1c690cd1] %[output:6ff5f10a] %[output:51dede73] %[output:212f97ae] %[output:3a056fd5] %[output:3442f0ac] %[output:798f4e7b] %[output:26576271] %[output:4e64ed14] %[output:43c5572f] %[output:67e093b6] %[output:9db055e8] %[output:82a524dc] %[output:3ccbe344] %[output:87e8f35d] %[output:5dea2cc1] %[output:13e01fc0] %[output:5e2bcbb7] %[output:8bb464a6] %[output:745ee0dd] %[output:5c778e8b] %[output:9a64de15] %[output:00e83291] %[output:03736277] %[output:7265088a] %[output:5df0ad86] %[output:5fc523bd] %[output:97ac8b5f] %[output:397f9b93] %[output:727a8d16] %[output:23cb293b] %[output:93a34d83] %[output:294d1949] %[output:151ebc13] %[output:50e8760f] %[output:015c3e7f] %[output:4ebeb166] %[output:2bd201b9] %[output:744ccfac] %[output:34d7a9af] %[output:022b1ee2] %[output:4cef3f27] %[output:523f8dc7] %[output:9798d36f] %[output:896bcb7e] %[output:145bb15f] %[output:520b3a81] %[output:2c22e474] %[output:219cb43a] %[output:6c0dfdd5] %[output:1f01d362] %[output:6222db44] %[output:2a38be67] %[output:8045a9f8] %[output:617f2bf5] %[output:7d747d8c] %[output:7751d73a] %[output:4384c2ce] %[output:70913744] %[output:362a61ed] %[output:5c49a499] %[output:5f4ce603] %[output:1aebf737] %[output:3e9602cf] %[output:5eeffb0e] %[output:390cb0f1] %[output:152f54ff] %[output:1c568d8a] %[output:0bf38b76] %[output:1d3f9857] %[output:4478a645] %[output:29746942] %[output:5e5afdd0] %[output:1579b812] %[output:2042ae1a] %[output:08f94a4e] %[output:1c78b57a] %[output:3dd498fb] %[output:9548ec22] %[output:613f97a1] %[output:5c0ecd31] %[output:8a308455] %[output:91e9487a] %[output:416adb8c] %[output:3e3337e6] %[output:18e2c003] %[output:62d6ac28] %[output:2411c03f] %[output:5478998b] %[output:3d30479a] %[output:81c481bb] %[output:60ea2d01] %[output:176f5ba7] %[output:8b264771] %[output:40b8f46d] %[output:6b7d6fbc] %[output:82824551] %[output:8eecbd17] %[output:49f3c040] %[output:48fa191b] %[output:6ee0c979] %[output:902c8878] %[output:7176279e] %[output:056262d8] %[output:1a272362] %[output:5826e72d] %[output:03b32715] %[output:8daa754b] %[output:85d1303d]
        
        % add a one-back trial in each half with at least 5 trials between them
        trials_count = length(trial_order);
        midpoint = floor(trials_count/2);
        while 1
            inds_one_back = [randperm(midpoint, 1) (randperm(trials_count-midpoint, 1) + midpoint)];
            if diff(inds_one_back) >= 5
                break
            end
        end
        fprintf("\t\tAdding one-backs to trial IDs [%s] at positions [%s]\n", strjoin(string(trial_order(inds_one_back)), " "), strjoin(string(inds_one_back), " ")); %[output:6fd971bf] %[output:903ea019] %[output:449b690b] %[output:5b733e83] %[output:63ed7d6f] %[output:262045be] %[output:943fd53a] %[output:8733a8e7] %[output:666bdc87] %[output:232832f7] %[output:9e0b1457] %[output:934faa69] %[output:95d7e1b3] %[output:89bef8d8] %[output:4acaff30] %[output:6dc98897] %[output:7b5a15e9] %[output:8a4ce55e] %[output:7e3ab7e4] %[output:9a99e159] %[output:29bcc280] %[output:6e343b65] %[output:8f217fb9] %[output:44ed6682] %[output:17ed8437] %[output:79aed29c] %[output:32fd1040] %[output:07469782] %[output:25e561d4] %[output:54949757] %[output:1639b750] %[output:16596e5c] %[output:6678329b] %[output:68ae506d] %[output:6d4e819f] %[output:9a9a2994] %[output:1fa1a22c] %[output:7d928979] %[output:7f80cf18] %[output:964ab779] %[output:0cefbb85] %[output:8936a88d] %[output:3a2b47e8] %[output:83c5c0b7] %[output:81afb150] %[output:7182d51c] %[output:18ea7daf] %[output:862a40aa] %[output:5f478957] %[output:6975a7be] %[output:94b4626e] %[output:18557d28] %[output:721f0c81] %[output:0ccd224c] %[output:0cc292e2] %[output:76fe0e61] %[output:7f318b1e] %[output:5a7313f4] %[output:5500eb5a] %[output:6ad80354] %[output:2ab4222a] %[output:1a42e6b0] %[output:9fc03f26] %[output:7d8efffa] %[output:0caaf63f] %[output:6809c838] %[output:815be192] %[output:228486c2] %[output:3ef30e83] %[output:2e830268] %[output:973ef3cc] %[output:1a37c40a] %[output:33d5830f] %[output:11415595] %[output:062324f2] %[output:45bd308a] %[output:220a9851] %[output:08370caf] %[output:86453936] %[output:0646fdb4] %[output:81f92489] %[output:4bd534b9] %[output:9fde54a9] %[output:26baf9f7] %[output:9113c03b] %[output:39d5a83b] %[output:831b7083] %[output:11a47c16] %[output:54ed6939] %[output:03e653e8] %[output:65f12034] %[output:7d501015] %[output:08109221] %[output:21ed196f] %[output:9288c77e] %[output:59bbd9e1] %[output:11d778ef] %[output:7cadf096] %[output:1c93c2a9] %[output:19fedd29] %[output:584e15f3] %[output:92ccf368] %[output:14f574e5] %[output:224821d6] %[output:3f3170c0] %[output:592cec04] %[output:07c40b4c] %[output:2d96f713] %[output:60bb5a8b] %[output:31ec04c9] %[output:2422faf7] %[output:024d53e8] %[output:5a909d9f] %[output:3c0c62ce] %[output:4e7b695c] %[output:35e129f9] %[output:7925b64d] %[output:991ced32] %[output:27104058] %[output:5d8ab670] %[output:63847d78] %[output:8f24885f] %[output:3ef6c630] %[output:02be6799] %[output:793ecb67] %[output:4a15ff5d] %[output:06891ac4] %[output:1f397c4b] %[output:1e6289d6] %[output:99f3ea28] %[output:31342a51] %[output:3de7e736] %[output:9d770a67] %[output:764041e5] %[output:6a6994ff] %[output:560aef4b] %[output:7ebdac6d] %[output:4a6b616c] %[output:55c4f47e] %[output:021d9044] %[output:072bb2e4] %[output:26c4feaf] %[output:9f995116] %[output:89277687] %[output:77493602] %[output:39b7adb2] %[output:681d5ac8] %[output:6014f28b] %[output:29e03f78] %[output:6fa5cbe9] %[output:5b8c3b6b] %[output:8647131c] %[output:6a057bf5] %[output:7936b521] %[output:9daf1aab] %[output:311fd145] %[output:389c1b26] %[output:8ee5f399] %[output:845efdd7] %[output:758235a3] %[output:20d967f8] %[output:0e75979d] %[output:2f14c377] %[output:7fcecd28] %[output:5c85e160] %[output:3c5c19e0] %[output:5d7808a1] %[output:0e6a64ad] %[output:3ffc0c5b] %[output:86e455b6] %[output:8ffbda3b] %[output:561df6c4] %[output:6841a973] %[output:343f9b4b] %[output:1b866a9b] %[output:8ad21da4] %[output:0418f2f3] %[output:5da2e3dc] %[output:86c0b5c8] %[output:8c7fe4d2] %[output:217f1101] %[output:509e0579] %[output:6307f7d0] %[output:9c3115c3] %[output:7350c65b] %[output:0a08da8a] %[output:7ee49f49] %[output:97b56e26] %[output:5eb77b80] %[output:8b394255] %[output:61800af2] %[output:987744e6] %[output:05ebe822] %[output:7f87ff25] %[output:9f1291cd] %[output:99c59933] %[output:7658282e] %[output:169c65b5] %[output:74a685af] %[output:71524949] %[output:3e725bea] %[output:82797f4f] %[output:0f4484bd] %[output:7a935446] %[output:5251acc7] %[output:2f2187cd] %[output:48dd5fd0] %[output:30fb632e] %[output:4958625a] %[output:9bfef1dd] %[output:47ffe59d] %[output:5d179576] %[output:4e337ea0] %[output:700ef14b] %[output:4b401f57] %[output:6e9687c3] %[output:98a3b4cf] %[output:39a2366d] %[output:4dde631d] %[output:66626815] %[output:3f2fc30b] %[output:0f06c21e] %[output:455fc904] %[output:3d6d135e] %[output:33fd0221] %[output:9dee2582] %[output:03c3340a] %[output:8badb5ab] %[output:9bb51d90] %[output:52608acb] %[output:282bdefc] %[output:451f9871] %[output:4bcf7f95] %[output:777183c5] %[output:56f16443] %[output:7d38b205] %[output:578f397f] %[output:950983c2] %[output:16d3355c] %[output:0590dd82]
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
        fprintf("\t\t%d long ITIs in trials: %s\n", length(inds_long_ITI), strjoin(string(inds_long_ITI), " ")); %[output:5fb0cad6] %[output:92ed4683] %[output:4bac2713] %[output:4297aac7] %[output:969eac69] %[output:612471b8] %[output:5b3fa52f] %[output:5a5c74eb] %[output:1df78162] %[output:6317dec1] %[output:0977d3fd] %[output:579a8079] %[output:72c98474] %[output:2ee1e6e9] %[output:4ed2c230] %[output:3624d6cb] %[output:45269f42] %[output:2e0ca428] %[output:7854d222] %[output:2231aaa2] %[output:16498011] %[output:3a99122f] %[output:06d94548] %[output:3c6a1618] %[output:7dd740ed] %[output:96c4ee01] %[output:2828ec03] %[output:9f73acbc] %[output:931b673a] %[output:69bc56b1] %[output:3f08f26a] %[output:4b251e22] %[output:9e93d3b5] %[output:2f14d2d4] %[output:15b7274f] %[output:520f8b63] %[output:5e5a51b5] %[output:5783d4f8] %[output:5ab805e1] %[output:4ddd256b] %[output:5c11e99c] %[output:59eb84e7] %[output:05da3127] %[output:1f206bd6] %[output:5e5025e6] %[output:4ccd77e1] %[output:5d3f439c] %[output:8f14c064] %[output:52d23cfe] %[output:1f11212a] %[output:066844ee] %[output:5e95ef7b] %[output:85ba84f6] %[output:27406aab] %[output:3c9390b7] %[output:30be5b86] %[output:9149c6bc] %[output:67db0374] %[output:36942f54] %[output:6426f56e] %[output:303adf98] %[output:8f587277] %[output:003e3dc3] %[output:2a2a2cb4] %[output:4d012b67] %[output:131b4338] %[output:16ad0ac2] %[output:7be5c549] %[output:77a152c2] %[output:214da4ae] %[output:317c4d21] %[output:4f7b1a7e] %[output:92962004] %[output:0ac53be0] %[output:38ca65df] %[output:162dfa3e] %[output:161e221f] %[output:08094887] %[output:69d0ea69] %[output:6f7b6fb4] %[output:2c642956] %[output:79452e79] %[output:4e5a5d28] %[output:2a531cb6] %[output:14b74e84] %[output:938cf0cc] %[output:5914049c] %[output:5d26477b] %[output:5143d7f7] %[output:7046065e] %[output:2715eb17] %[output:28b1ece0] %[output:58195e5c] %[output:99e5e036] %[output:14ad099d] %[output:87898500] %[output:7974dca0] %[output:557a25a5] %[output:8652ff07] %[output:9a82af65] %[output:6536fcc6] %[output:8e61d0b0] %[output:5f4ae297] %[output:64e14235] %[output:0c8367e9] %[output:1dcd4d9d] %[output:85b8f6f6] %[output:76e45413] %[output:73eb7ccc] %[output:1cbf3bb8] %[output:7b9fb038] %[output:614a56ad] %[output:02ae211c] %[output:9c76edbe] %[output:3c5b3858] %[output:23dbc624] %[output:08d6ab47] %[output:42f2549c] %[output:34c7648a] %[output:67c4b00d] %[output:05c80137] %[output:4ec476aa] %[output:48f267db] %[output:1aac594e] %[output:9a8a6856] %[output:1405208b] %[output:9945c8fa] %[output:3f3e5bcd] %[output:9f4298ac] %[output:0934a093] %[output:731d59bc] %[output:967da5af] %[output:8e1bd4c5] %[output:7b3862c3] %[output:044c470b] %[output:433c0add] %[output:1b0bab78] %[output:5bf9c31a] %[output:1192dccc] %[output:6c1cee3b] %[output:93918562] %[output:18a3dcef] %[output:05cac88e] %[output:011becf5] %[output:02b16632] %[output:59fd97d4] %[output:83edc7ac] %[output:2403def5] %[output:01c77c83] %[output:322c8f82] %[output:6d1c62f8] %[output:3b2b147d] %[output:8dc1547d] %[output:7132d4c6] %[output:2850597f] %[output:741177f8] %[output:493ee00d] %[output:7fe77147] %[output:99505fab] %[output:395800dd] %[output:6752f3dc] %[output:68a63506] %[output:55143ee2] %[output:0ef2614c] %[output:743c1fad] %[output:11a614a2] %[output:0538cc5f] %[output:1d72fc5c] %[output:29aa52f2] %[output:563aad98] %[output:8851b8af] %[output:7ede8201] %[output:3953c9ca] %[output:4a9ae3f8] %[output:37bbc835] %[output:4f080534] %[output:4d0f8757] %[output:4d793569] %[output:736e3031] %[output:73dff5f6] %[output:3c6abeee] %[output:2329de2f] %[output:4fa711e2] %[output:4f1fc43f] %[output:78ba2692] %[output:6d515bcd] %[output:61bdc661] %[output:82c9a328] %[output:1c350f04] %[output:27c83d0a] %[output:08ec14d7] %[output:510848bd] %[output:019d5209] %[output:15736e66] %[output:2c1086b4] %[output:64e636ca] %[output:023ef480] %[output:4b3fad25] %[output:6dce8a41] %[output:73f03dd0] %[output:44b8601d] %[output:8964defe] %[output:90994214] %[output:825e00df] %[output:455b6380] %[output:53250244] %[output:01070f80] %[output:00355052] %[output:65da2a7d] %[output:212ede18] %[output:108c2927] %[output:4ae3d9b3] %[output:4c956ef0] %[output:8e18b6ac] %[output:432b34e4] %[output:09ee1325] %[output:07dcc844] %[output:45a7256b] %[output:1bf42c8f] %[output:89cfc7b7] %[output:8214d577] %[output:0f3696c3] %[output:40f65152] %[output:0be0f01d] %[output:42ae261b] %[output:939528c9] %[output:99ad001d] %[output:0082a0b2] %[output:5698cf30] %[output:0bc05339] %[output:8ee8bbff] %[output:9a46f998] %[output:7e3d9392] %[output:50108132] %[output:8f116c45] %[output:36ab1ad7] %[output:1df62069] %[output:4e89f3e0] %[output:9d703f1f] %[output:9c2f18c4]

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
        fprintf("\t\tWriting: %s\n", filepath); %[output:87bb215c] %[output:07cf1438] %[output:5eb00fe0] %[output:0127a708] %[output:9f2c9167] %[output:52061ae8] %[output:1d50dff5] %[output:345e7aa3] %[output:008f2423] %[output:6792395b] %[output:1788784c] %[output:65cb2c22] %[output:44c8fcdf] %[output:19763ab0] %[output:2094909e] %[output:16be5d4d] %[output:1af7cae1] %[output:9c473ec7] %[output:13a6ccdb] %[output:2533c265] %[output:675ac97d] %[output:894d1895] %[output:7f775347] %[output:81b1300e] %[output:8e908a3e] %[output:96d1dd8a] %[output:679d6851] %[output:5d6991ce] %[output:85d2720f] %[output:592f0d55] %[output:6d92a788] %[output:0f37069f] %[output:472b1fc6] %[output:64a38e7b] %[output:2512385d] %[output:7a002e97] %[output:1391fda4] %[output:78f42eed] %[output:34033383] %[output:28225f96] %[output:4f3dda26] %[output:708586be] %[output:458165d9] %[output:05c586b3] %[output:2839f385] %[output:2c137f68] %[output:9471aa8a] %[output:5c100483] %[output:2daab74c] %[output:77e338b7] %[output:28745c64] %[output:6363ba49] %[output:39d5893b] %[output:0a3161dc] %[output:3c8b2780] %[output:19c685fb] %[output:47138589] %[output:16471c72] %[output:7dd658bc] %[output:1ebe6296] %[output:63067ab5] %[output:8bb37bf8] %[output:0281cffb] %[output:264191a5] %[output:681daafe] %[output:3145b76b] %[output:12e62604] %[output:0cbbe4b5] %[output:30095f65] %[output:0666a02c] %[output:0cbd67d1] %[output:68dc172f] %[output:7688c73e] %[output:559ed069] %[output:4f0a0547] %[output:00db80e1] %[output:7b4fa15c] %[output:478b74a3] %[output:71e35c8e] %[output:0d925e9a] %[output:7396ecae] %[output:9f6fb1ae] %[output:4de3c6eb] %[output:7782d5da] %[output:3537df15] %[output:41e8c1af] %[output:6d67406a] %[output:2fad697e] %[output:8b739919] %[output:5e8915e3] %[output:22f33665] %[output:8c4b4f73] %[output:27c300f3] %[output:78b275f9] %[output:9fc3e12c] %[output:64b450d7] %[output:0fd5d5ec] %[output:20661c80] %[output:96d4d2a2] %[output:612abbe6] %[output:3fef8c52] %[output:0a7d5db4] %[output:939b7b1c] %[output:3caa1c27] %[output:32aecbfc] %[output:9f0249ea] %[output:8b1049e6] %[output:220f1e2f] %[output:2c966164] %[output:076de3b2] %[output:609d0fc6] %[output:158ade42] %[output:357e835b] %[output:2a0b5764] %[output:63c28503] %[output:3391b9bc] %[output:2972375e] %[output:1ac15f08] %[output:97059421] %[output:35c5bd71] %[output:9f434574] %[output:29391088] %[output:85f28cc4] %[output:5dccb247] %[output:3c5c23e8] %[output:60798b3d] %[output:069e0a53] %[output:1445b1dd] %[output:17586476] %[output:0574f0a0] %[output:02908a7e] %[output:0c0809b7] %[output:048024d0] %[output:250cfa78] %[output:4221e1b6] %[output:00192416] %[output:6bee1e66] %[output:5e0dc925] %[output:9ba9a1f9] %[output:4e116795] %[output:6696fafe] %[output:8aedef7e] %[output:19f285be] %[output:3fe6d99d] %[output:8fc56479] %[output:2247e620] %[output:9710a3bd] %[output:79c6b5d0] %[output:31e2abd1] %[output:7a31a852] %[output:601c83aa] %[output:2f6744c0] %[output:80768500] %[output:118ca73c] %[output:8de49675] %[output:9566b30a] %[output:97e1e295] %[output:75dae226] %[output:38fede05] %[output:0e5fd41f] %[output:557db4fc] %[output:57ed2291] %[output:79d260d8] %[output:2ddc748c] %[output:99f7d59c] %[output:503148c4] %[output:1eb9399b] %[output:0742cb4e] %[output:12c26ae0] %[output:678aba83] %[output:6b7d2515] %[output:8ef66356] %[output:7e5a44f1] %[output:757a2deb] %[output:59d3b9b1] %[output:01163b39] %[output:66ab765a] %[output:22774130] %[output:1884ff32] %[output:7b990bdf] %[output:106c1bfa] %[output:93f5ace0] %[output:19cd8881] %[output:47bddd8f] %[output:7abeed04] %[output:6dbca031] %[output:02df48c3] %[output:4462b4a8] %[output:4e86f89b] %[output:2c195628] %[output:7fbd3421] %[output:722465be] %[output:78efbbbd] %[output:0a833c33] %[output:8d4391fa] %[output:93239c5e] %[output:0d2711eb] %[output:5873eab0] %[output:910a11b7] %[output:2b92a7c1] %[output:7991edfd] %[output:4f1c99ab] %[output:832efceb] %[output:753bb37e] %[output:7d57e632] %[output:318951ab] %[output:51d4a118] %[output:2580abec] %[output:8871d75a] %[output:3430346a] %[output:078b84c4] %[output:3cc270aa] %[output:49a6b6cc] %[output:8a43e691] %[output:95bc4e11] %[output:609a27ea] %[output:0babb007] %[output:6ba71993] %[output:23cf31a0] %[output:104b882f] %[output:3a7f41a3] %[output:2ca433a1] %[output:4d0d4d08] %[output:7e4f8f49] %[output:17cea30a] %[output:047d8796] %[output:7b1e908a] %[output:8ef81b87] %[output:9cffda04] %[output:42c9659d] %[output:284c9327] %[output:02827273] %[output:41b917dd] %[output:4c5539bf] %[output:0aedf9ab] %[output:1136eaa8] %[output:9faf9c0b] %[output:771bbd3f] %[output:715f5989] %[output:91188e3b]
        writetable(xlsx, filepath);
    end
end %[output:group:9f458673]

%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"onright","rightPanelPercent":33.3}
%---
%[output:66a76530]
%   data: {"dataType":"text","outputData":{"text":"     <strong>ID<\/strong>     <strong>View<\/strong>    <strong>Category<\/strong>    <strong>StimNum<\/strong>      <strong>FilenameLeft<\/strong>         <strong>FilenameRight<\/strong>  \n    <strong>____<\/strong>    <strong>____<\/strong>    <strong>________<\/strong>    <strong>_______<\/strong>    <strong>_________________<\/strong>    <strong>_________________<\/strong>\n\n    \"1\"     \"2D\"    \"Face\"       \"01\"      \"Face_01_R.png\"      \"Face_01_R.png\"  \n    \"2\"     \"2D\"    \"Face\"       \"02\"      \"Face_02_R.png\"      \"Face_02_R.png\"  \n    \"3\"     \"2D\"    \"Face\"       \"03\"      \"Face_03_R.png\"      \"Face_03_R.png\"  \n    \"4\"     \"2D\"    \"Face\"       \"04\"      \"Face_04_R.png\"      \"Face_04_R.png\"  \n    \"5\"     \"2D\"    \"Face\"       \"05\"      \"Face_05_R.png\"      \"Face_05_R.png\"  \n    \"6\"     \"2D\"    \"Face\"       \"06\"      \"Face_06_R.png\"      \"Face_06_R.png\"  \n    \"7\"     \"2D\"    \"Face\"       \"07\"      \"Face_07_R.png\"      \"Face_07_R.png\"  \n    \"8\"     \"2D\"    \"Face\"       \"08\"      \"Face_08_R.png\"      \"Face_08_R.png\"  \n    \"9\"     \"2D\"    \"Face\"       \"09\"      \"Face_09_R.png\"      \"Face_09_R.png\"  \n    \"10\"    \"2D\"    \"Face\"       \"10\"      \"Face_10_R.png\"      \"Face_10_R.png\"  \n    \"11\"    \"2D\"    \"Face\"       \"11\"      \"Face_11_R.png\"      \"Face_11_R.png\"  \n    \"12\"    \"2D\"    \"Face\"       \"12\"      \"Face_12_R.png\"      \"Face_12_R.png\"  \n    \"13\"    \"2D\"    \"Face\"       \"13\"      \"Face_13_R.png\"      \"Face_13_R.png\"  \n    \"14\"    \"2D\"    \"Face\"       \"14\"      \"Face_14_R.png\"      \"Face_14_R.png\"  \n    \"15\"    \"2D\"    \"Face\"       \"15\"      \"Face_15_R.png\"      \"Face_15_R.png\"  \n    \"16\"    \"2D\"    \"Face\"       \"16\"      \"Face_16_R.png\"      \"Face_16_R.png\"  \n    \"17\"    \"2D\"    \"Hand\"       \"01\"      \"Hand_01_R.png\"      \"Hand_01_R.png\"  \n    \"18\"    \"2D\"    \"Hand\"       \"02\"      \"Hand_02_R.png\"      \"Hand_02_R.png\"  \n    \"19\"    \"2D\"    \"Hand\"       \"03\"      \"Hand_03_R.png\"      \"Hand_03_R.png\"  \n    \"20\"    \"2D\"    \"Hand\"       \"04\"      \"Hand_04_R.png\"      \"Hand_04_R.png\"  \n    \"21\"    \"2D\"    \"Hand\"       \"05\"      \"Hand_05_R.png\"      \"Hand_05_R.png\"  \n    \"22\"    \"2D\"    \"Hand\"       \"06\"      \"Hand_06_R.png\"      \"Hand_06_R.png\"  \n    \"23\"    \"2D\"    \"Hand\"       \"07\"      \"Hand_07_R.png\"      \"Hand_07_R.png\"  \n    \"24\"    \"2D\"    \"Hand\"       \"08\"      \"Hand_08_R.png\"      \"Hand_08_R.png\"  \n    \"25\"    \"2D\"    \"Hand\"       \"09\"      \"Hand_09_R.png\"      \"Hand_09_R.png\"  \n    \"26\"    \"2D\"    \"Hand\"       \"10\"      \"Hand_10_R.png\"      \"Hand_10_R.png\"  \n    \"27\"    \"2D\"    \"Hand\"       \"11\"      \"Hand_11_R.png\"      \"Hand_11_R.png\"  \n    \"28\"    \"2D\"    \"Hand\"       \"12\"      \"Hand_12_R.png\"      \"Hand_12_R.png\"  \n    \"29\"    \"2D\"    \"Hand\"       \"13\"      \"Hand_13_R.png\"      \"Hand_13_R.png\"  \n    \"30\"    \"2D\"    \"Hand\"       \"14\"      \"Hand_14_R.png\"      \"Hand_14_R.png\"  \n    \"31\"    \"2D\"    \"Hand\"       \"15\"      \"Hand_15_R.png\"      \"Hand_15_R.png\"  \n    \"32\"    \"2D\"    \"Hand\"       \"16\"      \"Hand_16_R.png\"      \"Hand_16_R.png\"  \n    \"33\"    \"2D\"    \"Object\"     \"01\"      \"Object_01_R.png\"    \"Object_01_R.png\"\n    \"34\"    \"2D\"    \"Object\"     \"02\"      \"Object_02_R.png\"    \"Object_02_R.png\"\n    \"35\"    \"2D\"    \"Object\"     \"03\"      \"Object_03_R.png\"    \"Object_03_R.png\"\n    \"36\"    \"2D\"    \"Object\"     \"04\"      \"Object_04_R.png\"    \"Object_04_R.png\"\n    \"37\"    \"2D\"    \"Object\"     \"05\"      \"Object_05_R.png\"    \"Object_05_R.png\"\n    \"38\"    \"2D\"    \"Object\"     \"06\"      \"Object_06_R.png\"    \"Object_06_R.png\"\n    \"39\"    \"2D\"    \"Object\"     \"07\"      \"Object_07_R.png\"    \"Object_07_R.png\"\n    \"40\"    \"2D\"    \"Object\"     \"08\"      \"Object_08_R.png\"    \"Object_08_R.png\"\n    \"41\"    \"2D\"    \"Object\"     \"09\"      \"Object_09_R.png\"    \"Object_09_R.png\"\n    \"42\"    \"2D\"    \"Object\"     \"10\"      \"Object_10_R.png\"    \"Object_10_R.png\"\n    \"43\"    \"2D\"    \"Object\"     \"11\"      \"Object_11_R.png\"    \"Object_11_R.png\"\n    \"44\"    \"2D\"    \"Object\"     \"12\"      \"Object_12_R.png\"    \"Object_12_R.png\"\n    \"45\"    \"2D\"    \"Object\"     \"13\"      \"Object_13_R.png\"    \"Object_13_R.png\"\n    \"46\"    \"2D\"    \"Object\"     \"14\"      \"Object_14_R.png\"    \"Object_14_R.png\"\n    \"47\"    \"2D\"    \"Object\"     \"15\"      \"Object_15_R.png\"    \"Object_15_R.png\"\n    \"48\"    \"2D\"    \"Object\"     \"16\"      \"Object_16_R.png\"    \"Object_16_R.png\"\n    \"49\"    \"3D\"    \"Face\"       \"01\"      \"Face_01_L.png\"      \"Face_01_R.png\"  \n    \"50\"    \"3D\"    \"Face\"       \"02\"      \"Face_02_L.png\"      \"Face_02_R.png\"  \n    \"51\"    \"3D\"    \"Face\"       \"03\"      \"Face_03_L.png\"      \"Face_03_R.png\"  \n    \"52\"    \"3D\"    \"Face\"       \"04\"      \"Face_04_L.png\"      \"Face_04_R.png\"  \n    \"53\"    \"3D\"    \"Face\"       \"05\"      \"Face_05_L.png\"      \"Face_05_R.png\"  \n    \"54\"    \"3D\"    \"Face\"       \"06\"      \"Face_06_L.png\"      \"Face_06_R.png\"  \n    \"55\"    \"3D\"    \"Face\"       \"07\"      \"Face_07_L.png\"      \"Face_07_R.png\"  \n    \"56\"    \"3D\"    \"Face\"       \"08\"      \"Face_08_L.png\"      \"Face_08_R.png\"  \n    \"57\"    \"3D\"    \"Face\"       \"09\"      \"Face_09_L.png\"      \"Face_09_R.png\"  \n    \"58\"    \"3D\"    \"Face\"       \"10\"      \"Face_10_L.png\"      \"Face_10_R.png\"  \n    \"59\"    \"3D\"    \"Face\"       \"11\"      \"Face_11_L.png\"      \"Face_11_R.png\"  \n    \"60\"    \"3D\"    \"Face\"       \"12\"      \"Face_12_L.png\"      \"Face_12_R.png\"  \n    \"61\"    \"3D\"    \"Face\"       \"13\"      \"Face_13_L.png\"      \"Face_13_R.png\"  \n    \"62\"    \"3D\"    \"Face\"       \"14\"      \"Face_14_L.png\"      \"Face_14_R.png\"  \n    \"63\"    \"3D\"    \"Face\"       \"15\"      \"Face_15_L.png\"      \"Face_15_R.png\"  \n    \"64\"    \"3D\"    \"Face\"       \"16\"      \"Face_16_L.png\"      \"Face_16_R.png\"  \n    \"65\"    \"3D\"    \"Hand\"       \"01\"      \"Hand_01_L.png\"      \"Hand_01_R.png\"  \n    \"66\"    \"3D\"    \"Hand\"       \"02\"      \"Hand_02_L.png\"      \"Hand_02_R.png\"  \n    \"67\"    \"3D\"    \"Hand\"       \"03\"      \"Hand_03_L.png\"      \"Hand_03_R.png\"  \n    \"68\"    \"3D\"    \"Hand\"       \"04\"      \"Hand_04_L.png\"      \"Hand_04_R.png\"  \n    \"69\"    \"3D\"    \"Hand\"       \"05\"      \"Hand_05_L.png\"      \"Hand_05_R.png\"  \n    \"70\"    \"3D\"    \"Hand\"       \"06\"      \"Hand_06_L.png\"      \"Hand_06_R.png\"  \n    \"71\"    \"3D\"    \"Hand\"       \"07\"      \"Hand_07_L.png\"      \"Hand_07_R.png\"  \n    \"72\"    \"3D\"    \"Hand\"       \"08\"      \"Hand_08_L.png\"      \"Hand_08_R.png\"  \n    \"73\"    \"3D\"    \"Hand\"       \"09\"      \"Hand_09_L.png\"      \"Hand_09_R.png\"  \n    \"74\"    \"3D\"    \"Hand\"       \"10\"      \"Hand_10_L.png\"      \"Hand_10_R.png\"  \n    \"75\"    \"3D\"    \"Hand\"       \"11\"      \"Hand_11_L.png\"      \"Hand_11_R.png\"  \n    \"76\"    \"3D\"    \"Hand\"       \"12\"      \"Hand_12_L.png\"      \"Hand_12_R.png\"  \n    \"77\"    \"3D\"    \"Hand\"       \"13\"      \"Hand_13_L.png\"      \"Hand_13_R.png\"  \n    \"78\"    \"3D\"    \"Hand\"       \"14\"      \"Hand_14_L.png\"      \"Hand_14_R.png\"  \n    \"79\"    \"3D\"    \"Hand\"       \"15\"      \"Hand_15_L.png\"      \"Hand_15_R.png\"  \n    \"80\"    \"3D\"    \"Hand\"       \"16\"      \"Hand_16_L.png\"      \"Hand_16_R.png\"  \n    \"81\"    \"3D\"    \"Object\"     \"01\"      \"Object_01_L.png\"    \"Object_01_R.png\"\n    \"82\"    \"3D\"    \"Object\"     \"02\"      \"Object_02_L.png\"    \"Object_02_R.png\"\n    \"83\"    \"3D\"    \"Object\"     \"03\"      \"Object_03_L.png\"    \"Object_03_R.png\"\n    \"84\"    \"3D\"    \"Object\"     \"04\"      \"Object_04_L.png\"    \"Object_04_R.png\"\n    \"85\"    \"3D\"    \"Object\"     \"05\"      \"Object_05_L.png\"    \"Object_05_R.png\"\n    \"86\"    \"3D\"    \"Object\"     \"06\"      \"Object_06_L.png\"    \"Object_06_R.png\"\n    \"87\"    \"3D\"    \"Object\"     \"07\"      \"Object_07_L.png\"    \"Object_07_R.png\"\n    \"88\"    \"3D\"    \"Object\"     \"08\"      \"Object_08_L.png\"    \"Object_08_R.png\"\n    \"89\"    \"3D\"    \"Object\"     \"09\"      \"Object_09_L.png\"    \"Object_09_R.png\"\n    \"90\"    \"3D\"    \"Object\"     \"10\"      \"Object_10_L.png\"    \"Object_10_R.png\"\n    \"91\"    \"3D\"    \"Object\"     \"11\"      \"Object_11_L.png\"    \"Object_11_R.png\"\n    \"92\"    \"3D\"    \"Object\"     \"12\"      \"Object_12_L.png\"    \"Object_12_R.png\"\n    \"93\"    \"3D\"    \"Object\"     \"13\"      \"Object_13_L.png\"    \"Object_13_R.png\"\n    \"94\"    \"3D\"    \"Object\"     \"14\"      \"Object_14_L.png\"    \"Object_14_R.png\"\n    \"95\"    \"3D\"    \"Object\"     \"15\"      \"Object_15_L.png\"    \"Object_15_R.png\"\n    \"96\"    \"3D\"    \"Object\"     \"16\"      \"Object_16_L.png\"    \"Object_16_R.png\"\n\n","truncated":false}}
%---
%[output:8ed97dba]
%   data: {"dataType":"text","outputData":{"text":"Created View_x_Category with 6 IDs:\n    <strong>ID<\/strong>     <strong>ID_Label<\/strong>      <strong>View<\/strong>    <strong>Category<\/strong>\n    <strong>__<\/strong>    <strong>___________<\/strong>    <strong>____<\/strong>    <strong>________<\/strong>\n\n    1     \"2D_Face\"      \"2D\"    \"Face\"  \n    2     \"2D_Hand\"      \"2D\"    \"Hand\"  \n    3     \"2D_Object\"    \"2D\"    \"Object\"\n    4     \"3D_Face\"      \"3D\"    \"Face\"  \n    5     \"3D_Hand\"      \"3D\"    \"Hand\"  \n    6     \"3D_Object\"    \"3D\"    \"Object\"\n\n","truncated":false}}
%---
%[output:6bb7a9d2]
%   data: {"dataType":"text","outputData":{"text":"     <strong>ID<\/strong>     <strong>View<\/strong>    <strong>Category<\/strong>    <strong>StimNum<\/strong>      <strong>FilenameLeft<\/strong>         <strong>FilenameRight<\/strong>      <strong>View_x_Category<\/strong>\n    <strong>____<\/strong>    <strong>____<\/strong>    <strong>________<\/strong>    <strong>_______<\/strong>    <strong>_________________<\/strong>    <strong>_________________<\/strong>    <strong>_______________<\/strong>\n\n    \"1\"     \"2D\"    \"Face\"       \"01\"      \"Face_01_R.png\"      \"Face_01_R.png\"        \"2D_Face\"    \n    \"2\"     \"2D\"    \"Face\"       \"02\"      \"Face_02_R.png\"      \"Face_02_R.png\"        \"2D_Face\"    \n    \"3\"     \"2D\"    \"Face\"       \"03\"      \"Face_03_R.png\"      \"Face_03_R.png\"        \"2D_Face\"    \n    \"4\"     \"2D\"    \"Face\"       \"04\"      \"Face_04_R.png\"      \"Face_04_R.png\"        \"2D_Face\"    \n    \"5\"     \"2D\"    \"Face\"       \"05\"      \"Face_05_R.png\"      \"Face_05_R.png\"        \"2D_Face\"    \n    \"6\"     \"2D\"    \"Face\"       \"06\"      \"Face_06_R.png\"      \"Face_06_R.png\"        \"2D_Face\"    \n    \"7\"     \"2D\"    \"Face\"       \"07\"      \"Face_07_R.png\"      \"Face_07_R.png\"        \"2D_Face\"    \n    \"8\"     \"2D\"    \"Face\"       \"08\"      \"Face_08_R.png\"      \"Face_08_R.png\"        \"2D_Face\"    \n    \"9\"     \"2D\"    \"Face\"       \"09\"      \"Face_09_R.png\"      \"Face_09_R.png\"        \"2D_Face\"    \n    \"10\"    \"2D\"    \"Face\"       \"10\"      \"Face_10_R.png\"      \"Face_10_R.png\"        \"2D_Face\"    \n    \"11\"    \"2D\"    \"Face\"       \"11\"      \"Face_11_R.png\"      \"Face_11_R.png\"        \"2D_Face\"    \n    \"12\"    \"2D\"    \"Face\"       \"12\"      \"Face_12_R.png\"      \"Face_12_R.png\"        \"2D_Face\"    \n    \"13\"    \"2D\"    \"Face\"       \"13\"      \"Face_13_R.png\"      \"Face_13_R.png\"        \"2D_Face\"    \n    \"14\"    \"2D\"    \"Face\"       \"14\"      \"Face_14_R.png\"      \"Face_14_R.png\"        \"2D_Face\"    \n    \"15\"    \"2D\"    \"Face\"       \"15\"      \"Face_15_R.png\"      \"Face_15_R.png\"        \"2D_Face\"    \n    \"16\"    \"2D\"    \"Face\"       \"16\"      \"Face_16_R.png\"      \"Face_16_R.png\"        \"2D_Face\"    \n    \"17\"    \"2D\"    \"Hand\"       \"01\"      \"Hand_01_R.png\"      \"Hand_01_R.png\"        \"2D_Hand\"    \n    \"18\"    \"2D\"    \"Hand\"       \"02\"      \"Hand_02_R.png\"      \"Hand_02_R.png\"        \"2D_Hand\"    \n    \"19\"    \"2D\"    \"Hand\"       \"03\"      \"Hand_03_R.png\"      \"Hand_03_R.png\"        \"2D_Hand\"    \n    \"20\"    \"2D\"    \"Hand\"       \"04\"      \"Hand_04_R.png\"      \"Hand_04_R.png\"        \"2D_Hand\"    \n    \"21\"    \"2D\"    \"Hand\"       \"05\"      \"Hand_05_R.png\"      \"Hand_05_R.png\"        \"2D_Hand\"    \n    \"22\"    \"2D\"    \"Hand\"       \"06\"      \"Hand_06_R.png\"      \"Hand_06_R.png\"        \"2D_Hand\"    \n    \"23\"    \"2D\"    \"Hand\"       \"07\"      \"Hand_07_R.png\"      \"Hand_07_R.png\"        \"2D_Hand\"    \n    \"24\"    \"2D\"    \"Hand\"       \"08\"      \"Hand_08_R.png\"      \"Hand_08_R.png\"        \"2D_Hand\"    \n    \"25\"    \"2D\"    \"Hand\"       \"09\"      \"Hand_09_R.png\"      \"Hand_09_R.png\"        \"2D_Hand\"    \n    \"26\"    \"2D\"    \"Hand\"       \"10\"      \"Hand_10_R.png\"      \"Hand_10_R.png\"        \"2D_Hand\"    \n    \"27\"    \"2D\"    \"Hand\"       \"11\"      \"Hand_11_R.png\"      \"Hand_11_R.png\"        \"2D_Hand\"    \n    \"28\"    \"2D\"    \"Hand\"       \"12\"      \"Hand_12_R.png\"      \"Hand_12_R.png\"        \"2D_Hand\"    \n    \"29\"    \"2D\"    \"Hand\"       \"13\"      \"Hand_13_R.png\"      \"Hand_13_R.png\"        \"2D_Hand\"    \n    \"30\"    \"2D\"    \"Hand\"       \"14\"      \"Hand_14_R.png\"      \"Hand_14_R.png\"        \"2D_Hand\"    \n    \"31\"    \"2D\"    \"Hand\"       \"15\"      \"Hand_15_R.png\"      \"Hand_15_R.png\"        \"2D_Hand\"    \n    \"32\"    \"2D\"    \"Hand\"       \"16\"      \"Hand_16_R.png\"      \"Hand_16_R.png\"        \"2D_Hand\"    \n    \"33\"    \"2D\"    \"Object\"     \"01\"      \"Object_01_R.png\"    \"Object_01_R.png\"      \"2D_Object\"  \n    \"34\"    \"2D\"    \"Object\"     \"02\"      \"Object_02_R.png\"    \"Object_02_R.png\"      \"2D_Object\"  \n    \"35\"    \"2D\"    \"Object\"     \"03\"      \"Object_03_R.png\"    \"Object_03_R.png\"      \"2D_Object\"  \n    \"36\"    \"2D\"    \"Object\"     \"04\"      \"Object_04_R.png\"    \"Object_04_R.png\"      \"2D_Object\"  \n    \"37\"    \"2D\"    \"Object\"     \"05\"      \"Object_05_R.png\"    \"Object_05_R.png\"      \"2D_Object\"  \n    \"38\"    \"2D\"    \"Object\"     \"06\"      \"Object_06_R.png\"    \"Object_06_R.png\"      \"2D_Object\"  \n    \"39\"    \"2D\"    \"Object\"     \"07\"      \"Object_07_R.png\"    \"Object_07_R.png\"      \"2D_Object\"  \n    \"40\"    \"2D\"    \"Object\"     \"08\"      \"Object_08_R.png\"    \"Object_08_R.png\"      \"2D_Object\"  \n    \"41\"    \"2D\"    \"Object\"     \"09\"      \"Object_09_R.png\"    \"Object_09_R.png\"      \"2D_Object\"  \n    \"42\"    \"2D\"    \"Object\"     \"10\"      \"Object_10_R.png\"    \"Object_10_R.png\"      \"2D_Object\"  \n    \"43\"    \"2D\"    \"Object\"     \"11\"      \"Object_11_R.png\"    \"Object_11_R.png\"      \"2D_Object\"  \n    \"44\"    \"2D\"    \"Object\"     \"12\"      \"Object_12_R.png\"    \"Object_12_R.png\"      \"2D_Object\"  \n    \"45\"    \"2D\"    \"Object\"     \"13\"      \"Object_13_R.png\"    \"Object_13_R.png\"      \"2D_Object\"  \n    \"46\"    \"2D\"    \"Object\"     \"14\"      \"Object_14_R.png\"    \"Object_14_R.png\"      \"2D_Object\"  \n    \"47\"    \"2D\"    \"Object\"     \"15\"      \"Object_15_R.png\"    \"Object_15_R.png\"      \"2D_Object\"  \n    \"48\"    \"2D\"    \"Object\"     \"16\"      \"Object_16_R.png\"    \"Object_16_R.png\"      \"2D_Object\"  \n    \"49\"    \"3D\"    \"Face\"       \"01\"      \"Face_01_L.png\"      \"Face_01_R.png\"        \"3D_Face\"    \n    \"50\"    \"3D\"    \"Face\"       \"02\"      \"Face_02_L.png\"      \"Face_02_R.png\"        \"3D_Face\"    \n    \"51\"    \"3D\"    \"Face\"       \"03\"      \"Face_03_L.png\"      \"Face_03_R.png\"        \"3D_Face\"    \n    \"52\"    \"3D\"    \"Face\"       \"04\"      \"Face_04_L.png\"      \"Face_04_R.png\"        \"3D_Face\"    \n    \"53\"    \"3D\"    \"Face\"       \"05\"      \"Face_05_L.png\"      \"Face_05_R.png\"        \"3D_Face\"    \n    \"54\"    \"3D\"    \"Face\"       \"06\"      \"Face_06_L.png\"      \"Face_06_R.png\"        \"3D_Face\"    \n    \"55\"    \"3D\"    \"Face\"       \"07\"      \"Face_07_L.png\"      \"Face_07_R.png\"        \"3D_Face\"    \n    \"56\"    \"3D\"    \"Face\"       \"08\"      \"Face_08_L.png\"      \"Face_08_R.png\"        \"3D_Face\"    \n    \"57\"    \"3D\"    \"Face\"       \"09\"      \"Face_09_L.png\"      \"Face_09_R.png\"        \"3D_Face\"    \n    \"58\"    \"3D\"    \"Face\"       \"10\"      \"Face_10_L.png\"      \"Face_10_R.png\"        \"3D_Face\"    \n    \"59\"    \"3D\"    \"Face\"       \"11\"      \"Face_11_L.png\"      \"Face_11_R.png\"        \"3D_Face\"    \n    \"60\"    \"3D\"    \"Face\"       \"12\"      \"Face_12_L.png\"      \"Face_12_R.png\"        \"3D_Face\"    \n    \"61\"    \"3D\"    \"Face\"       \"13\"      \"Face_13_L.png\"      \"Face_13_R.png\"        \"3D_Face\"    \n    \"62\"    \"3D\"    \"Face\"       \"14\"      \"Face_14_L.png\"      \"Face_14_R.png\"        \"3D_Face\"    \n    \"63\"    \"3D\"    \"Face\"       \"15\"      \"Face_15_L.png\"      \"Face_15_R.png\"        \"3D_Face\"    \n    \"64\"    \"3D\"    \"Face\"       \"16\"      \"Face_16_L.png\"      \"Face_16_R.png\"        \"3D_Face\"    \n    \"65\"    \"3D\"    \"Hand\"       \"01\"      \"Hand_01_L.png\"      \"Hand_01_R.png\"        \"3D_Hand\"    \n    \"66\"    \"3D\"    \"Hand\"       \"02\"      \"Hand_02_L.png\"      \"Hand_02_R.png\"        \"3D_Hand\"    \n    \"67\"    \"3D\"    \"Hand\"       \"03\"      \"Hand_03_L.png\"      \"Hand_03_R.png\"        \"3D_Hand\"    \n    \"68\"    \"3D\"    \"Hand\"       \"04\"      \"Hand_04_L.png\"      \"Hand_04_R.png\"        \"3D_Hand\"    \n    \"69\"    \"3D\"    \"Hand\"       \"05\"      \"Hand_05_L.png\"      \"Hand_05_R.png\"        \"3D_Hand\"    \n    \"70\"    \"3D\"    \"Hand\"       \"06\"      \"Hand_06_L.png\"      \"Hand_06_R.png\"        \"3D_Hand\"    \n    \"71\"    \"3D\"    \"Hand\"       \"07\"      \"Hand_07_L.png\"      \"Hand_07_R.png\"        \"3D_Hand\"    \n    \"72\"    \"3D\"    \"Hand\"       \"08\"      \"Hand_08_L.png\"      \"Hand_08_R.png\"        \"3D_Hand\"    \n    \"73\"    \"3D\"    \"Hand\"       \"09\"      \"Hand_09_L.png\"      \"Hand_09_R.png\"        \"3D_Hand\"    \n    \"74\"    \"3D\"    \"Hand\"       \"10\"      \"Hand_10_L.png\"      \"Hand_10_R.png\"        \"3D_Hand\"    \n    \"75\"    \"3D\"    \"Hand\"       \"11\"      \"Hand_11_L.png\"      \"Hand_11_R.png\"        \"3D_Hand\"    \n    \"76\"    \"3D\"    \"Hand\"       \"12\"      \"Hand_12_L.png\"      \"Hand_12_R.png\"        \"3D_Hand\"    \n    \"77\"    \"3D\"    \"Hand\"       \"13\"      \"Hand_13_L.png\"      \"Hand_13_R.png\"        \"3D_Hand\"    \n    \"78\"    \"3D\"    \"Hand\"       \"14\"      \"Hand_14_L.png\"      \"Hand_14_R.png\"        \"3D_Hand\"    \n    \"79\"    \"3D\"    \"Hand\"       \"15\"      \"Hand_15_L.png\"      \"Hand_15_R.png\"        \"3D_Hand\"    \n    \"80\"    \"3D\"    \"Hand\"       \"16\"      \"Hand_16_L.png\"      \"Hand_16_R.png\"        \"3D_Hand\"    \n    \"81\"    \"3D\"    \"Object\"     \"01\"      \"Object_01_L.png\"    \"Object_01_R.png\"      \"3D_Object\"  \n    \"82\"    \"3D\"    \"Object\"     \"02\"      \"Object_02_L.png\"    \"Object_02_R.png\"      \"3D_Object\"  \n    \"83\"    \"3D\"    \"Object\"     \"03\"      \"Object_03_L.png\"    \"Object_03_R.png\"      \"3D_Object\"  \n    \"84\"    \"3D\"    \"Object\"     \"04\"      \"Object_04_L.png\"    \"Object_04_R.png\"      \"3D_Object\"  \n    \"85\"    \"3D\"    \"Object\"     \"05\"      \"Object_05_L.png\"    \"Object_05_R.png\"      \"3D_Object\"  \n    \"86\"    \"3D\"    \"Object\"     \"06\"      \"Object_06_L.png\"    \"Object_06_R.png\"      \"3D_Object\"  \n    \"87\"    \"3D\"    \"Object\"     \"07\"      \"Object_07_L.png\"    \"Object_07_R.png\"      \"3D_Object\"  \n    \"88\"    \"3D\"    \"Object\"     \"08\"      \"Object_08_L.png\"    \"Object_08_R.png\"      \"3D_Object\"  \n    \"89\"    \"3D\"    \"Object\"     \"09\"      \"Object_09_L.png\"    \"Object_09_R.png\"      \"3D_Object\"  \n    \"90\"    \"3D\"    \"Object\"     \"10\"      \"Object_10_L.png\"    \"Object_10_R.png\"      \"3D_Object\"  \n    \"91\"    \"3D\"    \"Object\"     \"11\"      \"Object_11_L.png\"    \"Object_11_R.png\"      \"3D_Object\"  \n    \"92\"    \"3D\"    \"Object\"     \"12\"      \"Object_12_L.png\"    \"Object_12_R.png\"      \"3D_Object\"  \n    \"93\"    \"3D\"    \"Object\"     \"13\"      \"Object_13_L.png\"    \"Object_13_R.png\"      \"3D_Object\"  \n    \"94\"    \"3D\"    \"Object\"     \"14\"      \"Object_14_L.png\"    \"Object_14_R.png\"      \"3D_Object\"  \n    \"95\"    \"3D\"    \"Object\"     \"15\"      \"Object_15_L.png\"    \"Object_15_R.png\"      \"3D_Object\"  \n    \"96\"    \"3D\"    \"Object\"     \"16\"      \"Object_16_L.png\"    \"Object_16_R.png\"      \"3D_Object\"  \n\n","truncated":false}}
%---
%[output:8c8d9bb1]
%   data: {"dataType":"text","outputData":{"text":"Initializing default order rules...\n\tView_x_Category (6 x 6): allowing 0 to infite occurances...\nInitializing default per-half count rules...\n\tView_x_Category: allowing 0 to infite occurances in each half of runs...\n","truncated":false}}
%---
%[output:571d0108]
%   data: {"dataType":"text","outputData":{"text":"    <strong>ID<\/strong>       <strong>Label<\/strong>   \n    <strong>__<\/strong>    <strong>___________<\/strong>\n\n    1     \"2D_Face\"  \n    2     \"2D_Hand\"  \n    3     \"2D_Object\"\n    4     \"3D_Face\"  \n    5     \"3D_Hand\"  \n    6     \"3D_Object\"\n\n","truncated":false}}
%---
%[output:55390eb9]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAABCEAAAJ7CAYAAADdt4tVAAAAAXNSR0IArs4c6QAAIABJREFUeF7s3Qm0FNW9\/v0f86ioIEE0IkZkUNQ4gUGQ4MjFOGOC8iqG4ADBCRQVhYCgqAgiCxxQo1wcwtVEiV6NSfwTFWeN84BExMggoAxyQOZ3PTu3DkXT3af7VO\/uru5vrcVK5FTtqv3ZVUfrqT3U2G233bYaGwIIIIAAAggggAACCCCAAAIIIOBZoAYhhGdhikcAAQQQQAABBBBAAAEEEEAAASdACMGNgAACCCCAAAIIIIAAAggggAACeREghMgLMydBAAEEEEAAAQQQQAABBBBAAAFCCO4BBBBAAAEEEEAAAQQQQAABBBDIiwAhRF6YOQkCCCCAAAIIIIAAAggggAACCBBCcA8ggAACCCCAAAIIIIAAAggggEBeBAgh8sLMSRBAAAEEEEAAAQQQQAABBBBAgBCCewABBBBAAAEEEEAAAQQQQAABBPIiQAiRF2ZOggACCCCQa4FbbrnFunXrtkOxixYtsqFDh9r8+fN3+FmLFi1s0qRJtvfee+\/wsxdffNGGDRtW+fcPPvigtW3b1v3zhg0bbMqUKTZz5sxcV4PyEEAAAQQQQACBshIghCir5qayCCCAQOkIpAoh1q1bZ7fffrs988wzO1S2R48edu2111rjxo0JIUrnVqAmCCCAAAIIIBAjAUKIGDUWl4oAAgggsE0gVQihPZ566ikbN27cDlyDBw+2Pn36WI0aNQghuJkQQAABBBBAAIECCBBCFACdUyKAAAIIRBdIF0J8+umnNmDAANu0adN2J7r77rvt4IMPTnryxOEY0a+QEhBAAAEEEEAAAQQSBQghuCcQQAABBGIpkBhCbN261fSnZs2atmLFCjfs4r333qusW\/v27V3viObNm9vmzZvdn7p161b+nBAilrcBF40AAggggAACMRMghIhZg3G5CCCAAAL\/EUgMIVauXOkmkFTIoP+9\/\/77bfr06ZVcZ599tg0aNMgFDwoptO26664pQ4h0E1N26tTJxowZUzm3hAKMUaNGWb9+\/eyEE06w3XbbzerUqWPr16+3Dz74wE2GOW\/ePJoOAQQQQAABBBAoewFCiLK\/BQBAAAEE4imQGEJoVYyFCxfaEUcc4SqU2LNhxIgR1rNnT\/ezzz77zHbaaSdr2bJlTkKIt956ywUP++67b1JMhR633nqrzZ49O57YXDUCCCCAAAIIIJAjAUKIHEFSDAIIIIBAfgWShRAKHnr37m21atWy8FKdTZo0sbvuustat27tLvLZZ5+1Aw44YLulOrNZojOxJ4SGduic6bb333\/f9cRInKciv2qcDQEEEEAAAQQQKKwAIURh\/Tk7AggggEA1BZKFEDNmzLCBAwe6YRLhpTqPOuooN1xCvR80VOPOO++0X\/ziF9a2bdvKs0cJIVSIylW4ockvd9llF1PPC81DEWyrVq2y66+\/3tRrgg0BBBBAAAEEEChXAUKIcm156o0AAgjEXCBZCKGJJ4cNG2Z77rmnq12wVKdWyjj\/\/PNdb4WlS5faNddc4\/bLVQihCTFnzZq13bKg4eBD17JmzRq7+eab7YUXXoi5PJePAAIIIIAAAghUX4AQovp2HIkAAgggUECBxBBC80FcccUVdtVVV1XOCxEs1TlhwoQd\/u6+++7LWQhRUVFhI0eOtDlz5lSKaOjH+PHjK+edUE+JKVOm2MyZMwuoxqkRQAABBBBAAIHCChBCFNafsyOAAAIIVFMgMYTQZJNanWLw4MHWp08fq1GjhlsFQ0GA5mIIJqHUkInRo0dbePULXUKU4RjJhloQQlSzYTkMAQQQQAABBEpagBCipJuXyiGAAAKlK5AqhOjVq5cNGTLEGjRo4OZp0PCHY445pvKfNUHlY4895pbw7NChQyVQlBAiPAlmUCAhROnee9QMAQQQQAABBKovQAhRfTuORAABBBAooECqEELLZKr3wx577OGuTr0UtDqGNvWMuPbaa+29996zxOMJIQrYmJwaAQQQQAABBMpGgBCibJqaiiKAAAKlJZAqhFAttULFwQcfvEOF58+fb5dccokLJgghSut+oDYIIIAAAgggEA8BQoh4tBNXiQACCCCQIJAuhNDqF6eeeuoOZrNnz3Y9IbQRQnBLIYAAAggggAAC+RcghMi\/OWdEAAEEEMiBQLoQ4cwzz7RLL73U6tatW3kmzQ+heSCmT59OCJEDf4pAAAEEEEAAAQSqI0AIUR01jkEAAQQQKLhAuhCiffv2Nm7cOGvevHnldX7\/\/fduGc1XX32VEKLgrccFIIAAAggggEC5ChBClGvLU28EEEAg5gLpQojatWvbtGnTrF27dpW1\/Oqrr+yyyy6zJUuWuL\/TUp7nnHNO5c+ZmDLmNwSXjwACCCCAAAKxECCEiEUzcZEIIIAAAokCVc3pMGLECOvZs2flYXPmzLGhQ4dW\/jMhBPcUAggggAACCCCQfwFCiPybc0YEEEAAAQQQQAABBBBAAAEEylKAEKIsm51KI4AAAggggAACCCCAAAIIIJB\/AUKI\/JtzRgQQQAABBBBAAAEEEEAAAQTKUoAQoiybnUojgAACCCCAAAIIIIAAAgggkH8BQoj8m3NGBBBAAAEEEEAAAQQQQAABBMpSgBCiLJudSiOAAAIIIIAAAggggAACCCCQfwFCiPybc0YEEEAAAQQQQAABBBBAAAEEylKAEKIsm51KI4AAAggggAACCCCAAAIIIJB\/AUKI\/JtzRgQQQAABBBBAAAEEEEAAAQTKUoAQoiybnUojgAACCCCAAAIIIIAAAgggkH8BQoj8m3NGBBBAAAEEEEAAAQQQQAABBMpSgBCiLJudSiOAAAIIIIAAAggggAACCCCQfwFCiPybc0YEEEAAAQQQQAABBBBAAAEEylKAEKIsm51KI4AAAggggAACCCCAAAIIIJB\/AUKI\/JtzRgQQQAABBAou0K9fP3vnnXfs\/fffL\/i1cAEIlIoAz1WptCT1QAABnwKEED51KRsBBBBAAIEiFDj66KPtuuuus9dff91GjRpVhFfIJSEQPwGeq\/i1GVeMAAKFESCEKIw7Z0UAAQQQQKBgAjfeeKMdd9xxtmrVKhs3bpzNnj27YNfCiREoFQGeq1JpSeqBAAK+BQghfAtTPgIIIIAAAkUmoC+2w4cPt1122cXeffddGzt2rF1yySX2+eef24MPPlhkV8vlIBAPAZ6reLQTV4kAAoUXIIQofBtwBQgggAACCORdYOTIkXbiiSfapk2b3J8GDRrY119\/bVdccYX7XzYEEMhegOcqezOOQACB8hMghCi\/NqfGCCCAQGwFGjdu7K59zZo1sa1DsVx4nz597KKLLrJ69erZxo0b7dVXX7W77rrLvvzyy2K5RK4jTwI8V7mD5rnKnSUlIYBA6QoQQpRu21IzBBBAoGQEateubeeff76dddZZbjWHYcOGlUzdClGRs88+2wYNGmR169Z1p9+8ebM9\/vjjdscddxTicjhngQR4rnILz3OVW09KQwCB0hUghCjdtqVmCCCAQMkI6GXp9ttvtyOPPNLWrl1rkyZNslmzZpVM\/fJdkSZNmtgNN9xgX3zxhWkce+vWrW3p0qXu71iyM9+tUbjz8Vzl1p7nKreelIYAAqUrQAhRum1LzRBAAIGSEjj00ENtzJgxtuuuu9rHH39sV155pVvdgS29gCaf\/NWvfmWHHHKI1apVyz799FN75JFHbPHixe7AM8880wYPHuyGZbz44ov0MimzG4rnqnoNznNVPTeOQgABBCRACMF9gAACCCAQG4FrrrnGTjnlFNuwYYNbxYGVHFI3XbirvV6Ywpvm1Lj\/\/vvtscces\/DXcP39bbfdZs8\/\/3xs7gkuNLoAz1XmhjxXmVuxJwIIIJBKgBCCewMBBBBAIDYCGjagl+Q999zTFi1aZEOHDrX58+fH5vrzdaF6Ubr66qvtpJNOciGDrN566y3bZ599rH379lanTh375JNP7Nprr3XDMMJLC3700Uc2ZMgQepnkq7GK4Dw8V5k1As9VZk7shQACCFQlQAhRlRA\/RwABBBAoKoF+\/fqZ\/mhSRc0LMW7cuKK6vmK4mGCIRc2aNZ2RJpzUMpzaunfvbu3atbPp06e7+TWCja\/hxdByhbsGnquq7XmuqjZiDwQQQCATAUKITJTYBwEEEECgoAL6Un\/66aebhhVs3brVWrZs6eaGWLFihY0dO9bmzJlT0OsrppPra+20adNc0KBJJrUKRhBApLtOfQ0fP368s9UynZpzI5g3opjqx7XkToDnKnNLnqvMrdgTAQQQqEqAEKIqIX6OAAIIIFAwgYYNG9p1111n3bp1c0MIkm1vvPGGGz6QyYt2wSqSxxNruIV6hzRv3txNQDl58uSMzx7+Gv7KK6\/Y3\/72N+vdu7f95S9\/sZkzZ2ZcDjsWtwDPVfbtw3OVvRlHIIAAAqkECCG4NxBAAIECCnTq1MnOPfdc22+\/\/dxL9sqVK90KBf\/93\/\/t\/n+5byNHjrQTTzzRNm7caP\/4xz9sxowZtnr1arfaQ69evaxx48Ys2Zlwkxx++OFuFREtF5hJCKGv4QcddJBNnTrVHaOlUA844IDtSl2+fLmbP+LDDz+MxS3Jc5W+mXiusr+Nea6yN+MIBBBAgBCCewABBBAoIgENK9AY\/KOOOsrNbZC4abLAW2+9tayHGeg\/+kePHm0777yzPfnkk26oQHjT3AaafFHDMubNm+eWmSyH4Eb3zgknnGA\/\/vGP3Sohr776qpt0Mtj09xMnTnSTd7755pt26aWXprzz1cvk5JNPtmXLlrn7UZNVhl11oO7Fu+66y5577rkieoKSXwrPVdVNxHOV+t7huar6\/mEPBBBAIBcC9ITIhSJlIIAAAlkIaGyx5jHo2rWr+8L\/9ttvu8kDtWn5ycMOO8wFE5rvQEHE7Nmzsyi9dHYdOHCg9e3b1wUL+gr\/3nvv7VC5Pn362EUXXWSagFG9JO69997YAeh+2GOPPezf\/\/532mtXF3rN76AeIPXq1avcV3NkLFmyxO68887Ke2XChAku4NI9NGLEiO1CivBJzj77bFemwozrr7\/eXn\/9dfdjvcwfe+yx9u2339rLL78ci6EuPFeZ3fo8V9s78Vxldt+wFwIIIJBLAUKIXGpSFgIIIJCBwIUXXuherrds2WL33HOPPfroo9sdFbxY60Xz008\/tSuuuKIsvvAn0qlnwznnnJN2KU69eGr4wJFHHukmUdTX\/Llz52bQCsWxi5bQvOSSS9xQHIUA77zzTtILUyigenbo0MHdNwodFM7o71u0aOFCmDVr1tjdd99tTzzxhAuzNLGk7iEN7xk+fHjSICFVCFEcOtldBc9VZl48V9uceK4yu2fYCwEEEMi1ACFErkUpDwEEEEgjEJ5hXd3o9aIY3hK\/yq1fv96N1S\/VSQHlofkHNM\/D\/Pnzt7MIXpa+\/\/570xh2eSXbevTo4XpKNGrUyE2gOGrUqNjcgwoLLrvsMlO7pwoLwl\/45aTg6k9\/+lNlHbVqiHqDaD4H9XxQmKFVMTQh5SGHHGK6h5KFXSpAw12OP\/54++qrr9x1KNyI48ZztX2r8VzxXMXxOeaaEUCgfAQIIcqnrakpAggUgUB4GcTESQM1Nn\/AgAFuVQN97db4fC21GHSRL4LLz9klaCLOoUOHui\/76gWgIQX\/+te\/7JZbbqmc\/FDDDrTqhYamaKiFvvIn29QTYNKkSbb33nu73gEa6qIhBHHY9LJ42223ud4MCpteeumlHS5bIYvmbtC+Dz74oPsT3vT3mhtDXuoREawWogkngzkz1q5daw888IA9\/PDD7lAdo3vtl7\/8ZayHsgQOPFf\/keC5+o8Dz1UcfvtxjQggUM4ChBDl3PrUHQEEvAjoq\/bPf\/5za9eunVVUVNgLL7xQOUQg2TJvmhvi17\/+te2\/\/\/7uhVATASp8ePrpp91\/TKvLvpafjMPEgJmAnnnmmXbxxRe7lS0St4ULF7oXbg2p0DwJmudgr732SjskQ2Xoxbxt27auuHfffddNUlkqS3YGY\/jVS0HBzRdffFHJpntHP2\/VqpX7O00wGdw7+mcNt1AvCd2TCno0x4P2Ueihruj6OwUf6j1R7F48V+mfLp6rTH77bNuH5yo7L\/ZGAAEEcilACJFLTcpCAIGyFlBgcP7559tZZ53lXvCCTZNPapWCG2+80XbaaafKlQvU00EvhJ07d3Zf+9Vt\/plnnrEpU6a4ZSf1oqiJKfV1Uy+Kw4YNi72vloKUw+67724LFixwPRwU1Mjs0EMPdfXTsATN7aDt8ssvdz9TOJNqqEXwFbxZs2ZWo0YN92Itw7gNYVE7a3iOJiq9\/\/77K9v6hhtusP\/6r\/\/aLojZZ5993FwSwb2jHiCPP\/64PfTQQy5M0Au7JpvU\/9dqF1ohQ\/eTfIJNQzc0f0RwTLHeXDxXVbcMz1VqI56rqu8f9kAAAQTyLUAIkW9xzocAAiUpoJc+zVugL9Pa9MVZf\/QVX3MV6MX4b3\/7m1upIFi5IIDQy+Jrr73mlkH88ssvK33CXcz1Yh7XECKY50IvSlpKsnfv3m6IiV6uFbZo03wGmnhR80NogkUNUXj++eddmKO5DfQiIac\/\/OEPbthCeNOL+2mnnebmQWjQoIGbzDMIcuJyszVt2tTVU22+aNEi1+MhmCMjmBtDoYHmu+jWrVvlChnBvXPHHXe4iTkPPvhg1zNCy3QmroqhpRm1YkatWrVcb5E4rHrBc5X6Dua5qvrp5rmq2og9EEAAgUIIEEIUQp1zIoBAyQnopVEvwvryrBdldYnX\/9eQAk34t3z5ctOLov4uPBmhhl7o5VshQ+IWHrrx1FNP2bhx42LpprkJtDqDggYFDNqSTTQZ7Kfg4eOPP3a9AlatWuW+5AdzG2iuDIUM8tAkjcGSpgp59BKvL\/tx3fr162f6o14x4V4fwQoWmjtDvWr0czloyIrmeQjPIxEEFnIOL7kZVxOeq9Qtx3OV2V3Nc5WZE3shgAAC+RQghMinNudCAIGSFNAX\/ptvvtl23XVXmzVrVpVhQXhZSb1UPvnkk653ROIWvID98MMPdtNNN7m5JeK6aXiFAgMNB0j80h+uU7CfvvCHJ2Hs0qWLCyI0aWfilqqHRL6tgsBJ4ZF6cmQ7OWa4N0h4gs3w3BiqU3jOkMQ6BiGEwhuFEOp5EteN56rqluO5qtqI56pqI\/ZAAAEE8i1ACJFvcc6HAAIlJ\/CrX\/3Kjc9XoKAv\/HPmzKmyjpr\/YMyYMS64SByOER7vr5f2VCFFlScpoh3CQ0vSLbkZ3k+TVF511VWVwxLU\/VxfNTXpp3pLyHvevHluxYdiWEHkhBNOcNerCTeDFSrCkz3qmjV54E9\/+lPXMv\/85z9dzw0FDsGWqowLL7zQ+vbt6yYqVc8H9SxJnEhSP9MwFL28f\/75525yToURcd14rqpuOZ4rc78LeK6qvlfYAwEEECgmAUKIYmoNrgUBBGIpkG0XeL0kKlz40Y9+5CZeVBCRbFM4oRUx9FW92Fcu0AoeWu5x3333dUtuasJNzXERXtEj\/CKdrsdIpvsV482iJUY1Z4PaLjw5psIT+YQnLNX1K4DQ8J3wspvJytBxEydOdCuuKHzR\/CLjx4+vnFNDAY16zhx33HFuqMY999xjjz76aDESZXxNPFfmVsbhuTK3dC\/PVcaPDjsigAACRS9ACFH0TcQFIoBAoQXUM0Ff2vQCqHkItOpC+Mt7MGZf15luVQZNkqZhFQceeKDrqq+JJjXhol4eO3To4F7etQVf+H\/\/+99vN94\/nw7B8pnBHA6pzh1cf8eOHd0KFuFNEylqdY\/Zs2e7vw6\/SOtnGi7wzjvv7FC0uk9reIpM0u2XT49MzxXu4aJeGnqR7tmzp1smU3M5aJlN1UmhwZ577unaXIHFn\/70JzdniLZkZSisSBySor\/TZJTaNGRDvollZXrdhdiP5yq1Os\/V9jY8V4V4QjknAggg4E+AEMKfLSUjgECRCqjbul50tXpFuk0vduqpECyDGOyrpTTDX5q1IkEwJ8Srr77qJlRMtenrtV4mP\/vsMze0INj0UqqQQ5smXgxWjcg3YXg5RK3UoZfoVL0wwhNGykTLkGqogFZhOOaYY9xLd3iCSdUlPCmnJuNMNqwgcb9kQxvy7ZLN+YJlRXWMhtKo54teuNX7I5icVD+T3xVXXOHmuZBfeGLNoAz1avif\/\/kf9zNtCrAUXv3kJz\/ZbrlN\/SzdXBHZXH919+W5Si3Hc1Xdu2rbceX6XEWXowQEEECg+AQIIYqvTbgiBBDwKKDuzeeff75bNlNf4rWsY7KtV69eNmjQIDdUQi+CWt1CPRT0wqiv14lf6INlN8PLSyYrN+hWnBhCeKxyVkWHeyEkDikIF7T\/\/vu7Xh0tW7Z0qzRofgt9+Q+2YMI8BRgzZsywe++91\/0oPCmngpZJkya5l\/PETfuNHTvWBUBaTlL\/Xy\/Zhdp0PVqN4Gc\/+5lbRlOhgeZd+H\/\/7\/\/tcA8pvNL9oOChoqLC1fmrr75KOkdDOMhR6KMAS70bwmWo3lrONLhXVZ6GXWhujGbNmrl7U9ehIRqFGrbDc5X+zuS5Su7Dc1Wo32icFwEEECisACFEYf05OwII5EkgsXvz5s2b3Vdq9UxI3IIXQ3VvX7BggU2dOrVyWESfPn1c1\/p69eq5ZTWDL\/nhCQXVk0FfuMMTDuocehHRF+02bdq4Y\/VFuxi3cG+FYEhBYl1GjBjhxqtr8shLL720clhAUB8FOL1793ZOiathhLtWJ\/aUCHvoRVxDWD788MOCMamHiiYdVV2DISrhi1FA9cUXX7iQJbxUZjBER71BtD377LM2evTopPUIVkFRWeHARvfaxRdf7EKv8JKdBcNIcmKeq8xbg+dqmxXPVeb3DXsigAACpShACFGKrUqdEECgUkD\/sasXYvVs0AuxtnTd1hU8KCjQy9Urr7zivkCHh0aoPH3l1hCMxC\/548aNc5OnadNcB+ppEby864ufuhPrRURf0TXZ5PPPP1+ULRX0QlBdFNY8\/vjjlfMVBBesiRTbtm3rVgLRS3Sw6djLLrvM1VP\/XxNwakuciDJVT4liAjniiCNczwT1aNCmnjDq2aCeB+qBoN40wTwe6jUiJ03Gqd4Iqrvuo0MOOcQd+9RTT6VculW9ShSG7b777vbee++54EFbuIyqetjk243nKntxnqv\/mPFcZX\/vcAQCCCBQagKEEKXWotQHAQQqX+A07OKss86qXJFAL\/\/PPPOMmzwy1ZwLCiuGDBniyrj99tvd\/uEX7Kuvvtp9FQ9ePsNf8hVg6BhNqKhNAcTbb7\/tJgvUvAAauqAX1DgsuRnurZA4HEB1u\/\/++109Vf\/+\/fu7+qrngpao7NSpk6vnH\/\/4Rzc\/hAIdWWhIhSbk1KYhDQpiNDljYk+JYriFw8MkEpdQDa4vvJSqejwopAi3rcpQ2KIeMBpKoTAs1XAJ9ZI4\/vjjXY8ShTrqXaEt3MNGw1LSzdGRD7fw3AbBSh88V5nL81x1N\/0OTbY0cTk\/V5nfQeyJAAIIlIYAIURptCO1QACBkEDXrl1t4MCB1qpVK\/clPtVLZDK0oBu9jtFkky+88ILbTS9c6hWhOQr0sqnx+\/qCnTjnQXi\/xNUiki3HmO+G0wvxqlWrMjptMExA9dDwEb1QB5uW0VRvgEceecRZ6OumhpcoVFDA88ADD9jDDz9s5557rg0YMMD1Qkl8idbEnPqjF9uHHnrIpk2bltF1+d4p3BtGPRDuvvtue+KJJ1Ketm\/fvvab3\/zG1TFx0tKRI0faiSee6Ew0h0ZwPyUWlm45yqAM3XfpVl\/x7cJzlVqY56rqu4\/nqmoj9kAAAQTKRYAQolxamnoiUAYC+uKu8OGwww5zKzNs3bp1hzkdqmI46qijXNigL9J64dOwivALdvBSqkkJb7zxRjdRpfbVC7omaAw29Xw47bTTXBCybt06N2xBXfILteqFbDQcJOiBECybmc4jPDliuuEA4V4D6jUxceLEymU527dv74YhBCtAaBiH\/mjTi5va65\/\/\/Kc999xzVTVN3n6u4RAKFhLnaEh3ARq2ofZWDxnNk6EeIfPnz3c9YIL7JN0qH0EIIT\/dS5988sl291JQhu477ZtpkJQLNJ6r1Io8V5nfYTxXmVuxJwIIIFDqAoQQpd7C1A+BMhIIJvJTAKGXZi1tqC\/y2awYoK\/yOj4ICzQ8Qy99emFOfMEOVrpQ2JHYU6DY2INeB8l6JFT1cn3mmWeaekMkGw4QnvVfL9\/XXXfddmFMOITQefTyrLkSwsNciskqPHloNi\/84VU\/EufRUK+RINQIhzBBvXWsAi8FFqmGbahXyhlnnGE\/\/PDDDsOEfPvxXKUW5rnK7O7jucrMib0QQACBchEghCiXlqaeCJSBQHgiP3VdD680kKz62j94OZw+ffoOu4THb+uFVCtCaOhBsAVfr\/XPid3wi4070yUCg+vWC7F6KXTs2NEFEEEdE1+ie\/ToYddee60LbjRPRKJj8JKmL\/vqFaKeAlop4s4778wqHMqXp+aw0HKj8ko3mWSy69ESnlotRd3OtSSnJuhcsmSJ++dgstPwUBWVEZ6wVD0vNCRFw1gSty5dutioUaPcZJgaAqPy8rXxXKWW5rnK7C7kucrMib0QQACBchEghCiXlqaeCJSJQHgiv3QTHobHty9btswNwdBX6PCm0KFnz56uB0Syn+tFWi\/rCjy0fKNWTtDfaSWIYtzCSwQqTNEQAg0lCW8agqFhG5r7IhjSovrrRVq9KBKPC+bQUBmJIYSGschNwYMmpdRyp99\/\/\/0OS5cWk5V6fWjJUW1a6eKxxx7L6vK0coqG9GgITnhiU5Wr0EqG6jnz7bffuvtKw1S0DKn+Tkt8akWVxJ47mgBTx2rCT\/WyKMS8EDxXqW8DnquqHxGeq6qN2AMBBBAoJwFCiHJqbeqKQJkIBBP5qbqJS0MGY7j1hT88b4ReHt98883thIJlKD\/77DMtR9tIAAAgAElEQVQ3gWJ4C148NARBQz6OO+44N9fBvHnzilo5GEKSOGQg2aoHmkhTy05q0kj1DtCSnfparxUgtKSkNi1Vqgk8Ndu9Ag3NB\/HBBx+YuvDLSF\/u47AaSNBoQaii4EQ9aaZOnZpVe5533nlutZDE4xOHa2ji0wYNGriyV6xY4Sa+lHOyoUNBsBEEFeptkc0Qo6wqkGZnnqvUODxX6e8ynqtcPYWUgwACCJSGACFEabQjtUAAgZBAeDLAYGlITTCpJRI1x4O+RmvTl2gFB3\/+85+TvtSpV4O+5mseA02uGEzmePrpp9tFF11k9evXd93i062cUGwNk2yJwL333tuFLFpCNFhN5NVXX7VJkyZV9pQIm+qlWV\/sZapNNgoodGx404u2JpzUUpyFeGmujr16GyhwUc8WzfOhFT+y2cLHa9iJlt4MtmC4hrrwq+w77rjD\/UhDNtJtWmFE99zTTz\/tgpFCWfJcpW4lnqv0TwnPVTa\/RdgXAQQQKH0BQojSb2NqiEBZCgSTAeqLtOZz0Iufur5r0\/wNmhhR3drTrVYRXl5Sx2gogr74a2lKvQj+6U9\/qnyRjBNysPRmrVq13Fd42WjeB\/VyUC8G9XJI1qNDwzTOOuss03HhF3QN1dCKDhqGoN4lKkdzIujLfjGtepFJG\/34xz92vTm01OjXX3\/thmYkDllJV066EELHyUmBTbqeD5lcZ6H24blKLc9zldqG56pQTyznRQABBIpTgBCiONuFq0IAgYgC4ckAg6KqeslOPKW60OuruOaPCCZn1D56cdcEjNnOFxCxSjk7PLz0ZlCoeoVoUkR9bU+1JU6wqJ4S4fkvGjZsaG3atHFzP6gHSlw39V44\/vjj3VwfVU1umlhH9bQZMmSI6yVTneEcxW7Gc5W6hXiu0t+9PFfF\/nRzfQgggED+BAgh8mfNmRBAIM8C4ckAFRxobP3f\/va3rK9C3ehPPvlkN4xDwxT0op6uB0XWJyjAAeGlBdXDQys5KIioagvGdqvHw8cff+wmt9RwlVLawpMwpprAM1V9g6U0dX\/cdNNN9sILL5QSjasLz1XqJuW5Sm3Dc1VyvwqoEAIIIFBtAUKIatNxIAIIFLtAeDLA6nzVLvb6Rbm+8LKLGmqSuPRmqrITj0u1pGSUayv0seH7JpvJIMNzJmilFc1BUqj5G3wa8lyl1uW5Sm+jFWOOPPLIytVgMplktVyeK5\/PLGUjgAACxSZACFFsLcL1IIBATgWCyQDVjVxj+zUmf+7cuTk9R1wLC3+Z1CofV111lc2fP7\/K6sj06quvdktKVjWvRpWFFekO4YkGFWBVtcKHuuJr6E6HDh1szZo1bjLO559\/vkhrF\/2yeK5SG\/JcpbbhuYr+7FECAgggUAoChBCl0IrUAQEE0gooeNBykdr+8pe\/2KhRoxD7P4FgZQv9Y+JypuWOpGVGtQqKhuEoiNBQnLvuustNUBreNFRnwIABbuLTTAKLUnHluUrdkjxXqW14rkrlNwD1QAABBKovQAhRfTuORACBiALqnbDffvu51RY0r8Cnn34ascTkh7du3dqt+KAlKIMlO19++WUv58pVofmySbf0Zq7q4qOcfPlo\/oOLL77YLdmpTSGD5s7Q\/aolSVu0aGG6Fv1\/DWuZOXOmTZ061UeVMy4zXzY8V6mbhOcq\/e0ax+cq4weQHRFAAAEEqhQghKiSiB0QQCDXAieddJL96le\/sn333de0hGawVVRUuJ4KPrr4h5cWfPfdd23w4MFFOV6\/EDay6N27t2uLN954w63uUKxzGRTC58ADD7QrrrjC2rVrt90qKcF9q1VXNMTngQcecENUCrUVwobnKnVr81ylfxLi8lwV6nnmvAgggEApCxBClHLrUjcEikxAXwcHDhxoHTt2TPoyF1yu5ie45ZZb7M0338xZDZo0aeJWx9CY\/Q0bNrigQ1+ti2UrpE1VS28Wg1EhfYL66xr+67\/+y37yk5+4+1fhg3rv\/PnPfy7oPCOFtOG5Sv108Fxl9pujWJ+rzK6evRBAAAEEqiNACFEdNY5BAIGsBDRp3+WXX26dO3c2Le2obfny5fbXv\/7VvcBpzL0mczv++OOtWbNm7udaUvPWW2+12bNnZ3WudDtrXggtRdmwYUM3rl\/LS2qyykJuxWITXnpTL9b68q+hK4XeisWn0A7Jzl8sNjxXqe8OnqtifHK4JgQQQACBQgsQQhS6BTg\/AiUsoOXqzj\/\/fDvrrLPcuHlterH905\/+ZDNmzLC1a9duV3u9VI0YMcIOPvhgN8Y+10GBrmfs2LGuW72Wlnz66acLpl+MNlrRQUNkCm2jRik2n4LdKElOXGw2PFep7w7Z8FwV09PDtSCAAAIIFIMAIUQxtALXgEAJCnTq1Mkt46hgQYGChkC89tprdscdd6TtfaCwQmvJa9jE1q1bS3I1C2zS3\/D4pPbBBpvq\/uuCe6e6chyHAAIIIJBrAUKIXItSHgIIOAGFD5qDYZ999nGrBjz44IPuTyZbeC35uKxmkUm9gn2wSa+FT2ofbLDJ5ndNeF\/unerKcRwCCCCAQK4FCCFyLUp5CCBQKaD14LW8oeaB+Pjjj90cDFraMJNNc0hoGIeW73zxxRdt2LBhmRwWm32wSd9U+KT2wQab6v6i496prhzHIYAAAgjkUoAQIpealIUAAtsJaDz05MmT7ZBDDsm6N0Tr1q1t\/Pjx1rJlS1u2bJkNHTq0oCsQ5LppsUkvik9qH2ywqe7vI+6d6spxHAIIIIBALgUIIXKpSVkIlJnA0UcfbZr9fb\/99nM1nzdvnlv28uWXX66U0KoXV111lTVu3NgWLVrkwoT58+dnJKVJKnv27JmzJTVPPvlku\/DCC+2VV16xcePGZXQN1d0Jm\/Ry+KT20ZKFxxxzjOtBpLlU\/vGPf9j777+\/3QHl+lxhk\/65wqe6v7E5DgEEEEAgnwKEEPnU5lwIlIiAQgeFCR07drSaNWtuV6uNGzfac88955bX3LRpk\/vZyJEj7cQTT3T\/f9asWRkHAGeeeaZdeuml7mXskUcecb0qqrN17drVhQ9a+UHX9NJLL9lNN920w+oc1Sk78Rhs0ivik9rnwAMPdEujavWW8HOlICLZPVtOzxU26Z8rfHLx25syEEAAAQTyJUAIkS9pzoNAiQh06dLFrXrRvHlzq6iocCtevPHGG27IhV721eMhcSJKfZ278cYb3TErVqxwy2TOmTOnShHN5j5mzBhXZnXmhdBEbJpbonPnzlanTh1bsGCBTZ061b3Q+diwSa+KT2qf7t27u+dq1113dc+VehXpf7VKjFaMSbZSTLk8V9ikf67w8fHbnDIRQAABBHwKEEL41KVsBEpMQC9D6o2gr9kLFy603\/3ud\/bhhx9W1jL8H8Nffvml+6q7ZMkS9\/PBgwdb7969XRig0GLIkCGVPSVSMYVDiKeeeirjHhQNGza0vn372umnn+5e4JYuXepW5vjzn\/9c5Tmr22TYpJfDJ7VP2Obzzz83DUPS86NNQdrNN99sbdu2dQHetddea++9915lYeX0XGGz4z3EvVPd39gchwACCCBQSAFCiELqc24EYiZw7rnn2oABA9yLvIZbPP\/88zvU4JprrrFTTz3VfcVVd\/Ggx0P4P5bVU0JhxhNPPJFW4LzzzrP+\/fu7fe6\/\/36bPn16lWKa90HXqF4XOs8zzzxjU6ZM8TL0Inwx2KRvGnxS+2helUGDBpmGMiV7roKfqwTdy5p3JdhK\/bnCJv1zhU+V\/0pgBwQQQACBIhQghCjCRuGSEChWgWCiyHQTTKZ7YQp+pjke1N1cX3FXrlyZtLr777+\/m7dhzz33zGh1jPBcA5s3b3ZLgmp1DZ0nHxs26ZXxSe2j5+Ccc85JOXFr0CNIy9XefvvtLlgLb6X8XGGT\/rnCJx+\/3TkHAggggECuBQghci1KeQiUsEDwIrl48WI3MeUXX3yxQ22DFyIFAYkvTFoeTn935JFHuq++M2bMsHvvvXeHMvbZZx8bPXq0tWnTxu335JNP2oQJE5LKqrv6ZZddZkcddVRe5n1I1bzYZBZCcO\/s6BS8SCYbbqG91RtIvYI0rEgTtcowvJXyc4VNZiEE904J\/4uXqiGAAAIlKEAIUYKNSpUQ8CWgYQ7nn3++G44xbdo0e\/jhh3c4VVUvDVqacfjw4ZVzNdxwww2Vyw\/qZUrln3XWWe7nW7ZscZNIXn\/99UnnctCM8Ootsfvuu7seFY8\/\/rg99NBD3uZ9SOeKTfq7Dp\/UPgoYfv3rX9uqVats4sSJNnv27MqddY8rkFPYtmbNGvf3Wi1Dy+BqnpMgkCjV5wqb9M8VPr7+bUe5CCCAAAI+BQghfOpSNgIlJqDZ+NXr4B\/\/+Id74V+7du0ONbzzzjvtiCOOsPnz59sll1ziXqwSN80bccopp7i\/\/stf\/mKjRo1yK2sMHDjQWrVqZTVq1HAvWppI8o477kgbKqgHglYOuO+++3b4QpxPfmzSa+OT2keBm+778IST2rtPnz6uB4R+nmxTTyQ9O3PnznU\/LsXnCpv0zxU++fwtz7kQQAABBHIlQAiRK0nKQQABa926tZuHoWXLlvbss8+6L7jJtvB++rqrr7kagqGVMxQo+F5KsxBNhU16dXx29FFQp9BPq0IoZHvrrbesR48ebuLVIKwLL11bTs8VNumfJ3wK8VuecyKAAAIIZCpACJGpFPshgECVAunmg0g8+MILL3TLaCp4CLZ8LKVZZSU87YBNelh8dvRp0qSJdezY0V577bXtegPp67eGbbRr186tQqMhSS+88IIroFyeK2zSP0\/4ePpFTrEIIIAAAjkRIITICSOFIICABDR5pCaI\/Oqrr9wX3CVLlqSE0X8ka\/8OHTrkdSnNQrUUNunl8cnuzgyWPNU8KpoHRXO0aCu35yqZGjbp7yV8snvW2BsBBBBAIPcChBC5N6VEBMpSQEtqaiiGJol86qmnbNy4cTs4HHrooW6uhw8\/\/ND97KSTTrJjjz3W7rnnnrwtpVmIxsEmvTo+2d+VwbKdjRs3tkceecQmT55cWUi5PFep1LBJfz\/hk\/3zxhEIIIAAArkVIITIrSelIVC2AppAT0sJaknNcPdwgWi+B01S2blzZ\/v4449NK2hohY1y2bBJ39L4ZP8kdOnSxU1KWb9+\/e16QmRfUukdgU36NsWn9O55aoQAAgjETYAQIm4txvUiUKQCwaoYmkRPIYNWxWjYsKENGjTIevXqZfXq1XNXrnkfbrvtNrfEYLls2KRvaXyS+2ioRd26dZOuQnP55Ze7pWxXr15tWiFGk1aW04ZN+tbGp5yeBuqKAAIIxE+AECJ+bcYVI1B0AuFZ+YOhGCeffLKbxb958+buetevX2\/PPPOMTZkyJelLVdFVKkcXhE16SHyS+xx44IE2bNgwF+RpaNObb75ZuaNCPQV9O++8s2l1DC3NWU4bNulbG59yehqoKwIIIBBPAUKIeLYbV41AUQkE3Xu10sWsWbPskEMOsX333ddq1qxpW7ZssQ8++MDNFzFv3ryiuu58XAw26ZXxSe4zZswYtxxnjRo1XID39ttv26JFi6xNmzbWvn1710NCQ5uGDBliK1euzMetXDTnwCZ9U+BTNLcqF4IAAgggkEKAEIJbAwEEIgsEyyvqxSjYtm7dagsWLHCz9gfLB0Y+UQwLwCZ9o+GT3Efd6TXM4phjjnGBQ3jT5K6vvvqq6yFRbgGEHLBJ\/0zhE8N\/UXDJCCCAQJkJEEKUWYNTXQR8CCS+SOrF6PHHH3cT5pXTBJTJbLHJLoTg3tne66CDDrLTTjvNWrVq5X6gYO\/JJ5+0999\/38ejHKsysUnfXPjE6nbmYhFAAIGyEiCEKKvmprII+BE4+OCD7eabb7ZGjRq5L7STJk2yxYsX+zlZzErFJn2D4ROzG5rLRQABBBBAAAEEIgoQQkQE5HAEEPhP9+i+ffu6FS\/Kcd6HdPcANumfEHz4DYIAAggggAACCJSXACFEebU3tUUAAQQQQAABBBBAAAEEEECgYAKEEAWj58QIIIAAAggggAACCCCAAAIIlJcAIUR5tTe1RQABBBBAAAEEEEAAAQQQQKBgAoQQBaPnxAgggAACCCCAAAIIIIAAAgiUlwAhRHm1N7VFAAEEEEAAAQQQQAABBBBAoGAChBAFo+fECCCAAAIIIIAAAggggAACCJSXACFEebU3tUUAAQQQQAABBBBAoKgFguWbTz\/9dGvWrJnVqFHD1qxZY6+\/\/rpNnTrVFi9eXNTXz8UhgEB6AUII7hAEEEAAAQQQQAABBBAoCgEFECNGjLDu3bu761m4cKGtX7\/e9tprL2vUqJF9\/fXXNnz4cJs7d25RXC8XgQAC2QsQQmRvxhEIIIAAAggggAACCCDgQeCUU06xyy67zGrVqmX33HOPPfroo+4s++yzj40ePdratGljL774og0bNszD2SkSAQTyIUAIkQ9lzoEAAggggAACCCCAAAJVCkyYMMGOOuooe\/PNN+3SSy\/dbv\/zzjvP+vfvb99++60NHTrUvvjiiyrLYwcEECg+AUKI4msTrggBBBBAAAEEEEAAgbITaNq0qY0dO9Z+8pOf2MyZM23atGnbGZx99tk2aNAgW7dunV1\/\/fX21ltvlZ0RFUagFAQIIUqhFakDAggggAACCCCAAAIlLqDhGMcff7x9\/vnnNnjwYFu1alWJ15jqIVCaAoQQpdmu1AoBBBBAAAEEEEAAgZIQ2H\/\/\/d0wjM6dO9vWrVu3myuiJCpIJRAoMwFCiDJrcKqLAAIIIIAAAggggEAcBPbdd18bP3687bHHHu5yKyoqbPr06e4PGwIIxFeAECK+bceVI4AAAggggAACCJS5QK9evbYTUE+BGjVqFFQl2TU888wzWV\/ToYce6ian3Lx5szVv3tw0Z8TGjRvtueees9tuu802bdqUdZkcgAAChRcghCh8G3AFCCCAAAIIIIAAAghUS+DVV1+12rUXh45VALG1WmXl7qBt17Bp0396MWjFiyhb7dq17fLLLzct4bllyxY3aeXDDz8cpUiORQCBAgkQQhQIntMigAACCCCAAAIIIBBVQCFEiz0GW\/0G\/4xalJfj13zf05YvGx45hNDFKYiYMmWKHXTQQfbee+\/ZxRdf7OWaKRQBBPwKEEL49aV0BLwKBGMkk52kWLtjegVJUjgO\/0HBAYfw45GL+yEXZUT9fcA1xOu+Xrw4\/LU+autzfCDgQogWl1r9+kUaQqzpacuXX5eTEEJ1vuaaa+zUU0+1zz77zPr168eNgAACMRQghIhho3HJCAQCGiupLwJsCCCAAAIIFLuAQogzzjij2C8zdtdXSiGE\/rtm5MiR1qhRI5s4caIlm0dixIgR1rNnT0KI2N2pXDAC2wQIIbgbEIixQBBCPHDHAvt26YaC1+Rnxza1Zs3r2qxH+dqV2BhtD2xsp5yzh9123ecFb6divICrbmpjsx5ZbJ99uKYYL6+g13RKn\/+Mp+a52rEZeK7S35p6rorl3w9qqyN+boQQHn6bKIT40Y8us\/r13\/VQevQi16w5yb799tqMekK0aNHCJk2aZHvvvbf99a9\/NQUO4W2XXXaxyZMn23777Zf059GvlhIQQCAfAoQQ+VDmHAh4EghCiGH9PyqKEOKUPi2sbcedeNFO0t5tOzY2vRD85hfF2V3W0y2acbH3\/fmn7mXplb9\/l\/Ex5bLjBZe3clX9\/R0LyqXKGdfzZ8fuZr++vBXPVQoxPVcKPj\/7oPDhntqq5y\/rEkJkfHdnvqMLIZpfUbwhRIVCiGEZhRCqtSafPOuss2zNmjUucAh6QzRs2ND1kujatautXLnSxo4da3PmzMkcij0RQKBoBAghiqYpuBAEshcghMjerFBHEEKklyeESO1DCJHahhCi6ueKEKJQv\/Xzd95SCyHU20E9IDp37uyW4Fy4cKGtW7fONA+WfrZ27Vq75557bObMmflD5kwIIJBTAUKInHJSGAL5FSCEyK93lLMRQlT9skRPiORGhBCEENX93UNPiOrKxes4hRDNd7\/C6td7rygvvKLiRPt2ReY9IVQJrYLRt29fO\/30061Zs2ZWs2ZNq6iosE8++cQN15g3b15R1pWLQgCBzAQIITJzYi8EilKg2EIIvWg3bV6XLvVJ7ha5dDl2N5v16JKivJcKfVEayjPn798VxbCiQlsknl9f+zXnSzF0qS82G\/3O0VwDPFfJW6aYniuGY\/h7ekoxhPCnRckIIFAMAoQQxdAKXAMC1RQothCimtXgMAQQQACBEhcghPDXwC6EaHZl8faEWKueEFdnPCeEPylKRgCBYhEghCiWluA6EKiGACFENdA4BAEEEEAg7wKEEP7IXQjRdKjVq1ukwzHWnWDfrbyKEMLfLUDJCMROgBAidk3GBSOwTYAQgrsBAQQQQCAOAoQQ\/lqJEMKfLSUjgIAfAUIIP66UikBeBAgh8sLMSRBAAAEEIgoQQkQETHO4CyF2U0+I9\/2dJELJFeoJsWooPSEiGHIoAqUmQAhRai1KfcpKgBCirJqbyiKAAAKxFSCE8Nd0hBD+bCkZAQT8CBBC+HGlVATyIkAIkRdmToIAAgggEFGAECIiYJrDXQixy1XF2xPih+Ptu9X0hPB3B1AyAvETIISIX5txxQhUChBCcDMggAACCMRBgBDCXysphNh9l6utXp0iHY7xw\/G24vshDMfwdwtQMgKxEyCEiF2TccEIbBMghOBuQAABBBCIgwAhhL9WIoTwZ0vJCCDgR4AQwo8rpSKQFwFCiLwwcxIEEEAAgYgChBARAdMc7kKInYcVb0+I9cfbijVX0hPC3y1AyQjEToAQInZNxgUjsE2AEIK7AQEEEEAgDgKEEP5aiRDCny0lI4CAHwFCCD+ulIpAXgQIIfLCzEkQQAABBCIKEEJEBExzuAshdlJPiA\/8nSRCyRXrj7MVFfSEiEDIoQiUnAAhRMk1KRUqJwFCiHJqbeqKAAIIxFeAEMJf27kQovE1Vq92kYYQG46zFWuvYDiGv1uAkhGInQAhROyajAtGYJsAIQR3AwIIIIBAHAQIIfy1EiGEP1tKRgABPwKEEH5cKRWBvAgQQuSFmZMggAACCEQUIISICJjmcBdCNLq2iHtCHGsr1tETwt8dQMkIxE+AECJ+bcYVI1ApQAjBzYAAAgggEAcBQgh\/rUQI4c+WkhFAwI8AIYQfV0pFIC8ChBB5YeYkCCCAAAIRBQghIgKmOdyFEA2vs3q1inROiI3H2oofLmdOCH+3ACUjEDsBQojYNRkXjMA2AUII7gYEEEAAgTgIEEL4ayUXQjQo8hBiPSGEvzuAkhGInwAhRPzajCtGoFKAEIKbAQEEEEAgDgKEEP5aiRDCny0lI4CAHwFCCD+usSh1jz32sEsuucQOP\/xwa9KkidWsWdM2bNhgixcvthkzZtjTTz+9Qz0efPBBa9u2bcr6bdmyxdauXWsLFiywxx9\/3J577rmcWwwePNjOOeecjMtVnaZMmWIzZ87M+Ji47EgIEZeW4joRQACB8hYghPDX\/i6EqKeeEB\/6O0mEkis2HWsrNlzGcIwIhhyKQKkJEEKUWotmWJ\/u3bvb1VdfbbvuumvSIxQmvPTSS3b99dfbpk2bKvepKoQIF6Yy3nnnHbvhhhts5cqVGV5Z1bsRQmwzIoSo+n5hDwQQQACBwgsQQvhrA0IIf7aUjAACfgQIIfy4FnWprVu3tttuu8323HNPW79+veutoHBh+fLl1qNHD7vgggtsn332sY0bN9r\/\/M\/\/2OTJk3cIIZYuXep6F6xatWq7uv7oRz+yI4880jp16mSNGzd2P\/v4449tyJAhOQsighBCPRwee+wxF3Sk2zZv3mzz5s3L2fmLqXEJIYqpNbgWBBBAAIFUAoQQ\/u4NF0LUHW71ahZpT4jNPWzFRnpC+LsDKBmB+AkQQsSvzSJf8cUXX2x9+\/Z1PRwUPuhPeNt\/\/\/3tpptuciHFV199ZZdddpktWbLE7RL0hFi0aJENHTrU5s+fn\/R6FGKMHj3a2rRpYwoBNDTjjjvuiHztKiAcQpTqMItMoQghMpViPwQQQACBQgoQQvjTJ4TwZ0vJCCDgR4AQwo9rUZd6991328EHH7xDwBC+6GuuucZOPfVUW7NmjRuS8frrr2cVQmhnvSCPGTPGDflYtmyZCy3mzp0b2YYQYhshIUTk24kCEEAAAQTyIEAI4Q9ZIUTzOsXdE+K7TfSE8HcHUDIC8RMghIhfm0W64qZNm7qhGOqpoEBAvSKSbcGLfpQQQuUGYYaGfUybNs0efvjhSNevg3MRQtSuXdt69+7tghZN0Fm3bl13XRrioUk1NYllsok5tY\/279evn3Xt2rVyQs+Kigr75JNPbNKkSW7oR+KW7BiZaKjKQw89VBnyZItDCJGtGPsjgAACCBRCgBDCn7oLIWpfb\/VqFOlwjC097LvNlzIxpb9bgJIRiJ0AIUTsmiw\/F3zLLbdYt27dbMWKFXbttdfae++9506c6XCM4Cp79erl5oNo0KCBPfvss26IRtQtagixyy672Pjx461Dhw5Wo0aNpJej+TCefPJJmzBhwnY\/r2pCT3ndeuutNnv27MrjunTp4iYBbd68edJzKYxQOKOQJtuNECJbMfZHAAEEECiEACGEP3VCCH+2lIwAAn4ECCH8uMa61KOPPtqGDx9uell\/\/\/33bdCgQZUrZGQbQrRv397GjRvnXsD11b9\/\/\/6RbaKGECNHjrQTTzzR1Un\/4r7\/\/vtdrxDVt0+fPnbGGWe4STUTh5CE58oIT+i5evVqN8eGelbouC+\/\/NKuvPJKt9RpeBJQ9bL4+9\/\/btOnT7evv\/56u0lAtaypelHMmjUrKx9CiKy42BkBBBBAoEAChBD+4F0IUesGq1\/EPSG+3TKYnhD+bgFKRiB2AoQQsWsyvxesF\/Hbb7\/d9RLQUAwN3Xj++ecrT5ptCKGXcPU6aNmypX322fBtJiAAACAASURBVGduGEPULZslOhMn0FSQoOvZfffd7Y033nC9NMJLkOragok7161bZzfffLO98MIL7pI1p4UCCvWS0Lwajz766HZVUd30R0M9NMRCPRuCY3SOZD0rwsFGYuCTiRMhRCZK7IMAAgggUGgBQgh\/LUAI4c+WkhFAwI8AIYQf11iWGh6mkOqlOe4hxAknnGC\/\/e1vXY8F1UW9EhK3s88+2\/X+0BasvqFgQaFCu3bt3Iogl1xyyQ7Lk2reB60Asttuu7ngYurUqXbXXXe53hCpjtE5FKqoB4ZCH\/XS0H9MZLoRQmQqxX4IIIAAAoUUIITwp+9CiBpF3BNiaw\/7dis9IfzdAZSMQPwECCHi12Zerlgv0DfeeKPrAaEAQnMaaP6GxF4CxRRCaHjDY489Zu+8805Kkx9++ME++uijHeoRPkAhQatWreywww6zjh07ukk769Wr5yapDEKIfffd1\/WgkJNsNE9GVZtWIFFPCq0O8uKLL9qwYcOSHhLMm1GrVi03NCRZMJLqXIQQVbUCP0cAAQQQKAYBQgh\/raAQ4kd2g9W3j\/ydJELJa+zn9q0RQkQg5FAESk6AEKLkmjT7Ch144IF23XXXuS\/2Gmrw3HPPuckVEwMIlZxtCHH44Ye7ZTqbNGniJrdMtRpHNlcddU4I9WrQHA56+ddcFcHKGInXEA4hOnXq5OqhHhSPPPKITZ48ucpLDh9T5c7\/t0OmZQflBSHErEcW2\/KlGypP89kHa+zb0D9nen72QwABBBBAIBcCbTs2tqbN\/7PylLa2HXeyfTusd8Ma2XIrQAiRW09KQwAB\/wKEEP6Ni\/oMGp5w+eWXu6\/1eun+wx\/+4IYRpNqyDSGCoQ160S+G1TEUQIwdO9Ytr6mVMbZu3WqaFFKTUC5ZssTNW7FlyxY799xzHUHQE6LYQ4hwAKHrVijxyt+\/K+p7j4tDAAEEEChdgVP6tLCfHde0soLNmtd1EzYTQuS+zRVCtNg6oqh7Qiyv8Vsmpsx901MiArEVIISIbdNFv\/AzzzzT9UzQ1329iD\/wwANuqch0W7YhhIZ0HH\/88dsNbYh65VF6QihcGDBggOv98Oabb9rEiRPdahbhLdmcEOFVPjIdjhHuBaJwR\/NF5HpjOEauRSkPAQQQQMCHAMMxfKj+p0xCCH+2lIwAAn4ECCH8uBZ9qeEAYsWKFe4FObwKRqoKZBNC6AVZQxjUy0JLUl566aXuK0jULUoIccstt1i3bt1Mdda8Dhoikrhdc801duqpp24XnGg4STDJ5Oeff+4mk1y1atUOx2rVDK14oX20NKn+7L333jssdRrVIDieECJXkpSDAAIIIOBTgBDCn64LIbaMtPpbi3ROiBrdbXlNekL4uwMoGYH4CRBCxK\/NIl\/xQQcd5Cah1HwIehnX\/A\/6up\/JlmkIockd1QuiTZs2bp6JGTNm2L333pvJKarcJ1chxIgRI+ytt97a7nyaH0PXrQkow3NCaKeqlujs3r27KcBQYBEMPdE5TjrpJFfWPffcs8OynkG5J598suuNookpn3jiiSoNCCEyJmJHBBBAAIEiECCE8NcICiH22Py7og4hltUaxHAMf7cAJSMQOwFCiNg1WfQLnjBhgvsXwfr1690L7xtvvJGy0M2bN9u8efNs5cqVbp8ghFi6dKmbLyGxN4BWkdAwBK0M0ahRIzfnwuuvv25XXXVV2hUqsqlVlBBCw080KaVWolBvhTvvvNMFES1atLBf\/epXduKJJ5qWKtWWGEKoh8NNN91ke+65pwsM\/vd\/\/9eFBtqvZ8+e1q9fP2vWrJkLdjTvxJw5c1yviOAYeWvSTxlq\/gn9rH\/\/\/ta5c2c3PETOqltgnYkJPSEyUWIfBBBAAIFCCxBC+GsBQgh\/tpSMAAJ+BAgh\/LgWbakKH0aNGmU77bRTRteY+CIehBCZHKwJHl977TXX6yKbF+uqyo4SQqiHg4ZIKABItqm+GqKx3377uTBCPTjCE3Wqt8PVV1\/thpgk2xROqMfDzJkzK39c1THaceHChaahIpqnIpuNECIbLfZFAAEEECiUACGEP3kXQmz8nTUo0uEY39fsbstq0xPC3x1AyQjET4AQIn5tFumKw6tVZFJQtiGEhl5UVFS4XgZ6EX\/55ZczOU1W+0QJIXQiBREDBw40rXihSTm1Soauee7cufbQQw\/Zp59+6pbg1FCS999\/3wYNGrRdL45Ux3\/yySc2adIk16MhcdMx6imhVTk0XKNmzZpumIrCmX\/84x+uR0V1ghpCiKxuHXZGAAEEECiQACGEP3hCCH+2lIwAAn4ECCH8uFIqAnkRIITICzMnQQABBBCIKEAIEREwzeGVIcSWj\/2dJELJ39dST4iBzAkRwZBDESg1AUKIUmtR6lNWAoQQZdXcVBYBBBCIrQAhhL+mUwjRcv0oa1C0IcQxtrQuIYS\/O4CSEYifACFE\/NqMK0agUoAQgpsBAQQQQCAOAoQQ\/lqJEMKfLSUjgIAfAUIIP66UikBeBAgh8sLMSRBAAAEEIgoQQkQETHO4Qog9fxhtDTYX53CM1bWPsaX1LmE4hr9bgJIRiJ0AIUTsmizeF6zJIMeMGeMmhMx2S5wkM9vjS3F\/QohSbFXqhAACCJSeACGEvzYlhPBnS8kIIOBHgBDCjyulphBo166dW22iYcOGWRtpNYnHHnvMZs+enfWxpXoAIUSptiz1QgABBEpLgBDCX3u6EGJdkfeEqE9PCH93ACUjED8BQoj4tRlXjEClACEENwMCCCCAQBwECCH8tZILISpuLN7hGHWOsaUNLmY4hr9bgJIRiJ0AIUTsmowLRmCbACEEdwMCCCCAQBwECCH8tRIhhD9bSkYAAT8ChBB+XCkVgbwIEELkhZmTIIAAAghEFCCEiAiY5nCFEHupJ8SmT\/ydJELJq+t2s2\/oCRFBkEMRKD0BQojSa1NqVEYChBBl1NhUFQEEEIixACGEv8YjhPBnS8kIIOBHgBDCjyulIpAXAUKIvDBzEgQQQACBiAKEEBEB0xzuQojvxxR3T4hGFzEnhL9bgJIRiJ0AIUTsmowLRmCbACEEdwMCCCCAQBwECCH8tZILIVaPLd4Qol5X+4YQwt8NQMkIxFCAECKGjcYlIxAIEEJwLyCAAAIIxEGAEMJfKxFC+LOlZAQQ8CNACOHHlVIRyIsAIURemDkJAggggEBEAUKIiIBpDnchxKqbrcHGIp2YUj0hdhrAcAx\/twAlIxA7AUKI2DUZF4zANgFCCO4GBBBAAIE4CBBC+GslQgh\/tpSMAAJ+BAgh\/LhSKgJ5ESCEyAszJ0EAAQQQiChACBERMM3hLoRYqZ4Qn\/o7SYSSV9c\/mp4QEfw4FIFSFCCEKMVWpU5lI0AIUTZNTUURQACBWAsQQvhrPhdCrBhnDTYUaQjR4Gj7ZuffMBzD3y1AyQjEToAQInZNxgUjsE2AEIK7AQEEEEAgDgKEEP5aiRDCny0lI4CAHwFCCD+ulIpAXgQIIfLCzEkQQAABBCIKEEJEBExzuAshvruluHtCNOlPTwh\/twAlIxA7AUKI2DUZF4zANgFCCO4GBBBAAIE4CBBC+GslQgh\/tpSMAAJ+BAgh\/LhSKgJ5ESCEyAszJ0EAAQQQiChACBERMM3hLoT4Vj0hPvN3kgglr27Qxb7ZhZ4QEQg5FIGSEyCEKLkmpULlJEAIUU6tTV0RQACB+AoQQvhrOxdCLL\/VGqwv0hCiYRf7ZtdfMxzD3y1AyQjEToAQInZNxgUjsE2AEIK7AQEEEEAgDgKEEP5aiRDCny0lI4CAHwFCCD+ulIpAXgQIIfLCzEkQQAABBCIKEEJEBExzuAshlt1WxD0hfmbf7EZPCH93ACUjED8BQoj4tRlXjEClACEENwMCCCCAQBwECCH8tRIhhD9bSkYAAT8ChBB+XCkVgbwIEELkhZmTIIAAAghEFCCEiAiY5nCFEC2Xji\/anhDfN\/qZLd3tAuaE8HcLUDICsRMghIhdk3HBCGwTIITgbkAAAQQQiIMAIYS\/ViKE8GdLyQgg4EeAEMKPK6UikBcBQoi8MHMSBBBAAIGIAoQQEQHTHK4QYo9virsnxLKm9ITwdwdQMgLxEyCEiF+bccUIVAoQQnAzIIAAAgjEQYAQwl8rKYRo8c14q\/9DcS7Ruabxz2w5IYS\/G4CSEYihACFEDBuNS0YgECCE4F5AAAEEEIiDACGEv1YihPBnS8kIIOBHgBDCjyulIpAXAUKIvDBzEgQQQACBiAKEEBEB0xyuEKL5N7cVbU+IisY\/s2+bskSnvzuAkhGInwAhRPzajCtGoFKAEIKbAQEEEEAgDgKEEP5aiRDCny0lI4CAHwFCCD+ulIpAXgQIIfLCzEkQQAABBCIKEEJEBExzuEKI3b+5xeoV6ZwQFY272Iqm\/Vmi098tQMkIxE6AECJ2TcYFI7BNgBCCuwEBBBBAIA4ChBD+WkkhRNNvxlm9Hz71d5IIJa9tfLStbPobQogIhhyKQKkJEEKUWotSn7ISIIQoq+amsggggEBsBQgh\/DUdIYQ\/W0pGAAE\/AoQQflwpFYG8CBBC5IWZkyCAAAIIRBQghIgImOZwhRC7fXOz1f3hE38niVDyusZdbVXTAfSEiGDIoQiUmgAhRKm1KPUpKwFCiLJqbiqLAAIIxFaAEMJf0xFC+LOlZAQQ8CNACOHHlVIRyIsAIURemDkJAggggEBEAUKIiIBpDlcIscs3Y4u2J8QPjbva6qYX0RPC3y1AyQjEToAQInZNxgUjsE2AEIK7AQEEEEAgDgKEEP5aSSHEzt\/caHV++NjfSSKUvL7xMbam6cWEEBEMORSBUhMghCi1FqU+ZSVACFFWzU1lEUAAgdgKEEL4azpCCH+2lIwAAn4ECCH8uFIqAnkRIITICzMnQQABBBCIKEAIEREwzeEKIXb6ZpTVLtKeEBsaH2MVTQfSE8LfLUDJCMROgBAidk3GBSOwTYAQgrsBAQQQQCAOAoQQ\/lqJEMKfLSUjgIAfAUIIP66UikBeBAgh8sLMSRBAAAEEIgoQQkQETHO4QohG3\/zOaq\/\/yN9JIpS8oVF3W9d0ED0hIhhyKAKlJkAIUWotSn3KSoAQoqyam8oigAACsRUghPDXdAohGn4z0moVaQixsVF3+6Hpbwkh\/N0ClIxA7AQIIWLXZFwwAtsECCG4GxBAAAEE4iBACOGvlQgh\/NlSMgII+BEghPDjSqkI5EWAECIvzJwEAQQQQCCiACFERMA0hyuEqLf0hqLtCbGp0c9tw26D6Qnh7xagZARiJ0AIEbsm44IR2CZACMHdgAACCCAQBwFCCH+tRAjhz5aSEUDAjwAhhB9XSkUgLwKEEHlh5iQIIIAAAhEFCCEiAqY5XCFE3aU3WM31H\/o7SYSSNzfqYRvpCRFBkEMRKD0BQojSa1NqVEYChBBl1NhUFQEEEIixACGEv8ZTCFF76fVWo0hDiC2Netjm3S5lOIa\/W4CSEYidACFE7JqMC0ZgmwAhBHcDAggggEAcBAgh\/LUSIYQ\/W0pGAAE\/AoQQflwpFYG8CBBC5IWZkyCAAAIIRBQghIgImOZwhRA1lg0v2p4QWxv2sK27XUZPCH+3ACUjEDsBQojYNRkXjMA2AUII7gYEEEAAgTgIEEL4ayVCCH+2lIwAAn4ECCH8uFIqAnkRIITICzMnQQABBBCIKEAIEREwzeEKIWz5cLMinRPCGvYw25WeEP7uAEpGIH4ChBDxa7NqX\/HJJ59sZ599trVq1crq1q1rW7ZssdWrV9tbb71lU6dOtcWLF29XdqdOnWzMmDHWuHHjlOfcsGGDrVmzxj744AO77777bN68edW+vlQHPvjgg9a2bVtbtGiRDR061ObPn5\/2HLfccot169bNXdf1119vr7\/+es6vKZcFBvV78cUXbdiwYVkVTQiRFRc7I4AAAggUSIAQwh+8Qogty6+zrUUaQtRoeKzVJITwdwNQMgIxFCCEiGGjZXvJtWvXdmFC165drWbNmkkPX7Fihd166602e\/bsyp9nEkKEC1u\/fr3NnDnTBRq53AghUmsSQuTyTqMsBBBAAAFfAoQQvmTNCCH82VIyAgj4ESCE8ONaVKUOHjzYevfubQojFixYYL\/\/\/e\/thRdesGbNmtkFF1xgJ510kusZsXDhQrvqqqsqexqEQ4g33njDHnnkkR3qdcABB9iRRx5p7du3d2Vs3LjRnnzySZswYULODAghCCFydjNREAIIIIBAQQQIIfyxK4TYqJ4QGz70d5IIJddseKzV3oXhGBEIORSBkhMghCi5Jt2+QnvssYfdeeedttdee7mhEgokVq5cud1OV155pZ122mmul8RDDz1k06ZNcz8PhxBVDRXo1auXK7tJkyau\/LFjx9rLL7+cE11CCEKInNxIFIIAAgggUDABQgh\/9IQQ\/mwpGQEE\/AgQQvhxLZpSFQ4MGTLE9VIIBwzhC1QvhnHjxlnz5s0tHDZkE0KovAsvvND69u1rderUcV0DFW7kYiOEIITIxX1EGQgggAAChRMghPBnr\/\/mWr\/8OttSpD0hajU81urSE8LfDUDJCMRQgBAiho2WzSWfd955ds4557ihGBMnTrRnnnlmh8Nbt25t48ePt5YtW0YKIdQL4q677jKVt2zZMjeJ5Ny5c7O53KT75jqE2G+\/\/WzAgAF20EEH2c477+x6gGiSzlWrVrlJOlWH8CSdYR8NSXn33XetX79+pnIU7mhyTu0\/Y8YMe\/rpp5PWQfNxhI\/R\/BmazHPSpElu8kxNvFlVb5NkBTMnROTbiwIQQAABBPIgQAjhD1khxA\/fXmebizSEqN3gWKtHCOHvBqBkBGIoQAgRw0bL9SUfddRRNmrUKNtpp53s2WeftdGjR7tTZNsTQseMGDHCevbsaevWrbPbb789aeiR7fXnMoTQ6iAXXXSRNWzYMOVlaG6M6667rjJACYcQb775pmkejGTHK4y4\/\/77bfr06duV3adPH3fOevXq7XBOnWvTpk1uxRJCiGzvDPZHAAEEEIiLACGEv5YihPBnS8kIIOBHgBDCj2usSg2WtNTXeU0oOWvWrGqHEOp50b9\/fzckQz0DcrFSRq5CCPUa0Cohu+66qy1fvtxUrkKXtWvX2uGHH+6CAgUM2v74xz+63iHawiGE\/llLf+rnjz76qOsFoR4OCjcUMnz99dd26aWXVvak6NKliw0fPtydUyuQ6JzqLaGhL5dccol17tzZ9abQRggRq8eGi0UAAQQQyEKAECILrCx3VQhR8d3wou0JUadBD2vQhIkps2xWdkegpAUIIUq6eauuXPgrvVbA0PwR+jKvrTo9IfQyPmjQIPdiraELkydPrvoiqtgjCCGyLUhhgYY6vP766+5QDQ8544wzrKKiwm677TZ7\/vnntysyPImnejwoTEgMIRRYaAhFENQEBajnxC9+8QsXUNx8881u9RFt6lVy\/PHHu6EemncjvASqfn7NNdfYKaecYjVq1CCEyLaB2R8BBBBAIDYChBD+mooQwp8tJSOAgB8BQgg\/rrEoNTw0IXEIQimGEBoecvDBB7teCr\/97W9dMJC4BYHHZ5995no4JIYQ8+fPdz0YEo8NwhftP2XKFJs5c6b9+Mc\/dvNw7LnnnhYONcLnTDUpaKY3EHNCZCrFfggggAAChRQghPCnrxDi+++ut01FOidE3QY9rFGTS03Df9kQQAABCRBClOl9cO6559qvf\/1rN7fB0qVL7dZbb7U5c+Zsp1FsPSF0nXrBTxYehC9cE3EeeeSRrldCuCdEYlOr7u3atXOTQh5yyCHu\/zdr1sxNVJkqhJCRelQkbslCiLBful4hmkeiQ4cO9IQo02eRaiOAAALlIEAI4a+VCSH82VIyAgj4ESCE8ONatKVqlQx9yT\/rrLPckAn1CtDwAX2pT9yqE0IMHDjQLdOp1SZSLQmaLU6u5oTQebWihYaLaO6Hxo0bu2EQybZUIUSqeRuShRBnnnlm5ZCOZBNWBucN5uSIMidEYh0euGOBvfL377KlZn8EEEAAAQRyInDB5a2sy7G7bVeW\/ptDwyLZciugEGLVihtsY5H2hKjXoIfttPNgekLkttkpDYFYCxBCxLr5srt4ffkfOXKkHX300e5r\/xdffOFWxUi1jGZ1QojghboYV8fo3r27XX311W6SSG2aVFK9JZYsWWILFiywt99+2375y19amzZtUvaEKNYQQqHDt0s3VN4Qy7\/ZsN0\/Z3ensDcCCCCAAALRBJo2r2vNfvSfiZe1tT2wsR3xcyOEiMaa9GiFECtWjLANGz\/yUHr0IhvU\/7ntvPNvCSGiU1ICAiUjQAhRMk2ZviK77LKLWxlCcwho+\/jjj+2GG26oXMUh2dHZhhDhiR0XLVrkhi1oDoWoWy56QjRp0sRNkqmAQcM5pk2bZk899VTlJJzBNVY1J0Q2IUTY7w9\/+IPdcccdSSnuvvtuN1dFlJ4Qw\/p\/ROgQ9UbjeAQQQAABbwIMx\/BGa4QQ\/mwpGQEE\/AgQQvhxLapSwwHE1q1b7eWXX3Y9ILTSQ7ot2xDiwgsvdEMxtDznX\/\/6VxsxYkROHHIRQoTromU5tWpF4haeJDIXwzFatGjhVtLYe++97f3333fDQIKVR4Jzh5f\/JITIye1CIQgggAACRShACOGvURRCLF8x0tYXaU+IhvW72670hPB3A1AyAjEUIISIYaNle8nBMpA67qWXXrLhw4fv8DKcrMxsQohevXrZ4MGDTT0OVqxY4SaEfOedd7K91KT75zqESBaQaK6MK664wk499VSrVatWToZjqDIa\/nLiiSe6oR\/33HOPPfroo9vV8corr7TTTjvNBTeEEDm5XSgEAQQQQKAIBQgh\/DUKIYQ\/W0pGAAE\/AoQQflyLptQePXrYddddZ40aNbIvv\/zS7rrrLlu\/fn3K69NQhU8\/\/dT9PBxCvPHGG6YVHsKbXtw1jEArUey7777uRVov2+kmYawOTC5CiPBQEdVfS2iqPpoTQnNkqAeHekJorgxtuegJoXIOOuggu\/HGG6158+buXH\/84x9dEFG\/fn274IIL7KSTTnIThGojhKjO3cExCCCAAAJxECCE8NdKCiG+Wfk7W7\/xY38niVByo\/rdrelOA5kTIoIhhyJQagKEEKXWogn1CSaKzLSa4ZfvcAiRyfEa3qEXe4UQudxyEULoes477zzr379\/5Ut\/4jVqCdB\/\/\/vfdthhh9nChQtdzwj9cyZDJpKtjhGUr14iGooRTIgZPm8wOeZuu+1GCJHLm4ayEEAAAQSKSoAQwl9zKIRYvHK0\/VCkIUTj+sfY7jtdQgjh7xagZARiJ0AIEbsmy+6Cgxf4TI\/KNoTQS7R6T7zyyiv22GOPud4Wud5yFULouk4++WTX60E9I9QDYePGjfbdd9\/Z888\/bzrP6aefbgMGDHBVmDBhgs2aNStyCKGytDToZZdd5npbqFeKzqulyv77v\/\/bunbtat26dSOEyPWNQ3kIIIAAAkUjQAjhrykIIfzZUjICCPgRIITw40qpCORFQKudTJkyxVgdIy\/cnAQBBBBAoJoChBDVhMvgMIUQC1fdaOs2fpLB3vnfZad63exHO11MT4j803NGBIpWgBCiaJuGC0OgagFCiKqN2AMBBBBAoPAChBD+2oAQwp8tJSOAgB8BQgg\/rpSKQF4ECCHywsxJEEAAAQQiChBCRARMc7hCiH+vHmtri7QnRJN6Xa1F44voCeHvFqBkBGInQAgRuybjghHYJkAIwd2AAAIIIBAHAUIIf62kEOLL1TdbRZGGELvU62p7Nh5ACOHvFqBkBGInQAgRuyaL1wVnuzpHuHbhSTLjVev8XS0hRP6sORMCCCCAQPUFCCGqb1fVkYQQVQnxcwQQKDYBQohia5ESu56BAwe6JS+rsy1YsMBGjx5dnUPL5hhCiLJpaiqKAAIIxFqAEMJf8ymE+NfqcVax6VN\/J4lQ8q71jrYfN\/oNPSEiGHIoAqUmQAhRai1KfcpKgBCirJqbyiKAAAKxFSCE8Nd0hBD+bCkZAQT8CBBC+HGlVATyIkAIkRdmToIAAgggEFGAECIiYJrDFULMXX2Lrdn0mb+TRCi5ab0u1qpRf3pCRDDkUARKTYAQotRalPqUlQAhRFk1N5VFAAEEYitACOGv6RRCfPr9ePu+SEOIZnV\/Zq0bXUAI4e8WoGQEYidACBG7JuOCEdgmQAjB3YAAAgggEAcBQgh\/rUQI4c+WkhFAwI8AIYQfV0pFIC8ChBB5YeYkCCCAAAIRBQghIgKmOVwhxMff326rN831d5IIJe9e9yj7SaN+9ISIYMihCJSaACFEqbUo9SkrAUKIsmpuKosAAgjEVoAQwl\/TEUL4s6VkBBDwI0AI4ceVUhHIiwAhRF6YOQkCCCCAQEQBQoiIgGkOVwjxwZqJtmrT5\/5OEqHk5nU72\/4Nz6MnRARDDkWg1AQIIUqtRalPWQkQQpRVc1NZBBBAILYChBD+mk4hxHtr7rSVRRpCtKjbydo27EsI4e8WoGQEYidACBG7JuOCEdgmQAjB3YAAAgggEAcBQgh\/rUQI4c+WkhFAwI8AIYQfV0pFIC8ChBB5YeYkCCCAAAIRBQghIgKmOVwhxDsVk23Fpnn+ThKh5D3qHmkdGpxLT4gIhhyKQKkJEEKUWotSn7ISIIQoq+amsggggEBsBQgh\/DUdIYQ\/W0pGAAE\/AoQQflwpFYG8CBBC5IWZkyCAAAIIRBQghIgImOZwhRBvVkyxFZv+5e8kEUpuWfcIO7BBH3pCRDDkUARKTYAQotRalPqUlQAhRFk1N5VFAAEEYitACOGv6RRCvFZxt323uThDiL3qHG4HNfglIYS\/W4CSEYidACFE7JqMC0ZgmwAhBHcDAggggEAcBAgh\/LUSIYQ\/W0pGAAE\/AoQQflwpFYG8CBBC5IWZkyCAAAIIRBQghIgImOZwhRBzKu61bzd\/4e8kEUr+cZ3D7KcNetMTIoIhV0ZqEQAAIABJREFUhyJQagKEEKXWotSnrAQIIcqquaksAgggEFsBQgh\/TUcI4c+WkhFAwI8AIYQfV0pFIC8ChBB5YeYkCCCAAAIRBQghIgKmOVwhxEsV02z55vn+ThKh5L3rHGqHNTiLnhARDDkUgVITIIQotRalPmUlQAhRVs1NZRFAAIHYChBC+Gs6hRCz1z5gy4o0hNinzk\/tiPpnEEL4uwUoGYHYCRBCxK7JuGAEtgkQQnA3IIAAAgjEQYAQwl8rEUL4s6VkBBDwI0AI4ceVUhHIiwAhRF6YOQkCCCCAQEQBQoiIgGkOVwjxwtoHbenmL\/2dJELJrescYp3qn0ZPiAiGHIpAqQkQQpRai1KfshIghCir5qayCCCAQGwFCCH8NR0hhD9bSkYAAT8ChBB+XCkVgbwIEELkhZmTIIAAAghEFCCEiAiY5nCFEH9d+5B9s3mBv5NEKHnfOgfbz+qfSk+ICIYcikCpCRBClFqLUp+yEiCEKKvmprIIIIBAbAUIIfw1nUKI59bOsCVFGkLsV+cgO7r+Lwgh\/N0ClIxA7AQIIWLXZFwwAtsECCG4GxBAAAEE4iBACOGvlQgh\/NlSMgII+BEghPDjSqkI5EWAECIvzJwEAQQQQCCiACFERMA0hyuE+N+1j9jizV\/5O0mEktvU6Wjd6veiJ0QEQw5FoNQECCFKrUWpT1kJEEKUVXNTWQQQQCC2AoQQ\/pqOEMKfLSUjgIAfAUIIP66UikBeBAgh8sLMSRBAAAEEIgoQQkQETHO4Qog\/r3vMFm3+t7+TRCi5be0DrXv9nvSEiGDIoQiUmgAhRKm1KPUpKwFCiLJqbiqLAAIIxFaAEMJf0xFC+LOlZAQQ8CNACOHHlVIRyIsAIURemDkJAggggEBEAUKIiIBpDlcI8eS6mbawSHtCtKt9gB1b\/yR6Qvi7BSgZgdgJEELErsm4YAS2CRBCcDcggAACCMRBgBDCXysphHhi3eO2cPPX\/k4SoeT2tTvY8fVPIISIYMihCJSaACFEqbUo9SkrAUKIsmpuKosAAgjEVoAQwl\/TEUL4s6VkBBDwI0AI4ceVUhHIiwAhRF6YOQkCCCCAQEQBQoiIgGkOVwgxc90f7evNC\/2dJELJB9RubyfWP46eEBEMORSBUhMghCi1FqU+ZSVACFFWzU1lEUAAgdgKEEL4azpCCH+2lIwAAn4ECCH8uFIqAnkRIITICzMnQQABBBCIKEAIEREwzeEKIR5b96T9e\/MifyeJUPKBtdtZz\/o96AkRwZBDESg1AUKIUmtR6lNWAoQQZdXcVBYBBBCIrQAhhL+mUwjxyLo\/21dFGkJ0rN3WetXvTgjh7xagZARiJ0AIEbsm44IR2CZACMHdgAACCCAQBwFCCH+tRAjhz5aSEUDAjwAhhB9XSkUgLwKEEHlh5iQIIIAAAhEFCCEiAqY5XCHEjHVP24LNi\/2dJELJB9Xe335R\/xh6QkQw5FAESk2AEKLUWpT6lJUAIURZNTeVRQABBGIrQAjhr+kIIfzZUjICCPgRIITw40qpCORFgBAiL8ycBAEEEEAgogAhRETANIcrhHho7f\/al5uX+DtJhJIPqdPGTq3flZ4QEQw5FIFSEyCEKLUWpT5lJUAIUVbNTWURQACB2AoQQvhrOoUQD6z9S9GGED+ts5+dXr8LIYS\/W4CSEYidACFE7JqMC0ZgmwAhBHcDAggggEAcBAgh\/LUSIYQ\/W0pGAAE\/AoQQflwpFYG8CBBC5IWZkyCAAAIIRBQghIgImOZwhRD3rX3e5m\/+xt9JIpR8aJ2f2Jn1f0ZPiAiGHIpAqQkQQpRai1KfshIghCir5qayCCCAQGwFCCH8NR0hhD9bSkYAAT8ChBB+XCkVgbwIEELkhZmTIIAAAghEFCCEiAiY5nCFEPeu\/Zt9sXmpv5NEKPmwOvta7\/qd6QkRwZBDESg1AUKIUmtR6lNWAoQQZdXcVBYBBBCIrQAhhL+mUwhx99oX7F9FGkIcXqe1\/bJ+J0IIf7cAJSMQOwFCiNg1GReMwDYBQgjuBgQQQACBOAgQQvhrJUIIf7aUjAACfgQIIfy4ei\/15JNPtrPPPttatWpldevWtS1bttjq1avtrbfesqlTp9rixYu3u4ZOnTrZmDFjrHHjximvbcOGDbZmzRr74IMP7L777rN58+Z5r8fRRx\/t6tGmTRvbeeedrWbNmpV1+fzzz+3hhx+2119\/Pel1tG7d2saPH28tW7a0F1980YYNG5bx9Q4ePNjOOeccV9\/rr78+5TkyLrBAOxJCFAie0yKAAAIIZCVACJEVV1Y7K4SYUjHb\/rV5WVbH5WvnI+rsY30aHEFPiHyBcx4EYiBACBGDRgpfYu3atV2Y0LVrV\/fCnmxbsWKF3XrrrTZ79uzKH2cSQoTLWr9+vc2cOdMFGj62ffbZx6655hrr2LFjynrovApX\/vnPf9rYsWN3CFZKIYRo2LCh\/eY3vzF5XHnllVlTE0JkTcYBCCCAAAIFECCE8IdOCOHPlpIRQMCPACGEH1dvpeoLfu\/evU1hxIIFC+z3v\/+9vfDCC9asWTO74IIL7KSTTnI9IxYuXGhXXXWVzZ8\/311LOIR444037JFHHtnhGg844AA78sgjrX379q6MjRs32pNPPmkTJkzIaX32339\/u+mmm2zPPfe0rVu32qJFi+zpp5+25557zpYsWWItWrRw9VBvD\/VyqFGjhn399dc2fPhwmzt3buW1lEIIcfPNN1v37t3ts88+s379+mXtTAiRNRkHIIAAAggUQIAQwh+6QojJFS\/avCLtCXFknVZ2boPD6Qnh7xagZARiJ0AIEaMm22OPPezOO++0vfbayw2VUCCxcuXK7Wqgr+mnnXaa613w0EMP2bRp03YIIaoautCrVy9XdpMmTVz56oXw8ssv50Rql112sdtvv906dOhgGv4xa9YsmzRpkm3atGmH8hW0XH311S6QqFOnjn300Uc2ZMgQW7Vqlds3SgiRk8rkoJBbbrnFunXrRgiRA0uKQAABBBAoXgFCCH9toxBiUsXL9vnm5f5OEqHkTnX2tv+vwaGEEBEMORSBUhMghIhRiyoc0Eu4eimEA4ZwFdSLYdy4cda8efPt5kkI94SoKoRQeRdeeKH17dvXvfzrX27VGSqQjDYoVwGDAghda7pN+ykE0Yu6embMmDHD7r33XkKI\/0OjJ0SMHmAuFQEEEChjAUIIf41PCOHPlpIRQMCPACGEH1cvpZ533nluMkW9mE+cONGeeeaZHc6TqndAtiGEekHcddddrrfBsmXLbOjQodsNhahOBVXm5MmT3SSU2ZR5+OGH2+jRo23XXXc1TVapXhrqDZFYVw3pUMihyToVnlRUVNjbb7\/teoMkTrJZ1cSU++23nw0YMMB++tOfusk8NSQkXXmBh9pGw2VOPfVUU88VBUbq8aGJQhWg6Bq1aTLOQYMGuZ+Ht2wnyiSEqM6dyDEIIIAAAvkWIITwJ64QYmLFHJu76Vt\/J4lQ8lF1f2znNfgpPSEiGHIoAqUmQAhRYi161FFH2ahRo2ynnXayZ5991r28a8s2hNAxI0aMsJ49e9q6devcEIpkoUc2fD169LBrr73WvdRn0hsjXLaGoRxxxBH2\/fff28iRI13vjHAIofkxNJdEvXr1drikZBN1pgshzjzzTLv44otTriSiAERhSqKHhppotQ4NNVFokbiF59gghMjmzmFfBBBAAIG4CxBC+GtBQgh\/tpSMAAJ+BAgh\/LgWrNRgjgGtbqEJJTXkobohhHpe9O\/f3\/Uq0Ff8qCtlRCkvCA3Uq+D++++36dOnbxdCqI6qsya3vPvuu12dFSQoRFFvgy+\/\/NINKQmWLk0VQnTp0sVNgKleF+qVoKDhwQcfdL0ZVJYmj9QkoAo2tLTnO++8484VDBvRqiWabDNY5lRLpip8Ua8KrYCxdu1aNwdG0C7MCVGwR4UTI4AAAgjkUYAQwh+2QojbK14t4p4Qe1m\/BofQE8LfLUDJCMROgBAidk2W+oL79Pn\/27sPKCuqbP\/jG0SQnJFkfCRxwDERFJBxxvREYHRGR0FAUUQQEXXA7BMQCQbQEdP4\/mYQw1MGR0b\/+mdMawiigqCEIUhSUAkSJPpf+\/Bu96Xpvn1v193Vdep+a61Za7Rv7Tr12YV6f33qnEvlmmuucbMBdAcMXT8iseBjSWZCJP+2XnfT0N\/+BzmSg4RHH33UbQGa7lHYWJJnQmhIoOHDpEmTDiiZvFCnBimJgKKoEEKDG51NooHGE088cVA93clCF8vUkOLdd991s0X00KDhtttuk8qVK7tZHhpkJC+22bp1axkxYoRbq+OLL75wAYkehBDpPgF8DgEEEEDAZwFCCLvuaQgxbttMWbTnR7uLBKh8WvlGcmXF1oQQAQw5FYG4CRBCxKSj+iVdA4hKlSq57Tn1C3HydpZxDyG+\/vprN9ug4C4byTuKJH\/5LyyESF7Uc\/bs2XL99dcX+nQkggPdWlTXytBtULWehkC6boRuu6nbphY89NWYDh06yDfffCO33HKL246UECImfwC5DQQQQACBlAKEEHYPCCGEnS2VEUDARoAQwsY11Ko9evSQK6+80gUQ69evl7Fjx8rHH398wBjiHkK8+eabRe60oes06GsWGs4MGTJEVq1a5UIDXeQzeSHIxO4jFStWlFQzPzTs6N27t1srIxE4FHaNdB4CQoh0lPgMAggggIDvAoQQdh3UEGLM1tmRnQlxevlG0rfSr5gJYfcIUBkB7wQIIbxrWf6AdR2Ca6+9Vv7whz+4dQ90vQP9Uqy\/xS94lCSEGDBggNumc9++fUVuCZoJX+LLu55T1BajRdVLjEUXdyxsTYhUoUFRMxcKhhBFLRZZ1Jj0FZDEayW6bkTz5s1l0aJFbt2IdI9shRCL5m894JJTJ62Tgn8v3THxOQQQQAABBIIKdL20vjRvVTWvTO3Dy8vuvT\/IhRdeGLQ05xcQIITgkUAAAd8ECCF869j\/jldnPeguETq9v2zZsrJs2TK3K0byKxjJt1aSECLxBdmH3TFyPYT4+L0D3wP95L0fCCE8\/bPNsBFAAIE4COjMh+QQok698lKtzk+EEAbN1RBi9NY58vWejQbVg5fsUL6hXFXpeGZCBKekAgKxESCE8LCVuhXkyJEj5aSTTnKjX7hwodx55515Oz8UdkuZhhDJaykkr30QhKt69epuccumTZvKhg0b3HoKRYUmydfR+9T71cUglyxZ4l6l0G0ykxemTPU6RmJ7T12LYfDgwW4thsJex9CtORPrQDz22GMyefLktG83cY3kVz7SOTlbMyGG9V0gP6zflc4l+QwCCCCAAAKhC\/A6hh25hhD3\/TQ3wiFEA7m6cktCCLtHgMoIeCdACOFZy5IDCN0K8qOPPnIzIHTrx1RHpiFEv3793KsYuj1n8i4QQbkSdfVVkg8\/\/PCgXSQK1k\/e+lIXndQdLp588kn3seQQInnRyeQayWFK8mKThYUQJ5xwgnudpeDOF+ncsy402a1bN7cw5ahRowpdmFJfR1FTDVDGjRvn7p8QIh1dPoMAAggg4LsAIYRdBwkh7GypjAACNgKEEDauZlX1y27Xrl1d\/XS+xCcGkkkIoQs06pd0nbmwceNGueOOO2Tu3LlZuSet+cADD8jxxx8vur7D9OnT3UKaBXe10ItpAKHbYZ577rkuDNEZH7rt6KZNmw4KITSEmTBhgkydOvWAcepsi+7du7v6Tz31lLz44ovu50Vt0Tlx4kQ58cQT3X3ruGbMmHFAvUQo0q5dO\/cZDRH0X\/7FbdGp4dFDDz0kLVq0cLtjJGZkJEII3WFD1\/fQgCKTQ2eJ6LoUzITIRI3PIoAAAgiELUAIYSeu\/x0y6qfP5as9+\/\/7KGpHx\/L1pV\/lFsyEiFpjGA8CpShACFGK+JleOvmL7ooVK0RfGdi5c2eRZfQLrW5dqUdyCDFr1iy3+0PyoV+udSZAmzZt5Nhjj3Vf+nXhxcQikJmONdXnmzVrJvfee680btxYdDaHvu4xbdo0F0joqxL169d3wUOXLl2kYcOGUqZMGVm9erWbNZH8+kbyTAi9nu508corr7jZEvXq1XM7hpxxxhlu0c4FCxa4ACPxJb+oEKJz584u+NDZEBp2aKgxadIk9\/9POeUUueqqq6RVq1ZuHQ511JoacCTP2NB70tBGQ4958+a583T7VA1e9LM6Rn0tRQ+deaHX1EBDZ7TMnDkzI2pCiIy4+DACCCCAQCkJEELYwRNC2NlSGQEEbAQIIWxcTaomfmuebvHknRqSQ4h0zteZBRpUaAhhcehrEhoq6KwD\/UJf1KE7c3z22WcutNDdP5KP5BBizpw5LhyoUKHCQaUKW7SzqBBCT9ZdMjQ00MU\/Czs0ZFBbDQ00DEocOttBt+ps2bKlC04KHnovOntFZ5YkZn5oUKK7aWjoo4cGP7q+xGuvvZYWOyFEWkx8CAEEEECglAUIIewaoCHEvVu+kK\/2ZDab0m5EB1buWOFwuaZyc2ZChAXOdRDwQIAQwoMmJYaY2AYy3SFnGkLoF2CdKfDJJ5+4RRmTv2Cne81MP6fhSI8ePdxildWqVXOBhL6mobMa5s+fL6+\/\/nqRswOSQwgNTPSVht69e+fNntDZC++9956bMVJwzYxUIYTeQ5MmTUTXcNCQpEqVKi5UUJ\/169e7GRs6O6KwdTh0RoSu+6CvgNSqVStvRokGKDpDQ2d8JB\/6eV1UVGdsaICyd+\/ejLYvJYTI9Inj8wgggAACpSFACGGnTghhZ0tlBBCwESCEsHGlasQFigshIj78vOERQvjSKcaJAAII5LYAIYRd\/zWEGLFlfmRnQnSqUE\/6V27GTAi7R4DKCHgnQAjhXcsYcDYEEiGEzvzQ1yP0dQ4fD0IIH7vGmBFAAIHcEyCEsOv5\/hDiS1m4e4vdRQJUPkNDiCpNCCECGHIqAnETIISIW0e5nyIF9NUHXYtC12PQBSGbN28ua9askSFDhsiqVau8lCOE8LJtDBoBBBDIOQFCCLuWE0LY2VIZAQRsBAghbFypGkGB4447TkaPHu12ztBDF5j8xz\/+4RaY9PUghPC1c4wbAQQQyC0BQgi7fmsIMXzzwgjPhKgr11b9D2ZC2D0CVEbAOwFCCO9aVnoDznR3juSRJi+SWVp3oFt+Dh482C00qYtM6r+0NZTQBSx9PQghfO0c40YAAQRyS4AQwq7fhBB2tlRGAAEbAUIIG9dYVh0wYICcfPLJJbq3lStXyvDhw0t0LicVLUAIwdOBAAIIIOCDACGEXZc0hPivzV\/Jwt0\/2V0kQOXOFerIgKrHMhMigCGnIhA3AUKIuHWU+8kpAUKInGo3N4sAAgh4K0AIYdc6F0JsWiQLohpCHFZbBlY9hhDC7hGgMgLeCRBCeNcyBoxAvgAhBE8DAggggIAPAoQQdl0ihLCzpTICCNgIEELYuFIVgVAECCFCYeYiCCCAAAIBBQghAgKmOF1DiLs2LY7sTIjfHFZbrqt6NDMh7B4BKiPgnQAhhHctY8AI5AsQQvA0IIAAAgj4IEAIYdclQgg7WyojgICNACGEjStVEQhFgBAiFGYuggACCCAQUIAQIiBgitM1hLhz4xJZsHur3UUCVP7NYbVkULWjmAkRwJBTEYibACFE3DrK\/eSUACFETrWbm0UAAQS8FSCEsGudhhB3bPy3fBnREOLMw2rJ9dWOIISwewSojIB3AoQQ3rWMASOQL0AIwdOAAAIIIOCDACGEXZcIIexsqYwAAjYChBA2rlRFIBQBQohQmLkIAggggEBAAUKIgIApTtcQ4raNy+TLXdvsLhKg8m8r1pTB1RozEyKAIaciEDcBQoi4dZT7ySkBQoicajc3iwACCHgrQAhh1zpCCDtbKiOAgI0AIYSNK1URCEWAECIUZi6CAAIIIBBQgBAiIGCK0zWEuHXjCpkf2ZkQNWRItUbMhLB7BKiMgHcChBDetYwBI5AvQAjB04AAAggg4IMAIYRdlzSEGPajhhDb7S4SoPLvKtaQG6s3JIQIYMipCMRNgBAibh3lfnJKgBAip9rNzSKAAALeChBC2LWOEMLOlsoIIGAjQAhh40pVBEIRIIQIhZmLIIAAAggEFCCECAiY4nQNIf784zcyL6IzIc6qWF1urt6AmRB2jwCVEfBOgBDCu5YxYATyBQgheBoQQAABBHwQIISw6xIhhJ0tlRFAwEaAEMLGlaoIhCJACBEKMxdBAAEEEAgoQAgREDDF6RpC3PTDKvli1w67iwSofHbFajK0Rn1mQgQw5FQE4iZACBG3jnI\/OSVACJFT7eZmEUAAAW8FCCHsWqchxJAf1sjnEQ0hzq1YVYbVOJwQwu4RoDIC3gkQQnjXMgaMQL4AIQRPAwIIIICADwKEEHZdIoSws6UyAgjYCBBC2LhSFYFQBAghQmHmIggggAACAQUIIQICpjhdQ4jrv18b2ZkQ51WqKrfWqMdMCLtHgMoIeCdACOFdyxgwAvkChBA8DQgggAACPggQQth1iRDCzpbKCCBgI0AIYeNKVQRCESCECIWZiyCAAAIIBBQghAgImOJ0DSGu+36dfLbzZ7uLBKj8n5WqyO016zITIoAhpyIQNwFCiLh1lPvJKQFCiJxqNzeLAAIIeCtACGHXOg0hrv3+O5kb0RDi\/EpV5K6atQkh7B4BKiPgnQAhhHctY8AI5AsQQvA0IIAAAgj4IEAIYdclQgg7WyojgICNACGEjStVEQhFgBAiFGYuggACCCAQUIAQIiBgitM1hLhmw3r5dOdOu4sEqNylUmX5r1q1mAkRwJBTEYibACFE3DrK\/eSUACFETrWbm0UAAQS8FSCEsGsdIYSdLZURQMBGgBDCxpWqCIQiQAgRCjMXQQABBBAIKEAIERAwxekaQly1YYPMiehMiK6VKslwZkLYPQBURsBDAUIID5vGkBFICBBC8CwggAACCPggQAhh1yUNIa5c\/73M3rnL7iIBKnerXElG1qrB6xgBDDkVgbgJEELEraPcT04JEELkVLu5WQQQQMBbAUIIu9YRQtjZUhkBBGwECCFsXKmKQCgChBChMHMRBBBAAIGAAoQQAQFTnK4hRJ\/vfozsTIjulSvKvbWrMxPC7hGgMgLeCRBCeNcyBoxAvgAhBE8DAggggIAPAoQQdl0ihLCzpTICCNgIEELYuFIVgVAECCFCYeYiCCCAAAIBBQghAgKmOF1DiN7fbZRZEV0T4veVK8qo2tWYCWH3CFAZAe8ECCG8axkDRiBfgBCCpwEBBBBAwAcBQgi7LmkI0eu7TTLr5912FwlQ+fdVDpP7alclhAhgyKkIxE2AECJuHeV+ckqAECKn2s3NIoAAAt4KEELYtY4Qws6WygggYCNACGHjSlUEQhEghAiFmYsggAACCAQUIIQICJjidA0hLv9uS4RnQlSQ0bWrMBPC7hGgMgLeCRBCeNcyBoxAvgAhBE8DAggggIAPAoQQdl0ihLCzpTICCNgIEELYuFIVgVAECCFCYeYiCCCAAAIBBQghAgKmON2FEN\/qTIg9dhcJUPn3VSrI6DqVmQkRwJBTEYibACFE3DrK\/eSUACFETrWbm0UAAQS8FSCEsGsdIYSdLZURQMBGgBDCxpWqCIQiQAgRCjMXQQABBBAIKEAIERAwxekuhFi3NcIzIcrL6LqVmAlh9whQGQHvBAghvGsZA0YgX4AQgqcBAQQQQMAHAUIIuy653THWbotuCFG1vNxXtyIhhN0jQGUEvBMghPCuZQwYAUIIngEEEEAAAb8ECCHs+kUIYWdLZQQQsBEghLBxpSoCoQgwEyIUZi6CAAIIIBBQgBAiIGCK0zWE6L12u8z6ea\/dRQJU\/n3VQ2VU3cOYCRHAkFMRiJsAIUTcOsr95JQAIUROtZubRQABBLwVIISwax0hhJ0tlRFAwEaAEMLGlaoIhCJACBEKMxdBAAEEEAgoQAgREDDF6RpC9Fn7s8zeEc2ZEN2rlpN761VgJoTdI0BlBLwTIITwrmUMGIF8AUIIngYEEEAAAR8ECCHsuqQhxJVrNITYZ3eRAJW7VS0nIw8vTwgRwJBTEYibACFE3DrK\/eSUACFETrWbm0UAAQS8FSCEsGsdIYSdLZURQMBGgBDCxpWqCIQiQAgRCjMXQQABBBAIKEAIERAwxekaQvRdvUvmRHQmRNdqh8iIww9lJoTdI0BlBLwTIITwrmUMGIF8AUIIngYEEEAAAR8ECCHsukQIYWdLZQQQsBEghLBx9aJqkyZNZPDgwXLcccdJ5cqVZd++fbJ582b58MMP5ZlnnpF169YddB\/695s3b17k\/WmN7du3y8qVK+XVV1+V6dOnZ91i0KBBctlll6Vdd9euXfLoo4\/KlClT0j7Hlw8SQvjSKcaJAAII5LYAIYRd\/zWEuHrVbvk0ojMhLqh2iNxTvxwzIeweASoj4J0AIYR3LcvOgC+66CLp37+\/VKlSpdCCa9askTFjxsjs2bMP+HlxIUTyhzWQmDt3rtx5552yadOm7AxcRAgh8ikJIbL2WFEIAQQQQMBQgBDCDldDiP6r9sinO36xu0iAyl2qlZW76x9CCBHAkFMRiJsAIUTcOprG\/bRu3VpGjBgh9erVk61bt8orr7wiL7zwgpQvX1769u0rF1xwgVSoUEEWLFggN910k5sdkTgSIcT69evd7ILkn+lnDj\/8cGnTpo20bds2L+BYuHChq5OtICIRQugMh8mTJ7ugI9Wxd+9eWbp0adaunwZxaB8hhAiNmgshgAACCAQQIIQIgFfMqYQQdrZURgABGwFCCBvXSFe9+eab5cILL5Tdu3cX+prCDTfcIH\/4wx9Ev+Q\/8MAD8tZbbx0UQqxdu1a0zvLlywu916OPPlqGDx8uTZs2FQ0B9NWM8ePHZ8UlOYSI62sW6UIRQqQrxecQQAABBEpTgBDCTl9DiGtX7ZW526M5E+L86mXkLmZC2D0AVEbAQwFCCA\/5XV18AAAgAElEQVSbFnTId911l5sS9\/3338t111130GwGncUwcuRIN5PhpZdekkceeSTjEEJP0C\/IWqdmzZqyYcMGF1osXrw46PDzXseI81oP6SIRQqQrxecQQAABBEpTgBDCTp8Qws6WygggYCNACGHj6nXV008\/Xe655x63WGWQEEIRbrnlFunWrZvs3LlTnnrqKXnxxRcD22RjJkS5cuXkj3\/8oxtbgwYN3KsoemiwoYtq6iKW06ZNK3Ss+vk+ffpIx44dpXr16lK2bFnZtm2bfPXVVzJhwgT36kfBo7Bz1ERfVXn22Wdl5syZJXIhhCgRGychgAACCIQsQAhhB64hxMBv9kV6JsQdDcqyJoTdI0BlBLwTIITwrmX2A9bgoGvXrm6Xi1GjRsn777+fd9HEmhDFvY6ROOH8889360FUrFhR3n77bfeKRtAjaAhRo0YNuf\/++6Vly5ZSpkyZQoejr6q88cYb8uCDDx7w886dO8vQoUPd7I7Cjo0bN8rYsWNlxowZeT\/WUEfP0TU4Cjs0jNBwRkOaTA9CiEzF+DwCCCCAQGkIEELYqWsIcd3KX+Sz7XbXCFL5P6uL3N6wDCFEEETORSBmAoQQMWtoSW9HZwacfPLJcvnll4suXKl\/rVt13n777bJnz54ShxC6\/efo0aPdF3D9rb8ufBn0CBpC3H333XLOOee4+9J\/cT\/99NPuNRENJy699FK3Xoa+ilLwFZJmzZq5UKZRo0ZuZoduP6qhzJYtW6Rnz55uZoWet2LFCrnxxhvdFqfHHHOMjBs3zp2jsyzee+89ee6552T16tVy5plnyhVXXCG6foYGPjqLYurUqRnxEEJkxMWHEUAAAQRKSYAQwg6eEMLOlsoIIGAjQAhh4+pV1YsvvlgGDhyY90pC4gv2ww8\/7L4cJx+ZzoTQL+E666Bhw4ayaNEi9xpD0COTLToLztjQIEHHU7duXZk1a5abpZEcsujYdOtSDRV27Ngh9913X95MkOQFPR9\/\/HGZNGnSAbei96b\/0wBHX7HQmQ2Jc\/Qahc2sSA425s2b5\/pQcDypvAghgj5NnI8AAgggEIYAIYSdsoYQ16+QyM6EOK+GyG0NhZkQdo8AlRHwToAQwruWZX\/AhX2p19\/a\/\/Of\/3SzGJKDCN9DiLPPPtstxqkzFvRedFZCwSMRyujfT+y+ocGChgotWrRwO4Jce+21By3oqes+6A4gtWrVcsHFxIkT5bHHHnOzIYo6R6+h\/joDQ7dL1Vka+h8T6R6EEOlK8TkEEEAAgdIUIISw0yeEsLOlMgII2AgQQti4elW1fv36bry6W0biFYGjjjrK\/b0PPvjALS6ZOKIUQmhQMnnyZJk7d26R3j\/\/\/LMsWLAg5ewCDQn0fvV1lFatWrnXIypUqOBen0iEEMcee6ybQaFBg673cOuttxbb4xNOOMHNpND1I9Rx2LBhhZ6TWDfjkEMOca+GFBaMFHUxQohi28AHEEAAAQQiIEAIYdeE\/SFEGfl8m901glTWmRC3NvqFmRBBEDkXgZgJEELErKHZuB1dG+Ghhx5yv\/XXhRZ1S885c+a40pmGEKeccorbplN3kfjiiy\/cqw5Bj6BrQuisBn3dQr\/861oViZ0xCo4rOYRItW1pUfeTfE6691xwN5LizkuEEFNfWiffr9+V9\/FF87fKD0l\/XVwdfo4AAggggEA2BZq3qiK16+3feUqP5q2qyrEtd7p1lziyK6AhxA3Ly8rn2wpfbDu7V8u82rk1fpFbGu8jhMicjjMQiK0AIURsWxvsxnr16pW3iGTyb+czDSGS15uIwu4YGkDce++9bntN3Rnjl19+ca+b6CKU3377rVu3Yt++fdKjRw8HmJgJEfUQIjmA0HFrKPHJez8Gewg4GwEEEEAAgRIKdL20vpz2u9p5Z9epV94t2EwIUULQFKcRQmTflIoIIGArQAhh6+tt9eTwIPm385mGELol51lnnXXAqw1BUYLMhNBw4eqrr3azH2bPnu1mfOhuFslHYWtCJO\/yke7rGMmzQF5++WW3XkS2D17HyLYo9RBAAAEELAR4HcNCdX9NDSGGLDskujMhau6TYcyEsHsAqIyAhwKEEB42LciQjzjiCDcToHHjxvL555+7rSQLOxKLJe7evVt0l4zXXnvNfSyTEEK\/IOurGLomgm5Jef3117vfggQ9goQQY8aMkU6dOrnXTHRdB31FpOCha2B069btgOBEXydJLDK5ZMkSt5jk5s2bDzpXd83QHS\/0M7qop\/7vyCOPlJLsfJGOEyFEOkp8BgEEEECgtAUIIew6QAhhZ0tlBBCwESCEsHGNbFV9HUFfMWjdurX7Eq1fkvU3+8lH8raRBbe4TDeE0MUddRZE06ZNRYOMF154QZ588smsuGQrhEhe6yIxsF\/96ldu3LoAZfKaEPrz4rbo7Ny5s1vEUwOLxKsneo1zzz3X1XriiScO2tYzUbdLly7utRB99SUR+KSDRQiRjhKfQQABBBAobQFCCLsOuBDi3+Xki4iuCXGOzoQ4Yi9rQtg9AlRGwDsBQgjvWhZ8wBdddJH7Tb7uAKE7YmiwoF+a9TjvvPNE14PQBRsLCw8SIcT69etdmFFwNoDuIqGvIejOEJUrV3ZrLsycOVP+\/Oc\/p9yhIpO7ChJC6MKYuiil7kShsxV0locuuqk7hPzpT3+Sc845R3RhTj0KhhDJ4YwGBn\/\/+99daKCfU7c+ffpInTp13CwLnW3y8ccfu1kRo0aNkkaNGsnOnTtl+vTpzlvXn9Cf9e3bV9q1a+deD1m6dKnry6ZNm9LmIIRIm4oPIoAAAgiUogAhhB2+hhA3agixtazdRQJUPqfWPhl6xB5CiACGnIpA3AQIIeLW0TTvZ8CAAXLJJZek3BlC1zGYOHHiARUTIUQ6l9EFHv\/1r3\/JiBEjMvpiXVztICGEznDQ2R8aABR2aKCgr2g0adLEhRE6gyPZQGc7DB061L1iUtih4YTOeJgyZUrej4s7Rz+4Zs0a0VdFdJ2KTA5CiEy0+CwCCCCAQGkJEELYyRNC2NlSGQEEbAQIIWxcvaiqOz707t3bfSHXWQt6bNu2TRYvXizPPvusm8FQ8CguhNDZE1pDZxnoF\/GPPvoo6xZBQggdjAYRGsLo\/VepUsXtkpF8319\/\/bU88sgj7lWSwtZyKOr8r776SiZMmOBmNBQ89BydKaG7cujrGmXLlnUzTXTWwz\/\/+U83oyKTGRCJ+oQQWX+8KIgAAgggYCBACGGA+r8lNYS4aemhkZ0JcXatvTL0SGZC2D0BVEbAPwFCCP96xogRyBMghOBhQAABBBDwQYAQwq5LhBB2tlRGAAEbAUIIG1eqIhCKACFEKMxcBAEEEEAgoAAhREDAFKe7EGJJ+WjPhDhqN2tC2D0CVEbAOwFCCO9axoARyBcghOBpQAABBBDwQYAQwq5LGkLcvDjCIUTtvfJnQgi7B4DKCHgoQAjhYdMYMgIJAUIIngUEEEAAAR8ECCHsukQIYWdLZQQQsBEghLBxpWoRAroY5MiRI92CkJkeBbfMzPT8OH6eECKOXeWeEEAAgfgJEELY9XR\/CFFB5v0UzS06z669V24+ehevY9g9AlRGwDsBQgjvWub3gFu0aCEDBw6USpUqZXwjupvE5MmTZcaMGRmfG9cTCCHi2lnuCwEEEIiXACGEXT8JIexsqYwAAjYChBA2rlRFIBQBQohQmLkIAggggEBAAUKIgIApTtcQ4s+LdCbEIXYXCVD5rNp75OZjmAkRgJBTEYidACFE7FrKDeWSACFELnWbe0UAAQT8FSCEsOsdIYSdLZURQMBGgBDCxpWqCIQiQAgRCjMXQQABBBAIKEAIERAwxekaQgz9KsIzIerskZuOZSaE3RNAZQT8EyCE8K9njBiBPAFCCB4GBBBAAAEfBAgh7LqkIcSwrw6TeVsi+jpG3T1y47E7WZjS7hGgMgLeCRBCeNcyBoxAvgAhBE8DAggggIAPAoQQdl0ihLCzpTICCNgIEELYuFIVgVAECCFCYeYiCCCAAAIBBQghAgKmON2FEAsPk\/kRnQnxO50J8R\/MhLB7AqiMgH8ChBD+9YwRI5AnQAjBw4AAAggg4IMAIYRdlwgh7GypjAACNgKEEDauVEUgFAFCiFCYuQgCCCCAQEABQoiAgClOdyHEgooRngmxW25swkwIuyeAygj4J0AI4V\/PGDECeQKEEDwMCCCAAAI+CBBC2HVJQ4hbvoxwCFFvtwwhhLB7AKiMgIcChBAeNo0hI5AQIITgWUAAAQQQ8EGAEMKuS4QQdrZURgABGwFCCBtXqiIQigAhRCjMXAQBBBBAIKAAIURAwBSn7w8hKsn8zdHcovN3OhOi6c9s0Wn3CFAZAe8ECCG8axkDRiBfgBCCpwEBBBBAwAcBQgi7LhFC2NlSGQEEbAQIIWxcqYpAKAKEEKEwcxEEEEAAgYAChBABAVOcriHErfN0JkQ5u4sEqPzbw3fLkGY7mAkRwJBTEYibACFE3DrK\/eSUACFETrWbm0UAAQS8FSCEsGudCyG+qBzhEGKXDGlOCGH3BFAZAf8ECCH86xkjRiBPgBCChwEBBBBAwAcBQgi7LhFC2NlSGQEEbAQIIWxcqYpAKAKEEKEwcxEEEEAAgYAChBABAVOcriHEbToTYlNEX8eov0tuYCaE3QNAZQQ8FCCE8LBpDBmBhAAhBM8CAggggIAPAoQQdl0ihLCzpTICCNgIEELYuFIVgVAECCFCYeYiCCCAAAIBBQghAgKmON2FEJ9XifZMiBbbWZjS7hGgMgLeCRBCeNcyBoxAvgAhBE8DAggggIAPAoQQdl1yIcRnVeXLCL+OMfi4bYQQdo8AlRHwToAQwruWMWAECCF4BhBAAAEE\/BIghLDrFyGEnS2VEUDARoAQwsaVqgiEIsBMiFCYuQgCCCCAQEABQoiAgClOdyHEXJ0JcajdRQJU\/m2DncJMiACAnIpADAUIIWLYVG4pdwQIIXKn19wpAggg4LMAIYRd9wgh7GypjAACNgKEEDauVEUgFAFCiFCYuQgCCCCAQEABQoiAgClO1xDi9k+ryZcbozkT4kydCXH8VtaEsHsEqIyAdwKEEN61jAEjkC9ACMHTgAACCCDggwAhhF2XNIS4Y0716IYQDX+W6wkh7B4AKiPgoQAhhIdNY8gIJAQIIXgWEEAAAQR8ECCEsOsSIYSdLZURQMBGgBDCxpWqCIQiQAgRCjMXQQABBBAIKEAIERAwxekaQtw5u0akZ0IM+tVPvI5h9whQGQHvBAghvGsZA0YgX4AQgqcBAQQQQMAHAUIIuy4RQtjZUhkBBGwECCFsXKmKQCgChBChMHMRBBBAAIGAAoQQAQFTnO5CiFk1ZMGP5e0uEqDybxr9LINabWEmRABDTkUgbgKEEHHrKPeTUwKEEDnVbm4WAQQQ8FaAEMKudRpC3DWzZoRDiB1yXWtCCLsngMoI+CdACOFfzxgxAnkChBA8DAgggAACPggQQth1iRDCzpbKCCBgI0AIYeNKVQRCESCECIWZiyCAAAIIBBQghAgImOJ0F0L8q1Z0Z0I01pkQm3kdw+4RoDIC3gkQQnjXMgaMQL4AIQRPAwIIIICADwKEEHZdIoSws6UyAgjYCBBC2LhSFYFQBAghQmHmIggggAACAQUIIQICpjhdQ4i7\/1VbFvwQzYUpO+tMiBM2MRPC7hGgMgLeCRBCeNcyBoxAvgAhBE8DAggggIAPAoQQdl1yIcQnGkJUsLtIgMqdj9gu1\/2aECIAIaciEDsBQojYtZQbyiUBQohc6jb3igACCPgrQAhh1ztCCDtbKiOAgI0AIYSNK1URCEWAECIUZi6CAAIIIBBQgBAiIGCK010I8XGdaM+EOHEjr2PYPQJURsA7AUII71rGgBHIFyCE4GlAAAEEEPBBgBDCrkuEEHa2VEYAARsBQggbV6oiEIoAIUQozFwEAQQQQCCgACFEQMAUp+8PIerKgu8juibEkdvkOmZC2D0AVEbAQwFCCA+bxpARSAgQQvAsIIAAAgj4IEAIYdclQgg7WyojgICNACGEjStVEQhFgBAiFGYuggACCCAQUIAQIiBgitNdCPFhvWjPhDj5R9aEsHsEqIyAdwKEEN61jAEjkC9ACMHTgAACCCDggwAhhF2XNIT4rw80hDjM7iIBKnc+apsMPPkHQogAhpyKQNwECCHi1lHuJ6cECCFyqt3cLAIIIOCtACGEXesIIexsqYwAAjYChBA2rlRFIBQBQohQmLkIAggggEBAAUKIgIApTt8fQhwuCzZEdSbEVhl4CjMh7J4AKiPgnwAhhH89Y8QI5AkQQvAwIIAAAgj4IEAIYdclQgg7WyojgICNACGEjStVEQhFgBAiFGYuggACCCAQUIAQIiBgitNdCDEjwjMhjt4qA09lJoTdE0BlBPwTIITwr2eMGIE8AUIIHgYEEEAAAR8ECCHsuuRCiP9XP7qvY2gI0eZ7Fqa0ewSojIB3AoQQ3rWMASOQL0AIwdOAAAIIIOCDACGEXZcIIexsqYwAAjYChBA2rpGrWq5cOenZs6d0795datWqJYceeqjs2rVLli1bJi+\/\/LJMnz79oDG3bdtWRo4cKVWqVCnyfrTG1q1bZf78+fLXv\/5Vli5dmvV7f+aZZ6R58+aydu1aufnmm2X58uUprzFmzBjp1KmTG9cdd9whM2fOzPqYslkwcX8ffPCBDBs2LKPShBAZcfFhBBBAAIFSEiCEsIPfH0I0kIXrI7ow5TFbZUCbDcyEsHsEqIyAdwKEEN61LPMB16hRw4UJ+oW1TJkyBxXQIEFDiHHjxsmePXvyfp5OCJFcbOfOnTJlyhSZOHFi5oNMcQYhRNE4hBBZfdQohgACCCBgJEAIYQQrIoQQdrZURgABGwFCCBvXSFW95ZZbpGvXrm5MCxYskEceeUTmzZsnHTp0kGuuuUaaNGkiGiDo33\/ttdcKDSFmzZolL7300kH3dfzxx0ubNm3kuOOOk\/Lly8vu3bvljTfekAcffDBrBoQQhBBZe5gohAACCCBQKgKEEHbsLoR4L+IzIdoxE8LuCaAyAv4JEEL417OMRtysWTO5\/\/77pW7durJw4UK58cYbZfPmzXk1jjnmGPfzhg0byhdffCH9+\/cvNIQo7lWB888\/XwYNGiTVq1eXTZs2yb333isfffRRRmMt6sOEEIQQWXmQKIIAAgggUGoChBB29BpC3PN\/NYSoaHeRAJXPOPYnGUAIEUCQUxGInwAhRPx6esAd6WyHgQMHSp06deT555+X55577qA7TqyhUHDNheTXMYoLIbRov3793LoTut6E\/gtRA49sHIQQhBDZeI6ogQACCCBQegKEEHb2hBB2tlRGAAEbAUIIG1evqupMiNNPP\/2ghR8zDSF0FsRjjz0mOrtiw4YNbhHJxYsXB7bIdgihr59cffXV0rp1a6lWrZqULVtW9u3b52aIzJkzx93DunXr8sadPFtEX0n5\/PPPpU+fPu41Fn0FRdfU0M+\/8MILMm3atELvt2PHjgeco6+\/6GKeEyZMcItn6sKb6QQ9BYuzJkTgx4sCCCCAAAIhCBBC2CFrCDH83Yay8LvozoS49rT1LExp9whQGQHvBAghvGtZdgesX8RHjBgh9erVO2j2QqYhhI7srrvukvPOO0927NghDzzwgLz11luBB5zNEOLiiy9262BUqlSpyHGtWbNGbrvttrwAJTmEmD17tug6GIWdr2HE008\/fdBsk0svvdRds0KFCgddU6+li4EeddRRhBCBnxQKIIAAAghEVYAQwq4zhBB2tlRGAAEbAUIIG9fIV61fv75brFK37KxZs6Zs3LhRxo4dKzNmzMgbe0lCiF69eknfvn3dKxk6MyAbO2VkK4TQWQO6S4je7\/fffy9a9+2335bt27fLKaec4oICDRj0eP31191aGXokhxD617r1p\/580qRJbhaEzorQcENDhtWrV8v111+fN5NCZ5jcfvvtecZ6TZ0toaHPtddeK+3atXOzKfRgJkTk\/9gwQAQQQACBEgoQQpQQLo3TNIQY8U6EZ0L8x0\/Sn5kQaXSSjyCQOwKEELnT67w7TXypT\/yNb775Rv7yl7\/Ihx9+eIBGSUII\/TKua1DoF2t9dUF33Ah6FBxvuvU0LNBXHWbOnOlO0ddDLrzwQtm2bZvbjvSdd945oFSDBg3k4YcflsaNG4vOeNAwoWAIoYGFvkIxderUA87VmRMXXHCBCyjuu+8+ef\/9993Phw8fLmeddZZ71WP06NEHhDz688TOJbp1KiFEup3lcwgggAACvgkQQth1zIUQ\/2gkX30bzdcxOjXZIv1P53UMuyeAygj4J0AI4V\/PAo244G\/1tdgvv\/wi3377rfsCHnQmRJRDCH095IQTTnCzFK677roDdglJoCYCj0WLFrkZDgVDiOXLl7sZDMk7jOhnEvet\/\/\/RRx+VKVOmyBFHHCEPPfSQNGrU6IBQI7mBurWphhM6M4IQItCjzckIIIAAAhEWIISwaw4hhJ0tlRFAwEaAEMLGNbJVy5UrJ0ceeaTo7AfdMUO\/aJ977rnuVQJ9JUO31vz444\/d+KM2E2L9+vXuC37BAKAg9mWXXSZt2rRxsxKSZ0IU\/Jyu69CiRQu3KOSvf\/1r9\/\/VRBeqLCqEUBudUVHwKCyESPZLNStE15Fo2bIlIURk\/9QwMAQQQACBoAKEEEEFiz5fQ4h7p0d3JkTHJlvkmg7MhLB7AqiMgH8ChBD+9SzrI9aFE\/v37+9eoXj33Xfd4pIlDSEGDBjgtunU3SaeffZZeeqppwKPN1trQuhAdEcLfV1E136oUqWK6GsQhR1FhRBFzVYoLIS46KKL8l7pKGzBysR1E1ukBpkJUfAe\/nv8SvnkvR8D21MAAQQQQACBkghcccNRcvpvax1wqs5E1NciObIrQAiRXU+qIYCAvQAhhL1x5K+QvLVm8usGJZkJkfhCHcXdMTp37ixDhw51i0TqoYtK6mwJfRVl5cqV8umnn8oll1wiTZs2LXImRFRDCA0dfli\/K+9Z+\/67XQf8deQfQgaIAAIIIBArgdr1ykudw\/cvvKxH819VkVN\/I4QQBl3WEGLU3xtHdk2Ijk23SL+O37FFp0HvKYmArwKEEL52LsvjLmy2QaYhRPLCjmvXrnWvLWioEfTIxkwIDVp0kUwNGPR1Dp2h8eabb7rtMZOP4taEyCSESPZ7+eWXZfz48YVSPP74426tiiAzIYb1XUDoEPRB43wEEEAAATMBXscwo3VbrN\/398by9bpoLkzZoekWuboTIYTdE0BlBPwTIITwr2cZjfjqq692v93fvXu32xEisWtDcpHkxSoXLlzottjUI9MQol+\/fu5VDN2eM\/m1jowGXMiHsxFCJN+Lbsupu1YUPJIXiczG6xi6DarupKFrcMybN8+9BlIw9Ei2J4QI+qRwPgIIIIBAVAUIIew6QwhhZ0tlBBCwESCEsHGNTNWuXbvKjTfe6Bae1C+5t99++0FfhPXn3bt3dwsyvvrqq3m\/sc8khDj\/\/PNl0KBBojMOdIFLXRBy7ty5WXHIdghRWECiC3YOGTJEunXrJoccckhWXsfQm7\/77rvlnHPOca9+PPHEEzJp0qQDTBL2GtwQQmTlcaEIAggggEAEBQgh7JqiIcToaToTopLdRQJU7tBsi1x1xre8jhHAkFMRiJsAIUTcOlrgfjQU0K0pdSFGnQ2h\/6LSRRIXL14szZo1c7Me2rVr5xalXLFihQssdOEoPZJDiFmzZonu8JB86Bd3fY1Ad6I49thj3QwI\/bKdahHGknBnI4RIflVk586dbgtNvR9dE6JDhw5uBofOhNAgRo9szITQOq1bt5YRI0a4LTj1Wq+\/\/roLIg477DC54oor3M4kaq8HIURJng7OQQABBBDwQYAQwq5LhBB2tlRGAAEbAUIIG9dIVdWwQX8jr0FBUceyZcvknnvuceFE4kgOIdK5oe3bt7sv9hpCZPPIRgih4+nVq5cLXRJf+guOUbcAXbVqlZx88smyZs0aNzNC\/zqdVyYK2x0jUV9nieirGIkFMZOvm1gcs1atWoQQ2XxoqIUAAgggECkBQgi7dmgIMeZvjWVRRGdCnN5si\/TtzEwIuyeAygj4J0AI4V\/PSjTiSpUqSZ8+feTss88W\/cKrsxZ0ZsSPP\/4o77zzjugXfQ0Rko90Qgj9Eq0LPX7yyScyefJkN5si20e2QggdV5cuXdysB50ZoWFEQYPf\/\/73outo6PHggw\/K1KlTA4cQWku3Bh08eLCbbVG5cmV3XZ1x8vzzz0vHjh2lU6dOhBDZfnCohwACCCAQGQFCCLtWaAgxdmpjWbQ2mq9jnN58i1z5G0IIuyeAygj4J0AI4V\/PGDECeQInnXSSPProo8LuGDwUCCCAAAJRFiCEsOsOIYSdLZURQMBGgBDCxpWqCIQiQAgRCjMXQQABBBAIKEAIERAwxekaQtz\/ZnRnQpzWfItccSYzIeyeACoj4J8AIYR\/PWPECOQJEELwMCCAAAII+CBACGHXJUIIO1sqI4CAjQAhhI0rVREIRYAQIhRmLoIAAgggEFCAECIgYIrTXQjxRmNZvCaaa0Kc1mKL9PktMyHsngAqI+CfACGEfz3zasRjxoxxiy6W5EjeJrMk5+fCOYQQudBl7hEBBBDwX4AQwq6HGkI88D8aQlS0u0iAyu01hPjdd9K+ffsAVTgVAQTiJEAIEaduRvBeBgwY4La8LMmxcuVKGT58eElOzZlzCCFyptXcKAIIIOC1ACGEXfsIIexsqYwAAjYChBA2rlRFIBQBQohQmLkIAggggEBAAUKIgIApTtcQ4sHXIjwT4rgt0vssZkLYPQFURsA\/AUII\/3rGiBHIEyCE4GFAAAEEEPBBgBDCrkuEEHa2VEYAARsBQggbV6oiEIoAIUQozFwEAQQQQCCgACFEQMAUp2sI8ZDOhFgd0TUhWm6RXsyEsOPlDBAAACAASURBVHsAqIyAhwKEEB42jSEjkBAghOBZQAABBBDwQYAQwq5LLoR4pbEsiWgI0U5DiHN4HcPuCaAyAv4JEEL41zNGjECeACEEDwMCCCCAgA8ChBB2XSKEsLOlMgII2AgQQti4UhWBUAQIIUJh5iIIIIAAAgEFCCECAqY43YUQUxpFdybE8ToTYj1bdNo9AlRGwDsBQgjvWsaAEcgXIITgaUAAAQQQ8EGAEMKuS4QQdrZURgABGwFCCBtXqiIQigAhRCjMXAQBBBBAIKAAIURAwBSnawgx\/uVGsmRVNBembHf8Frn8PGZC2D0BVEbAPwFCCP96xogRyBMghOBhQAABBBDwQYAQwq5LhBB2tlRGAAEbAUIIG1eqIhCKACFEKMxcBAEEEEAgoAAhREDAFKdrCDFhcnRnQrT9FTMh7LpPZQT8FCCE8LNvjBoBJ0AIwYOAAAIIIOCDACGEXZdcCDGpoSz5JpqvY7Rt9ZNc\/p+8jmH3BFAZAf8ECCH86xkjRiBPgBCChwEBBBBAwAcBQgi7LhFC2NlSGQEEbAQIIWxcqYpAKAKEEKEwcxEEEEAAgYAChBABAVOcriHEwy9FeyZEz\/OZCWH3BFAZAf8ECCH86xkjRiBPgBCChwEBBBBAwAcBQgi7LhFC2NlSGQEEbAQIIWxcqYpAKAKEEKEwcxEEEEAAgYAChBABAVOc7kKIFxtEek2Inl02SPv27e0QqIwAAl4JEEJ41S4Gi8CBAoQQPBEIIIAAAj4IEELYdcmFEC80kCUrI7owZeufpOcFhBB2TwCVEfBPgBDCv54xYgTyBAgheBgQQAABBHwQIISw6xIhhJ0tlRFAwEaAEMLGlaoIhCJACBEKMxdBAAEEEAgoQAgREDDF6S6EeL6BLF15mN1FAlRu23qr9OjKTIgAhJyKQOwECCFi11JuKJcECCFyqdvcKwIIIOCvACGEXe8IIexsqYwAAjYChBA2rlRFIBQBQohQmLkIAggggEBAAUKIgIApTnchxLMRnglxwlbp0Y2ZEHZPAJUR8E+AEMK\/njFiBPIECCF4GBBAAAEEfBAghLDr0v4Qor4sXRHR1zF+rSHE9+yOYfcIUBkB7wQIIbxrGQNGIF+AEIKnAQEEEEDABwFCCLsuEULY2VIZAQRsBAghbFypikAoAoQQoTBzEQQQQACBgAKEEAEBU5zuQohnDo\/2TIjuPzATwu4RoDIC3gkQQnjXMgaMQL4AIQRPAwIIIICADwKEEHZdIoSws6UyAgjYCBBC2LhSFYFQBAghQmHmIggggAACAQUIIQICpjjdhRD\/XS+6MyFO3CY9fs9MCLsngMoI+CdACOFfzxgxAnkChBA8DAgggAACPggQQth1KS+EWB7RhSk1hLiQEMLuCaAyAv4JEEL41zNGjAAhBM8AAggggIBXAoQQdu0ihLCzpTICCNgIEELYuFIVgVAEmAkRCjMXQQABBBAIKEAIERAwxekaQjzy13qydHkFu4sEqNzmpG3S46IfWZgygCGnIhA3AUKIuHWU+8kpAUKInGo3N4sAAgh4K0AIYdc6Qgg7WyojgICNACGEjStVEQhFgBAiFGYuggACCCAQUIAQIiBgitNdCPFU3WjPhPjDRmZC2D0CVEbAOwFCCO9axoARyBcghOBpQAABBBDwQYAQwq5L+0OIOrJ0WURfxzh5u\/QghLB7AKiMgIcChBAeNo0hI5AQIITgWUAAAQQQ8EGAEMKuS4QQdrZURgABGwFCCBtXqiIQigAhRCjMXAQBBBBAIKAAIURAwBSnuxDiidrRnglx8SZex7B7BKiMgHcChBDetYwBI5AvQAjB04AAAggg4IMAIYRdlwgh7GypjAACNgKEEDauVEUgFAFCiFCYuQgCCCCAQEABQoiAgClOdyHE4zoTorzdRQJUbnPKDunBTIgAgpyKQPwECCHi11PuKIcECCFyqNncKgIIIOCxACGEXfP2hxC1ZOm\/IxxCXLKZ1zHsHgEqI+CdACGEdy1jwAjkCxBC8DQggAACCPggQAhh1yVCCDtbKiOAgI0AIYSNK1URCEWAECIUZi6CAAIIIBBQgBAiIGCK010IMbFmdGdCnLpDevxpCzMh7B4BKiPgnQAhhHctY8AI5AsQQvA0IIAAAgj4IEAIYdclQgg7WyojgICNACGEjStVEQhFgBAiFGYuggACCCAQUIAQIiBgitNdCPFoDVn670PtLhKgcptTf5Yel\/7ETIgAhpyKQNwECCHi1lHuJ6cECCFyqt3cLAIIIOCtACGEXetcCPGX6rJ0aURDiDY\/S4\/LthJC2D0CVEbAOwFCCO9axoARyBcghOBpQAABBBDwQYAQwq5LhBB2tlRGAAEbAUIIG1eqIhCKACFEKMxcBAEEEEAgoAAhREDAFKe7EOKRahGeCbFTevRgJoTdE0BlBPwTIITwr2eMGIE8AUIIHgYEEEAAAR8ECCHsukQIYWdLZQQQsBEghLBxpSoCoQgQQoTCzEUQQAABBAIKEEIEBExxuoYQDz9cVZYuieaaEG3b7pQePbexJoTdI0BlBLwTIITwrmUMGIF8AUIIngYEEEAAAR8ECCHsukQIYWdLZQQQsBEghLBxNa1arlw56dmzp3Tv3l1q1aolhx56qOzatUuWLVsmL7\/8skyfPv2g67dt21ZGjhwpVapUKXJsWmPr1q0yf\/58+etf\/ypLly41vQ8t3qFDB7n44ouladOmUq1aNSlbtqzs27dPtmzZIkuWLJEXX3xRZs6cWeg4jjnmGLn\/\/vulYcOG8sEHH8iwYcPSHu+gQYPksssuc\/d7xx13FHmNtAuW0gcJIUoJnssigAACCGQkQAiREVdGH3YhxIQqsnRJuYzOC+vDbdvukh6Xb2cmRFjgXAcBDwQIITxoUvIQa9So4cIE\/fJZpkyZg0avQYKGEOPGjZM9e\/bk\/TydECK52M6dO2XKlCkyceJEE6Gjjz5abrnlFmnVqpULHoo6NJD47LPP5N5775V169Yd8LE4hBCVKlWSq666StTjxhtvzNiaECJjMk5AAAEEECgFAUIIO3QXQoyvHN0Qop2GEDsIIeweASoj4J0AIYRnLdMv7l27dnWjXrBggTzyyCMyb948N6PgmmuukSZNmogGCPr3X3vttUJDiFmzZslLL7100J0ff\/zx0qZNGznuuOOkfPnysnv3bnnjjTfkwQcfzKpSs2bNZNSoUdKoUSP55ZdfZO3atTJt2jQXnnz77bdSv359Offcc6VLly5uloOGLatXr5bbb79dFi9enDeWOIQQ9913n3Tu3FkWLVokffr0ydiZECJjMk5AAAEEECgFAUIIO3RCCDtbKiOAgI0AIYSNq0lV\/fKurx\/UrVtXFi5c6H5zvnnz5kK\/lH\/xxRfSv3\/\/QkOI4l5dOP\/880VfV6hevbps2rTJzUL46KOPsnJPOpPjgQcekJYtW7pXSKZOnSoTJkw4YNZG4kL62snQoUNdIKGvnGjoctNNN+Xdc5AQIis3k4UiY8aMkU6dOhFCZMGSEggggAAC0RUghLDrjQshHqokSxcfYneRAJXbtt8tPXr9zEyIAIacikDcBAghPOqoznYYOHCg1KlTR55\/\/nl57rnnDhp94kutzi64+eabZfny5e4zya9jFBdC6Of79evn1p3QL\/\/6L7eSvCpQGG2irgYMGkCMHj06ZQf0cxqC6Bd1nZnxwgsvyJNPPunOIYQQ91rOo48+KsP6LpAf1u\/y6GlmqAgggAACuSRACGHXbUIIO1sqI4CAjQAhhI1rqVXVmRKnn366e8UhSAihsyAee+wx90V\/w4YNrlbyqxAluUGtqa+J6CKUmdQ85ZRTZPjw4VKzZk23WKXO0tAZIAVDCH2lQ0OOo446yoUn27Ztk08\/\/VSeeuqpgxbZLG5hSn2t5eqrr5YTTzzRLeapr4Skqpfw0NDkj3\/8o3Tr1k0aNGjgXmvRGR+6noUGKDpGPXQxTg2U9OfJR6YLZRJClORJ5BwEEEAAgbAFCCHsxF0I8WDFaM+E6L2TmRB2jwCVEfBOgBDCu5YVPeDWrVvLiBEjpF69egfNXsh0JoRe5a677pLzzjtPduzY4V6heOuttwJpnXnmmXLrrbe6L\/XpzMZIvtjDDz8sp556qvz0009y9913u\/tLDiFWrlzp1pKoUKHCQWPcuHGjjB07VmbMmJH3s1QhxEUXXeReZSlqJxENQDRMKeihr5poCKSvmhS2aGjyGhuEEIEeJU5GAAEEEPBMgBDCrmEuhLi\/QnRDiNP2SI8+uwgh7B4BKiPgnQAhhHctO3jA+uVbF6vULTt1tkBhX7pLEkL06tVL+vbt62YV6G\/xg+6UEaReIjTQWQVPP\/20exUlOYRQFV2QUxe3fPzxxx2SBgkaouhsgxUrVrhXShI7bBQVQugsEl0AUx11VoIGDc8884ybzaC1dPFIfR1GjXVrz7lz57prJV4b6dixo1tsM7HN6Zw5c0TDF51VoTtgbN++3a2Boa+i6MGaEDH4A8gtIIAAAggUK0AIUSxRiT9ACFFiOk5EAIFSEiCEKCX4bF1WvyA3b948r9w333wjf\/nLX+TDDz884BIlCSGSf1uvu2nob\/+DHMlBgq5joFuApnsUNpbkEEJDAg0fJk2adEBJDR40nNFtQDVISQQURYUQuhNI+\/btXaDxxBNPHFRPd7LQxTI1pHj33XfdbBE9NGi47bbbpHLlym6WhwYZyVukJs9SSV40lBAi3SeAzyGAAAII+CxACGHXvf0hRHlZuqjoLc\/trl585ban7ZUeV+xmJkTxVHwCgZwRIITwuNUFZwLorehv4XWbS319Ifn1g7iHEF9\/\/bWbbZD8xV89dF0GtWjcuLEkf\/kvLITQrUl1oUx9nWX27Nly\/fXXF\/p0FLb4p9a79NJL3boRuu3m+++\/f9C5uq6FLi6qQZFutap9IoTw+A8gQ0cAAQQQSFuAECJtqow\/SAiRMRknIIBAKQsQQpRyA4JcXl8BOPLII92XWn1FQF8V0O0sdV0EfV1Ad5X4+OOP3SXiHkK8+eabRe60kVisc82aNTJkyBBZtWqVW9zysssuc69c6GsVM2fOFN2aVLcArVixoqSa+aFhR+\/evd1aGYnAobBrpNNbQoh0lPgMAggggIDvAoQQdh10IcS4Q2VJhGdC9LxyDzMh7B4BKiPgnQAhhHctSz1g\/W28roWg6yAkvy5QkhBiwIABbpvOffv2ybPPPut2mQhyJL68a41M6yXGoos7FrYmRKrQoKiZCwVDiKIWiyzqnvUVkMRrJYnXYhYtWuTCoHSPbIUQH7\/34wGX\/OS9H2TR\/K3pDoPPIYAAAgggkFUBDR2at6qaV7NOvfJSrc5PcuGFF2b1OhQTt1j3w2PKyZJFZSLJ0fb0fdKz715CiEh2h0EhUDoChBCl42521eStNZcvXy7XXnut286yJCFE4guyD7tjEEIQQpj9oaIwAggggEDGAoQQGZOV+ARCiBLTcSICCJSSACFEKcFbXjbxW\/m1a9fKzTffLBpGZBpCJK+lkFwnyLg1INHFLZs2bSobNmxwY1u8eHGxJU866SQZOXKkWwxyyZIl7lUKDVaS18RI9TpGYntPfW1l8ODBbi2Gwl7H0K05E+tAPPbYYzJ58uRix5b4QOIaya98pHNytmZCDOu7QH5YvyudS\/IZBBBAAAEEQhfgdQw78v0hRFlZ8nVEZ0J0+EV69t3HTAi7R4DKCHgnQAjhUcv0dYZLLrlE9JWEcePGFbr4YfIX84ULF7otNvXINITo16+fexVDt+dMfq0jKFeirq5noTt4FNxFomD95K0vddFJ3eHiySefdB9LvtfkRSeTaySHKcmLTRYWQpxwwglujYeCO1+kc8+60GS3bt3cwpSjRo0qtDfaPzXVAEX7p\/dPCJGOLp9BAAEEEPBdgBDCroOEEHa2VEYAARsBQggbV5OqXbt2Fd1yUheeLGwbSL1o8paUr776qowfPz7jEEIXaNQv6TpzQRe41IUb586dm5V70poPPPCAHH\/88S5MmT59uowdO\/agXS30YhpA6HaYutimhiEaqujCkZs2bToohNi+fbtMmDBBpk6desA4dbaFbtGpAYauafHiiy+6nxe1RefEiRPlxBNPdPet40reYSQxJl3ws127du4zGiLov\/yL26KzRo0a8tBDD0mLFi3cQqKJGRmJECL51ZlMoHWWiK5LwUyITNT4LAIIIIBA2AKEEHbiLoQYLbLka7trBKnctoNIz6uEmRBBEDkXgZgJEEJ41NCCX+D1Xzq6SKO+0tCsWTM360G\/HOuilCtWrHCBxLp16w4KIWbNmuV2f0g+9Au\/zgRo06aNHHvsse5Lvy68mFgEMptMOlb9Iq\/bZuqWovq6x7Rp01wgoa9K1K9f3wUPXbp0kYYNG0qZMmVk9erVbtZE8usbBbco1Z0uXnnlFTdbQrfZvPLKK+WMM85wHgsWLHABhs5CSBVCdO7c2QUfOhtCww4NNSZNmuT+\/ymnnCJXXXWVtGrVSsqWLSvqqDU14EiesaH3pKGNhh7z5s1z511zzTUueNHP6hj1tRQ9dOaFXlMDjXvuucft0pHJQQiRiRafRQABBBAoLQFCCDt5\/e\/BCffti3AIUUYuv7oMIYTdI0BlBLwTIITwrGX6Bf7uu+92QUFRx7Jly9wX2uQv7MmvY6RzyzqzQIMKDSEsDn1NQkMFnXWgX+iLOnRnjs8++8yFFolAJfHZ5BBizpw5LhzQWSIFj8I8ipoJoefqLhkaGlSqVKnQYWnIoLtgqLGGPYlDZzvoVp0tW7Z0wUnBQ+9FX8HQmSUaRuihQYnupqGhjx4a\/Oj6Eq+99lpa7IQQaTHxIQQQQACBUhYghLBrACGEnS2VEUDARoAQwsbVtKp+OdYvrmeffbbUqlXLfYHVVxt+\/PFHeeedd0QXptQQIflIJ4TQL8A6U+CTTz5xizImf8G2uiEdV48ePdxildWqVXOBhN6LzmqYP3++vP7660XODkgOITQw0VcaevfunTd7QmcvvPfee6KLTBb0SBVC6L02adJEdA0HDUmqVKniQgX1Wb9+vZuxobMjCtbU83RGhK77oK+AJHqj52mAojM0dMZH8qGfv\/POO92MDQ1Q9u7dm9H2pYQQVk8mdRFAAAEEsilACJFNzQNr7Q8h9sqSr36xu0iAym076kyIQ5gJEcCQUxGImwAhRNw6yv2kJVBcCJFWkQh8iBAiAk1gCAgggAACxQoQQhRLVOIPEEKUmI4TEUCglAQIIUoJnsuWrkAihNCZH\/p6hL7O4eNBCOFj1xgzAgggkHsChBB2PXchxL27ZclX++wuEqBy246HyOXXlGMmRABDTkUgbgKEEHHrKPdTpIC++qBrUeh6DLogZPPmzWXNmjUyZMgQWbVqlZdyhBBeto1BI4AAAjknQAhh13INIcaP3BnZEKJdJw0hyhNC2D0CVEbAOwFCCO9axoBLKnDcccfJ6NGj3c4ZeugCk\/\/4xz\/cApO+HoQQvnaOcSOAAAK5JUAIYddvQgg7WyojgICNACGEjWssq44ZM0Y6depUonvT3SR0Mc3SPHTLz8GDB7uFJnWxSP2XtoYSuoClrwchhK+dY9wIIIBAbgkQQtj124UQI3bIkq\/22l0kQOV2ncrJ5f0PYyZEAENORSBuAoQQceuo4f0MGDBATj755BJdYeXKlTJ8+PASnctJRQsQQvB0IIAAAgj4IEAIYdclQgg7WyojgICNACGEjStVEQhFgBAiFGYuggACCCAQUIAQIiBgitM1hHhoxDZZsnCP3UUCVG53Rnnp1b8iMyECGHIqAnETIISIW0e5n5wSIITIqXZzswgggIC3AoQQdq1zIcTwn6IdQlxbmRDC7hGgMgLeCRBCeNcyBoxAvgAhBE8DAggggIAPAoQQdl0ihLCzpTICCNgIEELYuFIVgVAECCFCYeYiCCCAAAIBBQghAgKmON2FEPdsliULd9tdJEDldmdUkF4DqjITIoAhpyIQNwFCiLh1lPvJKQFCiJxqNzeLAAIIeCtACGHXOkIIO1sqI4CAjQAhhI0rVREIRYAQIhRmLoIAAgggEFCAECIgYIrTXQjxXxtl8cJddhcJULl954rSa0A1ZkIEMORUBOImQAgRt45yPzklQAiRU+3mZhFAAAFvBQgh7Fq3P4T4XhYviGoIUUl6DaxBCGH3CFAZAe8ECCG8axkDRiBfgBCCpwEBBBBAwAcBQgi7LhFC2NlSGQEEbAQIIWxcqYpAKAKEEKEwcxEEEEAAgYAChBABAVOcriHEg3dvkMULdtpdJEDl9p0rSe\/rajETIoAhpyIQNwFCiLh1lPvJKQFCiJxqNzeLAAIIeCtACGHXOkIIO1sqI4CAjQAhhI0rVREIRYAQIhRmLoIAAgggEFCAECIgYIrTXQhx13eyeMHPdhcJULn9b6pI7+tqMxMigCGnIhA3AUKIuHWU+8kpAUKInGo3N4sAAgh4K0AIYdc6DSEeuHNthEOIqtJnUF1CCLtHgMoIeCdACOFdyxgwAvkChBA8DQgggAACPggQQth1iRDCzpbKCCBgI0AIYeNKVQRCESCECIWZiyCAAAIIBBQghAgImOL0\/SHEaln85Q67iwSo3P7MatJn0OEZzYQoV66c9OzZU7p37y61atWSQw89VHbt2iXr1q2TF154QaZNmxZgRJyKAAKlLUAIUdod4PoIBBAghAiAx6kIIIAAAqEJEELYUccthKhRo4aMHDlS9L9x9uzZI+vXr5fNmzdLvXr1pHbt2rJ79275n\/\/5Hxk\/frwdKpURQMBUgBDClJfiCNgKEELY+lIdAQQQQCA7AoQQ2XEsrIqGEPffsUoWf7nd7iIBKp92ZnXpc339tGdC9OvXz82C2L59uzzyyCPy1ltvuavr7IgbbrhBunbt6mZFjBo1St5\/\/\/0AI+NUBBAoLQFCiNKS57oIZEGAECILiJRAAAEEEDAXIISwI45TCKFBw1NPPSUtWrSQv\/3tby5oSD6qV6\/ugommTZvK22+\/LcOHD7eDpTICCJgJEEKY0VIYAXuBqIUQteuVdzf9w\/pd9jfv2RXUps7h5WXR\/K2ejTyc4TZvVUW+\/24Xz04h3Py5KvoZ5M9V6j+f+ucqKv\/MIYSw+2epCyFuXxHhmRA1pM\/ghmnNhDjiiCNc8NCwYUN54oknZMqUKQfBjRkzRjp16iQffPCBDBs2zA6WygggYCZACGFGS2EE7AWiFkJ0vbS+NG9VVcbdtsT+5j27gn4Z+POopnLVBZ95NvJwhvvXv50o\/z1+pXzy3o\/hXNCjq1xxw1FutP9n\/EqPRh3OUPWL7ZU3HMWfqyK49c+V\/vM4CkEEIYTdnwkXQty2TBZ9uc3uIgEqn\/bbmnLF4MZphRDFXSZ5psSMGTPk1ltvLe4Ufo4AAhEUIISIYFMYEgLpChBCpCtV+p8jhEjdA0KIon0IIYq2IYQo\/s8VIUTp\/\/PfegS5FELoehCDBw+WQw45xL228eKLL1rzUh8BBAwECCEMUCmJQFgChBBhSQe\/DiFE8V+WmAlRuBEhBCFESf8JxEyIksr5dZ6GEDpTKgozXgqT03\/\/6T\/H2rdvHwi2WbNm7lWNRo0aydKlS2XQoEGyadOmQDU5GQEESkeAEKJ03LkqAlkRIITICmMoRQghCCFK+qARQhBClPTZIYQoqZxf52kI4cMRJIRo0KCB27azZcuWsnHjRhk7dqzo6xgcCCDgpwAhhJ99Y9QIOIFECAEHAggggAACURdYt26dXHjhhVEfpnfj0\/8W8OGYO3duiYZ59NFHu10wdEeMzZs3H7BtZ4kKchICCJS6ACFEqbeAASAQTMCX\/\/gIdpecjQACCCAQB4GSfhGNw71zD5kLnHrqqW4HDH0FQ2dAjB8\/Xt55553MC3EGAghESoAQIlLtYDAIIIAAAggggAACCCBw9tlnyw033CA1a9YUnUVz3333yezZs4FBAIEYCBBCxKCJ3AICCCCAAAIIIIAAAnER6Ny5swwdOtQFEMuWLZN77rlHFi9eHJfb4z4QyHkBQoicfwQAQAABBBBAAAEEEEAgGgL6mqkuQqkBxMKFC+WOO+5wMyE4EEAgPgKEEPHpJXeCAAIIIIAAAggggIC3AuXKlXMLT\/7617+WNWvWyG233cYMCG+7ycARKFqAEIKnAwEEEEAAAQQQQAABBEpd4Mwzz3TBQ+XKlYsdywcffOAWreRAAAH\/BAgh\/OsZI0YAAQQQQAABBBBAIHYCAwYMkJ49e0qZMmWKvTdCiGKJ+AACkRUghIhsaxgYAggggAACCCCAAAIIIIAAAvESIISIVz+5GwQQQAABBBBAAAEEEEAAAQQiK0AIEdnWMDAEEEAAAQQQQAABBBBAAAEE4iVACBGvfnI3CCCAAAIIIIAAAggggAACCERWgBAisq1hYAgggAACCCCAAAIIIIAAAgjES4AQIl795G4QQAABBBBAAAEEEEAAAQQQiKwAIURkW8PAEEAAAQQQQAABBBBAAAEEEIiXACFEvPrJ3SCAAAIIIIAAAggggAACCCAQWQFCiMi2hoEhgAACCCCAAAIIIIAAAgggEC8BQoh49ZO7QQABBBBAAAEEEEAAAQQQQCCyAoQQkW0NA0MAAQQQQAABBBBAAAEEEEAgXgKEEPHqJ3eDAAIIIIAAAggggAACCCCAQGQFCCEi2xoGhgACCCCAAAIIIIAAAggggEC8BAgh4tVP7gYBBBBAAAEEEEAAAQQQQACByAoQQkS2NQwMAQQQQAABBBBAAAEEEEAAgXgJEELEq5\/cDQIIIIAAAggggAACCCCAAAKRFSCEiGxrGBgCCCCAAAIIIIAAAggggAAC8RIghIhXP7kbBBBAAAEEEEAAAQQQQAABBCIrQAgR2dYwMAQQQAABBBBAAAEEEEAAAQTiJUAIEa9+cjcIIIAAAggggAACCCCAAAIIRFaAECKyrWFgCCCAAAIIBYFhqgAABBZJREFUIIAAAggggAACCMRLgBAiXv3kbhBAAAEEEEAAAQQQQAABBBCIrAAhRGRbw8AQQAABBBBAAAEEEEAAAQQQiJcAIUS8+sndIIAAAggggAACCCCAAAIIIBBZAUKIyLaGgSGAAAIIIIAAAggggAACCCAQLwFCiHj1k7tBAAEEEEAAAQQQQAABBBBAILIChBCRbQ0DQwABBBBAAAEEEEAAAQQQQCBeAoQQ8eond4MAAggggAACCCCAAAIIIIBAZAUIISLbGgaGAAIIIIAAAggggAACCCCAQLwECCHi1U\/uBgEEEEAAAQQQQAABBBBAAIHIChBCRLY1DAwBBBBAAAEEEEAAAQQQQACBeAkQQsSrn9wNAggggAACCCCAAAIIIIAAApEVIISIbGsYGAIIIIAAAggggAACCCCAAALxEiCEiFc\/uRsEEEAAAQQQQAABBBBAAAEEIitACBHZ1jAwBBBAAAEEEEAAAQQQQAABBOIlQAgRr35yNwgggAACCCCAAAIIIIAAAghEVoAQIrKtYWAIIIAAAggggAACCCCAAAIIxEuAECJe\/eRuEEAAAQQQQAABBBBAAAEEEIisACFEZFvDwBBAAAEEEEAAAQQQQAABBBCIlwAhRLz6yd0ggAACCCCAAAIIIIAAAgggEFkBQojItoaBIYAAAggggAACCCCAAAIIIBAvAUKIePWTu0EAAQQQQAABBBBAAAEEEEAgsgKEEJFtDQNDAAEEEEAAAQQQQAABBBBAIF4ChBDx6id3gwACCCCAAAIIIIAAAggggEBkBQghItsaBoYAAggggAACCCCAAAIIIIBAvAQIIeLVT+4GAQQQQAABBBBAAAEEEEAAgcgKEEJEtjUMDAEEEEAAAQQQQAABBBBAAIF4CRBCxKuf3A0CCCCAAAIIIIAAAggggAACkRUghIhsaxgYAggggAACCCCAAAIIIIAAAvESIISIVz+5GwQQQAABBBBAAAEEEEAAAQQiK0AIEdnWMDAEEEAAAQQQQAABBBBAAAEE4iVACBGvfnI3CCCAAAIIIIAAAggggAACCERWgBAisq1hYAgggAACCCCAAAIIIIAAAgjES4AQIl795G4QQAABBBBAAAEEEEAAAQQQiKwAIURkW8PAEEAAAQQQQAABBBBAAAEEEIiXACFEvPrJ3SCAAAIIIIAAAggggAACCCAQWQFCiMi2hoEhgAACCCCAAAIIIIAAAgggEC8BQoh49ZO7QQABBBBAAAEEEEAAAQQQQCCyAoQQkW0NA0MAAQQQQAABBBBAAAEEEEAgXgKEEPHqJ3eDAAIIIIAAAggggAACCCCAQGQFCCEi2xoGhgACCCCAAAIIIIAAAggggEC8BAgh4tVP7gYBBBBAAAEEEEAAAQQQQACByAr8fxaxGc4rPd3fAAAAAElFTkSuQmCC","height":330,"width":549}}
%---
%[output:023d549c]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAABCEAAAJ7CAYAAADdt4tVAAAAAXNSR0IArs4c6QAAIABJREFUeF7s3QnUFNWd\/\/8v+6q4ICK4gBHF3agBjIIMStDguIIrR1GCCwRRUVEQCAiKgij6BxfUqINoGE2UaFTi8CPuojFuAUUiYkQQURbZ1\/\/53Jl6KJruru6n+\/ZT3f2uczyTyK1bVa97i0l9+i7Vdtttt63GgQACCCCAAAIIIIAAAggggAACCHgWqEYI4VmY6hFAAAEEEEAAAQQQQAABBBBAwAkQQtAREEAAAQQQQAABBBBAAAEEEECgIAKEEAVh5iIIIIAAAggggAACCCCAAAIIIEAIQR9AAAEEEEAAAQQQQAABBBBAAIGCCBBCFISZiyCAAAIIIIAAAggggAACCCCAACEEfQABBBBAAAEEEEAAAQQQQAABBAoiQAhREGYuggACCCCAAAIIIIAAAggggAAChBD0AQQQQAABBBBAAAEEEEAAAQQQKIgAIURBmLkIAggggECuAi1btrSxY8das2bNdqjqtddes4EDBya9RNeuXW3AgAFWr1697f58w4YNNmHCBJs6dWqut8b5CCCAAAIIIIAAAhkKEEJkCEUxBBBAAIGqFUgXQnz99dfWv39\/W7x48Q43edNNN9kZZ5yxw78nhKja9uTqCCCAAAIIIFCeAoQQ5dnuPDUCCCBQdALpQohVq1bZ7bffbjNmzNjuuWrWrGmTJk2y1q1bE0IUXYtzwwgggAACCCBQigKEEKXYqjwTAgggUIIC6UKIrVu32lNPPWX33Xffdk9+5JFHunBi1113JYQowT7BIyGAAAIIIIBA8QkQQhRfm3HHCCCAQFkKJAshtmzZYtWqVXP\/fPTRR3bllVduZ3PxxRdbr169rHbt2qbpFzVq1HD\/6GA6Rll2Ix4aAQQQQAABBKpYgBCiihuAyyOAAAIIZCaQLIRYuHChNWrUyBo2bGhLliwxrf8wZ86cigrvuOMO69Chg\/vvWjeiadOmLpBIF0K0bdvWLrnkEmvVqpXVr1\/fqlevXlFe13jxxRdt8uTJtmnTporr9OvXz7p37261atVy\/27jxo2uzEMPPVRR5pxzzjGVq1OnTsoymUlQCgEEEEAAAQQQKF4BQojibTvuHAEEECgrgWQhxHvvvWfNmzd3O2YkjmxQ4DB+\/Hjbd999bfPmzfb2229bmzZt0oYQffr0sfPOO6+iTDJgTf344IMP7JZbbrHly5e7IgpC7rrrLjv00EMrTlFgMWTIEPv4449N9z5mzBh3r8Hx4YcfulAiHGaUVYPysAgggAACCCBQlgKEEGXZ7Dw0AgggUHwCyUIIbc2pAEBrP+gIb9XZqVMnu\/nmm90oCS1cOW3aNDvrrLMqtupMDC1OOOEEGzx4sO2yyy6ROBrp8Nhjj9mjjz5aUfboo4+2kSNHbrf+hO5HdeqfLl26uGkjOpYtW+ZCDIUZHAgggAACCCCAQDkJEEKUU2vzrAgggEARC6QKIfRBH2zBGd6qU6MMLrjgAvfhr2kbmhpxww03uFBCR2IIMWLECOvcuXOF0BdffGFjx451Ixk0RUPnhkcyhAOP4KTLL7\/cevToUTEtY\/369fbCCy+4ACK4rv6dAgz9w4EAAggggAACCJSbACFEubU4z4sAAggUqUCqEGLWrFl29dVXuykU4a06H3jggYoREpq28eSTT7qRCqlCCE3fOPnkk61jx46255572t13373dlp8KNS688MIKvWQLYWpLUO3QcdRRR6VU1v0OGDCAaRhF2g+5bQQQQAABBBDITYAQIjc\/zkYAAQQQKJBAshBi5syZ9sQTT9jo0aOtSZMmFmzV+eqrr+7w7\/Txny6ESPUYuq5GMiigCI+E+Pzzz61nz547nHbEEUfYrbfe6u4n8Vi0aJFbPHPu3LkFUuMyCCCAAAIIIIBAvAQIIeLVHtwNAggggEAKgWQhxJQpU+z++++3SZMmWevWrd2ZGqEwY8YM69u3rxsdsXbtWrdo5NKlSzMKIRQinHnmmab\/u8cee6RcpDJVCKF7UDihf4KdMPTvNP1DozOeeuop2hgBBBBAAAEEEChbAUKIsm16HhwBBBAoLoFUIYSmPwwdOtROPfVU90DalUIjDbTQpA6NPrj++uttt912cyGEFrIMQoEJEybY1KlT3X\/XgpQawaAFJoNtOfXvV69ebV999ZX99NNP1q5duwq0dCHEwQcfXDESIzhhxYoV7t9p9AYHAggggAACCCBQrgKEEOXa8jw3AgggUGQC6UKI888\/36666io3akELP2rbywYNGrgnDNZuSDw\/cWFKBQQdOnRwC1kG23BqMUstTKkjkzUhVE7rQowaNcrat29fsRtGQD1v3jxXT7C1Z5E1AbeLAAIIIIAAAgjkLEAIkTMhFSCAAAIIFEIgXQihLTpvv\/327bbHDO7p+eefdyMQ0oUQiecHoye+\/PLLike75ppr7Lzzzqv478l2x9AfakeOK6+8Muk0DoUb2ipU98OBAAIIIIAAAgiUowAhRDm2Os+MAAIIFKFAuhBCUyy0NoTKhA+Ndrj33nvt2WefTRtCnHvuuRVrSOj8xBBCUzW0W0aw7oTKJAshDjzwQBcw7LXXXu42FDpoLYrGjRtXjIrQDh5jxoyx6dOnF2ErcMsIIIAAAggggEBuAoQQuflxNgIIIIBAgQSiplNoJIS21wwfWh9Cu1HMmTMnbQjRqVMnu\/nmmyu279y8ebO98cYbLlDYd9993RSKQw89dLvpFbNnz7ZevXpVXC6YhqEpHcGhtSSGDRtmQ4YMsQMOOGC7f3\/ddde5sIMDAQQQQAABBBAoJwFCiHJqbZ4VAQQQKGKBqBDi4osvdqGA1oUIjs8++8x69+7t1ohId75GLowbN85atGiRsVDiwpSJ0zC0NoUWzdQojNNPP9369+9v9evXd\/VrhMQrr7xiw4cPz\/h6FEQAAQQQQAABBEpBgBCiFFqRZ0AAAQTKQCAqhDjuuOPcR\/1OO+1UofHSSy\/ZiBEjKv77Y489ZgcddJD774kLU2pKxhVXXFERFIRJFRpogUtNywiCivAoi2TTMF5\/\/XUbPHiwC0B0aEREly5dKkZTrFmzxsaPH+\/WiOBAAAEEEEAAAQTKRYAQolxamudEAAEEilwgKoRo2rSp+6jX9IkgZNA6EU8\/\/XRGIYQKaUeLnj17uqkTGlGxceNG++677+zFF1+0yZMn26BBgyq2AtWUDf27hx9+2O2GEZ6GoWkWmgairUKDQ\/evtSCaN29e8e80XYNpGUXeMbl9BBBAAAEEEMhKgBAiKy4KI4AAAggggAACCCCAAAIIIIBAZQUIISorx3kIIIAAAggggAACCCCAAAIIIJCVACFEVlwURgABBBBAAAEEEEAAAQQQQACBygoQQlRWjvMQQAABBBBAAAEEEEAAAQQQQCArAUKIrLgojAACCCCAAAIIIIAAAggggAAClRUghKisHOchgAACCCCAAAIIIIAAAggggEBWAoQQWXFRGAEEEEAAAQQQQAABBBBAAAEEKitACFFZOc5DAAEEEEAAAQQQQAABBBBAAIGsBAghsuKiMAIIIIAAAggggAACCCCAAAIIVFaAEKKycpyHAAIIIIAAAggggAACCCCAAAJZCRBCZMVFYQQQQAABBBBAAAEEEEAAAQQQqKwAIURl5TgPAQQQQAABBBBAAAEEEEAAAQSyEiCEyIqLwggggAACCCCAAAIIIIAAAgggUFkBQojKynEeAggggAACCCCAAAIIIIAAAghkJUAIkRUXhRFAAAEEECgNgZ49e9oHH3xgH3\/8cWk8EE+BQAwEeK9i0AjcAgIIxF6AECL2TcQNIoAAAgggkF+BE044wQYNGmTvvvuuDR8+PL+VUxsCZSrAe1WmDc9jI4BA1gKEEFmTcQICCCCAAALFLXDrrbfaySefbCtWrLDRo0fbzJkzi\/uBuHsEYiDAexWDRuAWEECgKAQIIYqimbhJBBBAAAEE8iegX2wHDx5su+yyi3344Yc2atQou+qqq+yLL76wxx57LH8XoiYEykiA96qMGptHRQCBnAQIIXLi42QEEEAAAQSKU2DYsGHWpUsX27Rpk\/unXr169s0339i1117r\/i8HAghkL8B7lb0ZZyCAQPkJEEKUX5vzxAgggEDRCjRs2NDd+6pVq4r2GeJy4xdccIFdccUVVqdOHdu4caO9\/fbbdv\/999tXX30Vl1vkPgokwHuVP2jeq\/xZUhMCCJSuACFE6bYtT4YAAgiUjEDNmjXtkksusW7durndHAYOHFgyz1YVD3Luueda3759rXbt2u7ymzdvtmeeecbuueeeqrgdrllFArxX+YXnvcqvJ7UhgEDpChBClG7b8mQIIIBAyQjoY+muu+6yNm3a2Jo1a2z8+PE2bdq0knm+Qj9Io0aNbMiQIfbll1+a5rG3bNnSlixZ4v4dW3YWujWq7nq8V\/m1573Krye1IYBA6QoQQpRu2\/JkCCCAQEkJHH300TZy5Ejbddddbfbs2Xbddde53R040gto8cnzzz\/fjjrqKKtRo4Z99tlnNmXKFFu0aJE78ZxzzrF+\/fq5aRmvvfYao0zKrEPxXlWuwXmvKufGWQgggIAECCHoBwgggAACRSNw00032emnn24bNmxwuziwk0PqpgsPtdcHU\/jQmhqPPPKIPf300xb+NVz\/fsyYMTZ9+vSi6RPcaO4CvFeZG\/JeZW5FSQQQQCCVACEEfQMBBBBAoGgENG1AH8nNmze3b7\/91q6\/\/nqbP39+0dx\/oW5UH0o33nijnXLKKS5kkNX7779vLVq0sIMPPthq1aplc+bMsZtvvtlNwwhvLfjPf\/7TBgwYwCiTQjVWDK7De5VZI\/BeZeZEKQQQQCBKgBAiSog\/RwABBBCIlUDPnj1N\/2hRRa0LMXr06FjdXxxuJphiUb16dWekBSe1DaeOjh07WuvWre2JJ55w62sEB7+Gx6Hlqu4eeK+i7Xmvoo0ogQACCGQiQAiRiRJlEEAAAQSqVEC\/1J911lmmaQVbt261Zs2aubUhli1bZqNGjbI333yzSu8vThfXr7WTJk1yQYMWmdQuGEEAke4+9Wv42LFjna226dSaG8G6EXF6Pu4lfwK8V5lb8l5lbkVJBBBAIEqAECJKiD9HAAEEEKgygfr169ugQYOsQ4cObgpBsmPWrFlu+kAmH9pV9iAFvLCmW2h0SJMmTdwClPfdd1\/GVw\/\/Gv7WW2\/Zq6++at27d7dXXnnFpk6dmnE9FIy3AO9V9u3De5W9GWcggAACqQQIIegbCCCAQBUKtG3b1i666CI74IAD3Ef28uXL3Q4F\/\/Vf\/+X+c7kfw4YNsy5dutjGjRvtb3\/7m02ePNlWrlzpdnvo2rWrNWzYkC07EzrJscce63YR0XaBmYQQ+jX8iCOOsIkTJ7pztBXqoYceul2tS5cudetHfPrpp0XRJXmv0jcT71X23Zj3KnszzkAAAQQIIegDCCCAQIwENK1Ac\/CPO+44t7ZB4qHFAu+8886ynmag\/9E\/YsQI23nnne25555zUwXCh9Y20OKLmpYxb948t81kOQQ36ju\/+tWvbJ999nG7hLz99ttu0cng0L+\/++673eKd7733nl199dUpe75GmZx22mn2\/fffu\/6oxSrDrjpRffH++++3l19+OUZvUPJb4b2KbiLeq9R9h\/cquv9QAgEEEMiHACMh8qFIHQgggEAWAppbrHUM2rdv737h\/\/vf\/+4WD9Sh7SePOeYYF0xovQMFETNnzsyi9tIp2qdPH+vRo4cLFvQr\/EcffbTDw11wwQV2xRVXmBZg1CiJhx56qOgA1B\/22msv+\/e\/\/5323jWEXus7aARInTp1KspqjYzFixfbvffeW9FXxo0b5wIu9aGhQ4duF1KEL3Luuee6OhVm3HLLLfbuu++6P9bH\/EknnWQ\/\/PCDvfHGG0Ux1YX3KrOuz3u1vRPvVWb9hlIIIIBAPgUIIfKpSV0IIIBABgKXX365+7jesmWLPfjgg\/bUU09td1bwYa0Pzc8++8yuvfbasviFP5FOIxsuvPDCtFtx6sNT0wfatGnjFlHUr\/lz587NoBXiUURbaF511VVuKo5CgA8++CDpjSkU0HMecsghrt8odFA4o3\/ftGlTF8KsWrXKHnjgAXv22WddmKWFJdWHNL1n8ODBSYOEVCFEPHSyuwveq8y8eK+2OfFeZdZnKIUAAgjkW4AQIt+i1IcAAgikEQivsK5h9PpQDB+Jv8qtX7\/ezdUv1UUB5aH1B7TOw\/z587ezCD6WfvrpJ9McdnklOzp16uRGSjRo0MAtoDh8+PCi6YMKC\/r3729q91RhQfgXfjkpuPrTn\/5U8YzaNUSjQbSeg0Y+KMzQrhhakPKoo44y9aFkYZcq0HSXzp0729dff+3uQ+FGMR68V9u3Gu8V71UxvsfcMwIIlI8AIUT5tDVPigACMRAIb4OYuGig5ub37t3b7WqgX7s1P19bLQZD5GNw+3m7BS3Eef3117tf9jUKQFMK\/vWvf9kdd9xRsfihph1o1wtNTdFUC\/3Kn+zQSIDx48fbvvvu60YHaKqLphAUw6GPxTFjxrjRDAqbXn\/99R1uWyGL1m5Q2ccee8z9Ez7077U2hrw0IiLYLUQLTgZrZqxZs8YeffRRe\/LJJ92pOkd97bzzzivqqSyBA+\/V\/0rwXv2vA+9VMfztxz0igEA5CxBClHPr8+wIIOBFQL9q\/8d\/\/Ie1bt3aVq9ebTNmzKiYIpBsmzetDXHZZZfZgQce6D4ItRCgwocXXnjB\/Y9pDdnX9pPFsDBgJqDnnHOOXXnllW5ni8Rj4cKF7oNbUyq0ToLWOdh7773TTslQHfowP+igg1x1H374oVukslS27Azm8GuUgoKbL7\/8soJNfUd\/vt9++7l\/pwUmg76j\/67pFholoT6poEdrPKiMQg8NRde\/U\/Ch0RNx9+K9Sv928V5l8rfPtjK8V9l5URoBBBDIpwAhRD41qQsBBMpaQIHBJZdcYt26dXMfeMGhxSe1S8Gtt95qO+20U8XOBRrpoA\/Cdu3auV\/7NWz+xRdftAkTJrhtJ\/WhqIUp9eumPhQHDhxY9L7aClIOe+yxhy1YsMCNcFBQI7Ojjz7aPZ+mJWhtBx3XXHON+zOFM6mmWgS\/gjdu3NiqVavmPqxlWGxTWNTOmp6jhUofeeSRirYeMmSI\/frXv94uiGnRooVbSyLoOxoB8swzz9jjjz\/uwgR9sGuxSf1n7XahHTLUn+QTHJq6ofUjgnPi2rl4r6JbhvcqtRHvVXT\/oQQCCCBQaAFCiEKLcz0EEChJAX30ad0C\/TKtQ7846x\/9iq+1CvRh\/Oqrr7qdCoKdCwIIfSy+8847bhvEr776qsInPMRcH+bFGkIE61zoQ0lbSXbv3t1NMdHHtcIWHVrPQAsvan0ILbCoKQrTp093YY7WNtCHhJz+8Ic\/uGkL4UMf7meeeaZbB6FevXpuMc8gyCmWzrb77ru751Sbf\/vtt27EQ7BGRrA2hkIDrXfRoUOHih0ygr5zzz33uIU5jzzySDcyQtt0Ju6Koa0ZtWNGjRo13GiRYtj1gvcqdQ\/mvYp+u3mvoo0ogQACCFSFACFEVahzTQQQKDkBfTTqQ1i\/POtDWUPi9Z81pUAL\/i1dutT0oah\/F16MUFMv9PGtkCHxCE\/deP7552306NFF6aa1CbQ7g4IGBQw6ki00GZRT8DB79mw3KmDFihXul\/xgbQOtlaGQQR5apDHY0lQhjz7i9ct+sR49e\/Y0\/aNRMeFRH8EOFlo7Q6Nq9Ody0JQVrfMQXkciCCzkHN5ys1hNeK9StxzvVWa9mvcqMydKIYAAAoUUIIQopDbXQgCBkhTQL\/y333677brrrjZt2rTIsCC8raQ+Kp977jk3OiLxCD7A1q1bZ7fddptbW6JYD02vUGCg6QCJv\/SHnykop1\/4w4swHn\/88S6I0KKdiUeqERKFtgoCJ4VHGsmR7eKY4dEg4QU2w2tj6JnCa4YkPmMQQii8UQihkSfFevBeRbcc71W0Ee9VtBElEEAAgUILEEIUWpzrIYBAyQmcf\/75bn6+AgX9wv\/mm29GPqPWPxg5cqQLLhKnY4Tn++ujPVVIEXmRGBUITy1Jt+VmuJwWqbzhhhsqpiVo+Ll+1dSinxotIe958+a5HR\/isIPIr371K3e\/WnAz2KEivNij7lmLB\/785z93LfOPf\/zDjdxQ4BAcqeq4\/PLLrUePHm6hUo180MiSxIUk9WeahqKP9y+++MItzqkwolgP3qvoluO9Mvd3Ae9VdF+hBAIIIBAnAUKIOLUG94IAAkUpkO0QeH0kKlzYc8893cKLCiKSHQontCOGflWP+84F2sFD2z3uv\/\/+bstNLbipNS7CO3qEP6TTjRjJtFwcO4u2GNWaDWq78OKYCk\/kE16wVPevAELTd8LbbiarQ+fdfffdbscVhS9aX2Ts2LEVa2oooNHImZNPPtlN1XjwwQftqaeeiiNRxvfEe2VuZxzeK3Nb9\/JeZfzqUBABBBCIvQAhROybiBtEAIGqFtDIBP3Spg9ArUOgXRfCv7wHc\/Z1n+l2ZdAiaZpWcdhhh7mh+lpoUgsu6uPxkEMOcR\/vOoJf+H\/\/+99vN9+\/kA7B9pnBGg6prh3c\/+GHH+52sAgfWkhRu3vMnDnT\/evwh7T+TNMFPvjggx2q1vBpTU+RSbpyhfTI9FrhES4apaEP6VNPPdVtk6m1HLTNpp5JoUHz5s1dmyuw+NOf\/uTWDNGRrA6FFYlTUvTvtBilDk3ZkG9iXZned1WU471Krc57tb0N71VVvKFcEwEEEPAnQAjhz5aaEUAgpgIatq4PXe1eke7Qh51GKgTbIAZltZVm+Jdm7UgQrAnx9ttvuwUVUx369Vofk59\/\/rmbWhAc+ihVyKFDCy8Gu0YUmjC8HaJ26tBHdKpRGOEFI2WibUg1VUC7MJx44onuozu8wKSeJbwopxbjTDatILFcsqkNhXbJ5nrBtqI6R1NpNPJFH9wa\/REsTqo\/k9+1117r1rmQX3hhzaAOjWr47\/\/+b\/dnOhRgKbz62c9+tt12m\/qzdGtFZHP\/lS3Le5Vajveqsr1q23nl+l7lLkcNCCCAQPwECCHi1ybcEQIIeBTQ8OZLLrnEbZupX+K1rWOyo2vXrta3b183VUIfgtrdQiMU9MGoX68Tf6EPtt0Mby+ZrN5gWHFiCOHxkbOqOjwKIXFKQbiiAw880I3qaNasmdulQetb6Jf\/4AgWzFOAMXnyZHvooYfcH4UX5VTQMn78ePdxnnio3KhRo1wApO0k9Z\/1kV1Vh+5HuxH88pe\/dNtoKjTQugv\/7\/\/9vx36kMIr9QcFD6tXr3bP\/PXXXyddoyEc5Cj0UYCl0Q3hOvTc2s406KuqT9MutDZG48aNXd\/UfWiKRlVN2+G9St8zea+S+\/BeVdXfaFwXAQQQqFoBQoiq9efqCCBQIIHE4c2bN292v1JrZELiEXwYanj7ggULbOLEiRXTIi644AI3tL5OnTpuW83gl\/zwgoIayaBfuMMLDuoa+hDRL9qtWrVy5+oX7Tge4dEKwZSCxGcZOnSom6+uxSOvvvrqimkBwfMowOnevbtzStwNIzy0OnGkRNhDH+KawvLpp59WGZNGqGjRUT1rMEUlfDMKqL788ksXsoS3ygym6Gg0iI6XXnrJRowYkfQ5gl1QVFc4sFFfu\/LKK13oFd6ys8owklyY9yrz1uC92mbFe5V5v6EkAgggUIoChBCl2Ko8EwIIVAjof+zqg1gjG\/RBrCPdsHUFDwoK9HH11ltvuV+gw1MjVJ9+5dYUjMRf8kePHu0WT9OhtQ400iL4eNcvfhpOrA8R\/YquxSanT58ey5YKRiHoWRTWPPPMMxXrFQQ3rIUUDzroILcTiD6ig0Pn9u\/f3z2n\/rMW4NSRuBBlqpEScQL5xS9+4UYmaESDDo2E0cgGjTzQCASNpgnW8dCoETlpMU6NRtCzqx8dddRR7tznn38+5datGlWiMGyPPfawjz76yAUPOsJ1RI2wKbQb71X24rxX\/2vGe5V93+EMBBBAoNQECCFKrUV5HgQQqPiA07SLbt26VexIoI\/\/F1980S0emWrNBYUVAwYMcHXcddddrnz4A\/vGG290v4oHH5\/hX\/IVYOgcLaioQwHE3\/\/+d7dYoNYF0NQFfaAWw5ab4dEKidMB9GyPPPKIe049f69evdzzauSCtqhs27ate84\/\/vGPbn0IBTqy0JQKLcipQ1MaFMRoccbEkRJx6MLhaRKJW6gG9xfeSlUjHhRShNtWdShs0QgYTaVQGJZquoRGSXTu3NmNKFGoo9EVOsIjbDQtJd0aHYVwC69tEOz0wXuVuTzvVUfT36HJtiYu5\/cq8x5ESQQQQKA0BAghSqMdeQoEEAgJtG\/f3vr06WP77bef+yU+1UdkMrRgGL3O0WKTM2bMcMX0waVREVqjQB+bmr+vX7AT1zwIl0vcLSLZdoyFbjh9EK9YsSKjywbTBPQcmj6iD+rg0DaaGg0wZcoUZ6FfNzW9RKGCAp5HH33UnnzySbvooousd+\/ebhRK4ke0FubUP\/qwffzxx23SpEkZ3ZfvQuHRMBqB8MADD9izzz6b8rI9evSw3\/zmN+4ZExctHTZsmHXp0sWZaA2NoD8lVpZuO8qgDvW7dLuv+HbhvUotzHsV3ft4r6KNKIEAAgiUiwAhRLm0NM+JQBkI6Bd3hQ\/HHHOM25lh69atO6zpEMVw3HHHubBBv0jrg0\/TKsIf2MFHqRYlvPXWW91ClSqrD3Qt0BgcGvlw5plnuiBk7dq1btqChuRX1a4XstF0kGAEQrBtZjqP8OKI6aYDhEcNaNTE3XffXbEt58EHH+ymIQQ7QGgah\/7RoQ83tdc\/\/vEPe\/nll6OapmB\/rukQChYS12hIdwOatqH21ggZrZOhESHz5893I2CCfpJul48ghJCf+tKcOXO260tBHep3KptpkJQPNN6r1Iq8V5n3MN6rzK0oiQACCJS6ACFEqbcwz4dIkdFIAAAgAElEQVRAGQkEC\/kpgNBHs7Y21C\/y2ewYoF\/ldX4QFmh6hj769MGc+IEd7HShsCNxpEDc2INRB8lGJER9XJ9zzjmm0RDJpgOEV\/3Xx\/egQYO2C2PCIYSuo49nrZUQnuYSJ6vw4qHZfPCHd\/1IXEdDo0aCUCMcwgTPrXMVeCmwSDVtQ6NSzj77bFu3bt0O04R8+\/FepRbmvcqs9\/FeZeZEKQQQQKBcBAghyqWleU4EykAgvJCfhq6HdxpI9vgqH3wcPvHEEzsUCc\/f1gepdoTQ1IPgCH691n9PHIYfN+5MtwgM7lsfxBqlcPjhh7sAInjGxI\/oTp062c033+yCG60TkegYfKTpl32NCtFIAe0Uce+992YVDhXKU2tYaLtReaVbTDLZ\/WgLT+2WomHn2pJTC3QuXrzY\/fdgsdPwVBXVEV6wVCMvNCVF01gSj+OPP96GDx\/uFsPUFBjVV6iD9yq1NO9VZr2Q9yozJ0ohgAAC5SJACFEuLc1zIlAmAuGF\/NIteBie3\/7999+7KRj6FTp8KHQ49dRT3QiIZH+uD2l9rCvw0PaN2jlB\/047QcTxCG8RqDBFUwg0lSR8aAqGpm1o7YtgSoueXx\/SGkWReF6whobqSAwhNI1FbgoetCiltjv96aefdti6NE5WGvWhLUd1aKeLp59+Oqvb084pmtKjKTjhhU1Vr0IrGWrkzA8\/\/OD6laapaBtS\/Ttt8akdVRJH7mgBTJ2rBT81yqIq1oXgvUrdDXivol8R3qtoI0oggAAC5SRACFFOrc2zIlAmAsFCfnrcxK0hgznc+oU\/vG6EPh7fe++97YSCbSg\/\/\/xzt4Bi+Ag+PDQFQVM+Tj75ZLfWwbx582KtHEwhSZwykGzXAy2kqW0ntWikRgdoy079Wq8dILSlpA5tVaoFPLXavQINrQfxySefmIbwy0i\/3BfDbiBBowWhioITjaSZOHFiVu158cUXu91CEs9PnK6hhU\/r1avn6l62bJlb+FLOyaYOBcFGEFRotEU2U4yyeoA0hXmvUuPwXqXvZbxX+XoLqQcBBBAoDQFCiNJoR54CAQRCAuHFAIOtIbXApLZI1BoP+jVah36JVnDw5z\/\/OelHnUY16Nd8rWOgxRWDxRzPOussu+KKK6xu3bpuWHy6nRPi1jDJtgjcd999XciiLUSD3UTefvttGz9+fMVIibCpPpr1i71MdchGAYXODR\/60NaCk9qKsyo+mitjr9EGClw0skXrfGjHj2yO8PmadqKtN4MjmK6hIfyq+5577nF\/pCkb6Q7tMKI+98ILL7hgpKosea9StxLvVfq3hPcqm79FKIsAAgiUvgAhROm3MU+IQFkKBIsB6hdpreegDz8Nfdeh9Ru0MKKGtafbrSK8vaTO0VQE\/eKvrSn1IfinP\/2p4kOymJCDrTdr1KjhfoWXjdZ90CgHjWLQKIdkIzo0TaNbt26m88If6JqqoR0dNA1Bo0tUj9ZE0C\/7cdr1IpM22meffdxoDm01+s0337ipGYlTVtLVky6E0HlyUmCTbuRDJvdZVWV4r1LL816ltuG9qqo3lusigAAC8RQghIhnu3BXCCCQo0B4McCgqqiP7MRLagi9fhXX+hHB4owqow93LcCY7XoBOT5S3k4Pb70ZVKpRIVoUUb+2pzoSF1jUSInw+hf169e3Vq1aubUfNAKlWA+NXujcubNb6yNqcdPEZ9RImwEDBrhRMpWZzhF3M96r1C3Ee5W+9\/Jexf3t5v4QQACBwgkQQhTOmishgECBBcKLASo40Nz6V199Neu70DD60047zU3j0DQFfainG0GR9QWq4ITw1oIa4aGdHBRERB3B3G6NeJg9e7Zb3FLTVUrpCC\/CmGoBz1TPG2ylqf5x22232YwZM0qJxj0L71XqJuW9Sm3De1VyfxXwQAgggEClBQghKk3HiQggEHeB8GKAlflVO+7Pl8v9hbdd1FSTxK03U9WdeF6qLSVzubeqPjfcb7JZDDK8ZoJ2WtEaJFW1foNPQ96r1Lq8V+lttGNMmzZtKnaDyWSR1XJ5r3y+s9SNAAIIxE2AECJuLcL9IIBAXgWCxQA1jFxz+zUnf+7cuXm9RrFWFv5lUrt83HDDDTZ\/\/vzIx5HpjTfe6LaUjFpXI7KymBYILzSoACtqhw8NxdfUnUMOOcRWrVrlFuOcPn16TJ8u99vivUptyHuV2ob3Kvd3jxoQQACBUhAghCiFVuQZEEAgrYCCB20XqeOVV16x4cOHI\/Z\/AsHOFvqviduZljuSthnVLiiahqMgQlNx7r\/\/frdAafjQVJ3evXu7hU8zCSxKxZX3KnVL8l6ltuG9KpW\/AXgOBBBAoPIChBCVt+NMBBDIUUCjEw444AC324LWFfjss89yrDH56S1btnQ7PmgLymDLzjfeeMPLtfJVaaFs0m29ma9n8VFPoXy0\/sGVV17ptuzUoZBBa2eov2pL0qZNm5ruRf9Z01qmTp1qEydO9PHIGddZKBveq9RNwnuVvrsW43uV8QtIQQQQQACBSAFCiEgiCiCAQL4FTjnlFDv\/\/PNt\/\/33N22hGRyrV692IxV8DPEPby344YcfWr9+\/WI5X78qbGTRvXt31xazZs1yuzvEdS2DqvA57LDD7Nprr7XWrVtvt0tK0G+164qm+Dz66KNuikpVHVVhw3uVurV5r9K\/CcXyXlXV+8x1EUAAgVIWIIQo5dbl2RCImYB+HezTp48dfvjhST\/mgtvV+gR33HGHvffee3l7gkaNGrndMTRnf8OGDS7o0K\/WcTmq0iZq6804GFWlT\/D8uodf\/\/rX9rOf\/cz1X4UPGr3z5z\/\/uUrXGalKG96r1G8H71Vmf3PE9b3K7O4phQACCCBQGQFCiMqocQ4CCGQloEX7rrnmGmvXrp1pa0cdS5cutb\/+9a\/uA05z7rWYW+fOna1x48buz7Wl5p133mkzZ87M6lrpCmtdCG1FWb9+fTevX9tLarHKqjziYhPeelMf1vrlX1NXqvqIi09VOyS7flxseK9S9w7eqzi+OdwTAggggEBVCxBCVHULcH0ESlhA29Vdcskl1q1bNzdvXoc+bP\/0pz\/Z5MmTbc2aNds9vT6qhg4dakceeaSbY5\/voED3M2rUKDesXltLvvDCC1WmH0cb7eigKTJVbaNGiZtPlXWUJBeOmw3vVereIRveqzi9PdwLAggggEAcBAgh4tAK3AMCJSjQtm1bt42jggUFCpoC8c4779g999yTdvSBwgrtJa9pE1u3bi3J3SywSd\/h8Untgw02lf1\/F\/SdyspxHgIIIIBAvgUIIfItSn0IIOAEFD5oDYYWLVq4XQMee+wx908mR3gv+WLZzSKT5wrKYJNeC5\/UPthgk83fNeGy9J3KynEeAggggEC+BQgh8i1KfQggUCGg\/eC1vaHWgZg9e7Zbg0FbG2ZyaA0JTePQ9p2vvfaaDRw4MJPTiqYMNumbCp\/UPthgU9m\/6Og7lZXjPAQQQACBfAoQQuRTk7oQQGA7Ac2Hvu++++yoo47KejREy5YtbezYsdasWTP7\/vvv7frrr6\/SHQjy3bTYpBfFJ7UPNthU9u8j+k5l5TgPAQQQQCCfAoQQ+dSkLgTKTOCEE04wrf5+wAEHuCefN2+e2\/byjTfeqJDQrhc33HCDNWzY0L799lsXJsyfPz8jKS1Seeqpp+ZtS83TTjvNLr\/8cnvrrbds9OjRGd1DZQthk14On9Q+2rLwxBNPdCOItJbK3\/72N\/v444+3O6Fc3yts0r9X+FT2b2zOQwABBBAopAAhRCG1uRYCJSKg0EFhwuGHH27Vq1ff7qk2btxoL7\/8sttec9OmTe7Phg0bZl26dHH\/edq0aRkHAOecc45dffXV7mNsypQpblRFZY727du78EE7P+ieXn\/9dbvtttt22J2jMnUnnoNNekV8UvscdthhbmtU7d4Sfq8URCTrs+X0XmGT\/r3CJx9\/e1MHAggggEChBAghCiXNdRAoEYHjjz\/e7XrRpEkTW716tdvxYtasWW7KhT72NeIhcSFK\/Tp36623unOWLVvmtsl88803I0W0mvvIkSNdnZVZF0ILsWltiXbt2lmtWrVswYIFNnHiRPdB5+PAJr0qPql9Onbs6N6rXXfd1b1XGlWk\/6tdYrRjTLKdYsrlvcIm\/XuFj4+\/zakTAQQQQMCnACGET13qRqDEBPQxpNEI+jV74cKF9rvf\/c4+\/fTTiqcM\/4\/hr776yv2qu3jxYvfn\/fr1s+7du7swQKHFgAEDKkZKpGIKhxDPP\/98xiMo6tevbz169LCzzjrLfcAtWbLE7czx5z\/\/OfKalW0ybNLL4ZPaJ2zzxRdfmKYh6f3RoSDt9ttvt4MOOsgFeDfffLN99NFHFZWV03uFzY59iL5T2b+xOQ8BBBBAoCoFCCGqUp9rI1BkAhdddJH17t3bfchrusX06dN3eIKbbrrJzjjjDPcrroaLByMewv9jWSMlFGY8++yzaQUuvvhi69WrlyvzyCOP2BNPPBEppnUfdI8adaHrvPjiizZhwgQvUy\/CN4NN+qbBJ7WP1lXp27evaSpTsvcq+HPVoL6sdVeCo9TfK2zSv1f4RP6\/BAoggAACCMRQgBAiho3CLSEQV4Fgoch0C0ym+2AK\/kxrPGi4uX7FXb58edLHPfDAA926Dc2bN89od4zwWgObN292W4Jqdw1dpxAHNumV8Unto\/fgwgsvTLlwazAiSNvV3nXXXS5YCx+l\/F5hk\/69wqcQf7tzDQQQQACBfAsQQuRblPoQKGGB4ENy0aJFbmHKL7\/8coenDT6IFAQkfjBpezj9uzZt2rhffSdPnmwPPfTQDnW0aNHCRowYYa1atXLlnnvuORs3blxSWQ1X79+\/vx133HEFWfchVfNik1kIQd\/Z0Sn4kEw23UKlNRpIo4I0rUgLtcowfJTye4VNZiEEfaeE\/x8vj4YAAgiUoAAhRAk2Ko+EgC8BTXO45JJL3HSMSZMm2ZNPPrnDpaI+GrQ14+DBgyvWahgyZEjF9oP6mFL93bp1c3++ZcsWt4jkLbfcknQtB60Ir9ESe+yxhxtR8cwzz9jjjz\/ubd2HdK7YpO91+KT2UcBw2WWX2YoVK+zuu++2mTNnVhRWH1cgp7Bt1apV7t9rtwxtg6t1ToJAolTfK2zSv1f4+Pr\/dtSLAAIIIOBTgBDCpy51I1BiAlqNX6MO\/va3v7kP\/jVr1uzwhPfee6\/94he\/sPnz59tVV13lPqwSD60bcfrpp7t\/\/corr9jw4cPdzhp9+vSx\/fbbz6pVq+Y+tLSQ5D333JM2VNAIBO0c8PDDD+\/wC3Eh+bFJr41Pah8Fbur34QUnVfqCCy5wIyD058kOjUTSuzN37lz3x6X4XmGT\/r3Cp5B\/y3MtBBBAAIF8CRBC5EuSehBAwFq2bOnWYWjWrJm99NJL7hfcZEe4nH7d1a+5moKhnTMUKPjeSrMqmgqb9Or47OijoE6hn3aFUMj2\/vvvW6dOndzCq0FYF966tpzeK2zSv0\/4VMXf8lwTAQQQQCBTAUKITKUohwACkQLp1oNIPPnyyy9322gqeAiOQmylGfkQngpgkx4Wnx19GjVqZIcffri98847240G0q\/fmrbRunVrtwuNpiTNmDHDVVAu7xU26d8nfDz9RU61CCCAAAJ5ESCEyAsjlSCAgAS0eKQWiPz666\/dL7iLFy9OCaP\/kazyhxxySEG30qyqlsImvTw+2fXMYMtTraOidVC0RouOcnuvkqlhk74v4ZPdu0ZpBBBAAIH8CxBC5N+UGhEoSwFtqampGFok8vnnn7fRo0fv4HD00Ue7tR4+\/fRT92ennHKKnXTSSfbggw8WbCvNqmgcbNKr45N9rwy27WzYsKFNmTLF7rvvvopKyuW9SqWGTfr+hE\/27xtnIIAAAgjkV4AQIr+e1IZA2QpoAT1tJagtNcPDwwWi9R60SGW7du1s9uzZph00tMNGuRzYpG9pfLJ\/E44\/\/ni3KGXdunW3GwmRfU2ldwY26dsUn9Lr8zwRAgggUGwChBDF1mLcLwIxFQh2xdAiegoZtCtG\/fr1rW\/fvta1a1erU6eOu3Ot+zBmzBi3xWC5HNikb2l8kvtoqkXt2rWT7kJzzTXXuK1sV65cadohRotWltOBTfrWxqec3gaeFQEEECg+AUKI4msz7hiB2AmEV+UPpmKcdtppbhX\/Jk2auPtdv369vfjiizZhwoSkH1Wxe6g83RA26SHxSe5z2GGH2cCBA12Qp6lN7733XkVBhXoK+nbeeWfT7hjamrOcDmzStzY+5fQ28KwIIIBAcQoQQhRnu3HXCMRKIBjeq50upk2bZkcddZTtv\/\/+Vr16dduyZYt98sknbr2IefPmxeq+C3Ez2KRXxie5z8iRI912nNWqVXMB3t\/\/\/nf79ttvrVWrVnbwwQe7ERKa2jRgwABbvnx5IbpybK6BTfqmwCc2XZUbQQABBBBIIUAIQddAAIGcBYLtFfVhFBxbt261BQsWuFX7g+0Dc75QEVaATfpGwye5j4bTa5rFiSee6AKH8KHFXd9++203QqLcAgg5YJP+ncKnCP8fBbeMAAIIlJkAIUSZNTiPi4APgcQPSX0YPfPMM27BvHJagDKZLTbZhRD0ne29jjjiCDvzzDNtv\/32c3+gYO+5556zjz\/+2MerXFR1YpO+ufApqu7MzSKAAAJlJUAIUVbNzcMi4EfgyCOPtNtvv90aNGjgfqEdP368LVq0yM\/FiqxWbNI3GD5F1qG5XQQQQAABBBBAIEcBQogcATkdAQT+d3h0jx493I4X5bjuQ7o+gE36NwQf\/gZBAAEEEEAAAQTKS4AQorzam6dFAAEEEEAAAQQQQAABBBBAoMoECCGqjJ4LI4AAAggggAACCCCAAAIIIFBeAoQQ5dXePC0CCCCAAAIIIIAAAggggAACVSZACFFl9FwYAQQQQAABBBBAAAEEEEAAgfISIIQor\/bmaRFAAAEEEEAAAQQQQAABBBCoMgFCiCqj58IIIIAAAggggAACCCCAAAIIlJcAIUR5tTdPiwACCCCAAAIIIIBArAWC7ZvPOussa9y4sVWrVs1WrVpl7777rk2cONEWLVoU6\/vn5hBAIL0AIQQ9BAEEEEAAAQQQQAABBGIhoABi6NCh1rFjR3c\/CxcutPXr19vee+9tDRo0sG+++cYGDx5sc+fOjcX9chMIIJC9ACFE9macgQACCCCAAAIIIIAAAh4ETj\/9dOvfv7\/VqFHDHnzwQXvqqafcVVq0aGEjRoywVq1a2WuvvWYDBw70cHWqRACBQggQQhRCmWsggAACCCCAAAIIIIBApMC4cePsuOOOs\/fee8+uvvrq7cpffPHF1qtXL\/vhhx\/s+uuvty+\/\/DKyPgoggED8BAgh4tcm3BECCCCAAAIIIIAAAmUnsPvuu9uoUaPsZz\/7mU2dOtUmTZq0ncG5555rffv2tbVr19ott9xi77\/\/ftkZ8cAIlIIAIUQptCLPgAACCCCAAAIIIIBAiQtoOkbnzp3tiy++sH79+tmKFStK\/Il5PARKU4AQojTbladCAAEEEEAAAQQQQKAkBA488EA3DaNdu3a2devW7daKKIkH5CEQKDMBQogya3AeFwEEEEAAAQQQQACBYhDYf\/\/9bezYsbbXXnu52129erU98cQT7h8OBBAoXgFCiOJtO+4cAQQQQAABBBBAoMwFunbtup2ARgpUq1atSlWS3cOLL76Y9T0dffTRbnHKzZs3W5MmTUxrRmzcuNFefvllGzNmjG3atCnrOjkBAQSqXoAQourbgDtAAAEEEEAAAQQQQKBSAm+\/\/bbVrLkodK4CiK2Vqit\/J227h02b\/ncUg3a8yOWoWbOmXXPNNaYtPLds2eIWrXzyySdzqZJzEUCgigQIIaoInssigAACCCCAAAIIIJCrgEKIpnv1s7r1\/pFrVV7OX\/XTqbb0+8E5hxC6OQUREyZMsCOOOMI++ugju\/LKK73cM5UigIBfAUIIv77UjoBXgWCOZLKLxHU4pleQJJXj8L8oOOAQfj3y0R\/yUUeufx9wD8XVrxctCv9an2vrc34g4EKIpldb3boxDSFWnWpLlw7KSwihZ77pppvsjDPOsM8\/\/9x69uxJR0AAgSIUIIQowkbjlhEIBDRXUr8IcCCAAAIIIBB3AYUQZ599dtxvs+jur5RCCP3vmmHDhlmDBg3s7rvvtmTrSAwdOtROPfVUQoii66ncMALbBAgh6A0IFLFAEEI8es8C+2HJhip\/kl+etLs1blLbpj0Vn1+77vr9+Cp30Q2sW\/tzW768lzXd67exuJ+43cTiRf+f7bLLI7EdTlyVXsuX9XKX32XXR6ryNmJ57XXrfm7y4b1K3jx6rxrvMSphvYCqaUr9HThnzq8JITzwK4TYc8\/+Vrfuhx5qz73KVatOsR9+uDmjkRBNmza18ePH27777mt\/\/etfTYFD+Nhll13svvvuswMOOCDpn+d+t9SAAAKFECCEKIQy10DAk0AQQgzs9c9YhBCnX9DUDjp8Jxsz6AtPT5x9ta9+Go+Pfn0s6YOgRcvjs3+IMjjjq\/lvuo+lhg3\/UgZPm90jai61DvlwbC+wSsO8v7+F9ypFx9B7pYAmDsP0V636tX3y8WWEEB5eYhdCNLk2viHEaoUQAzMKIcSjxSe7detmq1atcoFDMBqifv36bpRE+\/btbfny5TZq1Ch78803PYhSJQII+BYghPAtTP0IeBQghIjGJYSINopDCUKI1K1ACJHahhAi\/dtLCBGHv93830OphRAa7aAREO3atXNbcC5cuNDWrl1rWgdLf7ZmzRp78MEHberUqf5xuQICCHgRIITwwkqlCBRGgBAi2pkQItooDiUIIQghKtMPCSEIISrTb0rtHIUQTfa41urW+SiWj7Z6dRf7YVnmIyH0ENoFo0ePHnbWWWdZ48aNrXr16rZ69WqbM2eOm64xb968WD4rN4UAApkJEEJk5kQpBGIpELcQ4qDDG9ruTWrbW\/\/zY2y84hJCaJ90bVO2y66PxsYmTjeyfNll1nCnl2Ixdz1OLroXDWOvWXNRLIbUx81G05y01gDvVfKWidN7xXQMf29PKYYQ\/rSoGQEE4iBACBGHVuAeEKikQNxCiEo+htfT4hJCeH1IKkcAAQRiLkAI4a+BXAjR+Lr4joRYo5EQN2a8JoQ\/KWpGAIG4CBBCxKUluA8EKiFACBGNRggRbUQJBBBAwLcAIYQ\/YRdC7H691akd0+kYa39lPy6\/gRDCXxegZgSKToAQouiajBtGYJsAIUR0byCEiDaiBAIIIOBbgBDCnzAhhD9bakYAAT8ChBB+XKkVgYIIEEJEMxNCRBtRAgEEEPAtQAjhT9iFELtpJMTH\/i6SQ82rNRJixfWMhMjBkFMRKDUBQohSa1Gep6wECCGim5sQItqIEggggIBvAUIIf8KEEP5sqRkBBPwIEEL4caVWBAoiQAgRzUwIEW1ECQQQQMC3ACGEP2EXQuxyQ3xHQqzrbD+uZCSEvx5AzQgUnwAhRPG1GXeMQIUAIUR0ZyCEiDaiBAIIIOBbgBDCn7BCiD12udHq1IrpdIx1nW3ZTwOYjuGvC1AzAkUnQAhRdE3GDSOwTYAQIro3EEJEG1ECAQQQ8C1ACOFPmBDCny01I4CAHwFCCD+u1IpAQQQIIaKZCSGijSiBAAII+BYghPAn7EKInQfGdyTE+s62bNV1jITw1wWoGYGiEyCEKLom44YR2CZACBHdGwghoo0ogQACCPgWIITwJ0wI4c+WmhFAwI8AIYQfV2pFoCAChBDRzIQQ0UaUQAABBHwLEEL4E3YhxE4aCfGJv4vkUPPq9SfbstWMhMiBkFMRKDkBQoiSa1IeqJwECCGiW5sQItqIEggggIBvAUIIf8IuhGh4k9WpGdMQYsPJtmzNtUzH8NcFqBmBohMghCi6JuOGEdgmQAgR3RsIIaKNKIEAAgj4FiCE8CdMCOHPlpoRQMCPACGEH1dqRaAgAoQQ0cyEENFGlEAAAQR8CxBC+BN2IUSDm2M8EuIkW7aWkRD+egA1I1B8AoQQxddm3DECFQKEENGdgRAi2ogSCCCAgG8BQgh\/woQQ\/mypGQEE\/AgQQvhxpVYECiJACBHNTAgRbUQJBBBAwLcAIYQ\/YRdC1B9kdWrEdE2IjSfZsnXXsCaEvy5AzQgUnQAhRNE1GTeMwDYBQojo3kAIEW1ECQQQQMC3ACGEP2EXQtSLeQixnhDCXw+gZgSKT4AQovjajDtGoEKAECK6MxBCRBtRAgEEEPAtQAjhT5gQwp8tNSOAgB8BQgg\/rkVR61577WVXXXWVHXvssdaoUSOrXr26bdiwwRYtWmSTJ0+2F154YYfneOyxx+yggw5K+XxbtmyxNWvW2IIFC+yZZ56xl19+Oe8W\/fr1swsvvDDjevVMEyZMsKlTp2Z8TrEUJISIbilCiGgjSiCAAAK+BQgh\/Am7EKKORkJ86u8iOdS8etNJtmxDf6Zj5GDIqQiUmgAhRKm1aIbP07FjR7vxxhtt1113TXqGwoTXX3\/dbrnlFtu0aVNFmagQIlyZ6vjggw9syJAhtnz58gzvLLoYIcQ2I0KI6P5CCBFtRAkEEEDAtwAhhD9hQgh\/ttSMAAJ+BAgh\/LjGutaWLVvamDFjrHnz5rZ+\/Xo3WkHhwtKlS61Tp0526aWXWosWLWzjxo323\/\/933bfffftEEIsWbLEjS5YsWLFds+65557Wps2baxt27bWsGFD92ezZ8+2AQMG5C2ICEIIjXB4+umnXdCR7ti8ebPNmzcvb9ePU+MSQkS3BiFEtBElEEAAAd8ChBD+hF0IUXuw1ake05EQmzvZso2MhPDXA6gZgeITIIQovjbL+Y6vvPJK69GjhxvhoPBB\/4SPAw880G677TYXUnz99dfWv39\/W7x4sSsSjIT49ttv7frrr7f58+cnvR+FGCNGjLBWrVqZQgBNzbjnnntyvndVEA4hSvPzsz8AACAASURBVHWaRaZQhBDRUoQQ0UaUQAABBHwLEEL4EyaE8GdLzQgg4EeAEMKPa6xrfeCBB+zII4\/cIWAI3\/RNN91kZ5xxhq1atcpNyXj33XezCiFUWB\/II0eOdFM+vv\/+exdazJ07N2cbQohthIQQ0d2JECLaiBIIIICAbwFCCH\/CCiGa1Ir3SIgfNzESwl8PoGYEik+AEKL42iynO959993dVAyNVFAgoFERyY7gQz+XEEL1BmGGpn1MmjTJnnzyyZzuXyfnI4SoWbOmde\/e3QUtWqCzdu3a7r40xUOLamoRy2QLc6qMyvfs2dPat29fsaDn6tWrbc6cOTZ+\/Hg39SPxSHaOTDRV5fHHH68IebLFIYSIFiOEiDaiBAIIIOBbgBDCn7ALIWreYnWqxXQ6xpZO9uPmq1mY0l8XoGYEik6AEKLomqwwN3zHHXdYhw4dbNmyZXbzzTfbRx995C6c6XSM4C67du3q1oOoV6+evfTSS26KRq5HriHELrvsYmPHjrVDDjnEqlWrlvR2tB7Gc889Z+PGjdvuz6MW9JTXnXfeaTNnzqw47\/jjj3eLgDZp0iTptRRGKJxRSJPtQQgRLUYIEW1ECQQQQMC3ACGEP2FCCH+21IwAAn4ECCH8uBZ1rSeccIINHjzY9LH+8ccfW9++fSt2yMg2hDj44INt9OjR7gNcv\/r36tUrZ5tcQ4hhw4ZZly5d3DPp\/3E\/8sgjblSInveCCy6ws88+2y2qmTiFJLxWRnhBz5UrV7o1NjSyQud99dVXdt1117mtTsOLgGqUxf\/8z\/\/YE088Yd988812i4BqW1ONopg2bVpWPoQQ0VyEENFGlEAAAQR8CxBC+BN2IUSNIVY3xiMhftjSj5EQ\/roANSNQdAKEEEXXZH5vWB\/id911lxsloKkYmroxffr0iotmG0LoI1yjDpo1a2aff\/65m8aQ65HNFp2JC2gqSND97LHHHjZr1iw3SiO8BanuLVi4c+3atXb77bfbjBkz3C1rTQsFFBoloXU1nnrqqe0eRc+mfzTVQ1MsNLIhOEfXSDayIhxsJAY+mTgRQkQrEUJEG1ECAQQQ8C1ACOFPmBDCny01I4CAHwFCCD+uRVlreJpCqo\/mYg8hfvWrX9lvf\/tbN2JBz6JRCYnHueee60Z\/6Ah231CwoFChdevWbkeQq666aoftSbXug3YA2W233VxwMXHiRLv\/\/vvdaIhU5+gaClU0AkOhj0Zp6H9MZHoQQkRLEUJEG1ECAQQQ8C1ACOFP2IUQ1WI8EmJrJ\/thKyMh\/PUAakag+AQIIYqvzbzcsT6gb731VjcCQgGE1jTQ+g2JowTiFEJoesPTTz9tH3zwQUqTdevW2T\/\/+c8dniN8gkKC\/fbbz4455hg7\/PDD3aKdderUcYtUBiHE\/vvv70ZQyEk2Wicj6tAOJBpJod1BXnvtNRs4cGDSU4J1M2rUqOGmhiQLRlJdixAiqhXMCCGijSiBAAII+BYghPAnrBBiTxtide2f\/i6SQ82r7D\/sByOEyIGQUxEoOQFCiJJr0uwf6LDDDrNBgwa5X+w11eDll192iysmBhCqOdsQ4thjj3XbdDZq1MgtbplqN45s7jrXNSE0qkFrOOjjX2tVBDtjJN5DOIRo27atew6NoJgyZYrdd999kbccPiey8P8VyLTuoL4ghJg2ZZEtXbKh4jKff7LKfgj990yvX4rlCCFKsVV5JgQQiLvAunU\/t02b9qq4zXVrf25ffPFzN62RI78ChBD59aQ2BBDwL0AI4d841lfQ9IRrrrnG\/Vqvj+4\/\/OEPbhpBqiPbECKY2qAP\/TjsjqEAYtSoUW57Te2MsXXrVtOikFqEcvHixW7dii1btthFF13kCIKREHEPIcIBhO5bocRb\/\/NjrPteoW6OEKJQ0lwHAQQQ2CawfNllptEPwaFAQgs2E0Lkv5cohGi6dWisR0IsrfZbFqbMf9NTIwJFK0AIUbRNl\/uNn3POOW5kgn7d14f4o48+6raKTHdkG0JoSkfnzp23m9qQ653nMhJC4ULv3r3d6If33nvP7r77brebRfhItiZEeJePTKdjhEeBKNzRehH5PpiOES1KCBFtRAkEEEDAtwDTMfwJE0L4s6VmBBDwI0AI4cc19rWGA4hly5a5D+TwLhipHiCbEEIfyJrCoFEW2pLy6quvdr+C5HrkEkLccccd1qFDB9Mza10HTRFJPG666SY744wztgtONJ0kWGTyiy++cItJrlixYodztWuGdrxQGW1Nqn\/23XffHbY6zdUgOJ8QIlqSECLaiBIIIICAbwFCCH\/CLoTYMszqbo3pmhDVOtrS6oyE8NcDqBmB4hMghCi+Nsv5jo844gi3CKXWQ9DHuNZ\/0K\/7mRyZhhBa3FGjIFq1auXWmZg8ebI99NBDmVwisky+QoihQ4fa+++\/v931tD6G7lsLUIbXhFChqC06O3bsaAowFFgEU090jVNOOcXV9eCDD+6wrWdQ72mnneZGo2hhymeffTbSgBAiYyIWpsycipIIIICANwFCCG+0bletvTb\/LtYhxPc1+jIdw18XoGYEik6AEKLomiz3Gx43bpz7fwTr1693H7yzZs1KWenmzZtt3rx5tnz5clcmCCGWLFni1ktIHA2gXSQ0DUE7QzRo0MCtufDuu+\/aDTfckHaHimyeKpcQQtNPtCildqLQaIV7773XBRFNmza1888\/37p06WLaqlRHYgihEQ633XabNW\/e3AUGf\/nLX1xooHKnnnqq9ezZ0xo3buyCHa078eabb7pREcE58tainzLU+hP6s169elm7du3c9BA569kC60xMGAkRrcRIiGgjSiCAAAK+BQgh\/AkTQvizpWYEEPAjQAjhxzW2tSp8GD58uO20004Z3WPih3gQQmRyshZ4fOedd9yoi2w+rKPqziWE0AgHTZFQAJDs0PNqisYBBxzgwgiN4Agv1KnRDjfeeKObYpLsUDihEQ9Tp06t+OOoc1Rw4cKFpqkiWqcim4MQIlqLECLaiBIIIICAbwFCCH\/CLoTY+DurF9PpGD9V72jf12QkhL8eQM0IFJ8AIUTxtVlOdxzerSKTirINITT1YvXq1W6UgT7E33jjjUwuk1WZXEIIXUhBRJ8+fUw7XmhRTu2SoXueO3euPf744\/bZZ5+5LTg1leTjjz+2vn37bjeKI9X5c+bMsfHjx7sRDYmHztFICe3Koeka1atXd9NUFM787W9\/cyMqKhPUEEJEdx1CiGgjSiCAAAK+BQgh\/AkTQvizpWYEEPAjQAjhx5VaESiIACFENDMhRLQRJRBAAAHfAoQQ\/oQrQogts\/1dJIeaf6qhkRB9WBMiB0NORaDUBAghSq1FeZ6yEiCEiG5uQohoI0oggAACvgUIIfwJK4Rotn641YttCHGiLalNCOGvB1AzAsUnQAhRfG3GHSNQIUAIEd0ZCCGijSiBAAII+BYghPAnTAjhz5aaEUDAjwAhhB9XakWgIAKEENHMhBDRRpRAAAEEfAsQQvgTVgjRfN0Iq7c5ntMxVtY80ZbUuYrpGP66ADUjUHQChBBF12TFfcNaDHLkyJFuQchsj8RFMrM9vxTLE0JEtyohRLQRJRBAAAHfAoQQ\/oQJIfzZUjMCCPgRIITw40qtKQRat27tdpuoX79+1kbaTeLpp5+2mTNnZn1uqZ5ACBHdsoQQ0UaUQAABBHwLEEL4E3YhxNqYj4Soy0gIfz2AmhEoPgFCiOJrM+4YgQoBQojozkAIEW1ECQQQQMC3ACGEP2EXQqy+Nb7TMWqdaEvqXcl0DH9dgJoRKDoBQoiiazJuGIFtAoQQ0b2BECLaiBIIIICAbwFCCH\/ChBD+bKkZAQT8CBBC+HGlVgQKIkAIEc1MCBFtRAkEEEDAtwAhhD9hhRB7ayTEpjn+LpJDzStrd7DvGAmRgyCnIlB6AoQQpdemPFEZCRBCRDc2IUS0ESUQQAAB3wKEEP6ECSH82VIzAgj4ESCE8ONKrQgURIAQIpqZECLaiBIIIICAbwFCCH\/CLoT4aWS8R0I0uII1Ifx1AWpGoOgECCGKrsm4YQS2CRBCRPcGQohoI0oggAACvgUIIfwJuxBi5aj4hhB12tt3hBD+OgA1I1CEAoQQRdho3DICgQAhRHRfIISINqIEAggg4FuAEMKfMCGEP1tqRgABPwKEEH5cqRWBgggQQkQzE0JEG1ECAQQQ8C1ACOFP2IUQK263ehtjujClRkLs1JvpGP66ADUjUHQChBBF12TcMALbBAghonsDIUS0ESUQQAAB3wKEEP6ECSH82VIzAgj4ESCE8ONKrQgURIAQIpqZECLaiBIIIICAbwFCCH\/CLoRYrpEQn\/m7SA41r6x7AiMhcvDjVARKUYAQohRblWcqGwFCiOimJoSINqIEAggg4FuAEMKfsAshlo22ehtiGkLUO8G+2\/k3TMfw1wWoGYGiEyCEKLom44YR2CZACBHdGwghoo0ogQACCPgWIITwJ0wI4c+WmhFAwI8AIYQfV2pFoCAChBDRzIQQ0UaUQAABBHwLEEL4E3YhxI93xHskRKNejITw1wWoGYGiEyCEKLom44YR2CZACBHdGwghoo0ogQACCPgWIITwJ0wI4c+WmhFAwI8AIYQfV2pFoCAChBDRzIQQ0UaUQAABBHwLEEL4E3YhxA8aCfG5v4vkUPPKesfbd7swEiIHQk5FoOQECCFKrkl5oHISIISIbm1CiGgjSiCAAAK+BQgh\/Am7EGLpnVZvfUxDiPrH23e7XsZ0DH9dgJoRKDoBQoiiazJuGIFtAoQQ0b2BECLaiBIIIICAbwFCCH\/ChBD+bKkZAQT8CBBC+HGlVgQKIkAIEc1MCBFtRAkEEEDAtwAhhD9hF0J8PybGIyF+ad\/txkgIfz2AmhEoPgFCiOJrM+4YgQoBQojozkAIEW1ECQQQQMC3ACGEP2FCCH+21IwAAn4ECCH8uFIrAgURIISIZiaEiDaiBAIIIOBbgBDCn7BCiGZLxsZ2JMRPDX5pS3a7lDUh\/HUBakag6AQIIYquybhhBLYJEEJE9wZCiGgjSiCAAAK+BQgh\/AkTQvizpWYEEPAjQAjhx5VaESiIACFENDMhRLQRJRBAAAHfAoQQ\/oQVQuz1XbxHQny\/OyMh\/PUAakag+AQIIYqvzbhjBCoECCGiOwMhRLQRJRBAAAHfAoQQ\/oQVQjT9bqzVXRfPLTpXNfylLSWE8NcBqBmBIhQghCjCRuOWEQgEghBi7326Wc2ai4BJInDyYf8fLikECGjoGgggUCgBQgh\/0oQQ\/mypGQEE\/AgQQvhxpVYECiJACBHNTAiR2ogQIrr\/UAIBBPIjQAiRH8dktSiEaPLdmNiOhFjd8Jf2w+5s0emvB1AzAsUnQAhRfG3GHSNQIUAIEd0ZCCEIIaJ7CSUQQMC3ACGEP2FCCH+21IwAAn4ECCH8uFIrAgURIISIZiaEIISI7iWUQAAB3wKEEP6EFULs8d0dViema0Ksbni8Ldu9F1t0+usC1IxA0QkQQhRdk3HDCGwTIISI7g2EEIQQ0b2EEggg4FuAEMKfsEKI3b8bbXXWfebvIjnUvKbhCbZ8998QQuRgyKkIlJoAIUSptSjPU1YChBDRzU0IQQgR3UsogQACvgUIIfwJE0L4s6VmBBDwI0AI4ceVWhEoiAAhRDQzIQQhRHQvoQQCCPgWIITwJ6wQYrfvbrfa6+b4u0gONa9t2N5W7N6bkRA5GHIqAqUmQAhRai3K85SVACFEdHMTQhBCRPcSSiCAgG8BQgh\/woQQ\/mypGQEE\/AgQQvhxpVYECiJACBHNTAhBCBHdSyiBAAK+BQgh\/AkrhNjlu1GxHQmxrmF7W7n7FYyE8NcFqBmBohMghCi6JuOGEdgmQAgR3RsIIQghonsJJRBAwLcAIYQ\/YYUQO393q9VaN9vfRXKoeX3DE23V7lcSQuRgyKkIlJoAIUSptSjPU1YChBDRzU0IQQgR3UsogQACvgUIIfwJE0L4s6VmBBDwI0AI4ceVWhEoiAAhRDQzIQQhRHQvoQQCCPgWIITwJ6wQYqfvhlvNmI6E2NDwRFu9ex9GQvjrAtSMQNEJEEIUXZNxwwhsEyCEiO4NhBCEENG9hBIIIOBbgBDCnzAhhD9bakYAAT8ChBB+XKkVgYIIEEJEMxNCEEJE9xJKIICAbwFCCH\/CCiEafPc7q7n+n\/4ukkPNGxp0tLW792UkRA6GnIpAqQkQQpRai\/I8ZSVACBHd3IQQhBDRvYQSCCDgW4AQwp+wQoj63w2zGjENITY26Gjrdv8tIYS\/LkDNCBSdACFE0TUZN4zANgFCiOjeQAhBCBHdSyiBAAK+BQgh\/AkTQvizpWYEEPAjQAjhx5VaESiIACFENDMhBCFEdC+hBAII+BYghPAnrBCizpIhsR0JsanBf9iG3foxEsJfF6BmBIpOgBCi6JqMG0ZgmwAhRHRvIIQghIjuJZRAAAHfAoQQ\/oQJIfzZUjMCCPgRIITw40qtCBREgBAimpkQghAiupdQAgEEfAsQQvgTVghRe8kQq77+U38XyaHmzQ062UZGQuQgyKkIlJ4AIUTptSlPVEYChBDRjU0IQQgR3UsogQACvgUIIfwJK4SoueQWqxbTEGJLg062ebermY7hrwtQMwJFJ0AIUXRNxg0jsE2AECK6NxBCEEJE9xJKIICAbwFCCH\/ChBD+bKkZAQT8CBBC+HGlVgQKIkAIEc1MCEEIEd1LKIEAAr4FCCH8CSuEqPb94NiOhNhav5Nt3a0\/IyH8dQFqRqDoBAghiq7JuGEEtgkQQkT3BkIIQojoXkIJBBDwLUAI4U+YEMKfLTUjgIAfAUIIP67UikBBBAghopkJIQghonsJJRBAwLcAIYQ\/YYUQtnSwWUzXhLD6ncx2ZSSEvx5AzQgUnwAhRPG1WaXv+LTTTrNzzz3X9ttvP6tdu7Zt2bLFVq5cae+\/\/75NnDjRFi1atF3dbdu2tZEjR1rDhg1TXnPDhg22atUq++STT+zhhx+2efPmVfr+Up342GOP2UEHHWTffvutXX\/99TZ\/\/vy017jjjjusQ4cO7r5uueUWe\/fdd\/N+T\/msMHi+1157zQYOHJhV1YQQ0VyEEIQQ0b2EEggg4FuAEMKfsEKILUsH2daYhhDV6p9k1Qkh\/HUAakagCAUIIYqw0bK95Zo1a7owoX379la9evWkpy9btszuvPNOmzlzZsWfZxJChCtbv369TZ061QUa+TwIIVJrEkJE9zRCCEKI6F5CCQQQ8C1ACOFPmBDCny01I4CAHwFCCD+usaq1X79+1r17d1MYsWDBAvv9739vM2bMsMaNG9ull15qp5xyihsZsXDhQrvhhhsqRhqEQ4hZs2bZlClTdniuQw891Nq0aWMHH3ywq2Pjxo323HPP2bhx4\/JmQAhBCJFLZyKEIITIpf9wLgII5EeAECI\/jslqUQixUSMhNnzq7yI51Fy9\/klWcxemY+RAyKkIlJwAIUTJNen2D7TXXnvZvffea3vvvbebKqFAYvny5dsVuu666+zMM890oyQef\/xxmzRpkvvzcAgRNVWga9euru5GjRq5+keNGmVvvPFGXnQJIQghculIhBCEELn0H85FAIH8CBBC5MeREMKfIzUjgEDhBAghCmddJVdSODBgwAA3SiEcMIRvRqMYRo8ebU2aNLFw2JBNCKH6Lr\/8cuvRo4fVqlXLlMor3MjHQQhBCJFLPyKEIITIpf9wLgII5EeAECI\/jqlCiPVLB9mWmI6EqFH\/JKvNSAh\/HYCaEShCAUKIImy0bG754osvtgsvvNBNxbj77rvtxRdf3OH0li1b2tixY61Zs2Y5hRAaBXH\/\/feb6vv+++\/dIpJz587N5naTls13CHHAAQdY79697YgjjrCdd97ZjQDRIp0rVqxwi3TqGcKLdIZ9NCXlww8\/tJ49e5rqUbijxTlVfvLkyfbCCy8kfQatxxE+R+tnaDHP8ePHu8UztfBm1GiTZBWzJkR09yKEIISI7iWUQAAB3wKEEP6E9cPPuh8G2eaYhhA1651kdQgh\/HUAakagCAUIIYqw0fJ9y8cdd5wNHz7cdtppJ3vppZdsxIgR7hLZjoTQOUOHDrVTTz3V1q5da3fddVfS0CPb+89nCKHdQa644gqrX79+ytvQ2hiDBg2qCFDCIcR7771nWgcj2fkKIx555BF74okntqv7ggsucNesU6fODtfUtTZt2uR2LCGEyLZnZFaeEIIQIrOeQikEEPApQAjhT5cQwp8tNSOAgB8BQgg\/rkVVa7ClpX6d14KS06ZNq3QIoZEXvXr1clMyNDIgHztl5CuE0KgB7RKy66672tKlS031KnRZs2aNHXvssS4oUMCg449\/\/KMbHaIjHELov2vrT\/35U0895UZBaISDwg2FDN98841dffXVFSMpjj\/+eBs8eLC7pnYg0TU1WkJTX6666ipr166dG02hgxDCz2tDCEEI4adnUSsCCGQjQAiRjVZ2ZRVCrP5xcGxHQtSq18nqNWJhyuxaldIIlLYAIURpt2\/k04V\/pdcOGFo\/Qr\/M66jMSAh9jPft29d9WGvqwn333Rd5D1EFghAiqlzinyss0FSHd9991\/2RpoecffbZtnr1ahszZoxNnz59u1PCi3hqxIPChMQQQoGFplAEQU1QgUZO\/Od\/\/qcLKG6\/\/Xa3+4gOjSrp3Lmzm+qhdTfCW6Dqz2+66SY7\/fTTrVq1aoQQ2TZwhuUJIQghMuwqFEMAAY8ChBD+cAkh\/NlSMwII+BEghPDjWhS1hqcmJE5BKMUQQtNDjjzySDdK4be\/\/a0LBhKPIPD4\/PPP3QiHxBBi\/vz5bgRD4rlB+KLyEyZMsKlTp9o+++zj1uFo3ry5hUON8DVTLQqaaQdiTYhoKUIIQojoXkIJBBDwLUAI4U9YIcRPP95im2K6JkTtep2sQaOrTdN\/ORBAAAEJEEKUaT+46KKL7LLLLnNrGyxZssTuvPNOe\/PNN7fTiNtICN2nPvCThQfhG9dCnG3atHGjEsIjIRKbWs\/eunVrtyjkUUcd5f5z48aN3UKVqUIIGWlEReKRLIQI+6UbFaJ1JA455BBGQnh6FwkhCCE8dS2qRQCBLAQIIbLAyrIoIUSWYBRHAIEqFyCEqPImKOwNaJcM\/ZLfrVs3N2VCowI0fUC\/1CcelQkh+vTp47bp1G4TqbYEzfaJ87UmhK6rHS00XURrPzRs2NBNg0h2pAohUq3bkCyEOOeccyqmdCRbsDK4brAmRy5rQiQ+Q+M9RlnDhn\/JlrokyxNCEEKUZMfmoRCIucDS7webgofwof\/NoWmRHPkVUAixYtkQ2xjTkRB16nWynXbux0iI\/DY7tSFQ1AKEEEXdfNndvH75HzZsmJ1wwgnu1\/4vv\/zS7YqRahvNyoQQwQd1HHfH6Nixo914441ukUgdWlRSoyUWL15sCxYssL\/\/\/e923nnnWatWrVKOhIhrCKHQoWbNRRUdombNxdv99+x6SmmVJoQghCitHs3TIFAcAps27WWbNjWtuNl1a39uc+b8mhDCQ\/MphFi2bKht2PhPD7XnXmW9uv9hO+\/8W0KI3CmpAYGSESCEKJmmTP8gu+yyi9sZQmsI6Jg9e7YNGTKkYheHZGdnG0KEF3b89ttv3bQFraGQ65GPkRCNGjVyi2QqYNB0jkmTJtnzzz9fsQhncI9Ra0JkE0KE\/f7whz\/YPffck5TigQcecGtV5DISYu99uhE6pOhohBCEELn+HcT5CCCQuwDTMXI3TFUDIYQ\/W2pGAAE\/AoQQflxjVWs4gNi6dau98cYbbgSEdnpId2QbQlx++eVuKoa25\/zrX\/9qQ4cOzYtDPkKI8LNoW07tWpF4hBeJzMd0jKZNm7qdNPbdd1\/7+OOP3TSQYOeR4Nrh7T8JIfLSXXaohBCCEMJPz6JWBBDIRoAQIhut7MoqhFi6bJitj+lIiPp1O9qujITIrlEpjUCJCxBClHgD6\/GCbSD1n19\/\/XUbPHjwDh\/DyRiyCSG6du1q\/fr1M404WLZsmVsQ8oMPPsiLbr5DiGQBidbKuPbaa+2MM86wGjVq5GU6hh5e01+6dOnipn48+OCD9tRTT21nct1119mZZ57pghtCiLx0F0KILBhf\/fS3WZSmKAIIIFB5AUKIyttFnUkIESXEnyOAQNwECCHi1iJ5vp9OnTrZoEGDrEGDBvbVV1\/Z\/fffb+vXr095FU1V+Oyzz9yfh0OIWbNmmXZ4CB\/6cNc0Au1Esf\/++7sPaX1sp1uEsTKPl48QIjxVRM+vLTT1PFoTQmtkaASHRkJorQwd+RgJoXqOOOIIu\/XWW61JkybuWn\/84x9dEFG3bl279NJL7ZRTTnELhOoghKhM74g+h5EQqY0IIaL7DyUQQCA\/AoQQ+XFMVotCiO+W\/87Wb5zt7yI51Nygbkfbfac+rAmRgyGnIlBqAoQQpdaiCc8TLBSZ6WOGP77DIUQm52t6hz7sFULk88hHCKH7ufjii61Xr14VH\/2J96gtQP\/973\/bMcccYwsXLnQjI\/TfM5kykWx3jKB+jRLRVIxgQczwdYPFMXfbbTdCiHx2mlBdhBCEEJ66FtUigEAWAoQQWWBlWVQhxKLlI2xdTEOIhnVPtD12uooQIst2pTgCpSxACFHKrWtmwQd8po+ZbQihj2iNnnjrrbfs6aefdqMt8n3kK4TQfZ122mlu1INGRmgEwsaNG+3HH3+06dOnO6uzzjrLevfu7R5h3LhxNm3atJxDCNWlrUH79+\/vRltoVIquq63K\/uu\/\/svat29vHTp0IITId8f5v\/oIIQghPHUtqkUAgSwECCGywMqyKCFElmAURwCBKhcghKjyJuAGEKi8gHY7mTBhgrE7RmpDQghCiMq\/YZyJAAL5EiCEyJfkjvUohFi44lZbu3GOv4vkUPNOdTrYnjtdyUiIHAw5FYFSEyCEKLUW5XnKSoAQIrq5CSEIIaJ7CSUQQMC3VDYAdwAAIABJREFUACGEP2FCCH+21IwAAn4ECCH8uFIrAgURIISIZiaEIISI7iWUQAAB3wKEEP6EFUL8e+UoWxPTkRCN6rS3pg2vYCSEvy5AzQgUnQAhRNE1GTeMwDYBQojo3kAIQQgR3UsogQACvgUIIfwJK4T4auXttjqmIcQuddpb84a9CSH8dQFqRqDoBAghiq7JiuuGs92dI\/x04UUyi+upC3e3hBDR1oQQhBDRvYQSCCDgW4AQwp8wIYQ\/W2pGAAE\/AoQQflyp9f8E+vTp47a8rMyxYMECGzFiRGVOLZtzCCGim5oQghAiupdQAgEEfAsQQvgTVgjxr5WjbfWmz\/xdJIead61zgu3T4DeMhMjBkFMRKDUBQohSa1Gep6wECCGim5sQghAiupdQAgEEfAsQQvgTJoTwZ0vNCCDgR4AQwo8rtSJQEAFCiGhmQghCiOheQgkEEPAtQAjhT1ghxNyVd9iqTZ\/7u0gONe9e53jbr0EvRkLkYMipCJSaACFEqbUoz1NWAoQQ0c1NCEEIEd1LKIEAAr4FCCH8CSuE+OynsfZTTEOIxrV\/aS0bXEoI4a8LUDMCRSdACFF0TcYNI7BNgBAiujcQQhBCRPcSSiCAgG8BQgh\/woQQ\/mypGQEE\/AgQQvhxpVYECiJACBHNTAhBCBHdSyiBAAK+BQgh\/AkrhJj90122ctNcfxfJoeY9ah9nP2vQk5EQORhyKgKlJkAIUWotyvOUlQAhRHRzE0IQQkT3EkoggIBvAUIIf8KEEP5sqRkBBPwIEEL4caVWBAoiQAgRzUwIQQgR3UsogQACvgUIIfwJK4T4ZNXdtmLTF\/4ukkPNTWq3swPrX8xIiBwMORWBUhMghCi1FuV5ykqAECK6uQkhCCGiewklEEDAtwAhhD9hhRAfrbrXlsc0hGhau60dVL8HIYS\/LkDNCBSdACFE0TUZN4zANgFCiOjeQAhBCBHdSyiBAAK+BQgh\/AkTQvizpWYEEPAjQAjhx5VaESiIACFENDMhBCFEdC+hBAII+BYghPAnrBDig9X32bJN8\/xdJIea96rdxg6pdxEjIXIw5FQESk2AEKLUWpTnKSsBQojo5iaEIISI7iWUQAAB3wKEEP6ECSH82VIzAgj4ESCE8ONKrQgURIAQIpqZEIIQIrqXUAIBBHwLEEL4E1YI8d7qCbZs07\/8XSSHmpvV\/oUdVu8CRkLkYMipCJSaACFEqbUoz1NWAoQQ0c1NCEEIEd1LKIEAAr4FCCH8CSuEeGf1A\/bj5niGEHvXOtaOqHceIYS\/LkDNCBSdACFE0TUZN4zANgFCiOjeQAhBCBHdSyiBAAK+BQgh\/AkTQvizpWYEEPAjQAjhx5VaESiIACFENDMhBCFEdC+hBAII+BYghPAnrBDizdUP2Q+bv\/R3kRxq3qfWMfbzet0ZCZGDIaciUGoChBCl1qI8T1kJEEJENzchBCFEdC+hBAII+BYghPAnTAjhz5aaEUDAjwAhhB9XakWgIAKEENHMhBCEENG9hBIIIOBbgBDCn7BCiNdXT7Klm+f7u0gONe9b62g7pl43RkLkYMipCJSaACFEqbUoz1NWAoQQ0c1NCEEIEd1LKIEAAr4FCCH8CSuEmLnmUfs+piFEi1o\/t1\/UPZsQwl8XoGYEik6AEKLomowbRmCbACFEdG8ghCCEiO4llEAAAd8ChBD+hAkh\/NlSMwII+BEghPDjSq0IFESAECKamRCCECK6l1ACAQR8CxBC+BNWCDFjzWO2ZPNX\/i6SQ80tax1lbeueyUiIHAw5FYFSEyCEKLUW5XnKSoAQIrq5CSEIIaJ7CSUQQMC3ACGEP2FCCH+21IwAAn4ECCH8uFIrAgURIISIZiaEIISI7iWUQAAB3wKEEP6EFUL8dc3j9t3mBf4ukkPN+9c60n5Z9wxGQuRgyKkIlJoAIUSptSjPU1YChBBl1dx5f1gCGgKavHcqKkQghQAhhL+uoRDi5TWTbXFMQ4gDah1hJ9T9T0IIf12AmhEoOgFCiKJrMm4YgW0ChBD0hlwECCEIIXLpP5yLQDYChBDZaGVXlhAiOy9KI4BA1QsQQlR9G3AHCFRagBCi0nScaGaEEIQQvAgIFEqAEMKftEKIv6yZYos2f+3vIjnU3KrW4dahbldGQuRgyKkIlJoAIUSptSjPU1YChBBl1dx5f1hCCEKIvHcqKkQghQAhhL+uQQjhz5aaEUDAjwAhhB9XakWgIAKEEAVhLtmLEEIQQpRs5+bBYidACOGvSRRC\/Hnt0\/bt5n\/7u0gONR9U8zDrWPdURkLkYMipCJSaACFEqbUoz1NWAoQQZdXceX9YQghCiLx3KipEIIUAIYS\/rkEI4c+WmhFAwI8AIYQfV2pFoCAChBAFYS7ZixBCEEKUbOfmwWInQAjhr0kUQjy3dqotjOlIiNY1D7WT6p7CSAh\/XYCaESg6AUKIomsybhiBbQKEEPSGXAQIIQghcuk\/nItANgKEENloZVdWIcSza5+xhZu\/ye7EApU+uOYh1rnurwghCuTNZRAoBgFCiGJoJe4RgRQChBB0jVwECCEIIXLpP5yLQDYChBDZaGVXlhAiOy9KI4BA1QsQQlR9G3AHCFRagBCi0nScyBadafvAq5\/+lj6CAAJ5FCCEyCNmQlUKIaau\/aN9s3mhv4vkUPOhNQ+2LnVPZiREDoacikCpCRBClFqL8jxlJUAIUVbNnfeHZSREalJCiLx3NyoscwFCCH8dgBDCny01I4CAHwFCCD+u1IpAQQQIIQrCXLIXIYQghCjZzs2DxU6AEMJfkyiEeHrtc\/bvzd\/6u0gONR9Ws7WdWrcTIyFyMORUBEpNgBCi1FqU5ykrAUKIsmruvD8sIQQhRN47FRUikEKAEMJf11AIMWXtn+3rmIYQh9c8yLrW7UgI4a8LUDMCRSdACFF0TcYNI7BNgBCC3pCLACEEIUQu\/YdzEchGgBAiG63syhJCZOdFaQQQqHoBQoiqbwPuAIFKCxBCVJqOE1mYMm0fYE0IXhEE8itACJFfz3BtCiEmr33BFmxe5O8iOdR8RM0D7T\/rnshIiBwMORWBUhMghCi1FuV5ykqAEKKsmjvvD8tIiNSkhBB5725UWOYChBD+OgAhhD9bakYAAT8ChBB+XKkVgYIIEEIUhLlkL0IIQQhRsp2bB4udACGEvyZRCPH4mr\/YV5sX+7tIDjUfVauVnVG3PSMhcjDkVARKTYAQotRalOcpKwFCiLJq7rw\/LCEEIUTeOxUVIpBCgBDCX9dQCPHomldiG0L8vNYBdlbd4wkh\/HUBakag6AQIIYquybhhBLYJEELQG3IRIIQghMil\/3AuAtkIEEJko5VdWUKI7LwojQACVS9ACFH1bcAdIFBpAUKIStNxIgtTpu0DrAnBK4JAfgUIIfLrGa5NIcTDa6bb\/M3f+btIDjUfXetndk7dXzISIgdDTkWg1AQIIUqtRXmeshIghCir5s77wzISIjUpIUTeuxsVlrkAIYS\/DkAI4c+WmhFAwI8AIYQfV2pFoCAChBAFYS7ZixBCEEKUbOfmwWInQAjhr0kUQjy05lX7cvMSfxfJoeZjau1v3eu2YyREDoacikCpCRBClFqL8jxlJUAIUVbNnfeHJYQghMh7p6JCBFIIEEL46xoKIR5YM8P+FdMQ4thaLe28um0JIfx1AWpGoOgECCGKrsm4YQS2CRBC0BtyESCEIITIpf9wLgLZCBBCZKOVXVlCiOy8KI0AAlUvQAhR9W1QqTs47bTT7Nxzz7X99tvPateubVu2bLGVK1fa+++\/bxMnTrRFixZtV2\/btm1t5MiR1rBhw5TX27Bhg61atco++eQTe\/jhh23evHmVurdsTjrhhBPcc7Rq1cp23nlnq169esWzfPHFF\/bkk0\/au+++m7TKli1b2tixY61Zs2b22muv2cCBAzO+dL9+\/ezCCy90z3vLLbekvEbGFVZRQUKIKoIvkcsSQhBClEhX5jGKQIAQwl8jKYSYsHqm\/Wvz9\/4ukkPNv6jVwi6o9wtGQuRgyKkIlJoAIUSRtWjNmjVdmNC+fXv3wZ7sWLZsmd155502c+bMij\/OJIQI17V+\/XqbOnWqCzR8HC1atLCbbrrJDj\/88JTPoesqXPnHP\/5ho0aN2iFYKYUQon79+vab3\/zG5HHddddlTU0IkTUZJ4QECCEIIXghECiUACGEP2lCCH+21IwAAn4ECCH8uHqrVb\/gd+\/e3RRGLFiwwH7\/+9\/bjBkzrHHjxnbppZfaKaec4kZGLFy40G644QabP3++u5dwCDFr1iybMmXKDvd46KGHWps2bezggw92dWzcuNGee+45GzduXF6f58ADD7TbbrvNmv\/\/7b0HmBVVtrC9wCY3UUGS8ZLEEQdFggEZ5xq4OsCoo1dBQFFEEBF1MGC4AhJUVGTENH6\/GcPoVQaV0aufY\/oGUFQUlHAJkhxwJEimwf9ZG09T3Zzurjp1dp1ddd56nvs8M9O7dnjX6qv19tp7N2smP\/\/8s6xevVqmT58uM2bMkO+\/\/14aN25s1qHVHlrlUKlSJVm5cqWMHDlSFi5cWDyXJEiIcePGSbdu3WTBggXSv3\/\/wJyREIGR8QISwlcOcDuGL0w0goBvAkgI36gCN1QJMXnLB7LY0UqIjlUOk941OlAJETiyvACB5BJAQsQotk2aNJEHH3xQmjdvbrZKqJDYsGFDiRXoX9N79eplqgueeuopefzxx\/eTEBVtXTj77LNN33Xr1jX9axXCRx99lBVS9erVk4kTJ0rbtm1Ft39MmzZNJk2aJEVFRfv1r6JlxIgRRkhUqVJF5s2bJ9dff71s3LjRtA0jIbKymCx0MmHCBOnatSsSIgss6SI4ASohymaGhAieT7wBgfIIICHs5YdKiElbPpJFu3+wN0iInjtVOVQuqXEcEiIEQ16FQNIIICFiFFGVA\/oRrlUKXsHgXYJWMYwfP14aNWpU4pwEbyVERRJC+xs4cKD06dPHfPzrP9wy2SqQDm2qXxUMKiB0ruU92k4liH6oa2XGs88+K4899hgS4hdoVELE6BfYwakiIZAQDqYlU0ooASSEvcAiIeyxpWcIQMAOASSEHa5Weu3bt685TFE\/zO+\/\/35544039hunrOqAoBJCqyAefvhhU22wbt06ueGGG0pshchkgdrn5MmTzSGUQfrs0KGDjBo1SurXry96WKVWaWg1ROm16pYOlRx6WKfKky1btshnn31mqkFKH7JZ0cGULVq0kCuuuELat29vDvPULSHl9ZfiobHR7TI9e\/YUrVxRYaQVH3pQqAoUnaM+ehjnkCFDzM+9T9CDMpEQmWQi76QIICGQEPw2QCAqAkgIe6RVQty\/5WNZWPQve4OE6LlL1UOkb432VEKEYMirEEgaASREwiLapUsXufPOO6V27dry1ltvmY93fYJKCH3n9ttvl+7du8u2bdvMFop00iMIvtNOO01uvvlm81HvpxrD27duQznhhBPkp59+kjvuuMNUZ3glhJ6PoWdJVKtWbb8ppTuoszwJcd5558mgQYPKvElEBYjKlNI8dKuJ3tahW01UWpR+vGdsICGCZA5tbRFAQiAhbOUW\/UKgNAEkhL2cQELYY0vPEICAHQJICDtcc9Zr6owBvd1CD5TULQ+ZSgitvBgwYICpKtC\/4oe9KSNMfylpoFUFTzzxhDz99NMlJISuUdesh1s+8sgjZs0qElSiaLXBsmXLzJaS1NWlZUmIk046yRyAqVUXWpWgouHJJ5801Qzalx4eqYeAqtjQqz3nzJljxkptG9FbS\/SwzdQ1p3plqsoXrarQGzC2bt1qzsBIxYUzIXL2q8LAIoKEQELwiwCBqAggIeyRVgkxccv\/c7gSorn0r\/FrKiHspQA9QyB2BJAQsQtZ2RO+6KKL5MorrzTVAHoDhp4fkTrwMZNKCO9f6\/U2Df3rf5jHKxIeeughcwWo3yfdXLyVECoJVD5MnTq1RJfegzpVpKQERVkSQsWNVpOo0Hj00Uf3609vstDDMlVSvPPOO6ZaRB8VDbfccovUqlXLVHmoyPAettmuXTsZPXq0Oavjyy+\/NIJEHySE3wygnQ0CSAgkhI28ok8IpCOAhLCXFyoh7tkyUxYU\/WhvkBA9n1i1mVxWox0SIgRDXoVA0gggIRISUf1IVwFRs2ZNcz2nfhB7r7NMuoT49ttvTbVB6Vs2vDeKeD\/+00kI76Ges2fPlmuuuSZtdqTEgV4tqmdl6DWo2p9KID03Qq\/d1GtTSz+6Nebkk0+W7777Tm666SZzHSkSIiG\/gDFdBhICCRHT1GXaMSSAhLAXNCSEPbb0DAEI2CGAhLDDNdJee\/fuLZdddpkREGvXrpW7775bPv744xJzSLqEeP3118u8aUPPadBtFipnhg8fLitWrDDSQA\/59B4Embp9pEaNGlJe5YfKjn79+pmzMlLCId0YfpIACeGHEm1sEUBCICFs5Rb9QqA0ASSEvZxQCTFh82xnKyFOqtpMBtT8FZUQ9lKAniEQOwJIiNiFbN+E9RyCq666Ss4\/\/3xz7oGed6AfxfpX\/NJPJhJi8ODB5prOPXv2lHklaBB8qY93faesK0bL6i81Fz3cMd2ZEOVJg7IqF0pLiLIOiyxrTroFJLWtRM+NaN26tSxYsMCcG+H3yZaEqF798xJD1qv\/hJT+3\/zOiXb5QwAJgYTIn2xnpVET2LD+Mtm+\/bjiYYuKGsuKFSLnnntu1FNJ\/HhIiMSHmAVCIHEEkBAxDalWPegtEVreX7lyZVmyZIm5FcO7BcO7tEwkROoDOQ63Y+S7hCgsfLNEJhfWfhMJEdPf7SinjYRAQkSZb4yVXwS08mH7tvYeCdFEli5tjISwkAYqIcZv\/lS+LVpvoffwXZ5ctalcXvNoKiHCo6QHCCSGABIihqHUqyDHjBkjxx239y8M8+fPl9tuu6345od0SwoqIbxnKXjPPgiDq27duuZwy5YtW8q6devMeQplSRPvOLpOXa8eBrlo0SKzlUKvyfQeTFnedozU9Z56FsOwYcPMWQzptmPo1ZypcyAefvhheeGFF3wvNzWGd8uHn5ezVQnR\/JDzpaBgjZ8haQOBYgJICCQEvw4QiIoA2zHskVYJMe6nOQ5LiCZyRa22SAh7KUDPEIgdASREzELmFRB6FeRHH31kKiD06sfynqASYuDAgWYrhl7P6b0FIiyuVL+6leTDDz\/c7xaJ0v17r77UQyf1hovHHnvMNPNKCO+hk94+vDLFe9hkOglx7LHHmu0spW++8LNmPWiyZ8+e5mDKsWPHpj2YUrejKFMVKPfcc49ZPxLCD13a2CKAhEBC2Mot+oVAaQJICHs5gYSwx5aeIQABOwSQEHa4WutVP3Z79Ohh+vfzEZ+aSBAJoQc06ke6Vi6sX79ebr31VpkzZ05W1qR9Tpw4UY4++mjR8x1mzJhhDtIsfauFDqYCQq\/DPOuss4wM0YoPvXZ0w4YN+0kIlTCTJk2SadOmlZinVlv06tXL9P\/444\/Lc889Z35e1hWdU6ZMkfbt25t167zef\/\/9Ev2lpEjnzp1NG5UI+g\/\/iq7oVHl0\/\/33S5s2bcztGKmKjJSE0Bs29HwPFRRBHq0S0XMpqIQIQo22KQJICCQEvw0QiIoAEsIeaf33kLE\/fSHfFO399yPXnlOqNpaBtdpQCeFaYJgPBHJIAAmRQ\/hBh\/Z+6C5btkx0y8COHTvK7EY\/aPXqSn28EmLWrFnm9gfvox\/XWgnQsWNHOfLII81Hvx68mDoEMuhcy2vfqlUrueuuu6R58+ai1Ry63WP69OlGSOhWicaNGxvxcM4550jTpk2lUqVKsnLlSlM14d2+4a2E0PH0pouXX37ZVEs0atTI3Bhy6qmnmkM7582bZwRG6iO\/LAnRrVs3Iz60GkJlh0qNqVOnmv\/coUMHufzyy+WYY44x53AoR+1TBYe3YkPXpNJGpcfcuXPNe3p9qooXbatz1G0p+mjlhY6pQkMrWmbOnBkINRIiEC4alyKAhEBC8EsBgagIICHskUZC2GNLzxCAgB0CSAg7XK30mvqrud\/OvTc1eCWEn\/e1skBFhUoIG49uk1CpoFUH+kFf1qM3c3z++edGWujtH97HKyE+\/fRTIweqVau2X1fpDu0sS0Loy3pLhkoDPfwz3aOSQdmqNFAZlHq02kGv6mzbtq0RJ6UfXYtWr2hlSaryQ0WJ3qah0kcfFT96vsQrr7ziCzsSwhcmGpVBAAlRdmr8z9dXkzcQgEAWCSAhsgizVFcqIe7a9KV8UxSsmtLejEr2fEq1g+XKWq2phIgKOONAIAYEkBAxCFJqiqlrIP1OOaiE0A9grRT45JNPzKGM3g9sv2MGbadypHfv3uawyjp16hghods0tKrhq6++kldffbXM6gCvhFBholsa+vXrV1w9odUL7777rqkYKX1mRnkSQtfQokUL0TMcVJIUFhYaqaB81q5dayo2tDoi3TkcWhGh5z7oFpAGDRoUV5SoQNEKDa348D7aXg8V1YoNFSi7d+8OdH0pEiJoxtHeSwAJgYTgNwICURFAQtgjjYSwx5aeIQABOwSQEHa40qvjBCqSEI5Pv3h6SIi4RMrNeSIhkBBuZiazSiIBJIS9qKqEGL3pK2crIbpWaySDarWiEsJeCtAzBGJHAAkRu5Ax4WwQSEkIrfzQ7RG6nSOODxIijlFzZ85ICCSEO9nITJJOAAlhL8J7JcTXMn\/XJnuDhOj5VJUQhS2QECEY8ioEkkYACZG0iLKeMgno1gc9i0LPY9ADIVu3bi2rVq2S4cOHy4oVK2JJDgkRy7A5M2kkBBLCmWRkIokngISwF2IkhD229AwBCNghgISww5VeHSRw1FFHyfjx483NGfroAZN\/+9vfzAGTcX2QEHGNnBvzRkIgIdzIRGaRDwSQEPairBJi1Mb5DldCNJSrav8blRD2UoCeIRA7AkiI2IUsdxMOejuHd6beQzJztQK98nPYsGHmoEk9ZFL\/oa1SQg+wjOuDhIhr5NyYNxICCeFGJjKLfCCAhLAXZSSEPbb0DAEI2CGAhLDDNZG9Dh48WI4\/\/viM1rZ8+XIZNWpURu\/yUtkEkBBkRxgCSAgkRJj84V0IBCGAhAhCK1hblRD\/tfEbmb\/rp2AvRtS6W7WDZHDtI6mEiIg3w0AgDgSQEHGIEnOEQBkEkBCkRhgCSAgkRJj84V0IBCGAhAhCK1hbIyE2LJB5rkqI6gfKkNpHICGChZXWEEg0ASREosPL4pJOAAmR9AjbXR8SAglhN8PoHQL7CCAh7GUDEsIeW3qGAATsEEBC2OFKrxCIhAASIhLMiR0ECYGESGxyszDnCCAh7IVEJcTtGxY6Wwnxm+oHytW1D6cSwl4K0DMEYkcACRG7kDFhCOwjgIQgG8IQQEIgIcLkD+9CIAgBJEQQWsHaIiGC8aI1BCCQewJIiNzHgBlAIGMCSIiM0fGiiCAhkBD8IkAgKgJICHukVULctn6RzNu12d4gIXr+TfUGMrTOYVRChGDIqxBIGgEkRNIiynryigASIq\/CnfXFIiGQEFlPKjqEQBkEkBD2UkMlxK3r\/1e+dlRCnFa9gVxT5xAkhL0UoGcIxI4AEiJ2IWPCENhHAAlBNoQhgIRAQoTJH96FQBACSIggtIK1RUIE40VrCEAg9wSQELmPATOAQMYEkBAZo+NFtmOUmwP\/8\/XV5AgEIJBFAkiILMIs1ZVKiFvWL5Gvd26xN0iInn9bo74Mq9OcSogQDHkVAkkjgIRIWkRZT14RQELkVbizvlgqIcpGioTIerrRYZ4TQELYSwAkhD229AwBCNghgISww5VeIRAJASREJJgTOwgSAgmR2ORmYc4RQELYC4lKiJvXL5OvnK2EqCfD6zSjEsJeCtAzBGJHAAkRu5AxYQjsI4CEIBvCEEBCICHC5A\/vQiAIASREEFrB2qqEuPFHlRBbg70YUet\/r1FPrqvbFAkREW+GgUAcCCAh4hAl5giBMgggIUiNMASQEEiIMPnDuxAIQgAJEYRWsLZIiGC8aA0BCOSeABIi9zFgBhDImAASImN0vMjBlOXmAGdC8CsCgewSQEJkl6e3N5UQf\/zxO5nraCXE6TXqyg11m1AJYS8F6BkCsSOAhIhdyJgwBPYRQEKQDWEIUAlRNj0kRJjM4l0I7E8ACWEvK5AQ9tjSMwQgYIcAEsIOV3qFQCQEkBCRYE7sIEgIJERik5uFOUcACWEvJCohrv\/XCvly5zZ7g4To+YwadWREvcZUQoRgyKsQSBoBJETSIsp68ooAEiKvwp31xSIhkBBZTyo6hEAZBJAQ9lJDJcTwf62SLxyVEGfVqC031jsYCWEvBegZArEjgISIXciYMAT2EUBCkA1hCCAhkBBh8od3IRCEABIiCK1gbZEQwXjRGgIQyD0BJETuY8AMIJAxASRExuh4kYMpy80BzoTgVwQC2SWAhMguT29vKiGu+WG1s5UQ3WvWlpvrNaISwl4K0DMEYkcACRG7kDFhCOwjgIQgG8IQoBKibHpIiDCZxbsQ2J8AEsJeViAh7LGlZwhAwA4BJIQdrvQKgUgIICEiwZzYQZAQSIjEJjcLc44AEsJeSFRCXP3DGvl8x3Z7g4To+T9qFsrI+g2phAjBkFchkDQCSIikRZT15BUBJERehTvri0VCICGynlR0CIEyCCAh7KWGSoirfvinzHFUQpxds1Bur38gEsJeCtAzBGJHAAkRu5AxYQjsI4CEIBvCEEBCICHC5A\/vQiAIASREEFrB2iIhgvGiNQQgkHsCSIjcx4AZQCBjAkiIjNHxIgdTlpsDnAnBrwgEsksACZFdnt7eVEJcuW6tfLZjh71BQvR8Ts1a8l8NGlAJEYIhr0IgaQSQEEmLKOvJKwJIiLwKN4uNkABVIuXDRtJEmIwJGQoJYS+QSAh7bOkZAhCwQwAJYYcrvUIgEgJIiEgwM0geEkBCICHyMO2tLhkJYQ+vSohQlpsjAAAgAElEQVTL162TTx2thOhRs6aMohLCXgLQMwRiSAAJEcOgMWUIpAggIcgFCNghgIRAQtjJrPztFQlhL\/YqIS5b+4PM3rHT3iAheu5Zq6aMaVCP7RghGPIqBJJGAAmRtIiynrwigITIq3Cz2AgJICGQEBGmW14MhYSwF2YkhD229AwBCNghgISww5VeIRAJASREJJgZJA8JICGQEHmY9laXjISwh1clRP9\/\/uhsJUSvWjXkrgPrUglhLwXoGQKxI4CEiF3ImDAE9hFAQpANELBDAAmBhLCTWfnbKxLCXuyREPbY0jMEIGCHABLCDld6hUAkBJAQkWBmkDwkgIRAQuRh2ltdMhLCHl6VEP3+uV5mOXomxO9r1ZCxB9ahEsJeCtAzBGJHAAkRu5AxYQhQCUEOQMA2ASQEEsJ2juVb\/0gIexFXCdH3nxtk1vZd9gYJ0fPvC6vLuANrIyFCMORVCCSNABIiaRFlPXlFgEqIvAo3i42QABICCRFhuuXFUEgIe2FGQthjS88QgIAdAkgIO1zpFQKREEBCRIKZQfKQABICCZGHaW91yUgIe3hVQlzyz00OV0JUk\/EHFlIJYS8F6BkCsSOAhIhdyJgwBPYRQEKQDRCwQwAJgYSwk1n52ysSwl7skRD22NIzBCBghwASwg5XeoVAJASQEJFgZpA8JICEQELkYdpbXTISwh5eIyG+10qIInuDhOj594XVZPxBtaiECMGQVyGQNAJIiKRFlPXkFQEkRF6Fm8VGSAAJgYSIMN3yYigkhL0wIyHssaVnCEDADgEkhB2u9AqBSAggISLBzCB5SAAJgYTIw7S3umQkhD28RkKs2exwJURVGd+wJpUQ9lKAniEQOwJIiNiFjAlDYB8BJATZAAE7BJAQSAg7mZW\/vSIh7MXe3I6xeou7EqJ2VRnXsAYSwl4K0DMEYkcACRG7kDFhCCAhyAEI2CaAhEBC2M6xfOsfCWEv4kgIe2zpGQIQsEMACWGHK71CIBICVEJEgplB8pAAEgIJkYdpb3XJSAh7eFVC9Fu9VWZt321vkBA9\/752FRnbsDqVECEY8ioEkkYACZG0iLKevCKAhMircLPYCAkgIZAQEaZbXgyFhLAXZiSEPbb0DAEI2CGAhLDDlV4hEAkBJEQkmBkkDwkgIZAQeZj2VpeMhLCHVyVE\/9XbZfY2NyshetUukLsaVaMSwl4K0DMEYkcACRG7kDFhCOwjgIQgGyBghwASAglhJ7Pyt1ckhL3Yq4S4bJVKiD32BgnRc8\/aBTLm4KpIiBAMeRUCSSOAhEhaRFlPXhFAQuRVuFlshASQEEiICNMtL4ZCQtgLMxLCHlt6hgAE7BBAQtjhSq8QiIQAEiISzAyShwSQEEiIPEx7q0tGQtjDqxJiwMqd8qmjlRA96hwgow+uQiWEvRSgZwjEjgASInYhY8IQ2EcACUE2QMAOASQEEsJOZuVvr0gIe7FHQthjS88QgIAdAkgIO1xj0WuLFi1k2LBhctRRR0mtWrVkz549snHjRvnwww\/lySeflDVr1uy3Dv3fW7duXeb6tI+tW7fK8uXL5S9\/+YvMmDEj6yyGDh0qF198se9+d+7cKQ899JC89NJLvt+JS0MkRFwixTzjRgAJgYSIW866Pl8khL0IqYS4YsUu+czRSojf1TlA7mxcQCWEvRSgZwjEjgASInYhy86EzzvvPBk0aJAUFham7XDVqlUyYcIEmT17domfVyQhvI1VSMyZM0duu+022bBhQ3YmLiJIiH0okRBZSys6gkAJAkgIJAS\/EtklgITILk9vbyohBq0oks+2\/WxvkBA9n1OnstzR+AAkRAiGvAqBpBFAQiQtoj7W065dOxk9erQ0atRINm\/eLC+\/\/LI8++yzUrVqVRkwYID87ne\/k2rVqsm8efPk+uuvN9URqSclIdauXWuqC7w\/0zYHH3ywdOzYUTp16lQsOObPn2\/6yZaISEkIrXB44YUXjOgo79m9e7csXrw4a+P7QBxZEyREZKgZKM8IICGQEHmW8taXi4SwhxgJYY8tPUMAAnYIICHscHW61xtuuEHOPfdc2bVrV9ptCtdee62cf\/75oh\/5EydOlDfeeGM\/CbF69WrRfpYuXZp2rYcffriMGjVKWrZsKSoBdGvGAw88kBUuXgmR1G0WfkEhIfySoh0EghFAQiAhgmUMrSsigISoiFDmP1cJcdWK3TJnq5uVEGfXrSS3UwmReYB5EwIJJICESGBQK1rS7bffbkrifvjhB7n66qv3q2bQKoYxY8aYSobnn39eJk+eHFhC6Av6gaz91K9fX9atW2ekxcKFCyuaXoU\/R0LsQ4SEqDBdaACBjAggIZAQGSUOL5VJAAlhLzmQEPbY0jMEIGCHABLCDtdY93rSSSfJnXfeaQ6rDCMhFMJNN90kPXv2lB07dsjjjz8uzz33XGg22ZAQBQUF8oc\/\/MHMrUmTJmYrij5a\/aGHauohltOnT087V23fv39\/OeWUU6Ru3bpSuXJl2bJli3zzzTcyadIks\/Wj9JPuHWWiW1WeeuopmTlzZkZckBAZYeMlCFRIAAmBhKgwSWgQiAASIhCuQI1VQgz5bo\/TlRC3NqnMmRCBokpjCCSbABIi2fHNaHUqDnr06GFuuRg7dqy89957xf2kzoSoaDtG6oWzzz7bnAdRo0YNeeutt8wWjbBPWAlRr149uffee6Vt27ZSqVKltNPRrSqvvfaa3HfffSV+3q1bNxkxYoSp7kj3rF+\/Xu6++255\/\/33i3+sUkff0TM40j0qI1TOqKQJ+iAhghKjPQT8EUBCICH8ZQqt\/BJAQvglFbydSoirl\/8sn28N\/m4Ub\/xHXZGRTSshIaKAzRgQiAkBJERMAmV7mloZcPzxx8sll1wienCl\/ne9qnPkyJFSVFSUsYTQ6z\/Hjx9vPsD1r\/568GXYJ6yEuOOOO+TMM88069J\/cD\/xxBNmm4jKiYsuusicl6FbUUpvIWnVqpWRMs2aNTOVHXr9qEqZTZs2SZ8+fUxlhb63bNkyue6668wVp0cccYTcc8895h2tsnj33Xfl6aeflpUrV8ppp50ml156qej5GSp8tIpi2rRpgfAgIQLhojEEfBNAQiAhfCcLDX0RQEL4wpRRIyRERth4CQIQyCEBJEQO4bsy9AUXXCBDhgwp3pKQ+sB+8MEHzcex9wlaCaEf4Vp10LRpU1mwYIHZxhD2CXJFZ+mKDRUJOp+GDRvKrFmzTJWGV7Lo3PTqUpUK27Ztk3HjxhVXgngP9HzkkUdk6tSpJZaia9P\/U4GjWyy0siH1jo6RrrLCKzbmzp1r4lB6PuXxQkKEzSbeh0B6AkgIJAS\/G9klgITILk9vbyohrlkmzlZCdK8ncktToRLCXgrQMwRiRwAJEbuQZX\/C6T7q9a\/2f\/\/7300Vg1dExF1CnHHGGeYwTq1Y0LVoVULpJyVl9H9P3b6hYkGlQps2bcyNIFddddV+B3rquQ96A0iDBg2MuJgyZYo8\/PDDphqirHd0DOWvFRh6XapWaei\/TPh9kBB+SdEOAsEIICGQEMEyhtYVEUBCVEQo858jITJnx5sQgEBuCCAhcsPdqVEbN25s5qO3ZaS2CBx22GHmf\/vggw\/M4ZKpxyUJoaLkhRdekDlz5pTJc\/v27TJv3rxyqwtUEuh6dTvKMcccY7ZHVKtWzWyfSEmII4880lRQqGjQ8x5uvvnmCmN47LHHmkoKPT9COd54441p30mdm3HAAQeYrSHpxEhZgyEhKgwDDSCQEQEkBBIio8ThpTIJICHsJcdeCVFJvthib4wwPWslxM3NfqYSIgxE3oVAwgggIRIW0GwsR89GuP\/++81f\/fWgRb3S89NPPzVdB5UQHTp0MNd06i0SX375pdnqEPYJeyaEVjXodgv9+NezKlI3Y5Sel1dClHdtaVnr8b7jd82lbyOp6L2UhKhX7wkpqPJ9cfPq1T+XgoI1Fb3OzyEAgTIIICGQEPxyhCOwfXt7KSpqUtzJ9m3tZdGi9ubcJZ7sElAJce3SyvLFlvSHbWd3tOC9nVXvZ7mp+R4kRHB0vAGBxBJAQiQ2tOEW1rdv3+JDJL1\/nQ8qIbznTbhwO4YKiLvuustcr6k3Y\/z8889mu4keQvn999+bcyv27NkjvXv3NgBTlRCuS4jSwqFe\/f8jhYVvhksC3oZAHhNAQiAh8jj9s7L0DesvE61+SD0qJPTAZiREVvCW6AQJkX2m9AgBCNglgISwyze2vXvlgfev80ElhF7Jefrpp5fY2hAWSphKCJULV1xxhal+mD17tqn40NssvE+6MyG8t3z43Y7hrQJ58cUXzXkR2X7YjpFtovQHgb0EkBBICH4XskuA7RjZ5entTSXE8CUHuFsJUX+P3EglhL0EoGcIxJAAEiKGQQsz5UMOOcRUAjRv3ly++OILc5Vkuid1WOKuXbtEb8l45ZVXTLMgEkI\/kHUrhp6JoFdSXnPNNeavIGGfMBJiwoQJ0rVrV7PNRM910C0ipR89A6Nnz54lxIluJ0kdMrlo0SJzmOTGjRv3e1dvzdAbL7SNHuqp\/3fooYdKJjdf+OGEhPBDiTYQCE4ACYGECJ41vFEeASSEvfxAQthjS88QgIAdAkgIO1yd7VW3I+gWg3bt2pmPaP1I1r\/sex\/vtZGlr7j0KyH0cEetgmjZsqWoyHj22WflscceywqXbEkI71kXqYn96le\/MvPWAyi9Z0Lozyu6orNbt27mEE8VFqmtJzrGWWedZfp69NFH97vWM9XvOeecY7aF6NaXlPDxAwsJ4YcSbSAQnAASAgkRPGt4AwmRmxwwEuJ\/C+RLR8+EOFMrIQ7ZzZkQuUkPRoWAkwSQEE6Gxe6kzjvvPPOXfL0BQm\/EULGgH836dO\/eXfQ8CD2wMZ08SEmItWvXGplRuhpAb5HQbQh6M0StWrXMmQszZ86UP\/7xj+XeUBFkxWEkhB6MqYdS6k0UWq2gVR566KbeEPKf\/\/mfcuaZZ4oezKlPaQnhlTMqDN58800jDbSdcuvfv78cdNBBpspCq00+\/vhjUxUxduxYadasmezYsUNmzJhheOv5E\/qzAQMGSOfOnc32kMWLF5u4bNiwwTcOJIRvVDSEQCACSAgkRKCEoXGFBKiEqBBRxg1UQlynEmJz5Yz7sPnimQ32yIhDipAQNiHTNwRiRgAJEbOAZWu6gwcPlgsvvLDcmyH0HIMpU6aUGDIlIfzMQw94\/Mc\/\/iGjR48O9GFdUd9hJIRWOGj1hwqAdI8KBd2i0aJFCyMjtILDy0CrHUaMGGG2mKR7VE5oxcNLL71U\/OOK3tGGq1atEt0qoudUBHmQEEFo0RYC\/gkgIZAQ\/rOFln4IICH8UMqsDRIiM268BQEI5I4AEiJ37HM+st740K9fP\/NBrlUL+mzZskUWLlwoTz31lKlgKP1UJCG0ekL70CoD\/RD\/6KOPsr7OMBJCJ6MiQiWMrr+wsNDckuFd97fffiuTJ082W0nSneVQ1vvffPONTJo0yVQ0lH70Ha2U0Fs5dLtG5cqVTaWJVj38\/e9\/NxUVQSogUv0jIbKeXnQIAUMACYGE4FchuwSQENnl6e1NJcT1i6s4WwlxRoPdMuJQKiHsZQA9QyB+BJAQ8YsZM4ZAMQEkBMkAATsEkBBICDuZlb+9IiHsxR4JYY8tPUMAAnYIICHscKVXCERCAAkRCWYGyUMCSAgkRB6mvdUlIyHs4TUSYlFVtyshDtvFmRD2UoCeIRA7AkiI2IWMCUNgHwEkBNkAATsEkBBICDuZlb+9IiHsxV4lxA0LHZYQB+6WPyIh7CUAPUMghgSQEDEMGlOGQIoAEoJcgIAdAkgIJISdzMrfXpEQ9mKPhLDHlp4hAAE7BJAQdrjSaxkE9DDIMWPGmAMhgz6lr8wM+n4S2yMhkhhV1uQCASQEEsKFPEzSHJAQ9qK5V0JUk7k\/uXlF5xkH7pYbDt\/Jdgx7KUDPEIgdASRE7EIW7wm3adNGhgwZIjVr1gy8EL1N4oUXXpD3338\/8LtJfQEJkdTIsq5cE0BCICFynYNJGx8JYS+iSAh7bOkZAhCwQwAJYYcrvUIgEgJIiEgwM0geEkBCICHyMO2tLhkJYQ+vSog\/LtBKiAPsDRKi59MPLJIbjqASIgRCXoVA4gggIRIXUhaUTwSQEPkUbdYaJQEkBBIiynzLh7GQEPaijISwx5aeIQABOwSQEHa40isEIiGAhIgEM4PkIQEkBBIiD9Pe6pKREPbwqoQY8Y3DlRAHFcn1R1IJYS8D6BkC8SOAhIhfzJgxBIoJICFIBgjYIYCEQELYyaz87RUJYS\/2KiFu\/Ka6zN3k6HaMhkVy3ZE7OJjSXgrQMwRiRwAJEbuQMWEI7COAhCAbIGCHABICCWEns\/K3VySEvdgjIeyxpWcIQMAOASSEHa70CoFICCAhIsHMIHlIAAmBhMjDtLe6ZCSEPbxGQsyvLl85Wgnx71oJ8W9UQtjLAHqGQPwIICHiFzNmDIFiAkgIkgECdgggIZAQdjIrf3tFQtiLPRLCHlt6hgAE7BBAQtjhSq8QiIQAEiISzAyShwSQEEiIPEx7q0tGQtjDayTEvBoOV0LskutaUAlhLwPoGQLxI4CEiF\/MmDEEqIQgByBgmQASAglhOcXyrnskhL2Qq4S46WuHJUSjXTIcCWEvAegZAjEkgISIYdCYMgRSBKiEIBcgYIcAEgIJYSez8rdXJIS92CMh7LGlZwhAwA4BJIQdrvQKgUgIICEiwcwgeUgACYGEyMO0t7pkJIQ9vHslRE35aqObV3T+u1ZCtNzOFZ32UoCeIRA7AkiI2IWMCUNgHwEkBNkAATsEkBBICDuZlb+9IiHsxR4JYY8tPUMAAnYIICHscKVXCERCAAkRCWYGyUMCSAgkRB6mvdUlIyHs4VUJcfNcrYQosDdIiJ5\/e\/AuGd5qG5UQIRjyKgSSRgAJkbSIsp68IoCEyKtws9gICSAhkBARplteDIWEsBdmIyG+rOWwhNgpw1sjIexlAD1DIH4EkBDxixkzhkAxASQEyQABOwSQEEgIO5mVv70iIezFHglhjy09QwACdgggIexwpVcIREIACREJZgbJQwJICCREHqa91SUjIezhVQlxi1ZCbHB0O0bjnXItlRD2EoCeIRBDAkiIGAaNKUMgRQAJQS5AwA4BJAQSwk5m5W+vSAh7sUdC2GNLzxCAgB0CSAg7XOkVApEQQEJEgplB8pAAEgIJkYdpb3XJSAh7eI2E+KLQ7UqINls5mNJeCtAzBGJHAAkRu5AxYQjsI4CEIBsgYIcAEgIJYSez8rdXJIS92BsJ8Xlt+drh7RjDjtqChLCXAvQMgdgRQELELmRMGAJICHIAArYJICGQELZzLN\/6R0LYizgSwh5beoYABOwQQELY4UqvEIiEAJUQkWBmkDwkgIRAQuRh2ltdMhLCHl4jIeZoJUQVe4OE6Pm3TXYIlRAhAPIqBBJIAAmRwKCypPwhgITIn1iz0mgJICGQENFmXPJHQ0LYizESwh5beoYABOwQQELY4UqvEIiEABIiEswMkocEkBBIiDxMe6tLRkLYw6sSYuRndeTr9W5WQpymlRBHb+ZMCHspQM8QiB0BJETsQsaEIbCPABKCbIAABHJBAElTNvX\/+frqXITE+TGREPZCpBLi1k\/ruishmm6Xa5AQ9hKAniEQQwJIiBgGjSlDIEUACUEuQAACuSCAhEBCBM07JERQYv7bIyH8s6IlBCDgBgEkhBtxYBYQyIgAEiIjbLwEAQiEJICEQEIETSEkRFBi\/turhLhtdj2nKyGG\/uontmP4DyktIZB4AkiIxIeYBSaZABIiydFlbRBwlwASAgkRNDuREEGJ+W+PhPDPipYQgIAbBJAQbsSBWUAgIwJIiIyw8RIEIBCSABICCRE0hZAQQYn5b28kxKx6Mu\/Hqv5firDlb5ptl6HHbKISIkLmDAUB1wkgIVyPEPODQDkEkBCkBwQgkAsCSAgkRNC8Q0IEJea\/vUqI22fWd1hCbJOr2yEh\/EeUlhBIPgEkRPJjzAoTTAAJkeDgsjQIOEwACYGECJqeSIigxPy3R0L4Z0VLCEDADQJICDfiwCwgkBEBJERG2HgJAhAISQAJgYQImkJIiKDE\/Lc3EuIfDdythGiulRAb2Y7hP6S0hEDiCSAhEh9iFphkAkiIJEeXtUHAXQJICCRE0OxEQgQl5r89EsI\/K1pCAAJuEEBCuBEHZgGBjAggITLCxksQgEBIAkgIJETQFEJCBCXmv71KiDv+caDM+5ebB1N200qIYzdQCeE\/pLSEQOIJICESH2IWmGQCSIgkR5e1QcBdAkgIJETQ7ERCBCXmv72REJ+ohKjm\/6UIW3Y7ZKtc\/WskRITIGQoCzhNAQjgfIiYIgbIJICHIDghAIBcEkBBIiKB5h4QISsx\/eySEf1a0hAAE3CCAhHAjDswCAhkRQEJkhI2XIACBkASQEEiIoCmEhAhKzH97IyE+PsjtSoj269mO4T+ktIRA4gkgIRIfYhaYZAJIiCRHl7VBwF0CSAgkRNDsREIEJea\/PRLCPytaQgACbhBAQrgRB2YBgYwIICEywsZLEIBASAJICCRE0BRCQgQl5r\/9XgnRUOb94OiZEIdukauphPAfUFpCIA8IICHyIMgsMbkEkBDJjS0rg4DLBJAQSIig+YmECErMf3skhH9WtIQABNwggIRwIw7MAgIZEUBCZISNlyAAgZAEkBBIiKAphIQISsx\/eyMhPmzkdiXE8T9yJoT\/kNISAokngIRIfIhZYJIJICGSHF3WBgF3CSAhkBBBsxMJEZSY\/\/YqIf7rA5UQ1f2\/FGHLbodtkSHH\/wsJESFzhoKA6wSQEK5HiPlBoBwCSAjSAwIQyAUBJAQSImjeISGCEvPfHgnhnxUtIQABNwggIdyIA7OAQEYEkBAZYeMlCEAgJAEkBBIiaAohIYIS899+r4Q4WOatc7USYrMM6UAlhP+I0hICySeAhEh+jFlhggkgIRIcXJYGAYcJICGQEEHTEwkRlJj\/9kgI\/6xoCQEIuEEACeFGHJgFBDIigITICBsvQQACIQkgIZAQQVMICRGUmP\/2RkK873AlxOGbZcgJVEL4jygtIZB8AkiI5MeYFSaYABIiwcFlaRBwmAASAgkRND2REEGJ+W9vJMT\/bezudgyVEB1\/4GBK\/yGlJQQSTwAJkfgQs8AkE0BCJDm6rA0C7hJAQiAhgmYnEiIoMf\/tkRD+WdESAhBwgwASwo04WJ9FQUGB9OnTR3r16iUNGjSQKlWqyM6dO2XJkiXy4osvyowZM\/abQ6dOnWTMmDFSWFhY5vy0j82bN8tXX30lf\/7zn2Xx4sVZX8uTTz4prVu3ltWrV8sNN9wgS5cuLXeMCRMmSNeuXc28br31Vpk5c2bW55TNDlPr++CDD+TGG28M1DUSIhAuGkMAAlkigIRAQgRNJSREUGL+2++VEE1k\/lpHD6Y8YrMM7riOSgj\/IaUlBBJPAAmR+BCL1KtXz8gE\/WCtVKnSfitWkaAS4p577pGioqLin\/uREN7OduzYIS+99JJMmTIlq1SREGXjREJkNdXoDAIQ8EkACYGE8Jkqxc2QEEGJ+W+PhPDPipYQgIAbBJAQbsTB6ixuuukm6dGjhxlj3rx5MnnyZJk7d66cfPLJcuWVV0qLFi1EBYL+76+88kpaCTFr1ix5\/vnn95vn0UcfLR07dpSjjjpKqlatKrt27ZLXXntN7rvvvqytCQmBhMhaMtERBCCQFQJICCRE0ERCQgQl5r+9kRDvOl4J0ZlKCP8RpSUEkk8ACZHwGLdq1UruvfdeadiwocyfP1+uu+462bhxY\/GqjzjiCPPzpk2bypdffimDBg1KKyEq2ipw9tlny9ChQ6Vu3bqyYcMGueuuu+Sjjz7KCl0kBBIiK4lEJxCAQNYIICGQEEGTCQkRlJj\/9ioh7vwflRA1\/L8UYctTj\/xJBiMhIiTOUBBwnwASwv0YhZqhVjsMGTJEDjroIHnmmWfk6aef3q+\/1BkKpc9c8G7HqEhCaKcDBw40507oeRP6D0QVHtl4kBBIiGzkEX1AAALZI4CEQEIEzSYkRFBi\/tsjIfyzoiUEIOAGASSEG3HI6Sy0EuKkk07a7+DHoBJCqyAefvhh0eqKdevWmUMkFy5cGHpt2ZYQuv3kiiuukHbt2kmdOnWkcuXKsmfPHlMh8umnn5o1rFmzpnje3moR3ZLyxRdfSP\/+\/c02Ft2ComdqaPtnn31Wpk+fnna9p5xySol3dPuLHuY5adIkc3imHrzpR\/SU7pwzIUKnFx1AAAIZEEBCICGCpg0SIigx\/+1VQox6p6nM\/6e7lRBXnbiWgyn9h5SWEEg8ASRE4kNc\/gL1Q3z06NHSqFGj\/aoXgkoIHen222+X7t27y7Zt22TixInyxhtvhCacTQlxwQUXmHMwatasWea8Vq1aJbfcckuxQPFKiNmzZ4ueg5HufZURTzzxxH7VJhdddJEZs1q1avuNqWPpYaCHHXYYEiJ0ptABBCAQFQEkBBIiaK4hIYIS898eCeGfFS0hAAE3CCAh3IhD5LNo3LixOaxSr+ysX7++rF+\/Xu6++255\/\/33i+eSiYTo27evDBgwwGzJ0MqAbNyUkS0JoVUDekuIrveHH34Q7fett96SrVu3SocOHYwoUMGgz6uvvmrOytDHKyH0v+vVn\/rzqVOnmioIrYpQuaGSYeXKlXLNNdcUV1JohcnIkSOLGeuYWi2h0ueqq66Szp07m2oKfaiEiPzXgAEhAIEMCSAhkBBBUwcJEZSY\/\/YqIUa\/7XAlxL\/9JIOohPAfUFpCIA8IICHyIMill5j6qE\/9799995386U9\/kg8\/\/LBE00wkhH6M6xkU+mGtWxf0xo2wT+n5+u1PZYFudZg5c6Z5RbeHnHvuubJlyxZzHenbb79doqsmTZrIgw8+KM2bNxeteFCZUFpCqLDQLRTTpk0r8fdV\/VwAACAASURBVK5WTvzud78zgmLcuHHy3nvvmZ+PGjVKTj\/9dLPVY\/z48SUkj\/48dXOJXp2KhPAbWdpBAAK5JoCEQEIEzUEkRFBi\/tsbCfG3ZvLN925ux+jaYpMMOontGP4jSksIJJ8AEiL5MS6xwtJ\/1dcf\/vzzz\/L999+bD\/CwlRAuSwjdHnLssceaKoWrr766xC0hKUgp4bFgwQJT4VBaQixdutRUMHhvGNE2qXXrf37ooYfkpZdekkMOOUTuv\/9+adasWQmp4Q2IXm2qckIrI5AQefbLyHIhEGMCSAgkRND0RUIEJea\/PRLCPytaQgACbhBAQrgRh8hmUVBQIIceeqho9YPemKEf2meddZbZSqBbMvRqzY8\/\/tjMx7VKiLVr15oP\/NICoDS8iy++WDp27GiqEryVEKXb6bkObdq0MYdC\/vrXvzb\/WZnoQZVlSQhloxUVpZ90EsLLr7yqED1Hom3btkiIyH4LGAgCEAhLAAmBhAiaQ0iIoMT8t1cJcdcMdyshTmmxSa48mUoI\/xGlJQSSTwAJkfwYV7hCPThx0KBBZgvFO++8Yw6XzFRCDB482FzTqbdNPPXUU\/L4449XOH5FDbJ1JoSOozda6HYRPfuhsLBQdBtEuqcsCVFWtUI6CXHeeecVb+lId2BlatzUFalhKiFKr+GghndJYeGbFaHl5xCAAAQyIoCEQEJUlDg\/rBspKh68j1Yi6rZInuwSQEJklye9QQAC9gkgIewzdn4E79Wa3u0GmVRCpD6oXbwdo1u3bjJixAhzSKQ+eqikVkvoVpTly5fLZ599JhdeeKG0bNmyzEoIVyWESoeCgn3XihYUfF\/ivzufhEwQAhCIFQEkBBKiooQtKmoiRUWNi5tt39ZevvnmP5AQFYHL4OcqIca+2dzZMyFOablJBp7yT67ozCC2vAKBpBJAQiQ1sgHXla7aIKiE8B7suHr1arNtQaVG2CcblRAqWvSQTBUMup1DKzRef\/11cz2m96noTIggEsLL78UXX5QHHnggLYpHHnnEnFURphKi+SHnIx3CJhrvQwACvgkgIZAQvpPll4ZsxwhKzH97lRDj3mwu365x82DKk1tukiu6IiH8R5SWEEg+ASREwmN8xRVXmL\/u79q1y9wIkbq1wbts72GV8+fPN1ds6hNUQgwcONBsxdDrOb3bOsIizoaE8K5Fr+XUWytKP95DIrOxHUOvQdWbNPQMjrlz55ptIKWlh5c9EiJspvA+BCAQFQEkBBIiaK4hIYIS898eCeGfFS0hAAE3CCAh3IiDtVn06NFDrrvuOnPwpH7kjhw5cr8PYf15r169zIGMf\/nLX4r\/Yh9EQpx99tkydOhQ0YoDPeBSD4ScM2dOVtaVbQmRTpDogZ3Dhw+Xnj17ygEHHJCV7Ri6+DvuuEPOPPNMs\/Xj0UcflalTp5ZgkmKv4gYJkZV0oRMIQCACAkgIJETQNENCBCXmv71KiPHTtRKipv+XImx5cqtNcvmp37MdI0LmDAUB1wkgIVyPUMj5qRTQqyn1IEathtB\/UOkhiQsXLpRWrVqZqofOnTubQymXLVtmhIUeHKWPV0LMmjVL9IYH76Mf7rqNQG+iOPLII00FhH5sl3cIYybLyYaE8G4V2bFjh7lCU9ejZ0KcfPLJpoJDKyFUxOiTjUoI7addu3YyevRocwWnjvXqq68aEVG9enW59NJLzc0kyl4fJEQm2cE7EIBALgggIZAQQfMOCRGUmP\/2SAj\/rGgJAQi4QQAJ4UYcrM5CZYP+RV5FQVnPkiVL5M477zRyIvV4JYSfCW7dutV82KuEyOaTDQmh8+nbt6+RLqmP\/tJz1CtAV6xYIccff7ysWrXKVEbof\/ezZSLd7Rip\/rVKRLdipA7E9I6bOhyzQYMGSIhsJg19QQACVgkgIZAQQRMMCRGUmP\/2KiEm\/LW5LHC0EuKkVptkQDcqIfxHlJYQSD4BJETyY2xWWLNmTenfv7+cccYZoh+8WrWglRE\/\/vijvP3226If+ioRvI8fCaEf0XrQ4yeffCIvvPCCqabI9pMtCaHzOuecc0zVg1ZGqIwozeD3v\/+96Dka+tx3330ybdq00BJC+9KrQYcNG2aqLWrVqmXG1YqTZ555Rk455RTp2rUrEiLbiUN\/EICANQJICCRE0ORCQgQl5r+9Soi7pzWXBavd3I5xUutNctlvkBD+I0pLCCSfABIi+TFmhQkmcNxxx8lDDz0k3I6R4CCzNAg4SAAJgYQImpZIiKDE\/LdHQvhnRUsIQMANAkgIN+LALCCQEQEkREbYeAkCEAhJAAmBhAiaQkiIoMT8t1cJce\/r7lZCnNh6k1x6GpUQ\/iNKSwgknwASIvkxZoUJJoCESHBwWRoEHCaAhEBCBE1PJERQYv7bIyH8s6IlBCDgBgEkhBtxYBYQyIgAEiIjbLwEAQiEJICEQEIETSEkRFBi\/tsbCfFac1m4ys0zIU5ss0n6\/5ZKCP8RpSUEkk8ACZH8GOd0hRMmTDCHLmbyeK\/JzOT9fHgHCZEPUWaNEHCPABICCRE0K5EQQYn5b68SYuJ\/q4So4f+lCFt2UQnx7\/+ULl26RDgqQ0EAAi4TQEK4HJ0EzG3w4MHmystMnuXLl8uoUaMyeTVv3kFC5E2oWSgEnCKAhEBCBE1IJERQYv7bIyH8s6IlBCDgBgEkhBtxYBYQyIgAEiIjbLwEAQiEJICEQEIETSEkRFBi\/turhLjvFYcrIY7aJP1OpxLCf0RpCYHkE0BCJD\/GrDDBBJAQCQ4uS4OAwwSQEEiIoOmJhAhKzH97JIR\/VrSEAATcIICEcCMOzAICGRFAQmSEjZcgAIGQBJAQSIigKYSECErMf3uVEPdrJcRKR8+EaLtJ+lIJ4T+gtIRAHhBAQuRBkFlicgkgIZIbW1YGAZcJICGQEEHzEwkRlJj\/9kZCvNxcFjkqITqrhDiT7Rj+I0pLCCSfABIi+TFmhQkmgIRIcHBZGgQcJoCEQEIETU8kRFBi\/tsjIfyzoiUEIOAGASSEG3FgFhDIiAASIiNsvAQBCIQkgIRAQgRNISREUGL+2xsJ8VIzdyshjtZKiLVc0ek\/pLSEQOIJICESH2IWmGQCSIgkR5e1QcBdAkgIJETQ7ERCBCXmvz0Swj8rWkIAAm4QQEK4EQdmAYGMCCAhMsLGSxCAQEgCSAgkRNAUQkIEJea\/vUqIB15sJotWuHkwZeejN8kl3amE8B9RWkIg+QSQEMmPMStMMAEkRIKDy9Ig4DABJAQSImh6IiGCEvPfHgnhnxUtIQABNwggIdyIA7OAQEYEkBAZYeMlCEAgJAEkBBIiaAohIYIS899eJcSkF9ythOj0Kyoh\/EeTlhDIDwJIiPyIM6tMKAEkREIDy7Ig4DgBJAQSImiKIiGCEvPf3kiIqU1l0XdubsfodMxPcsl\/sB3Df0RpCYHkE0BCJD\/GrDDBBJAQCQ4uS4OAwwSQEEiIoOmJhAhKzH97JIR\/VrSEAATcIICEcCMOzAICGRFAQmSEjZcgAIGQBJAQSIigKYSECErMf3uVEA8+73YlRJ+zqYTwH1FaQiD5BJAQyY8xK0wwASREgoPL0iDgMAEkBBIiaHoiIYIS898eCeGfFS0hAAE3CCAh3IgDs4BARgSQEBlh4yUIQCAkASQEEiJoCiEhghLz395IiOeaOH0mRJ9z1kmXLl38L4qWEIBAogkgIRIdXhaXdAJIiKRHmPVBwE0CSAgkRNDMREIEJea\/vZEQzzaRRcsdPZiy3U\/S53dICP8RpSUEkk8ACZH8GLPCBBNAQiQ4uCwNAg4TQEIgIYKmJxIiKDH\/7ZEQ\/lnREgIQcIMAEsKNODALCGREAAmRETZeggAEQhJAQiAhgqYQEiIoMf\/tjYR4poksXl7d\/0sRtuzUbrP07kElRITIGQoCzhNAQjgfIiYIgbIJICHIDghAIBcEkBBIiKB5h4QISsx\/eySEf1a0hAAE3CCAhHAjDswCAhkRQEJkhI2XIACBkASQEEiIoCmEhAhKzH97IyGecrgS4tjN0rsnlRD+I0pLCCSfABIi+TFmhQkmgIRIcHBZGgQcJoCEQEIETU8kRFBi\/tvvlRCNZfEyR7dj\/FolxA\/cjuE\/pLSEQOIJICESH2IWmGQCSIgkR5e1QcBdAkgIJETQ7ERCBCXmvz0Swj8rWkIAAm4QQEK4EQdmAYGMCCAhMsLGSxCAAASsEUDQpEd74m8bSPcLq8q5555rjX2+dmwkxJMHu10J0etfVELka4KybgikIYCEIC0gEGMCSIgYB4+pQwACiSSAhEBCRJ3YSIioiTMeBCAQlgASIixB3odADgkgIXIIn6EhAAEIpCGAhEBCRP2LYSTE\/2nkbiVE+y3S+\/dUQkSdF4wHAZcJICFcjg5zg0AFBJAQpAgEIAABtwggIZAQUWdksYRY6ujBlCohzkVCRJ0XjAcBlwkgIVyODnODABKCHIAABCAQKwJICCRE1AmLhIiaOONBAAJhCSAhwhLkfQjkkACVEDmEz9AQgAAE0hBAQiAhov7FUAkx+c+NZPHSalEP7Wu8jsdtkd7n\/cjBlL5o0QgC+UEACZEfcWaVCSWAhEhoYFkWBCAQWwJICCRE1MmLhIiaOONBAAJhCSAhwhLkfQjkkAASIofwGRoCEIBAGgJICCRE1L8YRkI83tDtSojz11MJEXViMB4EHCaAhHA4OEwNAhURQEJURIifQwACEIiWABICCRFtxonslRAHyeIljm7HOH6r9EZCRJ0WjAcBpwkgIZwOD5ODQPkEkBBkCAQgAAG3CCAhkBBRZyQSImrijAcBCIQlgIQIS5D3IZBDAkiIHMJnaAhAAAJpCCAhkBBR\/2IYCfHogW5XQlywge0YUScG40HAYQJICIeDw9QgUBEBJERFhPg5BCAAgWgJICGQENFm3C\/bMZAQUWNnPAhAIAQBJEQIeLwKgVwTQELkOgKMDwEIQKAkASQEEiLq3wlTCfGIVkJUjXpoX+N17LBNelMJ4YsVjSCQLwSQEPkSadaZSAJIiESGlUVBAAIxJoCEQEJEnb57JUQDWfy\/DkuICzeyHSPqxGA8CDhMAAnhcHCYGgQqIoCEqIgQP4cABCAQLQEkBBIi2oz7ZTsGEiJq7IwHAQiEIICECAGPVyGQawJIiFxHgPEhAAEIlCSAhEBCRP07YSohptR3txLihG3S+z83UQkRdWIwHgQcJoCEcDg4TA0CFRFAQlREiJ9DAAIQiJYAEgIJEW3G\/VIJgYSIGjvjQQACIQggIULA41UI5JoAEiLXEWB8CEAAAiUJICGQEFH\/TphKiIfqyeL\/rRL10L7G63jCdul90U9UQviiRSMI5AcBJER+xJlVJpQAEiKhgWVZEIBAbAkgIZAQUSevkRB\/qiuLFzsqITpul94Xb0ZCRJ0YjAcBhwkgIRwODlODQEUEkBAVEeLnEIAABKIlgIRAQkSbcb9sx0BCRI2d8SAAgRAEkBAh4PEqBHJNAAmR6wgwPgQgAIGSBJAQSIiofydMJcTkOg5XQuyQ3r2phIg6LxgPAi4TQEK4HB3mBoEKCCAhSBEIQAACbhFAQiAhos5IJETUxBkPAhAISwAJEZYg70MghwSQEDmEz9AQgAAE0hBAQiAhov7FUAnx4IO1ZfEiN8+E6NRph\/Tus4UzIaJODMaDgMMEkBAOB4epQaAiAkiIigjxcwhAAALREkBCICGizbi9Z0IgIaKmzngQgEAYAkiIMPRy9G5BQYH06dNHevXqJQ0aNJAqVarIzp07ZcmSJfLiiy\/KjBkz9ptZp06dZMyYMVJYWFjmrLWPzZs3y1dffSV\/\/vOfZfHixdZXePLJJ8sFF1wgLVu2lDp16kjlypVlz549smnTJlm0aJE899xzMnPmzLTzOOKII+Tee++Vpk2bygcffCA33nij7\/kOHTpULr74YrPeW2+9tcwxfHeYo4ZIiByBZ1gIQAACZRBAQiAhov7lMBJiUqEsXlQQ9dC+xuvUaaf0vmQrlRC+aNEIAvlBAAkRszjXq1fPyAT9+KxUqdJ+s1eRoBLinnvukaKiouKf+5EQ3s527NghL730kkyZMsUKocMPP1xuuukmOeaYY4x4KOtRIfH555\/LXXfdJWvWrCnRLAkSombNmnL55ZeL8rjuuusCs0ZCBEbGCxCAAASsEkBCICGsJliazo2EeKCWuxKis0qIbUiIqBOD8SDgMAEkhMPBSTc1\/XDv0aOH+dG8efNk8uTJMnfuXNGKgiuvvFJatGghKhD0f3\/llVfSSohZs2bJ888\/v1\/3Rx99tHTs2FGOOuooqVq1quzatUtee+01ue+++7JKqVWrVjJ27Fhp1qyZ\/Pzzz7J69WqZPn26kSfff\/+9NG7cWM466yw555xzTJWDypaVK1fKyJEjZeHChcVzSYKEGDdunHTr1k0WLFgg\/fv3D8wZCREYGS9AAAIQsEoACYGEsJpgSIio8TIeBCBggQASwgJUW13qx7tuP2jYsKHMnz\/f\/OV848aNaT\/Kv\/zySxk0aFBaCVHR1oWzzz5bdLtC3bp1ZcOGDaYK4aOPPsrKsrSSY+LEidK2bVuzhWTatGkyadKkElUbqYF028mIESOMkNAtJypdrr\/++uI1h5EQWVlMFjqZMGGCdO3aFQmRBZZ0AQEIQMAFAkgIJETUeWgqIe6vKYsXHhD10L7G69Rll\/Tuu51KCF+0aASB\/CCAhIhRnLXaYciQIXLQQQfJM888I08\/\/fR+s0991Gp1wQ033CBLly41bbzbMSqSENp+4MCB5twJ\/fjXf7hlslUgHdpUvyoYVECMHz++3AhoO5Ug+qGulRnPPvusPPbYY+YdJISYbTkPPfSQND\/kfCkoKLldJUapzVQhAAEIJIYAEgIJEXUyIyGiJs54EIBAWAJIiLAEHXtfKyVOOukks8UhjITQKoiHH37YfOivW7fO9OXdCpHJsrVP3Saih1AG6bNDhw4yatQoqV+\/vjmsUqs0tAKktITQLR0qOQ477DAjT7Zs2SKfffaZPP744\/sdslnRwZS6reWKK66Q9u3bm8M8dUtIef2leKg0+cMf\/iA9e\/aUJk2amG0tWvGh51moQNE56qOHcapQ0p97n6AHZSIhMslE3oEABCBgjwASAglhL7vS92wkxH013K6E6LeDSoioE4PxIOAwASSEw8EJOrV27drJ6NGjpVGjRvtVLwSthNCxb7\/9dunevbts27bNbKF44403gk6pRPvTTjtNbr75ZvNR76caw\/vygw8+KCeccIL89NNPcscdd5j1eSXE8uXLzVkS1apV22+O69evl7vvvlvef\/\/94p+VJyHOO+88s5WlrJtEVICoTCnNQ7eaqATSrSbpDg31nrGBhAiVSrwMAQhAwFkCSAgkRNTJaSTEvdXclRAnFknv\/juREFEnBuNBwGECSAiHg+N3avrxrYdV6pWdWi2Q7qM7EwnRt29fGTBggKkq0L\/ih70pI0x\/KWmgVQVPPPGE2YrilRDKSg\/k1MMtH3nkEYNORYJKFK02WLZsmdlSkrphoywJoVUkegCmctSqBBUNTz75pKlm0L708EjdDqOM9WrPOXPmmLFS20ZOOeUUc9hm6prTTz\/9VFS+aFWF3oCxdetWcwaGbkXRhzMh\/GY57SAAAQjEgwASAgkRdaYiIaImzngQgEBYAkiIsARz\/L5+ILdu3bp4Ft9995386U9\/kg8\/\/LDEzDKREN6\/1uttGvrX\/zCPVyToOQZ6BajfJ91cvBJCJYHKh6lTp5boUsWDyhm9BlRFSkpQlCUh9CaQLl26GKHx6KOP7tef3mShh2WqpHjnnXdMtYg+KhpuueUWqVWrlqnyUJHhvSLVW6XiPTQUCeE3A2gHAQhAIB4EkBBIiKgzda+EqCqLF5R95XnUc\/KO1+nE3dL70l1UQuQyCIwNAccIICEcC0iQ6ZSuBNB39a\/wes2lbl\/wbj9IuoT49ttvTbWB98Nfeei5DMqiefPm4v34Tych9GpSPShTt7PMnj1brrnmmrThSHf4p\/Z30UUXmXMj9NrN9957b7939VwLPVxURZFetapxQkIEyXjaQgACEHCfABICCRF1liIhoibOeBCAQFgCSIiwBHP4vm4BOPTQQ81HrW4R0K0Cep2lnoug2wX0VomPP\/7YzDDpEuL1118v86aN1GGdq1atkuHDh8uKFSvM4ZYXX3yx2XKh2ypmzpwpejWpXgFao0YNKa\/yQ2VHv379zFkZKeGQbgw\/qYGE8EOJNhCAAATiQwAJgYSIOluNhLiniixyuBKiz2VFVEJEnRiMBwGHCSAhHA5OJlPTv8brWQh6DoJ3u0AmEmLw4MHmms49e\/bIU089ZW6ZCPOkPt61j6D9peaihzumOxOiPGlQVuVCaQlR1mGRZa1Zt4CktpWktsUsWLDAyCC\/T7YkRGHhmyWGLKz9plSv\/rnfadAOAhCAAASyRAAJsRfkib9tIK2PqV1M9aBGVaXOQT\/JueeemyXSdJMiYCTEhAJZtKCSk1A6nbRH+gzYjYRwMjpMCgK5IYCEyA13a6N6r9ZcunSpXHXVVeY6y0wkROoDOQ63YyAhkBDWfqnoGAIQgEAAAkgIJESAdMlKUyREVjDSCQQgECEBJESEsKMaKvVX+dWrV8sNN9wgKiOCSgjvWQrefsKsQQWJHm7ZsmVLWbdunZnbwoULK+zyuOOOkzFjxpjDIBctWmS2UqhY8Z6JUd52jNT1nrptZdiwYeYshnTbMfRqztQ5EA8\/\/LC88MILFc4t1SA1hnfLh5+Xs1UJ0fyQ86WgYI2fIWkDAQhAAAIWCSAh0sPVyojuF1alEsJC7u2VEJVl0beOVkKc\/LP0GbCHSggLsadLCMSVABIiRpHT7QwXXnih6JaEe+65J+3hh94P8\/nz55srNvUJKiEGDhxotmLo9ZzebR1hcaX61fMs9AaP0rdIlO7fe\/WlHjqpN1w89thjppl3rd5DJ719eGWK97DJdBLi2GOPNWc8lL75ws+a9aDJnj17moMpx44dmzY2Gj9lqgJF46frR0L4oUsbCEAAAvEhgIRAQkSdrUiIqIkzHgQgEJYAEiIswQjf79Gjh+iVk3rwZLprIHUq3isp\/\/KXv8gDDzwQWELoAY36ka6VC3rApR7cOGfOnKysVPucOHGiHH300UamzJgxQ+6+++79brXQwVRA6HWYetimyhCVKnpw5IYNG\/aTEFu3bpVJkybJtGnTSsxTqy30ik4VGHqmxXPPPWd+XtYVnVOmTJH27dubdeu8vDeMpOakB3527tzZtFGJoP\/wr+iKznr16sn9998vbdq0MQeJpioyUhLCu3UmCGitEtFzKaiECEKNthCAAATsEUBCICHsZVf6no2EGC+y6NuoR\/Y3XqeTRfpcLlRC+MNFKwjkBQEkRIzCXPoDXv+ho4c06paGVq1amaoH\/TjWQymXLVtmhMSaNXtL9L2VELNmzTK3P3gf\/eDXSoCOHTvKkUceaT769eDF1CGQ2cSkc9UPeb02U68U1e0e06dPN0JCt0o0btzYiIdzzjlHmjZtKpUqVZKVK1eaqgnv9o3SV5TqTRcvv\/yyqZbQazYvu+wyOfXUUw2PefPmGYGhVQjlSYhu3boZ8aHVECo7VGpMnTrV\/OcOHTrI5ZdfLsccc4xUrlxZlKP2qYLDW7Gha1Jpo9Jj7ty55r0rr7zSiBdtq3PUbSn6aOWFjqlC48477zS3dAR5kBBBaNEWAhCAgH0CSAgkhP0sKzmC\/vvgpHF7HJYQleSSKyohIaJODMaDgMMEkBAOByfd1PQD\/o477jCioKxnyZIl5oPW+8HulRB+lqyVBSoqVELYeHSbhEoFrTrQD\/qyHr2Z4\/PPPzfSIiVUUm29EuLTTz81ckCrREo\/6XiUVQmh7+otGSoNatasmXZaKhn0FgxlrLIn9Wi1g17V2bZtWyNOSj+6Ft2CoZUlKiP0UVGit2mo9NFHxY+eL\/HKK6\/4wo6E8IWJRhCAAAQiI4CESI+aMyHspSASwh5beoYABOwQQELY4Wq1V\/041g\/XM844Qxo0aGA+YHVrw48\/\/ihvv\/226MGUKhG8jx8JoR\/AWinwySefmEMZvR\/Ythak8+rdu7c5rLJOnTpGSOhatKrhq6++kldffbXM6gCvhFBholsa+vXrV1w9odUL7777rughk6V5lCchdK0tWrQQPcNBJUlhYaGRCspn7dq1pmJDqyNK96nvaUWEnvugW0BSsdH3VKBohYZWfHgfbX\/bbbeZig0VKLt37w50fSkSwlZm0i8EIACBzAggIZAQmWVO5m\/tlRC7ZdE3P2feicU3O52ilRAHUAlhkTFdQyBuBJAQcYsY880KgYokRFYGiaATJEQEkBkCAhCAQAACSAgkRIB0yUpTJERWMNIJBCAQIQEkRISwGcodAikJoZUfuj1Ct3PE8UFCxDFqzBkCEEgyASQEEiLq\/DYS4q5dsuibPVEP7Wu8TqccIJdcWUAlhC9aNIJAfhBAQuRHnFnlL1sl9CwKPY9BD4Rs3bq1rFq1SoYPHy4rVqyIJSMkRCzDxqQhAIEEE0BCICGiTm+VEA+M2eGshOjcVSVEVSRE1InBeBBwmAASwuHgMLXsEjjqqKNk\/Pjx5uYMffSAyb\/97W\/mgMm4PkiIuEaOeUMAAkklgIRAQkSd20iIqIkzHgQgEJYAEiIswTx6f8KECdK1a9eMVqy3Sehhmrl89MrPYcOGmYMm9bBI\/Ye2Sgk9wDKuDxIirpFj3hCAQFIJICGQEFHntpEQo7fJom92Rz20r\/E6dy2QSwZVpxLCFy0aQSA\/CCAh8iPOWVnl4MGD5fjjj8+or+XLl8uoUaMyepeXyiaAhCA7IAABCLhFAAmBhIg6I5EQURNnPAhAICwBJERYgrwPgRwSQELkED5DQwACEEhDAAmBhIj6F0MlxP2jt8ii+UVRD+1rvM6nVpW+g2pQCeGLFo0gkB8EkBD5EWdWmVACDfhBfAAADdlJREFUSIiEBpZlQQACsSWAhEBCRJ28RkKM+sltCXFVLSRE1InBeBBwmAASwuHgMDUIVEQACVERIX4OAQhAIFoCSAgkRLQZJ+aMKyRE1NQZDwIQCEMACRGGHu9CIMcEkBA5DgDDQwACEChFAAmBhIj6l8JIiDs3yqL5u6Ie2td4nU+tJn0H16YSwhctGkEgPwggIfIjzqwyoQSQEAkNLMuCAARiSwAJgYSIOnmREFETZzwIQCAsASREWIK8D4EcEkBC5BA+Q0MAAhBIQwAJgYSI+hfDSIj\/Wi8L5++Memhf43XpVkP6Dq5DJYQvWjSCQH4QQELkR5xZZUIJICESGliWBQEIxJYAEgIJEXXy7pUQP8jCea5KiJrSd0g9JETUicF4EHCYABLC4eAwNQhURAAJUREhfg4BCEAgWgJICCREtBn3y8GUSIiosTMeBCAQggASIgQ8XoVArgkgIXIdAcaHAAQgUJIAEgIJEfXvhFZC3HfHOlk4b0fUQ\/sar0u3mtLv6gZUQviiRSMI5AcBJER+xJlVJpQAEiKhgWVZEIBAbAkgIZAQUScvEiJq4owHAQiEJYCECEuQ9yGQQwJIiBzCZ2gIQAACaQggIZAQUf9iGAlx+z9l4bztUQ\/ta7wuvymUflcfSCWEL1o0gkB+EEBC5EecWWVCCSAhEhpYlgUBCMSWABICCRF18qqEmHjbaoclRG3pP7QhEiLqxGA8CDhMAAnhcHCYGgQqIoCEqIgQP4cABCAQLQEkBBIi2ozbezAlEiJq6owHAQiEIYCECEOPdyGQYwJIiBwHgOEhAAEIlCKAhEBCRP1LsVdCrJSFX2+Lemhf43U5rY70H3pwoEqIgoIC6dOnj\/Tq1UsaNGggVapUkZ07d8qaNWvk2WeflenTp\/sam0YQgICbBJAQbsaFWUHAFwEkhC9MNIIABCAQGQEkBBIismT7ZaCkSYh69erJmDFjRP8dp6ioSNauXSsbN26URo0ayYEHHii7du2S\/\/7v\/5YHHnggatSMBwEIZIkAEiJLIOkGArkggITIBXXGhAAEIFA2ASQEEiLq3w+VEPfeukIWfr016qF9jXfiaXWl\/zWNfVdCDBw40FRBbN26VSZPnixvvPGGGUerI6699lrp0aOHqYoYO3asvPfee77mQCMIQMAtAkgIt+LBbCAQiAASIhAuGkMAAhCwTgAJgYSwnmSlBkiShFDR8Pjjj0ubNm3kr3\/9qxEN3qdu3bpGTLRs2VLeeustGTVqVNS4GQ8CEMgCASREFiDSBQRyRcA1CVFU1OSXv1asyRUSZ8dVNkVFjaV69c+dnWMuJ7Z9e3spKPheCgrIndJx4Peq7MzU3ynl49LvlUsSovUxhbLgq825\/NUuHvvE3zaQ7hdWlXPPPdeJ+SRpEkZCjFzmcCVEPek\/rKmvSohDDjnEiIemTZvKo48+Ki+99NJ+oZowYYJ07dpVPvjgA7nxxhuTFErWAoG8IYCEyJtQs9AkEnBNQmxYf5ls336cNG5ydRJxh1qTfmR\/v+ZPcvgRJ4XqJ6kvL1v6sRzU8C4pLHwzqUvMeF0\/rBtp3lU+PCUJbN7cXX5Yd6tTv1cuSYg\/\/7W93HPLIidEBBLC3m+vkRC3LJEFX2+xN0iInk\/8bX25dFhzXxKiomG8lRLvv\/++3HzzzRW9ws8hAAEHCSAhHAwKU4KAXwJICL+kct8OCVF+DJAQZfNBQpTNBglR\/u8VEiL3\/78\/ihnkk4TQ8yCGDRsmBxxwgNm28dxzz0WBmDEgAIEsE0BCZBko3UEgSgJIiChphxsLCYGEyDSDkBBIiExzBwmRKbl4vacS4v97YLkTFS\/pyOm2oEuvPSx0JUSrVq3MVo1mzZrJ4sWLZejQobJhw4Z4BYvZQgAChgASgkSAQIwJICHiEzwkBBIi02xFQiAhMs0dJESm5OL1nkqIODxdunTJeJpNmjQx13a2bdtW1q9fL3fffbfodgweCEAgngSQEPGMG7OGgCGQkhDggAAEIAABCLhOYM2aNRxMaSFI+u8CcXjmzJmT0TQPP\/xwcwuG3oixcePGEtd2ZtQhL0EAAjkngITIeQiYAATCEYjLv3yEWyVvQwACEIBAEghk+iGahLWzhuAETjjhBHMDhm7B0AqIBx54QN5+++3gHfEGBCDgFAEkhFPhYDIQgAAEIAABCEAAAhCAwBlnnCHXXnut1K9fX7SKZty4cTJ79mzAQAACCSCAhEhAEFkCBCAAAQhAAAIQgAAEkkKgW7duMmLECCMglixZInfeeacsXLgwKctjHRDIewJIiLxPAQBAAAIQgAAEIAABCEDADQK6zVQPoVQBMX\/+fLn11ltNJQQPBCCQHAJIiOTEkpVAAAIQgAAEIAABCEAgtgQKCgrMwZO\/\/vWvZdWqVXLLLbdQARHbaDJxCJRNAAlBdkAAAhCAAAQgAAEIQAACOSdw2mmnGfFQq1atCufywQcfmEMreSAAgfgRQELEL2bMGAIQgAAEIAABCEAAAokjMHjwYOnTp49UqlSpwrUhISpERAMIOEsACeFsaJgYBCAAAQhAAAIQgAAEIAABCEAgWQSQEMmKJ6uBAAQgAAEIQAACEIAABCAAAQg4SwAJ4WxomBgEIAABCEAAAhCAAAQgAAEIQCBZBJAQyYonq4EABCAAAQhAAAIQgAAEIAABCDhLAAnhbGiYGAQgAAEIQAACEIAABCAAAQhAIFkEkBDJiiergQAEIAABCEAAAhCAAAQgAAEIOEsACeFsaJgYBCAAAQhAAAIQgAAEIAABCEAgWQSQEMmKJ6uBAAQgAAEIQAACEIAABCAAAQg4SwAJ4WxomBgEIAABCEAAAhCAAAQgAAEIQCBZBJAQyYonq4EABCAAAQhAAAIQgAAEIAABCDhLAAnhbGiYGAQgAAEIQAACEIAABCAAAQhAIFkEkBDJiiergQAEIAABCEAAAhCAAAQgAAEIOEsACeFsaJgYBCAAAQhAAAIQgAAEIAABCEAgWQSQEMmKJ6uBAAQgAAEIQAACEIAABCAAAQg4SwAJ4WxomBgEIAABCEAAAhCAAAQgAAEIQCBZBJAQyYonq4EABCAAAQhAAAIQgAAEIAABCDhLAAnhbGiYGAQgAAEIQAACEIAABCAAAQhAIFkEkBDJiiergQAEIAABCEAAAhCAAAQgAAEIOEsACeFsaJgYBCAAAQhAAAIQgAAEIAABCEAgWQSQEMmKJ6uBAAQgAAEIQAACEIAABCAAAQg4SwAJ4WxomBgEIAABCEAAAhCAAAQgAAEIQCBZBJAQyYonq4EABCAAAQhAAAIQgAAEIAABCDhLAAnhbGiYGAQgAAEIQAACEIAABCAAAQhAIFkEkBDJiiergQAEIAABCEAAAhCAAAQgAAEIOEsACeFsaJgYBCAAAQhAAAIQgAAEIAABCEAgWQSQEMmKJ6uBAAQgAAEIQAACEIAABCAAAQg4SwAJ4WxomBgEIAABCEAAAhCAAAQgAAEIQCBZBJAQyYonq4EABCAAAQhAAAIQgAAEIAABCDhLAAnhbGiYGAQgAAEIQAACEIAABCAAAQhAIFkEkBDJiiergQAEIAABCEAAAhCAAAQgAAEIOEsACeFsaJgYBCAAAQhAAAIQgAAEIAABCEAgWQSQEMmKJ6uBAAQgAAEIQAACEIAABCAAAQg4SwAJ4WxomBgEIAABCEAAAhCAAAQgAAEIQCBZBJAQyYonq4EABCAAAQhAAAIQgAAEIAABCDhLAAnhbGiYGAQgAAEIQAACEIAABCAAAQhAIFkEkBDJiiergQAEIAABCEAAAhCAAAQgAAEIOEsACeFsaJgYBCAAAQhAAAIQgAAEIAABCEAgWQSQEMmKJ6uBAAQgAAEIQAACEIAABCAAAQg4SwAJ4WxomBgEIAABCEAAAhCAAAQgAAEIQCBZBJAQyYonq4EABCAAAQhAAAIQgAAEIAABCDhLAAnhbGiYGAQgAAEIQAACEIAABCAAAQhAIFkEkBDJiiergQAEIAABCEAAAhCAAAQgAAEIOEsACeFsaJgYBCAAAQhAAAIQgAAEIAABCEAgWQSQEMmKJ6uBAAQgAAEIQAACEIAABCAAAQg4SwAJ4WxomBgEIAABCEAAAhCAAAQgAAEIQCBZBJAQyYonq4EABCAAAQhAAAIQgAAEIAABCDhLAAnhbGiYGAQgAAEIQAACEIAABCAAAQhAIFkEkBDJiiergQAEIAABCEAAAhCAAAQgAAEIOEsACeFsaJgYBCAAAQhAAAIQgAAEIAABCEAgWQSQEMmKJ6uBAAQgAAEIQAACEIAABCAAAQg4SwAJ4WxomBgEIAABCEAAAhCAAAQgAAEIQCBZBJAQyYonq4EABCAAAQhAAAIQgAAEIAABCDhLAAnhbGiYGAQgAAEIQAACEIAABCAAAQhAIFkEkBDJiiergQAEIAABCEAAAhCAAAQgAAEIOEsACeFsaJgYBCAAAQhAAAIQgAAEIAABCEAgWQSQEMmKJ6uBAAQgAAEIQAACEIAABCAAAQg4SwAJ4WxomBgEIAABCEAAAhCAAAQgAAEIQCBZBJAQyYonq4EABCAAAQhAAAIQgAAEIAABCDhLAAnhbGiYGAQgAAEIQAACEIAABCAAAQhAIFkEkBDJiiergQAEIAABCEAAAhCAAAQgAAEIOEsACeFsaJgYBCAAAQhAAAIQgAAEIAABCEAgWQSQEMmKJ6uBAAQgAAEIQAACEIAABCAAAQg4S+D\/Bw5ViQrw6acwAAAAAElFTkSuQmCC","height":330,"width":549}}
%---
%[output:0d26fa3a]
%   data: {"dataType":"text","outputData":{"text":"Found solution after 1 attempt(s): 79 88 12 87 65 8 24 52 93 94 25 92 63 39 74 26 29 76 69 62 56 2 70 48 53 72 68 31 37 11 49 17 5 3 34 86 44 27 91 4 42 38 75 82 28 33 40 58 67 54 20 59 60 9 13 66 47 18 23 7 85 50 81 83 78 16 51 35 6 21 80 84 41 96 15 36 64 43 22 89 57 71 61 14 90 73 19 46 1 55 95 32 10 30 77 45\n","truncated":false}}
%---
%[output:37e3ff76]
%   data: {"dataType":"text","outputData":{"text":"Order effects table for View_x_Category:\n","truncated":false}}
%---
%[output:20a2ef1f]
%   data: {"dataType":"text","outputData":{"text":"     2     3     3     3     2     3\n     3     2     3     2     3     3\n     3     3     2     3     2     2\n     3     2     3     2     3     3\n     2     3     3     3     2     3\n     3     3     2     3     3     2\n\n","truncated":false}}
%---
%[output:10342261]
%   data: {"dataType":"image","outputData":{"dataUri":"data:image\/png;base64,iVBORw0KGgoAAAANSUhEUgAABCEAAAJ7CAYAAADdt4tVAAAAAXNSR0IArs4c6QAAIABJREFUeF7svQmYVdWVhr1qAIQqqAkqFIhBA4iYqM0fojY\/NG1aOsYOGtPBIcTwOyBCI0QREBEDQQQFAuJEaMeGGDEMMgSDgSagiQSC0SREEUUNU3CAUiikKOV\/9kkXVjHUHc757jn33vc8T56km7O\/vc+7lse7PtbZO6e0tPSwcUEAAhCAAAQgAAEIQAACEIAABCAAATGBHEwIMWHkIQABCEAAAhCAAAQgAAEIQAACEPAIYEKQCBCAAAQgAAEIQAACEIAABCAAAQikhAAmREowMwkEIAABCEAAAhCAAAQgAAEIQAACmBDkAAQgAAEIQAACEIAABCAAAQhAAAIpIYAJkRLMTAIBCEAAAhCAAAQgAAEIQAACEIAAJgQ5AAEIQAACEIAABCAAAQhAAAIQgEBKCGBCpAQzk0AAAhCAAAQgAAEIQAACEIAABCCACUEOQAACEIAABCAAAQhAAAIQgAAEIJASApgQKcHMJBCAAAQgAAEIQAACEIAABCAAAQhgQpADEIAABCAAAQhAAAIQgAAEIAABCKSEACZESjAzCQQgAAEIQAACEIAABCAAAQhAAAKYEOQABCAAAQhAAAIQgAAEIAABCEAAAikhgAmREsxMAoHMJdC\/f39z\/1m3bp2NHDkycx9U\/GQdOnSwwYMH25lnnmmFhYWWk5NjBw4csK1bt9rjjz9ua9euFa8gc+V79Ojh5ahj3LhxYzt06JB9+OGHtmLFCo9tVVVV5j58Cp+suLjYpk6dal26dLE1a9bwPkiC\/Ve\/+lWbMGGCFRUVNTj6Zz\/7mc2cOTOJGbJ7SH5+vvXr188uvvhiKy8v994H1dXVtnPnTpszZ44tXbo0uwHx9BCAAARSRAATIkWgmQYCmUigU6dONmnSJKuoqKDo8BHgvn372g033GDNmjU7ror7kbxw4UKbPn26j1myc+igQYPs8ssv94qNo6\/Dhw\/b66+\/buPGjbO33347OwEF+NSjRo2yPn36eAYaJkRyYN27wJmRx8vXuoqYEInzdSaZM3i6du3q5ejRF+\/ZxJkyAgIQgECyBDAhkiXHOAhkOQFnQEycONHatm3rkaDoSC4hunfvbrfffruVlJTY3r17bfHixfbUU095fzt30UUXeX+D37JlSzt48KD3N5\/z589PbqIsHNW7d2+79dZbvc6S999\/3x599FFbsmSJnXzyyXbddddZz549zf3NqMtdV0BzJU\/gO9\/5jg0ZMsSaNGnC+yB5jDZs2DDPNHP5+sADD9iePXuOq\/bOO+\/Yrl27fMyUfUOdYe7+mXfXX\/7yF+99umnTJvvWt75l11xzjfee3bdvn917771elxQXBCAAAQjoCGBC6NiiDIGMJdCrVy\/74Q9\/6LWz1l6YEMmFe\/z48XbhhRee8MevYz1ixAjPpHjllVds4MCByU2UhaOmTZtm559\/vmfu3HXXXfbCCy\/UozB58mSvKHGF3m233ebx5UqcQK0h2aZNG3PdJbm5uZiSiWP0RkyZMsWcMfnGG294hXFNTU2SSgyrS+CCCy6w0aNHW0FBgf3+97+3W265pR7buoYl\/y4jdyAAAQjoCWBC6BkzAwQyhoD77ML9Td15553ntQvv3r3b+2\/X5soPt8TD3Lp1a5sxY4adcsopDRoM9913n3Xr1s127Nhhw4cP9\/aJ4GqYQFlZmddhctZZZ3l\/6zl06NBjBtS2vrs\/cH\/rPG\/ePLAmSMB1kjiDx+278eabb3p7GbRq1Yr3QYIc3e2O3UMPPWSnnnoq\/JLg19CQsWPHep1lznB0\/3vDhg31bnd57N4BnTt3ttdee80z2dkrJuAgIAcBCECgDgFMCNIBAhCIm4Brt77qqqu8TwVeeukle\/rpp71Cz\/0NKCZE3BiP3PjlL3\/Z7rzzTq+jZOXKlea6Io531f6NPSZE4owbGnHFFVfYjTfe6N2CCZEc29qNaV3B5hi6v73nfZAcyzPOOMPbY8eZOG6TxAcffDA5IUbVI1DX3Fm\/fr3ddNNNEIIABCAAgZAJYEKEHACmh0A6EXAFm\/sb+ccee8w7rcH9jZ1rH6bo0EXR\/Q3d7Nmzvb+he\/fdd72\/0edbcP+8HVd3ksPXvvY1e++997wOk82bN\/sXziKF2v1M3J4brmh+\/vnneR\/4iL87scF9JuCun\/\/853bOOed4J424fTac8btlyxZOykmC79lnn213332390kbG3omAZAhEIAABAQEMCEEUJGEQLYQwITQR7rubvmuyHOtxFzJE3AnkLh9IK688krr2LGj9134okWLzO0fwRU\/gaOP43QdUe3atcOEiB\/hMXdef\/319oMf\/MA7ucHtrZGXl3fMPZzgkDhgtx+E2\/PFfTrounU2btzomblf+cpXjhg8HNGZOFdGQAACEPBDABPCDz3GQiDLCWBCaBOg7gkkbv+NO+64w1599VXtpBmsXvs5Ue0jup3wn3nmGe\/UDDYATCzwN998s1166aXevjBuwz\/XRcL7IDGGR9\/t\/rbebUTrLsf1ySeftOXLl3vFszPN3PGnzvxxJ+XMmjXLO0WHKzaBunu\/uM\/e3P4lrnvn6AuDJzZL7oAABCAQFAFMiKBIogOBLCRA0aELujMg3IZ\/7jhJio5gONfurVFXbf\/+\/bZw4UKvqMOIiI9z7UkCjRo1qlcM8z6Ij9+J7nJHRp555pn24YcfHjF26t5b96Qcd3qGM9UqKyv9TZoFo2tNCJevrsPkk08+sV\/+8pf2yCOPHDkK+eqrr\/b25uFdmwUJwSNCAAKRIIAJEYkwsAgIpCcBig5N3Go3rHQGhPvbObcBKJvU+WftPhf4+OOPjyk8Dh065HVEuCKQq2EC7p\/5e++998g+MKNGjToygPeBPnvqHunrOidWrVqlnzTNZ6j7SduJTAZ3is6Pf\/xjz4jA4EnzgLN8CEAgLQhgQqRFmFgkBKJJgKIj+Li4v+10x8PV\/q3c3LlzvY0puYIn4LpN3GkE7ujZbdu2ebvmu2\/DuY5PoO5xnO+88465TzLq8uJ9oM+cuie6uOM83QaWXA0TqGtCuM\/ZBg8efNyuJ2eoXXLJJV53yZgxY445xhPOEIAABCAQHAFMiOBYogSBrCNA0RFsyL\/3ve95Rxy6zRPdfgUPP\/ywzZ8\/P9hJUKtHoLbwcLz5m+WGk6PuP+\/xppHj6gq6devWxTuE+xogUHd\/A\/c5gds3gqthAu4Ul3HjxllBQUGDR0m7TzKuvfZa+\/TTT72Tc5YtWwZaCEAAAhAQEcCEEIFFFgLZQAATIrgoDxo0yC6\/\/HJvE7o9e\/bY9OnTbcWKFcFNgNJxCdRuVuk+e3E758+bNw9SJyCACaFNDddp4vaE+Pvf\/37CY3hrT9BwhfJ9992HSRlHSM444wyv48l1l61Zs8ZGjhx53FG1bA8cOIAhGQdXboEABCDghwAmhB96jIVAlhPAhAgmAeoaEO6zAPe3dn\/+85+DEc9Sla5du3p\/A19WVmZLlizxjo483lW7WSUt2P4ThfdB8gzPPfdcmzBhgndqQ0OFsjtK9vzzz\/eMSnfs5CuvvJL8pFk00nWVnX322Q1+dlW734Y7mcR1SP31r3\/NIkI8KgQgAIHUEsCESC1vZoNARhGg6PAfztqTBlzxsX379uPuiu9\/luxTcPs8uL8pdpt7un0LXFHhjpGse9U9bWDTpk3eHgecNpB8rvA+SJ5dUVGRtzFqx44dPYPBGWgbN26sJ+iO6bzhhhusSZMm9rvf\/c7LV674CAwYMMD69evn3bxo0SJzZs6J3gWwjY8pd0EAAhDwQwATwg89xkIgywlQdPhLgLqFhzsq8rHHHrMtW7acUNSd4vDaa69ZVVWVv4mzZLT71OK73\/2uuaP53n77bY+vO03AGT6uoOvTp48VFxd7PGfMmGGLFy\/OEjKax+R94I9r\/\/79zf3HmQzvv\/++Pf7447Z8+XLvEy23V8E3v\/lNb7+YE5kU\/mbP7NHun3O3z0OXLl2803FWrlzp7afhuh4uuugij3vLli09E9J9urF69erMBsLTQQACEAiZACZEyAFgegikMwGKDn\/Rq7trezxKbPIXD6XP73Hf2I8dO9Zcx4MzIo53sQFoYkwbupv3gT+WLl9vvfVW+8Y3vuEZD8e72C8mecbuNJw777zTTjvttOOKuOM7OY0oeb6MhAAEIJAIAUyIRGhxLwQgUI8ARYe\/hKjdFDFeFUyIeEnVv88VdW7TT1d8uOLu8OHD3ukjL7\/8snf8aUPdJ8nNmJ2jeB8EE\/fafP3iF79oTZs2PZKv7oSRBx98kGNkfWB2nSQDBw60f\/mXf\/E6H3Jzc82ZD+5zrCeeeIJTXHywZSgEIACBRAhgQiRCi3shAAEIQAACEIAABCAAAQhAAAIQSJoAJkTS6BgIAQhAAAIQgAAEIAABCEAAAhCAQCIEMCESocW9EIAABCAAAQhAAAIQgAAEIAABCCRNABMiaXQMhAAEIAABCEAAAhCAAAQgAAEIQCARApgQidDiXghAAAIQgAAEIAABCEAAAhCAAASSJoAJkTQ6BkIAAhCAAAQgAAEIQAACEIAABCCQCAFMiERocS8EIAABCEAAAhCAAAQgEDkC+fn51q9fP\/v2t7\/tHcGak5PjHcfM8baRCxULgoBhQpAEEIAABCAAAQhAAAIQgEDaEnAGxNixY61Xr17eM2zfvt0OHjxoJ598shUUFNi2bdvs9ttvt82bN6ftM7JwCGQSAUyITIomzwIBCEAAAhCAAAQgAIEsI9CnTx8bOnSo5eXl2axZs+ypp57yCLRv397Gjx9vHTt2tDVr1tjIkSOzjAyPC4FoEsCEiGZcWBUEIAABCEAAAhCAAAQgEAeBadOm2fnnn2\/r16+3m266qd6Iq6++2q699lr74IMPbPjw4fbWW2\/FocgtEICAkgAmhJIu2hCAAAQgAAEIQAACEICAjEBZWZnddddd9qUvfcnmzZtns2fPrjdX3759bfDgwXbgwAEbM2aMbdiwQbYWhCEAgfgIYELEx4m7IAABCEAAAhCAAAQgAIE0I+A+x7jwwgvtjTfesCFDhlhlZWWaPQHLhUDmEcCEyLyY8kQQgAAEIAABCEAAAhDIagKdOnXyPsM477zz7PDhw\/X2ishqMDw8BCJAABMiAkFgCRCAAAQgAAEIQAACEICAfwKnnXaaTZkyxSoqKjyx\/fv325NPPun9hwsCEIgGAUyIaMSBVUDgCIGLL744EBrO9XdnZId5sYZ\/0IcDHOr+c5gp+ZApz+H3HQkH\/vlOxT\/fO3futI0bN\/pN18B\/a5xoQUH9c7Fs2bKEn7lr167e5pSffvqplZeXm9sz4tChQ\/bcc8\/ZvffeazU1NQlrMgACEAiWACZEsDxRg4BvAg888IC5f4FyQQACEIAABCAAAUfAFeMTJkwIDMaCBQuOdAoEJioQuuyyy8wZMMle+fn5NmzYMHNHeH722WfeppVz585NVo5xEIBAQAQwIQICiQwEgiLgTIhtr1XY4qd2BSUp0\/n\/hn3RWpY3tntHvyGbI0jhX\/\/5v4KUk2l98sk\/2a6d91v7U7vL5shW4W1\/+4UVlzxqhYW\/zFYEkud+\/73braamwlpXpMc\/Y\/\/25fslHIIWPf0rhXbrxI523bdeDlpappcu79l0ehe4fx\/Mn78jcBPijC7LvfdhFK+amta27d1fmF8Twj2bMyLcb6uzzjrLXnnlFRs4cGAUH5k1QSCrCGBCZFW4edh0IIAJoYtSuvw4xoTQ5UA6FR46CsErY0IEz9QpYkJouDrVdHoXyEyIM5ZbcfFjOsg+lD0TYtszgZgQbhmjRo2ySy65xF5\/\/XXr37+\/j5UxFAIQCIIAJkQQFNGAQIAEMCEChHmUFCaEjm26KKdT4ZEuTN06MSE00cKE0HDFhDBzn2OckSEmhPuE9c4777SCggL7yU9+4n26cvQ1duxYu+iiizAhdP9IoQyBhAhgQiSEi5shoCeACaFjjAmhY5suypgQmkhhQmi4YkJouGJC\/MOE6Nz5OSsuflwH2Yey64TYvv3puDohWrdubTNmzLBTTjnFnn\/+eXOGQ92ruLjYZs6caR06dDjun\/tYJkMhAIEkCWBCJAmOYRBQEcCEUJE1w4TQsU0XZUwITaQwITRcMSE0XDEhMsuEcPF0m0\/+53\/+p+3bt88zHGq7IZo1a+Z1SfTo0cP27t1rd911l7344ou6xEIZAhCIiwAmRFyYuAkCqSOQTiZEWXljD8wHu6tTB8jHTOliQrhHdJv85ecnvyO4D0wZPRSumvA6ru5Kl5xNl40pHVP3nk2Xd6xbb7q8Z9PpXaDaE6Jz519ZcdETmpeCT1WvE2LHU3F1QripXLeD64A477zzvCM4t2\/fbgcOHPBOAHF\/VlVVZbNmzbJ58+b5XBnDIQCBIAhgQgRBEQ0IBEggnUyIAB87JVLp8uM4JTCYBAJZTCCdTIh0CxPv2eAjhgkRnyHvTsHo16+fffvb37aWLVtabm6u7d+\/3\/761796n2ts2bIl+OCgCAEIJEUAEyIpbAyCgI4AJoSOLT+OdWxRhkA6EcCE0EWL92zwbGUmxOkrrKhFdDshduz6WdydEMFTRxECEFASwIRQ0kUbAkkQwIRIAlqcQ\/hxHCcoboNAhhPAhNAFmPds8GwxIeLrhAiePIoQgICKACaEiiy6EEiSACZEkuDiGMaP4zggcQsEsoAAJoQuyLxng2crMyE6uU6IJ4NfcACKNZ+2th275tIJEQBLJCAQRQKYEFGMCmvKagKYELrw8+NYxxZlCKQTAUwIXbR4zwbPFhOCTojgswpFCIRLABMiXP7MDoFjCGBC6JKCH8c6tihDIJ0IYELoosV7Nni2KhPi9I7PW1Hz\/wl+wQEo1nz6Bdu5ew6dEAGwRAICUSSACRHFqLCmrCaACaELPz+OdWxRhkA6EcCE0EWL92zwbDEh6IQIPqtQhEC4BDAhwuXP7BCgEyKFOcCP4xTCZioIRJgAJoQuOLxng2erMyF+bUWFEe6EeO9\/6IQIPp1QhEAkCGBCRCIMLAICnxOgE0KXDfw41rFFGQLpRAATQhct3rPBs8WEoBMi+KxCEQLhEsCECJc\/s0OATogU5gA\/jlMIm6kgEGECmBC64PCeDZ6tzITo8GsrKpgT\/IIDUPT2hPjgSTohAmCJBASiSAATIopRYU1ZTYBOCF34+XGsY4syBNKJACaELlq8Z4NniwlBJ0TwWYUiBMIlgAkRLn9mhwCdECnMAX4cpxA2U0EgwgQwIXTB4T0bPFtMCEyI4LMKRQiESwATIlz+zA4BTIgU5gA\/jlMIm6kgEGECmBC64PCeDZ6tzIT40kprEeHPMXZ9+ASfYwSfTihCIBIEMCEiEQYWAYHPCfA5hi4b+HGsY4syBNKJACaELlq8Z4NniwlBJ0TwWYUiBMIlgAkRLn9mhwCdECnMAX4cpxA2U0EgwgQwIXTB4T0bPFuZCXHaSmvRbG7wCw5AseazL9iuPY\/TCREASyQgEEUCmBBRjAprymoCdELows+PYx1blCGQTgQwIXTR4j0bPFtMCDohgs8qFCEQLgFMiHD5MzsE6IRIYQ7w4ziFsJkKAhEmgAmhCw7v2eDZ6kyIVdaiaYQ7IfY+RidE8OmEIgQiQQATIhJhYBEQ+JwAnRC6bODHsY4tyhBIJwKYELpo8Z4Nni0mBJ0QwWcVihAIlwAmRLj8mR0CdEKkMAf4cZxC2EwFgQgTwITQBYf3bPBsZSbEqausxUk\/C37BASh6e0J89CidEAGwRAICUSSACRHFqLCmrCZAJ4Qu\/Pw41rFFGQLpRAATQhct3rPBs8WEoBMi+KxCEQLhEsCECJc\/s0OATogU5gA\/jlMIm6kgEGECmBC64PCeDZ6tzIRo\/78R7oQot10f0wkRfDahCIFoEMCEiEYcWAUEjhCgE0KXDPw41rFFGQLpRAATQhct3rPBs8WEoBMi+KxCEQLhEsCECJc\/s0OATogU5gA\/jlMIm6kgEGECmBC64PCeDZ6tzIT44v9aiyZPBb\/gABRrPiu3XfsfYU+IAFgiAYEoEsCEiGJUWFNWE6ATQhd+fhzr2KIMgXQigAmhixbv2eDZYkLQCRF8VqEIgXAJYEKEy5\/ZIUAnRApzgB\/HKYTNVBCIMAFMCF1weM8Gz1ZqQjSOcCdEFZ0QwWcTihCIBgFMiGjEgVVA4AgBOiF0ycCPYx1blCGQTgQwIXTR4j0bPFtMCDohgs8qFCEQLgFMiHD5M3uGEujfv7+5\/6xbt85GjhyZ0FNiQiSEK6Gb+XGcEC5uhkDGEsCE0IWW92zwbGUmxCmrrUWjiHZCHC63XQf+mz0hgk8nFCEQCQKYEJEIA4vIJAKdOnWySZMmWUVFha1ZswYTIkLB5cdxhILBUiAQIgFMCB183rPBs8WEoBMi+KxCEQLhEsCECJc\/s2cYAWdATJw40dq2bes9GSZEtALMj+NoxYPVQCAsApgQOvK8Z4NnKzMh2q22Fvk\/D37BASjWuE6Ig7PphAiAJRIQiCIBTIgoRoU1pSWBXr162Q9\/+EMrLy8\/sn5MiGiFkh\/H0YoHq4FAWAQwIXTkec8GzxYTgk6I4LMKRQiESwATIlz+zJ4BBNxnF8OGDbPzzjvPGjdubLt37\/b+u7i4mE6IiMWXH8cRCwjLgUBIBDAhdOB5zwbPVmZCnLzaiiLcCbGzmk6I4LMJRQhEgwAmRDTiwCrSmMCQIUPsqquusurqanvppZfs6aeftttvv93atGmDCRGxuPLjOGIBYTkQCIkAJoQOPO\/Z4NliQtAJEXxWoQiBcAlgQoTLn9kzgMCNN95o3bp1s8cee8zWrl1rp556qk2ZMgUTIoKx5cdxBIPCkiAQAgFMCB103rPBs5WZEG1\/Y0V50d0TYmfNT9kTIvh0QhECkSCACRGJMLCITCKACRHdaPLjOLqxYWUQSCUBTAgdbd6zwbPFhKATIvisQhEC4RLAhAiXP7NnIAFMiOgGlR\/H0Y0NK4NAKglgQuho854Nnq3KhOjsOiFynw5+wQEoutMxdnw6i06IAFgiAYEoEsCEiGJUWFNaEwjChDiwp70t\/ll95\/+D3dVpzSUKi+fHcRSiwBogED4BTAhdDHjP+mNbU1NxjMD7791u8+fvsAkTJvgTrzN6wYIFhgkRGE6EIACBBAlgQiQIjNshEItAECZE165dj5nm9T\/ts3tHvxFrev68AQL8OCY9IAABRwATQpcHvGf9sd32t1\/Y8YyIZcuWBW9CtPmNFeVEtBPCym3HZ4l1QuTn51u\/fv3s0ksvtdLSUmvUqJG3afjOnTttzpw5tnTp0oSC06NHD+vfv7916NDBO\/XMab322mv26KOP2rp16xLS4mYIQKA+AUwIMgICARMIwoQ4XieEWybdEP6CxY9jf\/wYDYFMIYAJoYsk71l\/bFPaCZFBJoQ7Ft11iri\/xKmpqfGOS6+srLTy8nIrKyuzQ4cO2cKFC2369OlxBejKK6+0G264wZo0aWL79++3bdu2WfPmza1169b2ySef2KxZs2zevHlxaXETBCBwLAFMCLICAgETCMKE2PZahS1+alfAK0OOH8fkAAQg4AhgQujygPds8Gxle0JUrLFii24nxHZ7OO49IQYMGOB1QVRVVdnMmTPNdY64y3VHDBs2zPr06eN1MkycONFWrVrVYJCckeEMDWdsbNy40caMGWN79+71xrg5rrvuOm+eu+66y1588cXgA44iBLKAACZEFgSZR0wtAUyI1PJOZDZ+HCdCi3shkLkEMCF0seU9GzxbTIiGT8dwRsPs2bOtc+fOtmTJEs9oqHsVFRV5xkTHjh1t+fLlNn78+AaDNGrUKLvkkku8boo77rjDXn311Xr3T5s2zc4\/\/3x7\/vnnbezYscEHHEUIZAEBTIgsCDKPmFoCmBCp5Z3IbPw4ToQW90IgcwlgQuhiy3s2eLYqE+KM1q4TIpqfFNRYuW3LeSiuToh27dp5xkObNm1O+JnE5MmTrWfPnrZmzRobOXJkg0F65JFHrEuXLl6Xw\/Dhw4+59+qrr7Zrr73Wdu3aZUOHDvX+mwsCEEiMACZEYry4GwIxCWBCxEQU2g38OA4NPRNDIFIEMCF04eA9GzxbTIiGOyFiEa\/bKbF69Wq77bbbGhzy+OOP2+mnn24\/+9nPvA6Ko6++ffva4MGD7cCBA96nGhs2bIi1BP4cAhA4igAmBCkBgYAJYEIEDDRAOX4cBwgTKQikMQFMCF3weM8Gz1ZmQnxhrRUfjmonRCvblhdfJ0Qs4m4\/CNexkJeX5322MXfu3LhMiBN9unHFFVfYjTfe6G12eeedd7IvRKwA8OcQOA4BTAjSAgIBE8CECBhogHL8OA4QJlIQSGMCmBC64PGeDZ4tJkTynRCdOnXyPtVo27atbdmyxYYMGXJkk8kTRcrt83DRRRed8H63p8SFF17obXT5wAMPcEpG8CmPYhYQwITIgiDziKklgAmRWt6JzMaP40RocS8EMpcAJoQutrxng2erNCFKPnsm+AUnqPhJzpn2cU6vY0bty+0V154QJ5quoqLCO+XC7e+wZ88eu+eee8x9jhHruuCCC2z06NHWuHFjbw8JZ2K40zDcVXs6hju6ExMiFkn+HAInJoAJQXZAIGIEnKvOEZ2aoPDjWMMVVQikGwFMCF3EeM8GzzbTTYgaa2Xv5Q2uB85tTFmT0yppE6J9+\/beKRjuRIzKysp6x3bGEyF3rOe3v\/1tz4hwx3Pu3LnT3CkbrVu3trfeesv7302bNrW777475pGf8czHPRDINgKYENkWcZ438gQwIXQh4sexji3KEEgnApgQumjxng2ercqE6FK+1ko+Db8T4njEnAHxbqMHkzIhunXr5p2A4T7BcB0Q06dPtxUrViQcmP\/4j\/+w73\/\/++Y6Ktzmls6MWLlypb300kv2ox\/9yNNzG1OuW7cuYW0GQCDbCWBCZHsG8PyRI4AJoQsJP451bFGGQDoRwIS4qzEkAAAgAElEQVTQRYv3bPBsMSHi3xOid+\/e5roYSkpKvO4F16mwfv36QINy8cUX2y233OKZEu4IT9cZwQUBCCRGABMiMV7cDQE5AUwIHWJ+HOvYogyBdCKACaGLFu\/Z4NnKTIhWL0S7E6LxAwl1QvTq1ctGjBjhGRDOGBg3bpxt3rw58IA44+Gyyy6zV1991QYOHBi4PoIQyAYCmBDZEGWeMa0IYELowsWPYx1blCGQTgQwIXTR4j0bPFtMiNidEF27dvU2oXQGxKZNm7zPJFwnRDLX9ddf721A6YwM979ramqOyLhPM6ZNm2bt2rWzOXPm2MMPP5zMFIyBQNYTwITI+hQAQNQIYELoIsKPYx1blCGQTgQwIXTR4j0bPFuZCdHyBSut+UXwCw5A0e0J8c5J98fVCeH2a5g5c6adc845tn37du9kCz8dELWnYzjdWbNm2VNPPeU9UbNmzezOO++0Hj162DvvvGM333xz0kZHAIiQgEBaE8CESOvwsfhMJIAJoYsqP451bFGGQDoRwITQRYv3bPBsMSEa7mioNQ0KCgpiwndHbrpNK9117rnnet0T7gQM99tr3rx5R8a7\/\/+\/\/uu\/2qeffuoZGwcOHPA2qCwuLk7ouM+YC+IGCGQpAUyILA08jx1dApgQutjw41jHFmUIpBMBTAhdtHjPBs9WZUKcWfailR6KZifEIdcJ0WxmXJ0QgwYN8j6fyMnJiQk\/XhPCdUE4TXdMZ8uWLS03N9f2799vf\/jDH2z27Nm2ZcuWmHNxAwQgcGICmBBkBwQiRgATQhcQfhzr2KIMgXQigAmhixbv2eDZYkIkt7dD8JFAEQIQCIoAJkRQJNGBQEAEMCECAnkcGX4c69iiDIF0IoAJoYsW79ng2UpNiOoId0IUxNcJETxxFCEAATUBTAg1YfQhkCABTIgEgSVwOz+OE4DFrRDIYAKYELrg8p4Nni0mBJ0QwWcVihAIlwAmRLj8mR0CxxDAhNAlBT+OdWxRhkA6EcCE0EWL92zwbGUmROmLVnpwfvALDkDxUG4re6fwvrj2hAhgOiQgAIEUE8CESDFwpoNALAKYELEIJf\/n\/DhOnh0jIZBJBDAhdNHkPRs8W0wIOiGCzyoUIRAuAUyIcPkzOwSOIYAJoUsKfhzr2KIMgXQigAmhixbv2eDZykyIkt9aWYQ7Id5uPoNOiODTCUUIRIIAJkQkwsAiIPA5AUwIXTbw41jHFmUIpBMBTAhdtHjPBs8WE4JOiOCzCkUIhEsAEyJc\/swOATohUpgD\/DhOIWymgkCECWBC6ILDezZ4tjITovi3VvbJguAXHICi2xPi7aLpdEIEwBIJCESRACZEFKPCmrKaAJ0QuvDz41jHFmUIpBMBTAhdtHjPBs8WE4JOiOCzCkUIhEsAEyJc\/swOATohUpgD\/DhOIWymgkCECWBC6ILDezZ4tjoT4ndWdiCqnRAt7e1iOiGCzyYUIRANApgQ0YgDq4DAEQJ0QuiSgR\/HOrYoQyCdCGBC6KLFezZ4tpgQdEIEn1UoQiBcApgQ4fJndgjQCZHCHODHcQphMxUEIkwAE0IXHN6zwbOVmRBFL1lZ1cLgFxyA4qHclvZ26TT2hAiAJRIQiCIBTIgoRoU1ZTUBOiF04efHsY4tyhBIJwKYELpo8Z4Nni0mBJ0QwWcVihAIlwAmRLj8mR0CdEKkMAf4cZxC2EwFgQgTwITQBYf3bPBsZSZEC9cJsSj4BQegeCjPdUJMpRMiAJZIQCCKBDAhohgV1pTVBOiE0IWfH8c6tihDIJ0IYELoosV7Nni2mBB0QgSfVShCIFwCmBDh8md2CNAJkcIc4MdxCmEzFQQiTAATQhcc3rPBs5WZEM3XWdn+CHdCtJxCJ0Tw6YQiBCJBABMiEmFgERD4nACdELps4Mexji3KEEgnApgQumjxng2eLSYEnRDBZxWKEAiXACZEuPyZHQJ0QqQwB\/hxnELYTAWBCBPAhNAFh\/ds8GylJsS+Z4NfcACK3p4Qre6lEyIAlkhAIIoEMCGiGBXWlNUE6ITQhZ8fxzq2KEMgnQhgQuiixXs2eLaYEHRCBJ9VKEIgXAKYEOHyZ3YI0AmRwhzgx3EKYTMVBCJMABNCFxzes8GzlZkQhb+3sih3QpTfQydE8OmEIgQiQQATIhJhYBEQ+JwAnRC6bODHsY4tyhBIJwKYELpo8Z4Nni0mBJ0QwWcVihAIlwAmRLj8mR0CdEKkMAf4cZxC2EwFgQgTwITQBYf3bPBsZSZEwe+t7OPFwS84AEVvT4jWk+mECIAlEhCIIgFMiChGhTVlNQE6IXTh58exji3KEEgnApgQumjxng2eLSYEnRDBZxWKEAiXACZEuPyZHQJ0QqQwB\/hxnELYTAWBCBPAhNAFh\/ds8Gx1JsR6K\/soqp0QZfZ2BZ0QwWcTihCIBgFMiGjEgVVA4AgBOiF0ycCPYx1blCGQTgQwIXTR4j0bPFtMCDohgs8qFCEQLgFMiHD5MzsE6IRIYQ7w4ziFsJkKAhEmgAmhCw7v2eDZqkyILs3WW+lHS4JfcACKNfll9k7FJPaECIAlEhCIIgFMiChGhTVlNQE6IXTh58exji3KEEgnApgQumjxng2eLSYEnRDBZxWKEAiXACZEuPyZHQLH7YS44IKXrbjkUegETIDCI2CgdeQoPDRsyVkNV\/JVwxVVDQGlCVFSGd1OiHfb0AmhyShUIRA+AUyI8GPACiBQj4DrhMCE0CQFBZ2Gq1OlqNOwJWc1XMlXDVdUNQQwIeiE0GQWqhAIjwAmRHjsmRkCxyWACaFLDAo6HVuKOg1bclbDlXzVcEVVQ0BlQpzRdL0VR7gTYltbOiE0GYUqBMIngAkRfgxYAQTohEhRDlDQ6UBT1GnYkrMaruSrhiuqGgKYEHRCaDILVQiERwATIjz2zAwBOiFSnAMUdDrgFHUatuSshiv5quGKqoaAyoTo3HS9FVUu1izap6o7HWNH28mcjuGTI8MhEFUCmBBRjQzryloCfI6hCz0FnY4tRZ2GLTmr4Uq+ariiqiGACUEnhCazUIVAeAQwIcJjz8wQoBMixTlAQacDTlGnYUvOariSrxquqGoIqEyI05v+3lpUPqtZtE\/VmvyWtqvtPXRC+OTIcAhElQAmRFQjw7qylgCdELrQU9Dp2FLUadiSsxqu5KuGK6oaApgQdEJoMgtVCIRHABMiPPbMDAE6IVKcAxR0OuAUdRq25KyGK\/mq4YqqhoDKhOjUdJ01r1ykWbRP1U\/zW9rf205JqBMiPz\/f+vXrZ5deeqmVlpZao0aNrLq62nbu3Glz5syxpUuXJrSqDh062NChQ+0rX\/mKNWnSxA4dOuRp\/c\/\/\/E\/CWglNzM0QyAICmBBZEGQeMb0I0AmhixcFnY4tRZ2GLTmr4Uq+ariiqiGACRG7E6K4uNgmTJhgXbt2tZqaGtu9e7dVVlZaeXm5lZWVeQbCwoULbfr06XEFqVevXjZixAgrKSmxvXv3euZDUVGRtW7d2j799FNbtGiRTZs2LS4tboIABI4lgAlBVkAgYgQwIXQBoaDTsaWo07AlZzVcyVcNV1Q1BFQmRMemL1lh5ULNon2quk6I99pOi7sTYsCAAV4XRFVVlc2cOdOWLVvmrcB1RwwbNsz69OnjdUVMnDjRVq1a1eDqnNngNDp27GibNm2yW265xTMi3HXzzTd7nRbxavnEwHAIZCwBTIiMDS0Plq4EMCF0kaOg07GlqNOwJWc1XMlXDVdUNQQwIRruhHBGw+zZs61z5862ZMkSz2ioe9U1FZYvX27jx49vMFBf\/epXva6Kxo0b29SpU48YGm6Q64SYMWOGnXLKKfb000\/H3VmhyQxUIZC+BDAh0jd2rDxDCWBC6AJLQadjS1GnYUvOariSrxquqGoIqEyIDk1\/ZwWVCzSL9qnqOiE+aDs9rk6Idu3aecZDmzZtbNasWTZv3rxjZp88ebL17NnT1qxZYyNHjmxwdeeee65nQrhrzJgxtm7dunr3P\/7443b66afb6tWr7bbbbvP5pAyHQHYSwITIzrjz1BEmgAmhCw4FnY4tRZ2GLTmr4Uq+ariiqiGACRF7T4iGyNftlIjHODjjjDNs0qRJ5vaZePLJJ+2RRx45In\/WWWfZj3\/8Y2+fiSeeeMLrwOCCAAQSJ4AJkTgzRkBASgATQoeXgk7HlqJOw5ac1XAlXzVcUdUQUJkQpzV90ZpVztcs2qfqZ\/mtbE\/b++LqhIg1ldsPwp1ykZeX55kGc+fOjTXkyN4Pbo8JN+bZZ5+1Ll262PDhw729It5++23vHrdhJRcEIJA4AUyIxJkxAgJSApgQOrwUdDq2FHUatuSshiv5quGKqoYAJkTyhX6nTp28TzXatm1rW7ZssSFDhhzZZLKhaLnuiWuuucb69u1rBQUFR2797LPPbMOGDV6nBAaEJt9RzQ4CmBDZEWeeMo0IYELogkVBp2NLUadhS85quJKvGq6oagioTIhTm75gTSt\/oVl0Aqo1J3Wx\/WWDjhnhuiEuu+yypIv9iooKb28H18GwZ88eu+eee7x9HOK5+vfvb5dffrl3LKc7GWPXrl3WokUL78jPw4cP29q1az1zw3VKcEEAAokTwIRInBkjICAlgAmhw0tBp2NLUadhS85quJKvGq6oaghkugnhqFUX\/ks9eJ\/mtbJPir+btAnRvn177xQM9+lEZWVlvWM7Y0Wp9vONRo0a2eLFi70TMGpqarxhvXv39o78dPtF\/OpXv7Jx48bFkuPPIQCB4xDAhCAtIBAxApgQuoBQ0OnYUtRp2JKzGq7kq4YrqhoCKhOifbO1dlLlM5pF+1R1XRAft3kwKROiW7du3gkY7hMM1wHhTIQVK1bEvaJp06bZ+eefb6+++qoNHjz4iAFRKzBw4EDr16+fffjhh94eEZs3b45bmxshAIF\/EMCEIBMgEDECmBC6gFDQ6dhS1GnYkrMaruSrhiuqGgKYEPHvCVHbqVBSUuJ9xnH33Xfb+vXrEwpM7RGcTz\/9tGdgHH3VHuHpNrqcOnWqLVu2LCF9boYABDAhyAEIRI4AJoQuJBR0OrYUdRq25KyGK\/mq4YqqhoDKhPhis7XWpHKeZtE+VV0nxP42DyXUCdGrVy8bMWKEOQPirbfe8j6VSKZLodaEcCdiuA0oMSF8BpPhEDgOATohSAsIRIwAJoQuIBR0OrYUdRq25KyGK\/mq4YqqhgAmROxOiK5du3qbUDoDYtOmTTZmzJikN7ScPHmy9ezZ09544w3vNA23p0Td69prr7Wrr77a27By1KhR9te\/\/lUTeFQhkMEEMCEyOLg8WnoSwITQxY2CTseWok7DlpzVcCVfNVxR1RBQmRCnNFtjjT56WrNon6qH88vtQMXDcXVCuOM0Z86caeecc45t377dRo8enVQHRO2S3Scdt956qzVp0sSee+4571QNNqb0GVCGQ+AoApgQpAQEIkYAE0IXEAo6HVuKOg1bclbDlXzVcEVVQwATouFOiAsuuMAzHgoKCmIGYM2aNd6mle6q3duhcePG5n57zZv3+acpgwYN8o7odH\/mOh7c\/hJNmzb1Nrt0pofrtnCbUro\/44IABBIngAmRODNGQEBKABNCh5eCTseWok7DlpzVcCVfNVxR1RBQmRDtmv3G8iPcCXGwYlZcnRDOMHCnVeTk5MQMQLwmhBPq0aOH9e\/f3zp06OCZEYcOHfJOxHAnbbh9I6qqqmLOxw0QgMDxCWBCkBkQiBgBTAhdQCjodGwp6jRsyVkNV\/JVwxVVDQFMiNh7QmjIowoBCKgIYEKoyKILgSQJYEIkCS6OYRR0cUBK8haKuiTBxRhGzmq4kq8arqhqCKhMiLbNfmN5H\/1cs2ifqm5PiJqKn8bVCeFzKoZDAAIhEMCECAE6U0KgIQKYELr8oKDTsaWo07AlZzVcyVcNV1Q1BDAh6ITQZBaqEAiPACZEeOyZGQLHJYAJoUsMCjodW4o6DVtyVsOVfNVwRVVDQGVCtClYbTkR7YSwvHL7rGI2nRCalEIVAqETwIQIPQQsAAL1CWBC6DKCgk7HlqJOw5ac1XAlXzVcUdUQwISgE0KTWahCIDwCmBDhsWdmCNAJkeIcoKDTAaeo07AlZzVcyVcNV1Q1BDAhMCE0mYUqBMIjgAkRHntmhgAmRIpzgIJOB5yiTsOWnNVwJV81XFHVEFCZEBUFq80+jubGlO5zDGvN5xiajEIVAuETwIQIPwasIAMIuDOkBw8ebGeeeaYVFhZ6Z1UfOHDAtm7d6p0lvXbt2rifks8x4kaV8I0UdAkji3sARV3cqBK6kZxNCFfcN5OvcaPixggQwISgEyICacgSIBAoAUyIQHEilo0E+vbtazfccIM1a9bsuI9fXV1tCxcutOnTp8eFBxMiLkxJ3URBlxS2uAZR1MWFKeGbyNmEkcU1gHyNCxM3RYSAyoT4QsFqO\/zxUxF5yqOWkVduea3\/m40poxkdVgUB3wQwIXwjRCCbCXTv3t1uv\/12Kykpsb1799rixYvtqaeeMmc8XHTRRda\/f39r2bKlHTx40GbOnGnz58+PiQsTIiaipG+goEsaXcyBFHUxESV1AzmbFLaYg8jXmIi4IUIEMCHohIhQOrIUCARCABMiEIyIZCuB8ePH24UXXmj79u2ze++911asWFEPRa9evWzEiBGeSfHKK6\/YwIEDY6LChIiJKOkbKOiSRhdzIEVdTERJ3UDOJoUt5iDyNSYibogQAZUJUV642j6NaCdETl65NfoCnRARSkOWAoFACWBCBIoTsWwi0Lp1a5sxY4adcsopDRoM9913n3Xr1s127Nhhw4cP9\/aJaOjChNBlEQWdji1FnYYtOavhSr5quKKqIYAJQSeEJrNQhUB4BDAhwmPPzGlO4Mtf\/rLdeeedVl5ebitXrjTXFXG8a\/LkydazZ09MiAjEm4JOFwSKOg1bclbDlXzVcEVVQ0BlQrQsXG01Ee6EOIlOCE1CoQqBCBDAhIhAEFhC5hLIz8+32bNnW+fOne3dd9+1oUOH2q5du+iECCnkFHQ68BR1GrbkrIYr+arhiqqGACYEnRCazEIVAuERwIQIjz0zZwEBd3KGO7qzcePG9vzzz9vYsWNjPjWfY8RElPQNFHRJo4s5kKIuJqKkbiBnk8IWcxD5GhMRN0SIgMqEKCtcbYf2RfN0DLcnRLNy9oSIUBqyFAgESgATIlCciEHgcwKdOnWyiRMnWtu2bW337t12xx132KuvvhoTESZETERJ30BBlzS6mAMp6mIiSuoGcjYpbDEHka8xEXFDhAhgQtAJEaF0ZCkQCIQAJkQgGBGBQH0CzoC466677OSTT\/aO55w1a5Z3dGc8FyZEPJSSu4eCLjlu8YyiqIuHUuL3kLOJM4tnBPkaDyXuiQoBlQlR2ny1Hdz386g8Zr115OaVW2Gr2XbZZZfZzp2YEJEMEouCgA8CmBA+4DEUAscjULthpTMgqqur7emnn7YHH3wwbljOhPja1yosP7\/+3hEnnbTRiksejVuHG48lQEGnywqKOg1bclbDlXzVcEXVP4H337vdamoq6gnV1LS2Z5\/daBMmTPA\/wf8pLFiwwDAhAsOJEAQgkCABTIgEgXE7BBoi0KtXL\/vhD3\/onZjhOiDmzp3rbUyZyOVMiH\/+5xxzpkPdK7\/RLiss\/GUiUtx7FAEKOl1KUNRp2JKzGq7kq4Yrqv4J7N1zzTEi+\/Z9U2JCFDf\/jX0S4U6IolY\/pRPCf0qhAIFIEsCEiGRYWFQ6Evje975n11xzjTVr1sz27dtnDz\/8sM2fPz\/hR+FzjISRxT2Agi5uVAnfSFGXMLK4BpCzcWFK+CbyNWFkDAiRgOpzDEyIEIPK1BDIcgKYEFmeADx+MAQGDRpkl19+uXcKxp49e2z69Om2YsWKpMQxIZLCFtcgCrq4MCV1E0VdUthiDiJnYyJK6gbyNSlsDAqJgMqEKGr+G6va\/3RIT9XwtG5PiNKWs+iEiGR0WBQE\/BPAhPDPEIUsJ1DXgNi2bZuNGzfO\/vznPydNBRMiaXQxB1LQxUSU9A0UdUmja3AgOavhSr5quKKqIYAJwcaUmsxCFQLhEcCECI89M2cAgd69e9utt95qhYWFtn37dhs9erRt3rzZ15NhQvjCR0Gnw9egMkWdBjwmhIYr+arhiqqGgMqEaN5ije3fP0+zaJ+qeXnl1rLsITohfHJkOASiSgATIqqRYV2RJ1BUVGQzZ860jh072v79++2xxx6zLVu2nHDdhw4dstdee82qqqoafDZMCF3oKeh0bCnqNGzJWQ1X8lXDFVUNAUwIOiE0mYUqBMIjgAkRHntmTnMCffv2tcGDB3v7QMRzuc0qx4wZY+vWrcOEiAeY4B4KOgHU\/5OkqNOwJWc1XMlXDVdUNQRUJkRBi7X2cWQ7IVpZazohNAmFKgQiQAATIgJBYAnpSWDIkCF21VVXxb14TIi4UclupKCToTWKOg1bclbDlXzVcEVVQwATgk4ITWahCoHwCGBChMeemSFwXAJ8jqFLDAo6HVuKOg1bclbDlXzVcEVVQ0BlQjRr8YJVVj2jWbRP1fy8Vtam9AH2hPDJkeEQiCoBTIioRoZ1ZS0BTAhd6CnodGwp6jRsyVkNV\/JVwxVVDQFMCDohNJmFKgTCI4AJER57ZoYAnRApzgEKOh1wijoNW3JWw5V81XBFVUNAZUKc1OJF21v1C82ifaq6Toh2pTPphPDJkeEQiCoBTIioRoZ1ZS0BOiF0oaeg07GlqNOwJWc1XMlXDVdUNQQwIeiE0GQWqhAIjwAmRHjsmRkCdEKkOAco6HTAKeo0bMlZDVfyVcMVVQ0BlQnRpOi39mHVfM2ifarm57ay9qUz6ITwyZHhEIgqAUyIqEaGdWUtATohdKGnoNOxpajTsCVnNVzJVw1XVDUEMCHohNBkFqoQCI8AJkR47JkZAnRCpDgHKOh0wCnqNGzJWQ1X8lXDFVUNAZUJ0ajod\/bBgQWaRftUbZTb0k4rmU4nhE+ODIdAVAlgQkQ1MqwrawnQCaELPQWdji1FnYYtOavhSr5quKKqIYAJQSeEJrNQhUB4BDAhwmPPzBCgEyLFOUBBpwNOUadhS85quJKvGq6oagioTIi8opfsvQMLNYv2qeo6ITqVTEuoEyI\/P9\/69etnl156qZWWllqjRo2surradu7caXPmzLGlS5fGtarJkydbz549Y97rtN1fHM2bNy\/mvdwAAQjUJ4AJQUZAIGIE6ITQBYSCTseWok7DlpzVcCVfNVxR1RDAhIjdCVFcXGwTJkywrl27Wk1Nje3evdsqKyutvLzcysrK7NChQ7Zw4UKbPn16zCDFa0Ls37\/fpkyZYs8991xMTW6AAAQwIcgBCESaACaELjwUdDq2FHUatuSshiv5quGKqoaAyoTILV5nfz+wSLNon6qNc1ta5+IpcXdCDBgwwOuCqKqqspkzZ9qyZcu8FbjuiGHDhlmfPn28roiJEyfaqlWrkl7dWWedZT\/+8Y+tpKTEFi1aZNOmTUtai4EQyGYCdEJkc\/R59kgSwITQhYWCTseWok7DlpzVcCVfNVxR1RDAhGi4E8IZDbNnz7bOnTvbkiVLPKOh7lVUVOQZEx07drTly5fb+PHjkwqU05k6daqdeeaZ9sc\/\/tGGDBnidV1wQQACiRPAhEicGSMgICWACaHDS0GnY0tRp2FLzmq4kq8arqhqCKhMCCv+ve088Kxm0T5VXSfEl4vviasTol27dp7x0KZNG5s1a9Zx92io\/cRizZo1NnLkyKRWV9ttsW\/fPhszZoxt3LgxKR0GQQACZpgQZAEEIkYAE0IXEAo6HVuKOg1bclbDlXzVcEVVQwATIvaeEA2Rr9spsXr1arvtttsSDlTtZxitWrWyxYsX26RJkxLWYAAEIPA5AUwIsgECESOACaELCAWdji1FnYYtOavhSr5quKKqIaAyIT4rXm87PlmiWbRP1Sa5ZXZW0aS4OiFiTeX2gxg6dKjl5eV5n23MnTs31pBj\/nzUqFHevhLupI3hw4fb1q1bE9ZgAAQggAlBDkAgsgQwIXShoaDTsaWo07AlZzVcyVcNV1Q1BDAhku+E6NSpk\/epRtu2bW3Lli3ePg579+5NKFBOw52C0bJlS1uwYIH3v7kgAAF\/BOiE8MeP0RAInAAmROBIjwhS0OnYUtRp2JKzGq7kq4YrqhoCKhPi0+INtu2TpZpFJ6Dquh6Od\/1T0URfnRAVFRXesZ1dunSxPXv22D333GPuc4xEr4EDB3onb3z44YdeF8TmzZsTleB+CEDgKAKYEKQEBCJGABNCFxAKOh1bijoNW3JWw5V81XBFVUMg002IFvmdrEvzW44L77LLLvM+gUj0at++vXcKhjsRo7Kyst6xnYlo1T1Z4\/nnn7exY8cmMpx7IQCBExDAhCA1IBAxApgQuoBQ0OnYUtRp2JKzGq7kq4YrqhoCKhPiUMlGe\/eTZZpFJ6h6dDfESbml9pXCHybVCdGtWzfvBAz3CYbrgJg+fbqtWLEiwRX94\/YLLrjA28iyUaNGNm3aNG9TSi4IQMA\/AUwI\/wxRgECgBDAhAsVZT4yCTseWok7DlpzVcCVfNVxR1RDIBhPiaHLOlOjW4scJmxC9e\/e2YcOGWUlJiddBcffdd9v69euTDozbQ+LKK6+07du320033ZRUV0bSkzMQAhlMABMig4PLo6UnAUwIXdwo6HRsKeo0bMlZDVfyVcMVVQ0BlQlxsORle+eT5ZpF+1R1nRDnthiXkAnRq1cvGzFihGdAvPXWWzZu3Djf+zc8\/PDDdvbZZ9uaNWu87gouCEAgGAKYEMFwRAUCgRHAhAgM5TFCFHQ6thR1GrbkrIYr+arhiqqGACZE7D0hunbt6m1C6QyITZs22ZgxY3x3LZx22mneSRjl5eX2xBNPeMd7ckEAAsEQwIQIhiMqEAiMACZEYCgxIXQoj1GmqNPAxoTQcPCGX3oAACAASURBVCVfNVxR1RBQmRAHSv5oWw8+p1m0T1XXCdG9+Z1xdULk5+d7G0+ec8453mcTo0eP9t0B4ZbfvXt3r5siNzfXpk6dasuWRWP\/DJ9oGQ6BSBDAhIhEGFgEBD4ngAmhywYKOh1bijoNW3JWw5V81XBFVUMAE6LhTgi3eaQzHgoKCmIGoO5nFeeee67XPdG4cWNzv73mzZtXb3zfvn1t8ODBduDAAa+zYsOGDTH1uQECEIiPACZEfJy4CwIpI4AJoUNNQadjS1GnYUvOariSrxquqGoIqEyIqpJX7c2Dv9Is2qdq09xS69F8TFydEIMGDbJ+\/fpZTk5OzFkTMSGuv\/56+8EPfmB\/\/\/vfbfjw4bZ169aY+twAAQjERwATIj5O3AWBlBHAhNChpqDTsaWo07AlZzVcyVcNV1Q1BDAhYu8JoSGPKgQgoCKACaEiiy4EkiSACZEkuDiGUdDFASnJWyjqkgQXYxg5q+FKvmq4oqohoDIh9pX+yd44+Lxm0T5Vm+aW2L8Wjo6rE8LnVAyHAARCIIAJEQJ0poRAQwQwIXT5QUGnY0tRp2FLzmq4kq8arqhqCGBC0AmhySxUIRAeAUyI8NgzMwSOSwATQpcYFHQ6thR1GrbkrIYr+arhiqqGgMqE+Kj0L\/b6wV9rFu1TtVluif1b4Ug6IXxyZDgEokoAEyKqkWFdWUsAE0IXego6HVuKOg1bclbDlXzVcEVVQwATgk4ITWahCoHwCGBChMeemSFAJ0SKc4CCTgecok7DlpzVcCVfNVxR1RBQmRB7SzfZawdXahbtU9V1Qvx74a10QvjkyHAIRJUAJkRUI8O6spYAnRC60FPQ6dhS1GnYkrMaruSrhiuqGgKYEHRCaDILVQiERwATIjz2zAwBOiFSnAMUdDrgFHUatuSshiv5quGKqoaAyoT4sPSvtqn6fzWL9qlakFts3yy4hU4InxwZDoGoEsCEiGpkWFfWEqATQhd6CjodW4o6DVtyVsOVfNVwRVVDABOCTghNZqEKgfAIYEKEx56ZIUAnRIpzgIJOB5yiTsOWnNVwJV81XFHVEFCZEB+Uvm5\/rl6tWbRPVdcJ8a2CYXRC+OTIcAhElQAmRFQjw7qylgCdEFkb+rR+cIplTfgoljVcyVcNV1Q1BG6d2NG2vPsbmzBhQmATLFiwwDAhAsOJEAQgkCABTIgEgXE7BNQEMCHUhNFXEKCoU1A1w4TQcCVfNVxR1RBQmRDvlW62V6t\/o1m0T1XXCfHtgpvohPDJkeEQiCoBTIioRoZ1ZS0BTIisDX1aPzhFnSZ8mBAaruSrhiuqGgKYEOwJocksVCEQHgFMiPDYMzMEjksAE4LESEcCFHWaqGFCaLiSrxquqGoIqEyIv5e+YX+sXqtZtE\/Vwtwi+8+C\/6ITwidHhkMgqgQwIaIaGdaVtQQwIbI29Gn94BR1mvBhQmi4kq8arqhqCGBC0AmhySxUIRAeAUyI8NgzMwTohCAHMoYARZ0mlJgQGq7kq4YrqhoCKhNiZ+mb9nL1C5pF+1R1nRCXF9xIJ4RPjgyHQFQJYEJENTKsK2sJ0AmRtaFP6wenqNOEDxNCw5V81XBFVUMAE4JOCE1moQqB8AhgQoTHnpkhQCcEOZAxBCjqNKHEhNBwJV81XFHVEFCZENvL3rI\/VP9Ws2ifqs1ziuyqggF0QvjkyHAIRJUAJkRUI8O6spYAnRBZG\/q0fnCKOk34MCE0XMlXDVdUNQQwIeiE0GQWqhAIjwAmRHjsmRkCdEKQAxlDgKJOE0pMCA1X8lXDFVUNAZUJ8beyrba++neaRftUbZ7Twq4uuJ5OCJ8cGQ6BqBLAhIhqZFhX1hKgEyJrQ5\/WD05RpwkfJoSGK\/mq4YqqhgAmBJ0QmsxCFQLhEcCECI89M0OATghyIGMIUNRpQokJoeFKvmq4oqohoDIh3i17x9ZVv6RZtE\/VFjktrH\/BNXRC+OTIcAhElQAmRFQjw7qylgCdEFkb+rR+cIo6TfgwITRcyVcNV1Q1BDAh6ITQZBaqEAiPACZEeOyZGQJ0QpADGUOAok4TSkwIDVfyVcMVVQ0BlQnxdtm79rvq32sW7VPVdUJcV\/ADOiF8cmQ4BKJKABMiqpFhXVlLgE6IrA19Wj84RZ0mfJgQGq7kq4YrqhoCmBB0QmgyC1UIhEcAEyI89swMATohyIGMIUBRpwklJoSGK\/mq4YqqhoDKhHirbJv9tnq9ZtE+VYtymtuAgu\/TCeGTI8MhEFUCmBBRjQzryloCdEJkbejT+sEp6jThw4TQcCVfNVxR1RDAhKATQpNZqEIgPAKYEOGxZ2YI0AlBDmQMAYo6TSgxITRcyVcNV1Q1BFQmxJtl2+2F6j9oFu1T1XVC3FhwFZ0QPjkyHAJRJYAJEdXIsK6sJUAnRNaGPq0fnKJOEz5MCA1X8lXDFVUNAUwIOiE0mYUqBMIjgAkRHntmhgCdEORAxhCgqNOEEhNCw5V81XBFVUNAZUK8UbbD1lZv1Czap6rrhPivgivohPDJkeEQiCoBTIioRoZ1ZS0BOiGyNvRp\/eAUdZrwYUJouJKvGq6oaghgQtAJocksVCEQHgFMiPDYMzME6IQgBzKGAEWdJpSYEBqu5KuGK6oaAioT4vXSXfab6pc1i\/apWpxbaEML+tIJ4ZMjwyEQVQKYEFGNDOvKWgJ0QmRt6NP6wSnqNOHDhNBwJV81XFHVEMCEoBNCk1moQiA8ApgQ4bFnZgjQCUEOZAwBijpNKDEhNFzJVw1XVDUEVCbEa6V\/t\/+tfkWzaJ+qrhPi5oLv0AnhkyPDIRBVApgQUY0M68paAnRCZG3o0\/rBKeo04cOE0HAlXzVcUdUQwISgE0KTWahCIDwCmBDhsWdmCNAJQQ5kDAGKOk0oMSE0XMlXDVdUNQRUJsSm0t22qvpVzaJ9qpbkFtrwgm8n1AmRn59v\/fr1s0svvdRKS0utUaNGVl1dbTt37rQ5c+bY0qVLE1pVs2bN7MYbb7Svf\/3rVlRUZDk5ObZv3z5bt26dPfjgg54uFwQgkBwBTIjkuDEKAjICdELI0CIsJEBRp4GLCaHhSr5quKKqIYAJEbvYLy4utgkTJljXrl2tpqbGdu\/ebZWVlVZeXm5lZWV26NAhW7hwoU2fPj2uIDm9KVOmWJcuXbyx7777rjfulFNOscaNG3v\/96hRo2zr1q1x6XETBCBQnwAmBBkBgYgRwISIWEBYTlwEKOriwpTwTZgQCSOLawD5GhcmbooIAZUJ8ZfS9+3X1X+KyFPWX0ZJboGNLLgk7k6IAQMGeF0QVVVVNnPmTFu2bJkn6Lojhg0bZn369PG6IiZOnGirVq2K+cx33nmn\/fu\/\/7vt2LHDfvSjH9mf\/\/xnb0y3bt3sjjvusJYtW9qCBQs8o4ILAhBInAAmROLMGAEBKQFMCClexEUEKOo0YDEhNFzJVw1XVDUEMCEa7oRwRsPs2bOtc+fOtmTJEs9oqHu5TymcMdGxY0dbvny5jR8\/vsFAffWrX\/XuadKkic2YMcMWL15c737XAeFMjT\/96U92ww03aIKOKgQynAAmRIYHmMdLPwKYEOkXM1ZsRlGnyQJMCA1X8lXDFVUNAZUJ8afSD+z56n\/8DX\/ULtcJMbrgW3F1QrRr184zHtq0aWOzZs2yefPmHfM4kydPtp49e9qaNWts5MiRDT7u9ddfbz\/4wQ\/sjTfeMPe\/3ecdXBCAQLAEMCGC5YkaBHwTwITwjRCBEAhQ1GmgY0JouJKvGq6oaghgQsTeE6Ih8nU7JVavXm233XZbg4Fyn1h0797dnn32WZs0aZImqKhCIMsJYEJkeQLw+NEjgAkRvZiwotgEKOpiM0rmDkyIZKjFHkO+xmbEHdEhoDIhXi390H51cFN0HrTOSkpzC2xM4Tfj6oSI9QDu04mhQ4daXl6e99nG3LlzGxzy+OOPW6dOnbwTNdwGlN\/\/\/vetoqLC219i7969tnLlSnvooYe8\/Se4IACB5AhgQiTHjVEQqEegR48e1r9\/f+vQoYO3a7LbSfnDDz+0FStWmPuXWSL\/osKEILnSkQBFnSZqmBAaruSrhiuqGgKYEMl3QjgzwX2q0bZtW9uyZYsNGTLEMxJOdLlPO37yk59Yq1atvD0fzjrrLG9Dy23btnl7RDgdZ0Zs2rTJhg8f3qCWJhtQhUBmEMCEyIw48hQhEhg0aJBdfvnlnvlw9HX48GF7\/fXXbdy4cfb222\/HtUpMiLgwcVPECFDUaQKCCaHhSr5quKKqIaAyIf5YuseeO\/hXzaITUC3NbWYd8lodM+J7Tb\/qqxPCdS+4YzvdMZt79uyxe+65x9znGA1dp556qnfihdtfwv2G27hxo40ZM+aI2dC7d2\/vtA13hKfbsJLPNRIINLdCoA4BTAjSAQI+CLh\/Gd16661WWFho77\/\/vj366KPezswnn3yyXXfddd4mSM4xdxshud2U47kwIeKhxD1RI0BRp4kIJoSGK\/mq4YqqhkA2mBBDmv1LPXjOmHDXZZddZjt3Jt4J0b59e++EC3ciRmVlZb1jO+M1IXbv3u0dx\/nqq6\/WG+I6INy6\/va3v3mfeezatUsTeFQhkMEEMCEyOLg8mp7AtGnT7Pzzz\/cc8rvuusteeOGFepPW7sbsHHi3EdIrr7wSc1GYEDERcUMECVDUaYKCCaHhSr5quKKqIaAyIV4urbRfHnxNs2ifqs6EGF\/YOykTolu3bt4JGO7TCff7a\/r06d7nsfFc7jhPt9+D64hYv3693XTTTccMu+CCC45sbum6JNatWxePNPdAAAJ1CGBCkA4QSJJAWVmZ3X777d73gn\/5y188N\/zoq2\/fvjZ48GDv\/+3MheMdG3X0GEyIJAPCsFAJUNRp8GNCaLiSrxquqGoIYELE3wlR+7lESUmJ10Fx9913e2ZCItcjjzzifcJxouM8zz33XO8zD3dhQiRClnsh8DkBTAiyAQJCAldccYXdeOONmBBCxkhHgwBFnSYOmBAaruSrhiuqGgIqE+IPJR\/ZsoOvaxbtU7Ust5lNaP5vCXVC9OrVy0aMGGHOgHjrrbe8\/bg2b96c8ErGjh1rF110kb3xxht2zTXXWE1NTT2Niy++2G655RZvw0pnQmzYsCHhORgAgWwngAmR7RnA88sIuL0gpk6dal\/72tfsvffe83ZRjudfhnRCyEKCsJAARZ0GLiaEhiv5quGKqoYAJkTsToiuXbt63QnOgHAnVzhzIJm9JFwE3ZGeN998s3fS2b333nvMpxxujy93T+1pG27PCS4IQCAxApgQifHibgjEJNCsWTNvQ8orr7zS2xDJOeiLFi0yt39EPBcmRDyUuCdqBCjqNBHBhNBwJV81XFHVEFCZEBtKPralBxPvFNA8ZX3VstymNrH51+PqhHB\/6TNz5kw755xzbPv27TZ69Oi4\/tLnRM\/h9oVwf4l05plnet0QrjOi9oQz1wXhjvl0v\/XmzJljP\/3pT1OBgzkgkHEEMCEyLqQ8UJgE3L+YrrrqqiNL2Ldvnz3zzDPeqRlHt\/OdaJ2YEGFGkLmTJUBRlyy5hsdhQmi4kq8arqhqCGBCNNwJ4TaKdMZDQUFBzADU3eehdm8Hd8T60ft2derUydtw3J125j67ePfdd73Tztxml+6\/165d6+0LFu9vu5gL4wYIZBkBTIgsCziPqyVQexpG3Vn2799vCxcutFmzZsX1LytMCG2MUNcQoKjTcMWE0HAlXzVcUdUQUJkQ60v22eKDWzSL9qnqOiEmN+8VVyfEoEGDrF+\/fpaTkxNz1nhNCCdUUVFhTtuZFe4o9sOHD3vHsbvfdK4LAgMiJm5ugMAJCWBCkBwQCJBAu3bt7OOPP\/Zcc7ep0dVXX23l5eXed4WuI8K1C8a6nAnxz\/+cY4XNf1nv1vz8nXbSSS\/HGs6fQyAUAhR1GuyYEBqu5KuGK6r+Cfzz10uPEen+9TLb8u5vjpzI4H8WswULFlimmBBB8EADAhBILQFMiNTyZrYsI+Da+SZNmuS56du2bfPOm461UZIzIdwGS0dfzoBoXfFfWUaQx00XAhR1mkhhQmi4kq8arqj6JzDpkTOtZXnjY4SWLVuGCeEfLwoQgEBECGBCRCQQLCNzCbhdlC+55BJz+0O486pXrVrV4MPyOUbm5kImPxlFnSa6mBAaruSrhiuqGgKqzzF+X7Lfnv3kTc2ifaq2zG1q97ToGdfnGD6nYjgEIBACAUyIEKAzZXYRqN2s0n2icfTGR8cjgQmRXfmRKU9LUaeJJCaEhiv5quGKqoYAJkTsIzo15FGFAARUBDAhVGTRzXgC7pMJdw51WVmZLVmyxKZMmXLcZ67drNKdI+3u37BhQ4NsMCEyPnUy8gEp6jRhxYTQcCVfNVxR1RBQmRDrSqps0SdvaRbtU9V1Qkxp8f\/SCeGTI8MhEFUCmBBRjQzrijwBt8\/Dfffd5x3f5PZ5cJ9dbN5c\/7ztXr162YgRI6ykpMQ2bdpkN998szkzoqELEyLyoWeBxyFAUadJC0wIDVfyVcMVVQ0BTAg6ITSZhSoEwiOACREee2bOAALuU4vvfve71qhRI3v77bftscce8\/Z8cEc5XXnlldanTx8rLi62qqoqmzFjhi1evDjmU2NCxETEDREkQFGnCQomhIYr+arhiqqGgMqEeKn4gC36ZKtm0T5VW+aeZFOLutMJ4ZMjwyEQVQKYEFGNDOtKCwL5+fk2duxYcx0Pzog43uU2pHz44Ydt\/vz5cT0TJkRcmLgpYgQo6jQBwYTQcCVfNVxR1RDAhKATQpNZqEIgPAKYEOGxZ+YMIvCNb3zDLr\/8cjvttNOscePGdvjwYe80jJdfftlmz55tW7ZsiftpMSHiRsWNESJAUacJBiaEhiv5quGKqoaAyoT4XfFBW\/jJ25pF+1R1nRA\/KTqPTgifHBkOgagSwISIamRYV9YSwITI2tCn9YNT1GnChwmh4Uq+ariiqiGACUEnhCazUIVAeAQwIcJjz8wQOC4BTAgSIx0JUNRpooYJoeFKvmq4oqohoDMhqm3BgXc0i\/ap6johphd\/jU4InxwZDoGoEsCEiGpkWFfWEsCEyNrQp\/WDU9RpwocJoeFKvmq4oqohgAlBJ4Qms1CFQHgEMCHCY8\/MEKATghzIGAIUdZpQYkJouJKvGq6oagioTIjfFh+y+Qfe1Szap2qr3CY2o7gbnRA+OTIcAlElgAkR1ciwrqwlQCdE1oY+rR+cok4TPkwIDVfyVcMVVQ0BTAg6ITSZhSoEwiOACREee2aGAJ0Q5EDGEKCo04QSE0LDlXzVcEVVQ0BlQrxYVGPzD\/xNs2ifqq4T4r6S\/4dOCJ8cGQ6BqBLAhIhqZFhX1hKgEyJrQ5\/WD05RpwkfJoSGK\/mq4YqqhgAmBJ0QmsxCFQLhEcCECI89M0OATghyIGMIUNRpQokJoeFKvmq4oqohoDMhPrVfVG3TLNqnquuEmFn6T3RC+OTIcAhElQAmRFQjw7qylgCdEFkb+rR+cIo6TfgwITRcyVcNV1Q1BDAh6ITQZBaqEAiPACZEeOyZGQJ0QpADGUOAok4TSkwIDVfyVcMVVQ0BlQnxQtFn9kzVds2ifaq6TogHSs+mE8InR4ZDIKoEMCGiGhnWlbUE6ITI2tCn9YNT1GnChwmh4Uq+ariiqiGACUEnhCazUIVAeAQwIcJjz8wQoBOCHMgYAhR1mlBiQmi4kq8arqhqCKhMiLUtDtszVTs0i\/ap2iqvsT1YehadED45MhwCUSWACRHVyLCurCVAJ0TWhj6tH5yiThM+TAgNV\/JVwxVVDQFMCDohNJmFKgTCI4AJER57ZoYAnRDkQMYQoKjThBITQsOVfNVwRVVDQGVCrGlx2OZVRbPAL89rbA+VfoVOCE1KoQqB0AlgQoQeAhYAgfoE6IQgI9KRAEWdJmqYEBqu5KuGK6oaApgQ0TRKNNFGFQLZQQATIjvizFOmEQFMiDQKFks9QoCiTpMMmBAaruSrhiuqGgI6E8Ls6f27NIv2qeo6IR4uO5NOCJ8cGQ6BqBLAhIhqZFhX1hLAhMja0Kf1g1PUacKHCaHhSr5quKKqIYAJQSeEJrNQhUB4BDAhwmPPzBA4LgFMCBIjHQlQ1Gmihgmh4Uq+ariiqiGgMiF+0yLHfr7\/75pF+1R1nRA\/LTuDTgifHBkOgagSwISIamRYV9YSwITI2tCn9YNT1GnChwmh4Uq+ariiqiGACUEnhCazUIVAeAQwIcJjz8wQoBOCHMgYAhR1mlBiQmi4kq8arqhqCKhMiNXNc+2p\/bs1i\/ap6joh\/rvl6XRC+OTIcAhElQAmRFQjw7qylgCdEFkb+rR+cIo6TfgwITRcyVcNV1Q1BDAh6ITQZBaqEAiPACZEeOyZGQJ0QpADGUOAok4TSkwIDVfyVcMVVQ0BlQnxv83z7Gf739Ms2qdqeV4je7RlJzohfHJkOASiSgATIqqRYV1ZS4BOiKwNfVo\/OEWdJnyYEBqu5KuGK6oaApgQdEJoMgtVCIRHABMiPPbMDAE6IciBjCFAUacJJSaEhiv5quGKqoaAyoRY1Tzf5u6LZifEF\/Ia2WOtOtIJoUkpVCEQOgFMiNBDwAIgUJ8AnRBkRDoSoKjTRA0TQsOVfNVwRVVDABOCTghNZqEKgfAIYEKEx56ZIUAnBDmQMQQo6jShxITQcCVfNVxR1RBQmRC\/bt7I5ux7X7Non6quE+LJVl+iE8InR4ZDIKoEMCGiGhnWlbUE6ITI2tCn9YNT1GnChwmh4Uq+ariiqiGACRFfJ0R+fr7169fPLr30UistLbVGjRpZdXW17dy50+bMmWNLly6NO0CnnXaaTZkyxSoqKk44Zs2aNTZy5Mi4NbkRAhD4nAAmBNkAgYgRwISIWEBYTlwEKOriwpTwTZgQCSOLawD5GhcmbooIAZUJ8XxhY3ty3wcRecr6y3CdEHPLT427E6K4uNgmTJhgXbt2tZqaGtu9e7dVVlZaeXm5lZWV2aFDh2zhwoU2ffr0uJ63e\/fuNm7cOCsoKMCEiIsYN0EgMQKYEInx4m4IyAlgQsgRM4GAAEWdAKqZYUJouJKvGq6oaghgQsTuhBgwYIDXBVFVVWUzZ860ZcuWecFw3RHDhg2zPn36eF0REydOtFWrVsUM1NVXX23XXnut7dq1y4YOHer9NxcEIBAcAUyI4FiiBIFACGBCBIIRkRQToKjTAMeE0HAlXzVcUdUQUJkQvypsYk\/s+1CzaJ+qrfPy7any9nF1QjijYfbs2da5c2dbsmSJZzTUvYqKijxjomPHjrZ8+XIbP358zNWNGjXKLrnkElu\/fr3ddNNNMe\/nBghAIDECmBCJ8eJuCMgJYELIETOBgABFnQAqnRAaqGZGvsrQIiwggAnRcCdEu3btPOOhTZs2NmvWLJs3b94xUZg8ebL17NnT4t3H4b777rNu3brZs88+a5MmTRJEFUkIZDcBTIjsjj9PH0ECmBARDApLikmAoi4moqRuoBMiKWwxB5GvMRFxQ4QIqEyI5wqb2GMf74nQk36+FNcJMe8LX4yrEyLWA9TtlFi9erXddtttDQ5p3bq1zZgxw9x\/P\/TQQ\/bzn\/881hT8OQQgkCABTIgEgXE7BNQEMCHUhNFXEKCoU1BlTwgNVTohVFzR1RDAhIi9J0RD5N1+EG5fh7y8PO+zjblz5zYYqLPPPtvuvvtua9asmb355pvmOi0KCwu9MXv37rWVK1d65oTbf4ILAhBIjgAmRHLcGAUBGQFMCBlahIUEMCE0cOmE0HAlXzVcUdUQUJkQvyw4yR79eK9m0T5VK\/Ly7Ret2\/nuhOjUqZP3qUbbtm1ty5YtNmTIEM9IaOj6zne+4+0D0bhxY\/vss8+8TSndGLe3hDttwx39+dZbb3mnZ2zevNnnkzIcAtlJABMiO+POU0eYACZEhIPD0k5IgKJOkxyYEBqu5KuGK6oaApluQvxTk5Ps2uYlx8Bz\/\/\/LLrvMdu5MrhOioqLCO7azS5cutmfPHrvnnnvMfY4R63KnYlxxxRXeUZ\/333\/\/kZM23LjevXt7p22UlJTEvb9ErPn4cwhkIwFMiGyMOs8caQKYELrwUHjo2FIsa9iSsxqu5KuGK6oaArt23m\/z5+\/wCuqgrgULFtjSgqb23x9XBiWZtI7reri+RVG98e7\/19WHCdG+fXvvFAx3IkZlZWW9YzuTXuj\/DRw4cKB3HOhHH33k7S\/xyiuv+JVkPASyjgAmRNaFnAeOOgFMCF2EKOh0bCnqNGzJWQ1X8lXDFVUNgUw3IY5HzZkQi1q3TaoTwp1qMXLkSO8TDNcBMX36dFuxYkVgwenevbv3KYb7LMP9ZjveaRyBTYYQBDKUACZEhgaWx0pfApgQuthR0OnYUtRp2JKzGq7kq4YrqhoCKhNiSUEz++lHH2kW7VPVmRBLKioSNiHqfi7hPuNwG0yuX78+4dWceuqp3pitW7ceM\/bcc8\/1ulLcnhGYEAmjZQAEPAKYECQCBCJGABNCFxAKOh1bijoNW3JWw5V81XBFVUMAEyK+PSF69eplI0aM8PZr8LNx5COPPOLtI\/Hiiy\/a8OHDjwnqBRdc4H2G4U7bmDp1ar09IzQZgCoEMo8AJkTmxZQnSnMCmBC6AFLQ6dhS1GnYkrMaruSrhiuqGgIqE+LZggJ7OKKdEG3y8uyXCXRCdO3a1etOcAbEpk2bbMyYMUlvaDlq1Ci75JJL7L333vNMiKNPwHB\/7o793L59u3eKRrIbZ2qyBVUIpAcBTIj0iBOrzCICmBC6YFPQ6dhS1GnYkrMaruSrhiuqGgKYEA13QuTn53sbT55zzjmeMTB69GhfR2fWGhrFxcW2du1ab\/+HqqoqL7huQ8rrrrvOcnNzbc6cOfbTn\/5UE3RUIZDhBDAhMjzAPF76EcCE0MWMgk7HlqJOw5ac1XAlXzVcUdUQUJkQi5oV2oMffaxZtE\/VNvl59quKL8S1J4T7XlbNfwAAIABJREFUPMIZDwUFBTFnXbNmjbdppbsa2tvhyiuvtBtuuMGaNGlie\/fu9bodioqKrHXr1t5YZ064bgt3jCcXBCCQOAFMiMSZMQICUgKYEDq8FHQ6thR1GrbkrIYr+arhiqqGACZEw50QgwYN8joUcnJyYgYgXhPCCfXo0cP69+9vHTp08DahPHTokGdGLFq0yJ555hkMiJi0uQECJyaACUF2QCBiBDAhdAGhoNOxpajTsCVnNVzJVw1XVDUEVCbEgmbN7cHKfZpF+1Rtm59nK9q0iqsTwudUDIcABEIggAkRAnSmhEBDBDAhdPlBQadjS1GnYUvOariSrxquqGoIYELEdzqGhj6qEICAggAmhIIqmhDwQQATwge8GEMp6HRsKeo0bMlZDVfyVcMVVQ0BlQkxv1lze6Byv2bRPlVdJ8Sv27SkE8InR4ZDIKoEMCGiGhnWlbUEMCF0oaeg07GlqNOwJWc1XMlXDVdUNQQwIeiE0GQWqhAIjwAmRHjsmRkCxyWACaFLDAo6HVuKOg1bclbDlXzVcEVVQ0BmQjRtYfdX\/uPoyahdrhNiZdtSOiGiFhjWA4GACGBCBAQSGQgERQATIiiSx+pQ0OnYUtRp2JKzGq7kq4YrqhoCmBB0QmgyC1UIhEcAEyI89swMgeMSwITQJQYFnY4tRZ2GLTmr4Uq+ariiqiGgMiF+0bTI7q88oFm0T9W2+bm2qm0JnRA+OTIcAlElgAkR1ciwrqwlgAmhCz0FnY4tRZ2GLTmr4Uq+ariiqiGACUEnhCazUIVAeAQwIcJjz8wQoBMixTlAQacDTlGnYUvOariSrxquqGoI6EyIYrt\/b4Q7IU4uphNCk1KoQiB0ApgQoYeABUCgPgE6IXQZQUGnY0tRp2FLzmq4kq8arqhqCGBC0AmhySxUIRAeAUyI8NgzMwTohEhxDlDQ6YBT1GnYkrMaruSrhiuqGgIyE+KkErt\/7yeaRftU9faEaNeCTgifHBkOgagSwISIamRYV9YSoBNCF3oKOh1bijoNW3JWw5V81XBFVUMAE4JOCE1moQqB8AhgQoTHnpkhQCdEinOAgk4HnKJOw5ac1XAlXzVcUdUQUJkQ810nxJ6DmkX7VHWdECtPaU4nhE+ODIdAVAlgQkQ1MqwrawnQCaELPQWdji1FnYYtOavhSr5quKKqIYAJQSeEJrNQhUB4BDAhwmPPzBCgEyLFOUBBpwNOUadhS85quJKvGq6oagjoTIhSe2BPtWbRPlVdJ8SvTymgE8InR4ZDIKoEMCGiGhnWlbUE6ITQhZ6CTseWok7DlpzVcCVfNVxR1RDAhKATQpNZqEIgPAKYEOGxZ2YI0AmR4hygoNMBp6jTsCVnNVzJVw1XVDUEVCbEgiZl9uCeQ5pF+1Rtm59jK77YjE4InxwZDoGoEsCEiGpkWFfWEqATQhd6CjodW4o6DVtyVsOVfNVwRVVDABOCTghNZqEKgfAIYEKEx56ZIUAnRIpzgIJOB5yiTsOWnNVwJV81XFHVEFCZEIuatLQHP4xmJ0Sb\/Bz7VfumdEJoUgpVCIROABMi9BCwAAjUJ0AnhC4jKOh0bCnqNGzJWQ1X8lXDFVUNAUwIOiE0mYUqBMIjgAkRHntmhgCdECnOAQo6HXCKOg1bclbDlXzVcEVVQ0BmQjRuZQ9\/WKNZtE\/VNo1ybHn7JnRC+OTIcAhElQAmRFQjw7qylgCdELrQU9Dp2FLUadiSsxqu5KuGK6oaApgQdEJoMgtVCIRHABMiPPbMDAE6IVKcAxR0OuAUdRq25KyGK\/mq4YqqhoDKhFjcuJXN+uBTzaJ9qrpOiKWnNqYTwidHhkMgqgQwIaIaGdaVtQTohNCFnoJOx5aiTsOWnNVwJV81XFHVEMCEoBNCk1moQiA8ApgQ4bFnZgjQCZHiHKCg0wGnqNOwJWc1XMlXDVdUNQRUJsSSxuU2+4PPNIv2qVrRKMcWn5pPJ4RPjgyHQFQJYEJENTKsK60JFBcX29SpU61Lly62Zs0aGzlyZNzPQydE3KgSvpGCLmFkcQ+gqIsbVUI3krMJ4Yr7ZvI1blTcGAECmBB0QkQgDVkCBAIlgAkRKE7EIPAPAqNGjbI+ffpYTk4OJkSEkoKCThcMijoNW3JWw5V81XBFVUNAZUIsbfQF++\/IdkKYLTqNTghNRqEKgfAJYEKEHwNWkGEEvvOd79iQIUOsSZMm3pPRCRGdAFPQ6WJBUadhS85quJKvGq6oaghgQtAJocksVCEQHgFMiPDYM3MGEujUqZNNnDjR2rRpY4cPH7bc3FxMiAjFmYJOFwyKOg1bclbDlXzVcEVVQ0BlQixr9AV75P3DmkX7VK1oZLbgS3nsCeGTI8MhEFUCmBBRjQzrSjsC+fn5dtddd1mPHj3szTfftKKiImvVqhUmRIQiSUGnCwZFnYYtOavhSr5quKKqIYAJQSeEJrNQhUB4BDAhwmPPzBlGoH\/\/\/ub+U1VVZW5zyWuuucbriOBzjOgEmoJOFwuKOg1bclbDlXzVcEVVQ0BlQvwyv7U9+r5mzX5VXSfELzrk0AnhFyTjIRBRApgQEQ0My0ovAt27d7fbb7\/dCgsLbc6cOfb888\/blClTMCEiFkYKOl1AKOo0bMlZDVfyVcMVVQ0BTAg6ITSZhSoEwiOACREee2bOEAJHH8fpzIh27dphQkQwvhR0uqBQ1GnYkrMaruSrhiuqGgIqE2J5foU99p5mzX5VWzcye6aj0QnhFyTjIRBRApgQEQ0My0ofAjfffLNdeumltnv3bhs9erRt3rzZTj31VEyICIaQgk4XFIo6DVtyVsOVfNVwRVVDABOCTghNZqEKgfAIYEKEx56ZM4BA79697dZbb7VGjRrZrFmz7KmnnvKeChMimsGloNPFhaJOw5ac1XAlXzVcUdUQUJkQz+W5TogczaJ9qrpOiHmdDtMJ4ZMjwyEQVQKYEFGNDOuKPAFnNNx7771H9n0YNWrUkTX7NSG6du16zPOfdNLL1rrivyLPJcoLpKDTRYeiTsOWnNVwJV81XFH1T2Db335hNTUVxwgtW7bMJkyY4H+C\/1NYsGCBZZoJ4U4p69evn9edWlpa6v0FUXV1te3cudPbr2vp0qW++F155ZU2cOBAe\/\/992348OG2detWX3oMhkA2E8CEyObo8+xJE6h7HOc777xj7pMM9y+52suvCdGz5y47qenLx6yvsPCXSa+ZgWYUdLosoKjTsCVnNVzJVw1XVP0T2Lfvm8eI7N1zjT377MbATYhf5bWxx3fn+l+0QMF1Qvz89E\/j7oRw+3M5k8b9JU5NTY33iWxlZaWVl5dbWVmZHTp0yBYuXGjTp09ParWdOnWySZMmWUVFhe3YsQMTIimKDILA5wQwIcgGCCRBoK7JEO\/wffv22ZgxY2zdunUNDnHHe15wwctWXPJovNLcFycBCro4QSVxG0VdEtDiGELOxgEpiVvI1ySgMSQ0AqrPMTLJhBgwYIDXBeGOSZ85c6a5zhF3ub80GjZsmPXp08fripg4caKtWrUqoVg6jalTp9r\/3979QElVnnkef5CmEZrYdLcSgSGiEQKNiQwrIRkDYdmVqOwQgjsYx97I6sgoDNJBBUFGAiL\/VNITEpFhzBgHxDQRiIDNMgNDWhNCMBgzEzTIgCjQ2EGhDUFpGtjzXg9KC3Tdqn6ee99b9e1z9pw9S9Vzb32ed9\/c+\/OpW1\/84heD9xFCpMXHixE4qwAhBAsDgQwECCEyQPPgLdzQ2TWBmzobW9asjSvr1caVqjYCZiHEeZ3lR75OQuSflKUhJyFcSLBo0SLp0aOHrFq1KggaTv8rLCwMgolu3bpJVVWVTJ8+Pa1GjRw5Utz\/cQFHQUEBX8dIS48XI3B2AUIIVgYCBgLN\/ToGkxAGTRG+jmGj+mFVbupsdAkhbFxZrzauVLURIIRo+tcx3M+iu+ChU6dOwUPCKysrz2jEnDlzZMCAAVJdXS0TJ04M3Sj39Y5Tz+JYv359MFHBMyFC8\/FCBM4pQAjB4kDAQIAQwgBVoSQ3dAqI5yjBTZ2NLWvWxpX1auNKVRsBqxBinZuEeLulzUk3s+rF+Sfl6R4NoZ8J0dThTp+U2Lhxo0yaNCnU2bn3uQmKXr16ycqVK2XPnj0yZswYQohQerwIgaYFCCFYIQgYCBBCGKAqlOSGTgGREMIO8SyVWbM23IQQNq5UtREghGh6EiKVupteGDdunLRs2TL42saSJUtSvSX497Fjx8pf\/dVfyfbt2+Xuu++Wr33ta4QQoeR4EQKpBQghUhvxCgTSFiCESJsskjdwQ2fHzE2djS1r1saV9WrjSlUbAbMQosWfyVMeT0Is6Xms2ZMQ7lct3Fc1OnfuLDt27AiChUOHDqVs1MCBA2XChAnB6x566CH5+c9\/LiNGjCCESCnHCxAIJ0AIEc6JVyGQlgAhRFpckb2YGzo7am7qbGxZszaurFcbV6raCGR7CHFluxMy77MNZ8UbPnx4o59AT0fY\/Zyme55DaWmpHDx4UObOnSvu6xip\/tzPfbpfw3APsly2bFnwlQz3RwiRSo5\/RyC8ACFEeCteiUAkAvxEpx0zN3R2ttzU2diyZm1cWa82rlS1EbAKIf7VTULsz7M56TSrDi4+3ugd7pkQ37r4eMaTEF27dg1+BcMFCXV1dY1+tjPVqY0fP16GDRv20dcw3PsJIVKp8e8IpCdACJGeF69GwFyAEMKOmBs6O1tu6mxsWbM2rqxXG1eq2gjkQgjxSblP55+UJaX1GYUQffv2DX4Bw30Fw01AVFRUyLp160I1x30N47777pMTJ0589DWMU29kEiIUIS9CIJQAIUQoJl6EQHQChBB21tzQ2dlyU2djy5q1cWW92rhS1UbALISQLt5MQpw1hOh1NO0QYvDgwVJeXi5FRUXB1zhmzZolW7ZsCd0Y98yIv\/7rvw71+sOHD8uUKVNk8+bNoV7PixBA4GMBQghWAwKeCRBC2DWEGzo7W27qbGxZszaurFcbV6raCBBChPt1jFMPk3QBxM6dO2XatGnBVyrS+bvhhhvk+uuvP+tb2rZtK126dJGjR4\/Km2++KS6EcNdsr732WjqH4LUIICAihBAsAwQ8EyCEsGsIN3R2ttzU2diyZm1cWa82rlS1ESCESB1C9OnTJ3gIpQsgtm3bFkwouEkIzT++jqGpSa1cFyCEyPUVwOf3ToAQwq4l3NDZ2XJTZ2PLmrVxZb3auFLVRsAyhPiXGj8eTPlJOfdMiMVXhPs6Rl5eXvDgyd69e8vevXtl8uTJaU9AhOkcIUQYJV6DQDgBQohwTrwKgcgECCHsqLmhs7Plps7GljVr48p6tXGlqo0AIUTTEw2DBg0KgoeCgoKUDaiurg4eWun++vXrF0xP5OfnB1+rqKysbPL9hBApeXkBAqEFCCFCU\/FCBKIRIISwc+aGzs6WmzobW9asjSvr1caVqjYCViHEv53sIv9S08rmpJtZ1U1C\/MvnPwj1YMrRo0dLWVmZtGjRIuVRCSFSEvECBCIRIISIhJmDIBBegBAivFW6r+SGLl2x8K\/npi68VTqvZM2moxX+tazX8Fa8Mn4BQgjdZzvE31HOAAEECCFYAwh4JkAIYdcQbujsbLmps7Flzdq4sl5tXKlqI2AXQnxGFu\/zdxLiqS+8H2oSwkadqgggYClACGGpS20EMhAghMgALeRbuKELCZXBy7ipywAtxFtYsyGQMngJ6zUDNN4SmwAhBJMQsS0+DoyAkQAhhBEsZRHIVIAQIlO51O\/jhi61Uaav4KYuU7mm38eatXFlvdq4UtVGwCqEWH\/iM7J4r6eTEK1Pyo+uZBLCZkVRFYH4BQgh4u8BZ4BAIwFCCLsFwQ2dnS03dTa2rFkbV9arjStVbQQIIZiEsFlZVEUgPgFCiPjsOTICZxUghLBbGNzQ2dlyU2djy5q1cWW92rhS1UbALIQ4\/hlZsjff5qSbWfXTrU\/Kk72P8EyIZjrydgR8FSCE8LUznFfOChBC2LWeGzo7W27qbGxZszaurFcbV6raCBBCMAlhs7KoikB8AoQQ8dlzZASYhIh4DXBDZwfOTZ2NLWvWxpX1auNKVRsBqxBig5uE2OPvJMQ\/\/zmTEDYriqoIxC9ACBF\/DzgDBBoJMAlhtyC4obOz5abOxpY1a+PKerVxpaqNACEEkxA2K4uqCMQnQAgRnz1HRoBJiIjXADd0duDc1NnYsmZtXFmvNq5UtREwCyEaLvF4EuKE\/HMfJiFsVhRVEYhfgBAi\/h5wBggwCRHRGuCGzg6amzobW9asjSvr1caVqjYChBBMQtisLKoiEJ8AIUR89hwZASYhIl4D3NDZgXNTZ2PLmrVxZb3auFLVRsAyhHj6LV+fCXFCfvjfmISwWVFURSB+AUKI+HvAGSDAJEREa4AbOjtobupsbFmzNq6sVxtXqtoIEEIwCWGzsqiKQHwChBDx2XNkBJiEiHgNcENnB85NnY0ta9bGlfVq40pVGwGzEOLYJfL0W61tTrqZVT\/d+oT88Ko\/yfDhw6WmhhCimZy8HQHvBAghvGsJJ5TrAvw6ht0K4IbOzpabOhtb1qyNK+vVxpWqNgKEEIQQNiuLqgjEJ0AIEZ89R0aASYiI1wA3dHbg3NTZ2LJmbVxZrzauVLURsAoh\/r2+qzz9pp+TEB3OPyE\/7HuYSQibJUVVBGIXIISIvQWcAAKNBZiEsFsR3NDZ2XJTZ2PLmrVxZb3auFLVRoAQgkkIm5VFVQTiEyCEiM+eIyPAJETEa4AbOjtwbupsbFmzNq6sVxtXqtoImIYQu8+3OelmVg0mIb74RyYhmunI2xHwVYAQwtfOcF45K8AkhF3ruaGzs+WmzsaWNWvjynq1caWqjQAhBJMQNiuLqgjEJ0AIEZ89R0aASYiI1wA3dHbg3NTZ2LJmbVxZrzauVLURMAshjnaVpR5PQjzRj0kImxVFVQTiFyCEiL8HnAECjQSYhLBbENzQ2dlyU2djy5q1cWW92rhS1UaAEIJJCJuVRVUE4hMghIjPniMjwCRExGuAGzo7cG7qbGxZszaurFcbV6raCNiFEJfK0jf8fSbEE196j2dC2CwpqiIQuwAhROwt4AQQaCzAJITdiuCGzs6WmzobW9asjSvr1caVqjYChBBMQtisLKoiEJ8AIUR89hwZASYhIl4D3NDZgXNTZ2PLmrVxZb3auFLVRsAqhNj4gZuEaGNz0s2s6n4d45++XMckRDMdeTsCvgoQQvjaGc4rZwWYhLBrPTd0drbc1NnYsmZtXFmvNq5UtREghGASwmZlURWB+AQIIeKz58gIMAkR8Rrghs4OnJs6G1vWrI0r69XGlao2AnYhxGWydJfHkxB\/cYhJCJslRVUEYhcghIi9BZwAAo0FmISwWxHc0NnZclNnY8uatXFlvdq4UtVGgBCCSQiblUVVBOITIISIz54jI3DOSYg9r3WU55buR0hZgBsPZVDKIZBQAcIdu8axz+rbmoUQ718mz+xsq3\/CChXdMyEWfeUgkxAKlpRAwEcBQggfu8I55bSAm4QghLBZAlwc27hSFYGkCRBC2HWMfVbflhCCSQj9VUVFBOIVIISI15+jI3CGACGE3aLg4tjOlsoIJEmAEMKuW+yz+rZWIcTPjnzW30mINsflH5mE0F9MVETAEwFCCE8awWkgcEqAEMJuLXBxbGdLZQSSJEAIYdct9ll9W0IIJiH0VxUVEYhXgBAiXn+OjgCTEBGuAS6OI8TmUAh4LEAIYdcc9ll9W8sQ4sf\/VaB\/wgoVO7Q5Lgv7v8szIRQsKYGAjwKEED52hXPKaQEmIezaz8WxnS2VEUiSACGEXbfYZ\/VtCSGYhNBfVVREIF4BQoh4\/Tk6AkxCRLgGuDiOEJtDIeCxACGEXXPYZ\/VtrUKI6j9dLj\/e4e8kxONffYdJCP3lREUEvBAghPCiDZwEAh8LMAlhtxq4OLazpTICSRIghLDrFvusvi0hRLhJiLy8PCkrK5Nhw4ZJcXGxtGrVSurr66WmpkYWL14sq1evTqs5\/fv3l5EjR8rll18u+fn5Qa0dO3bIk08+KS+88EJatXgxAgg0FiCEYEUg4JkAIYRdQ7g4trOlMgJJEiCEsOsW+6y+rVkIcfhyqdzRTv+EFSq6Z0IsGHgg9CRE+\/btZcaMGdKnTx9paGiQ2tpaqaurkw4dOkhJSYkcO3ZMVqxYIRUVFaHO7oYbbpA77rhDCgoK5J133gnqnar1\/vvvy8KFC6WysjJULV6EAAJnChBCsCoQ8EyAEMKuIVwc29lSGYEkCRBC2HWLfVbflhAi9STEqFGjgimII0eOyPz582XNmjVBI9x0RHl5uQwdOjSYZJg5c6Zs2LChySZ17NhR5s2bJ5dcckkw8XD\/\/fcHwYarNXnyZBk8eLC8\/fbbcs8998iuXbv0G05FBHJAgBAiB5rMR0yWACGEXb+4OLazpTICSRIghLDrFvusvq1dCNFNKl\/3eBLiv\/8h1CSECwcWLVokPXr0kFWrVgVBw+l\/hYWFQTDRrVs3qaqqkunTpzfZpJtvvlluv\/32YJLivvvuk1dfffWj1\/fs2VNmz54tbvJiwYIF8swzz+g3nIoI5IAAIUQONJmPmCwBQgi7fnFxbGdLZQSSJEAIYdct9ll9W0KIpichunTpEgQPnTp1OufXJObMmSMDBgyQ6upqmThxYpNNcpMTQ4YMCZ7\/cOeddzZ67aWXXiqPPPKIuGkJ95yJxx57TL\/hVEQgBwQIIXKgyXzEZAkQQtj1i4tjO1sqI5AkAUIIu26xz+rbWoUQL\/zRTUJ8Sv+EFSpe5J4JMag21CREqsOdPimxceNGmTRpUqq3nPPf3dc6xo8fH3w9I8xXOzI+EG9EIMsFCCGyvMF8vOQJEELY9YyLYztbKiOQJAFCCLtusc\/q2xJCpH4mRFPqLjgYN26ctGzZMvjaxpIlS9Jukvv6xU033RQ8W8J9veP0Z0WkXYw3IICAEEKwCBDwTIAQwq4hXBzb2VIZgSQJEELYdYt9Vt\/WLIR4r7tUbvd0EqLtcVnwP95u9iRE9+7dg4mFzp07B1+vGDt2rBw6dCitJrmvX1x99dXBe06cOCEvvviiPPjgg3L48OG06vBiBBD4WIAQgtWAgGcChBB2DeHi2M6WyggkSYAQwq5b7LP6ttkeQlzU9rh0aNNwBty0v3inWSGEe26D+9nO0tJSOXjwoMydO1fc1zHS\/XO\/lOEmIdq0aROEGe7rHb\/\/\/e9l2rRp8sYbb6RbjtcjgIAIkxCsAgR8EyCEsOsIF8d2tlRGIEkChBB23WKf1bc1DSF+f4H+CadZsVfJUZl29YGzvmv48OFSU5P+1zG6du0a\/AqG+0UM9ysXp\/9sZ5qn1+jl7uc53YMri4qKZNOmTcHzIfhDAIH0BZiESN+MdyBgKkAIYcfLxbGdLZURSJIAIYRdt9hn9W2zPYQ4m5ibjljwP\/dnNAnRt2\/f4Bcw3NSCm4CoqKiQdevWqTXmjjvukLKyMnnvvfeCh1y+8sorarUphECuCBBC5Eqn+ZyJESCEsGsVF8d2tlRGIEkChBB23WKf1bc1CyHqPieVHkxCnD2EaJAF16QfQpw+qeAmKGbNmiVbtmxRbcqgQYM++oWNKVOmyObNm1XrUwyBXBAghMiFLvMZEyVACGHXLi6O7WypjECSBAgh7LrFPqtvSwgR7usYAwcOlAkTJgRfldi5c2fwzIbt27en3ZAFCxYEz5FYv3598JWOT\/4NGTJE7r77bjl+\/LgQQqTNyxsQCAQIIVgICHgmQAhh1xAuju1sqYxAkgQIIey6xT6rb2sWQhz6nFS+Vqh\/wgoVL2rbIAu+VhP66xh9+vQJHkLpAoht27YF4UAmz5Jwp\/7AAw\/IddddJ3v27JG77rrrjDr33Xdf8FOde\/fuPeu\/K3x8SiCQ9QKEEFnfYj5g0gQIIew6xsWxnS2VEUiSACGEXbfYZ\/VtCSGanoRwv1bhHjzZu3fvIBiYPHlyRhMQpzr3la98Re6\/\/34pKCiQtWvXBr+q0dDw4a93uGdB\/M3f\/I2cd955smzZsuC4\/CGAQPoChBDpm\/EOBEwFCCHseLk4trOlMgJJEiCEsOsW+6y+rV0I0UOWvervJMRj1+4LNQnhntHgggcXGqT6q66uDh5a6f769esXTE\/k5+eLu\/aqrKz86O2333673HzzzcG\/vfPOO1JbWxv8TOfFF18cvOaFF14Ipi1OhROpjsu\/I4BAYwFCCFYEAp4JEELYNYSLYztbKiOQJAFCCLtusc\/q2xJCND0JMXr06GBCoUWLFinxw4YQrlD\/\/v1l5MiRcvnllwdhRH19ffDVjMWLF8vq1atTHosXIIDAuQUIIVgdCHgmQAhh1xAuju1sqYxAkgQIIey6xT6rb2sWQhx0kxDt9U9YoaJ7JsRj1+0NNQmhcDhKIIBAxAKEEBGDczgEUgkQQqQSyvzfuTjO3I53IpBNAoQQdt1kn9W3JYQI9+sY+vJURAABKwFCCCtZ6iKQoQAhRIZwId7GxXEIJF6CQA4IEELYNZl9Vt\/WLIR4t4cs2+bpJERBgzx2PZMQ+quJigj4IUAI4UcfOAsEPhIghLBbDFwc29lSGYEkCRBC2HWLfVbflhCCSQj9VUVFBOIVIISI15+jI3CGACGE3aLg4tjOlsoIJEmAEMKuW+yz+rZ2IURPWfY7jychhuzhmRD6y4mKCHghQAjhRRs4CQQ+FiCEsFsNXBzb2VIZgSQJEELYdYt9Vt+WEIJJCP1VRUUE4hUghIjXn6MjwCREhGuAi+MIsTkUAh4LEELYNYd9Vt\/WKoR48R03CVGkf8IKFS8qaJAf\/K+3mIRQsKQEAj4KEEL42BXOKacFmISwaz8Xx3a2VEYgSQKEEHbdYp\/VtyWEYBJCf1VREYF4BQgh4vXn6FkgcNVVV8mMGTOksLCwyU\/z9NNPy\/z581N+YkKIlEQZv4CL44w7rdOEAAAgAElEQVTpeCMCWSVACGHXTvZZfVuzEOJAT1n2nx5PQgxlEkJ\/NVERAT8ECCH86ANnkWCBESNGyJgxYyQ\/P58QwvM+cnHseYM4PQQiEiCEsINmn9W3JYRgEkJ\/VVERgXgFCCHi9efoWSBQXl4uN954oxw4cEDcFMPBgwfP+ql2794t+\/fvT\/mJmYRISZTxC7g4zpiONyKQVQKEEHbtZJ\/Vt7ULIUrlJ\/\/h7yTE97\/+Js+E0F9OVETACwFCCC\/awEkkWeCRRx6Rq6++Wl5\/\/XW59dZbpaGhoVkfhxCiWXxNvpmLYztbKiOQJAFCCLtusc\/q2xJCMAmhv6qoiEC8AoQQ8fpz9IQLuOdALFiwQC699FKprq6WiRMnNvsTEUI0m\/CcBbg4trOlMgJJEiCEsOsW+6y+rVUI8fM\/lMpPflusf8IKFd2vY8z\/xm4mIRQsKYGAjwKEED52hXNKjEDPnj1l9uzZctFFF8nixYvlsccea\/a5E0I0m5AQwo6QyghkhQAhhF0bCSH0bQkhmITQX1VURCBeAUKIeP05esIFhgwZInfffXfwKZ555hnp3bu3lJaWSuvWraW+vl527NghTz75pLzwwguhPykhRGiqtF\/IxXHaZLwBgawUIISwayv7rL6tWQhRWyrP+joJ0a5BvsckhP5ioiICnggQQnjSCE4jmQK333673HLLLdKiRQs5efKktGzZ8owP4sKIFStWSEVFRagPSQgRiimjF3FxnBEbb0Ig6wQIIexayj6rb0sIwSSE\/qqiIgLxChBCxOvP0RMuMGvWLBk4cGDwKWpra+Wpp56Sqqqq4Oc6b7rpJhk6dKi0b99ejh49KgsXLpSlS5em\/MSEECmJMn4BF8cZ0\/FGBLJKgBDCrp3ss\/q2ViHEL97uJc++4ukzIdodk3+4gWdC6K8mKiLghwAhhB994CwSKjB\/\/nzp1auXvPvuuzJ58mTZvn17o0\/iAooJEyZIUVFR8OsZY8eOlbq6uiY\/LSGE3WLg4tjOlsoIJEmAEMKuW+yz+raEEExC6K8qKiIQrwAhRLz+HD0HBKZPny7XXHONHD58WNzkxIYNG1KGEAWtusvv\/+OPjV53oLZefrH+3RwQs\/uIXBzb2VIZgSQJEELYdYt9tnm2hw9fLw3HLm5UxP2\/\/fSnW2XGjBnNK37au5cvXy6b3u4ly3\/j5yTEhe2OScX\/ZhJCreEUQsAzAUIIzxrC6WSfwDe\/+U258847gw\/mfs7TPcCyqT83CfGZP7tC3nm7\/owQ4p8rdmcfUISfiIvjCLE5FAIeCxBC2DWHfbZ5tgf+cL80NHRsVOSDD\/5c1qxZQwjRPFrejQACHgkQQnjUDE4lOwVGjBghY8aMCT7cE088ETw3IlUIsee1jvLc0v3ZCRLjp+LiOEZ8Do2ARwKEEHbNYJ\/Vt7X6Osam\/b1kxcsl+iesUNFNQnx3xBsyfPhwqanh6xgKpJRAwCsBQgiv2sHJJE0gLy8veCbE22+\/Lfv3nz00OPULGsePH5fvfe978uyzzxJCxNRoLo5jguewCHgmQAhh1xD2WX1bQghCCP1VRUUE4hUghIjXn6MnWKBfv37BaGS7du2kurpaJk6ceNZPM2\/ePPnyl78sBw8elEmTJskrr7xCCBFT37k4jgmewyLgmQAhhF1D2Gf1ba1CiF\/W9JKVHk9CPHojkxD6q4mKCPghQAjhRx84iwQKFBYWivt1jG7dugUBw5QpU2Tr1q2NPon7mc6\/\/du\/ldatW8umTZtk\/PjxKT8pv46RkijjF3BxnDEdb0QgqwQIIezayT6rb0sIwSSE\/qqiIgLxChBCxOvP0RMuMHLkSHH\/x4UMBw4ckCeffFKqqqokPz9fbrvtNrn++uulbdu25wwpzvbxCSHsFgUXx3a2VEYgSQKEEHbdYp\/Vt7UKITbvu0JWbvX0mRCfOiaPfHMXz4TQX05URMALAUIIL9rASSRVwD0T4t5775Vrr702CB7O9uemJCoqKmTdunWhPiYhRCimjF7ExXFGbLwJgawTIISwayn7rL4tIQSTEPqriooIxCtACBGvP0fPEgEXQtx4441yySWXSJs2beTkyZNy+PBh2bx5szz22GNpPdmZEMJuUXBxbGdLZQSSJEAIYdct9ll9W6sQ4lf7rpCf\/trfSYi5NzEJob+aqIiAHwKEEH70gbNA4CMBQgi7xcDFsZ0tlRFIkgAhhF232Gf1bQkhmITQX1VURCBeAUKIeP05OgJnCBBC2C0KLo7tbKmMQJIECCHsusU+q29rFkLsvUKee8nfSYg5NzMJob+aqIiAHwKEEH70gbNAgEmICNYAF8cRIHMIBBIgQAhh1yT2WX1bQggmIfRXFRURiFeAECJef46OAJMQEa4BLo4jxOZQCHgsQAhh1xz2WX1bqxBiy54rZJWnkxAlnzoms8uYhNBfTVREwA8BQgg\/+sBZIMAkRARrgIvjCJA5BAIJECCEsGsS+6y+LSEEkxD6q4qKCMQrQAgRrz9HR4BJiAjXABfHEWJzKAQ8FiCEsGsO+6y+rVUI8dJbV8iqLX4+E8JNQsz6FpMQ+quJigj4IUAI4UcfOAsEmISIYA1wcRwBModAIAEChBB2TWKf1bclhGASQn9VURGBeAUIIeL15+gIMAkR4Rrg4jhCbA6FgMcChBB2zWGf1be1CyF6yepf+TsJMfOWN2T48OFSU0MIob+qqIhAvAKEEPH6c3QECCEiXANcHEeIzaEQ8FiAEMKuOeyz+raEEOFCiLy8PCkrK5Nhw4ZJcXGxtGrVSurr64MQY\/HixbJ69eq0mtO\/f38ZOXKkXH755ZKfny8nTpyQuro6Wb9+vSxYsECOHDmSVj1ejAACHwsQQrAaEPBM4Ac\/+IHsea2jPLd0v2dnlvzT4eI4+T3kEyCgIUAIoaF49hrss\/q2ViHEr9\/sJas3ezoJccExeWhk+EmI9u3by4wZM6RPnz7S0NAgtbW1QWDQoUMHKSkpkWPHjsmKFSukoqIiVINGjx4tN954YxBkHDp0SPbv3y9t2rSRzp07iws7tm3bJvfcc0\/wb\/whgED6AoQQ6ZvxDgRMBQgh7Hi5OLazpTICSRIghLDrFvusvi0hROpJiFGjRgVTEG46Yf78+bJmzZqgES4wKC8vl6FDhwZTETNnzpQNGzY02SQXZLhAo127drJ27VqZO3duEGy4v8GDBwf1XOixfPlyeeSRR\/QbTkUEckCAECIHmsxHTJYAIYRdv7g4trOlMgJJEiCEsOsW+6y+rVkIsbuXrPF4EmLG\/w03CeGChkWLFkmPHj1k1apVQdBw+l9hYWEQTHTr1k2qqqpk+vTpTTZp7NixctNNN8nu3bvlzjvvPGPawU1AuGdVvPXWWzJu3LhgSoI\/BBBIT4AQIj0vXo2AuQAhhB0xF8d2tlRGIEkChBB23WKf1bclhGh6EqJLly5B8NCpUydZuHChVFZWntGEOXPmyIABA6S6ulomTpzYZJOmTp0qgwYNkl\/+8pdnfe2IESNkzJgxcuDAgeArGbt27dJvOhURyHIBQogsbzAfL3kChBB2PePi2M6WyggkSYAQwq5b7LP6tlYhxNY3esmaX\/r7TIgHbws3CZFK\/PRJiY0bN8qkSZNSvaXJfz81KbFv3z759re\/HUxE8IcAAukJEEKk58WrETAXIISwI+bi2M6WyggkSYAQwq5b7LP6toQQqZ8J0ZS6ex6E+9pEy5Ytg69tLFmyJOMmdezYUebNmyddu3aVTZs2yfjx4zOuxRsRyGUBQohc7j6f3UsBQgi7tnBxbGdLZQSSJEAIYdct9ll9W0KIzEOI7t27B1\/VcL9qsWPHDnFTDJn+ooWbqHjooYfE\/XTnn\/70J3n44Ydl3bp1+g2nIgI5IEAIkQNN5iMmS4AQwq5fXBzb2VIZgSQJEELYdYt9Vt\/WNITYVKx\/wmlWLLngmHyp1x\/PeNeQL78bPACypiazEMJNLbhfuSgtLZWDBw8Gv3Lhvo6Ryd\/pv7Lh3r9y5cpgIoI\/BBDITIAQIjM33oWAmQAhhBmtcHFsZ0tlBJIkQAhh1y32WX3bXAgh\/s\/XahvBlRQek5ILGjIOIdzXJdyvYLhfxKirq2v0s53pdsgFEBMmTJBrr702eOsnf7Yz3Xq8HgEERAghWAUIeCZACGHXEC6O7WypjECSBAgh7LrFPqtvaxZC7Oolz\/8i\/kmIs4m56Yjpo3ZnFEL07ds3+FUL9xUMNwFRUVGR8dcm2rdvL3\/\/938vX\/rSl+T48ePy3HPPBfUaGhr0G01FBHJIgBAih5rNR02GACGEXZ+4OLazpTICSRIghLDrFvusvi0hRPivYwwePFjKy8ulqKgo+BrHrFmzZMuWLRk1xX2d48EHHwy+zlFfXx880NI92JI\/BBBovgAhRPMNqYCAqgAhhCpno2JcHNvZUhmBJAkQQth1i31W39YqhHh5p7+TEMWF6U9CDBw4MPjahAsgdu7cKdOmTZPt27dn1BA3AfHoo48GAcThw4fl8ccfl2effTajWrwJAQTOFCCEYFUg4JkAIYRdQ7g4trOlMgJJEiCEsOsW+6y+LSFE6kmIPn36BA+hdAHEtm3bZMqUKRk\/0NI9A2L+\/PnSu3fvZn+dQ381UBGB7BAghMiOPvIpskiAEMKumVwc29lSGYEkCRBC2HWLfVbf1iyE+K9Sef7nfj4ToriwQabfEe6ZEKeHBnv37pXJkydnPAHhujdq1CgpKyuTEydOyMKFC2Xp0qX6TaUiAjkuQAiR4wuAj++fACGEXU+4OLazpTICSRIghLDrFvusvi0hRNOTEIMGDQqCh4KCgpT41dXVwUMr3V+\/fv2C6Yn8\/Hxx116VlZVSWFgYTEG4X9VI9bdv3z655557ZNeuXaleyr8jgMAnBAghWBIIeCZACGHXEC6O7WypjECSBAgh7LrFPqtvaxlCVL3o7yTEtDvDTUKMHj06mFxo0aJFSvxUIcRVV10VBBMujEj1RwiRSoh\/R+DcAoQQrA4EPBMghLBrCBfHdrZURiBJAoQQdt1in9W3JYRI\/UwIfXUqIoCApQAhhKUutRHIQIAQIgO0kG\/h4jgkFC9DIMsFCCHsGsw+q29rFkLsKJWqF4v0T1ihonsmxLTRb8rw4cMzfsCkwmlQAgEEjAQIIYxgKYtApgKEEJnKpX4fF8epjXgFArkgQAhh12X2WX1bQggmIfRXFRURiFeAECJef46OwBkChBB2i4KLYztbKiOQJAFCCLtusc\/q25qFEK+XStULHk9C\/B2TEPqriYoI+CFACOFHHzgLBD4SIISwWwxcHNvZUhmBJAkQQth1i31W35YQgkkI\/VVFRQTiFSCEiNefoyPAJESEa4CL4wixORQCHgsQQtg1h31W39YqhPjN6z2lqtrfSYjvjH2LZ0LoLycqIuCFACGEF23gJBD4WIBJCLvVwMWxnS2VEUiSACGEXbfYZ\/VtCSGYhNBfVVREIF4BQoh4\/Tk6AkxCRLgGuDiOEJtDIeCxACGEXXPYZ\/VtzUKI7T2l6meeTkK0b5Dv3MUkhP5qoiICfggQQvjRB84CgY8EmISwWwxcHNvZUhmBJAkQQth1i31W35YQgkkI\/VVFRQTiFSCEiNefoyPAJESEa4CL4wixORQCHgsQQtg1h31W39YshPi9m4Ror3\/CChWL3STEuD08E0LBkhII+ChACOFjVzinnBZwkxCDBr0s7Yt+mNMOfPhkCXBTZ9MvbuhsXKlqJ8BeoG9778xusuPNn8mMGTPUii9fvlx+Qwih5kkhBBBIT4AQIj0vXo2AuQAhhDkxBzAQ4MbDAFVECCFsXKlqJ8BeoG9rF0L0kKqNHk9ClO9lEkJ\/OVERAS8ECCG8aAMngcDHAoQQrIYkCnDjYdM1QggbV6raCbAX6NsSQvBMCP1VRUUE4hUghIjXn6MjcIYAIQSLIokC3HjYdI0QwsaVqnYC7AX6tmYhxGs9pOrfC\/VPWKFi8EyI8fuYhFCwpAQCPgoQQvjYFc4ppwUIIXK6\/Yn98Nx42LSOEMLGlap2AuwF+raEEExC6K8qKiIQrwAhRLz+HB0BJiFYA1khwI2HTRsJIWxcqWonwF6gb2sWQrzq+STE3UxC6K8mKiLghwAhhB994CwQ+EiASQgWQxIFuPGw6RohhI0rVe0E2Av0bQkhmITQX1VURCBeAUKIeP05OgJMQrAGskKAGw+bNhJC2LhS1U6AvUDf1iyE2PY5WbvB02dCFDXI1HtqeCaE\/nKiIgJeCBBCeNEGTgKBjwWYhGA1JFGAGw+brhFC2LhS1U6AvUDflhCCSQj9VUVFBOIVIISI15+jI8AkBGsgKwS48bBpIyGEjStV7QTYC\/RtTUOI9Rfon7BCxWI3CXHvfiYhFCwpgYCPAoQQPnaFc8ppASYhcrr9if3w3HjYtI4QwsaVqnYC7AX6toQQTELoryoqIhCvACFEvP4cHQEmIVgDWSHAjYdNGwkhbFypaifAXqBvaxZC\/K67rPV2EuK4TJ3AJIT+aqIiAn4IEEL40QfOAoGPBJiEYDEkUYAbD5uuEULYuFLVToC9QN+WEIJJCP1VRUUE4hUghIjXn6MjwCQEayArBLjxsGkjIYSNK1XtBNgL9G3NQoj\/7C5r\/+1T+iesULG46LhMve9tngmhYEkJBHwUIITwsSucU04LMAmR0+1P7IfnxsOmdYQQNq5UtRNgL9C3JYRgEkJ\/VVERgXgFCCHi9efoCDAJwRrICgFuPGzaSAhh40pVOwH2An1buxCim6z9V48nISbVMgmhv5yoiIAXAoQQXrSBk0DgYwEmIVgNSRTgxsOma4QQNq5UtRNgL9C3JYRgEkJ\/VVERgXgFCCHi9efoCDAJwRrICgFuPGzaSAhh40pVOwH2An1bsxDiP9wkRDv9E1aoGDwTYvIfmIRQsKQEAj4KEEL42BXOKacFmITI6fYn9sNz42HTOkIIG1eq2gmwF+jbEkIwCaG\/qqiIQLwChBDx+nN0BJiEYA1khQA3HjZtJISwcaWqnQB7gb6tWQjx28tl7TpPJyGKj8vU+w8wCaG\/nKiIgBcChBBetIGTQOBjASYhWA1JFODGw6ZrhBA2rlS1E2Av0LclhGASQn9VURGBeAUIIeL15+gIMAnBGsgKAW48bNpICGHjSlU7AfYCfVu7EOKzsvb\/FeifsELFYjcJMeVdJiEULCmBgI8ChBA+doVzymkBJiFyuv2J\/fDceNi0jhDCxpWqdgLsBfq2hBBMQuivKioiEK8AIUS8\/hwdASYhWANZIcCNh00bCSFsXKlqJ8BeoG9rFkK88llZu7at\/gkrVAwmIR44yCSEgiUlEPBRgBDCx65wTjktwCRETrc\/sR+eGw+b1hFC2LhS1U6AvUDflhCCSQj9VUVFBOIVIISI15+jI8AkBGsgKwS48bBpIyGEjStV7QTYC\/RtzUKI31zm8STECZk6Nb1JiLy8PCkrK5Nhw4ZJcXGxtGrVSurr66WmpkYWL14sq1evzrg57du3l+9+97tywQUXyD333CO7du3KuBZvRAABEUIIVgECngkwCeFZQzidUALceIRiSvtFhBBpk\/GGmAXYC\/QbQAiRehLChQQzZsyQPn36SENDg9TW1kpdXZ106NBBSkpK5NixY7JixQqpqKhIu0Ft27aVqVOnSv\/+\/YNAgxAibULegMAZAoQQLAoEPBMghPCsIZxOKAFuPEIxpf0iQoi0yXhDzALsBfoNMAshXr5Mqqra6J+wQsXi4hPynWmHQj8TYtSoUcEUxJEjR2T+\/PmyZs2a4CzcdER5ebkMHTo0mIqYOXOmbNiwIfQZduzYUR544AG58sorpUWLFrJv3z5CiNB6vBCBcwsQQrA6EPBMgBDCs4ZwOqEEuPEIxZT2iwgh0ibjDTELsBfoN4AQoulJCBc0LFq0SHr06CGrVq0KgobT\/woLC4Ngolu3blJVVSXTp09P2SQ3\/eBCjW984xvipixOnDgRhBBMQqSk4wUIhBIghAjFxIsQiE6AECI6a46kJ8CNh57l6ZUIIWxcqWonwF6gb2sXQlwqVc+fr3\/CChWDSYjp74WahOjSpUsQPHTq1EkWLlwolZWVZ5zBnDlzZMCAAVJdXS0TJ05MeYYjRoyQMWPGBM+V2L17t2zevDkIJA4cOMAkREo9XoBAagFCiNRGvAKBSAUIISLl5mBKAtx4KEF+ogwhhI0rVe0E2Av0bQkhUj8Toin10yclNm7cKJMmTUrZpBtuuEFcELFy5UpZtmxZEIa4UIIQIiUdL0AglAAhRCgmXoRAdAKEENFZcyQ9AW489CxPr0QIYeNKVTsB9gJ9W7MQYmtXfychStwkxB9DTUKkEnfPgxg3bpy0bNky+NrGkiVLUr3ljH8\/NRlBCJE2HW9A4KwChBAsDAQUBE79LNSQIUOCJzHn5+dn\/LNQhBAKDaFE5ALceNiQE0LYuFLVToC9QN+WECLzSYju3bsHX9Xo3Lmz7NixQ8aOHSuHDh1Ku0mEEGmT8QYEmhQghGCBINBMgdN\/Fso9tOiTf+5pzOn8LBQhRDMbwttjEeDGw4adEMLGlap2AuwF+rZmIcSvL5GqNa31TzjNipd3Py7XDTl6xru6dT\/erEkI98sW7mc7S0tL5eDBgzJ37lxxX8fI5I8QIhM13oPAuQUIIVgdCDRTYPbs2cHDjtzf7373u+AJzNu2bZO\/\/Mu\/lFtvvVUuvPBCOXz4sDz88MOybt26lEcjhEhJxAs8FODGw6YphBA2rlS1E2Av0LfN9hCiuOSE9PvSsUZwxSUnpd+Xj2UcQnTt2jX4FQz3ixh1dXWNfrYzkw4RQmSixnsQIIRgDSBgIjBo0CCZPHmyFBQUyK9+9Su5++67paGh4aNjDR48WO69915p165d6CcyE0KYtIqixgLceNgAE0LYuFLVToC9QN\/WNIRYna9\/wgoVXTDxnYeOZBRC9O3bN\/gFDPcVDDcBUVFREeo\/AjV12oQQCk2lBAKnCTAJwXJAoBkCDzzwgFx33XXB\/8i5\/\/tLL73UqJp7VoQLFdxvV7\/22mvy7W9\/W44cOdLkEQkhmtEQ3hqbADceNvSEEDauVLUTYC\/QtyWECP9MCPcff8rLy6WoqEhqampk1qxZsmXLlmY3hRCi2YQUQKCRACEECwKBDAUKCwtlwYIFcumllwb\/A3fXXXdlWKnx2wghVBgpErEANx424IQQNq5UtRNgL9C3NQshXvqMVK1qpX\/CChXd1zG+M+v9tCYhBg4cKBMmTAgCiJ07d8q0adNk+\/btCmcjwc918hOdKpQUQSAQIIRgISCQocCVV14ZJOzuf+yefvrp4PuGGn+EEBqK1IhagBsPG3FCCBtXqtoJsBfo2xJCpJ6E6NOnT\/AQSndN5p7LNWXKlGASQuuPEEJLkjoIfChACMFKQCBDAfc8iEmTJgU\/x+mCg61btwa\/Q\/35z39eWrduzU90ZujK25IpwI2HTd8IIWxcqWonwF6gb2sWQmzpIlWr8vRPWKFiMAkx+2ioSQj31Vf3H4J69+4te\/fuDZ7VpTUBceqjEEIoNJUSCJwmQAjBckAgQ4FT\/4Pk3r5+\/Xrp379\/8ADKT\/7xE50ZAvO2RAlw42HTLkIIG1eq2gmwF+jbEkI0PdFw+kPCU+lXV1cHD610f\/369QumJ079x6TKyspzvp0QIpUs\/45AegKEEOl58WoEPhI49T9IrVq1kpMnT8oHH3wgzz\/\/vDzxxBPBFIR7YOW3vvUt6dChgxw9elQWLlwoS5cuTSnI1zFSEvECDwW48bBpCiGEjStV7QTYC\/RtrUKIl7f8mVQ95+8kxLQ59aEmIUaPHi1lZWXSokWLlPiEECmJeAECkQgQQkTCzEGyUeBUCOES9HOFDF\/4whfkwQcfDIKI119\/XcaOHRv8XnVTfy6EGDBgv7Qv+mGjl+Xl6X23MRv7wWeKV4AbDxt\/QggbV6raCbAXNM+2pMOZP5l5a\/klsuPNnwX\/1V7rb\/ny5ZItIYSWCXUQQCA6AUKI6Kw5UpYJnB5C\/Pa3vw2emtzQ0HDGp7zvvvvk61\/\/ehA+uAclffJnPD\/5BhdCuAcsffLv\/PNflos7\/l2WKfJxskWAGw+bThJC2LhS1U6AvaB5trOf6CUXniWIWLNmjX4I8avOUvXTls07YaN3F194UqbNbQg1CWF0CpRFAAFDAUIIQ1xKZ7fA1VdfHfz8U0FBgZw+3vfJT+2+knHbbbfJ8ePH5dFHHxV3IdHU37kmIdx7mIbI7jWV5E\/HjYdN9wghbFypaifAXtA820gnIQghmtcs3o0AAhkLEEJkTMcbc12gZ8+eMnv27OCrFk2FELfffrvccsst8v777wc\/6blhw4aUIcSgQS+f8XWMXPfm8\/stwI2HTX8IIWxcqWonwF6gb2v2TIjNnaTqp+fpn7BCxeILRaY9fJxJCAVLSiDgowAhhI9d4ZwSI\/D444\/LlVdeKXv27JG77rrrrL9JPX36dLnmmmuktrZW3FczXn31VUKIxHSYEw0rwI1HWKn0XkcIkZ4Xr45fgL1AvweEEDwTS39VURGBeAUIIeL15+gJFxg1alTwRGb3t3LlSpk3b16jTzRw4ECZMGGCFBUVyaZNm2T8+PEpPzG\/jpGSiBd4KMCNh01TCCFsXKlqJ8BeoG9rF0J0lKqV+uerUTGYhHhEmITQwKQGAh4KEEJ42BROKTkC7du3D57zUFpaGvws5\/r16+Wpp54Kph7cT3SOHDlSLrzwwuChlO6rGxs3bkz54QghUhLxAg8FuPGwaQohhI0rVe0E2Av0bQkhmITQX1VURCBeAUKIeP05ehYIdO\/eXaZOnSqXXXbZWT+N+\/nOJUuWyKJFi0J9WkKIUEy8yDMBbjxsGkIIYeNKVTsB9gJ9W7MQ4pcXy\/MrT+qfsEJFNwkx\/dHzmIRQsKQEAj4KEEL42BXOKXECbdu2lTvuuEO++tWvBpMP5513nrjwYdu2bckQbIoAABALSURBVPKjH\/1INm\/eHPozEUKEpuKFHglw42HTDEIIG1eq2gmwF+jbEkIwCaG\/qqiIQLwChBDx+nN0BM4QIIRgUSRRgBsPm64RQti4UtVOgL1A39YuhPi0PL\/ihP4JK1QMJiHm5TEJoWBJCQR8FCCE8LErnFNOCxBC5HT7E\/vhufGwaR0hhI0rVe0E2Av0bQkhmITQX1VURCBeAUKIeP05OgJMQrAGskKAGw+bNhJC2LhS1U6AvUDf1iyE2HSRPL\/8uP4JK1QsvrCFTK\/IZxJCwZISCPgoQAjhY1c4p5wWYBIip9uf2A\/PjYdN6wghbFypaifAXqBvSwjBJIT+qqIiAvEKEELE68\/REWASgjWQFQLceNi0kRDCxpWqdgLsBfq2ViHE1l9cKM8vb9A\/YYWKJRe5SYjzmYRQsKQEAj4KEEL42BXOKacFmITI6fYn9sNz42HTOkIIG1eq2gmwF+jbEkIwCaG\/qqiIQLwChBDx+nN0BJiEYA1khQA3HjZtJISwcaWqnQB7gb6tXQhRIs8\/W69\/wgoVg0mIfyhgEkLBkhII+ChACOFjVzinnBZgEiKn25\/YD8+Nh03rCCFsXKlqJ8BeoG9LCMEkhP6qoiIC8QoQQsTrz9ERYBKCNZAVAtx42LSREMLGlap2AuwF+rZmIcTPi2TNs0f1T1ihYslF58mD3\/sUkxAKlpRAwEcBQggfu8I55bQAkxA53f7EfnhuPGxaRwhh40pVOwH2An1bQggmIfRXFRURiFeAECJef46OAJMQrIGsEODGw6aNhBA2rlS1E2Av0Le1CyHay5qffKB\/wgoVg0mI+YVMQihYUgIBHwUIIXzsCueU0wJMQuR0+xP74bnxsGkdIYSNK1XtBNgL9G0JIZiE0F9VVEQgXgFCiHj9OToCTEKwBrJCgBsPmzYSQti4UtVOgL1A39YshHixUNb85Ij+CStUDCYhvl\/MJISCJSUQ8FGAEMLHrnBOOS3AJEROtz+xH54bD5vWEULYuFLVToC9QN+WEIJJCP1VRUUE4hUghIjXn6MjwCQEayArBLjxsGkjIYSNK1XtBNgL9G2tQohfv\/gpWbPsT\/onrFCx5KKWMuMHFzIJoWBJCQR8FCCE8LErnFNOCzAJkdPtT+yH58bDpnWEEDauVLUTYC\/QtyWEYBJCf1VREYF4BQgh4vXn6AgwCcEayAoBbjxs2kgIYeNKVTsB9gJ9W7MQ4oV2smbZH\/VPWKFiMAnx2KeZhFCwpAQCPgoQQvjYFc4ppwWYhMjp9if2w3PjYdM6QggbV6raCbAX6NsSQjAJob+qqIhAvAKEEPH6c3QEmIRgDWSFADceNm0khLBxpaqdAHuBvq1dCFEgqyvf0z9hhYpuEuKhBR2ZhFCwpAQCPgoQQvjYFc4ppwWYhMjp9if2w3PjYdM6QggbV6raCbAX6NsSQjAJob+qqIhAvAKEEPH6c3QEmIRgDWSFADceNm0khLBxpaqdAHuBvq1ZCFHdRlZX1umfsELFkg558tCCzkxCKFhSAgEfBQghfOwK55TTAkxC5HT7E\/vhufGwaR0hhI0rVe0E2Av0bQkhmITQX1VURCBeAUKIeP05OgJMQrAGskKAGw+bNhJC2LhS1U6AvUDf1iqEeKn6fFn944P6J6xQ0U1CzHz8M0xCKFhSAgEfBQghfOwK55TTAkxC5HT7E\/vhufGwaR0hhI0rVe0E2Av0bQkhmITQX1VURCBeAUKIeP05OgJMQrAGskKAGw+bNhJC2LhS1U6AvUDf1iyE+Fm+rP7xu\/onrFCxpEMrmbmwK5MQCpaUQMBHAUIIH7vCOeW0AJMQOd3+xH54bjxsWkcIYeNKVTsB9gJ9W0IIJiH0VxUVEYhXgBAiXn+OjgCTEKyBrBDgxsOmjYQQNq5UtRNgL9C3tQshWsmqZ97RP2GFim4SYtY\/XpbWJEReXp6UlZXJsGHDpLi4WFq1aiX19fVSU1MjixcvltWrVyucGSUQQEBDgBBCQ5EaCCgKMAmhiEmpyAS48bChJoSwcaWqnQB7gb4tIUTqSYj27dvLjBkzpE+fPtLQ0CC1tbVSV1cnHTp0kJKSEjl27JisWLFCKioq9BtERQQQSFuAECJtMt6AgK0AIYStL9VtBLjxsHElhLBxpaqdAHuBvi0hROoQYtSoUcEUxJEjR2T+\/PmyZs2aoBFuOqK8vFyGDh0aTEXMnDlTNmzYoN8kKiKAQFoChBBpcfFiBOwFkhRCNDR0lLy81BcH9mrZdQTn+uHFU3Jsk3LjUdIhX96prU\/MgklKCMFeYLOk2AtsXF3VJO0FZiHExjxZ9cwf7JCbUTn4OsaibqG+juGChkWLFkmPHj1k1apVQdBw+l9hYWEQTHTr1k2qqqpk+vTpzTgz3ooAAhoChBAaitRAQFEgSSHEgT\/cL+4i+eKOf6coQKkPPvhz2V\/zfel66dWJwUhKCDH7n3rJc0tr5Bfr\/Xwi\/CcbnpQQgr3A5v+rshfYuLqqs5\/oJc89nYy9gBCi6UC+S5cuQfDQqVMnWbhwoVRWVp6xcObMmSMDBgyQ6upqmThxot3CojICCIQSIIQIxcSLEIhOgBAiOmtfj8SNh11nCCFsbAkhbFzZC2xcCSFEli9fLls2nierltbaITejsptUmf1Pnws1CZHqMKdPSmzcuFEmTZqU6i38OwIIGAsQQhgDUx6BdAUIIdIVy77Xc+Nh11NCCBtbQggbV\/YCG1dCiNwKIdzzIMaNGyctW7YMvraxZMkSu4VFZQQQCCVACBGKiRchEJ0AIUR01r4eiRsPu84QQtjYEkLYuLIX2LgSQnwYQuza1jr4Soqvf+4rM8OHDw9+YjPTv+7duwdf1ejcubPs2LFDxo4dK4cOHcq0HO9DAAElAUIIJUjKIKAlQAihJZncOtx42PWOEMLGlhDCxpW9wMaVEOLDEKJjxw8fguzzX3NCCPf53M92lpaWysGDB2Xu3Lnivo7BHwIIxC9ACBF\/DzgDBBoJuBDC\/c41fwgggAACCCCAgBNwPznpbqi1\/pJynbF169aMPnLXrl2DX8Fwv4hRV1fX6Gc7MyrImxBAQFWAEEKVk2IINF\/AJfdJ+K8Tzf+kVEAAAQQQQACBMALuKwnN+VpCmGNky2v69u0b\/AKG+wqGm4CoqKiQdevWZcvH43MgkBUChBBZ0UY+BAIIIIAAAggggAACuS0wePBgKS8vl6KioiC0mTVrlmzZsiW3Ufj0CHgoQAjhYVM4JQQQQAABBBBAAAEEEAgvMHDgQJkwYUIQQOzcuVOmTZsm27dvD1+AVyKAQGQChBCRUXMgBBBAAAEEEEAAAQQQ0BZwz7hwz8xwAcS2bdtkypQpfH1FG5l6CCgKEEIoYlIKAQQQQAABBBBAAAEEohPIy8sLHjzZu3dv2bt3r0yePJkJiOj4ORICGQkQQmTExpsQQAABBBBAAAEEEEAgboFBgwYFwUNBQUHKU6murg4eWskfAgjEK0AIEa8\/R0cAAQQQQAABBBBAAIEMBUaPHi1lZWXSokWLlBUIIVIS8QIEIhEghIiEmYMggAACCCCAAAIIIIAAAggggAAhBGsAAQQQQAABBBBAAAEEEEAAAQQiESCEiISZgyCAAAIIIIAAAggggAACCCCAACEEawABBBBAAAEEEEAAAQQQQAABBCIRIISIhJmDIIAAAggggAACCCCAAAIIIIAAIQRrAAEEEEAAAQQQQAABBBBAAAEEIhEghIiEmYMggAACCCCAAAIIIIAAAggggAAhBGsAAQQQQAABBBBAAAEEEEAAAQQiESCEiISZgyCAAAIIIIAAAggggAACCCCAACEEawABBBBAAAEEEEAAAQQQQAABBCIRIISIhJmDIIAAAggggAACCCCAAAIIIIAAIQRrAAEEEEAAAQQQQAABBBBAAAEEIhEghIiEmYMggAACCCCAAAIIIIAAAggggAAhBGsAAQQQQAABBBBAAAEEEEAAAQQiESCEiISZgyCAAAIIIIAAAggggAACCCCAACEEawABBBBAAAEEEEAAAQQQQAABBCIRIISIhJmDIIAAAggggAACCCCAAAIIIIAAIQRrAAEEEEAAAQQQQAABBBBAAAEEIhEghIiEmYMggAACCCCAAAIIIIAAAggggAAhBGsAAQQQQAABBBBAAAEEEEAAAQQiESCEiISZgyCAAAIIIIAAAggggAACCCCAACEEawABBBBAAAEEEEAAAQQQQAABBCIRIISIhJmDIIAAAggggAACCCCAAAIIIIAAIQRrAAEEEEAAAQQQQAABBBBAAAEEIhEghIiEmYMggAACCCCAAAIIIIAAAggggAAhBGsAAQQQQAABBBBAAAEEEEAAAQQiESCEiISZgyCAAAIIIIAAAggggAACCCCAACEEawABBBBAAAEEEEAAAQQQQAABBCIRIISIhJmDIIAAAggggAACCCCAAAIIIIAAIQRrAAEEEEAAAQQQQAABBBBAAAEEIhEghIiEmYMggAACCCCAAAIIIIAAAggggAAhBGsAAQQQQAABBBBAAAEEEEAAAQQiESCEiISZgyCAAAIIIIAAAggggAACCCCAACEEawABBBBAAAEEEEAAAQQQQAABBCIRIISIhJmDIIAAAggggAACCCCAAAIIIIAAIQRrAAEEEEAAAQQQQAABBBBAAAEEIhEghIiEmYMggAACCCCAAAIIIIAAAggggAAhBGsAAQQQQAABBBBAAAEEEEAAAQQiESCEiISZgyCAAAIIIIAAAggggAACCCCAACEEawABBBBAAAEEEEAAAQQQQAABBCIRIISIhJmDIIAAAggggAACCCCAAAIIIIAAIQRrAAEEEEAAAQQQQAABBBBAAAEEIhEghIiEmYMggAACCCCAAAIIIIAAAggggAAhBGsAAQQQQAABBBBAAAEEEEAAAQQiESCEiISZgyCAAAIIIIAAAggggAACCCCAACEEawABBBBAAAEEEEAAAQQQQAABBCIRIISIhJmDIIAAAggggAACCCCAAAIIIIAAIQRrAAEEEEAAAQQQQAABBBBAAAEEIhEghIiEmYMggAACCCCAAAIIIIAAAggggAAhBGsAAQQQQAABBBBAAAEEEEAAAQQiESCEiISZgyCAAAIIIIAAAggggAACCCCAACEEawABBBBAAAEEEEAAAQQQQAABBCIRIISIhJmDIIAAAggggAACCCCAAAIIIIAAIQRrAAEEEEAAAQQQQAABBBBAAAEEIhEghIiEmYMggAACCCCAAAIIIIAAAggggAAhBGsAAQQQQAABBBBAAAEEEEAAAQQiESCEiISZgyCAAAIIIIAAAggggAACCCCAACEEawABBBBAAAEEEEAAAQQQQAABBCIRIISIhJmDIIAAAggggAACCCCAAAIIIIAAIQRrAAEEEEAAAQQQQAABBBBAAAEEIhEghIiEmYMggAACCCCAAAIIIIAAAggggAAhBGsAAQQQQAABBBBAAAEEEEAAAQQiEfj\/Oqj0wW\/6U9kAAAAASUVORK5CYII=","height":330,"width":549}}
%---
%[output:6aec2274]
%   data: {"dataType":"text","outputData":{"text":"Per-half-run counts for View_x_Category (7-9):\n","truncated":false}}
%---
%[output:38d6f7c2]
%   data: {"dataType":"text","outputData":{"text":"\tFirst Half:\t7 8 9 7 9 8 \n\tLast Half:\t9 8 7 9 7 8 \n","truncated":false}}
%---
%[output:51a68621]
%   data: {"dataType":"text","outputData":{"text":"Generating 5 6x6 squares without replacement. Balancing mode is: both. The maximum number of search iterations is set to 1e+06...\n\nThere are 720 permutations of 1-6. Each permutation pairs with 102 of the others (14.17%).\n\nThe chance of randomly selecting a valid set to form a square is roughly 1 in 7e+101.\nThis script uses a heuristic method that is much more efficient, but this should give you an idea of how long it might take to run.\n\nGenerating balanced square 1 of 5...found a solution after 18 iterations\nGenerating balanced square 2 of 5...found a solution after 23 iterations\nGenerating balanced square 3 of 5...found a solution after 27 iterations\nGenerating balanced square 4 of 5...found a solution after 24 iterations\nGenerating balanced square 5 of 5...found a solution after 7 iterations\n","truncated":false}}
%---
%[output:4a850fbb]
%   data: {"dataType":"text","outputData":{"text":"Par x Run order of first main conditions:\n","truncated":false}}
%---
%[output:688b897f]
%   data: {"dataType":"text","outputData":{"text":"    \"2D_Object\"    \"3D_Object\"    \"2D_Face\"      \"3D_Hand\"      \"2D_Hand\"      \"3D_Face\"      \"2D_Object\"    \"2D_Hand\"  \n    \"2D_Hand\"      \"2D_Face\"      \"3D_Face\"      \"2D_Object\"    \"3D_Hand\"      \"3D_Object\"    \"3D_Hand\"      \"3D_Face\"  \n    \"2D_Face\"      \"2D_Object\"    \"2D_Hand\"      \"3D_Object\"    \"3D_Face\"      \"3D_Hand\"      \"2D_Face\"      \"3D_Object\"\n    \"3D_Object\"    \"3D_Hand\"      \"2D_Object\"    \"3D_Face\"      \"2D_Face\"      \"2D_Hand\"      \"3D_Object\"    \"2D_Object\"\n    \"3D_Hand\"      \"3D_Face\"      \"3D_Object\"    \"2D_Hand\"      \"2D_Object\"    \"2D_Face\"      \"2D_Hand\"      \"2D_Face\"  \n    \"3D_Face\"      \"2D_Hand\"      \"3D_Hand\"      \"2D_Face\"      \"3D_Object\"    \"2D_Object\"    \"3D_Hand\"      \"3D_Face\"  \n    \"2D_Hand\"      \"2D_Object\"    \"3D_Face\"      \"3D_Hand\"      \"2D_Face\"      \"3D_Object\"    \"3D_Hand\"      \"3D_Face\"  \n    \"3D_Hand\"      \"3D_Object\"    \"2D_Object\"    \"2D_Face\"      \"2D_Hand\"      \"3D_Face\"      \"2D_Face\"      \"2D_Object\"\n    \"2D_Face\"      \"3D_Face\"      \"3D_Object\"    \"2D_Hand\"      \"3D_Hand\"      \"2D_Object\"    \"3D_Object\"    \"2D_Hand\"  \n    \"2D_Object\"    \"3D_Hand\"      \"2D_Hand\"      \"3D_Object\"    \"3D_Face\"      \"2D_Face\"      \"2D_Hand\"      \"3D_Hand\"  \n    \"3D_Face\"      \"2D_Hand\"      \"2D_Face\"      \"2D_Object\"    \"3D_Object\"    \"3D_Hand\"      \"2D_Face\"      \"3D_Object\"\n    \"3D_Object\"    \"2D_Face\"      \"3D_Hand\"      \"3D_Face\"      \"2D_Object\"    \"2D_Hand\"      \"2D_Object\"    \"3D_Face\"  \n    \"2D_Hand\"      \"3D_Hand\"      \"3D_Face\"      \"3D_Object\"    \"2D_Object\"    \"2D_Face\"      \"3D_Hand\"      \"3D_Face\"  \n    \"2D_Face\"      \"2D_Object\"    \"3D_Object\"    \"3D_Face\"      \"3D_Hand\"      \"2D_Hand\"      \"2D_Face\"      \"2D_Object\"\n    \"3D_Hand\"      \"3D_Object\"    \"2D_Face\"      \"2D_Hand\"      \"3D_Face\"      \"2D_Object\"    \"2D_Hand\"      \"3D_Object\"\n    \"3D_Object\"    \"2D_Hand\"      \"2D_Object\"    \"3D_Hand\"      \"2D_Face\"      \"3D_Face\"      \"3D_Hand\"      \"3D_Object\"\n    \"3D_Face\"      \"2D_Face\"      \"3D_Hand\"      \"2D_Object\"    \"2D_Hand\"      \"3D_Object\"    \"2D_Face\"      \"2D_Object\"\n    \"2D_Object\"    \"3D_Face\"      \"2D_Hand\"      \"2D_Face\"      \"3D_Object\"    \"3D_Hand\"      \"2D_Hand\"      \"3D_Face\"  \n    \"2D_Object\"    \"3D_Object\"    \"2D_Hand\"      \"2D_Face\"      \"3D_Face\"      \"3D_Hand\"      \"3D_Face\"      \"2D_Face\"  \n    \"3D_Face\"      \"2D_Hand\"      \"3D_Hand\"      \"2D_Object\"    \"2D_Face\"      \"3D_Object\"    \"3D_Hand\"      \"2D_Hand\"  \n    \"3D_Object\"    \"2D_Face\"      \"2D_Object\"    \"3D_Hand\"      \"2D_Hand\"      \"3D_Face\"      \"3D_Object\"    \"2D_Object\"\n    \"3D_Hand\"      \"3D_Face\"      \"2D_Face\"      \"2D_Hand\"      \"3D_Object\"    \"2D_Object\"    \"3D_Face\"      \"2D_Object\"\n    \"2D_Face\"      \"3D_Hand\"      \"3D_Object\"    \"3D_Face\"      \"2D_Object\"    \"2D_Hand\"      \"2D_Face\"      \"3D_Hand\"  \n    \"2D_Hand\"      \"2D_Object\"    \"3D_Face\"      \"3D_Object\"    \"3D_Hand\"      \"2D_Face\"      \"3D_Object\"    \"2D_Hand\"  \n    \"3D_Object\"    \"2D_Face\"      \"3D_Face\"      \"3D_Hand\"      \"2D_Object\"    \"2D_Hand\"      \"2D_Face\"      \"3D_Face\"  \n    \"2D_Hand\"      \"2D_Object\"    \"3D_Hand\"      \"3D_Face\"      \"2D_Face\"      \"3D_Object\"    \"2D_Object\"    \"3D_Hand\"  \n    \"3D_Face\"      \"3D_Object\"    \"2D_Object\"    \"2D_Face\"      \"2D_Hand\"      \"3D_Hand\"      \"3D_Object\"    \"2D_Hand\"  \n    \"2D_Face\"      \"3D_Hand\"      \"3D_Object\"    \"2D_Hand\"      \"3D_Face\"      \"2D_Object\"    \"3D_Face\"      \"3D_Object\"\n    \"3D_Hand\"      \"2D_Hand\"      \"2D_Face\"      \"2D_Object\"    \"3D_Object\"    \"3D_Face\"      \"2D_Face\"      \"2D_Object\"\n    \"2D_Object\"    \"3D_Face\"      \"2D_Hand\"      \"3D_Object\"    \"3D_Hand\"      \"2D_Face\"      \"2D_Hand\"      \"3D_Hand\"  \n\n","truncated":false}}
%---
%[output:5b49398e]
%   data: {"dataType":"text","outputData":{"text":"Orders will be written to: ..\\Orders\\\n","truncated":false}}
%---
%[output:296cc0eb]
%   data: {"dataType":"text","outputData":{"text":"Participant 1 of 30:\n","truncated":false}}
%---
%[output:31cb35b6]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:6a978c51]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 46 1 30 15 9 44 45 58 55 35 82 21 88 3 80 41 67 13 54 85 95 49 68 89 77 20 18 39 31 52 14 96 40 69 60 27 78 65 73 94 71 17 64 7 36 87 24 19 8 2 76 12 32 72 33 43 10 83 62 26 48 57 59 34 25 91 42 92 81 16 50 70 63 86 75 28 74 61 90 38 56 11 29 93 6 84 51 22 53 47 23 4 66 37 79 5\n","truncated":false}}
%---
%[output:6fd971bf]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [13 4] at positions [18 92]\n","truncated":false}}
%---
%[output:5fb0cad6]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 5 6 7 8 18 21 22 25 26 28 37 40 41 44 54 56 58 63 65 67 72 73 74 76 78 86 89 90 91 93\n","truncated":false}}
%---
%[output:87bb215c]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR01_RUN01.xlsx\n","truncated":false}}
%---
%[output:6b49dc12]
%   data: {"dataType":"text","outputData":{"text":"Participant 2 of 30:\n","truncated":false}}
%---
%[output:7b8952a3]
%   data: {"dataType":"text","outputData":{"text":"Participant 3 of 30:\n","truncated":false}}
%---
%[output:93cd5356]
%   data: {"dataType":"text","outputData":{"text":"Participant 4 of 30:\n","truncated":false}}
%---
%[output:8d62fcfd]
%   data: {"dataType":"text","outputData":{"text":"Participant 5 of 30:\n","truncated":false}}
%---
%[output:07cf1438]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR01_RUN02.xlsx\n","truncated":false}}
%---
%[output:92ed4683]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 9 10 11 12 14 15 17 19 20 32 34 37 38 43 44 46 52 54 58 59 64 65 72 74 75 78 84 85 86 91 92 96\n","truncated":false}}
%---
%[output:903ea019]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [74 60] at positions [25 70]\n","truncated":false}}
%---
%[output:495ed668]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 86 45 77 47 4 29 69 59 68 90 3 14 44 52 56 22 87 89 25 34 96 50 6 70 74 13 49 83 71 18 7 94 1 48 33 19 24 63 36 80 20 95 55 54 9 8 31 28 43 53 79 58 37 5 75 46 38 21 12 84 91 65 76 15 51 81 39 93 30 60 23 78 92 62 73 32 2 66 10 35 16 85 67 41 72 64 27 42 26 57 82 11 61 40 88 17\n","truncated":false}}
%---
%[output:4d6774ba]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:5eb00fe0]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR01_RUN03.xlsx\n","truncated":false}}
%---
%[output:080c6b01]
%   data: {"dataType":"text","outputData":{"text":"Participant 6 of 30:\n","truncated":false}}
%---
%[output:4bac2713]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 13 14 17 19 25 26 33 36 37 38 39 40 43 44 47 50 52 53 55 67 68 72 73 74 76 81 83 86 90 96 97\n","truncated":false}}
%---
%[output:6a123b1e]
%   data: {"dataType":"text","outputData":{"text":"Participant 7 of 30:\n","truncated":false}}
%---
%[output:449b690b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [58 89] at positions [45 84]\n","truncated":false}}
%---
%[output:0127a708]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR01_RUN04.xlsx\n","truncated":false}}
%---
%[output:1b16023a]
%   data: {"dataType":"text","outputData":{"text":"Participant 8 of 30:\n","truncated":false}}
%---
%[output:5d79b18b]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 2 90 93 44 13 60 91 18 28 52 14 38 53 74 22 11 26 72 49 29 81 79 34 36 19 47 71 4 73 95 15 6 67 68 56 48 88 63 59 85 27 24 16 1 58 41 32 50 10 25 43 8 83 84 42 92 69 82 64 70 66 5 35 46 61 31 75 23 86 7 17 40 65 39 96 55 51 37 80 54 12 77 30 89 3 45 57 94 78 33 20 62 76 87 21 9\n","truncated":false}}
%---
%[output:4297aac7]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 6 11 13 15 16 20 23 25 28 29 30 31 39 41 44 53 63 66 70 75 76 77 78 82 84 86 87 88 92 94 98\n","truncated":false}}
%---
%[output:93137596]
%   data: {"dataType":"text","outputData":{"text":"Participant 9 of 30:\n","truncated":false}}
%---
%[output:9f2c9167]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR01_RUN05.xlsx\n","truncated":false}}
%---
%[output:66342917]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:5b733e83]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [9 37] at positions [20 93]\n","truncated":false}}
%---
%[output:36ca69c2]
%   data: {"dataType":"text","outputData":{"text":"Participant 10 of 30:\n","truncated":false}}
%---
%[output:969eac69]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 5 13 14 17 18 25 26 28 30 32 33 34 40 41 44 56 60 64 66 70 71 74 76 78 84 87 88 93 94 97 98\n","truncated":false}}
%---
%[output:52061ae8]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR01_RUN06.xlsx\n","truncated":false}}
%---
%[output:51382c5e]
%   data: {"dataType":"text","outputData":{"text":"Participant 11 of 30:\n","truncated":false}}
%---
%[output:2ad3bfa6]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 68 90 86 3 95 74 52 41 38 60 96 23 77 24 2 50 54 65 11 9 30 27 63 7 67 42 10 36 22 45 73 72 43 87 35 21 81 62 32 92 12 66 69 91 34 89 51 8 40 46 71 18 58 84 85 26 28 4 1 31 76 49 25 44 59 79 16 94 75 13 55 53 48 6 78 20 57 80 93 33 83 61 19 70 47 14 82 17 88 15 39 29 37 56 5 64\n","truncated":false}}
%---
%[output:686b11ad]
%   data: {"dataType":"text","outputData":{"text":"Participant 12 of 30:\n","truncated":false}}
%---
%[output:63ed7d6f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [57 91] at positions [42 78]\n","truncated":false}}
%---
%[output:1d50dff5]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR01_RUN07.xlsx\n","truncated":false}}
%---
%[output:612471b8]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 7 13 18 20 23 28 29 30 34 36 43 44 46 49 55 58 60 63 65 67 76 78 79 90 91 93 95 96 97 98\n","truncated":false}}
%---
%[output:2417a6e9]
%   data: {"dataType":"text","outputData":{"text":"Participant 13 of 30:\n","truncated":false}}
%---
%[output:22ba55c3]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:09d4f68a]
%   data: {"dataType":"text","outputData":{"text":"Participant 14 of 30:\n","truncated":false}}
%---
%[output:345e7aa3]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR01_RUN08.xlsx\n","truncated":false}}
%---
%[output:68e22f03]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 21 1 3 44 20 80 79 25 83 62 95 18 61 24 35 96 15 86 47 60 71 54 10 64 36 14 70 33 69 11 27 19 17 94 82 76 88 68 7 87 53 57 8 34 41 6 28 43 75 31 13 9 51 29 58 92 23 72 45 48 84 37 63 74 66 49 55 42 22 90 93 5 78 85 77 39 65 91 56 26 46 16 89 4 38 81 30 52 2 67 50 73 32 12 59 40\n","truncated":false}}
%---
%[output:5b3fa52f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 7 8 10 11 14 16 18 19 20 29 32 39 44 49 50 52 54 59 61 70 73 75 77 79 80 86 88 91 92 93\n","truncated":false}}
%---
%[output:262045be]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [39 48] at positions [41 84]\n","truncated":false}}
%---
%[output:85753cef]
%   data: {"dataType":"text","outputData":{"text":"Participant 15 of 30:\n","truncated":false}}
%---
%[output:8950383e]
%   data: {"dataType":"text","outputData":{"text":"Participant 16 of 30:\n","truncated":false}}
%---
%[output:008f2423]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR02_RUN01.xlsx\n","truncated":false}}
%---
%[output:3b09a922]
%   data: {"dataType":"text","outputData":{"text":"Participant 17 of 30:\n","truncated":false}}
%---
%[output:5a5c74eb]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 8 9 10 12 13 15 19 21 24 29 35 39 41 48 51 53 59 65 67 69 71 78 79 89 90 91 92 94 95 97\n","truncated":false}}
%---
%[output:94e12901]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:943fd53a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [91 74] at positions [2 90]\n","truncated":false}}
%---
%[output:6792395b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR02_RUN02.xlsx\n","truncated":false}}
%---
%[output:22d6018c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 60 15 74 37 70 90 62 29 41 33 4 13 91 19 3 24 67 63 61 79 7 43 95 44 50 36 23 20 83 80 78 18 59 85 92 16 52 65 11 69 39 10 51 26 46 81 21 53 93 56 5 27 86 71 96 38 49 47 25 9 82 89 6 14 34 40 75 58 64 87 55 17 76 30 28 57 2 32 66 77 42 72 8 48 31 94 1 84 68 88 35 54 45 12 73 22\n","truncated":false}}
%---
%[output:8b4535a4]
%   data: {"dataType":"text","outputData":{"text":"Participant 18 of 30:\n","truncated":false}}
%---
%[output:063b34ff]
%   data: {"dataType":"text","outputData":{"text":"Participant 19 of 30:\n","truncated":false}}
%---
%[output:1df78162]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 3 5 6 7 14 18 19 31 32 33 38 41 43 46 50 51 53 54 56 57 59 61 62 66 68 71 74 80 84 86\n","truncated":false}}
%---
%[output:1788784c]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR02_RUN03.xlsx\n","truncated":false}}
%---
%[output:843450f9]
%   data: {"dataType":"text","outputData":{"text":"Participant 20 of 30:\n","truncated":false}}
%---
%[output:8733a8e7]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [15 49] at positions [35 49]\n","truncated":false}}
%---
%[output:41b86dcd]
%   data: {"dataType":"text","outputData":{"text":"Participant 21 of 30:\n","truncated":false}}
%---
%[output:18a613e4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 42 91 30 80 9 81 78 23 41 22 90 55 35 75 48 10 53 73 61 3 69 93 11 34 46 49 27 17 2 28 54 95 45 13 1 83 88 21 7 6 36 82 63 62 67 65 57 47 51 12 71 16 26 79 39 18 59 56 25 44 33 68 92 4 50 86 96 38 84 70 76 29 24 85 15 94 32 89 52 5 19 14 37 72 64 40 20 58 31 74 87 66 43 60 77 8\n","truncated":false}}
%---
%[output:65cb2c22]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR02_RUN04.xlsx\n","truncated":false}}
%---
%[output:6317dec1]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 5 8 9 12 15 20 24 27 30 32 34 37 41 42 57 58 63 66 67 72 74 77 80 83 86 88 90 95 96 98\n","truncated":false}}
%---
%[output:4e721f98]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:982abd94]
%   data: {"dataType":"text","outputData":{"text":"Participant 22 of 30:\n","truncated":false}}
%---
%[output:5e574608]
%   data: {"dataType":"text","outputData":{"text":"Participant 23 of 30:\n","truncated":false}}
%---
%[output:44c8fcdf]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR02_RUN05.xlsx\n","truncated":false}}
%---
%[output:666bdc87]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [76 84] at positions [8 95]\n","truncated":false}}
%---
%[output:0977d3fd]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 7 13 14 15 19 20 21 23 25 32 35 40 41 44 49 54 57 63 64 65 66 67 68 69 71 72 73 78 83 90 98\n","truncated":false}}
%---
%[output:741f549a]
%   data: {"dataType":"text","outputData":{"text":"Participant 24 of 30:\n","truncated":false}}
%---
%[output:2e916823]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 27 62 79 86 4 72 24 33 19 94 28 71 9 88 56 7 17 8 1 57 89 47 43 59 55 42 81 66 74 58 22 31 65 40 15 39 73 41 91 90 78 5 11 37 29 50 68 64 49 18 45 53 13 87 82 30 32 6 69 93 63 44 35 75 21 84 2 52 96 34 3 26 38 92 67 76 60 77 85 61 36 16 25 95 48 20 80 12 70 23 10 46 51 14 54 83\n","truncated":false}}
%---
%[output:19763ab0]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR02_RUN06.xlsx\n","truncated":false}}
%---
%[output:0f8d53ae]
%   data: {"dataType":"text","outputData":{"text":"Participant 25 of 30:\n","truncated":false}}
%---
%[output:81b23ac1]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:579a8079]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 5 8 10 17 19 21 26 29 32 34 38 41 42 47 48 57 62 66 67 72 77 80 82 84 86 88 91 92 95 96 97\n","truncated":false}}
%---
%[output:232832f7]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [51 39] at positions [12 66]\n","truncated":false}}
%---
%[output:2094909e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR02_RUN07.xlsx\n","truncated":false}}
%---
%[output:7916dbf2]
%   data: {"dataType":"text","outputData":{"text":"Participant 26 of 30:\n","truncated":false}}
%---
%[output:833fca4f]
%   data: {"dataType":"text","outputData":{"text":"Participant 27 of 30:\n","truncated":false}}
%---
%[output:59f8ec4d]
%   data: {"dataType":"text","outputData":{"text":"Participant 28 of 30:\n","truncated":false}}
%---
%[output:72c98474]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 7 18 20 22 24 29 30 36 37 38 42 44 45 46 50 55 56 70 71 72 73 75 76 79 82 83 85 91 92 95\n","truncated":false}}
%---
%[output:16be5d4d]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR02_RUN08.xlsx\n","truncated":false}}
%---
%[output:4e6da2c4]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 20 67 38 33 94 58 95 76 30 52 3 32 13 7 73 60 54 22 35 21 29 83 4 56 66 2 91 86 23 15 44 77 68 90 43 11 79 92 96 12 16 59 45 57 72 74 39 27 36 37 87 31 51 55 42 62 26 81 75 28 70 6 46 65 50 85 48 9 17 24 61 14 82 64 47 18 1 69 89 19 40 78 8 49 10 88 71 63 80 41 93 34 5 25 84 53\n","truncated":false}}
%---
%[output:9e0b1457]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [35 95] at positions [11 83]\n","truncated":false}}
%---
%[output:4b76dda2]
%   data: {"dataType":"text","outputData":{"text":"Participant 29 of 30:\n","truncated":false}}
%---
%[output:89117f25]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:2ee1e6e9]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 6 9 11 26 30 34 35 39 41 42 43 45 47 48 53 55 57 58 59 60 61 65 67 79 81 86 92 94 96 98\n","truncated":false}}
%---
%[output:1af7cae1]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR03_RUN01.xlsx\n","truncated":false}}
%---
%[output:12450fbf]
%   data: {"dataType":"text","outputData":{"text":"Participant 30 of 30:\n","truncated":false}}
%---
%[output:781454c6]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:934faa69]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [92 20] at positions [44 73]\n","truncated":false}}
%---
%[output:53139cd9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 7 10 58 28 45 35 16 27 23 6 70 51 9 84 17 72 83 11 46 32 95 69 68 19 61 90 47 91 88 60 53 38 80 36 64 77 3 52 42 33 30 13 78 4 34 82 94 71 75 63 96 20 56 22 48 2 85 49 57 79 86 1 8 29 76 39 55 12 41 67 31 92 43 18 24 87 73 37 93 62 89 26 40 5 81 14 21 54 25 66 59 65 15 50 44 74\n","truncated":false}}
%---
%[output:9c473ec7]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR03_RUN02.xlsx\n","truncated":false}}
%---
%[output:4ed2c230]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 7 8 10 12 15 16 18 25 26 33 34 35 45 46 50 52 58 64 65 66 71 72 75 84 87 91 94 95 97 98\n","truncated":false}}
%---
%[output:761b9583]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:3ac63172]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:34efbc60]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:13a6ccdb]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR03_RUN03.xlsx\n","truncated":false}}
%---
%[output:95d7e1b3]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [23 1] at positions [43 62]\n","truncated":false}}
%---
%[output:3624d6cb]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 8 11 12 20 21 22 24 25 30 34 39 41 43 47 48 49 51 53 60 61 65 68 71 74 76 80 86 87 91 92 93 96\n","truncated":false}}
%---
%[output:6bbcc06d]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:91d0e64c]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 52 25 1 83 77 3 78 29 36 92 35 26 31 93 22 68 48 58 88 10 46 11 60 67 61 50 34 65 84 64 7 18 53 21 79 70 28 37 42 20 16 15 91 85 59 6 4 33 81 87 32 19 57 80 41 54 82 12 76 49 56 47 9 51 89 71 72 94 38 39 75 5 27 96 43 14 74 55 8 90 13 24 95 66 2 40 30 63 23 69 44 86 62 73 17 45\n","truncated":false}}
%---
%[output:2533c265]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR03_RUN04.xlsx\n","truncated":false}}
%---
%[output:952a9a63]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:818d4cb0]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:89bef8d8]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [58 66] at positions [14 95]\n","truncated":false}}
%---
%[output:45269f42]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 7 9 12 15 23 24 25 26 32 33 34 39 46 47 48 50 51 56 60 62 64 68 73 75 78 79 81 92 93 97 98\n","truncated":false}}
%---
%[output:675ac97d]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR03_RUN05.xlsx\n","truncated":false}}
%---
%[output:8ce4dd8a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:543ebb4d]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:01c1e81d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 94 of 96\n\t\tFound solution after 3 attempt(s): 42 44 61 59 36 25 26 70 48 65 8 15 40 83 32 41 11 71 72 17 49 85 14 30 88 80 63 75 89 95 55 2 51 29 4 94 46 91 13 67 18 34 31 92 53 28 5 45 10 87 66 76 6 16 24 21 69 62 3 54 33 39 78 96 37 64 79 43 23 56 82 86 20 81 60 52 47 1 35 93 74 22 68 50 7 77 90 12 84 38 58 27 9 19 57 73\n","truncated":false}}
%---
%[output:126b4e8c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:894d1895]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR03_RUN06.xlsx\n","truncated":false}}
%---
%[output:2e0ca428]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 7 8 11 17 19 26 28 29 31 33 34 35 36 37 46 56 61 67 70 76 77 78 79 81 82 83 90 94 95 96 98\n","truncated":false}}
%---
%[output:4acaff30]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [31 79] at positions [28 91]\n","truncated":false}}
%---
%[output:658dc280]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:091653ae]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:7f775347]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR03_RUN07.xlsx\n","truncated":false}}
%---
%[output:71afaa04]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:7854d222]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 3 4 11 13 19 26 34 35 36 40 42 47 48 49 53 55 56 57 60 61 70 74 75 76 78 79 85 90 94 95\n","truncated":false}}
%---
%[output:5561dd04]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 76 70 12 43 11 27 63 39 95 31 90 56 13 74 88 33 28 30 73 22 45 69 42 35 64 24 16 91 3 50 77 51 62 89 78 48 81 83 66 18 4 10 23 75 85 2 94 54 49 46 71 53 9 44 25 93 20 40 55 86 36 1 80 6 5 60 17 19 58 67 79 32 57 8 38 47 7 68 52 72 87 84 41 96 14 29 34 61 92 65 37 21 15 59 26 82\n","truncated":false}}
%---
%[output:6dc98897]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [37 78] at positions [17 73]\n","truncated":false}}
%---
%[output:81b1300e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR03_RUN08.xlsx\n","truncated":false}}
%---
%[output:0e7861b5]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:3bd8f542]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:2231aaa2]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 6 8 12 16 18 19 20 23 27 33 35 41 42 47 48 51 52 60 63 64 65 69 70 73 75 82 87 88 93 96 98\n","truncated":false}}
%---
%[output:32d8391e]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:705e7abc]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:8e908a3e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR04_RUN01.xlsx\n","truncated":false}}
%---
%[output:8af33d12]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 95 53 94 25 84 41 69 37 51 40 4 80 78 58 15 44 48 26 42 91 3 7 50 23 49 57 68 22 70 87 67 5 31 13 93 82 59 27 19 74 47 92 72 1 18 89 10 34 12 90 96 28 8 14 64 73 79 17 62 35 71 88 36 60 81 77 54 52 11 75 63 30 38 21 20 65 32 86 39 46 16 43 29 61 85 56 33 76 83 6 55 9 24 2 66 45\n","truncated":false}}
%---
%[output:7b5a15e9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [32 42] at positions [35 76]\n","truncated":false}}
%---
%[output:16498011]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 6 13 15 16 22 29 32 33 35 38 41 43 46 47 49 50 51 52 53 54 57 64 68 70 72 74 75 77 78 89 91\n","truncated":false}}
%---
%[output:5fec1c78]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:96d1dd8a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR04_RUN02.xlsx\n","truncated":false}}
%---
%[output:5ba7ad6e]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:6be0b0ee]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:69c22ea5]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:3a99122f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 6 9 10 12 13 14 17 19 24 25 26 29 47 48 49 50 52 53 58 61 65 67 75 80 86 89 91 92 93 94 95\n","truncated":false}}
%---
%[output:679d6851]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR04_RUN03.xlsx\n","truncated":false}}
%---
%[output:8a4ce55e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [23 6] at positions [10 79]\n","truncated":false}}
%---
%[output:42adb24e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 68 61 38 4 5 95 89 52 55 85 36 27 96 20 74 66 28 15 30 18 49 7 44 63 80 2 54 31 40 34 94 71 46 75 87 9 76 90 60 73 43 23 17 51 37 10 72 22 39 41 86 42 50 93 77 14 58 64 1 45 78 70 57 19 65 81 32 12 11 26 91 3 82 83 59 16 35 62 69 29 56 21 6 53 84 13 67 48 88 25 79 8 92 47 24 33\n","truncated":false}}
%---
%[output:03f1a468]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:209a562b]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:5d6991ce]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR04_RUN04.xlsx\n","truncated":false}}
%---
%[output:06d94548]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 6 7 11 12 15 20 22 28 31 34 36 37 38 42 47 49 53 54 56 57 60 63 66 67 69 73 81 82 85 86 96 98\n","truncated":false}}
%---
%[output:27f444cf]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:7e3ab7e4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [11 64] at positions [42 72]\n","truncated":false}}
%---
%[output:84835964]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:85d2720f]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR04_RUN05.xlsx\n","truncated":false}}
%---
%[output:0cc17b7b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 94 of 96\n\t\tAttempt 4 ran out of options at trial 94 of 96\n\t\tFound solution after 5 attempt(s): 61 52 74 92 7 11 79 59 85 33 13 62 36 29 63 5 37 88 49 31 27 70 6 81 82 72 45 60 51 8 18 47 35 65 80 21 86 28 4 67 39 46 68 83 76 24 1 91 22 94 56 73 16 57 95 3 12 40 84 89 42 25 20 66 53 23 34 2 26 50 44 55 78 71 17 58 41 14 75 10 87 69 64 9 32 15 43 54 96 38 77 90 30 48 19 93\n","truncated":false}}
%---
%[output:3c6a1618]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 7 10 12 15 16 18 19 20 21 26 29 31 32 34 39 50 55 56 57 60 62 64 66 68 74 79 82 90 95 97 98\n","truncated":false}}
%---
%[output:2c7abcf3]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:3d524f89]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:592f0d55]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR04_RUN06.xlsx\n","truncated":false}}
%---
%[output:9a99e159]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [85 20] at positions [13 88]\n","truncated":false}}
%---
%[output:9bb752c9]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:054ae947]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:7dd740ed]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 4 6 10 12 21 22 24 28 34 37 41 44 46 47 51 59 64 66 67 74 76 78 83 84 89 93 94 96 97 98\n","truncated":false}}
%---
%[output:6d92a788]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR04_RUN07.xlsx\n","truncated":false}}
%---
%[output:7ad656c2]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:4a824dd5]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 93 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tAttempt 5 ran out of options at trial 95 of 96\n\t\tFound solution after 6 attempt(s): 15 93 10 5 72 80 1 44 3 27 46 28 74 56 20 83 52 4 54 84 95 40 59 47 96 75 26 9 34 77 43 36 87 21 32 58 67 85 33 29 24 64 60 69 71 51 81 6 55 8 89 23 7 70 13 14 22 65 35 50 30 48 11 57 62 41 38 66 31 94 90 68 92 53 17 42 76 19 12 39 49 45 91 18 63 2 79 16 88 61 78 82 73 37 25 86\n","truncated":false}}
%---
%[output:29bcc280]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [55 41] at positions [36 91]\n","truncated":false}}
%---
%[output:7b4f1678]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:0f37069f]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR04_RUN08.xlsx\n","truncated":false}}
%---
%[output:96c4ee01]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 12 14 15 17 21 22 24 26 31 32 33 40 42 43 50 54 57 63 66 67 74 79 80 83 88 89 90 93 94 97\n","truncated":false}}
%---
%[output:5f42d776]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:500ea915]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:7ca993e4]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:6e343b65]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [17 38] at positions [5 73]\n","truncated":false}}
%---
%[output:472b1fc6]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR05_RUN01.xlsx\n","truncated":false}}
%---
%[output:2828ec03]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 7 9 10 12 15 20 23 25 26 31 35 36 38 44 52 60 64 66 68 70 71 73 74 76 78 84 88 92 95 97\n","truncated":false}}
%---
%[output:527eaf56]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 94 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 39 57 41 93 2 91 33 44 17 23 68 79 40 73 53 29 87 96 58 10 8 66 32 1 63 89 70 84 31 37 12 22 61 64 74 3 48 5 77 83 24 16 21 47 65 4 60 34 52 94 36 82 78 43 27 95 7 9 45 35 30 56 54 11 92 81 59 28 75 67 55 69 18 20 15 90 14 46 6 51 86 80 42 71 85 26 76 25 88 38 50 19 62 72 49 13\n","truncated":false}}
%---
%[output:574abcab]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:98c0aaf4]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:64a38e7b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR05_RUN02.xlsx\n","truncated":false}}
%---
%[output:2ca8d6f7]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:9f73acbc]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 9 11 17 20 21 23 26 27 28 31 34 36 42 43 46 55 67 68 69 70 71 72 74 77 80 81 83 88 90 96 98\n","truncated":false}}
%---
%[output:8f217fb9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [15 23] at positions [27 50]\n","truncated":false}}
%---
%[output:207af2df]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:2512385d]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR05_RUN03.xlsx\n","truncated":false}}
%---
%[output:5c89f9b9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 93 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 95 of 96\n\t\tAttempt 5 ran out of options at trial 95 of 96\n\t\tFound solution after 6 attempt(s): 28 20 50 86 63 75 51 42 52 57 7 34 68 14 10 82 71 21 67 79 38 18 37 90 13 58 19 92 81 31 12 76 83 36 8 17 6 2 26 74 61 11 47 43 48 77 23 89 30 25 33 32 60 91 93 40 88 56 73 39 16 53 27 69 9 95 80 84 15 72 78 64 46 59 62 3 41 65 24 54 44 22 96 45 4 55 94 49 66 35 85 1 70 87 29 5\n","truncated":false}}
%---
%[output:934a4705]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:931b673a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 5 11 13 15 19 25 33 34 36 38 40 41 42 48 51 52 56 58 59 60 63 64 70 71 72 73 75 86 87 93\n","truncated":false}}
%---
%[output:4a701c70]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:7a002e97]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR05_RUN04.xlsx\n","truncated":false}}
%---
%[output:44ed6682]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [3 63] at positions [20 77]\n","truncated":false}}
%---
%[output:7a80708f]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:735608c8]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:69bc56b1]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 6 7 9 13 14 16 18 23 31 32 37 42 44 47 54 67 72 73 77 79 84 85 86 87 88 90 91 92 95 97\n","truncated":false}}
%---
%[output:1391fda4]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR05_RUN05.xlsx\n","truncated":false}}
%---
%[output:638f610a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 94 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tFound solution after 5 attempt(s): 86 43 2 50 56 82 90 32 12 6 74 13 85 79 80 17 25 96 64 22 63 78 37 58 42 47 19 75 59 4 18 46 81 8 40 71 92 91 10 57 93 28 30 68 38 15 31 45 21 3 48 84 69 11 72 51 41 54 26 53 7 87 62 60 77 83 35 39 67 24 88 33 65 70 61 5 1 95 52 66 89 29 36 16 44 27 73 20 94 76 14 55 34 49 23 9\n","truncated":false}}
%---
%[output:630b1bc0]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:309fae85]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:17ed8437]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [41 7] at positions [43 89]\n","truncated":false}}
%---
%[output:78f42eed]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR05_RUN06.xlsx\n","truncated":false}}
%---
%[output:3f08f26a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 7 8 15 18 20 21 23 26 33 35 37 43 44 48 51 52 53 56 58 60 65 68 70 76 78 80 83 89 91 97\n","truncated":false}}
%---
%[output:58f46b2a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:17553d1a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:9b4cc254]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 62 83 33 66 65 14 19 27 39 30 84 77 81 54 75 44 6 5 48 63 12 59 61 31 70 26 9 73 51 46 85 2 92 91 28 55 96 80 37 40 88 95 50 64 32 67 69 4 17 57 1 53 74 56 35 29 16 93 20 42 13 7 43 72 87 15 78 24 18 89 47 52 71 49 38 34 10 45 25 86 11 76 90 21 60 3 58 94 36 79 41 82 68 23 8 22\n","truncated":false}}
%---
%[output:34033383]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR05_RUN07.xlsx\n","truncated":false}}
%---
%[output:3380168b]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:4b251e22]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 13 19 20 22 26 29 31 32 34 40 41 42 45 46 47 49 51 52 53 58 59 61 70 74 75 80 81 83 86 93 94 96\n","truncated":false}}
%---
%[output:79aed29c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [56 1] at positions [29 49]\n","truncated":false}}
%---
%[output:3421fc87]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:28225f96]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR05_RUN08.xlsx\n","truncated":false}}
%---
%[output:79942a55]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:30bfef14]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:714110f4]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 66 85 24 55 17 32 39 90 6 31 3 81 86 77 65 11 16 56 58 95 49 37 26 87 47 64 5 74 63 79 34 80 18 76 10 44 8 30 27 92 69 52 70 28 46 35 51 50 14 12 57 45 19 59 82 91 41 43 67 75 40 96 20 78 88 54 21 13 71 15 83 2 38 1 33 23 42 73 93 60 4 84 7 29 61 25 68 36 94 72 22 9 53 48 62 89\n","truncated":false}}
%---
%[output:9e93d3b5]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 5 6 8 14 16 19 21 24 28 29 36 40 42 43 52 54 56 60 63 64 73 77 78 81 83 87 88 95 97 98\n","truncated":false}}
%---
%[output:32fd1040]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [38 61] at positions [9 73]\n","truncated":false}}
%---
%[output:4f3dda26]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR06_RUN01.xlsx\n","truncated":false}}
%---
%[output:603996f9]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:53710f85]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:51c9783b]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:2f14d2d4]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 8 9 10 11 20 22 25 28 30 37 39 42 44 47 51 53 58 61 62 67 70 74 76 81 86 93 94 95 96 98\n","truncated":false}}
%---
%[output:708586be]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR06_RUN02.xlsx\n","truncated":false}}
%---
%[output:51579a64]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:07469782]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [52 33] at positions [36 74]\n","truncated":false}}
%---
%[output:1934e115]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 12 85 67 31 94 51 37 3 13 66 88 25 9 39 72 54 14 53 79 34 30 58 62 20 36 81 15 29 24 71 10 56 92 90 47 48 63 19 95 76 69 4 21 43 91 7 87 17 65 23 52 11 8 33 26 5 70 55 96 60 59 41 49 80 84 45 73 77 38 46 1 64 82 89 42 75 32 27 93 22 78 40 16 86 74 61 44 83 57 28 50 68 6 18 2 35\n","truncated":false}}
%---
%[output:77448363]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:458165d9]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR06_RUN03.xlsx\n","truncated":false}}
%---
%[output:15b7274f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 5 6 12 24 28 31 32 35 36 38 41 42 44 48 52 54 56 62 64 67 68 69 81 83 91 92 94 95 96 98\n","truncated":false}}
%---
%[output:36d6d748]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:8e68f2e2]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:25e561d4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [26 45] at positions [43 66]\n","truncated":false}}
%---
%[output:05c586b3]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR06_RUN04.xlsx\n","truncated":false}}
%---
%[output:1fe00075]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:520f8b63]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 8 13 16 18 20 22 24 25 30 36 40 45 46 47 49 50 52 57 60 61 63 65 70 74 75 77 87 88 89 96 98\n","truncated":false}}
%---
%[output:46cf3306]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 95 of 96\n\t\tFound solution after 4 attempt(s): 85 27 1 38 71 46 39 7 95 50 52 10 2 69 49 74 78 83 70 3 51 25 80 19 24 96 87 5 21 41 54 43 30 60 89 34 92 79 11 55 9 66 47 4 18 59 20 42 88 58 37 23 94 91 33 44 62 81 8 15 82 32 68 86 16 35 65 67 17 28 13 73 53 56 72 12 63 14 48 90 40 22 76 57 84 61 77 36 64 29 45 75 26 6 31 93\n","truncated":false}}
%---
%[output:138cd657]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:2839f385]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR06_RUN05.xlsx\n","truncated":false}}
%---
%[output:3859ae07]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:54949757]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [8 16] at positions [39 88]\n","truncated":false}}
%---
%[output:5e5a51b5]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 8 11 12 14 21 23 26 28 29 30 33 37 38 39 41 48 50 52 56 58 61 62 65 67 72 73 75 80 84 85 86 91\n","truncated":false}}
%---
%[output:22a1bb61]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:2c137f68]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR06_RUN06.xlsx\n","truncated":false}}
%---
%[output:180a7b75]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:274a00f9]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:1a140c9c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 96 78 36 31 39 91 53 71 51 88 90 21 22 57 49 28 8 95 47 33 14 60 4 23 70 19 81 1 74 76 15 42 64 34 77 83 35 11 2 63 65 45 41 55 93 3 89 20 18 73 56 54 48 82 86 72 27 58 29 13 25 87 59 16 5 67 80 9 37 30 44 75 85 40 50 43 17 61 79 92 32 10 68 46 12 62 26 66 7 94 6 38 69 24 84 52\n","truncated":false}}
%---
%[output:5783d4f8]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 3 10 16 22 23 26 29 31 34 36 37 38 39 43 52 61 66 73 74 75 78 80 82 83 84 85 86 89 94 98\n","truncated":false}}
%---
%[output:9471aa8a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR06_RUN07.xlsx\n","truncated":false}}
%---
%[output:1639b750]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [6 41] at positions [2 54]\n","truncated":false}}
%---
%[output:08455fa5]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:4f463106]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:9ea77f12]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:5c100483]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR06_RUN08.xlsx\n","truncated":false}}
%---
%[output:5ab805e1]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 9 11 15 17 21 25 32 33 39 40 42 43 45 46 53 56 59 63 67 72 76 79 81 82 83 87 90 91 95 96\n","truncated":false}}
%---
%[output:87aa9b1f]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:16596e5c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [83 40] at positions [24 89]\n","truncated":false}}
%---
%[output:42d39266]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 73 68 42 66 20 32 52 54 6 8 70 94 14 87 62 67 13 38 12 53 95 27 15 26 83 46 84 65 56 39 24 36 37 50 29 69 88 89 35 21 9 59 64 2 91 49 28 48 1 4 23 93 86 76 74 19 31 61 81 11 79 44 45 51 71 58 34 75 16 43 96 22 80 92 33 85 10 78 63 30 90 77 47 25 5 40 55 3 18 72 17 60 82 57 41 7\n","truncated":false}}
%---
%[output:7b33e19d]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:2daab74c]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR07_RUN01.xlsx\n","truncated":false}}
%---
%[output:4ddd256b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 6 9 13 17 20 22 26 30 31 33 37 39 44 46 52 59 61 62 64 68 69 71 73 74 78 83 84 86 92 95\n","truncated":false}}
%---
%[output:33de0f59]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:2047ee71]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:76094b64]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:77e338b7]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR07_RUN02.xlsx\n","truncated":false}}
%---
%[output:6678329b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [76 25] at positions [4 57]\n","truncated":false}}
%---
%[output:2995bee0]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 41 12 9 82 48 18 26 73 38 96 62 66 90 81 22 40 33 68 69 56 6 24 10 49 53 86 71 11 34 60 28 54 37 25 94 13 79 27 85 21 15 76 95 46 64 2 59 74 63 45 78 80 44 84 72 30 55 23 39 8 32 17 77 5 93 57 52 92 3 36 43 19 61 1 16 75 7 89 88 58 91 65 35 4 31 83 29 42 67 20 70 51 47 87 14 50\n","truncated":false}}
%---
%[output:5c11e99c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 9 15 16 18 20 25 26 32 33 38 41 44 48 49 50 51 53 57 59 61 62 70 73 77 79 81 84 88 91 94\n","truncated":false}}
%---
%[output:7719f595]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:28745c64]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR07_RUN03.xlsx\n","truncated":false}}
%---
%[output:832d81fa]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:691ef61c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:68ae506d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [31 8] at positions [34 92]\n","truncated":false}}
%---
%[output:59eb84e7]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 6 10 13 15 16 18 19 27 35 40 42 43 46 48 52 55 58 60 67 69 70 73 74 75 88 89 90 92 93 94\n","truncated":false}}
%---
%[output:6363ba49]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR07_RUN04.xlsx\n","truncated":false}}
%---
%[output:875b06c5]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:23eee78a]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 56 80 7 48 89 74 91 41 16 23 71 78 18 51 9 88 5 64 54 35 76 38 62 95 63 24 94 82 31 32 39 27 13 1 68 52 21 96 14 69 90 30 53 6 92 58 46 44 8 15 42 79 19 72 36 59 87 85 70 57 77 67 12 20 34 26 29 3 60 61 28 37 81 33 47 65 2 83 43 86 11 22 55 45 4 73 17 66 93 25 84 50 10 49 75 40\n","truncated":false}}
%---
%[output:435f61bf]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:928b7257]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:39d5893b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR07_RUN05.xlsx\n","truncated":false}}
%---
%[output:05da3127]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 13 16 22 24 26 27 30 32 33 37 40 42 44 48 50 52 53 56 65 67 68 72 73 76 78 80 92 94 95 98\n","truncated":false}}
%---
%[output:6d4e819f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [91 78] at positions [7 63]\n","truncated":false}}
%---
%[output:6423451a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:784593cd]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:0a3161dc]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR07_RUN06.xlsx\n","truncated":false}}
%---
%[output:944fa3ca]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 3 1 71 68 21 8 89 90 69 56 64 23 57 70 36 77 81 47 39 4 55 91 27 42 18 20 79 13 41 84 61 16 29 88 5 75 22 73 72 96 14 2 26 38 52 33 37 49 76 53 40 30 62 12 58 59 85 54 24 17 86 74 10 46 93 45 7 94 31 9 28 92 87 35 67 34 65 32 6 63 15 43 82 78 60 83 11 80 95 19 48 51 44 25 50 66\n","truncated":false}}
%---
%[output:1f206bd6]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 4 5 21 23 26 29 32 34 35 37 42 43 44 47 51 52 53 54 65 68 72 73 77 84 85 87 89 91 93 94\n","truncated":false}}
%---
%[output:1d3569d5]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:9a9a2994]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [72 79] at positions [5 73]\n","truncated":false}}
%---
%[output:3c8b2780]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR07_RUN07.xlsx\n","truncated":false}}
%---
%[output:8db04d09]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:8d6eeef6]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:5e5025e6]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 4 10 15 16 22 26 28 34 37 39 40 43 46 48 52 55 64 69 74 76 81 83 84 85 87 88 89 90 92 95\n","truncated":false}}
%---
%[output:8cb509ec]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:19c685fb]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR07_RUN08.xlsx\n","truncated":false}}
%---
%[output:4d356723]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 18 14 70 37 76 58 3 87 6 15 61 22 24 85 71 9 43 41 12 28 74 31 50 79 83 25 36 55 60 96 54 33 20 53 59 46 91 35 8 49 84 90 19 73 65 21 45 38 52 10 39 88 89 11 17 29 4 13 94 34 78 95 51 67 63 30 92 75 77 7 66 47 26 2 32 62 5 72 23 86 57 48 82 1 44 68 40 16 56 80 64 93 69 81 27 42\n","truncated":false}}
%---
%[output:1fa1a22c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [83 90] at positions [22 62]\n","truncated":false}}
%---
%[output:09dbe979]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:4ccd77e1]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 6 7 8 10 11 21 27 30 31 32 34 37 46 47 48 51 53 54 56 57 60 65 66 69 72 73 81 85 91 92 95\n","truncated":false}}
%---
%[output:3460895f]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:47138589]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR08_RUN01.xlsx\n","truncated":false}}
%---
%[output:736084e6]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:0218bdaf]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:7d928979]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [60 21] at positions [24 58]\n","truncated":false}}
%---
%[output:5d3f439c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 8 15 16 17 21 22 28 29 32 33 35 36 43 44 49 57 59 62 64 65 66 67 68 69 71 77 81 84 90 91 93\n","truncated":false}}
%---
%[output:16471c72]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR08_RUN02.xlsx\n","truncated":false}}
%---
%[output:74ca0a72]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 93 of 96\n\t\tAttempt 2 ran out of options at trial 94 of 96\n\t\tFound solution after 3 attempt(s): 82 6 11 35 80 78 1 76 44 81 43 46 49 57 12 60 29 22 73 61 71 85 90 79 18 40 16 95 30 86 59 33 32 56 84 7 19 8 15 94 75 10 45 39 67 31 54 53 48 92 63 83 88 41 55 69 91 21 89 9 24 3 65 66 37 28 26 68 64 2 51 25 42 4 77 52 14 38 20 62 72 87 34 13 58 47 93 27 36 50 96 70 17 5 23 74\n","truncated":false}}
%---
%[output:28ae6444]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:0a9a744e]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:65b9deb2]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:7dd658bc]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR08_RUN03.xlsx\n","truncated":false}}
%---
%[output:8f14c064]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 10 11 15 17 19 21 24 28 31 35 38 40 42 43 45 49 52 54 55 56 59 60 61 63 66 68 77 84 86 90 91 96\n","truncated":false}}
%---
%[output:7f80cf18]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [60 21] at positions [45 88]\n","truncated":false}}
%---
%[output:9bd5ab8f]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:9d202556]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 37 81 76 14 54 63 32 60 4 34 18 71 84 26 21 39 61 66 24 96 10 87 56 83 92 35 70 58 38 33 1 75 68 44 95 42 29 11 7 23 41 73 64 78 65 16 88 31 93 62 27 6 17 57 46 47 8 48 50 52 2 13 67 90 5 53 89 69 43 3 79 22 80 25 28 12 36 55 45 94 86 51 91 72 59 20 77 82 40 30 49 74 15 85 9 19\n","truncated":false}}
%---
%[output:1ebe6296]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR08_RUN04.xlsx\n","truncated":false}}
%---
%[output:36e6494f]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:0c11d8c4]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:52d23cfe]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 4 12 18 20 25 26 30 31 32 34 40 44 48 49 54 58 59 61 64 66 70 71 76 77 79 84 86 89 90 94\n","truncated":false}}
%---
%[output:964ab779]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [25 41] at positions [21 91]\n","truncated":false}}
%---
%[output:63067ab5]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR08_RUN05.xlsx\n","truncated":false}}
%---
%[output:2b235591]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:4a69950f]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:917f490b]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:1f11212a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 5 7 9 11 15 24 26 27 28 31 34 35 39 47 51 54 57 58 59 62 63 66 72 73 84 85 86 87 90 98\n","truncated":false}}
%---
%[output:8bb37bf8]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR08_RUN06.xlsx\n","truncated":false}}
%---
%[output:00ee3e30]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 77 44 50 76 63 15 74 67 16 7 85 48 88 55 84 69 93 17 90 94 4 46 36 66 32 62 19 29 41 2 26 12 60 57 33 30 80 87 82 75 10 13 42 68 61 27 58 91 40 81 14 31 18 35 6 79 25 96 24 65 71 34 22 11 64 59 73 51 5 83 52 43 56 86 54 23 72 89 37 38 53 39 9 28 1 49 8 47 78 20 95 21 45 92 3 70\n","truncated":false}}
%---
%[output:71c5c9d5]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:0cefbb85]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [16 87] at positions [21 60]\n","truncated":false}}
%---
%[output:771418ca]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:0281cffb]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR08_RUN07.xlsx\n","truncated":false}}
%---
%[output:066844ee]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 5 7 11 14 20 26 27 29 33 34 40 41 43 45 50 53 55 56 57 59 61 65 69 72 77 80 83 93 95 97\n","truncated":false}}
%---
%[output:7e584aa2]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:52ddb769]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:74213ce3]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 59 13 96 34 33 82 11 6 73 61 27 79 23 86 49 48 25 43 80 35 53 67 14 26 50 62 87 29 12 64 44 15 45 31 22 95 75 94 93 89 58 54 19 24 16 36 76 78 39 9 92 18 51 4 57 88 41 55 77 70 84 2 72 60 69 1 5 21 65 32 38 91 68 30 83 17 56 47 40 28 10 81 63 3 46 85 7 20 42 74 37 8 71 52 90 66\n","truncated":false}}
%---
%[output:264191a5]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR08_RUN08.xlsx\n","truncated":false}}
%---
%[output:8936a88d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [64 63] at positions [46 94]\n","truncated":false}}
%---
%[output:5e95ef7b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 7 9 13 14 18 19 20 24 25 28 31 33 39 42 46 52 53 54 57 58 60 61 64 65 66 69 71 79 85 86 94\n","truncated":false}}
%---
%[output:8447d816]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:7bd7bf44]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:0d3bff18]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:681daafe]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR09_RUN01.xlsx\n","truncated":false}}
%---
%[output:17e3468a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:85ba84f6]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 7 9 11 18 20 22 23 26 27 28 34 43 44 47 49 50 51 55 61 62 63 67 70 78 81 82 87 89 92 95 97\n","truncated":false}}
%---
%[output:3a2b47e8]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [1 8] at positions [41 90]\n","truncated":false}}
%---
%[output:0e300748]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 94 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 96 62 24 14 75 10 91 79 44 32 74 26 92 37 56 93 16 59 42 40 85 86 27 55 15 25 41 80 76 89 34 9 46 81 30 19 95 70 57 58 65 29 7 11 67 6 4 63 68 60 1 48 66 77 83 88 52 87 5 94 8 21 78 47 35 49 51 43 20 61 18 28 38 2 54 45 53 13 17 71 82 72 12 36 22 84 50 73 31 64 90 23 39 3 69 33\n","truncated":false}}
%---
%[output:3145b76b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR09_RUN02.xlsx\n","truncated":false}}
%---
%[output:39929606]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:4c47d97e]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:27406aab]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 8 9 10 11 12 16 18 19 20 26 27 28 33 47 48 53 54 58 65 66 67 72 82 85 87 89 90 91 94 95 97\n","truncated":false}}
%---
%[output:465c1efe]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:12e62604]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR09_RUN03.xlsx\n","truncated":false}}
%---
%[output:83c5c0b7]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [79 30] at positions [4 76]\n","truncated":false}}
%---
%[output:68036b0c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:3df8cda0]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 26 57 81 87 72 77 58 32 24 83 41 28 80 40 85 15 37 46 71 31 10 29 35 60 39 7 69 95 25 51 12 88 55 68 2 3 62 56 45 27 91 86 78 5 11 74 18 13 54 63 19 38 66 84 6 33 94 48 52 70 53 92 20 21 67 36 34 16 82 50 9 23 79 65 59 47 76 43 4 17 44 61 93 75 22 8 90 49 73 89 1 64 14 42 30 96\n","truncated":false}}
%---
%[output:3c9390b7]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 8 13 14 20 21 23 28 36 37 41 42 43 48 49 50 52 65 68 74 76 79 84 85 86 87 88 92 95 96 97\n","truncated":false}}
%---
%[output:0cbbe4b5]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR09_RUN04.xlsx\n","truncated":false}}
%---
%[output:485f3da9]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:531d54f0]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:81afb150]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [18 67] at positions [44 50]\n","truncated":false}}
%---
%[output:617e93de]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:30095f65]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR09_RUN05.xlsx\n","truncated":false}}
%---
%[output:30be5b86]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 6 7 9 10 15 16 18 22 23 25 27 35 41 44 46 51 52 65 66 68 70 74 77 79 81 85 88 91 93 95 96\n","truncated":false}}
%---
%[output:1266aff0]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:3e780f27]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 38 75 22 51 13 74 78 16 20 89 72 34 8 60 76 82 36 31 71 56 86 83 26 15 45 61 42 93 55 63 23 47 41 11 87 1 10 18 25 32 4 48 65 95 66 58 80 6 54 40 19 70 24 85 12 9 96 37 46 92 50 90 29 39 53 49 28 62 2 68 67 43 17 77 27 14 52 91 88 69 57 3 79 7 94 30 44 5 35 84 59 73 33 64 21 81\n","truncated":false}}
%---
%[output:0a7c899c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:0666a02c]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR09_RUN06.xlsx\n","truncated":false}}
%---
%[output:7182d51c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [82 57] at positions [26 91]\n","truncated":false}}
%---
%[output:957f8c71]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:9149c6bc]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 5 8 10 11 13 14 18 19 22 27 28 29 35 37 56 59 60 61 62 65 72 73 75 76 82 88 90 91 92 93\n","truncated":false}}
%---
%[output:0f7843e9]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:0cbd67d1]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR09_RUN07.xlsx\n","truncated":false}}
%---
%[output:6690a629]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:6bc3419e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 93 of 96\n\t\tFound solution after 5 attempt(s): 12 43 17 85 93 67 5 30 14 11 83 24 19 42 86 47 3 56 61 20 50 33 39 60 78 48 74 80 31 72 96 4 68 53 16 18 25 52 90 55 65 51 62 44 35 9 8 84 64 89 2 36 94 75 76 45 77 21 70 15 49 26 41 22 10 73 88 32 92 81 34 63 1 87 6 40 66 38 82 59 29 79 7 54 91 69 28 46 58 13 71 57 37 27 95 23\n","truncated":false}}
%---
%[output:18ea7daf]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [24 20] at positions [9 64]\n","truncated":false}}
%---
%[output:67db0374]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 11 12 16 17 19 20 24 29 32 36 37 38 42 43 48 51 54 56 58 59 62 63 65 67 69 70 72 78 80 82 83\n","truncated":false}}
%---
%[output:68dc172f]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR09_RUN08.xlsx\n","truncated":false}}
%---
%[output:71fe57b4]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:75d6af77]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:7b2da144]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:41e1dbe1]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:36942f54]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 8 10 12 15 18 21 24 26 34 35 37 39 42 47 48 50 52 53 54 59 62 63 68 71 78 79 80 82 84 90 96\n","truncated":false}}
%---
%[output:7688c73e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR10_RUN01.xlsx\n","truncated":false}}
%---
%[output:862a40aa]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [13 4] at positions [9 95]\n","truncated":false}}
%---
%[output:66fc08ed]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 32 74 18 31 43 1 20 93 67 48 19 57 24 13 71 54 96 88 41 53 66 69 11 5 92 25 47 80 94 49 42 83 15 52 50 10 36 34 58 46 85 2 73 61 60 81 28 26 78 27 82 56 65 45 44 17 63 8 6 39 12 22 9 95 89 33 79 4 51 29 84 70 87 59 75 76 16 30 77 40 86 23 38 55 35 3 68 21 64 90 14 62 7 37 72 91\n","truncated":false}}
%---
%[output:7613e9ab]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:57b7579f]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:559ed069]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR10_RUN02.xlsx\n","truncated":false}}
%---
%[output:6426f56e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 4 6 7 10 24 26 29 31 33 34 36 40 42 43 53 54 57 58 60 62 66 68 69 71 83 88 90 92 97 98\n","truncated":false}}
%---
%[output:0b684c97]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:17a7e95a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:5f478957]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [82 38] at positions [4 55]\n","truncated":false}}
%---
%[output:4f0a0547]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR10_RUN03.xlsx\n","truncated":false}}
%---
%[output:2767c64f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 12 76 26 21 74 62 52 47 8 60 14 13 81 73 39 30 96 95 18 15 25 64 90 4 37 56 20 48 45 84 57 79 87 46 67 75 1 32 85 34 92 10 43 38 69 7 54 59 82 80 89 24 66 51 36 11 83 49 16 9 78 35 61 71 72 17 19 6 44 23 50 28 42 91 88 2 86 33 5 68 94 55 70 22 77 3 53 31 93 29 41 27 63 40 65 58\n","truncated":false}}
%---
%[output:303adf98]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 6 8 10 11 13 18 19 27 29 31 33 34 40 41 50 51 55 66 67 70 74 77 79 83 84 86 87 88 94 98\n","truncated":false}}
%---
%[output:20f2193f]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:08bf2066]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:00db80e1]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR10_RUN04.xlsx\n","truncated":false}}
%---
%[output:7aa0fa15]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:6975a7be]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [63 89] at positions [13 87]\n","truncated":false}}
%---
%[output:8f587277]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 10 11 13 17 18 19 20 22 23 26 31 33 43 44 47 51 52 53 54 55 59 63 65 67 69 78 80 88 91 94 95\n","truncated":false}}
%---
%[output:3390f4ce]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:7b4fa15c]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR10_RUN05.xlsx\n","truncated":false}}
%---
%[output:8367a995]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:22f0de2c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 54 50 94 63 33 44 28 5 48 62 73 1 83 42 8 9 79 20 71 86 16 29 36 96 69 74 43 76 57 10 61 30 58 56 6 24 19 89 32 39 80 78 81 91 45 7 64 77 47 27 21 13 70 49 17 55 34 92 60 87 11 15 40 37 59 46 53 3 90 95 22 88 68 12 65 18 72 85 67 25 4 41 23 52 75 2 26 66 35 84 31 38 14 82 51 93\n","truncated":false}}
%---
%[output:8a985156]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:003e3dc3]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 8 10 13 14 18 19 22 24 27 29 31 33 34 36 44 52 55 57 63 68 72 74 83 85 86 87 88 90 94 96 98\n","truncated":false}}
%---
%[output:478b74a3]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR10_RUN06.xlsx\n","truncated":false}}
%---
%[output:94b4626e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [39 30] at positions [25 74]\n","truncated":false}}
%---
%[output:41898a8a]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:4aa60f17]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:634278ae]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:71e35c8e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR10_RUN07.xlsx\n","truncated":false}}
%---
%[output:2a2a2cb4]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 6 13 14 22 25 30 32 34 38 42 43 45 47 48 49 50 51 52 60 63 65 68 73 78 82 86 89 91 93 96 98\n","truncated":false}}
%---
%[output:019b00a8]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 19 23 4 94 72 65 57 69 12 77 83 93 36 60 32 82 50 62 13 56 40 96 22 49 84 14 44 68 31 79 41 38 2 17 43 21 3 9 75 48 74 92 90 37 35 64 66 61 20 58 54 46 27 80 16 88 18 39 8 47 81 6 1 28 26 91 78 67 29 87 53 10 51 89 7 95 33 11 30 45 55 85 76 42 86 59 73 5 34 24 71 52 25 63 15 70\n","truncated":false}}
%---
%[output:18557d28]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [17 20] at positions [17 86]\n","truncated":false}}
%---
%[output:8265963c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:0d925e9a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR10_RUN08.xlsx\n","truncated":false}}
%---
%[output:78f3348f]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:80d7be1c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:4d012b67]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 6 10 12 13 16 17 20 21 23 26 29 35 39 43 45 51 52 53 54 64 67 70 74 75 80 84 86 91 95 97 98\n","truncated":false}}
%---
%[output:75eb7016]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:721f0c81]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [9 88] at positions [47 70]\n","truncated":false}}
%---
%[output:7396ecae]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR11_RUN01.xlsx\n","truncated":false}}
%---
%[output:879cca4e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 73 30 70 57 64 3 61 86 5 23 44 75 96 58 41 9 38 90 93 78 67 14 65 48 46 24 54 19 28 6 84 25 85 42 49 77 63 91 21 10 1 13 83 82 39 7 60 17 22 87 66 35 71 69 89 16 36 94 59 74 11 27 37 34 51 33 18 79 26 53 2 72 32 62 56 12 40 95 31 4 20 92 45 29 68 50 47 76 43 8 52 81 80 15 88 55\n","truncated":false}}
%---
%[output:3fb89419]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:131b4338]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 6 11 12 13 16 17 24 25 26 27 30 32 36 42 51 52 56 67 71 72 73 77 83 85 89 92 94 95 96 98\n","truncated":false}}
%---
%[output:3a267872]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:9f6fb1ae]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR11_RUN02.xlsx\n","truncated":false}}
%---
%[output:746a9448]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:0ccd224c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [13 32] at positions [30 81]\n","truncated":false}}
%---
%[output:6bf48875]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:16ad0ac2]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 14 16 18 20 21 24 25 27 28 32 34 35 36 37 40 41 58 62 63 66 68 71 73 74 80 83 84 89 90 94 96 97\n","truncated":false}}
%---
%[output:4de3c6eb]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR11_RUN03.xlsx\n","truncated":false}}
%---
%[output:368150de]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 15 88 75 79 19 81 23 61 33 35 92 5 69 14 62 12 36 54 65 58 87 51 25 73 82 38 13 17 1 11 47 71 42 32 29 41 53 49 26 96 83 7 22 21 6 84 40 74 60 4 66 3 55 52 45 86 80 93 56 95 91 24 39 10 8 37 34 18 76 43 2 63 67 28 57 30 48 59 77 68 46 20 16 94 27 90 64 89 44 78 85 72 9 31 70 50\n","truncated":false}}
%---
%[output:160e8452]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:62ec9fde]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:0cc292e2]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [62 19] at positions [16 51]\n","truncated":false}}
%---
%[output:7782d5da]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR11_RUN04.xlsx\n","truncated":false}}
%---
%[output:7be5c549]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 15 16 19 22 23 24 26 28 30 35 41 43 46 48 49 50 52 56 59 60 67 70 76 82 83 85 90 94 95 96 98\n","truncated":false}}
%---
%[output:6646d07d]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:8b9b38cd]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:4cbcdb30]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 94 48 95 70 61 58 28 63 7 64 40 74 65 46 41 8 15 33 22 89 91 26 34 49 90 51 80 24 27 3 81 13 29 79 83 93 39 68 6 77 59 92 17 18 69 1 44 19 84 67 31 35 16 25 4 60 66 36 43 53 32 62 54 38 96 11 87 55 2 73 72 82 78 52 42 76 86 20 37 50 23 12 10 47 9 85 56 88 14 30 57 75 5 71 45 21\n","truncated":false}}
%---
%[output:3537df15]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR11_RUN05.xlsx\n","truncated":false}}
%---
%[output:20758266]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:77a152c2]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 7 17 18 21 24 25 28 31 33 34 37 38 39 41 43 52 53 57 58 60 64 65 69 72 74 75 79 82 87 91 97\n","truncated":false}}
%---
%[output:76fe0e61]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [20 7] at positions [26 83]\n","truncated":false}}
%---
%[output:851b2a7d]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:41e8c1af]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR11_RUN06.xlsx\n","truncated":false}}
%---
%[output:68926865]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:3e8a2d57]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:214da4ae]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 6 10 15 16 17 19 25 28 31 33 34 37 39 44 56 59 60 63 66 70 71 74 76 78 81 82 85 88 96 97\n","truncated":false}}
%---
%[output:58e09d40]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 48 34 20 73 19 2 6 76 87 35 70 50 7 58 22 52 45 13 18 95 61 55 71 16 37 82 24 41 54 94 4 86 85 74 43 46 3 40 79 75 17 25 1 68 83 78 11 63 93 31 96 38 30 29 80 66 47 53 65 56 33 90 5 27 39 28 64 9 15 92 89 49 60 23 44 51 32 88 10 42 77 8 91 59 67 36 12 72 81 69 57 14 26 62 84 21\n","truncated":false}}
%---
%[output:6d67406a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR11_RUN07.xlsx\n","truncated":false}}
%---
%[output:0d0d70cf]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:7f318b1e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [21 78] at positions [29 50]\n","truncated":false}}
%---
%[output:14b2b438]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:317c4d21]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 7 8 9 10 16 17 21 26 27 31 34 40 41 47 48 50 58 61 63 65 66 69 72 75 79 80 83 85 88 94 96\n","truncated":false}}
%---
%[output:2fad697e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR11_RUN08.xlsx\n","truncated":false}}
%---
%[output:73c7d7c6]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:00a34e30]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:047a7651]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 69 66 57 58 31 67 87 88 24 37 15 17 51 45 77 2 50 11 76 32 7 16 38 30 86 61 79 39 59 96 73 47 81 8 84 44 46 65 27 23 55 54 92 34 3 21 89 53 10 82 90 70 62 80 85 4 48 43 26 1 52 41 63 20 68 14 74 75 25 35 94 22 28 93 49 95 5 6 91 36 18 64 12 71 9 19 78 42 83 29 33 13 56 72 60 40\n","truncated":false}}
%---
%[output:5a7313f4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [84 1] at positions [10 69]\n","truncated":false}}
%---
%[output:4f7b1a7e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 6 9 13 14 17 18 21 25 32 35 36 38 39 43 52 54 55 56 60 61 62 63 67 68 76 79 82 87 88 97\n","truncated":false}}
%---
%[output:8b739919]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR12_RUN01.xlsx\n","truncated":false}}
%---
%[output:57b3c13c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:6eb3ecde]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:8514605b]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:14aedf0f]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:5e8915e3]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR12_RUN02.xlsx\n","truncated":false}}
%---
%[output:5500eb5a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [26 18] at positions [39 53]\n","truncated":false}}
%---
%[output:92962004]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 4 5 6 7 10 11 19 22 24 26 33 36 45 49 53 54 57 59 61 66 69 71 72 75 81 82 86 87 88 98\n","truncated":false}}
%---
%[output:6a1184cc]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 94 of 96\n\t\tAttempt 3 ran out of options at trial 94 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tFound solution after 5 attempt(s): 50 47 46 75 35 5 70 11 13 42 91 76 51 92 85 33 58 68 73 93 61 59 23 1 63 9 20 84 3 89 24 79 28 21 57 40 18 37 96 82 39 12 48 64 83 74 7 25 27 8 2 56 62 71 44 80 49 10 67 69 22 55 26 87 53 72 81 30 77 86 14 94 41 43 29 38 65 32 45 17 88 15 95 31 78 36 52 90 54 16 60 19 6 34 4 66\n","truncated":false}}
%---
%[output:77b411eb]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:22f33665]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR12_RUN03.xlsx\n","truncated":false}}
%---
%[output:19d17fc8]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:4ced56d3]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:0ac53be0]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 5 6 9 13 17 20 24 30 32 33 35 45 47 48 50 54 58 59 62 63 64 68 69 73 85 91 93 94 95 96\n","truncated":false}}
%---
%[output:6ad80354]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [18 28] at positions [31 78]\n","truncated":false}}
%---
%[output:8c4b4f73]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR12_RUN04.xlsx\n","truncated":false}}
%---
%[output:506086b6]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:9a76431d]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:0253f3e7]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tAttempt 5 ran out of options at trial 96 of 96\n\t\tAttempt 6 ran out of options at trial 96 of 96\n\t\tAttempt 7 ran out of options at trial 96 of 96\n\t\tFound solution after 8 attempt(s): 18 1 20 82 56 61 80 26 35 21 57 15 95 6 14 54 36 88 75 52 86 96 25 23 74 10 67 48 34 72 85 47 58 31 69 71 93 42 9 43 16 51 44 76 78 27 29 46 45 64 50 89 13 70 38 19 62 65 11 37 83 87 60 7 2 30 3 92 32 90 66 55 28 53 41 12 68 59 24 39 79 81 17 77 8 49 73 40 91 4 94 63 84 33 22 5\n","truncated":false}}
%---
%[output:38ca65df]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 7 8 9 11 14 16 17 20 29 30 36 38 41 49 54 55 56 64 66 68 75 78 80 81 82 86 89 91 94 96\n","truncated":false}}
%---
%[output:27c300f3]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR12_RUN05.xlsx\n","truncated":false}}
%---
%[output:970336f0]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:2ab4222a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [13 74] at positions [23 77]\n","truncated":false}}
%---
%[output:72a60886]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:1330aaf4]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:78b275f9]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR12_RUN06.xlsx\n","truncated":false}}
%---
%[output:162dfa3e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 7 11 16 17 19 23 25 28 30 33 35 36 41 42 44 52 59 61 64 66 67 68 70 73 76 79 81 83 90 95 96\n","truncated":false}}
%---
%[output:47e6267e]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:3bd55bf6]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 35 14 11 46 77 90 61 16 19 24 44 53 63 80 4 86 79 21 70 51 47 83 17 8 65 68 39 36 25 60 31 87 37 28 96 88 6 64 93 75 57 45 71 3 52 81 43 49 15 10 73 41 1 22 18 7 94 84 13 34 92 26 58 67 27 72 76 91 56 59 30 40 38 12 55 29 82 48 23 74 2 66 54 69 85 50 89 9 20 5 95 32 42 78 33 62\n","truncated":false}}
%---
%[output:1a42e6b0]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [19 90] at positions [14 77]\n","truncated":false}}
%---
%[output:9fc3e12c]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR12_RUN07.xlsx\n","truncated":false}}
%---
%[output:5a3fdaaf]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:161e221f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 8 13 14 18 26 30 32 33 34 35 43 46 48 49 50 53 55 56 59 62 65 67 69 75 86 87 88 93 96 98\n","truncated":false}}
%---
%[output:73bc84ad]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:0e2ac19f]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:64b450d7]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR12_RUN08.xlsx\n","truncated":false}}
%---
%[output:9f360604]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:9fc03f26]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [53 64] at positions [10 68]\n","truncated":false}}
%---
%[output:08094887]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 7 11 12 16 20 21 29 33 37 39 43 44 48 49 56 57 61 62 66 67 72 75 77 81 82 83 84 87 88 89\n","truncated":false}}
%---
%[output:071dc71a]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 63 91 3 76 17 67 71 45 25 58 65 61 55 34 53 28 46 80 90 18 13 1 87 48 39 6 40 93 89 64 15 21 81 66 2 51 8 73 49 47 57 24 20 32 94 83 29 72 22 42 95 9 82 56 85 35 23 52 75 70 37 68 86 77 5 36 38 12 60 50 44 16 7 30 11 92 19 62 26 74 88 33 59 78 41 96 69 31 4 54 14 27 84 10 43 79\n","truncated":false}}
%---
%[output:2f389876]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:0fd5d5ec]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR13_RUN01.xlsx\n","truncated":false}}
%---
%[output:5ec50fdd]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:895df9ab]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:69d0ea69]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 7 8 10 11 12 14 21 22 25 28 39 43 44 48 50 53 56 62 64 74 75 76 78 82 87 92 94 95 96 97\n","truncated":false}}
%---
%[output:7d8efffa]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [74 93] at positions [8 70]\n","truncated":false}}
%---
%[output:20661c80]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR13_RUN02.xlsx\n","truncated":false}}
%---
%[output:24a8740c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:7c708117]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tFound solution after 5 attempt(s): 72 2 4 29 21 92 76 71 38 36 24 35 53 30 55 84 17 12 69 89 48 15 87 57 60 43 74 51 11 39 88 85 7 62 68 25 65 44 26 18 56 73 82 41 46 14 78 58 1 64 94 19 6 91 96 66 10 37 54 27 42 86 50 45 80 79 31 93 13 22 70 40 59 52 95 77 81 3 5 63 34 23 16 47 90 20 33 8 28 49 67 9 83 61 32 75\n","truncated":false}}
%---
%[output:4a26f662]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:6f7b6fb4]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 5 8 9 11 12 13 16 18 19 32 34 36 41 46 48 54 55 56 59 62 63 66 71 72 73 74 81 86 87 92 98\n","truncated":false}}
%---
%[output:96d4d2a2]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR13_RUN03.xlsx\n","truncated":false}}
%---
%[output:0e4ee201]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:2174dabe]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:0caaf63f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [93 42] at positions [33 63]\n","truncated":false}}
%---
%[output:37bb7bb1]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:612abbe6]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR13_RUN04.xlsx\n","truncated":false}}
%---
%[output:816596e7]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 12 22 49 93 66 54 75 15 41 78 26 39 18 67 91 92 40 2 57 59 23 32 89 50 38 44 87 6 95 27 8 77 79 47 62 3 13 76 53 83 94 58 80 36 74 30 9 63 20 82 25 69 16 48 24 21 34 10 28 56 11 86 73 68 90 4 5 81 46 88 51 60 45 42 64 19 1 43 84 65 37 70 14 29 55 33 52 85 17 71 61 7 72 31 96 35\n","truncated":false}}
%---
%[output:2c642956]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 9 16 20 21 23 27 28 30 33 35 40 41 42 44 51 53 54 55 60 64 65 67 70 73 74 75 82 83 85 93\n","truncated":false}}
%---
%[output:67b74023]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:0e992f6b]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:3fef8c52]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR13_RUN05.xlsx\n","truncated":false}}
%---
%[output:6809c838]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [22 96] at positions [16 55]\n","truncated":false}}
%---
%[output:63c4c299]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:79452e79]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 6 8 11 12 14 17 19 22 24 27 30 38 44 46 48 50 56 59 62 63 67 68 69 74 75 80 88 89 92 96 97\n","truncated":false}}
%---
%[output:697d5abd]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:0a7d5db4]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR13_RUN06.xlsx\n","truncated":false}}
%---
%[output:1afecc3a]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 84 30 52 34 27 76 15 96 78 77 43 46 89 45 1 31 88 93 63 55 69 50 82 7 33 67 95 48 61 13 75 29 41 11 56 28 17 2 16 21 92 74 53 4 12 85 19 44 20 70 94 58 36 38 81 6 51 72 3 71 26 22 57 60 87 83 62 23 9 47 64 68 65 39 73 14 79 86 10 35 32 91 80 25 54 5 59 40 49 24 42 66 37 90 18 8\n","truncated":false}}
%---
%[output:3ed4ca11]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:815be192]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [71 85] at positions [24 77]\n","truncated":false}}
%---
%[output:4e5a5d28]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 3 7 8 10 15 16 19 25 31 32 33 34 40 42 51 53 54 57 58 63 64 67 72 73 75 77 89 91 92 97\n","truncated":false}}
%---
%[output:939b7b1c]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR13_RUN07.xlsx\n","truncated":false}}
%---
%[output:154868f3]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:8a8693d4]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:42a3a1b5]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:513625fc]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tFound solution after 3 attempt(s): 74 42 16 79 3 25 1 83 81 2 46 92 33 71 18 62 22 43 44 60 77 80 50 37 20 66 89 76 41 93 23 86 59 82 94 70 29 17 45 68 51 15 6 57 56 7 5 49 47 64 19 90 11 96 36 4 65 78 85 63 87 28 12 48 40 21 31 72 14 27 54 58 67 88 13 53 10 84 39 9 75 26 69 8 30 52 35 91 73 34 55 24 38 32 95 61\n","truncated":false}}
%---
%[output:3caa1c27]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR13_RUN08.xlsx\n","truncated":false}}
%---
%[output:2a531cb6]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 6 8 12 15 20 23 25 26 32 37 39 40 42 47 48 53 61 63 64 70 71 72 77 79 80 82 85 87 89 94 96\n","truncated":false}}
%---
%[output:228486c2]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [29 31] at positions [18 71]\n","truncated":false}}
%---
%[output:4066dadb]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:70c3253e]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:15d66906]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:32aecbfc]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR14_RUN01.xlsx\n","truncated":false}}
%---
%[output:14b74e84]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 11 15 17 19 23 24 25 32 36 41 43 44 45 47 49 56 57 60 64 67 68 69 72 75 81 84 89 90 96 97 98\n","truncated":false}}
%---
%[output:81bbac54]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:3ef30e83]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [21 66] at positions [30 91]\n","truncated":false}}
%---
%[output:2ed9304e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tAttempt 3 ran out of options at trial 95 of 96\n\t\tFound solution after 4 attempt(s): 53 36 5 14 33 76 32 65 78 44 29 18 87 82 71 13 68 49 75 84 60 6 19 54 88 20 34 51 22 2 92 39 93 16 58 61 83 52 37 35 30 91 96 28 56 21 70 3 69 40 1 94 72 59 9 25 23 12 10 55 66 27 41 77 73 86 4 48 63 57 95 43 89 17 79 81 50 45 38 24 47 67 7 80 46 85 11 42 62 8 26 15 64 74 31 90\n","truncated":false}}
%---
%[output:9f0249ea]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR14_RUN02.xlsx\n","truncated":false}}
%---
%[output:72307564]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:938cf0cc]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 7 9 12 14 15 17 18 20 22 25 28 37 45 47 48 51 54 59 65 69 70 75 77 79 80 86 87 89 90 94 98\n","truncated":false}}
%---
%[output:802d860b]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:2fa43489]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:8b1049e6]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR14_RUN03.xlsx\n","truncated":false}}
%---
%[output:2e830268]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [67 31] at positions [18 58]\n","truncated":false}}
%---
%[output:7b2bb931]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:5914049c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 6 8 9 11 16 18 21 26 32 33 36 38 40 44 49 51 53 58 61 65 66 71 73 79 80 82 84 85 86 96 97\n","truncated":false}}
%---
%[output:05f8e4de]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:220f1e2f]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR14_RUN04.xlsx\n","truncated":false}}
%---
%[output:1cb0052f]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 75 73 85 61 66 6 68 20 49 38 65 62 81 17 8 11 82 33 5 39 96 79 36 25 71 72 60 63 21 95 12 57 3 32 27 41 58 4 24 80 19 90 88 30 37 42 7 89 83 78 13 45 94 52 46 29 14 69 91 40 48 67 35 53 76 34 22 26 56 87 1 9 55 51 31 64 93 10 23 86 74 54 70 18 77 16 50 28 44 2 84 47 92 59 15 43\n","truncated":false}}
%---
%[output:3b74149b]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:973ef3cc]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [33 6] at positions [41 65]\n","truncated":false}}
%---
%[output:5d26477b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 7 8 12 15 16 17 18 19 29 31 36 41 43 48 51 53 62 66 67 69 73 77 78 81 85 86 87 91 95 97\n","truncated":false}}
%---
%[output:2c966164]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR14_RUN05.xlsx\n","truncated":false}}
%---
%[output:279af393]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:006dc622]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:1e1013ef]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:46399b1b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tAttempt 3 ran out of options at trial 94 of 96\n\t\tFound solution after 4 attempt(s): 93 74 73 30 19 75 48 81 24 84 14 77 85 47 13 7 34 46 69 2 50 64 89 96 60 3 92 87 56 31 33 22 11 17 59 80 52 43 63 4 15 35 29 91 42 67 78 6 51 55 90 21 39 40 49 32 23 58 76 82 10 18 71 28 12 70 53 41 1 94 65 45 83 72 62 66 27 86 5 44 26 54 8 25 36 68 38 61 20 9 57 88 37 16 79 95\n","truncated":false}}
%---
%[output:076de3b2]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR14_RUN06.xlsx\n","truncated":false}}
%---
%[output:1a37c40a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [67 73] at positions [31 88]\n","truncated":false}}
%---
%[output:5143d7f7]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 5 8 10 14 26 31 34 36 40 42 43 45 47 48 54 56 58 59 65 67 68 75 76 78 79 85 89 90 91 97\n","truncated":false}}
%---
%[output:260cfae6]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:2a29aa48]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:609d0fc6]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR14_RUN07.xlsx\n","truncated":false}}
%---
%[output:1c2cff74]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:751bca7c]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:7046065e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 5 11 14 18 19 21 22 26 30 35 37 42 43 49 50 54 56 58 59 64 67 68 71 73 78 81 86 90 91 92\n","truncated":false}}
%---
%[output:94053c58]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 39 82 34 30 76 48 72 95 9 68 53 43 49 12 88 75 21 54 55 89 31 14 51 65 3 5 47 33 8 23 35 61 17 27 92 94 57 46 26 73 66 50 96 29 4 62 16 67 7 84 83 64 18 91 45 6 32 24 36 44 69 93 78 74 40 81 2 11 38 71 28 56 52 77 22 13 63 19 85 79 58 42 20 60 80 90 41 15 25 70 10 86 59 1 37 87\n","truncated":false}}
%---
%[output:158ade42]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR14_RUN08.xlsx\n","truncated":false}}
%---
%[output:33d5830f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [75 21] at positions [5 55]\n","truncated":false}}
%---
%[output:564a7c47]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:4de9b467]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:2715eb17]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 5 9 13 18 19 24 25 26 27 28 33 34 40 48 53 55 58 62 63 71 72 82 85 86 88 90 92 94 96 97\n","truncated":false}}
%---
%[output:61080dfc]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:357e835b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR15_RUN01.xlsx\n","truncated":false}}
%---
%[output:53bb0948]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:11415595]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [92 10] at positions [20 67]\n","truncated":false}}
%---
%[output:14b59b3c]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 13 43 69 91 74 21 16 63 78 60 84 64 3 70 73 4 92 88 17 25 67 46 59 24 50 62 42 23 81 15 18 38 82 41 14 5 93 72 77 49 53 34 44 89 29 36 37 30 20 90 96 47 80 39 57 83 12 10 19 51 26 6 48 9 54 75 7 68 95 61 2 52 40 87 35 32 79 28 55 11 71 27 45 58 76 33 66 94 56 85 8 86 31 65 1 22\n","truncated":false}}
%---
%[output:28b1ece0]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 6 7 13 17 18 20 33 36 37 38 41 44 46 49 52 55 57 59 62 69 73 79 80 83 84 85 87 93 94 97\n","truncated":false}}
%---
%[output:2a0b5764]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR15_RUN02.xlsx\n","truncated":false}}
%---
%[output:0a9da888]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:7c79873e]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:68c50c41]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:062324f2]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [75 91] at positions [25 75]\n","truncated":false}}
%---
%[output:63c28503]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR15_RUN03.xlsx\n","truncated":false}}
%---
%[output:58195e5c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 8 10 13 15 19 20 22 23 25 32 35 36 38 46 49 50 51 55 57 59 63 66 68 69 70 71 72 84 85 86 98\n","truncated":false}}
%---
%[output:0c9d7265]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:258310c4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 28 41 29 1 38 52 30 31 86 9 18 53 88 60 48 2 67 8 4 64 65 59 13 81 71 78 46 93 96 25 69 87 37 34 73 21 62 58 40 19 15 80 77 57 17 44 54 85 95 75 43 33 7 49 10 16 94 14 32 79 91 47 66 5 39 84 23 92 61 72 20 22 51 56 24 3 74 27 90 45 83 76 55 35 70 11 42 26 68 36 12 63 89 50 6 82\n","truncated":false}}
%---
%[output:2e8b72fd]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:3391b9bc]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR15_RUN04.xlsx\n","truncated":false}}
%---
%[output:84ece5a3]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:99e5e036]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 8 11 19 22 23 24 27 29 30 33 37 38 41 47 49 50 51 52 54 56 59 63 66 67 68 71 73 76 82 83 98\n","truncated":false}}
%---
%[output:45bd308a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [94 95] at positions [46 85]\n","truncated":false}}
%---
%[output:6ae4bc43]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:2972375e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR15_RUN05.xlsx\n","truncated":false}}
%---
%[output:66a2837d]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:6501adbb]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 57 85 66 77 3 87 33 18 54 12 21 31 69 19 81 96 53 41 55 78 63 30 11 72 86 14 2 52 59 83 27 34 9 40 91 51 5 61 23 24 38 43 70 37 92 48 42 79 44 7 89 13 73 22 67 80 49 76 8 25 88 74 84 82 26 56 39 60 50 1 46 17 10 16 93 65 90 29 71 4 35 95 45 64 75 47 32 94 15 68 62 20 6 28 58 36\n","truncated":false}}
%---
%[output:14ad099d]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 13 14 16 17 22 25 26 27 29 31 40 41 47 48 49 53 54 57 61 65 68 77 78 79 83 84 89 90 93 94 95\n","truncated":false}}
%---
%[output:2f9718f6]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:1ac15f08]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR15_RUN06.xlsx\n","truncated":false}}
%---
%[output:220a9851]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [36 45] at positions [10 96]\n","truncated":false}}
%---
%[output:5021a138]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:5f1b0cc9]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:87898500]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 7 8 17 19 21 26 27 33 35 39 40 42 43 46 51 52 56 61 64 66 71 75 76 77 79 80 85 88 94 98\n","truncated":false}}
%---
%[output:97059421]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR15_RUN07.xlsx\n","truncated":false}}
%---
%[output:039603d1]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:28047844]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tFound solution after 3 attempt(s): 14 83 62 36 57 20 43 72 3 53 71 94 76 29 16 24 26 60 90 86 28 66 44 8 65 54 56 10 5 38 23 87 34 46 81 9 55 40 58 49 7 48 21 33 68 70 12 89 52 27 51 69 93 22 92 77 18 67 39 88 1 11 19 17 2 80 73 64 82 37 42 4 84 91 74 30 79 63 13 31 96 59 41 61 75 45 85 6 78 95 47 15 35 32 50 25\n","truncated":false}}
%---
%[output:08370caf]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [85 36] at positions [40 95]\n","truncated":false}}
%---
%[output:695b1229]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:35c5bd71]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR15_RUN08.xlsx\n","truncated":false}}
%---
%[output:9d0546d6]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:7974dca0]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 5 7 15 21 23 28 35 36 37 38 42 44 45 47 49 51 53 60 62 65 66 68 72 75 79 84 85 94 95 96 97\n","truncated":false}}
%---
%[output:3ccc1673]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:862e02e9]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:86453936]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [30 37] at positions [1 90]\n","truncated":false}}
%---
%[output:9f434574]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR16_RUN01.xlsx\n","truncated":false}}
%---
%[output:5e101379]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 37 79 96 83 17 95 12 74 52 43 30 41 54 9 32 73 72 31 58 50 25 18 7 10 36 33 91 51 86 68 42 2 88 48 85 19 89 65 15 64 71 63 35 62 8 29 40 28 14 70 5 87 57 84 3 4 59 61 80 76 44 16 47 34 78 22 49 24 67 93 90 38 77 13 46 53 27 21 69 56 11 60 82 39 94 1 26 45 6 92 20 55 66 23 81 75\n","truncated":false}}
%---
%[output:557a25a5]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 7 8 9 10 11 13 15 16 19 21 29 32 34 43 44 50 51 52 65 68 71 72 75 83 85 87 88 93 94 96 97\n","truncated":false}}
%---
%[output:5df1f4a3]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:1090bfc3]
%   data: {"dataType":"text","outputData":{"text":"\tRun 1 of 8:\n","truncated":false}}
%---
%[output:29391088]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR16_RUN02.xlsx\n","truncated":false}}
%---
%[output:8f671769]
%   data: {"dataType":"text","outputData":{"text":"\tRun 2 of 8:\n","truncated":false}}
%---
%[output:0646fdb4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [73 24] at positions [1 62]\n","truncated":false}}
%---
%[output:8652ff07]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 8 13 15 19 21 24 33 35 39 40 41 42 45 47 52 55 58 59 61 62 64 65 74 87 88 89 90 91 96 98\n","truncated":false}}
%---
%[output:949fa601]
%   data: {"dataType":"text","outputData":{"text":"\tRun 3 of 8:\n","truncated":false}}
%---
%[output:85f28cc4]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR16_RUN03.xlsx\n","truncated":false}}
%---
%[output:5fb7c387]
%   data: {"dataType":"text","outputData":{"text":"\tRun 4 of 8:\n","truncated":false}}
%---
%[output:2b8f766c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 2 45 88 40 20 54 26 15 12 96 69 65 4 78 62 41 64 73 44 36 75 94 91 51 87 17 35 9 52 60 1 32 93 10 27 79 29 22 43 56 67 18 90 13 89 31 57 61 19 66 81 71 6 53 48 25 24 3 5 76 47 8 42 33 95 38 70 55 16 85 63 83 86 58 21 39 74 77 82 14 23 50 46 30 92 72 59 68 28 80 7 37 11 49 84 34\n","truncated":false}}
%---
%[output:2a02280e]
%   data: {"dataType":"text","outputData":{"text":"\tRun 5 of 8:\n","truncated":false}}
%---
%[output:9a82af65]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 10 11 12 13 17 18 19 21 22 24 34 40 41 45 53 55 56 67 68 69 72 75 76 80 83 84 89 91 95 97\n","truncated":false}}
%---
%[output:5dccb247]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR16_RUN04.xlsx\n","truncated":false}}
%---
%[output:6a8ac409]
%   data: {"dataType":"text","outputData":{"text":"\tRun 6 of 8:\n","truncated":false}}
%---
%[output:81f92489]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [70 92] at positions [32 80]\n","truncated":false}}
%---
%[output:959bff54]
%   data: {"dataType":"text","outputData":{"text":"\tRun 7 of 8:\n","truncated":false}}
%---
%[output:1faec969]
%   data: {"dataType":"text","outputData":{"text":"\tRun 8 of 8:\n","truncated":false}}
%---
%[output:3c5c23e8]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR16_RUN05.xlsx\n","truncated":false}}
%---
%[output:6536fcc6]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 8 10 11 14 15 17 18 23 24 26 31 33 39 40 43 53 54 57 60 61 62 65 67 71 73 78 83 86 87 94 95\n","truncated":false}}
%---
%[output:3231ca43]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 60 25 37 40 13 34 63 14 28 82 36 87 23 71 45 22 50 84 89 11 15 81 78 68 90 55 52 70 29 31 1 49 47 79 5 80 54 48 3 77 39 91 30 74 18 94 53 27 38 57 9 58 67 75 96 10 43 44 26 61 93 66 8 86 85 46 69 62 59 42 24 2 21 19 33 92 32 95 7 16 64 73 4 41 51 12 20 56 88 76 17 6 65 83 35 72\n","truncated":false}}
%---
%[output:1a0d4727]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 94 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tAttempt 5 ran out of options at trial 96 of 96\n\t\tFound solution after 6 attempt(s): 92 58 35 21 56 51 76 39 64 18 31 2 22 93 3 34 11 14 79 4 63 10 88 71 55 91 42 45 73 70 17 36 89 32 75 83 87 28 8 72 23 41 78 7 96 5 62 50 77 80 53 25 84 43 16 27 67 81 54 13 9 48 40 86 95 65 33 61 82 1 47 20 59 46 24 19 85 60 94 66 49 29 74 30 6 90 37 52 38 15 57 69 12 26 44 68\n","truncated":false}}
%---
%[output:4bd534b9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [49 79] at positions [25 94]\n","truncated":false}}
%---
%[output:60798b3d]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR16_RUN06.xlsx\n","truncated":false}}
%---
%[output:1b320bd0]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 18 51 2 15 55 20 91 68 11 33 27 14 73 92 37 70 22 29 80 40 64 35 93 60 72 63 49 81 17 43 3 89 9 19 42 44 24 83 95 88 48 1 75 67 86 54 39 78 10 50 96 25 59 57 5 26 8 6 47 45 56 65 77 41 87 66 61 28 30 69 31 4 94 7 84 36 12 62 76 58 23 38 71 82 79 21 85 53 46 52 16 34 90 32 74 13\n","truncated":false}}
%---
%[output:8e61d0b0]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 5 10 13 16 17 30 32 38 39 40 41 42 45 46 55 57 61 62 66 70 71 74 76 77 83 85 86 87 89 93\n","truncated":false}}
%---
%[output:33d21721]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 79 28 67 1 29 61 13 45 36 84 91 12 6 95 75 86 52 46 54 76 60 59 25 81 39 20 11 49 96 21 37 70 40 9 69 72 15 22 19 2 89 48 23 80 65 93 58 10 41 74 24 42 5 7 55 94 82 32 64 35 38 83 71 50 73 33 63 26 30 92 8 68 18 56 51 88 53 78 57 27 85 43 3 17 34 87 16 47 77 4 66 90 31 14 62 44\n","truncated":false}}
%---
%[output:774a3dc0]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 94 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 95 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tFound solution after 5 attempt(s): 37 57 85 72 71 16 88 22 29 62 18 96 49 54 47 81 2 67 26 75 48 33 74 82 44 11 34 27 3 28 39 64 9 56 76 60 35 32 84 89 91 41 90 15 10 63 51 65 94 78 52 8 95 50 83 25 61 31 80 19 21 40 42 73 43 12 30 1 77 68 4 36 58 38 69 45 92 17 5 7 24 55 93 14 87 66 13 46 6 59 20 70 86 53 79 23\n","truncated":false}}
%---
%[output:069e0a53]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR16_RUN07.xlsx\n","truncated":false}}
%---
%[output:164e7a59]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 96 4 39 66 48 88 36 7 82 24 49 65 74 16 17 44 21 5 10 80 94 58 22 27 71 54 41 62 53 2 61 91 81 77 30 84 64 20 31 43 33 57 60 15 32 78 67 83 92 37 47 76 55 35 90 72 12 86 13 46 1 59 69 25 6 3 70 45 18 63 89 23 93 14 79 42 26 9 38 95 50 87 75 56 19 68 8 28 52 73 85 29 34 11 51 40\n","truncated":false}}
%---
%[output:9fde54a9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [48 74] at positions [17 67]\n","truncated":false}}
%---
%[output:5f4ae297]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 6 8 10 13 15 16 24 25 32 33 39 41 43 46 47 50 51 52 59 63 65 66 68 69 73 75 76 81 88 92 95\n","truncated":false}}
%---
%[output:934fcc47]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 28 82 81 7 3 38 11 20 56 41 85 66 74 27 33 70 8 55 71 51 10 93 23 1 65 40 44 57 52 18 67 96 50 87 36 31 21 15 53 80 13 94 61 83 9 48 75 91 69 63 58 24 72 79 30 54 42 95 88 46 43 49 14 6 29 86 22 19 37 16 77 47 17 5 35 32 68 89 2 78 59 92 25 62 34 12 64 73 39 84 45 60 4 26 90 76\n","truncated":false}}
%---
%[output:1445b1dd]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR16_RUN08.xlsx\n","truncated":false}}
%---
%[output:2f04b7f6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 94 of 96\n\t\tAttempt 4 ran out of options at trial 94 of 96\n\t\tFound solution after 5 attempt(s): 34 84 32 85 75 37 70 18 17 35 54 92 56 72 87 16 79 74 6 58 38 31 3 89 45 36 13 19 49 7 10 48 76 61 29 78 15 14 67 91 94 51 52 57 22 66 59 39 5 93 24 63 9 41 21 8 50 96 83 47 44 81 80 77 26 33 53 73 40 30 28 86 4 25 43 90 68 27 82 60 69 55 46 1 65 88 42 62 23 64 2 95 11 20 71 12\n","truncated":false}}
%---
%[output:9f488873]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 94 of 96\n\t\tFound solution after 2 attempt(s): 75 17 8 31 20 68 45 6 46 18 58 96 91 64 78 3 85 80 70 92 48 87 11 14 61 37 57 12 66 51 63 30 35 33 73 56 39 5 41 26 93 28 1 50 90 89 65 23 77 79 2 81 22 43 60 25 55 4 7 72 47 42 71 83 40 82 10 21 19 95 59 74 32 69 54 62 86 38 15 84 76 9 52 34 49 16 36 67 88 13 27 53 24 44 94 29\n","truncated":false}}
%---
%[output:8c48330a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 95 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tAttempt 5 ran out of options at trial 95 of 96\n\t\tAttempt 6 ran out of options at trial 96 of 96\n\t\tAttempt 7 ran out of options at trial 95 of 96\n\t\tFound solution after 8 attempt(s): 20 9 88 34 19 47 43 84 12 6 27 60 5 37 79 66 86 77 7 61 63 23 87 28 75 58 45 53 71 18 30 31 72 46 13 67 89 81 54 96 35 39 1 51 59 29 10 73 22 95 14 16 32 33 74 76 64 70 11 93 90 68 42 49 40 17 52 92 62 15 36 83 26 3 91 78 94 56 4 50 69 57 41 21 80 48 85 44 2 38 65 25 82 8 24 55\n","truncated":false}}
%---
%[output:64e14235]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 8 11 15 17 22 23 24 28 29 30 35 37 38 44 48 50 51 54 55 60 61 63 69 73 74 79 83 88 89 93 95\n","truncated":false}}
%---
%[output:26baf9f7]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [8 41] at positions [27 70]\n","truncated":false}}
%---
%[output:17586476]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR17_RUN01.xlsx\n","truncated":false}}
%---
%[output:892d6659]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 85 1 80 81 62 72 23 14 61 25 83 38 42 58 2 90 77 10 8 30 29 51 60 87 28 79 56 44 93 86 17 46 73 39 26 59 19 31 66 76 68 41 5 36 7 94 47 74 53 89 9 54 70 13 69 82 84 52 3 35 96 75 20 91 78 57 33 64 63 24 15 11 27 34 18 48 40 88 50 71 32 92 21 55 95 12 67 6 43 16 49 45 65 37 22 4\n","truncated":false}}
%---
%[output:48dbd6a6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 93 of 96\n\t\tFound solution after 2 attempt(s): 59 76 53 19 90 87 68 15 58 36 66 95 31 57 84 64 5 40 47 17 32 35 60 49 65 71 43 7 75 23 78 52 21 2 3 24 41 86 6 94 33 91 14 79 70 30 10 42 26 25 81 48 1 55 44 54 83 50 51 12 89 20 67 37 69 16 4 18 63 38 34 92 77 82 88 62 29 72 8 80 56 9 93 22 61 73 46 27 13 39 11 28 96 74 85 45\n","truncated":false}}
%---
%[output:592bb57c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 5 4 87 66 38 67 9 18 25 10 59 22 82 8 72 23 51 40 53 62 83 34 24 46 42 81 29 69 91 57 16 44 11 31 70 80 61 78 45 85 90 75 56 35 48 7 71 27 43 52 30 63 55 76 1 41 26 15 49 14 93 64 88 96 47 74 89 2 12 95 32 86 54 17 28 68 73 39 21 84 20 50 77 6 58 94 13 33 79 19 37 3 65 92 36 60\n","truncated":false}}
%---
%[output:3ea7ec37]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 30 96 14 13 40 94 70 46 48 52 93 45 32 39 76 85 60 15 28 79 80 20 16 89 86 22 23 64 35 11 74 5 54 55 77 49 29 9 69 56 12 26 57 59 75 95 7 41 27 91 72 73 44 83 84 43 4 87 24 42 62 38 65 18 78 3 8 61 19 21 10 90 50 92 2 58 34 47 17 63 67 82 71 6 66 51 81 31 88 37 68 33 1 25 36 53\n","truncated":false}}
%---
%[output:0574f0a0]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR17_RUN02.xlsx\n","truncated":false}}
%---
%[output:0c8367e9]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 9 17 18 19 21 30 31 32 34 36 37 38 42 46 47 48 51 58 59 62 65 66 67 68 69 73 87 88 90 94 95 98\n","truncated":false}}
%---
%[output:9113c03b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [4 83] at positions [36 92]\n","truncated":false}}
%---
%[output:17b8f7f1]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 94 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 95 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tAttempt 5 ran out of options at trial 94 of 96\n\t\tFound solution after 6 attempt(s): 73 13 52 82 83 47 46 76 87 4 96 69 43 21 12 74 28 32 55 5 6 37 56 31 48 1 17 92 25 75 49 63 44 85 57 80 65 71 93 16 20 67 45 18 23 35 84 53 34 42 78 2 72 50 64 30 62 10 7 89 95 24 14 51 91 77 29 94 40 3 39 59 70 90 15 36 66 58 27 38 60 33 22 68 41 11 81 19 61 86 79 8 54 9 26 88\n","truncated":false}}
%---
%[output:2b667024]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tFound solution after 3 attempt(s): 57 66 89 88 34 73 80 40 16 62 22 45 49 35 47 91 52 61 81 69 53 8 44 20 29 12 28 85 1 79 21 70 10 14 82 19 60 9 3 58 18 15 72 86 54 67 42 74 6 33 23 17 51 95 76 63 64 39 46 84 38 2 32 48 59 4 93 24 68 26 83 94 11 50 65 75 96 77 31 92 56 41 30 78 55 90 25 7 36 71 43 13 27 37 87 5\n","truncated":false}}
%---
%[output:02908a7e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR17_RUN03.xlsx\n","truncated":false}}
%---
%[output:760c4e97]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 95 of 96\n\t\tFound solution after 4 attempt(s): 24 13 43 91 47 27 73 62 35 66 69 82 59 10 28 17 87 1 77 21 57 72 12 60 49 31 33 11 16 92 70 34 40 56 96 32 3 2 61 78 23 26 94 95 63 85 88 45 58 22 76 65 54 4 19 38 74 8 71 84 68 36 5 81 9 42 25 53 64 48 90 20 7 89 80 51 18 55 46 39 86 52 15 75 44 6 41 29 67 30 93 37 50 79 83 14\n","truncated":false}}
%---
%[output:1dcd4d9d]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 7 8 11 16 20 23 30 31 32 38 41 42 43 44 48 52 57 58 59 63 64 77 83 86 89 90 94 95 96 97 98\n","truncated":false}}
%---
%[output:971b8fdd]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 11 6 89 53 38 56 5 73 37 24 88 84 15 40 43 94 48 8 20 46 67 14 55 62 69 49 83 75 29 27 78 80 95 28 9 93 82 4 34 30 64 31 13 57 96 39 61 65 45 71 16 18 47 42 12 79 32 70 76 63 36 91 60 51 26 90 74 81 22 59 10 2 86 66 17 23 33 25 77 92 21 87 54 1 52 19 58 72 35 7 68 3 44 50 41 85\n","truncated":false}}
%---
%[output:39d5a83b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [26 86] at positions [38 78]\n","truncated":false}}
%---
%[output:0c0809b7]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR17_RUN04.xlsx\n","truncated":false}}
%---
%[output:8cf8ede1]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 42 31 26 62 61 76 70 95 23 73 13 22 14 82 72 49 83 33 39 86 57 5 53 21 87 16 8 40 67 24 43 7 71 36 52 48 28 94 96 84 20 45 44 11 91 50 63 69 3 75 85 10 6 54 81 46 58 12 27 56 37 88 65 64 30 9 38 74 77 41 18 80 32 19 68 60 93 29 51 25 2 35 4 92 15 55 1 79 89 47 66 34 90 59 78 17\n","truncated":false}}
%---
%[output:47b1c4f9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tFound solution after 3 attempt(s): 88 2 28 26 62 12 10 59 66 92 51 21 76 72 32 7 89 38 54 46 35 94 71 43 67 3 65 60 55 93 23 82 95 16 37 4 87 29 48 19 27 50 40 80 42 31 6 61 57 73 69 63 8 33 91 96 36 39 56 24 86 68 84 64 81 34 11 17 78 25 45 14 15 79 13 58 77 90 53 85 22 47 20 74 41 49 18 5 75 1 30 83 70 52 9 44\n","truncated":false}}
%---
%[output:85b8f6f6]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 7 9 12 15 17 18 24 29 31 33 37 39 41 42 45 46 55 56 57 59 60 61 63 64 65 80 82 84 85 88 91 95\n","truncated":false}}
%---
%[output:6e533f0f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tAttempt 3 ran out of options at trial 95 of 96\n\t\tFound solution after 4 attempt(s): 79 54 59 88 83 35 28 72 48 85 30 18 90 15 74 89 55 75 4 58 7 1 25 51 37 38 62 29 11 45 3 95 73 23 41 76 78 26 39 65 10 87 93 60 22 21 91 12 69 94 70 53 84 24 66 44 32 8 6 56 68 77 27 63 5 31 61 34 16 33 64 52 36 47 92 46 9 86 71 13 19 42 82 49 67 57 2 40 17 96 14 80 81 43 50 20\n","truncated":false}}
%---
%[output:048024d0]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR17_RUN05.xlsx\n","truncated":false}}
%---
%[output:97b2b291]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 4 81 74 43 45 66 63 72 89 24 59 53 96 55 39 50 3 51 25 40 29 28 65 79 10 44 85 87 6 67 22 15 1 19 86 37 5 56 21 62 80 90 88 54 35 31 92 13 73 52 14 8 30 36 7 93 18 26 69 46 61 58 82 34 70 32 16 47 48 83 68 78 9 91 57 12 49 41 23 38 60 95 20 76 94 11 27 64 71 42 2 33 75 17 84 77\n","truncated":false}}
%---
%[output:831b7083]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [15 26] at positions [32 58]\n","truncated":false}}
%---
%[output:44c01840]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 91 72 85 59 56 1 76 60 78 74 14 4 41 29 61 43 9 22 48 36 70 32 66 37 54 27 7 87 31 86 39 88 81 11 64 83 2 82 50 15 80 16 40 51 94 20 25 68 53 42 47 90 45 28 18 38 6 57 55 79 17 58 26 89 71 75 35 65 84 93 19 13 24 96 69 23 10 3 63 30 33 12 92 49 95 5 77 46 52 44 73 62 67 8 34 21\n","truncated":false}}
%---
%[output:76e45413]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 5 9 14 15 16 19 21 22 26 27 32 35 38 42 44 52 54 56 61 66 69 71 72 77 83 84 86 87 88 95 98\n","truncated":false}}
%---
%[output:250cfa78]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR17_RUN06.xlsx\n","truncated":false}}
%---
%[output:23e752cf]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 82 52 42 92 32 76 63 80 33 49 9 91 87 77 17 36 5 29 31 56 22 16 71 73 11 55 62 93 34 74 89 13 47 30 84 85 28 72 53 45 38 51 59 20 1 8 3 26 27 61 68 41 25 35 70 90 48 94 7 39 10 67 69 19 88 66 15 58 4 96 57 83 64 14 95 65 43 40 6 50 79 60 44 21 37 54 23 81 18 75 24 12 46 78 86 2\n","truncated":false}}
%---
%[output:66b77e95]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 14 41 39 95 90 4 51 3 11 79 64 87 37 61 42 27 30 78 32 60 74 86 25 6 89 80 9 19 48 7 26 91 57 23 75 47 71 67 28 94 63 49 96 43 84 68 58 55 69 33 38 52 21 2 81 1 77 85 82 17 36 31 56 45 10 40 66 5 13 54 15 59 72 73 92 29 22 8 35 88 46 62 24 93 12 70 20 76 44 18 53 83 50 34 65 16\n","truncated":false}}
%---
%[output:717a270e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 94 of 96\n\t\tFound solution after 3 attempt(s): 76 26 59 45 77 43 53 66 81 51 94 83 69 16 80 55 29 19 9 62 8 37 88 4 7 89 30 73 78 24 93 46 32 35 48 15 22 2 65 58 52 72 38 27 23 96 13 44 6 21 75 84 68 1 87 64 36 74 67 41 39 90 31 63 17 34 54 56 10 57 86 42 95 82 33 60 85 70 28 47 11 5 92 18 79 61 20 49 40 71 14 50 3 25 91 12\n","truncated":false}}
%---
%[output:11a47c16]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [56 42] at positions [5 50]\n","truncated":false}}
%---
%[output:4221e1b6]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR17_RUN07.xlsx\n","truncated":false}}
%---
%[output:73eb7ccc]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 15 16 18 19 21 23 25 30 32 34 36 42 45 48 53 54 57 61 62 63 68 70 72 76 81 82 93 96 97 98\n","truncated":false}}
%---
%[output:78ced79a]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 60 5 62 36 43 82 95 45 69 32 6 37 11 75 48 26 73 3 12 31 18 49 80 93 30 34 54 64 27 90 63 94 67 79 53 21 8 92 7 84 16 68 44 66 70 1 19 41 83 50 52 85 86 23 57 10 40 51 78 56 46 42 25 24 88 72 20 76 81 38 15 2 61 33 13 74 29 58 96 59 71 55 14 87 47 17 65 9 28 35 89 22 4 39 77 91\n","truncated":false}}
%---
%[output:91a35211]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 94 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 95 of 96\n\t\tFound solution after 4 attempt(s): 35 42 28 12 50 62 39 74 96 46 56 20 79 70 43 94 71 18 25 61 68 63 90 55 11 17 33 13 48 66 7 83 21 87 14 80 95 81 5 15 64 2 23 89 60 53 91 44 31 27 52 73 41 8 75 10 45 82 30 36 40 58 47 88 84 65 78 51 24 6 3 85 57 1 67 19 69 92 77 34 29 93 4 54 32 59 86 37 16 38 72 49 76 26 9 22\n","truncated":false}}
%---
%[output:6cd70103]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 20 45 5 39 55 43 91 35 19 27 16 69 6 11 26 59 60 92 61 12 49 77 31 76 34 74 66 51 29 83 90 28 56 71 89 14 96 72 15 65 32 37 33 21 95 58 54 3 62 82 47 75 67 42 41 64 46 8 18 10 44 81 1 2 87 70 88 94 22 24 68 50 23 93 57 13 17 9 79 25 63 80 53 84 7 85 73 4 52 40 78 38 30 48 86 36\n","truncated":false}}
%---
%[output:00192416]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR17_RUN08.xlsx\n","truncated":false}}
%---
%[output:3521f915]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 34 61 87 44 6 18 25 38 23 77 45 72 62 69 71 19 86 8 56 16 92 73 88 28 60 33 41 91 52 53 22 4 67 14 13 37 90 95 12 36 20 2 94 50 68 76 9 54 32 80 81 82 70 55 96 47 51 1 5 21 89 31 57 48 42 11 74 46 75 24 39 59 63 65 7 49 85 66 43 78 30 17 84 29 10 93 40 26 64 27 35 15 79 83 58 3\n","truncated":false}}
%---
%[output:1cbf3bb8]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 5 6 14 22 24 26 29 30 33 34 36 37 38 45 54 57 58 61 62 63 65 71 73 81 83 87 89 95 97 98\n","truncated":false}}
%---
%[output:1a7d7c1d]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 61 69 19 30 77 3 60 29 84 1 11 86 40 92 72 78 83 17 14 48 8 74 53 62 89 64 38 37 80 42 49 13 25 43 24 57 6 91 88 75 2 79 21 67 50 34 10 20 85 87 16 15 44 59 73 81 58 32 51 63 82 47 28 12 56 35 65 46 39 95 22 27 33 71 70 93 36 90 31 68 23 41 9 26 96 54 5 55 94 4 45 18 52 66 7 76\n","truncated":false}}
%---
%[output:54ed6939]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [16 96] at positions [22 70]\n","truncated":false}}
%---
%[output:87080f43]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 29 19 68 12 41 63 91 74 43 92 56 13 53 77 81 86 35 37 7 6 90 27 45 79 21 14 78 55 46 22 88 2 31 60 32 17 51 57 23 65 67 95 4 34 49 70 42 47 75 3 30 83 73 24 33 84 28 11 72 54 1 5 82 93 62 36 26 89 44 16 58 94 64 50 9 52 39 59 96 18 71 80 15 48 25 38 66 61 69 87 10 20 8 76 40 85\n","truncated":false}}
%---
%[output:6bee1e66]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR18_RUN01.xlsx\n","truncated":false}}
%---
%[output:2fc4af36]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 67 9 42 15 17 75 58 68 91 29 95 53 44 88 39 36 77 19 55 8 74 79 37 61 18 31 14 93 94 80 57 89 5 3 52 49 6 82 34 23 48 81 16 4 54 65 32 78 2 76 33 60 85 96 25 11 47 20 62 56 41 13 26 24 86 64 27 45 70 66 87 73 40 35 90 46 63 21 43 69 50 92 59 38 12 22 71 30 10 72 84 1 83 28 51 7\n","truncated":false}}
%---
%[output:7b9fb038]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 7 11 12 21 25 32 39 40 43 44 45 47 48 49 50 55 57 59 63 65 71 74 75 77 80 84 85 87 89 94\n","truncated":false}}
%---
%[output:9b6d7fae]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 57 80 25 50 82 30 3 2 85 8 58 26 90 41 96 49 5 47 35 27 37 76 4 78 38 51 53 33 14 20 32 67 93 69 65 62 39 91 92 74 52 89 45 68 21 12 83 13 23 19 94 22 55 15 70 79 9 64 75 88 95 63 24 42 18 72 34 59 54 36 6 40 46 87 71 81 28 11 16 86 10 31 73 60 7 61 17 48 29 84 56 66 43 77 1 44\n","truncated":false}}
%---
%[output:4821820d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 82 45 11 4 54 77 34 94 50 40 44 56 51 83 70 20 79 14 39 17 61 19 90 25 12 29 22 43 78 95 89 2 69 72 49 9 87 58 88 31 53 33 8 48 46 92 71 66 21 32 91 6 28 47 68 86 38 60 10 7 57 73 35 24 5 75 3 93 81 16 27 74 64 30 85 80 42 13 37 96 63 52 76 59 18 36 23 65 26 55 84 41 62 1 67 15\n","truncated":false}}
%---
%[output:5e0dc925]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR18_RUN02.xlsx\n","truncated":false}}
%---
%[output:03e653e8]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [87 59] at positions [12 72]\n","truncated":false}}
%---
%[output:86e9b93d]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 41 5 95 40 73 34 42 93 64 9 11 52 55 48 54 91 25 35 18 7 75 62 77 16 29 69 66 22 86 89 8 43 3 45 76 83 67 6 85 27 49 19 21 53 88 68 80 38 32 12 23 90 84 15 2 74 96 50 51 37 36 87 33 59 79 31 47 70 61 20 26 71 46 57 4 63 39 14 56 13 92 58 94 24 60 72 28 81 78 10 30 65 82 44 17 1\n","truncated":false}}
%---
%[output:614a56ad]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 6 8 9 11 13 19 22 23 34 36 37 39 40 42 44 45 50 54 57 59 61 64 65 71 72 76 85 88 90 93 97 98\n","truncated":false}}
%---
%[output:2d283408]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 5 27 47 36 31 62 77 3 81 70 82 59 16 74 53 84 15 57 37 83 46 14 42 67 25 90 20 28 79 38 50 49 21 6 12 96 95 17 39 65 75 73 51 4 34 64 85 66 8 29 63 69 30 93 87 52 18 11 72 91 13 54 55 41 2 9 78 48 19 80 92 35 86 10 60 7 94 40 45 76 33 32 24 71 58 68 23 1 22 89 56 43 88 26 44 61\n","truncated":false}}
%---
%[output:9ba9a1f9]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR18_RUN03.xlsx\n","truncated":false}}
%---
%[output:19d1785d]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 72 68 29 45 26 73 12 20 60 4 81 84 71 34 62 50 38 90 44 66 88 21 91 57 27 22 6 1 78 61 94 13 46 8 59 79 17 7 16 24 43 33 69 64 18 92 5 89 55 47 42 15 80 77 37 51 3 35 32 49 67 85 82 41 87 30 25 74 11 52 56 83 76 86 54 28 2 58 9 70 19 65 53 39 93 48 63 95 23 96 10 31 36 14 40 75\n","truncated":false}}
%---
%[output:78651e75]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 49 12 5 78 16 41 59 92 28 21 94 89 47 85 77 24 46 42 69 34 17 67 76 55 68 88 53 57 37 2 81 14 26 10 56 20 50 74 54 19 66 79 91 35 86 83 8 36 40 30 87 71 38 63 51 3 6 31 7 72 13 82 60 33 9 61 90 22 64 25 23 48 75 18 70 95 73 27 93 62 80 43 65 11 32 4 39 1 84 15 52 96 44 29 45 58\n","truncated":false}}
%---
%[output:65f12034]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [80 1] at positions [15 54]\n","truncated":false}}
%---
%[output:4ff688f6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 13 84 89 24 91 57 51 71 29 68 53 48 65 10 61 5 43 88 69 47 18 33 64 93 35 4 7 77 94 8 26 6 25 30 58 23 80 72 34 42 79 28 46 59 63 15 95 41 81 66 56 96 14 52 27 21 55 45 22 82 90 32 11 9 78 75 87 50 67 3 40 36 1 44 20 85 17 38 92 62 70 16 54 31 76 83 12 73 39 60 2 19 49 86 37 74\n","truncated":false}}
%---
%[output:4e116795]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR18_RUN04.xlsx\n","truncated":false}}
%---
%[output:02ae211c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 10 11 18 19 21 23 27 29 31 35 39 40 42 46 47 50 52 57 60 62 68 70 74 75 77 84 85 86 89 95 96\n","truncated":false}}
%---
%[output:39e4141f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 33 83 74 79 23 58 57 86 87 59 16 94 5 72 10 32 77 42 69 55 30 45 17 21 93 20 4 13 56 41 11 47 64 66 96 37 48 19 49 92 7 54 61 31 24 82 80 35 40 91 27 73 6 26 9 36 78 62 65 68 81 85 34 50 8 14 67 22 46 3 95 63 43 29 51 2 84 15 39 52 88 44 75 25 89 76 12 28 70 53 38 90 60 18 1 71\n","truncated":false}}
%---
%[output:5e875e27]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tFound solution after 3 attempt(s): 82 57 46 2 70 51 74 75 11 59 3 6 92 33 40 50 22 91 23 39 87 66 86 93 5 41 21 31 12 28 55 83 77 19 65 37 72 62 53 76 96 27 9 4 78 42 26 25 44 38 84 15 94 64 14 60 24 56 88 36 54 52 48 7 34 79 29 69 67 1 20 85 89 10 30 68 45 71 13 61 95 17 47 58 16 90 80 63 73 32 81 43 18 49 35 8\n","truncated":false}}
%---
%[output:3f420047]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 53 22 86 7 82 77 93 29 16 73 60 80 67 36 76 31 38 42 15 27 21 59 92 51 62 33 24 69 5 54 13 2 34 55 96 40 90 91 8 89 58 26 1 39 41 57 11 79 45 12 61 65 88 84 78 70 9 3 19 37 30 63 49 43 68 50 72 20 85 46 83 18 32 66 94 4 95 71 56 10 48 14 75 44 23 35 64 25 74 28 6 17 81 47 87 52\n","truncated":false}}
%---
%[output:6696fafe]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR18_RUN05.xlsx\n","truncated":false}}
%---
%[output:7d501015]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [11 2] at positions [13 72]\n","truncated":false}}
%---
%[output:9c76edbe]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 5 6 14 16 17 19 21 22 29 32 36 38 39 41 43 51 54 57 62 65 66 69 71 75 78 79 81 86 90 93 98\n","truncated":false}}
%---
%[output:431e2396]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 73 35 28 37 58 82 57 43 65 2 62 16 93 39 36 96 18 50 61 24 75 32 89 14 72 68 84 81 71 64 78 3 17 27 13 38 4 9 92 70 33 21 76 60 86 1 15 20 53 26 29 88 46 6 48 94 95 49 74 30 5 66 83 31 40 41 56 7 52 59 47 69 67 44 91 77 11 34 54 22 51 12 63 85 25 79 19 8 80 87 55 45 23 42 10 90\n","truncated":false}}
%---
%[output:228a2b96]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 23 84 2 19 11 71 61 21 33 4 7 57 79 20 53 92 49 37 64 13 96 72 6 40 65 80 83 32 75 48 43 82 44 28 27 62 63 10 34 3 91 85 46 73 78 95 69 17 81 25 47 29 30 77 59 41 87 1 26 16 56 88 89 54 51 18 60 68 45 42 50 22 39 58 35 76 15 12 70 93 36 8 74 9 86 66 38 94 5 55 67 24 14 31 90 52\n","truncated":false}}
%---
%[output:8aedef7e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR18_RUN06.xlsx\n","truncated":false}}
%---
%[output:9e46ae8b]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 15 32 25 9 75 91 94 12 10 60 14 92 66 57 34 56 74 78 47 65 11 41 87 18 55 50 31 38 28 81 64 96 43 1 4 29 79 23 95 20 73 71 83 88 35 45 42 54 21 48 26 27 7 52 63 68 53 86 58 37 82 77 2 46 80 33 8 85 6 69 22 51 16 19 67 39 24 90 44 61 84 70 62 13 93 30 40 5 72 3 59 36 89 49 76 17\n","truncated":false}}
%---
%[output:8cb2da4a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 44 40 16 53 13 86 66 38 71 18 67 78 57 93 8 4 26 21 54 45 52 20 90 22 37 17 5 39 96 41 85 81 59 63 72 7 79 87 29 34 1 76 56 24 19 60 75 2 51 6 36 25 10 84 15 11 30 70 77 95 74 48 35 64 88 33 69 28 94 92 50 62 46 49 43 91 65 58 14 23 83 31 73 3 80 42 32 9 61 68 27 55 82 12 89 47\n","truncated":false}}
%---
%[output:3c5b3858]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 9 10 17 18 20 21 23 25 26 28 31 32 34 35 38 41 56 62 66 67 68 71 72 75 77 78 84 85 91 93 94 95\n","truncated":false}}
%---
%[output:08109221]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [83 8] at positions [32 54]\n","truncated":false}}
%---
%[output:19f285be]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR18_RUN07.xlsx\n","truncated":false}}
%---
%[output:441fd8a3]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 77 20 17 81 45 68 71 61 67 33 82 32 55 86 13 21 73 92 79 10 59 7 43 58 19 39 26 3 83 51 64 37 11 78 74 4 2 94 89 88 24 41 36 52 5 27 22 57 25 15 48 23 85 42 38 66 47 9 70 87 8 16 62 46 93 75 50 65 29 72 53 84 63 56 1 34 80 96 12 76 14 18 54 31 6 95 44 49 40 28 35 91 60 90 30 69\n","truncated":false}}
%---
%[output:59d939a6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 93 37 25 47 3 59 81 4 22 74 44 58 34 95 24 62 17 20 12 72 92 91 53 56 14 48 78 26 94 65 66 64 67 2 84 10 16 7 86 75 1 76 71 82 42 46 30 63 54 28 80 41 50 77 18 39 8 52 36 87 90 23 88 60 85 31 19 9 43 69 55 6 32 70 51 89 11 35 40 61 5 49 38 83 45 68 13 27 96 57 79 33 21 15 73 29\n","truncated":false}}
%---
%[output:468ae12c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 94 of 96\n\t\tFound solution after 3 attempt(s): 1 19 82 53 2 12 80 5 52 44 34 61 89 8 81 38 17 28 9 48 78 18 79 86 20 54 77 36 92 65 49 27 42 3 96 90 39 94 60 64 37 68 71 14 32 4 70 23 30 76 62 56 29 87 91 69 83 26 40 10 57 16 45 31 50 73 35 55 95 15 13 67 74 47 41 84 46 22 63 72 51 25 66 24 88 59 43 75 11 33 58 93 7 85 21 6\n","truncated":false}}
%---
%[output:23dbc624]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 6 11 14 16 18 19 20 24 26 33 37 38 39 45 46 56 60 62 66 67 68 69 70 72 74 80 84 86 90 96 98\n","truncated":false}}
%---
%[output:3fe6d99d]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR18_RUN08.xlsx\n","truncated":false}}
%---
%[output:45230fb5]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 94 of 96\n\t\tAttempt 3 ran out of options at trial 95 of 96\n\t\tFound solution after 4 attempt(s): 32 93 55 83 76 86 13 50 9 22 15 71 11 4 94 85 35 80 46 56 25 48 37 90 24 77 23 64 54 75 67 59 47 8 39 27 29 95 52 3 68 18 70 62 73 34 49 88 43 81 74 82 19 16 57 20 26 53 58 40 79 2 10 42 12 28 33 36 21 6 96 5 91 87 30 38 84 44 60 14 66 69 41 17 89 1 51 45 65 31 61 72 63 92 78 7\n","truncated":false}}
%---
%[output:21ed196f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [26 81] at positions [15 62]\n","truncated":false}}
%---
%[output:93adff9e]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 51 16 41 90 53 28 52 47 8 76 33 30 75 62 70 3 10 21 24 94 23 15 59 56 95 46 64 79 65 81 91 66 27 48 38 71 20 13 83 5 26 92 80 9 12 39 61 37 85 57 1 87 2 63 60 32 72 35 44 7 74 50 88 82 36 19 17 55 4 93 29 40 67 68 84 25 69 6 54 78 58 18 96 45 31 11 77 22 43 86 73 34 14 42 49 89\n","truncated":false}}
%---
%[output:4df0b406]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 38 94 61 12 19 43 64 63 35 1 68 21 69 81 16 60 90 34 22 24 14 86 87 70 52 29 59 75 44 80 2 47 42 9 3 84 32 85 48 33 82 5 13 67 79 53 72 18 91 96 31 20 39 58 50 25 78 83 56 89 65 74 45 77 7 62 36 26 4 17 51 15 41 57 92 37 73 11 93 6 30 49 10 55 71 28 40 8 46 23 88 66 95 54 27 76\n","truncated":false}}
%---
%[output:08d6ab47]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 7 12 16 20 25 29 30 31 34 35 38 41 43 45 47 48 54 61 62 63 67 68 71 74 80 81 84 86 91 93 96 97\n","truncated":false}}
%---
%[output:8fc56479]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR19_RUN01.xlsx\n","truncated":false}}
%---
%[output:66f9148a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 30 13 20 76 21 85 37 39 14 46 51 26 40 92 84 66 45 77 7 53 83 8 79 90 54 9 5 95 31 24 62 35 28 34 1 78 75 60 59 80 11 89 61 49 2 27 86 23 22 63 38 93 65 42 19 6 44 43 50 91 81 12 15 52 29 67 73 88 41 72 64 70 18 71 94 36 82 69 33 74 16 55 48 3 68 57 17 58 96 25 4 32 87 56 10 47\n","truncated":false}}
%---
%[output:98a9a365]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 93 of 96\n\t\tAttempt 3 ran out of options at trial 95 of 96\n\t\tAttempt 4 ran out of options at trial 95 of 96\n\t\tAttempt 5 ran out of options at trial 96 of 96\n\t\tFound solution after 6 attempt(s): 87 88 11 59 32 77 33 40 24 44 91 19 57 12 9 27 25 5 79 73 28 82 69 90 56 83 35 8 38 70 55 52 46 53 78 4 96 64 39 93 84 72 49 20 61 74 23 15 42 36 62 3 63 54 92 6 80 45 31 89 41 1 94 29 21 43 68 95 34 81 10 26 66 75 2 13 48 18 76 47 16 30 58 85 71 51 65 14 67 17 86 22 37 60 7 50\n","truncated":false}}
%---
%[output:9288c77e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [45 1] at positions [11 58]\n","truncated":false}}
%---
%[output:4f4c872b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tAttempt 5 ran out of options at trial 95 of 96\n\t\tAttempt 6 ran out of options at trial 96 of 96\n\t\tAttempt 7 ran out of options at trial 94 of 96\n\t\tFound solution after 8 attempt(s): 86 49 3 87 28 39 91 33 30 20 78 38 79 11 41 62 21 95 8 18 7 80 96 93 71 57 88 10 60 51 73 76 31 54 48 42 4 15 66 85 82 40 32 69 59 46 53 16 64 68 9 47 43 67 35 89 24 26 36 2 12 27 83 50 61 19 5 92 72 23 52 94 74 77 55 84 34 29 65 14 58 45 56 13 81 63 22 90 17 37 1 25 6 70 44 75\n","truncated":false}}
%---
%[output:2247e620]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR19_RUN02.xlsx\n","truncated":false}}
%---
%[output:42f2549c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 5 8 14 15 17 18 19 23 27 36 37 41 46 49 57 59 67 68 70 73 78 79 81 82 84 89 94 96 97 98\n","truncated":false}}
%---
%[output:1d4d3413]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 94 of 96\n\t\tFound solution after 3 attempt(s): 30 55 32 2 57 68 71 4 46 83 36 22 75 47 61 50 89 52 7 24 45 74 17 86 26 31 3 92 16 76 53 35 33 11 9 72 81 78 80 25 62 42 43 54 82 90 64 5 21 96 87 38 69 12 15 34 13 58 73 56 49 20 40 18 79 85 19 27 1 95 14 44 91 65 48 6 63 70 10 84 29 37 77 41 93 39 59 23 66 60 8 28 51 94 67 88\n","truncated":false}}
%---
%[output:6883677f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 43 12 53 31 59 66 41 44 27 45 75 78 61 47 52 60 7 40 89 11 17 69 28 10 3 83 58 86 92 39 56 74 93 25 82 70 6 77 30 29 5 1 63 35 26 19 85 49 21 38 2 48 76 8 80 88 42 91 15 87 72 50 4 32 67 65 34 46 68 57 54 84 81 18 62 71 20 95 36 55 94 22 64 9 37 13 96 73 90 51 33 23 16 79 14 24\n","truncated":false}}
%---
%[output:881fd128]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 80 54 44 46 86 89 55 69 23 22 52 27 85 25 5 88 67 79 43 28 73 2 37 64 82 36 72 95 15 70 30 48 14 21 24 87 96 35 45 53 49 9 58 91 8 6 62 4 1 29 41 78 68 40 92 26 61 32 3 94 77 12 39 20 74 56 60 33 10 65 93 51 76 13 34 19 47 90 31 71 57 38 7 50 17 84 63 11 75 81 66 18 16 83 42 59\n","truncated":false}}
%---
%[output:9710a3bd]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR19_RUN03.xlsx\n","truncated":false}}
%---
%[output:59bbd9e1]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [72 15] at positions [15 52]\n","truncated":false}}
%---
%[output:34c7648a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 9 10 14 22 23 30 32 34 35 37 38 39 46 49 53 61 65 71 78 80 81 82 85 86 88 89 90 92 95 98\n","truncated":false}}
%---
%[output:72c2e945]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 14 5 48 40 70 27 78 89 22 39 53 84 54 29 6 80 67 41 3 93 65 9 55 52 72 59 44 81 4 17 60 8 25 23 90 96 42 19 91 95 24 73 1 47 46 50 36 32 56 86 10 83 71 63 51 21 7 57 16 66 94 49 77 45 85 38 11 13 82 33 69 31 20 35 88 30 76 74 26 2 62 75 15 79 34 58 92 61 28 43 68 87 12 18 64 37\n","truncated":false}}
%---
%[output:763b73c8]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 94 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 94 of 96\n\t\tFound solution after 4 attempt(s): 51 74 38 73 4 8 66 18 75 90 54 22 26 94 71 79 57 7 37 14 52 34 36 92 23 15 95 6 25 48 56 93 81 45 28 60 50 32 31 82 19 35 55 3 72 47 70 84 41 43 1 86 12 33 88 49 39 27 78 5 10 20 9 53 65 21 63 58 83 67 76 64 96 89 80 16 24 77 29 87 61 17 46 68 85 42 2 69 40 30 59 13 62 44 91 11\n","truncated":false}}
%---
%[output:79c6b5d0]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR19_RUN04.xlsx\n","truncated":false}}
%---
%[output:8f8fd5ad]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 76 78 38 42 89 43 66 31 4 39 15 96 58 6 30 55 93 69 54 34 28 23 67 94 16 59 24 40 50 63 79 11 14 70 87 26 83 85 75 73 47 7 51 60 27 49 91 17 10 3 88 12 29 74 19 95 46 80 56 8 35 61 72 13 68 53 37 48 84 62 18 41 25 32 64 45 77 1 22 33 86 90 44 2 52 5 36 21 81 9 92 65 82 57 71 20\n","truncated":false}}
%---
%[output:81d95673]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 83 12 84 17 30 79 19 82 60 32 44 28 53 9 56 94 45 58 75 35 47 70 72 91 66 63 64 37 96 92 67 16 11 48 8 74 78 29 15 27 36 5 51 71 46 55 59 43 86 10 93 81 49 2 4 76 95 42 21 25 14 22 62 31 77 52 90 26 89 23 87 57 34 41 68 1 39 73 6 50 65 88 80 54 7 33 20 38 3 85 40 61 18 13 69 24\n","truncated":false}}
%---
%[output:67c4b00d]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 5 8 13 17 18 19 20 21 28 29 31 34 38 49 52 53 56 68 73 75 84 86 87 88 91 92 93 95 96 97\n","truncated":false}}
%---
%[output:571c7e17]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 59 24 80 62 65 9 76 78 26 50 82 10 54 55 44 83 81 71 42 58 1 91 57 60 92 39 77 95 19 94 75 33 25 45 46 13 15 38 32 28 12 23 27 85 84 5 73 79 16 4 41 93 34 7 90 53 8 52 37 63 66 20 3 21 70 49 17 47 67 86 30 61 40 36 6 74 96 43 87 69 31 56 22 72 2 88 11 35 18 48 64 14 29 89 51 68\n","truncated":false}}
%---
%[output:31e2abd1]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR19_RUN05.xlsx\n","truncated":false}}
%---
%[output:11d778ef]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [31 89] at positions [33 68]\n","truncated":false}}
%---
%[output:86ae51f9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 7 10 34 31 73 30 28 5 29 37 96 95 67 63 74 1 51 44 39 75 92 64 12 88 45 54 87 32 85 3 78 72 35 8 86 61 49 27 58 56 80 43 36 79 65 23 53 16 70 11 20 15 50 91 2 41 57 25 81 21 46 18 77 55 42 94 66 84 33 14 4 52 22 24 47 89 82 59 48 13 26 71 93 9 40 76 38 60 83 17 6 68 62 69 19 90\n","truncated":false}}
%---
%[output:0a22ac35]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 95 of 96\n\t\tFound solution after 5 attempt(s): 79 29 22 64 75 72 8 90 80 42 34 18 88 83 19 6 51 26 71 85 16 38 58 41 1 73 53 13 5 20 47 81 44 76 7 12 69 35 96 52 60 92 82 46 30 11 55 45 37 2 39 56 15 23 17 36 68 21 54 67 61 91 28 89 4 87 66 95 49 62 24 74 78 59 77 94 70 10 32 40 65 27 9 50 43 86 63 31 57 3 48 25 93 33 14 84\n","truncated":false}}
%---
%[output:1c690cd1]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 93 of 96\n\t\tFound solution after 4 attempt(s): 40 59 41 46 16 32 71 90 12 79 33 19 26 51 2 44 94 27 11 14 57 17 45 68 3 86 65 28 88 91 58 67 69 52 84 48 1 39 20 55 62 73 89 49 25 18 9 60 6 87 37 70 36 82 4 31 66 56 53 43 64 93 21 47 34 30 95 81 72 13 75 22 61 5 7 24 42 76 78 15 63 77 29 80 85 50 92 8 38 83 74 54 23 96 35 10\n","truncated":false}}
%---
%[output:7a31a852]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR19_RUN06.xlsx\n","truncated":false}}
%---
%[output:05c80137]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 7 12 15 17 18 20 22 23 25 28 29 34 35 40 44 53 54 58 60 63 66 72 73 74 76 84 86 88 90 93 98\n","truncated":false}}
%---
%[output:6ff5f10a]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 29 85 47 9 11 53 52 84 30 2 27 60 18 38 65 35 83 66 95 88 16 81 49 69 73 55 3 42 54 34 41 24 26 67 1 71 25 68 5 86 46 82 74 72 44 45 51 50 8 40 70 17 15 7 23 32 36 28 62 77 58 19 89 87 56 93 22 76 91 13 78 48 4 63 39 64 90 57 20 14 31 94 6 96 43 92 79 12 33 80 59 75 21 37 10 61\n","truncated":false}}
%---
%[output:7cadf096]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [89 90] at positions [32 75]\n","truncated":false}}
%---
%[output:51dede73]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 87 64 57 5 71 23 39 72 46 83 30 28 86 9 21 74 55 33 12 60 29 4 81 66 76 88 84 45 63 65 11 47 38 17 58 96 44 62 42 41 93 91 27 2 1 10 32 79 59 70 77 8 92 49 13 68 18 82 7 53 89 69 35 73 94 6 36 14 75 43 25 52 22 40 67 24 20 78 61 56 85 50 19 95 31 15 34 54 48 90 37 3 51 80 16 26\n","truncated":false}}
%---
%[output:601c83aa]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR19_RUN07.xlsx\n","truncated":false}}
%---
%[output:212f97ae]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 2 13 23 87 72 47 89 15 42 51 17 45 5 52 43 22 68 92 33 40 71 20 26 54 62 76 49 96 95 21 3 65 74 1 83 60 11 75 88 38 53 84 94 66 73 19 57 63 24 39 30 8 58 77 59 34 46 4 10 32 70 36 86 6 85 31 28 82 50 14 37 78 9 18 48 67 16 35 25 55 44 81 80 41 64 27 90 56 12 79 91 7 93 29 69 61\n","truncated":false}}
%---
%[output:4ec476aa]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 10 14 17 25 26 29 31 33 36 38 39 44 45 46 47 50 51 56 58 61 62 63 70 72 73 79 82 87 90 95 97\n","truncated":false}}
%---
%[output:3a056fd5]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 40 70 62 15 32 18 41 2 82 43 48 26 81 85 4 77 78 8 50 75 45 96 76 84 25 14 39 61 57 31 58 34 27 69 21 73 46 65 51 92 60 90 64 72 16 10 42 9 17 53 38 56 59 30 87 71 28 36 33 83 24 12 5 79 94 37 93 89 1 63 3 86 47 23 20 44 80 66 19 7 49 74 52 22 91 67 88 11 68 13 95 29 54 6 35 55\n","truncated":false}}
%---
%[output:3442f0ac]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 34 40 65 70 63 15 43 30 27 59 51 87 91 39 4 76 89 50 78 20 73 42 58 28 8 10 54 36 92 5 32 93 67 7 82 31 46 24 75 47 85 35 13 53 55 26 23 2 22 96 25 60 14 83 68 18 37 41 52 44 79 71 64 95 3 69 16 12 48 86 84 49 74 88 66 81 61 38 19 9 17 77 45 1 57 90 29 62 21 94 33 80 56 6 72 11\n","truncated":false}}
%---
%[output:2f6744c0]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR19_RUN08.xlsx\n","truncated":false}}
%---
%[output:1c93c2a9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [3 94] at positions [7 51]\n","truncated":false}}
%---
%[output:798f4e7b]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 60 44 35 68 92 51 17 14 48 54 61 85 18 39 15 76 22 23 78 77 16 19 84 81 40 24 62 71 56 9 3 96 1 55 20 66 37 94 80 72 6 93 91 42 12 21 28 33 34 26 95 73 41 67 57 58 5 64 83 13 4 65 27 50 38 59 70 88 32 11 43 86 63 29 53 7 79 52 36 87 75 30 2 46 10 82 31 90 8 25 45 74 89 47 49 69\n","truncated":false}}
%---
%[output:48f267db]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 7 8 15 23 26 28 30 31 33 35 40 42 45 47 49 54 57 60 64 65 66 70 71 72 79 80 84 88 89 94 97\n","truncated":false}}
%---
%[output:26576271]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 17 81 1 67 37 28 29 4 31 69 54 11 5 88 56 26 34 39 15 36 80 25 61 95 94 23 70 78 92 41 96 71 14 52 45 59 60 79 46 40 89 90 51 13 87 22 20 63 27 16 57 65 85 43 55 93 3 33 7 19 47 30 83 76 68 53 64 42 74 32 38 18 50 6 12 75 10 72 84 35 9 62 48 82 49 21 2 91 8 44 77 24 73 58 86 66\n","truncated":false}}
%---
%[output:4e64ed14]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 15 84 26 64 62 18 28 81 4 8 19 42 74 93 56 11 80 13 34 58 40 41 32 1 60 66 37 96 71 79 49 92 90 44 3 59 70 23 72 22 75 47 85 95 55 17 29 43 2 16 68 86 78 52 5 24 91 30 14 39 73 65 9 82 10 50 36 21 57 51 89 35 48 53 94 67 25 61 77 45 69 6 87 46 20 76 83 27 7 33 63 12 31 88 54 38\n","truncated":false}}
%---
%[output:80768500]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR20_RUN01.xlsx\n","truncated":false}}
%---
%[output:43c5572f]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 83 25 84 47 72 52 56 32 49 91 15 96 54 80 37 27 8 22 66 76 5 33 13 9 60 44 88 81 75 94 51 1 77 30 23 45 43 63 53 24 55 39 48 74 16 41 87 82 40 28 11 10 64 67 95 73 71 34 2 29 90 14 79 21 17 70 57 89 18 46 61 3 86 38 31 7 50 4 42 59 35 92 78 6 85 20 68 36 69 26 58 65 62 19 93 12\n","truncated":false}}
%---
%[output:19fedd29]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [71 68] at positions [47 55]\n","truncated":false}}
%---
%[output:1aac594e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 9 17 18 19 22 25 30 34 35 37 38 40 42 43 45 49 51 53 54 55 61 64 68 71 73 77 81 85 86 90 91 96\n","truncated":false}}
%---
%[output:67e093b6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 93 of 96\n\t\tFound solution after 2 attempt(s): 67 3 90 32 4 1 73 96 79 24 25 60 29 74 50 51 36 28 42 2 21 82 34 87 8 59 70 45 69 80 92 93 61 81 57 10 33 41 49 47 76 63 77 26 44 53 16 12 17 7 72 38 14 83 9 58 30 54 62 91 71 65 6 40 23 88 20 66 13 75 84 95 35 48 85 55 37 19 31 94 68 43 5 27 78 56 86 15 64 18 39 89 22 52 11 46\n","truncated":false}}
%---
%[output:118ca73c]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR20_RUN02.xlsx\n","truncated":false}}
%---
%[output:9db055e8]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 17 22 36 51 2 52 39 81 84 9 47 21 78 64 30 57 49 93 24 1 23 90 73 14 70 91 40 79 28 31 66 42 6 86 54 75 69 50 68 46 44 8 5 83 15 58 95 41 55 27 94 53 3 10 32 60 35 25 12 65 89 74 18 33 43 77 11 34 88 96 19 67 71 20 59 61 48 29 82 56 4 87 80 16 26 37 72 92 7 63 85 38 62 76 45 13\n","truncated":false}}
%---
%[output:82a524dc]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 94 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 63 64 30 78 82 42 31 88 90 57 33 15 89 24 32 40 87 70 73 56 85 11 55 66 4 14 26 12 47 61 13 80 19 50 92 43 35 67 45 60 49 41 27 3 69 77 37 74 62 1 51 72 29 84 65 95 16 96 93 58 21 54 17 28 38 46 81 23 68 5 7 44 6 18 48 52 91 75 25 76 8 39 10 86 9 71 59 34 94 20 2 22 53 79 83 36\n","truncated":false}}
%---
%[output:3ccbe344]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 47 94 52 54 76 39 61 21 84 77 96 17 58 91 8 31 66 1 83 48 80 59 15 9 74 27 46 7 40 33 22 4 56 44 37 19 30 38 49 92 81 20 23 69 65 86 13 50 79 75 29 16 14 34 71 36 95 90 67 2 28 57 60 45 5 87 41 11 78 51 25 85 64 10 63 26 89 24 72 3 42 88 70 32 12 93 43 18 35 53 6 73 82 55 68 62\n","truncated":false}}
%---
%[output:9a8a6856]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 5 6 11 13 14 18 26 32 35 36 41 42 43 44 49 55 56 57 64 65 66 68 72 75 76 78 80 88 91 95 97\n","truncated":false}}
%---
%[output:8de49675]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR20_RUN03.xlsx\n","truncated":false}}
%---
%[output:584e15f3]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [49 63] at positions [41 76]\n","truncated":false}}
%---
%[output:87e8f35d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 94 of 96\n\t\tAttempt 3 ran out of options at trial 94 of 96\n\t\tAttempt 4 ran out of options at trial 95 of 96\n\t\tAttempt 5 ran out of options at trial 96 of 96\n\t\tAttempt 6 ran out of options at trial 96 of 96\n\t\tAttempt 7 ran out of options at trial 95 of 96\n\t\tFound solution after 8 attempt(s): 81 21 49 56 42 55 14 92 87 12 22 1 58 18 37 89 48 66 46 16 79 59 94 50 65 77 27 23 95 72 15 45 34 29 70 86 39 36 88 82 25 7 8 32 60 57 69 61 31 44 24 19 85 67 2 51 6 93 52 47 78 68 33 63 83 10 73 91 40 9 3 38 20 74 28 13 64 90 30 41 96 75 4 26 76 53 35 62 11 71 43 5 84 54 80 17\n","truncated":false}}
%---
%[output:5dea2cc1]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 94 of 96\n\t\tFound solution after 2 attempt(s): 27 53 45 91 36 35 8 69 25 3 81 51 95 77 48 54 79 84 28 67 66 63 11 21 38 75 6 33 18 96 9 13 59 64 29 30 43 12 22 86 94 40 89 5 62 88 73 76 56 14 2 39 31 58 52 34 80 4 85 19 68 83 90 50 26 10 78 47 49 74 32 23 37 41 1 71 57 20 72 7 93 65 42 55 70 87 60 92 17 16 44 24 82 15 61 46\n","truncated":false}}
%---
%[output:13e01fc0]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 95 of 96\n\t\tAttempt 5 ran out of options at trial 96 of 96\n\t\tAttempt 6 ran out of options at trial 95 of 96\n\t\tAttempt 7 ran out of options at trial 96 of 96\n\t\tAttempt 8 ran out of options at trial 96 of 96\n\t\tAttempt 9 ran out of options at trial 95 of 96\n\t\tFound solution after 10 attempt(s): 2 19 64 75 63 15 41 17 45 76 96 53 35 55 30 22 94 27 13 93 4 59 51 86 95 79 71 32 78 37 44 5 9 72 3 28 7 82 34 89 10 39 52 33 38 67 24 29 60 81 80 50 20 87 36 21 70 77 83 85 31 43 84 61 54 14 8 66 12 62 69 42 1 88 26 56 73 46 65 90 68 23 74 11 25 91 58 6 49 40 57 18 48 92 47 16\n","truncated":false}}
%---
%[output:9566b30a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR20_RUN04.xlsx\n","truncated":false}}
%---
%[output:1405208b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 7 12 14 16 17 21 24 30 31 32 33 37 41 43 49 52 58 62 66 67 68 72 73 76 78 79 82 83 86 91 93\n","truncated":false}}
%---
%[output:5e2bcbb7]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 62 26 50 52 76 61 93 15 8 88 82 66 44 42 72 78 2 19 80 83 17 12 71 27 81 54 48 24 40 4 46 87 33 51 10 57 68 18 28 92 60 30 45 23 3 35 37 94 74 55 47 77 1 67 39 64 6 29 69 91 13 86 85 25 31 63 49 95 38 14 11 53 16 21 79 73 20 43 32 56 41 9 58 75 7 90 34 89 22 5 70 84 59 96 65 36\n","truncated":false}}
%---
%[output:92ccf368]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [21 40] at positions [33 78]\n","truncated":false}}
%---
%[output:8bb464a6]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 80 51 83 73 67 11 89 29 74 81 48 85 95 4 36 64 71 34 32 19 91 50 14 1 62 33 70 27 45 12 68 92 65 54 18 57 58 39 35 77 28 13 21 2 56 30 43 26 82 3 25 63 88 22 72 5 8 38 7 75 47 40 49 52 79 69 93 46 94 55 6 86 90 10 24 20 96 78 17 16 53 41 66 9 42 23 60 87 37 59 15 76 61 31 44 84\n","truncated":false}}
%---
%[output:97e1e295]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR20_RUN05.xlsx\n","truncated":false}}
%---
%[output:745ee0dd]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 58 84 21 38 34 29 92 91 59 9 66 41 6 95 78 87 8 23 27 10 61 63 48 81 44 70 68 22 67 12 16 40 50 31 64 75 49 65 33 69 57 25 5 39 4 85 11 52 90 89 28 96 36 94 71 72 30 42 62 14 18 20 60 35 46 19 77 3 2 74 82 51 56 15 47 17 43 76 45 13 93 53 26 80 83 73 24 54 88 37 86 1 55 79 7 32\n","truncated":false}}
%---
%[output:9945c8fa]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 3 5 7 10 11 19 21 28 29 39 40 44 47 49 51 52 59 60 62 72 73 76 80 83 85 86 90 93 96 97\n","truncated":false}}
%---
%[output:5c778e8b]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 5 28 77 24 18 37 52 1 54 21 89 95 48 36 66 92 11 88 71 60 39 4 15 44 27 55 59 80 45 84 32 7 70 8 19 69 75 42 49 83 62 91 57 74 31 64 26 3 76 86 34 17 30 47 93 72 63 38 2 6 40 46 73 79 14 94 87 16 61 53 10 51 12 68 9 29 96 23 67 41 85 65 82 13 81 35 78 56 20 43 50 33 22 90 25 58\n","truncated":false}}
%---
%[output:9a64de15]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 52 65 33 96 62 48 39 9 80 72 94 70 1 59 24 28 89 12 47 67 30 5 2 95 46 51 60 93 82 22 44 17 71 55 6 31 56 85 36 69 83 66 68 21 40 13 32 8 84 90 10 3 63 26 87 57 74 34 53 58 41 91 19 54 7 38 35 27 78 61 42 25 18 92 45 77 4 75 50 23 14 49 86 73 37 16 81 29 43 88 11 76 15 20 64 79\n","truncated":false}}
%---
%[output:75dae226]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR20_RUN06.xlsx\n","truncated":false}}
%---
%[output:14f574e5]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [88 80] at positions [21 53]\n","truncated":false}}
%---
%[output:00e83291]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 24 83 2 25 48 76 81 44 5 80 10 94 91 60 30 32 78 36 84 66 49 65 73 28 15 35 51 12 62 46 37 19 55 82 17 7 14 3 47 4 27 95 40 71 56 54 41 18 57 8 89 69 9 64 58 72 21 67 70 42 93 52 31 22 33 38 53 88 86 13 74 90 26 43 59 6 61 34 23 50 85 1 79 29 87 45 92 68 96 63 75 11 39 16 20 77\n","truncated":false}}
%---
%[output:3f3e5bcd]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 8 9 21 25 26 28 30 31 34 35 38 41 42 44 46 47 53 56 62 64 66 68 72 77 80 81 82 84 91 92 95 98\n","truncated":false}}
%---
%[output:03736277]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 78 35 7 89 85 64 91 77 60 26 30 16 18 36 19 80 93 37 40 56 62 43 69 74 28 61 79 6 5 49 9 39 94 2 66 90 32 95 70 25 23 86 54 44 1 92 12 8 59 72 50 24 4 31 67 76 33 87 46 48 29 34 75 14 45 57 52 11 65 55 83 22 58 17 73 21 10 51 71 13 96 88 42 68 47 63 3 41 20 38 81 53 84 15 27 82\n","truncated":false}}
%---
%[output:38fede05]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR20_RUN07.xlsx\n","truncated":false}}
%---
%[output:7265088a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 43 2 15 52 55 30 27 57 72 94 48 84 56 91 67 1 93 24 11 34 33 71 50 8 31 45 62 44 19 88 7 80 23 69 75 46 77 96 82 5 89 28 49 29 13 76 58 66 78 18 32 95 42 9 26 38 25 70 6 47 86 73 35 51 81 85 59 53 40 39 14 63 10 4 65 21 37 92 12 83 60 87 41 54 36 68 3 20 74 90 22 16 61 17 64 79\n","truncated":false}}
%---
%[output:5df0ad86]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 95 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tAttempt 5 ran out of options at trial 95 of 96\n\t\tFound solution after 6 attempt(s): 16 85 81 9 60 72 70 51 26 43 37 55 59 40 32 88 47 68 11 25 66 82 79 46 95 29 63 8 39 3 5 77 23 21 12 64 84 50 75 96 33 41 71 49 58 10 45 24 15 19 90 73 31 76 7 13 86 87 1 69 74 44 14 62 92 27 61 20 28 35 52 42 89 56 18 36 17 67 38 65 91 78 30 94 57 2 80 54 48 4 34 53 93 22 6 83\n","truncated":false}}
%---
%[output:224821d6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [57 58] at positions [28 96]\n","truncated":false}}
%---
%[output:5fc523bd]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 89 32 77 88 85 8 70 10 81 35 22 42 94 66 21 12 45 59 93 60 65 67 62 11 6 28 18 54 17 91 5 63 53 39 68 46 4 38 41 86 40 24 83 80 33 9 49 57 7 73 26 37 72 55 48 51 95 90 23 74 14 82 56 31 58 69 71 84 79 19 1 30 29 13 16 61 20 76 52 75 43 44 64 92 27 36 25 96 50 3 34 87 47 15 78 2\n","truncated":false}}
%---
%[output:0e5fd41f]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR20_RUN08.xlsx\n","truncated":false}}
%---
%[output:9f4298ac]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 10 11 13 16 20 23 28 29 31 32 37 40 43 48 49 51 52 53 54 55 59 60 64 76 79 81 83 86 89 95 96\n","truncated":false}}
%---
%[output:97ac8b5f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 94 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tAttempt 5 ran out of options at trial 96 of 96\n\t\tFound solution after 6 attempt(s): 66 26 4 56 92 30 91 64 29 73 76 51 5 25 55 47 8 12 70 93 1 36 62 63 68 10 81 65 39 72 41 37 17 34 96 84 38 79 27 19 69 59 61 90 16 20 52 7 45 53 28 48 87 42 9 67 11 57 74 83 86 58 44 18 95 32 23 13 85 78 75 88 46 43 54 82 24 40 89 77 31 49 6 15 50 71 14 33 3 94 60 22 80 35 21 2\n","truncated":false}}
%---
%[output:397f9b93]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 29 52 32 44 37 63 55 45 27 17 65 96 81 56 5 47 70 35 15 58 68 26 83 72 54 87 20 3 77 2 8 82 38 94 1 28 60 16 66 75 64 18 80 24 40 4 46 86 31 93 12 91 95 50 53 69 11 21 23 7 13 49 88 67 42 59 48 73 89 34 22 33 43 78 71 57 14 85 61 74 90 76 6 62 39 10 30 84 36 25 51 19 9 79 41 92\n","truncated":false}}
%---
%[output:727a8d16]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 81 49 46 57 26 63 66 70 95 47 12 34 96 21 85 15 51 1 23 48 28 29 74 53 58 82 83 79 31 14 84 19 91 80 42 40 73 7 11 65 35 41 52 8 37 90 5 61 39 17 78 4 13 32 38 67 94 45 6 87 62 93 89 10 76 54 60 24 2 25 27 56 72 20 71 77 9 59 33 16 92 30 64 22 36 69 55 68 44 50 3 75 88 43 18 86\n","truncated":false}}
%---
%[output:23cb293b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 94 of 96\n\t\tFound solution after 2 attempt(s): 16 70 72 27 4 26 43 5 61 69 13 48 19 89 78 35 36 54 15 92 57 17 22 76 96 47 90 25 60 50 87 85 11 2 18 31 80 56 33 74 88 67 7 34 59 42 8 91 20 58 23 46 68 38 37 84 9 14 73 28 81 53 95 94 44 30 12 49 6 41 77 65 62 52 71 1 75 39 83 32 93 45 63 10 51 24 64 86 3 29 40 21 79 55 66 82\n","truncated":false}}
%---
%[output:557db4fc]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR21_RUN01.xlsx\n","truncated":false}}
%---
%[output:0934a093]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 9 10 11 14 16 25 31 33 35 36 40 46 47 48 52 56 57 60 61 63 67 69 71 73 74 86 88 90 92 96\n","truncated":false}}
%---
%[output:3f3170c0]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [53 19] at positions [11 92]\n","truncated":false}}
%---
%[output:93a34d83]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tAttempt 3 ran out of options at trial 94 of 96\n\t\tAttempt 4 ran out of options at trial 95 of 96\n\t\tAttempt 5 ran out of options at trial 96 of 96\n\t\tFound solution after 6 attempt(s): 38 92 30 36 60 86 4 17 49 7 80 61 37 11 95 59 70 79 88 73 27 76 6 2 51 63 26 91 81 43 65 34 21 8 44 46 32 22 94 66 77 10 33 9 12 18 64 67 62 19 28 3 52 45 39 83 20 68 87 55 90 48 72 42 50 1 96 13 78 29 40 89 85 47 5 84 57 58 93 24 35 54 69 16 31 71 41 75 25 56 15 53 23 14 74 82\n","truncated":false}}
%---
%[output:294d1949]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 68 85 90 56 95 41 88 72 19 28 74 9 81 5 55 6 67 62 40 14 27 86 25 13 44 42 20 43 58 70 80 45 78 77 63 49 23 57 12 15 89 66 39 32 91 83 47 64 29 10 59 61 33 16 8 22 31 36 37 93 3 71 17 54 84 51 79 4 34 73 82 18 65 35 69 53 87 38 96 76 30 11 52 26 48 60 2 94 21 92 1 75 7 24 50 46\n","truncated":false}}
%---
%[output:57ed2291]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR21_RUN02.xlsx\n","truncated":false}}
%---
%[output:151ebc13]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 26 35 78 21 9 74 69 41 29 17 90 25 53 95 14 32 70 10 52 6 93 36 34 62 65 58 46 4 38 81 61 59 19 22 80 92 86 71 37 39 73 51 20 5 3 87 54 63 44 28 89 13 66 88 96 40 85 76 67 15 24 56 91 23 42 55 79 27 43 7 2 50 12 47 57 33 72 11 31 49 94 75 48 1 77 83 16 84 64 8 60 68 30 82 45 18\n","truncated":false}}
%---
%[output:731d59bc]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 5 6 9 10 11 18 22 24 25 26 27 28 37 45 47 52 53 54 55 56 60 62 64 75 81 85 89 91 92 93 94\n","truncated":false}}
%---
%[output:50e8760f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 50 91 86 6 42 61 39 14 13 73 26 72 51 20 92 29 11 28 17 48 36 96 55 70 87 77 78 9 53 58 15 81 44 65 47 24 57 49 4 3 38 79 54 89 23 75 94 76 68 41 88 34 56 45 31 64 18 43 7 80 16 63 69 30 12 25 82 60 85 1 95 93 10 66 2 84 22 32 74 46 37 27 35 8 52 33 59 67 83 40 71 19 62 5 21 90\n","truncated":false}}
%---
%[output:592cec04]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [47 38] at positions [32 91]\n","truncated":false}}
%---
%[output:79d260d8]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR21_RUN03.xlsx\n","truncated":false}}
%---
%[output:015c3e7f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 93 of 96\n\t\tAttempt 3 ran out of options at trial 94 of 96\n\t\tAttempt 4 ran out of options at trial 94 of 96\n\t\tAttempt 5 ran out of options at trial 96 of 96\n\t\tAttempt 6 ran out of options at trial 95 of 96\n\t\tAttempt 7 ran out of options at trial 96 of 96\n\t\tAttempt 8 ran out of options at trial 96 of 96\n\t\tAttempt 9 ran out of options at trial 96 of 96\n\t\tAttempt 10 ran out of options at trial 95 of 96\n\t\tAttempt 11 ran out of options at trial 96 of 96\n\t\tAttempt 12 ran out of options at trial 96 of 96\n\t\tAttempt 13 ran out of options at trial 96 of 96\n\t\tFound solution after 14 attempt(s): 81 66 15 94 42 89 86 18 72 95 10 57 8 28 41 37 76 38 26 90 51 29 19 60 84 12 34 5 9 73 54 36 50 61 74 78 30 1 69 71 31 7 52 48 35 92 20 75 93 56 53 17 27 82 70 45 63 11 21 40 25 64 68 2 14 88 44 67 62 91 85 22 65 33 4 39 55 23 43 24 13 32 59 46 77 49 16 96 58 79 87 6 80 3 47 83\n","truncated":false}}
%---
%[output:4ebeb166]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 47 26 62 74 92 36 39 71 51 49 4 85 1 9 53 43 10 42 55 25 32 88 24 65 5 66 41 94 54 91 79 20 35 90 89 28 11 23 64 2 78 69 96 48 75 60 21 14 34 52 82 61 45 31 19 68 7 17 87 16 13 84 72 37 12 50 57 73 29 40 33 86 93 6 44 80 67 46 3 56 22 95 77 63 81 58 38 30 15 27 70 83 18 59 76 8\n","truncated":false}}
%---
%[output:967da5af]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 12 13 23 24 27 31 34 38 39 41 42 43 44 47 49 55 57 66 68 69 70 71 77 79 81 83 85 92 95 96 98\n","truncated":false}}
%---
%[output:2bd201b9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 69 95 6 58 17 31 47 66 22 89 30 77 56 68 37 12 80 15 9 40 42 59 53 7 94 87 39 18 14 29 52 85 60 46 91 75 76 74 41 5 1 54 21 24 81 71 84 62 78 4 19 48 72 32 16 44 34 64 82 23 73 63 36 92 90 43 25 50 8 70 86 13 88 67 33 65 61 57 35 51 93 27 49 79 11 96 2 20 10 55 28 83 45 26 38 3\n","truncated":false}}
%---
%[output:2ddc748c]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR21_RUN04.xlsx\n","truncated":false}}
%---
%[output:744ccfac]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tFound solution after 3 attempt(s): 54 50 83 13 93 80 29 56 48 11 63 65 15 39 87 32 89 84 64 18 70 40 45 71 90 44 26 16 76 53 4 27 43 58 66 75 20 30 19 46 94 31 81 91 14 5 61 37 68 77 42 25 73 96 74 49 62 7 23 8 1 72 12 38 60 95 33 10 82 57 22 55 85 59 6 52 69 47 34 67 2 86 35 17 92 78 28 3 24 79 51 36 9 41 88 21\n","truncated":false}}
%---
%[output:07c40b4c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [21 7] at positions [27 64]\n","truncated":false}}
%---
%[output:34d7a9af]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 11 66 84 12 34 59 6 92 95 33 47 10 13 61 60 36 71 48 23 16 18 62 75 21 22 69 15 65 55 87 20 45 81 56 17 89 67 70 74 86 5 30 4 96 49 39 83 38 28 50 8 44 52 27 79 41 42 68 9 14 58 53 72 57 91 88 76 26 90 25 29 46 3 94 7 40 63 43 24 54 85 31 93 77 35 2 32 37 80 19 73 82 64 78 51 1\n","truncated":false}}
%---
%[output:8e1bd4c5]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 3 6 7 10 16 17 22 24 25 34 37 38 46 49 51 52 59 67 69 73 74 76 78 79 81 83 86 87 93 97\n","truncated":false}}
%---
%[output:99f7d59c]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR21_RUN05.xlsx\n","truncated":false}}
%---
%[output:022b1ee2]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 29 72 88 18 52 51 12 11 80 20 89 64 74 53 17 22 14 82 87 76 9 34 46 58 40 25 48 5 63 90 13 24 71 69 47 85 37 73 95 83 30 43 21 7 57 66 41 44 67 54 59 27 91 1 3 92 77 32 49 39 50 8 68 16 26 23 55 93 36 86 62 28 45 2 42 19 4 81 70 75 94 15 33 65 60 96 35 6 79 10 31 84 56 38 61 78\n","truncated":false}}
%---
%[output:4cef3f27]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 93 of 96\n\t\tFound solution after 3 attempt(s): 95 6 83 25 57 17 4 76 12 28 92 71 22 21 39 1 44 24 70 94 63 88 36 48 67 43 91 84 15 10 53 51 73 50 41 58 5 55 34 32 52 27 81 65 68 74 46 90 59 64 66 93 31 9 33 2 13 96 89 45 80 11 72 19 78 61 82 30 18 40 47 49 3 23 8 87 7 38 75 26 69 85 60 16 79 37 29 54 35 14 20 42 56 77 62 86\n","truncated":false}}
%---
%[output:523f8dc7]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 40 92 20 17 79 62 88 59 37 31 46 63 10 35 71 86 7 80 75 3 15 50 54 25 49 69 21 83 47 36 4 96 95 70 34 77 42 24 5 23 12 33 53 26 82 74 55 60 13 51 45 85 58 91 1 29 73 72 28 18 52 65 16 81 27 41 39 14 2 76 94 84 44 66 6 78 19 8 22 67 89 56 90 11 38 64 9 61 68 57 30 87 43 32 48 93\n","truncated":false}}
%---
%[output:2d96f713]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [67 35] at positions [13 86]\n","truncated":false}}
%---
%[output:503148c4]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR21_RUN06.xlsx\n","truncated":false}}
%---
%[output:7b3862c3]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 4 6 7 8 11 13 14 21 23 24 29 32 37 41 53 56 59 60 61 63 65 70 73 74 78 85 88 91 92 95\n","truncated":false}}
%---
%[output:9798d36f]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 51 50 25 37 90 89 71 18 14 1 83 21 73 47 60 82 53 40 13 44 48 22 26 92 8 68 61 66 72 4 31 58 3 56 11 86 46 78 87 23 42 34 77 70 2 54 65 41 91 36 63 94 88 15 29 80 93 75 19 57 55 43 16 45 27 5 79 49 28 30 95 59 7 12 38 10 67 20 39 62 84 32 69 96 64 24 9 81 74 35 85 33 17 52 76 6\n","truncated":false}}
%---
%[output:896bcb7e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 95 of 96\n\t\tAttempt 5 ran out of options at trial 95 of 96\n\t\tAttempt 6 ran out of options at trial 95 of 96\n\t\tFound solution after 7 attempt(s): 37 74 20 92 10 64 30 34 29 5 68 40 2 89 61 47 53 65 88 95 17 73 70 60 85 75 1 48 42 82 38 36 3 16 26 54 50 13 90 28 25 58 24 14 6 31 77 56 63 93 71 4 57 78 96 55 33 52 12 46 80 67 27 23 84 11 66 44 18 41 86 83 45 81 76 62 79 22 59 87 9 91 35 72 8 49 39 32 43 51 7 69 94 19 15 21\n","truncated":false}}
%---
%[output:145bb15f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 94 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 95 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tFound solution after 5 attempt(s): 2 71 64 57 19 79 67 31 17 81 86 29 15 82 76 85 9 42 47 55 69 8 60 5 16 22 44 30 59 33 84 37 1 73 38 68 26 3 52 90 61 74 7 41 21 54 92 62 35 95 20 83 48 58 14 12 96 94 78 75 93 11 25 34 77 46 39 13 27 72 51 50 24 18 70 89 45 32 6 36 56 66 43 10 53 91 28 63 4 88 65 23 87 49 40 80\n","truncated":false}}
%---
%[output:1eb9399b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR21_RUN07.xlsx\n","truncated":false}}
%---
%[output:520b3a81]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 65 35 20 38 9 40 36 54 1 80 72 7 4 57 22 68 55 51 85 89 19 90 5 17 50 76 18 31 11 86 79 94 48 88 53 43 77 46 24 21 64 74 92 69 29 47 13 87 26 93 16 71 78 63 3 15 32 70 12 60 37 73 39 52 28 10 34 91 95 56 96 42 33 81 25 84 49 58 41 62 83 66 8 67 82 14 30 44 75 27 6 45 23 61 2 59\n","truncated":false}}
%---
%[output:044c470b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 4 5 10 13 17 19 22 25 26 28 30 34 39 42 52 53 58 59 60 74 75 76 79 82 84 86 89 92 95 98\n","truncated":false}}
%---
%[output:60bb5a8b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [32 51] at positions [22 81]\n","truncated":false}}
%---
%[output:2c22e474]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 95 of 96\n\t\tAttempt 5 ran out of options at trial 93 of 96\n\t\tAttempt 6 ran out of options at trial 95 of 96\n\t\tFound solution after 7 attempt(s): 83 60 18 7 9 57 48 73 74 23 45 3 77 4 33 52 56 10 91 69 92 1 29 54 76 58 88 36 26 21 72 37 82 95 24 87 39 34 35 93 59 5 70 61 28 81 79 8 53 66 84 25 42 2 41 78 67 22 71 40 27 15 86 13 11 30 63 94 85 68 12 80 17 32 49 55 47 64 19 14 96 43 90 31 89 6 38 20 46 65 44 51 75 62 16 50\n","truncated":false}}
%---
%[output:0742cb4e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR21_RUN08.xlsx\n","truncated":false}}
%---
%[output:219cb43a]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 56 15 68 3 8 46 1 81 24 34 29 74 19 84 89 33 91 79 53 67 48 40 59 90 16 26 30 62 39 78 66 88 51 58 28 10 52 21 50 13 83 70 23 73 49 77 44 5 7 80 9 38 32 25 85 57 42 92 37 76 65 95 93 12 55 61 87 20 6 17 47 54 45 36 22 43 94 27 86 11 82 64 71 60 18 4 63 2 41 75 35 14 31 72 96 69\n","truncated":false}}
%---
%[output:6c0dfdd5]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 47 75 83 20 66 36 57 37 45 4 24 9 11 42 81 6 65 62 59 74 8 89 76 28 48 23 30 54 22 93 86 39 64 3 55 92 60 50 12 41 27 85 82 72 71 67 21 52 26 70 16 31 15 84 35 79 58 73 40 88 56 43 1 77 94 25 44 46 90 14 5 61 95 38 53 91 68 29 19 63 80 7 32 69 33 10 78 96 17 2 34 18 87 49 13 51\n","truncated":false}}
%---
%[output:433c0add]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 13 15 19 20 22 25 26 28 34 37 42 45 47 49 52 57 58 59 62 64 66 69 71 74 79 89 90 95 97 98\n","truncated":false}}
%---
%[output:1f01d362]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 32 51 72 5 79 28 29 43 60 86 9 62 20 91 90 21 80 83 39 71 58 14 25 15 16 38 85 52 35 48 19 81 68 74 36 10 82 46 53 57 70 37 65 1 17 75 24 64 13 92 73 50 49 42 40 27 12 34 7 11 77 87 56 22 26 41 96 88 8 55 84 23 61 33 95 44 3 45 76 66 30 47 59 94 69 63 67 4 78 89 54 2 93 31 6 18\n","truncated":false}}
%---
%[output:31ec04c9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [64 76] at positions [19 76]\n","truncated":false}}
%---
%[output:12c26ae0]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR22_RUN01.xlsx\n","truncated":false}}
%---
%[output:6222db44]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 7 57 80 17 93 49 60 8 79 34 54 88 31 59 41 2 39 37 81 35 27 44 75 73 58 28 5 32 66 11 6 90 65 87 14 29 20 92 86 19 48 13 69 56 9 94 77 67 33 72 22 51 68 1 4 46 62 50 24 71 84 10 52 82 36 25 21 15 85 83 55 47 95 78 18 53 74 89 61 91 42 38 63 23 96 26 16 40 3 64 45 70 12 76 43 30\n","truncated":false}}
%---
%[output:2a38be67]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 93 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 94 of 96\n\t\tFound solution after 5 attempt(s): 73 40 88 52 54 85 71 89 91 5 69 65 15 64 24 58 13 9 81 45 31 32 80 22 87 27 8 38 48 63 44 68 55 67 4 28 33 1 34 47 23 21 84 39 95 30 60 70 92 7 59 62 46 14 82 49 90 78 43 53 29 79 76 18 35 77 51 2 17 10 74 25 72 3 6 83 93 41 20 56 96 57 42 75 61 66 94 12 50 16 19 11 37 86 26 36\n","truncated":false}}
%---
%[output:8045a9f8]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 17 36 67 95 1 57 82 29 64 27 78 58 16 44 85 59 35 24 90 74 10 9 21 25 5 79 75 41 4 94 83 47 48 54 70 30 38 69 88 60 49 55 12 28 72 37 20 56 18 26 87 68 66 32 11 80 6 3 63 42 46 53 65 52 92 89 31 7 86 33 13 45 81 2 84 14 39 23 51 22 96 76 34 15 62 91 43 77 8 19 73 93 61 40 50 71\n","truncated":false}}
%---
%[output:1b0bab78]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 9 12 14 17 23 25 28 29 35 37 38 39 41 49 52 56 60 62 63 65 72 78 82 84 85 88 89 90 94 96\n","truncated":false}}
%---
%[output:678aba83]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR22_RUN02.xlsx\n","truncated":false}}
%---
%[output:617f2bf5]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 48 18 50 55 46 51 73 85 19 20 15 94 69 61 23 38 74 6 72 79 39 5 44 81 1 3 58 87 92 62 14 32 71 25 84 35 41 53 13 22 17 9 52 64 76 4 95 75 28 60 26 91 40 68 82 27 77 80 37 96 86 49 83 10 11 78 63 43 8 33 21 45 34 67 16 42 93 59 90 70 29 88 30 66 89 12 65 47 57 36 31 7 54 2 24 56\n","truncated":false}}
%---
%[output:2422faf7]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [91 72] at positions [6 89]\n","truncated":false}}
%---
%[output:7d747d8c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tFound solution after 3 attempt(s): 59 49 67 24 1 70 36 82 94 62 41 19 45 55 91 65 60 17 86 14 35 7 25 71 72 90 43 76 9 6 87 20 57 12 63 47 34 21 23 77 75 8 85 39 3 73 83 18 58 56 89 61 30 4 29 42 38 53 13 52 80 33 69 32 93 15 2 40 96 88 66 54 16 44 79 50 68 5 51 22 28 48 81 27 10 95 64 46 31 78 84 11 26 92 74 37\n","truncated":false}}
%---
%[output:7751d73a]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 95 87 8 82 77 63 67 30 1 4 24 32 46 58 28 60 89 54 7 39 14 57 47 69 75 84 31 86 48 17 78 11 72 33 45 92 90 52 56 29 37 76 66 62 49 43 26 10 41 55 65 15 71 36 40 13 12 94 73 93 22 80 18 64 16 21 20 96 38 81 2 61 85 79 3 74 19 35 9 44 23 70 59 42 83 53 5 25 50 68 91 27 6 88 34 51\n","truncated":false}}
%---
%[output:6b7d2515]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR22_RUN03.xlsx\n","truncated":false}}
%---
%[output:5bf9c31a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 6 14 19 20 21 22 23 29 32 35 37 43 45 49 58 62 65 67 71 72 75 76 77 79 83 84 87 88 90 92\n","truncated":false}}
%---
%[output:4384c2ce]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tFound solution after 3 attempt(s): 80 68 58 32 7 37 46 51 88 54 13 49 69 18 73 44 28 63 64 34 74 91 47 81 72 5 82 20 85 15 30 42 11 6 79 62 8 1 52 26 29 61 35 71 93 83 96 24 67 2 95 60 87 38 33 9 22 89 66 36 19 45 57 59 65 77 23 17 14 78 41 90 4 40 21 94 55 16 92 75 27 48 3 39 76 10 50 25 70 53 43 86 31 56 84 12\n","truncated":false}}
%---
%[output:70913744]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 9 60 53 84 68 80 90 10 32 26 12 13 70 31 36 8 94 85 28 86 41 54 2 46 17 59 47 82 57 65 52 19 78 37 77 15 20 61 39 33 58 16 5 50 87 34 75 76 18 95 66 55 25 44 24 74 83 4 43 6 72 3 91 30 21 7 64 63 67 45 40 88 49 81 93 51 38 23 71 22 89 11 73 56 1 35 79 92 29 62 27 42 96 69 48 14\n","truncated":false}}
%---
%[output:024d53e8]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [57 83] at positions [13 81]\n","truncated":false}}
%---
%[output:8ef66356]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR22_RUN04.xlsx\n","truncated":false}}
%---
%[output:362a61ed]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 93 37 80 43 44 82 22 14 76 26 25 84 92 8 34 56 2 16 61 54 41 11 95 69 72 1 24 42 18 75 94 62 85 51 73 57 28 64 88 3 38 59 21 39 4 20 7 70 10 87 96 68 89 33 29 32 81 23 53 67 17 74 78 50 58 47 90 66 40 79 9 63 13 15 36 48 6 83 12 52 77 60 86 55 35 31 5 65 46 49 27 45 91 19 71 30\n","truncated":false}}
%---
%[output:1192dccc]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 11 21 22 23 24 26 27 28 30 31 35 41 47 48 49 56 57 59 61 64 68 72 77 79 81 84 86 92 93 95 96\n","truncated":false}}
%---
%[output:5c49a499]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 25 48 3 42 87 75 52 44 57 23 55 62 4 85 93 40 47 69 2 21 74 22 17 6 70 95 29 89 13 11 50 65 73 34 19 82 61 83 41 79 68 26 12 35 8 64 76 59 51 88 9 67 92 90 72 5 27 49 30 24 33 37 63 15 94 32 78 46 81 54 43 18 1 7 28 38 77 58 36 84 71 91 53 10 60 86 20 56 66 39 31 80 16 96 14 45\n","truncated":false}}
%---
%[output:5f4ce603]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 93 61 92 47 50 45 40 95 90 79 24 44 69 91 18 14 32 23 60 57 10 71 5 49 27 77 65 46 8 38 19 86 7 16 96 2 58 78 59 84 83 29 64 72 68 26 66 33 43 11 15 85 39 56 63 9 48 81 52 36 31 3 74 13 20 17 37 73 55 21 82 70 88 76 51 30 53 89 62 75 94 28 34 87 35 4 41 22 67 42 54 6 80 1 25 12\n","truncated":false}}
%---
%[output:7e5a44f1]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR22_RUN05.xlsx\n","truncated":false}}
%---
%[output:1aebf737]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 5 24 30 50 66 32 92 69 47 85 23 12 38 64 63 90 10 79 81 88 35 1 53 17 44 22 65 9 2 95 51 46 75 74 52 13 70 31 28 57 72 33 48 93 8 56 96 36 4 34 43 78 6 83 21 87 94 68 59 26 73 77 86 55 16 27 41 25 3 15 80 91 40 61 42 58 62 82 67 45 11 19 60 71 14 89 54 29 84 7 49 39 20 37 76 18\n","truncated":false}}
%---
%[output:3e9602cf]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 60 84 62 35 52 49 78 81 29 26 6 34 92 67 37 14 57 11 31 56 18 70 9 3 72 51 76 71 23 83 91 13 86 42 43 73 65 33 25 44 59 90 4 21 79 10 53 16 5 40 12 96 80 28 32 47 82 19 2 75 55 54 36 46 68 88 94 58 24 87 39 27 64 77 38 1 30 50 41 63 93 17 15 69 95 48 20 89 61 7 45 85 66 22 74 8\n","truncated":false}}
%---
%[output:6c1cee3b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 9 11 13 17 19 23 28 29 31 33 38 39 44 47 48 51 60 62 65 69 70 71 79 81 82 83 84 86 90 93 96\n","truncated":false}}
%---
%[output:5a909d9f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [55 65] at positions [13 68]\n","truncated":false}}
%---
%[output:757a2deb]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR22_RUN06.xlsx\n","truncated":false}}
%---
%[output:5eeffb0e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 93 of 96\n\t\tFound solution after 2 attempt(s): 67 16 88 76 55 42 18 24 39 1 70 81 54 60 71 45 36 72 69 21 53 7 19 6 59 87 17 93 12 2 47 86 92 35 63 32 78 52 33 51 23 56 11 10 29 89 13 68 31 43 94 20 26 75 41 74 95 84 46 37 25 15 61 77 80 8 83 50 57 90 65 58 82 5 34 3 49 79 96 38 27 62 30 4 22 91 73 14 66 28 44 85 64 40 9 48\n","truncated":false}}
%---
%[output:390cb0f1]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 36 55 82 84 48 42 83 52 19 28 62 16 87 4 7 51 46 74 17 10 45 1 68 88 24 43 21 72 40 53 70 61 57 50 6 18 95 76 67 3 60 35 29 33 66 79 96 22 78 58 94 63 27 25 49 75 23 91 37 13 69 39 90 65 15 32 8 89 5 44 38 71 20 47 31 73 92 85 30 56 34 81 9 11 64 26 86 77 59 12 80 2 41 14 93 54\n","truncated":false}}
%---
%[output:152f54ff]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 93 of 96\n\t\tFound solution after 4 attempt(s): 20 22 2 59 34 92 93 30 42 77 60 28 84 79 16 73 48 29 74 18 52 12 46 15 31 56 66 95 43 44 64 81 1 83 63 49 65 76 54 62 8 7 38 14 27 68 10 96 91 37 39 55 89 25 88 61 36 78 32 23 45 19 11 9 58 26 86 69 71 87 4 72 47 82 3 51 13 35 53 75 41 5 21 57 40 80 6 94 17 67 24 33 85 50 90 70\n","truncated":false}}
%---
%[output:93918562]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 6 10 11 14 15 19 20 24 33 34 35 39 43 47 52 55 56 61 62 66 68 69 78 79 80 85 89 90 92 94\n","truncated":false}}
%---
%[output:59d3b9b1]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR22_RUN07.xlsx\n","truncated":false}}
%---
%[output:1c568d8a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 13 39 88 95 73 81 63 83 36 38 62 10 65 30 51 22 46 14 26 20 12 85 4 16 50 52 74 80 64 42 17 92 29 72 2 9 67 35 70 69 87 25 31 49 43 78 15 18 44 34 90 11 82 96 56 19 86 75 24 76 54 6 53 84 47 23 5 37 55 57 79 41 8 28 71 48 66 93 32 94 7 60 27 59 45 58 1 40 91 61 89 77 21 33 3 68\n","truncated":false}}
%---
%[output:3c0c62ce]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [74 15] at positions [10 94]\n","truncated":false}}
%---
%[output:0bf38b76]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 94 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tFound solution after 3 attempt(s): 53 21 14 79 72 15 5 56 77 87 25 32 39 89 67 59 91 64 50 40 78 44 10 26 96 42 61 12 33 18 69 28 63 19 24 55 8 95 85 6 13 94 46 41 47 9 71 81 66 70 2 31 65 35 80 23 83 1 45 29 37 90 20 4 58 51 88 60 75 52 48 57 74 22 7 36 68 54 11 49 43 62 27 84 92 76 82 34 86 30 73 38 16 93 3 17\n","truncated":false}}
%---
%[output:1d3f9857]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 94 of 96\n\t\tFound solution after 3 attempt(s): 19 80 21 50 62 41 96 5 2 40 63 94 27 3 61 18 47 23 17 82 53 77 64 1 79 8 85 70 65 91 35 10 30 95 88 24 74 45 46 67 16 15 69 58 9 55 57 36 25 22 51 20 7 37 73 48 54 71 72 89 86 60 83 11 92 39 81 75 32 42 12 28 66 34 38 68 59 31 52 43 90 6 56 78 14 33 13 93 29 4 76 84 49 87 44 26\n","truncated":false}}
%---
%[output:01163b39]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR22_RUN08.xlsx\n","truncated":false}}
%---
%[output:18a3dcef]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 7 9 10 14 17 18 19 30 31 33 36 37 39 42 51 54 55 57 59 60 62 63 67 73 83 84 89 90 91 94\n","truncated":false}}
%---
%[output:4478a645]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 95 of 96\n\t\tAttempt 5 ran out of options at trial 95 of 96\n\t\tFound solution after 6 attempt(s): 44 78 60 92 59 49 9 51 21 26 46 25 3 16 66 83 29 93 90 75 41 88 40 11 84 5 32 73 10 38 42 63 65 68 18 55 45 95 14 17 37 4 71 67 54 91 23 2 86 48 50 34 33 80 8 64 53 69 36 27 56 30 70 87 85 52 1 12 39 31 19 94 72 28 35 13 20 7 43 62 77 24 82 22 79 61 6 58 81 74 96 57 47 89 15 76\n","truncated":false}}
%---
%[output:29746942]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 70 10 1 49 8 35 40 54 59 95 84 46 25 42 11 87 4 27 61 37 92 52 24 3 72 55 67 43 73 23 88 65 78 82 21 32 76 17 13 64 90 68 41 47 96 2 91 60 63 6 45 14 15 71 75 81 26 36 18 29 62 77 5 20 85 39 66 53 33 50 22 79 19 12 57 30 74 93 94 28 56 9 86 51 69 38 89 34 80 58 83 7 44 31 48 16\n","truncated":false}}
%---
%[output:4e7b695c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [61 69] at positions [12 56]\n","truncated":false}}
%---
%[output:5e5afdd0]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 53 33 21 19 62 76 93 10 22 84 42 79 37 34 59 17 12 72 74 56 96 23 75 28 47 6 44 90 54 7 9 52 63 11 81 71 3 64 83 91 92 32 24 66 68 85 49 39 15 94 38 95 2 65 58 61 70 26 45 69 35 51 27 57 89 78 14 41 46 18 82 1 8 20 4 87 25 48 77 30 50 36 29 73 86 43 55 5 31 16 40 88 60 67 13 80\n","truncated":false}}
%---
%[output:66ab765a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR23_RUN01.xlsx\n","truncated":false}}
%---
%[output:05cac88e]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 6 12 16 18 19 21 22 23 29 31 34 35 38 41 46 52 55 57 60 65 66 67 68 69 70 73 74 76 77 82 94\n","truncated":false}}
%---
%[output:1579b812]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 95 of 96\n\t\tAttempt 4 ran out of options at trial 95 of 96\n\t\tAttempt 5 ran out of options at trial 95 of 96\n\t\tAttempt 6 ran out of options at trial 94 of 96\n\t\tFound solution after 7 attempt(s): 14 28 52 88 21 13 91 6 75 36 4 3 55 58 77 93 50 42 35 32 69 74 11 44 89 38 61 23 45 70 63 9 22 92 72 17 24 30 37 80 94 81 64 15 10 78 20 83 8 59 67 56 84 39 95 65 33 5 41 60 34 26 51 57 19 12 87 25 66 79 7 62 40 43 90 96 46 16 18 82 49 85 68 48 29 76 31 53 71 86 27 1 73 54 2 47\n","truncated":false}}
%---
%[output:2042ae1a]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 92 15 34 71 56 14 8 67 28 80 9 62 51 36 53 96 90 64 23 59 72 74 84 41 40 18 38 6 25 22 12 95 21 93 76 46 81 78 68 94 44 3 61 2 13 17 79 37 49 69 16 77 57 87 58 26 10 86 31 60 63 39 88 5 43 66 30 85 91 47 48 32 45 20 27 35 73 33 52 29 4 24 65 83 54 7 42 11 89 1 75 55 70 19 50 82\n","truncated":false}}
%---
%[output:08f94a4e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 38 95 29 6 46 51 69 30 79 35 25 82 40 41 15 52 31 54 4 73 78 89 2 86 58 87 76 13 28 18 36 77 50 33 67 66 93 96 14 10 68 61 63 64 26 44 11 1 37 57 16 56 80 42 94 32 88 71 27 17 9 81 55 47 23 72 7 21 49 92 90 39 48 75 12 43 8 24 74 53 70 85 5 60 22 84 20 62 45 91 65 34 19 3 83 59\n","truncated":false}}
%---
%[output:22774130]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR23_RUN02.xlsx\n","truncated":false}}
%---
%[output:35e129f9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [8 96] at positions [34 71]\n","truncated":false}}
%---
%[output:011becf5]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 4 5 8 9 15 20 24 32 37 38 39 42 44 48 53 56 58 60 63 65 73 75 78 81 86 88 90 93 95 98\n","truncated":false}}
%---
%[output:1c78b57a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 70 1 11 89 63 67 71 27 28 47 79 48 36 49 60 91 4 73 93 17 68 56 13 25 62 44 10 38 96 72 66 84 41 30 2 64 29 86 82 34 83 77 22 52 5 85 24 21 15 46 26 87 92 12 54 59 88 58 18 69 37 57 80 14 16 75 50 35 65 61 74 31 43 7 20 9 33 42 78 45 81 39 55 3 53 23 90 32 76 94 51 95 8 19 40 6\n","truncated":false}}
%---
%[output:3dd498fb]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 95 of 96\n\t\tFound solution after 4 attempt(s): 57 10 24 27 65 60 68 67 15 49 51 94 85 46 62 41 83 23 54 18 4 34 12 70 39 40 74 88 80 31 87 11 3 91 55 33 22 43 95 37 45 73 96 53 2 32 21 69 5 77 58 29 44 19 14 90 75 48 50 79 66 30 61 56 81 8 6 38 1 64 25 84 26 36 86 89 71 82 20 93 59 42 13 35 52 78 16 92 47 76 63 9 17 7 72 28\n","truncated":false}}
%---
%[output:1884ff32]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR23_RUN03.xlsx\n","truncated":false}}
%---
%[output:9548ec22]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tFound solution after 3 attempt(s): 88 30 34 41 84 96 78 75 29 1 73 51 57 38 15 47 72 33 61 13 18 89 14 87 54 93 42 23 59 66 6 63 26 28 80 90 20 36 27 65 44 52 39 77 91 12 3 8 69 31 24 5 62 50 68 56 95 55 19 58 9 43 94 92 40 4 86 76 16 21 82 25 2 83 11 35 48 32 71 70 45 7 79 53 46 64 17 81 74 85 37 67 22 60 10 49\n","truncated":false}}
%---
%[output:613f97a1]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 39 55 57 33 15 47 81 64 22 82 66 73 44 37 28 80 14 75 94 40 70 53 90 11 32 17 61 67 21 6 62 13 5 91 89 20 41 56 51 31 95 59 96 18 8 43 79 38 35 4 23 26 45 87 83 68 69 29 60 48 30 71 50 65 10 54 9 76 86 42 78 84 16 2 93 49 77 12 46 3 63 7 88 19 92 72 34 58 25 52 85 1 24 36 27 74\n","truncated":false}}
%---
%[output:7925b64d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [37 31] at positions [48 85]\n","truncated":false}}
%---
%[output:02b16632]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 9 16 17 21 23 25 27 28 32 33 34 37 38 44 47 49 50 54 57 58 62 66 68 71 72 76 79 86 90 92 95 98\n","truncated":false}}
%---
%[output:7b990bdf]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR23_RUN04.xlsx\n","truncated":false}}
%---
%[output:5c0ecd31]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 16 44 31 68 3 2 52 64 38 1 27 28 88 40 43 67 48 56 75 80 86 62 12 74 53 84 7 89 94 18 33 90 69 30 51 24 6 57 29 46 36 54 50 70 20 4 42 81 13 66 49 14 19 71 11 5 96 17 82 95 41 9 23 21 63 45 76 79 47 22 61 85 72 91 55 87 37 65 32 8 35 60 77 59 34 15 92 73 39 25 93 10 78 83 58 26\n","truncated":false}}
%---
%[output:8a308455]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 94 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tFound solution after 5 attempt(s): 31 46 68 43 84 56 57 87 18 6 66 20 81 45 26 72 59 32 28 52 10 40 16 27 60 47 39 50 80 9 53 58 91 1 3 90 78 71 94 93 88 11 51 13 41 67 19 96 54 29 33 85 36 23 15 74 35 38 7 82 69 92 25 73 75 4 5 17 22 76 64 65 89 8 77 2 83 70 42 63 34 79 61 37 55 14 49 21 12 48 86 44 30 62 95 24\n","truncated":false}}
%---
%[output:91e9487a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 76 24 68 59 85 54 41 88 10 6 62 72 96 92 22 40 17 82 66 79 9 27 12 73 39 43 11 95 48 58 60 29 50 3 33 69 63 32 21 42 84 71 77 47 37 51 91 16 64 34 80 25 23 83 31 7 44 5 2 70 89 46 19 78 4 93 61 8 18 57 55 74 20 1 49 14 86 87 28 90 67 45 13 36 65 52 30 56 81 15 75 94 35 26 38 53\n","truncated":false}}
%---
%[output:416adb8c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tAttempt 3 ran out of options at trial 92 of 96\n\t\tAttempt 4 ran out of options at trial 96 of 96\n\t\tFound solution after 5 attempt(s): 90 68 29 49 56 75 53 12 26 19 14 7 85 37 89 54 20 95 1 34 48 16 55 83 92 23 76 10 73 47 59 42 65 91 21 33 25 8 77 71 82 96 36 41 2 4 31 51 30 22 79 13 45 17 88 70 50 9 64 52 93 62 78 46 86 11 81 67 27 39 74 80 28 3 87 35 58 38 60 15 43 72 84 5 69 6 32 61 40 18 44 94 63 66 57 24\n","truncated":false}}
%---
%[output:106c1bfa]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR23_RUN05.xlsx\n","truncated":false}}
%---
%[output:59fd97d4]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 10 17 21 26 29 32 33 34 35 36 40 41 45 49 57 64 68 69 70 77 78 79 82 83 85 88 90 92 93 98\n","truncated":false}}
%---
%[output:991ced32]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [35 37] at positions [9 76]\n","truncated":false}}
%---
%[output:3e3337e6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 32 12 4 17 51 13 70 10 45 53 66 33 5 84 56 55 88 48 42 94 74 87 19 90 2 52 44 29 72 21 34 65 58 20 28 40 26 89 81 16 71 73 49 82 77 43 80 91 95 27 59 47 7 41 85 63 11 57 23 31 68 75 25 6 96 39 60 61 69 15 18 83 79 50 30 38 37 67 1 8 62 36 64 92 46 14 93 3 76 24 54 78 35 86 22 9\n","truncated":false}}
%---
%[output:18e2c003]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 16 2 96 65 40 36 68 5 29 45 9 73 79 30 92 44 53 64 42 17 8 33 90 60 4 61 86 91 21 28 76 81 7 83 57 75 59 26 56 18 71 31 82 48 89 32 51 10 23 19 3 37 72 69 41 63 38 15 14 70 87 84 12 52 67 50 58 93 80 11 54 20 35 22 77 46 34 55 85 43 78 27 62 6 94 74 49 66 1 25 47 95 13 39 24 88\n","truncated":false}}
%---
%[output:93f5ace0]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR23_RUN06.xlsx\n","truncated":false}}
%---
%[output:62d6ac28]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 71 57 22 31 16 76 41 79 73 94 75 23 54 3 58 92 85 61 59 44 64 77 14 9 83 38 84 25 88 13 30 48 35 17 67 4 39 7 50 52 65 66 34 53 11 32 86 8 36 81 72 19 6 70 56 33 80 93 18 28 46 1 15 95 60 89 47 42 29 69 49 27 51 2 24 55 91 87 45 26 74 96 62 78 43 5 63 37 90 12 82 20 40 68 21 10\n","truncated":false}}
%---
%[output:83edc7ac]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 6 7 9 10 12 21 24 25 31 36 37 38 41 43 52 55 58 60 62 64 68 76 77 78 85 88 89 90 92 93\n","truncated":false}}
%---
%[output:2411c03f]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 88 48 12 78 50 83 54 13 43 36 68 1 92 30 49 79 71 94 66 45 26 7 53 17 67 32 93 84 8 2 27 18 47 52 34 85 76 6 64 60 91 61 19 72 40 59 3 82 38 41 21 62 51 74 69 56 46 10 35 73 81 29 95 87 9 14 80 22 24 44 90 23 4 20 11 42 57 5 28 86 65 39 31 55 96 15 77 89 37 75 58 70 16 63 25 33\n","truncated":false}}
%---
%[output:27104058]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [26 68] at positions [12 85]\n","truncated":false}}
%---
%[output:19cd8881]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR23_RUN07.xlsx\n","truncated":false}}
%---
%[output:5478998b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 31 53 76 95 82 28 4 86 9 37 71 63 96 80 68 45 57 43 47 92 39 26 67 27 33 6 16 19 87 56 21 32 24 42 20 75 11 62 58 12 72 48 10 15 64 51 90 74 29 85 3 22 59 73 14 89 52 35 54 23 1 77 83 84 46 78 70 49 2 36 81 30 94 8 50 65 38 41 55 93 40 69 91 25 34 17 13 66 7 18 61 5 44 88 79 60\n","truncated":false}}
%---
%[output:3d30479a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 60 78 64 43 91 68 25 61 20 24 37 44 12 82 41 65 90 29 86 85 54 62 15 5 59 87 7 26 16 39 21 72 3 76 75 36 52 77 51 38 80 30 2 27 94 40 92 1 49 8 46 35 58 22 70 34 28 19 53 81 95 57 55 6 9 73 69 13 93 71 88 31 33 11 50 42 79 10 89 14 23 56 83 48 96 17 74 18 84 66 45 32 4 47 63 67\n","truncated":false}}
%---
%[output:2403def5]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 6 7 9 16 18 19 20 27 29 30 32 38 39 40 47 53 54 57 58 65 71 73 76 77 79 80 81 89 91 93 96\n","truncated":false}}
%---
%[output:81c481bb]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 42 86 24 92 59 20 35 45 60 34 65 82 93 36 16 52 94 70 73 10 8 32 23 53 77 50 56 12 85 11 40 26 13 74 47 54 96 68 19 76 18 21 37 91 7 9 43 78 15 72 44 25 89 46 6 17 58 39 33 27 1 83 95 51 62 4 64 66 49 30 80 71 90 31 14 28 48 88 69 57 29 79 84 55 5 38 75 22 87 2 63 81 41 61 67 3\n","truncated":false}}
%---
%[output:47bddd8f]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR23_RUN08.xlsx\n","truncated":false}}
%---
%[output:60ea2d01]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 55 92 77 49 72 41 66 32 68 95 45 27 13 23 86 85 21 60 19 31 42 54 35 7 71 74 12 34 40 88 5 84 53 4 63 51 75 24 78 64 8 3 47 30 1 96 37 94 28 62 83 52 59 33 11 65 76 91 6 57 29 87 73 2 18 48 39 61 26 20 69 46 80 82 81 67 14 16 38 22 15 25 56 44 79 50 90 10 70 43 89 17 93 36 9 58\n","truncated":false}}
%---
%[output:5d8ab670]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [52 1] at positions [32 62]\n","truncated":false}}
%---
%[output:176f5ba7]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 94 86 1 85 65 16 36 76 51 10 63 33 23 27 2 26 83 47 53 73 43 96 31 57 30 79 82 56 55 91 69 17 39 11 77 70 44 38 64 59 89 5 7 25 81 22 49 12 66 95 34 84 93 54 19 41 32 15 35 13 92 68 6 9 52 46 75 80 18 20 67 50 78 28 87 14 60 88 48 42 21 45 72 37 3 90 24 71 8 40 61 4 29 62 74 58\n","truncated":false}}
%---
%[output:01c77c83]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 6 9 12 20 24 29 31 40 41 42 45 46 47 49 50 55 57 59 60 62 69 70 78 81 82 83 90 92 93 98\n","truncated":false}}
%---
%[output:8b264771]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 80 61 15 5 54 29 18 70 20 43 27 81 12 65 73 9 31 52 67 82 38 55 39 75 36 44 4 92 87 76 17 11 47 95 63 94 23 1 8 85 7 45 60 59 32 19 49 84 69 91 42 34 96 24 35 68 78 33 21 79 6 62 74 50 10 26 88 89 64 56 37 13 72 90 25 53 46 83 2 41 3 57 93 48 58 66 16 22 40 28 86 77 30 71 51 14\n","truncated":false}}
%---
%[output:7abeed04]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR24_RUN01.xlsx\n","truncated":false}}
%---
%[output:40b8f46d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 94 of 96\n\t\tAttempt 2 ran out of options at trial 95 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 24 57 58 90 91 41 38 10 89 60 6 17 37 94 4 59 76 85 70 63 40 29 96 28 2 12 74 77 27 71 7 36 65 47 61 18 20 66 14 95 84 50 45 43 88 32 16 79 30 81 80 72 55 78 34 73 93 5 46 11 56 53 83 33 52 13 1 25 31 42 21 64 22 87 3 75 51 19 15 82 48 49 92 62 39 8 44 68 9 23 54 67 35 86 69 26\n","truncated":false}}
%---
%[output:6b7d6fbc]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 94 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 15 42 44 3 70 92 52 71 59 24 80 72 17 95 83 76 13 53 14 4 26 43 94 40 32 28 61 96 12 86 21 10 87 49 45 62 54 51 73 34 77 39 8 6 31 79 56 82 84 74 89 46 65 22 1 64 9 35 50 18 41 90 11 66 7 30 20 57 38 48 29 91 19 88 68 75 23 36 69 16 60 25 2 78 85 27 63 67 33 5 93 37 81 55 47 58\n","truncated":false}}
%---
%[output:82824551]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 44 53 68 21 3 31 24 81 17 48 41 82 80 46 27 74 7 11 36 15 86 60 57 40 77 58 26 55 9 63 95 96 1 66 87 42 93 23 12 25 78 75 76 2 67 18 56 50 72 37 51 45 16 52 4 8 89 79 94 43 19 90 91 64 20 38 70 61 92 14 33 47 49 22 28 5 71 29 39 83 30 84 59 73 85 6 88 69 35 13 54 34 65 62 10 32\n","truncated":false}}
%---
%[output:322c8f82]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 3 4 5 7 8 22 23 25 33 37 41 42 47 48 59 60 61 65 68 73 76 77 82 84 87 90 92 94 97 98\n","truncated":false}}
%---
%[output:6dbca031]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR24_RUN02.xlsx\n","truncated":false}}
%---
%[output:63847d78]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [48 64] at positions [35 49]\n","truncated":false}}
%---
%[output:8eecbd17]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tAttempt 3 ran out of options at trial 96 of 96\n\t\tFound solution after 4 attempt(s): 89 21 74 28 34 44 68 14 91 5 20 53 57 15 80 41 58 96 50 17 92 76 66 56 65 84 45 26 31 11 39 7 16 51 33 81 90 8 24 29 55 49 83 82 22 79 36 9 87 71 69 2 38 60 47 94 48 42 73 52 23 6 13 54 3 72 19 37 32 88 64 67 93 12 63 4 75 1 35 95 25 10 30 46 77 40 59 43 27 86 62 18 70 61 85 78\n","truncated":false}}
%---
%[output:49f3c040]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tAttempt 2 ran out of options at trial 96 of 96\n\t\tFound solution after 3 attempt(s): 49 53 45 85 11 61 80 19 58 88 54 1 89 32 36 2 40 78 90 81 76 47 25 66 77 9 69 50 30 29 6 14 21 96 35 55 43 41 42 92 83 15 86 18 60 31 79 64 87 68 38 52 67 70 23 84 34 5 3 39 72 7 20 13 63 51 10 73 91 59 26 24 44 22 37 12 46 57 71 93 74 62 33 75 27 95 8 65 4 56 94 28 16 82 48 17\n","truncated":false}}
%---
%[output:48fa191b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 14 16 41 91 84 73 55 63 23 82 22 11 62 2 95 8 18 51 67 40 56 33 79 92 54 89 34 42 13 68 27 31 77 10 47 20 43 81 29 19 85 3 94 74 80 60 26 35 17 12 76 28 70 86 58 4 6 57 59 46 64 71 66 37 5 25 52 87 44 78 9 38 39 24 65 15 30 88 96 61 90 7 93 32 50 45 49 69 48 1 72 53 21 36 83 75\n","truncated":false}}
%---
%[output:02df48c3]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR24_RUN03.xlsx\n","truncated":false}}
%---
%[output:6d1c62f8]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 4 7 9 11 12 13 14 30 31 34 35 36 37 40 50 58 61 63 66 69 78 79 81 83 88 89 92 93 95 96\n","truncated":false}}
%---
%[output:6ee0c979]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 95 of 96\n\t\tFound solution after 2 attempt(s): 43 60 52 70 94 91 34 29 3 36 47 86 30 20 45 12 79 10 89 2 24 50 46 76 55 4 1 62 23 85 73 31 71 72 44 11 42 21 66 67 28 57 82 58 88 38 95 9 77 14 8 22 87 25 18 6 59 65 41 49 19 48 35 80 63 64 16 83 90 54 40 13 69 96 75 15 37 51 81 74 61 68 26 7 84 5 53 27 56 33 93 17 78 39 32 92\n","truncated":false}}
%---
%[output:8f24885f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [46 59] at positions [9 87]\n","truncated":false}}
%---
%[output:902c8878]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 37 35 62 82 16 22 80 55 75 24 86 46 89 83 61 26 41 1 96 78 42 66 85 25 2 44 30 56 4 14 72 71 13 49 40 63 51 5 6 68 36 81 60 88 79 28 29 32 94 15 93 18 69 57 52 31 48 47 23 53 70 95 45 73 10 54 39 11 33 27 7 20 77 65 92 90 12 91 19 50 43 64 3 17 84 74 59 67 9 58 21 34 8 76 38 87\n","truncated":false}}
%---
%[output:4462b4a8]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR24_RUN04.xlsx\n","truncated":false}}
%---
%[output:7176279e]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 59 91 94 27 18 7 76 84 40 96 78 47 67 79 57 23 33 42 64 52 13 11 85 1 43 24 50 35 3 56 69 29 66 10 28 82 61 30 44 75 87 62 58 81 5 72 74 37 26 88 71 2 21 20 63 77 22 70 54 45 60 8 90 17 14 4 36 83 93 48 16 53 38 41 15 65 34 86 6 25 49 12 51 95 19 46 55 68 31 89 80 92 39 32 73 9\n","truncated":false}}
%---
%[output:3b2b147d]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 5 6 11 12 14 15 26 27 29 30 33 44 45 49 54 56 59 67 69 70 74 75 80 81 82 89 91 93 95 97\n","truncated":false}}
%---
%[output:056262d8]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 19 59 15 66 60 35 18 90 36 87 54 77 3 81 25 16 26 69 70 38 1 45 50 55 30 24 41 72 82 2 8 53 86 76 31 92 95 28 9 42 44 63 93 46 74 13 23 65 29 17 34 91 57 61 7 84 80 64 40 47 14 49 75 79 48 21 51 27 37 96 83 6 11 73 89 71 32 78 94 43 10 58 22 52 39 68 62 5 20 85 12 33 56 67 4 88\n","truncated":false}}
%---
%[output:1a272362]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 84 28 37 92 52 19 75 47 30 63 77 65 10 38 8 25 83 71 21 17 16 49 50 41 46 66 89 44 51 90 2 15 91 85 81 53 13 68 62 43 4 7 96 42 31 58 72 11 22 9 76 23 48 95 67 87 3 64 6 33 56 60 20 70 55 82 27 86 1 24 18 35 36 79 69 39 5 93 34 59 29 73 57 12 61 45 26 88 54 94 80 40 74 14 78 32\n","truncated":false}}
%---
%[output:4e86f89b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR24_RUN05.xlsx\n","truncated":false}}
%---
%[output:3ef6c630]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [86 79] at positions [28 94]\n","truncated":false}}
%---
%[output:5826e72d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 66 25 19 2 14 83 74 41 30 73 6 28 92 56 61 42 89 46 12 54 82 93 13 79 77 59 16 48 67 87 23 57 69 96 39 47 51 26 45 95 90 58 53 78 71 55 10 27 34 52 24 88 72 35 65 15 40 1 60 43 17 3 7 84 31 18 76 32 64 86 4 75 37 33 68 5 85 8 62 80 29 36 81 38 20 9 70 50 91 22 49 21 94 63 44 11\n","truncated":false}}
%---
%[output:03b32715]
%   data: {"dataType":"text","outputData":{"text":"\t\tFound solution after 1 attempt(s): 2 23 25 43 80 55 73 40 91 5 69 10 95 29 15 36 30 57 16 52 42 4 1 90 72 87 81 33 64 63 31 94 58 84 46 39 59 13 19 68 21 32 82 88 51 78 67 77 3 75 17 35 7 14 47 89 70 34 38 71 60 45 28 76 85 8 54 49 92 26 12 37 18 50 20 79 62 83 66 86 11 65 27 61 22 93 48 53 44 6 96 56 74 9 24 41\n","truncated":false}}
%---
%[output:8dc1547d]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 10 11 14 16 19 21 29 30 31 34 36 39 46 48 53 56 59 61 62 65 71 73 79 80 83 84 85 86 88 98\n","truncated":false}}
%---
%[output:2c195628]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR24_RUN06.xlsx\n","truncated":false}}
%---
%[output:8daa754b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 96 of 96\n\t\tFound solution after 2 attempt(s): 32 68 9 28 3 6 39 27 35 94 55 18 31 82 33 74 70 62 44 58 16 90 81 11 64 89 71 42 40 14 65 87 26 59 53 67 20 43 96 52 23 7 49 66 76 46 15 79 4 34 24 61 10 22 85 88 5 93 36 80 29 77 86 72 54 60 48 51 95 30 19 8 12 45 38 83 78 37 75 84 41 56 92 63 47 13 57 17 69 21 91 25 50 2 73 1\n","truncated":false}}
%---
%[output:85d1303d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAttempt 1 ran out of options at trial 94 of 96\n\t\tAttempt 2 ran out of options at trial 93 of 96\n\t\tFound solution after 3 attempt(s): 76 60 55 36 65 90 63 88 78 4 92 40 41 83 82 26 32 39 62 11 8 30 7 72 47 31 64 67 75 18 70 3 56 27 95 2 46 1 57 42 45 49 80 20 37 68 94 52 61 86 23 69 58 19 22 5 6 89 15 29 54 14 73 44 13 33 91 87 43 28 85 66 71 53 74 16 17 51 38 59 25 34 24 84 77 21 12 81 9 35 10 50 93 48 79 96\n","truncated":false}}
%---
%[output:02be6799]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [64 59] at positions [24 96]\n","truncated":false}}
%---
%[output:793ecb67]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [47 12] at positions [44 93]\n","truncated":false}}
%---
%[output:7fbd3421]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR24_RUN07.xlsx\n","truncated":false}}
%---
%[output:7132d4c6]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 7 8 11 13 15 20 24 27 32 34 35 37 38 44 45 49 52 62 63 64 67 68 69 70 77 78 79 82 85 90 93 94\n","truncated":false}}
%---
%[output:4a15ff5d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [26 64] at positions [13 72]\n","truncated":false}}
%---
%[output:06891ac4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [34 29] at positions [20 53]\n","truncated":false}}
%---
%[output:1f397c4b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [15 23] at positions [39 70]\n","truncated":false}}
%---
%[output:722465be]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR24_RUN08.xlsx\n","truncated":false}}
%---
%[output:1e6289d6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [5 31] at positions [46 81]\n","truncated":false}}
%---
%[output:2850597f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 11 12 13 15 19 22 23 28 31 36 39 40 42 43 46 55 65 67 69 71 73 75 76 78 83 84 86 87 88 90 96\n","truncated":false}}
%---
%[output:99f3ea28]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [75 50] at positions [20 53]\n","truncated":false}}
%---
%[output:31342a51]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [44 25] at positions [33 92]\n","truncated":false}}
%---
%[output:3de7e736]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [58 6] at positions [31 49]\n","truncated":false}}
%---
%[output:78efbbbd]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR25_RUN01.xlsx\n","truncated":false}}
%---
%[output:9d770a67]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [9 59] at positions [4 91]\n","truncated":false}}
%---
%[output:741177f8]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 6 11 12 15 16 18 19 24 27 28 30 31 33 40 44 47 56 57 65 66 71 73 82 83 84 87 88 89 90 92 94 95\n","truncated":false}}
%---
%[output:764041e5]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [41 43] at positions [40 70]\n","truncated":false}}
%---
%[output:6a6994ff]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [73 12] at positions [45 89]\n","truncated":false}}
%---
%[output:0a833c33]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR25_RUN02.xlsx\n","truncated":false}}
%---
%[output:560aef4b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [62 5] at positions [3 63]\n","truncated":false}}
%---
%[output:7ebdac6d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [36 64] at positions [28 63]\n","truncated":false}}
%---
%[output:493ee00d]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 7 8 9 11 12 15 16 18 19 29 31 34 39 40 42 46 56 57 58 63 64 65 68 69 71 72 73 79 80 91 96 97\n","truncated":false}}
%---
%[output:4a6b616c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [20 75] at positions [35 81]\n","truncated":false}}
%---
%[output:8d4391fa]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR25_RUN03.xlsx\n","truncated":false}}
%---
%[output:55c4f47e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [88 86] at positions [14 95]\n","truncated":false}}
%---
%[output:021d9044]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [58 6] at positions [20 82]\n","truncated":false}}
%---
%[output:072bb2e4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [15 78] at positions [11 83]\n","truncated":false}}
%---
%[output:7fe77147]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 10 11 12 14 16 17 18 25 31 33 36 38 43 46 52 57 59 62 63 66 67 69 70 71 72 77 81 87 88 91\n","truncated":false}}
%---
%[output:93239c5e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR25_RUN04.xlsx\n","truncated":false}}
%---
%[output:26c4feaf]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [63 17] at positions [42 49]\n","truncated":false}}
%---
%[output:9f995116]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [91 4] at positions [26 81]\n","truncated":false}}
%---
%[output:89277687]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [89 54] at positions [13 62]\n","truncated":false}}
%---
%[output:77493602]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [92 71] at positions [40 55]\n","truncated":false}}
%---
%[output:0d2711eb]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR25_RUN05.xlsx\n","truncated":false}}
%---
%[output:99505fab]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 3 7 8 13 22 26 28 29 31 33 35 45 46 48 51 53 56 64 65 69 70 72 74 78 79 80 89 90 93 97\n","truncated":false}}
%---
%[output:39b7adb2]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [22 93] at positions [11 58]\n","truncated":false}}
%---
%[output:681d5ac8]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [66 44] at positions [21 91]\n","truncated":false}}
%---
%[output:6014f28b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [5 43] at positions [32 62]\n","truncated":false}}
%---
%[output:5873eab0]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR25_RUN06.xlsx\n","truncated":false}}
%---
%[output:29e03f78]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [87 58] at positions [32 83]\n","truncated":false}}
%---
%[output:395800dd]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 7 9 10 12 17 19 21 24 25 33 35 36 38 43 46 50 51 53 55 56 59 60 61 62 64 77 82 84 87 91 98\n","truncated":false}}
%---
%[output:6fa5cbe9]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [28 94] at positions [41 69]\n","truncated":false}}
%---
%[output:5b8c3b6b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [44 86] at positions [25 91]\n","truncated":false}}
%---
%[output:910a11b7]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR25_RUN07.xlsx\n","truncated":false}}
%---
%[output:8647131c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [44 20] at positions [24 89]\n","truncated":false}}
%---
%[output:6a057bf5]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [6 41] at positions [35 61]\n","truncated":false}}
%---
%[output:7936b521]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [14 69] at positions [37 52]\n","truncated":false}}
%---
%[output:6752f3dc]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 5 7 8 9 13 15 18 22 25 30 32 41 43 44 46 52 57 61 63 71 75 79 81 82 86 87 89 91 93 95 97\n","truncated":false}}
%---
%[output:2b92a7c1]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR25_RUN08.xlsx\n","truncated":false}}
%---
%[output:9daf1aab]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [7 11] at positions [3 68]\n","truncated":false}}
%---
%[output:311fd145]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [45 90] at positions [26 90]\n","truncated":false}}
%---
%[output:389c1b26]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [55 90] at positions [12 51]\n","truncated":false}}
%---
%[output:8ee5f399]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [68 78] at positions [35 95]\n","truncated":false}}
%---
%[output:68a63506]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 5 7 21 22 24 25 27 28 31 32 38 40 42 46 50 52 53 59 66 67 69 70 72 74 79 81 82 89 91 93\n","truncated":false}}
%---
%[output:7991edfd]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR26_RUN01.xlsx\n","truncated":false}}
%---
%[output:845efdd7]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [30 9] at positions [6 55]\n","truncated":false}}
%---
%[output:758235a3]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [75 57] at positions [40 76]\n","truncated":false}}
%---
%[output:20d967f8]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [83 87] at positions [27 60]\n","truncated":false}}
%---
%[output:0e75979d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [4 9] at positions [5 57]\n","truncated":false}}
%---
%[output:4f1c99ab]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR26_RUN02.xlsx\n","truncated":false}}
%---
%[output:55143ee2]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 5 7 14 16 18 19 22 25 27 29 32 39 42 44 48 51 53 55 57 64 72 73 75 76 79 82 87 89 92 94 95\n","truncated":false}}
%---
%[output:2f14c377]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [95 5] at positions [15 75]\n","truncated":false}}
%---
%[output:7fcecd28]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [13 93] at positions [24 60]\n","truncated":false}}
%---
%[output:5c85e160]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [86 76] at positions [37 58]\n","truncated":false}}
%---
%[output:832efceb]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR26_RUN03.xlsx\n","truncated":false}}
%---
%[output:3c5c19e0]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [4 95] at positions [39 71]\n","truncated":false}}
%---
%[output:0ef2614c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 6 7 20 23 26 28 29 30 32 34 35 38 41 44 45 48 50 55 61 66 67 68 70 75 76 77 78 86 90 92 93 97\n","truncated":false}}
%---
%[output:5d7808a1]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [30 62] at positions [37 69]\n","truncated":false}}
%---
%[output:0e6a64ad]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [65 63] at positions [24 84]\n","truncated":false}}
%---
%[output:753bb37e]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR26_RUN04.xlsx\n","truncated":false}}
%---
%[output:3ffc0c5b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [39 92] at positions [27 64]\n","truncated":false}}
%---
%[output:86e455b6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [29 78] at positions [7 86]\n","truncated":false}}
%---
%[output:743c1fad]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 7 8 11 13 16 19 20 22 25 26 27 31 35 46 52 57 58 60 62 64 66 67 70 73 80 81 83 90 91 92\n","truncated":false}}
%---
%[output:8ffbda3b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [36 42] at positions [16 57]\n","truncated":false}}
%---
%[output:7d57e632]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR26_RUN05.xlsx\n","truncated":false}}
%---
%[output:561df6c4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [87 96] at positions [19 86]\n","truncated":false}}
%---
%[output:6841a973]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [10 14] at positions [30 90]\n","truncated":false}}
%---
%[output:343f9b4b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [42 61] at positions [37 88]\n","truncated":false}}
%---
%[output:11a614a2]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 4 6 7 10 13 18 25 29 35 37 39 40 45 48 50 51 53 56 61 62 67 71 80 82 84 87 90 91 93 94\n","truncated":false}}
%---
%[output:318951ab]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR26_RUN06.xlsx\n","truncated":false}}
%---
%[output:1b866a9b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [48 36] at positions [21 50]\n","truncated":false}}
%---
%[output:8ad21da4]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [65 44] at positions [18 68]\n","truncated":false}}
%---
%[output:0418f2f3]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [16 49] at positions [25 94]\n","truncated":false}}
%---
%[output:5da2e3dc]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [87 66] at positions [48 82]\n","truncated":false}}
%---
%[output:51d4a118]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR26_RUN07.xlsx\n","truncated":false}}
%---
%[output:0538cc5f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 5 7 9 10 11 12 18 20 22 23 26 37 41 49 51 52 53 58 61 63 64 67 69 74 76 77 81 87 90 94\n","truncated":false}}
%---
%[output:86c0b5c8]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [8 2] at positions [48 54]\n","truncated":false}}
%---
%[output:8c7fe4d2]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [88 86] at positions [32 79]\n","truncated":false}}
%---
%[output:217f1101]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [24 96] at positions [11 88]\n","truncated":false}}
%---
%[output:2580abec]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR26_RUN08.xlsx\n","truncated":false}}
%---
%[output:509e0579]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [91 44] at positions [14 76]\n","truncated":false}}
%---
%[output:1d72fc5c]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 5 7 11 12 13 18 19 24 26 30 33 38 40 42 51 55 56 58 60 63 64 69 71 72 77 78 82 85 88 94\n","truncated":false}}
%---
%[output:6307f7d0]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [31 76] at positions [13 94]\n","truncated":false}}
%---
%[output:9c3115c3]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [88 17] at positions [3 69]\n","truncated":false}}
%---
%[output:7350c65b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [69 13] at positions [38 71]\n","truncated":false}}
%---
%[output:8871d75a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR27_RUN01.xlsx\n","truncated":false}}
%---
%[output:0a08da8a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [46 42] at positions [5 76]\n","truncated":false}}
%---
%[output:7ee49f49]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [72 37] at positions [25 96]\n","truncated":false}}
%---
%[output:29aa52f2]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 10 11 14 24 26 27 28 30 32 33 36 38 44 47 54 55 58 60 61 62 68 70 73 80 85 87 92 95 97 98\n","truncated":false}}
%---
%[output:97b56e26]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [33 64] at positions [34 64]\n","truncated":false}}
%---
%[output:3430346a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR27_RUN02.xlsx\n","truncated":false}}
%---
%[output:5eb77b80]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [15 12] at positions [30 96]\n","truncated":false}}
%---
%[output:8b394255]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [77 64] at positions [35 67]\n","truncated":false}}
%---
%[output:61800af2]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [1 31] at positions [26 86]\n","truncated":false}}
%---
%[output:563aad98]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 7 15 21 22 26 28 30 31 39 40 41 44 47 48 52 54 55 56 59 66 67 68 72 74 75 76 79 85 90 92\n","truncated":false}}
%---
%[output:078b84c4]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR27_RUN03.xlsx\n","truncated":false}}
%---
%[output:987744e6]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [6 30] at positions [24 59]\n","truncated":false}}
%---
%[output:05ebe822]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [33 1] at positions [48 94]\n","truncated":false}}
%---
%[output:7f87ff25]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [22 54] at positions [26 87]\n","truncated":false}}
%---
%[output:9f1291cd]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [35 46] at positions [4 64]\n","truncated":false}}
%---
%[output:3cc270aa]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR27_RUN04.xlsx\n","truncated":false}}
%---
%[output:8851b8af]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 9 12 13 19 20 21 27 29 30 32 34 37 38 42 45 47 53 54 55 66 72 77 78 79 80 91 92 93 94 96 97 98\n","truncated":false}}
%---
%[output:99c59933]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [54 90] at positions [13 70]\n","truncated":false}}
%---
%[output:7658282e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [83 94] at positions [7 51]\n","truncated":false}}
%---
%[output:169c65b5]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [73 75] at positions [16 80]\n","truncated":false}}
%---
%[output:49a6b6cc]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR27_RUN05.xlsx\n","truncated":false}}
%---
%[output:74a685af]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [39 34] at positions [2 50]\n","truncated":false}}
%---
%[output:7ede8201]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 8 11 12 15 17 22 24 25 31 32 36 37 38 42 47 52 54 58 70 71 73 74 77 78 80 81 85 86 88 89 97\n","truncated":false}}
%---
%[output:71524949]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [71 22] at positions [47 74]\n","truncated":false}}
%---
%[output:3e725bea]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [24 39] at positions [36 66]\n","truncated":false}}
%---
%[output:8a43e691]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR27_RUN06.xlsx\n","truncated":false}}
%---
%[output:82797f4f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [93 13] at positions [18 76]\n","truncated":false}}
%---
%[output:0f4484bd]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [65 63] at positions [32 49]\n","truncated":false}}
%---
%[output:3953c9ca]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 10 12 14 18 20 24 25 26 27 33 37 38 39 46 48 51 52 53 55 57 58 62 69 75 77 81 83 84 87 90 97\n","truncated":false}}
%---
%[output:7a935446]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [66 4] at positions [44 75]\n","truncated":false}}
%---
%[output:95bc4e11]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR27_RUN07.xlsx\n","truncated":false}}
%---
%[output:5251acc7]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [17 86] at positions [36 90]\n","truncated":false}}
%---
%[output:2f2187cd]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [2 49] at positions [44 49]\n","truncated":false}}
%---
%[output:48dd5fd0]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [51 56] at positions [6 52]\n","truncated":false}}
%---
%[output:4a9ae3f8]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 6 7 8 15 16 17 18 19 21 22 23 27 35 42 49 53 57 58 61 66 72 74 75 77 85 86 88 90 95 97 98\n","truncated":false}}
%---
%[output:609a27ea]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR27_RUN08.xlsx\n","truncated":false}}
%---
%[output:30fb632e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [10 35] at positions [27 68]\n","truncated":false}}
%---
%[output:4958625a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [74 20] at positions [27 79]\n","truncated":false}}
%---
%[output:9bfef1dd]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [89 43] at positions [22 62]\n","truncated":false}}
%---
%[output:47ffe59d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [33 68] at positions [4 56]\n","truncated":false}}
%---
%[output:37bbc835]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 6 16 18 19 20 21 22 23 30 33 39 40 43 44 47 53 56 59 60 61 62 65 67 68 77 80 85 90 91 96 98\n","truncated":false}}
%---
%[output:0babb007]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR28_RUN01.xlsx\n","truncated":false}}
%---
%[output:5d179576]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [2 25] at positions [6 90]\n","truncated":false}}
%---
%[output:4e337ea0]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [78 44] at positions [37 92]\n","truncated":false}}
%---
%[output:700ef14b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [17 13] at positions [17 83]\n","truncated":false}}
%---
%[output:4b401f57]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [55 5] at positions [23 84]\n","truncated":false}}
%---
%[output:6ba71993]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR28_RUN02.xlsx\n","truncated":false}}
%---
%[output:4f080534]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 9 13 14 15 16 18 22 26 32 33 38 42 43 48 56 57 62 70 71 75 76 83 84 85 87 88 90 93 94 97\n","truncated":false}}
%---
%[output:6e9687c3]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [28 23] at positions [35 59]\n","truncated":false}}
%---
%[output:98a3b4cf]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [76 74] at positions [31 86]\n","truncated":false}}
%---
%[output:39a2366d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [11 19] at positions [45 52]\n","truncated":false}}
%---
%[output:23cf31a0]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR28_RUN03.xlsx\n","truncated":false}}
%---
%[output:4dde631d]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [84 77] at positions [28 87]\n","truncated":false}}
%---
%[output:66626815]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [37 40] at positions [10 81]\n","truncated":false}}
%---
%[output:4d0f8757]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 10 12 14 16 18 19 25 31 35 39 43 44 47 48 50 52 63 66 69 71 73 74 75 79 83 90 94 95 96 97\n","truncated":false}}
%---
%[output:3f2fc30b]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [77 83] at positions [38 83]\n","truncated":false}}
%---
%[output:104b882f]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR28_RUN04.xlsx\n","truncated":false}}
%---
%[output:0f06c21e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [92 57] at positions [4 80]\n","truncated":false}}
%---
%[output:455fc904]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [31 93] at positions [20 93]\n","truncated":false}}
%---
%[output:3d6d135e]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [1 92] at positions [3 61]\n","truncated":false}}
%---
%[output:4d793569]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 9 11 15 18 21 22 28 33 34 38 41 44 45 46 48 52 54 55 59 68 70 75 76 79 80 81 83 87 93 97 98\n","truncated":false}}
%---
%[output:3a7f41a3]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR28_RUN05.xlsx\n","truncated":false}}
%---
%[output:33fd0221]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [52 57] at positions [18 82]\n","truncated":false}}
%---
%[output:9dee2582]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [77 80] at positions [28 51]\n","truncated":false}}
%---
%[output:03c3340a]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [62 18] at positions [36 60]\n","truncated":false}}
%---
%[output:8badb5ab]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [23 28] at positions [38 75]\n","truncated":false}}
%---
%[output:2ca433a1]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR28_RUN06.xlsx\n","truncated":false}}
%---
%[output:736e3031]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 3 4 5 7 10 15 17 24 25 34 38 40 45 47 52 53 54 56 61 63 66 69 78 80 84 85 86 92 95 97\n","truncated":false}}
%---
%[output:9bb51d90]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [49 43] at positions [42 88]\n","truncated":false}}
%---
%[output:52608acb]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [80 5] at positions [7 58]\n","truncated":false}}
%---
%[output:282bdefc]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [60 1] at positions [46 90]\n","truncated":false}}
%---
%[output:4d0d4d08]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR28_RUN07.xlsx\n","truncated":false}}
%---
%[output:451f9871]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [85 33] at positions [30 90]\n","truncated":false}}
%---
%[output:73dff5f6]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 5 8 15 16 17 21 25 27 33 34 35 43 45 46 53 54 56 57 59 70 71 75 79 82 85 88 92 93 95 96\n","truncated":false}}
%---
%[output:4bcf7f95]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [46 64] at positions [12 82]\n","truncated":false}}
%---
%[output:777183c5]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [61 31] at positions [37 89]\n","truncated":false}}
%---
%[output:7e4f8f49]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR28_RUN08.xlsx\n","truncated":false}}
%---
%[output:56f16443]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [74 58] at positions [45 82]\n","truncated":false}}
%---
%[output:7d38b205]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [30 24] at positions [9 70]\n","truncated":false}}
%---
%[output:3c6abeee]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 7 13 15 21 22 25 27 30 32 33 36 40 41 45 47 48 53 55 57 63 64 73 76 77 79 86 88 90 92 93 95 98\n","truncated":false}}
%---
%[output:578f397f]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [26 37] at positions [38 73]\n","truncated":false}}
%---
%[output:950983c2]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [91 35] at positions [9 52]\n","truncated":false}}
%---
%[output:17cea30a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR29_RUN01.xlsx\n","truncated":false}}
%---
%[output:16d3355c]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [20 29] at positions [37 61]\n","truncated":false}}
%---
%[output:0590dd82]
%   data: {"dataType":"text","outputData":{"text":"\t\tAdding one-backs to trial IDs [83 86] at positions [14 50]\n","truncated":false}}
%---
%[output:2329de2f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 8 9 10 11 13 18 20 23 24 25 29 36 42 47 48 52 53 59 62 66 71 72 78 83 85 86 90 92 93 95 98\n","truncated":false}}
%---
%[output:4fa711e2]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 7 12 15 16 17 20 27 30 31 32 40 41 46 48 50 51 60 62 66 69 71 76 77 78 80 83 84 94 96 97\n","truncated":false}}
%---
%[output:047d8796]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR29_RUN02.xlsx\n","truncated":false}}
%---
%[output:4f1fc43f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 7 11 14 15 17 20 21 22 24 26 30 34 39 45 47 49 59 65 67 68 70 74 77 79 80 81 88 89 90 91 96 98\n","truncated":false}}
%---
%[output:78ba2692]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 6 9 13 14 19 23 25 26 30 31 33 34 35 39 48 53 58 61 62 65 67 68 70 78 80 82 84 85 90 91 95\n","truncated":false}}
%---
%[output:6d515bcd]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 6 12 17 18 24 25 27 29 30 33 34 35 43 49 50 51 55 57 62 63 65 66 69 78 80 81 86 89 90 98\n","truncated":false}}
%---
%[output:61bdc661]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 8 13 14 17 18 22 23 27 29 33 35 36 37 41 42 46 58 61 62 63 66 67 70 71 75 78 81 87 88 90 93 94\n","truncated":false}}
%---
%[output:7b1e908a]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR29_RUN03.xlsx\n","truncated":false}}
%---
%[output:82c9a328]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 6 8 9 15 16 20 25 27 28 29 32 37 43 44 46 62 64 69 71 73 74 75 82 84 85 86 87 92 95 96 98\n","truncated":false}}
%---
%[output:1c350f04]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 9 11 12 14 16 17 19 20 22 26 28 36 44 45 49 50 55 65 66 69 70 79 80 83 84 86 88 91 93 96 97\n","truncated":false}}
%---
%[output:27c83d0a]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 5 6 12 16 17 19 20 24 26 28 36 40 44 48 58 59 60 65 66 69 71 72 73 74 76 78 82 87 88 93\n","truncated":false}}
%---
%[output:08ec14d7]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 7 13 15 17 18 20 25 26 28 30 34 36 41 49 51 52 57 60 61 64 65 74 75 81 84 85 87 90 91 94\n","truncated":false}}
%---
%[output:8ef81b87]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR29_RUN04.xlsx\n","truncated":false}}
%---
%[output:510848bd]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 6 7 8 9 19 20 21 22 24 25 27 30 42 45 52 53 56 62 67 71 77 78 80 81 84 85 87 88 89 91\n","truncated":false}}
%---
%[output:019d5209]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 9 12 15 21 22 24 26 30 32 33 34 36 39 40 44 46 56 57 58 64 66 69 70 76 79 83 85 86 88 95 97 98\n","truncated":false}}
%---
%[output:15736e66]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 6 9 13 20 21 23 28 30 34 38 41 42 45 46 47 50 55 58 61 63 65 66 68 74 83 86 87 90 91 93 97\n","truncated":false}}
%---
%[output:2c1086b4]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 7 8 10 11 21 23 26 31 36 37 38 40 41 42 53 59 63 66 67 68 72 73 74 75 76 83 87 90 91 97\n","truncated":false}}
%---
%[output:9cffda04]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR29_RUN05.xlsx\n","truncated":false}}
%---
%[output:64e636ca]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 4 6 12 13 19 20 28 30 34 37 41 42 43 44 52 55 56 57 59 60 64 65 72 74 77 82 85 86 92 97\n","truncated":false}}
%---
%[output:023ef480]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 5 8 10 15 18 19 20 23 24 29 36 41 45 47 49 51 52 54 55 56 57 60 64 66 71 72 73 77 80 89 91\n","truncated":false}}
%---
%[output:4b3fad25]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 5 6 19 22 24 28 31 34 35 37 38 39 40 46 50 52 53 56 57 60 65 70 74 76 77 78 85 87 92 97\n","truncated":false}}
%---
%[output:6dce8a41]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 7 10 13 14 16 18 19 24 34 35 42 43 44 45 47 53 54 60 61 62 63 69 71 72 77 78 85 90 93 96 97\n","truncated":false}}
%---
%[output:42c9659d]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR29_RUN06.xlsx\n","truncated":false}}
%---
%[output:73f03dd0]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 5 6 7 12 14 17 24 27 35 36 39 43 46 47 51 55 60 61 62 63 67 70 74 80 83 85 87 91 92 97\n","truncated":false}}
%---
%[output:44b8601d]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 6 8 10 16 17 26 27 28 30 32 33 36 37 40 47 49 50 54 56 58 59 60 63 64 68 77 79 83 84 85 86 90\n","truncated":false}}
%---
%[output:8964defe]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 6 7 12 14 17 18 20 21 22 24 28 33 35 46 54 59 60 61 68 71 72 73 78 82 83 87 89 92 93 96\n","truncated":false}}
%---
%[output:90994214]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 4 6 16 21 23 26 31 33 34 39 40 43 45 49 52 55 56 59 60 63 67 75 78 83 85 86 90 94 96 97\n","truncated":false}}
%---
%[output:284c9327]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR29_RUN07.xlsx\n","truncated":false}}
%---
%[output:825e00df]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 5 15 16 19 22 23 30 34 35 37 39 41 44 48 49 57 59 61 68 69 70 74 78 79 81 83 85 88 93 94 95\n","truncated":false}}
%---
%[output:455b6380]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 6 8 10 13 19 21 24 27 30 38 42 45 46 47 49 51 53 54 57 59 63 76 80 84 85 88 91 93 94 96 98\n","truncated":false}}
%---
%[output:53250244]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 8 13 14 17 21 22 26 30 31 32 36 37 44 47 49 53 56 59 63 68 72 77 79 80 81 87 89 90 94 96 98\n","truncated":false}}
%---
%[output:01070f80]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 7 9 10 11 12 13 15 17 19 24 37 38 41 42 50 52 57 58 61 62 65 68 75 79 82 87 92 93 94 96\n","truncated":false}}
%---
%[output:02827273]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR29_RUN08.xlsx\n","truncated":false}}
%---
%[output:00355052]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 8 9 15 17 22 23 25 27 30 33 34 38 39 45 61 64 67 69 70 72 73 74 80 82 83 84 86 88 89 93\n","truncated":false}}
%---
%[output:65da2a7d]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 3 6 8 9 11 13 19 24 25 27 28 29 37 39 40 51 53 54 55 60 67 74 77 79 80 83 86 87 89 93 94\n","truncated":false}}
%---
%[output:212ede18]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 3 13 14 15 16 17 23 26 31 33 34 40 45 49 56 58 60 62 68 69 73 74 75 78 79 91 94 95 96 98\n","truncated":false}}
%---
%[output:108c2927]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 5 9 14 15 19 22 25 26 31 34 36 37 38 39 42 50 53 55 56 57 58 59 67 71 72 76 83 86 90 95 97\n","truncated":false}}
%---
%[output:4ae3d9b3]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 8 14 15 16 20 21 30 36 37 40 42 43 44 47 49 51 53 55 56 57 61 67 69 70 71 77 81 84 85 91 94\n","truncated":false}}
%---
%[output:41b917dd]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR30_RUN01.xlsx\n","truncated":false}}
%---
%[output:4c956ef0]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 10 12 19 20 24 25 28 29 33 35 37 39 40 42 46 54 55 56 59 62 63 66 77 78 80 84 86 87 88 94 98\n","truncated":false}}
%---
%[output:8e18b6ac]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 5 7 16 18 23 25 29 31 36 38 46 47 48 49 57 64 65 66 70 78 85 87 89 90 91 92 93 94 96 97\n","truncated":false}}
%---
%[output:432b34e4]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 5 9 10 12 16 18 20 22 23 27 28 31 44 46 55 57 60 68 73 74 76 82 83 84 86 87 88 90 91 96\n","truncated":false}}
%---
%[output:09ee1325]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 7 10 12 14 15 24 28 32 33 35 36 37 44 48 49 50 55 58 62 63 64 72 77 78 79 81 87 90 96 97 98\n","truncated":false}}
%---
%[output:4c5539bf]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR30_RUN02.xlsx\n","truncated":false}}
%---
%[output:07dcc844]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 8 12 13 15 19 23 27 30 31 35 36 39 43 45 46 49 51 56 57 60 63 64 67 76 77 79 81 82 84 85 89 92\n","truncated":false}}
%---
%[output:45a7256b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 6 13 14 16 17 19 25 26 27 28 35 37 39 45 46 50 51 56 62 63 69 71 73 77 78 80 83 86 88 91 98\n","truncated":false}}
%---
%[output:1bf42c8f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 10 12 13 15 16 20 21 24 28 30 32 38 47 49 50 53 54 58 61 62 63 67 68 79 80 82 91 95 96 97\n","truncated":false}}
%---
%[output:89cfc7b7]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 6 11 13 14 15 22 30 33 34 35 39 44 45 47 49 51 55 56 60 64 67 73 75 82 83 87 88 89 90 93 96\n","truncated":false}}
%---
%[output:0aedf9ab]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR30_RUN03.xlsx\n","truncated":false}}
%---
%[output:8214d577]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 5 7 8 10 19 25 26 27 29 31 32 33 35 38 40 41 50 51 52 53 59 70 75 78 81 86 90 91 93 95 97 98\n","truncated":false}}
%---
%[output:0f3696c3]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 5 6 7 10 11 18 19 20 23 26 31 32 40 42 43 55 56 59 65 67 70 71 76 77 79 80 88 89 91 96 98\n","truncated":false}}
%---
%[output:40f65152]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 3 12 17 31 32 33 35 36 37 41 43 44 45 49 52 55 58 67 68 70 71 73 74 77 82 83 86 89 97 98\n","truncated":false}}
%---
%[output:0be0f01d]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 6 7 8 9 10 11 14 17 28 29 30 37 46 47 50 51 52 53 55 57 59 60 71 74 78 82 83 85 91 95\n","truncated":false}}
%---
%[output:1136eaa8]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR30_RUN04.xlsx\n","truncated":false}}
%---
%[output:42ae261b]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 6 8 9 11 12 18 27 30 31 37 40 42 43 46 50 51 53 54 55 58 59 65 66 70 73 79 83 86 94 96\n","truncated":false}}
%---
%[output:939528c9]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 6 7 9 12 13 19 20 28 29 35 37 38 39 46 53 54 55 56 59 67 71 74 75 80 82 84 89 92 96 97\n","truncated":false}}
%---
%[output:99ad001d]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 4 7 8 9 12 18 20 24 31 32 34 35 43 48 49 52 55 64 66 67 69 71 73 74 76 79 82 86 90 93 96\n","truncated":false}}
%---
%[output:0082a0b2]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 5 6 8 9 18 23 26 28 32 33 34 36 37 39 43 52 56 63 66 72 73 79 80 81 85 88 89 92 94 95 98\n","truncated":false}}
%---
%[output:9faf9c0b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR30_RUN05.xlsx\n","truncated":false}}
%---
%[output:5698cf30]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 7 9 12 14 15 18 25 28 29 30 32 34 36 46 49 58 59 63 69 70 71 76 77 78 81 85 86 88 89 91 96\n","truncated":false}}
%---
%[output:0bc05339]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 3 4 6 8 10 14 15 18 21 27 30 31 38 40 44 49 50 55 60 62 63 69 70 73 79 80 81 84 89 90 95 98\n","truncated":false}}
%---
%[output:8ee8bbff]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 9 10 14 15 16 19 20 24 27 32 34 36 38 40 41 47 54 56 61 63 64 65 66 68 70 71 78 80 81 88 89 92\n","truncated":false}}
%---
%[output:9a46f998]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 6 10 11 16 18 20 27 29 30 31 34 35 39 43 45 50 52 54 55 56 58 65 67 75 78 83 89 90 92 96 97\n","truncated":false}}
%---
%[output:771bbd3f]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR30_RUN06.xlsx\n","truncated":false}}
%---
%[output:7e3d9392]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 3 4 5 6 10 24 26 27 29 34 37 39 41 45 46 53 54 55 59 64 70 72 73 75 77 80 81 87 89 92 96\n","truncated":false}}
%---
%[output:50108132]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 4 5 6 11 12 13 15 20 21 22 27 28 36 39 46 48 54 64 65 68 69 71 77 80 82 84 85 86 87 89 92 98\n","truncated":false}}
%---
%[output:8f116c45]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 10 13 17 18 19 20 22 27 28 30 35 37 38 42 43 45 52 53 57 59 66 69 73 76 79 80 82 83 84 85 86 90\n","truncated":false}}
%---
%[output:36ab1ad7]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 2 4 11 18 21 22 23 24 25 26 31 36 42 43 48 51 52 53 54 56 60 62 64 66 75 77 78 88 89 95 98\n","truncated":false}}
%---
%[output:715f5989]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR30_RUN07.xlsx\n","truncated":false}}
%---
%[output:1df62069]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 11 14 15 16 21 23 24 26 29 30 31 32 33 34 39 40 50 53 54 61 63 64 66 68 76 77 78 81 83 91 92 96\n","truncated":false}}
%---
%[output:4e89f3e0]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 9 13 14 17 20 27 32 33 36 38 39 40 43 44 48 49 50 53 58 62 63 65 73 77 79 81 86 87 90 91 95 98\n","truncated":false}}
%---
%[output:9d703f1f]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 2 7 14 16 17 22 24 29 34 35 38 40 41 42 43 44 51 56 57 60 63 66 69 76 84 88 90 91 93 94 96 98\n","truncated":false}}
%---
%[output:9c2f18c4]
%   data: {"dataType":"text","outputData":{"text":"\t\t32 long ITIs in trials: 1 4 5 7 9 12 16 20 24 33 34 38 44 47 48 49 50 52 56 57 60 61 62 63 67 72 74 81 88 93 96 98\n","truncated":false}}
%---
%[output:91188e3b]
%   data: {"dataType":"text","outputData":{"text":"\t\tWriting: ..\\Orders\\PAR30_RUN08.xlsx\n","truncated":false}}
%---
