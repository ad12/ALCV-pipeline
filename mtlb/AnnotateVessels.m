function varargout = AnnotateVessels(varargin)
% ANNOTATEVESSELS MATLAB code for AnnotateVessels.fig
%      ANNOTATEVESSELS, by itself, creates a new ANNOTATEVESSELS or raises the existing
%      singleton*.
%
%      H = ANNOTATEVESSELS returns the handle to a new ANNOTATEVESSELS or the handle to
%      the existing singleton*.
%
%      ANNOTATEVESSELS('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ANNOTATEVESSELS.M with the given input arguments.
%
%      ANNOTATEVESSELS('Property','Value',...) creates a new ANNOTATEVESSELS or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before AnnotateVessels_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to AnnotateVessels_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help AnnotateVessels

% Last Modified by GUIDE v2.5 29-Sep-2016 09:54:44

% Begin initialization code - DO NOT EDIT
gui_Singleton = 1;
gui_State = struct('gui_Name',       mfilename, ...
    'gui_Singleton',  gui_Singleton, ...
    'gui_OpeningFcn', @AnnotateVessels_OpeningFcn, ...
    'gui_OutputFcn',  @AnnotateVessels_OutputFcn, ...
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

% --- Executes just before AnnotateVessels is made visible.
function AnnotateVessels_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to AnnotateVessels (see VARARGIN)

% Choose default command line output for AnnotateVessels
handles.output = hObject;

path(path,'helpers/circle_hough');
path(path,'helpers/Dijkstra_segmentation');
path(path,'helpers/hysteresis');
path(path,'helpers/BCOSFIRE_matlab');
path(path,'helpers/Lasso');
path(path,'helpers');
set(0,'RecursionLimit',2000);

handles.FILL_COLOR = [79,129,189]/255;
handles.FILL_COLOR2 = [1,0,1];
% handles.OUTLINE_COLOR = [56,93,138]/255;
handles.OUTLINE_COLOR = [255,255,0];
handles.DUMMYIMAGE = uint8(255*ones(100,100,3));
handles.INIT_STACK_LEN = 30;
handles.MAX_ERASER_SIZE = 25; % for eraser
handles.HalfWinSize = 1; % for eraser
handles.EraserSize = (2*handles.HalfWinSize) + 1;
set(handles.EraserSizeSlider,'Value',0);
set(handles.EraserSizeSliderText,'String',sprintf('Size: %d',1));
handles.InfoH = []; % for segmentation options
handles.VidH = []; % for video upload
handles.VidStruct = [];

% Auto seg params
handles.AUTOSEG.COSFIRE_THRESHOLD = 37;
handles.AUTOSEG.COSFIRE_THRESHOLD_RANGE = [20,50];
handles.AUTOSEG.DIJKSTRA_FILTER_THRESHOLD = 0.6;
handles.AUTOSEG.DIJKSTRA_FILTER_THRESHOLD_RANGE = [0.5,0.7];
handles.AUTOSEG.DIJKSTRA_PERCENT_THRESHOLD = 0.7;
handles.AUTOSEG.DIJKSTRA_PERCENT_THRESHOLD_RANGE = [0.5,0.75];
handles.AUTOSEG.DIJKSTRA_RAW_FILTERED_THRESHOLD = 0.6;
handles.AUTOSEG.DIJKSTRA_RAW_FILTERED_THRESHOLD_RANGE = [0.5,0.7];
handles.AUTOSEG.HYSTERESIS_HIGH_THRESHOLD = 0.05;
handles.AUTOSEG.HYSTERESIS_HIGH_THRESHOLD_RANGE = [0.01,0.1];
handles.AUTOSEG.HYSTERESIS_LOW_THRESHOLD = 0.02;
handles.AUTOSEG.HYSTERESIS_LOW_THRESHOLD_RANGE = [0.01,0.1];
handles.AUTOSEG.TRACE_HIGH_THRESHOLD = 0.5;
handles.AUTOSEG.TRACE_HIGH_THRESHOLD_RANGE = [0.1,0.9];
handles.AUTOSEG.TRACE_LOW_THRESHOLD = 0.05;
handles.AUTOSEG.TRACE_LOW_THRESHOLD_RANGE = [0.01,0.1];

% Semi auto seg params
handles.SEMIAUTOSEG.LASSO_RAD = 300; % Increasing may slow down the system
handles.SEMIAUTOSEG.EDGE_WEIGHT = 1.0; 
handles.SEMIAUTOSEG.ORIENT_WEIGHT = 0.0; 
handles.SEMIAUTOSEG.LOG_WEIGHT = 0.0; 

[handles.HImg,handles.HImgPanel,handles.ApiImgPanel,handles.Mag]...
    = initFrame(1,handles.ImgAxis,handles.figure1,handles.ImgPanel,handles.DUMMYIMAGE);
handles.HFrame = initFrame(2,handles.FrameAxis,handles.figure1,handles.FramePanel,handles.DUMMYIMAGE);

handles.OpPathName = pwd;
handles.OpFile = [];

handles.StatusString = ['Uploaded video: %s\n',...
    'Uploaded frame: %s\n',...
    'Uploaded eye image: %s\n',...
    'Automatic eye extraction from frame: %s\n',...
    'Results file located: %s\n',...
    'For help, hover mouse over any control\n',...
    'or press "Help".'];

handles.infoText1 = ['Total number of branches: %d\n',...
    'Longest branch length: %.2f\n',...
    'Shortest branch length: %.2f\n',...
    'Maximum branch avg. width: %.2f\n',...
    'Minimum branch avg. width: %.2f\n',...
    'Maximum branch tortuosity: %.2f\n',...
    'Minimum branch tortuosity: %.2f\n',...
    'Vessel density (%%): %.2f\n'];
handles.infoText2 = ['Selected branch length: %.2f\n',...
    'Selected branch avg. width: %.2f\n',...
    'Selected branch tortuosity: %.2f\n',...
    'Width at selected pixel: %.2f'];

handles.UdStack = UndoStack(handles.INIT_STACK_LEN);

handles = init(handles);

% Update handles structure
guidata(hObject, handles);

% UIWAIT makes AnnotateVessels wait for user response (see UIRESUME)
% uiwait(handles.figure1);
end

% --- Outputs from this function are returned to the command line.
function varargout = AnnotateVessels_OutputFcn(hObject, eventdata, handles)
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;
end

function handles = init(handles)

try
    % general
    handles.ImageLoaded = false;
    handles.FrameLoaded = false;
    handles.VideoLoaded = false;
    handles.ResultLoaded = false;
    handles.ResultState = struct('ImgMask',cell(1,1),'Rect',cell(1,1),...
        'Annotation',cell(1,1));
    
    % image related
    if ~isempty(handles.VidStruct)
        delete(handles.VidStruct);
        handles.VidStruct = [];
    end
    handles.VidInfo = struct('TimeStamps',[],'FrameInfo',[],'CurrentFrame',[]);
    handles.Frame = handles.DUMMYIMAGE;
    handles.FrameSize = [100,100];
    handles.Img = handles.DUMMYIMAGE;
    handles.ImgMask = [];
    handles.DispImg = mat2gray(handles.Img);
    handles.ChosenSegImg = [];
    handles.SegImg = [];
    handles.Rect = [];
    handles.ImSize = [100,100];
    % handles.IsColor = false;
    if ~isempty(handles.InfoH)
        delete(handles.InfoH);
        handles.InfoH = [];
    end
    if ~isempty(handles.HImg)
        delete(handles.HImg);
        delete(handles.HImgPanel);
    end
    if ~isempty(handles.HFrame)
        delete(handles.HFrame);
    end
    [handles.HImg,handles.HImgPanel,handles.ApiImgPanel,handles.Mag]...
        = initFrame(1,handles.ImgAxis,handles.figure1,handles.ImgPanel,handles.Img);
    handles.HFrame = initFrame(2,handles.FrameAxis,handles.figure1,handles.FramePanel,handles.Frame);
    
    % controls
    handles.L = [];
    handles.N = [];
    handles.B = [];
    handles.CurrPt = [];
    handles.NumCurrPt = 0;
    handles.HDraw = [];
    struct1 = struct('Img',cell(4,1),'DiagImg',cell(4,1),'BranchImg',cell(4,1),'BranchStruct',cell(4,1),'NumImg',cell(4,1));
    handles.SelectedSegStruct = struct('Img',[],'DiagImg',[],'BranchImg',[],'BranchStruct',[],'NumImg',[],'MinorAxis',[],'Seg',[]);
    handles.SelectedSegStruct.Seg = struct1; % as the types of segmentation
    handles.SourcePix = [];
    handles.DestPix = [];
    handles.LassoPath = [];
    handles.InitLassoPath = [];
    handles.ImgNeiList = [];
    handles.FrameNeiList = [];
    handles.ImgCostMat = [];
    handles.FrameCostMat = [];
    handles.DrawMode = false;
    handles.EraseMode = false;
    handles.RemoveMode = false;
    handles.ForcedRemoveMode = false;
    handles.SemiAutoMode = false;
    handles.FrameEditMode = false; % Choose manual image from frame
    handles.ClosedLoopSeg = true; % closed loop manual annotation
    handles.SkeletonLasso = true; % lasso tool draws skeleton
    handles.UdStack.clearStack();
    
    % display
    handles.ShowOverlappedAnnotation = true;
    handles.SegmentationChoice = 3;
    
    % GUI
    handles = showSegInfo(handles,0);
    set(handles.StatusText,'String','');
    set(handles.SaveStatusText,'String','Save Status: not available');
    set(handles.OverlapAnnotationCheckBox,'Value',handles.ShowOverlappedAnnotation);
    set(handles.SegmentationOptionsPopUpMenu,'Value',handles.SegmentationChoice);
    set(handles.ImageAddressTextBox,'String','');
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

function handles = setGUIcontrols(handles)

try
    set(handles.AutomaticControlPanel,'Visible',getOnOff(~(handles.FrameEditMode || handles.SemiAutoMode)));
    set(handles.SemiAutoButtonGroup,'Visible',getOnOff(~handles.FrameEditMode));
    set(handles.ManualControlPanel,'Visible',getOnOff((~handles.SemiAutoMode) | handles.FrameEditMode));
    set(handles.ManualButtonGroup,'Visible',getOnOff(~handles.FrameEditMode));
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

function strVal = getOnOff(val)
if val
    strVal = 'On';
else
    strVal = 'Off';
end
end

function strVal = getYesNo(val)
if val
    strVal = 'Yes';
else
    strVal = 'No';
end
end

function [Him,hPanel,apiHPanel,mag] = initFrame(type,imgAxis,fig,panel,img,imgCallback)

try
    if type == 1
        specificArgNames = [];
        axisTag = get(imgAxis,'Tag');
        tArgs = images.internal.imageDisplayParseInputs(specificArgNames,img);
        imgAxis = axes('Parent',panel);
        Him = images.internal.basicImageDisplay(fig,imgAxis,...
            tArgs.CData,tArgs.CDataMapping,...
            tArgs.DisplayRange,tArgs.Map,...
            tArgs.XData,tArgs.YData, false);
        hPanel = imscrollpanel(panel,Him);
        set(imgAxis,'Tag',axisTag);
        apiHPanel = iptgetapi(hPanel);
        mag = apiHPanel.getMagnification();
    else
        axes(imgAxis);
        Him = imshow(mat2gray(img));
        hPanel = []; apiHPanel = []; mag = [];
    end
    if nargin == 6
        set(Him,'ButtonDownFcn',imgCallback);
    end
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

function handles = showSegInfo(handles,n,pt)

try
    branchStruct = handles.SelectedSegStruct.BranchStruct;
    diagImg = handles.SelectedSegStruct.DiagImg;
    
    if n == 1
        
        binImg = handles.SelectedSegStruct.NumImg>0;
        %     if ~isempty(handles.selectedMaskedRegion)
        %         mask = handles.selectedMaskedRegion;
        %         maskSum = sum(mask(:));
        %     else
        %         maskSum = 0;
        %     end
        dataSize = handles.ImSize(1)*handles.ImSize(2);
        
        len = length(branchStruct);
        if len>0
            maxLen = 0;
            minLen = Inf;
            maxWid = 0;
            minWid = Inf;
            maxTort = 0;
            minTort = Inf;
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
            end
            vd = sum(binImg(:))*100/(dataSize);% - maskSum);
        else
            maxLen = 0;
            minLen = 0;
            maxWid = 0;
            minWid = 0;
            maxTort = 0;
            minTort = 0;
            vd = 0;
        end
        S1 = sprintf(handles.infoText1,len,maxLen,minLen,maxWid,minWid,maxTort,minTort,vd);
        set(handles.InfoTextbox1,'String',S1);
    elseif n == 2
        cf = handles.CurrPt(2);
        S2 = sprintf(handles.infoText2,branchStruct(cf).Length,...
            branchStruct(cf).AvgWidth,...
            branchStruct(cf).Tortuosity,...
            diagImg(pt(2),pt(1)));
        set(handles.InfoTextbox2,'String',S2);
    else
        set(handles.InfoTextbox1,'String','');
        set(handles.InfoTextbox2,'String','');
    end
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

function handles = updateGUI(handles)

try
    tmpImg = handles.DispImg;
    if handles.SemiAutoMode
        if handles.NumCurrPt>0
            tmpPix = handles.DestPix;
            while tmpPix ~= handles.SourcePix
                if handles.LassoPath(tmpPix)==0
                    break;
                end
                [r,c] = ind2sub(handles.ImSize,handles.LassoPath(tmpPix));
                if r>handles.ImSize(1)
                    r = handles.ImSize(1);
                end
                if c>handles.ImSize(2)
                    c = handles.ImSize(2);
                end
                tmpImg(r,c,1) = 255;
                tmpImg(r,c,2) = 255;
                tmpImg(r,c,3) = 255;
                tmpPix = handles.LassoPath(tmpPix);
            end
        end
    else
        if ~isempty(handles.CurrPt)
            %     handles.statInfo.IsChosen = true;
            L2 = false(handles.ImSize(1),handles.ImSize(2));
            for cf = 1:handles.NumCurrPt
                if handles.CurrPt(cf)>0
                    L2 = L2 | (handles.L==handles.CurrPt(cf));
                end
            end
            for cf = 1:3
                tmp = tmpImg(:,:,cf);
                tmp(L2) = handles.FILL_COLOR(cf);
                tmpImg(:,:,cf) = tmp;
            end
            if ~handles.FrameEditMode
                if (handles.NumCurrPt == 1) && (~handles.RemoveMode)
                    if handles.CurrPt(2)>0
                        L3 = handles.SelectedSegStruct.NumImg==handles.CurrPt(2);
                        for cf = 1:3
                            tmp = tmpImg(:,:,cf);
                            tmp(L3) = handles.FILL_COLOR2(cf);
                            tmpImg(:,:,cf) = tmp;
                        end
                    end
                end
            end
        end
    end
    if (~isempty(handles.B)) && handles.ShowOverlappedAnnotation
        mask = handles.L>0;
        for cf = 1:3
            tmp = tmpImg(:,:,cf);
            tmp(mask) = tmp(mask) + 0.2;
            tmp(handles.B) = handles.OUTLINE_COLOR(cf);
            tmpImg(:,:,cf) = tmp;
        end
    end
    % handles = updateStatText(handles);
    set(handles.HImg,'CData',tmpImg);
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

% --- Executes on button press in LoadEyeImageButton.
function LoadEyeImageButton_Callback(hObject, eventdata, handles)
% hObject    handle to LoadEyeImageButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.DrawMode || handles.EraseMode || handles.RemoveMode || handles.ForcedRemoveMode
    return;
end

[file,pathname] = uigetfile({'*.bmp;*.emf;*.jpg;*.pgm;*.png;*.ppm;*.tif;*.tiff', 'All Image Files (*.bmp, *.emf, *.jpg, *.pgm, *.png, *.ppm, *.tif, *.tiff)';...
    '*.*',  'All Files (*.*)'},'Choose Image',handles.OpPathName);

if ~isequal(file, 0)
    try
        handles = init(handles);
        handles.ResultLoaded = true;
        % Find if there is a results file
        k = strfind(file,'.');
        matFileName = [file(1:k(end)-1),'.mat'];
        dir1 = dir(fullfile(pathname,matFileName));
        if ~isempty(dir1)
            tmpData = load(fullfile(pathname,matFileName));
            if (~isfield(tmpData,'data')) || (~isfield(tmpData.data,'ID'))
                errordlg('Results file found but seems corrupted');
                handles.ResultLoaded = false;
            end
            if handles.ResultLoaded
                if ~strcmp(tmpData.data.ID,'ANNOTATEVESSELS-VIP')
                    handles.ResultLoaded = false;
                else
                    data = tmpData.data;
                end
            end
            
            clear tmpData;
        else
            handles.ResultLoaded = false;
        end
        
        % Read the image
        img = imread(fullfile(pathname,file));
        if islogical(img)
            img = uint8(255*img);
        end
        nd = size(img,3);
        if nd>3
            img = img(:,:,1:3);
        elseif nd<3
            img = repmat(img(:,:,1),[1,1,3]);
        end
        
        handles.Img = img;
        if handles.ResultLoaded
            if sum(abs(double(img(:))-double(data.Img(:))))>0
                error('Discrepancy found between loaded results and current eye image');
            end
        end
        handles.DispImg = mat2gray(handles.Img);
        handles.ImSize = size(handles.Img);
        if handles.ResultLoaded
            handles.SegImg = data.Annotation;
            [handles.L,handles.N] = bwlabel(handles.SegImg);
            handles.B = bwmorph(handles.SegImg,'remove');
        else
            handles.SegImg = false(handles.ImSize(1),handles.ImSize(2));
            handles.L = zeros(handles.ImSize(1),handles.ImSize(2));
            handles.B = handles.SegImg;
            handles.N = 0;
        end
        handles.ChosenSegImg = handles.SegImg;
        handles.ResultState.Annotation = handles.ChosenSegImg;
        handles.UdStack.push(2,sparse(handles.SegImg));
        
        handles.SelectedSegStruct.MinorAxis = getMinorAxis(handles.Img);
        [diagImg,branchImg,branchStruct,numImg] = analyzeVessels(handles.SegImg,10,handles.SelectedSegStruct.MinorAxis);
        handles.SelectedSegStruct.DiagImg = diagImg;
        handles.SelectedSegStruct.BranchImg = branchImg;
        handles.SelectedSegStruct.BranchStruct = branchStruct;
        handles.SelectedSegStruct.NumImg = numImg;
        handles.SelectedSegStruct.Img = mat2gray(handles.SegImg);
        handles = showSegInfo(handles,0);
        handles = showSegInfo(handles,1);
        
        % Keep the data
        handles.OpFile = file;
        handles.OpPathName = pathname;
        handles.ImageLoaded = true;
        handles = getCostMat(handles,2); % get the cost matrices
        handles.SelectedSegStruct.MinorAxis = getMinorAxis(handles.Img);
        set(handles.StatusText,'String',sprintf(handles.StatusString,'Not used','Not used',file,'Not required',getYesNo(handles.ResultLoaded)));
        
        % Display it
        set(handles.ImageAddressTextBox,'String',fullfile(pathname,file));
        [handles.HImg,handles.HImgPanel,handles.ApiImgPanel,handles.MagImg]...
            = initFrame(1,handles.ImgAxis,handles.figure1,handles.ImgPanel,handles.Img,@Figs_Callback);
        
        handles = updateGUI(handles);
        guidata(hObject,handles);
    catch ME
        errordlg(ME.message)
        makeLog(ME);
    end
end

end

% --- Executes on button press in LoadFrameButton.
function LoadFrameButton_Callback(hObject, eventdata, handles)
% hObject    handle to LoadFrameButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.DrawMode || handles.EraseMode || handles.RemoveMode || handles.ForcedRemoveMode
    return;
end

[file,pathname] = uigetfile({'*.bmp;*.emf;*.jpg;*.pgm;*.png;*.ppm;*.tif;*.tiff', 'All Image Files (*.bmp, *.emf, *.jpg, *.pgm, *.png, *.ppm, *.tif, *.tiff)';...
    '*.*',  'All Files (*.*)'},'Choose Image',handles.OpPathName);

if ~isequal(file, 0)
    try
        handles = init(handles);
        handles.ResultLoaded = true;
        % Find if there is a results file
        k = strfind(file,'.');
        matFileName = [file(1:k(end)-1),'.mat'];
        dir1 = dir(fullfile(pathname,matFileName));
        if ~isempty(dir1)
            tmpData = load(fullfile(pathname,matFileName));
            if (~isfield(tmpData,'data')) || (~isfield(tmpData.data,'ID'))
                errordlg('Results file found but seems corrupted');
                handles.ResultLoaded = false;
            end
            if handles.ResultLoaded
                if ~strcmp(tmpData.data.ID,'ANNOTATEVESSELS-VIP')
                    handles.ResultLoaded = false;
                end
            end
            data = tmpData.data;
            clear tmpData;
        else
            handles.ResultLoaded = false;
        end
        
        % Read the image
        img = imread(fullfile(pathname,file));
        if islogical(img)
            img = uint8(255*img);
        end
        nd = size(img,3);
        if nd>3
            img = img(:,:,1:3);
        elseif nd<3
            img = repmat(img(:,:,1),[1,1,3]);
        end
        handles.Frame = img;
        if handles.ResultLoaded
            if sum(abs(double(img(:))-double(data.Frame(:))))>0
                error('Discrepancy found between loaded results and current frame');
            end
        end
        handles.FrameSize = size(handles.Frame);
        
        % Keep the data
        handles.OpFile = file;
        handles.OpPathName = pathname;
        handles.FrameLoaded = true;
        handles = getCostMat(handles,1); % get the cost matrices
        if handles.ResultLoaded
            outImgStruct.Img = data.Img;
            outImgStruct.Mask = data.ImgMask;
            outImgStruct.Rect = data.Rect;
        else
            outImgStruct = extractEyeRegionEx(handles);
        end
        if ~isempty(outImgStruct)
            handles.Img = outImgStruct.Img;
            handles.DispImg = mat2gray(handles.Img);
            handles.Rect = outImgStruct.Rect;
            handles.ImgMask = outImgStruct.Mask;
            handles.ImSize = size(handles.Img);
            if handles.ResultLoaded
                handles.SegImg = data.Annotation;
                [handles.L,handles.N] = bwlabel(handles.SegImg);
                handles.B = bwmorph(handles.SegImg,'remove');
            else
                handles.SegImg = false(handles.ImSize(1),handles.ImSize(2));
                handles.L = zeros(handles.ImSize(1),handles.ImSize(2));
                handles.B = handles.SegImg;
                handles.N = 0;
            end
            handles.ChosenSegImg = handles.SegImg;
            handles.UdStack.push(2,sparse(handles.SegImg));
            
            handles.SelectedSegStruct.MinorAxis = getMinorAxis(handles.Img);
            [diagImg,branchImg,branchStruct,numImg] = analyzeVessels(handles.SegImg,10,handles.SelectedSegStruct.MinorAxis);
            handles.SelectedSegStruct.DiagImg = diagImg;
            handles.SelectedSegStruct.BranchImg = branchImg;
            handles.SelectedSegStruct.BranchStruct = branchStruct;
            handles.SelectedSegStruct.NumImg = numImg;
            handles.SelectedSegStruct.Img = mat2gray(handles.SegImg);
            handles = showSegInfo(handles,0);
            handles = showSegInfo(handles,1);
            
            handles.ImageLoaded = true;
            handles = getCostMat(handles,2); % get the cost matrices
            handles.SelectedSegStruct.MinorAxis = getMinorAxis(handles.Img);
            [handles.HImg,handles.HImgPanel,handles.ApiImgPanel,handles.MagImg]...
                = initFrame(1,handles.ImgAxis,handles.figure1,handles.ImgPanel,handles.Img,@Figs_Callback);
        else
            handles.ImgMask = false(handles.FrameSize(1),handles.FrameSize(2));
        end
        
        % Keep original
        handles.ResultState.ImgMask = handles.ImgMask;
        handles.ResultState.Rect = handles.Rect;
        handles.ResultState.Annotation = handles.ChosenSegImg;
        if handles.ImageLoaded
            set(handles.StatusText,'String',sprintf(handles.StatusString,'Not used',file,'Not used','Completed',getYesNo(handles.ResultLoaded)));
        else
            set(handles.StatusText,'String',sprintf(handles.StatusString,'Not used',file,'Not used','No candidates found',getYesNo(handles.ResultLoaded)));
        end
        
        % Display it
        set(handles.ImageAddressTextBox,'String',fullfile(pathname,file));
        [handles.HFrame]...
            = initFrame(2,handles.FrameAxis,handles.figure1,handles.ImgPanel,handles.Frame,@Frame_Callback);
        
        handles = updateGUI(handles);
        guidata(hObject,handles);
    catch ME
        errordlg(ME.message)
        makeLog(ME);
    end
end

end

function Frame_Callback(hObject, eventdata)

try
    handles = guidata(hObject);
    if handles.DrawMode || handles.EraseMode || handles.RemoveMode || handles.ForcedRemoveMode || handles.SemiAutoMode
        return;
    end
    
    if handles.FrameEditMode
        
        updateMask = false;
        if sum(handles.ImgMask(:)~=handles.SegImg(:)) && (sum(handles.SegImg(:))>0)
            % if the mask changed, confirm the change
            choice = questdlg(sprintf('Location/shape of eye mask has changed. Do you want to update it?\n (warning: all annotation will be lost.'), ...
                'Eye mask update menu', ...
                'Yes','No','No');
            % Handle response
            switch choice
                case 'Yes'
                    updateMask = true;
                case 'No'
                    % do nothing
            end
        end
        
        handles.FrameEditMode = false;
        handles.ImSize = size(handles.Img);
        if updateMask
            [xx,yy] = meshgrid(1:handles.FrameSize(2),1:handles.FrameSize(1));
            minX = min(xx(handles.SegImg)); maxX = max(xx(handles.SegImg));
            minY = min(yy(handles.SegImg)); maxY = max(yy(handles.SegImg));
            handles.ImgMask = handles.SegImg;
            handles.Rect = [minX,minY,maxX-minX+1,maxY-minY+1];
            handles.Img = handles.Frame(minY:maxY,minX:maxX,:);
            notMask = ~handles.ImgMask(minY:maxY,minX:maxX);
            for cf = 1:3
                tmp = handles.Img(:,:,cf);
                tmp(notMask) = 0;
                handles.Img(:,:,cf) = tmp;
            end
            handles.ImSize = [handles.Rect(4),handles.Rect(3)];
            struct1 = struct('Img',cell(4,1),'DiagImg',cell(4,1),'BranchImg',cell(4,1),'BranchStruct',cell(4,1),'NumImg',cell(4,1));
            handles.SelectedSegStruct = struct('Img',[],'DiagImg',[],'BranchImg',[],'BranchStruct',[],'NumImg',[],'Seg',[]);
            handles.SelectedSegStruct.Seg = struct1; % as the types of segmentation
            handles.ChosenSegImg = false(handles.ImSize(1),handles.ImSize(2));
            handles.ImageLoaded = true;
            handles = getCostMat(handles,2); % get the cost matrices
            
            % Keep original
            handles.ResultState.ImgMask = handles.ImgMask;
            handles.ResultState.Rect = handles.Rect;
            handles.ResultState.Annotation = handles.ChosenSegImg;
            
            handles.SelectedSegStruct.MinorAxis = getMinorAxis(handles.Img);
            [diagImg,branchImg,branchStruct,numImg] = analyzeVessels(handles.ChosenSegImg,10,handles.SelectedSegStruct.MinorAxis);
            handles.SelectedSegStruct.DiagImg = diagImg;
            handles.SelectedSegStruct.BranchImg = branchImg;
            handles.SelectedSegStruct.BranchStruct = branchStruct;
            handles.SelectedSegStruct.NumImg = numImg;
            handles.SelectedSegStruct.Img = mat2gray(handles.SegImg);
        end
        handles.DispImg = mat2gray(handles.Img);
        handles.SegImg = handles.ChosenSegImg;
        handles.UdStack.clearStack();
        handles.UdStack.push(2,sparse(handles.SegImg));
        [handles.HImg,handles.HImgPanel,handles.ApiImgPanel,handles.MagImg]...
            = initFrame(1,handles.ImgAxis,handles.figure1,handles.ImgPanel,handles.DispImg,@Figs_Callback);
        
        if handles.ImageLoaded
            handles = showSegInfo(handles,1);
        end
    else
        handles.FrameEditMode = true;
        handles.DispImg = mat2gray(handles.Frame);
        handles.ImSize = handles.FrameSize;
        handles.SegImg = handles.ImgMask;
        [handles.HImg,handles.HImgPanel,handles.ApiImgPanel,handles.MagImg]...
            = initFrame(1,handles.ImgAxis,handles.figure1,handles.ImgPanel,handles.DispImg,@Figs_Callback);
        
        handles.UdStack.clearStack();
        handles.UdStack.push(2,sparse(handles.SegImg));
        handles = showSegInfo(handles,0);
    end
    [handles.L,handles.N] = bwlabel(handles.SegImg);
    handles.B = bwmorph(handles.SegImg,'remove');
    
    handles = setGUIcontrols(handles);
    handles = updateGUI(handles);
    guidata(hObject,handles);
    
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

function Figs_Callback(hObject, eventdata)

try
    handles = guidata(hObject);
    fig = ancestor(hObject,'figure');
    currPt = round(eventdata.IntersectionPoint);
    currPt(currPt<1) = 1;
    if currPt(1)>handles.ImSize(2) || currPt(2)>handles.ImSize(1)
        return;
    end
    if handles.EraseMode || handles.DrawMode
        props.WindowButtonMotionFcn = get(fig,'WindowButtonMotionFcn');
        props.WindowButtonUpFcn = get(fig,'WindowButtonUpFcn');
        setappdata(fig,'TestGuiCallbacks',props);
        n.pt(1) = currPt(1)-(fig.CurrentPoint(1)/handles.Mag);
        n.pt(2) = currPt(2)+(fig.CurrentPoint(2)/handles.Mag);
        guidata(hObject,handles);
        set(fig,'WindowButtonMotionFcn',{@MeasureWindowButtonMotionFcn,n})
        set(fig,'WindowButtonUpFcn',{@MeasureWindowButtonUpFcn})
    elseif handles.RemoveMode
        if ~isempty(handles.L)
            if handles.L(currPt(2),currPt(1))>0
                idx = find(handles.CurrPt == handles.L(currPt(2),currPt(1)));
                if isempty(idx)
                    handles.NumCurrPt = handles.NumCurrPt + 1;
                    handles.CurrPt(handles.NumCurrPt) = handles.L(currPt(2),currPt(1));
                else
                    %                 handles.NumCurrPt = handles.NumCurrPt - 1;
                    handles.CurrPt(idx) = 0;
                end
            end
        end
        handles = updateGUI(handles);
    elseif handles.SemiAutoMode
        if (eventdata.Button == 1)
            handles.NumCurrPt = handles.NumCurrPt + 1;
            handles.SourcePix = sub2ind(handles.ImSize,currPt(2),currPt(1));
            handles.CurrPt(handles.NumCurrPt).pt = currPt(1:2);
            handles.CurrPt(handles.NumCurrPt).h = rectangle('Position',...
                [handles.CurrPt(handles.NumCurrPt).pt,3,3],'Curvature',[1 1]);
            if handles.NumCurrPt>1
                tmpPix = handles.DestPix;
                sourcePix = sub2ind(handles.ImSize,...
                    handles.CurrPt(handles.NumCurrPt-1).pt(2),...
                    handles.CurrPt(handles.NumCurrPt-1).pt(1));
                %             handles.SegImg(tmpPix) = true;
                %             handles.B(tmpPix) = true;
                while tmpPix ~= sourcePix
                    if handles.LassoPath(tmpPix)==0
                        break;
                    end
                    [r,c] = ind2sub(handles.ImSize,handles.LassoPath(tmpPix));
                    if r>handles.ImSize(1)
                        r = handles.ImSize(1);
                    end
                    if c>handles.ImSize(2)
                        c = handles.ImSize(2);
                    end
                    handles.SegImg(r,c) = true;
                    handles.B(r,c) = true;
                    tmpPix = handles.LassoPath(tmpPix);
                end
                handles.SegImg(handles.CurrPt(handles.NumCurrPt-1).pt(2),...
                    handles.CurrPt(handles.NumCurrPt-1).pt(1)) = true;
                handles.B(handles.CurrPt(handles.NumCurrPt-1).pt(2),...
                    handles.CurrPt(handles.NumCurrPt-1).pt(1)) = true;
            end
            handles = updateGUI(handles);
            if handles.FrameEditMode
                handles.LassoPath = LiveWireFunc3_3(handles.FrameNeiList,handles.FrameCostMat,handles.ImSize(1),currPt(2)-1,currPt(1)-1,handles.SEMIAUTOSEG.LASSO_RAD);
            else
                handles.LassoPath = LiveWireFunc3_3(handles.ImgNeiList,handles.ImgCostMat,handles.ImSize(1),currPt(2)-1,currPt(1)-1,handles.SEMIAUTOSEG.LASSO_RAD);
            end
            if handles.NumCurrPt == 1
                handles.InitLassoPath = handles.LassoPath;
                props.WindowButtonMotionFcn = get(fig,'WindowButtonMotionFcn');
                setappdata(fig,'TestGuiCallbacks',props);
                n.pt(1) = currPt(1)-(fig.CurrentPoint(1)/handles.Mag);
                n.pt(2) = currPt(2)+(fig.CurrentPoint(2)/handles.Mag);
                guidata(hObject,handles);
                set(fig,'WindowButtonMotionFcn',{@MeasureWindowButtonMotionFcn,n})
            end
        elseif (eventdata.Button == 3)
            props = getappdata(fig,'TestGuiCallbacks');
            if ~isempty(props)
                set(fig,props);
                setappdata(fig,'TestGuiCallbacks',[]);
            end
            if handles.NumCurrPt>1 % closing of region is possible
                if handles.FrameEditMode || (~handles.SkeletonLasso)
                    tmpPix = sub2ind(handles.ImSize,...
                        handles.CurrPt(handles.NumCurrPt).pt(2),...
                        handles.CurrPt(handles.NumCurrPt).pt(1));
                    sourcePix = sub2ind(handles.ImSize,...
                        handles.CurrPt(1).pt(2),...
                        handles.CurrPt(1).pt(1));
                    handles.SegImg(handles.CurrPt(handles.NumCurrPt).pt(2),...
                        handles.CurrPt(handles.NumCurrPt).pt(1)) = true;
                    handles.B(handles.CurrPt(handles.NumCurrPt).pt(2),...
                        handles.CurrPt(handles.NumCurrPt).pt(1)) = true;
                    while tmpPix ~= sourcePix
                        if handles.InitLassoPath(tmpPix)==0
                            break;
                        end
                        [r,c] = ind2sub(handles.ImSize,handles.InitLassoPath(tmpPix));
                        if r>handles.ImSize(1)
                            r = handles.ImSize(1);
                        end
                        if c>handles.ImSize(2)
                            c = handles.ImSize(2);
                        end
                        handles.SegImg(r,c) = true;
                        handles.B(r,c) = true;
                        tmpPix = handles.InitLassoPath(tmpPix);
                    end
                    handles.SegImg(handles.CurrPt(1).pt(2),...
                        handles.CurrPt(1).pt(1)) = true;
                    handles.B(handles.CurrPt(1).pt(2),...
                        handles.CurrPt(1).pt(1)) = true;
                end
                for cf = 1:handles.NumCurrPt
                    delete(handles.CurrPt(cf).h);
                end
                handles.NumCurrPt = 0;
                handles.CurrPt = [];
            end
            handles.SourcePix = [];
            handles.DestPix = [];
            handles = updateGUI(handles);
        end
    else
        if ~isempty(handles.L)
            if handles.L(currPt(2),currPt(1))>0
                handles.CurrPt(1) = handles.L(currPt(2),currPt(1));
                handles.NumCurrPt = 1;
                handles.ForcedRemoveMode = true;
                set(handles.RemoveRegionButton,'BackgroundColor',[1.0,0.0,0.0]);
                if ~handles.FrameEditMode
                    handles.CurrPt(2) = handles.SelectedSegStruct.NumImg(currPt(2),currPt(1));
                    if handles.CurrPt(2)>0
                        handles = showSegInfo(handles,2,currPt);
                    end
                end
            else
                handles.CurrPt = [];
                handles.NumCurrPt = 0;
                handles.ForcedRemoveMode = false;
                set(handles.RemoveRegionButton,'BackgroundColor',[0.9412,0.9412,0.9412]);
            end
        end
        handles = updateGUI(handles);
    end
    
    guidata(hObject,handles);
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

function MeasureWindowButtonUpFcn(hObject, eventdata)

try
    handles = guidata(hObject);
    fig = ancestor(hObject,'figure');
    
    props = getappdata(fig,'TestGuiCallbacks');
    set(fig,props);
    setappdata(fig,'TestGuiCallbacks',[]);
    if handles.EraseMode
        %     handles.CustomSeg = true;
        [handles.L,results.N] = bwlabel(handles.SegImg);
        handles.B = bwmorph(handles.SegImg,'remove');
        handles.UdStack.push(2,sparse(handles.SegImg));
        if ~isempty(handles.HDraw)
            delete(handles.HDraw);
            handles.HDraw = [];
        end
        guidata(hObject,handles);
    end
    if ~isempty(handles.HDraw)
        tmpx = get(handles.HDraw,'xdata');
        tmpy = get(handles.HDraw,'ydata');
        if handles.ClosedLoopSeg || handles.FrameEditMode
            tmpx = [tmpx,tmpx(1)];
            tmpy = [tmpy,tmpy(1)];
        end
        tx = tmpx(1);
        ty = tmpy(1);
        len = length(tmpx);
        for cf = 2:len
            diffx = abs(tmpx(cf)-tmpx(cf-1));
            diffy = abs(tmpy(cf)-tmpy(cf-1));
            if (diffx <= 1) && (diffy <= 1)
                tx = [tx,tmpx(cf)];
                ty = [ty,tmpy(cf)];
            elseif diffx>=diffy
                valx = linspace(tmpx(cf-1),tmpx(cf),diffx+1);
                valy = interp1(tmpx(cf-1:cf),tmpy(cf-1:cf),valx);
                tx = [tx,valx];
                ty = [ty,valy];
            else
                valy = linspace(tmpy(cf-1),tmpy(cf),diffy+1);
                valx = interp1(tmpy(cf-1:cf),tmpx(cf-1:cf),valy);
                tx = [tx,valx];
                ty = [ty,valy];
            end
        end
        tx = round(tx);
        ty = round(ty);
        idx = sub2ind(handles.ImSize,ty,tx);
        if ~isempty(handles.SegImg)
            %         if len>0
            %             handles.customSeg = true;
            %         end
            segImgT = false(size(handles.SegImg));
            segImgT(idx) = true;
            if handles.FrameEditMode || handles.ClosedLoopSeg
                segImgT = imfill(segImgT,'holes');
%                 handles.SegImg = handles.SegImg | segImgT;
%             else
%                 if handles.ClosedLoopSeg
%                     segImgT = imfill(segImgT,'holes');
%                 end
%                 handles.SegImg = segImgT | handles.SegImg;
            end
            handles.SegImg = handles.SegImg | segImgT;
            [handles.L,handles.N] = bwlabel(handles.SegImg);
            handles.B = bwmorph(handles.SegImg,'remove');
            handles.UdStack.push(2,sparse(handles.SegImg));
            %         handles = updateStatInfo(handles);
            handles = updateGUI(handles);
        end
        delete(handles.HDraw);
        handles.HDraw = [];
        guidata(hObject,handles);
    end
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

function MeasureWindowButtonMotionFcn(hObject, eventdata,n)

try
    handles = guidata(hObject);
    pt(1) = (hObject.CurrentPoint(1)/handles.Mag) + n.pt(1);
    pt(2) = n.pt(2)-(hObject.CurrentPoint(2)/handles.Mag);
    pt = round(pt);
    if (pt(1)>1) && (pt(1)<handles.ImSize(2)) && (pt(2)>1) && (pt(2)<handles.ImSize(1))
        if handles.EraseMode
            vect1 = pt(2)-handles.HalfWinSize:pt(2)+...
                handles.HalfWinSize;
            vect2 = pt(1)-handles.HalfWinSize:pt(1)+...
                handles.HalfWinSize;
            vect1 = vect1(vect1>0);
            vect2 = vect2(vect2>0);
            handles.SegImg(vect1,vect2) = false;
            handles.B = bwmorph(handles.SegImg,'remove');
            if isempty(handles.HDraw)
                handles.HDraw = rectangle('Position',...
                    [pt(1)-handles.HalfWinSize,pt(2)-handles.HalfWinSize,...
                    handles.EraserSize,handles.EraserSize]);
            else
                set(handles.HDraw,'Position',...
                    [pt(1)-handles.HalfWinSize,pt(2)-handles.HalfWinSize,...
                    handles.EraserSize,handles.EraserSize]);
            end
            handles = updateGUI(handles);
        elseif handles.DrawMode
            if isempty(handles.HDraw)
                handles.HDraw = line(pt(1),pt(2),'LineWidth',3);
            else
                tmpx = get(handles.HDraw,'xdata');
                tmpy = get(handles.HDraw,'ydata');
                set(handles.HDraw,'xdata',[tmpx,pt(1)],'ydata',[tmpy,pt(2)]);
            end
        elseif handles.SemiAutoMode
            handles.DestPix = sub2ind(handles.ImSize,pt(2),pt(1));
            handles = updateGUI(handles);
        end
        guidata(hObject,handles);
    end
catch ME
    errordlg(ME.message);
    makeLog(ME);
end


end

% --- Executes on button press in ZoomInButton.
function ZoomInButton_Callback(hObject, eventdata, handles)
% hObject    handle to ZoomInButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.Mag = handles.Mag*2;
handles.ApiImgPanel.setMagnification(handles.Mag);
guidata(hObject,handles);

end

% --- Executes on button press in ZoomOutButton.
function ZoomOutButton_Callback(hObject, eventdata, handles)
% hObject    handle to ZoomOutButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.Mag = handles.Mag/2;
handles.ApiImgPanel.setMagnification(handles.Mag);
guidata(hObject,handles);

end



function ImageAddressTextBox_Callback(hObject, eventdata, handles)
% hObject    handle to ImageAddressTextBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of ImageAddressTextBox as text
%        str2double(get(hObject,'String')) returns contents of ImageAddressTextBox as a double

set(hObject,'String',fullfile(handles.OpPathName,handles.OpFile));

end

% --- Executes during object creation, after setting all properties.
function ImageAddressTextBox_CreateFcn(hObject, eventdata, handles)
% hObject    handle to ImageAddressTextBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end


% --- Executes on button press in DrawButton.
function DrawButton_Callback(hObject, eventdata, handles)
% hObject    handle to DrawButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.SegImg)
    return;
