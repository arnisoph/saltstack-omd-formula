omd:
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
      config:
        DEFAULT_GUI: check_mk
        MULTISITE_COOKIE_AUTH: 'on'
    - name: test
      ensure: absent
    - name: test2
    - name: test3
      ensure: stopped
    - name: test4
      config:
        AUTOSTART: 'off'
        CORE: nagios
