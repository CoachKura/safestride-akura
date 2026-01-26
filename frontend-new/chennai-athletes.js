/**
 * 10 Chennai Elite Athletes Data
 * Pre-loaded athlete profiles for SafeStride by AKURA
 */

const CHENNAI_ATHLETES = [
    {
        id: 1,
        name: "Arjun Kumar",
        age: 28,
        email: "arjun.kumar@example.com",
        currentPace: "4:15/km",
        goal: "Sub-3:00 Marathon",
        restingHR: 48,
        maxHR: 188,
        injuryHistory: "none",
        yearsRunning: 6,
        location: "Chennai",
        trainingFrequency: 6,
        recentWorkouts: [
            { type: 'tempo', pace: '4:10', avgHR: 168, distance: 10, date: '2026-01-23' },
            { type: 'easy', pace: '4:50', avgHR: 145, distance: 12, date: '2026-01-22' },
            { type: 'interval', pace: '3:50', avgHR: 182, distance: 8, date: '2026-01-21' }
        ],
        workoutHistory: [
            { type: 'tempo', pace: '4:20', avgHR: 165, distance: 10, date: '2026-01-15' },
            { type: 'tempo', pace: '4:15', avgHR: 167, distance: 10, date: '2026-01-08' },
            { type: 'tempo', pace: '4:10', avgHR: 168, distance: 10, date: '2026-01-01' }
        ],
        weekStats: { distance: 68, runs: 6, avgHR: 162 }
    },
    {
        id: 2,
        name: "Priya Sharma",
        age: 25,
        email: "priya.sharma@example.com",
        currentPace: "4:45/km",
        goal: "Sub-1:35 HM",
        restingHR: 52,
        maxHR: 191,
        injuryHistory: "minor knee",
        yearsRunning: 4,
        location: "Chennai",
        trainingFrequency: 5,
        recentWorkouts: [
            { type: 'tempo', pace: '4:40', avgHR: 165, distance: 10, date: '2026-01-23' },
            { type: 'easy', pace: '5:20', avgHR: 145, distance: 8, date: '2026-01-22' }
        ],
        workoutHistory: [
            { type: 'tempo', pace: '4:50', avgHR: 162, distance: 8, date: '2026-01-15' },
            { type: 'tempo', pace: '4:45', avgHR: 164, distance: 10, date: '2026-01-08' }
        ],
        weekStats: { distance: 52, runs: 5, avgHR: 158 }
    },
    {
        id: 3,
        name: "Vikram Reddy",
        age: 32,
        email: "vikram.reddy@example.com",
        currentPace: "4:30/km",
        goal: "Sub-3:15 Marathon",
        restingHR: 50,
        maxHR: 186,
        injuryHistory: "IT band",
        yearsRunning: 8,
        location: "Chennai",
        trainingFrequency: 6,
        recentWorkouts: [
            { type: 'long', pace: '4:55', avgHR: 152, distance: 22, date: '2026-01-24' }
        ],
        workoutHistory: [
            { type: 'tempo', pace: '4:35', avgHR: 165, distance: 12, date: '2026-01-17' }
        ],
        weekStats: { distance: 72, runs: 6, avgHR: 158 }
    },
    {
        id: 4,
        name: "Anjali Menon",
        age: 27,
        email: "anjali.menon@example.com",
        currentPace: "5:00/km",
        goal: "Sub-1:50 HM",
        restingHR: 54,
        maxHR: 189,
        injuryHistory: "none",
        yearsRunning: 3,
        location: "Chennai",
        trainingFrequency: 4,
        recentWorkouts: [
            { type: 'easy', pace: '5:30', avgHR: 148, distance: 10, date: '2026-01-23' }
        ],
        workoutHistory: [
            { type: 'tempo', pace: '5:05', avgHR: 168, distance: 8, date: '2026-01-16' }
        ],
        weekStats: { distance: 42, runs: 4, avgHR: 154 }
    },
    {
        id: 5,
        name: "Rahul Iyer",
        age: 30,
        email: "rahul.iyer@example.com",
        currentPace: "4:20/km",
        goal: "Sub-3:05 Marathon",
        restingHR: 49,
        maxHR: 187,
        injuryHistory: "plantar fasciitis",
        yearsRunning: 7,
        location: "Chennai",
        trainingFrequency: 6,
        recentWorkouts: [
            { type: 'interval', pace: '3:55', avgHR: 178, distance: 10, date: '2026-01-23' }
        ],
        workoutHistory: [
            { type: 'tempo', pace: '4:25', avgHR: 166, distance: 12, date: '2026-01-16' }
        ],
        weekStats: { distance: 64, runs: 6, avgHR: 165 }
    },
    {
        id: 6,
        name: "Deepa Krishnan",
        age: 29,
        email: "deepa.krishnan@example.com",
        currentPace: "4:50/km",
        goal: "Sub-1:40 HM",
        restingHR: 53,
        maxHR: 188,
        injuryHistory: "none",
        yearsRunning: 5,
        location: "Chennai",
        trainingFrequency: 5,
        recentWorkouts: [
            { type: 'tempo', pace: '4:45', avgHR: 164, distance: 10, date: '2026-01-23' }
        ],
        workoutHistory: [
            { type: 'tempo', pace: '4:55', avgHR: 162, distance: 10, date: '2026-01-16' }
        ],
        weekStats: { distance: 56, runs: 5, avgHR: 160 }
    },
    {
        id: 7,
        name: "Karthik Subramanian",
        age: 26,
        email: "karthik.s@example.com",
        currentPace: "4:10/km",
        goal: "Sub-2:55 Marathon",
        restingHR: 46,
        maxHR: 190,
        injuryHistory: "none",
        yearsRunning: 5,
        location: "Chennai",
        trainingFrequency: 7,
        recentWorkouts: [
            { type: 'tempo', pace: '4:05', avgHR: 170, distance: 12, date: '2026-01-23' }
        ],
        workoutHistory: [
            { type: 'tempo', pace: '4:10', avgHR: 168, distance: 12, date: '2026-01-16' }
        ],
        weekStats: { distance: 78, runs: 7, avgHR: 165 }
    },
    {
        id: 8,
        name: "Lakshmi Venkatesh",
        age: 31,
        email: "lakshmi.v@example.com",
        currentPace: "5:10/km",
        goal: "Sub-2:00 HM",
        restingHR: 56,
        maxHR: 186,
        injuryHistory: "shin splints",
        yearsRunning: 2,
        location: "Chennai",
        trainingFrequency: 3,
        recentWorkouts: [
            { type: 'easy', pace: '5:40', avgHR: 145, distance: 8, date: '2026-01-23' }
        ],
        workoutHistory: [
            { type: 'tempo', pace: '5:15', avgHR: 165, distance: 6, date: '2026-01-16' }
        ],
        weekStats: { distance: 32, runs: 3, avgHR: 152 }
    },
    {
        id: 9,
        name: "Aditya Nair",
        age: 28,
        email: "aditya.nair@example.com",
        currentPace: "4:35/km",
        goal: "Sub-3:20 Marathon",
        restingHR: 51,
        maxHR: 188,
        injuryHistory: "minor calf",
        yearsRunning: 6,
        location: "Chennai",
        trainingFrequency: 5,
        recentWorkouts: [
            { type: 'tempo', pace: '4:30', avgHR: 166, distance: 10, date: '2026-01-23' }
        ],
        workoutHistory: [
            { type: 'tempo', pace: '4:35', avgHR: 164, distance: 10, date: '2026-01-16' }
        ],
        weekStats: { distance: 58, runs: 5, avgHR: 162 }
    },
    {
        id: 10,
        name: "Sneha Patel",
        age: 24,
        email: "sneha.patel@example.com",
        currentPace: "4:55/km",
        goal: "Sub-1:45 HM",
        restingHR: 55,
        maxHR: 192,
        injuryHistory: "none",
        yearsRunning: 3,
        location: "Chennai",
        trainingFrequency: 4,
        recentWorkouts: [
            { type: 'easy', pace: '5:25', avgHR: 150, distance: 10, date: '2026-01-23' }
        ],
        workoutHistory: [
            { type: 'tempo', pace: '5:00', avgHR: 168, distance: 8, date: '2026-01-16' }
        ],
        weekStats: { distance: 46, runs: 4, avgHR: 156 }
    }
];

// Export for use in modules
if (typeof module !== 'undefined' && module.exports) {
    module.exports = CHENNAI_ATHLETES;
}
