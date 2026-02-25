"""
Technical Knowledge Base for AISRi Coach
Domain-specific knowledge for running biomechanics, training science, and technical questions
"""

class TechnicalKnowledge:
    """
    ML-powered knowledge base for technical running questions
    Provides context-aware, scientific explanations with examples
    """
    
    @staticmethod
    def classify_technical_question(text: str):
        """
        Classify the type of technical question being asked
        
        Args:
            text: User's question text
            
        Returns:
            str: Question category (cadence/intervals/biomechanics/general)
        """
        text = text.lower()
        
        # Cadence-specific questions
        if any(k in text for k in ["cadence", "spm", "steps per minute", "step rate", "stride rate"]):
            if any(k in text for k in ["interval", "recovery", "rest", "work", "repeat"]):
                return "cadence_intervals"
            return "cadence_general"
        
        # Interval training questions
        if any(k in text for k in ["interval", "repeat", "work", "recovery", "rest period"]):
            return "interval_training"
        
        # Biomechanics questions
        if any(k in text for k in ["oscillation", "vertical", "contact time", "ground contact", "stride length", "running form"]):
            return "biomechanics"
        
        # Heart rate zones
        if any(k in text for k in ["heart rate", "hr zone", "zone", "threshold", "aerobic", "anaerobic"]):
            return "heart_rate_zones"
        
        # Pace and performance
        if any(k in text for k in ["pace", "speed", "tempo", "threshold pace"]):
            return "pace_performance"
        
        return "general_technical"
    
    @staticmethod
    def get_cadence_intervals_explanation(athlete_data=None):
        """
        Explain how cadence is measured during interval workouts
        Based on AKURA/AISRI methodology
        
        Args:
            athlete_data: Optional athlete-specific data for personalized examples
            
        Returns:
            str: Detailed explanation with examples
        """
        return """🎯 *How We Measure Cadence During Intervals*

Great question! Let me explain our scientific approach.

*📱 What Your Watch Shows:*
Your Garmin/COROS/Apple Watch calculates cadence across the *entire* workout—including warm-up, work intervals, recovery, and cool-down. This gives you an "overall average" that's actually misleading!

*❌ The Problem with Overall Average:*
Example: 6×6 min Interval Workout

• Warm-up: 150 SPM (5 min)
• Work Interval 1: 185 SPM (6 min)
• Recovery 1: 120 SPM (2 min walking)
• Work Interval 2: 185 SPM (6 min)
• Recovery 2: 120 SPM (2 min)
• Work Interval 3: 185 SPM (6 min)
• Recovery 3: 120 SPM (2 min)
• Cool-down: 150 SPM (5 min)

*Watch Average: 162 SPM* ❌

This number includes your slow recovery periods and tells us nothing about your actual running efficiency!

*✅ The AKURA/AISRI Method:*
We measure cadence *ONLY during work intervals* when you're running at target intensity:

*Working Cadence* = (185 + 185 + 185) ÷ 3 = *185 SPM* ✓

This is your TRUE performance indicator!

*💡 Why This Matters:*
• Recovery cadence (120-140 SPM) doesn't affect performance
• Even complete rest (0 SPM standing still) during recovery is FINE!
• We only care: "Can you maintain 180-190 SPM during work intervals?"

*📊 What We Measure:*
✅ Cadence during each work interval
✅ Consistency across intervals (185, 185, 185 = excellent!)
✅ Working cadence trend over weeks

❌ We ignore:
• Overall average cadence (includes recovery)
• Recovery period metrics
• Warm-up/cool-down cadence

*🎯 Bottom Line:*
Take complete rest during recovery if needed! Walk, stand, stretch—whatever helps you recover. Your *working cadence* during intervals is what predicts your running economy, injury risk, and race performance.

Focus on maintaining 180-190 SPM during work intervals. The rest doesn't count! 💪

*Want to see your working cadence analysis? Upload your latest interval workout!*"""
    
    @staticmethod
    def get_interval_training_explanation():
        """
        Explain interval training methodology and recovery importance
        """
        return """🏃‍♂️ *Understanding Interval Training*

Interval training is one of the most effective ways to improve your running performance!

*🎯 The Science:*
Work Intervals → Stress your cardiovascular system at high intensity
Recovery Periods → Allow partial recovery while maintaining elevated heart rate
Repetitions → Build aerobic capacity and lactate threshold

*💡 Why Recovery Matters:*
• Clears lactate from muscles
• Lowers heart rate to prepare for next interval
• Prevents premature fatigue
• Allows you to maintain quality during work intervals

*✅ Recovery Types:*
• *Active Recovery*: Light jogging (140-150 SPM)
• *Walking Recovery*: Slow walk (120 SPM)
• *Complete Rest*: Standing/stretching (0 SPM)

All are valid! Choose based on your fitness level and workout intensity.

*📊 What We Analyze:*
• Work interval consistency (pace, HR, cadence)
• Recovery time needed between intervals
• Overall workout quality
• Training adaptation over weeks

*🎯 Key Principle:*
Quality work intervals > quantity. If you need longer recovery to maintain target pace/HR during work intervals, take it!

Need help analyzing your intervals? Share your workout! 💪"""
    
    @staticmethod
    def get_cadence_general_explanation():
        """
        General cadence information and optimal ranges
        """
        return """👟 *Understanding Running Cadence*

Cadence (steps per minute) is one of the most important biomechanical metrics for running efficiency and injury prevention!

*🎯 Optimal Cadence Ranges:*
• *Elite Runners*: 180-190 SPM
• *Advanced*: 170-180 SPM
• *Intermediate*: 160-170 SPM
• *Beginner*: 150-160 SPM

*💡 Why Cadence Matters:*
✅ Higher cadence = less impact per step
✅ Reduces injury risk (especially knee injuries)
✅ Improves running economy
✅ Better energy distribution

*❌ Common Mistakes:*
• Over-striding (too low cadence)
• Measuring cadence during recovery/walking
• Comparing easy run cadence to interval cadence

*📊 How to Improve Cadence:*
1️⃣ Use metronome apps (set to target SPM)
2️⃣ Focus on "quick feet" during easy runs
3️⃣ Shorten your stride slightly
4️⃣ Practice at target cadence for 1-2 min intervals

*🎯 AISRI Recommendation:*
Target 175-180 SPM during your regular training runs. During intervals, 180-190 SPM is ideal!

Want a personalized cadence analysis? Share your recent workouts! 🏃‍♂️"""
    
    @staticmethod
    def get_biomechanics_explanation():
        """
        Explain key running biomechanics metrics
        """
        return """🔬 *Running Biomechanics Analysis*

AISRI analyzes your running form scientifically using key biomechanical metrics!

*📊 Key Metrics We Track:*

*1️⃣ Cadence (Steps Per Minute)*
• Target: 180-190 SPM
• Impact: Injury prevention, efficiency

*2️⃣ Vertical Oscillation*
• Target: 6-8 cm
• Impact: Energy waste, running economy
• Lower = more efficient

*3️⃣ Ground Contact Time*
• Target: 200-250 ms
• Impact: Running power, efficiency
• Shorter = faster turnover

*4️⃣ Stride Length*
• Varies by pace and height
• Should increase with speed
• Avoid over-striding!

*💡 Why Biomechanics Matter:*
• Predict injury risk
• Improve running economy
• Optimize performance
• Identify form issues early

*✅ AISRI's Approach:*
We analyze these metrics during WORK intervals only, excluding recovery periods. This gives you accurate performance indicators!

*🎯 Want Your Biomechanics Report?*
Upload your recent runs and I'll analyze:
• Cadence consistency
• Vertical oscillation trends
• Ground contact time
• Stride efficiency

Let's optimize your running form! 💪"""
    
    @staticmethod
    def get_response(question_type: str, context: dict = None):
        """
        Get appropriate technical response based on question type
        
        Args:
            question_type: Type of technical question
            context: Optional context data (athlete info, workout data)
            
        Returns:
            str: Formatted technical response
        """
        handlers = {
            "cadence_intervals": TechnicalKnowledge.get_cadence_intervals_explanation,
            "cadence_general": TechnicalKnowledge.get_cadence_general_explanation,
            "interval_training": TechnicalKnowledge.get_interval_training_explanation,
            "biomechanics": TechnicalKnowledge.get_biomechanics_explanation,
            "heart_rate_zones": lambda: "Heart rate zones explanation coming soon!",
            "pace_performance": lambda: "Pace performance analysis coming soon!",
            "general_technical": lambda: "Technical analysis coming soon!"
        }
        
        handler = handlers.get(question_type, handlers["general_technical"])
        
        # Call handler (with context if it accepts it)
        try:
            if context:
                return handler(context)
            else:
                return handler()
        except TypeError:
            # Handler doesn't accept context parameter
            return handler()
