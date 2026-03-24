/*
This script preloads OpenSkill ratings from SVS 4v4 Elo data.
Elo data was read from:
- 2026-03-22 Prac Leaderboard
- Season 57 Rosters
- Season 56 Rosters
and converted to OpenSkill mu values.

mu = (Elo - Base Elo / Scale Factor) + default mu
   = (Elo - 1000     / 50          ) + 25
   
where Scale Factor is 200 Elo points to 4 units of mu = 50
and the default mu = 25.
*/

/*
select * from ss.game_type;

select p.player_name, pm.game_type_id, pm.mu, pm.sigma
from ss.player_mmr as pm
inner join ss.player as p
	on pm.player_id = p.player_id
order by player_name
*/

insert into ss.player_mmr(
	 player_id
	,game_type_id
	,mu
	,sigma
)
select
	 dt2.player_id
	,dt2.game_type_id
	,dt2.mu
	,dt2.sigma
from(
	select 
		 ss.get_or_insert_player(dt.player_name) as player_id
		,cast(9 as bigint) as game_type_id -- 9 is the Id for "SVS 4v4 Prac" on NEXUS.
		,cast(mu as double precision)
		,cast(6 as double precision) as sigma -- Some but not much confidence in the Elo ratings these came from (combination of stack !cap, biased sbt, and non-random league matches).
	from(
			  select 'saiyan' as player_name, 47.44 as mu
		union select 'Da Monkk', 41.7
		union select 'Rojo', 38.78
		union select 'UKU', 38.32
		union select 'blink', 38.02
		union select 'Legacy', 37.7
		union select 'kdak', 37.58
		union select 'WORLDSTAR', 37.44
		union select 'Caerbannog', 37.4
		union select 'traxx', 37.38
		union select 'Rage', 37.12
		union select 'loveless', 36.5
		union select 'Ra', 36.44
		union select 'Crescendo', 36.28
		union select 'Captor', 35.5
		union select 'Ozn', 35.46
		union select 'BOMBED', 35.36
		union select 'MastiphaL', 34.32
		union select 'the seven year itch', 33.82
		union select 'aiti', 33.72
		union select 'KriLYu', 33.7
		union select 'Three', 33.18
		union select 'ro', 33.02
		union select 'Tool', 32.3
		union select 'BICK', 32.26
		union select 'TURBAN', 30.78
		union select 'develop', 30.76
		union select 'Candyman', 30.72
		union select 'retroaction', 30.42
		union select 'Creature', 30.34
		union select 'a', 30.18
		union select 'digital', 30.06
		union select 'Riverside', 29.62
		union select 'shikaa', 29.42
		union select 'Lemonaire', 29.32
		union select 'Tunahead', 29.22
		union select 'bierji', 29.2
		union select 'homie', 29
		union select 'psycho', 28.92
		union select 'Street Fighter', 28.74
		union select 'DOJ', 28.7
		union select 'Plaje', 28.58
		union select 'ivf', 28.48
		union select 'Robo', 28.48
		union select 'SK', 28.34
		union select 'Dequadin', 28.26
		union select 'Gunishment', 28.26
		union select 'necro', 28.16
		union select 'pic', 28.1
		union select 'Teddy', 27.74
		union select 'Kepi', 27.48
		union select 'eURipeDes', 27.34
		union select 'Tom Petty', 27.04
		union select 'Jack', 26.98
		union select 'SURI', 26.74
		union select 'sparrow', 26.7
		union select '2', 26.04
		union select 'Bettysueyo', 25.94
		union select 'apt', 25.56
		union select 'Palin', 25.52
		union select 'Low', 25.3
		union select 'Storm', 25.18
		union select 'hedcase8', 25.14
		union select 'Hurricane', 25
		union select 'omega red', 24.92
		union select 'Gold Teeth', 24.92
		union select 'Enforcer', 24.88
		union select 'Jamuraan', 24.86
		union select 'Dre', 24.64
		union select 'GBoNe', 24.56
		union select 'Curi', 24.04
		union select 'No one can kill me', 24
		union select 'midnight', 23.84
		union select 'Minor Threat', 23.82
		union select 'Punjab Fighter', 23.78
		union select 'a suicidal dentist', 23.66
		union select 'AcidFreak', 23.64
		union select 'Sword', 23.64
		union select 'Grinder', 23.48
		union select 'spy', 23.18
		union select 'phong', 23.16
		union select 'Rickdog', 22.92
		union select 'faulty', 22.68
		union select 'A mirror', 22.62
		union select 'Cape', 22.62
		union select 'adept', 22.6
		union select 'download', 22.5
		union select 'shaun', 22.34
		union select 'Lucky Tom', 22.22
		union select 'peabrain', 21.92
		union select 'abo', 21.86
		union select 'MACrelliK', 21.8
		union select 'zerovoltage', 21.42
		union select 'hawk', 21.38
		union select 'Enter', 21.32
		union select 'thc', 21.3
		union select 'Dbz', 21.16
		union select 'dreamwin', 21.06
		union select 'Aleksandra', 20.3
		union select 'mauisun', 20.3
		union select '3D', 20.16
		union select 'AFRI', 20.08
		union select 'Ace', 19.82
		union select 'Jinxi', 19.82
		union select 'da paz', 19.58
		union select 'Something Dutch', 19.5
		union select 'dare', 19.14
		union select 'Kodiak', 18.78
		union select 'avalon', 18.72
		union select 'Markypoo', 18.5
		union select 'katt', 18.3
		union select 'Rampage', 18.3
		union select 'Charas', 18.08
		union select 'Pog', 17.8
		union select 'JURASSIC', 17.68
		union select 'Hellsbane', 17.64
		union select 'Liar', 17
		union select 'zztop', 17
		union select 'havok', 16.86
		union select 'ikutsu', 16.86
		union select 'RaCka', 16.46
		union select 'Lusty', 16.34
		union select 'USS Evader', 16
		union select 'Death Artist', 15.98
		union select 'highrate', 15.88
		union select 'Brunson', 15.42
		union select 'G o G o', 15.12
		union select 'Obe', 15.06
		union select 'TheDeadPresidents', 15.04
		union select 'Stayon', 15
		union select 'EK', 15
		union select 'Valour Ant', 15
		union select 'Tripin', 14.8
		union select 'BoneMan', 14.76
		union select 'Flying Bass.', 14.76
		union select 'seer', 14.64
		union select 'autopilot', 14.34
		union select 'Lepton', 14.14
		union select 'Dioxide', 13.82
		union select 'Mongoose', 13.7
		union select 'Bargeld', 13.54
		union select 'GLYDE', 13.34
		union select 'honcho', 13
		union select 'Lee', 12.9
		union select 'Angel Blade', 12.54
		union select 'INRI', 12.48
		union select 'Kruger', 12.24
		union select 'Zwix', 11.84
		union select '420?', 10.88
		union select 'Hammeri', 7.28
		union select 'Grunt', 2.98
	) as dt
) as dt2
where not exists(
		select *
		from ss.player_mmr as pm
		where pm.player_id = dt2.player_id
			and pm.game_type_id = dt2.game_type_id
	);
