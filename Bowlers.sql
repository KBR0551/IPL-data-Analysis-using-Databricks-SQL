
--------------------  Temorary Table --------

CREATE  TEMPORARY TABLE INNS_STATS AS
select * from (
select 
season ,
player_id,
player_name,
player_team,
count( match_id) as MAT,
sum( inn) as INNS,
sum(overs) as OV,
coalesce(sum(runs),0) as RUNS,
sum(wickets) as WKTS,
coalesce(round(NULLIF(sum(runs),0)/NULLIF(sum(wickets),0),2),0) as AVG,
coalesce(round(NULLIF(sum(runs),0)/NULLIF(sum(overs),0),2),0) as ECON,
coalesce(round(NULLIF(sum(overs)*6,0)/NULLIF(sum(wickets),0),2),0) as SR,
sum(four_wick) as "4W",
sum(five_wick) as "5W"
from
(
select a.season_year as season,
	   a.match_id,
	   a.player_id,
	   a.player_name,
	   a.player_team,
	   count(distinct b.bowler) as inn,
	   count(distinct b.over_id) as overs,
	   sum(b.runs_scored+b.bowler_extras)  as runs,
	   sum(case when b.bowler_wicket=1 then 1 else 0 end) as wickets,
	   case when sum(bowler_wicket)=4 then 1 else 0 end as four_wick,
	   case when sum(bowler_wicket)>=5 then 1 else 0 end as five_wick
from player_match a
left join 
cricket_match_data b
on a.match_id=b.match_id and a.season_year=b.season and a.player_id=b.bowler
GROUP BY 1,2,3,4,5
) a
group by 1,2,3,4) a 
where a.WKTS>0


drop table BBI_WICKETS
CREATE  TEMPORARY TABLE BBI_WICKETS AS
select bowler,wickets,runs from 
(
select 
        match_id,
        bowler, 
		season,
		sum(bowler_wicket) as wickets,
	    sum(runs_scored+bowler_extras)  as runs,
		dense_rank() over(partition by bowler order by sum(bowler_wicket) desc, sum(runs_scored+bowler_extras) asc )  as bbi_rnk,
		sum(runs_scored) as runs_concided 
		from cricket_match_data   
	    group by 1,2,3 ) a 
where bbi_rnk=1
group by 1,2,3

------------------------------------------------- PURPLE_CAP -------------------------------------------------
CREATE TABLE PURPLE_CAP as 
select  
a.SEASON,
a.PLAYER_ID,
a.PLAYER_NAME,
a.PLAYER_TEAM,
a.MAT,
a.INNS,
a.OV,
a.RUNS,
a.WKTS,
concat(b.wickets,'/',b.runs) as BBI,
a.AVG,
a.ECON,
a.SR,
a."4W",
a."5W"
from INNS_STATS a
join 
BBI_WICKETS b on a.PLAYER_ID=b.bowler
Order by season asc, wkts desc;



-------------------------------------------------MOST_MADINS-------------------------------------------------
CREATE TABLE Most_Maidens as 
select  
a.SEASON,
a.PLAYER_ID,
a.PLAYER_NAME,
a.PLAYER_TEAM,
a.MAT,
a.INNS,
a.OV,
a.RUNS,
a.WKTS,
b.MAID,
a.AVG,
a.ECON,
a.SR,
a."4W",
a."5W"
from INNS_STATS a
join 
(select season,bowler,b.player_name,count(*) as MAID
from (
select season,match_id,bowler,over_id,
sum(runs_scored+bowler_extras) as runs,
count(ball_id) as ball_count
from cricket_match_data 
group by 1,2,3,4 
having sum(runs_scored+bowler_extras)=0 and count(ball_id) >=6 ) a
join 
player_data b on a.bowler=b.player_id
group by 1,2,3)  b  on a.season=b.season and a.player_id=b.bowler 
order by season asc, MAID desc


------------------------------------------------- MOST DOT BALLS -------------------------------------------------


CREATE TABLE dot_balls as 
select 
	season,
	match_id,
	bowler,
	count(*) as DOTS
from 
	cricket_match_data a
join 
	player_data b on a.bowler=b.player_id 
where runs_scored+extra_runs+bowler_extras+extra_runs=0
group by 1,2,3



CREATE TABLE Most_dots_balls as 
select  
a.SEASON,
a.PLAYER_ID,
a.PLAYER_NAME,
a.PLAYER_TEAM,
a.MAT,
a.INNS,
a.OV,
a.RUNS,
a.WKTS,
b.DOTS,
a.AVG,
a.ECON,
a.SR,
a."4W",
a."5W"
from INNS_STATS a
join
(select season,bowler,sum(DOTS) as DOTS
from dot_balls a
group by 1,2) b on a.season=b.season and a.player_id=b.bowler
order by b.DOTS desc

