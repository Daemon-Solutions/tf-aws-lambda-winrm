tf-aws-lambda-winrm
-----

Mechanism to target ec2 Windows instances with a PowerShell scriptblock.

This module utilises the pywinrm library, Lambda, and s3.

Usage
-----
Create a text file similar to the below:

```
target=foo:bar
scriptblock=@
    Add-WindowsFeature telnet-client;
    Add-WindowsFeature TFTP-Client;
@
```

* Placing the above file into the WinRM s3 bucket will trigger a Lambda function.
* The Lambda function will target all instances with a tag `name:value` of `foo:bar`, executing the contents of the `scriptblock` parameter above.
* Output of all commands are written to the Lambda WinRM CloudWatch log group.


Prerequisites
-------------
You must have a local credential which matches the variables in your terraform configuration, as well as having the following WinRM configuration applied on the instance:

```PowerShell
# Create the new TLS certificate
$Certificate = New-SelfSignedCertificate -DnsName $env:COMPUTERNAME -CertStoreLocation "Cert:\LocalMachine\My";

# Queue up and execute some WinRM commands
$WinRMCommands = @(
    [String]::Format('create winrm/config/Listener?Address=*+Transport=HTTPS @{Hostname="{0}";CertificateThumbprint="{1}"}',$env:COMPUTERNAME,$Certificate.Thumbprint),
    "delete winrm/config/listener?Address=*+Transport=HTTPS",
    'set winrm/config/client/auth @{Basic="true"}',
    'set winrm/config/service/auth @{Basic="true"}',
    'set winrm/config/service @{AllowUnencrypted="false"}'
)| %{
    Start-Process "winrm" -ArgumentList $_ -NoNewWindow -PassThru -Wait;
}

# Create a firewall rule for WinRM over HTTPS
New-NetFirewallRule -DisplayName "Windows Remote Management (HTTPS-In)" -Direction Inbound -LocalPort 5986 -Protocol TCP -Action Allow;
```

Variables
---------
_Variables marked with **[*]** are mandatory._

 - `customer` - The name prefix for resources created by this module. **[*]**
 - `envname` - The value for the `Environment` tag on the AWS Security Group rule. **[*]**
 - `envtype` - The value for the `Envtype` tag on the AWS Security Group rule, and the second part of the S3 bucket name. **[*]**
 - `lambda_subnets` - A List of subnet IDs associated with the Lambda function. [Default: `[]`]
 - `lambda_sgs` - A list of security group IDs associated with the Lambda function. [Default: `[]`]
 - `vpc_id` - The VPC ID for the Security Group rule to allow WinRM traffic. **[*]**
 - `username` - The username of a Windows account to connect to ec2 instances with.  **[*]**
 - `password` - The password for the Windows user account specified in `username`. **[*]**

Outputs
-------
 - `winrm_sg` - The ID for the WinRM security group.

Future development tasks
------------------------
* Read password from secure SSM parameter store
* Enable targeting by wildcards, IPs and AZs
* Add scheduled trigger to allow re-application of PowerShell (drift control)
