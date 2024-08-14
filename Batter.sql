DROP TABLE BATTER_INNS_PLAYED
CREATE  TEMPORARY TABLE BATTER_INNS_PLAYED AS
select 
season_year,
player_id,
player_team,
count(distinct match_id) as total_matches_played,
sum(inn) as innings_played,
(sum(inn) -sum(out_ind) )as not_out
from 
(
select a.match_id,
	   a.player_id,
	   a.season_year,
	   a.player_team,
       case when (a.player_id=b.striker or a.player_id=b.non_striker) then 1 else 0 end as inn,
       case when a.player_id=c.player_out then 1 else 0 end as out_ind 
from player_match a
left join 
cricket_match_data b
on a.match_id=b.match_id and a.season_year=b.season and (a.player_id=b.striker or a.player_id=b.non_striker)
left join 
cricket_match_data c on c.match_id=a.match_id and a.player_id=c.player_out and c.player_out is not null
GROUP BY 1,2,3,4,5,6) a
group by 1,2,3
order by player_id;


CREATE  TEMPORARY TABLE total_runs_and_balls_faced AS
select 
season,
striker,
sum(runs_scored) as scored_match_runs ,
sum(case when extra_type in ('No Extras','Byes','Legbyes','legbyes','byes','Noballs','noballs') then 1 else 0 end) as balls_faced
from  cricket_match_data
group by 1,2;


CREATE  TEMPORARY TABLE batter_season_highg_scores AS
select 
season,
striker,
runs
from
(
select 
season,
striker,
match_id,
sum(runs_scored) as runs,
row_number() over( partition by  season,striker order by season asc , sum(runs_scored) desc) as runs_rank
from cricket_match_data
group by 1,2,3
) a where  runs_rank=1;


CREATE TEMPORARY TABLE centuries AS
select 
season,
striker, 
sum(case when runs>=50 and runs<100 then 1 else 0 end) as fifties ,
sum(case when runs>=100 then 1 else 0 end) as hundreds 
from (
select 
season,
striker,
match_id,
sum(runs_scored) as runs
from cricket_match_data
group by 1,2,3 ) a 
group by season,striker;


CREATE  TEMPORARY TABLE boundry_count AS
select 
season,
striker,
sum (case when runs_scored=4 then 1 else 0 end ) as fours,
sum (case when runs_scored=6 then 1 else 0 end ) as sixes
from cricket_match_data
where runs_scored in (4,6) 
group by 1,2  ; 

drop table ORANGE_CAP

CREATE TABLE ORANGE_CAP AS
select 
a.season_year,
a.player_id as PLAYER, 
h.player_name,
a.player_team,
coalesce(a.total_matches_played,0) as MAT ,
coalesce(a.innings_played,0) as INNS,
coalesce(a.not_out,0) as NO,
coalesce(b.scored_match_runs,0) as RUNS,
--row_number() over(partition by(a.season_year) order by coalesce(b.scored_match_runs,0) desc ) as POS,
coalesce(c.runs,0) as HS,
coalesce(ROUND(cast(NULLIF(b.scored_match_runs,0) as DECIMAL(10,2))/cast(NULLIF((NULLIF(a.innings_played,0) -NULLIF(a.not_out,0)) ,0) as decimal(10,2)),2),0) as "AVG",
coalesce(b.balls_faced,0) as BF,
coalesce(ROUND((cast(NULLIF(b.scored_match_runs,0) as DECIMAL(10,2))/cast(NULLIF(b.balls_faced,0) as decimal(10,2))*100),2),0) as SR,
coalesce(d.hundreds,0) as "100",
coalesce(d.fifties,0) as "50",
coalesce(f.fours,0) as "4S",
coalesce(f.sixes,0) as "6S"
from BATTER_INNS_PLAYED a 
left join 
total_runs_and_balls_faced b on a.season_year=b.season and a.player_id=b.striker
left join
batter_season_highg_scores c on a.season_year=c.season and a.player_id=c.striker
left join 
centuries d on a.season_year=d.season and a.player_id=d.striker
left join
boundry_count f on a.season_year=f.season and a.player_id=f.striker
left join 
player_data h on a.player_id=h.player_id
order by a.season_year asc,RUNS desc


------------------------------------------ RuPay_On_The_Go_4s_of_the_Season ------------------------------------------
CREATE TABLE RuPay_On_The_Go_4s_of_the_Season AS 
select 
season_year,
Player,
player_name,
player_team,
"4S",
mat,
inns,
no,
runs,
hs,
"AVG",
bf,
sr,
"100",
"50",
"6S"
from ORANGE_CAP order by season_year asc, "4S" desc

------------------------------------------ Angel_One_Super_Sixes_of_the_Season ------------------------------------------

CREATE TABLE Angel_One_Super_Sixes_of_the_Season AS 
select 
season_year,
Player,
player_name,
player_team,
"6S",
mat,
inns,
no,
runs,
hs,
"AVG",
bf,
sr,
"100",
"50",
"4S"
from ORANGE_CAP order by season_year asc, "6S" desc

------------------------------------------ Most_Fifties ------------------------------------------

CREATE TABLE Most_Fifties AS 
select 
season_year,
Player,
player_name,
player_team,
"50",
mat,
inns,
no,
runs,
hs,
"AVG",
bf,
sr,
"100",
"6S",
"4S"
from ORANGE_CAP order by season_year asc, "50" desc

------------------------------------------ Most_Centuries ------------------------------------------

CREATE TABLE Most_Centuries AS 
select 
season_year,
Player,
player_name,
player_team,
"100",
mat,
inns,
no,
runs,
hs,
"AVG",
bf,
sr,
"50",
"6S",
"4S"
from ORANGE_CAP order by season_year asc, "50" desc


------------------------------------------ Highest_Scores ------------------------------------------

CREATE TABLE Highest_Scores AS 
select 
season_year,
Player,
player_name,
player_team,
hs,
mat,
inns,
no,
runs,
"AVG",
bf,
sr,
"100",
"50",
"6S",
"4S"
from ORANGE_CAP order by season_year asc, "hs" desc

------------------------------------------ Punch_ev_Electric_Striker_of_the_Season ------------------------------------------

CREATE TABLE Punch_ev_Electric_Striker_of_the_Season AS 
select 
season_year,
Player,
player_name,
player_team,
sr,
mat,
inns,
no,
runs,
hs,
"AVG",
bf,
"100",
"50",
"6S",
"4S"
from ORANGE_CAP order by season_year asc, "sr" desc
