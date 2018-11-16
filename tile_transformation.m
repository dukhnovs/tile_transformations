function []= tile_transformation()
% tile_transformation() 
% this function applies a random tile tranformation to an image
% the input image is selected via a file explorer when the function is executed
% the transformed image is displayed in a figure and can be saved by the user
    %%  Read in the original image
    % imIn = imread('cameraman.tif'); % this is a way to pre-select an image
    % this allows the user to select an image via a file explorer gui
    [filename, pathname] = uigetfile({'*.jpg;*.tif;*.png;*.gif;*.bmp','All Image Files';...   % browse window
              '*.*','All Files' },'Select an Image',... % set window parameters such as title and file types
              'D:\MATLAB\Images'); % set default path for window
    % Check if user clicked cancel in the file explorer gui      
    if isequal(filename,0) || isequal(pathname,0)
           disp('User pressed cancel')
    else % User did not click cancel, so user selected an image
       filename = fullfile(pathname, filename); % filename of image selected
       disp(['User selected ', filename]) % display message with filename

    end
    % convert all color images to rgb
    dot = regexp(filename,'\.'); % index of the . symbol in filename
    fileend = filename(dot+1:end); % get the file type from filename, i.e. tif, png, jpeg
    % check if the image file needs to be converted to rgb
    % some image types are 2 dimensional so check dim length 
    % gif and tif always need to be converted 
    if(fileend == 'gif' | fileend == 'tif' | length(size(imread(filename)))==2)
        disp('Conversion to RGB necessary'); % message to user that image needs to be convertedto rgb
        [imIn, cmap] = imread(filename); % read image and get the image and its cmap

        if(~isempty(cmap)) % if cmap is not empty
            imIn = ind2rgb8(imIn, cmap); % convert image to rgb
        end
    else % image is already rgb so no conversion is necessary
        disp('Conversion to RGB not necessary')
        imIn = imread(filename); % no conversion necessary, read image
    end
    figure; imshow(imIn);  % display the original image       
    title('Original image'); % title for the original image
    %% Get the pixel size for each tile based on x direction
    
    % imIn is an rgb image
    % s1 is size of x dim
    % s2 is size of y dim
    % s3 is size of z dim (should be 3 for rgb image)
 
    [s1, s2, s3] = size(imIn);  % get the s1 and s2 sizes, s3 is not used
    
    % x_tiles is the number of tiles to divide the image into in the x dim
    
    %x_tiles = input('How many tiles?');  % user picks number of tiles
    x_tiles = 17; % set a fixed number of tiles
    
    % x_pixels is an array of lenght x_tiles with the amount of pixels per
    % tile needed in order to divide the image into x_tiles number of tiles
    x_pixels = ones(1, x_tiles).*floor(s2 / x_tiles);               % how many pixels, rounding down
    
    % since we rounded down, there are some remaining pixels that didn't
    % get used by the tiles, so we will add 1 pixel to some of the tiles to use up
    % all the remaining pixels in the image
    
    % x_remainders is an array of length x_tiles with a 1 or a 0 at each
    % index, the sum of x_remainders is the total number of remaining pixels
    x_remainders = zeros(1, x_tiles);                               % vector of 0's, one for each tile
    x_remainders(1:rem(s2, x_tiles)) = ones(1, rem(s2, x_tiles));   % assign extra 1 pixel for each remainder
    x_pixels = x_pixels + x_remainders; % add the remainder pixels to the tiles in the front of the array
    x_pixels = sort(x_pixels); % sort the pixel amounts for the tiles so that the remainders are at the end
    % so x_pixels might be something like this [37    37    37    37    37    38    38    38    38]


    y_pixels = floor(x_pixels(1)); % get the number of pixels for the 1st tile in the y dim to make it a square
    y_tiles = floor(s1/y_pixels); % get the number of tiles in the y dim
    y_pixels = ones(1,y_tiles).*y_pixels; % get an array with the pixel counts for each tile in the y dim, make them all same size and round down if image is not evenly divisible
    y_remainder_sum = s1 - sum(y_pixels); % amount of remaining pixels in the y dim that didn't get used in our tiles yet
    y_remainders = zeros(1, y_tiles); % array of zeros that will be used to divide the remainding pixels into the tiles
    y_remainders(1:y_tiles) = ones(1, y_tiles)*floor(y_remainder_sum/y_tiles); % an array of length y_tiles with a 1 or a 0 at each index, the sum is the total number of remaining pixels
    y_rem_unused = y_remainder_sum - sum(y_remainders);
    y_remainders(1:y_rem_unused) = y_remainders(1:y_rem_unused)+ones(1,y_rem_unused);
    y_pixels = y_pixels + y_remainders;
    y_pixels = sort(y_pixels);
    
    % don't allow tile shifting more than this many pixels in any direction
    maxShift = floor(x_pixels(1)/4); % needs to be an integer

    %% Creates a black background for the output
    %  Add padding on all 4 sides to allow for tile shifting past the edges
    if(length(size(imIn)) == 3)
        sizes = size(imIn)+[maxShift*2,maxShift*2,0];
        imOut = uint8(zeros(sizes(1), sizes(2), sizes(3)));             % black background
    else
        sizes = size(imIn)+[maxShift*2,maxShift*2];
        imOut = uint8(zeros(sizes(1), sizes(2)));             % black background
    end

    % optional, change background color
    % imOut(:,:,1) = uint8(randi([40,60],sizes(1), sizes(2), 1));              % random red colors 
    % imOut(:,:,2) = uint8(randi([130,160],sizes(1), sizes(2), 1));            % random green colors
    % imOut(:,:,3) = uint8(randi([150,190],sizes(1), sizes(2), 1));            % random blue colors

    %figure(2); imshow(imOut);                                          % display the background
    %title('Black background with enough room for shifting at the edges');   % title the background
    %% Go through the original image one row tile at a time, row by row

    numRows = size(imIn, 1);                        % count rows
    numCols = size(imIn, 2);                        % count columns
    ii = 1; % index for pixel counts per tile in the i loop which is y dim
    jj = 1; % index for pixel counts per tile in the j loop which is x dim
    ssum = 0; % for testing
    for i = 1 : y_pixels(1,ii) : numRows                  % go through each row
     for j = 1 : x_pixels(1,jj) : numCols                 % go through each column
         tile_r = imIn(i : i + y_pixels(1,ii) - 1, j : j + x_pixels(1,jj) - 1,1);   % create a tile of the image's red color
         if(length(size(imIn)) == 3)
             tile_g = imIn(i : i + y_pixels(1,ii) - 1, j : j + x_pixels(1,jj) - 1,2);   % create a tile of the image's green color
             tile_b = imIn(i : i + y_pixels(1,ii) - 1, j : j + x_pixels(1,jj) - 1,3);   % create a tile of the image's blue color
         end
         dx = randi([-maxShift, maxShift]);             % assign random shift for x by [-9,9], the actual value is 1/4 of pixels in 1 tile
         dy = randi([-maxShift, maxShift]);             % assign random shift for y by [-9,9], the actual value is 1/4 of pixels in 1 tile
         % put the tile on the background image
         % account for the shifts
         % account for the extra padding of size maxShift on each edge
         x_start = j + maxShift + dx;
         x_end = x_start + x_pixels(1,jj) - 1;
         y_start = i + maxShift + dy;
         y_end = y_start + y_pixels(1,ii) - 1;
         imOut(y_start : y_end, x_start : x_end,1) = im2uint8(tile_r);
         if(length(size(imIn)) == 3)
             imOut(y_start : y_end, x_start : x_end,2) = im2uint8(tile_g);
             imOut(y_start : y_end, x_start : x_end,3) = im2uint8(tile_b);
         end
         %imshow(imOut); title(i);
         ssum = x_pixels(1,jj) + ssum;
    %      fprintf(' %d %d  %d    \n', jj,ssum,numCols);
         jj = jj+1;
         if(jj>x_tiles) % index of pixel counts per tile can't be higher than num of tiles
             break;
         end
     end
     jj = 1;
     ii = ii+1;
     if(ii>y_tiles) % index of pixel counts per tile can't be higher than num of tiles
         break;
     end
    end

    %% Crop the padding to get back the original image size
    %imOut = imOut(maxShift:maxShift+numCols-1, maxShift:maxShift+numCols-1,:);

    figure; imshow(imOut);
    title('Image after random tile transformation')
end
