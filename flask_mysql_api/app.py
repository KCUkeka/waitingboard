import traceback
from flask import Flask, jsonify, request
from flask_mysqldb import MySQL
from flask_cors import CORS
from config import Config

# Initialize the Flask app
app = Flask(__name__)
CORS(app)

# Load database configuration
app.config.from_object(Config)

# Initialize MySQL
mysql = MySQL(app)

# Route to fetch all users
@app.route('/users', methods=['GET'])
def get_users():
    try:
        cursor = mysql.connection.cursor()
        cursor.execute("SELECT id, username, email, role, admin, created_at FROM waitingboard_users")
        users = cursor.fetchall()
        print("Users Retrieved:", users)  # Debug raw query results
        cursor.close()

        # Map results to JSON-friendly format
        user_list = []
        for row in users:
            print(f"Processing user: {row}")  # Check the structure of each row
            
            # Initialize user dictionary
            user = {}

            # Check if row is a dictionary (since it's returning as a dictionary)
            if isinstance(row, dict):
                user = {
                    "id": row['id'],
                    "username": row['username'],
                    "email": row['email'],
                    "role": row['role'],
                    "admin": bool(row['admin']),  
                    "created_at": row['created_at'].strftime("%Y-%m-%d %H:%M:%S") if row['created_at'] else None,
                }
            else:
                print(f"Unexpected format for row: {row}")

            # Append the user dictionary to the user_list
            user_list.append(user)

        return jsonify(user_list), 200

    except Exception as er:
        print(f"General Error: {er}")  # Debugging message
        return jsonify({"error": f"An error occurred: {str(er)}"}), 500


# Route to add a new user
@app.route('/users', methods=['POST'])
def add_user():
    try:
        data = request.json
        print(f"Incoming data: {data}")  # Debug the incoming data

        # Validate input
        username = data.get('username')
        email = data.get('email')
        password = data.get('password')
        role = data.get('role')
        admin = '0'  # Default admin to 'false' if not provided

        if not all([username, email, password, role]):
            return jsonify({"error": "All fields are required"}), 400

        cursor = mysql.connection.cursor()
        cursor.execute(
            """
            INSERT INTO waitingboard_users (username, email, password, role, admin, created_at)
            VALUES (%s, %s, %s, %s, %s, NOW())
            """,
            (username, email, password, role, admin),
        )
        mysql.connection.commit()
        cursor.close()

        return jsonify({"message": "User added successfully!"}), 201
    except Exception as e:
        print(f"Error in /users (POST) route: {e}")
        return jsonify({"error": str(e)}), 500

@app.route('/locations', methods=['GET'])
def get_locations():
    try:
        cursor = mysql.connection.cursor()
        cursor.execute("SELECT id, name FROM waitingboard_locations")
        locations = cursor.fetchall()
        cursor.close()

        # Map results to JSON-friendly format
        location_list = []
        for row in locations:
            location = {
                "id": row['id'],
                "name": row['name'],
            }
            location_list.append(location)

        return jsonify(location_list), 200
    except Exception as e:
        print(f"Error in /locations route: {e}")
        return jsonify({"error": "An error occurred while fetching locations."}), 500


# Start the Flask app
if __name__ == '__main__':
    app.run(debug=True)
