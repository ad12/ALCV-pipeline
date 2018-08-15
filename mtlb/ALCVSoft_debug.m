function varargout = ALCVSoft_debug(varargin)
% clc;
% ALCVSOFT_DEBUG MATLAB code for ALCVSoft_debug.fig
%      ALCVSOFT_DEBUG, by itself, creates a new ALCVSOFT_DEBUG or raises the existing
%      singleton*.
%
%      H = ALCVSOFT_DEBUG returns the handle to a new ALCVSOFT_DEBUG or the handle to
%      the existing singleton*.
%
%      ALCVSOFT_DEBUG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ALCVSOFT_DEBUG.M with the given input arguments.
%
%      ALCVSOFT_DEBUG('Property','Value',...) creates a new ALCVSOFT_DEBUG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before ALCVSoft_debug_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to ALCVSoft_debug_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% % Edit the above text to modify the response to help ALCVSoft_debug

% Last Modified by GUIDE v2.5 14-Aug-2018 20:49:08

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @ALCVSoft_debug_OpeningFcn, ...
                   'gui_OutputFcn',  @ALCVSoft_debug_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT
end

% --- Executes just before ALCVSoft_debug is made visible.
function ALCVSoft_debug_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to ALCVSoft_debug (see VARARGIN)

% Turn off hardware optimization for reading videos
%matlab.video.read.UseHardwareAcceleration('off');

% Choose default command line output for ALCVSoft_debug
handles.output = hObject;

path(path,'helpers/circle_hough');
path(path,'helpers/MST_SR_fusion_toolbox');
path(path,'helpers/Dijkstra_segmentation');
path(path,'helpers/hysteresis');
path(path,'helpers/BCOSFIRE_matlab');
path(path,'helpers/SIFT-Flow');
path(path,'helpers');

path(path,'IQA');

path(path, 'utils');
path(path, 'fall_lens_helpers');


set(0,'RecursionLimit',2000);
handles.FILL_COLOR = [79,129,189]/255;
% handles.OUTLINE_COLOR = [56,93,138]/255;
handles.OUTLINE_COLOR = [255,255,0];
handles.TYPE.MOV = 1;
handles.TYPE.JPG = 2;
handles.TYPE.PNG = 3;
handles.TYPE.TIF = 4;
handles.TYPE.BMP = 5;
handles.TYPE.PPM = 6;
handles.TYPE.RES = 7;
handles.TYPE.BFM = 8;
handles.TYPE.EYE = 9;
handles.CurrInputType = 1;
handles.blankImg = ones(100,100,3);
handles.InputImgHandle = []; % Input images display handle
handles.ChosenFramesHandle = []; % Chosen images display handle
handles.SelectedFrameHandle = []; % Selected image display handle
handles.SegmentedImageHandle = []; % Segmented image display handle
handles.fig = []; % Manual choice window handle
handles.frameStruct = []; % Initially the frames are nonexistent
handles = init(handles); % Initialize all shared variables
handles.ipPath = [];  % Path to input folder containing input images and (optionally) result mat
handles.ipFile = []; % Name of input file (only for videos)
handles.matPath = []; % Path to the output results file (equals to ipPath if not provided otherwise)
handles.matFile = []; % Name of mat file (optional)
handles.segInfo = [];

set(handles.UploadImagesCheckBox,'Value',1);

handles.InputVideoAxesRect = get(handles.InputVideoAxes,'Position');
handles.ChosenFramesAxisRect = get(handles.ChosenFramesAxis,'Position');
handles.SWinSize = get(handles.figure1,'Position');
handles.SWinSize = [handles.SWinSize(3:4),handles.SWinSize(3:4)];
handles.OnInputVideoAxes = false;
handles.OnChosenFramesAxis = false;

handles.infoText1 = ['Total number of branches: %d\n',...
    'Longest branch length: %.2f\n',...
    'Shortest branch length: %.2f\n',...
    'Median branch length: %.2f\n',...    
    'Maximum branch avg. width: %.2f\n',...
    'Minimum branch avg. width: %.2f\n',...
    'Median branch avg. width: %.2f\n',...    
    'Maximum branch tortuosity: %.2f\n',...
    'Minimum branch tortuosity: %.2f\n',...
    'Median branch tortuosity: %.2f\n',...    
    'Vessel density (%%): %.2f\n'];
handles.infoText2 = ['Selected branch length: %.2f\n',...   
    'Selected branch avg. width: %.2f\n',...
    'Selected branch tortuosity: %.2f\n',...
    'Width at selected pixel: %.2f'];

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes ALCVSoft_debug wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = ALCVSoft_debug_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

function handles = init(handles)

handles.chosenInputType = []; % chosen input type for this dataset
handles.imagesLoaded = false; % Input image loading flag
handles.resultsLoaded = false; % Input results loading flag
handles.processed = false; % Input image processing flag (true for results)
handles.imgMat = []; % Input images matrix
handles.imageStack = []; % Chosen images structure
handles.manualImageStack = []; % Manually chosen images structure
handles.numInputImages = 0; % Number of input images
handles.numChosenFrames = 0; % Number of chosen images
handles.currInputImage = 0; % Currently displayed input image
handles.currChosenFrame = 0; % Currently displayed chosen image
handles.currChosenFrameType = false; % Showing all (false) or only eye (true)
handles.selectedFrame = []; % Automatically selected frame
handles.selectedSpecularMask = []; % specularity mask
handles.manualFrame = []; % Manually created frame
handles.manualSpecularMask = []; % specularity mask
handles.manualAvailable = false; % True if manual selection is performed
handles.selectedMaskedRegion = []; % For masking the region to NOT segment - selected
handles.manualMaskedRegion = []; % For masking the region to NOT segment - manual
handles.frameStruct = [];
delete(handles.frameStruct);
handles.frameStruct = [];
handles.currPt = [];

% Segmentation variables
handles.L = [];
handles.n = [];
struct1 = struct('Img',cell(5,1),'DiagImg',cell(5,1),'BranchImg',cell(5,1),'BranchStruct',cell(5,1),'NumImg',cell(5,1));
handles.selectedSegStruct = struct('Img',[],'DiagImg',[],'BranchImg',[],'BranchStruct',[],'NumImg',[],'Seg',[]);
handles.selectedSegStruct.Seg = struct1; % as the types of segmentation
handles.manualSegStruct = handles.selectedSegStruct;

handles.SegmentationChoice = 1; % Type of segmentation to perform
handles.manualSelectionChoice = 1; % Choice of frames for manual selection - chosen or all

if ~isempty(handles.fig)
    delete(handles.fig);
    handles.fig = [];
end

if ~isempty(handles.InputImgHandle)
    delete(handles.InputImgHandle);
    handles.InputImgHandle = [];
end
if ~isempty(handles.ChosenFramesHandle)
    delete(handles.ChosenFramesHandle);
    handles.ChosenFramesHandle = [];
end
if ~isempty(handles.SelectedFrameHandle)
    delete(handles.SelectedFrameHandle);
    handles.SelectedFrameHandle = [];
end
if ~isempty(handles.SegmentedImageHandle)
    delete(handles.SegmentedImageHandle);
    handles.SegmentedImageHandle = [];
end
handles = showSegInfo(handles,0);
set(handles.ShowChosenEyesCheckbox,'Value',false);
set(handles.ToggleManualSelectionCheckbox,'Value',false);
set(handles.VesselSkeletonCheckbox,'Value',false);
set(handles.ManualSelectionChoicePopup,'Value',1);
set(handles.SegmentationChoicePopup,'Value',1);
set(handles.InputVideoSlider,'Value',0);
set(handles.ChosenFramesSlider,'Value',0);
set(handles.AddressText,'String','');

end

function extn = getExtn(types,type)
switch type
    case types.MOV,
        extn = 'mov';
    case types.TIF,
        extn = {'tif','tiff'};
    case types.PNG,
        extn = 'png';
    case types.JPG,
        extn = {'jpg','jpeg'};
    case types.BMP,
        extn = 'bmp';
    case types.PPM,
        extn = 'ppm';
    case types.RES,
        extn = 'mat';
    case types.BFM,
        extn = 'jpg';        
    case types.EYE,
        extn = 'jpg';             
    otherwise,
        extn = [];
end
end

% --- Executes on selection change in InputTypePopup.
function InputTypePopup_Callback(hObject, eventdata, handles)
% hObject    handle to InputTypePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns InputTypePopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from InputTypePopup

handles.CurrInputType = get(hObject,'Value');
guidata(hObject,handles);

end

% --- Executes during object creation, after setting all properties.
function InputTypePopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to InputTypePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --------------------------------------------------------------------
function FileMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FileMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --------------------------------------------------------------------
function OpenVideoMenu_Callback(hObject, eventdata, handles)
% hObject    handle to OpenVideoMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)



% Estimate the folder structure and load

wrongData = false;
frameStruct = [];
ipFileName = [];
if (handles.CurrInputType == handles.TYPE.MOV) || (handles.CurrInputType == handles.TYPE.RES) || (handles.CurrInputType == handles.TYPE.BFM) || (handles.CurrInputType == handles.TYPE.EYE)
    if isempty(handles.ipPath)
        [ipFileName,ipPathName] = uigetfile({['*.',getExtn(handles.TYPE,handles.CurrInputType)]},'Choose File',pwd);
    else
        [ipFileName,ipPathName] = uigetfile({['*.',getExtn(handles.TYPE,handles.CurrInputType)]},'Choose File',handles.ipPath);
    end
    if ipFileName ~= 0
        hb = waitbar(0,'Please wait while the data is uploaded...','WindowStyle','modal');
        if handles.CurrInputType == handles.TYPE.MOV
            try
                frameStruct = GenericFrameReader(fullfile(ipPathName,ipFileName),true);
            catch ME
                wrongData = true;
            end
            if frameStruct.NumFrames == 0
                wrongData = true;
            end
        elseif handles.CurrInputType == handles.TYPE.BFM || handles.CurrInputType == handles.TYPE.EYE
            % Load Manually Selected BestFrame    
            wrongData = false;
            ManualBFM = [];
            handles.frameStruct = [];
            try
                ManualBFM = imread(fullfile(ipPathName,ipFileName));
            catch ME
                wrongData = true;
                makeLog(ME);
            end                 
                
        else
            waitbar(0,hb,sprintf('Getting Results'));
            [results,wrongData] = checkResultsConsistency(fullfile(ipPathName,ipFileName));
        end
        delete(hb);
    else
        return;
    end
else
    if isempty(handles.ipPath)
        [ipPathName] = uigetdir(pwd);
    else
        [ipPathName] = uigetdir(handles.ipPath);
    end
    if ipPathName ~= 0
        try
            frameStruct = GenericFrameReader(ipPathName,false,getExtn(handles.TYPE,handles.CurrInputType));
        catch ME
            wrongData = true;
        end
        if frameStruct.NumFrames == 0
            wrongData = true;
        end
    else
        return;
    end
end

if wrongData
    errordlg('Data unavailable.');
    return;
end

try
    hb = waitbar(0,'Please wait while the data is processed...','WindowStyle','modal');
    handles = init(handles); % initialize the handle at this moment
    
    handles.ipPath = ipPathName;
    handles.matPath = ipPathName;
    handles.ipFile = ipFileName;
    handles.matFile = ipFileName;
    % Upload
    if handles.CurrInputType == handles.TYPE.RES
        % Process mat file
        handles.chosenInputType = results.chosenInputType;
        handles.ipPath = results.ipPath;
        handles.ipFile = results.ipFile;
        handles.imageStack = results.imageStack;
        handles.selectedSpecularMask = results.selectedSpecularMask;
        handles.imgMat = results.imgMat;
        handles.numInputImages = size(handles.imgMat,1);
        if isfield(results,'manualImageStack')
            handles.manualAvailable = true;
            handles.manualImageStack = results.manualImageStack;
            handles.manualFrame = results.manualFrame;
            handles.manualSpecularMask = results.manualSpecularMask;
        end
        handles.resultsLoaded = true;
        uploadImages = get(handles.UploadImagesCheckBox,'Value');
        if uploadImages            
            if handles.chosenInputType == handles.TYPE.MOV
                try
                    % Initial run to populate timestamps and check availability
                    try
                        handles.frameStruct = GenericFrameReader(fullfile(handles.ipPath,handles.ipFile),true);
                    catch ME2
                        try 
                            handles.frameStruct = GenericFrameReader(fullfile(ipPathName,handles.ipFile),true);
                            handles.ipPath = pwd;
                        catch ME3
                            try
                                handles.frameStruct = GenericFrameReader(fullfile(pwd,handles.ipFile),true);
                                handles.ipPath = ipPathName;
                            catch ME4
                                rethrow(ME4);
                            end
                        end
                    end
                    if handles.numInputImages ~= handles.frameStruct.NumFrames
                        error('mismatch');
                    end
                    if size(handles.imgMat,2)==2
                        for cf = 1:handles.frameStruct.NumFrames
                            waitbar(cf/handles.frameStruct.NumFrames,hb,...
                                sprintf('Uploading original frame %d of %d',cf,handles.frameStruct.NumFrames));
                            handles.frameStruct.CurrentTime(cf) = handles.imgMat{cf,2};
                        end
                        handles.frameStruct.ProcessedOnce = true;
                    else
                        imgMat = cell(handles.numInputImages,2);
                        for cf = 1:handles.frameStruct.NumFrames
                            waitbar(cf/handles.frameStruct.NumFrames,hb,...
                                sprintf('Uploading original frame %d of %d',cf,handles.frameStruct.NumFrames));
                            imgo = handles.frameStruct.getFrame();
                            imgMat{cf,1} = handles.imgMat{cf,1};
                            imgMat{cf,2} = handles.frameStruct.CurrentTime(cf);
                        end
                        handles.imgMat = imgMat;
                    end
                    handles.imagesLoaded = true;
                catch ME
                    handles.imagesLoaded = false;
                end
            else
                try
                    % Initial run to populate timestamps and check availability
                    handles.frameStruct = GenericFrameReader(handles.ipPath,false,getExtn(handles.TYPE,handles.chosenInputType));
                    if handles.numInputImages ~= handles.frameStruct.NumFrames
                        error('mismatch');
                    end
