# Raw Parquet Crawler
resource "aws_glue_crawler" "raw_parquet_crawler" {
  name              = "raw_parquet_crawler"
  database_name     = "music_db"
  role              = aws_iam_role.GlueCrawlerFromS3Role.arn  # replace with your role
  s3_target {path   = "s3://term-project3280/raw_parquet/user_data/"}
  s3_target {path   = "s3://term-project3280/raw_parquet/user_top_artists/"}
  table_prefix      = "raw_parquet_"
}

#Processed Parquet Crawler
resource "aws_glue_crawler" "processed_parquet_rank_crawler" {
  name              = "processed_parquet_rank_crawler"
  database_name     = "music_db"
  role              = aws_iam_role.GlueCrawlerFromS3Role.arn
  s3_target {path   = "s3://term-project3280/processed_parquet/artist_rank_in_country/"}
  s3_target {path   = "s3://term-project3280/processed_parquet/country_rank_per_artist/"}
  table_prefix      = "processed_parquet_"
}

#User Embedding Crawler
resource "aws_glue_crawler" "processed_parquet_user_embedding_crawler" {
  name              = "processed_parquet_user_embedding_crawler"
  database_name     = "music_db"
  role              = aws_iam_role.GlueCrawlerFromS3Role.arn
  s3_target {path   = "s3://term-project3280/processed_parquet/user_embedding/"}
  table_prefix      = "processed_parquet_"
}

#music_db
resource "aws_glue_catalog_database" "music_db" {
  name        = "music_db"
  description = "Database for music datasets"
}