end

if handles.EraseMode || handles.RemoveMode || handles.ForcedRemoveMode
    return;
end

try
    fig = ancestor(hObject,'figure');
    
    if handles.DrawMode
        if handles.FrameEditMode
            %         handles.ImgMask = handles.SegImg;
        else
            handles.ChosenSegImg = handles.SegImg;
            [diagImg,branchImg,branchStruct,numImg] = analyzeVessels(handles.SegImg,10,handles.SelectedSegStruct.MinorAxis);
            handles.SelectedSegStruct.DiagImg = diagImg;
            handles.SelectedSegStruct.BranchImg = branchImg;
            handles.SelectedSegStruct.BranchStruct = branchStruct;
            handles.SelectedSegStruct.NumImg = numImg;
            handles.SelectedSegStruct.Img = mat2gray(handles.SegImg);
            handles = showSegInfo(handles,0);
            handles = showSegInfo(handles,1);
        end
        handles.DrawMode = false;
        set(fig,'Pointer','arrow');
        set(hObject,'BackgroundColor',[0.9412,0.9412,0.9412]);
    else
        if ~isempty(handles.HDraw)
            delete(handles.HDraw);
            handles.HDraw = [];
        end
        handles.DrawMode = true;
        handles.ShowOverlappedAnnotation = true;
        set(handles.OverlapAnnotationCheckBox,'Value',handles.ShowOverlappedAnnotation);
        set(fig,'Pointer','crosshair');
        set(hObject,'BackgroundColor',[1.0,0,0]);
    end
    guidata(hObject,handles);
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