%                     for cf = 1:handles.frameStruct.NumFrames
%                         imgo = handles.frameStruct.getFrame();
%                     end
                    handles.imagesLoaded = true;
                catch ME
                    handles.imagesLoaded = false;
                end
            end
        else
            handles.imagesLoaded = false;
        end
    elseif handles.CurrInputType == handles.TYPE.BFM
        
        handles.ManualBFM = ManualBFM;
        handles.chosenInputType = handles.CurrInputType;
        % Process input file
        handles.frameStruct.NumFrames = 1;
        handles.numInputImages = handles.frameStruct.NumFrames;
        % Load & process images
        [handles] = extractEyeRegionEx(handles);
        if isempty(handles.imageStack)
            error('No eyes found');
        end
        handles.imagesLoaded = true;    
        
    elseif handles.CurrInputType == handles.TYPE.EYE
        
        handles.ManualBFM = ManualBFM;
        handles.chosenInputType = handles.CurrInputType;
        % Process input file
        handles.frameStruct.NumFrames = 1;
        handles.numInputImages = handles.frameStruct.NumFrames;
        % Load & process images
        [handles] = extractEyeRegionEx(handles);
        try
            Eyeimage = imread([handles.ipPath(1:end-1) '_Eye\' handles.ipFile(1:end-4) 'eye.JPG']);
        catch
            error('Corresponding eye image does not exist!');
        end
        Eyeimage = im2bw(Eyeimage);
        Eyeminx = 9999; Eyeminy = 9999; Eyemaxx = 0; Eyemaxy = 0;
        ManualBFM_tmp = zeros(size(ManualBFM,1),size(ManualBFM,2),3);
        
        if min(min(Eyeimage))==0
            for tmpi = 1:size(Eyeimage,1)
                tmp = Eyeimage(tmpi,:);
                tmp2 = find(tmp==0);
                if tmp2
                    Eyeminx = min(Eyeminx,tmpi);
                    Eyemaxx = max(Eyemaxx,tmpi);
                    Eyeminy = min(Eyeminy,tmp2(1));
                    Eyemaxy = max(Eyemaxy,tmp2(end));
                    ManualBFM_tmp(tmpi,tmp2(1):tmp2(end),:) = double(ManualBFM(tmpi,tmp2(1):tmp2(end),:));
                end
            end
        end
            
            
%         for tmpi = 1:size(Eyeimage,1)
%             for tmpj = 1:size(Eyeimage,2)
%                 tmp = Eyeimage(tmpi,tmpj);
%                 if tmp == 0
%                     Eyeminx = min(Eyeminx,tmpi);
%                     Eyemaxx = max(Eyemaxx,tmpi);
%                     Eyeminy = min(Eyeminy,tmpj);
%                     Eyemaxy = max(Eyemaxy,tmpj);
%                     ManualBFM_tmp(tmpi,tmpj,:) = double(ManualBFM(tmpi,tmpj,:));
%                 end
%             end
%         end
        
        imageStack = struct('Img',cell(1,1),...
            'OrigImg',cell(1,1),...
            'OrigFrameNum',cell(1,1),...
            'Rect',cell(1,1));
        imageStack(1).Img = uint8(ManualBFM_tmp(Eyeminx:Eyemaxx,Eyeminy:Eyemaxy,:));
        imageStack(1).OrigImg = ManualBFM;
        imageStack(1).OrigFrameNum = 1;
        imageStack(1).Rect = [Eyeminy,Eyeminx,Eyemaxy-Eyeminy+1,Eyemaxx-Eyeminx+1];
        imageStack(1).mask = Eyeimage(Eyeminx:Eyemaxx,Eyeminy:Eyemaxy,:);

        handles.imageStack = imageStack;
        
        
        
%         [handles] = extractEyeRegionEx(handles);
        if isempty(handles.imageStack)
            error('No eyes found');
        end
        handles.imagesLoaded = true;    
        
    else
        handles.frameStruct = frameStruct;
        handles.chosenInputType = handles.CurrInputType;
        % Process input file
        handles.numInputImages = handles.frameStruct.NumFrames;
        % Load & process images
        [handles] = extractEyeRegionEx(handles);
        if isempty(handles.imageStack)
            error('No eyes found');
        end
        handles.imagesLoaded = true;        
    end
    % Display loaded images
    if handles.imagesLoaded || handles.resultsLoaded
        % Set input image
        handles.currInputImage = 1;
        handles.InputImgHandle = initFrame(handles.InputVideoAxes,handles.figure1,handles.InputVideoPanel,handles.imgMat{1,1});
        handles = getCurrImg(handles,1);  % Set the text
    end
    
    % Post-processing - start
    handles.numChosenFrames = length(handles.imageStack);
    handles.selectedFrame = handles.imageStack(1).Img;
    tSize = size(handles.selectedFrame);
    handles.selectedMaskedRegion = false(tSize(1),tSize(2));
    handles.selectedSpecularMask = getSpecularityMask(handles.selectedFrame);
    handles.processed = true;
    handles.currChosenFrame = 1;
    handles = getCurrImg(handles,2,1); % Set the slider and text
    
    handles.SelectedFrameHandle = initFrame(handles.SelectedFrameAxis,handles.figure1,handles.SelectedFramePanel,handles.selectedFrame);
    handles = getCurrImg(handles,3);
    handles.SegmentedImageHandle = initFrame(handles.SegmentedImageAxis,handles.figure1,handles.SegmentationPanel,ones(size(handles.selectedFrame)),{@Figs_Callback,2});
    handles = showSegInfo(handles,0);
    % Post-processing - end
    
    if ~(handles.imagesLoaded || handles.resultsLoaded)
        error('No data found!');
    end
    
    waitbar(1,hb,'Upload complete');
    
    delete(hb);
    
    set(handles.AddressText,'String',fullfile(handles.ipPath,handles.ipFile));
    guidata(hObject,handles);
catch ME
    delete(hb);
    errordlg(ME.message);
    makeLog(ME);
    return;
end



end

function [results,errorVal] = checkResultsConsistency(matFilePath)
errorVal = false;
results = [];
try
    results = load(matFilePath);
    if ~isfield(results,'ID')
        if ~strcmp(results.ID,'ALCVSOFT-VIP')
            error('Wrong mat file!');
        end
    end
catch ME
    errorVal = true;
    makeLog(ME);
end
end

function Him = initFrame(imgAxis,fig,panel,img,imgCallback)

% specificArgNames = [];
% axisTag = get(imgAxis,'Tag');
% tArgs = images.internal.imageDisplayParseInputs(specificArgNames,img);
% imgAxis = axes('Parent',panel);
% Him = images.internal.basicImageDisplay(fig,imgAxis,...
%     tArgs.CData,tArgs.CDataMapping,...
%     tArgs.DisplayRange,tArgs.Map,...
%     tArgs.XData,tArgs.YData, false);

axes(imgAxis);
Him = imshow(mat2gray(img));

% HPanel = imscrollpanel(panel,Him);
% set(imgAxis,'Tag',axisTag);
% apiHPanel = iptgetapi(HPanel);
% mag = apiHPanel.getMagnification();
if nargin == 5
    set(Him,'ButtonDownFcn',imgCallback);
end

end

function handles = getCurrImg(handles,type,pt)

switch type
    case 1
        % Input image
        set(handles.InputVideoText,'String',sprintf('%d/%d',handles.currInputImage,handles.numInputImages));
        set(handles.InputImgHandle,'CData',handles.imgMat{handles.currInputImage,1});
    case 2
        % Chosen frames
        set(handles.ChosenFramesText,'String',sprintf('%d/%d',handles.currChosenFrame,handles.numChosenFrames));
        if handles.currChosenFrameType
            img = insertShape(handles.imageStack(handles.currChosenFrame).Img,'Rectangle',handles.imageStack(handles.currChosenFrame).Rect, ...
                'LineWidth', 4);
        else
            img = insertShape(handles.imageStack(handles.currChosenFrame).OrigImg,'Rectangle',handles.imageStack(handles.currChosenFrame).Rect, ...
                'LineWidth', 4);
            if handles.CurrInputType == handles.TYPE.BFM || handles.CurrInputType == handles.TYPE.EYE
                img = imresize(img,0.2);
            end
        end      
        if nargin<3 % Generated originally
            set(handles.ChosenFramesHandle,'CData',img);
        else % Generated through user clicking
            handles.ChosenFramesHandle = initFrame(handles.ChosenFramesAxis,handles.figure1,handles.ChosenFramesPanel,img);
        end
    case 3
        % Selected/Manual image
        flag = get(handles.ToggleManualSelectionCheckbox,'Value');
        mask = [];
        if flag == 1
            img = handles.manualFrame;
            if ~isempty(handles.manualSpecularMask)
                mask = bwmorph(handles.manualSpecularMask,'remove');
                mask = imdilate(mask,strel('disk',1));
            end
            mask2 = handles.manualMaskedRegion;
        else
            img = handles.selectedFrame;
            if ~isempty(handles.selectedSpecularMask)
                mask = bwmorph(handles.selectedSpecularMask,'remove');
                mask = imdilate(mask,strel('disk',1));
            end
            mask2 = handles.selectedMaskedRegion;
        end
        isMask = sum(mask2(:))>0;
        for cf = 1:3
            tmp = img(:,:,cf);
            if ~isempty(mask)
                tmp(mask) = handles.OUTLINE_COLOR(cf);
            end
            if isMask
                tmp(mask2) = tmp(mask2) + 50;
            end
            img(:,:,cf) = tmp;
        end
        set(handles.SelectedFrameHandle,'CData',img);
    case 4
        % Segmentation image
        skeleton = get(handles.VesselSkeletonCheckbox,'Value');
        flag = get(handles.ToggleManualSelectionCheckbox,'Value');
        flagAllVess = get(handles.OverlapVesselsCheckBox,'Value');
        if nargin<3
            pointGiven = false;
        else
            pointGiven = true;
        end
        if flag == 1
            img = handles.manualSegStruct.Img;
            skelImg = handles.manualSegStruct.BranchImg>0;
            numImg = handles.manualSegStruct.NumImg;
%             if pointGiven
                selectedImg = handles.manualFrame;
                mask2 = handles.manualMaskedRegion;
                if sum(mask2(:))>0
                    for cf = 1:3
                        tmp = selectedImg(:,:,cf);
                        tmp(mask2) = tmp(mask2) + 50;
                        selectedImg(:,:,cf) = tmp;
                    end
                end
%             end
        else
            img = handles.selectedSegStruct.Img;
            skelImg = handles.selectedSegStruct.BranchImg>0;
            numImg = handles.selectedSegStruct.NumImg;
%             if pointGiven
                selectedImg = handles.selectedFrame;
                mask2 = handles.selectedMaskedRegion;
                if sum(mask2(:))>0
                    for cf = 1:3
                        tmp = selectedImg(:,:,cf);
                        tmp(mask2) = tmp(mask2) + 50;
                        selectedImg(:,:,cf) = tmp;
                    end
                end
%             end
        end
        flag2 = ~isempty(img);
        if skeleton
            img = skelImg;
        end
        if flag2 % Showable
            img = repmat(img,[1,1,3]);
        else
            img = handles.blankImg;
        end   
        if flagAllVess && flag2
            mask2 = numImg>0;
            for cf = 1:3
                tmp = selectedImg(:,:,cf);
                tmp(mask2) = tmp(mask2) + 50; % less brightly colored
                selectedImg(:,:,cf) = tmp;
            end
        end
        if pointGiven % Generated through user clicking
            if numImg(pt(2),pt(1))>0
                handles.n = numImg(pt(2),pt(1));
                handles.L = numImg == handles.n;
                for cf = 1:3
                    tmp = img(:,:,cf);
                    tmp(handles.L) = handles.FILL_COLOR(cf);
                    img(:,:,cf) = tmp;
                    tmp = selectedImg(:,:,cf);
                    tmp(handles.L) = tmp(handles.L) + 80; % brightly colored
                    selectedImg(:,:,cf) = tmp;
                end                
                handles = showSegInfo(handles,2,pt);
            end
            set(handles.SegmentedImageHandle,'CData',img);
        else
            handles.SegmentedImageHandle = initFrame(handles.SegmentedImageAxis,handles.figure1,handles.SegmentationPanel,img,{@Figs_Callback,2});
        end
        set(handles.SelectedFrameHandle,'CData',selectedImg);
    otherwise
        % Nothing yet
end

end

function Figs_Callback(hObject,eventdata,n)

handles = guidata(hObject);
fig = ancestor(hObject,'figure');
currPt = round(eventdata.IntersectionPoint);
currPt(currPt<1) = 1;
if n == 1 % not thought about yet
    % Do nothing at present
elseif n == 2 % Segmented frame
    handles.currPt = currPt;
    handles = getCurrImg(handles,4,currPt);
    guidata(hObject,handles);
else
    % Do nothing at this moment
end

end

function handles = showSegInfo(handles,n,pt)
flag = get(handles.ToggleManualSelectionCheckbox,'Value');
if flag
    branchStruct = handles.manualSegStruct.BranchStruct;
    diagImg = handles.manualSegStruct.DiagImg;
else
    branchStruct = handles.selectedSegStruct.BranchStruct;
    diagImg = handles.selectedSegStruct.DiagImg;
end
if n == 1
    mask = false(size(diagImg,1),size(diagImg,2));
    if flag
        binImg = handles.manualSegStruct.NumImg>0;
        if ~isempty(handles.manualMaskedRegion)
            mask = handles.manualMaskedRegion;
            maskSum = sum(mask(:));
        else
            maskSum = 0;
        end
        dataSize = sum(sum(handles.manualFrame(:,:,1)>0));
    else
        binImg = handles.selectedSegStruct.NumImg>0;
        if ~isempty(handles.selectedMaskedRegion)
            mask = handles.selectedMaskedRegion;
            maskSum = sum(mask(:));
        else
            maskSum = 0;
        end
        dataSize = sum(sum(handles.selectedFrame(:,:,1)>0));
    end
    len = length(branchStruct);
    if len>0  % calculate vessel density
        maxLen = 0;
        minLen = Inf;
        maxWid = 0;
        minWid = Inf;
        maxTort = 0;
        minTort = Inf;
        medianLen = 0;
        medianWid = 0;
        medianTort = 0;        
        medianLenlist = [];
        medianWidlist = [];
        medianTortlist = [];
        
        for cf = 1:len
            if branchStruct(cf).Length>maxLen
                maxLen = branchStruct(cf).Length;
            end
            if branchStruct(cf).Length<minLen
                minLen = branchStruct(cf).Length;
            end
            if branchStruct(cf).AvgWidth>maxWid
                maxWid = branchStruct(cf).AvgWidth;
            end
            if branchStruct(cf).AvgWidth<minWid
                minWid = branchStruct(cf).AvgWidth;
            end
            if branchStruct(cf).Tortuosity>maxTort
                maxTort = branchStruct(cf).Tortuosity;
            end
            if branchStruct(cf).Tortuosity<minTort
                minTort = branchStruct(cf).Tortuosity;
            end
            medianLenlist = [medianLenlist;branchStruct(cf).Length];
            medianWidlist = [medianWidlist;branchStruct(cf).AvgWidth];
            medianTortlist = [medianTortlist;branchStruct(cf).Tortuosity];
        end
        
        medianLen = median(medianLenlist);
        medianWid = median(medianWidlist);
        medianTort = median(medianTortlist);
        
        maskoverlap = binImg & mask;

        vd = (sum(binImg(:))-sum(maskoverlap(:)))*100/(dataSize - maskSum);    
    else
        maxLen = 0;
        minLen = 0;
        maxWid = 0;
        minWid = 0;
        maxTort = 0;
        minTort = 0;
        medianLen = 0;
        medianWid = 0;
        medianTort = 0;
        vd = 0;
    end
    handles.segInfo = {len,maxLen,minLen,medianLen,maxWid,minWid,medianWid,maxTort,minTort,medianTort,vd};
    S1 = sprintf(handles.infoText1,len,maxLen,minLen,medianLen,maxWid,minWid,medianWid,maxTort,minTort,medianTort,vd);
    set(handles.InfoTextbox1,'String',S1);
elseif n == 2
    cf = handles.n;
    S2 = sprintf(handles.infoText2,branchStruct(cf).Length,...
        branchStruct(cf).AvgWidth,...
        branchStruct(cf).Tortuosity,...
        diagImg(pt(2),pt(1)));
    set(handles.InfoTextbox2,'String',S2);
else
    set(handles.InfoTextbox1,'String','');
    set(handles.InfoTextbox2,'String','');
end
end

function AddressText_Callback(hObject, eventdata, handles)
% hObject    handle to AddressText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of AddressText as text
%        str2double(get(hObject,'String')) returns contents of AddressText as a double

set(hObject,'String',fullfile(handles.ipPath,handles.ipFile));

end

% --- Executes during object creation, after setting all properties.
function AddressText_CreateFcn(hObject, eventdata, handles)
% hObject    handle to AddressText (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --------------------------------------------------------------------
function SaveResultsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to SaveResultsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    if handles.processed
        hb = waitbar(0,'Please wait while the files are being saved','WindowStyle','modal');
        ID = 'ALCVSOFT-VIP';
        imageStack = handles.imageStack;
        selectedSpecularMask = handles.selectedSpecularMask;
        imgMat = handles.imgMat;
        chosenInputType = handles.chosenInputType;
        ipPath = handles.ipPath;
        ipFile = handles.ipFile;
        if isempty(handles.matFile)
            k = strfind(handles.matPath,filesep);
            idx = length(k);
            if k(end) == length(handles.matPath)
                idx = length(k)-1;
            end
            matFileName = [handles.matPath(k(idx)+1:end),'.mat'];
        else
            matFileName = [handles.matFile(1:end-4),'.mat'];
        end
        dir1 = dir(fullfile(handles.matPath,matFileName));
        if ~isempty(dir1)
            % Construct a questdlg with three options
            choice = questdlg('File already exists. Do you want to override?', ...
                'Duplicate File Menu', ...
                'Yes','No','Cancel','Cancel');
            % Handle response
            switch choice
                case 'Yes'
                    % Do nothing
                case 'No'
                    [ipFileName,ipPathName] = uiputfile({'*.mat'},'Choose File',handles.matPath);
                    matFileName = ipFileName;
                    handles.matFile = ipFileName;
                    handles.matPath = ipPathName;
                case 'Cancel'
                    close(hb);
                    return;
            end
            
        end
        if handles.manualAvailable
            manualImageStack = handles.manualImageStack;
            manualFrame = handles.manualFrame;
            manualSpecularMask = handles.manualSpecularMask;
            save(fullfile(handles.matPath,matFileName),'ID','chosenInputType','ipPath','ipFile','imgMat','imageStack','selectedSpecularMask',...
                'manualImageStack','manualFrame','manualSpecularMask','-v7.3');
            clear  manualImageStack manualFrame manualSpecularMask
        else
            save(fullfile(handles.matPath,matFileName),'ID','chosenInputType','ipPath','ipFile','imgMat','imageStack','selectedSpecularMask','-v7.3');
        end
        clear imageStack selectedSpecularMask imgMat
        guidata(hObject,handles);
        
        close(hb);
    end
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end


% --- Executes on slider movement.
function ChosenFramesSlider_Callback(hObject, eventdata, handles)
% hObject    handle to ChosenFramesSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

if ~handles.processed
    set(hObject,'Value',0);
    return;
end
try
    val = get(hObject,'Value');
    val = (handles.numChosenFrames-1)*val+1;
    if val>handles.currChosenFrame
        inc = floor(val-handles.currChosenFrame);
        if inc == 0
            inc = 1;
        end
        handles.currChosenFrame = handles.currChosenFrame + inc;
    else
        inc = floor(handles.currChosenFrame-val);
        if inc == 0
            inc = 1;
        end
        handles.currChosenFrame = handles.currChosenFrame - inc;
    end
    set(hObject,'Value',(handles.currChosenFrame-1)/(handles.numChosenFrames-1));
    handles = getCurrImg(handles,2); % through slider
    guidata(hObject,handles);
catch ME
    set(hObject,'Value',0);
    errordlg(ME.message);
    makeLog(ME);
end

end

% --- Executes during object creation, after setting all properties.
function ChosenFramesSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ChosenFramesSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
end

% --- Executes on slider movement.
function InputVideoSlider_Callback(hObject, eventdata, handles)
% hObject    handle to InputVideoSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

if ~handles.processed
    set(hObject,'Value',0);
    return;
end
try
    val = get(hObject,'Value');
    val = (handles.numInputImages-1)*val+1;
    if val>handles.currInputImage
        inc = floor(val-handles.currInputImage);
        if inc == 0
            inc = 1;
        end
        handles.currInputImage = handles.currInputImage + inc;
    else
        inc = floor(handles.currInputImage-val);
        if inc == 0
            inc = 1;
        end
        handles.currInputImage = handles.currInputImage - inc;
    end
    set(hObject,'Value',(handles.currInputImage-1)/(handles.numInputImages-1));
    handles = getCurrImg(handles,1); % through slider
    guidata(hObject,handles);
catch ME
    set(hObject,'Value',0);
    errordlg(ME.message);
    makeLog(ME);
end

end

% --- Executes during object creation, after setting all properties.
function InputVideoSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to InputVideoSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
end

% --- Executes on button press in ExtractEyesButton.
function ExtractEyesButton_Callback(hObject, eventdata, handles)
% hObject    handle to ExtractEyesButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~handles.imagesLoaded % cannot proceed without images
    return;
end

try
    if handles.processed
        choice = questdlg('Data already processed. Do you want to process again?', ...
            'Process Menu', ...
            'Yes','No','No');
    else
        choice = 'Yes';
    end
    % Handle response
    switch choice
        case 'Yes'
            handles = extractEyeRegionEx(handles);
            handles.numChosenFrames = numel(handles.imageStack);
            handles.selectedFrame = handles.imageStack(1).Img;
            
            handles.processed = true;
            handles.currChosenFrame = 1;
            handles.ChosenFramesHandle = initFrame(handles.ChosenFramesAxis,handles.figure1,handles.ChosenFramesPanel,handles.imageStack(1).OrigImg);
            handles = getCurrImg(handles,2); % Set the slider and text
            
            handles.SelectedFrameHandle = initFrame(handles.SelectedFrameAxis,handles.figure1,handles.SelectedFramePanel,handles.selectedFrame);
            guidata(hObject,handles);
        otherwise
            % Do nothing
    end
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

% --- Executes on button press in ShowChosenEyesCheckbox.
function ShowChosenEyesCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to ShowChosenEyesCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ShowChosenEyesCheckbox

if ~handles.processed
    set(hObject,'Value',0);
    return;
end
try
    handles.currChosenFrameType = get(hObject,'Value');
    handles = getCurrImg(handles,2,1);
    guidata(hObject,handles);
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

% --- Executes on button press in ToggleManualSelectionCheckbox.
function ToggleManualSelectionCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to ToggleManualSelectionCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of ToggleManualSelectionCheckbox

try
    val = get(hObject,'Value');
    if val
        if handles.manualAvailable
            set(handles.SelectedFrameHandle,'CData',handles.manualFrame);
        else
            msgbox('Manual selection is not available');
            set(hObject,'Value',0);
        end
    else
        set(handles.SelectedFrameHandle,'CData',handles.selectedFrame);
    end
    handles = getCurrImg(handles,3);
    handles = getCurrImg(handles,4);
    guidata(hObject,handles);
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

% --- Executes on button press in SegmentButton.
function SegmentButton_Callback(hObject, eventdata, handles)
% hObject    handle to SegmentButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~handles.processed
    return;
end
try
    val = get(handles.ToggleManualSelectionCheckbox,'Value');
    if val
        img = handles.manualFrame;
        mask2 = handles.manualMaskedRegion;
        segmentationRequired = isempty(handles.manualSegStruct.Seg(handles.SegmentationChoice,1).Img);
    else
        img = handles.selectedFrame;
        mask2 = handles.selectedMaskedRegion;
        segmentationRequired = isempty(handles.selectedSegStruct.Seg(handles.SegmentationChoice,1).Img);
    end
    isMask = sum(mask2(:))>0;
    if segmentationRequired
        hb = waitbar(0,'Please wait while the frame is segmented','WindowStyle','modal');
        
        imSize = size(img);
        if isMask
            img = uint8(double(img).*repmat(~mask2,[1,1,3]));
        end
        dataSize = imSize(1)*imSize(2);
        
        spMask = getSpecularityMask(img);
        
        sImg = double(img) / 255;
        R = sImg(:,:,1);
        G = sImg(:,:,2);
        B = sImg(:,:,3);
        [L,~,~] = RGB2Lab(R,G,B);
        L = L/100;
        mask = ~(L<0.4);
        mask(1:3,:) = false;
        mask(end-3:end,:) = false;
        mask(:,1:3) = false;
        mask(:,end-3:end) = false;
        mask = imerode(imfill(bwareafilt(mask,1),'holes'),strel('disk',11));
        statMask = regionprops(mask,'MinorAxisLength','Area');
        if length(statMask)>1
            area = 0;
            for cf = 1:length(statMask)
                if statMask(cf).Area>area
                    area = statMask(cf).Area;
                    minorAxis = statMask(cf).MinorAxisLength;
                end
            end
        else
            minorAxis = statMask(1).MinorAxisLength;
        end
        mask = ~mask;
        if handles.chosenInputType == handles.TYPE.EYE
            mask = handles.imageStack(1).mask;
        end
        switch handles.SegmentationChoice
            case 1
                img = removeSpecularity(img);
                [~, imgf, ~, ~] = Application(img,37);
            case 2
                h1 = fspecial('gaussian',[15 15],3);
                h2 = strel('disk',5);
                
%                 img1lab = rgb2lab(mat2gray(img));
%                 tmpImg = imfilter(img1lab(:,:,2),h1);
%                 maskXA = tmpImg>0.3*max(tmpImg(:));
%                 
%                 maska = imdilate(img1lab(:,:,1)>80,h2);
%                 tmask = rgb2gray(img)>0;
%                 for cf = 1:3
%                     tmp = img(:,:,cf);
%                     tmp(maska) = mean(tmp(tmask));
%                     img(:,:,cf) = tmp;
%                 end
                
                h2 = fspecial('gaussian',7,1.);
                opt = option_defaults_fa;
                opt_d = dijkstra_seg_defaults;
                opt_d.flt_thr = 0.6;
                opt_d.t9 = 0.7; % Percentage value 
                opt_d.t11 = 0.6; % Raw filtered value
                im1 = im2double(imfilter(img,h2));
                filt_f = filter_image(uint8(im1 * 255),opt);
                filt_f(spMask) = 1;
                imgf = dijkstra_segmentation(filt_f,opt_d);
                imgf = imgf>0;
            case 3
                img = removeSpecularity(img);
                img2 = img(:,:,1);
                h1 = fspecial('gaussian',31,31/4);
                im2 = double(img2)-double(imfilter(img2,h1));
                im2 = im2.*(~mask).*(im2<0);
                im3 = imbothat(im2,strel('disk',31)).*(~mask);
%                 opt = option_defaults_fa;
                fImg = mat2gray(filter_image(img));
                fImg(mask) = 1;
                [~,imgf]=hysteresis3d(im3.*(1-fImg),0.02,0.05,8);
%                 imgf = imerode(imgf,strel('disk',1));
                imgf = imopen(imgf,strel('disk',1));
            case 4
                img = removeSpecularity(img);
                imgf = hyst2d_3x(img,0.05,0.5);
            case 5
                if handles.chosenInputType ~= handles.TYPE.EYE
                    error('Corresponding vessel image does not exist!');
                end
                try
                    Vesselimage = imread([handles.ipPath(1:end-1) '_Vessel\' handles.ipFile(1:end-4) 'vessel.JPG']);
                catch
                    error('Corresponding vessel image does not exist!');
                end
                Vesselimage = im2bw(Vesselimage);
                Vesselimage = Vesselimage(handles.imageStack(1).Rect(2):handles.imageStack(1).Rect(2)+handles.imageStack(1).Rect(4)-1,handles.imageStack(1).Rect(1):handles.imageStack(1).Rect(1)+handles.imageStack(1).Rect(3)-1);
                imgf = ~Vesselimage;
                
        end
        
        if handles.SegmentationChoice ~= 5
            imgf(mask) = 0;
            imgf = bwareafilt(imgf,[50,dataSize]);
            % Attribute filtering
            stats = regionprops(imgf,'MajorAxisLength','MinorAxisLength','Solidity','PixelIdxList');
            for cf = 1:length(stats)
                if (((stats(cf).MajorAxisLength/stats(cf).MinorAxisLength)<2) && (stats(cf).Solidity>0.7))
                    imgf(stats(cf).PixelIdxList) = false;
                end
            end

            [diagImg,branchImg,branchStruct,numImg] = analyzeVessels(imgf,10,minorAxis,0.05);
            imgf = numImg>0;   
        else
            [diagImg,branchImg,branchStruct,numImg] = analyzeVessels(imgf,1,minorAxis,1);
            imgf = numImg>0;   
        end
        
        if val
            handles.manualSegStruct.DiagImg = diagImg;
            handles.manualSegStruct.BranchImg = branchImg;
            handles.manualSegStruct.BranchStruct = branchStruct;
            handles.manualSegStruct.NumImg = numImg;
            handles.manualSegStruct.Img = mat2gray(imgf);
            handles.manualSegStruct.Seg(handles.SegmentationChoice,1).DiagImg = diagImg;
            handles.manualSegStruct.Seg(handles.SegmentationChoice,1).BranchImg = branchImg;
            handles.manualSegStruct.Seg(handles.SegmentationChoice,1).BranchStruct = branchStruct;
            handles.manualSegStruct.Seg(handles.SegmentationChoice,1).NumImg = numImg;
            handles.manualSegStruct.Seg(handles.SegmentationChoice,1).Img = mat2gray(imgf);
        else
            handles.selectedSegStruct.DiagImg = diagImg;
            handles.selectedSegStruct.BranchImg = branchImg;
            handles.selectedSegStruct.BranchStruct = branchStruct;
            handles.selectedSegStruct.NumImg = numImg;
            handles.selectedSegStruct.Img = mat2gray(imgf);
            handles.selectedSegStruct.Seg(handles.SegmentationChoice,1).DiagImg = diagImg;
            handles.selectedSegStruct.Seg(handles.SegmentationChoice,1).BranchImg = branchImg;
            handles.selectedSegStruct.Seg(handles.SegmentationChoice,1).BranchStruct = branchStruct;
            handles.selectedSegStruct.Seg(handles.SegmentationChoice,1).NumImg = numImg;
            handles.selectedSegStruct.Seg(handles.SegmentationChoice,1).Img = mat2gray(imgf);
        end
        close(hb);
    else
        if val
            handles.manualSegStruct.DiagImg = handles.manualSegStruct.Seg(handles.SegmentationChoice,1).DiagImg;
            handles.manualSegStruct.BranchImg = handles.manualSegStruct.Seg(handles.SegmentationChoice,1).BranchImg;
            handles.manualSegStruct.BranchStruct = handles.manualSegStruct.Seg(handles.SegmentationChoice,1).BranchStruct;
            handles.manualSegStruct.NumImg = handles.manualSegStruct.Seg(handles.SegmentationChoice,1).NumImg;
            handles.manualSegStruct.Img = handles.manualSegStruct.Seg(handles.SegmentationChoice,1).Img;
        else
            handles.selectedSegStruct.DiagImg = handles.selectedSegStruct.Seg(handles.SegmentationChoice,1).DiagImg;
            handles.selectedSegStruct.BranchImg = handles.selectedSegStruct.Seg(handles.SegmentationChoice,1).BranchImg;
            handles.selectedSegStruct.BranchStruct = handles.selectedSegStruct.Seg(handles.SegmentationChoice,1).BranchStruct;
            handles.selectedSegStruct.NumImg = handles.selectedSegStruct.Seg(handles.SegmentationChoice,1).NumImg;
            handles.selectedSegStruct.Img = handles.selectedSegStruct.Seg(handles.SegmentationChoice,1).Img;
        end
    end
    handles = showSegInfo(handles,0); % Reset
    handles = showSegInfo(handles,1);
    handles = getCurrImg(handles,4);
    guidata(hObject,handles);
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

% --- Executes on button press in MarkerButton.
function MarkerButton_Callback(hObject, eventdata, handles)
% hObject    handle to MarkerButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if (~handles.imagesLoaded) && (~handles.resultsLoaded)
    return;
end

h = imfreehand(handles.SelectedFrameAxis);
position = wait(h); 
BW = createMask(h);
delete(h);
flag = get(handles.ToggleManualSelectionCheckbox,'Value');
if flag == 1
    handles.manualMaskedRegion = handles.manualMaskedRegion | BW;
    handles.manualMaskedRegion = handles.manualMaskedRegion & (handles.manualFrame(:,:,1)>0);
else
    handles.selectedMaskedRegion = handles.selectedMaskedRegion | BW;
    handles.selectedMaskedRegion = handles.selectedMaskedRegion & (handles.selectedFrame(:,:,1)>0);
end
handles = getCurrImg(handles,3);
guidata(hObject,handles);

end

% --- Executes on button press in RemoveMaskButton.
function RemoveMaskButton_Callback(hObject, eventdata, handles)
% hObject    handle to RemoveMaskButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if (~handles.imagesLoaded) && (~handles.resultsLoaded)
    return;
end
flag = get(handles.ToggleManualSelectionCheckbox,'Value');
if flag == 1
    tSize = size(handles.manualFrame);
    handles.manualMaskedRegion = false(tSize(1),tSize(2));
else
    tSize = size(handles.selectedFrame);
    handles.selectedMaskedRegion = false(tSize(1),tSize(2));
end
handles = getCurrImg(handles,3);
guidata(hObject,handles);

end

% --- Executes on button press in ManualFrameSelectionButton.
function ManualFrameSelectionButton_Callback(hObject, eventdata, handles)
% hObject    handle to ManualFrameSelectionButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% if ~handles.processed
%     return;
% end

try
    origScrnSize = get(0,'screensize');
    winSize = round(origScrnSize(4:-1:3)-200);
    
   
    if handles.manualSelectionChoice == 1
        numRows = 2;
        numCols = 3;
        numImagesPerTurn = numRows*numCols;
        numImages = handles.numChosenFrames;
        vect = 1:numImagesPerTurn:numImages;
        numTurns = length(vect);
%         if vect(end)==numImages
%             numTurns = numTurns - 1;
%         end
    else
        numRows = 1;
        numCols = 1;
        numImagesPerTurn = 1;
        numImages = handles.numInputImages;
        numTurns = numImages;
        chosenEyeList = struct('Img',cell(numImages,1),'Rect',cell(numImages,1));
        for cf = 1:handles.numChosenFrames
            chosenEyeList(handles.imageStack(cf).OrigFrameNum).Img = handles.imageStack(cf).Img;
            chosenEyeList(handles.imageStack(cf).OrigFrameNum).Rect = handles.imageStack(cf).Rect;
        end
    end
    currTurn = 1;
    
    sep = 10;
    buttonHeight = 30;
    buttonWidth = 80;
    tableWidth = round(winSize(2)/6);
    sliderWidth = winSize(2)-(4*sep+2*buttonWidth);
    axisHeight = round(winSize(1)/numRows)-sep-50;
    axisWidth = round((winSize(2)-tableWidth)/numCols)-sep;
    if handles.manualSelectionChoice == 1
        tableHeight = round(((numRows-1)*axisHeight + (numRows-2)*sep)/2);
    else
        tableHeight = 0.25*axisHeight;
    end
    
    
    isVid = handles.chosenInputType == handles.TYPE.MOV;
    
    if ~isempty(handles.fig)
        close(handles.fig);
    end
    
    handles.fig = figure('Units','Pixels',...
        'Position',[100, 100,winSize(2),...
        winSize(1)],...
        'Name','Choose Frames',...
        'DeleteFcn',{@windowClosing},...
        'Toolbar','none',...
        'Menubar','none',...
        'Visible','Off');
    
    bPrev = uicontrol(handles.fig,'Style',...
        'pushbutton',...
        'String',sprintf(sprintf('Previous %d',numRows*numCols)),...
        'Tag','prevButton',...
        'Units','Pixels',...
        'Position',[sep,sep,buttonWidth,buttonHeight],...
        'Callback',@prevCallback);
    
    imgSlider = uicontrol(handles.fig,'Style',...
        'slider',...
        'Tag','imgSlider',...
        'Units','Pixels',...
        'Position',[2*sep+buttonWidth,sep,sliderWidth,buttonHeight],...
        'Callback',@sliderCallback);
    
    bNext = uicontrol(handles.fig,'Style',...
        'pushbutton',...
        'String',sprintf(sprintf('Next %d',numRows*numCols)),...
        'Tag','nextButton',...
        'Units','Pixels',...
        'Position',[3*sep+sliderWidth+buttonWidth,sep,buttonWidth,buttonHeight],...
        'Callback',@nextCallback);
    
    if handles.manualSelectionChoice == 1
        currY = (numRows-1)*(axisHeight+sep)+(buttonHeight+2*sep);
    else
        currY = buttonHeight+2*sep;
    end
    
    if handles.manualSelectionChoice == 1
        hAxes = cell(numRows,numCols);
        hImages = cell(max(numImages,numImagesPerTurn),1);
        cnt = 1;
        imgVect = zeros(numImagesPerTurn,1);
        for rr = 1:numRows
            currX = sep;
            for cc = 1:numCols
                hAxes{rr,cc} = axes('Parent',handles.fig,'Units','Pixels',...
                    'Position',[currX,currY,axisWidth,axisHeight]);
                hImages{cnt} = imshow(handles.imageStack(cnt).OrigImg);
                set(hImages{cnt},'ButtonDownFcn',{@imgCallback,cnt});
                imgVect(cnt) = cnt;
                currX = currX + sep + axisWidth;
                cnt = cnt + 1;
                if cnt>handles.numChosenFrames
                    break;
                end
            end
            currY = currY - sep - axisHeight;
            if cnt>handles.numChosenFrames
                break;
            end
        end
    else
        hAxes = axes('Parent',handles.fig,'Units','Pixels',...
                    'Position',[sep,currY,axisWidth,axisHeight]);
        if handles.imagesLoaded
            hImages = imshow(handles.frameStruct.getFrame(1));        
        else
            hImages = imshow(handles.imgMat{1,1});        
        end
        
%         hImages = imshow(handles.imgMat{1,1});
        set(hImages,'ButtonDownFcn',{@imgCallback,1});
        imgVect = 1;
    end
    
    sTableData = [];
    chosenIdx = [];
    prevChosenIdx = [];
    sTableSelectedRow = [];
    currX = numCols*(sep+axisWidth)+sep;
    currY = 2*sep+buttonHeight;
    sTable = uitable(handles.fig,'Data',sTableData,...
        'ColumnName',{'Frame ID'},...
        'CellSelectionCallback',{@sTableCellSelect},...
        'Position',[currX,currY,tableWidth,tableHeight]);
    currX2 = currX;
    newButtonWidth = round(tableWidth/2)-(1.5*sep);
    currX = currX + sep;
    currY = currY + sep + tableHeight;
    bAdd = uicontrol(handles.fig,'Style',...
        'pushbutton',...
        'String',sprintf('Add Selection'),...
        'Tag','addButton',...
        'TooltipString','Add Selection',...
        'Units','Pixels',...
        'Position',[currX,currY,newButtonWidth,buttonHeight],...
        'Callback',@addCallback);
    currX = currX + newButtonWidth + sep;
    bDelete = uicontrol(handles.fig,'Style',...
        'pushbutton',...
        'String',sprintf('Delete Selection'),...
        'Tag','deleteButton',...
        'TooltipString','Delete Selection',...
        'Units','Pixels',...
        'Position',[currX,currY,newButtonWidth,buttonHeight],...
        'Callback',@deleteCallback);
    currY = currY+buttonHeight+sep;
    hAxes3Text = uicontrol(handles.fig,'Style',...
        'text',...
        'String','',...
        'Tag','hAxes2Text',...
        'TooltipString','Frame Number',...
        'Units','Pixels',...
        'Position',[currX - (newButtonWidth + sep),currY,buttonWidth,buttonHeight]);
    bConfirm = uicontrol(handles.fig,'Style',...
        'pushbutton',...
        'String',sprintf('Confirm Selection'),...
        'Tag','confirmButton',...
        'TooltipString','Confirm Selection',...
        'Units','Pixels',...
        'Position',[currX,currY,newButtonWidth,buttonHeight],...
        'Callback',@confirmCallback);
    currY = currY+buttonHeight+sep;
    sizeX = min(winSize(2)-currX2-sep,round((winSize(1)-currY-sep)/2));
    hAxes3 = axes('Parent',handles.fig,'Units','Pixels',...
        'Position',[currX2,currY,sizeX,sizeX]);
    currY = currY + sizeX + sep;
    hAxes2 = axes('Parent',handles.fig,'Units','Pixels',...
        'Position',[currX2,currY,sizeX,sizeX]);
    hAxes2Text = uicontrol(handles.fig,'Style',...
        'text',...
        'String','',...
        'Tag','hAxes2Text',...
        'TooltipString','Frame Number',...
        'Units','Pixels',...
        'Position',[currX2,...
        currY+sizeX+sep,sizeX,buttonHeight]);
    % him = imshow(ones(100,100)*255);
    
    
    movegui(handles.fig,'center');
    set(handles.fig,'Visible','On');
    set(handles.fig,'Resize','Off');
    guidata(hObject,handles);
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

    function windowClosing(src,~)
        % global tempResults
        clear chosenEyeList 
        handles.fig = [];
        guidata(hObject,handles);
    end

    function prevCallback(src, eventdata)
        if currTurn > 1
            currTurn = currTurn - 1;
            set(imgSlider,'Value',(currTurn-1)/(numTurns-1));
            getImages();
        end
    end

    function nextCallback(src, eventdata)
        if currTurn < numTurns
            currTurn = currTurn + 1;
            set(imgSlider,'Value',(currTurn-1)/(numTurns-1));
            getImages();
        end
    end

    function confirmCallback(src, eventdata)    
        sTableData = get(sTable,'Data');
        if ~isempty(sTableData)
            choice = questdlg('Do you want to confirm the choices?', ...
                'Confirm Menu', ...
                'Yes','No','No');
            switch choice
                case 'Yes'
                    % Confirm the choices
                    len = size(sTableData,1);
                    handles.manualImageStack = struct('Img',cell(len,1),'OrigImg',cell(len,1));
                    for ccf = 1:len
                        if handles.manualSelectionChoice == 1
                            handles.manualImageStack(ccf).OrigImg = handles.imageStack(sTableData(ccf,1)).OrigImg;
                            handles.manualImageStack(ccf).Img = handles.imageStack(sTableData(ccf,1)).Img;
                        else
                            if handles.imagesLoaded
                                handles.manualImageStack(ccf).OrigImg = handles.frameStruct.getFrame(sTableData(ccf,1));
                            else
                                handles.manualImageStack(ccf).OrigImg = handles.imgMat{sTableData(ccf,1),1};
                            end
                            handles.manualImageStack(ccf).Img = chosenEyeList(sTableData(ccf,1)).Img;
                        end
                    end
                    if len>1
                        handles.manualImageStack = registerEyeRegion( handles.manualImageStack);
                    end
                    %                         manualMask = getMask(handles.manualImageStack(1).Img);
                    if ~isempty(handles.manualImageStack)
                        if len>1
                            mask = handles.manualImageStack(1).Img(:,:,1)>0;
                            hb = waitbar(0,'Please wait while the frames are fused','WindowStyle','modal');
                            
                            % lpsr based fusion method below ---
                            handles.manualFrame = fuse(handles.manualImageStack);
                            % lpsr based fusion method end ---
                            
% % %                             % min fusion method below ---
% % %                             imSize = size(handles.manualImageStack(1).Img);
% % %                             handles.manualFrame = 255*ones(imSize(1),imSize(2),imSize(3));
% % %                             for cfn = 1:len
% % %                                 handles.manualFrame = min(handles.manualFrame,handles.manualImageStack(cfn).Img);
% % %                             end
% % %                             % min fusion method end -----

                            h1 = fspecial('gaussian',[15 15],3);
                            %                                 img2 = rgb2lab(uint8(handles.manualFrame));
                            %                                 img2 = imfilter(img2(:,:,2),h1);
                            %                                 mask = img2>0.3*max(img2(:));
                            %                                 mask = handles.manualFrame(:,:,1)>0.1;
                            %                                 mask = imfill(mask,'holes');
                            handles.manualFrame = handles.manualFrame.*repmat(mask,[1,1,3]);
                            handles.manualFrame = uint8(mat2gray(handles.manualFrame)*255);
                            close(hb);
                            
                            handles.manualFrame = preproc(handles.manualFrame);
                            
                        else
                            handles.manualFrame = handles.manualImageStack(1).Img;
                        end
%                         handles.manualFrame = preproc(handles.manualFrame);
                        tSize = size(handles.manualFrame);
                        handles.manualMaskedRegion = false(tSize(1),tSize(2));
                        handles.manualSpecularMask = getSpecularityMask(handles.manualFrame);
                        %                             set(handles.SelectedFrameHandle,'CData',handles.manualFrame);
                        set(handles.ToggleManualSelectionCheckbox,'Value',1);
                        handles = getCurrImg(handles,3);
                        set(handles.SegmentedImageHandle,'CData',ones(size(handles.manualFrame)));
                        handles.manualAvailable = true;
                        handles.manualSegStruct.Img = [];
                        %                             handles.manualFrame = uint8(double(handles.manualFrame).*repmat(manualMask,[1,1,3]));
                        
                    else
                        errordlg('Registration problem. Choose other frames.');
                    end
                    clear chosenEyeList 
                    close(handles.fig);
                    delete(handles.fig);
                    handles.fig = [];
                    guidata(hObject,handles);
                otherwise
                    % Do nothing
            end
        end
    end

    function addCallback(src, eventdata)
        sTableData = get(sTable,'Data');
        if handles.manualSelectionChoice == 1
            tmpIdx = imgVect(chosenIdx);
        else
            if ~isempty(chosenEyeList(imgVect).Img)
                tmpIdx = imgVect;
            else
                tmpIdx = 0;
            end
        end
        if tmpIdx > 0
            if ~isempty(sTableData)
                duplicateFound = false;
                for ccf = 1:size(sTableData,1)
                    if sTableData(ccf,1) == tmpIdx
                        duplicateFound = true;
                        break;
                    end
                end
                if duplicateFound
                    msgbox('Already added the frame');
                    return;
                end
            end
            sTableData = [sTableData;tmpIdx];
            set(sTable,'Data',sTableData);
        end
    end

    function deleteCallback(src, eventdata)
        if ~isempty(sTableSelectedRow)
            choice = questdlg(sprintf('Do you want to delete row %d from list?',sTableSelectedRow), ...
                'Delete Menu', ...
                'Yes','No','No');
            switch choice
                case 'Yes'
                    sTableData = get(sTable,'Data');
                    if size(sTableData,1)>1
                        if sTableSelectedRow == 1
                            sTableData = sTableData(2:end,:);
                        elseif sTableSelectedRow == size(sTableData,1)
                            sTableData = sTableData(1:end-1,:);
                        else
                            sTableData = [sTableData(1:sTableSelectedRow-1,:);sTableData(sTableSelectedRow+1:end,:)];
                        end
                    else
                        sTableData = [];
                    end
                    set(sTable,'Data',sTableData);
                    set(hAxes3Text,'String','');
                    axes(hAxes3);
                    imshow(handles.blankImg);
                    sTableSelectedRow = [];
                otherwise
                    % Do nothing
            end
        end
    end

    function sliderCallback(src, eventdata)
        val = get(src,'Value');
        currTurn = round((numTurns-1)*val+1);
        getImages();
    end
    
    function imgCallback(src, eventdata,n)
        if handles.manualSelectionChoice == 1
            if imgVect(n)>0
                prevChosenIdx = chosenIdx;
                chosenIdx = n;
                if ~isempty(prevChosenIdx)
                    set(hImages{prevChosenIdx},'CData',handles.imageStack(imgVect(prevChosenIdx)).OrigImg);
                end
                imSize = size(handles.imageStack(imgVect(chosenIdx)).OrigImg);
                set(hImages{n},'CData',insertShape(handles.imageStack(imgVect(chosenIdx)).OrigImg,'Rectangle',[6,6,imSize(2)-6,imSize(1)-6],'LineWidth',6));
                axes(hAxes2);
                imshow(handles.imageStack(imgVect(n)).Img);
                if isVid
                    currTime = handles.imgMat{handles.imageStack(imgVect(chosenIdx)).OrigFrameNum,2};
                    set(hAxes2Text,'String',sprintf('Selected Frame: %d (%.2f)',imgVect(n),currTime));
                else
                    set(hAxes2Text,'String',sprintf('Selected Frame: %d',imgVect(n)));
                end
            end
        else
            chosenIdx = imgVect;
            % for original image
            if handles.imagesLoaded
                imgR = handles.frameStruct.getFrame(chosenIdx);
            else
                imgR = handles.imgMat{chosenIdx,1};
            end            
            if isempty(chosenEyeList(chosenIdx).Rect)
                chosenEyeList(chosenIdx) = getChosenEyes(imgR,false);
            end
            if ~isempty(chosenEyeList(chosenIdx).Img)
                set(hImages,'CData',insertShape(imgR,'Rectangle',chosenEyeList(chosenIdx).Rect,'LineWidth',6));
                axes(hAxes2);
                imshow(chosenEyeList(chosenIdx).Img);
                if isVid
                    currTime = handles.imgMat{chosenIdx,2};
                    set(hAxes2Text,'String',sprintf('Selected Frame: %d (%.2f)',imgVect,currTime));
                else
                    set(hAxes2Text,'String',sprintf('Selected Frame: %d',imgVect));
                end
            else
                chosenEyeList(chosenIdx).Rect = 0;
                errordlg('No eye candidate found!');
            end
        end
    end
    
    function sTableCellSelect(src, eventdata)
        indices = eventdata.Indices;
        data = get(src,'Data');
        r = indices(:,1);
        if ~isempty(r)
            sTableSelectedRow = r;
            
            if handles.manualSelectionChoice == 1
                k1 = find(vect==data(r,1),1);
                if isempty(k1)
                    k1 = find(vect>data(r,1),1);
                    if isempty(k1)
                        k1 = length(vect);
                    else
                        k1 = k1-1;
                    end
                end
%                 currTurn = k1;
%                 set(imgSlider,'Value',(currTurn-1)/(numTurns-1));
%                 getImages();
                axes(hAxes3);
                imshow(handles.imageStack(data(r,1)).Img);
            else
                % for original image
%                 currTurn = data(r,1);
%                 set(imgSlider,'Value',(currTurn-1)/(numTurns-1));
%                 getImages();
                axes(hAxes3);
                imshow(chosenEyeList(data(r,1)).Img);
            end
            set(hAxes3Text,'String',sprintf('Frame: %d',data(r,1)));
        end
    end

    function getImages()
        sTableSelectedRow = [];
        chosenIdx = [];
        prevChosenIdx = [];
        set(hAxes2Text,'String','');
        axes(hAxes2);
        imshow(handles.blankImg);
        ccnt = 0;
        if currTurn == numTurns
            if handles.manualSelectionChoice == 1
                for ccf = vect(currTurn):numImages
                    ccnt = ccnt + 1;
                    set(hImages{ccnt},'CData',handles.imageStack(ccf).OrigImg);
                    imgVect(ccnt) = ccf;                    
                end
                if ccnt<numImagesPerTurn
                    for ccf = ccnt+1:numImagesPerTurn
                        set(hImages{ccf},'CData',handles.imageStack(ccnt).OrigImg*255);
                        imgVect(ccf) = 0;
                    end
                end
            else
                if handles.imagesLoaded
                    set(hImages,'CData',handles.frameStruct.getFrame(currTurn));
                else
                    set(hImages,'CData',handles.imgMat{currTurn,1});
                end
                imgVect = currTurn;
            end
        else
            if handles.manualSelectionChoice == 1
                for ccf = vect(currTurn):vect(currTurn+1)-1
                    ccnt = ccnt + 1;
                    set(hImages{ccnt},'CData',handles.imageStack(ccf).OrigImg);
                    imgVect(ccnt) = ccf;                    
                end
            else
                if handles.imagesLoaded
                    set(hImages,'CData',handles.frameStruct.getFrame(currTurn));
                else
                    set(hImages,'CData',handles.imgMat{currTurn,1});
                    
                end
                imgVect = currTurn;
            end
        end
        
    end

end


% --- Executes on selection change in SegmentationChoicePopup.
function SegmentationChoicePopup_Callback(hObject, eventdata, handles)
% hObject    handle to SegmentationChoicePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SegmentationChoicePopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SegmentationChoicePopup

handles.SegmentationChoice = get(hObject,'Value');
guidata(hObject,handles);

end

% --- Executes during object creation, after setting all properties.
function SegmentationChoicePopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SegmentationChoicePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on selection change in ManualSelectionChoicePopup.
function ManualSelectionChoicePopup_Callback(hObject, eventdata, handles)
% hObject    handle to ManualSelectionChoicePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns ManualSelectionChoicePopup contents as cell array
%        contents{get(hObject,'Value')} returns selected item from ManualSelectionChoicePopup

handles.manualSelectionChoice = get(hObject,'Value');
guidata(hObject,handles);

end


% --- Executes during object creation, after setting all properties.
function ManualSelectionChoicePopup_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ManualSelectionChoicePopup (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes on button press in VesselSkeletonCheckbox.
function VesselSkeletonCheckbox_Callback(hObject, eventdata, handles)
% hObject    handle to VesselSkeletonCheckbox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of VesselSkeletonCheckbox

if ~handles.processed
    set(hObject,'Value',0);
    return;
end
try
    handles = getCurrImg(handles,4);
    guidata(hObject,handles);
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

%%%%% ALL IMAGE PROCESSING CODES - STAR

function [handles] = extractEyeRegionEx(handles)

try
%     waitbarHandle = waitbar(0,'Extracting eye regions...');
%     stdFun = @(x) (std(x));
    stdFun2 = @(x) (std(x)./mean(x));
    
    circularHoughThresh = 1.5;
    
    radii = 10:1:50;
    radiiMult = 1.2;
    
 load modelparameters.mat
 
 blocksizerow    = 30;
 blocksizecol    = 30;
 blockrowoverlap = 0;
 blockcoloverlap = 0;     
    
    h1 = fspecial('gaussian',[15 15],3);
    h2 = strel('disk',19);
    % se = strel('disk',9);
    h21 = strel('disk',5);
    
    numFrames = handles.frameStruct.NumFrames;
    isNotVid = handles.chosenInputType ~= handles.TYPE.MOV;
    handles.imageStack = [];
    % imgo = imread([filePath '\' frames{1}]);
    if (handles.chosenInputType == handles.TYPE.BFM) || (handles.chosenInputType == handles.TYPE.EYE)
        imgo = handles.ManualBFM;
    else
        imgo = handles.frameStruct.getFrame(1);
    end
    imSize = size(imgo);
    if imSize(1)<=135
        imScale = 1;
    elseif imSize(1)<=1080
        imScale = 0.2;
    elseif imSize(1)<=1800
        imScale = 0.125;
    else
        imScale = 0.08;
    end
    % videoObj.CurrentTime = fc / videoObj.FrameRate;
    % while hasFrame(videoObj)
    eyeStruct = struct('Pos',cell(numFrames,1));
    handles.imgMat = cell(numFrames,2);
    % handles.imgMat{1,1} = imresize(imgo, imScale);
    totEyes = 0;
    isRelaxed = get(handles.RelaxationCheckBox,'Value');
    for cf = 1:numFrames
        if cf > 1
            imgo = handles.frameStruct.getFrame(cf);
        end
        if isempty(imgo)
            continue;
        end
        if isNotVid
            % Frames may be inconsistent
            if sum(abs(size(imgo)-imSize))>0
                imgo = imresize(imgo,imSize(1:2));
            end
            if size(imgo,3)<3
                imgo = repmat(imgo,[1,1,3]);
            end
        end
        img = imresize(imgo, imScale);
        imgMask = img(:,:,1)>20;
        if sum(imgMask(:))==0 
            continue;
        end
        imgMask = imerode(bwareafilt(imfill(imgMask,'holes'),1),h21);
        handles.imgMat{cf,1} = img;
        if ~isNotVid % Save the timestamps %% Solve "index exceeds matrix dimension" error problem
            try
                handles.imgMat{cf,2} = handles.frameStruct.CurrentTime(cf);
            catch
%                 handles.imgMat{cf,2} = handles.frameStruct.CurrentTime(end);
                for cf_i = cf:numFrames
                    handles.imgMat{cf_i,1} = handles.imgMat{cf,1};
                    handles.imgMat{cf_i,2} = handles.frameStruct.CurrentTime(end);
                end
%                 handles.imgMat{cf,2} = handles.frameStruct.CurrentTime(cf);
            end
        end
        img = imfilter(img(:,:,1),h1);
        img = colfilt(double(img), [9 9], 'sliding', stdFun2);
        img(isnan(img)) = 0;
        %     im = rgb2gray(img);
        tSize = size(img);
        e = edge(img, 'canny');
        e(~imgMask) = false;
        h = circle_hough(e, radii, 'same', 'normalise');
        peak = circle_houghpeaks(h, radii, 'nhoodxy', 15, 'nhoodr', 21, 'npeaks', 5, ...
            'Threshold',circularHoughThresh);
        
        if ~isempty(peak)
            cfhCnt = 0;
            for cfh = 1:size(peak,2)
                [x, y] = circlepoints(peak(3,cfh)*radiiMult); % take more location
                minX = min(x);
                maxX = max(x);
                minY = min(y);
                maxY = max(y);
                
                sizeScaleY = imSize(1)/tSize(1);
                sizeScaleX = imSize(2)/tSize(2);
                
                maxY = round((maxY + peak(2,cfh))*sizeScaleY);
                minY = round((minY + peak(2,cfh))*sizeScaleY);
                maxX = round((maxX + peak(1,cfh))*sizeScaleX);
                minX = round((minX + peak(1,cfh))*sizeScaleX);
                if minY<1
                    minY = 1;
                end
                if maxY>imSize(1)
                    maxY = imSize(1);
                end
                if minX<1
                    minX = 1;
                end
                if maxX>imSize(2)
                    maxX = imSize(2);
                end
                biasX = minX; biasY = minY;
                img2 = imgo(minY:maxY,minX:maxX,:);
                imSize2 = size(img2);
                img22 = imresize(rgb2gray(img2),imScale);
                tSize2 = size(img22);
                e2 = edge(img22,'canny');
                h = circle_hough(e2, radii, 'same', 'normalise');
                [peak2,v] = circle_houghpeaks(h, radii, 'nhoodxy', 15, 'nhoodr', 21, 'npeaks', 1);
                
                if isempty(peak2)
                    continue;
                end
                
                
                [x, y] = circlepoints(peak2(3)+2); % take more location (2 pixels bias to avoid close cutoffs)
                currX = x+peak2(1);
                currY = y+peak2(2);
                
                if isRelaxed
                    idx = currY<1;
                    currY(idx) = 1;
                    idx = currX<1;
                    currX(idx) = 1;
                    idx = currY>tSize2(1);
                    currY(idx) = tSize2(1);
                    idx = currX>tSize2(2);
                    currX(idx) = tSize2(2);
                    flag = 4;
                else
                    flag = (min(currY)>=1) + (max(currY)<=tSize2(1)) + (min(currX)>=1) + (max(currX)<=tSize2(2));
                end
                if flag == 4
                    sizeScaleY = imSize2(1)/tSize2(1);
                    sizeScaleX = imSize2(2)/tSize2(2);
                    currY = round(currY*sizeScaleY);
                    currX = round(currX*sizeScaleX);
                    currY(currY>imSize2(1)) = imSize2(1);
                    currX(currX>imSize2(2)) = imSize2(2);
                    Ym2 = min(currY);
                    YM2 = max(currY);
                    Xm2 = min(currX);
                    XM2 = max(currX);
                    %             imco = imgo(Ym:YM,Xm:XM,:);
                    imco2 = img2;
                    maskXO = true(imSize2(1:2));
                    [~,indx] = sort(x);
                    for cc = 1:length(x)
                        if x(indx(cc))<0
                            if y(indx(cc))<0
                                imco2(1:currY(indx(cc)),1:currX(indx(cc)),:) = 0;
                                maskXO(1:currY(indx(cc)),1:currX(indx(cc))) = false;
                            else
                                imco2(currY(indx(cc)):end,1:currX(indx(cc)),:) = 0;
                                maskXO(currY(indx(cc)):end,1:currX(indx(cc))) = false;
                            end
                        else
                            if y(indx(cc))<0
                                imco2(1:currY(indx(cc)),currX(indx(cc)):end,:) = 0;
                                maskXO(1:currY(indx(cc)),currX(indx(cc)):end) = false;
                            else
                                imco2(currY(indx(cc)):end,currX(indx(cc)):end,:) = 0;
                                maskXO(currY(indx(cc)):end,currX(indx(cc)):end) = false;
                            end
                        end
                    end
                    
                    Ym = Ym2 + biasY;
                    YM = YM2 + biasY;
                    if YM>imSize(1)
                        YM2 = YM2-(YM-imSize(1));
                        YM = imSize(1);
                    end
                    Xm = Xm2 + biasX;
                    XM = XM2 + biasX;
                    if XM>imSize(2)
                        XM2 = XM2-(XM-imSize(2));
                        XM = imSize(2);
                    end
                    
                    imco = imco2(Ym2:YM2,Xm2:XM2,:);
                    eyeSize = size(imco);
                    imcoh = img2(Ym2:YM2,Xm2:XM2,:);
                    imglab = rgb2lab(uint8(imco));
                    imglab = imfilter(imglab(:,:,2),h1);
                    maskX = imglab>0.3*max(imglab(:));
                    maskX = imfill(maskX,'holes');
                    sumX = sum(maskX(:));
                    sumO = sum(sum(rgb2gray(imco)>0));
                    if sumX<(0.5*sumO)
                        continue;
                    end
                    
                    
                    tmp1 = imcoh(:,:,1);
                    meanIN = mean(tmp1(maskX));
                    maskXD = imdilate(maskX,h2) & (~maskX);
                    meanOUT = mean(tmp1(maskXD));
                    R3 = meanIN - meanOUT;
                    stats = regionprops(bwareafilt(maskX,1),'Solidity');
                    if (R3<10) || (stats.Solidity <= 0.7)
                        continue;
                    end
                    
                    
                    
                    
% %                     % Sharpness
% %                     imgs = double(imgo(:,:,1));
% %                     ctr = round(eyeSize(1:2)/2);
% %                     h = fspecial('average',round(ctr*0.2));
% %                     a2 = abs(imgs-imfilter(imgs,h));
% %                     a2 = a2(Ym:YM,Xm:XM).*maskX;
% %                     a = fft2(a2);
                    
                    % IQA
                    imgotmp = double(imgo); % imgo, the whole image;
                    imgs = zeros(YM-Ym+1,XM-Xm+1,3);
%                     imgs(:,:,1) = imgotmp(Ym:YM,Xm:XM,1).*maskX;
%                     imgs(:,:,2) = imgotmp(Ym:YM,Xm:XM,2).*maskX;
%                     imgs(:,:,3) = imgotmp(Ym:YM,Xm:XM,3).*maskX; % imgs, eye region image;
                    
                    
                    imgs(:,:,1) = imgotmp(Ym:YM,Xm:XM,1);
                    imgs(:,:,2) = imgotmp(Ym:YM,Xm:XM,2);
                    imgs(:,:,3) = imgotmp(Ym:YM,Xm:XM,3); % imgs, eye region image;
                                        
                    imgs = imresize(imgs,[150,150]);
                    
                    [Qg1,Qch1]=blindimagequality(imgs);
                    

                    
imgs = uint8(imgs);
quality1 = computequality(imgs,blocksizerow,blocksizecol,blockrowoverlap,blockcoloverlap, ...
    mu_prisparam,cov_prisparam);          
                    

                    
                    tmp1 = Qg1*10000; 
                    tmp2 = 1000-quality1;
                    
                    a = tmp1+tmp2;

                    
                    
                    cfhCnt = cfhCnt + 1;
                    totEyes = totEyes + 1;
                    eyeStruct(cf).Pos(cfhCnt).Img = imco;
                    eyeStruct(cf).Pos(cfhCnt).OrigImg = imgo;
                    eyeStruct(cf).Pos(cfhCnt).Num = cf;
                    eyeStruct(cf).Pos(cfhCnt).Rect = [Xm,Ym,XM-Xm+1,YM-Ym+1];
                    eyeStruct(cf).Pos(cfhCnt).R3 = R3;
                    eyeStruct(cf).Pos(cfhCnt).MeanOUT = meanOUT;
                    eyeStruct(cf).Pos(cfhCnt).Sharpness = abs(a(1,1));
                    eyeStruct(cf).Pos(cfhCnt).HOGv = v;
                    eyeStruct(cf).Pos(cfhCnt).Solidity = stats.Solidity;
                    %                 eyeStruct(cf).Pos(cfCnt).Cnt = totEyes;
                    eyeStruct(cf).Pos(cfhCnt).Chosen = false;
                    MOArr(totEyes) = meanOUT;
                    R3Arr(totEyes) = R3;
                    %                 SpArr(totEyes) = a(ctr(1),ctr(2));
                    HogArr(totEyes) = v;
                end
            end
        end
        
        %     waitbar(fc / videoObj.FrameRate / videoObj.Duration, waitbarHandle, 'Extracting eye regions...');
%         waitbar(cf / numFrames, waitbarHandle, 'Extracting eye regions...');
    end
%     delete(waitbarHandle);
    
    
    if totEyes>0
        frameUsed = zeros(numFrames,3); % Keep track of duplicate frames
        medValR3 = median(R3Arr);
        medValMO = median(MOArr);
        medValMO = min(medValMO*1.5,medValMO+20);
        medValHog = min(median(HogArr),2.5);
        
        clear SpArr;
        cnt = 0;
        for cf = 1:numel(eyeStruct)
            for cf2 = 1:numel(eyeStruct(cf).Pos)
                addThisFrame = false;
                % check 1 - R3
                chR3 = (eyeStruct(cf).Pos(cf2).MeanOUT<medValMO) &&...
                    (eyeStruct(cf).Pos(cf2).R3>=medValR3);
                
                % check 3 - hog peak
                chHog = eyeStruct(cf).Pos(cf2).HOGv>medValHog;
                if chR3 && chHog
                    if (frameUsed(eyeStruct(cf).Pos(cf2).Num,1) == 0) % if not already added any frames
                        addThisFrame = true;
                    elseif (eyeStruct(cf).Pos(cf2).R3>frameUsed(eyeStruct(cf).Pos(cf2).Num,2))
                        addThisFrame = true;
                    end
                end
                if addThisFrame
                    cnt = cnt + 1;
                    eyeStruct(cf).Pos(cf2).Chosen = true;
                    if (frameUsed(eyeStruct(cf).Pos(cf2).Num,1) > 0)
                        SpArr(frameUsed(eyeStruct(cf).Pos(cf2).Num,3)) = eyeStruct(cf).Pos(cf2).Sharpness;
                        eyeStruct(cf).Pos(frameUsed(eyeStruct(cf).Pos(cf2).Num,1)).Chosen = false;
                        cnt = cnt - 1;
                    else
                        SpArr(cnt) = eyeStruct(cf).Pos(cf2).Sharpness;
                    end
                    frameUsed(eyeStruct(cf).Pos(cf2).Num,1) = cf2;
                    frameUsed(eyeStruct(cf).Pos(cf2).Num,2) = eyeStruct(cf).Pos(cf2).R3;
                    frameUsed(eyeStruct(cf).Pos(cf2).Num,3) = cnt;
                end
            end
        end
        clear frameUsed;
        
        if cnt>0
            [~,idx] = sort(SpArr,'descend');
            [~,idx2] = sort(idx);
            imageStack = struct('Img',cell(cnt,1),...
                'OrigImg',cell(cnt,1),...
                'OrigFrameNum',cell(cnt,1),...
                'Rect',cell(cnt,1));
            
            imgCnt = cnt;
            cnt = 0;
            for cf = 1:numel(eyeStruct)
                for cf2 = 1:numel(eyeStruct(cf).Pos)
                    if eyeStruct(cf).Pos(cf2).Chosen
                        cnt = cnt + 1;
                        pos = idx2(cnt);
                        imageStack(pos).Img = eyeStruct(cf).Pos(cf2).Img;
                        imageStack(pos).OrigImg = eyeStruct(cf).Pos(cf2).OrigImg;
                        imageStack(pos).OrigFrameNum = eyeStruct(cf).Pos(cf2).Num;
                        imageStack(pos).Rect = eyeStruct(cf).Pos(cf2).Rect;
                    end
                end
            end
            len = min(imgCnt,50);
            handles.imageStack = imageStack(1:len);
        end
        
        clear imageStack eyeStruct SpArr R3Arr HogArr
    end
catch ME
%     rethrow(ME);
    errordlg(ME.message);
    makeLog(ME);
end

end

% function [imageStack,selectedFrameIdx,len] = extractEyeRegionEx(handles)
% %EXTRACTEYEREGION extract eyeregion
% %   
% %   Extract useful regions from each of the frames, and select useful
% %   frames according to a criterior of each's usefulness.
% %
% %   criterion: criterion of selecting good frames
% %       Possible options
% %
% %   Return:
% %       imageStack: useful images sorted by the descending order of blur
% %       imgCnt: total number of useful images extracted
% %
% 
% if ~handles.imagesLoaded
%     imageStack = [];
%     selectedFrameIdx = [];
%     len = 0;
%     return;
% end
% 
% waitbarHandle = waitbar(0,'Extracting eye regions...');
% stdFun = @(x) (std(x));
% 
% circularHoughThresh = 2.5;
% 
% radii = 15:1:40;
% radiiGap = 1;
% 
% grp = 1;
% imgCnt = 0;
% 
% h1 = fspecial('gaussian',[15 15],3);
% h2 = strel('disk',19);
% se = strel('disk',9);
% 
% % frame count
% % fc = 350;
% fc = 1;
% prevfc = fc-1;
% % start from the beginning
% 
% 
% 
% imageStack = struct('Img',cell(handles.numInputImages,1),...
%     'OrigImg',cell(handles.numInputImages,1),...
%     'BlurVal',cell(handles.numInputImages,1),...
%     'OrigFrameNum',cell(handles.numInputImages,1),...
%     'MeanIN',cell(handles.numInputImages,1),...
%     'MeanOUT',cell(handles.numInputImages,1),...
%     'Rect',cell(handles.numInputImages,1),...
%     'HsiIN',cell(handles.numInputImages,1),...
%     'HsiOUT',cell(handles.numInputImages,1),...
%     'R1',cell(handles.numInputImages,1),...
%     'R2',cell(handles.numInputImages,1));
% 
% fileName = handles.imgMat{1,2};
% origSeparator = strfind(fileName,'.');
% origSeparator = origSeparator(end);
% dir1 = dir([handles.ipPath,filesep,fileName(1:origSeparator-1),'*']);
% if isempty(dir1)
%     error('Full resolution for first file not found!');
% end
% fileName = dir1(1).name;
% separator = strfind(fileName,'.');
% extn = fileName(separator(end)+1:end);
% % imgo = handles.imgMat{1,1};
% imgo = imread(fullfile(handles.ipPath,dir1(1).name));
% imSize = size(imgo);
% if imSize(1)<=1080
%     imScale = 0.2;
% elseif imSize(1)<=1800
%     imScale = 0.125;
% else
%     imScale = 0.08;
% end
% % videoObj.CurrentTime = fc / videoObj.FrameRate;
% % while hasFrame(videoObj)
% for cf = 1:handles.numInputImages
%     fileName = handles.imgMat{cf,2};
%     fileName = fileName(1:origSeparator-1);
%     imgo = imread(fullfile(handles.ipPath,[fileName,'.',extn]));
%     imSize = size(imgo);
%     img = imresize(imgo, imScale);
%     img = colfilt(double(img(:,:,1)), [9 9], 'sliding', stdFun);
%     %     im = rgb2gray(img);
%     tSize = size(img);
%     e = edge(img, 'canny');
%     h = circle_hough(e, radii, 'same', 'normalise');
%     peak = circle_houghpeaks(h, radii, 'nhoodxy', 15, 'nhoodr', 21, 'npeaks', 1, ...
%         'Threshold',circularHoughThresh);
%     
%     if ~isempty(peak)
%         [x, y] = circlepoints(peak(3) + radiiGap); % take more location
%         currX = x+peak(1);
%         currY = y+peak(2);
%         
%         flag = (min(currY)>=1) + (max(currY)<=tSize(1)) + (min(currX)>=1) + (max(currX)<=tSize(2));
%         if flag==4
%             sizeScaleY = imSize(1)/tSize(1);
%             sizeScaleX = imSize(2)/tSize(2);
%             currY = round(currY*sizeScaleY);
%             currX = round(currX*sizeScaleX);
%             currY(currY>imSize(1)) = imSize(1);
%             currX(currX>imSize(2)) = imSize(2);
%             Ym = min(currY);
%             YM = max(currY);
%             Xm = min(currX);
%             XM = max(currX);
% %             imco = imgo(Ym:YM,Xm:XM,:);
%             imco2 = imgo;
%             [~,indx] = sort(x);
%             for cc = 1:length(x)
%                 if x(indx(cc))<0
%                     if y(indx(cc))<0
%                         imco2(1:currY(indx(cc)),1:currX(indx(cc)),:) = 0;
%                     else
%                         imco2(currY(indx(cc)):end,1:currX(indx(cc)),:) = 0;
%                     end
%                 else
%                     if y(indx(cc))<0
%                         imco2(1:currY(indx(cc)),currX(indx(cc)):end,:) = 0;
%                     else
%                         imco2(currY(indx(cc)):end,currX(indx(cc)):end,:) = 0;
%                     end
%                 end
%             end
%             imco = imco2(Ym:YM,Xm:XM,:);
%             img2 = rgb2lab(uint8(imco));
%             img3 = rgb2hsv(uint8(imco));
%             img2 = imfilter(img2(:,:,2),h1);
%             maskX = img2>0.3*max(img2(:));
% %             maskX = imfill(imopen(maskX,se),'holes');
%             maskX = imfill(maskX,'holes');
%             sumX = sum(maskX(:));
%             sumO = sum(sum(rgb2gray(imco)>0));
%             if sumX<(0.5*sumO)
%                 continue;
%             end
%             maskXD = imdilate(maskX,h2) & (~maskX);
%             meanIN = zeros(1,3); meanOUT = meanIN;
% 
%             for chc = 1:3
%                 tmp1 = img3(:,:,chc);
%                 if chc == 1
%                    tmp1 = sin(tmp1*pi); 
%                 end
%                 meanIN(chc) = mean(tmp1(maskX));
%                 meanOUT(chc) = mean(tmp1(maskXD));
%                 if chc == 3
%                     hsiIN = mean(tmp1(maskX));
%                     hsiOUT = mean(tmp1(maskXD));
%                 end
%             end
%             imco = double(imco).*repmat(maskX,[1 1 3]);            
%             
%             %imco2 = colfilt(imco(:,:,1)/sum(sum(imco(:,:,1))),[9 9],'sliding',fun1);
%             %tVar = 10000000*mean(imco2(:));
%             
%             if abs(fc - prevfc) > 3
%                 % comment out for total image count (instead of group-wise)
%                 %imgCnt = 1; 
%                 grp = grp + 1;
%             end
%             prevfc = fc;
%             
%             
% %             imwrite(uint8(imco), sprintf('%s/Grp%03d_img%06d.png', rawOutputDir, grp, imgCnt));
% %             imwrite(uint8(imco),sprintf('%s/Grp%03d_img%06d_var%s.png',dir2,grp,imgCnt,num2str(tVar)));
% %           imwrite(uint8(imco),sprintf('%s/img%06d_var%s.png',dir2,cf,num2str(tVar)));
%             
% %             criterionPassed = false;
% %             switch handles.criterion
% %                 case 'Blur Metric'
%                     blurness = blurMetric(rgb2gray(mat2gray(imco, [0, 255])));
% %                     if blurness >= threshold
% % %                         fprintf('%d selected\n', fc);
% %                         criterionPassed = true;
% %                     end
% %                 case 'BotHat'
% %                     imgt = rgb2gray(mat2gray(imco, [0, 255]));
% %                     mask = imerode(imgt>0,se);
% %                     img2 = imbothat(imgt,se);
% %                     blurness = var(double(img2(mask)));
% % %                     criterionPassed = true;
% %                 otherwise
% %                     error('Unknown criterion');
% %             end
%             
%             
% %             imgSelected = criterionPassed; % & others if included
% %             if imgSelected
%                 imgCnt = imgCnt + 1;
%                 imageStack(imgCnt).Img = uint8(imco);
%                 imageStack(imgCnt).OrigImg = imgo;
%                 imageStack(imgCnt).BlurVal = blurness;
%                 imageStack(imgCnt).OrigFrameNum = cf;
%                 imageStack(imgCnt).MeanIN = meanIN;
%                 imageStack(imgCnt).MeanOUT = meanOUT;
%                 imageStack(imgCnt).Rect = [Xm,Ym,XM-Xm+1,YM-Ym+1];
%                 imageStack(imgCnt).HsiIN = hsiIN;
%                 imageStack(imgCnt).HsiOUT = hsiOUT;
%                 imageStack(imgCnt).R1 = imageStack(imgCnt).MeanOUT/imageStack(imgCnt).MeanIN;
%                 imageStack(imgCnt).R2 = imageStack(imgCnt).HsiIN/imageStack(imgCnt).HsiOUT;
%                 imageStack(imgCnt).R3 = imageStack(imgCnt).MeanOUT(1)-imageStack(imgCnt).MeanIN(1);
% %                 imageStack(imgCnt).R4 = imageStack(imgCnt).HsiIN(1)-imageStack(imgCnt).HsiOUT(1);
% %                 imageStack(imgCnt).R5 = imageStack(imgCnt).R3 + imageStack(imgCnt).R4;
% %                 imageStack(imgCnt).R6 = imageStack(imgCnt).R3 * imageStack(imgCnt).R4;
% %                 imageStack(imgCnt).R7 = imageStack(imgCnt).R3*imageStack(imgCnt).BlurVal;
%                 img = bwareafilt(rgb2gray(imageStack(imgCnt).Img)>0,1);
%                 stats = regionprops(img,'Solidity');
%                 imageStack(imgCnt).R8 = stats.Solidity;
%                 
% %             end
%         end
%     end
%     fc = fc + 1;
%     waitbar(fc / handles.numInputImages, waitbarHandle, 'Extracting eye regions...');
% end
% delete(waitbarHandle);
% stackLen = imgCnt;
% 
% for cf = 1:stackLen
%     for cf2 = cf+1:stackLen
%         if imageStack(cf).BlurVal<imageStack(cf2).BlurVal
%             imageStackT = imageStack(cf);
%             imageStack(cf) = imageStack(cf2);
%             imageStack(cf2) = imageStackT;
%         end
%     end
% end
% 
% len = min(40,stackLen);
% 
% vect = zeros(len,1);
% for cf = 1:len
%     vect(cf) = imageStack(cf).R3;
% end
% [~,idx] = sort(vect,'descend');
% cnt1 = 0;
% for cf = 1:len
%     if imageStack(idx(cf)).R8>0.7
%         cnt1 = cnt1 + 1;
%     end
% end
% 
% imageStack2 = struct('Img',cell(cnt1,1),...
%     'OrigImg',cell(cnt1,1),...
%     'OrigFrameNum',cell(cnt1,1),...
%     'Rect',cell(cnt1,1));
% cnt = 0;
% for cf = 1:len
%     if imageStack(idx(cf)).R8>0.7
%         cnt = cnt + 1;
%         imageStack2(cnt).Img = imageStack(idx(cf)).Img;
%         imageStack2(cnt).OrigImg = imageStack(idx(cf)).OrigImg;
%         imageStack2(cnt).OrigFrameNum = imageStack(idx(cf)).OrigFrameNum;
%         imageStack2(cnt).Rect = imageStack(idx(cf)).Rect;
%         if cnt == cnt1
%             break;
%         end
%     end
% end
% 
% imageStack = imageStack2;
% selectedFrameIdx = 1;
% len = cnt1;
% 
% % vect = zeros(len,1);
% % for cf = 1:len
% %     vect(cf) = imageStack(cf).R3;
% % end
% % [~,idx] = sort(vect,'descend');
% % 
% % for cf = 1:len
% %     if imageStack(idx(cf)).R8>0.7
% %         break;
% %     end
% % end
% % selectedFrameIdx = idx(cf);
% % imageStack = imageStack(1:len);
% 
% end

function [regImgStack] = registerEyeRegion(imageStack,imgCnt)
%REGISTEREYEREGION Summary of this function goes here
%   Detailed explanation goes here

% prepare the parameters
SIFTflowpara.alpha=2;
SIFTflowpara.d=40;
SIFTflowpara.gamma=0.005;
SIFTflowpara.nlevels=4;
SIFTflowpara.wsize=5;
SIFTflowpara.topwsize=20;
SIFTflowpara.nIterations=60;

[optimizer, metric] = imregconfig('multimodal');
optimizer.MaximumIterations = 500;
optimizer.GrowthFactor = optimizer.GrowthFactor -0.02;


if nargin<2
    imgCnt = length(imageStack); % all
end
if imgCnt>length(imageStack)
    imgCnt = length(imageStack);
end

regImgStack = struct('Img',cell(imgCnt,1),'FiltImg',cell(imgCnt,1));

opt = option_defaults_fa;
patchsize=8;
gridspacing=1;
h2 = fspecial('gaussian',7,1.);

hb = waitbar(0,'Please wait while the chosen frames are registered...','WindowStyle','modal');
try
    for cf = 1:imgCnt
        if cf == 1
            im1=imageStack(cf).Img;
            im1 = im2double(imfilter(im1,h2));
            Im1=im1(patchsize/2:end-patchsize/2+1,patchsize/2:end-patchsize/2+1,:);
            imgf = mat2gray(filter_image(uint8(Im1 * 255),opt));
            regImgStack(cf).Img = Im1;
            regImgStack(cf).FiltImg = imgf;
        else
            im2=imageStack(cf).Img;
            
            im1 = imfilter(im1,h2);
            im2 = imfilter(im2,h2);
            
            im1=im2double(im1);
            im2=im2double(im2);
            
            
            % Step 2. Compute the dense SIFT image
            
            % patchsize is half of the window size for computing SIFT
            % gridspacing is the sampling precision
            
            
            
            Sift1=dense_sift(im1,patchsize,gridspacing);
            Sift2=dense_sift(im2,patchsize,gridspacing);
            
            % % visualize the SIFT image
            %         figure;imshow(showColorSIFT(Sift1));title('SIFT image 1');
            %         figure;imshow(showColorSIFT(Sift2));title('SIFT image 2');
            
            % Step 3. SIFT flow matching
            
            % warpI2 = imregister(im1, im2, 'affine', optimizer, metric);
            
            tic;[vx,vy,energylist]=SIFTflowc2f(Sift1,Sift2,SIFTflowpara);toc
            
            % Step 4.  Visualize the matching results
            Im1=im1(patchsize/2:end-patchsize/2+1,patchsize/2:end-patchsize/2+1,:);
            Im2=im2(patchsize/2:end-patchsize/2+1,patchsize/2:end-patchsize/2+1,:);
            warpI2=warpImage(Im2,vx,vy);
            % whether to use the first image as reference or the previous image
            %im1 = warpI2;
            
            imgf = mat2gray(filter_image(uint8(warpI2 * 255),opt));
            regImgStack(cf).Img = warpI2;
            regImgStack(cf).FiltImg = imgf;
        end
        waitbar(cf/imgCnt,hb,sprintf('Completed frame %d',cf));
    end
    close(hb);
catch ME
    regImgStack = [];
    errordlg(ME.message);
    close(hb);
    makeLog(ME);
end

end

function [diagImg,branchImg,branchStruct,numImg] = analyzeVessels(img,thresh,minorAxis,widthparam)

try
    if ~islogical(img)
        img = img>0;
    end
    imSize = size(img);
    
    distImg = 2*bwdist(~img);
    skelImg = bwmorph(img,'skel',Inf);
    skelImg = bwmorph(imclose(skelImg,strel('disk',5)),'skel',Inf);
    diagImg = distImg.*skelImg;
    endptImg = bwmorph(skelImg,'endpoints');
    brptImg = bwmorph(skelImg,'branchpoints');
    trvImg = false(imSize);
    cmpstImg = endptImg | brptImg;
    [r,c] = find(cmpstImg);
    L = zeros(imSize);
    lenBr = length(r);
    L(cmpstImg) = 1:lenBr;
    
    numBranches = 0;
    branchImg = zeros(imSize);
    branchSImg = branchImg;
    branchSImg2 = branchImg;
    sqrtof2 = sqrt(2);
    indMat = [sqrtof2,1,sqrtof2;1,0,1;sqrtof2,1,sqrtof2];
    % Find individual branches
    dataSize = lenBr*4;
    leafBranches = false(dataSize,1);
    maxBranchLen = 0;
    for cf = 1:lenBr
        startIsLeaf = false;
        currNumBranches = numBranches;
        if (endptImg(r(cf),c(cf))) && (~trvImg(r(cf),c(cf)))
            numBranches = numBranches + 1;
            branchImg(r(cf),c(cf)) = numBranches;
            startIsLeaf = true;
        end
        trvImg(r(cf),c(cf)) = true;
        % Mark branches
        for rr = -1:1
            for cc = -1:1
                if ~((rr==0) && (cc==0))
                    newR = r(cf)+rr; newC = c(cf)+cc;
                    if (newR>0) && (newC>0) && (newR<=imSize(1)) && (newC<=imSize(2))
                        if (skelImg(newR,newC))
                            if (~trvImg(newR,newC))
                                trvImg(newR,newC) = true;
                                if brptImg(r(cf),c(cf))
                                    numBranches = numBranches + 1;
                                end
                                branchImg(newR,newC) = numBranches;
                            end
                        end
                    end
                end
            end
        end
        % Traverse branches
        for rr = -1:1
            for cc = -1:1
                if ~((rr==0) && (cc==0))
                    newR = r(cf)+rr; newC = c(cf)+cc;
                    if (newR>0) && (newC>0) && (newR<=imSize(1)) && (newC<=imSize(2))
                        if (branchImg(newR,newC)>currNumBranches)
                            endIsLeaf = false;
                            branchSImg(newR,newC) = 1;
                            branchSImg2(newR,newC) = 0;
                            tracePath(newR,newC,branchImg(newR,newC),L(r(cf),c(cf)));
                            if startIsLeaf || endIsLeaf
                                leafBranches(branchImg(newR,newC),1) = true;
                            end
                        end
                    end
                end
            end
        end
    end
    
    if nargin<2
        thresh = 0.05*maxBranchLen;
    else
        thresh = max(0.05*maxBranchLen,thresh);
    end
    
    if nargin<3
        minorAxis = imSize(1);
    end
    
    % Remove branches with length < thresh
    for cf = 1:numBranches
        brImg = branchImg == cf;
        brImg2 = branchSImg2.*brImg;
        maxVal2 = max(brImg2(:));
        if (maxVal2<thresh) && (leafBranches(cf))
            skelImg(brImg) = false;
        end
    end
    
    % Merge branches if size < thresh - run the code again with new skelImg
    skelImg = bwmorph(imclose(skelImg,strel('disk',5)),'skel',Inf);
    endptImg = bwmorph(skelImg,'endpoints');
    brptImg = bwmorph(skelImg,'branchpoints');
    trvImg = false(imSize);
    cmpstImg = endptImg | brptImg;
    [r,c] = find(cmpstImg);
    L = zeros(imSize);
    lenBr = length(r);
    L(cmpstImg) = 1:lenBr;
    
    numBranches = 0;
    branchImg = zeros(imSize);
    branchSImg = branchImg;
    branchSImg2 = branchImg;
    sqrtof2 = sqrt(2);
    indMat = [sqrtof2,1,sqrtof2;1,0,1;sqrtof2,1,sqrtof2];
    % Find individual branches
    maxBranchLen = 0;
    for cf = 1:lenBr
        startIsLeaf = false;
        currNumBranches = numBranches;
        if (endptImg(r(cf),c(cf))) && (~trvImg(r(cf),c(cf)))
            numBranches = numBranches + 1;
            branchImg(r(cf),c(cf)) = numBranches;
            startIsLeaf = true;
        end
        trvImg(r(cf),c(cf)) = true;
        % Mark branches
        for rr = -1:1
            for cc = -1:1
                if ~((rr==0) && (cc==0))
                    newR = r(cf)+rr; newC = c(cf)+cc;
                    if (newR>0) && (newC>0) && (newR<=imSize(1)) && (newC<=imSize(2))
                        if (skelImg(newR,newC)) && (~brptImg(newR,newC)) % Not a branch point
                            if (~trvImg(newR,newC))
                                trvImg(newR,newC) = true;
                                if brptImg(r(cf),c(cf))
                                    numBranches = numBranches + 1;
                                end
                                branchImg(newR,newC) = numBranches;
                            end
                        end
                    end
                end
            end
        end
        % Traverse branches
        for rr = -1:1
            for cc = -1:1
                if ~((rr==0) && (cc==0))
                    newR = r(cf)+rr; newC = c(cf)+cc;
                    if (newR>0) && (newC>0) && (newR<=imSize(1)) && (newC<=imSize(2))
                        if (branchImg(newR,newC)>currNumBranches)
                            endIsLeaf = false;
                            branchSImg(newR,newC) = 1;
                            branchSImg2(newR,newC) = 0;
                            tracePath(newR,newC,branchImg(newR,newC),L(r(cf),c(cf)));
                            if startIsLeaf && endIsLeaf % Both leaves - so its not part of a group
                                leafBranches(branchImg(newR,newC),1) = true;
                            else
                                leafBranches(branchImg(newR,newC),1) = false;
                            end
                        end
                    end
                end
            end
        end
    end
    
    % Find tortuosity for each branch, remove branches with length < thresh
    branchStruct = struct('Tortuosity',cell(numBranches,1),'AvgWidth',cell(numBranches,1),...
        'Length',cell(numBranches,1));
    newBranchImg = zeros(imSize);
    cnt = 0;
    for cf = 1:numBranches
        brImg = branchImg == cf;
        brImg1 = branchSImg.*brImg;
        brImg2 = branchSImg2.*brImg;
        maxVal1 = max(brImg1(:));
        maxVal2 = max(brImg2(:));
        avgWidth = mean(diagImg(brImg));
        if ((maxVal2<thresh) && (leafBranches(cf))) || (avgWidth>(widthparam*minorAxis)) %0.05
            %         branchImg(brImg) = 0;
            diagImg(brImg) = 0;
        else
            cnt = cnt + 1;
            if maxVal1>5 % Ignore small branches
                [x1,y1] = find(brImg1==1);
                [x2,y2] = find(brImg1==maxVal1);
                C = sqrt((x1-x2)^2+(y1-y2)^2);
                branchStruct(cnt).Tortuosity = maxVal2/C;
            else
                branchStruct(cnt).Tortuosity = []; % Do not consider
            end
            branchStruct(cnt).Length = maxVal2;
            branchStruct(cnt).AvgWidth = avgWidth;
            newBranchImg(brImg) = cnt;
        end
    end
    
    branchImg = newBranchImg;
    skelImg = branchImg>0;
    if sum(skelImg(:))>0
        [~,idx] = bwdist(skelImg);
        img = imreconstruct(skelImg,img);
        numImg = branchImg(idx);
        numImg = numImg.*img;
        diagImg = diagImg(idx);
        diagImg = diagImg.*img;
    else
        numImg = zeros(imSize);
        diagImg = numImg;
    end
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

    function tracePath(ro,co,branchNum,sourceBr)
        % Recursive function to trace each branch separately
        trvImg(ro,co) = true;
        branchImg(ro,co) = branchNum;
        % Find if any branch points in neighbourhood - if yes, stop tracing
        for ri = -1:1
            for ci = -1:1
                if ~((ri==0) && (ci==0))
                    newR2 = ro+ri; newC2 = co+ci;
                    if (newR2>0) && (newC2>0) && (newR2<=imSize(1)) && (newC2<=imSize(2))
                        if (brptImg(newR2,newC2)) && (L(newR2,newC2)~=sourceBr)
                            return;
                        end
                    end
                end
            end
        end
        
        for ri = -1:1
            for ci = -1:1
                if ~((ri==0) && (ci==0))
                    newR2 = ro+ri; newC2 = co+ci;
                    if (newR2>0) && (newC2>0) && (newR2<=imSize(1)) && (newC2<=imSize(2))
                        if (skelImg(newR2,newC2)) && (~trvImg(newR2,newC2))
                            if (endptImg(newR2,newC2))
                                trvImg(newR2,newC2) = true;
                                branchImg(newR2,newC2) = branchNum;
                                endIsLeaf = true;
                            else
                                branchSImg(newR2,newC2) = branchSImg(ro,co) + 1;
                                branchSImg2(newR2,newC2) = branchSImg2(ro,co) + indMat(ri+2,ci+2);
                                if branchSImg2(newR2,newC2)>maxBranchLen
                                    maxBranchLen = branchSImg2(newR2,newC2);
                                end
                                tracePath(newR2,newC2,branchNum,sourceBr);
                            end
                        end
                    end
                end
            end
        end
    end
end

function maska = getSpecularityMask(image_input1)
h1 = fspecial('gaussian',[15 15],3);
h2 = strel('disk',5);
% imSize = size(image_input1);

% img1=double(image_input1);
img1lab = rgb2lab(mat2gray(image_input1));
tmpImg = imfilter(img1lab(:,:,2),h1);
% maskXA = tmpImg>0.3*max(tmpImg(:));

maska = imdilate(img1lab(:,:,1)>90,h2);

end

function img1 = removeSpecularity(image_input1)
h1 = fspecial('gaussian',[15 15],3);
h2 = strel('disk',5);
imSize = size(image_input1);

img1=double(image_input1);
img1lab = rgb2lab(mat2gray(image_input1));
tmpImg = imfilter(img1lab(:,:,2),h1);
maskXA = tmpImg>0.3*max(tmpImg(:));

maska = imdilate(img1lab(:,:,1)>90,h2);

[idxA,idxDA] = bwdist(~maska);

for cf2 = 1:3
    tmpa = img1(:,:,cf2);
    mA = mean(tmpa(maskXA));
    mAo = zeros(imSize(1),imSize(2));
    mAo(maska) = tmpa(idxDA(maska));
    tmpa(maska) = mAo(maska) + idxA(maska).*(mA-mAo(maska))./max(idxA(maska));
    img1(:,:,cf2) = tmpa;
end
img1 = uint8(img1);
end

function [L,a,b,X,Y,Z] = RGB2Lab(R,G,B)
% function [L, a, b] = RGB2Lab(R, G, B)
% RGB2Lab takes matrices corresponding to Red, Green, and Blue, and 
% transforms them into CIELab.  This transform is based on ITU-R 
% Recommendation  BT.709 using the D65 white point reference.
% The error in transforming RGB -> Lab -> RGB is approximately
% 10^-5.  RGB values can be either between 0 and 1 or between 0 and 255.  
% By Mark Ruzon from C code by Yossi Rubner, 23 September 1997.
% Updated for MATLAB 5 28 January 1998.

if (nargin == 1)
  B = double(R(:,:,3));
  G = double(R(:,:,2));
  R = double(R(:,:,1));
end

if ((max(max(R)) > 1.0) | (max(max(G)) > 1.0) | (max(max(B)) > 1.0))
  R = R/255;
  G = G/255;
  B = B/255;
end

[M, N] = size(R);
s = M*N;

% Set a threshold
T = 0.008856;

RGB = [reshape(R,1,s); reshape(G,1,s); reshape(B,1,s)];

% RGB to XYZ
MAT = [0.412453 0.357580 0.180423;
       0.212671 0.715160 0.072169;
       0.019334 0.119193 0.950227];
XYZ = MAT * RGB;

X = XYZ(1,:) / 0.950456;
Y = XYZ(2,:);
Z = XYZ(3,:) / 1.088754;

XT = X > T;
YT = Y > T;
ZT = Z > T;

fX = XT .* X.^(1/3) + (~XT) .* (7.787 .* X + 16/116);

% Compute L
Y3 = Y.^(1/3); 
fY = YT .* Y3 + (~YT) .* (7.787 .* Y + 16/116);
L  = YT .* (116 * Y3 - 16.0) + (~YT) .* (903.3 * Y);

fZ = ZT .* Z.^(1/3) + (~ZT) .* (7.787 .* Z + 16/116);

% Compute a and b
a = 500 * (fX - fY);
b = 200 * (fY - fZ);

L = reshape(L, M, N);
a = reshape(a, M, N);
b = reshape(b, M, N);

if ((nargout == 1) | (nargout == 0))
  L = cat(3,L,a,b);
end
end

function oImg = preproc(img,flag)

mask1 = bwareafilt(img(:,:,1)>0,1);
img = uint8(double(img).*repmat(mask1,[1,1,3]));
if nargin<2
    mask = getMask(img);
    img = uint8(double(img).*repmat(mask,[1,1,3]));
end
oImg = img;
% oImg = removeSpecularity(img);

end

function mask = getMask(img)
sImg = double(img) / 255;
R = sImg(:,:,1);
G = sImg(:,:,2);
B = sImg(:,:,3);
[L,~,~] = RGB2Lab(R,G,B);
L = L/100;
mask = ~(L<0.4);
mask(1:3,:) = false;
mask(end-3:end,:) = false;
mask(:,1:3) = false;
mask(:,end-3:end) = false;
if sum(mask(:))>0
    mask = imerode(imfill(bwareafilt(mask,1),'holes'),strel('disk',11)); % 
end
end


function chosenEyeList = getChosenEyes(imgR,excludeFlag)

try
    % stdFun = @(x) (std(x));
    stdFun2 = @(x) (std(x)./mean(x));
    
    circularHoughThresh = 1.5;
    
    radii = 10:1:50;
    radiiMult = 1.2;
    
 load modelparameters.mat
 
 blocksizerow    = 30;
 blocksizecol    = 30;
 blockrowoverlap = 0;
 blockcoloverlap = 0;           
    
    h1 = fspecial('gaussian',[15 15],3);
    h2 = strel('disk',19);
    h21 = strel('disk',5);
    
    imgo = imgR;
    if isempty(imgo)
        chosenEyeList = [];
        return;
    end
    imSize = size(imgo);
    if imSize(1)<=135
        imScale = 1;
    elseif imSize(1)<=1080
        imScale = 0.2;
    elseif imSize(1)<=1800
        imScale = 0.125;
    else
        imScale = 0.08;
    end
    img = imresize(imgo, imScale);
    imgMask = imerode(bwareafilt(imfill(img(:,:,1)>20,'holes'),1),h21);
    tSize = size(img);
    img = imfilter(img(:,:,1),h1);
    img = colfilt(double(img), [9 9], 'sliding', stdFun2);
    
    e = edge(img, 'canny');
    e(~imgMask) = false;
    h = circle_hough(e, radii, 'same', 'normalise');
    peak = circle_houghpeaks(h, radii, 'nhoodxy', 15, 'nhoodr', 21, 'npeaks', 5, ...
        'Threshold',circularHoughThresh);
    
    chosenEyeList.Img = [];
    chosenEyeList.Rect = [];
    cfhCnt = 0;
    if ~isempty(peak)
        sizeP = size(peak,2);
        
        
        for cfh = 1:sizeP
            [x, y] = circlepoints(peak(3,cfh)*radiiMult); % take more location
            minX = min(x);
            maxX = max(x);
            minY = min(y);
            maxY = max(y);
            
            sizeScaleY = imSize(1)/tSize(1);
            sizeScaleX = imSize(2)/tSize(2);
            
            maxY = round((maxY + peak(2,cfh))*sizeScaleY);
            minY = round((minY + peak(2,cfh))*sizeScaleY);
            maxX = round((maxX + peak(1,cfh))*sizeScaleX);
            minX = round((minX + peak(1,cfh))*sizeScaleX);
            if minY<1
                minY = 1;
            end
            if maxY>imSize(1)
                maxY = imSize(1);
            end
            if minX<1
                minX = 1;
            end
            if maxX>imSize(2)
                maxX = imSize(2);
            end
            biasX = minX; biasY = minY;
            img2 = imgo(minY:maxY,minX:maxX,:);
            imSize2 = size(img2);
            img22 = imresize(rgb2gray(img2),imScale);
            tSize2 = size(img22);
            e2 = edge(img22,'canny');
            h = circle_hough(e2, radii, 'same', 'normalise');
            [peak2,v] = circle_houghpeaks(h, radii, 'nhoodxy', 15, 'nhoodr', 21, 'npeaks', 1);
            
            [x, y] = circlepoints(peak2(3)); % take more location
            currX = x+peak2(1);
            currY = y+peak2(2);
            
            flag = (min(currY)>=1) + (max(currY)<=tSize2(1)) + (min(currX)>=1) + (max(currX)<=tSize2(2));
            %         flag = 4;
            if flag==4
                sizeScaleY = imSize2(1)/tSize2(1);
                sizeScaleX = imSize2(2)/tSize2(2);
                currY = round(currY*sizeScaleY);
                currX = round(currX*sizeScaleX);
                circInfo = [peak2(1)*sizeScaleX,peak2(2)*sizeScaleY,peak2(3)*max(sizeScaleX,sizeScaleY)];
                currY(currY>imSize2(1)) = imSize2(1);
                currX(currX>imSize2(2)) = imSize2(2);
                Ym2 = min(currY);
                YM2 = max(currY);
                Xm2 = min(currX);
                XM2 = max(currX);
                %             imco = imgo(Ym:YM,Xm:XM,:);
                imco2 = img2;
                maskXO = true(imSize2(1:2));
                [~,indx] = sort(x);
                for cc = 1:length(x)
                    if x(indx(cc))<0
                        if y(indx(cc))<0
                            imco2(1:currY(indx(cc)),1:currX(indx(cc)),:) = 0;
                            maskXO(1:currY(indx(cc)),1:currX(indx(cc))) = false;
                        else
                            imco2(currY(indx(cc)):end,1:currX(indx(cc)),:) = 0;
                            maskXO(currY(indx(cc)):end,1:currX(indx(cc))) = false;
                        end
                    else
                        if y(indx(cc))<0
                            imco2(1:currY(indx(cc)),currX(indx(cc)):end,:) = 0;
                            maskXO(1:currY(indx(cc)),currX(indx(cc)):end) = false;
                        else
                            imco2(currY(indx(cc)):end,currX(indx(cc)):end,:) = 0;
                            maskXO(currY(indx(cc)):end,currX(indx(cc)):end) = false;
                        end
                    end
                end
                
                %             if (Ym2<1)
                %                 Ym2 = 1;
                %             end
                %             if (Xm2<1)
                %                 Xm2 = 1;
                %             end
                
                Ym = Ym2 + biasY;
                YM = YM2 + biasY;
                if YM>imSize(1)
                    YM2 = YM2-(YM-imSize(1));
                    YM = imSize(1);
                end
                Xm = Xm2 + biasX;
                XM = XM2 + biasX;
                if XM>imSize(2)
                    XM2 = XM2-(XM-imSize(2));
                    XM = imSize(2);
                end
                circInfo(1) = circInfo(1) + biasX;
                circInfo(2) = circInfo(2) + biasY;
                
                
                imco = imco2(Ym2:YM2,Xm2:XM2,:);
                eyeSize = size(imco);
                imcoh = img2(Ym2:YM2,Xm2:XM2,:);
                imglab = rgb2lab(uint8(imco));
                imglab = imfilter(imglab(:,:,2),h1);
                maskX = imglab>0.3*max(imglab(:));
                maskX = imfill(maskX,'holes');
                sumX = sum(maskX(:));
                sumO = sum(sum(rgb2gray(imco)>0));
                if sumX<(0.5*sumO)
                    continue;
                end
                
                
                tmp1 = imcoh(:,:,1);
                meanIN = mean(tmp1(maskX));
                maskXD = imdilate(maskX,h2) & (~maskX);
                meanOUT = mean(tmp1(maskXD));
                R3 = meanIN - meanOUT;
                stats = regionprops(bwareafilt(maskX,1),'Solidity');
                if (R3<10) || (stats.Solidity <= 0.7)
                    if excludeFlag
                        continue;
                    end
                end
                
%                 % Sharpness
%                 imgs = double(imgo(:,:,1));
%                 ctr = round(eyeSize(1:2)/2);
%                 h = fspecial('average',round(ctr*0.2));
%                 a2 = abs(imgs-imfilter(imgs,h));
%                 a2 = a2(Ym:YM,Xm:XM).*maskX;
%                 a = fft2(a2);

                    % IQA
                    imgotmp = double(imgo); % imgo, the whole image;
                    imgs = zeros(YM-Ym+1,XM-Xm+1,3);
%                     imgs(:,:,1) = imgotmp(Ym:YM,Xm:XM,1).*maskX;
%                     imgs(:,:,2) = imgotmp(Ym:YM,Xm:XM,2).*maskX;
%                     imgs(:,:,3) = imgotmp(Ym:YM,Xm:XM,3).*maskX; % imgs, eye region image;
                    
                    
                    imgs(:,:,1) = imgotmp(Ym:YM,Xm:XM,1);
                    imgs(:,:,2) = imgotmp(Ym:YM,Xm:XM,2);
                    imgs(:,:,3) = imgotmp(Ym:YM,Xm:XM,3); % imgs, eye region image;
                                        
                    imgs = imresize(imgs,[150,150]);
                    
                    [Qg1,Qch1]=blindimagequality(imgs);

                    
                    
imgs = uint8(imgs);
quality1 = computequality(imgs,blocksizerow,blocksizecol,blockrowoverlap,blockcoloverlap, ...
    mu_prisparam,cov_prisparam);          
                    

                    
                    tmp1 = Qg1*10000; 
                    tmp2 = 1000-quality1;
                    
                    a = tmp1+tmp2;                    
                    
                    
                
                
                cfhCnt = cfhCnt + 1;
                eyeStruct.Pos(cfhCnt).Img = imco;
                %             eyeStruct.Pos(cfhCnt).OrigImg = imgo;
                %             eyeStruct.Pos(cfhCnt).Num = cf;
                eyeStruct.Pos(cfhCnt).Rect = [Xm,Ym,XM-Xm+1,YM-Ym+1];
                eyeStruct.Pos(cfhCnt).R3 = R3;
                eyeStruct.Pos(cfhCnt).MeanOUT = meanOUT;
                eyeStruct.Pos(cfhCnt).Sharpness = abs(a(1,1));
                eyeStruct.Pos(cfhCnt).HOGv = v;
                %             eyeStruct.Pos(cfhCnt).Solidity = stats.Solidity;
                eyeStruct.Pos(cfhCnt).Info = [circInfo(1),circInfo(2),circInfo(3),sizeScaleX,sizeScaleY];
                %                 eyeStruct(cf).Pos(cfCnt).Cnt = totEyes;
                eyeStruct.Pos(cfhCnt).Chosen = false;
                %             R3Arr(cfhCnt) = R3;
                %                 SpArr(totEyes) = a(ctr(1),ctr(2));
                %             HogArr(cfhCnt) = v;
            end
        end
    end
    
    % medValR3 = median(R3Arr);
    % medValHog = median(HogArr);
    
    if cfhCnt>0
        cnt = 0;
        maxSp = -Inf;
        maxSpIdx = 0;
        for cfp = 1:cfhCnt
            chR3 = (eyeStruct.Pos(cfp).MeanOUT<90) &&...
                (eyeStruct.Pos(cfp).R3>=30);
            % check 3 - hog peak
            chHog = eyeStruct.Pos(cfp).HOGv>1.5;
            if excludeFlag && (~(chR3 && chHog))
                continue;
            end
            cnt = cnt + 1;
            if eyeStruct.Pos(cfp).Sharpness > maxSp
                maxSp = eyeStruct.Pos(cfp).Sharpness;
                maxSpIdx = cfp;
            end
        end
        
        if cnt>0
            chosenEyeList.Img = eyeStruct.Pos(maxSpIdx).Img;
            chosenEyeList.Rect = eyeStruct.Pos(maxSpIdx).Rect; % ystart,yend,xstart,xend
        end
    end
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end
%%%%% ALL IMAGE PROCESSING CODES - END

function isInside = checkInside(pt,rect)

isInside = false;
if (pt(1)>=rect(1)) && (pt(2)>=rect(2)) && (pt(1)<=rect(3)) && (pt(2)<=rect(4))
    isInside = true;
end

end

% --- Executes on mouse motion over figure - except title and menu.
function figure1_WindowButtonMotionFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.OnInputVideoAxes = checkInside(hObject.CurrentPoint,handles.InputVideoAxesRect);
handles.OnChosenFramesAxis = checkInside(hObject.CurrentPoint,handles.ChosenFramesAxisRect);
guidata(hObject,handles);

end


% --- Executes when figure1 is resized.
function figure1_SizeChangedFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.InputVideoAxesRect = get(handles.InputVideoPanel,'Position');
handles.ChosenFramesAxisRect = get(handles.ChosenFramesPanel,'Position');
handles.SWinSize = get(handles.figure1,'Position');
handles.SWinSize = [handles.SWinSize(3:4),handles.SWinSize(3:4)];
handles.InputVideoAxesRect = [handles.InputVideoAxesRect(1:2),...
    handles.InputVideoAxesRect(1:2)+handles.InputVideoAxesRect(3:4)].*handles.SWinSize;
handles.ChosenFramesAxisRect = [handles.ChosenFramesAxisRect(1:2),...
    handles.ChosenFramesAxisRect(1:2)+handles.ChosenFramesAxisRect(3:4)].*handles.SWinSize;

guidata(hObject,handles);

end


% --- Executes on scroll wheel click while the figure is in focus.
function figure1_WindowScrollWheelFcn(hObject, eventdata, handles)
% hObject    handle to figure1 (see GCBO)
% eventdata  structure with the following fields (see MATLAB.UI.FIGURE)
%	VerticalScrollCount: signed integer indicating direction and number of clicks
%	VerticalScrollAmount: number of lines scrolled for each click
% handles    structure with handles and user data (see GUIDATA)

if handles.processed
    if handles.OnInputVideoAxes || handles.OnChosenFramesAxis
        if handles.OnInputVideoAxes
            imgIdx = handles.currInputImage;
            handles.currInputImage = handles.currInputImage - eventdata.VerticalScrollCount;
            % Stop and do nothing
            if handles.currInputImage>handles.numInputImages
                handles.currInputImage = handles.numInputImages;
            end
            if handles.currInputImage < 1
                handles.currInputImage = 1;
            end
            if handles.currInputImage ~= imgIdx
                handles = getCurrImg(handles,1); % through slider
                set(handles.InputVideoSlider,'Value',(handles.currInputImage-1)/(handles.numInputImages-1));
                guidata(hObject,handles);
            end
        else
            imgIdx = handles.currChosenFrame;
            handles.currChosenFrame = handles.currChosenFrame - eventdata.VerticalScrollCount;
            if handles.currChosenFrame>handles.numChosenFrames
                handles.currChosenFrame = handles.numChosenFrames;
            end
            if handles.currChosenFrame < 1
                handles.currChosenFrame = 1;
            end
            if handles.currChosenFrame ~= imgIdx
                handles = getCurrImg(handles,2); % through slider
                set(handles.ChosenFramesSlider,'Value',(handles.currChosenFrame-1)/(handles.numChosenFrames-1));
                guidata(hObject,handles);
            end
        end
    end
end

end

% --- Executes on button press in ProcessBatchButton.
function ProcessBatchButton_Callback(hObject, eventdata, handles)
% hObject    handle to ProcessBatchButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    vidPath = uigetdir(pwd);
    if vidPath~=0
        extn = getExtn(handles.TYPE,handles.CurrInputType);
        if iscell(extn)
            vidList1 = [];
            for cf0 = 1:numel(extn)
                extn2 = ['*.',extn{cf0}];
                vidList2 = findsubdir(vidPath,extn2); % type 0
                if ~isempty(vidList2(1).name)
                    vidList1 = [vidList1,vidList2];
                end
            end
            numFiles = numel(vidList1);
            vidList = struct('name',cell(0,1),'folderName',cell(0,1));
            cnt = 0;
            for cf0 = 1:numFiles
                name1 = vidList1(cf0).name;
                matchFound = false;
                for cf02 = cf0+1:numFiles
                    name2 = vidList1(cf02).name;
                    if strcmp(name1,name2)
                        matchFound = true;
                        break;
                    end
                end
                if ~matchFound
                    cnt = cnt + 1;
                    vidList(cnt) = vidList1(cf0);
                end
            end
        else
            extn2 = ['*.',extn];
            vidList = findsubdir(vidPath,extn2); % type 0
        end
        
        %     len = length(vidPath);
        
        numFiles = numel(vidList);
        chckboxes = cell(numFiles,2);
        origScrnSize = get(0,'screensize');
        origScrnSize = round(origScrnSize(3:4)*0.8);
        winWid = round(origScrnSize(1)*0.7);
        winLen = round(origScrnSize(2)-100);
        interv = round(winLen/(numFiles+2));
        
        fig = figure('Units','Pixels',...
            'Position',[100, 100,winWid,...
            winLen],...
            'Name','Check files to use',...
            'Toolbar','none',...
            'Menubar','none',...
            'Visible','On');
        yMin = 10;
        yMax = winLen-30;
        yvals = linspace(yMin,yMax,numFiles+1);
        skipList = []; %[7,16,30,42,45];
        for cfc = 1:numFiles
            
            if ~isempty(find(skipList==cfc,1))
                tmpVal = false;
            else
                tmpVal = true;
            end
            chckboxes{cfc,1} = uicontrol(fig,'Style',...
                'checkbox',...
                'String',vidList(cfc).name,...
                'Tag',num2str(cfc),...
                'Units','Pixels',...
                'HorizontalAlignment','center',...
                'Position',[10,yvals(numFiles-cfc+2),winWid-10,30],...
                'Value',tmpVal,...
                'Callback',{@boxSelectCallback,cfc});
            chckboxes{cfc,2} = tmpVal;
            %     yPos = yPos - interv;
        end
        
        bconfirm = uicontrol(fig,'Style',...
            'pushbutton',...
            'String',sprintf('Confirm'),...
            'Tag','confirmButton',...
            'Units','Pixels',...
            'HorizontalAlignment','center',...
            'Position',[10,yvals(1),80,30],...
            'Callback',@confirmCallback);
        set(fig,'Units','Normalized');
        set(bconfirm,'Units','Normalized');
        
        hlist = [];
        for cfc = 1:numFiles
            hlist = [hlist,chckboxes{cfc,1}];
            set(chckboxes{cfc,1},'Units','Normalized');
        end
        % align([hlist,bconfirm], 'None', 'Distribute')
        % set(fig,'Visible','On');
        
        % not processed -
        % {'I:\Postdoctoral Works\From Sina\Project - Neonatal Eye\Datasets\Datasets_PILOT\103-2016-05-27\103\0118','0118'}
        % {'I:\Postdoctoral Works\From Sina\Project - Neonatal Eye\Datasets\Datasets_PILOT\105-2016-05-27\105\0119','0119'}
        % {'I:\Postdoctoral Works\From Sina\Project - Neonatal
        % Eye\Datasets\Datasets_PILOT\206-2016-05-27\206\1229','1229'} - 3
        % {'I:\Postdoctoral Works\From Sina\Project - Neonatal Eye\Datasets\Datasets_PILOT\210-2016-05-27\210\0118','0118'}
        % {'0609 (file format problem_','I:\Postdoctoral Works\From Sina\Project - Neonatal Eye\Datasets\Datasets_PILOT\211-2016-07-07\211\0609 (file format problem_'}
    end
catch MEg
    errordlg(MEg.message);
    makeLog(MEg);
end
    function boxSelectCallback(hObject,eventdata,hd)
        chckboxes{hd,2} = get(hObject,'Value');
    end

    function confirmCallback(src,eventdata)
        ID = 'ALCVSOFT-VIP';
        waitbarHandle = waitbar(0,'Extracting eye regions...');
        for cf = 1:numFiles
            cf
            if chckboxes{cf,2}
                ipPath = vidList(cf).name;                
                if handles.CurrInputType == handles.TYPE.MOV
                    extn2 = ['*.',extn];
                    dir1 = dir(fullfile(ipPath,extn2));
                else
                    dir1(1).name = vidList(cf).folderName;
                end
                %waitbar(cf/numel(vidList),waitbarHandle,sprintf('Processing dataset %s',vidList(cf).folderName));
                for cf2 = 1:numel(dir1)
                    waitbar(cf2/numel(dir1),waitbarHandle,sprintf('Processing dataset- %s/%s',num2str(cf2), num2str(numel(dir1))));
                    if handles.CurrInputType == handles.TYPE.MOV
                        fileName = [dir1(cf2).name(1:end-4),'.mat'];
                    else
                        fileName = [dir1(cf2).name,'.mat'];
                    end
                    dir2 = dir(fullfile(ipPath,fileName));
%                     if isempty(dir2)
                        try
                            tic
                            tmpHandle = init(handles);
                            tmpHandle.CurrInptType = handles.CurrInputType;
                            tmpHandle.chosenInputType = handles.CurrInputType;
                            if handles.CurrInputType == handles.TYPE.MOV
                                tmpHandle.frameStruct = GenericFrameReader(fullfile(ipPath,dir1(cf2).name),true);
                            else
                                tmpHandle.frameStruct = GenericFrameReader(fullfile(ipPath),false,extn);
                            end
                            tmpHandle = extractEyeRegionEx(tmpHandle);
                            imageStack = tmpHandle.imageStack;
                            selectedSpecularMask = tmpHandle.selectedSpecularMask;
                            imgMat = tmpHandle.imgMat;
                            chosenInputType = tmpHandle.chosenInputType;
                            ipFile = dir1(cf2).name;
                            
                            coarse_extraction_time = toc;
                            fprintf('Coarse Extraction Time: %0.4f\n', coarse_extraction_time);
                            save(fullfile(ipPath,fileName),'ID',...
                                'chosenInputType','ipPath','ipFile','imgMat',...
                                'imageStack','selectedSpecularMask', 'coarse_extraction_time', '-v7.3');
                            clear imageStack selectedSpecularMask imgMat
                        catch ME
                            fprintf('Incomplete: %s\n',fullfile(ipPath,dir1(cf2).name));
                            makeLog(ME);
                            continue;
                        end
%                     end
                end
            end
        end
        delete(waitbarHandle);
    end

end


% --- Executes on button press in RelaxationCheckBox.
function RelaxationCheckBox_Callback(hObject, eventdata, handles)
% hObject    handle to RelaxationCheckBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of RelaxationCheckBox
end

% --- Executes on button press in UploadImagesCheckBox.
function UploadImagesCheckBox_Callback(hObject, eventdata, handles)
% hObject    handle to UploadImagesCheckBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of UploadImagesCheckBox
end


% --- Executes on button press in OverlapVesselsCheckBox.
function OverlapVesselsCheckBox_Callback(hObject, eventdata, handles)
% hObject    handle to OverlapVesselsCheckBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of OverlapVesselsCheckBox

handles = getCurrImg(handles,4);
guidata(hObject,handles);

end


% --------------------------------------------------------------------
function SnapshotMenu_Callback(hObject, eventdata, handles)
% hObject    handle to SnapshotMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --------------------------------------------------------------------
function GetCurrentInputFrameMenu_Callback(hObject, eventdata, handles)
% hObject    handle to GetCurrentInputFrameMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.processed
    getSnapshot(handles,1,handles.currInputImage);
end

end

% --------------------------------------------------------------------
function GetCurrentChosenFrameMenu_Callback(hObject, eventdata, handles)
% hObject    handle to GetCurrentChosenFrameMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.processed
    getSnapshot(handles,2,handles.currChosenFrame);
end

end

% --------------------------------------------------------------------
function GetSelectedImageMenu_Callback(hObject, eventdata, handles)
% hObject    handle to GetSelectedImageMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.processed
    getSnapshot(handles,3);
end

end

% --------------------------------------------------------------------
function GetManualImageMenu_Callback(hObject, eventdata, handles)
% hObject    handle to GetManualImageMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.processed
    if handles.manualAvailable
        getSnapshot(handles,4);
    else
        msgbox('Manually selected image is not available');
    end
end

end

% --------------------------------------------------------------------
function GetSegmentationMenu_Callback(hObject, eventdata, handles)
% hObject    handle to GetSegmentationMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.processed
    if ~isempty(handles.currPt)
        getSnapshot(handles,5,handles.currPt);
    else
        getSnapshot(handles,5);
    end
end

end

function getSnapshot(handles,type,idx)

isVid = handles.chosenInputType == handles.TYPE.MOV;
k = strfind(handles.ipFile,'.');
ke = k(end);
origFileName = handles.ipFile(1:ke-1);
switch type
    case 1 % original input frame
        if isVid
            fileName = sprintf('%s-ORIG_FRAME_AT_%.2fs.tif',origFileName,handles.imgMat{idx,2});
        else
            fileName = sprintf('%s-ORIG_FRAME.tif',origFileName);
        end
        if handles.imagesLoaded
            imwrite(handles.frameStruct.getFrame(idx),fullfile(handles.ipPath,fileName));
        else
            imwrite(handles.imgMat{idx,1},fullfile(handles.ipPath,fileName));
        end
        msgbox(sprintf('Snapshot saved at %s',fullfile(handles.ipPath,fileName)));
    case 2 % chosen image frame
        if isVid
            fileName1 = sprintf('%s-CHOSEN_FRAME_AT_%.2fs.tif',origFileName,handles.imgMat{idx,2});
            fileName2 = sprintf('%s-CHOSEN_EYE_AT_%.2fs.tif',origFileName,handles.imgMat{idx,2});
        else
            fileName1 = sprintf('%s-CHOSEN_FRAME.tif',origFileName);
            fileName2 = sprintf('%s-CHOSEN_EYE.tif',origFileName);
        end
        img = insertShape(handles.imageStack(idx).OrigImg,...
            'Rectangle',handles.imageStack(idx).Rect, ...
            'LineWidth', 4);
        imwrite(handles.imageStack(idx).Img,fullfile(handles.ipPath,fileName2));
        imwrite(img,fullfile(handles.ipPath,fileName1));
        msgbox(sprintf('Snapshot saved at %s as (%s,%s)',handles.ipPath,fileName1,fileName2));
    case 3 % selected automatic image
        fileName = sprintf('%s-AUTO_SELECTED_FRAME.tif',origFileName);
        imwrite(handles.selectedFrame,fullfile(handles.ipPath,fileName));
        msgbox(sprintf('Snapshot saved at %s',fullfile(handles.ipPath,fileName)));
    case 4 % manual image
        fileName = sprintf('%s-MANUALLY_SELECTED_FRAME.tif',origFileName);
        imwrite(handles.manualFrame,fullfile(handles.ipPath,fileName));
        msgbox(sprintf('Snapshot saved at %s',fullfile(handles.ipPath,fileName)));
    case 5 % segmentation
        fileName1 = sprintf('%s-SEGMENTATION.tif',origFileName);
        fileName2 = sprintf('%s-SEG_OVERLAP.tif',origFileName);
        skeleton = get(handles.VesselSkeletonCheckbox,'Value');
        flag = get(handles.ToggleManualSelectionCheckbox,'Value');
        flagAllVess = get(handles.OverlapVesselsCheckBox,'Value');
        if nargin<3
            pointGiven = false;
        else
            pointGiven = true;
        end
        if flag == 1
            img = handles.manualSegStruct.Img;
            skelImg = handles.manualSegStruct.BranchImg>0;
            numImg = handles.manualSegStruct.NumImg;
            selectedImg = handles.manualFrame;
            mask2 = handles.manualMaskedRegion;
            if sum(mask2(:))>0
                for cf = 1:3
                    tmp = selectedImg(:,:,cf);
                    tmp(mask2) = tmp(mask2) + 50;
                    selectedImg(:,:,cf) = tmp;
                end
            end
        else
            img = handles.selectedSegStruct.Img;
            skelImg = handles.selectedSegStruct.BranchImg>0;
            numImg = handles.selectedSegStruct.NumImg;
            selectedImg = handles.selectedFrame;
            mask2 = handles.selectedMaskedRegion;
            if sum(mask2(:))>0
                for cf = 1:3
                    tmp = selectedImg(:,:,cf);
                    tmp(mask2) = tmp(mask2) + 50;
                    selectedImg(:,:,cf) = tmp;
                end
            end
        end
        flag2 = ~isempty(img);
        if skeleton
            img = mat2gray(skelImg);
        end
        if flag2 % Showable
            img = repmat(img,[1,1,3]);
        else
            img = handles.blankImg;
        end   
        if flagAllVess && flag2
            mask2 = numImg>0;
            for cf = 1:3
                tmp = selectedImg(:,:,cf);
                tmp(mask2) = tmp(mask2) + 50; % less brightly colored
                selectedImg(:,:,cf) = tmp;
            end
        end
        if pointGiven % Generated through user clicking
            pt = idx;
            if numImg(pt(2),pt(1))>0
                handles.n = numImg(pt(2),pt(1));
                handles.L = numImg == handles.n;
                for cf = 1:3
                    tmp = img(:,:,cf);
                    tmp(handles.L) = handles.FILL_COLOR(cf);
                    img(:,:,cf) = tmp;
                    tmp = selectedImg(:,:,cf);
                    tmp(handles.L) = tmp(handles.L) + 80; % brightly colored
                    selectedImg(:,:,cf) = tmp;
                end                
                handles = showSegInfo(handles,2,pt);
            end
        end
        imwrite(img,fullfile(handles.ipPath,fileName1));
        imwrite(selectedImg,fullfile(handles.ipPath,fileName2));
    case 6 % automatically selected image w/o messagebox
        fileName = sprintf('%s-AUTO_SELECTED_FRAME.tif',origFileName);
        imwrite(handles.selectedFrame,fullfile(handles.ipPath,fileName));
        %msgbox(sprintf('Snapshot saved at %s',fullfile(handles.ipPath,fileName)));
    case 7 %save at most top 3 best frames and corresponding eyes
        for tmp_index = 1:min(3, length(handles.imageStack))
            fileName = sprintf('%s-%d-AUTO_SELECTED_FRAME.tif',origFileName,tmp_index);
            imwrite(handles.imageStack(tmp_index).Img,fullfile(handles.ipPath,fileName));
        end
    case 8 %think of something!
end

end


% --- Executes on button press in batchsegment.
function batchsegment_Callback(hObject, eventdata, handles)
% hObject    handle to batchsegment (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    vidPath = uigetdir(pwd);
    if vidPath~=0
        if handles.CurrInputType == handles.TYPE.BFM || handles.CurrInputType == handles.TYPE.EYE
            extn = getExtn(handles.TYPE,8);
        else
            extn = getExtn(handles.TYPE,7);
        end
        
        if iscell(extn)
            vidList1 = [];
            for cf0 = 1:numel(extn)
                extn2 = ['*.',extn{cf0}];
                vidList2 = findsubdir(vidPath,extn2); % type 0
                if ~isempty(vidList2(1).name)
                    vidList1 = [vidList1,vidList2];
                end
            end
            numFiles = numel(vidList1);
            vidList = struct('name',cell(0,1),'folderName',cell(0,1));
            cnt = 0;
            for cf0 = 1:numFiles
                name1 = vidList1(cf0).name;
                matchFound = false;
                for cf02 = cf0+1:numFiles
                    name2 = vidList1(cf02).name;
                    if strcmp(name1,name2)
                        matchFound = true;
                        break;
                    end
                end
                if ~matchFound
                    cnt = cnt + 1;
                    vidList(cnt) = vidList1(cf0);
                end
            end
        else
            extn2 = ['*.',extn];
            vidList = findsubdir(vidPath,extn2); % type 0
        end
        
        %     len = length(vidPath);
        
        numFiles = numel(vidList);
        chckboxes = cell(numFiles,2);
        origScrnSize = get(0,'screensize');
        origScrnSize = round(origScrnSize(3:4)*0.8);
        winWid = round(origScrnSize(1)*0.7);
        winLen = round(origScrnSize(2)-100);
        interv = round(winLen/(numFiles+2));
        
        fig = figure('Units','Pixels',...
            'Position',[100, 100,winWid,...
            winLen],...
            'Name','Check files to use',...
            'Toolbar','none',...
            'Menubar','none',...
            'Visible','On');
        yMin = 10;
        yMax = winLen-30;
        yvals = linspace(yMin,yMax,numFiles+1);
        skipList = []; %[7,16,30,42,45];
        for cfc = 1:numFiles
            
            if ~isempty(find(skipList==cfc,1))
                tmpVal = false;
            else
                tmpVal = true;
            end
            chckboxes{cfc,1} = uicontrol(fig,'Style',...
                'checkbox',...
                'String',vidList(cfc).name,...
                'Tag',num2str(cfc),...
                'Units','Pixels',...
                'HorizontalAlignment','center',...
                'Position',[10,yvals(numFiles-cfc+2),winWid-10,30],...
                'Value',tmpVal,...
                'Callback',{@boxSelectCallback,cfc});
            chckboxes{cfc,2} = tmpVal;
            %     yPos = yPos - interv;
        end
        
        bconfirm = uicontrol(fig,'Style',...
            'pushbutton',...
            'String',sprintf('Confirm'),...
            'Tag','confirmButton',...
            'Units','Pixels',...
            'HorizontalAlignment','center',...
            'Position',[10,yvals(1),80,30],...
            'Callback',@confirmCallback);
        set(fig,'Units','Normalized');
        set(bconfirm,'Units','Normalized');
        
        hlist = [];
        for cfc = 1:numFiles
            hlist = [hlist,chckboxes{cfc,1}];
            set(chckboxes{cfc,1},'Units','Normalized');
        end
        % align([hlist,bconfirm], 'None', 'Distribute')
        % set(fig,'Visible','On');
        
        % not processed -
        % {'I:\Postdoctoral Works\From Sina\Project - Neonatal Eye\Datasets\Datasets_PILOT\103-2016-05-27\103\0118','0118'}
        % {'I:\Postdoctoral Works\From Sina\Project - Neonatal Eye\Datasets\Datasets_PILOT\105-2016-05-27\105\0119','0119'}
        % {'I:\Postdoctoral Works\From Sina\Project - Neonatal
        % Eye\Datasets\Datasets_PILOT\206-2016-05-27\206\1229','1229'} - 3
        % {'I:\Postdoctoral Works\From Sina\Project - Neonatal Eye\Datasets\Datasets_PILOT\210-2016-05-27\210\0118','0118'}
        % {'0609 (file format problem_','I:\Postdoctoral Works\From Sina\Project - Neonatal Eye\Datasets\Datasets_PILOT\211-2016-07-07\211\0609 (file format problem_'}
    end
catch MEg
    errordlg(MEg.message);
    makeLog(MEg);
end
    function boxSelectCallback(hObject,eventdata,hd)
        chckboxes{hd,2} = get(hObject,'Value');
    end

    function confirmCallback(src,eventdata)
        ID = 'ALCVSOFT-VIP';
        waitbarHandle = waitbar(0,'Batch Segmentation Processing...');
        
        totalResult = [];
        totalResult = {'Filename','Number of Branches','Maximum Branch Length (pixels)','Minimum Branch Length (pixels)','Median Branch Length (pixels)','Maximum Branch Width (pixels)','Minimum Branch Width (pixels)','Median Branch Width (pixels)','Maximum Branch Tortuosity (max = 2)','Minimum Branch Tortuosity (max = 2)','Median Branch Tortuosity (max = 2)','Density (%)','CaseID'};
        xlswrite('Result.xlsx',totalResult);
                
        for cf = 1:numFiles
            cf
            if chckboxes{cf,2}
                ipPath = vidList(cf).name;                
                if handles.CurrInputType == handles.TYPE.MOV || handles.CurrInputType == handles.TYPE.RES || handles.CurrInputType == handles.TYPE.BFM || handles.CurrInputType == handles.TYPE.EYE
                    extn2 = ['*.',extn];
                    dir1 = dir(fullfile(ipPath,extn2));
                else
                    dir1(1).name = vidList(cf).folderName;
                end
                
                for cf2 = 1:numel(dir1)
                    waitbar(cf2/numel(dir1),waitbarHandle,sprintf('Processing ... %d out of %d',cf2,numel(dir1)));
                    if handles.CurrInputType == handles.TYPE.MOV || handles.CurrInputType == handles.TYPE.RES
                        fileName = [dir1(cf2).name(1:end-4),'.mat'];
                    elseif handles.CurrInputType == handles.TYPE.BFM || handles.CurrInputType == handles.TYPE.EYE
                        fileName = [dir1(cf2).name(1:end-4),'.jpg'];
                    else
                        fileName = [dir1(cf2).name,'.mat'];
                    end
                    dir2 = dir(fullfile(ipPath,fileName));
%                     if isempty(dir2)
                        try
                            
                            handles.segInfo = [];% clear previous segmentation info

                            
                            
                            if handles.CurrInputType == handles.TYPE.BFM
                                % Load Manually Selected BestFrame    
                                wrongData = false;
                                ManualBFM = [];
                                handles.frameStruct = [];
                                ManualBFM = imread(fullfile(ipPath,fileName));                            

                                tmpHandle = init(handles);
                                tmpHandle.CurrInptType = handles.CurrInputType;
                                tmpHandle.chosenInputType = handles.CurrInputType;
                                tmpHandle.ManualBFM = ManualBFM;
                                tmpHandle.frameStruct.NumFrames = 1;
                                tmpHandle.numInputImages = tmpHandle.frameStruct.NumFrames;
                                
                                tmpHandle = extractEyeRegionEx(tmpHandle);
                                
                                imageStack = tmpHandle.imageStack;
                                selectedSpecularMask = tmpHandle.selectedSpecularMask;
                                imgMat = tmpHandle.imgMat;
                                chosenInputType = tmpHandle.chosenInputType;    

                                img = tmpHandle.imageStack(1).Img;
                                handles.selectedFrame = img;
                            elseif handles.CurrInputType == handles.TYPE.EYE
                                % Load Manually Selected BestFrame    
                                wrongData = false;
                                ManualBFM = [];
                                handles.frameStruct = [];
                                ManualBFM = imread(fullfile(ipPath,fileName));                            

                                tmpHandle = init(handles);
                                tmpHandle.CurrInptType = handles.CurrInputType;
                                tmpHandle.chosenInputType = handles.CurrInputType;
                                tmpHandle.ManualBFM = ManualBFM;
                                tmpHandle.frameStruct.NumFrames = 1;
                                tmpHandle.numInputImages = tmpHandle.frameStruct.NumFrames;
                                
                                tmpHandle = extractEyeRegionEx(tmpHandle);
                                
                                
                                

                                Eyeimage = imread([ipPath '_Eye\' fileName(1:end-4) 'eye.JPG']);
                                Eyeimage = im2bw(Eyeimage);
                                Eyeminx = 9999; Eyeminy = 9999; Eyemaxx = 0; Eyemaxy = 0;
                                ManualBFM_tmp = zeros(size(ManualBFM,1),size(ManualBFM,2),size(ManualBFM,3));

                                if min(min(Eyeimage))==0
                                    for tmpi = 1:size(Eyeimage,1)
                                        tmp = Eyeimage(tmpi,:);
                                        tmp2 = find(tmp==0);
                                        if tmp2
                                            Eyeminx = min(Eyeminx,tmpi);
                                            Eyemaxx = max(Eyemaxx,tmpi);
                                            Eyeminy = min(Eyeminy,tmp2(1));
                                            Eyemaxy = max(Eyemaxy,tmp2(end));
                                            ManualBFM_tmp(tmpi,tmp2(1):tmp2(end),:) = double(ManualBFM(tmpi,tmp2(1):tmp2(end),:));
                                        end
                                    end
                                end        
                        %         for tmpi = 1:size(Eyeimage,1)
                        %             for tmpj = 1:size(Eyeimage,2)
                        %                 tmp = Eyeimage(tmpi,tmpj);
                        %                 if tmp == 0
                        %                     Eyeminx = min(Eyeminx,tmpi);
                        %                     Eyemaxx = max(Eyemaxx,tmpi);
                        %                     Eyeminy = min(Eyeminy,tmpj);
                        %                     Eyemaxy = max(Eyemaxy,tmpj);
                        %                     ManualBFM_tmp(tmpi,tmpj,:) = double(ManualBFM(tmpi,tmpj,:));
                        %                 end
                        %             end
                        %         end
                                imageStack = struct('Img',cell(1,1),...
                                    'OrigImg',cell(1,1),...
                                    'OrigFrameNum',cell(1,1),...
                                    'Rect',cell(1,1));
                                imageStack(1).Img = uint8(ManualBFM_tmp(Eyeminx:Eyemaxx,Eyeminy:Eyemaxy,:));
                                imageStack(1).OrigImg = ManualBFM;
                                imageStack(1).OrigFrameNum = 1;
                                imageStack(1).Rect = [Eyeminy,Eyeminx,Eyemaxy-Eyeminy+1,Eyemaxx-Eyeminx+1];
                                imageStack(1).mask = Eyeimage(Eyeminx:Eyemaxx,Eyeminy:Eyemaxy,:);

                                tmpHandle.imageStack = imageStack;                                
                                
                                
                                imageStack = tmpHandle.imageStack;
                                selectedSpecularMask = tmpHandle.selectedSpecularMask;
                                imgMat = tmpHandle.imgMat;
                                chosenInputType = tmpHandle.chosenInputType;    

                                img = tmpHandle.imageStack(1).Img;
                                handles.selectedFrame = img;
                                

                                
                            else
                                tmpHandle = init(handles);
                                tmpHandle.Result = load(fullfile(ipPath,fileName));
                                img = tmpHandle.Result.imageStack(1).Img;
                                handles.selectedFrame = img;
                            end            
                            
                            imSize = size(img);
                            dataSize = imSize(1)*imSize(2);

                            spMask = getSpecularityMask(img);

                            sImg = double(img) / 255;
                            R = sImg(:,:,1);
                            G = sImg(:,:,2);
                            B = sImg(:,:,3);
                            [L,~,~] = RGB2Lab(R,G,B);
                            L = L/100;
                            mask = ~(L<0.4);
                            mask(1:3,:) = false;
                            mask(end-3:end,:) = false;
                            mask(:,1:3) = false;
                            mask(:,end-3:end) = false;
                            mask = imerode(imfill(bwareafilt(mask,1),'holes'),strel('disk',11));
                            
                            if (sum(mask(:)) == 0)
                                level = graythresh(L);
                                mask = ~(L<level);
                                mask(1:3,:) = false;
                                mask(end-3:end,:) = false;
                                mask(:,1:3) = false;
                                mask(:,end-3:end) = false;
                                mask = imerode(imfill(bwareafilt(mask,1),'holes'),strel('disk',11));
                            end
                            
                            statMask = regionprops(mask,'MinorAxisLength','Area');
                            if length(statMask)>1
                                area = 0;
                                for cf = 1:length(statMask)
                                    if statMask(cf).Area>area
                                        area = statMask(cf).Area;
                                        minorAxis = statMask(cf).MinorAxisLength;
                                    end
                                end
                            else
                                minorAxis = statMask(1).MinorAxisLength;
                            end
                            mask = ~mask;    
                            if handles.CurrInputType == handles.TYPE.EYE
                                mask = tmpHandle.imageStack(1).mask;
                            end                            
                            
                            
                            
                        if handles.SegmentationChoice ~= 5   
                            
                            % Segmentation method 3 Hysteresis used        
                            img = removeSpecularity(img);
                            img2 = img(:,:,1);
                            h1 = fspecial('gaussian',31,31/4);
                            im2 = double(img2)-double(imfilter(img2,h1));
                            im2 = im2.*(~mask).*(im2<0);
                            im3 = imbothat(im2,strel('disk',31)).*(~mask);
            %                 opt = option_defaults_fa;
                            fImg = mat2gray(filter_image(img));
                            fImg(mask) = 1;
                            [~,imgf]=hysteresis3d(im3.*(1-fImg),0.02,0.05,8);
            %                 imgf = imerode(imgf,strel('disk',1));
                            imgf = imopen(imgf,strel('disk',1));
                
                            imgf(mask) = 0;
                            imgf = bwareafilt(imgf,[50,dataSize]);
                        else
                            Vesselimage = imread([ipPath '_Vessel\' fileName(1:end-4) 'vessel.JPG']);
                            Vesselimage = im2bw(Vesselimage);
                            Vesselimage = Vesselimage(tmpHandle.imageStack(1).Rect(2):tmpHandle.imageStack(1).Rect(2)+tmpHandle.imageStack(1).Rect(4)-1,tmpHandle.imageStack(1).Rect(1):tmpHandle.imageStack(1).Rect(1)+tmpHandle.imageStack(1).Rect(3)-1);
                            imgf = ~Vesselimage;
                
                        end
        
                        if handles.SegmentationChoice ~= 5
                            imgf(mask) = 0;
                            imgf = bwareafilt(imgf,[50,dataSize]);
                            % Attribute filtering
                            stats = regionprops(imgf,'MajorAxisLength','MinorAxisLength','Solidity','PixelIdxList');
                            for cf = 1:length(stats)
                                if (((stats(cf).MajorAxisLength/stats(cf).MinorAxisLength)<2) && (stats(cf).Solidity>0.7))
                                    imgf(stats(cf).PixelIdxList) = false;
                                end
                            end

                            [diagImg,branchImg,branchStruct,numImg] = analyzeVessels(imgf,10,minorAxis,0.05);
                            imgf = numImg>0;   
                        else
                            [diagImg,branchImg,branchStruct,numImg] = analyzeVessels(imgf,1,minorAxis,1);
                            imgf = numImg>0;   
                        end    
        

                            
                            
                            
                            
                            handles.selectedSegStruct.DiagImg = diagImg;
                            handles.selectedSegStruct.BranchImg = branchImg;
                            handles.selectedSegStruct.BranchStruct = branchStruct;
                            handles.selectedSegStruct.NumImg = numImg;
                            handles.selectedSegStruct.Img = mat2gray(imgf);
                            handles.selectedSegStruct.Seg(handles.SegmentationChoice,1).DiagImg = diagImg;
                            handles.selectedSegStruct.Seg(handles.SegmentationChoice,1).BranchImg = branchImg;
                            handles.selectedSegStruct.Seg(handles.SegmentationChoice,1).BranchStruct = branchStruct;
                            handles.selectedSegStruct.Seg(handles.SegmentationChoice,1).NumImg = numImg;
                            handles.selectedSegStruct.Seg(handles.SegmentationChoice,1).Img = mat2gray(imgf);


            

                            handles = showSegInfo(handles,0); % Reset
                            handles = showSegInfo(handles,1);

                            
                            
                            
                            tmpfileName = [dir1(cf2).name(1:end-4),'.mov'];
                            tmpResult = [tmpfileName,handles.segInfo,tmpfileName(1:8)];
                            totalResult = [totalResult;tmpResult];
                            xlswrite('Result.xlsx',totalResult);
                            
                            handles.segresultimg = img;
                            for cf = 1:3
                                tmp = handles.segresultimg(:,:,cf);
                                tmp(imgf) = tmp(imgf) + 50;
                                handles.segresultimg(:,:,cf) = tmp;
                            end                            
%                             handles.segresultimg(imgf) = img(imgf)+50;
                            imwrite(imresize(img,4),['Segmentation Result/',fileName(1:end-4),'.jpg']);
                            imwrite(imresize(handles.segresultimg,4),['Segmentation Result/',fileName(1:end-4),'_seg.jpg']);
                            
                        catch ME
                            fprintf('Incomplete: %s\n',fullfile(ipPath,dir1(cf2).name));
                            makeLog(ME);
                            continue;
                        end
%                     end
                end
            end
        end
        delete(waitbarHandle);
    end



end


% --------------------------------------------------------------------
function ClassificationMenu_Callback(hObject, eventdata, handles)
% hObject    handle to ClassificationMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

end


% --------------------------------------------------------------------
function TrainClassifierMenu_Callback(hObject, eventdata, handles)
% hObject    handle to TrainClassifierMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    % TYPE must be RESULTS (mat file) 
    if handles.CurrInputType ~= handles.TYPE.RES
        errordlg('Please choose type RESULT');
        return;
    end
    
    % Find current directory path
    resPath = uigetdir(pwd);
    if resPath==0
        errordlg('Current directory path not found');
        return;
    end
    
    extn = getExtn(handles.TYPE, handles.CurrInputType);
    extn2 = ['*.',extn];
    vidList = findsubdir(resPath,extn2); % type 0
    
    numFiles = numel(vidList);
    chckboxes = cell(numFiles, 2);
    
    origScrnSize = get(0,'screensize');
    origScrnSize = round(origScrnSize(3:4)*0.8);
    winWid = round(origScrnSize(1)*0.7);
    winLen = round(origScrnSize(2)-100);
    interv = round(winLen/(numFiles+2));
    
    % Create Figure to confirm selection results
    fig = figure('Units','Pixels',...
        'Position',[100, 100,winWid,...
        winLen],...
        'Name','Check files to use',...
        'Toolbar','none',...
        'Menubar','none',...
        'Visible','On');
    yMin = 10;
    yMax = winLen-30;
    yvals = linspace(yMin,yMax,numFiles+1);
    skipList = []; %[7,16,30,42,45];
    for cfc = 1:numFiles
        if ~isempty(find(skipList==cfc,1))
            tmpVal = false;
        else
            tmpVal = true;
        end
        % 
        chckboxes{cfc,1} = uicontrol(fig,'Style',...
            'checkbox',...
            'String',vidList(cfc).name,...
            'Tag',num2str(cfc),...
            'Units','Pixels',...
            'HorizontalAlignment','center',...
            'Position',[10,yvals(numFiles-cfc+2),winWid-10,30],...
            'Value',tmpVal,...
            'Callback',{@boxSelectCallback_SVM,cfc});
        chckboxes{cfc,2} = tmpVal;
        %     yPos = yPos - interv;
    end

    bconfirm = uicontrol(fig,'Style',...
        'pushbutton',...
        'String',sprintf('Confirm'),...
        'Tag','confirmButton',...
        'Units','Pixels',...
        'HorizontalAlignment','center',...
        'Position',[10,yvals(1),80,30],...
        'Callback',@confirmCallback_SVM);
    set(fig,'Units','Normalized');
    set(bconfirm,'Units','Normalized');

    hlist = [];
    for cfc = 1:numFiles
        hlist = [hlist,chckboxes{cfc,1}];
        set(chckboxes{cfc,1},'Units','Normalized');
    end
catch MEg
    errordlg(MEg.message);
    makeLog(MEg);
end

    function boxSelectCallback_SVM(hObject,eventdata,hd)
        chckboxes{hd,2} = get(hObject,'Value');
    end

    function confirmCallback_SVM(src,eventdata)
        ID = 'ALCVSOFT-VIP';
        if handles.CurrInputType ~= handles.TYPE.RES
            errordlg('Please choose type RESULT');
            return;
        end
        
        % User select where to store image
        image_folder_path = uigetdir(pwd, 'Select folder to store eye images');
        
        waitbarHandle = waitbar(0,'Training Classifier...');
        for cf = 1:numFiles
            cf
            if chckboxes{cf,2}
                ipPath = vidList(cf).name;
                curr_extn = ['*.', extn];
                dir1 = dir(fullfile(ipPath,extn2));
                    %dir1(1).name = vidList(cf).folderName;
                
                % Initialzie wait bar to be 0
                waitbar(0/numel(dir1),waitbarHandle,'Saving Automatic Eye Regions');
                
                for cf2 = 1:numel(dir1)

                    % try to load each mat file
                    results=[];
                    wrongData =[];
                    curr_filename = dir1(cf2).name;
                    try
                        [results,wrongData] = checkResultsConsistency(fullfile(ipPath, curr_filename));
                        
                        if (wrongData)
                            errrordlg(['Mat file ' curr_filename ' is invalid.']);
                            return;
                        end
                        
                    catch
                        errrordlg('Failed to read mat file.');
                        return;
                    end
                    
                    try
                        tmphandles = init(handles);
                        tmphandles.chosenInputType = results.chosenInputType;
                        
                        % Set ipPath to where user wants to save images
                        tmphandles.ipPath = image_folder_path;
                        
                        tmphandles.ipFile = results.ipFile;
                        tmphandles.imageStack = results.imageStack;

                        % Do not use specular mask for SVM training
                        % images
                        tmphandles.selectedSpecularMask = [];
                        tmphandles.imgMat = results.imgMat;
                        tmphandles.numInputImages = size(tmphandles.imgMat,1);
                        tmphandles.resultsLoaded = true;
                        
                        % Set auto selected frame to 1st frame in imageStack
                        % Take snapshot of tmphandles
                        tmphandles.selectedFrame = tmphandles.imageStack(1).Img;
                      
                        
                        % Save snapshot of automatic image
                        getSnapshot(tmphandles,6);
                    catch ME
                        fprintf('Incomplete: %s\n',fullfile(ipPath,dir1(cf2).name));
                        makeLog(ME);
                        continue;
                    end
                    
                    % Update waitbar
                    waitbar(cf2/numel(dir1),waitbarHandle);
                end
            end
        end
        delete(waitbarHandle);
    end
end


% --------------------------------------------------------------------
function EstimateAgeMenu_Callback(hObject, eventdata, handles)
% hObject    handle to EstimateAgeMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

errordlg('Function not available');
return;
end


% --------------------------------------------------------------------
function ExtractEyeRegionsMenu_Callback(hObject, eventdata, handles)
% hObject    handle to ExtractEyeRegionsMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

errordlg('Function not available');
return;
end


% --------------------------------------------------------------------
function VisualizationMenu_Callback(hObject, eventdata, handles)
% hObject    handle to VisualizationMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


end

% --------------------------------------------------------------------
function FindCirclesMenu_Callback(hObject, eventdata, handles)
% hObject    handle to FindCirclesMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)\

    img_hf = handles.imageStack(handles.currChosenFrame).Img;
    
    circularHoughThresh = 1.5;
    radii = floor(1/5 * max(size(img_hf)):1:max(size(img_hf)));
    
    load modelparameters.mat
    
    h1 = fspecial('gaussian',[15 15],3);
    h21 = strel('disk',5);
    
    img = img_hf;
    %img = imfilter(img_hf(:,:,1),h1);

    img(isnan(img)) = 0;

    % Identify red regions and threshold on these regions
    % BW = otsu_mask
    R = img_hf(:,:,1);
    
    level = graythresh(R);
    BW = imbinarize(R,level);
    BW = imerode(bwareafilt(imfill(BW,'holes'),1),h21);
    
    h = circle_hough(R, radii, 'same');
    peaks = circle_houghpeaks(h, radii, 'nhoodxy', 15, 'nhoodr', 21, 'npeaks', 5, ...
        'Threshold',circularHoughThresh);
    
    
    % Create mask for valid region of image
    % valid region is defined as all areas that are not completely black
    valid_region_mask = R;
    valid_region_mask(valid_region_mask > 0) = 1;
    
    h = circle_hough(BW, radii, 'same');
    peaks = circle_houghpeaks(h, radii, 'nhoodxy', 15, 'nhoodr', 21, 'npeaks', 5, ...
        'Threshold',circularHoughThresh);
    
    figure;
    imshowpair(BW,img_hf,'montage');
    hold on;

    count = 1;
    circle_data = [];
    color_band = {'r-', 'b-','g-', 'g-', 'g-'};
    for peak = peaks
        [x, y] = circlepoints(peak(3));
        plot(x+peak(1), y+peak(2), color_band{count});
        
        % Circle mask
        circle_data(count).params = peak;
        circle_data(count).mask = get_circular_overlap_region(peak(1), peak(2), peak(3), size(BW));
        
        count = count+1;
    end
    hold off
    
    % Rank different circles
    curr_cost = inf;
    selected_circle_index = 0;
    for i = 1:length(circle_data)
        [C, Ao, Ac, Aec, At, skip_circle] = get_cost_per_circle(BW, circle_data(i).mask, valid_region_mask);
        
        if (skip_circle)
            continue;
        end
        
        circle_data(i).cost = C;
        circle_data(i).area.Ao = Ao;
        circle_data(i).area.Ac = Ac;
        circle_data(i).area.Aec = Aec;
        circle_data(i).area.At = At;
        
        if (C < curr_cost)
            curr_cost = C;
            selected_circle_index = i;
        end  
    end
    
    assert(selected_circle_index ~= 0);
    selected_circle = circle_data(selected_circle_index);
    
    % Pass only information from selected circle
    new_img = crop_to_mask(img_hf, selected_circle.mask);
    
    figure;
    imshow(new_img);
    
    figure;
    imshow(img_hf)
    hold on
    cx = selected_circle.params(1);
    cy = selected_circle.params(2);
    [x,y] = circlepoints(selected_circle.params(3));
    plot(x+cx, y+cy, 'g-');
end

function [BW, level, Ao] = get_otsu_threshold_region(curr_img)
    h1 = fspecial('gaussian',[15 15],3);
    h2 = strel('disk',19);
    % se = strel('disk',9);
    h21 = strel('disk',5);
    
    %ImgMask to get general circular region
    imgMask = curr_img(:,:,1)>20;
    if sum(imgMask(:))==0
        return;
    end
    imgMask = imerode(bwareafilt(imfill(imgMask,'holes'),1),h21);
        
    img = imfilter(curr_image(:,:,1),h1);
    img(isnan(img)) = 0;
    
    % Get red channel
    R = curr_img(:,:,1);
    level = graythresh(R);
    BW = imbinarize(R,level);
    BW = imerode(bwareafilt(imfill(BW,'holes'),1),h2);
    BW = BW & imgMask;
    
    Ao = sum(BW(:));
end

function [C, Ao, Ac, Aec, At, skip_circle] = get_cost_per_circle(otsu_mask, circle_mask, valid_region_mask)
    %assert(size(otsu_mask) == size(circle_mask));
    At = size(otsu_mask, 1)*size(otsu_mask,2);
    A_valid = sum(valid_region_mask(:) > 0);
    Ao = sum(otsu_mask(:));
    Ac = sum(circle_mask(:));
    
    if (size(circle_mask,1) > size(otsu_mask,1) || size(circle_mask,1) > size(otsu_mask,2))
        C = inf;
        Aec = 0;
        skip_circle = true;
        return;
    end
    
    Aec = sum(~otsu_mask(:) & circle_mask(:));
    Ac_invalid = sum(circle_mask(:) & ~valid_region_mask(:));
    Aoverlap = sum(otsu_mask(:) & circle_mask(:));
    
    a = 2;
    b = 1;
    c = 8;
    C = a*Aec/At + b*(1-Ac/At) + c*(Ac_invalid/Ac); 
    
    skip_circle = Aec/Ac >= 0.4 & Aoverlap/A_valid < 0.6;
end

% --------------------------------------------------------------------
function HomomorphicFilterMenu_Callback(hObject, eventdata, handles)
% hObject    handle to HomomorphicFilterMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

img_hf = handles.imageStack(handles.currChosenFrame).Img;
sigma= 1;

im_filt_eq = @(I, sigma) im2uint8(gaussian_homomorphic_filter(I, sigma));

fig = figure;
SliderH = uicontrol(fig,'style','slider','Value',sigma,'Units','normalized',...
    'min', min(size(img_hf,1), size(img_hf,2))/1000, 'max', max(size(img_hf,1), size(img_hf,2)));
addlistener(SliderH, 'Value', 'PostSet', @homomorphic_filter_callback);

im_filt = im_filt_eq(img_hf, sigma);
subplot(1,3,1); imagesc(img_hf); axis square; axis off
subplot(1,3,2); imagesc(im_filt); axis square; axis off
subplot(1,3,3); imagesc(img_hf-im_filt);axis square; axis off
    
    function homomorphic_filter_callback(source, eventdata)
        sigma = get(eventdata.AffectedObject, 'Value');
        im_filt = im_filt_eq(img_hf, sigma);
        
        fig;
        subplot(1,3,2); imagesc(im_filt); axis square; axis off;
        subplot(1,3,3); imagesc(img_hf - im_filt); axis square; axis off;
    end
end


% --------------------------------------------------------------------
function DataPruningMenu_Callback(hObject, eventdata, handles)
% hObject    handle to DataPruningMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)


end

% --------------------------------------------------------------------
function RerankFramesMenu_Callback(hObject, eventdata, handles)
% hObject    handle to RerankFramesMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    % TYPE must be RESULTS (mat file) 
    if handles.CurrInputType ~= handles.TYPE.RES
        errordlg('Please choose type RESULT');
        return;
    end
    
    % Find current directory path
    resPath = uigetdir(pwd);
    if resPath==0
        errordlg('Current directory path not found');
        return;
    end
    
    extn = getExtn(handles.TYPE, handles.CurrInputType);
    extn2 = ['*.',extn];
    vidList = findsubdir(resPath,extn2); % type 0
    
    numFiles = numel(vidList);
    chckboxes = cell(numFiles, 2);
    
    origScrnSize = get(0,'screensize');
    origScrnSize = round(origScrnSize(3:4)*0.8);
    winWid = round(origScrnSize(1)*0.7);
    winLen = round(origScrnSize(2)-100);
    interv = round(winLen/(numFiles+2));
    
    % Create Figure to confirm selection results
    fig = figure('Units','Pixels',...
        'Position',[100, 100,winWid,...
        winLen],...
        'Name','Check files to use',...
        'Toolbar','none',...
        'Menubar','none',...
        'Visible','On');
    yMin = 10;
    yMax = winLen-30;
    yvals = linspace(yMin,yMax,numFiles+1);
    skipList = []; %[7,16,30,42,45];
    for cfc = 1:numFiles
        if ~isempty(find(skipList==cfc,1))
            tmpVal = false;
        else
            tmpVal = true;
        end
        % 
        chckboxes{cfc,1} = uicontrol(fig,'Style',...
            'checkbox',...
            'String',vidList(cfc).name,...
            'Tag',num2str(cfc),...
            'Units','Pixels',...
            'HorizontalAlignment','center',...
            'Position',[10,yvals(numFiles-cfc+2),winWid-10,30],...
            'Value',tmpVal,...
            'Callback',{@boxSelectCallback_SVM,cfc});
        chckboxes{cfc,2} = tmpVal;
        %     yPos = yPos - interv;
    end

    bconfirm = uicontrol(fig,'Style',...
        'pushbutton',...
        'String',sprintf('Confirm'),...
        'Tag','confirmButton',...
        'Units','Pixels',...
        'HorizontalAlignment','center',...
        'Position',[10,yvals(1),80,30],...
        'Callback',@confirmCallback_SVM);
    set(fig,'Units','Normalized');
    set(bconfirm,'Units','Normalized');

    hlist = [];
    for cfc = 1:numFiles
        hlist = [hlist,chckboxes{cfc,1}];
        set(chckboxes{cfc,1},'Units','Normalized');
    end
catch MEg
    errordlg(MEg.message);
    makeLog(MEg);
end

    function boxSelectCallback_SVM(hObject,eventdata,hd)
        chckboxes{hd,2} = get(hObject,'Value');
    end

    function confirmCallback_SVM(src,eventdata)
        ID = 'ALCVSOFT-VIP';
        if handles.CurrInputType ~= handles.TYPE.RES
            errordlg('Please choose type RESULT');
            return;
        end
        
        % User select where to store image
        image_folder_path = uigetdir(pwd, 'Select folder to store eye images');
        
        reranking_runtime = [];
        waitbarHandle = waitbar(0,'Training Classifier...');
        for cf = 1:numFiles
            cf
            if chckboxes{cf,2}
                ipPath = vidList(cf).name;
                curr_extn = ['*.', extn];
                dir1 = dir(fullfile(ipPath,extn2));
                    %dir1(1).name = vidList(cf).folderName;
                
                % Initialzie wait bar to be 0
                waitbar(0/numel(dir1),waitbarHandle,sprintf('Pruning and Saving Automatic Eye Regions- %d/%d Complete',0,numel(dir1)));
                
                for cf2 = 1:numel(dir1)

                    % try to load each mat file
                    results=[];
                    wrongData =[];
                    curr_filename = dir1(cf2).name;
                    try
                        [results,wrongData] = checkResultsConsistency(fullfile(ipPath, curr_filename));
                        
                        if (wrongData)
                            errrordlg(['Mat file ' curr_filename ' is invalid.']);
                            return;
                        end
                        
                    catch
                        errrordlg('Failed to read mat file.');
                        return;
                    end
                    
                    try
                        tic
                        [new_image_stack, curr_reranking_runtime] = rerank_frames_v2(results.imageStack);
                        reranking_runtime = [reranking_runtime; curr_reranking_runtime];
                        
                        if (length(new_image_stack) == 0)
                            new_image_stack = results.imageStack;
                            fprintf('Original Frame Ranks Used: %s\n',fullfile(ipPath, curr_filename));
                        end
                        
                        % Save mat file im images folder
                        new_results = results;
                        new_results.imageStack = new_image_stack;
                        fileName = [curr_filename(1:end-4) '_rerank.mat'];
                        save(fullfile(image_folder_path,fileName), '-struct', 'new_results');
                        
                        tmphandles = init(handles);
                        tmphandles.chosenInputType = results.chosenInputType;
                        
                        % Set ipPath to where user wants to save images
                        tmphandles.ipPath = image_folder_path;
                        
                        tmphandles.ipFile = results.ipFile;
                        tmphandles.imageStack = new_image_stack;

                        % Do not use specular mask for SVM training
                        % images
                        tmphandles.selectedSpecularMask = [];
                        tmphandles.imgMat = results.imgMat;
                        tmphandles.numInputImages = size(tmphandles.imgMat,1);
                        tmphandles.resultsLoaded = true;
                        
                        % Set auto selected frame to 1st frame in imageStack
                        % Take snapshot of tmphandles
                        tmphandles.selectedFrame = tmphandles.imageStack(1).Img;
                        
                        % Save snapshot of automatic image
                        getSnapshot(tmphandles,6);
                        
                        % Update waitbar
                        waitbar(cf2/numel(dir1),waitbarHandle, sprintf('Pruning and Saving Automatic Eye Regions- %d/%d Complete',cf2,numel(dir1)));
                    catch ME
                        fprintf('Incomplete: %s\n',fullfile(ipPath,dir1(cf2).name));
                        makeLog(ME);
                        continue;
                    end
                    
                    
                end
            end
        end
        delete(waitbarHandle);
        
        % Save reranking runtime/used data
        save('reranking_runtime.mat', 'reranking_runtime');
    end
end

function [img_circ, selected_circle, bb_rect] = extract_circular_region(curr_img, resize_dimensions)
    
    circularHoughThresh = 1.5;
    radii = floor(1/5 * max(size(curr_img)):1:max(size(curr_img)));
    
    load modelparameters.mat
    
    h1 = fspecial('gaussian',[15 15],3);
    h21 = strel('disk',5);
    
    img = imfilter(curr_img(:,:,1),h1);
    img = curr_img;
    img(isnan(img)) = 0;

    % Identify red regions and threshold on these regions
    % BW = otsu_mask
    R = img(:,:,1);
    
    level = graythresh(R);
    BW = imbinarize(R,level);
    BW = imerode(bwareafilt(imfill(BW,'holes'),1),h21);
    
    h = circle_hough(R, radii, 'same');
    peaks = circle_houghpeaks(h, radii, 'nhoodxy', 15, 'nhoodr', 21, 'npeaks', 5, ...
        'Threshold',circularHoughThresh);
    
    % Create mask for valid region of image
    % valid region is defined as all areas that are not completely black
    valid_region_mask = R;
    valid_region_mask(valid_region_mask > 0) = 1;
    
    h = circle_hough(BW, radii, 'same');
    peaks = circle_houghpeaks(h, radii, 'nhoodxy', 15, 'nhoodr', 21, 'npeaks', 5, ...
        'Threshold',circularHoughThresh);
    
    % Store center, radii, and mask for circle
    count = 1;
    circle_data = [];
    for peak = peaks
        % Circle mask
        circle_data(count).params = peak;
        circle_data(count).mask = get_circular_overlap_region(peak(1), peak(2), peak(3), size(BW));
        
        count = count+1;
    end
    
    % Rank different circles
    cost_ind_mat = [];
    for i = 1:length(circle_data)
        [C, Ao, Ac, Aec, At, skip_circle] = get_cost_per_circle(BW, circle_data(i).mask, valid_region_mask);
        
        if (skip_circle)
            continue;
        end
        
        circle_data(i).cost = C;
        circle_data(i).area.Ao = Ao;
        circle_data(i).area.Ac = Ac;
        circle_data(i).area.Aec = Aec;
        circle_data(i).area.At = At;
        
        cost_ind_mat = [cost_ind_mat; C i];
    end
    
    % If no circle is a good fit, then we should not use this image
    % all together
    % Return an empty value
    if (isempty(cost_ind_mat))
        img_circ = [];
        selected_circle = [];
        bb_rect = [];
        return;
    end
    
    % Sort cost_ind_mat in ascending order to get best frame index 
    sorted_cost_ind_mat = sortrows(cost_ind_mat);
    
    % Pick the best circle - lowest cost
    selected_circle = circle_data(sorted_cost_ind_mat(1,2));
    
    % Pass only information from selected circle
    [img_circ, bb_rect] = crop_to_mask(curr_img, selected_circle.mask);
    
    % Find where extracted lens image occurs in base 1920x1080 image
    % use normalized correlation to find bounding box
    
    % resize image to specific dimensions if dimensions provided
    if (nargin == 2)
        img_circ = imresize(img_circ, resize_dimensions);
    end
end

function [new_img_stack, runtimes_per_image] = rerank_frames_v2(curr_img_stack)
    count = 1;
    
    % make a matrix to sort by cost of each image
    cost_ind_mat = [];
    runtimes_per_image = zeros(length(curr_img_stack), 2);
    for i = 1:length(curr_img_stack)
        tic
        curr_img = curr_img_stack(i).Img;
        
        [new_img, circle_data, bb_new] = extract_circular_region(curr_img, [224 224]);
          
        if (isempty(new_img))
            runtimes_per_image(i, 1) = toc;
            runtimes_per_image(i, 2) = 0;
            continue;
        end
        
        % Update bounding box coordinates - must translate coordinates
        bb_updated = curr_img_stack(i).Rect;
        bb_updated(1) = bb_updated(1) + bb_new(1);
        bb_updated(2) = bb_updated(2) + bb_new(2);
        bb_updated(3) = bb_new(3);
        bb_updated(4) = bb_new(4);
        
        % Update struct bounding box of chosen region
        new_tmp_img_stack = curr_img_stack(i);
        new_tmp_img_stack.Img = new_img;
        new_tmp_img_stack.Rect = bb_updated;
        new_tmp_img_stack.RectBasicExtractedImage = curr_img_stack(i).Rect;
        new_tmp_img_stack.BasicExtractedImg = curr_img_stack(i).Img;
        new_tmp_img_stack.BasicBoundingBox = bb_new;
        new_tmp_img_stack.Cost = circle_data.cost;
        
        tmp_img_stack(count) = new_tmp_img_stack;
        
        cost_ind_mat = [cost_ind_mat; circle_data.cost count];
        
        runtimes_per_image(i, 1) = toc;
        runtimes_per_image(i, 2) = 1;
            
        count = count + 1;
    end
    
    if (isempty(cost_ind_mat))
        new_img_stack = [];
        return;
    end
    
    % Sort cost_ind_mat in ascending order (lowest -> highest) cost
    sorted_cost_ind_mat = sortrows(cost_ind_mat);
    
    num_frames = length(tmp_img_stack);
    
    for i = 1:num_frames
        corresponding_ind = sorted_cost_ind_mat(i, 2);
        new_img_stack(i) = tmp_img_stack(corresponding_ind);
    end
end

function [new_img_stack] = rerank_frames(curr_img_stack)
    new_img_stack = curr_img_stack;
    inds_to_remove = [];
    
    for i = 1:length(curr_img_stack)
        curr_img = curr_img_stack(i).Img;
        
        radii = floor(1/5 * max(size(curr_img)):1:max(size(curr_img)));
        circularHoughThresh = 1.5;
        R = curr_img(:,:,1);
    
        level = graythresh(R);
        
        h1 = fspecial('gaussian',[15 15],3);
        h2 = strel('disk',19);
    
        h21 = strel('disk',5);
        BW = imbinarize(R, level);
        BW = imerode(bwareafilt(imfill(BW,'holes'),1),h21);
        h = circle_hough(BW, radii, 'same');
        peaks = circle_houghpeaks(h, radii, 'nhoodxy', 15, 'nhoodr', 21, 'npeaks', 5, ...
            'Threshold',circularHoughThresh);
        
        skip_frame = true;
        for peak = peaks
            %[x, y] = circlepoints(peak(3));
            %plot(x+peak(1), y+peak(2), 'g-');
            Cmask_overlap = get_circular_overlap_region(peak(1), peak(2), peak(3), size(BW));
            [C, Ao, Ac, Aec, At, skip_circle] = get_cost_per_circle(BW, Cmask_overlap, valid_region_mask);
            skip_frame = skip_frame & skip_circle;
        end

        if (level * 255 >= 60 && ~skip_frame)
            continue;
        end
        
        inds_to_remove = [inds_to_remove, i];
    end
    
    new_img_stack(inds_to_remove) = [];
end

% Returns binary mask of circular region
function [Cmask_overlap] = get_circular_overlap_region(cx, cy, r, img_base_size)
    [xs, ys] = circlepoints(r);
    
    circle_outline = zeros(img_base_size);
    for i = length(xs) 
        circle_outline(cy + ys(i), cx + xs(i)) = true;
    end
    
    Cmask_overlap = zeros(img_base_size);
    for y = 1:size(circle_outline, 1)
        for x = 1:size(circle_outline, 2)
            Cmask_overlap(y,x) = (hypot(x-cx, y-cy) <= r);
        end
    end
    
    % Account for missing edges
    Cmask_overlap = circle_outline | Cmask_overlap;
    Cmask_overlap = imfill(Cmask_overlap, 'holes');
end


% --------------------------------------------------------------------
function CheckVarianceMenu_Callback(hObject, eventdata, handles)
% hObject    handle to CheckVarianceMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

img = handles.imageStack(handles.currChosenFrame).Img;
I_var = im2uint8(variance_conv(img(:,:,1), 15));

circularHoughThresh = 1.5;
radii = floor(1/5 * max(size(img)):1:max(size(img)));
h = circle_hough(I_var, radii, 'same');
peaks = circle_houghpeaks(h, radii, 'nhoodxy', 15, 'nhoodr', 21, ...
                        'npeaks', 5, 'Threshold',circularHoughThresh);
    
figure;
imshowpair(img, I_var, 'montage');
colormap gray

    
figure;
imagesc(I_var)
axis square
colormap gray
hold on;

count = 1;
circle_data = [];
color_band = {'r-', 'b--','b.', 'g--', 'g.'};
for peak = peaks
    [x, y] = circlepoints(peak(3));
    plot(x+peak(1), y+peak(2), color_band{count});

    count = count+1;
end
hold off

end


% --------------------------------------------------------------------
function ChannelVarianceMenu_Callback(hObject, eventdata, handles)
% hObject    handle to ChannelVarianceMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

img = handles.imageStack(handles.currChosenFrame).Img;
R = double(img(:,:,1));
G = double(img(:,:,2));
B = double(img(:,:,3));

I_var = (R-G > 0).*(R-G).^2 + (R-B > 0).*(R-B).^2 - (B-G).^2;
I_var(I_var < 0) = 0;

%I_var = I_var ./ max(I_var(:)) .* 255;
% 
% circularHoughThresh = 1.5;
% radii = floor(1/5 * max(size(img)):1:max(size(img)));
% h = circle_hough(I_var, radii, 'same');
% peaks = circle_houghpeaks(h, radii, 'nhoodxy', 15, 'nhoodr', 21, ...
%                         'npeaks', 5, 'Threshold',circularHoughThresh);
%     
% figure;
% imshowpair(img, I_var, 'montage');
% colormap gray
% 
%     
figure;
imagesc(I_var)
axis square
colormap gray
% hold on;
% 
% count = 1;
% circle_data = [];
% color_band = {'r-', 'b--','b.', 'g--', 'g.'};
% for peak = peaks
%     [x, y] = circlepoints(peak(3));
%     plot(x+peak(1), y+peak(2), color_band{count});
% 
%     count = count+1;
% end
% hold off

end


% --------------------------------------------------------------------
function SegmentationMenu_Callback(hObject, eventdata, handles)
% hObject    handle to SegmentationMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --------------------------------------------------------------------
function RefineAndExtractLensMenu_Callback(hObject, eventdata, handles)
% hObject    handle to RefineAndExtractLensMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% User should specify file for input images and file for mask
im_filedir = uigetdir(pwd(), 'Choose directory with input images');
if (isempty(im_filedir))
    return;
end

mask_filedir = fullfile(im_filedir, 'mask-pred');
if (exist(mask_filedir,'dir') ~= 7)
    errordlg('Path %s does not exist.\n Please use python FALL segmentation algorithm to generate raw masks')
    return;
end

lens_filedir = fullfile(im_filedir, 'lens');
check_and_create_dir(lens_filedir);

ims_data = dir(fullfile(im_filedir, '*.png'));
num_ims = length(ims_data);

waitbar_title = 'Extracting Lens %d/%d';
f = waitbar(0, sprintf(waitbar_title, 0, num_ims));

for i = 1:length(ims_data)
    curr_im_data = ims_data(i);
    im = imread(fullfile(curr_im_data.folder, curr_im_data.name));
    
    % Load mask
    mask_filename = [erase(curr_im_data.name, '.png'), '_mask.png'];
    raw_mask = imread(fullfile(curr_im_data.folder, 'mask-pred', mask_filename));
    
    % Find upsample factor, upsampled factor should be an integer and the
    % same in both the y and x directions
    y_uf = size(im, 1) / size(raw_mask, 1);
    x_uf = size(im, 2) / size(raw_mask, 2);
    if (y_uf ~= x_uf)
        errordlg('Upsample factor should be same in x and y directions.');
        return;
    end
    
    % Upsample and refine mask
    [~, mask_upsampled, cost, ~] = refine_mask(raw_mask, x_uf);
    
    % if cost is infinity, that means we should reject this image
    if (isinf(cost))
        continue
    end
    
    % Crop to mask to extract lens region
    lens = crop_to_mask(im, mask_upsampled);
    imwrite(lens, fullfile(lens_filedir, curr_im_data.name))
    
    waitbar(i/num_ims, f, sprintf(waitbar_title, i, num_ims))
end

close(f)

end





