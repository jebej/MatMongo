classdef MongoGrid < handle
    %MONGOCOLLECTION Wrapper around the MongoDB java driver GridFSBucket class
    %   This wrapper implements a few convenience functions to make the use
    %   of Mongo GridFSBucket in MATLAB simpler.
    
    properties (SetAccess = private)
        Name
        ParentDatabase
    end
    
    properties (SetAccess = private, Hidden)
        GridObj
    end
    
    methods
        function obj = MongoGrid(db,bucketName)
            % Get grid of the specified bucket name, or create one if it
            % does not already exist
            import com.mongodb.client.gridfs.GridFSBuckets
            obj.GridObj = handle(GridFSBuckets.create(db.DatabaseObj,bucketName));
            obj.Name = bucketName;
            obj.ParentDatabase = db.Name;
        end
        
        function delete(obj)
            %delete(obj.GridObj); % Does not work, should find workaround
            obj.GridObj=[];
        end
        
        function dropGrid(obj)
            % Drop this grid, will delete the MongoGrid object
            obj.GridObj.drop();
            delete(obj);
        end
        
        function result = find(obj,filter)
            % Find documents in the "files" collection matching the filter.
            % If no argument is passed, finds all the documents in the
            % collection. Input must be a com.mongodb.client.model.Filters
            % object. The function returns a GridFSFindIterable interface.
            % It might be useful to dump this resulting interface into an
            % ArrayList for further processing. This is done as such:
            % list = handle(result.into(java.util.ArrayList))
            if nargin==1; filter=org.bson.Document(); end
            result = handle(obj.GridObj.find(filter));
        end
        
        function [bytes,meta] = getGridFile(obj,filename)
            % Download file from the GridFSBucket with a ByteArrayOutputStream
            import com.mongodb.client.model.Filters.eq
            % Create OutputStream and download
            ostream = handle(java.io.ByteArrayOutputStream());
            try
                obj.GridObj.downloadToStream(filename,ostream);
            catch err
                ostream.close();
                error(char(err.ExceptionObject.getMessage));
            end
            ostream.close();
            bytes = ostream.toByteArray();
            % Download metadata and return as Document
            meta = obj.GridObj.find(eq('filename',filename)).first().getMetadata();
        end
        
        function putGridFile(obj,filename,bytes,meta)
            % Upload file to the GridFSBucket
            if ~isa(bytes,'int8');error('putGridFile requires a int8 array input!');end
            % Create default options
            options = com.mongodb.client.gridfs.model.GridFSUploadOptions();
            % Add the given metadata to options
            if nargin==4 && isa(meta,'char')
                options.metadata(parseJson(meta));
            elseif nargin==4 && isa(meta,'org.bson.Document')
                options.metadata(meta);
            end
            % Create the InputStream and upload it
            stream = handle(java.io.ByteArrayInputStream(bytes));
            try
                obj.GridObj.uploadFromStream(filename,stream,options);
            catch err
                error(char(err.ExceptionObject.getMessage));
            end
        end
    end
end
