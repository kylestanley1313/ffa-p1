function estimate_L_analysis(analysis_id, time, L_name) 

    % get analysis, then unpack
    analysis = yaml.loadFile(fullfile( ...
        'data-analysis', 'analyses', sprintf('%s.yml', analysis_id)));
    scratch_root = analysis.scratch_root;
    dir_data = analysis.dirs.data;
    M1 = analysis.settings.M1;
    M2 = analysis.settings.M2;
    K = analysis.settings.K;
    delta = analysis.settings.delta;
    alphas = cell2mat(analysis.settings.alphas.(genvarname(sprintf('time_%d', time))));

    % get C_hat
    C_hat_file = fullfile( ...
        scratch_root, dir_data, ... 
        format_matrix_filename_analysis('Chat', '.csv.gz', time) ...
        );
    C_hat = read_zipped_matrix_file(C_hat_file);
    C_hat = reshape(C_hat, M1, M2, M1, M2);

    % estimate L
    [~, L_hat_mat, ~, ~] = array_completion(C_hat, K, delta, alphas);

    % write L_hat_mat
    write_zipped_matrix_file( ...
        L_hat_mat, ...
        fullfile( ...
            analysis.dirs.data, ...
            format_matrix_filename_analysis(L_name, '.csv', time) ...
            ) ...
        );

end