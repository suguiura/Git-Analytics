
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
- git
- perl
- ruby
- libxml (libxml.rubyforge.org)


How to use
==========

The full process of evaluating the data includes generating config files,
downloading bare git files and parsing them is described in the following steps.

The configuration file is described further below.

Generating configuration files
------------------------------

All of the required metadata about projects is obtained and generated in this
section. Given a small set of data about a server hosting git repositories,
a list of projects is downloaded, obtaining and expanding the metadata for each
of those projects. This generated metadata is, then, saved into a YAML file.
The script for this task has the following syntax:

    ruby script/generate.rb <config.yaml>

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

    :data:
      :dir:
      - data/linux/
      - 
    :git:
      :url:
      - git://git.kernel.org/pub/scm/
      -
    :description:
      :url:
      - http://git.kernel.org/?a=rss;p=
      -
      :find:
        :xpath: /rss/channel/description
        :nslist:
    :list:
      :url: http://git.kernel.org/?a=project_index
      :regexp: ^[^\s]*
      :file: config/list-linux.yaml
      :deny:
      - 
      :only:
      - linux/kernel/git/torvalds/linux.git

The main sections used in the tool, and specified in the configuration file are
_data_, _git_, _description_ and _list_.

_Data_ represents the work data, so far
represented only by the (to be downloaded) git mirror files, and the only
subsection is _dir_, which is where the data is going to be saved. It is an
array in order to build a path according to a parameter, which is given by
entries in the _list_ section, explained below. Two other subsections are also
arrays, due to the same reason: _git/url_ and _description/url_.

The _git_ section contains informations about git repositories.

The _description_ section represents data about project description, since it's
not really downloaded from servers when they are cloned by the git tool.
_description/find_ subsection has two other subsections, _xpath_ and _nslist_.
_xpath_ is a XML xpath, selecting the description about the project from a XML
file provided from the _description/url_, and the _nslist_ is the list of XML
namespaces used by _xpath_.

Finally, the _list_ section contain informations about the list of projects.
It has the _url_ of the list, and a _regexp_ (regular expression) subsection to
extract the essencial information from the file downloaded from the _url_
subsection. _file_ is the filename where the YAML file about the projects will
be saved. The last two subsections, _deny_ and _only_, are arrays, denying and
selecting projects, respectively. When _only_ is specified, only projects in
this subsection is evaluated. The projects in _deny_ will be excluded from the
list.

TODO: to include the _instances_ section and the generated configuration file.


Acknowledgements
================

This project was possible with the tutorship of [Carlos Denner dos Santos Jr]
(denner@ime.usp.br) and the financial support from
[Centro de Competência de Software Livre](http://ccsl.ime.usp.br/).

