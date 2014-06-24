#!jinja|yaml

{% from "omd/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('omd:lookup')) %}

include:
  - omd
  - omd._user_cmkagent

{% if datamap.cmk.agent.script.deploy|default(True) %}
script:
  file:
    - managed
    - name: {{ datamap.cmk.agent.script.path|default('/usr/bin/check_mk_agent') }}
    - source: {{ datamap.cmk.agent.script.template_path|default('salt://omd/files/check_mk_agent.linux') }}
    - mode: {{ datamap.cmk.agent.script.mode|default(750) }}
    - user: {{ datamap.cmk.agent.script.user|default('root') }}
    - group: {{ datamap.cmk.agent.script.group|default('root') }}
    - template: jinja
{% endif %}

{% if datamap.cmk.agent.waitmax.deploy|default(True) %}
waitmax:
  file:
    - managed
    - name: {{ datamap.cmk.agent.waitmax.path|default('/usr/bin/waitmax') }}
    - source: {{ datamap.cmk.agent.waitmax.template_path|default('salt://omd/files/waitmax') }}
    - mode: {{ datamap.cmk.agent.waitmax.mode|default(755) }}
    - user: {{ datamap.cmk.agent.waitmax.user|default('root') }}
    - group: {{ datamap.cmk.agent.waitmax.group|default('root') }}
{% endif %}

mkconfdir:
  file:
    - directory
    - name: {{ datamap.cmk.agent.config.mkconfdir.path|default('/etc/check_mk') }}
    - makedirs: True
    - mode: {{ datamap.cmk.agent.config.mkconfdir.mode|default(750) }}
    - user: {{ datamap.cmk.agent.config.mkconfdir.user|default(datamap.cmk.agent.user.name|default('monitoring')) }}
    - group: {{ datamap.cmk.agent.config.mkconfdir.group|default(datamap.cmk.agent.group.name|default('monitoring')) }}

mkcachedir:
  file:
    - directory
    - name: {{ datamap.cmk.agent.config.mkcachedir.path|default('/etc/check_mk/cache') }}
    - makedirs: True
    - mode: {{ datamap.cmk.agent.config.mkcachedir.mode|default(750) }}
    - user: {{ datamap.cmk.agent.config.mkcachedir.user|default(datamap.cmk.agent.user.name|default('monitoring')) }}
    - group: {{ datamap.cmk.agent.config.mkcachedir.group|default(datamap.cmk.agent.group.name|default('monitoring')) }}

libdir:
  file:
    - directory
    - name: {{ datamap.cmk.agent.config.libdir.path|default('/usr/lib/check_mk_agent') }}
    - makedirs: True
    - mode: {{ datamap.cmk.agent.config.libdir.mode|default(750) }}
    - user: {{ datamap.cmk.agent.config.libdir.user|default(datamap.cmk.agent.user.name|default('monitoring')) }}
    - group: {{ datamap.cmk.agent.config.libdir.group|default(datamap.cmk.agent.group.name|default('monitoring')) }}

pluginsdir:
  file:
    - directory
    - name: {{ datamap.cmk.agent.config.pluginsdir.path|default('/usr/lib/check_mk_agent/plugins') }}
    - makedirs: True
    - mode: {{ datamap.cmk.agent.config.pluginsdir.mode|default(750) }}
    - user: {{ datamap.cmk.agent.config.pluginsdir.user|default(datamap.cmk.agent.user.name|default('monitoring')) }}
    - group: {{ datamap.cmk.agent.config.pluginsdir.group|default(datamap.cmk.agent.group.name|default('monitoring')) }}

localdir:
  file:
    - directory
    - name: {{ datamap.cmk.agent.config.localdir.path|default('/usr/lib/check_mk_agent/local') }}
    - makedirs: True
    - mode: {{ datamap.cmk.agent.config.localdir.mode|default(750) }}
    - user: {{ datamap.cmk.agent.config.localdir.user|default(datamap.cmk.agent.user.name|default('monitoring')) }}
    - group: {{ datamap.cmk.agent.config.localdir.group|default(datamap.cmk.agent.group.name|default('monitoring')) }}

spooldir:
  file:
    - directory
    - name: {{ datamap.cmk.agent.config.spooldir.path|default('/etc/check_mk/spool') }}
    - makedirs: True
    - mode: {{ datamap.cmk.agent.config.spooldir.mode|default(750) }}
    - user: {{ datamap.cmk.agent.config.spooldir.user|default(datamap.cmk.agent.user.name|default('monitoring')) }}
    - group: {{ datamap.cmk.agent.config.spooldir.group|default(datamap.cmk.agent.group.name|default('monitoring')) }}

jobdir:
  file:
    - directory
    - name: {{ datamap.cmk.agent.config.jobdir.path|default('/var/lib/check_mk_agent/job') }}
    - makedirs: True
    - mode: {{ datamap.cmk.agent.config.jobdir.mode|default(750) }}
    - user: {{ datamap.cmk.agent.config.jobdir.user|default(datamap.cmk.agent.user.name|default('monitoring')) }}
    - group: {{ datamap.cmk.agent.config.jobdir.group|default(datamap.cmk.agent.group.name|default('monitoring')) }}
