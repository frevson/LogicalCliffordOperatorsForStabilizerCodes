function circuit = find_circuit(F)
% Function to find a circuit for the given symplectic transformation F
% Uses Trung Can's algorithm to decompose F into elementary forms

% Author: Narayanan Rengaswamy, Date: Feb. 22, 2018

m = size(F,1)/2;
I = eye(m);
Z = zeros(m);
Omega = [Z, I; I, Z];

if (~all(all(mod(F * Omega * F', 2) == Omega)))
    fprintf('\nInvalid symplectic matrix!\n');
    circuit = [];
    return;
end

Decomp = symp_mat_decompose(F);
circuit = cell(1,2);
ckt_ind = 1;
ancilla = m + 1;

for i = 1:length(Decomp)
    if (all(all(Decomp{i} == eye(2*m))))
        continue;
    elseif (all(all(Decomp{i} == Omega)))
        circuit{ckt_ind,1} = 'H';
        circuit{ckt_ind,2} = 1:m;
        ckt_ind = ckt_ind + 1;
        continue;
    end
    A = Decomp{i}(1:m,1:m);
    B = Decomp{i}(1:m,m+(1:m));
    C = Decomp{i}(m+(1:m),1:m);
    D = Decomp{i}(m+(1:m),m+(1:m));
    
    if (all(A(:) == I(:)) && all(C(:) == Z(:)) && all(D(:) == I(:)))
        S_ind = find(diag(B) == 1);
        for j = 1:length(S_ind)
            circuit{ckt_ind,1} = 'S';
            circuit{ckt_ind,2} = S_ind(j);
            ckt_ind = ckt_ind + 1;
        end
        % Clear diagonal entries, extract upper triangular part as B = B'
        B = triu(mod(B + diag(diag(B)), 2));
        for j = 1:m
            CZ_ind = find(B(j,:) == 1);
            for k = 1:length(CZ_ind)
                circuit{ckt_ind,1} = 'CZ';
                circuit{ckt_ind,2} = [j CZ_ind(k)];
                ckt_ind = ckt_ind + 1;
            end
        end
    elseif (all(B(:) == Z(:)) && all(C(:) == Z(:)))
        for j = 1:m
            inds = find(A(:,j) == 1);
            if (A(j,j) == 1)
                inds(inds == j) = [];
                for k = 1:length(inds)
                    circuit{ckt_ind,1} = 'CNOT';
                    circuit{ckt_ind,2} = [inds(k) j];  % CNOT_{inds(k)->j}
                    ckt_ind = ckt_ind + 1;
                end
            else
                if (length(inds) == 1)
                    circuit{ckt_ind,1} = 'Swap';
                    circuit{ckt_ind,2} = [j inds(1)];
                    ckt_ind = ckt_ind + 1;
                else
                    circuit{ckt_ind,1} = 'Ancilla in |0>';
                    circuit{ckt_ind,2} = ancilla;
                    ckt_ind = ckt_ind + 1;
                    circuit{ckt_ind,1} = 'CNOTs';
                    circuit{ckt_ind,2} = [inds', ancilla];
                    ckt_ind = ckt_ind + 1;
                    ancilla = ancilla + 1;
                end
            end
        end
    else
        k = m - sum(diag(A));
        Uk = blkdiag(eye(k), zeros(m-k));
        Lmk = blkdiag(zeros(k), eye(m-k));
        if (all(A(:) == Lmk(:)) && all(B(:) == Uk(:)) && ...
            all(C(:) == Uk(:)) && all(D(:) == Lmk(:)))
            circuit{ckt_ind,1} = 'H';
            circuit{ckt_ind,2} = 1:k;
            ckt_ind = ckt_ind + 1;
        else
            fprintf('\nUnknown elementary symplectic form!\n');
            circuit = [];
            break;
        end
    end
end    
            
        

end