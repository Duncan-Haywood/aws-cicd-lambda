# test_nginx.py

import requests
import pytest
import time

API_URL = "https://xyz123.execute-api.us-east-1.amazonaws.com/test"

@pytest.mark.nginx
def test_nginx_response():
    while True:
        try:
            response = requests.get(API_URL)
            if response.status_code != 404:
                break 
        except:
            pass
            time.sleep(5)

    response = requests.get(f"{API_URL}/")

    assert response.status_code == 200
    assert "Server: nginx" in response.text