close all % close all opened figures
clc; % Clear command window.
clearvars; % Get rid of variables from prior run of this m-file.

I=imread('0.65.jpg'); % Read image "0.65" in the current folder

% The user should adjust the sensitivity according to the image and how many object he wants to detect
sensitivity = input('Sensitivity: ');
background = input('Background: '); % 0 for draker background and 1 for lighter background 

% convert image to binary
IB = im2bw(I,sensitivity);

if(background ==1)
    IB=~IB; 
end 
[height, width, ~] = size(I); 
ImageArea = height*width;
% Neglect area with pixels less than 0.001 from image area
IB = bwareaopen(IB,round(ImageArea*0.001)); 
% Fill holes in the detected objects, a hole is a set of background pixels that cannot be reached by filling in 
% the background from the edge of the image. 
IB = imfill(IB,'holes');
imshow(I); 
hold on

[B,L] = bwboundaries(IB,'noholes'); 
stats = regionprops(L,'perimeter','area','extrema','boundingbox','centroid');

for k=1:length(B)
    perimeter=stats(k).Perimeter; %Gets permieter of kth object
    area=stats(k).Area; %Gets area of kth object
  
    roundness = 4*pi*area/perimeter^2; %Rondness
%   Ratio between height and width of bounding box
    if( roundness>=0.96 && min(stats(k).BoundingBox(3),stats(k).BoundingBox(4))/max(stats(k).BoundingBox(3),stats(k).BoundingBox(4)) >=0.9 ) 
         text(stats(k).Centroid(1)-25,stats(k).Centroid(2),'circle','Color','black','FontSize',9,'FontWeight','bold');
         continue;
    end 
    
%   Get 8 extreme points of the kth object in the order: 
%   [top-left top-right right-top right-bottom bottom-right bottom-left left-bottom left-top]
    ExtremPoints = stats(k).Extrema; 
%   Round the extrema points (pixel value must be integer)
    temp = round(ExtremPoints);
%   Remap the coordinates by referring to the minimum values of x and y
    temp(:,1) = temp(:,1) - min(temp(:,1)) + 1;
    temp(:,2) = temp(:,2) - min(temp(:,2)) + 1;
%   Create a zero matrix (black image) for the kth object
    mask = zeros(max(temp(:,1)),max(temp(:,2)));
%   Convert the coordinates of the 8 Extreme Points of the kth object to white pixels
    for  x=1:8  
        mask(temp(x,1),temp(x,2))=1;
    end
%   Create morphological structuring element (disk) with 6 area pixels 
    se = strel('disk',6); 
%   The image dilation technique to group close-by points (clustring)
    mask=imdilate(mask,se);
    
%   Count number of real extrema points in the image (number of corners)
    [Bounds,labeledImage,numberOfCorners] = bwboundaries(mask,'noholes');
    
%   Triangle 
    if(numberOfCorners==3)
        text(stats(k).Centroid(1)-25,stats(k).Centroid(2),'triangle','Color','black','FontSize',9,'FontWeight','bold');
        continue;
    end
    
%   Get centers of detected corners
    measures= regionprops(labeledImage,'Centroid');
    
%   Square / Rectangle
    if(numberOfCorners==4)
        
%       Get 3 distances between the center of a specific corner and the centers of the 3 other corners
        points = [measures(1).Centroid(1),measures(1).Centroid(2); measures(2).Centroid(1),measures(2).Centroid(2)];
        d1 = pdist(points,'euclidean');
        points = [measures(1).Centroid(1),measures(1).Centroid(2); measures(3).Centroid(1),measures(3).Centroid(2)];
        d2 = pdist(points,'euclidean');
        points = [measures(1).Centroid(1),measures(1).Centroid(2); measures(4).Centroid(1),measures(4).Centroid(2)];
        d3 = pdist(points,'euclidean');
        distances = [d1 d2 d3];
        distances = sort(distances); %sort distances
        diagonal = sqrt(distances(1,1).^2 +distances(1,2).^2);
        diagonal_ratio = min(diagonal,distances(1,3))/max(diagonal,distances(1,3));
        
%       Square -> if the 2 min distances are equal (with error of 0.2) & the diagonal (pythagoras)
        if (distances(1,1)/distances(1,2)>=0.8 && diagonal_ratio>=0.95  )
            text(stats(k).Centroid(1)-25,stats(k).Centroid(2),'Square','Color','black','FontSize',9,'FontWeight','bold');
            continue;
        
%       Rectangle -> (pythagoras)
        elseif diagonal_ratio>=0.98
            text(stats(k).Centroid(1)-25,stats(k).Centroid(2),'Rectangle','Color','black','FontSize',9,'FontWeight','bold');
            continue;  
        end
    end 
end
 


