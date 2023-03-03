function fname = format_matrix_filename_analysis( mat, ext, K, alpha, v, split ) 
    arguments
        mat
        ext
        K = nan
        alpha = nan
        v = nan
        split = nan
    end
    
    fname = sprintf('mat-%s', mat);
    if ~isnan(K)
        fname = sprintf('%s_K-%d', fname, K);
    end
    if ~isnan(alpha)
        fname = sprintf('%s_alpha-%d', fname, alpha);
    end
    if ~isnan(v)
        fname = sprintf('%s_v-%d', fname, v);
    end
    if ~isnan(split)
        fname = sprintf('%s_split-%s', fname, split);
    end
    fname = sprintf('%s%s', fname, ext);
end