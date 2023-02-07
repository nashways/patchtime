# Patchtime
So the problem is to schedule stuff monthly in a reliable manner. Let say you want **Leg A** of a solution to do someting like patching on the first tuesday of the month and **Leg B** on the first wednesday. Using cron this would be a mess as **leg A** would sometimes be executed six days after **Leg B** depending on the month.

## Description
This litte script will tell you what day of the month it is. Sound trivial but it prints time like this **w2d6h23**, it is all based on when the first Monday or Tuesday occurs in the month. You can set whether to count from mondays ot tuesday inside the script. The output is simple **w** for week, **d** for day **h** for hour. When counting from Tuesdays, the whole week including the Monday before Tuesday is considered part of the week. This is when you take out a calendar and have a look. The last week of the month will steal days from next month as they are not otherwise used in next month's week one.
This means you can use this to sanely schedule **w1d1h00 - w4d7h23**. Some months will have a Week 5 and it will be printed as expected but as it does not always exist, it's not the best of ideas to use it in scheduling.

This is great to use for scheduling monthly patching, lets say you want your repo to sync and publish to your **test-environment** at **w1d1h00**. You might then want your **test-environment** to patch **leg A** of your redundant solution at **w1d1h10** and **leg B** at **w1d2h10**. Giving you a day to notice any issues in between.
Lets then say you want to publish the updated repo to **prod**, at **w3d1h00**, a good week later running and evaluating your patched **test-environment**. You could the patch **prod** **leg A** at **w3d1h20** and **B** at **w3d1h21**. 

You now probably understand these scripts are written with cron in mind.

This idea came up when running large systems with a plethora of customers, where each customer could define what patchwindow their servers should use via an interface.
The Automation Management Tool of your choice would be asked to read the patchwindow every hour and patch whatever systems tagged via a simple cron, check out the examples below.
When running large systems you often have monitoring of some sort, and patching with reboot is always an issue. So you want to notify the monitoring system beforehand. This little script do'nt handle delays or preemtive strikes like that but will combine nicely with faketime, https://www.rpmfind.net/linux/rpm2html/search.php?query=libfaketime.

## Usage
##### Simple example
$ date "+%Y-%m-%d %H:%M"  
2022-11-26 09:40  
$ ./patchtime.sh  
w3d6h09

#Set the variable DAY inside the script to Tue and it will count from tuesdays.
$ ./patchtime.sh  
w4d6h09  


##### Combining with cron to run scripts syncing repos and patching hosts.
0 * * * * [ $(/opt/scripts/patchtime.sh) == "**w1d1h00**" ] && /opt/scripts/**sync_repos.sh** && /opt/scripts/**publish_phase1.sh**  
0 * * * * [ $(/opt/scripts/patchtime.sh) == "**w1d1h10**" ] && /opt/scripts/patch_**test_leg-A**.sh  
0 * * * * [ $(/opt/scripts/patchtime.sh) == "**w1d2h10**" ] && /opt/scripts/patch_**test_leg-B**.sh  
0 * * * * [ $(/opt/scripts/patchtime.sh) == "**w3d1h00**" ] && /opt/scripts/**publish_phase2.sh**  
0 * * * * [ $(/opt/scripts/patchtime.sh) == "**w3d1h20**" ] && /opt/scripts/patch_**prod_leg-A**.sh  
0 * * * * [ $(/opt/scripts/patchtime.sh) == "**w3d2h21**" ] && /opt/scripts/patch_**prod_leg-B**.sh  


##### Combining with cron and AWX/Tower/Ansible, the inventory in AWX/Ansible is pulled from Netbox where each host has a defined patchwindow.
0 * * * * bash -c '/usr/bin/awx job_templates launch "Notify patch stakeholders" --extra_vars "survey_hosts: patchwindow_$(/usr/bin/faketime -f "+24h" /opt/scripts/patchtime.sh)"'  
0 * * * * bash -c '/usr/bin/awx job_templates launch "Monitoring Schedule Downtime" --extra_vars "survey_hosts: patchwindow_$(/usr/bin/faketime -f "+2h" /opt/scripts/patchtime.sh)"'  
0 * * * * bash -c '/usr/bin/awx job_templates launch "Patch OS" --extra_vars "survey_hosts: patchwindow_$(/opt/scripts/patchtime.sh)"'  

## Roadmap
It would be cool to rewrite this is something other than bash and package it in a rpm. Or even extend a version of cron with this stuff.

## Contributing
Yes, please!, Just say hi and I will add you as a collaborator if you want.

## Authors and acknowledgment
Google is supposedly your friend.

## License
GNU GPLv3

## Project status
Not sure how much energy I have to push this further, if you want to fork or just grab the idea, go ahead.
