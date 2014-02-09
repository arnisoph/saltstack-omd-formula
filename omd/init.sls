{% from "omd/defaults.yaml" import rawmap with context %}
{% set datamap = salt['grains.filter_by'](rawmap, merge=salt['pillar.get']('omd:lookup')) %}

{% for ver in salt['pillar.get']('omd:versions') %}
  {% if ver['state'] is not defined %}
  {% set state = 'installed' %}
  {% else %}
  {% set state = ver['state'] %}
  {% endif %}

  {% if ver['srcuri'] is not defined %}
  {% set srcuri = 'http://files.omdistro.org/releases/' ~ datamap['pkg_default_os'] ~ '/' ~ ver['filename'] ~ '.' ~ grains.get('oscodename') ~ '_' ~ grains.get('osarch') ~ '.' ~ datamap['pkg_default_ext'] %}
  {% else %}
  {% set srcuri = ver['srcuri'] %}
  {% endif %}

omd-version-{{ ver.name }}:
  pkg:
    - {{ state }}
    - name: {{ ver['name'] }}
  {% if state not in ['removed', 'purged'] %}
    - sources:
      - {{ ver['name'] }}: {{ srcuri }}
  {% endif %}
{% endfor %}
