"""
Structural State Workout Templates

Templates optimized for each structural state:
- RED: Mobility-focused, foundation building
- YELLOW: Moderate intensity, controlled progression
- GREEN: Full range, performance-oriented
"""

STRUCTURAL_WORKOUT_TEMPLATES = {
    'red': {
        'mobility': {
            'name': 'Structural Foundation - Mobility',
            'type': 'mobility',
            'duration_minutes': 30,
            'intensity': 'low',
            'zones_allowed': [1],
            'structure': {
                'warmup': {
                    'duration': 10,
                    'activity': 'Dynamic stretching + gentle movement prep',
                    'focus': 'Joint mobility, muscle activation'
                },
                'main': {
                    'duration': 15,
                    'activity': 'Targeted mobility drills',
                    'exercises': [
                        'Hip circles and leg swings',
                        'Ankle dorsiflexion work',
                        'Glute activation (clamshells, bridges)',
                        'Core stability (planks, dead bugs)'
                    ]
                },
                'cooldown': {
                    'duration': 5,
                    'activity': 'Static stretching',
                    'focus': 'Major muscle groups'
                }
            },
            'ai_constraints': {
                'max_heart_rate_percent': 60,
                'max_perceived_exertion': 3,
                'no_impact': True,
                'focus': 'structural_strengthening'
            }
        },
        'easy': {
            'name': 'Structural Foundation - Easy Run',
            'type': 'easy',
            'duration_minutes': 25,
            'intensity': 'very_low',
            'zones_allowed': [1, 2],
            'structure': {
                'warmup': {
                    'duration': 5,
                    'activity': 'Walk to very easy jog',
                    'pace': 'conversational'
                },
                'main': {
                    'duration': 15,
                    'activity': 'Zone 1-2 running',
                    'pace': 'Very easy - can hold full conversation',
                    'instructions': 'Focus on form, cadence 160-170 SPM'
                },
                'cooldown': {
                    'duration': 5,
                    'activity': 'Easy walk',
                    'stretch': 'Light post-run stretching'
                }
            },
            'ai_constraints': {
                'max_heart_rate_percent': 65,
                'max_perceived_exertion': 4,
                'cadence_target': 165,
                'focus': 'aerobic_base_only'
            }
        }
    },
    'yellow': {
        'easy': {
            'name': 'Structural Build - Easy Run',
            'type': 'easy',
            'duration_minutes': 40,
            'intensity': 'moderate_low',
            'zones_allowed': [1, 2, 3],
            'structure': {
                'warmup': {
                    'duration': 8,
                    'activity': 'Progressive warmup walk to jog'
                },
                'main': {
                    'duration': 25,
                    'activity': 'Zone 2-3 steady running',
                    'pace': 'Comfortable aerobic'
                },
                'cooldown': {
                    'duration': 7,
                    'activity': 'Easy jog to walk + stretch'
                }
            },
            'ai_constraints': {
                'max_heart_rate_percent': 75,
                'max_perceived_exertion': 6,
                'focus': 'endurance_building'
            }
        },
        'tempo': {
            'name': 'Structural Build - Tempo Run',
            'type': 'tempo',
            'duration_minutes': 45,
            'intensity': 'moderate',
            'zones_allowed': [2, 3],
            'structure': {
                'warmup': {
                    'duration': 10,
                    'activity': 'Easy running + dynamic drills'
                },
                'main': {
                    'duration': 25,
                    'activity': 'Steady tempo',
                    'pace': 'Comfortably hard - can speak short sentences',
                    'blocks': [
                        '3 x 8min @ tempo pace',
                        '2min easy between blocks'
                    ]
                },
                'cooldown': {
                    'duration': 10,
                    'activity': 'Easy jog + stretch'
                }
            },
            'ai_constraints': {
                'max_heart_rate_percent': 82,
                'max_perceived_exertion': 7,
                'no_vo2_work': True,
                'focus': 'lactate_threshold'
            }
        }
    },
    'green': {
        'threshold': {
            'name': 'Performance - Threshold Session',
            'type': 'threshold',
            'duration_minutes': 55,
            'intensity': 'high',
            'zones_allowed': [2, 3, 4],
            'structure': {
                'warmup': {
                    'duration': 12,
                    'activity': 'Easy run + strides'
                },
                'main': {
                    'duration': 30,
                    'activity': 'Threshold intervals',
                    'blocks': [
                        '4 x 6min @ threshold',
                        '2min recovery jog between'
                    ]
                },
                'cooldown': {
                    'duration': 13,
                    'activity': 'Easy jog + mobility'
                }
            },
            'ai_constraints': {
                'max_heart_rate_percent': 88,
                'max_perceived_exertion': 8,
                'focus': 'performance'
            }
        },
        'interval': {
            'name': 'Performance - VO2max Intervals',
            'type': 'interval',
            'duration_minutes': 50,
            'intensity': 'very_high',
            'zones_allowed': [2, 3, 4, 5],
            'structure': {
                'warmup': {
                    'duration': 12,
                    'activity': 'Easy run + drills + 2 strides'
                },
                'main': {
                    'duration': 25,
                    'activity': 'VO2max intervals',
                    'blocks': [
                        '6 x 3min @ VO2max pace',
                        '90sec recovery jog between'
                    ]
                },
                'cooldown': {
                    'duration': 13,
                    'activity': 'Easy jog + full stretch routine'
                }
            },
            'ai_constraints': {
                'max_heart_rate_percent': 95,
                'max_perceived_exertion': 9,
                'speed_permission_required': True,
                'focus': 'vo2max'
            }
        },
        'race': {
            'name': 'Performance - Race Simulation',
            'type': 'race',
            'duration_minutes': 60,
            'intensity': 'race_pace',
            'zones_allowed': [3, 4, 5],
            'structure': {
                'warmup': {
                    'duration': 15,
                    'activity': 'Progressive warmup + race prep drills'
                },
                'main': {
                    'duration': 35,
                    'activity': 'Race pace simulation',
                    'pace': 'Goal race pace'
                },
                'cooldown': {
                    'duration': 10,
                    'activity': 'Easy recovery jog'
                }
            },
            'ai_constraints': {
                'max_heart_rate_percent': 95,
                'max_perceived_exertion': 9,
                'speed_permission_required': True,
                'focus': 'race_specificity'
            }
        }
    }
}


def get_template_for_state(structural_state: str, workout_type: str) -> dict:
    """
    Get appropriate workout template based on structural state.
    
    Args:
        structural_state: 'red', 'yellow', or 'green'
        workout_type: Desired workout type
    
    Returns:
        Template dict or fallback template
    """
    state_templates = STRUCTURAL_WORKOUT_TEMPLATES.get(structural_state.lower(), {})
    
    # Map workout types to template keys
    type_mapping = {
        'mobility': 'mobility',
        'activation': 'mobility',
        'easy': 'easy',
        'recovery': 'easy',
        'tempo': 'tempo',
        'threshold': 'threshold',
        'interval': 'interval',
        'vo2max': 'interval',
        'race': 'race'
    }
    
    template_key = type_mapping.get(workout_type.lower())
    
    if template_key and template_key in state_templates:
        return state_templates[template_key]
    
    # Fallback: most conservative option for state
    if structural_state == 'red':
        return state_templates.get('easy', state_templates.get('mobility'))
    elif structural_state == 'yellow':
        return state_templates.get('easy')
    else:
        return state_templates.get('threshold')
