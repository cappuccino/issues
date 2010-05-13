/*
 * Jakefile
 * Issues
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

app ("Issues", function(task)
{
    task.setBuildIntermediatesPath(FILE.join("Build", "Issues.build", configuration));
    task.setBuildPath(FILE.join("Build", configuration));

    task.setProductName("Issues");
    task.setIdentifier("com.280north.Issues");
    task.setVersion("1.0");
    task.setAuthor("280 North, Inc.");
    task.setEmail("feedback @nospam@ 280north.com");
    task.setSummary("Issues");
    task.setSources((new FileList("**/*.{j,js}")).exclude(FILE.join("Build", "**")));
    task.setResources(new FileList("Resources/**"));
    task.setIndexFilePath("index.html");
    task.setInfoPlistPath("Info.plist");

    if (configuration === "Debug")
        task.setCompilerFlags("-DDEBUG -g");
    else
        task.setCompilerFlags("-O");
});

task ("default", ["Issues"], function()
{
    OS.system("cp *.js " + OS.enquote(FILE.join("Build", configuration, "Issues", ".")));
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
    OS.system(["open", FILE.join("Build", "Debug", "Issues", "index.html")]);
});

task ("run-release", ["release"], function()
{
    OS.system(["open", FILE.join("Build", "Release", "Issues", "index.html")]);
});

task ("deploy", ["release"], function()
{
    FILE.mkdirs(FILE.join("Build", "Deployment", "Issues"));
    OS.system(["press", "-f", FILE.join("Build", "Release", "Issues"), FILE.join("Build", "Deployment", "Issues")]);
    printResults("Deployment")
});

task ("desktop", ["release"], function()
{
    FILE.mkdirs(FILE.join("Build", "Desktop", "Issues"));
    require("cappuccino/nativehost").buildNativeHost(FILE.join("Build", "Release", "Issues"), FILE.join("Build", "Desktop", "Issues", "Issues.app"));
    printResults("Desktop")
});

task ("run-desktop", ["desktop"], function()
{
    OS.system([FILE.join("Build", "Desktop", "Issues", "Issues.app", "Contents", "MacOS", "NativeHost"), "-i"]);
});

function printResults(configuration)
{
    print("----------------------------");
    print(configuration+" app built at path: "+FILE.join("Build", configuration, "Issues"));
    print("----------------------------");
}
