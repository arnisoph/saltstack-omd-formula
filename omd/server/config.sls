#!jinja|yaml

{% from "omd/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('omd:lookup')) %}

include:
  - omd.server
  - omd.server.service
{#
{% for si in salt['pillar.get']('omd:server:sls_include', []) %}
  - {{ si }}
{% endfor %}

extend: {{ salt['pillar.get']('omd:server:sls_extend', '{}') }}
#}

{% for s in salt['pillar.get']('omd:sites', []) if s.ensure|default('running') in ['managed', 'running', 'stopped'] %}
  {% set omd = s.omd|default({}) %}
  {% set omdconfig = omd.config|default({}) %}
  {% set cmk = s.cmk|default({}) %}
  {% set cmkconfig = cmk.config|default({}) %}

# OMD specific configuration
  {% for k, v in omdconfig.items() %}
site_{{ s.name }}_setting_{{ k }}:
  cmd:
    - run
    - name: {{ datamap.omdbin.path|default('/usr/bin/omd') }} --verbose stop {{ s.name }} 1>/dev/null; {{ datamap.omdbin.path|default('/usr/bin/omd') }} --verbose config {{ s.name }} set '{{ k }}' '{{ v }}'
    - unless: {{ 'test "$(' ~ datamap.omdbin.path|default('/usr/bin/omd') ~ ' --verbose config ' ~ s.name ~ ' show ' ~ k ~ ')" = "' ~ v ~ '"'}}
    - require_in:
      - cmd: site_{{ s.name }}_startstop
    - watch_in:
      - cmd: site_{{ s.name }}_restart
  {% endfor %}


# Main configuration
  {% if 'main' in cmkconfig.manage|default(datamap.cmk.server.config.manage)|default([]) %}
    {% set f_ccma = cmkconfig.main|default({}) %}
site_{{ s.name }}_config_main:
  file:
    - managed
    - name: /omd/sites/{{ s.name }}/etc/check_mk/main.mk
    - source: {{ f_ccma.template_path|default('salt://omd/files/cmk/server/' ~ s.name ~ '/main.mk') }}
    - template: {{ datamap.cmk.server.config.main.template_renderer|default('jinja') }}
    - mode: {{ datamap.cmk.server.config.main.mode|default(644) }}
    - user: {{ datamap.cmk.server.config.main.user|default(s.name) }}
    - group: {{ datamap.cmk.server.config.main.group|default(s.name) }}
    - watch_in:
      - cmd: site_{{ s.name }}_restart
  {% endif %}

  {% if 'main_wato_global' in cmkconfig.manage|default(datamap.cmk.server.config.manage)|default([]) %}
    {% set f_ccmawg = cmkconfig.main_wato_global|default({}) %}
site_{{ s.name }}_config_main_wato_global:
  file:
    - managed
    - name: /omd/sites/{{ s.name }}/etc/check_mk/conf.d/wato/global.mk
    - source: {{ f_ccmawg.template_path|default('salt://omd/files/cmk/server/' ~ s.name ~ '/main_global.mk') }}
    - template: {{ datamap.cmk.server.config.multisite.template_renderer|default('jinja') }}
    - mode: {{ datamap.cmk.server.config.main_wato_global.mode|default(660) }}
    - user: {{ datamap.cmk.server.config.main_wato_global.user|default(s.name) }}
    - group: {{ datamap.cmk.server.config.main_wato_global.group|default(s.name) }}
    - watch_in:
      - cmd: site_{{ s.name }}_restart
  {% endif %}


# Multisite specific configuration
  {% if 'multisite' in cmkconfig.manage|default(datamap.cmk.server.config.manage)|default([]) %}
    {% set f_ccmu = cmkconfig.multisite|default({}) %}
site_{{ s.name }}_config_multisite:
  file:
    - managed
    - name: /omd/sites/{{ s.name }}/etc/check_mk/multisite.mk
    - source: {{ f_ccmu.template_path|default('salt://omd/files/cmk/server/' ~ s.name ~ '/multisite.mk') }}
    - template: {{ datamap.cmk.server.config.multisite.template_renderer|default('jinja') }}
    - mode: {{ datamap.cmk.server.config.multisite.mode|default(644) }}
    - user: {{ datamap.cmk.server.config.multisite.user|default(s.name) }}
    - group: {{ datamap.cmk.server.config.multisite.group|default(s.name) }}
    - watch_in:
      - cmd: site_{{ s.name }}_restart
  {% endif %}

  {% if 'multisite_wato_global' in cmkconfig.manage|default(datamap.cmk.server.config.manage)|default([]) %}
    {% set f_ccmuwg = cmkconfig.multisite_wato_global|default({}) %}
site_{{ s.name }}_config_multisite_wato_global:
  file:
    - managed
    - name: /omd/sites/{{ s.name }}/etc/check_mk/multisite.d/wato/global.mk
    - source: {{ f_ccmuwg.template_path|default('salt://omd/files/cmk/server/' ~ s.name ~ '/multisite_global.mk') }}
    - template: {{ datamap.cmk.server.config.multisite.template_renderer|default('jinja') }}
    - mode: {{ datamap.cmk.server.config.multisite_wato_global.mode|default(660) }}
    - user: {{ datamap.cmk.server.config.multisite_wato_global.user|default(s.name) }}
    - group: {{ datamap.cmk.server.config.multisite_wato_global.group|default(s.name) }}
    - watch_in:
      - cmd: site_{{ s.name }}_restart
  {% endif %}

# CMK Agent/ SSH specific configuration
omd_user_sshdir_{{ s.name }}:
  file:
    - directory
    - name: /omd/sites/{{ s.name }}/.ssh
    - mode: 700
    - user: {{ s.name }}
    - group: {{ s.name }}

  {% if salt['file.file_exists']('/omd/sites/' ~ s.name ~ '/.ssh/id_rsa.pub') == False %}
monitoring_user_ssh_keypair_{{ s.name }}:
  cmd:
    - run
    - name: /usr/bin/ssh-keygen -q -b {{ datamap.cmk.agent.user.ssh_bits|default('8192') }} -t rsa -f /omd/sites/{{ s.name }}/.ssh/id_rsa -N '' -C ''
    - user: {{ s.name }}
  {% endif %}
{% endfor %}
