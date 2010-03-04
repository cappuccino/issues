<?php
//phpinfo();

/*
 * GitHubAPI.php
 * GitIssues
 *
 * Created by Randall Luecke on February 20, 2010.
 * Copyright 2010, Randall Luecke All rights reserved.
 */

/*
    This file is designed to use the GitHubAPIConnection class
    to communicate with GitHub.
*/

include "GitHubAPIConnection.class.php";

//print_r($_POST);
// We require all three post variables to be passed in. 
//if(!isset($_POST) || !isset($_POST['user']) || !isset($_POST['pass']) || !isset($_POST['suffix']))
  //  die();

/*$_POST = array(
    "user"=>"me1000",
    "pass"=>"icu81234",
    "suffix"=>"blah"
);*/

//print_r($_POST);

$call = new GitHubAPIConnection;
$call->username = $_POST['user'];
$call->password = $_POST['pass'];
$call->urlSuffix = $_POST['suffix'];
$response = $call->sendRequest();

echo $response;

?>