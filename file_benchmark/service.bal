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
        string string3 = "\nUse the /response endpoint to get the csv string of the response of Benchmarking the File oprations";
        string string4 = "\nUse the /jsonoutput endpoint to get a sample json endpoint\n\n";
        return string1 + string2 + string3 + string4;
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
    # + return - http response message or error
    resource function get response () returns http:Response|error {
        http:Response response = new;
        // if status {
        //     check response.setContentType("text/csv");
        //     response.statusCode = 200;
        //     response.setPayload(finalDurations);
        // }else{
        //     check response.setContentType("text/plain");
        //     response.statusCode = 404;
        //     response.setPayload("Respond not found or Process not completed. \nMake a request to /file endpoint first. \nWait for some time and try again if you have already requested /file endpoint.\n");
        // }
        check response.setContentType("text/csv");
        //response.statusCode = 200;
        response.setPayload(finalDurations);
        return response;
    }

    # A resource for get /jsonoutput path
    # + return - static json response or error
    resource function get jsonoutput () returns json|error {
        return sampleJson;
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

    string header = "FileSize (KB),Write Duration (ms),Read Duration (ms),Read and Write Duration (ms)\n";
    string[] rows = [];
    rows.push(header);

    foreach var item in finalDurations {
        string size = item.get("size");
        string write = item.get("WriteDuration");
        string read = item.get("ReadDuration");
        string readwrite = item.get("ReadWriteDuration");
        string row = size + "," + write + "," + read + "," + readwrite + "\n";
        rows.push(row);
    }

    foreach var item in rows {
        csvString = csvString.'join(item,"\n");
    }

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

map<string>[] sampleJson  = [
    {
      "_id": "641bdaaa0a5b4af1047d0dde",
      "index": "1",
      "guid": "e097b36c-3a93-443e-9a3b-17da59dafcab",
      "isActive": "false",
      "balance": "$2,865.23",
      "picture": "http://placehold.it/32x32",
      "age": "29",
      "eyeColor": "brown",
      "name": "Marina Herrera",
      "gender": "female",
      "company": "BLEEKO",
      "email": "marinaherrera@bleeko.com",
      "phone": "+1 (913) 512-2676",
      "address": "880 Amherst Street, Kenmar, California, 5070",
      "about": "Proident sunt magna elit duis officia in esse labore tempor ipsum id ipsum. Sunt nisi nostrud anim veniam est nisi cupidatat ut minim esse laborum elit. Do cupidatat officia reprehenderit incididunt sit eiusmod excepteur dolor commodo esse nulla. Sit aute nisi veniam cillum aliqua.\r\n",
      "registered": "2015-11-12T01:02:54 -06:-30",
      "latitude": "65.668736",
      "longitude": "53.450258",
      "tags": [
        "cillum",
        "do",
        "cupidatat",
        "minim",
        "do",
        "sint",
        "ullamco"
      ].toJsonString(),
      "friends": [
        {
          "id": 0,
          "name": "Newman Hamilton"
        },
        {
          "id": 1,
          "name": "Christi Bond"
        },
        {
          "id": 2,
          "name": "Nunez Saunders"
        }
      ].toJsonString(),
      "greeting": "Hello, Marina Herrera! You have 2 unread messages.",
      "favoriteFruit": "banana"
    },
    {
      "_id": "641bdaaa58a952cc84c2a416",
      "index": "2",
      "guid": "c414d682-7979-4ea5-bded-042d8d398ee7",
      "isActive": "false",
      "balance": "$3,371.83",
      "picture": "http://placehold.it/32x32",
      "age": "31",
      "eyeColor": "green",
      "name": "Hallie Cardenas",
      "gender": "female",
      "company": "PLASMOX",
      "email": "halliecardenas@plasmox.com",
      "phone": "+1 (922) 524-3484",
      "address": "241 Menahan Street, Cecilia, South Dakota, 7736",
      "about": "Exercitation esse incididunt consequat duis sunt enim in ad elit nostrud tempor nulla aliquip. Proident sint nisi ea fugiat exercitation consequat proident dolor nostrud nostrud ad. Id aliqua sit culpa sit amet ex enim do mollit. Magna fugiat deserunt deserunt eu. Amet veniam ea consequat dolore laborum aliquip occaecat nisi.\r\n",
      "registered": "2018-09-14T04:45:57 -06:-30",
      "latitude": "-13.566072",
      "longitude": "6.398352",
      "tags": [
        "labore",
        "enim",
        "eu",
        "laborum",
        "ullamco",
        "magna",
        "magna"
      ].toJsonString(),
      "friends": [
        {
          "id": 0,
          "name": "Ochoa Shelton"
        },
        {
          "id": 1,
          "name": "Maryanne Farley"
        },
        {
          "id": 2,
          "name": "Greta Welch"
        }
      ].toJsonString(),
      "greeting": "Hello, Hallie Cardenas! You have 10 unread messages.",
      "favoriteFruit": "banana"
    }
];