% --- Executes on button press in EraseButton.
function EraseButton_Callback(hObject, eventdata, handles)
% hObject    handle to EraseButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.SegImg)
    return;
end

if handles.DrawMode || handles.RemoveMode || handles.ForcedRemoveMode
    return;
end

try
    fig = ancestor(hObject,'figure');
    
    if handles.EraseMode
        if handles.FrameEditMode
            %         handles.ImgMask = handles.SegImg;
        else
            handles.ChosenSegImg = handles.SegImg;
            [diagImg,branchImg,branchStruct,numImg] = analyzeVessels(handles.SegImg,10,handles.SelectedSegStruct.MinorAxis);
            handles.SelectedSegStruct.DiagImg = diagImg;
            handles.SelectedSegStruct.BranchImg = branchImg;
            handles.SelectedSegStruct.BranchStruct = branchStruct;
            handles.SelectedSegStruct.NumImg = numImg;
            handles.SelectedSegStruct.Img = mat2gray(handles.SegImg);
            handles = showSegInfo(handles,0);
            handles = showSegInfo(handles,1);
        end
        handles.EraseMode = false;
        set(hObject,'BackgroundColor',[0.9412,0.9412,0.9412]);
        if ~isempty(handles.HDraw)
            delete(handles.HDraw);
            handles.HDraw = [];
        end
    else
        handles.EraseMode = true;
        handles.ShowOverlappedAnnotation = true;
        set(handles.OverlapAnnotationCheckBox,'Value',handles.ShowOverlappedAnnotation);
        set(hObject,'BackgroundColor',[1.0,0,0]);
    end
    guidata(hObject,handles);
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

