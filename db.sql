
--- 2. create new index based on user seek and user scan
SELECT
migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans)
 AS improvement_measure,
'CREATE INDEX [IX_' +    
  LEFT (PARSENAME(mid.statement, 1), 32) 
  + REPLACE (REPLACE(  mid.equality_columns ,'[', '_'), ']', '') 
  + REPLACE( REPLACE( REPLACE (mid.included_columns ,'[', '_'),']', ''),',','')
  +  ']' + ' ON ' + mid.statement
  + ' (' + ISNULL (mid.equality_columns,'')
    + CASE WHEN mid.equality_columns IS NOT NULL AND mid.inequality_columns IS NOT NULL THEN ',' ELSE '' END
    + ISNULL (mid.inequality_columns, '')
  + ')'
  + ISNULL (' INCLUDE (' + mid.included_columns + ')', '') AS create_index_statement,
  migs.*, mid.database_id, mid.[object_id]
FROM sys.dm_db_missing_index_groups mig
INNER JOIN sys.dm_db_missing_index_group_stats migs ON migs.group_handle = mig.index_group_handle
INNER JOIN sys.dm_db_missing_index_details mid ON mig.index_handle = mid.index_handle
WHERE migs.avg_total_user_cost * (migs.avg_user_impact / 100.0) * (migs.user_seeks + migs.user_scans) > 1000
ORDER BY migs.avg_total_user_cost * migs.avg_user_impact * (migs.user_seeks + migs.user_scans) DESC


---highly used tables
SELECT TableName, COUNT(*) [Dependency Count]
FROM (
Select Distinct
o.Name 'TableName',
op.Name 'DependentObject'
From SysObjects o
INNER Join SysDepends d ON d.DepId = o.Id
INNER Join SysObjects op on op.Id = d.Id
Where o.XType = 'U'
Group by o.Name, o.Id, op.Name
) x
GROUP BY TableName
ORDER BY 2 desc
-- more info from= > sys.dm_db_missing_index_groups,  and sys.dm_db_missing_index_details



---highly used table
use database_name
SELECT TableName, COUNT(*) 
FROM ( Select Distinct o.Name 'TableName', op.Name 'DependentObject' 
From SysObjects o 
INNER Join SysDepends d ON d.DepId = o.Id 
INNER Join SysObjects op on op.Id = d.Id Where o.XType = 'U' Group by o.Name, o.Id, op.Name ) x 
GROUP BY TableName ORDER BY 2 desc

---find which table is belonging to which db
SELECT table_catalog, table_name
 FROM INFORMATION_SCHEMA.TABLES where table_name = 'highlyused table name'


---higly used column
select col.name as column_name,
      count(*) as tables,
      cast(100.0 * count(*) / 
      (select count(*) from sys.tables) as numeric(36, 1)) as percent_tables
   from sys.tables as tab
       inner join sys.columns as col 
       on tab.object_id = col.object_id
group by col.name 
having count(*) > 1
order by count(*) desc
