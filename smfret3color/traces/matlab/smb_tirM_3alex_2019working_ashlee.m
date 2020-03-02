% Single Molecule Biophysics Lab. in Seoul National University // MJ 2019 July
% edited by X. Feng Sep 4, 2019

close all;

%% path and filename setting
WorkingDirectory = pwd;
filename_head = 'hel2';
folder_prefix = '200121-1';

%% Correction parameters for FRET%%
dbackground_b=0;
d2background_b=0;abackground_b=0;

dbackground_g=0;
d2background_g=0;
abackground_g=0;

dbackground_r=0;
d2background_r=0;
abackground_r=0; 

leakage12=0.1066;   %0.11
leakage21=0.0;
leakage13=0.0083;   %0.013
leakage23=0.0446;   %0.12

gamma12=0.8730;  %1
gamma23 = 2.62;
gamma13=gamma12*gamma23;

direct = 0.117; %ashlee: 0.1578;

%% Options
LaserOrderChange = 'y'; %Check this part when excitation laser order is matched.
ColorNumber = 3;
DyeType = 'cy235';      %not done: b->g, g->r, r->far red (color change only)
DoseBinningNeed = 'n';  %#ok<*NASGU> % %binning required??
binwidth=5;
DoesFilterNeed = 'n';   % %filter required??
DoseMovieNeed = 'n';    % Movie required??
Is_Avg_and_E_save ='n'; % Average and E level save??
FirstNumber = 10;       % histogram options
LastNumber = 10;        % histogram options

%% Trace axis range
BottomLimit_b=-600;
UpperLimit_b=1000;
BottomLimit_g=-300;
UpperLimit_g=1000;
BottomLimit_r=-100;
UpperLimit_r=1000;

%% log file loading (time unit etc. Ha lab ver.)

fileinfo = dir([filename_head '.log']);
if sum(size(fileinfo)) == 1
    disp(['No log file : '  filename_head '.log']);
end
%date = fileinfo(1).date;
fileid_log = fopen([filename_head '.log'],'r');		%% .log file
%fileid_log = fopen(['hel1.log'],'r');	
logarray = textscan(fileid_log, '%s', 'Delimiter','\n');
timeunit = 0.001*str2double(logarray{1,1}{strmatch('Exposure Time [ms]', logarray{1,1})+1});
gain = str2double(logarray{1,1}{strmatch('Gain', logarray{1,1})+1}); 
scaler = str2double(logarray{1,1}{strmatch('Data Scaler', logarray{1,1})+1});
background_donor = str2double(logarray{1,1}{strmatch('Background', logarray{1,1})+1}); %#ok<*MATCH2>
background_acceptor = str2double(logarray{1,1}{strmatch('Background', logarray{1,1})+1});
fclose(fileid_log);

%% path and filename

OriginalDirectory=cd;
cd(WorkingDirectory);
filename_traces = [filename_head '.' num2str(ColorNumber) 'color_3alex_traces'];
filename_movie = [filename_head '.' num2str(ColorNumber) 'color_3alex_movies'];
filename_time = [filename_head '_time.dat'];
filename_add = [ filename_head '_select.dat'];
filename_add_region = [ filename_head '_region.dat' ];
filename_add_region_data=[ filename_head '_region_data.dat' ];

%% Reading data %%
fileid = fopen(filename_traces,'r');

if fileid == -1
    disp(['No data file  '  filename_head]);
end

time_length = fread(fileid, 1, 'int32');
fprintf('The length of the time traces is: %d\n', time_length);

if mod(time_length,3)==0
    time_b = (0:+3:(time_length-3))*timeunit;
    time_g = (1:+3:(time_length-2))*timeunit;
    time_r = (2:+3:(time_length-1))*timeunit;
end

if mod(time_length,3)==1
    time_b = (0:+3:(time_length-3))*timeunit;
    time_g = (1:+3:(time_length-2))*timeunit;
    time_r = (2:+3:(time_length-1))*timeunit;
end

if mod(time_length,3)==2
    time_b = (0:+3:(time_length-3))*timeunit;
    time_g = (1:+3:(time_length-2))*timeunit;
    time_r = (2:+3:(time_length-1))*timeunit;
end

NumberofTraces = fread(fileid, 1, 'int16');
NumberofPeaks = NumberofTraces/ColorNumber;
fprintf('The number of traces and peaks are: %d, %d\n', NumberofTraces, NumberofPeaks);

Data = fread(fileid, [NumberofTraces  time_length],'int16');
SpotDiameter = fread(fileid, 1, 'int16');  
disp('Done reading trace data.');
fclose(fileid);

Temp_i = [];
Tempfirstpoint = [];
Templastpoint = [];
Templength = [];
Temptime_region = [];
TempFret12_region = [];
TempFret13_region = [];
TempFret23_region = [];
TempDonor_b_region = [];
TempDonor2_b_region = []; 
TempAcceptor_b_region = []; 
TempDonor_g_region = [];
TempDonor2_g_region = [];
TempAcceptor_g_region = [];
TempDonor_r_region = [];
TempDonor2_r_region = [];
TempAcceptor_r_region = [];

dbackground_b_temp = dbackground_b;
d2background_b_temp = d2background_b;
abackground_b_temp = abackground_b;

dbackground_g_temp = dbackground_g;
d2background_g_temp = d2background_g;
abackground_g_temp = abackground_g;

dbackground_r_temp = dbackground_r;
d2background_r_temp = d2background_r;
abackground_r_temp = abackground_r;

if DoseMovieNeed == 'y'
    cd(WorkingDirectory);
    disp(filename_movie);
    fileid_movie = fopen(filename_movie, 'r');
    if fileid_movie ~= -1
        peaks_total_width = fread(fileid_movie, 1, 'int16');
        peak_height = fread(fileid_movie, 1, 'int16');
        peaks_number = peaks_total_width/peak_height;
        file_information = dir(filename_movie);
        film_time_length = (file_information.bytes-4)/(peak_height*peaks_total_width);
        fclose(fileid_movie);
        
        disp('peaks_total_width, height, number, film_time_length: ');
        disp(peaks_total_width);
        disp(peak_height);
        disp(peaks_number);
        disp(film_time_length);
        
        peak=zeros(ColorNumber*peak_height, peak_height, 'uint8');
        
        if peaks_number ~= NumberofTraces
            disp('error: Different trace numbers between .trace and .movies');
            return;
        end
        
        if film_time_length ~= time_length
            disp('error: Different time length between .trace and .movies');
            return;
        end
    else
        DoseMovieNeed = 'n';
        disp('No movie file');
    end
end


%% Convert raw data into donor and acceptor traces %%
time_length_each = floor(time_length/3);
DonorRawData_0 = zeros(NumberofPeaks, time_length_each, 'double');
Donor2RawData_0 = zeros(NumberofPeaks, time_length_each, 'double');
AcceptorRawData_0 = zeros(NumberofPeaks, time_length_each, 'double');
DonorRawData_1 = zeros(NumberofPeaks, time_length_each, 'double');
Donor2RawData_1 = zeros(NumberofPeaks, time_length_each, 'double');
AcceptorRawData_1 = zeros(NumberofPeaks, time_length_each, 'double');
DonorRawData_2 = zeros(NumberofPeaks, time_length_each, 'double');
Donor2RawData_2 = zeros(NumberofPeaks, time_length_each, 'double');
AcceptorRawData_2 = zeros(NumberofPeaks, time_length_each, 'double');

