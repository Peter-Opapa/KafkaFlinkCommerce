import json
import random
import time

from faker import Faker
from confluent_kafka import SerializingProducer
from datetime import datetime, timezone

fake = Faker()

def generate_sales_transactions():
    user = fake.simple_profile()

    return {
        "transactionId": fake.uuid4(),
        "userId": user['username'],
        "transactionType": random.choice(['purchase', 'refund', 'transfer']),
        "amount": round(random.uniform(10, 1000), 2),
        "currency": random.choice(['USD', 'GBP', 'EUR']),
        "transactionDate": datetime.now(timezone.utc).strftime('%Y-%m-%dT%H:%M:%S'),  # Match expected format
        "category": random.choice(['electronics', 'fashion', 'grocery', 'home', 'beauty', 'sports']),
        "merchant": random.choice(['Amazon', 'Walmart', 'Target', 'BestBuy', 'Apple Store', 'Nike']),
        "location": fake.city() + ", " + fake.country()
    }

def delivery_report(err, msg):
    if err is not None:
        print(f'Message delivery failed: {err}')
    else:
        print(f"Message delivered to {msg.topic} [{msg.partition()}]")
def main():
    topic = 'financial_transactions'
    producer = SerializingProducer({
        'bootstrap.servers': 'localhost:9092',
        # Safer defaults for dev
        'enable.idempotence': True,
        'acks': 'all',
    })

    curr_time = datetime.now()

    try:
        while (datetime.now() - curr_time).total_seconds() < 10000000000000000000:
            try:
                transaction = generate_sales_transactions()

                print(transaction)

                producer.produce(
                    topic,
                    key=str(transaction['transactionId']).encode('utf-8'),
                    value=json.dumps(transaction).encode('utf-8'),
                    on_delivery=delivery_report,
                )
                # Serve delivery callbacks
                producer.poll(0)

                # waiting for 1 second before sending the next transaction
                time.sleep(1)
            except BufferError:
                print("Buffer full! Waiting...")
                # Giving the producer a moment to deliver queued messages
                producer.poll(1)
                time.sleep(1)
            except Exception as e:
                print(e)
    finally:
        # Ensuring all queued messages are delivered before exit
        producer.flush(10)

if __name__ == "__main__":
    main()