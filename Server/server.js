var HTTP = require("http");
var MIME = require("./mime");
var FS = require("fs");

// set some additional mime types
MIME.types[".cib"] = "text/plain";
MIME.types[".sj"] = "text/plain";
MIME.types[".j"] = "text/plain";
MIME.types[".plist"] = "application/xml";

var puts = require("sys").puts;

HTTP.createServer(function (request, response) {
    try {
        if (/^\/github\//.test(request.url)) {
            githubProxy(request, response);
        }
        else {
            staticServe(request, response);
        }
    } catch (e) {
        response.writeHead(200, {"Content-Type": "text/plain"})
        response.end("error: "+e+"\n");
    }
}).listen(parseInt(process.env.PORT || 8001));

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