binlength = int32(time_length/binwidth-1);
bintime = zeros(binlength, 1, 'double');
binEraw = zeros(binlength, 1, 'double');
binEcorrect = zeros(binlength, 1, 'double');

for m=1:binlength
    bintime(m) = double(m-1)*(binwidth*timeunit);
end

if ColorNumber == 2
    for i=1:NumberofPeaks
        for j=1:time_length_each
            DonorRawData_1(i,j) = Data(i*2-1,j*2-1);
            Donor2RawData_1(i,j) = Data(i*2,j*2-1);
            %AcceptorRawData_1(i,j) = Data(i*2,j*2-1);
            AcceptorRawData_1(i,j) = 0;
            DonorRawData_2(i,j) = Data(i*2-1,j*2);
            Donor2RawData_2(i,j) = Data(i*2,j*2);
            %AcceptorRawData_2(i,j) = Data(i*2,j*2);
            AcceptorRawData_2(i,j) = 0;
        end
    end
end

if ColorNumber == 3
    for i=1:NumberofPeaks
        for j=1:time_length_each
            if LaserOrderChange == 'y' % Edit this part when the order of laser is wrong.
                DonorRawData_1(i,j) = Data(i*3-2,j*3-2);
                Donor2RawData_1(i,j) = Data(i*3-1,j*3-2);
                AcceptorRawData_1(i,j) = Data(i*3,j*3-2);
                DonorRawData_2(i,j) = Data(i*3-2,j*3-1);
                Donor2RawData_2(i,j) = Data(i*3-1,j*3-1);
                AcceptorRawData_2(i,j) = Data(i*3,j*3-1);
                DonorRawData_0(i,j) = Data(i*3-2,j*3);
                Donor2RawData_0(i,j) = Data(i*3-1,j*3);
                AcceptorRawData_0(i,j) = Data(i*3,j*3);
            else
                DonorRawData_0(i,j) = Data(i*3-2,j*3-2);
                Donor2RawData_0(i,j) = Data(i*3-1,j*3-2);
                AcceptorRawData_0(i,j) = Data(i*3,j*3-2);
                DonorRawData_1(i,j) = Data(i*3-2,j*3-1);
                Donor2RawData_1(i,j) = Data(i*3-1,j*3-1);
                AcceptorRawData_1(i,j) = Data(i*3,j*3-1);
                DonorRawData_2(i,j) = Data(i*3-2,j*3);
                Donor2RawData_2(i,j) = Data(i*3-1,j*3);
                AcceptorRawData_2(i,j) = Data(i*3,j*3);
            end
        end
    end
end

clear Data;



%% calculate, plot and save average traces %%
% MJ edited

DonorRawData_b = DonorRawData_1;
Donor2RawData_b = Donor2RawData_1;
AcceptorRawData_b = AcceptorRawData_1;
DonorRawData_g = DonorRawData_2;
Donor2RawData_g = Donor2RawData_2;
AcceptorRawData_g = AcceptorRawData_2;
DonorRawData_r = DonorRawData_0;
Donor2RawData_r = Donor2RawData_0;
AcceptorRawData_r = AcceptorRawData_0;

DonorRawAverage_b = sum(DonorRawData_b, 1) / NumberofPeaks;
Donor2RawAverage_b = sum(Donor2RawData_b, 1) /NumberofPeaks;
AcceptorRawAverage_b = sum(AcceptorRawData_b, 1) / NumberofPeaks;
DonorRawAverage_g = sum(DonorRawData_g, 1) / NumberofPeaks;
Donor2RawAverage_g = sum(Donor2RawData_g, 1) /NumberofPeaks;
AcceptorRawAverage_g = sum(AcceptorRawData_g, 1) / NumberofPeaks;
DonorRawAverage_r = sum(DonorRawData_r, 1) / NumberofPeaks;
Donor2RawAverage_r = sum(Donor2RawData_r, 1) /NumberofPeaks;
AcceptorRawAverage_r = sum(AcceptorRawData_r, 1) / NumberofPeaks;

clear DonorRawData_0;
clear Donor2RawData_0;
clear AcceptorRawData_0;
clear DonorRawData_1;
clear Donor2RawData_1;
clear AcceptorRawData_1;
clear DonorRawData_2;
clear Donor2RawData_2;
clear AcceptorRawData_2;

figure('Name','Raw Data Ensemble Average');
hdl1 = gcf;

%Green excitation signal average
subplot(3,1,1);
plot(time_b, DonorRawAverage_b - dbackground_b, 'g', time_b, Donor2RawAverage_b - d2background_b, 'r', time_b, AcceptorRawAverage_b - abackground_b, 'b');
title('Average raw signal on green excitation');
zoom on;

%Green excitation signal average
subplot(3,1,2);
plot(time_g, DonorRawAverage_g - dbackground_g, 'g', time_g, Donor2RawAverage_g - d2background_g, 'r', time_g, AcceptorRawAverage_g - abackground_g, 'b');
title('Average raw signal on red excitation');
zoom on;

%Red excitation signal average
subplot(3,1,3);
plot(time_r, DonorRawAverage_r - dbackground_r, 'g', time_r, Donor2RawAverage_r - d2background_r, 'r', time_r, AcceptorRawAverage_r - abackground_r, 'b');
title('Average raw signal on 750 excitation');
zoom on;

if Is_Avg_and_E_save =='n'
    AverageOutput_b = [time_b' DonorRawAverage_b' Donor2RawAverage_b' AcceptorRawAverage_b'];
    AverageOutput_g = [time_g' DonorRawAverage_g' Donor2RawAverage_g' AcceptorRawAverage_g'];
    AverageOutput_r = [time_r' DonorRawAverage_r' Donor2RawAverage_r' AcceptorRawAverage_r'];
    save([filename_head '_avg_b.dat'], 'AverageOutput_b', '-ascii');
    save([filename_head '_avg_g.dat'], 'AverageOutput_g', '-ascii');
    save([filename_head '_avg_r.dat'], 'AverageOutput_r', '-ascii');
end

%% calculate E level from the first 10 points and plot histograms of E level and total intensity. Also save the same info
tempDonor_b = reshape(DonorRawData_b(1:NumberofPeaks, 1:FirstNumber), NumberofPeaks*FirstNumber, 1);
tempDonor2_b = reshape(Donor2RawData_b(1:NumberofPeaks, 1:FirstNumber), NumberofPeaks*FirstNumber, 1);
tempAcceptor_b = reshape(AcceptorRawData_b(1:NumberofPeaks, 1:FirstNumber), NumberofPeaks*FirstNumber, 1);
tempDonor_g = reshape(DonorRawData_g(1:NumberofPeaks, 1:FirstNumber), NumberofPeaks*FirstNumber, 1);
tempDonor2_g = reshape(Donor2RawData_g(1:NumberofPeaks, 1:FirstNumber), NumberofPeaks*FirstNumber, 1);
tempAcceptor_g = reshape(AcceptorRawData_g(1:NumberofPeaks, 1:FirstNumber), NumberofPeaks*FirstNumber, 1);
tempDonor_r = reshape(DonorRawData_r(1:NumberofPeaks, 1:FirstNumber), NumberofPeaks*FirstNumber, 1);
tempDonor2_r = reshape(Donor2RawData_r(1:NumberofPeaks, 1:FirstNumber), NumberofPeaks*FirstNumber, 1);
tempAcceptor_r = reshape(AcceptorRawData_r(1:NumberofPeaks, 1:FirstNumber), NumberofPeaks*FirstNumber, 1);

