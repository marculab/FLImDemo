%% IMPORT VIDEO FILE (Use this section for Position Correction)
%Change folder path
cd([root2 '\videos'])
% Specify the video file to load
obj=VideoReader(videoFile); 
% [obj,path] = uigetfile('*.avi');
I=read(obj); % Stores data in variable I
% implay(I,18); 
video_size=size(I);
max_frame=video_size(4);
disp(max_frame)
res_x=video_size(1); 
res_y=video_size(2);

for n=1:max_frame % MAKE SURE TO RESET TO 1:max_frame for new run
    figure(1);
    %set(gcf, 'Position', get(0, 'Screensize'));
    frame_temp=I(:,:,:,n);
    frame_temp=imresize(frame_temp,[res_x res_y]);
    imshow(frame_temp);
    [x,y] = ginput(1);
    A=x>0;
    B=x<res_y;
    C=y>0;
    D=y<res_x;
    Filt=A.*B.*C.*D;
    x=Filt.*x;
    y=Filt.*y;
    X(n)=x;
    Y(n)=y;
    disp(n)
end

pos=[X; Y]';
posname=extractBefore(obj.Name,".avi");
cd([root '\Analysis'])
save ([posname '_pos'], 'pos');
