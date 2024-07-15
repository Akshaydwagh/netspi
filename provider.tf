provider "aws" {
  region = "us-east-1"  
  shared_credentials_files = "C/Users/Lenovo/Desktop/TF_Space/access.txt"
  profile                 = "profile_name"  // Optional: Use a named profile
}
