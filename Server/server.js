var HTTP = require("http");
var MIME = require("./mime");
var FS = require("fs");

// set some additional mime types
MIME.types[".cib"] = "text/plain";
MIME.types[".sj"] = "text/plain";
MIME.types[".j"] = "text/plain";
MIME.types[".plist"] = "application/xml";

var puts = require("sys").puts;

// used for the oauth requests
// REMOVE BEFORE PUSHING
var CLIENT_SECRET = "";
var CLIENT_ID     = "c775a44a08cffa50eba3";
var CLIENT_REDIRECT_URL = "http://localhost:8001/getAccessToken/";

HTTP.createServer(function (request, response) {
    try {
        if (/^\/github\//.test(request.url)) {
            githubProxy(request, response);
        }
        else if (/\/getAccessToken\/\?code=(\w+)/.test(request.url)) {
            var code = request.url.replace(/\/getAccessToken\/\?code=(\w+)/, "$1");
            getAccessKey(request, response, code);
        
        }
        else if(/\/getAccessToken\/\?error=user_denied$/.test(request.url)) {
            response.writeHead(200, {"Content-Type": "text/plain"})
            response.write("<html><head><title>Authorization Failed</title><script>window.authFailed = true;</script></head><body></body></html>");
        }
        else {
            staticServe(request, response);
        }
    } catch (e) {
        response.writeHead(200, {"Content-Type": "text/plain"})
        response.end("error: "+e+"\n");
    }
}).listen(parseInt(process.env.PORT || 8001));

function getAccessKey(request, response, code) {
    var request_url = "https://github.com/login/oauth/access_token?client_id="+ CLIENT_ID + "&client_secret="+ CLIENT_SECRET +"&code=" + code;
    var askForAccessToken = HTTP.createClient(443, "github.com", true);
    var askForAccessToken_request = askForAccessToken.request("POST", request_url, {"host":"github.com","Content-Length":0, "location":request_url});

    askForAccessToken_request.addListener("response", function (askForAccessToken_response) {
        askForAccessToken_response.body = "";

        askForAccessToken_response.addListener("data", function(chunk) {
            askForAccessToken_response.body+=chunk;

        });
        askForAccessToken_response.addListener("end", function() {

            var newBody = "<html><head><title>Authenticated</title><script>window.opener.auth('"+askForAccessToken_response.body+"', this); function token(){ return '"+askForAccessToken_response.body+"'; }; document.cookie='github."+ askForAccessToken_response.body +"';</script></head><body></body></html>";

            response.writeHead(askForAccessToken_response.statusCode, askForAccessToken_response.headers["content-length"] = newBody.length);
            response.write(newBody);
            response.end();
        });
    });
    request.addListener("data", function(chunk) {
        askForAccessToken_request.write(chunk);
    });
    request.addListener("end", function() {
        askForAccessToken_request.end();
    });
}

// based on http://github.com/pkrumins/nodejs-proxy
// http://www.catonmat.net/http-proxy-in-nodejs
function githubProxy(request, response) {
    request.headers.host = "github.com";
    request.url = "/api/v2/json/" + request.url.match(/^\/github\/(.*)$/)[1];
    delete request.headers.cookie;

    var proxy = HTTP.createClient(80, request.headers.host);
    var proxy_request = proxy.request(request.method, request.url, request.headers);
    proxy_request.addListener("response", function (proxy_response) {
        proxy_response.addListener("data", function(chunk) {
            response.write(chunk);
        });
        proxy_response.addListener("end", function() {
            response.end();
        });
        response.writeHead(proxy_response.statusCode, proxy_response.headers);
    });
    request.addListener("data", function(chunk) {
        proxy_request.write(chunk);
    });
    request.addListener("end", function() {
        proxy_request.end();
    });
}

function staticServe(request, response) {
    var path = "static" + request.url + (/\/$/.test(request.url) ? "index.html" : "");
    FS.readFile(path, "binary", function (err, data) {
        if (err) {
            response.writeHead(404, {
                "Content-Type": "text/plain"
            });
            response.end("404: not found\n");
        } else {
            response.writeHead(200, {
                "Content-Type": MIME.lookup(path),
                "Cache-Control" : "public, max-age=" + (60*60*12) // 12 hours, like Rack::File
            });
            response.write(data, "binary");
            response.end();
        }
    });
}
