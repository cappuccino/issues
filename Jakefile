var JAKE = require("jake");
var FILE = require("file");
var OS = require("os");

var BUILD_PATH = FILE.path("Build");
var SERVER_BUILD_PATH = BUILD_PATH.join("Server");
var CLIENT_BUILD_PATH = SERVER_BUILD_PATH.join("static");

var DEPLOY_GIT_REMOTE = "git@heroku.com:githubissues.git";

JAKE.task("deploy", ["build"], function() {
    var sha = getGitSHA();

    OS.system("cd "+OS.enquote(SERVER_BUILD_PATH)+" " + buildCommandString([
        ["git", "pull"],
        ["git", "add", "."],
        ["git", "commit", "-a", "-m", sha+" built on "+(new Date())],
        ["git", "push", "heroku", "master"]
    ]));
});

JAKE.task("build", ["checkout"], function() {
    // server
    OS.system("cp -r Server/* " + OS.enquote(SERVER_BUILD_PATH.join(".")));

    // client
    OS.system("cd Client && jake deploy");
    if (CLIENT_BUILD_PATH.isDirectory())
        CLIENT_BUILD_PATH.rmtree();

    FILE.copyTree(FILE.join("Client", "Build", "Deployment", "Issues"), CLIENT_BUILD_PATH);
});

JAKE.task("checkout", function() {
    if (!SERVER_BUILD_PATH.isDirectory()) {
        SERVER_BUILD_PATH.dirname().mkdirs();
        OS.system(["git", "clone", DEPLOY_GIT_REMOTE, SERVER_BUILD_PATH, "-o", "heroku"]);
    }
});

function getGitSHA(directory) {
    var p = OS.popen((directory ? "cd "+OS.enquote(directory)+" && " : "") + "git rev-parse --verify HEAD");
    var sha = p.stdout.read().trim();
    p.stdin.close();
    p.stdout.close();
    p.stderr.close();
    return sha;
}

function buildCommandString(commands) {
    return commands.map(function(command) {
        return command.map(OS.enquote).join(" ");
    }).join(" && ");
}