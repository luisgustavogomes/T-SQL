
CREATE OR ALTER  PROCEDURE DBO.SP_HELPINDEX2
	@objname nvarchar(776)		-- the table to check for indexes
as
/*
Original Script - Microsoft Corporation

Modified by - Girish Sumaria - girish.sumaria@gmail.com

Information - The sp_helpindex only provides the list of columns in the index and not the INCLUDED COLUMNS.
		In order to retrieve complete index information, I have modified the original code so that 
		you can now retrieve INCLUDED COLUMNS list as well. Also, the index type can be retrived separately.
		
Tip from my fellow Database Developer - Prasant Nanda - prasant.nanda@gmail.com
		Ensure that you mark this procedure as a SYSTEM PROCEDURE to leverage its use from all databases. 

*/

	-- PRELIM
	set nocount on

	declare @objid int,			-- the object id of the table
			@indid smallint,	-- the index id of an index
			@groupid int,  		-- the filegroup id of an index
			@indname sysname,
			@groupname sysname,
			@status int,
			@keys nvarchar(2126),	--Length (16*max_identifierLength)+(15*2)+(16*3)
			@included_keys nvarchar(2126),	--Length (16*max_identifierLength)+(15*2)+(16*3)
			@InclCol nvarchar(225),
			@dbname	sysname,
			@ignore_dup_key	bit,
			@is_unique		bit,
			@is_hypothetical	bit,
			@is_primary_key	bit,
			@is_unique_key 	bit,
			@auto_created	bit,
			@no_recompute	bit

	-- Check to see that the object names are local to the current database.
	select @dbname = parsename(@objname,3)
--	print @dbname 
	if @dbname is null
		select @dbname = db_name()
	else if @dbname <> db_name()
		begin
			raiserror(15250,-1,-1)
			return (1)
		end

	-- Check to see the the table exists and initialize @objid.
	select @objid = object_id(@objname)
--	print @objid 
	if @objid is NULL
	begin
		raiserror(15009,-1,-1,@objname,@dbname)
		return (1)
	end

	-- OPEN CURSOR OVER INDEXES (skip stats: bug shiloh_51196)
	declare ms_crs_ind cursor local static for
		select i.index_id, i.data_space_id, i.name,
			i.ignore_dup_key, i.is_unique, i.is_hypothetical, i.is_primary_key, i.is_unique_constraint,
			s.auto_created, s.no_recompute
		from sys.indexes i join sys.stats s
			on i.object_id = s.object_id and i.index_id = s.stats_id
		where i.object_id = @objid
	open ms_crs_ind
	fetch ms_crs_ind into @indid, @groupid, @indname, @ignore_dup_key, @is_unique, @is_hypothetical,
			@is_primary_key, @is_unique_key, @auto_created, @no_recompute

	-- IF NO INDEX, QUIT
	if @@fetch_status < 0
	begin
		deallocate ms_crs_ind
		raiserror(15472,-1,-1,@objname) -- Object does not have any indexes.
		return (0)
	end

	-- create temp table
	CREATE TABLE #spindtab
	(
		index_name			sysname	collate database_default NOT NULL,
		index_id				int,
		ignore_dup_key		bit,
		is_unique				bit,
		is_hypothetical		bit,
		is_primary_key		bit,
		is_unique_key			bit,
		auto_created			bit,
		no_recompute			bit,
		groupname			sysname collate database_default NULL,
		index_keys			nvarchar(2126)	collate database_default NOT NULL, -- see @keys above for length descr
		included_keys			nvarchar(2126)	collate database_default NULL
	)

	-- Now check out each index, figure out its type and keys and
	--	save the info in a temporary table that we'll print out at the end.
	while @@fetch_status >= 0
	begin
		-- First we'll figure out what the keys are.
		declare @i int, @thiskey nvarchar(131) -- 128+3

		select @keys = index_col(@objname, @indid, 1), @i = 2
		if (indexkey_property(@objid, @indid, 1, 'isdescending') = 1)
			select @keys = @keys  + '(-)'

		select @thiskey = index_col(@objname, @indid, @i)
		if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, 'isdescending') = 1))
			select @thiskey = @thiskey + '(-)'

		while (@thiskey is not null )
		begin
			select @keys = @keys + ', ' + @thiskey, @i = @i + 1
			select @thiskey = index_col(@objname, @indid, @i)
			if ((@thiskey is not null) and (indexkey_property(@objid, @indid, @i, 'isdescending') = 1))
				select @thiskey = @thiskey + '(-)'
		end

/* Code to find Included Columns goes here */
	set @InclCol=null
	set @included_keys=null 
	declare ms_crs_inc_cols cursor local static for
		SELECT --sys.tables.object_id, 
			--sys.tables.name as table_name, sys.indexes.name as index_name,sys.indexes.type_desc as Ind_Type, 
		sys.columns.name as column_name
		--,sys.index_columns.index_column_id, sys.indexes.is_unique, sys.indexes.is_primary_key , sys.index_columns.is_included_column 
		FROM sys.tables, sys.indexes, sys.index_columns, sys.columns 
		WHERE (sys.tables.object_id = sys.indexes.object_id AND sys.tables.object_id = sys.index_columns.object_id AND sys.tables.object_id = sys.columns.object_id
		AND sys.indexes.index_id = sys.index_columns.index_id AND sys.index_columns.column_id = sys.columns.column_id) 
		AND sys.indexes.object_id = @objid
			and sys.indexes.index_id = @indid
			and is_included_column=1
		order by index_column_id
	open ms_crs_inc_cols 
	fetch next from ms_crs_inc_cols into @InclCol
	while @@fetch_status >= 0
	begin
		if @included_keys is null
			set @included_keys=@InclCol
		else
			set @included_keys=@included_keys+','+@InclCol
		print @included_keys
		fetch next from ms_crs_inc_cols into @InclCol
	end
	close ms_crs_inc_cols
	deallocate ms_crs_inc_cols

/* Code to find Included Columns ends here */

		select @groupname = null
		select @groupname = name from sys.data_spaces where data_space_id = @groupid

		-- INSERT ROW FOR INDEX
		insert into #spindtab values (@indname, @indid, @ignore_dup_key, @is_unique, @is_hypothetical,
			@is_primary_key, @is_unique_key, @auto_created, @no_recompute, @groupname, @keys,@included_keys)

		-- Next index
		fetch ms_crs_ind into @indid, @groupid, @indname, @ignore_dup_key, @is_unique, @is_hypothetical,
			@is_primary_key, @is_unique_key, @auto_created, @no_recompute
	end
	deallocate ms_crs_ind

	-- DISPLAY THE RESULTS
	select
		'index_name' = index_name,
		'type' = case when index_id = 1 then 'clustered' else 'nonclustered' end,
		'index_description' = convert(varchar(210), --bits 16 off, 1, 2, 16777216 on, located on group
				case when ignore_dup_key <>0 then 'ignore duplicate keys' else '' end
				+ case when is_unique <>0 then ', unique' else '' end
				+ case when is_hypothetical <>0 then ', hypothetical' else '' end
				+ case when is_primary_key <>0 then ', primary key' else '' end
				+ case when is_unique_key <>0 then ', unique key' else '' end
				+ case when auto_created <>0 then ', auto create' else '' end
				+ case when no_recompute <>0 then ', stats no recompute' else '' end
				+ ' located on ' + groupname),
		'index_keys' = index_keys,
		'included_keys' = included_keys
	from #spindtab
	order by index_name


	return (0) -- sp_helpindex