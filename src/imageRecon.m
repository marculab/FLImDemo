
addpath(genpath(pwd))

%% load in data
% root = '';
[DeConfile,DeConpath] = uigetfile([root '\*.mat'],'Please select DeCon file');
[Txtfile,Txtpath] = uigetfile([root '\*.txt'],'Please select text file');
[Posfile,Pospath] = uigetfile([root '\*.mat'],'Please select Segementation Position file');
[videoName,videoPath] = uigetfile([root '\*.avi'],'Please select video file');

%% load in data
load(fullfile(DeConpath,DeConfile))
load(fullfile(Pospath,Posfile))
VideoData = importVideoTextFile(fullfile(Txtpath,Txtfile));
RepRate = Ch1DataObj.laserRepRate;

%% open video and get the last image for augmentation
v = VideoReader(fullfile(videoPath, videoName));
im = read(v,inf);
% im = read(v,1);
figure
image(im)
output.img = im;
%% calculate num of data points
% shift = length(Ch1LT)-(MetaData(end,9)-MetaData(1,9))/1000*120/4;
% shift = round(shift);
shift = 0; %shift need to be 0!

Ch1INTCorr = circshift(Ch1DataObj.Lg_INTsGainCorrected,shift);
Ch1LT = circshift(Ch1DataObj.Lg_LTs,shift);
Ch1SNR = circshift(Ch1DataObj.SNR,shift)';
G1 = circshift(Ch1DataObj.gain,shift);

Ch2INTCorr = circshift(Ch2DataObj.Lg_INTsGainCorrected,shift);
Ch2LT = circshift(Ch2DataObj.Lg_LTs,shift);
Ch2SNR = circshift(Ch2DataObj.SNR,shift)';
G2 = circshift(Ch2DataObj.gain,shift);

Ch3INTCorr = circshift(Ch3DataObj.Lg_INTsGainCorrected,shift);
Ch3LT = circshift(Ch3DataObj.Lg_LTs,shift);
Ch3SNR = circshift(Ch3DataObj.SNR,shift)';
G3 = circshift(Ch3DataObj.gain,shift);

%% repopulate output data mat with interplation
% reset start time to 0
VideoData(:,9) = VideoData(:,9)-VideoData(1,9);

% use segmentation location data
VideoData(:,6:7) = double(pos(:,1:2));

Length = VideoData(end,9);
VideoData(VideoData(:,9)>Length,:) = [];
numOfVideoFrame = size(VideoData,1);
removeFlag = zeros(numOfVideoFrame,1);

%------------remove single 0 lines---------------------------------------%
for i = 1:numOfVideoFrame
    posCurrent = VideoData(i,6)+ VideoData(i,7);
    if posCurrent==0 % if current pos is all 0 check before and after
        if i==1
            posBefore = 1;
            posAfter = VideoData(i+1,6)+ VideoData(i+1,7);
        else if i==numOfVideoFrame
                posBefore = VideoData(i-1,6)+ VideoData(i-1,7);
                posAfter = 1;
            else
                posBefore = VideoData(i-1,6)+ VideoData(i-1,7);
                posAfter = VideoData(i+1,6)+ VideoData(i+1,7);
            end
            removeFlag(i) = posBefore&posAfter;
        end
    end
end
removeIdx = find(removeFlag);
VideoData(removeIdx,:) = [];

% remove all 0 points
temp = VideoData(:,6)+VideoData(:,7);
ZeroIdx = find(temp==0);
VideoData(ZeroIdx,:)=[];

frameNum = 1:size(VideoData,1);
frameNum = frameNum';

time = 0:1:size(Ch1LT,1)-1;
time = time'*1000/RepRate*4;
frameT = VideoData(:,9);
[frameT,ia] = unique(frameT); % find duplicate frame
VideoData = VideoData(ia,:); % remove duplicated data
frameNum = frameNum(ia); % remove duplicated frame
frameIdx = interp1(frameT,frameNum,time);
frameIdx = ceil(frameIdx);
output.frame = frameIdx;
VideoData = [frameNum VideoData];


%% interpolate locations
xx = interp1(VideoData(:,10),VideoData(:,7),time);
xx(isnan(xx))=0; % replace NaN with 0
yy = interp1(VideoData(:,10),VideoData(:,8),time);
yy(isnan(yy))=0; % replace NaN with 0
rr = interp1(VideoData(:,10),VideoData(:,9),time);
rr(isnan(rr)) = 0;
output.xx = xx;
output.yy = yy;
output.rr = rr;
output.lt1 = Ch1LT;
output.int1 = Ch1INTCorr;
output.lt2 = Ch2LT;
output.int2 = Ch2INTCorr;
output.lt3 = Ch3LT;
output.int3 = Ch3INTCorr;
output.snr1 = Ch1SNR;
output.snr2 = Ch2SNR;
output.snr3 = Ch3SNR;
output.gain1 = G1;
output.gain2 = G2;
output.gain3 = G3;

%% save data
cd([root '\Analysis'])
[filepath,name,ext] = fileparts(videoName);
save([name '_ImgRecon.mat'],'output')
disp('Reconstructed image .mat file saved successfully!')
close all
