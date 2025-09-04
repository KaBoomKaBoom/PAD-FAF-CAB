# FAF Cab Microservices Architecture

This repository contains the set of microservices powering **FAF Cab** and its community operations.  
Each service has a **clear boundary** and encapsulates specific functionality to ensure modularity, independence, and maintainability.  

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