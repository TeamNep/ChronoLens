# ChronoLens

## Table of Contents

1. [Overview](#overview)
2. [Product Spec](#product-spec)
3. [Wireframes](#wireframes)
4. [Schema](#schema)

## Overview

### Description

**ChronoLens** is a mobile app that helps users discover and learn about historical places around them. Users take a picture of a landmark, building, or artwork, use an LLM to identify what the place is, and enter questions in a chat space to get answers from the model. Users can continue asking follow-up questions in the same chat flow.

When saving to **Collection**, only the landmark snapshot card is stored (image + identified place info + metadata), not the full chat conversation. Sharing to the **Community** feed also shares only this collection card. Users can also enable **Travel Mode**, which sends a daily reminder encouraging them to scan and learn one unique historical place each day.

### App Evaluation

- **Category:** Education / Travel / Social
- **Mobile:** Strongly mobile-first (camera scan, location, push notifications, map-based context).
- **Story:** "Learn history where you stand." Clear, memorable, and easy to demo.
- **Market:** Travelers, students, history enthusiasts, and curious local explorers.
- **Habit:** Daily reminder loop + collection building + social sharing encourages repeat opens.
- **Scope:** Well-bounded MVP with room for optional gamification and personalization.
- **AI/API Feasibility:** Team has NVIDIA LLM API credits through a hackathon, enabling LLM-powered place identification and question-answering in MVP.

## Product Spec

### 1. User Stories (Required and Optional)

#### Required Must-have Stories

- [x] User can create an account and sign in.
- [x] User can grant camera and location permissions.
- [x] User can capture or upload a landmark photo, have an LLM identify it.
- [x] User can ask a custom question about the identified landmark, and retrieve an answer.
- [x] User can save a discovered place to personal **Collection** as a card containing image + identified place info + location/timestamp (without full chat history).
- [x] User can share any collection card to **Community** in one tap (without full chat history).
- [x] User can enable/disable **Travel Mode** daily reminder notifications.

#### Optional Nice-to-have Stories

- [x] User can react and comment on community posts.
- [x] User can earn badges/streaks for consecutive daily discoveries.
- [x] User can bookmark community posts for later reading.
- [ ] User can filter collection by city, era, or tags.
- [ ] User can translate place answers/summaries to preferred language.
- [ ] User can follow specific users or local creators.

### 2. Screen Archetypes

- **Onboarding / Auth Screen**
  - User signs up/logs in.
  - User grants camera/location/notification permissions.

- **Explore Screen (Tab 1)**
  - User captures or uploads a landmark photo.
  - User initiates LLM-based place identification and lookup.

- **Landmark Chat Screen**
  - Shows captured image, identified place title, question input, AI answers, and follow-up chat flow.
  - User can save to collection card.

- **Collection Screen (Tab 2)**
  - Lists saved collection cards with image, identified place info, and date/location metadata.
  - Does not display full question/answer conversation history.
  - User can tap "Share" on any item to auto-post publicly.

- **Community Feed Screen (Tab 3)**
  - Displays shared collection cards (image + identified place info) from users.
  - User can react/comment on posts.

- **Post Detail / Comments Screen**
  - Full post view with comments thread and reactions.

- **Travel Mode Settings Screen**
  - Toggle daily reminder and preferred reminder time (1 notification per day).

### 3. Navigation

#### Tab Navigation (Tab to Screen)

- **Explore** -> Explore Screen
- **Collection** -> Collection Screen
- **Community** -> Community Feed Screen

#### Flow Navigation (Screen to Screen)

- **Onboarding / Auth Screen**
  - Leads to **Explore Screen**

- **Explore Screen**
  - Leads to **Landmark Chat Screen** (after capture/upload)
  - Leads to **Travel Mode Settings Screen**

- **Landmark Chat Screen**
  - Leads to **Collection Screen** (after save)
  - Returns to **Explore Screen**

- **Collection Screen**
  - Leads to **Landmark Chat Screen** (open saved item)
  - Leads to **Community Feed Screen** (after one-tap share)

- **Community Feed Screen**
  - Leads to **Post Detail / Comments Screen**
  - Leads to **Collection Screen** (via tab)

- **Post Detail / Comments Screen**
  - Returns to **Community Feed Screen**

- **Travel Mode Settings Screen**
  - Returns to **Explore Screen**

## Wireframes

### Low-Fidelity Wireframes

![IMG_0752](https://github.com/user-attachments/assets/ef7511fc-f489-4c4f-ac0e-85debd3aea0e)

### [BONUS] Digital Wireframes & Mockups

<img width="965" height="1035" alt="image" src="https://github.com/user-attachments/assets/d48a01d3-8dc4-4241-9076-388b3beb69ea" />
<img width="965" height="1035" alt="image" src="https://github.com/user-attachments/assets/4f383198-0c3a-4e6d-9aac-29909f5f5c7e" />
<img width="965" height="1035" alt="image" src="https://github.com/user-attachments/assets/18427b79-36af-4b8c-b01c-b81b7e7b50ff" />
<img width="965" height="673" alt="image" src="https://github.com/user-attachments/assets/a742961e-a89d-4213-a974-ae1c7432c2d0" />

## Build Progress:

**Milestones: Sprint 1 & 2 completed (Combined Video)**

We completed two Milestones (Sprint 1 and Sprint 2) for this unit submission! Sprint 3 will be done in next unit!

<div>
    <a href="https://www.loom.com/share/bc5dab2b41074a5da90459fa7fcccc11">
    </a>
    <a href="https://www.loom.com/share/bc5dab2b41074a5da90459fa7fcccc11">
      <img style="max-width:300px;" src="https://cdn.loom.com/sessions/thumbnails/bc5dab2b41074a5da90459fa7fcccc11-1c738f010df1a298-full-play.gif#t=0.1">
    </a>
  </div>

## Schema

### Models

#### User

| Property          | Type    | Description                      |
| ----------------- | ------- | -------------------------------- |
| objectId          | String  | unique user id                   |
| username          | String  | unique display/account name      |
| email             | String  | login/contact email              |
| travelModeEnabled | Boolean | whether daily reminder is active |
| reminderTime      | String  | user's preferred reminder time   |

#### PlaceEntry

| Property            | Type            | Description                               |
| ------------------- | --------------- | ----------------------------------------- |
| objectId            | String          | unique place entry id                     |
| userId              | Pointer to User | owner of saved place                      |
| imageUrl            | String          | stored landmark image path/url            |
| placeName           | String          | historical place title                    |
| summary             | String          | short historical description              |
| aiAnswerModel       | String          | model used for final answer generation    |
| detectionConfidence | Number          | confidence score from identification step |
| latitude            | Number          | geo latitude                              |
| longitude           | Number          | geo longitude                             |
| scannedAt           | DateTime        | timestamp when discovered                 |
| isShared            | Boolean         | whether posted publicly                   |

#### ChatTurn (Session Context)

| Property     | Type                  | Description                                       |
| ------------ | --------------------- | ------------------------------------------------- |
| objectId     | String                | unique chat turn id                               |
| userId       | Pointer to User       | owner of chat turn                                |
| placeEntryId | Pointer to PlaceEntry | linked place context                              |
| questionText | String                | user question in chat                             |
| answerText   | String                | grounded answer returned by LLM                   |
| createdAt    | DateTime              | timestamp                                         |
| isShared     | Boolean               | always false (chat turns are not shared publicly) |

#### Post

| Property      | Type                  | Description           |
| ------------- | --------------------- | --------------------- |
| objectId      | String                | unique post id        |
| placeEntryId  | Pointer to PlaceEntry | linked saved place    |
| userId        | Pointer to User       | author                |
| caption       | String                | optional post caption |
| reactionCount | Number                | total reactions       |
| commentCount  | Number                | total comments        |
| createdAt     | DateTime              | time shared           |

#### Comment

| Property  | Type            | Description       |
| --------- | --------------- | ----------------- |
| objectId  | String          | unique comment id |
| postId    | Pointer to Post | parent post       |
| userId    | Pointer to User | author            |
| text      | String          | comment content   |
| createdAt | DateTime        | timestamp         |

### Networking

#### External APIs

- **NVIDIA LLM API**
  - Team has credits through hackathon.
  - Used for landmark identification from image input.
  - Used again for question-answering and follow-up responses in chat.

#### App Requests by Screen

- **Explore Screen**
  - `[POST] uploadLandmarkImage(imagePayload)`
  - `[POST] identifyPlaceWithLLM(imagePayload)`

- **Landmark Chat Screen**
  - `[POST] answerPlaceQuestionWithLLM(question, sessionContext)`
  - `[POST] answerFollowUpQuestionWithLLM(sessionContext, question)`
  - `[POST] savePlaceEntry(...)`

- **Collection Screen**
  - `[GET] listSavedEntries(userId)`
  - `[POST] sharePlaceEntry(placeEntryId)` (shares only collection card)

- **Community Feed Screen**
  - `[GET] listPosts()`
  - `[POST] reactToPost(postId, reactionType)`

- **Post Detail Screen**
  - `[GET] listComments(postId)`
  - `[POST] createComment(postId, text)`

- **Travel Mode Settings Screen**
  - `[PATCH] updateReminderSettings(userId, enabled, time)`
