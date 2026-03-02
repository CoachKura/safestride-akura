# Update /agent/generate-workout to use orchestrator with safety gates
with open('main.py', 'r', encoding='utf-8') as f:
    content = f.read()

# Find and replace the old implementation
old_implementation = '''@app.post("/agent/generate-workout")
def generate_workout(request: WorkoutRequest):
    from ai_engine_agent.workout_generator_agent import AISRiWorkoutGeneratorAgent

    agent = AISRiWorkoutGeneratorAgent()

    result = agent.generate_workout(request.athlete_id)

    return result'''

new_implementation = '''@app.post("/agent/generate-workout")
async def generate_workout(request: WorkoutRequest):
    # Generate workout - UPDATED to use  Orchestrator with Safety Gates
    # Legacy endpoint maintained for backward compatibility
    if orchestrator is None:
        # Fallback to direct agent call if orchestrator not available
        from ai_engine_agent.workout_generator_agent import AISRiWorkoutGeneratorAgent
        agent = AISRiWorkoutGeneratorAgent()
        return agent.generate_workout(request.athlete_id)
    
    # Route through orchestrator for safety gate enforcement
    try:
        result = await orchestrator.generate_safe_workout(
            athlete_id=request.athlete_id,
            workout_type='run',
            duration_minutes=60,
            intensity=None
        )
        return result
    except Exception as e:
        raise HTTPException(status_code=500, detail=str(e))'''

if old_implementation in content:
    content = content.replace(old_implementation, new_implementation)
    print('✅ Updated /agent/generate-workout to use orchestrator')
else:
    print('⚠️  Could not find exact match')

with open('main.py', 'w', encoding='utf-8') as f:
    f.write(content)
