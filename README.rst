******
taskdb
******

A personal tasks (todo list) management solution.

Introduction
############

Goals
=====

* Manage my todo list and schedule with little effort.
* Be in full control of my data.
* Work offline.
* Use something powerful and hackable to be able to experiment.

Motivation
==========

* Taskwarrior not fully satisfying.
    * Frustrating sync issues.
    * Lacking, or immature, UI and important integrations.
* Paid and/or non-FOSS solutions not deemed acceptable.
    * Scheduled todo list with attached notes is not what I think is complicated enough to give up software freedom I had with taskwarrior, at least it's not something I'd take lightly.
    * Most prominent runner-up, todoist, requires paid account to be marginally useful (to have, for example, text annotations).

Design ideas
============

* **Be extremely low maintenance**, and short roadmap project (the only way a parent of a toddler can afford).
* **Be paranoid about data** integrity and history.
    * Data integrity issues is why i migrate away from Taskwarrior, but I don't assume I can write perfect code.
    * So let's backup all data after every change!
    * Even better - let's annotate the changes with *what was the change operation*!
* **Don't roll my own** implementations of complex things.
    * Database.
        * Taskwarrior rolls their own RDBMS.
            * With a backend of text file of custom format, which is a JSON object per line.
            * Implements all various functions to access, process and present that data.
        * taskdb employs robust and feature-rich PostgreSQL as both backend and API (and even frontend).
    * Sync, replication.
        * Taskwarrior implements replay based replication with star topology, which is architecturally sound, but is buggy and caused me grief.
        * taskdb does not have master DB replication solution yet, but it will be a reuse of backend technology (PostgreSQL) specific solution, not taskdb-specific.
        * Most important taskdb feature for me currently is bidirectional sync with CalDAV. To have it, *and not implement it*, taskdb shells out to ``vdirsyncer``.
* **Enable usage of available commoditized tools**, don't require building specialized toolkit, or huge monolith, from scratch. The Unix way.
    * SQL UI.
        * Variety of readily available SQL UI products is a great bonus, but not a coincidence. I use:
            * OmniDB - great WYSIWYG interface to view and edit SQL databases
            * Grafana - gives dashboards with various views of information, e.g. plots, charts, tables. Define your metrics and watch how you perform towards them over time!
    * Calendar UI.
        * I haven't planned to lean heavily on it at initial design phase, but it quickly proved to be the biggest game changer.
        * Visualisation of time as space, Drag & Drop are amazing things! I would never implement that as well as some established solutions do.
