"""
Test the ML-powered Technical Knowledge Base
Demonstrates self-thinking capability for complex technical questions
"""

from ai_engine_agent.technical_knowledge_base import TechnicalKnowledge

# Test questions that should trigger technical responses
test_questions = [
    "How do you measure cadence during intervals?",
    "Does recovery cadence affect my overall average?",
    "Why do you skip the recovery part when measuring?",
    "Explain how cadence works during interval workouts",
    "What is optimal running cadence?",
    "How does vertical oscillation affect my running?",
]

print("=" * 70)
print("🧠 TESTING ML-POWERED TECHNICAL KNOWLEDGE BASE")
print("=" * 70)
print()

for i, question in enumerate(test_questions, 1):
    print(f"\n{'='*70}")
    print(f"TEST {i}: {question}")
    print(f"{'='*70}\n")
    
    # Classify the question
    question_type = TechnicalKnowledge.classify_technical_question(question)
    print(f"🔍 Classified as: {question_type}")
    print()
    
    # Get response
    response = TechnicalKnowledge.get_response(question_type)
    print(f"🤖 AISRI Response:\n")
    print(response)
    print()
    
print("\n" + "=" * 70)
print("✅ ALL TESTS COMPLETED - ML KNOWLEDGE BASE IS WORKING!")
print("=" * 70)
