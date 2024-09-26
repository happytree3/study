//키바나

GET test/_search
{
	"query":{
		"bool":{
			"must":[
				{ "exists" : { "field": "FIELD_CONTENT"}},
				{ "range": {"FIELD_CONTENT" : { "gt" : ""}}}
			]
		}
	}
}

GET test/_search
{
	"query":{
		"bool":{
			"must":{
				"nested":{
					"path":"FIELD_FILE",
					"query":{ "exists": { "field" : "FIELD_FILE.FIELD_FILE_CONTENT" }}
				}
			}
		}
	}
}

// 자바


// 사이버다임

find ./ -type f -exec sed -i 's|/proten/prosearch|설치경로|g' {} \;


searchstat.sh index


// sql

CASE WHEN TRGT_ID NOT LIKE 'TL%' THEN
'true' ELSE 'false' END AS FIELD_FILE_CONTENT

select 
	film_id,
	case when title like 'AC%' then 'true' else 'false' end as TEST 
from film; 


CREATE VIEW v_film AS
select
	film_id as DOCID,
	case when title like 'AC%' then 'true' else 'false' end as TEST 
FROM film
WHERE film_id <= 5;

vi /etc/security/limits.conf
vi /etc/sysctl.conf

sysctl -p

vm.max_map_count

cat /proc/sys/vm/max_map_count
