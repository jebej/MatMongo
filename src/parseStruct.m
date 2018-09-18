function [ out ] = parseStruct( instruct )
%PARSESTRUCT
if ~isstruct(instruct); error('Input must be a structure or structure array!'); end

% Import java classes
import java.util.Arrays
import java.util.Date
import org.bson.Document

% Find key names
keys = fieldnames(instruct);

% Prepare output Document
out = Document();

for k = 1:length(keys)
    key = keys{k};
    val = instruct.(key);
    if (islogical(val)||isnumeric(val))&&isscalar(val)||ischar(val)
        % Number/logical or string
        out.append(key,val);
    elseif isdatetime(val)&&isscalar(val)
        % Single datetime
        out.append(key,Date(posixtime(val)*1000));
    elseif iscellstr(val)
        % List of strings
        out.append(key,Arrays.asList(val));
    elseif (islogical(val)||isnumeric(val))&&isvector(val)
        % List of numbers/logicals
        out.append(key,Arrays.asList(num2cell(val)));
    end
end
end
