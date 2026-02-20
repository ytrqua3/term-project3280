<h2>Term Project for CPSC 3280</h2>h2>
<h3>Introduction </h3>
Purpose	
  1. Provide fast query on data through api endpoint 
  2. Process and aggregate data 
  3. Prepare data for downstream machine learning task 

Input Data: 
Music Listening Data (~500k Users) <br/>
Top 50 artists, tracks, and albums for each user <br/>
Source: https://www.kaggle.com/datasets/gabrielkahen/music-listening-data-500k-users/data <br/>

Tables used: users, user_top_artists 
  - users 
      -> user_id (INT)  
      -> country (TEXT) 
      -> total_scrobbles (BIGINT) 
  - user_top_artists (50 per user) 
      -> user_id (INT) 
      -> rank (INT, 1 to 50) 
      -> artist_name (TEXT) 
      -> playcount (BIGINT) 
      -> mbid (TEXT, may be empty) 

Output Data: 

  1. Country rank per artist 
      - Country (TEXT) 
      - Artist_name (TEXT) 
      - Total_playcount (DOUBLE) : Artists' playcount in country 
      - Normalized_popularity (DOUBLE): artist playcount in country / country total playcount 
      - Rank (INT): rank of country in popularity of certain artist (e.g. rank of Canada in normalized popularity of Drake) 
  2. Artist rank in country 
      - Country (TEXT) 
      - Artist_name (TEXT) 
      - Total_playcount (DOUBLE): artists’ playcount in country 
      - Rank (INT): Artist's rank in a certain country 
  3. User Embeddings: each user is represented as a vector in a 50 dimension space, vectors are created by word2vec by feeding in rank of users’ artist as a sentence. So users with similar prefernces for music will have vectors that are closer together. 
      - 50 dimensions (DOUBLE) 

<h3>Workflow</h3>
Workflow for 1,2:<br/>

