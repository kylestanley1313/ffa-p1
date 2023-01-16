function mat = read_zipped_matrix_file( path ) 
    path_unzip_array = gunzip(path);
    path_unzip = path_unzip_array{1};
    mat = readmatrix(path_unzip);
    delete(path_unzip);
end