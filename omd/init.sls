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
