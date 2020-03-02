%Analyze traces in batches to make FRET histograms
% X. Feng, modified from M. Poyton
% July 9, 2019

clear;
close all;
fclose('all');

%% Correction parameters for FRET%%
dbackground_0=0;
d2background_0=0;
abackground_0=0;

dbackground_1=0;
d2background_1=0;
abackground_1=0;

dbackground_2=0;
d2background_2=0;
abackground_2=0;

leakage12=0.1066;   %0.11
leakage21=0.0;
leakage13=0.0083;   %0.013
leakage23=0.0446;   %0.12

gamma12=0.8730;  %1
gamma23 = 2.62; 
gamma13=gamma12*gamma23;

direct = 0.117; %ashlee: 0.1578;   %0.19


%read data
pth=input('directory [default=C:\\User\\tir data\\yyyy\\New Folder]  ');
if isempty(pth)
    pth=pwd;
end
cd(pth);
save_file=pth;

disp(pth);
FolderDir=dir;
[nf,dumn]=size(FolderDir);

timeunit=input('time unit [default=0.2 sec]  ');
if isempty(timeunit)
    timeunit=0.2;
end

raw = [];
raw2 = [];
Data_b = [];
Data_r = [];
tempData = [];
n_regions = 0;
region2numTraces = [];

%% read .traces files

for i=1:nf
    if FolderDir(i).isdir == 0
        s=FolderDir(i).name;
        if s(end-7:end) == 'l.traces'
            n_regions = n_regions + 1;
            disp(s);
            fileid=fopen(s,'r');
            fid2=fopen(s,'r');
            %first line of binary file specifies length of trace
            len=fread(fid2,1,'int32');
            disp('The len of the time traces_background is: ')
            disp(len);
            %number of traces
            Ntraces=fread(fid2,1,'int16');
            tempData=zeros(Ntraces,len);
            index=(1:Ntraces*len);
            disp('The number of traces_background is: ')
            disp(Ntraces/3);
            %tempraw2 is a linear array, looks like it
            raw2=fread(fid2,Ntraces*len,'int16');
            disp('Done reading data.');
            fclose(fid2);
            tempData(index)=raw2(index);
            Data_b = [Data_b' tempData(:, 1:30)']';
            %Data_b = [Data_b' tempData']';
        end
        if s(end-7:end) == 'w.traces'
            disp(s);
            fileid=fopen(s,'r');
            fid=fopen(s,'r');
            %first line of binary file specifies length of trace
            len=fread(fid,1,'int32');
            disp('The len of the time traces_raw is: ')
            disp(len);
            %number of traces
            Ntraces=fread(fid,1,'int16');
            tempData=zeros(Ntraces,len);
            index=(1:Ntraces*len);
            disp('The number of traces_raw is: ')
            disp(Ntraces/3);
            region2numTraces = [region2numTraces Ntraces/3];
            %tempraw2 is a linear array, looks like it
            raw=fread(fid,Ntraces*len,'int16');
            disp('Done reading data.');
            fclose(fid);
            
            tempData(index)=raw(index);
            Data_r = [Data_r' tempData(:, 1:30)']';
            %Data_r = [Data_r' tempData']';
        end
    end
end

%subtracts background

Data_bs=Data_r-Data_b;

Ntraces=size(Data_bs,1);

num_frames = size(Data_bs,2);
len=num_frames;

for i = 0:len
    greenlaser_time= (i*3+1)*timeunit;
    redlaser_time = (i*3+2)*timeunit;
    farredlaser_tme = (i*3+3)*timeunit;
end

N_mol=Ntraces/3;
len_each = len/3;

% allocate space to store raw data
DonorRawData_0 = zeros(N_mol, len_each);
DonorRawData_1 = zeros(N_mol, len_each);
DonorRawData_2 = zeros(N_mol, len_each);
Donor2RawData_0 = zeros(N_mol, len_each);
Donor2RawData_1 = zeros(N_mol, len_each);
Donor2RawData_2 = zeros(N_mol, len_each);
AcceptorRawData_0 = zeros(N_mol, len_each);
AcceptorRawData_1 = zeros(N_mol, len_each);
AcceptorRawData_2 = zeros(N_mol, len_each);

