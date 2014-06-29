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

# OMD site configuration
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


# CMK main configuration
  {% for f in cmkconfig.main.manage|default(datamap.cmk.server.config.main.manage)|default([]) %}
    {% set f_p = cmkconfig.main[f]|default({}) %}
    {% set f_d = datamap.cmk.server.config.main[f]|default({}) %}
site_{{ s.name }}_config_main_{{ f }}:
  file:
    - managed
    - name: /omd/sites/{{ s.name }}/etc/check_mk/{{ f_p.relpath|default(f_d.relpath)|default('conf.d/' ~ f ~ '.mk') }}
    - source: {{ f_p.template_path|default('salt://omd/files/cmk/server/' ~ s.name ~ '/main/' ~ f ~ '.mk') }}
    - template: {{ f_d.template_renderer|default('jinja') }}
    - mode: {{ f_d.mode|default(660) }}
    - user: {{ f_d.user|default(s.name) }}
    - group: {{ f_d.group|default(s.name) }}
    - defaults:
        site: {{ s }}
    - watch_in:
      - cmd: site_{{ s.name }}_restart
  {% endfor %}

# CMK multisite configuration
  {% for f in cmkconfig.multisite.manage|default(datamap.cmk.server.config.multisite.manage)|default([]) %}
    {% set f_p = cmkconfig.multisite[f]|default({}) %}
    {% set f_d = datamap.cmk.server.config.multisite[f]|default({}) %}
site_{{ s.name }}_config_multisite_{{ f }}:
  file:
    - managed
    - name: /omd/sites/{{ s.name }}/etc/check_mk/{{ f_p.relpath|default(f_d.relpath)|default('multisite.d/' ~ f ~ '.mk') }}
    - source: {{ f_p.template_path|default('salt://omd/files/cmk/server/' ~ s.name ~ '/multisite/' ~ f ~ '.mk') }}
    - template: {{ f_d.template_renderer|default('jinja') }}
    - mode: {{ f_d.mode|default(660) }}
    - user: {{ f_d.user|default(s.name) }}
    - group: {{ f_d.group|default(s.name) }}
    - defaults:
        site: {{ s }}
    - watch_in:
      - cmd: site_{{ s.name }}_restart
  {% endfor %}

# CMK notification plugins
  {% for f in cmkconfig.notify.manage|default(datamap.cmk.server.config.notify.manage)|default([]) %}
    {% set f_p = cmkconfig.notify[f]|default({}) %}
    {% set f_d = datamap.cmk.server.config.notify[f]|default({}) %}
site_{{ s.name }}_deploy_notifyplugin_{{ f }}:
  file:
    - managed
    - name: /omd/sites/{{ s.name }}/local/share/check_mk/notifications/{{ f_p.relpath|default(f_d.relpath)|default(f) }}
    - source: {{ f_p.template_path|default('salt://omd/files/cmk/server/' ~ s.name ~ '/notify/' ~ f) }}
    - template: {{ f_d.template_renderer|default('jinja') }}
    - mode: {{ f_d.mode|default(755) }}
    - user: {{ f_d.user|default(s.name) }}
    - group: {{ f_d.group|default(s.name) }}
  {% endfor %}

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