if strcmp(DyeType, 'cy235') == 1
    EachTotal_23_g = tempDonor2_g + tempAcceptor_g;
    EachTotal_23_g = (EachTotal_23_g~=0).*EachTotal_23_g + (EachTotal_23_g==0)*1;	% remove zeros
    EachTotal_123_b = tempDonor_b + tempDonor2_b + tempAcceptor_b;
    EachTotal_123_b = (EachTotal_123_b~=0).*EachTotal_123_b + (EachTotal_123_b==0)*1;	% remove zeros
    
    E_level_23 = tempAcceptor_g./EachTotal_23_g;
    E_level_12 = tempDonor2_b./((1-E_level_23).*tempDonor_b + tempDonor2_b);
    E_level_13 = (tempAcceptor_b - E_level_23.*(tempDonor2_b + tempAcceptor_b))./(tempDonor_b + tempAcceptor_b - E_level_23.*(EachTotal_123_b));
    if Is_Avg_and_E_save =='y'
        E_level_output_b = [E_level_b EachTotal_b];
        E_level_output_g = [E_level_g EachTotal_g];
        save([filename_head '_elevel_10p_b.dat'],'E_level_output_b','-ascii');
        save([filename_head '_elevel_10p_g.dat'],'E_level_output_g','-ascii');
    end
end

figure('Name','Raw data analysis');
hdl2 = gcf;

subplot(3,4,1); % 2*3 figure_ upper left (the last number shows the location of figure)
hist(E_level_12,-0.1:0.02:1.1); % histogram for first 10 point with the number of 50 shows the bin size
temp=axis;
temp(1)=-0.1;
temp(2)=1.1;
axis(temp);
title([ 'first ' num2str(FirstNumber) 'Raw Cy3-Cy5 FRET histogram' ]);
zoom on;

subplot(3,4,2); % 2*3 figure_ upper left (the last number shows the location of figure)
hist(E_level_13,-0.1:0.02:1.1); % histogram for first 10 point with the number of 50 shows the bin size
temp=axis;
temp(1)=-0.1;
temp(2)=1.1;
axis(temp);
title([ 'first ' num2str(FirstNumber) 'Raw Cy3-Cy7 FRET histogram' ]);
zoom on;

subplot(3,4,3); % 2*3 figure_ upper left (the last number shows the location of figure)
hist(E_level_23,-0.1:0.02:1.1); % histogram for first 10 point with the number of 50 shows the bin size
temp=axis;
temp(1)=-0.1;
temp(2)=1.1;
axis(temp);
title([ 'first ' num2str(FirstNumber) 'Raw Cy5-Cy7 FRET histogram' ]);
zoom on;

subplot(3,4,4);
hist(EachTotal_123_b,-100:50:4000);
temp=axis;
temp(1)=-100;
temp(2)=4000;
axis(temp);
title([ 'first ' num2str(FirstNumber) 'Raw Total intensity histogram' ]);
zoom on;

subplot(2,2,3);
plot(E_level_12, EachTotal_123_b,'b+', 'MarkerSize', 2);
temp=axis;
temp(1)=-0.1;
temp(2)=1.1;
temp(3)=-100;
temp(4)=4000;
axis(temp);
xlabel('FRET');
ylabel('Total intensity on green ex');
title([ 'first ' num2str(FirstNumber) 'Raw Total Intensity vs FRET' ]);
zoom on;

DonorFirstData_g = reshape(DonorRawData_g(1:NumberofPeaks, 1:FirstNumber), NumberofPeaks*FirstNumber, 1);
Donor2FirstData_g = reshape(Donor2RawData_g(1:NumberofPeaks, 1:FirstNumber), NumberofPeaks*FirstNumber, 1);
AcceptorFirstData_g = reshape(AcceptorRawData_g(1:NumberofPeaks, 1:FirstNumber), NumberofPeaks*FirstNumber, 1);
DonorLastData_g = reshape(DonorRawData_g(1:NumberofPeaks, (time_length_each + 1 - LastNumber):time_length_each), NumberofPeaks*LastNumber, 1);
Donor2LastData_g = reshape(Donor2RawData_g(1:NumberofPeaks, (time_length_each + 1 - LastNumber):time_length_each), NumberofPeaks*LastNumber, 1);
AcceptorLastData_g = reshape(AcceptorRawData_g(1:NumberofPeaks, (time_length_each + 1 - LastNumber):time_length_each), NumberofPeaks*LastNumber, 1);
DonorFirstData_r = reshape(DonorRawData_r(1:NumberofPeaks, 1:FirstNumber), NumberofPeaks*FirstNumber, 1);
Donor2FirstData_r = reshape(Donor2RawData_r(1:NumberofPeaks, 1:FirstNumber), NumberofPeaks*FirstNumber, 1);
AcceptorFirstData_r = reshape(AcceptorRawData_r(1:NumberofPeaks, 1:FirstNumber), NumberofPeaks*FirstNumber, 1);
DonorLastData_r = reshape(DonorRawData_r(1:NumberofPeaks, (time_length_each + 1 - LastNumber):time_length_each), NumberofPeaks*LastNumber, 1);
Donor2LastData_r = reshape(Donor2RawData_r(1:NumberofPeaks, (time_length_each + 1 - LastNumber):time_length_each), NumberofPeaks*LastNumber, 1);
AcceptorLastData_r = reshape(AcceptorRawData_r(1:NumberofPeaks, (time_length_each + 1 - LastNumber):time_length_each), NumberofPeaks*LastNumber, 1);

subplot(5,4,11);
hist(DonorFirstData_g,-300:5:2000);
temp=axis;
temp(1)=-300;
temp(2)=2000;
axis(temp);
title([ 'First ' num2str(FirstNumber) 'raw Cy3']);
zoom on;

subplot(5,4,12);
hist(DonorLastData_g,-300:5:2000);
temp=axis;
temp(1)=-300;
temp(2)=2000;
axis(temp);
title([ 'Last ' num2str(LastNumber) 'raw Cy3']);
zoom on;

subplot(5,4,15);
hist(Donor2FirstData_g,-300:5:2000);
temp=axis;
temp(1)=-300;
temp(2)=2000;
axis(temp);
title([ 'First ' num2str(FirstNumber) 'raw Cy5']);
zoom on;

subplot(5,4,16);
hist(Donor2LastData_g,-300:5:2000);
temp=axis;
temp(1)=-300;
temp(2)=2000;
axis(temp);
title([ 'Last ' num2str(LastNumber) 'raw Cy5']);
zoom on;

