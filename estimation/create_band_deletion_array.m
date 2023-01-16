function [A, A_mat] = create_band_deletion_array(M1, M2, delta)
    A = zeros(M1, M2, M1, M2);
    delta_1 = ceil(M1*delta);
    delta_2 = ceil(M2*delta);
    for m11 = 1:M1
        for m21 = 1:M2
            for m12 = 1:M1
                for m22 = 1:M2
                    diff_1 = abs(m11 - m12);
                    diff_2 = abs(m21 - m22);
                    if diff_1 > delta_1 | diff_2 > delta_2
                        A(m11, m21, m12, m22) = 1;
                    end
                end
            end
        end
    end
    A_mat = reshape(A, M1*M2, M1*M2);
end