![result for Drake1](https://github.com/ytrqua3/term-project3280/blob/68152255c5bb746f690100fc3026cf77c0d1ab78/assets/workflow.png)
 
Workflow for 3:
Api get request -> λ: start_embedding_job -> Glue ETL: embedding_job -> λ: createCrawlerForEmbedding -> Glue Crawler: embedding_data_crawler -> Glue Database: music_db -> λ: ApiQueryHandler <br/>
(Since embedding utilizes word2vec which is a simple neural network model, the process is expensive. Therefore, it is only ran when needed.) 


<h3>Infrastructure </h3>

S3 
term-project3280/ <br/>
|------------user_data/ <br/>
│   		|-------user_top_artists/ <br/>
│   		└-------user_data/ <br/>
|-------------raw_parquet/ <br/>
│   		├--- user_top_artists/ <br/>
│   		└---- user_data/ <br/>
|------------- processed_parquet/ <br/>
│   		├--- artist_rank_in_country/ <br/>
│   		├--- country_rank_per_artist/ <br/>
│   		└── user_embedding/ <br/>
├-------------glue_jobs/ <br/>
├------------ lambda_functions/ <br/>
├------------ lambda_layer/ <br/>
└── ----------athena_results/ <br/>

Glue ETL Jobs <br/>

  1. Music_csv_to_parquet: transforms csv uploaded to term-project3280/user_data/ into parquet format and store in term-project3280/raw_parquet/ then delete the csv file to free up storage <br/>

  2. Aggregate_data: produce artist_rank_in_country and country_rank_per_artist table then store in term-project3280/processed_parquet/ <br/>

  3. Embedding_job: produce user embedding table then store term-project3280/processed_parquet/ <br/>

 

Lambda Function <br/>

  1. CreateCrawlerForMusicData: create and run raw_data_crawler <br/>

  2. CreateCrawlerForProcessedData: create and run processed_data_crawler <br/>

  3. CreateCrawlerForEmbedding: create and run embedding_data_crawler <br/>

  4. Raw_csv_update_trigger: start music_csv_to_parquet glue job <br/>

  5. Start_aggregate_job: start aggregate_data glue job <br/>

  6. Start_embedding_job: start embedding_job glue job <br/>

  7. Raw_parquet_distributer: invokes CreateCrawlerForMusicData and	Start_aggregate_job <br/>

  8. ApiQueryHandler: accepts post request with sql query as body and responses with json format of query result <br/>

 

Lambda Layer: Boto3, numpy, pandas <br/>

Glue DataBase <br/>
  - Music_db<br/>
      -> raw_parquet_user_data <br/>
      -> raw_parquet_user_top_artists<br/>
      -> processed_parquet_country_rank_per_artist <br/>
      -> processed_parquet_artist_rank_in_country<br/>
      -> processed_parquet_user_embedding <br/>

Glue Crawlers <br/>
  - raw_data_crawler: term-project3280/raw_parquet/user_data/ and term-project3280/raw_parquet/user_top_artists/ <br/>
  - processed_data_crawler: term-project3280/processed_parquet/artist_rank_in_country/ and term-project3280/processed_parquet/country_rank_per_artist/ <br/>
  - embedding_data_crawler: term-project3280/processed_parquet/user_embedding/ <br/>

<h3>Glue ETL Explaination </h3>

  - Music_csv_to_parquet <br/>
      1. Store all csv object paths under user_data folder into raw_csv_s3_paths variable <br/>
      2. Loop through all the csv objects to convert them into pyspark dataframe then write them in parquet format into raw_parquet folder (I used append instead of overwrite mode when writing parquet to ensure that new csv files can be added to the collection of data to ensure scalability) <br/>
      3. Delete all the csv objects to save up space<br/>
      4. Invoke raw_parquet_disributer to automate the further steps <br/><br/>

  - Aggregate_data (artist_rank_in_country) <br/>
      1. Inner join the two dataframes so each user has a country attribute<br/>
      2. Find the total playcount of each artist in each country using groupby and sum<br/>
      3. Add a column for the artist’s rank in country using Window(for each country put the artists in descending order of playcount)<br/>
      4. Store the dataframe in s3 <br/><br/>

   - Aggregate_data (country_rank_per_artist) <br/>
      1. Get each countries’ total playcount using groupby<br/>
      2. Join the dataframe with playcount of each artist in each country with the country total playcount dataframe<br/>
      3. Calculate normalized_popularity of artist in a certain country by Artist's playcount in country / country total playcount<br/>
      5. Add a column for the country’s rank for that artist using Window(one artist as a group)<br/>
      6. Store the dataframe to s3 <br/><br/>

  - Embedding_job <br/>
      Purpose: get a vector that describes each artist, the closer the vectors of two artists are, the more similar their styles are. (they appear in similar context) <br/>
      *Note that the sequence fed into word2vec model is weighted, so artists with more 	playcount has a higher weight <br/>
      1. Get weight column: weight = round(1+log10(playcount)) , this is log scaled<br/>
      2. Have a row repeat itself according to weight using explode function<br/>
      3. Form artist_sequence for each user using groupby user_id then collect artist column as a list (since it is exploaded, the weight is applied)<br/>
      4. Now the dataframe is a sequence of artists per user, feed that into word2vec<br/>
      5. Obtain the vectors for each artist then store it in s3. <br/>

 

<h3>Conclusion </h3>
After running through the data pipeline, use postman to obtain the results 

Get 5 rows with artist_name Drake from unprocessed table 
![result for Drake1](https://github.com/ytrqua3/term-project3280/blob/68152255c5bb746f690100fc3026cf77c0d1ab78/assets/conclusion1.png)

Get top 5 countries with highest normalized popularity of Drake in processed table 
![result for Drake2](https://github.com/ytrqua3/term-project3280/blob/68152255c5bb746f690100fc3026cf77c0d1ab78/assets/conclustion2.png)
 

Can also use athena to query in console using athena 

SELECT user_id, country, total_scrobbles FROM raw_parquet_user_data LIMIT 5; 
![result from raw data](https://github.com/ytrqua3/term-project3280/blob/68152255c5bb746f690100fc3026cf77c0d1ab78/assets/conclustion3.png)
 

SELECT artist_name FROM processed_parquet_artist_rank_in_country WHERE country = 'Germany' ORDER BY rank LIMIT 10; 
![result for germany](https://github.com/ytrqua3/term-project3280/blob/68152255c5bb746f690100fc3026cf77c0d1ab78/assets/conclusion4.png)

Artist Embeddings: 
![embeddings1](https://github.com/ytrqua3/term-project3280/blob/68152255c5bb746f690100fc3026cf77c0d1ab78/assets/embeddings1.png)
![embeddings2](https://github.com/ytrqua3/term-project3280/blob/68152255c5bb746f690100fc3026cf77c0d1ab78/assets/embeddings2.png)


