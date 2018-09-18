classdef MatMongo
    %MATMONGO Functions to help install MatMongo
    
    methods (Static)
        function ver = version()
            ver = fileread(fullfile(MatMongo.packageDir,'VERSION'));
        end
        
        function ver = javaDriverVersion()
            % This is the driver version that is needed. Do not change this
            % as other driver versions were not tested.
            ver = '3.4.0';
        end
        
        function install(location)
            % Download and install the uber mongo java driver JAR file to 
            % the java static class path
            if nargin==0; location=fullfile(MatMongo.packageDir,'jar'); end
            % Make sure the m files are on the path
            path(fullfile(MatMongo.packageDir,'src'),path); savepath();
            % Check if the JAR is already installed
            [installed,classpath] = MatMongo.isInstalled();
            if installed; return; end
            % Ok we actually need to install the driver, first download the
            % uber JAR file from Mongo
            ver = MatMongo.javaDriverVersion;
            filename = ['mongo-java-driver-' ver '.jar'];
            url = ['https://oss.sonatype.org/content/repositories/releases/org/mongodb/mongo-java-driver/' ver '/' filename];
            outpath = websave(fullfile(location,filename),url);
            % Add JAR to class path
            classpath{end+1} = outpath;
            % Write classpath back to file
            MatMongo.writeJavaClassPath(classpath)
            % Warn that the user needs to restart MATLAB
            warning('The java driver was properly installed! You need to restart MATLAB.');
        end
        
        function uninstall()
            % Todo
        end
        
        function reinstall()
            MatMongo.uninstall();
            MatMongo.install();
        end
        
        function [installed,classpath] = isInstalled()
            % Verify that the driver is installed and working
            [loc,classpath] = MatMongo.javaDriverLocation();
            if ~isempty(loc)&&any(strcmp(loc,javaclasspath('-static')))&&logical(exist('org.bson.Document','class'))
                fprintf('The java driver is already installed and working!\n');
                installed = true;
            elseif ~isempty(loc)&&any(strcmp(loc,javaclasspath('-static')))&&~logical(exist('org.bson.Document','class'))
                warning('An invalid driver appears to be installed, run MatMongo.reinstall() to fix this.');
                installed = false;
            elseif ~isempty(loc)
                warning('The java driver is installed but you need to restart MATLAB.');
                installed = false;
            else
                installed = false;
            end
        end
        
        function [loc,classpath] = javaDriverLocation()
            % Check if the right JAR file is installed and on the static
            % java class path text file.
            jarfile = 'mongo-java-driver-';
            rightjarfile = [jarfile MatMongo.javaDriverVersion '.jar'];
            % Read the javaclasspath.txt file
            classpath = MatMongo.readJavaClassPath();
            % Check for any mongo java JAR
            somejarpresent = cellfun(@(s)contains(s,jarfile),classpath);
            % Check for existing AND right version java JAR
            rightjarpresent = cellfun(@(s)contains(s,rightjarfile),classpath);
            rightjarpresent = logical(cellfun(@(s)exist(s,'file'),classpath))&rightjarpresent;
            % Ok let's check if we found the right jar
            if sum(rightjarpresent)==0 % Nope
                loc = [];
            elseif sum(rightjarpresent)==1 % Yep
                loc = classpath{rightjarpresent};
            else % Many right exis jars! Let's keep the first one only
                rightjarindex = find(rightjarpresent,1);
                rightjarpresent = zeros(size(rightjarpresent));
                rightjarpresent(rightjarindex) = 1;
                rightjarpresent = logical(rightjarpresent);
                loc = classpath{rightjarpresent};
            end
            % Let's see if there are any bad jars, and ask to remove them
            badjars = somejarpresent-rightjarpresent;
            if sum(badjars)>0
                answer = input('Invalid mongo-java-driver JAR file(s) found on the static class path,\ndo you want to remove it(them)? Enter Y if you are not sure.\nY/N: ','s');
                if any(strcmp(answer,{'yes','y','Y'}))
                    classpath = classpath(~badjars);
                    MatMongo.writeJavaClassPath(classpath);
                end
            end
        end
        
        function dir = packageDir()
            % Return the path to the package root directory
            dir = fileparts(fileparts(mfilename('fullpath')));
        end
        
        function classpath = readJavaClassPath()
            % Read the javaclasspath.txt file in the prefdir and return a
            % cell array of strings with each entry corresponding to a line
            % in the file.
            filepath = fullfile(prefdir(),'javaclasspath.txt');
            fileID = fopen(filepath,'rt');
            classpath = textscan(fileID,'%s','Delimiter','\n');
            fclose(fileID);
            classpath = classpath{1};
        end
        
        function writeJavaClassPath(classpath)
            % Write the javaclasspath.txt to the prefdir
            filepath = fullfile(prefdir(),'javaclasspath.txt');
            fileID = fopen(filepath,'wt');
            nlines = size(classpath,1);
            for row = 1:nlines
                fprintf(fileID,'%s\n',classpath{row});
            end
            fclose(fileID);
        end
    end
    
end
