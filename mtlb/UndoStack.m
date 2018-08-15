classdef UndoStack < handle
    properties
        stackArr
        prevElem
        currElem
        endElem
        len
    end
    methods
        function obj = UndoStack(len)
            obj.len = len;
            myStack.idx = [];
            myStack.op = [];
            myStack.map = [];
            obj.stackArr = cell(obj.len,1);
            for cf = 1:obj.len
                obj.stackArr{cf,1} = myStack;
            end
            obj.currElem = 0;
            obj.prevElem = -1;
        end
        function clearStack(obj)
            myStack.idx = [];
            myStack.op = [];
            myStack.map = [];
            obj.stackArr = cell(obj.len,1);
            for cf = 1:obj.len
                obj.stackArr{cf,1} = myStack;
            end
            obj.currElem = 0;
            obj.prevElem = -1;
        end
        function push(obj,op,val)
            myStack.op = op;
            if size(val,2) == 1 % idx
                myStack.idx = val;
            else
                myStack.map = val;
            end
            obj.currElem = obj.currElem + 1;
            if obj.currElem > obj.len
                obj.currElem = obj.currElem - 1;
                obj.stackArr(1:end-1,1) = obj.stackArr(2:end,1);
            else
                obj.prevElem = obj.currElem - 1;
            end
            obj.stackArr{obj.currElem,1} = myStack;
            obj.endElem = obj.currElem;
        end
        function myStack = popRD(obj)
            if obj.currElem >= obj.endElem
                myStack = [];
            else
                obj.prevElem = obj.currElem;
                obj.currElem = obj.currElem + 1;
                myStack = obj.stackArr{obj.currElem,1};
            end
        end
        function myStack = popUD(obj)
            if obj.prevElem <= 0
                myStack = [];
            else
                myStack = obj.stackArr{obj.prevElem,1};
                obj.currElem = obj.prevElem;
                obj.prevElem = obj.prevElem - 1;
            end
        end
        function modified = modifyLength(obj,newLen)
            modified = false;
            if obj.len>newLen
                if obj.currElem>newLen
                    obj.currElem = newLen;
                    obj.endElem = newLen;
                    obj.prevElem = obj.currElem - 1;
                elseif obj.endElem>newLen
                    obj.endElem = newLen;
                end
                obj.stackArr = obj.stackArr(obj.endElem-newLen+1:obj.endElem,1);
                modified = true;
            elseif obj.len<newLen
                tmpStackArr = cell(newLen,1);
                tmpStackArr(1:obj.len,1) = obj.stackArr;
                obj.stackArr = tmpStackArr;
                modified = true;
            end
            obj.len = newLen;
        end
    end
end