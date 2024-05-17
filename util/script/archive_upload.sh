#!/bin/bash

# Function to display usage
usage() {
  echo "Usage: $0 -p <project_id> -b <bucket_name/destination_path> -s <source_dir> -o <output_zip_path>"
  exit 1
}

# Parse command-line arguments
while getopts ":p:b:s:o:" opt; do
  case $opt in
    p) PROJECT_ID="$OPTARG"
    ;;
    b) BUCKET_DESTINATION="$OPTARG"
    ;;
    s) SOURCE_DIR="$OPTARG"
    ;;
    o) OUTPUT_ZIP_PATH="$OPTARG"
    ;;
    *) usage
    ;;
  esac
done

# Check if all required arguments are provided
if [ -z "$PROJECT_ID" ] || [ -z "$BUCKET_DESTINATION" ] || [ -z "$SOURCE_DIR" ] || [ -z "$OUTPUT_ZIP_PATH" ]; then
  usage
fi

# Ensure gcloud is authenticated and set the project
# gcloud auth login
# gcloud config set project $PROJECT_ID

# Zip the source directory
echo "Zipping the source directory..."
zip -r $OUTPUT_ZIP_PATH $SOURCE_DIR

# Upload the zip file to the specified path in the storage bucket
echo "Uploading zip file to Google Cloud Storage..."
gsutil cp $OUTPUT_ZIP_PATH gs://$BUCKET_DESTINATION

# Clean up the local zip file
echo "Cleaning up local zip file..."
rm $OUTPUT_ZIP_PATH

echo "Done! The zip file has been uploaded to gs://$BUCKET_DESTINATION"
