# Collaborative Brainstorming Application

A real-time collaborative platform designed to facilitate brainstorming sessions for teams. This application allows users to create events, form teams, define topics, and conduct interactive brainstorming rounds. It leverages **Google Gemini AI** to summarize ideas and provides comprehensive reporting features including PDF exports.

## 🚀 Features

- **Real-time Collaboration**: Live updates during brainstorming sessions using WebSockets.
- **Session Management**: Structured rounds for idea generation.
- **Team & Event Management**: Organize participants into teams and group sessions under events.
- **AI-Powered Summarization**: Automatically groups and summarizes ideas using Gemini AI.
- **Reporting**: Export detailed session reports as PDF.
- **Secure Authentication**: JWT-based user authentication.
- **Modern UI**: Responsive design built with Next.js and Tailwind CSS.

## 🛠️ Tech Stack

### Backend
- **Language**: Java 21
- **Framework**: Spring Boot 3
- **Database**: MySQL 8.0
- **AI Integration**: Google Gemini API
- **Security**: Spring Security + JWT
- **Build Tool**: Maven

### Frontend
- **Framework**: Next.js 16 (App Router)
- **Library**: React 19
- **Styling**: Tailwind CSS 4
- **Language**: TypeScript
- **State Management**: React Hooks
- **PDF Generation**: jsPDF
- **Icons**: Lucide React

## 📋 Prerequisites

Ensure you have the following installed:
- **Java Development Kit (JDK) 21**
- **Node.js** (v18 or higher)
- **MySQL Server**
- **Maven**

## ⚙️ Installation & Setup

### 1. Database Setup

Create the MySQL database and import the schema:

```bash
# Log in to MySQL
mysql -u root -p

# Create database
CREATE DATABASE brainstorming_app;

# Import schema (from project root)
use brainstorming_app;
source brainstorming_app.sql;
```

### 2. Backend Setup

Navigate to the backend directory:

```bash
cd backend
```

Configure environment variables in `src/main/resources/application.yml` or set them in your environment:

- `spring.datasource.username`: Your MySQL username
- `spring.datasource.password`: Your MySQL password
- `gemini.api.key`: Your Google Gemini API Key
- `jwt.secret`: A secure secret key for token generation

Build and run the application:

```bash
mvn clean install
mvn spring-boot:run
```

The backend server will start on `http://localhost:8080`.

### 3. Frontend Setup

Navigate to the frontend directory:

```bash
cd frontend
```

Install dependencies:

```bash
npm install
# or
yarn install
```

Create a `.env.local` file in the `frontend` directory (optional, if you need to override defaults):

```env
NEXT_PUBLIC_API_URL=http://localhost:8080/api
NEXT_PUBLIC_WS_URL=ws://localhost:8080/ws
```

Run the development server:

```bash
npm run dev
```

The application will be available at `http://localhost:3000`.

## 📖 Usage Guide

1.  **Register/Login**: Create an account to get started.
2.  **Create an Event**: Define the context for your brainstorming (e.g., "Q4 Marketing Strategy").
3.  **Create Teams**: Add participants to teams.
4.  **Start a Session**: Select a topic and launch a session.
5.  **Brainstorm**: Participants submit ideas in real-time.
6.  **Review & Summarize**: View grouped ideas and AI-generated summaries.
7.  **Export**: Download the session report as a PDF.

## 🤝 Contributing

Contributions are welcome! Please fork the repository and submit a pull request.

## 📄 License

This project is licensed under the MIT License.
