#!jinja|yaml

{% from "omd/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('omd:lookup')) %}

{% if datamap.repo.manage|default(True) %}
  {% if salt['grains.get']('os_family') == 'Debian' %}
omd_repo:
  pkgrepo:
    - managed
    - name: {{ datamap.repo.debtype|default('deb') }} {{ datamap.repo.url }} {{ datamap.repo.dist }} {{ datamap.repo.comps }}
    - file: /etc/apt/sources.list.d/{{ datamap.repo.filename|default('omd') }}.list
    - key_url: {{ datamap.repo.keyurl }}
  {% endif %}
{% endif %}

{% for ver in salt['pillar.get']('omd:versions', []) %}
  {% set ensure = ver.ensure|default('installed') %}

  {% set srcuri = ver.srcuri|default('http://files.omdistro.org/releases/' ~ datamap.pkg_default_os ~ '/' ~ ver.filename|default('omd_NOVERSIONSET') ~ '.' ~ grains.get('oscodename') ~ '_' ~ grains.get('osarch') ~ '.' ~ datamap.pkg_default_ext) %}

omd_version_{{ ver.name }}:
  pkg:
    - {{ ensure }}
    - name: {{ ver.name }}
  {% if ver.pkgprovider|default('standard') == 'src' and ensure not in ['removed', 'purged'] %}
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
    - contents: ''
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
  {% endif %}

  {% if ensure in ['managed', 'running', 'stopped'] %}
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
  {% endif %}


{% endfor %}
