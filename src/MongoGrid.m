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
        
        function [bytes,metadata] = getGridFile(obj,filename)
            % Download file from the GridFSBucket with a ByteArrayOutputStream
            import com.mongodb.client.model.Filters
            % Create default options
            options = handle(com.mongodb.client.gridfs.model.GridFSDownloadByNameOptions());
            % Create OutputStream and download
            stream = handle(java.io.ByteArrayOutputStream());
            obj.GridObj.downloadToStreamByName(filename,stream,options);
            stream.close()
            bytes = stream.toByteArray();
            % Download metadata and return as Document
            metadata = obj.GridObj.find(Filters.eq('filename',filename)).first().getMetadata();
        end
        
        function fileID = putGridFile(obj,filename,bytes,metadata)
            % Upload file to the GridFSBucket
            if ~isa(bytes,'int8');error('putGridFile requires a int8 array input!');end
            % Create default options
            options = handle(com.mongodb.client.gridfs.model.GridFSUploadOptions);
            % Add the given metadata to options
            if nargin==4&&isa(metadata,'char')
                javaMethod('metadata',options,parseJson(metadata));
            elseif nargin==4&&isa(metadata,'org.bson.Document')
                javaMethod('metadata',options,metadata);
            end
            % Create the InputStream and upload it
            stream = handle(java.io.ByteArrayInputStream(bytes));
            javaFileID = handle(obj.GridObj.uploadFromStream(filename,stream,options));
            fileID = javaFileID.toHexString();
        end
    end
end
