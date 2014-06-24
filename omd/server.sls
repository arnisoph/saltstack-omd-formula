#!jinja|yaml

{% from "omd/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('omd:lookup')) %}

include:
  - omd
{% for si in salt['pillar.get']('omd:server:sls_include', []) %}
  - {{ si }}
{% endfor %}

extend: {{ salt['pillar.get']('omd:server:sls_extend', '{}') }}

{% for ver in salt['pillar.get']('omd:versions', []) %}
  {% set ensure = ver.ensure|default('managed') %}
  {% set srcuri = ver.srcuri|default('http://files.omdistro.org/releases/' ~ datamap.pkg_default_os ~ '/' ~ ver.filename|default('omd_NOVERSIONSET') ~ '.' ~ grains.get('oscodename') ~ '_' ~ grains.get('osarch') ~ '.' ~ datamap.pkg_default_ext) %}

omd_version_{{ ver.name }}:
  pkg:
    {% if ensure in ['managed', 'running', 'stopped'] %}
    - installed
    {% else %}
    - absent
    {% endif %}
    - name: {{ ver.name }}
  {% if ver.pkgprovider|default('standard') == 'src' and ensure not in ['removed'] %}
    - sources:
      - {{ ver.name }}: {{ srcuri }}
  {% endif %}
{% endfor %}

{% if 'zzz_omd' in datamap.config.manage|default([]) %}
zzz_omd:
  file:
    - managed
    - name: {{ datamap.config.zzz_omd.path }}
    - mode: 644
    - user: root
    - group: root
    - contents: |
        {{ '#' }} OMD Apache vhosts are defined elsewhere
{% endif %}

{% for s in salt['pillar.get']('omd:sites', []) %}
  {% set ensure = s.ensure|default('running') %}

  {% if ensure in ['managed', 'running', 'absent', 'stopped'] %}
site_{{ s.name }}_createremove:
  cmd:
    - run
    {% if ensure in ['managed', 'running', 'stopped'] %}
    - name: {{ datamap.omdbin.path|default('/usr/bin/omd') }} --verbose create {{ s.name }}
    - unless: {{ datamap.omdbin.path|default('/usr/bin/omd') }} version {{ s.name }}
    {% elif ensure in ['absent'] %}
    - name: {{ datamap.omdbin.path|default('/usr/bin/omd') }} --verbose --force rm {{ s.name }}
    - onlyif: {{ datamap.omdbin.path|default('/usr/bin/omd') }} version {{ s.name }}
    {% endif %}
  {% endif %}

  {% if ensure in ['managed', 'running', 'stopped'] %}
    {% set config = s.config|default({}) %}

    {% for k, v in config.items() %}
site_{{ s.name }}_setting_{{ k }}:
  cmd:
    - run
    - name: {{ datamap.omdbin.path|default('/usr/bin/omd') }} --verbose stop {{ s.name }} 1>/dev/null; {{ datamap.omdbin.path|default('/usr/bin/omd') }} --verbose config {{ s.name }} set '{{ k }}' '{{ v }}'
    - unless: {{ 'test "$(' ~ datamap.omdbin.path|default('/usr/bin/omd') ~ ' --verbose config ' ~ s.name ~ ' show ' ~ k ~ ')" = "' ~ v ~ '"'}}
    {% endfor %}

site_{{ s.name }}_startstop:
  cmd:
    - run
    {% if ensure in ['managed', 'running'] %}
    - name: {{ datamap.omdbin.path|default('/usr/bin/omd') }} start {{ s.name }}
    - unless: {{ datamap.omdbin.path|default('/usr/bin/omd') }} status {{ s.name }}
    {% elif ensure in ['stopped'] %}
    - name: {{ datamap.omdbin.path|default('/usr/bin/omd') }} stop {{ s.name }}
    - onlyif: {{ datamap.omdbin.path|default('/usr/bin/omd') }} status {{ s.name }}
    {% endif %}

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
  {% endif %}
{% endfor %}