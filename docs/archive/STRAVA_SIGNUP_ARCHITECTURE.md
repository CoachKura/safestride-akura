# SafeStride Strava Signup Flow - Visual Architecture

## 🎯 Complete System Architecture

```mermaid
graph TB
    subgraph "User Experience"
        A[User Opens App/Web] --> B[Clicks 'Sign Up with Strava']
        B --> C[Strava OAuth Page]
        C --> D[User Authorizes]
        D --> E[Redirect with Code]
    end

    subgraph "Frontend Layer"
        E --> F[Flutter App<br/>or<br/>Web Dashboard]
        F --> G[Call POST /api/strava-signup]
    end

    subgraph "Backend API Layer"
        G --> H[FastAPI Endpoint]
        H --> I[Exchange Code for Token]
        I --> J[Fetch Athlete Profile]
        J --> K[Create Supabase User]
        K --> L[Store Profile Data]
        L --> M[Start Background Sync]
    end

    subgraph "Background Sync Process"
        M --> N[Fetch Activities Page 1]
        N --> O[Fetch Activities Page 2]
        O --> P[... up to 1000 activities]
        P --> Q[Calculate PBs]
        Q --> R[Calculate Stats]
        R --> S[Update Database]
    end

    subgraph "Database Layer"
        S --> T[(Supabase)]
        T --> U[profiles table]
        T --> V[strava_activities table]
    end

    subgraph "User Dashboard"
        L --> W[Return Session Token]
        W --> X[Navigate to Dashboard]
        X --> Y[Show Profile Data]
        S --> Y
        Y --> Z[Display PBs & Stats]
    end

    style A fill:#ff6b6b
    style Z fill:#51cf66
    style T fill:#339af0
```

## 📊 Data Flow Diagram

```mermaid
sequenceDiagram
    participant User
    participant Frontend
    participant Backend
    participant Strava
    participant Supabase

    User->>Frontend: Click "Sign Up with Strava"
    Frontend->>Strava: Redirect to OAuth
    Strava->>User: Show Authorization Page
    User->>Strava: Authorize
    Strava->>Frontend: Redirect with code
    Frontend->>Backend: POST /api/strava-signup {code}

    Backend->>Strava: Exchange code for token
    Strava->>Backend: Return access_token + athlete

    Backend->>Strava: GET /athlete (profile)
    Strava->>Backend: Return profile data

    Backend->>Supabase: Create auth user
    Supabase->>Backend: Return user_id

    Backend->>Supabase: Insert into profiles
    Supabase->>Backend: Success

    Backend->>Frontend: Return session token + athlete
    Frontend->>User: Navigate to Dashboard

    Note over Backend,Supabase: Background Sync Starts

    loop For each page (max 1000 activities)
        Backend->>Strava: GET /activities?page=N
        Strava->>Backend: Return 200 activities
    end

    Backend->>Backend: Calculate PBs (5K, 10K, Half, Marathon)
    Backend->>Backend: Calculate Stats (total distance, avg pace)

    Backend->>Supabase: Update profiles (PBs + stats)
    Backend->>Supabase: Insert into strava_activities

    Note over Frontend,User: Dashboard auto-refreshes with stats
```

## 🗂️ Database Schema Diagram

```mermaid
erDiagram
    PROFILES ||--o{ STRAVA_ACTIVITIES : has

    PROFILES {
        uuid id PK
        bigint strava_athlete_id UK
        text strava_access_token
        text strava_refresh_token
        timestamp strava_token_expires_at
        text first_name
        text last_name
        text profile_photo_url
        varchar gender
        decimal weight
        decimal height
        integer pb_5k "seconds"
        integer pb_10k "seconds"
        integer pb_half_marathon "seconds"
        integer pb_marathon "seconds"
        integer total_runs
        decimal total_distance_km
        decimal total_time_hours
        decimal avg_pace_min_per_km
        decimal longest_run_km
        timestamp last_strava_sync
        timestamp updated_at
    }

    STRAVA_ACTIVITIES {
        uuid id PK
        uuid user_id FK
        bigint strava_activity_id UK
        text name
        decimal distance_meters
        integer moving_time_seconds
        integer elapsed_time_seconds
        decimal total_elevation_gain
        varchar activity_type
        timestamp start_date
        decimal average_speed
        decimal max_speed
        integer average_heartrate
        integer max_heartrate
        decimal average_cadence
        timestamp created_at
    }
```