% --- Executes on button press in RemoveRegionButton.
function RemoveRegionButton_Callback(hObject, eventdata, handles)
% hObject    handle to RemoveRegionButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if isempty(handles.SegImg)
    return;
end

if handles.EraseMode || handles.DrawMode
    return;
end

try
    if handles.RemoveMode || handles.ForcedRemoveMode
        if ~isempty(handles.CurrPt)
            L2 = false(handles.ImSize(1),handles.ImSize(2));
            for cf = 1:handles.NumCurrPt
                if handles.CurrPt(cf)>0
                    L2 = L2 | (handles.L==handles.CurrPt(cf));
                end
            end
            handles.L(L2) = 0;
            handles.N = handles.N - handles.NumCurrPt;
            handles.SegImg = handles.L>0;
            handles.B = bwmorph(handles.SegImg,'remove');
            %         handles = updateStatInfo(handles);
            handles.CurrPt = [];
            handles.NumCurrPt = 0;
            if handles.FrameEditMode
                %             handles.ImgMask = handles.SegImg;
            else
                handles.ChosenSegImg = handles.SegImg;
                [diagImg,branchImg,branchStruct,numImg] = analyzeVessels(handles.SegImg,10,handles.SelectedSegStruct.MinorAxis);
                handles.SelectedSegStruct.DiagImg = diagImg;
                handles.SelectedSegStruct.BranchImg = branchImg;
                handles.SelectedSegStruct.BranchStruct = branchStruct;
                handles.SelectedSegStruct.NumImg = numImg;
                handles.SelectedSegStruct.Img = mat2gray(handles.SegImg);
                handles = showSegInfo(handles,0);
                handles = showSegInfo(handles,1);
            end
            handles.UdStack.push(2,sparse(handles.SegImg));
            handles = updateGUI(handles);
        end
        handles.RemoveMode = false;
        handles.ForcedRemoveMode = false;
        set(hObject,'BackgroundColor',[0.9412,0.9412,0.9412]);
    else
        handles.RemoveMode = true;
        set(hObject,'BackgroundColor',[1.0,0,0]);
    end
    guidata(hObject,handles);
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

% --- Executes on button press in ResetButton.
function ResetButton_Callback(hObject, eventdata, handles)
% hObject    handle to ResetButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~(handles.FrameEditMode || handles.ImageLoaded)
    return;
end

if handles.DrawMode || handles.RemoveMode || handles.RemoveMode || handles.ForcedRemoveMode
    return;
end

try
    updateSeg = false;
    choice = questdlg(sprintf('Resetting would keep uploaded results (if any)\n (warning: this is irreversible.\n Would you like to reset?'), ...
        'Reset menu', ...
        'Yes','No','No');
    % Handle response
    switch choice
        case 'Yes'
            updateSeg = true;
        case 'No'
            % do nothing
    end
    if updateSeg
        handles.UdStack.clearStack();
        if handles.FrameEditMode
            handles.SegImg = handles.ResultState.ImgMask;
            handles.ImgMask = handles.SegImg;
            handles.Rect = handles.ResultState.Rect;
            handles.ChosenSegImg = handles.ResultState.Annotation;
            handles.Img = handles.Frame(handles.Rect(2):handles.Rect(2)+handles.Rect(4)-1,...
                handles.Rect(1):handles.Rect(1)+handles.Rect(3)-1,:);
            struct1 = struct('Img',cell(4,1),'DiagImg',cell(4,1),'BranchImg',cell(4,1),'BranchStruct',cell(4,1),'NumImg',cell(4,1));
            handles.SelectedSegStruct = struct('Img',[],'DiagImg',[],'BranchImg',[],'BranchStruct',[],'NumImg',[],'Seg',[]);
            handles.SelectedSegStruct.Seg = struct1; % as the types of segmentation
            handles.ImageLoaded = true;
            handles = getCostMat(handles,2); % get the cost matrices
        elseif handles.ImageLoaded
            handles.SegImg = handles.ResultState.Annotation;
            handles.ChosenSegImg = handles.SegImg;
            [diagImg,branchImg,branchStruct,numImg] = analyzeVessels(handles.SegImg,10,handles.SelectedSegStruct.MinorAxis);
            handles.SelectedSegStruct.DiagImg = diagImg;
            handles.SelectedSegStruct.BranchImg = branchImg;
            handles.SelectedSegStruct.BranchStruct = branchStruct;
            handles.SelectedSegStruct.NumImg = numImg;
            handles.SelectedSegStruct.Img = mat2gray(handles.SegImg);
            handles = showSegInfo(handles,0);
            handles = showSegInfo(handles,1);
        end
        handles.UdStack.push(2,sparse(handles.SegImg));
        [handles.L,handles.N] = bwlabel(handles.SegImg);
        handles.B = bwmorph(handles.SegImg,'remove');
        handles = updateGUI(handles);
        guidata(hObject,handles);
    end
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

% --- Executes on selection change in SegmentationOptionsPopUpMenu.
function SegmentationOptionsPopUpMenu_Callback(hObject, eventdata, handles)
% hObject    handle to SegmentationOptionsPopUpMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns SegmentationOptionsPopUpMenu contents as cell array
%        contents{get(hObject,'Value')} returns selected item from SegmentationOptionsPopUpMenu

handles.SegmentationChoice = get(hObject,'Value');
guidata(hObject,handles);

end

% --- Executes during object creation, after setting all properties.
function SegmentationOptionsPopUpMenu_CreateFcn(hObject, eventdata, handles)
% hObject    handle to SegmentationOptionsPopUpMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: popupmenu controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end
end

% --- Executes when selected object is changed in SemiAutoButtonGroup.
function SemiAutoButtonGroup_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in SemiAutoButtonGroup
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.SkeletonLasso = strcmp(eventdata.NewValue.Tag,'SkeletonSemiAutoRadioButton'); % lasso tool draws skeleton
guidata(hObject,handles);

end


% --- Executes when selected object is changed in ManualButtonGroup.
function ManualButtonGroup_SelectionChangedFcn(hObject, eventdata, handles)
% hObject    handle to the selected object in ManualButtonGroup
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

handles.ClosedLoopSeg = strcmp(eventdata.NewValue.Tag,'ClosedLoopRadioButton'); % closed loop manual annotation
guidata(hObject,handles);

end

% --- Executes on button press in AutoSegmentButton.
function AutoSegmentButton_Callback(hObject, eventdata, handles)
% hObject    handle to AutoSegmentButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.FrameEditMode || (~handles.ImageLoaded)
    return;
end

if handles.DrawMode || handles.EraseMode || handles.RemoveMode || handles.ForcedRemoveMode
    return;
end

hb = [];
try
    addAnnotation = false;
    if sum(handles.SegImg(:))>0
        choice = questdlg(sprintf('You have previous annotation. Would you like to add to it, or create new?'), ...
            'Annotation menu', ...
            'Add','New','Cancel','Cancel');
        % Handle response
        switch choice
            case 'Add'
                addAnnotation = true;
            case 'New'
                % do nothing
            case 'Cancel',
                return;
        end
    end
    
    segmentationRequired = isempty(handles.SelectedSegStruct.Seg(handles.SegmentationChoice,1).Img);
    
    if segmentationRequired
        hb = waitbar(0,'Please wait while the frame is segmented','WindowStyle','modal');
        img = handles.Img;
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
        mask = ~mask;
        minorAxis = handles.SelectedSegStruct.MinorAxis;
        
        switch handles.SegmentationChoice
            case 1
                img = removeSpecularity(img);
                [~, imgf, ~, ~] = Application(img,handles.AUTOSEG.COSFIRE_THRESHOLD);
            case 2
                %             h1 = fspecial('gaussian',[15 15],3);
                %             h2 = strel('disk',5);
                
                h2 = fspecial('gaussian',7,1.);
                opt = option_defaults_fa;
                opt_d = dijkstra_seg_defaults;
                opt_d.flt_thr = handles.AUTOSEG.DIJKSTRA_FILTER_THRESHOLD;
                opt_d.t9 = handles.AUTOSEG.DIJKSTRA_PERCENT_THRESHOLD; % Percentage value
                opt_d.t11 = handles.AUTOSEG.DIJKSTRA_RAW_FILTERED_THRESHOLD; % Raw filtered value
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
                fImg = mat2gray(filter_image_mex(img));
                fImg(mask) = 1;
                [~,imgf]=hysteresis3d(im3.*(1-fImg),...
                    handles.AUTOSEG.HYSTERESIS_LOW_THRESHOLD,...
                    handles.AUTOSEG.HYSTERESIS_HIGH_THRESHOLD,8);
                %                 imgf = imerode(imgf,strel('disk',1));
                imgf = imopen(imgf,strel('disk',1));
            case 4
                img = removeSpecularity(img);
                imgf = hyst2d_3x(img,handles.AUTOSEG.TRACE_LOW_THRESHOLD,...
                    handles.AUTOSEG.TRACE_HIGH_THRESHOLD);
        end
        imgf(mask) = 0;
        imgf = bwareafilt(imgf,[50,dataSize]);
        
        % Attribute filtering
        stats = regionprops(imgf,'MajorAxisLength','MinorAxisLength','Solidity','PixelIdxList');
        for cf = 1:length(stats)
            if (((stats(cf).MajorAxisLength/stats(cf).MinorAxisLength)<2) && (stats(cf).Solidity>0.7))
                imgf(stats(cf).PixelIdxList) = false;
            end
        end
        
        [diagImg,branchImg,branchStruct,numImg] = analyzeVessels(imgf,10,minorAxis);
        imgf = numImg>0;
        
        handles.SelectedSegStruct.DiagImg = diagImg;
        handles.SelectedSegStruct.BranchImg = branchImg;
        handles.SelectedSegStruct.BranchStruct = branchStruct;
        handles.SelectedSegStruct.NumImg = numImg;
        handles.SelectedSegStruct.Img = mat2gray(imgf);
        handles.SelectedSegStruct.Seg(handles.SegmentationChoice,1).DiagImg = diagImg;
        handles.SelectedSegStruct.Seg(handles.SegmentationChoice,1).BranchImg = branchImg;
        handles.SelectedSegStruct.Seg(handles.SegmentationChoice,1).BranchStruct = branchStruct;
        handles.SelectedSegStruct.Seg(handles.SegmentationChoice,1).NumImg = numImg;
        handles.SelectedSegStruct.Seg(handles.SegmentationChoice,1).Img = mat2gray(imgf);
        %     handles.SegImg = imgf;
        close(hb);
        hb = [];
    else
        handles.SelectedSegStruct.DiagImg = handles.SelectedSegStruct.Seg(handles.SegmentationChoice,1).DiagImg;
        handles.SelectedSegStruct.BranchImg = handles.SelectedSegStruct.Seg(handles.SegmentationChoice,1).BranchImg;
        handles.SelectedSegStruct.BranchStruct = handles.SelectedSegStruct.Seg(handles.SegmentationChoice,1).BranchStruct;
        handles.SelectedSegStruct.NumImg = handles.SelectedSegStruct.Seg(handles.SegmentationChoice,1).NumImg;
        handles.SelectedSegStruct.Img = handles.SelectedSegStruct.Seg(handles.SegmentationChoice,1).Img;
        imgf = handles.SelectedSegStruct.NumImg>0;
    end
    if addAnnotation
        imgf = imgf | handles.SegImg;
        % recompute the statistics
        [diagImg,branchImg,branchStruct,numImg] = analyzeVessels(imgf,10,handles.SelectedSegStruct.MinorAxis);
        handles.SelectedSegStruct.DiagImg = diagImg;
        handles.SelectedSegStruct.BranchImg = branchImg;
        handles.SelectedSegStruct.BranchStruct = branchStruct;
        handles.SelectedSegStruct.NumImg = numImg;
        handles.SelectedSegStruct.Img = mat2gray(imgf);
        handles.SegImg = imgf;
    else
        handles.SegImg = imgf;
    end
    handles.ChosenSegImg = handles.SegImg;
    [handles.L,results.N] = bwlabel(handles.SegImg);
    handles.B = bwmorph(handles.SegImg,'remove');
    handles.UdStack.push(2,sparse(handles.SegImg));
    handles = showSegInfo(handles,0); % Reset
    handles = showSegInfo(handles,1);
    % handles = getCurrImg(handles,4);
    handles = updateGUI(handles);
    guidata(hObject,handles);
