function [ output_args ] = runtests( input_args )
%RUNTESTS Summary of this function goes here
%   Detailed explanation goes here

import org.bson.Document
import java.util.Arrays;
import java.util.ArrayList;
import com.mongodb.client.model.Filters;


db = MongoDatabase('testdb','localhost',27017,'siteUserAdmin','adminpass','admin');
col1 = db.getCollection('testcol1');
col2 = db.getCollection('testcol2');
grid = db.getGrid('test_bucket');

thisdate = datetime('now','Timezone','utc');
dateasint = int64(posixtime(thisdate)*1000);
jsondoc = [
    '{'...
    ' "name" : "MongoDB",'...
    ' "type" : "database",'...
    ' "count" : 1,'...
    ' "versions": [ "v3.2", "v3.0", "v2.6" ],'...
    ' "info" : { x : 203, y : 102 },'...
    ' "a_date" : {"$date": ' num2str(dateasint) '}'...
    '}'];

bsondoc = Document('name','Caf� Con Leche')...
            .append('contact',Document('phone','228-555-0149')...
               .append('email','cafeconleche@example.com')...
               .append('location',Arrays.asList({-73.92502,40.8279556})))...
            .append('stars',3)...
            .append('categories',Arrays.asList({'Bakery','Coffee','Pastries'}));

manyjsondoc = [
    '['...
    '{ name: "bob", age: 42, status: "A" },'...
    '{ name: "ahn", age: 22, status: "A" },'...
    '{ name: "xi", age: 34, status: "D" }'...
    ']'];

manybsondoc = ArrayList();
for n = 1:100
    manybsondoc.add(Document('number',n));
end

filter = Filters.exists('number');

bytes = int8([110 101 118 101 114 32 103 111 110 110 97 32 103 105 118 101 32 121 111 117 32 117 112].');

field1 = 'f1';  value1 = zeros(1,10);
field2 = 'f2';  value2 = [true true false];
field3 = 'f3';  value3 = [pi, pi.^2];
field4 = 'f4';  value4 = 'fourth';
s = struct(field1,value1,field2,value2,field3,value3,field4,value4);
s.name = 'John Doe';
s.billing = 127.00;
s.date = datetime('now','Timezone','utc');
s.words = {'abc', 'bcfes', 'boat', 'qwerty'};
s.healthy = false;

% Tests
try
    test_wrongPassword();
    test_wrongAddress();
    test_insertOne(col1,jsondoc);
    test_insertOne(col1,bsondoc);
    test_insertMany(col2,manyjsondoc);
    test_insertMany(col2,manybsondoc);
    test_count(col1,2);
    test_CollectionNames(db,{'testcol1' 'testcol2'});
    test_findDate(col1,dateasint);
    test_emptyfind(col1,2,bsondoc);
    test_find(col2,filter,100);
    test_dropCollection(col2);
    test_CollectionNames(db,{'testcol1'});
    test_putGridFile(grid,'testname.txt',bytes,bsondoc);
    test_getGridFile(grid,'testname.txt',bytes,bsondoc);
    %db.close();Mongo.getNewJobID(db);db.open();
catch err
    db.dropDatabase();
    rethrow(err);
end

% Remove test collections and databases
db.dropDatabase();
% Done!
fprintf('Tests completed succesfully!\n');
end


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Test functions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
function test_wrongPassword()
try
    MongoDatabase('testdb','localhost',27017,'siteUserAdmin','wrongpass','admin');
catch err
    if ~any(strfind(err.message,'Authentication failed'))
        error('This should have thrown an "Authentication failed" error!');
    end
end
end

function test_wrongAddress()
try
    MongoDatabase('testdb','badaddress',27017,'siteUserAdmin','wrongpass','admin');
catch err
    if ~any(strfind(err.message,'Unknown host'))
        error('This should have thrown an "Unknown host" error!');
    end
end
end

function test_insertOne(col,doc)
% Test inserting one document
col.insertOne(doc);
end

function test_insertMany(col,docs)
% Test inserting many document
col.insertMany(docs);
end

function test_CollectionNames(db,names)
% Test reading collection names
isequal(names,db.CollectionNames);
end

function test_count(col,N)
if ~(col.DocumentCount==N)
    error('Wrong number of documents!')
end
end

function test_findDate(col,dateasint)
filter = com.mongodb.client.model.Filters.exists('a_date');
res = handle(col.find(filter).into(java.util.ArrayList));
if ~(size(res)==1&&res.get(0).getDate('a_date').getTime==dateasint)
    error('Did not retrieve documents properly');
end
end

function test_emptyfind(col,N,comparedoc)
% Test finding all the documents in the collection
res = handle(col.find().into(java.util.ArrayList));
if ~(size(res)==N&&res.get(1).equals(comparedoc))
    error('Did not retrieve documents properly');
end
end

function test_find(col,filter,N)
% Try finding all the documents in the collection
res = handle(col.find(filter).into(java.util.ArrayList));
if ~(size(res)==N&&res.get(36).getDouble('number')==37)
    error('Did not retrieve documents properly');
end
end

function test_dropCollection(col)
col.dropCollection();
end

function test_putGridFile(grid,filename,bytes,metadata)
grid.putGridFile(filename,bytes,metadata);
end

function test_getGridFile(grid,filename,bytes,metadata)
[a,b] = grid.getGridFile(filename);
if ~isequal(a,bytes) || ~isequal(b,metadata)
    error('Invalid grid file');
end
end
