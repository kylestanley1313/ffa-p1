function write_zipped_matrix_file( mat, path ) 
    writematrix(mat, path);
    gzip(path);
    delete(path);
end