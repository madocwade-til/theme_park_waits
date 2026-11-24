{% test consistent_ids(model, column_name, name_column) %}

SELECT m1.*, 
m2.{{column_name}} as id_col2, 
m2.{{name_column}} as name_col2
FROM {{model}} m1
LEFT JOIN {{model}} m2
ON m1.{{column_name}} = m2.{{column_name}}
WHERE m1.{{name_column}} != m2.{{name_column}}

{% endtest %}