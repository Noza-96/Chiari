function[largestComponentMask] = segment_3Dimage_2(myimage, area, delta_thr)
%% Step 1
% built-in function for histogram
% myimage=image_volume_a;
figure()
imagesc(myimage(:,:,31))
max_pixel = max(myimage(:));
nbins = 0:max_pixel+1;
h = histogram(myimage(:), nbins);
hist_counts = h.Values;

% Convert hist_counts to a 2-column matrix
histogram_3D = zeros(max_pixel+1,2);
histogram_3D (:,1)=0:max_pixel;
histogram_3D(:,2)=hist_counts;

t=sum(hist_counts);   % same as total number of pixels
sigm=[];
% We perform the Otsu's method
for i=1:length(histogram_3D) %calculation with every possible pixel value
    w1=sum(histogram_3D (1:i,2))/t;  %Calculate the weights
    w2=1-w1;
    s1=0;  %calculate the means
    s2=0;
    for n=1:i
        s1=s1+histogram_3D(n,2).*histogram_3D(n,1);
    end
    mu1=s1/sum(histogram_3D(1:i,2));
    for m=i:length(histogram_3D(:,2))
        s2=s2+histogram_3D(m,2).*histogram_3D(m,1);
    end
    mu2=s2/sum(histogram_3D (i:length(histogram_3D(:,2)),2));
    sigm=[sigm; w1*w2*((mu1-mu2)^2)]; % Calculate between class variances
end

thr=find(sigm==max(sigm))-1;

if strcmp(area, 'C2C3')
    thr=thr+delta_thr;
end
% We use a logical to make the mask binary
binaryMask=myimage>thr;
imagesc(binaryMask(:,:,31))


%%
if strcmp(area, 'aqueduct')==1
binaryMask(:,:,:)= (binaryMask(:,:,:).*-1 )+1; %inverse
end

if strcmp(area, 'C2C3')==1
binaryMask(:,:,:)= (binaryMask(:,:,:).*-1 )+1; %inverse
end

figure()
imagesc(binaryMask(:,:,31))

%% Step 2 intermediate step, enhance high intensity values
enhanced_image=myimage;
enhancement_factor_high=5;
%just for a centered region:

if strcmp(area, 'aqueduct')==1
crop_width = size(myimage, 2) / 4; % Adjust as needed
crop_height = size(myimage, 1) /4; % Adjust as needed
crop_x = round((size(myimage, 2) - crop_width) / 2);
crop_y = round((size(myimage, 1) - crop_height) / 1.4); %region un poco más abajo
else %for C2-C3...
    % Define the coordinates of the cropped region in the middle of the image
crop_width = size(myimage, 2) / 1.5; % Adjust as needed
crop_height = size(myimage, 1) / 1.5; % Adjust as needed
crop_x = round((size(myimage, 2) - crop_width) / 2);
crop_y = round((size(myimage, 1) - crop_height) / 2);

end
% Create a binary mask for the cropped region
crop_mask = zeros(size(myimage));
crop_mask(crop_y+1:crop_y+crop_height, crop_x+1:crop_x+crop_width, :) = 1;
figure()
imagesc(crop_mask(:,:,31));
%identify pixels with high intensity within the cropped region
if strcmp(area, 'aqueduct')==1
high_values_in_crop= myimage < thr & crop_mask;
else
    high_values_in_crop= myimage > thr & crop_mask;
end
    
figure()
imagesc(high_values_in_crop(:,:,31));
%multiply only the cropped region by the enhancement factor
enhanced_image=myimage + high_values_in_crop*800;
figure()
imagesc(enhanced_image(:,:,31))


%% Step 3
inv_mask(:,:,:)=high_values_in_crop(:,:,:);
cc = bwconncomp(inv_mask, 26); % 26-connectivity for 3D labeling
labeledImage = labelmatrix(cc);
%% Step 4
%Get all conected component intensities and the number of pixels for each one
%cellfun allows to apply the function numel to the contents of each cell of
%cell array C.
%numel counts the number of elements in a cell array
compSizes = cellfun(@numel,cc.PixelIdxList);
%Extract the intensities (indicesSmall) of components smaller than the threshold
[valuesSmall, indicesSmall] = find(compSizes<thr);
%Create a mask were you make 0 all intensities found in "indicesSmall"
labImageWithoutSmall = labeledImage;
labImageWithoutSmall(ismember(labImageWithoutSmall,indicesSmall))=0;
%Extract the intensities (indicesSmall) of the largest component
[valueMax, indexLargest] = find(compSizes == max(compSizes));
%Create a mask were you make 0 the intensity found in "indexLargest"
Mask_4 = labImageWithoutSmall;

figure
imagesc(Mask_4(:,:,31))

%% Step 4: get the largest component
% Find the index of the largest component
[~, indexLargest] = max(compSizes);
% Get the linear indices of the largest component
largestComponentIndices = cc.PixelIdxList{indexLargest};

% Create a mask for the largest component
largestComponentMask = false(size(labeledImage));
largestComponentMask(largestComponentIndices) = true;

figure
imagesc(largestComponentMask(:,:,31))


%% Step 6
%First row
%Axial
figure
subplot(1,2,1)
imshow(enhanced_image(:,:,31), []);
title('Axial view: Enhanced image for CSF')

%Second row --> Mask 
subplot(1,2,2)
imshow(largestComponentMask(:,:,31), []);
title('Axial view: Mask')

end