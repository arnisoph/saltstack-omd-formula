omd:
{% if salt['grains.get']('os') == 'Debian' %}
  lookup:
    repo:
      manage: True
      url: http://192.168.2.42/
      dist: wheezy
      comps: main
      keyurl: http://192.168.2.42/pubkey.gpg
{% endif %}
    cmk:
      agent:
        script:
          group: monitoring
  salt:
    collect_monitoring_pubkeys:
      tgt: monitoring.domain.local
      arg: 'test -r /omd/sites/prod/.ssh/id_rsa.pub && cat /omd/sites/prod/.ssh/id_rsa.pub'
      exprform: compound
  versions:
    - name: omd-1.11.20140622
    - name: omd-1.10
      filename: omd-1.10_0
      ensure: installed
    - name: omd-1.00
      filename: omd-1.00_0
      ensure: removed
    - name: omd-0.56
      filename: omd-0.56_0
      srcuri: http://files.omdistro.org/releases/debian_ubuntu/omd-0.56_0.wheezy_amd64.deb
  sites:
    - name: prod
      omd:
        config:
          DEFAULT_GUI: check_mk
          MULTISITE_COOKIE_AUTH: 'on'
          NAGIOS_THEME: exfoliation
      cmk:
        config:
          main:
            template_path: salt://omd/files/cmk/server/foo/prod/main.mk
          main_wato_global:
            template_path: salt://omd/files/cmk/server/foo/prod/main/global.mk
          multisite:
            template_path: salt://omd/files/cmk/server/foo/prod/multisite.mk
          multisite_wato_global:
            template_path: salt://omd/files/cmk/server/foo/prod/multisite/global.mk
    - name: test
      ensure: absent
    - name: test2
    - name: test3
      ensure: stopped
    - name: test4
      omd:
        config:
          AUTOSTART: 'off'
          CORE: nagios
