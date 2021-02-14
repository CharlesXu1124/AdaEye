import asyncio
from aio_pika import connect, IncomingMessage
import serial
import cv2
import time
import io
import os
from google.cloud import vision
from aio_pika import connect, Message
import requests
import json

os.environ["GOOGLE_APPLICATION_CREDENTIALS"] = "service.json"

# Instantiates a client
client = vision.ImageAnnotatorClient()

# The name of the image file to annotate
file_name = os.path.abspath('capture.png')

cam = cv2.VideoCapture(1)

s = serial.Serial('COM4',9600, timeout=.1)

async def on_message(message: IncomingMessage):
    """
    on_message doesn't necessarily have to be defined as async.
    Here it is to show that it's possible.
    """
    # print(" [x] Received message %r" % message)
    print("Message body is: %r" % message.body)
    # send the command for grabbing!

    if message.body == b'left':
        s.write('1'.encode())
        time.sleep(2)
        _, image = cam.read()
        cv2.imwrite('capture.png', image)

    
    if message.body == b'right':
        s.write('2'.encode())
        time.sleep(2)
        _, image = cam.read()
        cv2.imwrite('capture.png', image)

    if message.body == b'front':
        time.sleep(2)
        _, image = cam.read()
        cv2.imwrite('capture.png', image)

    with io.open(file_name, 'rb') as image_file:
        content = image_file.read()

    image = vision.types.Image(content=content)

    # Performs label detection on the image file
    response = client.label_detection(image=image)
    labels = response.label_annotations

    print('Labels:')
    for label in labels:
        print(label.description)

    upload_labels(labels)
    
    print("Before sleep!")
    await asyncio.sleep(1000)  # Represents async I/O operations
    print("After sleep!")


def upload_labels(labels):
    URL = "http://ec2-54-90-166-180.compute-1.amazonaws.com:5000/updateLabels"
  
    # defining a params dict for the parameters to be sent to the API 
    PARAMS = {"label0": str(labels[0].description),
    "label1": str(labels[1].description),
    "label2": str(labels[2].description),
    "label3": str(labels[3].description),
    "label4": str(labels[4].description)
    }

    payload = json.dumps(PARAMS)

    # print(str(labels[0].description))
    
    # sending get request and saving the response as response object 
    r = requests.post(URL, payload) 
    
    # extracting data in json format 



async def main(loop):
    # Perform connection
    # please use your own rabbitMQ server
    connection = await connect(
        "amqp://user2:rtc2021@168.61.18.117", loop=loop
    )

    # Creating a channel
    channel = await connection.channel()

    # Declaring queue
    queue = await channel.declare_queue("hello")

    # Start listening the queue with name 'hello'
    await queue.consume(on_message, no_ack=True)


if __name__ == "__main__":
    loop = asyncio.get_event_loop()
    loop.create_task(main(loop))

    # we enter a never-ending loop that waits for data and
    # runs callbacks whenever necessary.
    print(" [*] Waiting for messages. To exit press CTRL+C")
    loop.run_forever()