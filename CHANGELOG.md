Change Log
==========

[v0.6.0-a8][] (2019-01-18)
--------------------------

- Bug Fixes:
    + backport for v0.6.0-a8: windows: git clone '' (with the quote) trigger fatal error #596
    + git sync: tag not found bug should be fixed #593

Details: https://github.com/teracyhq/dev/milestone/17?closed=1


[v0.6.0-a7][] (2019-01-17)
--------------------------

- Improvements:
    + should release v0.6.0-a7 with proper fix for git sync with different system locales #590

Details: https://github.com/teracyhq/dev/milestone/16?closed=1


[v0.6.0-a6][] (2018-12-21)
--------------------------

- Bug Fixes:
    + Should support multi language for git_sync #580

Details: https://github.com/teracyhq/dev/milestone/15?closed=1


[v0.6.0-a5][] (2018-11-16)
--------------------------

- Features:
    + should support register processors, configurators with weight #497
    + should support "remote" location config from Location::GitSynch #502
    + should add support for extension dependency validation #498
    + should support \_id update with deprecation #501
    + should mask specified secret values within log messages #492

- Improvements:
    + gitsynch should not auto update repos when there are untracked changes #469
    + should always use Util.true? for converting boolean values #506
    + should add "nodes" generated from chef provisioner to the .gitignore file #503
    + should have a way to display the final settings in yaml format for the debug log level #505
    + should not display log tracing when the log level is not debug #533
    + should use \_id: "kernel-core" instead of \_id: "0" for the core extension config #545
    + location sync should support offline mode #526
    + gitsynch should check if git clone success or not to inform users about errors #508
    + should make sure gitsynch support http authentication #464
    + should run location sync with specific vagrant sub commands only to improve responsiveness #531

- Bug Fixes:
    + should sync teracy-dev, sync teracy-dev-entry before syncing extensions #487
    + something wrong with the plugin installation when no plugin is installed #486
    + plugin should validate plugin params before proceeding #493
    + wrong order in extensions config merge #499
    + should make sure settings is immutable after being built #462
    + failed to sync teracy-dev-entry #523
    + load_yaml_file should use YAML.load_file instead of YAML.load #529
    + teracy-dev-entry should update its git remote repos even if sync is false #535
    + "fatal: No such remote:" should not be displayed when a new git remote repo config is added #534

- Tasks:
    + should update README with "how to develop" section #470
    + logger should be `TeracyDev::Config::Manager` instead of `TeracyDev::Processors::Manager` #514
    + gitsynch on Windows did not work as expected with private git repos #509
    + update docs for "win32/registry.rb:185:in "encode!': code converter not found (UTF-16LE to Windows-1258) (Encoding::ConverterNotFoundError)" error on Windows #544

Details: https://github.com/teracyhq/dev/milestone/12?closed=1


[v0.6.0-a4][] (2018-09-15)
--------------------------

- Tasks:
    + clean up config_default.yaml support for extensions

- Bug Fixes:
    + fix Util.exist always return true if it is String


Details: https://github.com/teracyhq/dev/milestone/11?closed=1


[v0.6.0-a3][] (2018-09-14)
--------------------------

- Improvements:
    + add tracing when something wrong
    + improve logging by adding filter, tracing
    + simply the config override mechanism and use teracy-dev-entry only for override

- Bug Fixes:
    + warn log did not display the yellow color


Details: https://github.com/teracyhq/dev/milestone/10?closed=1


[v0.6.0-a2][] (2018-08-26)
--------------------------

Bug fix for gitsynch tag


Details: https://github.com/teracyhq/dev/milestone/9?closed=1


[v0.6.0-a1][] (2018-08-25)
--------------------------

Completely new teracy-dev with initial alpha-1 version


Details: https://github.com/teracyhq/dev/milestone/7?closed=1



[v0.5.0-c2][] (2018-01-16)
--------------------------

new important critical features, bug fixes and improvements.

- Bugs
    + provide hot fix for docker-compose installation bug

- New features
    + select the right bridged network interface automatically


Details: https://github.com/teracyhq/dev/milestone/8?closed=1


[v0.5.0-c1][] (2017-07-27)
--------------------------

new features, bug fixes and improvements, add more documents and make it more stable.

