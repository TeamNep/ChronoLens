# App Design Fest - Brainstorming

## New App Ideas

1. **ChronoLens** (Education + Travel + Social)  
   Take a picture of a landmark, building, or art piece, use an LLM to identify it, then ask questions in a chat space with follow-up support. The app fetches Wikipedia context and returns grounded answers. Save and share only collection card data (image + identified place info), not full chat history.

2. **TrailGuard** (Travel + Health & Fitness)  
   A hiking safety app with route check-ins, weather/risk alerts, and emergency contact fallbacks.

3. **CampusSwap** (Lifestyle + Productivity)  
   Students list, trade, and request used textbooks, gadgets, and supplies within campus groups.

4. **FitQuest AR** (Health & Fitness + Entertainment)  
   AR-powered fitness challenges where users unlock milestones by completing location-based workouts.

5. **MinuteMentor** (Education + Productivity)  
   Daily 5-minute micro-lessons with adaptive quizzes and spaced-repetition reminders.

6. **PocketPantry** (Lifestyle)  
   Scan pantry items, get recipe suggestions, and reduce food waste with expiration notifications.

7. **LocalVibe** (Social + Travel)  
   Discover hyperlocal events and hidden gems based on your neighborhood and interests.

8. **CalmCommute** (Lifestyle + Productivity)  
   Optimized commute planner with stress-aware route suggestions and real-time delay predictions.

9. **StoryTrails** (Education + Entertainment)  
   Audio storytelling tours tied to landmarks, with user-generated local history snippets.

---

## Top 3 Ideas that we selected by Group Vote

1. **ChronoLens**
2. **TrailGuard**
3. **CampusSwap**

---

## Evaluation of Top 3 Ideas (Mobile, Story, Market, Habit, Scope)

Scoring scale: **1 (weak) to 5 (strong)**

| Criteria   | ChronoLens                                                                                 | TrailGuard                                                             | CampusSwap                                                           |
| ---------- | ------------------------------------------------------------------------------------------ | ---------------------------------------------------------------------- | -------------------------------------------------------------------- |
| **Mobile** | **5** - Camera scan + GPS location + push reminders make this strongly mobile-first.       | **5** - GPS, maps, push weather/risk alerts are core mobile strengths. | **3** - Useful on mobile, but core value could also exist as web.    |
| **Story**  | **5** - "Discover history where you stand" is easy to explain and demo.                    | **4** - Strong safety narrative, especially for hikers/travelers.      | **4** - Useful and relatable for students, clear money-saving story. |
| **Market** | **4** - Travelers, students, tourists, and local explorers.                                | **4** - Outdoor and travel community is sizable but somewhat niche.    | **4** - Strong in campus ecosystems, narrower outside student users. |
| **Habit**  | **4** - Travel mode daily challenge can create repeat usage and streak behavior.           | **4** - Frequent use during trips/hikes; moderate daily use otherwise. | **3** - Usage spikes around semester cycles and buying periods.      |
| **Scope**  | **4** - Clear MVP: scan -> chat Q&A/follow-up -> save card -> share card -> comment/react. | **3** - Safety features can expand scope quickly (SOS, offline maps).  | **4** - Manageable MVP with listings, search, and messaging basics.  |
| **Total**  | **22/25**                                                                                  | **20/25**                                                              | **18/25**                                                            |

### API Availability and Feasibility Check

- **ChronoLens**
  - **NVIDIA LLM API (hackathon credits available to team)** for image-based place identification.
  - **Wikimedia/Wikipedia APIs** for trusted historical references and raw content (free).
  - **NVIDIA LLM API (second pass)** for question-answering based on Wikipedia context.
  - **OpenStreetMap Nominatim** for reverse geocoding place names (free, with usage limits).
  - **OpenTripMap** (free tier) for nearby points of interest and place metadata.
  - Verdict: **Feasible for MVP with free public APIs plus availability of NVIDIA LLM API credits makes things much easier and faster**.

- **TrailGuard**
  - **OpenWeather API** (free tier) for weather/risk forecast.
  - **Mapbox/OpenStreetMap** for routes and map display.
  - Verdict: **Feasible**, but risk features may increase complexity.

- **CampusSwap**
  - Can be built mostly backend-first (no heavy external API dependency).
  - Optional integrations: campus maps/geolocation and auth providers.
  - Verdict: **Feasible**, technically straightforward.

---

## Final App Decision

### Chosen App: **ChronoLens**

**Why this won:**

- Highest overall evaluation score.
- Strongest mobile-first experience (camera + location + notifications).
- Clear, compelling product story for demos and user testing.
- Achievable MVP within course timeline while still feeling unique.

### Final MVP Direction

- User scans or selects a nearby historical place.
- LLM identifies the place from the photo, user asks questions (including follow-ups), and LLM returns grounded answers.
- Discovery is saved in the user's **Collection** with location and timestamp.
- Saved collection and public share include only snapshot card data (image + identified place info), not the full Q&A thread.
- Other users can react/comment on shared entries.
- **Travel Mode** sends a daily reminder to discover and read at least one unique place.

---