---------BBF_Innings ---


drop table over_ball_count
CREATE TABLE over_ball_count as 
select 
season,
match_id,
bowler,
over_id,
sum(case when bowler_extras=0 then 1 else 0 end) as ball_count,
sum(case when bowler_wicket=1 then 1 else 0 end) as over_wickets,
sum(runs_scored+bowler_extras) as runs
from cricket_match_data  --where bowler=102 and match_id=336010
group by 1,2,3,4
order by bowler



CREATE TABLE bbi_innings as 
select a.season,
a.match_id,
a.bowler,
d.player_name,
d.player_team,
case when ball_count IS NULL then cast(a.over_count as VARCHAR(5)) else concat(a.over_count,'.',b.ball_count) end as OV,
c.runs,
c.wkts,
concat(c.wkts,'/',c.runs) as BBI,
coalesce(round(NULLIF(total_match_balls,0)/NULLIF(wkts,0),2),0) as SR,
d.opposit_team as AGNAIST,
e.venue_name as venue,
e.match_date
from 
(select season,match_id,bowler,
 sum(ball_count) as total_match_balls,
sum(case when ball_count>=6 then 1 else 0 end) as  over_count
from over_ball_count
group by 1,2,3 ) a
left join 
(select season,match_id,bowler,ball_count
from over_ball_count where ball_count<6) b on a.season=b.season and a.match_id=b.match_id and a.bowler=b.bowler
left join 
(select season,match_id,bowler,sum(runs) as runs,count(over_wickets) as wkts from over_ball_count group by 1,2,3) c
on a.season=c.season and a.match_id=c.match_id and a.bowler=c.bowler
left join 
player_match d on a.bowler=d.player_id and a.season=d.season_year and a.match_id=d.match_id 
left join 
matches e on a.season=e.season_year and a.match_id=e.match_id 


---mos dot balls in innings -----

select 
a.season,
a.bowler as player_id,
b.player_name,
b.player_team,
b.ov,
b.runs,
b.wkts,
a.dots,
b.sr,
b.AGNAIST,
b.venue,
b.match_date
from dot_balls a
left join 
bbi_innings b on a.match_id=b.match_id and a.season=b.season and a.bowler=b.bowler
order by a.season asc , dots desc


------MOST ECON Bowler by innings -----

select 
a.season,
a.bowler as player_id,
b.player_name,
b.player_team,
b.ov,
b.runs,
b.wkts,
a.dots,
coalesce(round(NULLIF(b.runs,0)/NULLIF(cast(b.ov as decimal),0),2),0) as ECON,
b.sr,
b.AGNAIST,
b.venue,
b.match_date
from dot_balls a
left join 
bbi_innings b on a.match_id=b.match_id and a.season=b.season and a.bowler=b.bowler
where cast(b.ov as decimal)>1
order by a.season asc , ECON asc



------- Most Runs Conceded ---

cREATE TABLE match_played_player as 
select season,match_id,bowler
from cricket_match_data a
join player_data b on a.bowler=b.player_id 
group by 1,2,3

select 
a.season,
a.match_id,
a.bowler as player_id,
b.player_name,
b.player_team,
b.ov,
b.runs,
b.wkts,
b.sr,
b.AGNAIST,
b.venue,
b.match_date
from match_played_player a
left join 
bbi_innings b on a.match_id=b.match_id and a.season=b.season and a.bowler=b.bowler
order by a.season asc , runs desc


------MOST Strike rate of Bowler by innings -----


select 
a.season,
a.match_id,
a.bowler as player_id,
b.player_name,
b.player_team,
b.ov,
b.runs,
b.wkts,
b.sr,
b.AGNAIST,
b.venue,
b.match_date
from match_played_player a
left join 
bbi_innings b on a.match_id=b.match_id and a.season=b.season and a.bowler=b.bowler
where b.wkts>1 
order by a.season asc , sr asc


-------- HATRIC -------------------------------------------------------------------------
--------------------------------
drop table bowler_over_id_rank
CREATE  TEMPORARY TABLE bowler_over_id_rank AS
select 
a.season,a.bowler, a.match_id,a.over_id,is_wicket_taken,
row_number() over(partition by a.season,a.match_id,a.bowler order by a.over_id asc) as over_order_num
from 
(SELECT 
season,bowler, match_id,over_id,max(bowler_wicket) as is_wicket_taken
from cricket_match_data 
group by 1,2,3,4) a

drop table bowler_over_wicket_cnt
CREATE  TEMPORARY TABLE bowler_over_wicket_cnt AS
select season,bowler, match_id,over_id,
sum( bowler_wicket) as over_wicket_cnt
from cricket_match_data 
group by 1,2,3,4

