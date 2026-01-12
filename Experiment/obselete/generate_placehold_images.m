% load PAR01_RUN01.xlsx
order = readtable(".\Orders\PAR01_RUN01.xlsx");

% get all image filenames
filenames = unique([order.Filename_left; order.Filename_right]);
filenames = filenames(~cellfun(@isempty, filenames));

% image folder
folder = "./Images/";
if ~exist(folder, "dir")
    mkdir(folder)
end

% create each image (uses Computer Vision Toolbox to create text iamges)
for fn = string(filenames(:)')
    img = ones(1000, 1000, 3, "uint8") * 225;

    if fn.endsWith("L.png")
        pos = [100 500];
    else
        pos = [600 500];
    end

    img = insertText(img, pos, fn, FontSize=30);
    
    imwrite(img, folder + fn)
end

