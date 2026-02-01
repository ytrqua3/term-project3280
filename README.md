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
Workflow for 1,2:
![workflow graph](https://github.com/ytrqua3/term-project3280/blob/a5ca99bf960f2c5d2f982420f44adebc5401067b/assets/workflow.png)

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

Glue ETL Jobs 

  1. Music_csv_to_parquet: transforms csv uploaded to term-project3280/user_data/ into parquet format and store in term-project3280/raw_parquet/ then delete the csv file to free up storage 

  2. Aggregate_data: produce artist_rank_in_country and country_rank_per_artist table then store in term-project3280/processed_parquet/ 

  3. Embedding_job: produce user embedding table then store term-project3280/processed_parquet/ 

 

Lambda Function 

  1. CreateCrawlerForMusicData: create and run raw_data_crawler 

  2. CreateCrawlerForProcessedData: create and run processed_data_crawler 

  3. CreateCrawlerForEmbedding: create and run embedding_data_crawler 

  4. Raw_csv_update_trigger: start music_csv_to_parquet glue job 

  5. Start_aggregate_job: start aggregate_data glue job 

  6. Start_embedding_job: start embedding_job glue job 

  7. Raw_parquet_distributer: invokes CreateCrawlerForMusicData and	Start_aggregate_job 

  8. ApiQueryHandler: accepts post request with sql query as body and responses with json format of query result 

 

Lambda Layer: Boto3, numpy, pandas 

Glue DataBase 
  - Music_db
      -> raw_parquet_user_data 
      -> raw_parquet_user_top_artists
      -> processed_parquet_country_rank_per_artist 
      -> processed_parquet_artist_rank_in_country
      -> processed_parquet_user_embedding 

Glue Crawlers 
  - raw_data_crawler: term-project3280/raw_parquet/user_data/ and term-project3280/raw_parquet/user_top_artists/ 
  - processed_data_crawler: term-project3280/processed_parquet/artist_rank_in_country/ and term-project3280/processed_parquet/country_rank_per_artist/ 
  - embedding_data_crawler: term-project3280/processed_parquet/user_embedding/ 

<h3>Glue ETL Explaination </h3>
  - Music_csv_to_parquet 
      1. Store all csv object paths under user_data folder into raw_csv_s3_paths variable 
      2. Loop through all the csv objects to convert them into pyspark dataframe then write them in parquet format into raw_parquet folder (I used append instead of overwrite mode when writing parquet to ensure that new csv files can be added to the collection of data to ensure scalability) 
      3. Delete all the csv objects to save up space
      4. Invoke raw_parquet_disributer to automate the further steps 

  - Aggregate_data (artist_rank_in_country) 
      1. Inner join the two dataframes so each user has a country attribute
      2. Find the total playcount of each artist in each country using groupby and sum
      3. Add a column for the artist’s rank in country using Window(for each country put the artists in descending order of playcount)
      4. Store the dataframe in s3 

   - Aggregate_data (country_rank_per_artist) 
      1. Get each countries’ total playcount using groupby
      2. Join the dataframe with playcount of each artist in each country with the country total playcount dataframe
      3. Calculate normalized_popularity of artist in a certain country by Artist's playcount in country / country total playcount
      5. Add a column for the country’s rank for that artist using Window(one artist as a group)
      6. Store the dataframe to s3 

  - Embedding_job 
      Purpose: get a vector that describes each artist, the closer the vectors of two artists 		are, the more similar their styles are. (they appear in similar context) 
      *Note that the sequence fed into word2vec model is weighted, so artists with more 	playcount has a higher weight 
      1. Get weight column: weight = round(1+log10(playcount)) , this is log scaled
      2. Have a row repeat itself according to weight using explode function
      3. Form artist_sequence for each user using groupby user_id then collect artist column as a list (since it is exploaded, the weight is applied)
      4. Now the dataframe is a sequence of artists per user, feed that into word2vec
      5. Obtain the vectors for each artist then store it in s3. 

 

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


