tf-aws-lambda-winrm
============

This module provides you with a mechanism to send powershell commands to a ec2 windows instance. The module utilises the pywinrm library, lambda, and s3. 

Usage
-----

Create a text file with the following contents:-

  `target=foo:bar`

  `scriptblock=@`

  `add-WindowsFeature telnet-client`

  `add-WindowsFeature TFTP-Client`

  `@`

Dropping the above file into the winrm s3 bucket will trigger a lambda function.

The lambda function will target all instances with a Tag of `foo` and a tag value of `bar`. It will then apply the script block between the 2 `@`s.

Output of all commands are written to the Lambda Winrm Cloudwtach log group.

Prerequisites
-------------

Instance must have the folllowing configured

`winrm set winrm/config/service @{AllowUnencrypted="true"}`

`winrm quickconfig`

`winrm set winrm/config/service/auth @{Basic="true"}`

`local username and password that matches the vars set in terraform`

future development tasks
------------------------
read password from secure ssm parameter store
enable targetting by wildcards, ips and AZs
add scheduled trigger to allow re-application of powershell (drift control)