subplot(5,4,19);
hist(AcceptorFirstData_g,-300:5:2000);
temp=axis;
temp(1)=-300;
temp(2)=2000;
axis(temp);
title([ 'First ' num2str(FirstNumber) 'raw Cy7']);
zoom on;

subplot(5,4,20);
hist(AcceptorLastData_g,-300:5:2000);
temp=axis;
temp(1)=-300;
temp(2)=2000;
axis(temp);
title([ 'Last ' num2str(LastNumber) 'raw Cy7']);
zoom on;


figure('Name','Raw data analysis additional part');
hdl_add = gcf;

subplot(2,2,1);
plot(E_level_12, EachTotal_123_b,'b+', 'MarkerSize', 2);
temp=axis;
temp(1)=-0.1;
temp(2)=1.1;
temp(3)=-100;
temp(4)=4000;
axis(temp);
title([ 'First ' num2str(FirstNumber) ' raw 357 vs 3-5 FRET' ]);
zoom on;


subplot(2,2,3);
plot(Donor2FirstData_g, DonorFirstData_g,'b+', 'MarkerSize', 2);
temp=axis;
temp(1)=-100;
temp(2)=3000;
temp(3)=-100;
temp(4)=3000;
axis(temp);
title([ 'First ' num2str(FirstNumber) 'raw Cy7 vs Cy5 red ex ' ]);
zoom on;

DonorFirstData_g_after = reshape(DonorRawData_g(1:NumberofPeaks, 2:(FirstNumber+1)), NumberofPeaks*FirstNumber, 1);
DonorFirstData_g_before = reshape(DonorRawData_g(1:NumberofPeaks, 1:FirstNumber), NumberofPeaks*FirstNumber, 1);
Donor2FirstData_g_after = reshape(Donor2RawData_g(1:NumberofPeaks, 2:(FirstNumber+1)), NumberofPeaks*FirstNumber, 1);
Donor2FirstData_g_before = reshape(Donor2RawData_g(1:NumberofPeaks, 1:FirstNumber), NumberofPeaks*FirstNumber, 1);

E_level_12_after = Donor2FirstData_g_after./(Donor2FirstData_g_after + DonorFirstData_g_after);
E_level_12_before = Donor2FirstData_g_before./(Donor2FirstData_g_before + DonorFirstData_g_before);

E_level_12_onestep = [E_level_12(end)' E_level_12(1:(end-1))'];
subplot(2,2,2);
plot(E_level_12_before, E_level_12_after,'b+', 'MarkerSize', 2);
temp=axis;
temp(1)=-0.1;
temp(2)=1.1;
temp(3)=-0.1;
temp(4)=1.1;
axis(temp);
title([ 'First ' num2str(FirstNumber) ' steps' ]);
zoom on;


%% Start to servey
%Temptime = [];
%TempFret = [];
%TempDonor = [];
%TempAcceptor = [];
% TempFret12 = [];
% TempFret13 = [];
% TempFret23 = [];
% TempDonor_b = [];
% TempDonor2_b = [];
% TempAcceptor_b = [];
% TempDonor_g = [];
% TempDonor2_g = [];
% TempAcceptor_g = [];
% TempDonor_r = [];
% TempDonor2_r= [];
% TempAcceptor_r = [];
r12_list = [];
r13_list = [];
r23_list = [];
l12_list = [];
l13_list = [];
l23_list = [];
dd2ac_list = [];
t_list = -1 * ones(NumberofPeaks, 1);
DT1=[];DT2=[];DT3=[];
DT1a=[];DT2a=[];DT3a=[];
DT1d=[];DT2d=[];DT3d=[];
DT1f=[];DT2f=[];DT3f=[];
DT1id = []; DT2id = []; DT3id = [];
FirstSelectX=[];
FirstSelectY=[];
LastSelectX=[];
LastSelectY=[];

scrsz = get(0,'ScreenSize');
figure('Name','Trace analysis','OuterPosition',[scrsz(4)/2 0.05*scrsz(4) scrsz(4)+300 0.95*scrsz(4)]);
hdl_trace=gcf;

i=0;
prev_i = -1;
history_n = 0;
history = zeros(1000, 1, 'int16');
firstpoint = 1;
lastpoint = time_length_each;
junk=zeros(NumberofPeaks, 1);

% Display traces

while i < NumberofPeaks

    i = i + 1;
    