% fill in with data

for i=1:N_mol
    for j=1:len_each
        DonorRawData_0(i,j) = Data_bs(i*3-2,j*3-2);
        Donor2RawData_0(i,j) = Data_bs(i*3-1,j*3-2);
        AcceptorRawData_0(i,j) = Data_bs(i*3,j*3-2);
        
        DonorRawData_1(i,j) = Data_bs(i*3-2,j*3-1);
        Donor2RawData_1(i,j) = Data_bs(i*3-1,j*3-1);
        AcceptorRawData_1(i,j) = Data_bs(i*3,j*3-1);
        
        DonorRawData_2(i,j) = Data_bs(i*3-2,j*3);
        Donor2RawData_2(i,j) = Data_bs(i*3-1,j*3);
        AcceptorRawData_2(i,j) = Data_bs(i*3,j*3);
    end
end

% 7ex7em
trimmedAcceptorRawData_2 = AcceptorRawData_2(:,1:9);
AvAcceptorRawData_2= sum(trimmedAcceptorRawData_2,2)/9;

% 3ex5em
trimmedDonor2RawData_0 = Donor2RawData_0(:,1:9);
AvDonor2RawData_0 = sum(trimmedDonor2RawData_0,2)/9;

% 3ex3em
trimmedDonorRawData_0 = DonorRawData_0(:,1:9);
AvDonorRawData_0=sum(trimmedDonorRawData_0,2)/9;

% 3ex7em
trimmedAcceptorRawData_0 = AcceptorRawData_0(:,1:9);
AvAcceptorRawData_0 = sum(trimmedAcceptorRawData_0,2)/9;

trimmedDonorRawData_1 = DonorRawData_1(:,1:9);
AvDonorRawData_1=sum(trimmedDonorRawData_1,2)/9;

% 5ex5em
trimmedDonor2RawData_1 = Donor2RawData_1(:,1:9);
AvDonor2RawData_1=sum(trimmedDonor2RawData_1,2)/9;

% 5ex7em
trimmedAcceptorRawData_1 = AcceptorRawData_1(:,1:9);
AvAcceptorRawData_1 = sum(trimmedAcceptorRawData_1,2)/9;

% Corrections

Donor2Correct_0 = gamma12 * ((1 + leakage21 + leakage23) / (1 - leakage12 * leakage21)) * ((AvDonor2RawData_0 - d2background_0) - leakage12 * (AvDonorRawData_0 - dbackground_0));
DonorCorrect_0 = ((1 + leakage12 + leakage13) / (1 - leakage12 * leakage21)) * (AvDonorRawData_0 - dbackground_0) - leakage21 * (AvDonor2RawData_0 - d2background_0);
AcceptorCorrect_0 = gamma13 * ((AvAcceptorRawData_0 - abackground_0) - ((leakage23 * leakage12 - leakage13)/(1 - leakage12 * leakage21)) * (AvDonorRawData_0 - dbackground_0) + ((leakage13 * leakage21 - leakage23 ) / (1 - leakage12 * leakage21)) * (AvDonor2RawData_0 - d2background_0));
EachTotalCorrect_0 = DonorCorrect_0 + Donor2Correct_0 + AcceptorCorrect_0;
EachTotalCorrect_0 = (EachTotalCorrect_0~=0).*EachTotalCorrect_0 + (EachTotalCorrect_0==0)*1;	% remove zeros

DonorCorrect_1 = ((1 + leakage12 + leakage13) / (1 - leakage12 * leakage21)) * (AvDonorRawData_1 - dbackground_1) - leakage21 * (AvDonorRawData_1 - d2background_1);
Donor2Correct_1 = gamma12 * ((1 + leakage21 + leakage23) / (1 - leakage12 * leakage21)) * (AvDonor2RawData_1 - d2background_1) - leakage12 * (AvDonorRawData_1 - dbackground_1);
AcceptorCorrect_1 = gamma13 * (AvAcceptorRawData_1 - abackground_1) - ((leakage23 * leakage12 - leakage13)/(1 - leakage12 * leakage21)) * (AvDonorRawData_1 - dbackground_1) + ((leakage13 * leakage21 - leakage23) / (1 - leakage12 * leakage21)) * (AvDonor2RawData_1 -d2background_1);
AcceptorCorrect_1 = AcceptorCorrect_1 - direct * (Donor2Correct_1 + AcceptorCorrect_1);
EachTotalCorrect_1 = Donor2Correct_1 + AcceptorCorrect_1;

