import ballerina/log;
import ballerina/os;
import ballerina/io;
import ballerina/time;
import ballerina/file;
import ballerina/http;

configurable string DIR = "../tmp/";
const string resourceDIR = "./resource/";
const int minfilesize = 1024 * 10; //10KB
const int maxfilesize = 1024 * 1024 * 100; //100MB
map<string>[] writeDurations = [];
map<string>[] readDurations = [];
map<string>[] finalDurations = [];
float writeDuration = 0;
float readDuration = 0;
int filesizeinKB = 0;
string csvString = "";
string filePath = "";
string resourcePath = "";
boolean status = false; 

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    # A resource for get / path
    # + return - string response message or error
    resource function get .() returns string|error {
        string string1 = "Connection successful to the host:" + os:getUsername();
        string string2 = "\nUse the /file endpoint to Benchmark the File oprations.";
        string string3 = "\nUse the /response endpoint to get the csv string of the response of Benchmarking the File oprations\n\n";
        return string1 + string2 + string3;
    }

    # A resource for get /file path
    # + return - string response message or error
    resource function get file () returns http:Response|error {
        finalDurations = [];
        check  fileProcessMultiple();
        http:Response response = new;
        response.setPayload(finalDurations);
        return response;
    }

    # A resource for get /response path
    # + return - string response message or error
    resource function get response () returns string|error {
        http:Response response = new;
        check response.setContentType("text/csv");
        response.setPayload(finalDurations);
        return "accessing the /response endpoint";
    }

    public function init() {
        log:printInfo("Service started and listening on port 9090");
    }
}

# function for reading and writing to multiple files
# + return - error if any
public function fileProcessMultiple() returns error?{
    status = false;
    writeDurations = [];
    readDurations = [];
    var fileSize = minfilesize;
    byte[] buffer = [];
    byte onebyte = 1;
    foreach int i in 1 ... minfilesize-1 {
        buffer[i] = onebyte;
    }
    check fileProcess(fileSize, buffer);
    fileSize = fileSize + 1024*1024*2;

    while fileSize<=maxfilesize {
        // byte[] buffer = [];
        // byte onebyte = 1;
        // for loop to write the buffer to the file
        var end = fileSize + 1024*1024*2;
        foreach int i in fileSize ... end-1 {
            buffer[i] = onebyte;
        }
        check fileProcess(fileSize, buffer);
        fileSize = fileSize + 1024*1024*2;
    }

    io:println(finalDurations.toJson());
    var csvPath = DIR + "csvContent-ballerina.csv";
    check io:fileWriteCsv(csvPath, finalDurations);
    status = true;
}

# function for reading and writing to a file
# + filesize - the int value to denote the file size in bytes
# + bytes - bytes equivalent to the file size
# + return - error if any
public function fileProcess(int filesize, byte[] bytes) returns error?{
    filePath = DIR + "file-" + filesize.toString();

    // resourcePath = resourceDIR + "file-"+ filesize.toString();
    check writeProcess(filePath, filesize, bytes);
    check readProcess(filePath, filesize);

    filesizeinKB = filesize/1024;
    map<string> fDuration = {
        size: filesizeinKB.toString(),
        WriteDuration: writeDuration.toString(),
        ReadDuration: readDuration.toString(),
        ReadWriteDuration: (writeDuration + readDuration).toString()
    };
    finalDurations.push(fDuration);
}

# function to get the write duration of a file in ms
# + filePath - file path
# + filesize - int value of file size in bytes
# + bytes - file size in bytes
# + return - error if any
public function writeProcess(string filePath,int filesize, byte[] bytes) returns error? {
    writeDurations = [];
    float sum = 0;

    foreach int i in 0...9 {
        time:Utc writeStart = time:utcNow(9);
        check io:fileWriteBytes(filePath,bytes);
        time:Utc writeEnd = time:utcNow(9);
        time:Seconds writeDurationS = time:utcDiffSeconds(writeEnd,writeStart);
        string durationStr = writeDurationS.toString();
        float writeDuration = check float:fromString(durationStr)*1000;
        sum = sum + writeDuration;
        map<string> wDuration = {
            size: filesize.toString(),
            write: (writeDuration).toString()
        };
        writeDurations.push(wDuration);
    }

    writeDuration = sum/10;

    io:println(writeDurations.toJson());
    io:println(`FileSize (KB): ${filesize}, AvgDuration (ms): ${writeDuration}`);
}

# function to get average read duration for a file in ms
# + filePath - file path of the specific file 
# + filesize - file size in bytes
# + return - error if any
public function readProcess(string filePath, int filesize) returns error? {
    writeDurations = [];
    float sum = 0;

    foreach int i in 0...9 {
        time:Utc readStart = time:utcNow(9);
        byte[] _ = check io:fileReadBytes(filePath);
        time:Utc readEnd = time:utcNow(9);
        time:Seconds readDurationS = time:utcDiffSeconds(readEnd,readStart);
        string durationStr = readDurationS.toString();
        float readDuration = check float:fromString(durationStr)*1000;
        sum = sum + readDuration;
        map<string> rDuration = {
            size: filesize.toString(),
            read: (readDuration).toString()
        };
        readDurations.push(rDuration);
    }

    check file:remove(filePath);
    readDuration = sum/10;

    io:println(readDurations.toJson());
    io:println(`FileSize (KB): ${filesize}, AvgDuration (ms): ${readDuration}`);
}

# function to call readWriteProcess multiple times
# + return - error if any
public function multipleFileProcess() returns error?{

}