%     if prev_i ~= i
%         corrected = false;
%     end
    
    if ColorNumber == 3
        if strcmp(DyeType, 'cy235') == 1
            DonorCorrect_b = ((1 + leakage12 + leakage13) / (1 - leakage12 * leakage21)) * ((DonorRawData_b(i,:) - dbackground_b_temp) - leakage21 * (Donor2RawData_g(i,:) - d2background_b_temp));
            Donor2Correct_b = gamma12 * ((1 + leakage21 + leakage23) / (1 - leakage12 * leakage21)) * ((Donor2RawData_b(i,:) - d2background_b_temp) - leakage12 * (DonorRawData_b(i,:) - dbackground_b_temp));
            AcceptorCorrect_b = gamma13 * ((AcceptorRawData_b(i,:) - abackground_b_temp) - ((leakage23 * leakage12 - leakage13)/(1 - leakage12 * leakage21)) * (DonorRawData_b(i,:) - dbackground_b_temp) + ((leakage13 * leakage21 - leakage23 ) / (1 - leakage12 * leakage21)) * (Donor2RawData_b(i,:) -d2background_b_temp));
            EachTotalCorrect_b = DonorCorrect_b + Donor2Correct_b + AcceptorCorrect_b;
            EachTotalCorrect_b = (EachTotalCorrect_b~=0).*EachTotalCorrect_b + (EachTotalCorrect_b==0)*1;	% remove zeros
            
            DonorCorrect_g = ((1 + leakage12 + leakage13) / (1 - leakage12 * leakage21)) * ((DonorRawData_g(i,:) - dbackground_g_temp) - leakage21 * (Donor2RawData_g(i,:) - d2background_g_temp));
            Donor2Correct_g = gamma12 * ((1 + leakage21 + leakage23) / (1 - leakage12 * leakage21)) * ((Donor2RawData_g(i,:) - d2background_g_temp) - leakage12 * (DonorRawData_g(i,:) - dbackground_g_temp));
            AcceptorCorrect_g = gamma13 * ((AcceptorRawData_g(i,:) - abackground_g_temp) - ((leakage23 * leakage12 - leakage13)/(1 - leakage12 * leakage21)) * (DonorRawData_g(i,:) - dbackground_g_temp) + ((leakage13 * leakage21 - leakage23 ) / (1 - leakage12 * leakage21)) * (Donor2RawData_g(i,:) -d2background_g_temp));
            AcceptorCorrect_g = AcceptorCorrect_g - direct * (Donor2Correct_g + AcceptorCorrect_g);
            EachTotalCorrect_g = Donor2Correct_g + AcceptorCorrect_g;
            EachTotalCorrect_g = (EachTotalCorrect_g~=0).*EachTotalCorrect_g + (EachTotalCorrect_g==0)*1;	% remove zeros
            
            DonorCorrect_r = DonorRawData_r(i,:);
            Donor2Correct_r = Donor2RawData_r(i,:);
            AcceptorCorrect_r = AcceptorRawData_r(i,:);
            EachTotalCorrect_r = AcceptorCorrect_r;
            EachTotalCorrect_r = (EachTotalCorrect_r~=0).*EachTotalCorrect_r + (EachTotalCorrect_r==0)*1;	% remove zeros
            
            Fret23 = AcceptorCorrect_g./EachTotalCorrect_g;
            Fret12 = Donor2Correct_b./((1-Fret23).*DonorCorrect_b + Donor2Correct_b);
            Fret13 = (AcceptorCorrect_b - Fret23.*(Donor2Correct_b + AcceptorCorrect_b))./(DonorCorrect_b + AcceptorCorrect_b - Fret23 .* (EachTotalCorrect_b));
            %corrected = true;
        end
    end
    
    for j=2:time_length_each
        if (Fret13(j) < -0.2)
            Fret13(j) = 0;
        elseif (Fret13(j) > 1.2)
            Fret13(j) = 1;
        end
        if(Fret12(j) < -0.2)
            Fret12(j) = 0;
        elseif(Fret12(j) > 1.2)
            Fret12(j) = 1;
        end
        if(Fret23(j) < -0.2)
            Fret23(j) = 0;
        elseif(Fret23(j) > 1.2)
            Fret23(j) = 1;
        end
    end
    
    prev_i = i;

    % Trace window
    % green laser excitation corrected trace
    figure(hdl_trace);
    subplot('position',[0.1 0.84 0.8 0.1]); 
    plot(time_b, DonorCorrect_b, 'g', time_b, Donor2Correct_b, 'r', time_b, AcceptorCorrect_b, 'm');
    hold on
    plot(time_b, DonorCorrect_b + Donor2Correct_b + AcceptorCorrect_b + 300, 'k');
    hold off
    temp=axis;
    temp(3)=BottomLimit_b;
    temp(4)=UpperLimit_b;
    grid on;
    axis(temp);
    title(['Green Laser Molecule ' num2str(i) '  / ' num2str(NumberofPeaks) ' File ' filename_head], 'Interpreter', 'none');
    ylabel('Intensity');
    zoom on;
    set(gca, 'FontSize', 12);
    
    % red laser excitation corrected trace
    subplot('position',[0.1 0.68 0.8 0.1]); 
    plot(time_g, DonorCorrect_g, 'g', time_g, Donor2Correct_g, 'r', time_g, AcceptorCorrect_g, 'm');
    temp=axis;
    temp(3)=BottomLimit_g;
    temp(4)=UpperLimit_g;
    grid on;
    axis(temp);
    title(['Red Laser Molecule ' num2str(i) '  / ' num2str(NumberofPeaks) ' File ' filename_head], 'Interpreter', 'none');
    zoom on;
    ylabel('Intensity');
    set(gca, 'FontSize', 12);
    
    % 750 laser excitation corrected trace
    subplot('position',[0.1 0.52 0.8 0.1]);
    plot(time_g, DonorCorrect_r, 'g', time_g, Donor2Correct_r, 'r', time_g, AcceptorCorrect_r, 'm');
    temp=axis;
    temp(3)=BottomLimit_r;
    temp(4)=UpperLimit_r;
    grid on;
    axis(temp);
    title(['750 Laser Molecule ' num2str(i) '  / ' num2str(NumberofPeaks) ' File ' filename_head], 'Interpreter', 'none');
    zoom on;
    ylabel('Intensity');
    set(gca, 'FontSize', 12);
    
    subplot('position',[0.1 0.36 0.8 0.1]);
    %	FretEc=(1./(1+gamma*(donorcorrect(i,:)./acceptorcorrect(i,:))));
    hFretLine = plot(time_g(firstpoint:lastpoint), Fret12(firstpoint:lastpoint), FirstSelectX, FirstSelectY, LastSelectX, LastSelectY, bintime, binEcorrect, 'k');
    temp=axis;
    temp(3)=-0.1;
    temp(4)=1.1;
    axis(temp);
    grid on;
    zoom on;
    title('Cy3 Cy5 FRET');
    ylabel('FRET');
    set(gca, 'FontSize', 12);
    
    subplot('position',[0.93 0.36 0.03 0.1]);
    x = -0.1:0.05:1.1;
    [hX,hN]=hist(Fret12(firstpoint:lastpoint),x);
    barh(hN,hX,'k');
    temp=axis;
    temp(3)=-0.1;
    temp(4)=1.1;
    axis(temp);
    xlabel('Count');
    grid on;
    axis on;
    zoom on;
    
    subplot('position',[0.1 0.20 0.8 0.1]);
    plot(time_g(firstpoint:lastpoint), Fret13(firstpoint:lastpoint), bintime, binEraw, 'k');
    temp=axis;
    temp(3)=-0.1;
    temp(4)=1.1;
    axis(temp);
    grid on;
    zoom on;
    title('Cy3 Cy7 FRET');
    ylabel('FRET');
    set(gca, 'FontSize', 12);
    
    subplot('position',[0.93 0.20 0.03 0.1]);
    x = -0.1:0.05:1.1;
    [hX,hN]=hist(Fret13(firstpoint:lastpoint),x);
    barh(hN,hX,'k');
    temp=axis;
    temp(3)=-0.1;
    temp(4)=1.1;
    axis(temp);
    xlabel('Count');
    grid on;
    axis on;
    zoom on;
    
    subplot('position', [0.1 0.04 0.8 0.1]);
    plot(time_g(firstpoint:lastpoint), Fret23(firstpoint:lastpoint), bintime, binEraw, 'k');
    temp=axis;
    temp(3)=-0.1;
    temp(4)=1.1;
    axis(temp)
    grid on;
    zoom on;
    title('Cy5 Cy7 FRET');
    ylabel('FRET');
    xlabel('Time (s)');
    set(gca, 'FontSize', 12);
    
    subplot('position',[0.93 0.04 0.03 0.1]);
    x = -0.1:0.05:1.1;
    [hX,hN]=hist(Fret23(firstpoint:lastpoint),x);
    barh(hN,hX,'k');
    temp=axis;
    temp(3)=-0.1;
    temp(4)=1.1;
    axis(temp);
    xlabel('Count');
    grid on;
    axis on;
    zoom on;

    if DoseMovieNeed == 'y'
        fileid_movie = fopen([filename_head '.' num2str(ColorNumber) 'color_3alex_movies'], 'r');
        %startpoint = uint32(4 + (i-1)*ColorNumber*peak_height) + color_order*peak_height*peaks_total_width;
        Xpoint = 6;
        startpoint = 4 + uint32((i-1)*ColorNumber*peak_height) + 3*(uint32(Xpoint/3)-1)*peak_height*peaks_total_width + 0*peak_height*peaks_total_width;
        for j=1:peak_height
            fseek(fileid_movie, startpoint , 'bof');
            peak_line=fread(fileid_movie, peak_height*ColorNumber, 'uint8');
            peak(1:peak_height*ColorNumber, j) = peak_line(1:peak_height*ColorNumber);
            startpoint = startpoint + peaks_total_width;
        end
        fclose(fileid_movie);
        
        subplot('position',[0.93 0.80 0.05 0.18]);
        colormap(hot);
        image(peak);
        axis off;
        zoom on;
        title(['frame: ' num2str(Xpoint) '  time ' num2str(Xpoint*timeunit)]);
        
        fileid_movie = fopen([filename_head '.' num2str(ColorNumber) 'color_3alex_movies'], 'r');
        %startpoint = uint32(4 + (i-1)*ColorNumber*peak_height) + (1-color_order)*peak_height*peaks_total_width;
        startpoint = 4 + uint32((i-1)*ColorNumber*peak_height) + 3*(uint32(Xpoint/3)-1)*peak_height*peaks_total_width + 1*peak_height*peaks_total_width;
        for j=1:peak_height
            fseek(fileid_movie, startpoint , 'bof');
            peak_line=fread(fileid_movie, peak_height*ColorNumber, 'uint8');
            peak(1:peak_height*ColorNumber, j) = peak_line(1:peak_height*ColorNumber);
            startpoint = startpoint + peaks_total_width;
        end
        fclose(fileid_movie);
        
        subplot('position',[0.93 0.60 0.05 0.18]);
        colormap(hot);
        image(peak);
        axis off;
        zoom on;
        title(['frame: ' num2str(Xpoint) '  time ' num2str(Xpoint*timeunit)]);
        
        fileid_movie = fopen([filename_head '.' num2str(ColorNumber) 'color_3alex_movies'], 'r');
        %startpoint = uint32(4 + (i-1)*ColorNumber*peak_height) + (1-color_order)*peak_height*peaks_total_width;
        startpoint = 4 + uint32((i-1)*ColorNumber*peak_height) + 3*(uint32(Xpoint/3)-1)*peak_height*peaks_total_width + 2*peak_height*peaks_total_width;
        for j=1:peak_height
            fseek(fileid_movie, startpoint , 'bof');
            peak_line=fread(fileid_movie, peak_height*ColorNumber, 'uint8');
            peak(1:peak_height*ColorNumber, j) = peak_line(1:peak_height*ColorNumber);
            startpoint = startpoint + peaks_total_width;
        end
        fclose(fileid_movie);
        
        subplot('position',[0.93 0.40 0.05 0.18]);
        colormap(hot);
        image(peak);
        axis off;
        zoom on;
        title(['frame: ' num2str(Xpoint) '  time ' num2str(Xpoint*timeunit)]);
    end


    disp([num2str(i) ' (l=save select, s=save region, h=histogram select, t=terminate program, b=back, g=go, c=choose time range for fret hist, j=count as junk)']);
    keyanswer =input('(r=calculate gamma, o=subtract background, k=calculate leakage, i=calculate direction cy7 excitation, p=collect photobleaching time, d=collect dwell times, n=subtract background for green excitation only) : ','s');
    answer = sscanf(keyanswer, '%s %*s');
    numberofanswer = sscanf(keyanswer, '%*s %f');
    
    if answer == 'o' % subtract background
        
        [raw_x, ~] = ginput(2);
        x = round(raw_x / (3*timeunit));
        dbackground_b_temp = mean(DonorRawData_b(i, x(1):x(2)));
        d2background_b_temp = mean(Donor2RawData_b(i, x(1):x(2)));
        abackground_b_temp = mean(AcceptorRawData_b(i, x(1):x(2)));
        
        dbackground_g_temp = mean(DonorRawData_g(i, x(1):x(2)));
        d2background_g_temp = mean(Donor2RawData_g(i, x(1):x(2)));
        abackground_g_temp = mean(AcceptorRawData_g(i, x(1):x(2)));
        
        dbackground_r_temp = mean(DonorRawData_r(i, x(1):x(2)));
        d2background_r_temp = mean(Donor2RawData_r(i, x(1):x(2)));
        abackground_r_temp = mean(AcceptorRawData_r(i, x(1):x(2)));
        
