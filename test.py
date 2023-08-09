# test_nginx.py

import requests
import pytest
import time
import os


@pytest.mark.nginx
def test_nginx_response():
    API_URL = os.getenv("API_URL")
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