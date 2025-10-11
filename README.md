# FAF Cab Microservices Architecture

This repository contains the set of microservices powering **FAF Cab** and its community operations.  
Each service has a **clear boundary** and encapsulates specific functionality to ensure modularity, independence, and maintainability.  

---

## Table of Contents
- [Overview](#overview)
- [Service Boundaries](#-service-boundaries)
  - [1. User Management Service](#1-user-management-service)
  - [2. Notification Service](#2-notification-service)
  - [3. Tea Management Service](#3-tea-management-service)
  - [4. Communication Service](#4-communication-service)
  - [5. Cab Booking Service](#5-cab-booking-service)
  - [6. Check-in Service](#6-check-in-service)
  - [7. Lost & Found Service](#7-lost--found-service)
  - [8. Budgeting Service](#8-budgeting-service)
  - [9. Fund Raising Service](#9-fund-raising-service)
  - [10. Sharing Service](#10-sharing-service)
- [Architecture Diagram](#-architecture-diagram)
- [Technologies and Communication Patterns](#️-technologies-and-communication-patterns)
- [Communication Contract and Data Management](#-communication-contract-and-data-management)
- [API Endpoints](#-api-endpoints)
  - [Lost & Found Service](#-lost--found-service-1)
  - [Budgeting Service](#-budgeting-service-1)
  - [Cab Booking Service](#cab-booking-service-1)
  - [Check-in Service](#check-in-service-1)
  - [Tea Management Service](#️-tea-management-service-1)
  - [Communication Service](#-communication-service-1)
  - [Sharing Service](#-sharing-service-1)
  - [Fund Raising Service](#-fund-raising-service-1)
- [Docker Images](#-docker-images)
- [Running the Project](#-running-the-project)
  - [Prerequisites](#prerequisites)
  - [Step-by-Step Guide](#step-1-clone-the-repository)
- [Troubleshooting](#-troubleshooting)
- [Health Checks](#-health-checks)
- [Monitoring](#-monitoring)
- [Updating Services](#-updating-services)
- [Contribution Guidelines](#-contribution-guidelines)
  - [Branching Strategy](#-branching-strategy)
  - [Merging Strategy](#-merging-strategy)
  - [Pull Request Template](#-pull-request-template)
  - [Example Workflow](#-example-workflow)

---


## 📌 Service Boundaries

### 1. User Management Service
- **Responsibilities**:
  - Register and manage users.
  - Store details such as name, nickname, group, and role (student, teacher, admin).
  - Integrate with **Discord** to fetch information from the FAF Community Server.
- **Boundaries**:
  - Owns all user-related data and authentication.
  - Provides APIs for other services to fetch user details (nickname, role).
  - Does **not** handle notifications or resource tracking.

---

### 2. Notification Service
- **Responsibilities**:
  - Send notifications to the right people in a timely manner.
  - Cover cases such as:
    - Supplies running low.
    - Visitor exit reminders during bookings.
    - Communication infractions or bans.
- **Boundaries**:
  - Does not track resources itself; it only **consumes events** from other services and delivers messages.
  - Serves as the central notification hub.

---

### 3. Tea Management Service
- **Responsibilities**:
  - Track consumables (tea, sugar, paper cups, markers, etc.).
  - Record which user consumes what and when.
  - Trigger notifications when consumables run low or when a user overuses resources.
- **Boundaries**:
  - Owns inventory data for consumables.
  - Provides events to **Notification Service** and **Budgeting Service**.

---

### 4. Communication Service
- **Responsibilities**:
  - Allow users to find each other by nickname.
  - Enable public and private chats with individuals or groups.
  - Apply censorship with a banned-words list.
  - Enforce infractions and bans (temporary or permanent).
- **Boundaries**:
  - Owns messaging data and moderation logic.
  - Relies on **User Management Service** for nicknames and roles.
  - Sends infractions to **Notification Service**.

---

### 5. Cab Booking Service
- **Responsibilities**:
  - Manage scheduling of meetings in main room or kitchen.
  - Prevent collisions between exams, games, and other activities.
  - Allow students and teachers to book spaces.
  - Integrate with **Google Calendar**.
- **Boundaries**:
  - Owns booking schedules.
  - Provides booking status APIs to other services.
  - Triggers notifications (via **Notification Service**) for reminders and conflicts.

---

### 6. Check-in Service
- **Responsibilities**:
  - Simulate CCTV facial recognition for user entry/exit tracking.
  - Answer: *“Who has the key?”*
  - Allow registration of one-time guests.
  - Notify admins of unknown persons.
- **Boundaries**:
  - Owns check-in/check-out logs.
  - Relies on **User Management Service** for identity validation.
  - Publishes events to **Notification Service**.

---

### 7. Lost & Found Service
- **Responsibilities**:
  - Allow users to post announcements about lost or found items.
  - Support multiple comment threads per post.
  - Allow posts to be marked as resolved.
- **Boundaries**:
  - Owns lost & found posts and comments.
  - Can trigger notifications when a new post is created or resolved.

---

### 8. Budgeting Service
- **Responsibilities**:
  - Track funds flowing in and out of FAF Cab & FAF NGO.
  - Maintain logs of spending and donations.
  - Manage a debt book for users who overuse or break property.
  - Allow admins to export reports as CSV.
- **Boundaries**:
  - Owns treasury and financial data.
  - Receives updates from **Tea Management Service**, **Sharing Service**, and **Fund Raising Service**.

---

### 9. Fund Raising Service
- **Responsibilities**:
  - Enable admins to raise funds for purchases.
  - Store fundraising goals, deadlines, and donations.
  - Track donor contributions.
  - Automatically register new objects in **Tea Management** or **Sharing Service** after successful campaigns.
  - Update **Budgeting Service** with funds and expenses.
- **Boundaries**:
  - Owns fundraising campaigns and donor data.
  - Delegates financial tracking to **Budgeting Service**.

---

### 10. Sharing Service
- **Responsibilities**:
  - Track multi-use objects (games, cords, cups, kettles).
  - Allow users to rent and return objects.
  - Track object condition (damaged, missing parts, etc.).
  - Notify owners/admins if an object is misused or broken.
  - Update debt book for damages (via **Budgeting Service**).
- **Boundaries**:
  - Owns sharing inventory.
  - Publishes events to **Notification Service** and **Budgeting Service**.
  
  ---

## 🔗 Architecture Diagram

![Architecture Diagram](docs/architecture_diagram.jpg)

---

## ⚙️ Technologies and Communication Patterns

Each microservice is implemented with a different technology stack to ensure diversity, flexibility, and to reflect real-world scenarios where teams may use different languages/frameworks based on their strengths and service requirements.  

### 1. User Management Service
- **Technology**: Python, FastAPI, FastAPI-Users
- **Database**: PostgreSQL
- **Communication**: REST APIs (synchronous), publishes identity-related events via Message Broker.
- **Motivation**:  
  FastAPI provides high performance for REST APIs with minimal overhead.  
  The **FastAPI-Users** library accelerates user authentication and role management (students, teachers, admins).  
  Python’s flexibility and ease of integration with external services (like **Discord**) makes it a strong fit.  
  Trade-off: Not as performant as compiled languages, but speed of development and community support outweigh this for user management tasks.

---

### 2. Notification Service
- **Technology**: Python, FastAPI
- **Database**: PostgreSQL, Redis (for fast, temporary storage of notifications/queues)
- **Communication**:  
  - Consumes events asynchronously from the Message Broker.  
  - Sends REST responses (e.g., confirmation of notification status).  
- **Motivation**:  
  Notifications must be delivered quickly and reliably. Python with FastAPI allows quick prototyping and integration with async event systems.  
  Redis is ideal for short-lived, high-frequency messages.  
  Trade-off: Requires careful scaling to handle spikes in traffic.

---

### 3. Tea Management Service
- **Technology**: .NET 8 (ASP.NET Core Web API)
- **Database**: PostgreSQL
- **Communication**: REST APIs (for querying consumables), publishes events (low stock, overuse) to the Message Broker.
- **Motivation**:  
  .NET provides strong enterprise support and excellent integration with SQL Server.  
  Since this service tracks inventory with structured data, relational DB is a natural fit.  
  Trade-off: More rigid than NoSQL, but consistency and relational queries matter here.

---

### 4. Communication Service
- **Technology**: .NET 8 (SignalR for real-time communication)
- **Database**: PostgreSQL
- **Communication**:  
  - Real-time via WebSockets/SignalR.  
  - Publishes infractions to Notification Service via Message Broker.  
- **Motivation**:  
  Real-time chat requires stable, scalable WebSocket support. SignalR abstracts much of this complexity.  
  MongoDB handles unstructured chat data well (flexible schema).  
  Trade-off: Eventual consistency with NoSQL, but acceptable for chat data.

---

### 5. Cab Booking Service
- **Technology**: Java, Spring Boot
- **Database**: PostgreSQL
- **Communication**: REST APIs for booking, event publishing for reminders and conflicts.
- **Motivation**:  
  Spring Boot provides mature support for enterprise apps and integrates well with external services (e.g., Google Calendar).  
  PostgreSQL ensures consistency for scheduling and avoiding double-bookings.  
  Trade-off: Slightly steeper learning curve, but reliability justifies it.

---

### 6. Check-in Service
- **Technology**: Java, Spring Boot
- **Database**: PostgreSQL
- **Communication**:  
  - REST APIs to register check-in/check-out events.  
  - Publishes entry/exit logs asynchronously (events to Notification Service).  
- **Motivation**:  
  Java provides good support for scalability and performance under high load (simulating CCTV input).  
  PostgreSQL fits well with structured logs of entry/exit events.  
  Trade-off: More verbose than Python/.NET, but ideal for stable backend tracking.

---

### 7. Lost & Found Service
- **Technology**: .NET 8 (ASP.NET Core Web API)
- **Database**: PostgreSQL
- **Communication**: REST APIs (create posts, comment threads), publishes events (post created/resolved) to Notification Service.
- **Motivation**:  
  Flexible structure of posts and comments makes MongoDB a natural choice.  
  .NET ensures good performance and developer productivity.  
  Trade-off: Requires extra moderation logic, but performance is not a bottleneck here.

---

### 8. Budgeting Service
- **Technology**: .NET 8 (ASP.NET Core Web API)
- **Database**: PostgreSQL
- **Communication**:  
  - REST APIs for reports and financial logs.  
  - Consumes events from Tea Management, Sharing, and Fund Raising Services.  
- **Motivation**:  
  Requires ACID compliance to handle treasury logs, debts, and donations.  
  SQL Server provides strong consistency guarantees.  
  Trade-off: Higher maintenance cost vs NoSQL, but correctness is crucial.

---

### 9. Fund Raising Service
- **Technology**: .NET 8 (ASP.NET Core Web API)
- **Database**: PostgreSQL
- **Communication**:  
  - REST APIs for campaign management.  
  - Publishes completion events to Budgeting, Tea Management, or Sharing Services.  
- **Motivation**:  
  PostgreSQL provides good relational modeling for campaigns, goals, and donations.  
  .NET allows strong integration with other services and event-driven workflows.  
  Trade-off: Campaign data is semi-structured, but consistency of donations outweighs flexibility.

---

### 10. Sharing Service
- **Technology**: .NET 8 (ASP.NET Core Web API)
- **Database**: PostgreSQL
- **Communication**:  
  - REST APIs for object rentals/returns.  
  - Publishes events to Notification Service (object broken, overdue).  
  - Updates Budgeting Service via events when debt must be tracked.  
- **Motivation**:  
  MongoDB’s flexible schema is useful for varied object states (games, cords, cups).  
  Event-driven approach ensures smooth integration with debt tracking.  
  Trade-off: Less strict consistency, but acceptable for sharing object states.

 

---

## 📡 Communication Patterns
- **Synchronous**:  
  - REST APIs (FastAPI, ASP.NET Core, Spring Boot) used for direct queries (user lookup, booking availability, lost & found posts).  
- **Asynchronous**:  
  - Message Broker (RabbitMQ) used for events:  
    - Notifications (infractions, booking reminders, consumables low).  
    - Budget updates (fundraising completion, consumables overuse).  
    - Resource state changes (object broken, sharing updates).  
- **Real-time**:  
  - WebSockets (SignalR) for chat and live user communication.  
 
---

## 📑 Communication Contract and Data Management

### 🔗 Communication Contract
To ensure **loose coupling** and **scalability**, services will communicate using a hybrid model of synchronous APIs and asynchronous events:

1. **Synchronous Communication (APIs)**  
   - Services expose **REST APIs** (FastAPI, ASP.NET Core, Spring Boot) for direct queries and updates.  
   - Examples:  
     - User Management Service provides user role/nickname lookup APIs.  
     - Cab Booking Service provides booking availability queries.  
     - Lost & Found Service provides APIs for creating posts and comments.  

2. **Asynchronous Communication (Events via Message Broker)**  
   - Services publish **domain events** (e.g., *ConsumablesLow*, *BookingCreated*, *ObjectBroken*) to a **Message Broker** (Kafka/RabbitMQ).  
   - Other services subscribe to events and react accordingly.  
   - Examples:  
     - Tea Management Service publishes *ConsumablesLow*, consumed by Notification Service.  
     - Sharing Service publishes *ObjectBroken*, consumed by Budgeting Service.  
     - Fund Raising Service publishes *CampaignCompleted*, consumed by Tea Management/Sharing Service + Budgeting Service.  

3. **Real-Time Communication**  
   - Communication Service uses **SignalR (WebSockets)** for live chat between users.  
   - Infractions are sent as async events to Notification Service.  

---

### 🗄️ Data Management Strategy

- **Database per Service**  
  Each microservice owns its own database. No other service is allowed to access it directly.  

- **Data Sharing via APIs**  
  Services requiring another service’s data must call its **public API** rather than accessing its database.  
  Example:  
  - Communication Service requests user nicknames from User Management API.  
  - Check-in Service validates user IDs against User Management API.  

- **Event-Driven Data Propagation**  
  For cross-service workflows, events are propagated via the Message Broker.  
  - Services maintain **local copies** of necessary external data (if needed), updated by events.  
  - Example: Budgeting Service stores debt entries when it receives events from Tea Management or Sharing Services.  

- **Consistency Model**  
  - **Strong consistency** within a service’s own database.  
  - **Eventual consistency** across services via asynchronous events.  
  - Trade-off: Eventual consistency allows decoupling and resilience at the cost of short delays in data propagation, which is acceptable for the FAFCab use case (e.g., budget updates, consumable logs).  

---

### 📡 Example Communication Flow
- A user consumes too much tea:  
  1. **Tea Management Service** records consumption in its SQL Server DB.  
  2. It publishes a `ConsumableOveruse` event to the **Message Broker**.  
  3. **Notification Service** consumes the event → notifies the admin.  
  4. **Budgeting Service** consumes the event → adds an entry to the debt book in SQL Server.  

  ---

  # 📚 API Endpoints

This section defines the **Communication Contract** (endpoints, request/response formats, and data types).
All services expose REST APIs and exchange data in **JSON format** (`Content-Type: application/json`).

---

## 🔎 Lost & Found Service

**Base URL:** `/api/lost-found`  
**Database:** MongoDB  
**Technology Stack:** .NET  

### 1. Create a Post

- **POST** `/posts`
- **Description:** Create a new lost or found item post.

**Request:**
```json
{
  "title": "Lost USB Stick",
  "description": "Black Kingston USB stick, lost in FAFCab kitchen",
  "type": "lost", 
  "authorId": "u123"
}
```

**Response (201 Created):**
```json
{
  "postId": "p001",
  "title": "Lost USB Stick",
  "description": "Black Kingston USB stick, lost in FAFCab kitchen",
  "type": "lost",
  "authorId": "u123",
  "status": "open",
  "createdAt": "2025-09-02T10:30:00Z"
}
```

### 2. Get All Posts

- **GET** `/posts`
- **Description:** Retrieve all lost & found posts.

**Response (200 OK):**
```json
[
  {
    "postId": "p001",
    "title": "Lost USB Stick",
    "type": "lost",
    "status": "open"
  },
  {
    "postId": "p002",
    "title": "Found Jacket",
    "type": "found",
    "status": "resolved"
  }
]
```

### 3. Get a Single Post

- **GET** `/posts/{postId}`
- **Description:** Retrieve details of a specific post.

**Response (200 OK):**
```json
{
  "postId": "p001",
  "title": "Lost USB Stick",
  "description": "Black Kingston USB stick, lost in FAFCab kitchen",
  "type": "lost",
  "authorId": "u123",
  "status": "open",
  "createdAt": "2025-09-02T10:30:00Z",
  "comments": [
    {
      "commentId": "c001",
      "authorId": "u555",
      "text": "I saw one in the main room yesterday",
      "createdAt": "2025-09-02T11:00:00Z"
    }
  ]
}
```

### 4. Add Comment to Post

- **POST** `/posts/{postId}/comments`

**Request:**
```json
{
  "authorId": "u555",
  "text": "I saw one in the main room yesterday"
}
```

**Response (201 Created):**
```json
{
  "commentId": "c001",
  "authorId": "u555",
  "text": "I saw one in the main room yesterday",
  "createdAt": "2025-09-02T11:00:00Z"
}
```

### 5. Resolve Post

- **PATCH** `/posts/{postId}/resolve`
- **Description:** Mark a post as resolved by its creator.

**Response (200 OK):**
```json
{
  "postId": "p001",
  "status": "resolved",
  "resolvedAt": "2025-09-02T12:00:00Z"
}
```

---

## 💰 Budgeting Service

**Base URL:** `/api/budget`  
**Database:** SQL Server  
**Technology Stack:** .NET

### 1. Get Current Balance

- **GET** `/balance`
- **Description:** Returns the current treasury balance.

**Response (200 OK):**
```json
{
  "balance": 1520.75,
  "currency": "EUR",
  "lastUpdated": "2025-09-02T09:00:00Z"
}
```

### 2. Get All Transactions

- **GET** `/transactions`
- **Description:** Retrieve a list of all treasury transactions.

**Response (200 OK):**
```json
[
  {
    "transactionId": "t001",
    "type": "donation",
    "amount": 200.00,
    "currency": "EUR",
    "source": "Partner NGO",
    "createdAt": "2025-08-20T14:30:00Z"
  },
  {
    "transactionId": "t002",
    "type": "expense",
    "amount": 50.00,
    "currency": "EUR",
    "source": "Tea Supplies",
    "createdAt": "2025-08-21T09:15:00Z"
  }
]
```

### 3. Add a Transaction

- **POST** `/transactions`

**Request:**
```json
{
  "type": "expense",
  "amount": 75.00,
  "currency": "EUR",
  "source": "New Board Markers",
  "authorId": "u123"
}
```

**Response (201 Created):**
```json
{
  "transactionId": "t003",
  "type": "expense",
  "amount": 75.00,
  "currency": "EUR",
  "source": "New Board Markers",
  "authorId": "u123",
  "createdAt": "2025-09-02T10:00:00Z"
}
```

### 4. Get Debt Book

- **GET** `/debts`
- **Description:** Retrieve a list of users who owe money for overuse or damages.

**Response (200 OK):**
```json
[
  {
    "debtId": "d001",
    "userId": "u321",
    "reason": "Broke kettle",
    "amount": 30.00,
    "currency": "EUR",
    "status": "unpaid"
  },
  {
    "debtId": "d002",
    "userId": "u789",
    "reason": "Overused tea",
    "amount": 15.00,
    "currency": "EUR",
    "status": "paid"
  }
]
```

### 5. Export Transactions as CSV

- **GET** `/transactions/export`
- **Description:** Allows admins to export transactions as CSV.

**Response (200 OK):**
```
Content-Type: text/csv

transactionId,type,amount,currency,source,createdAt
t001,donation,200.00,EUR,Partner NGO,2025-08-20T14:30:00Z
t002,expense,50.00,EUR,Tea Supplies,2025-08-21T09:15:00Z
t003,expense,75.00,EUR,New Board Markers,2025-09-02T10:00:00Z
```

---

## Cab Booking Service
**Base url:** `/api/bookings`

**Database:** PostgreSQL

**Technology stack:** Java & Spring boot

### 1. Create a booking
- **POST**
- **Description:** Create a booking of any of the rooms in Google Calendar
  **Request:**
``` json
{
    "user_email": "username@gmail.com",
    "room_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
    "startIso": "2025-09-06T09:00:00+03:00",
    "endIso": "2025-09-06T09:00:00+03:00",
    "attendees": [
        {
            "user_email": "username@gmail.com",
            "role_name": "STUDENT"
        },
        {
            "user_email": "username@gmail.com",
            "role_name": "STUDENT"
        }
    ]
}
```
**Response:**
``` json
{
  "id": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
  "booking_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
  "room_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
  "user_email": "username@gmail.com"
  "startIso": "2025-09-06T09:00:00+03:00",
  "endIso": "2025-09-06T09:00:00+03:00",
  "googleEventId": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
  "created_at": "2025-09-06T09:00:00+03:00"
}
```

### 2. Get all bookings
- **GET**
- **Description:** Get all registered bookings
  **Response:**
``` json
{
    {
        "id": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
        "booking_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
        "room_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
        "user_email": "username@gmail.com"
        "startIso": "2025-09-06T09:00:00+03:00",
        "endIso": "2025-09-06T09:00:00+03:00",
        "googleEventId": "c75f7c66-e858-47d6-bb82-7ea5547c800c"
    },
    {
        "id": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
        "booking_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
        "room_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
        "user_email": "username@gmail.com"
        "startIso": "2025-09-06T09:00:00+03:00",
        "endIso": "2025-09-06T09:00:00+03:00",
        "googleEventId": "c75f7c66-e858-47d6-bb82-7ea5547c800c"
    }
}
```
### 3. Get booking by uuid
- **GET** `/{booking_uuid}`
- **Description:** Get booking by it's uuid
  **Response:**
``` json
{
  "id": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
  "booking_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
  "room_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
  "user_email": "username@gmail.com"
  "startIso": "2025-09-06T09:00:00+03:00",
  "endIso": "2025-09-06T09:00:00+03:00",
  "googleEventId": "c75f7c66-e858-47d6-bb82-7ea5547c800c"
}
```
### 4. Cancel a booking
- **DELETE** `/{booking_uuid}`
- **Description:** Cancel a booking by it's uuid
  **Response:**
``` json
{
  "status": "canceled"
  "booking_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c"
}
```
### 5. Add/Remove attendees
- **PATCH** `/{booking_uuid}/attendees`
- **Description:** Add or remove attendees from a google calendar booking
  **Request:**
``` json
{
  "add": [
    {
      "user_email": "username@gmail.com"
      "role_name": "STUDENT"
    }
  ],
  "remove": [
    {
      "user_email": "username@gmail.com"
      "role_name": "STUDENT"
    }
  ]
}
```
**Response:**
``` json
{
  "booking_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
  "attendees": [
    {
      "user_email": "username@gmail.com"
      "status": "added"
    },
    {
      "user_email": "username@gmail.com"
      "status": "removed"
    }
  ],
  "updatedAt": "2025-09-06T09:00:00+03:00"
}
```
### 6. Get attendees of a booking
- **GET** /{booking_uuid}/attendees`
- **Description:** Get all attendees of a booking
  **Response:**
``` json
{
    {
        "booking_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
        "user_email: "username@gmail.com"
    },
    {
        "booking_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
        "user_email: "username@gmail.com"
    }
}
```
### 7. Google calendare response
``` json
{
  "kind": "calendar#event",
  "id": "97nt9h22gfb7ojk7hm2k3ajob0",
  "status": "confirmed",
  "htmlLink": "https://www.google.com/calendar/event?eid=...",
  "summary": "Room booked by Alice",
  "start": { "dateTime": "2025-09-06T09:00:00+03:00" },
  "end":   { "dateTime": "2025-09-06T10:00:00+03:00" },
  "attendees": [
    { 
        "email": "username@gmail.com", 
        "responseStatus": "needsAction" 
    }
  ]
}
```

---

# Check-in Service
**Base url:** `/api/check_in`

**Database:** PostgreSQL

**Technology stack:** Java & Spring boot

### 1. Create an entry
- **POST**
- **Database:** PostgreSQL
- **Technology stack:** Java & Spring boot
  **Request:**
``` json
{
    "id": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
    "registered_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c", (OPTIONAL)    
    "unregistered_uuid": "guest_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c", (OPTIONAL)
    "entry_time": "2025-09-06T09:00:00+03:00"
}
```
**Response:**
``` json
{
    "entry_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
    "registered_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c", (OPTIONAL)
    "unregistered_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c", (OPTIONAL)
    "authorized": True (False if no user/guest uuid provided)
    "entry_time": "2025-09-06T09:00:00+03:00",
    "exit_time": "2025-09-06T09:00:00+03:00"
}
```

### 2. Get an entry
- **GET** `/{entry_uuid}`
- **Description:** Get an entry via its uuid
  **Response:**
``` json
{
    "entry_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
    "registered_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c", (OPTIONAL)
    "unregistered_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c", (OPTIONAL)
    "authorized": True (False if no user/guest uuid provided)
    "entry_time": "2025-09-06T09:00:00+03:00",
    "exit_time": "2025-09-06T09:00:00+03:00"
}
```

### 3. Create a guest
- **POST** `/create_guest`
- **Description:** Create a guest
  **Request:**
``` json
{
    "user_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
    "guest_name": "JohnDoe"
    "room_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c"
}
```
**Response:**
``` json
{
    "guest_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
    "registered_by": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
    "room_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c"
}
```

### 4. Get all guests
- **GET**
- **Description:** Get all guests that were registered
  **Response:**
``` json
{
    {
        "guest_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
        "registered_by": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
        "room_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c"
    },
    {
        "guest_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
        "registered_by": "c75f7c66-e858-47d6-bb82-7ea5547c800c",
        "room_uuid": "c75f7c66-e858-47d6-bb82-7ea5547c800c"
    }
}
```

## ☕️ Tea Management Service

**Base URL:** `/api/consumables`  
**Database:** PostgreSQL  
**Technology Stack:** .NET

### 1. Get All Consumables
- **GET** `/`
- **Description:** Retrieve a list of all consumables and their current stock levels.
**Response (200 OK):**
```json
[
  {
    "uuid": "00000000-0000-0000-0000-000000000000",
    "name": "string",
    "image_link": "string",
    "amount": 0.0,
    "amount_type": "GRAMS",
    "threshold": 0.0,
    "edited_at": "2025-09-02T10:30:00Z"
  }
]
```
### 2. Get Consumable by UUID
- **GET** `/{consumable_uuid}`
- **Description:** Retrieve details of a specific consumable by its UUID.
**Response (200 OK):**
```json
{
  "uuid": "00000000-0000-0000-0000-000000000000",
  "name": "string",
  "image_link": "string",
  "amount": 0.0,
  "amount_type": "GRAMS",
  "threshold": 0.0,
  "edited_at": "2025-09-02T10:30:00Z"
}
```
### 3. Add a New Consumable
- **POST** `/`
- **Description:** Add a new consumable to the inventory.
**Request:**
```json
{
  "name": "string",
  "image": "blob",
  "amount": 0.0,
  "amount_type": "GRAMS",
  "threshold": 0.0
}
```
**Response (201 Created):**
```json
{
  "uuid": "00000000-0000-0000-0000-000000000000",
  "name": "string",
  "image_link": "string",
  "amount": 0.0,
  "amount_type": "GRAMS",
  "threshold": 0.0,
  "edited_at": "2025-09-02T10:30:00Z"
}
```
### 4. Update Consumable Details
- **PATCH** `/{consumable_uuid}`
- **Description:** Update details of a specific consumable (name, image, threshold).
**Request:**
```json
{
  "name": "string",
  "image": "blob",
  "threshold": 0.0
}
```
**Response (200 OK):**
```json
{
  "uuid": "00000000-0000-0000-0000-000000000000",
  "name": "string",
  "image_link": "string",
  "amount": 0.0,
  "amount_type": "GRAMS",
  "threshold": 0.0,
  "edited_at": "2025-09-02T10:30:00Z"
}
```
### 5. Delete a Consumable
- **DELETE** `/{consumable_uuid}`
- **Description:** Remove a consumable from the inventory.
**Response (204 No Content):**
_No body_
### 6. Get Consumption Logs
- **GET** `/logs`
- **Description:** Retrieve a list of all consumption logs.
**Response (200 OK):**
```json
[
  {
    "user_name": "string",
    "user_surname": "string",
    "user_uuid": "00000000-0000-0000-0000-000000000000",
    "name": "string",
    "image_link": "string",
    "consumable_uuid": "00000000-0000-0000-0000-000000000000",
    "amount": 0.0,
    "amount_type": "GRAMS",
    "created_at": "2025-09-02T10:30:00Z"
  }
]
```
### 7. Log Consumable Usage
- **POST** `/logs/use`
- **Description:** Log the usage of a consumable by a user.
**Request:**
```json
{
  "user_uuid": "00000000-0000-0000-0000-000000000000",
  "consumable_uuid": "00000000-0000-0000-0000-000000000000",
  "amount": 0.0
}
```
**Response (201 Created):**
```json
{
  "user_name": "string",
  "user_surname": "string",
  "user_uuid": "00000000-0000-0000-0000-000000000000",
  "name": "string",
  "image_link": "string",
  "consumable_uuid": "00000000-0000-0000-0000-000000000000",
  "amount": 0.0,
  "amount_type": "GRAMS",
  "created_at": "2025-09-02T10:30:00Z"
}
```
### 8. Log Consumable Restock
- **POST** `/logs/restock`
- **Description:** Log the restock of a consumable by an admin.
**Request:**
```json
{
  "user_uuid": "00000000-0000-0000-0000-000000000000",
  "consumable_uuid": "00000000-0000-0000-0000-000000000000",
  "amount": 0.0
}
```
**Response (201 Created):**
```json
{
  "user_name": "string",
  "user_surname": "string",
  "user_uuid": "00000000-0000-0000-0000-000000000000",
  "name": "string",
  "image_link": "string",
  "consumable_uuid": "00000000-0000-0000-0000-000000000000",
  "amount": 0.0,
  "amount_type": "GRAMS",
  "created_at": "2025-09-02T10:30:00Z"
}
```
---

## 💬 Communication Service
**Base URL:** `/api/chat`
**Database:** MongoDB, PostgreSQL
**Technology Stack:** .NET (SignalR for real-time communication)
### 1. Connect to Chat Hub
- **Endpoint:** `/chatHub`
- **Description:** Establish a WebSocket connection to the chat hub using SignalR.
- **Request:**
  - Use SignalR client to connect to the hub.
- **Response:**
  - WebSocket connection established.
### 2. Send Message to Chat
- **Method:** `SendMessage`
- **Description:** Send a message to a private chat.
- **Request:**
```json
{
  "user_id": "string",
  "message": "string"
}
```
- **Response:**
  - Message sent confirmation.
### 3. Send Message to Channel
- **Method:** `SendChannelMessage`
- **Description:** Send a message to a specific channel.
- **Request:**
```json
{
  "channel_id": "string",
  "message": "string"
}
```
- **Response:**
  - Message sent confirmation.
### 4. Receive Messages
- **Method:** `ReceiveMessage`
- **Description:** Receive messages from the chat hub.
- **Response:**
```json
[
  {
    "message_id": "string",
    "sender_id": "string",
    "channel_id": "string",
    "content": "string",
    "sent_at": "2025-09-02T10:30:00Z",
    "read": false
  }
]
```

## 🤝 Sharing Service
**Base URL:** `/api/sharing`
**Database:** PostgreSQL
**Technology Stack:** .NET 
### 1. Get All Shareable Items
- **GET** `/items`
- **Description:** Retrieve a list of all shareable items and their current status.
**Response (200 OK):**
```json
[
  {
    "uuid": "00000000-0000-0000-0000-000000000000",
    "owner_name": "string",
    "owner_surname": "string",
    "owner_uuid": "00000000-0000-0000-0000-000000000000",
    "category": "GAMES",
    "name": "string",
    "image_link": "string",
    "is_available": true,
    "is_usable": true,
    "state": "string",
  }
]
```
### 2. Get Shareable Items by UUID
- **GET** `/{item_uuid}`
- **Description:** Retrieve details of a specific shareable item by its UUID.
**Response (200 OK):**
```json
{
  "uuid": "00000000-0000-0000-0000-000000000000",
  "owner_name": "string",
  "owner_surname": "string",
  "owner_uuid": "00000000-0000-0000-0000-000000000000",
  "category": "GAMES",
  "name": "string",
  "image_link": "string",
  "is_available": true,
  "is_usable": true,
  "state": "string",
}
```
### 3. Add a New Shareable Item
- **POST** `/items`
- **Description:** Add a new shareable item to the inventory.
**Request:**
```json
{
  "owner_uuid": "00000000-0000-0000-0000-000000000000",
  "category": "GAMES",
  "name": "string",
  "image": "blob",
  "state": "string"
}
```
**Response (201 Created):**
```json
{
  "uuid": "00000000-0000-0000-0000-000000000000",
  "owner_name": "string",
  "owner_surname": "string",
  "owner_uuid": "00000000-0000-0000-0000-000000000000",
  "category": "GAMES",
  "name": "string",
  "image_link": "string",
  "is_available": true,
  "is_usable": true,
  "state": "string",
}
```
### 4. Update Shareable Item Details
- **PATCH** `/{item_uuid}`
- **Description:** Update details of a specific shareable item (name, image, state).
**Request:**
```json
{
  "name": "string",
  "image": "blob",
  "state": "string"
}
```
**Response (200 OK):**
```json
{
  "uuid": "00000000-0000-0000-0000-000000000000",
  "owner_name": "string",
  "owner_surname": "string",
  "owner_uuid": "00000000-0000-0000-0000-000000000000",
  "category": "GAMES",
  "name": "string",
  "image_link": "string",
  "is_available": true,
  "is_usable": true,
  "state": "string",
}
```
### 5. Delete a Shareable Item
- **DELETE** `/{item_uuid}`
- **Description:** Remove a shareable item from the inventory.
**Response (204 No Content):**
_No body_
### 6. Rent a Shareable Item
- **POST** `/rent`
- **Description:** Rent a shareable item to a user.
**Request:**
```json
{
  "user_uuid": "00000000-0000-0000-0000-000000000000",
  "item_uuid": "00000000-0000-0000-0000-000000000000",
  "borrowed_at": "2025-09-02T10:30:00"
}
```
**Response (201 Created):**
```json
{ 
  "uuid": "00000000-0000-0000-0000-000000000000",
  "user_name": "string",
  "user_surname": "string",
  "user_uuid": "00000000-0000-0000-0000-000000000000",
  "item_name": "string", 
  "item_uuid": "00000000-0000-0000-0000-000000000000",
  "borrowed_at": "2025-09-02T10:30:00",
  "to_be_returned_at": "2025-09-09T10:30:00",
}
```
### 7. Return a Shareable Item
- **POST** `/return`
- **Description:** Return a rented shareable item.
**Request:**
```json
{
  "rental_uuid": "00000000-0000-0000-0000-000000000000",
  "is_usable": true,
  "state": "string"
}
```
**Response (200 OK):**
```json
{
  "uuid": "00000000-0000-0000-0000-000000000000",
  "user_name": "string",
  "user_surname": "string",
  "user_uuid": "00000000-0000-0000-0000-000000000000",
  "item_name": "string", 
  "item_uuid": "00000000-0000-0000-0000-000000000000",
  "borrowed_at": "2025-09-02T10:30:00",
  "to_be_returned_at": "2025-09-09T10:30:00",
  "returned_at": "2025-09-05T10:30:00",
  "is_usable": true,
  "return_state_borrower": "string"
}
```   
### 8. Confirm Return
- **POST** `/confirm-return`
- **Description:** Confirm the return of a rented shareable item by the owner.
**Request:**
```json
{
  "rental_uuid": "00000000-0000-0000-0000-000000000000",
  "is_usable": true,
  "state": "string"
}
```
**Response (200 OK):**
```json
{
  "uuid": "00000000-0000-0000-0000-000000000000",
  "user_name": "string",
  "user_surname": "string",
  "user_uuid": "00000000-0000-0000-0000-000000000000",
  "item_name": "string", 
  "item_uuid": "00000000-0000-0000-0000-000000000000",
  "borrowed_at": "2025-09-02T10:30:00",
  "to_be_returned_at": "2025-09-09T10:30:00",
  "returned_at": "2025-09-05T10:30:00",
  "is_usable": true,
  "return_state_borrower": "string",
  "return_state_owner": "string"
}
``` 
## 💸 Fund Raising Service
**Base URL:** `/api/fundraising`
**Database:** PostgreSQL
**Technology Stack:** .NET
### 1. Get All Fundraising Campaigns
- **GET** `/`
- **Description:** Retrieve a list of all fundraising campaigns.
**Response (200 OK):**
```json
[
  {
    "uuid": "00000000-0000-0000-0000-000000000000",
    "author_name": "string",
    "author_surname": "string",
    "author_uuid": "00000000-0000-0000-0000-000000000000",
    "good_name": "string",
    "good_amount": 0.0,
    "good_type": "MONEY",
    "good_uuid": "00000000-0000-0000-0000-000000000000",
    "title": "string",
    "description": "string",
    "amount": 0.0,
    "target": 0.0,
    "created_at": "2025-09-02T10:30:00Z",
    "expires_at": "2025-09-02T10:30:00Z",
    "is_active": true
  }
]
```
### 2. Get Fundraising Campaign by UUID
- **GET** `/{fundraiser_uuid}`
- **Description:** Update details of a specific fundraising campaign (title, description, target, expires_at).  
**Request:**
```json
{
  "title": "string",
  "description": "string",
  "target": 0.0,
  "expires_at": "2025-09-02T10:30:00Z"
}
``` 
**Response (200 OK):**
```json
{
  "uuid": "00000000-0000-0000-0000-000000000000",
  "author_name": "string",
  "author_surname": "string",
  "author_uuid": "00000000-0000-0000-0000-000000000000",
  "good_name": "string",
  "good_amount": 0.0,
  "good_type": "MONEY",
  "good_uuid": "00000000-0000-0000-0000-000000000000",
  "title": "string",
  "description": "string",
  "amount": 0.0,
  "target": 0.0,
  "created_at": "2025-09-02T10:30:00Z",
  "expires_at": "2025-09-02T10:30:00Z",
  "is_active": true
}
```   
### 5. Delete a Fundraising Campaign 
- **DELETE** `/{fundraiser_uuid}`
- **Description:** Delete a specific fundraising campaign by its UUID.
**Response (204 No Content):**
_No body_
### 6. Create a Donation
- **POST** `/donations`
- **Description:** Create a new donation towards a fundraising campaign.
**Request:**
```json
{
  "fundraiser_uuid": "00000000-0000-0000-0000-000000000000",
  "user_uuid": "00000000-0000-0000-0000-000000000000",
  "amount": 0.0,
  "currency": "EUR",
  "payment_method": "CREDIT_CARD",
  "reason": "string"
}
```
- **Description:** Retrieve details of a specific fundraising campaign by its UUID.
**Response (200 OK):**
```json
{
  "uuid": "00000000-0000-0000-0000-000000000000",
  "author_name": "string",
  "author_surname": "string",
  "author_uuid": "00000000-0000-0000-0000-000000000000",
  "good_name": "string",
  "good_amount": 0.0,
  "good_type": "MONEY",
  "good_uuid": "00000000-0000-0000-0000-000000000000",
  "title": "string",
  "description": "string",
  "amount": 0.0,
  "target": 0.0,
  "created_at": "2025-09-02T10:30:00Z",
  "expires_at": "2025-09-02T10:30:00Z",
  "is_active": true
}
```
### 3. Create a New Fundraising Campaign
- **POST** `/`
- **Description:** Create a new fundraising campaign.
**Request:**
```json
{
  "author_uuid": "00000000-0000-0000-0000-000000000000",
  "good_uuid": "00000000-0000-0000-000000000000",
  "title": "string",
  "description": "string",
  "target": 0.0,
  "expires_at": "2025-09-02T10:30:00Z"
}
```
**Response (201 Created):**
```json
{
  "uuid": "00000000-0000-0000-0000-000000000000",
  "author_name": "string",
  "author_surname": "string",
  "author_uuid": "00000000-0000-0000-0000-000000000000",
  "good_name": "string",
  "good_amount": 0.0,
  "good_type": "MONEY",
  "good_uuid": "00000000-0000-0000-0000-000000000000",
  "title": "string",
  "description": "string",
  "amount": 0.0,
  "target": 0.0,
  "created_at": "2025-09-02T10:30:00Z",
  "expires_at": "2025-09-02T10:30:00Z",
  "is_active": true
}
```
### 4. Update Fundraising Campaign Details
- **PATCH** `/{fundraiser_uuid}`
- **Description:** Update details of a specific fundraising campaign (title, description, target, expires_at).  
**Request:**
```json
{
  "title": "string",
  "description": "string",
  "target": 0.0,
  "expires_at": "2025-09-02T10:30:00Z"
}
``` 
**Response (200 OK):**
```json
{
  "uuid": "00000000-0000-0000-0000-000000000000",
  "author_name": "string",
  "author_surname": "string",
  "author_uuid": "00000000-0000-0000-0000-000000000000",
  "good_name": "string",
  "good_amount": 0.0,
  "good_type": "MONEY",
  "good_uuid": "00000000-0000-0000-0000-000000000000",
  "title": "string",
  "description": "string",
  "amount": 0.0,
  "target": 0.0,
  "created_at": "2025-09-02T10:30:00Z",
  "expires_at": "2025-09-02T10:30:00Z",
  "is_active": true
}
```   
### 5. Delete a Fundraising Campaign 
- **DELETE** `/{fundraiser_uuid}`
- **Description:** Delete a specific fundraising campaign by its UUID.
**Response (204 No Content):**
_No body_
### 6. Create a Donation
- **POST** `/donations`
- **Description:** Create a new donation towards a fundraising campaign.
**Request:**
```json
{
  "fundraiser_uuid": "00000000-0000-0000-0000-000000000000",
  "user_uuid": "00000000-0000-0000-0000-000000000000",
  "amount": 0.0
}
```
**Response (201 Created):**
```json
{
  "uuid": "00000000-0000-0000-0000-000000000000",
  "fundraiser_title": "string",
  "fundraiser_uuid": "00000000-0000-0000-0000-000000000000",
  "good_name": "string",
  "good_uuid": "00000000-0000-0000-0000-000000000000",
  "user_name": "string",
  "user_surname": "string",
  "user_uuid": "00000000-0000-0000-0000-000000000000",
  "amount": 0.0,
  "created_at": "2025-09-02T10:30:00Z"
}
```
### 7. Get Donations by Fundraiser UUID
- **GET** `/donations/{fundraiser_uuid}`
- **Description:** Retrieve all donations made towards a specific fundraising campaign.
**Response (200 OK):**
```json
[
  {
    "uuid": "00000000-0000-0000-0000-000000000000",
    "fundraiser_title": "string",
    "fundraiser_uuid": "00000000-0000-0000-0000-000000000000",
    "good_name": "string",
    "good_uuid": "00000000-0000-0000-0000-000000000000",
    "user_name": "string",
    "user_surname": "string",
    "user_uuid": "00000000-0000-0000-0000-000000000000",
    "amount": 0.0,
    "created_at": "2025-09-02T10:30:00Z"
  }
]
```
### 8. Get Donations by User UUID
- **GET** `/donations/user/{user_uuid}`
- **Description:** Retrieve all donations made by a specific user.
**Response (200 OK):**
```json
[
  { 
    "uuid": "00000000-0000-0000-0000-000000000000",
    "fundraiser_title": "string",
    "fundraiser_uuid": "00000000-0000-0000-0000-000000000000",
    "good_name": "string",
    "good_uuid": "00000000-0000-0000-0000-000000000000",
    "amount": 0.0,
    "created_at": "2025-09-02T10:30:00Z"
  }
]
```
---

## 🤝 Contribution Guidelines

### 🔀 Branching Strategy
- **Main Branches:**
  - `main` → Stable production-ready code
  - `development` → Active development branch where features are merged before release
- **Naming Branches:**  
  - Naming convention: `<ticket-number>/<short-description>` 

---

### 🔧 Merging Strategy
- All changes must be introduced via **Pull Requests (PRs)**.
- PRs into `main` and `development` require:
  - **At least 2 approvals** from team members.
  - All checks/tests to pass successfully.
- Use **Squash and Merge** strategy to keep history clean.
- Commit messages should be descriptive and follow [Conventional Commits](https://www.conventionalcommits.org/) style:
  - `feat: add comment endpoint to Lost & Found service`
  - `fix: correct balance calculation in Budgeting service`
  - `doc: update contribution guidelines`
- PRs on main are closed after end-to-end testing and 3 approvals

---

### 📋 Pull Request Template
Each PR should include:
1. **Summary** – Short description of the change.
2. **Related Issue** – Reference to issue number (if applicable).
3. **Changes Made** – List of modifications.
4. **Testing Done** – How was this tested (manual/automated).
5. **Checklist**:
   - [ ] Code follows project coding style
   - [ ] Tests added/updated
   - [ ] Documentation updated (if required)

---

### 🗂 Example Workflow
1. Create a new branch from `development`:  
   ```bash
   git checkout development
   git pull origin development
   git checkout -b feature/communication-censorship

---

## 🐳 Docker Images

All microservices are available as pre-built Docker images hosted on Docker Hub:

| Service | Docker Image | Platform |
|---------|-------------|----------|
| API Gateway | `andreiberco/pad-faf-gateway:latest` | linux/amd64 |
| User Management Service | `russian17/pad-user-management-service:latest` | linux/amd64 |
| Notification Service | `russian17/pad-notification_service:latest` | linux/amd64 |
| Budgeting Service | `andreiberco/pad-budgeting-service:latest` | linux/amd64 |
| Lost & Found Service | `andreiberco/pad-l-f-service:latest` | linux/amd64 |
| Cab Booking Service | `victorrevenco/pad_cab_booking_service:latest` | linux/amd64 |
| Check-in Service | `victorrevenco/pad_check-in_service:latest` | linux/amd64 |
| Tea Management Service | `theboogheyman/pad-tea-management-service:1.0.1` | linux/amd64 |
| Communication Service | `theboogheyman/pad-communication-service:1.0.3` | linux/amd64 |
| Sharing Service | `iulianach/pad-sharing-service:latest` | linux/amd64 |
| Fund Raising Service | `iulianach/pad-fund-raising-service:latest` | linux/amd64 |

### Supporting Services
- **Redis**: `redis:7`
- **PostgreSQL**: `postgres:16`, `postgres:15-alpine`, `postgres:16-alpine`
- **MongoDB**: `mongo`

---

## 🚀 Running the Project

### Prerequisites
- Docker (version 20.10 or higher)
- Docker Compose (version 2.0 or higher)
- Git

### Step 1: Clone the Repository
```bash
git clone https://github.com/your-org/PAD-FAF-CAB.git
cd PAD-FAF-CAB
```

### Step 2: Configure Environment Variables
Create a `.env` file in the root directory based on the provided template:

```bash
cp .env.example .env
```

Edit the `.env` file and configure the following required variables:

**Redis Configuration:**
```env
REDIS_HOST=redis
REDIS_PORT=6379
```

**JWT Configuration:**
```env
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production-min-32-chars
```

**User Management Service:**
```env
UM_POSTGRES_DB=user_management_db
UM_POSTGRES_USER=user_management_user
UM_POSTGRES_PASSWORD=secure_password
UM_DATABASE_URL=postgresql+asyncpg://user_management_user:secure_password@um_postgres:5432/user_management_db
UM_SYNC_DATABASE_URL=postgresql://user_management_user:secure_password@um_postgres:5432/user_management_db
UM_JWT_SECRET_KEY=your-jwt-secret-key
UM_JWT_ALGORITHM=HS256
UM_JWT_EXPIRE_MINUTES=30
UM_JWT_REFRESH_EXPIRE_DAYS=7
UM_SECURE_COOKIES=false
UM_COOKIE_DOMAIN=localhost
UM_CORS_ORIGINS=["http://localhost:3000"]
UM_ENVIRONMENT=development
UM_DB_ECHO=false
UM_APP_PORT=8088
UM_DISCORD_BOT_TOKEN=your_discord_bot_token
UM_DISCORD_GUILD_ID=your_discord_guild_id
```

**Notification Service:**
```env
NS_POSTGRES_DB=notification_service_db
NS_POSTGRES_USER=notification_service_user
NS_POSTGRES_PASSWORD=secure_password
NS_DATABASE_URL=postgresql+asyncpg://notification_service_user:secure_password@ns_postgres:5432/notification_service_db
NS_SYNC_DATABASE_URL=postgresql://notification_service_user:secure_password@ns_postgres:5432/notification_service_db
NS_CORS_ORIGINS=["http://localhost:3000"]
NS_APP_PORT=8089
NS_DISCORD_BOT_TOKEN=your_discord_bot_token
NS_DISCORD_GUILD_ID=your_discord_guild_id
NOTIFICATION_SERVICE_URL=http://pad-gateway:8001/internal/notification
```

**Budgeting Service:**
```env
BUDGETING_POSTGRES_DB=budgeting_db
BUDGETING_POSTGRES_USER=budgeting_user
BUDGETING_POSTGRES_PASSWORD=secure_password
ASPNETCORE_ENVIRONMENT=Development
```

**Lost & Found Service:**
```env
LF_POSTGRES_DB=lost_found_db
LF_POSTGRES_USER=lost_found_user
LF_POSTGRES_PASSWORD=secure_password
```

**Cab Booking Service:**
```env
CAB_BOOKING_POSTGRES_DB=cab_booking_db
CAB_BOOKING_POSTGRES_USER=cab_booking_user
CAB_BOOKING_POSTGRES_PASSWORD=secure_password
CAB_BOOKING_SPRING_DATASOURCE_URL=jdbc:postgresql://cb_postgres:5432/cab_booking_db
CAB_BOOKING_SPRING_DATASOURCE_USERNAME=cab_booking_user
CAB_BOOKING_SPRING_DATASOURCE_PASSWORD=secure_password
```

**Check-in Service:**
```env
CHECKIN_POSTGRES_DB=checkindb
CHECKIN_POSTGRES_USER=checkin_user
CHECKIN_POSTGRES_PASSWORD=secure_password
CHECKIN_SPRING_DATASOURCE_URL=jdbc:postgresql://ci_postgres:5432/checkindb
CHECKIN_SPRING_DATASOURCE_USERNAME=checkin_user
CHECKIN_SPRING_DATASOURCE_PASSWORD=secure_password
```

**Tea Management Service:**
```env
TM_HTTP_PORTS=8082
TM_DB_HOST=tea-management-db
TM_DB_PORT=5432
TM_DB_USER=tea_management_service_user
TM_DB_PASSWORD=cyngos-wikpuT-bukmo8
TM_DB_NAME=tea_management_service_db
TM_ASPNETCORE_ENVIRONMENT=Development
```

**Communication Service:**
```env
C_HTTP_PORTS=8083
C_DB_HOST=communication-db
C_DB_PORT=5432
C_DB_USER=communication_service_user
C_DB_PASSWORD=cyngos-wikpuT-bukmo8
C_DB_NAME=communication_service_db
C_LOCAL_DB_PORT=5432
C_MONGO_DB_ROOT_USER=root
C_MONGO_DB_ROOT_PASSWORD=example
C_MONGO_DB_NAME=communication
C_MONGO_DB_PORT=27017
C_ASPNETCORE_ENVIRONMENT=Development
```

**Sharing Service:**
```env
S_HTTP_PORTS=8090
S_DB_HOST=s_postgres
S_DB_PORT=5432
S_DB_USER=sharing_user
S_DB_PASSWORD=secure_password
S_DB_NAME=sharing_db
S_LOCAL_DB_PORT=5438
S_ASPNETCORE_ENVIRONMENT=Development
```

**Fund Raising Service:**
```env
FR_HTTP_PORTS=8091
FR_DB_HOST=fr_postgres
FR_DB_PORT=5432
FR_DB_USER=fundraising_user
FR_DB_PASSWORD=secure_password
FR_DB_NAME=fundraising_db
FR_LOCAL_DB_PORT=5439
FR_ASPNETCORE_ENVIRONMENT=Development
```

### Step 3: Pull Docker Images
Pull all required Docker images from Docker Hub:

```bash
docker compose pull
```

This will download all the pre-built images for the microservices.

### Step 4: Start All Services
Start all services using Docker Compose:

```bash
docker compose up -d
```

The `-d` flag runs the containers in detached mode (background).

### Step 5: Verify Services Are Running
Check the status of all containers:

```bash
docker compose ps
```

All services should show a status of "Up" or "healthy".

### Step 6: Access the Services
Once all services are running, you can access them at the following ports:

| Service | Port | URL |
|---------|------|-----|
| API Gateway (External) | 8000 | http://localhost:8000 |
| API Gateway (Internal) | 8001 | http://localhost:8001 |
| User Management Service | 8088 | http://localhost:8088/docs |
| Notification Service | 8089 | http://localhost:8089/docs |
| Tea Management Service | 8082 | http://localhost:8082 |
| Communication Service | 8083 | http://localhost:8083 |
| Cab Booking Service | 8084 | http://localhost:8084 |
| Check-in Service | 8085 | http://localhost:8085 |
| Lost & Found Service | 8086 | http://localhost:8086 |
| Budgeting Service | 8087 | http://localhost:8087 |
| Sharing Service | 8090 | http://localhost:8090 |
| Fund Raising Service | 8091 | http://localhost:8091 |

### Step 7: View Logs
To view logs for all services:

```bash
docker compose logs -f
```

To view logs for a specific service:

```bash
docker compose logs -f <service-name>
```

Example:
```bash
docker compose logs -f user-management
```

### Step 8: Stop All Services
To stop all running services:

```bash
docker compose down
```

To stop services and remove all volumes (including databases):

```bash
docker compose down -v
```

---

## 🔧 Troubleshooting

### Common Issues

**1. Port Conflicts**
If you encounter port conflicts, modify the port mappings in [`docker-compose.yml`](docker-compose.yml ) or change the exposed ports in your [`.env`](.env ) file.

**2. Database Connection Errors**
Ensure that:
- Database containers are healthy: `docker compose ps`
- Connection strings in [`.env`](.env ) match the service names in [`docker-compose.yml`](docker-compose.yml )
- Wait for databases to initialize (check logs: `docker compose logs <db-service>`)

**3. Image Pull Errors**
If images fail to pull:
```bash
docker login
docker compose pull
```

**4. Memory Issues**
If services crash due to memory limits, increase Docker's memory allocation in Docker Desktop settings (recommend at least 8GB).

**5. Service Dependencies**
Services have dependencies on databases. If a service fails to start:
1. Check database health: `docker compose ps`
2. Restart the specific service: `docker compose restart <service-name>`

---

## 🧪 Health Checks

Most services include health checks. To verify:

```bash
docker compose ps
```

Services should show "healthy" status when ready.

Individual health check endpoints (where available):
- User Management: `http://localhost:8088/docs`
- Notification Service: `http://localhost:8089/docs`

---

## 📊 Monitoring

To monitor resource usage:

```bash
docker stats
```

This shows CPU, memory, and network usage for all running containers.

---

## 🔄 Updating Services

To update to the latest version of a service:

```bash
docker compose pull <service-name>
docker compose up -d <service-name>
```

To update all services:

```bash
docker compose pull
docker compose up -d
```