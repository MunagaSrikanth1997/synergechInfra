provider "aws"{
region="us-east-1"

assume_role{
role_arn="arn:aws:iam::845119702206:role/synergechInfra"
}
}