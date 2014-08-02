#!jinja|yaml

{% from "omd/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('omd:lookup')) %}

include:
  - omd
  - omd._user_cmkagent

# CMK Agent Directories
{% for i in datamap.cmk.agent.config.manage_dir|default([]) %}
  {% set d = datamap.cmk.agent.config[i] %}
cmk_agent_dir_{{ i }}:
  file:
    - directory
    - name: {{ d.path }}
    - makedirs: True
    - mode: {{ d.mode|default(750) }}
    - user: {{ d.user|default(datamap.cmk.agent.user.name)|default('monitoring') }}
    - group: {{ d.group|default(datamap.cmk.agent.group.name)|default('monitoring') }}
{% endfor %}

# CMK Agent Files
{% for i in datamap.cmk.agent.config.manage_file|default([]) %}
  {% set f = datamap.cmk.agent.config[i] %}
cmk_agent_file_{{ i }}:
  file:
    - managed
    - name: {{ f.path }}
    - source: {{ f.template_path|default('salt://omd/files/cmk/agent/' ~ i) }}
    - mode: {{ f.mode|default(755) }}
    - user: {{ f.user|default(datamap.cmk.agent.user.name)|default('root') }}
    - group: {{ f.group|default(datamap.cmk.agent.group.name)|default('root') }}
    - watch_in:
      - module: reinventory_host
{% endfor %}

{% set sr = salt['pillar.get']('omd:salt:send_reinventory', {}) %}
#TODO use reactor ?!
reinventory_host:
  module:
    - wait
    - name: publish.publish
    - opts:
      tgt: {{ sr.tgt }}
      m_fun: {{ sr.m_fun|default('cmd.run') }}
      arg:
        - runas={{ salt['pillar.get']('omd:cmk:agent:site', 'sitenotsetinpillars') }}
        - shell=/bin/bash
        - cmd="check_mk -II --cleanup-autochecks --no-cache {{ salt['grains.get']('fqdn') }} && check_mk -O"
      expr_form: {{ sr.expr_form|default('glob') }}
