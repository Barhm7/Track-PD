from flask import Flask, send_from_directory
from reportlab.lib.pagesizes import A4, landscape
from reportlab.lib import colors
from reportlab.lib.units import cm
from reportlab.platypus import Table, TableStyle
from reportlab.pdfgen import canvas
from firebase_admin import firestore
from firebase_admin import credentials
import firebase_admin
from reportlab.lib.pagesizes import letter
import matplotlib.pyplot as plt
from reportlab.graphics.shapes import Drawing
from reportlab.lib.units import inch
import os

app = Flask(__name__)

# Connect Python with Firebase
cred = credentials.Certificate("track-pd-firebase-adminsdk.json")
firebase_admin.initialize_app(cred)

db = firestore.client()
# Get the users collection
users_ref = db.collection('users').document("h2MWRvrFY1XiInFR6xh5")
user_data = users_ref.get().to_dict()
# Get the activities
activities_ref = db.collection('users').document(
    "ICHIwHSqwmhucxWc3C6KQ096DSY2").collection('activity')
activities = activities_ref.get()
# Get tremor values
tremor_ref = db.collection('tremors')
tremor_data = tremor_ref.get()

# Create lists for time and intensity values
time_values = []
intensity_values = []

# Extract time and intensity values from tremor data
for tremor in tremor_data:
    tremor_dict = tremor.to_dict()
    time_values.append(tremor_dict.get('time'))
    intensity_values.append(tremor_dict.get('intensity'))

# Create the tremor graph
fig_tremor, ax_tremor = plt.subplots()
ax_tremor.plot(time_values, intensity_values)
ax_tremor.set_title('Tremor Report')
ax_tremor.set_xlabel('Time')
ax_tremor.set_ylabel('Intensity')

# Save the tremor graph as an image
tremor_graph_file = 'tremor_graph.png'
plt.savefig(tremor_graph_file)
plt.close(fig_tremor)


# Define the table data
table_data = [['Name', 'Age', 'Gender', 'Height', 'Weight',
               'Bradykiness', 'Dyskinesia', 'PD Duration', 'Tremor']]

# Add the user information to the table data
data = []
data.append(user_data.get('name', ''))
data.append(str(user_data.get('age', '')))
data.append(user_data.get('gender', ''))
data.append(str(user_data.get('height', '')))
data.append(str(user_data.get('weight', '')))
data.append(user_data.get('Bradykinesia', ''))
data.append(user_data.get('Dyskinesia', ''))
data.append(user_data.get('PD duration', ''))
data.append(user_data.get('Tremor', ''))
table_data.append(data)

# Define the table style
table_style = TableStyle([
    ('BACKGROUND', (0, 0), (-1, 0), colors.HexColor('#1E90FF')),
    ('TEXTCOLOR', (0, 0), (-1, 0), colors.whitesmoke),
    ('ALIGN', (0, 0), (-1, 0), 'CENTER'),
    ('FONTNAME', (0, 0), (-1, 0), 'Helvetica-Bold'),
    ('FONTSIZE', (0, 0), (-1, 0), 14),
    ('BOTTOMPADDING', (0, 0), (-1, 0), 12),
    ('BACKGROUND', (0, 1), (-1, -1), colors.beige),
    ('TEXTCOLOR', (0, 1), (-1, -1), colors.black),
    ('ALIGN', (0, 1), (-1, -1), 'LEFT'),
    ('FONTNAME', (0, 1), (-1, -1), 'Helvetica'),
    ('FONTSIZE', (0, 1), (-1, -1), 12),
    ('VALIGN', (0, 0), (-1, -1), 'MIDDLE'),
    ('GRID', (0, 0), (-1, -1), 1, colors.black),
    ('TOPPADDING', (0, 0), (-1, -1), 20),
    ('BOTTOMPADDING', (0, 0), (-1, -1), 20),
    ('BACKGROUND', (0, -1), (-1, -1), colors.HexColor('#1E90FF')),
    ('TEXTCOLOR', (0, -1), (-1, -1), colors.whitesmoke),
    ('ALIGN', (0, -1), (-1, -1), 'CENTER'),
    ('FONTNAME', (0, -1), (-1, -1), 'Helvetica-Bold'),
    ('FONTSIZE', (0, -1), (-1, -1), 14),
    ('TOPPADDING', (0, -1), (-1, -1), 12),
])

def generate_pdf():
    # Create a new PDF document
    pdf = canvas.Canvas('users.pdf', pagesize=landscape(A4))

    # Set the title of the PDF document
    pdf.setTitle('User Information')

    # Create the table
    table = Table(table_data)

    # Apply the table style
    table.setStyle(table_style)

    # Add the table to the PDF document
    table_height = 12.1 * cm
    table.wrapOn(pdf, 0, 0)
    table.drawOn(pdf, 0, A4[1] - table_height)

    activity_data = []
    for activity in activities:
        activity_dict = activity.to_dict()
        activity_type = activity_dict.get('activityType')
        timestamp = activity_dict.get('timestamp')

        # Append the activity data to the list
        activity_data.append((activity_type, timestamp))

    # Create the activity graph
    x = [t[1] for t in activity_data]
    y = [t[0] for t in activity_data]
    fig, ax = plt.subplots()
    ax.bar(x, y)

   # Create the tremor graph
    tremor_values = []
    for tremor in tremor_data:
        tremor_dict = tremor.to_dict()
        tremor_value = tremor_dict.get('tremor')
        tremor_values.append(tremor_value)

    fig_tremor, ax_tremor = plt.subplots()
    ax_tremor.plot(time_values, intensity_values)
    ax_tremor.set_title('Tremor Report')
    ax_tremor.set_xlabel('Time')
    ax_tremor.set_ylabel('Intensity')

    # Set the desired distance between ticks on the x-axis
    tick_distance = 3  # Adjust this value as needed
    ax_tremor.set_xticks(range(len(time_values))[::tick_distance])

    # Save the tremor graph as an image
    tremor_graph_file = 'tremor_graph.png'
    plt.savefig(tremor_graph_file)
    plt.close(fig_tremor)

    ax.set_title('Activity Rhythm Report')
    ax.set_xlabel('timestamp')
    ax.set_ylabel('Activity Type')

    # Save the activity graph as an image
    plt.savefig('Activity_Rhythm.png')
    plt.close(fig)

    pdf.drawString(100, 750, 'Activity Rhythm Report')
    pdf.drawImage('Activity_Rhythm.png', 25, 240, 650, 250)

    # Add the tremor graph to the PDF document
    pdf.drawString(100, 900, 'Tremor Report')
    pdf.drawImage(tremor_graph_file, 25, -8, 650, 250)

    # Save the PDF document
    pdf.save()

@app.route('/RepPDF', methods=['GET'])
def get_pdf():
    pdf_path = os.path.join(os.getcwd(), 'users.pdf')
    if not os.path.exists(pdf_path):
        generate_pdf()
    return send_from_directory(os.getcwd(), 'users.pdf', as_attachment=True)

if __name__ == '__main__':
    generate_pdf()  # Generate the PDF before running the Flask server
    app.run(host="0.0.0.0", port=8866)
