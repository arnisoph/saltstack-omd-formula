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


{% for s in salt['pillar.get']('omd:sites', []) if s.ensure|default('running') in ['managed', 'running', 'stopped'] %}
  {% set ensure = s.ensure|default('running') %}

  {% if ensure in ['managed', 'running'] %}
site_{{ s.name }}_restart:
  cmd:
    - wait
    - name: {{ datamap.omdbin.path|default('/usr/bin/omd') }} restart {{ s.name }}
  {% endif %}

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
{% endfor %}
