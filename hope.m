f = fopen('hope.bin');
A = fread(f);
fclose(f);
t = linspace(0,4096/39062.5,4096);

%% 
figure(1);
A=clap;
volt =(A/255-0.5) *1.25 +2.5;
plot(find(A~=63),A(find(A~=63)),'-c');
hold on; 
plot(A,'.b');
hold off;
ylim([0 256])
xlabel('time (s)');
ylabel('ADC Code');
set(gca,'YTick',[0:16:256]);
grid on;
set(gca, 'YTickLabel', cellstr(num2str(reshape(get(gca, 'YTick'),[],1),'%02X')) )
%%
figure(11);
plot(t,volt,'.-');
ylim([0 5])
xlabel('time (s)');
ylabel('volt (V)');
grid on;


%%
    

figure(2);
plot(db(fft(A)));

figure(3);
hist(A,256);
xlim([0 255])