%         DonorCorrect_b = DonorCorrect_b - d1d1_bg;
%         Donor2Correct_b = Donor2Correct_b - d1d2_bg;
%         AcceptorCorrect_b = AcceptorCorrect_b - d1ac_bg;
%         
%         DonorCorrect_g = DonorCorrect_g - d2d1_bg;
%         Donor2Correct_g = Donor2Correct_g - d2d2_bg;
%         AcceptorCorrect_g = AcceptorCorrect_g - d2ac_bg;
%         
%         DonorCorrect_r = DonorCorrect_r - acd1_bg;
%         Donor2Correct_r = Donor2Correct_r - acd2_bg;
%         AcceptorCorrect_r = AcceptorCorrect_r - acac_bg;
% 
%         Fret23 = AcceptorCorrect_g./EachTotalCorrect_g;
%         Fret12 = Donor2Correct_b./((1-Fret23).*DonorCorrect_b + Donor2Correct_b);
%         Fret13 = (AcceptorCorrect_b - Fret23.*(Donor2Correct_b + AcceptorCorrect_b))./(DonorCorrect_b + AcceptorCorrect_b - Fret23 .* (EachTotalCorrect_b));
        
        i = i - 1;

        continue; 
    end
    
    if answer == 'n' % subtract background for green excitation only
        
        [raw_x, ~] = ginput(2);
        x = round(raw_x / (3*timeunit));
        dbackground_b_temp = mean(DonorRawData_b(i, x(1):x(2)));
        d2background_b_temp = mean(Donor2RawData_b(i, x(1):x(2)));
        abackground_b_temp = mean(AcceptorRawData_b(i, x(1):x(2)));
%         disp(d1d1_bg);
%         disp(d1d2_bg);
%         disp(d1ac_bg);
        
