{% macro generate_schema_name(custom_schema_name, node) -%}

    {%- set default_schema = target.schema -%}
    
    {# 
      In production, write directly to the custom schema (e.g. staging).
      In development, prefix the custom schema with the user's default schema (e.g. dbt_stackoverflow_staging)
      to avoid developers overwriting each other's tables.
    #}
    {%- if target.name == 'prod' and custom_schema_name is not none -%}

        {{ custom_schema_name | trim }}

    {%- elif custom_schema_name is not none -%}

        {{ default_schema }}_{{ custom_schema_name | trim }}

    {%- else -%}

        {{ default_schema }}

    {%- endif -%}

{%- endmacro %}
