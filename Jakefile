/*
 * Jakefile
 * GitIssues
 *
 * Created by You on February 20, 2010.
 * Copyright 2010, Your Company All rights reserved.
 */

var ENV = require("system").env,
    FILE = require("file"),
    task = require("jake").task,
    FileList = require("jake").FileList,
    app = require("cappuccino/jake").app,
    configuration = ENV["CONFIG"] || ENV["CONFIGURATION"] || ENV["c"] || "Release",
    OS = require("os");

app ("GitIssues", function(task)
{
    task.setBuildIntermediatesPath(FILE.join("Build", "GitIssues.build", configuration));
    task.setBuildPath(FILE.join("Build", configuration));

    task.setProductName("GitIssues");
    task.setIdentifier("com.yourcompany.GitIssues");
    task.setVersion("1.0");
    task.setAuthor("Your Company");
    task.setEmail("feedback @nospam@ yourcompany.com");
    task.setSummary("GitIssues");
    task.setSources(new FileList("**/*.j"));
    task.setResources(new FileList("Resources/*"));
    task.setIndexFilePath("index.html");
    task.setInfoPlistPath("Info.plist");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g");
    else
        task.setCompilerFlags("-O");
});

task ("default", ["GitIssues"]);
task ("deploy", function()
{
    OS.system("press Build/Release/GitIssues Build/Release/GitIssuesPressed/");
    OS.system("flatten Build/Release/GitIssuesPressed Build/Release/GitIssuesFlattened/");
});

task ("closure", function()
{
   OS.system("cp -r Build/Release/TimeTableFlattened/ Build/Release/TimeTableClosure/");
    OS.system("java -jar /Users/randy/Desktop/compiler.jar --js=Build/Release/TimeTableClosure/Application.js  --js_output_file=Build/Release/TimeTableClosure/out.js");
    OS.system("rm Build/Release/TimeTableClosure/Application.js");
    OS.system("cp Build/Release/TimeTableClosure/out.js  Build/Release/TimeTableClosure/Application.js");
    OS.system("rm Build/Release/TimeTableClosure/out.js");
});