## 🔄 Personal Best Calculation Logic

```mermaid
flowchart TD
    A[Start: Activities List] --> B{Filter by Type}
    B -->|Type = 'Run'| C[Running Activities]
    B -->|Other| D[Skip]

    C --> E{Check Distance Range}

    E -->|4.8-5.2 km| F[5K Candidates]
    E -->|9.8-10.2 km| G[10K Candidates]
    E -->|20-22 km| H[Half Marathon Candidates]
    E -->|42-43 km| I[Marathon Candidates]
    E -->|Other| D

    F --> J[Find Minimum Time]
    G --> K[Find Minimum Time]
    H --> L[Find Minimum Time]
    I --> M[Find Minimum Time]

    J --> N[pb_5k]
    K --> O[pb_10k]
    L --> P[pb_half_marathon]
    M --> Q[pb_marathon]

    N --> R[Update Database]
    O --> R
    P --> R
    Q --> R

    style A fill:#ffd43b
    style R fill:#51cf66
```

## 🚀 Deployment Architecture

```mermaid
graph LR
    subgraph "Client Side"
        A[Web Browser] --> B[Web App<br/>signup.html]
        C[Mobile Device] --> D[Flutter App<br/>SafeStride]
    end

    subgraph "Backend Infrastructure"
        B --> E[FastAPI Server<br/>Railway/Render]
        D --> E

        E --> F[Strava API<br/>api.strava.com]
        E --> G[(Supabase<br/>PostgreSQL)]
    end

    subgraph "External Services"
        F
        G
    end

    subgraph "Data Storage"
        G --> H[profiles table]
        G --> I[strava_activities]
        G --> J[auth.users]
    end

    style E fill:#339af0
    style G fill:#5c7cfa
    style F fill:#ff6b6b
```

## 📱 Mobile App Component Hierarchy

```mermaid
graph TD
    A[MaterialApp] --> B[StravaSignupScreen]
    B --> C[Strava Button]
    B --> D[Benefits List]

    C --> E[StravaCompleteSyncService]
    E --> F[initiateStravaOAuth]
    F --> G[WebView OAuth]

    G --> H[Backend API]
    H --> I[createAccountAndSync]

    I --> J[startBackgroundSync]
    I --> K[Navigate to Dashboard]

    K --> L[AthleteDashboard]
    L --> M[Profile Header]
    L --> N[Personal Bests Cards]
    L --> O[Activity Stats]
    L --> P[Quick Actions]

    style A fill:#ffd43b
    style L fill:#51cf66
    style E fill:#339af0
```

## 🌐 Web Dashboard Flow

```mermaid
stateDiagram-v2
    [*] --> SignupPage

    SignupPage --> StravaOAuth: Click "Sign Up with Strava"
    StravaOAuth --> CallbackPage: User Authorizes

    CallbackPage --> ProcessingState: Extract code from URL
    ProcessingState --> APICall: POST /api/strava-signup

    APICall --> Success: 200 OK
    APICall --> Error: 400/500 Error

    Success --> StoreSession: Save tokens to localStorage
    StoreSession --> Dashboard: Redirect to /dashboard

    Error --> SignupPage: Show error message

    Dashboard --> [*]
```

## 🔐 Security Flow

```mermaid
graph TB
    A[User Initiates OAuth] --> B[Generate State Token<br/>CSRF Protection]
    B --> C[Redirect to Strava]
    C --> D[Strava Validates User]
    D --> E[Return Code + State]

    E --> F{Verify State}
    F -->|Invalid| G[Reject Request]
    F -->|Valid| H[Exchange Code for Token]

    H --> I[Strava Access Token<br/>Expires: 6 hours]
    I --> J[Create Supabase User<br/>JWT Token]

    J --> K[Store in Database<br/>Encrypted]

    K --> L[Row Level Security<br/>User can only see own data]

    style G fill:#ff6b6b
    style L fill:#51cf66
```

## 📈 Performance Optimization

