function fname = format_matrix_filename_analysis( mat, ext, time, v, split ) 
    arguments
        mat
        ext
        time
        v = nan
        split = nan
    end
    
    fname = sprintf('mat-%s', mat);
    if ~isnan(time)
        fname = sprintf('%s_time-%d', fname, time);
    end
    if ~isnan(v)
        fname = sprintf('%s_v-%d', fname, v);
    end
    if ~isnan(split)
        fname = sprintf('%s_split-%s', fname, split);
    end
    fname = sprintf('%s%s', fname, ext);
end