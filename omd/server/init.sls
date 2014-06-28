#!jinja|yaml

{% from "omd/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('omd:lookup')) %}

include:
  - omd
  - omd.server.setup
  - omd.server.config
  - omd.server.service
