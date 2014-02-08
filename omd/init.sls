{% from "omd/map.jinja" import datamap with context %}

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
