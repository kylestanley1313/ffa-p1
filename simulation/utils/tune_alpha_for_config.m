function tune_alpha_for_config(config_id , design_id, scratch_root) 

    % get config, then unpack
    config = yaml.loadFile( ...
        fullfile('simulation', 'data', design_id, config_id, 'config.yml') ...
    );
    M = config.settings.M;
    K_max = config.settings.K_max;
    delta = config.settings.delta;
    num_reps = config.settings.num_reps;
    V = config.tuning.num_reps;

    % create A and R
    [A, A_mat] = create_band_deletion_array(M, M, delta);
    [R, ~] = create_difference_array(M, M);

    % create table data_tune and vector alpha_stars for tuning results
    col_names = {'alpha', 'rep', 'v', 'nobpe'};
    data_tune = array2table(zeros(0, length(col_names)));
    data_tune.Properties.VariableNames = col_names;
    alpha_stars = zeros(1, num_reps);
    for rep = 1:num_reps
        mnobpe_decreasing = true;
        alpha_last = NaN;
        alpha_curr = 0;
        iter = 0;  % used to compute alpha after first iteration

        % NOTE: This function tunes the smoothing parameter, alpha, adaptively.
        % For each `rep`, it starts with no smoothing then exponentially 
        % increments the smoothing parameter until MNOBPE increases for the
        % first time, at which point it stops and proceeds to the next `rep`.
        % To minimize file I/O, we cache covariances and loadings.
        cov_cache = struct();
        load_cache = struct();

        while mnobpe_decreasing
            
            % increment alphas unless on the first iteration
            if iter > 0
                alpha_last = alpha_curr;
                alpha_curr = 10^(iter-1);
            end

            for v = 1:V
            
                % generate struct fields for covariance cache
                cov_field_train = sprintf('f_%d_%s', v, 'train');
                cov_field_test = sprintf('f_%d_%s', v, 'test');

                % generate struct field for loading cache
                load_field = sprintf('f_%d_%d', v, alpha_curr);
    
                if ~any(strcmp(fieldnames(cov_cache), cov_field_train))
                    % add train/test covariances to cache
                    C_hat_train_path = fullfile( ...
                        scratch_root, config.dirs.data, ...  % pull from scratch root
                        format_matrix_filename( ...
                            'Chat', '.csv.gz', rep, v, 'train' ...
                            ) ...
                        );
                    C_hat_test_path = fullfile( ...
                        scratch_root, config.dirs.data, ...  % pull from scratch root
                        format_matrix_filename( ...
                            'Chat', '.csv.gz', rep, v, 'test' ...
                            ) ...
                        );
                    C_hat_train_mat = read_zipped_matrix_file(C_hat_train_path);
                    C_hat_test_mat = read_zipped_matrix_file(C_hat_test_path);
                    cov_cache.(genvarname(cov_field_train)) = C_hat_train_mat;
                    cov_cache.(genvarname(cov_field_test)) = C_hat_test_mat;
                else  
                    % retrieve from cache
                    C_hat_train_mat = cov_cache.(genvarname(cov_field_train));
                    C_hat_test_mat = cov_cache.(genvarname(cov_field_test));
                end
                    
                % compute L_hat_alpha from C_hat_train
                [~,L_hat_train_mat,~,~] = array_completion( ...
                    reshape(C_hat_train_mat, M, M, M, M), ...
                    K_max, delta, alpha_curr, A, R ...
                    );
                load_cache.(genvarname(load_field)) = L_hat_train_mat;
                
                % compute normalized off-band prediction error
                nobpe = norm( ...
                    A_mat.*(L_hat_train_mat*L_hat_train_mat' ...
                    - C_hat_test_mat), 'fro') ... 
                    / norm(A_mat.*C_hat_test_mat, 'fro');
                
                % add row to data_tune
                row = {alpha_curr, rep, v, nobpe};
                data_tune = [data_tune; row];
                
            end

            % determine whether mnobpe is decreasing
            if ~isnan(alpha_last)
                mnobpe_last = mean(data_tune( ...
                    data_tune.rep == rep & data_tune.alpha == alpha_last, ...
                    :).nobpe);
                mnobpe_curr = mean(data_tune( ...
                    data_tune.rep == rep & data_tune.alpha == alpha_curr, ...
                    :).nobpe);
                if mnobpe_last - mnobpe_curr < 0 
                    mnobpe_decreasing = false; 
                end
            end
            iter = iter + 1;

        end
        alpha_stars(rep) = alpha_last;
        
        % write smoothed LHats for each fold (to be used in later CV)
        for v = 1:V
            load_field = sprintf('f_%d_%d', v, alpha_last);
            L_hat_mat = load_cache.(genvarname(load_field));
            write_zipped_matrix_file( ...
                L_hat_mat, ...
                fullfile( ...
                    config.dirs.data, ...
                    format_matrix_filename('Lhatsm', '.csv', rep, v, 'train') ...
                    ) ...
                );
        end
    end

    % write tuning results to appropriate files
    config.tuning.selections.alphas = alpha_stars;
    yaml.dumpFile(fullfile('simulation', 'data', design_id, config_id, 'config.yml'), config);
    writetable(data_tune, fullfile(config.dirs.results, 'data_tune_alpha.csv'));

end