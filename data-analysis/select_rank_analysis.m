function select_rank_analysis(analysis_id, time, K_max) 

    % get analysis, then unpack
    analysis = yaml.loadFile(fullfile( ...
        'data-analysis', 'analyses', sprintf('%s.yml', analysis_id)));
    scratch_root = analysis.scratch_root;
    dir_data = analysis.dirs.data;
    dir_results = analysis.dirs.results;
    M1 = analysis.settings.M1;
    M2 = analysis.settings.M2;
    delta = analysis.settings.delta;
    alphas = cell2mat(analysis.settings.alphas.(genvarname(sprintf('time_%d', time))));

    % create A and R
    [A, A_mat] = create_band_deletion_array(M1, M2, delta);
    [R, ~] = create_difference_array(M1, M2);

    % get C_hat
    C_hat_file = fullfile( ...
        scratch_root, dir_data, ... 
        format_matrix_filename_analysis('Chat', '.csv.gz', time) ...
        );
    C_hat_mat = read_zipped_matrix_file(C_hat_file);
    C_hat = reshape(C_hat_mat, M1, M2, M1, M2);

    fits = zeros(K_max, 1);
    for j = 1:K_max

        [~, L_hat_mat, ~, ~] = array_completion(C_hat, j, delta, alphas(1:j), A, R);
        
        % compute fit and store
        fits(j) = norm( ...
            A_mat.*(L_hat_mat*L_hat_mat' ...
            - C_hat_mat), 'fro') ... 
            / norm(A_mat.*C_hat_mat, 'fro');

    end

    % save data
    col_names = {'K', 'fit'};
    Ks = (1:K_max)';
    data_rank_select = array2table([Ks, fits], 'VariableNames', col_names);

    % write rank selection table
    writetable(data_rank_select, fullfile(dir_results, sprintf('data_rank_select_time-%d.csv', time)));

end