- Bugs
    + fixed the problem on windows with chocolate and bash-completion.
    + upgraded and pin down with newest chef version.
    + fixed problem with rsync_args (thanks to @smxsm).

- Improvements
    + added some useful alias (ctop, httpie-jwt-auth).
    + used lastest docker-compose version by default.

- New features
    + added [support project base json config]
    + json config support for docker registry login


Details: https://github.com/teracyhq/dev/milestone/5?closed=1


[v0.5.0-b3][] (2017-04-12)
--------------------------

Fix the Chef version critical bug

Details: https://github.com/teracyhq/dev/milestone/6?closed=1


[v0.5.0-b2][] (2017-03-09)
--------------------------

bug fixes and improvements, make it more stable.

- Bugs
    + fix the script to install on Ubuntu
    + fix specific docker config
    + fix the network setting problem related to the default bridge interface list

- Improvements
    + add `$ vagrant global-status` command to the basic guide
    + use vX.X.X for all things related to versions
    + mention about VT-X/AMD-v problem for the default ubuntu 64-bit guest OS
    + display the oudated videos at the end of instruction instead of the beginning
    + use git reset --hard to update teracy-dev instead of git pull

- Tasks
    + use latest docker-compose 1.11.2 as default
    + contribution list is updated


Details: https://github.com/teracyhq/dev/milestone/4?closed=1


[v0.5.0-b1][] (2017-02-14)
--------------------------

The next milestone release includes:

- lots of features and improvements
- project clean up
- higher performance on Windows, especially file syncing
- Docker workflow out of the box, can use any versions of docker, docker-compose
- support all type of provisioners configurations
- use public_network by default
- config override the object within array
- Vagrantfile-ext support
- use rsync as the default sync mechanism (with the support from vagrant-gatling-rsync and
  vagrant-rsync-back plugins)
- reverse proxy support with /etc/hosts update for auto domain management
- auto vagrant plugins installation support


Details: https://github.com/teracyhq/dev/milestone/1?closed=1


[v0.4.0][] (2015-05-15)
----------------------

The next milestone release includes:

- add .bat automatic installation script
- multiple python versions
- LAMP, LEMP stack support
- Ruby on Rails stack support
- Built-in IDE (codebox) support
- Improve Vagrant configuration
- Support optional sync methods along with default sharing folder method
- Documentation improvements
- Bug fixes and improvements


Details:

- Sub-task
    + [DEV-126] - Fix foodcritic violations when upgrade
    + [DEV-201] - update php dev guide
    + [DEV-214] - update databases guide
    + [DEV-216] - update nodejs dev guide
    + [DEV-217] - update python dev guide


- Bug
    + [DEV-93] - virtualenvwrapper not work
    + [DEV-101] - nosetests does not work well on vagrantbox
    + [DEV-109] - permission denied of .virtualenvs on windows
    + [DEV-121] - No "source" of install_method for mongodb recipe
    + [DEV-134] - don't reinstall php when $ vagrant reload --provision
    + [DEV-136] - fix Could not find mixlib-shellout-1.6.0 in any of the sources error on travis-ci
    + [DEV-151] - git installer did not work properly
    + [DEV-161] - problems related to virtualbox guest addition for v0.4.0
    + [DEV-162] - auto generated key pair by vagrant 1.7.1 did not work with `$ vagrant ssh`
    + [DEV-168] - fix apache2 cache bug
    + [DEV-171] - .htaccess not working
    + [DEV-193] - Failed to install `amo-validator` via pip globals config
    + [DEV-210] - Need to set default date.timezone = UTC for php.ini


