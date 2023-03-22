import ballerina/log;
import ballerina/os;
import ballerina/http;

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

    resource function get file () returns string|error {
        return "accessing the /file endpoint";
    }

    resource function get response () returns string|error {
        return "accessing the /response endpoint";
    }

    public function init() {
        log:printInfo("Service started and listening on port 9090");
    }
}
