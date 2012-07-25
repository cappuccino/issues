var HTTP = require("http");
var HTTPS = require("https");
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
var CLIENT_SECRET = process.env.CLIENT_SECRET;
var CLIENT_ID     = process.env.CLIENT_ID;
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
            var trimmed = askForAccessToken_response.body.slice(askForAccessToken_response.body.indexOf("=")+1);

            var newBody = "<html><head><style>body{background:rgb(237, 241, 244);}</style><title>Authenticated</title><script>function sendAuth(){ if(window.opener) {window.opener.auth('"+askForAccessToken_response.body+"', this);}else{} } sendAuth(); function token(){ return '"+askForAccessToken_response.body+"'; }; document.cookie='github."+ askForAccessToken_response.body +"';</script></head><body><div style='margin-top:100px; text-align:center;'>Due to a bug in Chrome you need to paste the PIN code below into the main window:</div><div style='background:#F6F8DE; width:620px; padding:15px; margin-top:10px; border:2px solid black; margin:auto; text-align:center; font-size:24px;'>" + trimmed + "</div></body></html>";

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
    var options = {
        host: 'api.github.com',
        port: 443,
        path: "/" + request.url.match(/^\/github\/(.*)$/)[1],
        method: request.method
    }

    var proxy_request = HTTPS.request(options, function(proxy_response){
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

var PREFIX = process.env.STATIC_DIR || 'static'
console.log("Starting with static directory: "+PREFIX)

function staticServe(request, response) {
    var path = PREFIX + request.url + (/\/$/.test(request.url) ? "index.html" : "");
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
