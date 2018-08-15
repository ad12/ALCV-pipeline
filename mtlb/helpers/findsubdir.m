function [returnPath] = findsubdir(tempPath,extn,returnPath)
if nargin==2
    returnPath = struct('name',[],'folderName',[]);
    currDirHierarchy = dir(fullfile(tempPath,extn));
    if ~isempty(currDirHierarchy)
        if ~isempty(returnPath(1).name)
            returnPath(numel(returnPath)+1).name = tempPath;
        else
            returnPath(1).name = tempPath;
        end
    end
end
currDirHierarchy = dir(tempPath);
if ~isempty(currDirHierarchy)
    for i = 1 : numel(currDirHierarchy)
        if(currDirHierarchy(i).isdir==1) && ~strcmp(currDirHierarchy(i).name,'.') && ~strcmp(currDirHierarchy(i).name,'..')
            tempDirHierarchy = dir(fullfile(tempPath,currDirHierarchy(i).name,extn));
            if ~isempty(tempDirHierarchy)
                if ~isempty(returnPath(1).name)
                    tNum = numel(returnPath)+1;
                    returnPath(tNum).name = fullfile(tempPath,currDirHierarchy(i).name);
                    returnPath(tNum).folderName = currDirHierarchy(i).name;
                else
                    returnPath(1).name = fullfile(tempPath,currDirHierarchy(i).name);
                    returnPath(1).folderName = currDirHierarchy(i).name;
                end
            end
            tempDirHierarchy = dir(fullfile(tempPath,currDirHierarchy(i).name));
            if ~isempty(tempDirHierarchy)
                returnPath = findsubdir(fullfile(tempPath,currDirHierarchy(i).name),extn,returnPath);
            end
        end
    end
end
end