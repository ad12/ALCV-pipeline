function makeLog(ME,varargin)
% makeLog(ME,logOrder,hyperlink) takes an exception ME and maintains a log
% for the upper-most calling m-file. If the log file exists, it will be 
% appended.
% logOrder - an optional argument that reports the log to a file name other
% than the upper-most calling function. If logOrder has any integer value
% other than 0 (default), the log will be reported to a log file named 
% after the immediately calling m-file.
% hyperlink - another optional argument. If value is 'On', complete path to
% the Matlab function is shown. Default value is 'Off'.


p = inputParser;
expectedHyperLinks = {'On','Off'};

addRequired(p,'ME',@(x) isa(x,'MException'));
addOptional(p,'logOrder',0,@isnumeric);
addOptional(p,'hyperlink','Off',...
    @(x) any(validatestring(x,expectedHyperLinks)));

parse(p,ME,varargin{:});
ME = p.Results.ME;
logOrder = p.Results.logOrder;
hyperlink = p.Results.hyperlink;

t = dbstack;
stackLen = size(t,1);
if logOrder == 0
    k = stackLen;
    while isempty(t(k).file)
       k = k - 1; 
    end
    fileName = [t(k).file(1:end-2),'-log.txt'];
else
    fileName = [t(2).file(1:end-2),'-log.txt'];
end

fid = fopen(fileName,'a');

fprintf(fid,'***********************************\n');
str = getReport(ME,'extended','hyperlinks',hyperlink); 
t = datetime('now');
fprintf(fid,'Logging date-time: %s\n',datestr(t));
fprintf(fid,'Error identifier: %s\n',ME.identifier);
fprintf(fid,'%s\n',str);
fprintf(fid,'***********************************\n');
fclose(fid);

end