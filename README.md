# patchtime — week-of-month scheduling for cron

Small bash and Python utilities that print a *patch window* like `w2d6h23` — week 2 of the month, Saturday, 23:00 — so you can drive cron jobs by the first/second/third/fourth Monday or Tuesday of every month. Useful for Patch-Tuesday-style staged rollouts where leg A and leg B of a redundant system have to update on consecutive but predictable days, every month, without the spacing drift that plain `0 9 1-7 * 1` (first Monday) gives you. Companion project: [cronie-patchtime](https://github.com/nashways/cronie-patchtime) — a fork of cronie with this idea built into the daemon as an `@patch` crontab keyword.

## The problem
You want **Leg A** of a redundant system patched on the first Tuesday of the month and **Leg B** on the first Wednesday. Plain cron makes this awkward — `0 9 1-7 * 2` and `0 9 1-7 * 3` work in some months and misfire in others depending on the day the month starts on, and the spacing between the two firings changes monthly.

## The solution
Count weeks from a repeatable anchor day in the month — the first Monday, first Tuesday, or any other ISO weekday 1-7. That's how Microsoft defines "Patch Tuesday" (second Tuesday of the month at 10:00 PST), and it's how patchtime works.

## Description
`patchtime.sh` and `patchtime.py` print the current patch window as `w2d6h23`: **w** for week (1-4), **d** for day (1-7, ISO Monday=1), **h** for hour (00-23).

The script can count weeks from the first Monday of Tuesday of the month. When counting from Tuesdays, the whole week including the Monday before Tuesday is considered part of the week. This is when you take out a calendar and have a look. The last week of the month will sometimes not be a complete week, the script will then "steal" days from next month as they are not otherwise used in next month's week one.

This means you can use this to sanely schedule **w1d1h00 - w4d7h23**. Some months will have a Week 5 and it will be printed as expected but as it does not always exist, it's not the best of ideas to use it.

This is great to use for scheduling monthly patching, lets say you want your repo to sync and publish to your **test-environment** at **w1d1h00**. You might then want your **test-environment** to patch **leg A** of your redundant solution at **w1d1h10** and **leg B** at **w1d2h10**. Giving you a day to notice any issues in between.

Lets then say you want to publish the updated repo to **prod**, at **w3d1h00**, a good week later running and evaluating your patched **test-environment**. You could the patch **prod** **leg A** at **w3d1h20** and **B** at **w3d1h21**. 

You now probably understand these scripts are written with cron in mind.

## Source the idea
This idea came up when running numerous systems with a plethora of customers, where each customer could define what patchwindow their servers should use via an interface.
The Automation Management Tool of your choice would be asked to read members of the patchwindow every hour and patch via a simple cron, check out the scheaduled examples below.
When running large systems you often have monitoring of some sort, and patching with reboot is always an issue. So you want to notify the monitoring system beforehand. This little script do not handle delays or preemtive strikes like that but will combine nicely with faketime, https://www.rpmfind.net/linux/rpm2html/search.php?query=libfaketime.

## Usage
##### Simple example
$ date "+%Y-%m-%d %H:%M"  
2022-11-26 09:40  
$ ./patchtime.sh 
w3d6h09

###### Counting from the first Monday is default, "-t" counts from the first Tuesday.

#Faketime is mearly to produce the example
$ faketime "2023-07-31 08:00:00" ./patchtime.sh  
w5d1h08  
$ faketime "2023-07-31 08:00:00" ./patchtime.sh -t  
w1d1h08  
$ faketime "2023-08-7 08:00:00" ./patchtime.sh  
w1d1h08  
$ faketime "2023-08-7 08:00:00" ./patchtime.sh -t  
w2d1h08  


##### Combining with cron to run scripts syncing repos and patching hosts.
0 * * * * [ $(/opt/scripts/patchtime.sh -t) == "**w1d1h00**" ] && /opt/scripts/**sync_repos.sh** && /opt/scripts/**publish_phase1.sh**  
0 * * * * [ $(/opt/scripts/patchtime.sh -t) == "**w1d1h10**" ] && /opt/scripts/patch_**test_leg-A**.sh  
0 * * * * [ $(/opt/scripts/patchtime.sh -t) == "**w1d2h10**" ] && /opt/scripts/patch_**test_leg-B**.sh  
0 * * * * [ $(/opt/scripts/patchtime.sh -t) == "**w3d1h00**" ] && /opt/scripts/**publish_phase2.sh**  
0 * * * * [ $(/opt/scripts/patchtime.sh -t) == "**w3d1h20**" ] && /opt/scripts/patch_**prod_leg-A**.sh  
0 * * * * [ $(/opt/scripts/patchtime.sh -t) == "**w3d2h21**" ] && /opt/scripts/patch_**prod_leg-B**.sh  


##### Combining with cron and AWX/Tower/Ansible, the inventory in AWX/Ansible is pulled from Netbox where each host has a defined patchwindow.
0 * * * * bash -c '/usr/bin/awx job_templates launch "Notify patch stakeholders" --extra_vars "survey_hosts: patchwindow_$(/usr/bin/faketime -f "+24h" /opt/scripts/patchtime.sh -t)"'  
0 * * * * bash -c '/usr/bin/awx job_templates launch "Monitoring Schedule Downtime" --extra_vars "survey_hosts: patchwindow_$(/usr/bin/faketime -f "+2h" /opt/scripts/patchtime.sh -t)"'  
0 * * * * bash -c '/usr/bin/awx job_templates launch "Patch OS" --extra_vars "survey_hosts: patchwindow_$(/opt/scripts/patchtime.sh -t)"'  

## Native cron support — cronie-patchtime
A fork of cronie with a built-in `@patch` keyword lives at
https://github.com/nashways/cronie-patchtime (branch `patchtime`).
It teaches cron the same week-of-month math, so you can drop the
shell-gating shown above and write entries like:

    @patch w1 d1 h00  /opt/scripts/sync_repos.sh
    @patch w1 d1 h10  /opt/scripts/patch_test_leg-A.sh
    @patch w3 d1 h00  /opt/scripts/publish_phase2.sh

Syntax: `@patch [a<N>] w<list> d<list> [h<list>] [m<list>]  command`,
where `a` is the anchor weekday 1..7 (default 1=Monday), and `w`/`d`/`h`/`m`
accept the same list/range/`*` syntax as ordinary cron fields. Build
with `./configure --enable-patchtime` (or `--disable-patchtime` for
vanilla cronie). See the `crontab(5)` man page in the fork for full
docs and examples.

## Roadmap
It would be cool to rewrite this is something other than bash and package it in a rpm. ~~Or even extend a version of cron with this stuff.~~ Cron extension done — see cronie-patchtime above.

## Contributing
Yes, please!, Just say hi and I will add you as a collaborator if you want.

## Authors and acknowledgment
Google is supposedly your friend.

## License
GNU GPLv3

## Project status
Not sure how much energy I have to push this further, if you want to fork or just grab the idea, go ahead.
