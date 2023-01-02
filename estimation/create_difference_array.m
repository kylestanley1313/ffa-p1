function [R, R_mat] = create_difference_array(M1, M2)
    R = zeros(M1, M2, M1, M2);
    for m11 = 1:M1
        for m21 = 1:M2
            for m12 = 1:M1
                for m22 = 1:M2
                    diff_1 = abs(m11 - m12);
                    diff_2 = abs(m21 - m22);
                    max_diff = max(diff_1, diff_2);
                    if max_diff == 0
                        R(m11, m21, m12, m22) = 8;
                    elseif max_diff == 1
                        R(m11, m21, m12, m22) = -1;
                    end
                end
            end
        end
    end
    R_mat = reshape(R, M1*M2, M1*M2);
end