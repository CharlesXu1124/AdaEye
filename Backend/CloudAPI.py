# dependencies imports
import requests
import json
import numpy as np
import json

from flask import Flask
from flask import request
import openai
import os


app = Flask(__name__)


@app.route('/')
def index():
    return 'invalid call'


@app.route('/updateLabels', methods=['GET', 'POST'])
def updateLabels():
    global item0
    global item1
    global item2
    global item3
    global item4
    data = request.data
    loaded_json = json.loads(data)
    item0 = loaded_json["label0"]
    item1 = loaded_json["label1"]
    item2 = loaded_json["label2"]
    item3 = loaded_json["label3"]
    item4 = loaded_json["label4"]

    print(item0, item1, item2, item3, item4)
    return json.dumps("1")

@app.route('/getLabels', methods=['GET'])
def returnLabels():
    global item0
    global item1
    global item2
    global item3
    global item4
    return json.dumps([item0, item1, item2, item3, item4])

@app.route('/qna', methods=['GET', 'POST'])
def getAnswer():
    data = request.data
    loaded_json = json.loads(data)
    q = loaded_json["question"]
    
    
    openai.api_key = "YOOUR API KEY"

    response = openai.Completion.create(
    engine="davinci",
    prompt="The following is a conversation with an AI assistant. The assistant is helpful, creative, clever, and very friendly.\n\nHuman: %s?\nAI:" % q,
    temperature=0.9,
    max_tokens=150,
    top_p=1,
    frequency_penalty=0.0,
    presence_penalty=0.6,
    stop=["\n", " Human:", " AI:"]
    )

    return json.dumps(response)


if __name__ == "__main__":
    global item0
    global item1
    global item2
    global item3
    global item4
    app.run(host='0.0.0.0', port=5000)