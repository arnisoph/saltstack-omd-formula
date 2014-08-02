#!jinja|yaml

{% from 'omd/defaults.yaml' import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('omd:lookup')) %}

include:
  - omd

{% if datamap.cmk.agent.user.manage|default(True) %}
monitoring_user:
  user:
    - present
    - name: {{ datamap.cmk.agent.user.name|default('monitoring') }}
    - groups: {{ datamap.cmk.agent.user.groups|default(['monitoring']) }}
    - optional_groups: {{ datamap.cmk.agent.user.optional_groups|default(['monitoring']) }}
    - home: {{ datamap.cmk.agent.user.home|default('/home/monitoring') }}
    - shell: {{ datamap.cmk.agent.user.shell|default('/bin/bash') }}
    - createhome: True
    - system: True
    - require:
      - group: monitoring_user
  group:
    - present
    - name: {{ datamap.cmk.agent.group.name|default('monitoring') }}
    - system: True
  file:
    - directory
    - name: {{ datamap.cmk.agent.user.home|default('/home/monitoring') }}
    - mode: 750
    - user: {{ datamap.cmk.agent.user.name|default('monitoring') }}
    - group: {{ datamap.cmk.agent.group.name|default('monitoring') }}
    - require:
      - user: monitoring_user

  {% set cmp = salt['pillar.get']('omd:salt:collect_monitoring_pubkeys', {}) %}
  {% for k, v in salt['publish.publish'](cmp.tgt|default('*'), cmp.fun|default('ssh.user_keys'), cmp.arg, cmp.expr_form|default('glob')).items() if k|length > 0 %}
ssh_auth_monitoring_{{ v['mbp100']['id_rsa.pub'][-20:]|replace('\n', '') }}: {# TODO: this will break when several keys have been found instead of only one. FIXME! #}
  ssh_auth:
    - present
    - name: command="{{ datamap.cmk.agent.config.script.path|default('/usr/bin/check_mk_agent') }}" {{ v['mbp100']['id_rsa.pub']|replace('\n', '') }}
    - user: {{ datamap.cmk.agent.user.name|default('monitoring') }}
    - enc: ssh-rsa
  {% endfor %}
{% endif %}
