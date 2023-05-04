function select_rank_for_config(config_id, design_id, scratch_root)

    % get config, then unpack
    config = yaml.loadFile( ...
        fullfile('simulation', 'data', design_id, config_id, 'config.yml') ...
    );
    M = config.settings.M;
    K_max = config.tuning.K_max;
    delta = config.settings.delta_est;
    num_reps = config.settings.num_reps_rank;
    alphas = cell2mat(config.tuning.selections.rank_sim.alphas);

    % create A and R
    [A, A_mat] = create_band_deletion_array(M, M, delta);
    [R, R_mat] = create_difference_array(M, M);

    % create rank selection table
    col_names = {'rep', 'K', 'fit'};
    data_rank_select = array2table(zeros(0, length(col_names)));
    data_rank_select.Properties.VariableNames = col_names;

    for rep = 1:num_reps

        % read in Chat
        C_hat_file = fullfile( ...
            scratch_root, config.dirs.data, ...  % pull from scratch root
            format_matrix_filename('Chat', '.csv.gz', nan, rep) ...
            );
        C_hat_mat = read_zipped_matrix_file(C_hat_file);
        C_hat = reshape(C_hat_mat, M, M, M, M);
        
        fits = zeros(K_max, 1);
        for K = 1:K_max

            % estimate rank-K L
            [~, L_hat_mat, ~, ~] = array_completion(C_hat, K, delta, alphas(rep), A, R);

            % compute fit and store
%             fits(K) = norm( ...
%                 A_mat.*(L_hat_mat*L_hat_mat' ...
%                 - C_hat_mat), 'fro') ... 
%                 / norm(A_mat.*C_hat_mat, 'fro');
            [fit, ~] = penalized_objective(L_hat_mat, C_hat_mat, A_mat, R_mat, alphas(rep));
            fits(K) = fit;
                
        end

        % save data
        reps = rep*ones(K_max, 1);
        Ks = (1:K_max)';
        temp = array2table([reps, Ks, fits], 'VariableNames', col_names);
        data_rank_select = [data_rank_select; temp];

    end

    % write rank selection table
    writetable(data_rank_select, fullfile(config.dirs.results, 'data_rank_select.csv'));

end