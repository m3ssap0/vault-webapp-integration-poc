import configparser
import logging
import mysql.connector
import time
from flask import Flask, render_template, request, redirect, url_for

CONFIG_FILE = "config.ini"
VAULT_TOKEN_FILE = "/vault-agent/vault-token-via-agent"
VAULT_ROLE_ID_FILE = "/vault-agent/ids/role_id"
VAULT_SECRET_ID_FILE = "/vault-agent/ids/secret_id"

app = Flask(__name__)
logging.basicConfig(level=logging.INFO)

def read_config_file():
    logging.info("Reading config file.")
    config = configparser.ConfigParser()
    config.read(CONFIG_FILE)
    return config

def connect_to_db(attempts=4, delay=2):
    logging.info("Connecting to database.")
    attempt = 1
    # Implement a reconnection routine
    while attempt < attempts + 1:
        try:
            config = read_config_file()
            logging.info(f"config[\"DATABASE\"][\"MYSQL_HOST\"] = {config['DATABASE']['MYSQL_HOST']}")
            logging.info(f"config[\"DATABASE\"][\"MYSQL_USER\"] = {config['DATABASE']['MYSQL_USER']}")
            logging.info(f"config[\"DATABASE\"][\"MYSQL_PASSWORD\"] = {config['DATABASE']['MYSQL_PASSWORD']}")
            logging.info(f"config[\"DATABASE\"][\"MYSQL_DB\"] = {config['DATABASE']['MYSQL_DB']}")
            return mysql.connector.connect(
                host=config["DATABASE"]["MYSQL_HOST"],
                user=config["DATABASE"]["MYSQL_USER"],
                password=config["DATABASE"]["MYSQL_PASSWORD"],
                database=config["DATABASE"]["MYSQL_DB"]
            )
        except (mysql.connector.Error, IOError) as err:
            if (attempts is attempt):
                # Attempts to reconnect failed; returning None
                logging.warn("Failed to connect, exiting without a connection: %s", err)
                return None
            logging.warn(
                "Connection failed: %s. Retrying (%d/%d)...",
                err,
                attempt,
                attempts-1,
            )
            # progressive reconnect delay
            time.sleep(delay ** attempt)
            attempt += 1
    return None

@app.route("/", methods=["GET"])
def index():
    logging.info("Index has been called.")
    db = connect_to_db()
    if db is None:
        return render_template("error.html", error_message="Can't connect to database."), 500
    with db.cursor() as cursor:
        cursor.execute('''SELECT id, content FROM notes_webapp.note''')
        result = cursor.fetchall()
    db.close()
    return render_template("index.html", notes=result)

@app.route("/read/<int:note_id>", methods=["GET"])
def read(note_id):
    logging.info("Read has been called.")
    db = connect_to_db()
    if db is None:
        return render_template("error.html", error_message="Can't connect to database."), 500
    with db.cursor() as cursor:
        cursor.execute('''SELECT id, content FROM notes_webapp.note WHERE id = %s''', (note_id,))
        result = cursor.fetchone()
    db.close()
    if result is None:
        return redirect(url_for("index"))
    else:
        return render_template("read.html", note_id=result[0], note_content=result[1])

@app.route("/add", methods=["GET", "POST"])
def add():
    logging.info("Add has been called.")
    if request.method == "GET":
        return render_template("add.html")
    else:
        note = request.form["note"]
        if note is not None and len(note.strip()) > 0:
            note = note.strip()
            logging.info(f"Note was: {note}")
            db = connect_to_db()
            if db is None:
                return render_template("error.html", error_message="Can't connect to database."), 500
            with db.cursor() as cursor:
                cursor.execute('''INSERT INTO notes_webapp.note (content) VALUES (%s)''', (note,))
                db.commit()
            db.close()
        else:
            logging.warn("None or empty note!")
        return redirect(url_for("index"))

def read_file(filename):
    file_content = ""
    try:
        with open(filename, "r") as f:
            file_content = f.read()
    except:
        logging.warn(f"Error in opening the '{filename}' file!")
    return file_content

@app.route("/config", methods=["GET"])
def config():
    logging.info("Config has been called.")
    config_file_content = read_file(CONFIG_FILE)
    token_file_content = read_file(VAULT_TOKEN_FILE)
    role_id_file_content = read_file(VAULT_ROLE_ID_FILE)
    secret_id_file_content = read_file(VAULT_SECRET_ID_FILE)
    return render_template("config.html", config_file=config_file_content, token_file=token_file_content, role_id_file=role_id_file_content, secret_id_file=secret_id_file_content)

