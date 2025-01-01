# Dockerfile

# Use the official PyTorch image as base
FROM pytorch/pytorch:1.13.1-cuda11.6-cudnn8-runtime

# Set the working directory
WORKDIR /opt/program

# Copy the code
COPY app/ /opt/program

# Install requirements
RUN pip install --no-cache-dir -r /opt/program/requirements.txt

# Expose the port
EXPOSE 8080

# Define environment variables
ENV PYTHONUNBUFFERED=TRUE
ENV PYTHONDONTWRITEBYTECODE=TRUE

# Set the entrypoint
ENTRYPOINT ["python", "serve"]
