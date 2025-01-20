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
        cursor.execute("SELECT id, username, email, role, admin, password, created_at FROM waitingboard_users")
        users = cursor.fetchall()
        cursor.close()

        # Map results to JSON-friendly format
        user_list = []
        for row in users:
            user = {
                "id": row['id'],
                "username": row['username'],
                "email": row['email'],
                "role": row['role'],
                "admin": bool(row['admin']),
                "password": row['password'],
                "created_at": row['created_at'].strftime("%Y-%m-%d %H:%M:%S") if row['created_at'] else None,
            }
            user_list.append(user)

        return jsonify(user_list), 200
    except Exception as e:
        print(f"Error in /users route: {e}")
        return jsonify({"error": str(e)}), 500

# Route to add a new user
@app.route('/users', methods=['POST'])
def add_user():
    try:
        data = request.json
        username = data.get('username')
        email = data.get('email')
        password = data.get('password')
        role = data.get('role')
        admin = data.get('admin', False)

        if not all([username, email, password, role]):
            return jsonify({"error": "All fields are required"}), 400

        cursor = mysql.connection.cursor()
        cursor.execute(
            """
            INSERT INTO waitingboard_users (username, email, password, role, admin, created_at)
            VALUES (%s, %s, %s, %s, %s, NOW())
            """,
            (username, email, password, role, int(admin)),
        )
        mysql.connection.commit()
        cursor.close()

        return jsonify({"message": "User added successfully!"}), 201
    except Exception as e:
        print(f"Error in /users (POST) route: {e}")
        return jsonify({"error": str(e)}), 500

# Route to fetch all locations
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
        return jsonify({"error": str(e)}), 500

# Route to add a new location
@app.route('/locations', methods=['POST'])
def add_location():
    try:
        data = request.json
        location_name = data.get('name')

        if not location_name:
            return jsonify({"error": "Location name is required"}), 400

        cursor = mysql.connection.cursor()
        cursor.execute(
            """
            INSERT INTO waitingboard_locations (name, created_at)
            VALUES (%s, NOW())
            """,
            (location_name,),
        )
        mysql.connection.commit()
        cursor.close()

        return jsonify({"message": "Location added successfully!"}), 201
    except Exception as e:
        print(f"Error in /locations (POST) route: {e}")
        return jsonify({"error": str(e)}), 500

# Route to mark a provider as deleted (sets deleteFlag to 1)
@app.route('/providers/<provider_id>', methods=['PATCH'])
def delete_provider(provider_id):
    try:
        # Use the MySQL connection to update the provider's deleteFlag
        cursor = mysql.connection.cursor()
        cursor.execute("""
            UPDATE waitingboard_providers 
            SET deleteFlag = 1 
            WHERE id = %s
        """, (provider_id,))
        mysql.connection.commit()
        cursor.close()

        return jsonify({"message": "Provider marked as deleted"}), 200
    except Exception as e:
        print(f"Error in /providers/<provider_id> PATCH route: {e}")
        return jsonify({"error": str(e)}), 500

# Start the Flask app
if __name__ == '__main__':
    app.run(debug=True)
