import os
import json
import torch
from transformers import LlamaForCausalLM, LlamaTokenizer
from sagemaker_inference import content_types, default_inference_handler

class LlamaPredictor:
    def __init__(self):
        self.device = torch.device('cuda' if torch.cuda.is_available() else 'cpu')
        model_dir = '/opt/ml/model'
        self.tokenizer = LlamaTokenizer.from_pretrained(model_dir)
        self.model = LlamaForCausalLM.from_pretrained(model_dir).to(self.device)
        self.model.eval()

    def predict(self, input_text, max_length=100, temperature=0.7):
        inputs = self.tokenizer.encode(input_text, return_tensors='pt').to(self.device)
        with torch.no_grad():
            outputs = self.model.generate(
                inputs,
                max_length=max_length,
                temperature=temperature,
                num_return_sequences=1
            )
        generated_text = self.tokenizer.decode(outputs[0], skip_special_tokens=True)
        return generated_text

_predictor = None

def handle(data, context):
    global _predictor
    if _predictor is None:
        _predictor = LlamaPredictor()

    if context.request_content_type == 'application/json':
        input_data = json.loads(data.read().decode('utf-8'))
        prompt = input_data['prompt']
        generated_text = _predictor.predict(prompt)
        response = {'generated_text': generated_text}
        return [json.dumps(response).encode('utf-8')]

    else:
        raise ValueError(f"Unsupported content type: {context.request_content_type}")