- Improvement
    + [DEV-76] - Adding loading indicator bar to .bat installation script
    + [DEV-83] - Support python.version config
    + [DEV-97] - Improve Getting Started
    + [DEV-99] - Reduce the provision time of base box v0.3.0 on v0.3.0
    + [DEV-111] - improve java, maven cookbook
    + [DEV-118] - Support Linux, Apache, MySQL, PHP (LAMP) stack to deploy PHP applications
    + [DEV-120] - [DOC] Improve the section Ruby training
    + [DEV-143] - add support to use nginx instead of default apache server
    + [DEV-157] - Add all options for Vagrantfile config.vm settings
    + [DEV-169] - remove "git" from vagrant_config.json's chef_recipes
    + [DEV-176] - Don't force apt-get update by default on mysql recipe
    + [DEV-177] - Avoid using vagrant 1.7.2 for now, use 1.7.1 instead
    + [DEV-188] - Support for Ruby on Rails, Sinatra development
    + [DEV-189] - make sure to support provisioning from a clean ubuntu base box
    + [DEV-190] - Enable ruby by default
    + [DEV-195] - By default use fmode=755 instead of fmode=644 for workspace directory
    + [DEV-198] - Support optional sync methods along with default sharing folder method
    + [DEV-222] - support remote access for MongoDB
    + [DEV-223] - Support for Rails development with PostgreSQL's hstore extension
    + [DEV-225] - make sure apt-get-update-periodic should work

- New Feature
    + [DEV-9] - multiple python versions on python_dev VM
    + [DEV-23] - Use tox for testing
    + [DEV-139] - Add support to install phpMyAdmin
    + [DEV-146] - IDE running with vagrant
    + [DEV-155] - Add option to specify preferred ubuntu repository mirrors


- Task
    + [DEV-11] - useful sublimetext plugins and preferences configuration
    + [DEV-92] - Config support for VM customize
    + [DEV-96] - write docs how to use jira client on toolchain section
    + [DEV-98] - update workflow: git branching off section
    + [DEV-103] - update manual installation for dev
    + [DEV-119] - upgrade Gemfile and Berksfile
    + [DEV-124] - Update Workflow
    + [DEV-127] - Add "gulp" as global npm to install by default
    + [DEV-132] - add more vm_forwarded_ports config
    + [DEV-137] - Install some PHP applications to teracy-dev to make sure it works (wordpress, drupal, etc)
    + [DEV-138] - Fix violations foodcritic of apache recipe
    + [DEV-141] - update docs for v0.4.0
    + [DEV-142] - Upgrade and define the supported vagrant, virtualbox versions for v0.4.0
    + [DEV-144] - Write documentation how to develop chrome extenstion, firefox add-on with teracy-dev
    + [DEV-150] - upgrade default git from v2.0.0 to v2.2.1
    + [DEV-152] - Add `compass`, `foreman` to default global gems
    + [DEV-158] - upgrade cookbooks to latest stable versions
    + [DEV-170] - update automatic installation scripts
    + [DEV-172] - use default memory setting of vagrant instead of current 2048
    + [DEV-175] - Set default VM memory is 512MB instead of default 318MB
    + [DEV-180] - update the docs copyright year on the footer
    + [DEV-194] - update documentation how to use restview for .rst writing
    + [DEV-227] - release teracy-dev v0.4.0



[v0.3.0][] (2014-07-24)
----------------------

The next milestone release includes:

- Use teracy base box
- Support overriding vagrant configuration that is ignored by git
- Update workspace layout: `workspace/personal` and `workspace/readonly`
- Bat script to install virtualbox and vagrant automatically for Windows
- More dev platform support: Ruby, Node.js, Java, PHP
- Database support: mysql, mongodb, postgreSQL
- docs updated

Details:

- Bug
    + [DEV-6]  - vm.ssh.forward_agent does not work on windows host
    + [DEV-63] - failed to vagrant up at child directory of teracy-dev
    + [DEV-75] - Fix Doc Syntax Error
    + [DEV-81] - update code.teracy.org instead of teracy.com to ssh known hosts
    + [DEV-93] - virtualenvwrapper not work

- Improvement
    + [DEV-7]  - Don't mess custom configuration into managed versioned file
    + [DEV-45] - automatic docs deploy of 0.2.0 instead of v0.2.0
    + [DEV-57] - Update workspace layout
    + [DEV-60] - Vagrant Config override instead of overwrite
    + [DEV-62] - Update some vagrant config attributes
    + [DEV-64] - warning when vagrant_config_override.json is malformed
    + [DEV-65] - Support deep key override
    + [DEV-77] - Make sure consistent recipe file names (use _ instead of -)
    + [DEV-80] - Make sure git usage from vagrant box and host work well together
    + [DEV-82] - Add support for ruby.globals
    + [DEV-84] - Support ruby.version config
    + [DEV-88] - Support apt package installer configuration

