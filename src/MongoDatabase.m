classdef MongoDatabase < handle
    %MONGODATABASE Wrapper around the MongoDB java driver database class
    %   Wrapper around both the MongoClient and the MongoDatabase java
    %   classes. This MATLAB class implements a few convenience functions
    %   to make the use of Mongo databases in MATLAB simpler.
    
    properties (SetAccess = private)
        Name
        Status = 'closed'
        Username = ''
        Roles = {''}
        Server = 'localhost'
        Port = 27017
    end
    
    properties (SetAccess = private, Dependent = true)
        CollectionNames
    end
    
    properties (SetAccess = private, Hidden)
        ClientObj
        DatabaseObj
    end
    
    properties (Access = private, Hidden)
        UseAuth = 0
        Password
        AuthDB
    end
    
    methods % Property methods
        function names = get.CollectionNames(obj)
            % Get collection names
            if strcmp(obj.Status,'closed');error('Database connection is closed!');end
            namesList = handle(obj.DatabaseObj.listCollectionNames.into(java.util.ArrayList()));
            names = cell(namesList.toArray()).';
        end
    end
    
    methods
        function obj = MongoDatabase(dbname,server,port,username,password,authdb)
            % Validate and store arguments
            if nargin==0;error('You need to specify the database you want to connect to!');end
            if nargin>=1;obj.Name=dbname;end
            if nargin>=2;obj.Server=server;end
            if nargin>=3;obj.Port=port;end
            if nargin==4;error('You also need to specify a password!');end
            if nargin>=5;obj.UseAuth=1;obj.Username=username;obj.Password=password;end
            if nargin==6;obj.AuthDB=authdb;else; obj.AuthDB=dbname;end
            % Silence log4j
            import org.apache.log4j.Logger; import org.apache.log4j.Level;
            Logger.getRootLogger().setLevel(Level.OFF);
            % Open the connection
            obj.open();
            % Check if the connection is ok
            obj.checkConnection();
            % Grab roles if authentication is being used
            if obj.UseAuth
                cmd = ['{"usersInfo":{"user":"' obj.Username '","db":"' obj.AuthDB...
                    '" },"showCredentials":false,"showPrivileges":false}'];
                roles = handle(obj.runCommand(cmd).get('users').get(0).get('roles'));
                obj.Roles = cell(1,size(roles));
                for n = 1:size(roles)
                    obj.Roles{n} = char(roles.get(n-1).get('role'));
                end
            end
            % If everything worked we are done.
        end
        
        function delete(obj)
            % Delete the database object
            if strcmp(obj.Status,'open')
                obj.close()
            end
        end
        
        function open(obj)
            % Open connection to the database
            if strcmp(obj.Status,'open');error('Connection is already open!');end
            % Import driver classes
            import com.mongodb.*
            % Create a Mongo ServerAddress object
            addr = handle(ServerAddress(obj.Server,obj.Port));
            % Create a MongoClientOption object
            opts = handle(MongoClientOptions.builder()...
                .applicationName('MatMongo')...
                .connectTimeout(1000)...
                .socketTimeout(30000)...
                .serverSelectionTimeout(1500)... %http://stackoverflow.com/questions/30455152/check-mongodb-authentication-with-java-3-0-driver
                .build());
            if obj.UseAuth
                % Create a MongoCredential object to store the credentials
                creds = handle(java.util.Collections.singletonList(...
                    MongoCredential.createCredential(obj.Username,obj.AuthDB,obj.Password)));
                % Create a MongoClient object
                obj.ClientObj = handle(MongoClient(addr,creds,opts));
            else % Create a MongoClient object without authentication
                obj.ClientObj = handle(MongoClient(addr,opts));
            end
            % Get Database using the MongoClient we created
            obj.DatabaseObj = handle(obj.ClientObj.getDatabase(obj.Name));
            obj.Status = 'open';
        end
        
        function close(obj)
            % Close connection to the database
            if strcmp(obj.Status,'closed');error('Connection is already closed!');end
            % Delete database object
            delete(obj.DatabaseObj); obj.DatabaseObj=[];
            % Close and delete client object
            obj.ClientObj.close();
            delete(obj.ClientObj); obj.ClientObj=[];
            obj.Status = 'closed';
        end
        
        function checkConnection(obj)
            % Send a ping and check for errors
            try
                obj.runCommand('{ping:1}');
            catch err
                errMsg = char(err.ExceptionObject.getMessage);
                if any(strfind(errMsg,'Authentication failed'))
                    % Looks like the authentication failed
                    error('Authentication failed!');
                elseif any(strfind(errMsg,'UnknownHostException'))
                    % Unknown host
                    error('Unknown host %d!',obj.Server);
                elseif any(strfind(errMsg,'Connection refused: connect'))
                    % Connection refused
                    error('Exception opening socket, connection refused!');
                else
                    % Can't tell why this failed, give the full message
                    error(errMsg);
                end
            end
        end
        
        function dropDatabase(obj)
            % Drop this database, will delete the MongoDatabase object
            if strcmp(obj.Status,'closed');error('Database connection is closed!');end
            obj.DatabaseObj.drop()
            delete(obj);
        end
        
        function result = runCommand(obj,command)
            % Run a JSON command on the database
            if strcmp(obj.Status,'closed');error('Database connection is closed!');end
            cmd = parseJson(command);
            % Execute command and return result as BSON java object. If an
            % error occurs, a java error will be thrown.
            result = handle(obj.DatabaseObj.runCommand(cmd));
        end
        
        function col = getCollection(obj,collectionName)
            % Get a collection from the database, creates one if it does
            % not exist already. Note that creation will only occur if an
            % action (eg document inserted) is taken.
            if strcmp(obj.Status,'closed');error('Database connection is closed!');end
            col = MongoCollection(obj,collectionName);
        end
        
        function grid = getGrid(obj,bucketName)
            % Get a gridFS bucket from the database, creates ones if it
            % does not exist already.
            if strcmp(obj.Status,'closed');error('Database connection is closed!');end
            grid = MongoGrid(obj,bucketName);
        end
    end
end
