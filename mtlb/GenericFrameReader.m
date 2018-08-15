classdef GenericFrameReader < handle
    properties (Hidden = true)
        IpPath
        IsVid
        FrameObj
        Extn
        NumFrames
        FrameName
        CurrentTime
        CurrFrameIdx
        ProcessedOnce
    end
    methods
        function obj = GenericFrameReader(ipPath,isVid,extn)
            narginchk(2,3);
            validateattributes(isVid, {'logical'},{},'','isVid');
            if ~isVid
                if nargin == 2
                    obj = []; % return empty
                else
                    validateattributes(extn, {'char','cell'},{},'','extn');
                end
            end
            obj.NumFrames = 0;
            obj.IpPath = ipPath;
            obj.IsVid = isVid;
            if isVid
                obj.FrameObj = VideoReader(ipPath);
                obj.NumFrames = round(obj.FrameObj.Duration*obj.FrameObj.FrameRate);
                obj.CurrentTime = zeros(obj.NumFrames,1);
            else
                obj.Extn = extn;
                if iscell(obj.Extn)
                    filedetails = [];
                    for cf = 1:numel(obj.Extn)
                        extn = ['*.',obj.Extn{cf}];
                        filedetails = [filedetails;dir([ipPath,filesep,extn])];
                    end
                else
                    extn = ['*.',extn];
                    filedetails = dir([ipPath,filesep,extn]);
                end                
                obj.FrameObj = {filedetails.name}';
                obj.NumFrames = numel(obj.FrameObj);
            end
            obj.ProcessedOnce = false;
            obj.CurrFrameIdx = 0;
            obj.FrameName = '';
        end
        function frame = getFrame(obj,cnt)
            frame = [];
            if nargin>1
                cnt = round(cnt);
                if cnt<1
                    return;
                end
            else
                cnt = [];
            end
            try
                if obj.IsVid
                    if obj.ProcessedOnce
                        if cnt <= obj.NumFrames
                            obj.CurrFrameIdx = cnt;
                            obj.FrameObj.CurrentTime = obj.CurrentTime(obj.CurrFrameIdx);
                            frame = readFrame(obj.FrameObj);
                        end
                    else
                        if hasFrame(obj.FrameObj)
                            obj.CurrFrameIdx = obj.CurrFrameIdx + 1;
                            obj.CurrentTime(obj.CurrFrameIdx) = obj.FrameObj.CurrentTime;
                            frame = readFrame(obj.FrameObj);
                            if obj.CurrFrameIdx==obj.NumFrames
                                obj.ProcessedOnce = true;
                                % update numFrames and length of CurrentTime
                                obj.NumFrames = obj.CurrFrameIdx;
                                obj.CurrentTime = obj.CurrentTime(1:obj.CurrFrameIdx);
                            end
                        else % no more frames - check for a premature end
                            if obj.CurrFrameIdx<obj.NumFrames
                                obj.ProcessedOnce = true;
                                % update numFrames and length of CurrentTime
                                obj.NumFrames = obj.CurrFrameIdx;
                                obj.CurrentTime = obj.CurrentTime(1:obj.CurrFrameIdx);
                                % send the new last frame to prevent
                                % errors - may be removed afterwards
                                obj.FrameObj.CurrentTime = obj.CurrentTime(obj.CurrFrameIdx);
                                frame = readFrame(obj.FrameObj);
                            end
                        end
                    end
                else
                    if cnt <= obj.NumFrames
                        obj.CurrFrameIdx = cnt;
                        obj.FrameName = obj.FrameObj{cnt};
                        frame = imread(fullfile(obj.IpPath,obj.FrameObj{cnt}));
                    end
                end
            catch ME
                errordlg(ME.message);
            end                
        end
        function delete(obj)
            if obj.IsVid
                delete(obj.FrameObj);
            else
                clear obj.FrameObj;
            end
        end
    end
end