#!jinja|yaml

{% from "omd/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('omd:lookup')) %}

include:
  - omd.server
{#
{% for si in salt['pillar.get']('omd:server:sls_include', []) %}
  - {{ si }}
{% endfor %}

extend: {{ salt['pillar.get']('omd:server:sls_extend', '{}') }}
#}

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
{% endfor %}
