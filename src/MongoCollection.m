classdef MongoCollection < handle
    %MONGOCOLLECTION Wrapper around the MongoDB java driver collection class
    %   This wrapper implements a few convenience functions to make the use
    %   of Mongo collections in MATLAB simpler.
    
    properties (SetAccess = private)
        Name
        ParentDatabase
    end
    
    properties (SetAccess = private, Dependent = true)
        DocumentCount
    end
    
    properties (SetAccess = private, Hidden)
        CollectionObj
    end
    
    methods
        function obj = MongoCollection(db,colname)
            % Get collection of the specified name, or create one if it
            % does not already exist
            obj.CollectionObj = handle(db.DatabaseObj.getCollection(colname));
            obj.Name = colname;
            obj.ParentDatabase = db.Name;
        end
        
        function dropCollection(obj)
            % Drop this collection, will delete the MongoCollection object
            obj.CollectionObj.drop();
            delete(obj.CollectionObj); obj.CollectionObj=[];
            delete(obj);
        end
        
        function count = get.DocumentCount(obj)
            % Count the number of documents in the collection
            count = obj.CollectionObj.count();
        end
        
        function insertOne(obj,doc)
            % Insert one document in the collection. Input can be a java
            % org.bson.Document object, or a JSON formatted string. If the
            % document is missing an identifier, one is generated and the
            % input doc is modified (unless a string was passed).
            if isa(doc,'char')
                % Parse JSON into a document
                doc = parseJson(doc);
            elseif isa(doc,'org.bson.Document')
                % All good, we already have a document
            else
                error('Invalid function input, only BSON objects or JSON strings are supported.');
            end
            obj.CollectionObj.insertOne(doc);
        end
        
        function insertMany(obj,docs)
            % Insert many document in the collection. Input can be a java
            % ArrayList containing org.bson.Document objects, or a JSON
            % formatted string.  If the documents are missing an
            % identifier, they are generated and the input docs are
            % modified (unless a string was passed).
            if isa(docs,'char')
                % Parse JSON into a document
                docs = parseJson(docs);
            elseif isa(docs,'java.util.ArrayList')&&isa(docs.get(0),'org.bson.Document')
                % All good, we already have a document
            else
                error('Invalid function input, only ArrayList of BSON objects or JSON strings are supported.');
            end
            obj.CollectionObj.insertMany(docs);
        end
        
        function result = find(obj,filter)
            % Find documents in the collection matching the filter. If no
            % argument is passed, finds all the documents in the
            % collection. Input must be a com.mongodb.client.model.Filters
            % object. The function returns a FindIterable interface. It
            % might be useful to dump this resulting interface into an
            % ArrayList for further processing. This is done as such:
            % list = handle(result.into(java.util.ArrayList))
            if nargin==1;filter=org.bson.Document(); end
            result = handle(obj.CollectionObj.find(filter));
        end
        
        function doc = findOneAndUpdate(obj,filter,update,options)
            % Atomically find a document and update it. Inputs must be a
            % com.mongodb.client.model.Filters object, and a
            % com.mongodb.client.model.Updates object. The function returns
            % the document that was updated before the update was applied.
            % If no documents matched the query filter, then null will be
            % returned.
            if nargin==3;options=com.mongodb.client.model.FindOneAndUpdateOptions(); end
            doc = handle(obj.CollectionObj.findOneAndUpdate(filter,update,options));
        end
        
        function doc = findOneAndReplace(obj,filter,replacement,options)
            % Atomically find a document and replace it. Inputs must be a
            % com.mongodb.client.model.Filters object, and a
            % org.bson.Document object. The function returns
            % the document that was replaced. Depending on the value of the
            % returnOriginal property, this will either be the document as
            % it was before the update or as it is after the update. If no
            % documents matched the query filter, then null will be returned
            if nargin==3;options=com.mongodb.client.model.FindOneAndReplaceOptions(); end
            doc = handle(obj.CollectionObj.findOneAndReplace(filter,replacement,options));
        end
        
    end
    
end