%         DonorCorrect_b = DonorCorrect_b - d1d1_bg;
%         Donor2Correct_b = Donor2Correct_b - d1d2_bg;
%         AcceptorCorrect_b = AcceptorCorrect_b - d1ac_bg;
% 
%         Fret12 = Donor2Correct_b./((1-Fret23).*DonorCorrect_b + Donor2Correct_b);
%         Fret13 = (AcceptorCorrect_b - Fret23.*(Donor2Correct_b + AcceptorCorrect_b))./(DonorCorrect_b + AcceptorCorrect_b - Fret23 .* (EachTotalCorrect_b));
        i = i - 1;

        continue; 
    end
    
    if answer == 'h' % histogram select
        again=1;
        [Xc,~] = ginput(1);
        firstpoint = round(Xc(1)/(2*timeunit));
        
        subplot('position',[0.1 0.42 0.8 0.15]);
        %fretEc=(1./(1+gamma*(donorcorrect(i,:)./acceptorcorrect(i,:))));
        
        FirstSelectX=[Xc Xc];
        FirstSelectY=[-2 +2];
        plot(time_g, Fret12, FirstSelectX, FirstSelectY, bintime, binEcorrect, 'k');
        temp=axis;
        temp(3)=-0.1;
        temp(4)=1.1;
        axis(temp);
        grid on;
        zoom on;
        
        [Xc,~] = ginput(1);
        lastpoint = round(Xc(1)/(2*timeunit));
        
        subplot('position',[0.1 0.42 0.8 0.15]);
        LastSelectX=[Xc Xc];
        LastSelectY=[-2 +2];
        plot(time_g, Fret12, FirstSelectX, FirstSelectY, LastSelectX, LastSelectY, bintime, binEcorrect, 'k');
        temp=axis;
        temp(3)=-0.1;
        temp(4)=1.1;
        axis(temp);
        grid on;
        zoom on;
        
        if firstpoint>lastpoint
            temp=lastpoint;
            lastpoint=firstpoint;
            firstpoint=temp;
        end
        
        disp(firstpoint);
        disp(lastpoint);
        subplot('position',[0.93 0.42 0.06 0.15]);
        x = -0.1:0.02:1.1;
        [hX,hN]=hist(Fret12(firstpoint:lastpoint),x);
        barh(hN,hX,'k');
        temp=axis;
        temp(3)=-0.1;
        temp(4)=1.1;
        axis(temp);
        grid on;
        axis on;
        zoom on; 
    end
    
    if answer == 's'  % save region data
        again=1;
        filename_add_region = sprintf('%s_trace_%i.dat', filename_head, i); %XXX
        fprintf('%s\n', filename_add_region);
        fid = fopen(filename_add_region, 'w');
        fprintf(fid, ' dbackground_g d2background_g abackground_g dbackground_r d2background_r abackground_r leakage12 leakage21 leakage13 leakage23 gamma12 gamma13 direct \n');
        fprintf(fid, '%f %f %f %f %f  %f %f %f %f %f  %f %f %f \n', dbackground_g, d2background_g, abackground_g, dbackground_r, d2background_r, abackground_r, leakage12, leakage21, leakage13, leakage23, gamma12, gamma13, direct);
        fprintf(fid, ' number firstpoint lastpoint length \n');
        output = double([ Temp_i; Tempfirstpoint; Templastpoint; Templength]);
        fprintf(fid, '%f %f %f %f \n', output);
        fclose(fid);
        
        output = [ Temptime_region' TempFret12_region' TempFret13_region' TempFret23_region' TempDonor_g_region' TempDonor2_g_region' TempAcceptor_g_region' TempDonor_r_region' TempDonor2_r_region' TempAcceptor_r_region'];
        save(filename_add_region_data,'output','-ascii');
    end
    
    if answer == 'c'
        [Xc, ~, ~] = ginput(2);
        firstpoint = round(Xc(1)/(3*timeunit));
        lastpoint = round(Xc(2)/(3*timeunit));
        disp(firstpoint);
        disp(lastpoint);
        i = i - 1;
        continue;
    end
    
    if answer == 'j'
        junk(i) = 1;
    end
    
    if answer == 'l' % save select