AcceptorCorrect_2 = AvAcceptorRawData_2 - abackground_2;

fret12 = AcceptorCorrect_1 ./ EachTotalCorrect_1;
fret01 = Donor2Correct_0 ./ ((1-fret12).*DonorCorrect_0 + Donor2Correct_0);
fret02 = (AcceptorCorrect_0 - fret12.*(Donor2Correct_0 + AcceptorCorrect_0)) ./ (DonorCorrect_0 + AcceptorCorrect_0 - fret12 .* (EachTotalCorrect_0));

% discard bad fret values
for i = 1:N_mol
    
    if fret12(i) < -0.2 || fret12(i) > 1.2
        fret12(i) = nan;
    end
    
    if fret01(i) < -0.2 || fret01(i) > 1.2
        fret01(i) = nan;
    end
    
    if fret02(i) < -0.2 || fret02(i) > 1.2
        fret02(i) = nan;
    end
    
end

figure;
set(gcf,'Position',[500 100 700 700])
subplot(4,1,1);
hist(EachTotalCorrect_0(:,1),80);
title('Green laser, Cy3 + Cy5 + Cy7 Em');
[cy357_x, cy357_y] = ginput(2);

subplot(4,1,2);
hist(EachTotalCorrect_1(:,1),80);
title('Red laser, Cy5 + Cy7 Em');
[cy57_x, cy57_y] = ginput(2);

subplot(4,1,3);
hist(AcceptorCorrect_2(:,1),80);
title('750 laser, Cy7 Em');
[cy7_x, cy7_y] = ginput(2);

% subplot(4,1,4);
% hist(AvAcceptorRawData_0(:,1),80);
% title('Green laser, Cy7 Em');
% [cy37fret_x, cy37fret_y] = ginput(2);

% filter for spots of interest
molec_with_cy3 = false(N_mol, 1);
molec_with_cy5 = false(N_mol, 1);
molec_with_cy7 = false(N_mol, 1);
molec_with_cy3cy7fret = false(N_mol, 1);

for i = 1:N_mol
    
    % has cy3
    if EachTotalCorrect_0(i, 1) > cy357_x(1) && EachTotalCorrect_0(i, 1) < cy357_x(2) 
        molec_with_cy3(i) = true;
    end
    
    % has cy5
    if EachTotalCorrect_1(i, 1) > cy57_x(1) && EachTotalCorrect_1(i, 1) < cy57_x(2)
        molec_with_cy5(i) = true;
    end
    
    % has cy7
    if AcceptorCorrect_2(i, 1) > cy7_x(1) && AcceptorCorrect_2(i, 1) < cy7_x(2)
        molec_with_cy7(i) = true;
    end
    
%     if AvAcceptorRawData_0(i, 1) > cy37fret_x(1) && AvAcceptorRawData_0(i, 1) < cy37fret_x(2)
%         molec_with_cy3cy7fret(i) = true;
%     end
end

diary colocalization_analysis.txt

fprintf('Colocalized Cy3 and Cy5 count per image: %.2f\n', ...
    sum(molec_with_cy3 & molec_with_cy5) / n_regions);

% fprintf('Colocalized Cy3-Cy7 FRET and Cy7 fraction: %.2f\n', ...
%     sum(molec_with_cy7 & molec_with_cy3cy7fret) / sum(molec_with_cy7));

% find Cy3/(Cy3 + Cy5) for each region, then average

global_traceID = 1;
nCy3_over_nCy3orCy5 = zeros(n_regions, 1);
nCy3andCy5_over_Cy5 = zeros(n_regions, 1);

