<?php
/*
 * GitHubAPIConnection.class.php
 * GitIssues
 *
 * Created by Randall Luecke on February 20, 2010.
 * Copyright 2010, Randall Luecke All rights reserved.
 */

/*
    This class is designed to provide a connection to GitHub 
    for "write" API calls which are not supported for JSONP
*/


class GitHubAPIConnection
{
    var $username;
    var $password;
    var $urlSuffix;


    function sendRequest()
    {
        //var theReadURL = "https://" + GITHUBUSERNAME + ":" + GITHUBPASSWORD + "@github.com/api/v2/json/issues/comment/" + theUser + "/" + repo + "/" + anIssueNumber + "?comment=" + aComment,
        $fullURL = "https://".$this->username.":".$this->password."@github.com/api/v2/json/issues/".$this->urlSuffix;
//        echo $this->urlSuffix;
  //      return $fullURL;
        $curl_handle = curl_init();
        curl_setopt($curl_handle, CURLOPT_URL, $fullURL);
        //curl_setopt($curl_handle, CURLOPT_POST, true);
        curl_setopt($curl_handle, CURLOPT_CONNECTTIMEOUT, 20);
        curl_setopt($curl_handle, CURLOPT_RETURNTRANSFER, 1);
        $buffer = curl_exec($curl_handle);
        //$error = curl_error($curl_handle);
        //echo "error: ".$error;
        curl_close($curl_handle);
        
        return $buffer;
    }

}
?>