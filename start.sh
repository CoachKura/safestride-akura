#!/bin/bash
# Check if we're already in ai_agents directory
if [ -f "main.py" ]; then
    echo "Already in correct directory"
else
    echo "Changing to ai_agents directory"
    cd ai_agents
fi
pip install -r requirements.txt
uvicorn main:app --host 0.0.0.0 --port $PORT