catch ME
    if ~isempty(hb)
        close(hb);
    end
    errordlg(ME.message);
    makeLog(ME);
end

end

function minorAxis = getMinorAxis(img)

try
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
    if numel(statMask)>1
        area = 0;
        for cf = 1:length(statMask)
            if statMask(cf).Area>area
                area = statMask(cf).Area;
                minorAxis = statMask(cf).MinorAxisLength;
            end
        end
    elseif numel(statMask) == 1
        minorAxis = statMask(1).MinorAxisLength;
    else
        minorAxis = 1;
    end
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

% --- Executes on button press in SaveResultsButton.
function SaveResultsButton_Callback(hObject, eventdata, handles)
% hObject    handle to SaveResultsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.DrawMode || handles.EraseMode || handles.RemoveMode || handles.ForcedRemoveMode
    return;
end

if ~handles.ImageLoaded
    errordlg('Cannot save without an eye image');
    return;
end

hb = waitbar(0,'Please wait while the data is being saved','WindowStyle','modal');
try   
    
    k = strfind(handles.OpFile,'.');
    opFileName = [handles.OpFile(1:k(end)-1),'.mat'];
    data.ID = 'ANNOTATEVESSELS-VIP';
    data.Img = handles.Img;
    data.Annotation = handles.ChosenSegImg;
    if handles.FrameLoaded
        data.Frame = handles.Frame;
        data.ImgMask = handles.ImgMask;
        data.Rect = handles.Rect;
        if handles.VideoLoaded
            handles.VidInfo.FrameInfo{handles.VidInfo.CurrentFrameIdx,3} = sparse(handles.ImgMask);
            handles.VidInfo.FrameInfo{handles.VidInfo.CurrentFrameIdx,4} = handles.Rect;
            handles.VidInfo.FrameInfo{handles.VidInfo.CurrentFrameIdx,5} = handles.Img;
            handles.VidInfo.FrameInfo{handles.VidInfo.CurrentFrameIdx,6} = sparse(handles.ChosenSegImg);
            data.VidInfo = handles.VidInfo;
        end
    end
    
    save(fullfile(handles.OpPathName,opFileName),'data','-v7.3');
    set(handles.SaveStatusText,'String','Save Status: saved');
    msgbox(sprintf('Data was saved in following path/file:\n%s',fullfile(handles.OpPathName,opFileName)));
    delete(hb);
catch ME
    delete(hb);
    errordlg(ME.message);
    makeLog(ME);
end

end


% --- Executes on button press in LassoButton.
function LassoButton_Callback(hObject, eventdata, handles)
% hObject    handle to LassoButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.DrawMode || handles.EraseMode || handles.RemoveMode || handles.ForcedRemoveMode
    return;
end

hb = [];
try
    if handles.SemiAutoMode
        handles.SemiAutoMode = false;
        props = getappdata(handles.figure1,'TestGuiCallbacks');
        if ~isempty(props)
            set(handles.figure1,props);
            setappdata(handles.figure1,'TestGuiCallbacks',[]);
        end
        if handles.NumCurrPt>1 % closing of region is possible
            handles.LassoPath = handles.InitLassoPath;
            for cf = 1:handles.NumCurrPt
                delete(handles.CurrPt(cf).h);
            end
            handles.NumCurrPt = 0;
            handles.CurrPt = [];
        end
        handles.SourcePix = [];
        handles.DestPix = [];
        if ~handles.FrameEditMode
            if handles.SkeletonLasso
                img = removeSpecularity(handles.Img);
                segImg = handles.SegImg  & (~handles.ChosenSegImg); % use just the new skeleton
                hb = waitbar(0,'Please wait while the skeleton is expanded','WindowStyle','modal');
                segImg = hyst2d_3x(img,0.05,0.5,[],segImg);
                delete(hb);
                hb = [];
                handles.SegImg = handles.SegImg | segImg;
            else
                handles.SegImg = imfill(handles.SegImg,'holes');
            end
            handles.ChosenSegImg = handles.SegImg;
            [diagImg,branchImg,branchStruct,numImg] = analyzeVessels(handles.SegImg,10,handles.SelectedSegStruct.MinorAxis);
            handles.SelectedSegStruct.DiagImg = diagImg;
            handles.SelectedSegStruct.BranchImg = branchImg;
            handles.SelectedSegStruct.BranchStruct = branchStruct;
            handles.SelectedSegStruct.NumImg = numImg;
            handles.SelectedSegStruct.Img = mat2gray(handles.SegImg);
            handles = showSegInfo(handles,0);
            handles = showSegInfo(handles,1);
        else
            handles.SegImg = imfill(imclose(handles.SegImg,strel('disk',2)),'holes');
        end
        handles.UdStack.push(2,sparse(handles.SegImg));
        [handles.L,handles.N] = bwlabel(handles.SegImg);
        handles.B = bwmorph(handles.SegImg,'remove');
        handles = updateGUI(handles);
        set(hObject,'BackgroundColor',[0.9412,0.9412,0.9412]);
    else
        if handles.FrameEditMode || handles.ImageLoaded
            handles.SemiAutoMode = true;
            set(hObject,'BackgroundColor',[1.0,0.0,0.0]);
        end
    end
    
    handles = setGUIcontrols(handles);
    guidata(hObject,handles);
catch ME
    if ~isempty(hb)
        delete(hb);
    end
    errordlg(ME.message);
    makeLog(ME);
end

end


% --- Executes on button press in OverlapAnnotationCheckBox.
function OverlapAnnotationCheckBox_Callback(hObject, eventdata, handles)
% hObject    handle to OverlapAnnotationCheckBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of OverlapAnnotationCheckBox

handles.ShowOverlappedAnnotation = get(handles.OverlapAnnotationCheckBox,'Value');
handles = updateGUI(handles);
guidata(hObject,handles);

end

