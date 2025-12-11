
provider "aws" {
  region = "us-west-2"
}

# Buckets
resource "aws_s3_bucket" "project_bucket" {
  bucket        = "term-project3280"
  force_destroy = true 
}

# Top-level folders
resource "aws_s3_object" "user_data_folder" {
  bucket = aws_s3_bucket.project_bucket.bucket
  key    = "user_data/"
}

resource "aws_s3_object" "raw_parquet_folder" {
  bucket = aws_s3_bucket.project_bucket.bucket
  key    = "raw_parquet/"
}

resource "aws_s3_object" "processed_parquet_folder" {
  bucket = aws_s3_bucket.project_bucket.bucket
  key    = "processed_parquet/"
}

# Subfolders in user_data
resource "aws_s3_object" "user_data_user_data_subfolder" {
  bucket = aws_s3_bucket.project_bucket.bucket
  key    = "user_data/user_data/"
}

resource "aws_s3_object" "user_data_user_top_artists_subfolder" {
  bucket = aws_s3_bucket.project_bucket.bucket
  key    = "user_data/user_top_artists/"
}

# Subfolders in raw_parquet
resource "aws_s3_object" "raw_parquet_user_top_artists" {
  bucket = aws_s3_bucket.project_bucket.bucket
  key    = "raw_parquet/user_top_artists/"
}

resource "aws_s3_object" "raw_parquet_user_data" {
  bucket = aws_s3_bucket.project_bucket.bucket
  key    = "raw_parquet/user_data/"
}

# Subfolders in processed_parquet
resource "aws_s3_object" "processed_artist_rank_in_country" {
  bucket = aws_s3_bucket.project_bucket.bucket
  key    = "processed_parquet/artist_rank_in_country/"
}

resource "aws_s3_object" "processed_country_rank_per_artist" {
  bucket = aws_s3_bucket.project_bucket.bucket
  key    = "processed_parquet/country_rank_per_artist/"
}

resource "aws_s3_object" "processed_user_embedding" {
  bucket = aws_s3_bucket.project_bucket.bucket
  key    = "processed_parquet/user_embedding/"
}

#Athena results
resource "aws_s3_object" "athena_results_folder" {
  bucket = aws_s3_bucket.project_bucket.bucket
  key    = "athena_results/"
}
