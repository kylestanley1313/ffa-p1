function estimate_L_analysis(analysis_id, L_name, alphas, v, split) 
    arguments
        analysis_id
        L_name
        alphas = nan
        v = nan
        split = nan
    end

    % get analysis, then unpack
    analysis = yaml.loadFile(fullfile( ...
        'data-analysis', 'analyses', sprintf('%s.yml', analysis_id)));
    scratch_root = analysis.scratch_root;
    dir_data = analysis.dirs.data;
    M1 = analysis.settings.M1;
    M2 = analysis.settings.M2;
    K = analysis.settings.ffa.K;
    delta = analysis.settings.ffa.delta;
    if isnan(alphas)
        alphas = analysis.settings.ffa.alpha;
    end

    % get C_hat
    C_hat_file = fullfile( ...
        scratch_root, dir_data, ... 
        format_matrix_filename_analysis('Chat', '.csv.gz', nan, nan, v, split) ...
        );
    C_hat = read_zipped_matrix_file(C_hat_file);
    C_hat = reshape(C_hat, M1, M2, M1, M2);

    for alpha = alphas

        % estimate L
        [~, L_hat_mat, ~, ~] = array_completion(C_hat, K, delta, alpha);

        % write L_hat_mat
        write_zipped_matrix_file( ...
            L_hat_mat, ...
            fullfile( ...
                dir_data, ...
                format_matrix_filename_analysis(L_name, '.csv', K, alpha, v, split) ...
                ) ...
            );

    end

end