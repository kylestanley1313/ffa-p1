function estimate_L_for_config(config_id, design_id, band, smooth, n_facs_override, scratch_root) 
    % get config, then unpack
    config = yaml.loadFile( ...
        fullfile('simulation', 'data', design_id, config_id, 'config.yml') ...
    );
    M = config.settings.M;
    num_reps = config.settings.num_reps;
    if isnan(n_facs_override)
        K = config.settings.K;
    else
        K = n_facs_override;
    if band
        delta = config.settings.delta_est;
    else
        delta = 0;
    end
    if smooth
        if iscell(config.tuning.selections.comp_sim.alphas)
            alphas = cell2mat(config.tuning.selections.comp_sim.alphas);
        else
            alphas = config.tuning.selections.comp_sim.alphas;
        end
    else
        alphas = zeros(1, num_reps);
    end
    if band && smooth
        method = 'dps';
    elseif band && ~smooth
        method = 'dp';
    elseif ~band && ~smooth
        method = 'mvfa';
    elseif ~band && smooth
        method = 'other';
    end

    for rep = 1:num_reps

        % get C_hat
        C_hat_file = fullfile( ...
            scratch_root, config.dirs.data, ...  % pull from scratch root
            format_matrix_filename('Chat', '.csv.gz', nan, rep) ...
            );
        C_hat = read_zipped_matrix_file(C_hat_file);
        C_hat = reshape(C_hat, M, M, M, M);

        % estimate L
        [~, L_hat_mat, ~, ~] = array_completion(C_hat, K, delta, alphas(rep));

        % write L_hat_mat
        write_zipped_matrix_file( ...
            L_hat_mat, ...
            fullfile( ...
                config.dirs.data, ...
                format_matrix_filename('Lhat', '.csv', method, rep) ...
                ) ...
            );

    end
end