% --- Executes on button press in RelaxationCheckBox.
function RelaxationCheckBox_Callback(hObject, eventdata, handles)
% hObject    handle to RelaxationCheckBox (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hint: get(hObject,'Value') returns toggle state of RelaxationCheckBox
end

% --------------------------------------------------------------------
function EditMenu_Callback(hObject, eventdata, handles)
% hObject    handle to EditMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --------------------------------------------------------------------
function UndoMenu_Callback(hObject, eventdata, handles)
% hObject    handle to UndoMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    myStack = handles.UdStack.popUD();
    if ~isempty(myStack)
        handles.SegImg = full(myStack.map);
        [handles.L,handles.N] = bwlabel(handles.SegImg);
        handles.B = bwmorph(handles.SegImg,'remove');
        set(handles.SaveStatusText,'String','Save Status: not saved');
        handles = updateGUI(handles);
        guidata(hObject,handles);
    end
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

% --------------------------------------------------------------------
function RedoMenu_Callback(hObject, eventdata, handles)
% hObject    handle to RedoMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    myStack = handles.UdStack.popRD();
    if ~isempty(myStack)
        handles.SegImg = full(myStack.map);
        [handles.L,handles.N] = bwlabel(handles.SegImg);
        handles.B = bwmorph(handles.SegImg,'remove');
        set(handles.SaveStatusText,'String','Save Status: not saved');
        handles = updateGUI(handles);
        guidata(hObject,handles);
    end
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end


% --- Executes on button press in AutoSegSettingsButton.
function AutoSegSettingsButton_Callback(hObject, eventdata, handles)
% hObject    handle to AutoSegSettingsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isempty(handles.InfoH)
    delete(handles.InfoH);
end

try
    origScrnSize = get(0,'screensize');
    figSize = round([origScrnSize(4),origScrnSize(3)]/3);
    handles.InfoH = figure('Position',[1 1 figSize(2) figSize(1)],...
        'Name','Auto Segmentation Setting',...
        'DeleteFcn',{@windowClosingASB},...
        'Toolbar','none',...
        'Menubar','none',...
        'Resize','Off',...
        'Visible','Off');
    movegui(handles.InfoH,'center');
    tableLen = figSize(1)-50;
    if tableLen<0
        tableLen = figSize(1);
    end
    
    num = 8;
    data = cell(num,2);
    data{1,1} = 'CosFire Threshold:';
    data{1,2} = handles.AUTOSEG.COSFIRE_THRESHOLD;
    data{2,1} = 'Dijkstra Filter Threshold:';
    data{2,2} = handles.AUTOSEG.DIJKSTRA_FILTER_THRESHOLD;
    data{3,1} = 'Dijkstra Percentage Value:';
    data{3,2} = handles.AUTOSEG.DIJKSTRA_PERCENT_THRESHOLD;
    data{4,1} = 'Dijkstra Raw Filtered Value:';
    data{4,2} = handles.AUTOSEG.DIJKSTRA_RAW_FILTERED_THRESHOLD;
    data{5,1} = 'Hysteresis High Threshold:';
    data{5,2} = handles.AUTOSEG.HYSTERESIS_HIGH_THRESHOLD;
    data{6,1} = 'Hysteresis Low Threshold:';
    data{6,2} = handles.AUTOSEG.HYSTERESIS_LOW_THRESHOLD;
    data{7,1} = 'Trace High Threshold:';
    data{7,2} = handles.AUTOSEG.TRACE_HIGH_THRESHOLD;
    data{8,1} = 'Trace Low Threshold:';
    data{8,2} = handles.AUTOSEG.TRACE_LOW_THRESHOLD;
    
    valueChanged = false;
    valueSaved = false;
    segAvailable = 4; % currently four types of autos segmentation available
    valueChangeIdx = false(segAvailable,1);
    
    maxLen = round((figSize(2)-25)/2);
    
    tbl1 = uitable(handles.InfoH,...
        'Tag','ASBTable',...
        'Data',data,...
        'FontSize',10,...
        'ColumnName', {'Name','Value'},...
        'ColumnEditable',[false,true],...
        'ColumnWidth',{maxLen-20,maxLen},...
        'CellEditCallback',{@TableCellEditCallbackASB},...
        'Position',[1,50,figSize(2)-10,tableLen]);
    
    bconfirm = uicontrol(handles.InfoH,'Style',...
        'pushbutton',...
        'String','Save',...
        'Tag','ASBConfirmButton',...
        'Units','Pixels',...
        'Position',[1,1,80,30],...
        'Callback',@confirmCallBackASB);
    
    set(handles.InfoH,'Visible','On');
    guidata(hObject,handles);
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

    function populateValueASB(r,val)
        isError = true;
        switch r
            case 1
                % CosFire Threshold
                if isa(val,'double')
                    if (val>=handles.AUTOSEG.COSFIRE_THRESHOLD_RANGE(1))...
                            && (val<=handles.AUTOSEG.COSFIRE_THRESHOLD_RANGE(2))
                        isError = false;
                        valueChangeIdx(1) = true;
                    end
                end
            case 2
                % Dijkstra Filter Threshold
                if isa(val,'double')
                    if (val>=handles.AUTOSEG.DIJKSTRA_FILTER_THRESHOLD_RANGE(1))...
                            && (val<=handles.AUTOSEG.DIJKSTRA_FILTER_THRESHOLD_RANGE(2))
                        isError = false;
                        valueChangeIdx(2) = true;
                    end
                end
            case 3
                % Dijkstra Percentage Value
                if isa(val,'double')
                    if (val>=handles.AUTOSEG.DIJKSTRA_PERCENT_THRESHOLD_RANGE(1))...
                            && (val<=handles.AUTOSEG.DIJKSTRA_PERCENT_THRESHOLD_RANGE(2))
                        isError = false;
                        valueChangeIdx(2) = true;
                    end
                end
            case 4
                % Dijkstra Raw Filtered Value
                if isa(val,'double')
                    if (val>=handles.AUTOSEG.DIJKSTRA_RAW_FILTERED_THRESHOLD_RANGE(1))...
                            && (val<=handles.AUTOSEG.DIJKSTRA_RAW_FILTERED_THRESHOLD_RANGE(2))
                        isError = false;
                        valueChangeIdx(2) = true;
                    end
                end
            case 5
                % Hysteresis High Threshold
                if isa(val,'double')
                    if (val>=handles.AUTOSEG.HYSTERESIS_HIGH_THRESHOLD_RANGE(1))...
                            && (val<=handles.AUTOSEG.HYSTERESIS_HIGH_THRESHOLD_RANGE(2))
                        isError = false;
                        valueChangeIdx(3) = true;
                    end
                end
            case 6
                % Hysteresis Low Threshold
                if isa(val,'double')
                    if (val>=handles.AUTOSEG.HYSTERESIS_LOW_THRESHOLD_RANGE(1))...
                            && (val<=handles.AUTOSEG.HYSTERESIS_LOW_THRESHOLD_RANGE(2))
                        isError = false;
                        valueChangeIdx(3) = true;
                    end
                end
            case 7
                % Trace High Threshold
                if isa(val,'double')
                    if (val>=handles.AUTOSEG.TRACE_HIGH_THRESHOLD_RANGE(1))...
                            && (val<=handles.AUTOSEG.TRACE_HIGH_THRESHOLD_RANGE(2))
                        isError = false;
                        valueChangeIdx(4) = true;
                    end
                end
            case 8
                % Trace Low Threshold
                if isa(val,'double')
                    if (val>=handles.AUTOSEG.TRACE_LOW_THRESHOLD_RANGE(1))...
                            && (val<=handles.AUTOSEG.TRACE_LOW_THRESHOLD_RANGE(2))
                        isError = false;
                        valueChangeIdx(4) = true;
                    end
                end
        end
        if ~isError
            data{r,2} = val;
            valueChanged = true;
        else
            set(tbl1,'Data',data);
        end
    end

    function TableCellEditCallbackASB(src, eventdata)
        indices = eventdata.Indices;
        localData = get(src,'Data');
        r = indices(:,1);
        if ~isempty(r)
            populateValueASB(r,localData{r,2});
        end
    end

    function confirmCallBackASB(src, eventdata)
        if valueChanged
            handles.AUTOSEG.COSFIRE_THRESHOLD = data{1,2};
            handles.AUTOSEG.DIJKSTRA_FILTER_THRESHOLD = data{2,2};
            handles.AUTOSEG.DIJKSTRA_PERCENT_THRESHOLD = data{3,2};
            handles.AUTOSEG.DIJKSTRA_RAW_FILTERED_THRESHOLD = data{4,2};
            handles.AUTOSEG.HYSTERESIS_HIGH_THRESHOLD = data{5,2};
            handles.AUTOSEG.HYSTERESIS_LOW_THRESHOLD = data{6,2};
            handles.AUTOSEG.TRACE_HIGH_THRESHOLD = data{7,2};
            handles.AUTOSEG.TRACE_LOW_THRESHOLD = data{8,2};
            for cf = 1:segAvailable
                if valueChangeIdx(cf)
                    % enable re-segmentation
                    handles.SelectedSegStruct.Seg(handles.SegmentationChoice,1).Img = [];
                end
            end
            valueSaved = true;
            guidata(hObject,handles);
            msgbox('Values are saved');
        end
    end

    function windowClosingASB(src,~)
        % global tempResults
        delete(tbl1);
        handles.InfoH = [];
        if valueSaved
            msgbox('To reflect the changes, you need to perform the auto-segmentation again.');
        end
        guidata(hObject,handles);
    end

end


% --- Executes on button press in SemiAutoSegSettingsButton.
function SemiAutoSegSettingsButton_Callback(hObject, eventdata, handles)
% hObject    handle to SemiAutoSegSettingsButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if ~isempty(handles.InfoH)
    delete(handles.InfoH);
end

try
    origScrnSize = get(0,'screensize');
    figSize = round([origScrnSize(4),origScrnSize(3)]/3);
    handles.InfoH = figure('Position',[1 1 figSize(2) figSize(1)],...
        'Name','Semi-Auto Segmentation Setting',...
        'DeleteFcn',{@windowClosingSASB},...
        'Toolbar','none',...
        'Menubar','none',...
        'Resize','Off',...
        'Visible','Off');
    movegui(handles.InfoH,'center');
    sabsGap = [round(figSize(2)/2),round(figSize(1)/4)];
    gap = 10;
    hei = sabsGap(2)-(2*gap); wid = sabsGap(1)-(2*gap);
    if hei>40
        hei = 40;
    end
    if wid>80
        wid = 80;
    end
    checkboxGap = round((figSize(2)-(wid+2*gap))/8);
    currX = gap;
    currY = gap;
    edgeW = handles.SEMIAUTOSEG.EDGE_WEIGHT;
    orientW = handles.SEMIAUTOSEG.ORIENT_WEIGHT;
    logW = handles.SEMIAUTOSEG.LOG_WEIGHT;
    
    bconfirm = uicontrol(handles.InfoH,'Style',...
        'pushbutton',...
        'String','Save',...
        'Tag','SASBConfirmButton',...
        'Units','Pixels',...
        'Position',[currX,currY,wid,hei],...
        'Callback',@confirmCallBackSASB);
    currY = currY + sabsGap(2);
    
    labelchckbox = uicontrol(handles.InfoH,'Style',...
        'text',...
        'String','Cost function',...
        'Tag','SABSlabel1',...
        'Units','Pixels',...
        'Position',[currX,currY,wid,hei]);
    
    currX = currX + wid + gap;

    sabseditbox1 = uicontrol(handles.InfoH,'Style',...
        'edit',...
        'String',num2str(edgeW),...
        'Tag','SABSedit1',...
        'Units','Pixels',...
        'Position',[currX,currY,checkboxGap,hei],...
        'Callback',{@costFuncEditboxCallbackSABS,1});
    currX = currX + 2*checkboxGap;
    
    sabseditbox2 = uicontrol(handles.InfoH,'Style',...
        'edit',...
        'String',num2str(orientW),...
        'Tag','SABSedit2',...
        'Units','Pixels',...
        'Position',[currX,currY,checkboxGap,hei],...
        'Callback',{@costFuncEditboxCallbackSABS,2});
    currX = currX + 2*checkboxGap;
    
    sabseditbox3 = uicontrol(handles.InfoH,'Style',...
        'edit',...
        'String',num2str(logW),...
        'Tag','SABSedit3',...
        'Units','Pixels',...
        'Position',[currX,currY,checkboxGap,hei],...
        'Callback',{@costFuncEditboxCallbackSABS,3});
    currX = currX + 2*checkboxGap;

    bEqualizeW = uicontrol(handles.InfoH,'Style',...
        'pushbutton',...
        'String','Normalize',...
        'Tag','SASBEqualizationButton',...
        'Units','Pixels',...
        'Position',[currX,currY,checkboxGap,hei],...
        'BackgroundColor',[0.9412,0.9412,0.9412],...
        'Callback',@normalizeWeights);
    
    currY2 = min(currY+hei+gap,currY+sabsGap(2));
    currY = currY + sabsGap(2);    
    currX = wid + 2*gap;
    
    sabslabelchkbox1 = uicontrol(handles.InfoH,'Style',...
        'text',...
        'String','Edge Weight',...
        'Tag','SABStextlabel1',...
        'Units','Pixels',...
        'Position',[currX,currY2,checkboxGap,hei]);
    currX = currX + 2*checkboxGap;
    
    sabslabelchkbox2 = uicontrol(handles.InfoH,'Style',...
        'text',...
        'String','Orientation Weight',...
        'Tag','SABStextlabel2',...
        'Units','Pixels',...
        'Position',[currX,currY2,checkboxGap,hei]);
    currX = currX + 2*checkboxGap;
    
    sabslabelchkbox3 = uicontrol(handles.InfoH,'Style',...
        'text',...
        'String','LOG Weight',...
        'Tag','SABStextlabel3',...
        'Units','Pixels',...
        'Position',[currX,currY2,checkboxGap,hei]);
    
    currY = currY + sabsGap(2);
    currX = gap;
    
    labelLassoLen = uicontrol(handles.InfoH,'Style',...
        'text',...
        'String','Lasso radius',...
        'Tag','SABSlabel1',...
        'Units','Pixels',...
        'Position',[currX,currY,wid,hei]);
    currX = currX + sabsGap(1);
    textLassoLen = uicontrol(handles.InfoH,'Style',...
        'edit',...
        'String',num2str(handles.SEMIAUTOSEG.LASSO_RAD),...
        'Tag','SABSlabel1',...
        'Units','Pixels',...
        'Position',[currX,currY,wid,hei],...
        'Callback',@textLasseLenCallbackSABS);
    valueChanged = false;
    costChanged = [false,false,false];    
    costEqualized = false;
    
    set(handles.InfoH,'Visible','On');
    guidata(hObject,handles);
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

    function costFuncEditboxCallbackSABS(src, eventdata, n)
        val = str2double(get(src,'String'));
        if (~isnan(val)) && (val>=0)
            switch n
                case 1
                    if val~= handles.SEMIAUTOSEG.EDGE_WEIGHT
                        costChanged(1) = true;
                        set(bEqualizeW,'BackgroundColor',[1.0,0.0,0.0]);
                    else
                        costChanged(1) = false;
                        set(bEqualizeW,'BackgroundColor',[0.9412,0.9412,0.9412]);
                    end
                    edgeW = val;
                case 2
                    if val~= handles.SEMIAUTOSEG.ORIENT_WEIGHT
                        costChanged(2) = true;
                        set(bEqualizeW,'BackgroundColor',[1.0,0.0,0.0]);
                    else
                        costChanged(2) = false;
                        set(bEqualizeW,'BackgroundColor',[0.9412,0.9412,0.9412]);
                    end
                    orientW = val;
                case 3
                    if val~= handles.SEMIAUTOSEG.LOG_WEIGHT
                        costChanged(3) = true;
                        set(bEqualizeW,'BackgroundColor',[1.0,0.0,0.0]);
                    else
                        costChanged(3) = false;
                        set(bEqualizeW,'BackgroundColor',[0.9412,0.9412,0.9412]);
                    end
                    logW = val;
            end
        else
            switch n
                case 1
                    set(sabseditbox1,'String',num2str(edgeW));
                case 2
                    set(sabseditbox2,'String',num2str(orientW));
                case 3
                    set(sabseditbox3,'String',num2str(logW));
            end
        end        
    end

    function normalizeWeights(src, eventdata)
        if sum(costChanged)>0
            sumW = edgeW + orientW + logW;
            if sumW>0
                edgeW = edgeW/sumW;
                orientW = orientW/sumW;
                logW = logW/sumW;
                set(sabseditbox1,'String',num2str(edgeW));
                set(sabseditbox2,'String',num2str(orientW));
                set(sabseditbox3,'String',num2str(logW));       
            else
                edgeW = 1.0;
                set(sabseditbox1,'String',num2str(edgeW));
                msgbox('Atleast one cost needs to be greater than 0');
            end
            costEqualized = true;
        end
        set(bEqualizeW,'BackgroundColor',[0.9412,0.9412,0.9412]);
    end

    function textLasseLenCallbackSABS(src, eventdata)
        val = str2double(get(src,'String'));
        valChanged = false;
        if ~isnan(val)
            if (val>=50)
                if (val>600)
                    choice = questdlg(sprintf('A large value would slow down the lasso.\nWould you still like to continue?'), ...
                        'Lasso Radius Update Menu', ...
                        'Yes','No','No');
                    % Handle response
                    switch choice
                        case 'Yes'
                            valChanged = true;
                        case 'No'
                            % do nothing
                    end
                else
                    valChanged = true;
                end
            end            
        end
        if ~valChanged
            set(src,'String',num2str(handles.SEMIAUTOSEG.LASSO_RAD));
        else
            valueChanged = true;
        end
    end

    function confirmCallBackSASB(src, eventdata)
        if valueChanged
            handles.SEMIAUTOSEG.LASSO_RAD = str2double(get(textLassoLen,'String'));            
        end
        sumCostChange = sum(costChanged);
        if (sumCostChange>0)
            if costEqualized
                if costChanged(1)
                    handles.SEMIAUTOSEG.EDGE_WEIGHT = edgeW;
                end
                if costChanged(2)
                    handles.SEMIAUTOSEG.ORIENT_WEIGHT = orientW;
                end
                if costChanged(3)
                    handles.SEMIAUTOSEG.LOG_WEIGHT = logW;
                end
                waitbarHandle = waitbar(0,'Computing new cost matrices');
                if handles.FrameLoaded
                    [handles.FrameCostMat,handles.FrameNeiList] = computeCostMat(handles.Frame,[],...
                        handles.SEMIAUTOSEG.EDGE_WEIGHT,...
                        handles.SEMIAUTOSEG.ORIENT_WEIGHT,...
                        handles.SEMIAUTOSEG.LOG_WEIGHT);
                    mask = handles.ImgMask(handles.Rect(2):handles.Rect(2)+handles.Rect(4)-1,...
                        handles.Rect(1):handles.Rect(1)+handles.Rect(3)-1);
                else
                    mask = [];
                end
                [handles.ImgCostMat,handles.ImgNeiList] = computeCostMat(handles.Img,...
                    mask,handles.SEMIAUTOSEG.EDGE_WEIGHT,...
                    handles.SEMIAUTOSEG.ORIENT_WEIGHT,...
                    handles.SEMIAUTOSEG.LOG_WEIGHT);
                delete(waitbarHandle);
            else
                msgbox('Any changes to cost values require pressing the "Normalize" button');
                sumCostChange = 0;
            end
        end
        if valueChanged || (sumCostChange>0)
            msgbox('Values are saved');
            guidata(hObject,handles);
        end
    end

    function windowClosingSASB(src,~)
        handles.InfoH = [];
        guidata(hObject,handles);
    end

end


% --- Executes on slider movement.
function EraserSizeSlider_Callback(hObject, eventdata, handles)
% hObject    handle to EraserSizeSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'Value') returns position of slider
%        get(hObject,'Min') and get(hObject,'Max') to determine range of slider

val = get(hObject,'Value');
val = round(val*(handles.MAX_ERASER_SIZE - 1) + 1);
handles.HalfWinSize = val;
handles.EraserSize = (2*handles.HalfWinSize) + 1;
set(handles.EraserSizeSliderText,'String',sprintf('Size: %d',val));
guidata(hObject,handles);

end

