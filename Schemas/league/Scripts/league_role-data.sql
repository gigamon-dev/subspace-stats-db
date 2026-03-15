-- select * from league.league_role;

merge into league.league_role as lr
using(
	values
		 (1, 'Manager')
		,(2, 'Practice Permit')
		,(3, 'Permit Manager')
		--,(4, 'Private Match Captain') -- TODO: perhaps in the future?
) as v(league_role_id, league_role_name)
	on lr.league_role_id = v.league_role_id
when matched and v.league_role_name <> lr.league_role_name then
	update set
		league_role_name = v.league_role_name
when not matched then
	insert(
		 league_role_id
		,league_role_name
	)
	values(
		 v.league_role_id
		,v.league_role_name
	);
