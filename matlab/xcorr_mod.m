function [X] = xcorr_mod( A, B )
A = double(A);
B = double(B);
X = zeros(1,256);
for n = 1:256
    X(n) = (A(n:n+255)')*(B((257-n):512-n));
end
    
X = X*(2^-13);
end