- New Feature
    + [DEV-49] - node.js dev support
    + [DEV-56] - Create .bat file to install vagrant and virtualbox automatically on Windows
    + [DEV-61] - Support PHP
    + [DEV-85] - Support mongodb
    + [DEV-86] - Support mysql db development
    + [DEV-87] - Support postgreSQL development

- Task
    + [DEV-47] - review and update docs
    + [DEV-51] - Improve and Create visual guide for workflow
    + [DEV-54] - Upgrade support for vagrant and virtualbox
    + [DEV-55] - Create Teracy base boxes for v0.3.0
    + [DEV-59] - install "bower" by default for node.js support
    + [DEV-66] - upgrade git
    + [DEV-69] - Upgrade npm for teracy-dev
    + [DEV-71] - Update docs to make sure it's the most up to date
    + [DEV-72] - remove known_hosts file
    + [DEV-73] - remove system-python recipe


[v0.2.0][] (2013-11-20)
----------------------

The next milestone release: extend CHEF, better support for python platform development

- Migration from v0.1.0 to v0.2.0
    + Vagrantfile: https://github.com/teracy-official/dev/commit/f8906c9d5d24951028a41f524e68463ea0bf32f8

- Sub-task
    + [DEV-25] - Define Python Coding Standards

- Bug
    + [DEV-5] - Bug when determining ubuntu

- New Feature
    + [DEV-31] - extend CHEF
    + [DEV-39] - Make sure gettext is available on demand
    + [DEV-42] - optional add pip index-url of teracy's public pypi

- Task
    + [DEV-1] - Project migration
    + [DEV-14] - define software semantic versioning
    + [DEV-16] - update the latest development of sphinx-deployment
    + [DEV-17] - update docs, resources after github issues migration
    + [DEV-18] - update workflow
    + [DEV-19] - update project-template
    + [DEV-20] - release process documentation
    + [DEV-22] - upgrade setuptools to 1.0
    + [DEV-26] - add interesting resources section
    + [DEV-28] - upgrade vagrant
    + [DEV-30] - use nature theme for docs instead of default one
    + [DEV-35] - upgrade to sphinx-deployment v0.2.0


[v0.1.0][] (2013-08-17)
----------------------

Release the first milestone

- Sub-task
    + [DEV-2] - release current deprecated teracy-dev to be 0.1.0

[v0.1.0]: https://issues.teracy.org/secure/ReleaseNote.jspa?projectId=10400&version=10000

[v0.2.0]: https://issues.teracy.org/secure/ReleaseNote.jspa?projectId=10400&version=10002

[v0.3.0]: https://issues.teracy.org/secure/ReleaseNote.jspa?projectId=10400&version=10702

[v0.4.0]: https://issues.teracy.org/secure/ReleaseNote.jspa?projectId=10400&version=11000

[v0.5.0-b1]: https://github.com/teracyhq/dev/milestone/1?closed=1

[v0.5.0-b2]: https://github.com/teracyhq/dev/milestone/4?closed=1

[v0.5.0-b3]: https://github.com/teracyhq/dev/milestone/6?closed=1

[v0.5.0-c1]: https://github.com/teracyhq/dev/milestone/5?closed=1

[v0.5.0-c2]: https://github.com/teracyhq/dev/milestone/8?closed=1

[support project base json config]: https://github.com/teracyhq/dev/issues/321

[v0.6.0-a1]: https://github.com/teracyhq/dev/milestone/7?closed=1
[v0.6.0-a2]: https://github.com/teracyhq/dev/milestone/9?closed=1
[v0.6.0-a3]: https://github.com/teracyhq/dev/milestone/10?closed=1
[v0.6.0-a4]: https://github.com/teracyhq/dev/milestone/11?closed=1
[v0.6.0-a5]: https://github.com/teracyhq/dev/milestone/12?closed=1
[v0.6.0-a6]: https://github.com/teracyhq/dev/milestone/15?closed=1
[v0.6.0-a7]: https://github.com/teracyhq/dev/milestone/16?closed=1
[v0.6.0-a8]: https://github.com/teracyhq/dev/milestone/17?closed=1
