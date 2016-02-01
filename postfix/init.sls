{% from "postfix/map.jinja" import postfix with context %}

postfix:
  pkg.installed:
    - name: {{ postfix.package }}
    - watch_in:
      - service: postfix
  service.running:
    - enable: True
    - require:
      - pkg: postfix
    - watch:
      - pkg: postfix

{%- macro postmap_file(filename, mode=644, sourcefile='') %}
{%- set sourcefile = filename if sourcefile == '' else sourcefile %}
{%- set file_path = '/etc/postfix/' ~ filename %}
postmap_{{ filename }}:
  file.managed:
    - name: {{ file_path }}
    - source: salt://postfix/{{ sourcefile }}
    - user: root
    - group: root
    - mode: {{ mode }}
    - template: jinja
    - context:
      filename: {{ filename }}
    - require:
      - pkg: postfix
  cmd.wait:
    - name: /usr/sbin/postmap {{ file_path }}
    - cwd: /
    - watch:
      - file: {{ file_path }}
{%- endmacro %}

# manage /etc/aliases if data found in pillar
{% if 'aliases' in pillar.get('postfix', '') %}
{{ postfix.aliases_file }}:
  file.managed:
    - source: salt://postfix/aliases
    - user: root
    - group: root
    - mode: 644
    - template: jinja
    - require:
      - pkg: postfix

run-newaliases:
  cmd.wait:
    - name: newaliases
    - cwd: /
    - watch:
      - file: {{ postfix.aliases_file }}
{% endif %}

# manage /etc/postfix/virtual if data found in pillar
{% if 'virtual' in pillar.get('postfix', '') %}
{{ postmap_file('virtual') }}
{% endif %}

# manage /etc/postfix/sasl_passwd if data found in pillar
{% if 'sasl_passwd' in pillar.get('postfix', '') %}
{{ postmap_file('sasl_passwd', 600) }}
{% endif %}

# manage /etc/postfix/sender_canonical if data found in pillar
{% if 'sender_canonical' in pillar.get('postfix', '') %}
{{ postmap_file('sender_canonical') }}
{% endif %}

# manage transport configurations if data found in pillar
{% if 'transport' in pillar.get('postfix', '') %}
{{ postmap_file('transport') }}
{% endif %}

# manage ldap configurations if data found in pillar
{% if 'ldap' in pillar.get('postfix', '') %}
{% for filename in pillar.get('postfix').get('ldap', {}).keys()  %}
{{ postmap_file(filename, sourcefile='ldap') if filename != 'common' else '' }}
{% endfor %}
{% endif %}

