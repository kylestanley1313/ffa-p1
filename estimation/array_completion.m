function [L_hat, L_hat_mat, svd_time, fminunc_time] = array_completion( ...
    C, K, delta, alpha, A, R)
    arguments
        C
        K
        delta
        alpha
        A = nan
        R = nan
    end

    M1 = size(C, 1);
    M2 = size(C, 2);
    C_mat = reshape(C, M1*M2, M1*M2);

    % Create A, the band-deleting array
    % Create R, the 2nd-order difference tensor
    % TODO: Alternative to for loops (use fact that A/R are symmetric)
    if isnan(A) 
        [~, A_mat] = create_band_deletion_array(M1, M2, delta); 
    else
        A_mat = reshape(A, M1*M2, M1*M2);
    end
    if isnan(R) 
        [~, R_mat] = create_difference_array(M1, M2); 
    else
        R_mat = reshape(R, M1*M2, M1*M2);
    end

    % Set options for optimization using fminunc
	options = optimset;
	options = optimset(options,'Display', 'iter');  % 'off' or 'iter'
	options = optimset(options,'GradObj', 'on');
	options = optimset(options,'Hessian', 'off');
    % options = optimset(options, 'HessUpdate', 'lbfgs') % this is faster
    % options = optimset(options, 'DerivativeCheck', 'on');

    % Initialize L
    tic
    [U,S,~] = svd(C_mat);
    svd_time = toc;
    L_init_mat = U(:,1:K) * sqrt(S(1:K,1:K));

    % Optimization
    tic
    [x] = fminunc(@(L_mat)penalized_objective(L_mat, C_mat, A_mat, R_mat, alpha), L_init_mat, options);
    fminunc_time = toc;
    L_hat_mat = x;
    L_hat = reshape(L_hat_mat, M1, M2, K);
    
end