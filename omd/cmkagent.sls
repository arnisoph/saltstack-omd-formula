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

#TODO plugins dir + plugins
