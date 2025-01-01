#!/usr/bin/env python

from sagemaker_inference import model_server

if __name__ == "__main__":
    model_server.start_model_server(handler_service="/opt/program/predictor:handle")
