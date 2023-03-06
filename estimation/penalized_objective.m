function [f,g] = penalized_objective(L, C, A, R, alpha)

temp = A.*(C-L*L');
f= (norm(temp(:),2))^2 + trace(L'*R*L*alpha);

temp2 = -4.*((A.*(C-L*L'))*L) + 2*R*L*alpha;
g=temp2(:);

end