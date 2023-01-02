function estimate_L_for_config(config_id , design_id, scratch_root) 
    % get config, then unpack
    config = yaml.loadFile( ...
        fullfile('simulation', 'data', design_id, config_id, 'config.yml') ...
    );
    M = config.settings.M;
    K = config.settings.K;
    delta = config.settings.delta;
    alphas = cell2mat(config.tuning.selections.alphas);
    num_reps = config.settings.num_reps;

    for rep = 1:num_reps

        % get C_hat
        C_hat_file = fullfile( ...
            scratch_root, config.dirs.data, ...  % pull from scratch root
            format_matrix_filename('Chat', '.csv.gz', rep) ...
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
                format_matrix_filename('Lhatsm', '.csv', rep) ...
                ) ...
            );

    end
end