
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


------------------------------------------------- Best Bowling Average -------------------------------------------------

CREATE TABLE Best_Bowling_Average as 
select  
SEASON,
PLAYER_ID,
PLAYER_NAME,
PLAYER_TEAM,
MAT,
INNS,
OV,
RUNS,
WKTS,
BBI,
AVG,
ECON,
SR,
"4W",
"5W"
from PURPLE_CAP 
Order by season asc, AVG  asc;


------------------------------------------------- Best Bowling Economy -------------------------------------------------

CREATE TABLE Best_Bowling_Economy as 
select  
SEASON,
PLAYER_ID,
PLAYER_NAME,
PLAYER_TEAM,
MAT,
INNS,
OV,
RUNS,
WKTS,
BBI,
AVG,
ECON,
SR,
"4W",
"5W"
from PURPLE_CAP 
Order by season asc, ECON  asc;

------------------------------------------------- Best Bowling Strike Rate -------------------------------------------------

CREATE TABLE Best_Bowling_Strike_Rate as 
select  
SEASON,
PLAYER_ID,
PLAYER_NAME,
PLAYER_TEAM,
MAT,
INNS,
OV,
RUNS,
WKTS,
BBI,
AVG,
ECON,
SR,
"4W",
"5W"
from PURPLE_CAP 
Order by season asc, SR  asc;


----- Stats At innings/match level -----
-- Most Dot Balls (innings)
-- Best_Bowling_Strike_Rate (innings)
-- Best_Bowling_Strike_Rate  (innings)
-- Most_Runs_Conceded (innings)
-- Best_Bowling_Figures_innings

-------------------------------------------------Best_Bowling_Figures_innings -------------------------------------------------


drop table over_ball_count
CREATE TABLE over_ball_count as    -- at over level 
select 
season,
match_id,
bowler,
over_id,
sum(case when bowler_extras=0 then 1 else 0 end) as ball_count,  --balls bowled ignoring extra balls bowled by bowler
sum(case when bowler_wicket=1 then 1 else 0 end) as over_wickets,  -- wickets taken in each over
sum(runs_scored+bowler_extras) as runs  --runs conceded in each over
from cricket_match_data 
group by 1,2,3,4




CREATE TABLE Best_Bowling_Figures_innings_stg as 
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
(select season,match_id,bowler,sum(runs) as runs,sum(over_wickets) as wkts from over_ball_count group by 1,2,3) c
on a.season=c.season and a.match_id=c.match_id and a.bowler=c.bowler
left join 
player_match d on a.bowler=d.player_id and a.season=d.season_year and a.match_id=d.match_id 
left join 
matches e on a.season=e.season_year and a.match_id=e.match_id 


CREATE TABLE Best_Bowling_Figures_innings as 	
select  season,
	player_id,
	player_name,
	player_team,
	BBI,
	OV,
	RUNS,
	WKTS,
	SR,
	AGNAIST,
	venue,
	match_datr
from Best_Bowling_Figures_innings_stg order by season asc, wkts desc;
	
	
-------------------------------------------------Most_Dot_Balls_Innings-------------------------------------------------

CREATE TABLE Most_Dot_Balls_Innings as 	
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
Best_Bowling_Figures_innings_stg b on a.match_id=b.match_id and a.season=b.season and a.bowler=b.bowler
order by a.season asc , dots desc


------------------------------------------------- Best_Bowling_Economy_Innings -------------------------------------------------

CREATE TABLE Best_Bowling_Economy_Innings as 		
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
Best_Bowling_Figures_innings_stg b on a.match_id=b.match_id and a.season=b.season and a.bowler=b.bowler
where cast(b.ov as decimal)>1
order by a.season asc , ECON asc

-------------------------------------------------Best_Bowling_Strike_Rate_Innings -------------------------------------------------

CREATE TABLE bowler_played_matches as 
select 
	season,match_id,bowler
from cricket_match_data a 
group by 1,2,3
	
CREATE TABLE Best_Bowling_Strike_Rate_Innings as 	
select 
a.season,
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
from bowler_played_matches a
left join 
Best_Bowling_Figures_innings_stg b on a.match_id=b.match_id and a.season=b.season and a.bowler=b.bowler
where b.wkts>1 
order by a.season asc , sr asc;


------------------------------------------------- Most_Runs_Conceded_Innings -------------------------------------------------

CREATE TABLE Most_Runs_Conceded_Innings as 
select 
a.season,
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
from bowler_played_matches a
left join 
Best_Bowling_Figures_innings_stg b on a.match_id=b.match_id and a.season=b.season and a.bowler=b.bowler
order by a.season asc , runs desc




------------------------------------------------- HATRIC -------------------------------------------------------------------------


create TEMPORARY TABLE bowler_over_order_wicket_cnt  as
select 
a.season,a.bowler, a.match_id,a.over_id,is_wicket_taken,over_wicket_cnt,
row_number() over(partition by a.season,a.match_id,a.bowler order by a.over_id asc) as over_order_num
from 
(SELECT 
season,bowler, match_id,over_id,max(bowler_wicket)as is_wicket_taken,sum(bowler_wicket) as over_wicket_cnt
from cricket_match_data 
group by 1,2,3,4) a

	

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


CREATE  TEMPORARY TABLE bowler_cont_wick_taken_overs AS
select a.*,b.player_name from bowler_current_over_next_over  a
join player_data b on a.bowler=b.player_id
where  
(current_over_over_wicket_cnt=0 and next_over_over_wicket_cnt>=3) or
(current_over_over_wicket_cnt>=3 and next_over_over_wicket_cnt=0) or
(current_over_over_wicket_cnt>=1 and next_over_over_wicket_cnt>=2) or
(current_over_over_wicket_cnt>=2 and next_over_over_wicket_cnt>=1)

	
CREATE  TEMPORARY TABLE wicket_taken_balls AS
select  
season,bowler,match_id,over_id,ball_id
from cricket_match_data where  bowler_wicket=1 

	
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

CREATE  TABLE HATRICKS AS
select 
hatrick_count.season,
hatrick_count.bowler as player_id,
pc.player_name,
pc.player_team,
hatrick_count.HAT_TRICKS,
pc.mat,
pc.inns,
pc.ov,
pc.runs,
pc.wkts,
pc.avg,
pc.sr,
pc."4W",
pc."5W"
from
 (select a.season,a.bowler,count(*) as HAT_TRICKS from 
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
 group by 1,2
) hatrick_count
join PURPLE_CAP PC on hatrick_count.season=pc.season and hatrick_count.bowler=pc.player_id
 order by season asc;
 
