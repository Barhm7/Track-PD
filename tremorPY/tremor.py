import firebase_admin
from firebase_admin import credentials
from firebase_admin import firestore
from flask import Flask, request, jsonify
from datetime import datetime

# Initialize Flask app
app = Flask(__name__)

# Initialize Firestore database
cred = credentials.Certificate('track-pd-firebase-adminsdk-drwp1-41035398ca.json')
firebase_admin.initialize_app(cred)
db = firestore.client()

# Endpoint to receive tremor data from Xcode
@app.route('/tremor', methods=['POST'])
def receive_tremor_data():
    tremor_data = request.get_json()
    
    # Add the time of detection
    tremor_data['time'] = datetime.now().strftime("%H:%M") # Store time as HH:MM format
    
    # Store the tremor data in Firestore
    doc_ref = db.collection('tremorstest').document()
    doc_ref.set(tremor_data)

    # Print the received tremor data to the console
    print("Received Tremor Data:")
    print("Intensity:", tremor_data.get("intensity"))
    print("Situation:", tremor_data.get("situation"))
    print("Time:", tremor_data.get("time"))

    return jsonify({'message': 'Tremor data received'})

# Run the Flask app
if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8880)
