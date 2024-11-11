# IPL-data-Analysis-using-Databricks-SQL

This repo has SQL scripts that are developed to genrate IPL statistics like:
1) Orange Cap
2) Purple Cap
3) Most Dot Balls
4) Fastest 50's, 100's etx
5) Hatricks.. etc

There a total of 25 reports, we will be using Joins, aggregate functions to achive the desired results. 

All the stats are avalibale @ https://www.iplt20.com/stats/2008 I am trying to produce all the stats that are in the IPL website using the sample data from 2008 to 2017

Databrciks community addition works for this project, we can later put this in cloud (Azure), improve performance and more

Below is the architecture the we are going to use for this use case. There are no streaming data sources for this project, its batch oriented only

![image](https://github.com/user-attachments/assets/4b69d057-c52d-43e1-9fd4-5dc373e33ef5)

User will upload data to DBFS file system in to bronze layer and do operations on top of it. Source data for this project is available in `data` directory of this repo.

Data files Description:
1) Ball_By_Ball.csv -- provides details about each ball bowler like runs, ball number, over number ,match_id etc.
2) Team.csv -- list of IPL teams
3) player.csv -- Provides information about each player played in ipl season
4) Match.csv -- Information about match venu, date, toss winner, captain etc
5) Player_match.csv - Information about palyer played matches, his role, seasosn etc

ETL Data Flow and Transformations sequence:
  IPL Data Analysis - Data Transform- Bronze to silver.ipynb
                     ||
                     ||
                     \/ 
  IPL Data Analysis - Orange Cap Stats - SQL.ipynb
                     ||
                     ||
                     \/ 
  IPL Data Analysis - Purple Cap Stats - SQL.ipynb
                     ||
                     ||
                     \/ 
  IPL Data Analysis- Read from Gold Layer.ipynb

Output Validation:
Each report in gold layer is comapred against the reports in https://www.iplt20.com/stats/2008 for accuracy.

Next Steps: 
we look into performance imporovements

