from ai_engine_agent.autonomous_decision_agent import AISRiAutonomousDecisionAgent
import json

# Test the autonomous decision agent
agent = AISRiAutonomousDecisionAgent()

result = agent.run_decision_cycle("athlete_1771670436116")

print("=== Autonomous Decision Test ===")
print(json.dumps(result, indent=2))
