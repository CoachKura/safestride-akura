#!/bin/bash
cd ai_agents
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port $PORT
