p1 = double(hex2dat('sin800_1.hex',512));
p2 = double(hex2dat('sin800_2.hex',512));

r=-256:2:255;

%xc = xcorr_mod(p1-mean(p1),p2-mean(p1));
xc = xcorr_mod(p1,p2);
figure(1); plot(r,xc);
grid on;
figure(3);
plot([p1,p2],'.');
%%

[a, n] = xcorr(p1,p2);
figure(4); plot(n,a);

%%
A = hex2dat('xcorr.hex',256);
[max_y max_i] = max(A);
figure(2); plot(r,A,'.-');
hold on;
plot(r(max_i), max_y,'.r');
hold off;
