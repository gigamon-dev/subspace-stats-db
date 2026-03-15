-- select * from ss.player_log_type order by player_log_type_id;

merge into ss.player_log_type as t
using(
	values
		--  (1, 'Created')
		-- ,(2, 'Update name')
		-- ,(3, 'Update squad')
		-- ,(4, 'Update resolution')
		 (1000, 'League - Grant Role')
		,(1001, 'League - Revoke Role')
		,(1002, 'League - Request Role')
		-- ,(2000, 'League Season - Signup')
		-- ,(2001, 'League Season - Unsignup')
		-- ,(2100, 'League Season - Add to Team')
		-- ,(2101, 'League Season - Remove from Team')
		-- ,(2103, 'League Season - Suspended')
		-- ,(2104, 'League Season - Unsuspended')
) as v(player_log_type_id, player_log_type_description)
	on t.player_log_type_id = v.player_log_type_id
when matched then
	update set
		 player_log_type_description = v.player_log_type_description
when not matched then
	insert(
		 player_log_type_id
		,player_log_type_description
	)
	values(
		 v.player_log_type_id
		,v.player_log_type_description
	);