for regionID = 1:n_regions
    num_traces = region2numTraces(regionID);
    nCy3 = 0;
    nCy5 = 0;
    nCy3orCy5 = 0;
    nCy3andCy5 = 0;
    for traceID = 1:num_traces
        nCy3 = nCy3 + molec_with_cy3(global_traceID);
        nCy5 = nCy5 + molec_with_cy5(global_traceID);
        nCy3orCy5 = nCy3orCy5 + ...
            (molec_with_cy3(global_traceID) | molec_with_cy5(global_traceID));
        nCy3andCy5 = nCy3andCy5 + ...
            (molec_with_cy3(global_traceID) & molec_with_cy5(global_traceID));
        global_traceID = global_traceID + 1;
    end
    nCy3_over_nCy3orCy5(regionID) = nCy3 / nCy3orCy5;
    nCy3andCy5_over_Cy5(regionID) = nCy3andCy5 / nCy5;
end

% fprintf('average #Cy3 / #(Cy3 or Cy5) = %.3f +/- %.3f\n', ...
%     mean(nCy3_over_nCy3orCy5), std(nCy3_over_nCy3orCy5));

fprintf('average #(Cy3 and Cy5) / #Cy5 = %.3f +/- %.3f\n', ...
    mean(nCy3andCy5_over_Cy5), std(nCy3andCy5_over_Cy5));

diary off

f1 = figure;
histogram(fret01(molec_with_cy3 & molec_with_cy5), 'BinWidth', 0.025);
xlim([-0.2 1.2]);
%ylim([0 600]);
title('Cy3 Cy5 FRET');
xlabel('FRET Efficiency');
ylabel('Count');
set(gca,'FontSize',20);
saveas(f1, 'Cy3 Cy5 FRET ver2.png')

% Cy5-Cy7 FRET histogram

f2 = figure;
histogram(fret12(molec_with_cy5 & molec_with_cy7), 'BinWidth', 0.025);
xlim([-0.2 1.2]);
title('Cy5 Cy7 FRET');
xlabel('FRET Efficiency');
ylabel('Count');
set(gca,'FontSize',20);
saveas(f2, 'Cy5 Cy7 FRET ver2.png')

% Cy5-Cy7 FRET histogram for spots with Cy3 intensity

f2 = figure;
histogram(fret12(molec_with_cy5 & molec_with_cy7 & molec_with_cy3), 'BinWidth', 0.025);
xlim([-0.2 1.2]);
title('Cy5 Cy7 FRET');
xlabel('FRET Efficiency');
ylabel('Count');
set(gca,'FontSize',20);
saveas(f2, 'Cy5 Cy7 FRET ver2 filtered for Cy3.png')

f3 = figure;
histogram(fret02(molec_with_cy3 & molec_with_cy7 & (~molec_with_cy5)), 'BinWidth', 0.04);
%histogram(fret02(molec_with_cy3 & molec_with_cy7), 'BinWidth', 0.025);
xlim([-0.2 1.2]);
title('Cy3 Cy7 FRET');
xlabel('FRET Efficiency');
ylabel('Count');
set(gca,'FontSize',20);
saveas(f3, 'Cy3 Cy7 FRET ver2.png')

to_save01 = fret01(molec_with_cy3 & molec_with_cy5);
to_save12 = fret12(molec_with_cy5 & molec_with_cy7);
to_save12_ver2 = fret12(molec_with_cy5 & molec_with_cy7 & molec_with_cy3);
to_save02 = fret02(molec_with_cy3 & molec_with_cy7);
to_save02_ver2 = fret02(molec_with_cy3 & molec_with_cy7 & (~molec_with_cy5));
%csvwrite('Cy3Cy5_fret_values_ver2.csv', to_save01);
%csvwrite('Cy5Cy7_fret_values_ver2.csv', to_save12);
%csvwrite('Cy3Cy7_fret_values_ver2.csv', to_save02_ver2);
csvwrite('Cy5Cy7_fret_values_ver2_filtered_for_cy3.csv', to_save12_ver2);