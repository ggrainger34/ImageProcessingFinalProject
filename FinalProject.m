%Image Processing for Engineering and Science Specialization - Final
%Project
%
%The task of this project is to analyse video footage of a busy road and
%draw a bounding box around the cars. As well as creating a table for the
%average number of pixels on screen in a given frame.
%
%The program is able to recognise cars even when they are split in half by
%the pole to the left of the frame.
%
%However, the program sometimes struggles to recognise car on the far
%lane. Morphological closing might be too aggressive, sometimes causing the cars on
%the far lane to disappear.

%Load the video
v = VideoReader('RoadTraffic.mp4');

%Write to video
outputVideo = VideoWriter('RoadTrafficAnalysed');
open(outputVideo);

%Calculate the number of frames in the video
numFrames = v.NumFrames;

%Find a fram with no cars
backgroundFrame = read(v, 240);
backgroundFrame = im2gray(backgroundFrame);
backgroundFrame = filter2(fspecial('average',3), backgroundFrame)/255;
backgroundFrame = medfilt2(backgroundFrame);
backgroundFrame = im2uint8(backgroundFrame);

NumberRegions = [];
MeanRegionSize = [];
TotalRegionSize = [];

%Loop through each frame in the video
for i=1:numFrames
    %Convert to grey
    img = im2gray(read(v, i));
    %Blur the image
    img = filter2(fspecial('average',3), img)/255;
    %Filter out noise
    img = medfilt2(img);
    %Convert image format to uint8
    img = im2uint8(img);
    %Work out any differences between the current image and the background
    %This should show us any cars in the image
    difference = abs(im2double(img) - im2double(backgroundFrame));
    %Convert to binary image (black and white)
    difference = imbinarize(difference, 0.1);

    %Perform morphological closing (disk)
    se = strel('disk', 5);
    difference = imclose(difference, se);
    
    %Perform morphological closing (line)
    se = strel('line', 40, 0);
    difference = imclose(difference, se);
    
    %Remove small artifacts
    BW = bwareaopen(difference,2000);

    %Work out the mean region size
    numRegions = height(regionprops(BW,'Area'));
    totalRegionSize = nnz(BW);
    meanRegionSize = totalRegionSize / numRegions;

    %Append this frame to an array
    NumberRegions = [NumberRegions; numRegions];
    MeanRegionSize = [MeanRegionSize; meanRegionSize];
    TotalRegionSize = [TotalRegionSize; totalRegionSize];
    
    %Calculate the bounding box of all cars in the frame
    s = regionprops(BW, 'BoundingBox');
    annotatedImage = img;

    hold on;
    %Loop through each region and draw the bounding box
    for j = 1:length(s)
        bbox = s(j).BoundingBox;
        %rectangle('Position', [currbb(1), currbb(2), currbb(3), currbb(4)], 'EdgeColor', 'g');
        annotatedImage = insertShape(img,"rectangle",bbox,"LineWidth",4);
    end
    hold off;

    writeVideo(outputVideo, annotatedImage);

end

close(outputVideo);

%Create a table of the number of regions, mean region size and total region
%size.
Table = table(NumberRegions, MeanRegionSize, TotalRegionSize);

disp(nnz(Table.NumberRegions > 0))

disp(mode(NumberRegions));

disp(Table.TotalRegionSize(152));

%Work out the average size of a region
totalSum = sum(Table.TotalRegionSize);
averageRegionCount = sum(Table.NumberRegions);
average = totalSum / averageRegionCount;
disp(average);

%For testing
%montage({backgroundFrame, img, difference, BW})