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

import boto3

s3 = boto3.client('s3')
bucket_name = 'term-project3280'
prefix = 'user_data'
suffix = '.csv'
raw_csv_s3_paths = []
response = s3.list_objects(Bucket=bucket_name)
for obj in response['Contents']:
    if obj['Key'].endswith(suffix) and obj['Key'].startswith(prefix):
        raw_csv_s3_paths.append(obj['Key'])
        
raw_csv_s3_paths
csv_files_to_delete = []
for s3_path in raw_csv_s3_paths:
    df = spark.read.csv(f"s3://{bucket_name}/{s3_path}", header=True, inferSchema=True)
    subfolder_name = s3_path.split('/')[1]
    parquet_file_path = f"s3://{bucket_name}/raw_parquet/{subfolder_name}/"
    df.write.mode("append").parquet(f"s3://{bucket_name}/raw_parquet/{subfolder_name}/")
    csv_files_to_delete.append({"Key": s3_path}) 
    print(parquet_file_path)
s3.delete_objects(
    Bucket=bucket_name,
    Delete={"Objects": csv_files_to_delete}
)
import json
lambda_client = boto3.client('lambda')
lambda_client.invoke(
    FunctionName="raw_parquet_distributer",
    InvocationType="Event",
    Payload=json.dumps({})
)
## stop the current session

job.commit()