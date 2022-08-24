# Patchtime
So the problem is to schedule stuff monthly in a reliable manner. Let say you want **Leg A** of a solution to do someting like patching on the first tuesday of the month and **Leg B** on the first wednesday. Using cron this would be a mess as **leg A** would sometimes be executed six days after **Leg B** depending on the month.

## Description
These little effers will tell you what day of the month it is. Sound trivial but they print stuff like **w2d6h23**, it is all based on when the first Monday or Tuesday is. Weeks are considered Monday to Sunday, week 1 (w1) is when the first Tuesday or Monday of the month occurs. 
When counting from Tuesdays, the whole week including the Monday before Tuesday is considered part of the week. This is when you take out a calendar and have a look. The last week of the month will most often have days from next month, these days are counted as part of the last week.
You can use this to sanely schedule **w1d1h00 - w4d7h23**. Week 5 will be printed as expected but as it does not always exist, it is not the best of ideas to use it in scheduling.

These are great to schedule monthly patching, lets say you want the repo to sync and publish to your **test-environment** at **w1d1h00**. You might then want your **test-environment** to patch **leg A** of the your redundant solution at **w1d1h10** and **leg B** at **w1d2h10**. Giving you a day to notice any issues in between.
Lets say then you want to publish the updated repo to **prod**, **w3d1h00**, a good week later running and evaluating your patched **test-environment**. You could the patch **prod** **leg A** at **w3d1h20** and **B** at **w3d1h21**. 

You now probably understand these scripts are written with cron in mind.

This idea was forged running large systems with a plethora of customers, where each customer could define what patchwindow their servers should use via an interface.
The Configuration Management Tool of your choice would be asked to read the patchwindow every hour and patch whatever systems tagged via a simple cron, check out the examples below.
When running large systems you often have monitoring of some sort, and patching with reboot is always an issue. So you want to notify the monitoring system beforehand. My little scripts aren't great with this but will combine nicely with faketime.

## Usage
##### Simple example
$ date "+%Y-%m-%d %H:%M"  
2022-11-26 09:40  
$ ./patchtime_mon.sh  
w3d6h09  
$ ./patchtime_tue.sh  
w4d6h09  


##### Combining with cron to run scripts syncing repos and patching hosts.
0 * * * * [ $(/opt/scripts/patchtime_mon.sh) == "**w1d1h00**" ] && /opt/scripts/**sync_repos.sh** && /opt/scripts/**publish_phase1.sh**  
0 * * * * [ $(/opt/scripts/patchtime_mon.sh) == "**w1d1h10**" ] && /opt/scripts/patch_**test_leg-A**.sh  
0 * * * * [ $(/opt/scripts/patchtime_mon.sh) == "**w1d2h10**" ] && /opt/scripts/patch_**test_leg-B**.sh  
0 * * * * [ $(/opt/scripts/patchtime_mon.sh) == "**w3d1h00**" ] && /opt/scripts/**publish_phase2.sh**  
0 * * * * [ $(/opt/scripts/patchtime_mon.sh) == "**w3d1h20**" ] && /opt/scripts/patch_**prod_leg-A**.sh  
0 * * * * [ $(/opt/scripts/patchtime_mon.sh) == "**w3d2h21**" ] && /opt/scripts/patch_**prod_leg-B**.sh  


##### Combining with cron and AWX/Tower/Ansible, the inventory in AWX/Ansible is pulled from Netbox where each host has a defined patchwindow.
0 * * * * bash -c '/usr/bin/awx job_templates launch "Notify patch stakeholders" --extra_vars "survey_hosts: patchwindow_$(/usr/bin/faketime -f "+24h" /opt/scripts/patchtime_tue.sh)"'  
0 * * * * bash -c '/usr/bin/awx job_templates launch "Monitoring Schedule Downtime" --extra_vars "survey_hosts: patchwindow_$(/usr/bin/faketime -f "+2h" /opt/scripts/patchtime_tue.sh)"'  
0 * * * * bash -c '/usr/bin/awx job_templates launch "Patch OS" --extra_vars "survey_hosts: patchwindow_$(/opt/scripts/patchtime_tue.sh)"'  

## Roadmap
It would be cool to rewrite this is something other than bash and package it in an rpm. Or even extend a version of cron with this stuff.

## Contributing
Yes, please!

## Authors and acknowledgment
Google is supposedly your friend.

## License
GNU GPLv3

## Project status
Not sure how much energy I have to push this further, if you want to fork or just grab the idea, go ahead.
