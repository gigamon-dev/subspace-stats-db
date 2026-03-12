create or replace function league.end_season(
	 p_season_id league.season.season_id%type
)
returns void
language plpgsql
security definer
set search_path = league, pg_temp
as
$$

/*
Ends a season by setting the season's end date and the associated stat period's the upper bound.
*/

declare
	l_end_timestamp timestamptz;
begin
	l_end_timestamp :=
		coalesce(
			 (
				select max(dt.game_timestamp)
				from(
					select sg.game_timestamp
					from league.season_game as sg
					where sg.season_id = p_season_id
					union 
					select upper(g.time_played)
					from league.season_game as sg2
					inner join ss.game as g
						on sg2.game_id = g.game_id
					where sg2.season_id = p_season_id
				) as dt
			 )
			,current_timestamp
		);
	
	update ss.stat_period as sp
	set period_range = tstzrange(lower(sp.period_range), l_end_timestamp, '[]')
	where sp.stat_period_id = (
			select s.stat_period_id
			from league.season as s
			where s.season_id = p_season_id
		)
		and upper_inf(sp.period_range); -- no upper bound yet (this is expected)
	
	update league.season
	set end_date = l_end_timestamp
	where season_id = p_season_id;
end;
$$;

alter function league.end_season owner to ss_developer;

revoke all on function league.end_season from public;

grant execute on function league.end_season to ss_web_server;