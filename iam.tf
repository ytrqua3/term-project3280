# Create IAM Roles
resource "aws_iam_role" "crawlRawDataLambdaCustome" {
  name               = "crawlRawDataLambdaCustome"
  assume_role_policy = file("Roles/crawlRawDataLambdaCustome.json")
}

resource "aws_iam_role" "Glue_csv_to_parquet" {
  name               = "Glue_csv_to_parquet"
  assume_role_policy = file("Roles/Glue_csv_to_parquet.json")
}

resource "aws_iam_role" "GlueAggregateDataTermProjectRole" {
  name               = "GlueAggregateDataTermProjectRole"
  assume_role_policy = file("Roles/GlueAggregateDataTermProjectRole.json")
}

resource "aws_iam_role" "GlueCrawlerFromS3Role" {
  name               = "GlueCrawlerFromS3Role"
  assume_role_policy = file("Roles/GlueCrawlerFromS3Role.json")
}

resource "aws_iam_role" "LambdaStartGlueRole" {
  name               = "LambdaStartGlueRole"
  assume_role_policy = file("Roles/LambdaStartGlueRole.json")
}

resource "aws_iam_role" "LambdaQueryApiRole" {
  name               = "LambdaQueryApiRole"
  assume_role_policy = file("Roles/LambdaQueryApiRole.json")
}

# Create IAM Policies

resource "aws_iam_policy" "LambdaCreateCrawlerPolicy" {
  name   = "LambdaCreateCrawlerPolicy"
  policy = file("Policies/LambdaCreateCrawlerPolicy.json")
}

resource "aws_iam_policy" "GlueCsvToParquetCustomePolicy" {
  name   = "GlueCsvToParquetCustomePolicy"
  policy = file("Policies/GlueCsvToParquetCustomePolicy.json")
}

resource "aws_iam_policy" "GlueAggregateTermProjectPolicy" {
  name   = "GlueAggregateTermProjectPolicy"
  policy = file("Policies/GlueAggregateTermProjectPolicy.json")
}

resource "aws_iam_policy" "GlueCrawlerPolicy" {
  name   = "GlueCrawlerPolicy"
  policy = file("Policies/GlueCrawlerPolicy.json")
}

resource "aws_iam_policy" "LambdaStartGlueJobs" {
  name   = "LambdaStartGlueJobs"
  policy = file("Policies/LambdaStartGlueJobs.json")
}

resource "aws_iam_policy" "LambdaQueryApiPolicy" {
  name   = "LambdaQueryApiPolicy"
  policy = file("Policies/LambdaQueryApiPolicy.json")
}


#Attach policies to roles
resource "aws_iam_role_policy_attachment" "attach1" {
  role       = aws_iam_role.crawlRawDataLambdaCustome.name
  policy_arn = aws_iam_policy.LambdaCreateCrawlerPolicy.arn
}

resource "aws_iam_role_policy_attachment" "attach2" {
  role       = aws_iam_role.Glue_csv_to_parquet.name
  policy_arn = aws_iam_policy.GlueCsvToParquetCustomePolicy.arn
}

resource "aws_iam_role_policy_attachment" "attach3" {
  role       = aws_iam_role.GlueAggregateDataTermProjectRole.name
  policy_arn = aws_iam_policy.GlueAggregateTermProjectPolicy.arn
}

resource "aws_iam_role_policy_attachment" "attach4" {
  role       = aws_iam_role.GlueCrawlerFromS3Role.name
  policy_arn = aws_iam_policy.GlueCrawlerPolicy.arn
}

resource "aws_iam_role_policy_attachment" "attach5" {
  role       = aws_iam_role.LambdaStartGlueRole.name
  policy_arn = aws_iam_policy.LambdaStartGlueJobs.arn
}

resource "aws_iam_role_policy_attachment" "attach6" {
  role       = aws_iam_role.LambdaQueryApiRole.name
  policy_arn = aws_iam_policy.LambdaQueryApiPolicy.arn
}