```mermaid
graph LR
    A[Signup Request] --> B{Async Strategy}

    B --> C[Immediate Response]
    B --> D[Background Jobs]

    C --> E[Account Created]
    C --> F[Basic Profile Stored]
    C --> G[Session Token Returned]

    D --> H[Fetch Activities<br/>Batch: 200/page]
    D --> I[Calculate PBs<br/>In-Memory]
    D --> J[Calculate Stats<br/>Aggregate]

    H --> K[Store in Database<br/>Batch: 100/insert]
    I --> K
    J --> K

    K --> L[Update Profile<br/>Single Query]

    G --> M[User Sees Dashboard]
    L --> M

    style C fill:#51cf66
    style D fill:#ffd43b
    style M fill:#51cf66
```

## 📊 Activity Sync Progress States

```mermaid
stateDiagram-v2
    [*] --> NotStarted: User Signs Up
    NotStarted --> Fetching: Background Task Starts

    Fetching --> CalculatingPBs: All Activities Fetched
    CalculatingPBs --> CalculatingStats: PBs Found
    CalculatingStats --> StoringData: Stats Calculated
    StoringData --> Complete: Database Updated

    Fetching --> Error: API Rate Limit / Network Error
    CalculatingPBs --> Error: Invalid Data
    StoringData --> Error: Database Error

    Error --> Retry: Exponential Backoff
    Retry --> Fetching: Retry Attempt

    Complete --> [*]
    Error --> [*]: Max Retries Exceeded

    note right of Fetching
        Fetching 200 activities per page
        Respecting Strava rate limits
        100 requests / 15 minutes
    end note

    note right of Complete
        User profile fully populated:
        - PBs: 5K, 10K, Half, Marathon
        - Stats: Total distance, avg pace
        - Activities: All runs stored
    end note
```

## 🎨 UI Component Tree

```mermaid
graph TB
    A[StravaSignupScreen] --> B[AppBar]
    A --> C[Body Container]

    C --> D[Logo Section]
    C --> E[Title & Tagline]
    C --> F[Sign Up Button]
    C --> G[Benefits Card]
    C --> H[Terms Text]

    F --> I[onPressed Handler]
    I --> J[initiateStravaSignup]

    J --> K{OAuth Result}
    K -->|Success| L[Show Athlete Preview]
    K -->|Loading| M[Show Progress Spinner]
    K -->|Error| N[Show Error Message]

    L --> O[Confirm Button]
    O --> P[createAccountAndSync]

    P --> Q[Navigate to Dashboard]

    style A fill:#ffd43b
    style Q fill:#51cf66
```

## 🔄 Token Refresh Flow

```mermaid
sequenceDiagram
    participant App
    participant Backend
    participant Strava
    participant Database

    Note over App,Database: Token expires after 6 hours

    App->>Backend: API Request
    Backend->>Database: Check token_expires_at
    Database->>Backend: Token expired

    Backend->>Database: Get refresh_token
    Database->>Backend: Return refresh_token

    Backend->>Strava: POST /oauth/token<br/>(grant_type: refresh_token)
    Strava->>Backend: New access_token + refresh_token

    Backend->>Database: Update tokens
    Database->>Backend: Success

    Backend->>Strava: Retry original request
    Strava->>Backend: Return data

    Backend->>App: Return data
```

## 📝 Summary

### Key Features:

- ✅ One-click signup with Strava OAuth
- ✅ Auto-population of profile data
- ✅ Automatic PB calculation (5K, 10K, Half, Marathon)
- ✅ Background sync of up to 1000 activities
- ✅ Real-time dashboard updates
- ✅ Secure token management
- ✅ Row-level security on data

### Technology Stack:

- **Frontend**: Flutter (mobile) + HTML/JS (web)
- **Backend**: FastAPI (Python)
- **Database**: Supabase (PostgreSQL)
- **OAuth**: Strava OAuth 2.0
- **Real-time**: Supabase Realtime subscriptions

### Performance:

- **Signup Time**: < 2 seconds (before background sync)
- **Background Sync**: 30 seconds - 5 minutes (depending on activity count)
- **Database**: Optimized with indexes on frequently queried fields
- **API**: Rate limit respecting (100 requests / 15 minutes)

---

**Ready to deploy!** 🚀
