import os
import json
import requests
from flask import Flask, request
from datetime import datetime

APP_ID = os.environ.get('APP_ID', 'unknown_app')
PEERS = os.environ.get('PEERS', '').split(',')
LOG_FILE = f'/data/logs/{APP_ID}_messages.json' 

app = Flask(__name__)

def load_messages():
    if not os.path.exists(LOG_FILE):
        return []
    try:
        with open(LOG_FILE, 'r') as f:
            return [json.loads(line) for line in f if line.strip()]
    except Exception:
        return []

def save_message(message_data, source):
    timestamp = datetime.now().isoformat()
    log_entry = {
        "timestamp": timestamp,
        "app_id": APP_ID,
        "source": source,
        "message": message_data.get("message"),
        "original_app": message_data.get("original_app", APP_ID),
        "original_timestamp": message_data.get("original_timestamp", timestamp),
        "data": message_data
    }
    
    os.makedirs(os.path.dirname(LOG_FILE), exist_ok=True)
    with open(LOG_FILE, 'a') as f:
        f.write(json.dumps(log_entry) + '\n')
    
    return log_entry

def replicate_to_peers(message_data):
    successful_peers = []
    
    message_data['original_app'] = APP_ID
    message_data['original_timestamp'] = datetime.now().isoformat()
    
    for peer in PEERS:
        if not peer: continue
        try:
            url = f"http://{peer}/send?replicated=true"
            requests.post(url, json=message_data, timeout=1) 
            successful_peers.append(peer)
        except requests.exceptions.RequestException as e:

            pass 
            
    return successful_peers

@app.route('/send', methods=['POST'])
def send_message():
    message_data = request.get_json(silent=True)
    if not message_data or 'message' not in message_data:
        return {"error": "JSON inválido ou campo 'message' ausente."}, 400

    is_replicated = request.args.get('replicated') == 'true'
    
    if is_replicated:
        source = "replicated_from_peer"
        save_message(message_data, source)
        return {"status": "replicado", "app": APP_ID}, 200
    else:

        source = "original_request"
        saved_entry = save_message(message_data, source)
        
        successful_peers = replicate_to_peers(message_data)
        
        return {
            "status": "recebido_e_replicado",
            "app": APP_ID,
            "message": saved_entry,
            "replicado_para": successful_peers
        }, 200

@app.route('/messages', methods=['GET'])
def get_messages():
    messages = load_messages()
    return {
        "app_id": APP_ID,
        "total_messages": len(messages),
        "messages": messages
    }, 200
