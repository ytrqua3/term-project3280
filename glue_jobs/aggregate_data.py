import sys
from awsglue.transforms import *
from awsglue.utils import getResolvedOptions
from pyspark.context import SparkContext
from awsglue.context import GlueContext
from awsglue.job import Job

sc = SparkContext.getOrCreate()
glueContext = GlueContext(sc)
spark = glueContext.spark_session
job = Job(glueContext)
#build pyspark dataframes
user_df = spark.read.parquet("s3://term-project3280/raw_parquet/user_data/")
top_artists_df = spark.read.parquet("s3://term-project3280/raw_parquet/user_top_artists/")
user_df.show(5)
top_artists_df.show(5)
from pyspark.sql import functions as F

joined = top_artists_df.join(
    user_df.select("user_id", "country"),
    on="user_id",
    how="inner"
)

joined.show(5)
artist_country_playcounts = (
    joined.groupBy("country", "artist_name")
          .agg(F.sum("playcount").alias("total_playcount"))
)

artist_country_playcounts.show(5)
from pyspark.sql import Window

#e.g.Who are the top artists in Canada?

window_spec = (
    Window
    .partitionBy("country")
    .orderBy(F.col("total_playcount").desc())
)

output_ranked_playcount_df = (
    artist_country_playcounts
    .withColumn("rank", F.row_number().over(window_spec))
).filter(F.col('country').isNotNull())
output_ranked_playcount_df.show() #this is one output table!!!
#compute total playcount of countries
country_total_playcount = (
    output_ranked_playcount_df
    .groupBy("country")
    .agg(F.sum("total_playcount").alias("country_total_playcount"))
)

country_total_playcount.show(5)
#join into ranked_country_aritst_playcount_df
df_with_totals = (
    artist_country_playcounts
    .join(country_total_playcount, on="country", how="inner")
)

df_with_totals.show(5)
#map the country playcount column to normalize popularity
#Which countries does Drake perform best in?
normalized_popularity_df = (
    df_with_totals
    .withColumn(
        "normalized_popularity",
        F.col("total_playcount") / F.col("country_total_playcount")
    ).drop('country_total_playcount')
)
normalized_popularity_df.show(5)
#add column for ranking each artists' popularity in each country
window_spec = (
    Window
    .partitionBy("artist_name")
    .orderBy(F.col("normalized_popularity").desc())
)
output_normalized_popularity_df = (
    normalized_popularity_df
    .withColumn("rank", F.row_number().over(window_spec))
)

output_normalized_popularity_df.show(5)
#store output to s3 as parquet
bucket_name = 'term-project3280'
output_ranked_playcount_df.write.mode("overwrite").partitionBy("country").parquet(f"s3://{bucket_name}/processed_parquet/artist_rank_in_country/")
output_normalized_popularity_df.write.mode("overwrite").parquet(f"s3://{bucket_name}/processed_parquet/country_rank_per_artist/")
#invoke lambda for crawler for automation
import boto3
import json
lambda_client = boto3.client('lambda')
lambda_client.invoke(
    FunctionName="createCrawlerForProcessedMusicData",
    InvocationType="Event",
    Payload=json.dumps({})
)
job.commit()