===========
omd-formula
===========

Salt Stack Formula to set up and configure the Open Monitoring Distribution (OMD)

NOTICE BEFORE YOU USE
---------------------

* This formula aims to follow the conventions and recommendations described at http://docs.saltstack.com/en/latest/topics/development/conventions/formulas.html#conventions-formula and http://docs.saltstack.com/en/latest/topics/best_practices.html

TODO
----

* define parents when applicable (e.g. VMs)
* provide CMK config examples (``contrib/``)

Instructions
------------

1. Add this repository as a `GitFS <http://docs.saltstack.com/topics/tutorials/gitfs.html>`_ backend in your Salt master config.

2. Configure your Pillar top file (``/srv/pillar/top.sls``) and your pillars, see pillar.example.sls

3. Include this Formula within another Formula or simply define your needed states within the Salt top file (``/srv/salt/top.sls``).

Available states
----------------

.. contents::
    :local:

``omd``
~~~~~~~
Installs a repo containing OMD packages (optionally)

``omd.cmkagent``
~~~~~~~~~~~~~~~~
Sets a Check_MK agent up

``omd.server``
~~~~~~~~~~~~~~
Manages an OMD instance with all its versions and sites

Additional resources
--------------------

**Apache httpd vhosts**

If you don't want to truncate zzz_omd.conf which includes the default Apache httpd vhost config, overwrite config.manage in your pillars. But if you want to manage the vhost(s) manually use `a httpd formula <https://github.com/bechtoldt/httpd-formula>`_ to manage httpd's vhosts.

**Check_MK Configuration**

This formula doesn't make use of Check_MK's Web Administration Tool (WATO ). The reason for this is that WATO has a confusing way (at least for me) of saving MK configuration files. Settings (like global settings in global.mk) aren't ordered in a specific order so it's often hard to generate *WATO-like* MK files.

This means to you that you A) should disable WATO in Multisite and B) configure all OMD/ Check_MK components manually including user DB, contacts, roles and more. Most of these will be possible with this formula.

Templates
---------

Some states/ commands may refer to templates which aren't included in the files folder (``omd/files``). Take a look at ``contrib/`` (if present) for e.g. template examples and place them in separate file roots (e.g. Git repository, refer to `GitFS <http://docs.saltstack.com/topics/tutorials/gitfs.html>`_) in your Salt master config.

Formula Dependencies
--------------------

None

Contributions
-------------

Contributions are always welcome. All development guidelines you have to know are

* write clean code (proper YAML+Jinja syntax, no trailing whitespaces, no empty lines with whitespaces, LF only)
* set sane default settings
* test your code
* update README.rst doc

Salt Compatibility
------------------

Tested with:

* Salt Development Version (should work with 2014.1.x mostly too)

OS Compatibility
----------------

Tested with:

* GNU/ Linux Debian Wheezy
