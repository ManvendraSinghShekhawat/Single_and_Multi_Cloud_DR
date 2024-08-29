import psycopg2
from psycopg2 import OperationalError

def test_connection():
    try:
        connection = psycopg2.connect(
            host="terraform-20240807030842941700000005.c3om60ww0jqb.eu-north-1.rds.amazonaws.com",
            database="mydatabase",
            user="dbadmin",
            password="Y}Phs<gYU!fRbT1}",
            port="5432"
        )
        print("Connection successful")
        connection.close()
    except OperationalError as e:
        print(f"Connection failed: {e}")

if __name__ == "__main__":
    test_connection()