%         [Xc, ~, ~] = ginput(2);
%         if (Xc(1)>Xc(2))
%             temp = Xc(1);
%             Xc(1) = Xc(2);
%             Xc(2) = temp;
%         end
%         firstpoint = round(Xc(1)/(3*timeunit));
%         lastpoint = round(Xc(2)/(3*timeunit));
%         disp(firstpoint);
%         disp(lastpoint);
        firstpoint = 1;
        lastpoint = length(time_g);
        Temptime = time_g(firstpoint:lastpoint);
        TempFret12 = Fret12(firstpoint:lastpoint);
        TempFret13 = Fret13(firstpoint:lastpoint);
        TempFret23 = Fret23(firstpoint:lastpoint);
        TempDonor_b = DonorCorrect_b(firstpoint:lastpoint);
        TempDonor2_b = Donor2Correct_b(firstpoint:lastpoint);
        TempAcceptor_b = AcceptorCorrect_b(firstpoint:lastpoint);
        TempDonor_g = DonorCorrect_g(firstpoint:lastpoint);
        TempDonor2_g = Donor2Correct_g(firstpoint:lastpoint);
        TempAcceptor_g = AcceptorCorrect_g(firstpoint:lastpoint);
        TempDonor_r = DonorCorrect_r(firstpoint:lastpoint);
        TempDonor2_r = Donor2Correct_r(firstpoint:lastpoint);
        TempAcceptor_r = AcceptorCorrect_r(firstpoint:lastpoint);
        output = [ Temptime' TempFret12' TempFret13' TempFret23' ...
            TempDonor_b' TempDonor2_b' TempAcceptor_b' ...
            TempDonor_g' TempDonor2_g' TempAcceptor_g' ...
            TempDonor_r' TempDonor2_r' TempAcceptor_r' ...
            DonorRawData_b(i, :)' Donor2RawData_b(i, :)' AcceptorRawData_b(i, :)' ...
            DonorRawData_g(i, :)' Donor2RawData_g(i, :)' AcceptorRawData_g(i, :)' ...
            DonorRawData_r(i, :)' Donor2RawData_r(i, :)' AcceptorRawData_r(i, :)'];
        file_outname = sprintf('%s_%s_trace_%i.dat', folder_prefix, filename_head, i);
        save(file_outname,'output','-ascii');
    end
    
    if answer == 'r' % calculate gamma factor

        [raw_x, ~] = ginput(4);
        x = round(raw_x / (3 * timeunit));

        % average intensities before change point
        
        d1d1_bef = mean(DonorCorrect_b(x(1):x(2)));
        d1d2_bef = mean(Donor2Correct_b(x(1):x(2)));
        d1ac_bef = mean(AcceptorCorrect_b(x(1):x(2)));
        
        d2d2_bef = mean(Donor2Correct_g(x(1):x(2)));
        d2ac_bef = mean(AcceptorCorrect_g(x(1):x(2)));
        
        d1d1_aft = mean(DonorCorrect_b(x(3):x(4)));
        d1d2_aft = mean(Donor2Correct_b(x(3):x(4)));
        d1ac_aft = mean(AcceptorCorrect_b(x(3):x(4)));
        
        d2d2_aft = mean(Donor2Correct_g(x(3):x(4)));
        d2ac_aft = mean(AcceptorCorrect_g(x(3):x(4)));
        
        delta_d1d1 = d1d1_aft - d1d1_bef;
        delta_d1d2 = d1d2_aft - d1d2_bef;
        delta_d1ac = d1ac_aft - d1ac_bef;
        
        delta_d2d2 = d2d2_aft - d2d2_bef;
        delta_d2ac = d2ac_aft - d2ac_bef;
        
        r12 = (-1) * delta_d1d1 / delta_d1d2;
        r13 = (-1) * delta_d1d1 / delta_d1ac;
        r23 = (-1) * delta_d2d2 / delta_d2ac;
        
        r12_list = [r12_list r12]; %#ok<*AGROW>
        r13_list = [r13_list r13];
        r23_list = [r23_list r23];
    end
    
    if answer == 'k' % calculate leakage
        [raw_x, ~] = ginput(2);
        x = round(raw_x / (3 * timeunit));
        d1d1 = mean(DonorCorrect_b(x(1):x(2)));
        d1d2 = mean(Donor2Correct_b(x(1):x(2)));
        d1ac = mean(AcceptorCorrect_b(x(1):x(2)));
        
        d2d2 = mean(Donor2Correct_g(x(1):x(2)));
        d2ac = mean(AcceptorCorrect_g(x(1):x(2)));
        
        l12 = d1d2 / d1d1;
        l13 = d1ac / d1d1;
        l23 = d2ac / d2d2;
        
        l12_list = [l12_list l12];
        l13_list = [l13_list l13];
        l23_list = [l23_list l23];
        
        fprintf('Leakage for this trace: l12 = %.2f, l13 = %.2f, l23 = %.2f', l12, l13, l23);
    end
    
    if answer == 'i' % calculate direct excitation of cy7 by the red laser
        [raw_x, ~] = ginput(4);
        x = round(raw_x / (3 * timeunit));
        % average intensities before change point
        d2d2_bef = mean(Donor2Correct_g(x(1):x(2)));
        d2ac_bef = mean(AcceptorCorrect_g(x(1):x(2)));
        
        d2d2_aft = mean(Donor2Correct_g(x(3):x(4)));
        d2ac_aft = mean(AcceptorCorrect_g(x(3):x(4)));
        
        dd2ac = (d2d2_aft + d2ac_aft) / (d2d2_bef + d2ac_bef);
        
        dd2ac_list = [dd2ac_list dd2ac];
    end
      
    if answer == 'p' % photobleaching analysis
        [x, ~] = ginput(1);
        disp(x);
        t_list(i) = x;
    end

    if answer == 'd' % dwell time analysis 
        disp('Click for beginning and end of states.');
        disp('Left/middle/right click for different states.');
        [time,~,button]=ginput;
        
        % left button for saving cy5-cy7 FRET trace
        time1 = time(button == 1);
        for c = 1:2:(sum(button == 1) - 1)
            t1 = ceil(time1(c) / (3 * timeunit));
            t2 = ceil(time1(c+1) / (3 * timeunit));
            dt1 = abs(time1(c+1) - time1(c));
            fprintf('dt1 = %.2f s\n', dt1);
            DT1(end+1) = dt1;
            DT1a(end+1) = mean(AcceptorCorrect_g(t1:t2));
            DT1d(end+1) = mean(Donor2Correct_g(t1:t2));
            DT1f(end+1) = mean(Fret23(t1:t2));
            DT1id(end+1) = i;
        end
        
        % left button for saving cy5-cy7 FRET trace
        time2 = time(button == 2);
        for c = 1:2:(sum(button == 2) - 1)
            t1 = ceil(time2(c) / (3 * timeunit));
            t2 = ceil(time2(c+1) / (3 * timeunit));
            dt2 = abs(time2(c+1) - time2(c));
            fprintf('dt2 = %.2f s\n', dt2);
            DT2(end+1) = dt2;
            DT2a(end+1) = mean(AcceptorCorrect_g(t1:t2));
            DT2d(end+1) = mean(Donor2Correct_g(t1:t2));
            DT2f(end+1) = mean(Fret23(t1:t2));
            DT2id(end+1) = i;
        end
        
        % right button for saving cy3-cy5 FRET trace
        time3 = time(button == 3);
        for c = 1:2:sum(button == 3) - 1
            t1 = ceil(time3(c) / (3 * timeunit));
            t2 = ceil(time3(c+1) / (3 * timeunit));
            dt3 = abs(time3(c+1) - time3(c));
            fprintf('dt3 = %.2f s\n', dt3);
            DT3(end+1) = dt3;
            DT3a(end+1) = mean(Donor2Correct_b(t1:t2));
            DT3d(end+1) = mean(DonorCorrect_b(t1:t2));
            DT3f(end+1) = mean(Fret12(t1:t2));
            DT3id(end+1) = i;
        end
    end
    
    if answer == 'b' % go back
        i = i - 2;
    end

    if answer == 'g'
        answer=input('number to go : ','s');
        gonumber = str2double(answer);
        if gonumber > 0 && gonumber <= NumberofPeaks
            i = gonumber - 1;
        end % go to trace
    end
    
    if answer == 't'
        close all;
        cd(OriginalDirectory);
        break; % terminate and exit
    end
    
    firstpoint = 1;
    lastpoint = time_length_each;

    dbackground_b_temp = dbackground_b;
    d2background_b_temp = d2background_b;
    abackground_b_temp = abackground_b;

    dbackground_g_temp = dbackground_g;
    d2background_g_temp = d2background_g;
    abackground_g_temp = abackground_g;

    dbackground_r_temp = dbackground_r;
    d2background_r_temp = d2background_r;
    abackground_r_temp = abackground_r;
end

%%save region datas
if size(Temp_i)~=0
    fid = fopen(filename_add_region, 'w');
    fprintf(fid, ' dbackground_g d2background_g abackground_g dbackground_r d2background_r abackground_r leakage12 leakage21 leakage13 leakage23 gamma12 gamma13 direct \n');
    fprintf(fid, '%f %f %f %f %f  %f %f %f %f %f  %f %f %f \n', dbackground_g, d2background_g, abackground_g, dbackground_r, d2background_r, abackground_r, leakage12, leakage21, leakage13, leakage23, gamma12, gamma13, direct);
    fprintf(fid, ' number firstpoint lastpoint length \n');
    output = double([ Temp_i; Tempfirstpoint; Templastpoint; Templength]);
    fprintf(fid, '%f %f %f %f \n', output);
    fclose(fid);
    
    output = [ Temptime_region' TempFret12_region' TempFret13_region' TempFret23_region' TempDonor_g_region' TempDonor2_g_region' TempAcceptor_g_region' TempDonor_r_region' TempDonor2_r_region' TempAcceptor_r_region'];
    save(filename_add_region_data,'output','-ascii');
end
%%

disp('Program end.')

cd(OriginalDirectory);

if size(l12_list) ~= 0
    csvwrite('l12.csv', l12_list);
    csvwrite('l13.csv', l13_list);
    csvwrite('l23.csv', l23_list);
end

if size(r12_list) ~= 0
    csvwrite('r12.csv', r12_list);
    csvwrite('r13.csv', r13_list);
    csvwrite('r23.csv', r23_list);
end

if size(dd2ac_list) ~= 0
    csvwrite('direct_d2ac.csv', dd2ac_list);
end

%figure;
%photob_hist = histogram(t_list);
%xlabel('Time');
%ylabel('Count');
%saveas(photob_hist, [filename_head '_photobleaching_curve.png']);
%csvwrite([filename_head '_photobleaching.csv'], t_list);

% save dwell time data

fprintf('Saving dwell time data if there is any...\n');

if ~isempty(DT1)
    DT1=[DT1id;DT1;DT1a;DT1d;DT1f]';
    fname1=[filename_head  '_dwelltime1_effective_unwrapping_fret.dat'];
    save(fname1,'DT1','-ascii','-append');
end
if ~isempty(DT2)
    DT2=[DT2id;DT2;DT2a;DT2d;DT2f]';
    fname1=[filename_head  '_dwelltime2_futile_unwrapping_fret.dat'];
    save(fname1,'DT2','-ascii','-append');
end
if ~isempty(DT3)
    DT3=[DT3id;DT3;DT3a;DT3d;DT3f]';
    fname1=[filename_head  '_dwelltime3_high_cy3_fret.dat'];
    save(fname1,'DT3','-ascii','-append');
end

% saving junk calls

if sum(junk) > 1
   fname_junk = [filename_head '_junk_traces.dat'];
   junk_calls = [(1:NumberofPeaks)' junk];
   save(fname_junk, 'junk_calls', '-ascii');
end

fprintf('Done.\n');

close all;
