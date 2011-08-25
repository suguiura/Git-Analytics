
Git Analytics
=============

Git Analytics is a set of tools for downloading and parsing publicly available
git repositories metadata.

The tools were created as a part of a research at Instituto de Matemática e
Estatística.


Dependencies
============

- linux
- bash
- wget
- git
- ruby
- libxml (libxml.rubyforge.org)


How to use
==========

The full process of downloading and parsing the data is described in the
following steps.

Download the git files from each project
----------------------------------------

A given server can contain several projects (e.g. git.kernel.org) and the dl.rb
tool was made to automatically download them. Give a yaml configuration file to
the too, using the following command syntax to download the data. If a project
list doesn't already exist, it is downloaded.

    ruby script/dl.rb <config.yaml>

### Download git descriptions (optional)

Since the git tool, used within the script in the previous step, doesn't
download projects description, it can be done separately. A tool is available
for this task and has the following syntax:

    ruby script/dl-description <config.yaml>

### Correct incorrect emails (optional)

Many emails are messed up by their own owners, due to a number of reasons. To
correct some of them (not all emails can be corrected sometimes), git has a
mailmap file (more information at `git help shortlog`), which, in one of its
basic forms, plainly maps the original email string to the correct one. It's
pretty simple.

A script to list all the anomalies is the following:

    ruby script/anomalies.rb <config.yaml>

Another script tries its best to guess the correct email from a list supplied
into its standard input. Using the list from the script above, the following
will generate a mailmap format from the input list.

    ruby script/anomalies.rb <config.yaml> | ruby script/mailmap.rb

Note: In order to actually use the mailmap file, set it into the git config with
the following command:

    git config --global mailmap.file <path_to_mailmap>

Concatenate commit logs into a formatted file
---------------------------------------------

All the commit data are hidden within the git files, usually packaged,
compressed and using their own format. This step is needed to expand, filter and
format the logs into the standard output which is going to be used by the next
step. Redirecting it to a file is recommended, since the output can be big.

    ruby script/gitlog.rb <config.yaml>

Generate a CSV file
-------------------

In order to generate a valid csv formatted text, along with some
transformations, the following script is used, where both parameters
--default-origin and --regexp-origin are optional and are used to define the
origin column, in terms of the default and the presence of a substring at the
project's name.

    ruby script/csv.rb [--default-origin <string>] [--regexp-origin <regexp>]

The pipe way
------------

Given the data is already downloaded, performing the above steps many times in a
rown can become quite monotonous. Fortunately, the scripts were coded into such
a way that it all can be done into a long pipe. The following is an example
using the pipe feature, along with `time` and `gzip`.

    time ruby script/gitlog.rb config/linux.yaml | ruby script/csv.rb | gzip -c > generated/linux.dat.gz

Acknowledgements
================

This project was possible with the tutorship of Carlos Denner dos Santos Jr and
the financial support of [Centro de Competência de Software Livre]
(http://ccsl.ime.usp.br/).

