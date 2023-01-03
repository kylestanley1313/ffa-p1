function fname = format_matrix_filename( mat, ext, method, rep, v, split ) 
    arguments
        mat
        ext
        method = nan
        rep = nan
        v = nan
        split = nan
    end
    
    fname = sprintf('mat-%s_', mat);
    if ~isnan(method)
        fname = sprintf('%smethod-%s_', fname, method);
    end
    if ~isnan(rep)
        fname = sprintf('%sr-%d_', fname, rep);
    end
    if ~isnan(v)
        fname = sprintf('%sv-%d_', fname, v);
    end
    if ~isnan(split)
        fname = sprintf('%ssplit-%s_', fname, split);
    end
    fname = sprintf('%s%s', fname, ext);
end
