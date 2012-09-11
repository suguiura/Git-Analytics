
Git Analytics
=============

Git Analytics is a set of tools for downloading and parsing publicly available
git repositories metadata.

The tools were created as a part of a research at Instituto de Matemática e
Estatística.


Dependencies
------------

- [linux](http://kernel.org/)
- [git](http://git-scm.com/)
- [ruby 1.9](http://ruby-lang.org/)

### Gems

- [activerecord](https://rubygems.org/gems/activerecord)
- [libxml](http://rubygems.org/gems/libxml-ruby)
- [domainatrix](http://rubygems.org/gems/domainatrix)
- [email_veracity](http://rubygems.org/gems/email_veracity)
- [sqlite3](http://rubygems.org/gems/sqlite3)


How to use
----------

The full process of evaluating the data includes generating a list of
repositories (config/list.yaml) from the initial config file
(config/general.yaml), downloading the bare git files from the repositories in
that list, parsing them and either printing data in the CSV format or generating
and populating a database, is described in the following section.

The configuration file is described further below.

### Generating the projects list file

After updating the config/general.yaml file (check its description bellow), run
the configure.rb to generate the config/list.yaml file (as defined in the
_:list_ ).

    ruby configure.rb <android|gnome|linux> (<android|gnome|linux> (...))

The config/list.yaml is a file that contains projects metadata which allows both
batch operations over them and customization of how the scripts should deal with
each of those projects.

It will also try to download the project descriptions for the projects.

### Download the git data

From the config/list.yaml generated (and customized) above, a tool was created
to make the computer automatically download the git data from each project:

    ruby dl.rb <android|gnome|linux> (<android|gnome|linux> (...))

It will download the files and place them according to the data in
config/list.yaml.

### Generate the database

The data downloaded in the previous section can now be processed. Use the
following to parse the data:

    ruby analytics.rb <android|gnome|linux> (<android|gnome|linux> (...))

For each project, this script reads, parses and stores its commits log to the
database specified in config/general.yaml. Along the way, it also validates the
email strings. If it's not a valid one, it saves it in config/rawfix.yaml, along
with an email fix suggestion. The email will be saved as is in the database and
won't be fixed by this script.

It can also generate a CSV file.

### Parsing and associating emails with companies

Once the entries in config/rawfix.yaml are fixed, they can be parsed and
structured further, so the username and the domain of the email can be separated
from the raw email string, and be associated with the companies in the
CrunchBase database. This is done with the following script:

    ruby parse_email.rb

Since this is going to work only with the data within the database, it's doesn't
require a server to parse.

Configuration File
------------------

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
configure.rb to the ones in each of the given instances.

    :conflicts: config/conflicts.yaml
    :rawfix: config/rawfix.yaml
    :list: config/list.yaml

Finally some additional files are used, which are the _:conflicts_, _:emailfix_
and _:list_. _:emailfix_ is a dictionary of fixes of strings that are supposed
to be email string, but for some reason are not a valid. _:list_ is the list of
projects and some metadata about them. _:conflicts_ is a file of conflicts from
associating a company to an email domain and it's related to the CrunchBase
data.


Acknowledgements
----------------

This project was possible with the tutorship of [Carlos Denner dos Santos Jr]
(denner@ime.usp.br) and the financial support from
[Centro de Competência de Software Livre](http://ccsl.ime.usp.br/).


License
-------

GNU Affero General Public License v3
