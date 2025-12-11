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
#Step 1: add weight to df from playcount
#weight is 1+log(playcount)

from pyspark.sql import functions as F
from pyspark.sql.functions import col, collect_list, log10, explode, array_repeat, round

weighted_df = (
    top_artists_df
        .withColumn("play_weight", 1 + log10(col("playcount")))
        # weight is float, but array_repeat needs integer → round
        .withColumn("weight_int", round(col("play_weight")).cast("int"))
).drop(col("play_weight"))

weighted_df.show(5)
#Step 2: expand each row into part of sentence

expanded_df = (
    weighted_df
        .withColumn("artist_weighted", array_repeat("artist_name", col("weight_int")))
        .withColumn("artist", explode("artist_weighted"))
)
expanded_df.show(5)
#Step 3: get sequence for each user

artist_sequences = (
    expanded_df
        .select("user_id", "rank", "artist")
        .orderBy("user_id", "rank")
        .groupBy("user_id")
        .agg(collect_list("artist").alias("artist_sequence"))
)
artist_sequences.show(5)
#Step 4: train the model

from pyspark.ml.feature import Word2Vec
word2vec = Word2Vec(
    vectorSize=50,
    windowSize=5,
    minCount=1,
    inputCol="artist_sequence",
    outputCol="artist_embedding"
)
w2v_model = word2vec.fit(artist_sequences)
w2v_model.getVectors().show(5)
#Step 5: form embedding dataframe
from pyspark.ml.functions import vector_to_array
embedding_cols = [col("embedding_array")[i].alias(f"dim_{i}") for i in range(50)]

artist_embeddings = (
    w2v_model.getVectors()
        .withColumn("embedding_array", vector_to_array("vector"))
        .select(
            col("word").alias("artist_name"),
            *embedding_cols  # unpack vector dimensions
        )
)
artist_embeddings.first()
#store output to s3 as parquet
bucket_name = 'term-project3280'
artist_embeddings.write.mode("overwrite").parquet(f"s3://{bucket_name}/processed_parquet/user_embedding/")
#invoke create crawler lambda function for the table
import boto3
import json
lambda_client = boto3.client('lambda')
lambda_client.invoke(
    FunctionName="createCrawlerForEmbedding",
    InvocationType="Event",
    Payload=json.dumps({})
)
job.commit()