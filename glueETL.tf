#prepare s3 bucket folder for scripts
resource "aws_s3_object" "csv_to_parquet_script" {
  bucket = "term-project3280"
  key    = "glue_jobs/csv_to_parquet.py"   
  source = "glue_jobs/csv_to_parquet.py"  
  depends_on = [
    aws_s3_bucket.project_bucket
  ]
}

resource "aws_s3_object" "aggregate_data_script" {
  bucket = "term-project3280"
  key    = "glue_jobs/aggregate_data.py"
  source = "glue_jobs/aggregate_data.py"
  depends_on = [
    aws_s3_bucket.project_bucket
  ]
}

resource "aws_s3_object" "embedding_job_script" {
  bucket = "term-project3280"
  key    = "glue_jobs/embedding_job.py"
  source = "glue_jobs/embedding_job.py"
  depends_on = [
    aws_s3_bucket.project_bucket
  ]
}

# csv_to_parquet
resource "aws_glue_job" "csv_to_parquet" {
  name     = "music_csv_to_parquet"
  role_arn = aws_iam_role.Glue_csv_to_parquet.arn

  command {
    name            = "glueetl"
    script_location = "s3://term-project3280/glue_jobs/csv_to_parquet.py"
    python_version  = "3"
  }

  glue_version = "3.0"
  max_capacity  = 2
}

# aggregate_data
resource "aws_glue_job" "aggregate_data" {
  name     = "aggregate_data"
  role_arn = aws_iam_role.GlueAggregateDataTermProjectRole.arn

  command {
    name            = "glueetl"
    script_location = "s3://term-project3280/glue_jobs/aggregate_data.py"
    python_version  = "3"
  }

  glue_version = "3.0"
  max_capacity  = 2
}

# embedding_job
resource "aws_glue_job" "embedding_job" {
  name     = "embedding_job"
  role_arn = aws_iam_role.GlueAggregateDataTermProjectRole.arn

  command {
    name            = "glueetl"
    script_location = "s3://term-project3280/glue_jobs/embedding_job.py"
    python_version  = "3"
  }

  glue_version = "3.0"
  max_capacity  = 2
}

