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

{% for ver in salt['pillar.get']('omd:versions') %}
  {% set state = ver.state|default('installed') %}

  {% set srcuri = ver.srcuri|default('http://files.omdistro.org/releases/' ~ datamap.pkg_default_os ~ '/' ~ ver.filename|default('omd_NOVERSIONSET') ~ '.' ~ grains.get('oscodename') ~ '_' ~ grains.get('osarch') ~ '.' ~ datamap.pkg_default_ext) %}

omd_version_{{ ver.name }}:
  pkg:
    - {{ state }}
    - name: {{ ver.name }}
  {% if ver.pkgprovider|default('standard') == 'src' and state not in ['removed', 'purged'] %}
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
