import ballerina/log;
import ballerina/os;
import ballerina/io;
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
        // Send a response back to the caller.
        string string1 = "Connection successful to the host:" + os:getUsername();
        string string2 = "\nUse the /file endpoint to Benchmark the File oprations.";
        string string3 = "\nUse the /response endpoint to get the csv string of the response of Benchmarking the File oprations\n\n";
        return string1 + string2 + string3;
    }

    # A resource for get /file path
    # + return - string response message or error
    resource function get file () returns http:Response|error {
        finalDurations = [];
        check  readWriteProcess(minfilesize);
        http:Response response = new;
        response.setPayload(finalDurations);
        return response;
    }

    # A resource for get /response path
    # + return - string response message or error
    resource function get response () returns string|error {
        return "accessing the /response endpoint";
    }

    public function init() {
        log:printInfo("Service started and listening on port 9090");
    }
}

# function for reading and writing to a file
# + filesize - the int value to denote the file size in bytes
# + return - error if any
public function readWriteProcess(int filesize) returns error?{
    filePath = DIR + "file-" + filesize.toString();
    resourcePath = resourceDIR + "file-"+ filesize.toString();
    byte[] bytes = check io:fileReadBytes(resourcePath);
    check io:fileWriteBytes(filePath,bytes);
    io:println(filePath);
    io:println("The file created successfully.");
}

# function to call readWriteProcess multiplr times
# + return - error if any
public function multipleFileProcess() returns error?{

}