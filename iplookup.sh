#!/bin/bash
############################################################################
#	iplookup.sh
#	  Author:Garrett Dyer	
#	  Date:10/28/21		
# 	  Last revised:11/26/21	
#	  Description:	Identifies attempted hacking on the server
#			- Checks an input file for IP addresses
#			- Counts the number of attempts for each
#			- Discards IP addresses with <100 attempts
#			- Menu driven
#			  - 1. Displays IP addresses
#			  - 2. Displays detailed IP information
#			  - 3. Adds IP addresses to UFW
#			       - Makes sure IP addy isn't already in UFW
#			  - 4. Displays firewall rules
#			  - 5. Exits script
#
############################################################################

############### ERROR CHECKING ######################
# have to sudo to access log files
if [ "$EUID" -ne 0 ]; then
printf "Run with sudo\n"
exit 1
fi

# check for proper usage (correct # of arguments - 0)
if [ "$#" -gt 1 ] || [ "$#" -lt 1 ]; ## check for less than 1
then
printf "Incorrect number of parameters. Only one parameter is allowed\n"
exit 1
fi

if [ ! -f "$1" ]; then
echo "File not found. Please try again"
exit 1
fi

############# DONE ERROR CHECKING ##################

#variables
regs=""
iponly=""
counter=""
ipinufw=""
attempts=""
ipnotinufw=""
#this regex will match pattern from 0.0.0.0 to 255.255.255.255. it's a
#beast, but it works
printf "Working....\n\n"
regs=$(grep -i 'rhost=' "$1"| grep -E -o "(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)" "$1"| sort -n | uniq -c > file1.txt ) 

#get all offenders (100+) from input file. In the input file, the IP address is recorded three times for each offense.
#filtering on "rhost=$IP" trims off the other two entries

#display the unique IP addresses on demand
function display_unique_ips {
	echo "$iponly"
	printf "\n"
}

#print detailed info on the offenders
function print_info {
printf "Working...Please wait\n"
    for i in $(echo "$iponly")
    do
	   curl -s ipinfo.io/"$i"?token=#removed token
	   if [ "$?" != 0 ]; then
		  printf "Error something went wrong"
	       return
	   fi
       done
}

#add the IPs to the firewall. if 'y', have to check
#and make sure that the IP isn't already in the firewall
function add_ips_to_ufw {
echo "Do you want add all the Ips to the firewall? yes/no"
read ans
case $ans in
	[Yy]es) 

	echo "Working.....Please be patient."  
	ipinufw=$(sudo ufw status | awk '{if($2 ~ /DENY/) print $3}')

	for i in $(echo "$iponly")
	do
		echo "$ipinufw" | grep -F -w "$i" > /dev/null
		if [ "$?" = 0 ]; then
			printf "Ip is already in firewall\n"
		else
			sudo ufw insert 1 deny from "$i" > /dev/null
		fi
	done		;;


	[Nn]o)
	return ;;
esac
}

function show_firewall {
	sudo ufw status numbered
}

function quit {
	printf "Quitting....\n"
	exit 1
}

#count both total attempts and unique IP addresses
iponly=$(awk '{if($1 < 100) ; else print $2}' file1.txt)
attempts=$(awk '{if($1 < 100) ; else print $1}' file1.txt | awk '{sum+=$1} ; {print sum}' | tail -1) 
counter=$(echo "$iponly" | wc -l) 
printf "There are $counter unique ips, and $attempts number of attempts\n"


#menu
for (( ; ; ))
do
printf "Choose an option:\n1. Display IP's\n2. Print IP info\n3. Add IP's to firewall\n4. Show firewall rules\n5. Quit\nEnter option:"
read op
case $op in
	1)
		display_unique_ips ; ;;  
	2)
		print_info ; ;;
	3)
		add_ips_to_ufw ; ;;  
	4)
		show_firewall ; ;;  
	5) 
		quit ; ;;
	esac
done

###################################################################
echo
echo "Done! Bye now"
echo
