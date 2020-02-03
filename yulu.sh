#!/usr/bin/env bash

# this command collects all the ASG in a region and store it in array 
declare -a ASGS=$(aws autoscaling describe-auto-scaling-instances --query 'AutoScalingInstances[].AutoScalingGroupName' --output text)

# allows the user to choose the ASG
echo "Choose the ASG"
select ASG in ${ASGS[@]}
do
	 :;break;

done

# filter instnce ids of that ASG
aws autoscaling describe-auto-scaling-instances --query 'AutoScalingInstances[?contains(AutoScalingGroupName,`'${ASG}'`)].InstanceId' --output text > instance_ids.txt


# if there are no instance ids then exit 
if [ -s instance_ids.txt ]; then
   : # echo "Got ids of all instance in the ASG - continuing to get publipIP and keyName"
else
    echo "No instance found with that ASG Name" && rm instance_ids.txt && exit 0
fi


# for brevity any of the file i create here is assumed to be non existent 
# otherwise i would do `rm filename` beforehand 
 
rm hostlist.txt 2> /dev/null
# filter all the instance with instance ids and store pem key name and public ip of the instance
aws ec2 describe-instances --query "Reservations[*].Instances[*].{key_name: KeyName ,public_ip: PublicIpAddress}" --instance-ids $(cat instance_ids.txt | tr '\n' ' ') --filters Name=instance-state-name,Values=running --output text | while read pem ip;do echo ${pem}.pem $ip >> hostlist.txt;done 


#if u are here , u obviously have a file with instance_ids.txt 
rm instance_ids.txt
# at this point we have .pem files and ips ready , assuming u kept ur server pem files in .ssh
# assuming u have ubuntu OS for all the servers 


# scp the script to run to each of those instance and sleep for 5 second
while read pem ip
do
	chmod u+x remote_exec_file.sh 
	scp -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/${pem} remote_exec_file.sh  ubuntu@${ip}:/home/ubuntu/
	sleep 5
done < hostlist.txt

# now the part is to execute ssh and run them 
while read pem ip
do
        chmod u+x remote_exec_file.sh
        ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -i ~/.ssh/${pem} ubuntu@${ip} 'bash /home/ubuntu/remote_exec_file.sh' 
        sleep 5
done < hostlist.txt

