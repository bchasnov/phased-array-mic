function [ X,H ] = hex2dat( file, n )
%HEX2DAT Summary of this function goes here
%   Detailed explanation goes here
    H = importdata(file,',',n);
    X = uint8(zeros(length(H),1));

    for i=1:length(H)
        c = char(H(i));
        X(i) = uint8(hex2dec(c(10:11)));
    end
end

