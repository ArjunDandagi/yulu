#!/usr/bin/env bash


declare -a ASGS=$(aws autoscaling describe-auto-scaling-instances --query 'AutoScalingInstances[].AutoScalingGroupName' --output text)

echo "Choose the ASG"
select ASG in ${ASGS[@]}
do
	:;break;

done

aws autoscaling describe-auto-scaling-instances --query 'AutoScalingInstances[?contains(AutoScalingGroupName,`'${ASG}'`)].InstanceId' --output text > instance_ids.txt


if [ -s instance_ids.txt ]; then
   : # echo "Got ids of all instance in the ASG - continuing to get publipIP and keyName"
else
    echo "No instance found with that ASG Name" && rm instance_ids.txt && exit 0
fi


# for brevity any of the file i create here is assumed to be non existent 
# otherwise i would do `rm filename` before hand 
rm hostlist.txt 2> /dev/null
aws ec2 describe-instances --query "Reservations[*].Instances[*].{key_name: KeyName ,public_ip: PublicIpAddress}" --instance-ids $(cat instance_ids.txt | tr '\n' ' ') --filters Name=instance-state-name,Values=running --output text | while read pem ip;do echo ${pem}.pem $ip >> hostlist.txt;done 


rm instance_ids.txt
echo "the file hostlist.txt has the pem keyname and ip of the server - happy bashing"
