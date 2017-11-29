%GB comments
Step1 100
Step2 100
Step3 100 
Step4 100
Step5 100
Step6 100 
Step7 100 
Step8 100
Overall 100


%% step 1: write a few lines of code or use FIJI to separately save the
% nuclear channel of the image Colony1.tif for segmentation in Ilastik
reader = bfGetReader('48hColony1.tif');
%check channels
reader.getSizeC;
for ii = 1:reader.getSizeC
    chan = reader.getIndex(0,ii-1,0)+1;
    img = bfGetPlane(reader,chan);
    %figure(ii);subplot(2,2,ii);imshow(img,[]);
end
chan = reader.getIndex(0,0,0)+1;
img = bfGetPlane(reader,chan);
%imwrite(img,'Matlab_Dapi.tif','TIFF');

%% step 2: train a classifier on the nuclei
% try to get the get nuclei completely but separe them where you can
% save as both simple segmentation and probabilities

%Adam Howard: this was done in ilastik
%% step 3: use h5read to read your Ilastik simple segmentation
% and display the binary masks produced by Ilastik 
seg1  = h5read('Matlab_Dapi_Simple Segmentation.h5','/exported_data');
% (datasetname = '/exported_data')
% Ilastik has the image transposed relative to matlab
% values are integers corresponding to segmentation classes you defined,
% figure out which value corresponds to nuclei

seg1 = squeeze(seg1 == 2)';

%% step 3.1: show segmentation as overlay on raw data
img = im2double(img);
imgCat = cat(3,imadjust(img),img + 0.4*seg1,imadjust(img));
x = 1;figure(x);imshow(imgCat);

%% step 4: visualize the connected components using label2rgb
% probably a lot of nuclei will be connected into large objects
bwimg = bwlabel(seg1);
seg1_color = label2rgb(bwimg, 'jet','k','shuffle');
x = x+1;figure(x);imshow(seg1_color,[]);


%% step 5: use h5read to read your Ilastik probabilities and visualize
% it will have a channel for each segmentation class you defined
seg2  = h5read('Matlab_Dapi_Probabilities.h5','/exported_data');
seg2 = squeeze(seg2(2,:,:))';

%% step 6: threshold probabilities to separate nuclei better
seg2_thresh = seg2 > 0.97;
seg2_thresh = bwlabel(seg2_thresh);
seg2_color = label2rgb(seg2_thresh,'jet','w','shuffle');
x = x+1; figure(x);imshow(seg2_color,[]);
%% step 7: watershed to fill in the original segmentation (~hysteresis threshold)
outside = ~imdilate(seg1,strel('disk',1));
basin = imcomplement(bwdist(outside));
basin = imimposemin(basin, seg2_thresh | outside);
L = watershed(basin);
x = x+1; figure(x);imshow(L); colormap('jet'); caxis([0 20]);

%% step 8: perform hysteresis thresholding in Ilastik and compare the results
% explain the differences

%seg3  = h5read('Matlab_Dapi_Object Predictions.h5','/exported_data');
%x = x+1; figure(x);imshow(seg3,[]);

%Adam Howard: It is very clear that the ilastick file did a much better job
%distinguishing between nuclei than matlab's watershed algorythm. I
%attribute this to Ilastik's ability to build a scale around a number of
%nucleur characteristics (eg. average object intensity,average object 
%shape, etc.) and use that to build a model instead of relying on the the
%more rigid approach that underlies Matlab's analysis. 
%% step 9: clean up the results more if you have time 
% using bwmorph, imopen, imclose etc

