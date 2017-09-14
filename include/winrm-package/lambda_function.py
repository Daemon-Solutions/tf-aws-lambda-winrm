import winrm
import boto3
import os

s3 = boto3.resource('s3') 

def lambda_handler(event, context):
    bucket = event['Records'][0]['s3']['bucket']['name']
    key = event['Records'][0]['s3']['object']['key']
    file_contents = (read_s3_object(bucket,key))
    tags_name,tags_value,script=parse_file(file_contents)
    username=os.environ['env_username']
    password=os.environ['env_password']

    print ("TAG: ",tags_name)
    print ("Tag Value: ",tags_value)
    print ("Script Block: ", script)

    target_instances=list_instances_by_tag_value(tags_name, tags_value)
    
    for instance in target_instances:
        print ("Instance: ", instance)
        ip = ip_from_instance_id(instance)
        execute_winrm(ip, script, username, password)
    

def read_s3_object(bucket,key):
    s3object = s3.Object(bucket,key)
    contents = s3object.get()["Body"].read()
    return contents

def execute_winrm(target, script_block, username, password):
    s = winrm.Session(target, auth=(username, password), transport='ssl', server_cert_validation='ignore')
    ps_script = script_block
    r = s.run_ps(ps_script)
    print (r.std_out)

def left(s, amount):
    return s[:amount]
    
def parse_file(file_contents):
    row = 0
    for line in file_contents.splitlines():
        row += 1
        if left(line.lower(), 6) == "target":
            tags_name = ((line.split("="))[1]).split(":")[0]
            tags_value = ((line.split("="))[1]).split(":")[1]
        if left(line.lower(), 13) == "scriptblock=@":
            script_start = row+1
        if left(line, 1) == "@":
            script_end = row
    contents=file_contents.splitlines()
    script=""
    for x in range(script_start, script_end):
        script = script + (contents[x-1])+'\n'
    return (tags_name,tags_value,script)

def list_instances_by_tag_value(tagkey, tagvalue):
   
    ec2client = boto3.client('ec2')

    response = ec2client.describe_instances(
        Filters=[
            {
                'Name': 'tag:'+tagkey,
                'Values': [tagvalue]
            },{'Name': 'instance-state-name', 'Values': ['running']}
        ]
    )
    instancelist = []
    for reservation in (response["Reservations"]):
        for instance in reservation["Instances"]:
            instancelist.append(instance["InstanceId"])
    return instancelist

def ip_from_instance_id(instance_id):
       
    ec2 = boto3.resource('ec2') 
    instances = ec2.instances.filter(
    Filters=[{'Name': 'instance-id', 'Values': [instance_id]}])
    

    
    ip=list(instances.all())[0].private_ip_address
    return ip