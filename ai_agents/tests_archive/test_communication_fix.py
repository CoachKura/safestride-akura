"""
Test the communication agent fixes for performance prediction
"""

# Test classify_message function
def classify_message(text: str):
    """
    Classify incoming message to route to appropriate endpoint
    """
    text = text.lower()

    # Injury/pain keywords
    if any(k in text for k in ["pain", "sore", "injury", "hurt", "ache", "strain"]):
        return "injury"

    # Performance/race keywords
    if any(k in text for k in ["race", "pace", "performance", "pr", "personal best", "time", "predict", "10k", "5k", "marathon", "half marathon"]):
        return "performance"

    # Training plan keywords
    if any(k in text for k in ["plan", "workout", "schedule", "training", "program"]):
        return "training"

    # Default to autonomous
    return "autonomous"

# Test messages
test_messages = [
    "What pace for my 10K race",
    "10k pace prediction",
    "Can I run 5k under 20 minutes",
    "What's my predicted marathon time",
    "I have knee pain",
    "Show me my training plan",
    "What should I do today"
]

print("Testing message classification:\n")
for msg in test_messages:
    route = classify_message(msg)
    print(f"Message: '{msg}'")
    print(f"Route: {route}")
    print()

# Test performance response formatting
print("\n" + "="*60)
print("Testing performance prediction response formatting:\n")

# Simulate a successful API response
api_response_success = {
    "status": "success",
    "athlete_id": "test_123",
    "vo2max": 45.3,
    "aisri_score": 72,
    "predictions": {
        "5K": "23:15",
        "10K": "48:30",
        "Half Marathon": "1:47:20",
        "Marathon": "3:45:10"
    }
}

# Format the response
predictions = api_response_success.get("predictions", {})
vo2max = api_response_success.get("vo2max", "N/A")
aisri_score = api_response_success.get("aisri_score", "N/A")

response_text = f"""📈 *Performance Predictions*

*Current Fitness:*
• VO2max: {vo2max}
• AISRi Score: {aisri_score}

*Race Time Predictions:*
🏃 5K: {predictions.get('5K', 'N/A')}
🏃 10K: {predictions.get('10K', 'N/A')}
🏃 Half Marathon: {predictions.get('Half Marathon', 'N/A')}
🏃 Marathon: {predictions.get('Marathon', 'N/A')}

Keep training to improve these times! 🎯"""

print("Formatted response:")
print(response_text)

# Test error response
print("\n" + "="*60)
print("Testing error response:\n")

api_response_error = {
    "error": "Connection timeout",
    "endpoint": "/agent/predict-performance"
}

if "error" in api_response_error:
    error_response = "⚠️ AISRi engine is temporarily unavailable. Please try again in a moment."
    print("Error response:")
    print(error_response)

print("\n✅ All tests completed!")
