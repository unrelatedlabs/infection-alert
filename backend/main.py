# Copyright 2018 Google LLC
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# [START gae_python37_bigquery]
import concurrent.futures
import hashlib

import flask
from google.cloud import bigquery

import json
import jwt

app = flask.Flask(__name__)
client = bigquery.Client()


table_id = "infection-alert.test.heartrate"



@app.route("/api/heartrate",methods=["POST"])
def ingest():
    if not flask.request.is_json:
        return 400, "POST application/json"

    data = flask.request.get_json()


    if flask.request.headers.get("Authorization","").startswith("Bearer "):
        token = flask.request.headers.get("Authorization", "")[len("Bearer "):]
        print(token)
        decoded = jwt.decode(token,verify=False)
        key = decoded["pbk"]
        verified = jwt.decode(token,key=key,verify=True)
        print(decoded)
        hashedkey = hashlib.sha1(key.encode("utf8")).hexdigest()
        user_id = verified["uid"]

        if user_id != hashedkey:
            raise BaseException("Key missmatch")

        for record in data:
            record['user_id'] = user_id




    print( json.dumps( data,indent=1))

    table = client.get_table(table_id)  # Make an API request.
    rows_to_insert = flask.request.get_json()

    errors = client.insert_rows_json(table, rows_to_insert)  # Make an API request.
    if errors == []:
        return flask.jsonify({"success":True})
    else:
        print(errors)
        return flask.jsonify({"success": False,"error":str(errors)}),400





@app.route("/")
def index():
    return flask.redirect("https://github.com/unrelatedlabs/infection-alert")


if __name__ == "__main__":
    # This is used when running locally only. When deploying to Google App
    # Engine, a webserver process such as Gunicorn will serve the app. This
    # can be configured by adding an `entrypoint` to app.yaml.
    app.run(host="0.0.0.0", port=8080, debug=True)
# [END gae_python37_bigquery]
