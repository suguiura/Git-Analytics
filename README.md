
Git Analytics
=============

Git Analytics is a set of tools for downloading and parsing publicly available
git repositories metadata.

The tools were created as a part of a research at Instituto de Matemática e
Estatística.


Dependencies
============

- [linux](http://kernel.org/)
- [bash](http://www.gnu.org/s/bash/)
- [git](http://git-scm.com/)
- [perl](http://www.perl.org/)
- [ruby](http://ruby-lang.org/)
- [libxml](http://libxml.rubyforge.org/)


How to use
==========

The full process of evaluating the data includes generating a list of
repositories (list.yaml) from the initial config file (config.yaml), downloading
the bare git files from the repositories in that list, parsing them and either
printing data in the CSV format or generating and populating a database, is
described in the following section.

The configuration file is described further below.

Generating configuration files
------------------------------

All of the required metadata about projects is obtained and generated in this
section. Given a small set of data about a server hosting git repositories,
a list of projects is downloaded, obtaining and expanding the metadata for each
of those projects. This generated metadata is, then, saved into a YAML file.
The script for this task has the following syntax:

    ruby tools/configure.rb <android|gnome|linux>

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

Configuration File
==================

The configuration file has a YAML format. An example is shown below:

    :db:
      :commits:
        :adapter: sqlite3
        :database: /home/ram/commits.sqlite3
      :crunchbase:
        :adapter: sqlite3
        :database: /home/ram/cb.sqlite3

The _:db_ section of the configuration file are parameters passed straightly to
ActiveRecord to store the data into the database, or to retrieve data from it.
The _:commits_ subsection is the database for the git commits data. For a
specific moment, the crunchbase database should be queried, so it's
configuration was also stored here.

    :servers:
      :linux:
        :host: git.kernel.org
        :ip: 149.20.4.72
        :data:
          :dir:
          - /media/attach/data/git/source/linux/
          - 
          :csv: /media/attach/data/git/working/linux.dat
        :git:
          :url:
          - git://149.20.4.72/pub/scm/
          -
        :description:
          :url:
          - http://149.20.4.72/?a=rss;p=
          -
          :find:
            :xpath: /rss/channel/description
            :nslist:
        :origin:
          :default: .
          :regexp: '^$'
        :list:
          :url: http://149.20.4.72/?a=project_index
          :regexp: ^[^\s]*
          :only:
          - linux/kernel/git/torvalds/linux.git

Each server in the _:servers_ section has a basic structure containing its host 
name (_:host_), its ip (_:ip_), the base dir where the git repositories shall be
placed for that server (_:data/:dir_) and what is the file for the generated CSV
(_:data/:csv). Note that _:data/:dir_ is an array with two elements, with the
second one empty. This is a way to programatically wrap the path of each project
with a prefix and a suffix, which are the first and the second elements of the
array, respectively. The same applies to all other two-elements-array in the
config file.

_:git/:url_ has the base url of the git repositories. _:description_ has the url
for the description of the projects (_:url_) and the xpath expression to
retrieve it (_:description/:find/:xpath_) in the given namespace
(_:description/:find/:nslist_)

_:origin_ is a string that will be put into the database table as the origin
column. It will defaults to the content of _:origin/:default_ if no expression
is found from the project name using the regular expression from
_:origin/:regexp_.

:list_ relates to the list of projects from that server. A url is used
to get the list (_:list/:url_) and a regular expression is used to select the
part of the url to that project (_:list/:regexp_).

The _:list/:only_ is an option to ignore the list provided from the _:list/:url_
to select only the projects from its list.

      :android:
        (...)
        :list:
          (...)
          :deny:
          - kernel/experimental.git
          - kernel/linux-2.6.git
        :instances:
          kernel/common.git:
            :dir: /home/rafael/media/git-data/linux/linux/kernel/git/torvalds/linux.git
            :range: ..remotes/common/android-3.0
            :fork: true
          kernel/msm.git:
            :dir: /home/rafael/media/git-data/linux/linux/kernel/git/torvalds/linux.git
            :range: ..remotes/msm/android-msm-2.6.35
            :fork: true
          kernel/omap.git:
            :dir: /home/rafael/media/git-data/linux/linux/kernel/git/torvalds/linux.git
            :range: ..remotes/omap/android-omap-3.0
            :fork: true
          kernel/qemu.git:
            :dir: /home/rafael/media/git-data/linux/linux/kernel/git/torvalds/linux.git
            :range: ..remotes/qemu/android-goldfish-2.6.29
            :fork: true
          kernel/samsung.git:
            :dir: /home/rafael/media/git-data/linux/linux/kernel/git/torvalds/linux.git
            :range: ..remotes/samsung/android-samsung-2.6.35
            :fork: true
          kernel/tegra.git:
            :dir: /home/rafael/media/git-data/linux/linux/kernel/git/torvalds/linux.git
            :range: ..remotes/tegra/android-tegra-2.6.39
            :fork: true

The _:list/:deny_ is a list of projects that are not going to be included into
the list of projects.

The _:instances_ section alters the default values generated from
tools/configure.rb to the ones in each of the given instances.

    :conflicts: conflicts.yaml
    :emailfix: emailfix.yaml
    :list: list.yaml

Finally some additional files are used, which are the _:conflicts_, _:emailfix_
and _:list_. _:emailfix_ is a dictionary of fixes of strings that are supposed
to be email string, but for some reason are not a valid. _:list_ is the list of
projects and some metadata about them. _:conflicts_ is a file of conflicts from
associating a company to an email domain and it's related to the CrunchBase
data.


Acknowledgements
================

This project was possible with the tutorship of [Carlos Denner dos Santos Jr]
(denner@ime.usp.br) and the financial support from
[Centro de Competência de Software Livre](http://ccsl.ime.usp.br/).

