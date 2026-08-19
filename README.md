## Team members
Anushri Neramballi Raghavendra (UF ID: 38155612)

Avantika Holla Sathyanarayana (UF ID: 25363524)

## Reddit Clone Simulation

### Instructions on how to run it
gleam run {num_users} {num_subreddits} {time_in_seconds}

### Overview
This project implements a Reddit Clone simulator to model core Reddit-like interactions using an actor-based system architecture. The simulation creates a central Reddit Engine actor that manages users, subreddits, posts, comments, messages, and voting activities. Multiple Client actors simulate independent Reddit users performing randomized actions such as joining subreddits, posting, commenting, voting, messaging, and retrieving personalized feeds.

The system supports realistic workload patterns using a Zipf distribution to model subreddit popularity and number of posts on subreddits.

### Features
- User account registration and management.
- Subreddit creation.
- User joining and leaving subreddits.
- Post creation with hierarchical comments and comment replies.
- Voting system with upvotes, downvotes, and karma computation.
- Direct messaging between users with inbox storage.
- Personalized feed retrieval showing posts from subscribed subreddits.
- Simulation of user activity using randomized actions over a configurable time period.
- Zipf distribution based subreddit selection.
- Aggregated statistics reporting total users, posts, comments, votes, messages, and karma metrics.

### Simulation Details
The simulation is driven by three main input parameters:
- `num_users`: Number of simulated users
- `num_subreddits`: Number of subreddits available
- `simulation_time`: Duration for which simulation runs (in seconds)

During runtime, each client actor randomly performs a sequence of valid actions such as joining or leaving subreddits, creating posts and comments, voting on posts, sending messages, and retrieving feeds until the simulation time elapses. Once complete, the Reddit Engine outputs comprehensive statistics capturing overall system activity and performance.

### Performance
The simulation has been tested with configurations ranging from 100,000 users and 5,000 subreddits up to 1,000,000 users and 10,000 subreddits. It maintains functional correctness, data consistency, and stable performance throughout even large-scale scenarios.
![Screenshot](Simulation_for_100000_users_5000_subreddits_120_secs.png)

![Screenshot](Simulation_for_1000000_users_10000_subreddits_300_secs.png)