drop table bowler_over_order_wicket_cnt
CREATE  TEMPORARY TABLE bowler_over_order_wicket_cnt AS
select a.season,a.bowler, a.match_id,a.over_id,a.is_wicket_taken,a.over_order_num,b.over_wicket_cnt
from bowler_over_id_rank a 
join 
bowler_over_wicket_cnt b on a.season=b.season
and a.match_id=b.match_id and a.bowler=b.bowler and a.over_id=b.over_id

drop table bowler_current_over_next_over
CREATE  TEMPORARY TABLE bowler_current_over_next_over AS
select 
a.season,a.bowler,a.match_id,
a.over_id as current_over ,
a.is_wicket_taken as current_over_is_wicket_taken,
a.over_order_num as current_over_over_order_num,
a.over_wicket_cnt as current_over_over_wicket_cnt,
b.over_id as next_over ,
b.is_wicket_taken as next_over_is_wicket_taken,
b.over_order_num as next_over_over_order_num,
b.over_wicket_cnt as next_over_over_wicket_cnt
from  bowler_over_order_wicket_cnt a 
join 
bowler_over_order_wicket_cnt b on a.season=b.season and a.match_id=b.match_id 
                              and a.bowler=b.bowler and a.over_order_num+1=b.over_order_num

drop table bowler_cont_wick_taken_overs
CREATE  TEMPORARY TABLE bowler_cont_wick_taken_overs AS
select a.*,b.player_name from bowler_current_over_next_over  a
join player_data b on a.bowler=b.player_id
where  
(current_over_over_wicket_cnt=0 and next_over_over_wicket_cnt>=3) or
(current_over_over_wicket_cnt>=3 and next_over_over_wicket_cnt=0) or
(current_over_over_wicket_cnt>=1 and next_over_over_wicket_cnt>=2) or
(current_over_over_wicket_cnt>=2 and next_over_over_wicket_cnt>=1)

select * from bowler_cont_wick_taken_overs

drop table wicket_taken_balls
CREATE  TEMPORARY TABLE wicket_taken_balls AS
select  
season,bowler,match_id,over_id,ball_id
from cricket_match_data where  bowler_wicket=1 

drop table overs_with_contunious_wickets
CREATE  TEMPORARY TABLE overs_with_contunious_wickets AS
select a.*,
row_number() over(partition by a.season,a.match_id,a.bowler order by a.over_id,a.ball_id) as rnk
from 
(select 
a.season,a.bowler,a.match_id,a.current_over as over_id ,b.ball_id
from bowler_cont_wick_taken_overs a
left join 
wicket_taken_balls b on a.season=b.season and a.bowler=b.bowler and a.match_id=b.match_id 
and a.current_over=b.over_id
union 
select 
a.season,a.bowler,a.match_id,a.next_over as over_id ,b.ball_id
from bowler_cont_wick_taken_overs a
left join 
wicket_taken_balls b on a.season=b.season and a.bowler=b.bowler and a.match_id=b.match_id 
and a.next_over=b.over_id) a


CREATE  TEMPORARY TABLE HATRICK AS
select  
a.season,a.bowler,a.match_id,a.over_id as over_id_1,
a.ball_id as ball_id_1,b.over_id as  over_id_2 ,b.ball_id as  ball_id_2,
c.over_id as over_id_3,c.ball_id as ball_id_3
from overs_with_contunious_wickets a ,
overs_with_contunious_wickets b,
overs_with_contunious_wickets c 
where a.season=b.season and a.match_id=b.match_id and a.bowler=b.bowler and a.rnk+1=b.rnk
and b.season=c.season and b.match_id=c.match_id and b.bowler=c.bowler and b.rnk+1=c.rnk


 select a.* from 
 (select season,bowler,b.player_name,
 case when over_id_1=over_id_2 and over_id_2=over_id_3
           and (ball_id_1+1=ball_id_2 and ball_id_2+1=ball_id_3) then 'YES' --Hartick in same Over
	  when (ball_id_1=5 and ball_id_2=6 and over_id_1=over_id_2  and ball_id_3 =1) then 'YES'
	  when (ball_id_1=6 and ball_id_2=1 and ball_id_3 =2 and over_id_2=over_id_3) then 'YES'
	  when (ball_id_1=7 and ball_id_2=1 and ball_id_3 =2  and over_id_2=over_id_3) then 'YES'
      when (ball_id_1=6 and ball_id_2=7  and over_id_1=over_id_2 and ball_id_3 =1) then 'YES'
   else 'NO' end as HATRICK
 from HATRICK a
 join 
  Player_data b on a.bowler=b.player_id
 ) a where HATRICK='YES'
 order by season asc
