function [ out ] = parseJson( jsonstring )
%PARSEJSON Parse the given JSON string into a BSON document
%   This function wraps the java method from the Mongo driver. Note that
%   this method return legacy BasicDBObject and BasicDBList objects, for
%   compatibility. We convert them to the new format.
%   Ref: http://stackoverflow.com/questions/37526474/mongodb-java-driver-3-2-parsing-json-string-to-arraylistdocument
%
%   The JSON string will be parsed to BSON, with the following syntax used
%   to specify various binary types:
%   {
%      "string": "someString",
%      "integer": 123,
%      "float": 12.3,
%      "date": {"$date": 1352540684243} % milliseconds since unix epoch
%   }
%   
%   An array of documents is specified with square brackets:
%   [
%     { name: "bob", age: 42, status: "A" },
%     { name: "ahn", age: 22, status: "A" },
%     { name: "xi", age: 34, status: "D" }
%   ]

try % Parse
    parsed = com.mongodb.util.JSON.parse(jsonstring);
catch err
    error('Could not parse given string as JSON! %s',char(err.ExceptionObject.getMessage));
end

% Convert to the new "org.bson.Document" format
if isa(parsed,'com.mongodb.BasicDBObject')
    out = handle(org.bson.Document(parsed));
elseif isa(parsed,'com.mongodb.BasicDBList')
    out = handle(java.util.ArrayList(size(parsed)));
    for n = 1:size(parsed)
        out.add(org.bson.Document(parsed.get(n-1)));
    end
else % If the JSON string was properly parsed this should not happen.
    error('Not too sure what happened but the parsed JSON was not a document nor a document list...');
end

end
