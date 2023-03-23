import ballerina/log;
import ballerina/os;
import ballerina/io;
import ballerina/file;
import ballerina/http;

configurable string DIR = "/../tmp";
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
boolean status = false; 

# A service representing a network-accessible API
# bound to port `9090`.
service / on new http:Listener(9090) {

    # A resource for generating greetings
    # + return - string name with hello message or error
    resource function get .() returns string|error {
        // Send a response back to the caller.
        string string1 = "Connection successful to the host:" + os:getUsername();
        string string2 = "\nUse the /file endpoint to Benchmark the File oprations.";
        string string3 = "\nUse the /response endpoint to get the csv string of the response of Benchmarking the File oprations\n\n";
        return string1 + string2 + string3;
    }

    resource function get file () returns http:Response|error {
        finalDurations = [];
        check  writeProcess();
        http:Response response = new;
        response.setPayload(finalDurations);
        return response;
    }

    resource function get response () returns string|error {
        return "accessing the /response endpoint";
    }

    public function init() {
        log:printInfo("Service started and listening on port 9090");
    }
}

public function writeProcess() returns error?{
    filePath = check file:joinPath("/",DIR,"file");
    io:println(filePath);
    // byte[] buffer = base64 `yPHaytRgJPg+QjjylUHakEwz1fWPx/wXCW41JSmqYW8=`;
    // io:println("writing file");
    // check io:fileWriteBytes(filePath,buffer);
    int fileSize = 1024 * 1024; // 1 MB
    // byte[] data = new byte(filesize);
    // check io:fileWriteBlocksFromStream(filePath,streamName)
    // byte[] data = generateRandomBytes(fileSize);
    // os:writeFile(filePath, data, io:createFileOptions { permissions: 0o777 });
}