% --- Executes during object creation, after setting all properties.
function EraserSizeSlider_CreateFcn(hObject, eventdata, handles)
% hObject    handle to EraserSizeSlider (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: slider controls usually have a light gray background.
if isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor',[.9 .9 .9]);
end
end

% --- Executes on button press in HelpButton.
function HelpButton_Callback(hObject, eventdata, handles)
% hObject    handle to HelpButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

try
    open 'helpers/AnnotateVessels_Help.pdf';
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

% --------------------------------------------------------------------
function GetImgMenu_Callback(hObject, eventdata, handles)
% hObject    handle to GetImgMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
end

% --------------------------------------------------------------------
function GetAnnotatedImageMenu_Callback(hObject, eventdata, handles)
% hObject    handle to GetAnnotatedImageMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.DrawMode || handles.EraseMode || handles.RemoveMode || handles.ForcedRemoveMode
    return;
end

if ~handles.ImageLoaded
    errordlg('Cannot save without an eye image');
    return;
end

hb = waitbar(0,'Please wait while the data is being saved','WindowStyle','modal');
try   
    
    k = strfind(handles.OpFile,'.');
    fileName = handles.OpFile(1:k(end)-1);
    opFileName = [fileName,'_OVERLAP.tif'];
    opFileName2 = [fileName,'_SEG.tif'];
    opFileName3 = [fileName,'_IMG.tif'];
    if (~isempty(handles.ChosenSegImg))
        tmpImg = handles.DispImg;
        B = bwmorph(handles.ChosenSegImg,'remove');
        for cf = 1:3
            tmp = tmpImg(:,:,cf);
            tmp(handles.ChosenSegImg) = handles.FILL_COLOR(cf);
            tmp(handles.B) = handles.OUTLINE_COLOR(cf);
            tmpImg(:,:,cf) = tmp;
        end
        imwrite(tmpImg,fullfile(handles.OpPathName,opFileName));
        imwrite(handles.ChosenSegImg,fullfile(handles.OpPathName,opFileName2));
        if handles.FrameLoaded
            imwrite(handles.Img,fullfile(handles.OpPathName,opFileName3));
        end
        msgbox(sprintf('Images were saved in following path\n with extentions of _OVERLAP, _SEG, and _IMG after file name "%s":\n%s',fileName,handles.OpPathName));
    end
    delete(hb);
catch ME
    delete(hb);
    errordlg(ME.message);
    makeLog(ME);
end

end

% --------------------------------------------------------------------
function GetAnnotatedFrameMenu_Callback(hObject, eventdata, handles)
% hObject    handle to GetAnnotatedFrameMenu (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.DrawMode || handles.EraseMode || handles.RemoveMode || handles.ForcedRemoveMode
    return;
end

if ~handles.ImageLoaded
    errordlg('Cannot save without an eye image');
    return;
end

hb = waitbar(0,'Please wait while the data is being saved','WindowStyle','modal');
try   
    
    k = strfind(handles.OpFile,'.');
    fileName = handles.OpFile(1:k(end)-1);
    opFileName = [fileName,'_OVERLAP_FRAME.tif'];
    if (~isempty(handles.ChosenSegImg))
        tmpImg = handles.DispImg;
        B = bwmorph(handles.ChosenSegImg,'remove');
        for cf = 1:3
            tmp = tmpImg(:,:,cf);
            tmp(handles.ChosenSegImg) = handles.FILL_COLOR(cf);
            tmp(handles.B) = handles.OUTLINE_COLOR(cf);
            tmpImg(:,:,cf) = tmp;
        end
        frame = mat2gray(handles.Frame);
        frame2 = frame;
        frame(handles.Rect(2):handles.Rect(2)+handles.Rect(4)-1,...
            handles.Rect(1):handles.Rect(1)+handles.Rect(3)-1,:)...
            = tmpImg;
        notImgMask = ~handles.ImgMask;
        imgMaskD = imdilate(handles.ImgMask,strel('disk',2));
        imgMaskE = imerode(handles.ImgMask,strel('disk',2));
        imgMask = imgMaskD & (~imgMaskE);
        pinkColor = [1,0,1];
        for cf = 1:3
            tmp = frame(:,:,cf);
            tmp2 = frame2(:,:,cf);
            tmp(notImgMask) = tmp2(notImgMask);
            tmp(imgMask) = pinkColor(cf);
            frame(:,:,cf) = tmp;
        end
        imwrite(handles.Frame,fullfile(handles.OpPathName,[fileName,'.tif']));
        imwrite(frame,fullfile(handles.OpPathName,opFileName));
        msgbox(sprintf('Annotated frame was saved in following path/file: \n%s',fullfile(handles.OpPathName,opFileName)));
    end
    delete(hb);
catch ME
    delete(hb);
    errordlg(ME.message);
    makeLog(ME);
end

end


% --- Executes on button press in VideoUploadButton.
function VideoUploadButton_Callback(hObject, eventdata, handles)
% hObject    handle to VideoUploadButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.DrawMode || handles.EraseMode || handles.RemoveMode || handles.ForcedRemoveMode
    return;
end

loadVid = true;
if handles.VideoLoaded
    choice = questdlg(sprintf('A video is already loaded. Do you want to upload another?\n (warning: all annotation will be lost.'), ...
                'Video upload confirmation', ...
                'Yes','No','No');
            % Handle response
            switch choice
                case 'Yes'
                    % do nothing
                case 'No'
                    loadVid = false;
            end
end
wb = [];
if loadVid
    try
        if ~isempty(handles.VidStruct)
            delete(handles.VidStruct);
            handles.VidStruct = [];
        end
        [file,pathname] = uigetfile({'*.mov;*.mp4;*.avi', 'Supported Video Files (*.mov, *.mp4, *.avi)';...
            '*.*',  'All Files (*.*)'},'Choose Video',handles.OpPathName);
        
        if ~isequal(file, 0)
            
            wrongData = false;
            try
                frameStruct = GenericFrameReader(fullfile(pathname,file),true);
            catch ME2
                wrongData = true;
                msgStr = 'The video file cannot be read.';
                makeLog(ME2);
            end
            if frameStruct.NumFrames == 0
                wrongData = true;
                msgStr = 'No video frames found.';
            end
            if wrongData
                error(msgStr);
            end
            
            % Find if there is a results file
            try
                k = strfind(file,'.');
                matFileName = [file(1:k(end)-1),'.mat'];
                dir1 = dir(fullfile(pathname,matFileName));
                resultLoaded = true;
                if ~isempty(dir1)
                    tmpData = load(fullfile(pathname,matFileName));
                    if (~isfield(tmpData,'data')) || (~isfield(tmpData.data,'ID'))
                        errordlg('Results file found but seems corrupted');
                        resultLoaded = false;
                    end
                    if resultLoaded
                        if ~strcmp(tmpData.data.ID,'ANNOTATEVESSELS-VIP')
                            resultLoaded = false;
                        end
                    end
                    data = tmpData.data;
                    clear tmpData;
                else
                    resultLoaded = false;
                end
            catch ME2
                resultLoaded = false;
                makeLog(ME2);
            end
            
            % process time stamps
            if ~resultLoaded
                wb = waitbar(0,'Please wait while the video file is processed for display');
                for cf = 1:frameStruct.NumFrames
                    waitbar(cf/frameStruct.NumFrames,wb,...
                        sprintf('Reading frame %d of %d',cf,frameStruct.NumFrames));
                    imgo = frameStruct.getFrame();
                end
            end
            delete(wb);
            wb = [];
            
            handles = init(handles);
            
            handles.ResultLoaded = resultLoaded;
            handles.OpFile = file;
            handles.OpPathName = pathname;
            handles.VideoLoaded = true;
            if handles.ResultLoaded
                handles.VidInfo = data.VidInfo;
                frameStruct.CurrentTime = handles.VidInfo.TimeStamps;
                frameStruct.ProcessedOnce = true;
            else
                handles.VidInfo.TimeStamps = frameStruct.CurrentTime;
            end
            handles.VidStruct = frameStruct;
            
            handles = chooseVideoFrameOptions(handles);
            guidata(hObject,handles);
        end
    catch ME
        if ~isempty(wb)
            delete(wb);
        end
        errordlg(ME.message);
        makeLog(ME);
    end
end

end

% --- Executes on button press in ChooseVideoFrameButton.
function ChooseVideoFrameButton_Callback(hObject, eventdata, handles)
% hObject    handle to ChooseVideoFrameButton (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

if handles.DrawMode || handles.EraseMode || handles.RemoveMode || handles.ForcedRemoveMode
    return;
end

if ~handles.VideoLoaded 
    return;
end

if handles.FrameLoaded
    % populate the VidInfo with current settings
    handles.VidInfo.FrameInfo{handles.VidInfo.CurrentFrameIdx,3} = sparse(handles.ImgMask);
    if handles.ImageLoaded
        handles.VidInfo.FrameInfo{handles.VidInfo.CurrentFrameIdx,4} = handles.Rect;
        handles.VidInfo.FrameInfo{handles.VidInfo.CurrentFrameIdx,5} = handles.Img;
        handles.VidInfo.FrameInfo{handles.VidInfo.CurrentFrameIdx,6} = sparse(handles.ChosenSegImg);
    end
end
handles.UdStack.clearStack();
handles = chooseVideoFrameOptions(handles);
guidata(hObject,handles);
    
end

function handles = chooseVideoFrameOptions(handles)

if ~isempty(handles.VidH)
    delete(handles.VidH);
end

try
    origScrnSize = get(0,'screensize');
    figSize = round([origScrnSize(3),origScrnSize(4)]*0.8); % X Y
    buttonHeight = 30;
    buttonWidth = 80;
    frameGap = 10;
    frameMargin = 20;
    tableSize = [(figSize(1)-(3*frameGap))*0.25,round(figSize(2)*0.5)];
    if tableSize(1)>350
        tableSize(1) = 350;
    end
    axisSize = [round(figSize(1)-(3*frameGap)-tableSize(1)),round(figSize(2)-frameMargin-(2*frameGap)-buttonHeight)];
    sliderWidth = round(figSize(1)-(5*frameGap)-(3*buttonWidth));
    handles.VidH = figure('Position',[1 1 figSize(1) figSize(2)],...
        'Name','Choose Video Frame',...
        'DeleteFcn',{@windowClosingCVF},...
        'Toolbar','none',...
        'Menubar','none',...
        'Resize','Off',...
        'Visible','Off');
    
    currX = frameGap;
    currY = frameGap;
    bPrev = uicontrol(handles.VidH,'Style',...
        'pushbutton',...
        'String','Prev',...
        'Tag','prevButtonCVF',...
        'Units','Pixels',...
        'Position',[currX,currY,buttonWidth,buttonHeight],...
        'Callback',@prevCallbackCVF);
    currX = currX + buttonWidth + frameGap;
    imgSlider = uicontrol(handles.VidH,'Style',...
        'slider',...
        'Tag','imgSliderCVF',...
        'Units','Pixels',...
        'Position',[currX,currY,sliderWidth,buttonHeight],...
        'Callback',@sliderCallbackCVF);    
    currX = currX + sliderWidth + frameGap;
    bNext = uicontrol(handles.VidH,'Style',...
        'pushbutton',...
        'String','Next',...
        'Tag','nextButtonCVF',...
        'Units','Pixels',...
        'Position',[currX,currY,buttonWidth,buttonHeight],...
        'Callback',@nextCallbackCVF);
    currX = currX + buttonWidth + frameGap;
    bConfirm = uicontrol(handles.VidH,'Style',...
        'pushbutton',...
        'String','Confirm',...
        'Tag','confirmButtonCVF',...
        'BackgroundColor',[0.2,0.9,0],...
        'Units','Pixels',...
        'Position',[currX,currY,buttonWidth,buttonHeight],...
        'Callback',@confirmCallbackCVF);
    
    currY = currY + buttonHeight + 2*frameGap;
    currX = frameGap;
    hAxes = axes('Parent',handles.VidH,'Units','Pixels',...
                    'Position',[currX,currY,axisSize(1),axisSize(2)]);
    

    if ~isempty(handles.VidInfo.FrameInfo)
        data = handles.VidInfo.FrameInfo(:,1:2);
        dataLen = size(data,1);
    else
        data = [];
    end
                
    currX = currX + axisSize(1) + frameGap;
    tbl1 = uitable(handles.VidH,...
        'Tag','TableCVF',...
        'Data',data,...
        'FontSize',10,...
        'ColumnName', {'Frame','TimeStamp'},...
        'CellSelectionCallback',{@TableCellSelectCallbackCVF},...
        'Position',[currX,currY,tableSize(1),tableSize(2)]);

    currY = currY + tableSize(2) + frameGap;
    labelHeight = round(figSize(2) - currY - frameMargin);
    lbl1 = uicontrol(handles.VidH,'Style',...
        'text',...
        'String','',...
        'Tag','frameInfoTextCVF',...
        'TooltipString','Frame Information',...
        'Units','Pixels',...
        'Position',[currX,currY,tableSize(1),labelHeight]);
    
    lblString = 'Frame: %d\nTime Stamp: %f';
    
    axes(hAxes);
    hFrame = handles.VidStruct.getFrame(1);
    hImg = imshow(hFrame);
    currentFrame = 1;
    chosenFrameIdx = []; % in VidInfo
    numFrames = handles.VidStruct.NumFrames;
    set(lbl1,'String',sprintf(lblString,currentFrame,handles.VidInfo.TimeStamps(currentFrame)));
    set(imgSlider,'Value',0);
    
    movegui(handles.VidH,'center');
    set(handles.VidH,'Visible','On');
    uiwait(handles.VidH);
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

    function updateGUICVF()
        hFrame = handles.VidStruct.getFrame(currentFrame);
        set(hImg,'CData',hFrame);
        set(lbl1,'String',sprintf(lblString,currentFrame,handles.VidInfo.TimeStamps(currentFrame)));
    end

    function TableCellSelectCallbackCVF(src, eventdata)
        indices = eventdata.Indices;
        r = indices(:,1);
        if ~isempty(r)
            currentFrame = handles.VidInfo.FrameInfo{r,1};
            val = (currentFrame-1)/(numFrames-1);
            set(imgSlider,'Value',val);
            updateGUICVF();
        end
    end

    function nextCallbackCVF(src, eventdata)
        if currentFrame < numFrames
            currentFrame = currentFrame + 1;
            val = (currentFrame-1)/(numFrames-1);
            set(imgSlider,'Value',val);
            updateGUICVF();
        end
    end
    function prevCallbackCVF(src, eventdata)
        if currentFrame > 1
            currentFrame = currentFrame - 1;
            val = (currentFrame-1)/(numFrames-1);
            set(imgSlider,'Value',val);
            updateGUICVF();
        end
    end
    function sliderCallbackCVF(src, eventdata)
        val = get(src,'Value');
        currentFrame = round((numFrames-1)*val+1);
        updateGUICVF();
    end

    function confirmCallbackCVF(src, eventdata)
        frameExists = false;
        if ~isempty(handles.VidInfo.FrameInfo)
            for cf = 1:dataLen
                if handles.VidInfo.FrameInfo{cf,1} == currentFrame
                    frameExists = true;
                    chosenFrameIdx = cf;
                    break;
                end
            end
            if ~frameExists
                dataLen = dataLen + 1;
                chosenFrameIdx = dataLen;
            end
        else
            % 1 - frame number 
            % 2 - timestamp
            % 3 - ImgMask
            % 4 - Rect
            % 5 - Img
            % 6 - Annotation
            handles.VidInfo.FrameInfo = cell(1,6);
            dataLen = 1;
            chosenFrameIdx = 1;
        end
        if ~frameExists
            handles.VidInfo.FrameInfo{chosenFrameIdx,1} = currentFrame;
            handles.VidInfo.FrameInfo{chosenFrameIdx,2} = handles.VidInfo.TimeStamps(currentFrame);
        end
        handles.VidInfo.CurrentFrameIdx = chosenFrameIdx;
        
        frameLoadFunc(frameExists);
        delete(handles.VidH);
    end

    function frameLoadFunc(resultsLoaded)
        handles.Frame = hFrame;
        handles.FrameSize = size(handles.Frame);
        handles.FrameLoaded = true;
        handles = getCostMat(handles,1); % get the cost matrices
        outImgStruct = [];
        if resultsLoaded
            outImgStruct.Img = handles.VidInfo.FrameInfo{chosenFrameIdx,5};
            outImgStruct.Mask = full(handles.VidInfo.FrameInfo{chosenFrameIdx,3});
            outImgStruct.Rect = handles.VidInfo.FrameInfo{chosenFrameIdx,4};
        else
            outImgStruct = extractEyeRegionEx(handles);
            if ~isempty(outImgStruct)
                handles.VidInfo.FrameInfo{chosenFrameIdx,5} = outImgStruct.Img;
                handles.VidInfo.FrameInfo{chosenFrameIdx,3} = sparse(outImgStruct.Mask);
                handles.VidInfo.FrameInfo{chosenFrameIdx,4} = outImgStruct.Rect;
            end
        end
        if ~isempty(outImgStruct)
            handles.Img = outImgStruct.Img;
            handles.DispImg = mat2gray(handles.Img);
            handles.Rect = outImgStruct.Rect;
            handles.ImgMask = outImgStruct.Mask;
            handles.ImSize = size(handles.Img);
            if resultsLoaded
                handles.SegImg = full(handles.VidInfo.FrameInfo{chosenFrameIdx,6});
                [handles.L,handles.N] = bwlabel(handles.SegImg);
                handles.B = bwmorph(handles.SegImg,'remove');
            else
                handles.SegImg = false(handles.ImSize(1),handles.ImSize(2));
                handles.VidInfo.FrameInfo{chosenFrameIdx,6} = sparse(handles.SegImg);
                handles.L = zeros(handles.ImSize(1),handles.ImSize(2));
                handles.B = handles.SegImg;
                handles.N = 0;
            end
            handles.ChosenSegImg = handles.SegImg;
            handles.UdStack.push(2,sparse(handles.SegImg));
            
            struct1 = struct('Img',cell(4,1),'DiagImg',cell(4,1),'BranchImg',cell(4,1),'BranchStruct',cell(4,1),'NumImg',cell(4,1));
            handles.SelectedSegStruct = struct('Img',[],'DiagImg',[],'BranchImg',[],'BranchStruct',[],'NumImg',[],'MinorAxis',[],'Seg',[]);
            handles.SelectedSegStruct.Seg = struct1; % as the types of segmentation
            
            handles.SelectedSegStruct.MinorAxis = getMinorAxis(handles.Img);
            [diagImg,branchImg,branchStruct,numImg] = analyzeVessels(handles.SegImg,10,handles.SelectedSegStruct.MinorAxis);
            handles.SelectedSegStruct.DiagImg = diagImg;
            handles.SelectedSegStruct.BranchImg = branchImg;
            handles.SelectedSegStruct.BranchStruct = branchStruct;
            handles.SelectedSegStruct.NumImg = numImg;
            handles.SelectedSegStruct.Img = mat2gray(handles.SegImg);
            handles = showSegInfo(handles,0);
            handles = showSegInfo(handles,1);
            
            handles.ImageLoaded = true;
            handles = getCostMat(handles,2); % get the cost matrices
            handles.SelectedSegStruct.MinorAxis = getMinorAxis(handles.Img);
            [handles.HImg,handles.HImgPanel,handles.ApiImgPanel,handles.MagImg]...
                = initFrame(1,handles.ImgAxis,handles.figure1,handles.ImgPanel,handles.Img,@Figs_Callback);
        else
            handles.ImgMask = false(handles.FrameSize(1),handles.FrameSize(2));
        end
        
        % Keep original
        handles.ResultState.ImgMask = handles.ImgMask;
        handles.ResultState.Rect = handles.Rect;
        handles.ResultState.Annotation = handles.ChosenSegImg;
        if handles.ImageLoaded
            set(handles.StatusText,'String',sprintf(handles.StatusString,handles.OpFile,num2str(handles.VidInfo.FrameInfo{chosenFrameIdx,1}),'Not used','Completed',getYesNo(handles.ResultLoaded)));
        else
            set(handles.StatusText,'String',sprintf(handles.StatusString,handles.OpFile,num2str(handles.VidInfo.FrameInfo{chosenFrameIdx,1}),'Not used','No candidates found',getYesNo(handles.ResultLoaded)));
        end
        
        % Display it
        set(handles.ImageAddressTextBox,'String',fullfile(handles.OpPathName,handles.OpFile));
        [handles.HFrame]...
            = initFrame(2,handles.FrameAxis,handles.figure1,handles.ImgPanel,handles.Frame,@Frame_Callback);
        handles = updateGUI(handles);
    end

    function windowClosingCVF(src,~)
        % global tempResults
        delete(tbl1);
        handles.VidH = [];
    end

end

%***************** IMAGE PROCESSING FUNCTIONS *******************%
function outImgStruct = extractEyeRegionEx(handles)

waitbarHandle = [];
try
    outImgStruct = [];
    
    waitbarHandle = waitbar(0,'Extracting eye regions...');
    stdFun = @(x) (std(x));
    stdFun2 = @(x) (std(x)./mean(x));
    
    circularHoughThresh = 1.5;
    
    radii = 10:1:50;
    radiiMult = 1.2;
    
    
    h2 = strel('disk',19);
    % se = strel('disk',9);
    h21 = strel('disk',5);
    
    imgo = handles.Frame;
    imSize = size(imgo);
    if imSize(1)<=135
        h1 = fspecial('gaussian',[11 11],3);
        imScale = 1;
    elseif imSize(1)<=1080
        h1 = fspecial('gaussian',[21 21],3);
        imScale = 0.2;
    elseif imSize(1)<=1800
        h1 = fspecial('gaussian',[31 31],3);
        imScale = 0.125;
    else
        h1 = fspecial('gaussian',[41 41],3);
        imScale = 0.08;
    end
    
    % eyeStruct = struct('Pos',cell(numFrames,1));
    
    totEyes = 0;
    isRelaxed = get(handles.RelaxationCheckBox,'Value');
    
    if isempty(imgo)
        return;
    end
    img = imresize(imgo, imScale);
    imgMask = img(:,:,1)>20;
    if sum(imgMask(:))==0
        return;
    end
    imgMask = imerode(bwareafilt(imfill(imgMask,'holes'),1),h21);
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
            img22 = imfilter(img22,h1);
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
                
                % Sharpness
                imgs = double(imgo(:,:,1));
                ctr = round(eyeSize(1:2)/2);
                h = fspecial('average',round(ctr*0.2));
                a2 = abs(imgs-imfilter(imgs,h));
                a2 = a2(Ym:YM,Xm:XM).*maskX;
                a = fft2(a2);
                
                
                cfhCnt = cfhCnt + 1;
                totEyes = totEyes + 1;
                eyeStruct.Pos(cfhCnt).Img = imco;
                eyeStruct.Pos(cfhCnt).OrigImg = imgo;
                eyeStruct.Pos(cfhCnt).Rect = [Xm,Ym,XM-Xm+1,YM-Ym+1];
                eyeStruct.Pos(cfhCnt).R3 = R3;
                eyeStruct.Pos(cfhCnt).MeanOUT = meanOUT;
                eyeStruct.Pos(cfhCnt).MaskX = maskX;
                eyeStruct.Pos(cfhCnt).HOGv = v;
                %                 eyeStruct(cf).Pos(cfCnt).Cnt = totEyes;
                eyeStruct.Pos(cfhCnt).Sharpness = abs(a(1,1));
                MOArr(totEyes) = meanOUT;
                R3Arr(totEyes) = R3;
                HogArr(totEyes) = v;
            end
        end
    end
    delete(waitbarHandle);
    waitbarHandle = [];
    
    if totEyes>0
        cnt = 0;
        for cfp = 1:cfhCnt
            chR3 = (eyeStruct.Pos(cfp).MeanOUT<130) &&...
                (eyeStruct.Pos(cfp).R3>=30);
            % check 3 - hog peak
            chHog = eyeStruct.Pos(cfp).HOGv>0.9;
            if (~(chR3 && chHog))
                continue;
            end
            cnt = cnt + 1;
            SpArr(cnt) = eyeStruct.Pos(cfp).Sharpness;
            eyeStruct.Pos(cfp).Chosen = true;
        end
        
        if cnt>0
            [~,idx] = sort(SpArr,'descend');
            for cfp = 1:cnt
                cfp2 = idx(cfp);
                if eyeStruct.Pos(cfp2).Chosen % get the first one chosen
                    outImgStruct.Img = uint8(double(eyeStruct.Pos(cfp2).Img).*repmat(eyeStruct.Pos(cfp2).MaskX,[1,1,3]));
                    outImgStruct.Rect = eyeStruct.Pos(cfp2).Rect;
                    mask = false(imSize(1),imSize(2));
                    mask(outImgStruct.Rect(2):outImgStruct.Rect(2)+outImgStruct.Rect(4)-1,...
                        outImgStruct.Rect(1):outImgStruct.Rect(1)+outImgStruct.Rect(3)-1) = eyeStruct.Pos(cfp2).MaskX;
                    outImgStruct.Mask = mask;
                    break;
                end
            end
        end
        clear eyeStruct SpArr R3Arr HogArr MOArr;
    end
catch ME
    if ~isempty(waitbarHandle)
        delete(waitbarHandle);
    end
    errordlg(ME.message);
    makeLog(ME);
end

end


function maska = getSpecularityMask(image_input1)

try
    h1 = fspecial('gaussian',[15 15],3);
    h2 = strel('disk',5);
    % imSize = size(image_input1);
    
    % img1=double(image_input1);
    img1lab = rgb2lab(mat2gray(image_input1));
    tmpImg = imfilter(img1lab(:,:,2),h1);
    % maskXA = tmpImg>0.3*max(tmpImg(:));
    
    maska = imdilate(img1lab(:,:,1)>90,h2);
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

function img1 = removeSpecularity(image_input1)

try
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
    
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

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

if ((max(max(R)) > 1.0) || (max(max(G)) > 1.0) || (max(max(B)) > 1.0))
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

if ((nargout == 1) || (nargout == 0))
    L = cat(3,L,a,b);
end
end

function handles = getCostMat(handles,type)

try
    if type == 1
        [handles.FrameCostMat,handles.FrameNeiList] = computeCostMat(handles.Frame,[],...
            handles.SEMIAUTOSEG.EDGE_WEIGHT,...
            handles.SEMIAUTOSEG.ORIENT_WEIGHT,...
            handles.SEMIAUTOSEG.LOG_WEIGHT);
    else
        if handles.FrameLoaded
            mask = handles.ImgMask(handles.Rect(2):handles.Rect(2)+handles.Rect(4)-1,...
                handles.Rect(1):handles.Rect(1)+handles.Rect(3)-1);
        else
            mask = [];
        end
        [handles.ImgCostMat,handles.ImgNeiList] = computeCostMat(handles.Img,...
            mask,handles.SEMIAUTOSEG.EDGE_WEIGHT,...
            handles.SEMIAUTOSEG.ORIENT_WEIGHT,...
            handles.SEMIAUTOSEG.LOG_WEIGHT);
    end
catch ME
    errordlg(ME.message);
    makeLog(ME);
end

end

function [costMat,neiList] = computeCostMat(img,mask,edgeW,orientationW,LOGW)

hb = waitbar(0,'Please wait while cost function is computed','WindowStyle','modal');
try    
    if nargin<3
        useEdge = true;
        edgeW = 1.0;
    else
        useEdge = edgeW>0;
    end
    if nargin<4
        useOrientation = false;
        orientationW = 0.0;
    else
        useOrientation = orientationW>0;
    end
    if nargin<5
        useLOG = false;
        LOGW = 0.0;
    else
        useLOG = LOGW>0;
    end
    
    imSize = size(img);
    
    img = rgb2gray(img);
    [dx,dy] = gradient(double(img));
    % tophatImg = imtophat(double(img),strel('disk',31));
    if useLOG
        logImg = imfilter(double(img),fspecial('log'));
    end
    if (nargin==2) && (~isempty(mask))
        mask = imerode(mask,strel('disk',3));
        dx = dx.*mask;
        dy = dy.*mask;
        %     tophatImg = tophatImg.*mask;
        if useLOG
           logImg = logImg.*mask;
        end
    end
    
    imSize = imSize(1:2);
    
    if useOrientation || useLOG
        fX = dx(:);
        fY = dy(:);
    end
    G = sqrt(dx.^2+dy.^2);
    maxG = max(G(:));
    fG0 = 1-(G/maxG);
    % maxT = max(tophatImg(:));
    % fT0 = 1-(tophatImg/maxT);
    
    
    dataSize = imSize(1)*imSize(2);
    
    neiList = zeros(dataSize,8);
    if useEdge
        fG = neiList;
    end
    if useOrientation
       fD = neiList;
    end
    if useLOG
       fZ = neiList;
    end
    pqX = [-1,-1,-1,0,0,1,1,1];
    pqY = [-1,0,1,-1,1,-1,0,1];
    % fT = fG;
    idxMat = reshape(1:dataSize,imSize);
    sqrtOfTwo = 1/sqrt(2);
    scalefG = [1,sqrtOfTwo,1,sqrtOfTwo,sqrtOfTwo,1,sqrtOfTwo,1];
    cnt = 0;
    for cf = 1:9
        if cf ~= 5
            cnt = cnt + 1;
            waitbar(cf/9,hb,sprintf('Computing pixel neighborhood %d',cnt));
            tmpMat = zeros(3,3);
            tmpMat(cf) = 1;
            hMat = imfilter(idxMat,tmpMat);
            neiList(:,cnt) = hMat(:);
            nonZeroIdx = neiList(:,cnt)>0;
            if useEdge
                fG(nonZeroIdx,cnt) = scalefG(cnt)*fG0(neiList(nonZeroIdx,cnt));
            end
            %         fT(nonZeroIdx,cnt) = scalefG(cnt)*fT0(neiList(nonZeroIdx,cnt));
            if useOrientation
                fX1 = fX(neiList(nonZeroIdx,cnt));
                fY1 = fY(neiList(nonZeroIdx,cnt));
                dp = pqX(cnt)*fX(nonZeroIdx) + pqY(cnt)*fY(nonZeroIdx);
                dq = pqX(cnt)*fX1 + pqX(cnt)*fY1;
                idx = dp<0;
                dp(idx) = -dp(idx);
                dq(idx) = -pqX(cnt)*fX1(idx)-pqY(cnt)*fY1(idx);
                fD(nonZeroIdx,cnt) = ((acos(dp))+(acos(dq)))/pi;
            end
            if useLOG
                fZ2 = logImg(neiList(nonZeroIdx,cnt))==0;
                logImgO = logImg(nonZeroIdx);
                logImgN = logImg(neiList(nonZeroIdx,cnt));
                idx = ((logImgO<0) & (logImgN>0))...
                    | ((logImgO>0) & (logImgN<0));
                fZ3 = fZ2(idx);
                fZ3(abs(logImgO(idx))>abs(logImgN(idx))) = 1;
                fZ2(idx) = fZ3;
                fZ(nonZeroIdx,cnt) = fZ2;
            end
        end
    end
    
    costMat = 0;
    if useEdge
        costMat = costMat + edgeW*fG;
    end
    if useOrientation
        costMat = costMat + orientationW*fD;
    end
    if useLOG
        costMat = costMat + LOGW*fZ;
    end

    close(hb);
catch ME
    close(hb);
    errordlg(ME.message);
    makeLog(ME);
end


end

