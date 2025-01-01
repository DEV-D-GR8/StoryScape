import boto3
from botocore.exceptions import ClientError
import logging
from django.http import StreamingHttpResponse
from django.conf import settings

logger = logging.getLogger(__name__)

# Initialize AWS S3 client
s3_client = boto3.client(
    's3',
    aws_access_key_id=settings.AWS_ACCESS_KEY_ID,
    aws_secret_access_key=settings.AWS_SECRET_ACCESS_KEY,
    region_name=settings.AWS_REGION
)

S3_BUCKET_NAME = settings.S3_BUCKET_NAME

def check_s3_for_audio(filename):
    """Check if audio file exists in S3"""
    try:
        s3_client.head_object(Bucket=S3_BUCKET_NAME, Key=filename)
        return True
    except ClientError as e:
        if e.response['Error']['Code'] == '404':
            return False
        else:
            raise e

def upload_to_s3(audio_bytes, filename):
    """Upload audio file to S3"""
    try:
        audio_bytes.seek(0)
        s3_client.upload_fileobj(
            audio_bytes,
            S3_BUCKET_NAME,
            filename,
            ExtraArgs={'ContentType': 'audio/mpeg'}
        )
        logger.info(f"Successfully uploaded {filename} to S3")
    except Exception as e:
        logger.error(f"Failed to upload to S3: {str(e)}")
        raise Exception(f"Failed to upload to S3: {str(e)}")

def get_audio_stream_from_s3(filename):
    """Get audio file from S3 and return as StreamingHttpResponse"""
    try:
        response = s3_client.get_object(Bucket=S3_BUCKET_NAME, Key=filename)

        def iterate_response():
            for chunk in response['Body'].iter_chunks(chunk_size=8192):
                yield chunk

        return StreamingHttpResponse(
            iterate_response(),
            content_type="audio/mpeg",
            headers={
                "Content-Disposition": f"attachment; filename={filename}"
            }
        )
    except Exception as e:
        logger.error(f"Failed to get audio from S3: {str(e)}")
        raise Exception(f"Failed to get audio from S3: {str(e)}")
