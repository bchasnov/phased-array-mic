function [ X,H ] = hex2dat32( file, n )
%HEX2DAT Summary of this function goes here
%   Detailed explanation goes here
    m = 32/8;
    H = importdata(file,',',n*m);
    XX = zeros(n*m,1);
    X = zeros(n,1);
    
    for i=1:length(H)
        c = char(H(i));
        XX(i) = uint8(hex2dec(c(10:11)));
    end
    
    for i=1:n
        j = i+(i-1)*m;
        X(i) = X(j) + ...
            X(j+1) * 2^8 + ...
            X(j+2) * 2^16 + ...
            X(j+3) * 2^24;
    end
end
