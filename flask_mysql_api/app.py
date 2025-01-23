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

# Route to fetch providers
@app.route('/providers', methods=['GET'])
def get_providers():
    try:
        location_id = request.args.get('location_id')  # Get location_id from query parameters
        # Debug print
        print(f"Received location_id: {location_id}")

        cursor = mysql.connection.cursor()

        # Base query: Fetch all non-deleted providers
        query = """
            SELECT 
                p.id, p.first_name, p.last_name, p.specialty, 
                p.title, p.wait_time, p.last_changed, 
                p.location_id, l.name AS location_name
            FROM waitingboard_providers p
            JOIN waitingboard_locations l ON p.location_id = l.id
            WHERE p.deleteFlag = 0
        """

        # Add filtering by location_id if provided
        if location_id:
            query += " AND p.location_id = %s"
            cursor.execute(query, (location_id,))
        else:
            cursor.execute(query)

        providers = cursor.fetchall()
        cursor.close()

        # Map results to JSON-friendly format
        provider_list = []
        for row in providers:
            provider = {
                "id": row['id'],
                "firstName": row['first_name'],
                "lastName": row['last_name'],
                "specialty": row['specialty'],
                "title": row['title'],
                "waitTime": row['wait_time'],
                "lastChanged": row['last_changed'].strftime("%Y-%m-%d %H:%M:%S") if row['last_changed'] else None,
                "locationId": row['location_id'],
                "locationName": row['location_name'],
            }
            provider_list.append(provider)

        return jsonify(provider_list), 200
    except Exception as e:
        print(f"Error in /providers route: {e}")
        return jsonify({"error": str(e)}), 500

# Route to add a provider
@app.route('/providers', methods=['POST'])
def add_provider():
    data = request.get_json()
    print("Incoming Data:", data)  # Debug incoming data

    first_name = data.get('firstName')
    last_name = data.get('lastName')
    specialty = data.get('specialty')
    title = data.get('title')
    locations = data.get('locations', '')  # Comma-separated string of locations

    # Validate that none of the required fields are empty
    if not all([first_name, last_name, specialty, title, locations]):
        return jsonify({"error": "All fields are required"}), 400

    # Split locations into a list
    location_list = [loc.strip() for loc in locations.split(',')]

    try:
        cursor = mysql.connection.cursor()

        # Check for duplicates (same first and last name)
        cursor.execute(
            "SELECT id FROM waitingboard_providers WHERE first_name = %s AND last_name = %s",
            [first_name, last_name],
        )
        if cursor.fetchone():
            return jsonify({"error": "Provider already exists"}), 400

        # Validate that all provided locations exist in the `waitingboard_locations` table
        valid_locations = []
        for location in location_list:
            cursor.execute("SELECT id FROM waitingboard_locations WHERE name = %s", (location,))
            if cursor.fetchone():  # Location exists
                valid_locations.append(location)
            else:
                print(f"Invalid location: {location}")  # Debug invalid locations

        if not valid_locations:
            return jsonify({"error": "None of the selected locations are valid"}), 400

        # Combine valid locations into a single string for `location_name`
        combined_locations = ','.join(valid_locations)
        print(f"Combined Locations: {combined_locations}")  # Debug print

        # Insert the provider with the combined location_name
        query = """
        INSERT INTO waitingboard_providers (first_name, last_name, specialty, title, location_name)
        VALUES (%s, %s, %s, %s, %s)
        """
        cursor.execute(query, (first_name, last_name, specialty, title, combined_locations))

        mysql.connection.commit()
        cursor.close()

        return jsonify({"message": "Provider added successfully", "locations": combined_locations}), 201

    except Exception as e:
        print("Error:", e)  # Log the error for debugging
        mysql.connection.rollback()  # Rollback on error
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
