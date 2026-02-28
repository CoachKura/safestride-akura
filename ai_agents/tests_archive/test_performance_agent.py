from ai_engine_agent.performance_prediction_agent import AISRiPerformancePredictionAgent
import json

# Test the performance prediction agent
agent = AISRiPerformancePredictionAgent()

result = agent.predict_performance("athlete_1771670436116")

print("=== Performance Prediction Test ===")
print(json.dumps(result, indent=2))
