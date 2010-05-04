/*
 * Jakefile
 * GitHubIssues
 *
 * Created by You on May 3, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

var ENV = require("system").env,
    FILE = require("file"),
    JAKE = require("jake"),
    task = JAKE.task,
    FileList = JAKE.FileList,
    app = require("cappuccino/jake").app,
    configuration = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Debug",
    OS = require("os");

app ("GitHubIssues", function(task)
{
    task.setBuildIntermediatesPath(FILE.join("Build", "GitHubIssues.build", configuration));
    task.setBuildPath(FILE.join("Build", configuration));

    task.setProductName("GitHubIssues");
    task.setIdentifier("com.yourcompany.GitHubIssues");
    task.setVersion("1.0");
    task.setAuthor("Your Company");
    task.setEmail("feedback @nospam@ yourcompany.com");
    task.setSummary("GitHubIssues");
    task.setSources((new FileList("**/*.{j,js}")).exclude(FILE.join("Build", "**")));
    task.setResources(new FileList("Resources/**"));
    task.setIndexFilePath("index.html");
    task.setInfoPlistPath("Info.plist");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g");
    else
        task.setCompilerFlags("-O");
});

task ("default", ["GitHubIssues"], function()
{
    OS.system("cp *.js " + OS.enquote(FILE.join("Build", configuration, "GitHubIssues", ".")));
    printResults(configuration);
});

task ("build", ["default"]);

task ("debug", function()
{
    ENV["CONFIGURATION"] = "Debug";
    JAKE.subjake(["."], "build", ENV);
});

task ("release", function()
{
    ENV["CONFIGURATION"] = "Release";
    JAKE.subjake(["."], "build", ENV);
});

task ("run", ["debug"], function()
{
    OS.system(["open", FILE.join("Build", "Debug", "GitHubIssues", "index.html")]);
});

task ("run-release", ["release"], function()
{
    OS.system(["open", FILE.join("Build", "Release", "GitHubIssues", "index.html")]);
});

task ("deploy", ["release"], function()
{
    FILE.mkdirs(FILE.join("Build", "Deployment", "GitHubIssues"));
    OS.system(["press", "-f", FILE.join("Build", "Release", "GitHubIssues"), FILE.join("Build", "Deployment", "GitHubIssues")]);
    printResults("Deployment")
});

task ("desktop", ["release"], function()
{
    FILE.mkdirs(FILE.join("Build", "Desktop", "GitHubIssues"));
    require("cappuccino/nativehost").buildNativeHost(FILE.join("Build", "Release", "GitHubIssues"), FILE.join("Build", "Desktop", "GitHubIssues", "GitHubIssues.app"));
    printResults("Desktop")
});

task ("run-desktop", ["desktop"], function()
{
    OS.system([FILE.join("Build", "Desktop", "GitHubIssues", "GitHubIssues.app", "Contents", "MacOS", "NativeHost"), "-i"]);
});

function printResults(configuration)
{
    print("----------------------------");
    print(configuration+" app built at path: "+FILE.join("Build", configuration, "GitHubIssues"));
    print("----------------------------");
}
